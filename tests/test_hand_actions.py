"""OpenSCAD integration and kinematic invariants; no Python dependencies."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "hand_actions_modular" / "hand_actions"
OPENSCAD = shutil.which("openscad")


@unittest.skipUnless(OPENSCAD, "OpenSCAD executable is required")
class HandActionsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="hand_actions_test_")
        self.directory = Path(self.temp.name)
        self.addCleanup(self.temp.cleanup)

    def evaluate(self, path=None, source=None, **settings):
        if source is not None:
            path = self.directory / "check.scad"
            path.write_text(source)
        command = [OPENSCAD, "--hardwarnings", "-o", str(self.directory / "check.csg")]
        for name, value in settings.items():
            command += ["-D", f"{name}={value}"]
        command.append(str(path or SCENE / "main.scad"))
        result = subprocess.run(command, capture_output=True, text=True, timeout=60)
        # Some OpenSCAD versions return zero even when an assertion fails.
        return result.returncode, result.stdout + result.stderr

    def assert_evaluates(self, **kwargs):
        code, output = self.evaluate(**kwargs)
        self.assertEqual(code, 0, output)
        self.assertNotIn("ERROR:", output)
        self.assertNotIn("WARNING:", output)

    def test_all_actions_at_phase_boundaries(self):
        actions = ("arm_reach", "joint_test", "open_close", "cylinder_grasp",
                   "pinch", "peel", "peel_whole", "wave", "manual")
        for action in actions:
            for mounted in ("true", "false"):
                for time in (0, .2, .42, .5, .65, .72, .8, .9, 1):
                    with self.subTest(action=action, mounted=mounted, time=time):
                        self.assert_evaluates(action=f'"{action}"', show_arm=mounted,
                                              animate="false", pose_time=time)

    def test_display_controls_and_direct_previews(self):
        self.assert_evaluates(fill_workspace="true", show_object="false")
        self.assert_evaluates(show_workspace="false", animate="false", pose_time=.5)
        for action in (SCENE / "actions").glob("*.scad"):
            with self.subTest(file=action.name):
                self.assert_evaluates(path=action)

    def test_invalid_settings_report_assertions(self):
        cases = [
            ({"action": '"pinch"', "workspace_upper": "[55,350,477]"}, "Workspace crosses"),
            ({"action": '"pinch"', "workspace_upper": "[55,285,300]"}, "Workspace bounds"),
            ({"action": '"pinch"', "reach_margin": 3}, "Workspace crosses"),
            ({"reach_margin": -1}, "nonnegative"),
            ({"workspace_lower": "[-10,145,385]", "workspace_upper": "[10,280,477]",
              "action": '"arm_reach"', "animate": "false", "pose_time": .5}, "Wrist outside"),
            ({"action": '"peel"', "peel_length": -1}, "Peel length"),
            ({"action": '"peel"', "peel_length": 54}, "Peel length"),
            ({"action": '"peel"', "peel_lift_angle": 90}, "Peel lift angle"),
            ({"whole_peel_bands": 7}, "Whole peel bands"),
            ({"whole_peel_bands": 12.5}, "Whole peel bands"),
            ({"whole_workspace_upper": "[155,335,300]"}, "Workspace bounds"),
            ({"whole_workspace_lower": "[-10,25,385]", "whole_workspace_upper": "[10,335,645]",
              "animate": "false", "pose_time": .53}, "Wrist outside"),
            ({"action": '"unknown"'}, "Unknown action"),
        ]
        for settings, expected in cases:
            with self.subTest(settings=settings):
                # A user's selected preview action must not change these cases.
                _, output = self.evaluate(**{"action": '"peel_whole"', **settings})
                self.assertIn("ERROR:", output)
                self.assertIn(expected, output)

    def test_whole_box_includes_interior_nearest_point(self):
        # All corners are outside the folded-arm hole, but the interior is not.
        _, output = self.evaluate(source=f"""
use <{SCENE / 'model/workspace.scad'}>
validate_workspace([-40,-40,-40],[40,40,40],[0,0,0],180,155,2);
""")
        self.assertIn("Workspace crosses", output)

    def test_whole_peel_passes_and_final_skin(self):
        for band in (0, 7, 15):
            for phase in (0, .12, .16, .46, .76, .78, .88, .94, 1):
                with self.subTest(band=band, phase=phase):
                    self.assert_evaluates(action='"peel_whole"', animate="false",
                                          pose_time=(band + phase) / 16)
        self.assert_evaluates(action='"peel_whole"', show_potato_holder="false",
                              show_whole_peel_strip="false")
        for t in (0, .5, 1):
            self.assert_evaluates(source=f"""
use <{SCENE / 'actions/peel_whole.scad'}>
whole_remaining_skin({t});
""")
            geometry = (self.directory / "check.csg").read_text()
            if t == 1:
                self.assertNotIn("sphere(", geometry, "Final skin must be empty")
            else:
                self.assertIn("sphere(", geometry)

    def test_whole_potato_and_holder_are_stationary(self):
        flesh_transforms = []
        holder_geometry = []
        for time in (0, .1, .33, .53, .8, 1):
            self.assert_evaluates(source=f"""
use <{SCENE / 'actions/peel_whole.scad'}>
whole_potato({time});
""")
            geometry = (self.directory / "check.csg").read_text()
            # The first sphere is the flesh: include every ancestor transform,
            # so moving the entire potato would also fail this comparison.
            self.assertIn("sphere(", geometry)
            flesh_transforms.append(geometry.split("sphere(", 1)[0])
            self.assert_evaluates(source=f"""
use <{SCENE / 'actions/peel_whole.scad'}>
$t={time};
whole_holder();
""")
            holder_geometry.append((self.directory / "check.csg").read_text())
        self.assertTrue(all(p == flesh_transforms[0] for p in flesh_transforms))
        self.assertTrue(all(p == holder_geometry[0] for p in holder_geometry))

    def test_whole_peel_coverage_motion_and_contact(self):
        self.assert_evaluates(source=f"""
use <{SCENE / 'actions/peel_whole.scad'}>
use <{SCENE / 'actions/peel.scad'}>
use <{SCENE / 'model/hand.scad'}>
use <{SCENE / 'model/kinematics.scad'}>
use <{SCENE / 'model/mounted_arm.scad'}>
use <{SCENE / 'model/workspace.scad'}>
assert(norm(hand_wrist_point([-27,36,120],[0,0,0])-[-27,36,120])<0.000001);
assert(norm(hand_wrist_point([-27,36,120],[90,0,0])-[-27,82,-2])<0.000001);

assert(norm(rest_wrist()+whole_center()-[0,180,548])<0.000001);
for(bands=[8,16,24],i=[0:bands*40]) {{
    t=i/(bands*40);
    wrist=rest_wrist()+whole_wrist_offset(t,bands);
    assert(inside_workspace(wrist,whole_workspace_min(),whole_workspace_max()),
           str("Whole peel wrist outside envelope: ",wrist));
    assert(norm(wrist-arm_shoulder())<arm_upper_length()+arm_lower_length()-2);
    assert(norm(wrist-arm_shoulder())>abs(arm_upper_length()-arm_lower_length())+2);
    // The actual three-axis wrist rotation must preserve the authored grip target.
    contact=wrist-rest_wrist()+rotate_point(
        hand_wrist_point(skin_point(0),whole_wrist_angles(t,bands)),whole_hand_angles(t,bands));
    assert(norm(contact-whole_handle_point(t,bands))<0.000001);
    // Palm stays on the outward side as the hand visits the back and both ends.
    assert(norm(rotate_point([1,0,0],whole_hand_angles(t,bands))-whole_normal(t,bands))<0.000001);
    surface=whole_contact(t,bands)-whole_center();
    assert(abs(pow(surface.x/34,2)+pow(surface.y/30,2)+pow(surface.z/43,2)-1)<0.000001);
    if(whole_cut(t,bands)>0 && whole_cut(t,bands)<1) {{
        assert(whole_clearance(t,bands)<0.000001,"Tool cutting while retracted");
        assert(whole_grip(t,bands)>0.999999,"Tool cutting with open fingers");
        assert(abs(whole_latitude(t,bands)-whole_band_latitude(t,bands))<0.000001);
    }}
    assert(abs(norm(whole_strip_direction(t,bands))-1)<0.000001);
    assert(whole_strip_direction(t,bands)*whole_normal(t,bands)>0,"Ribbon enters potato");
}}
// Both poles and all sampled surface directions are eventually peeled.
for(lat=[-90:5:90],lon=[0:15:360]) {{
    assert(!whole_surface_peeled(0,lat,lon));
    assert(whole_surface_peeled(1,lat,lon));
    for(i=[0:63]) assert(!whole_surface_peeled(i/64,lat,lon) ||
                         whole_surface_peeled((i+1)/64,lat,lon),"Skin restored between passes");
}}
// Indexing is continuous at pass boundaries; no hand or potato teleport.
for(band=[1:15]) {{
    t=band/16;
    assert(norm(whole_wrist_offset(t)-whole_wrist_offset(t-0.0000001))<0.01);
    assert(norm(whole_contact(t)-whole_contact(t-0.0000001))<0.01);
    assert(abs(whole_longitude(t)-whole_longitude(t-0.0000001))<0.01);
}}
assert(abs(whole_longitude(1)-whole_longitude(0)-16*360)<0.000001);
assert(whole_latitude(0)<-80 && whole_latitude(1)>80,"Hand never reaches the poles");
assert(norm(whole_wrist_angles(0.3))>1,"Wrist joints never move");
""")

    def test_peel_and_reach_invariants(self):
        self.assert_evaluates(source=f"""
use <{SCENE / 'actions/peel.scad'}>
use <{SCENE / 'actions/arm_reach.scad'}>
use <{SCENE / 'model/mounted_arm.scad'}>
use <{SCENE / 'model/workspace.scad'}>

// Independent dense arc integration bounds the length approximation error.
function arc_sum(n,i=0,s=0)=i==n ? s :
    arc_sum(n,i+1,s+norm(skin_point((i+1)/n)-skin_point(i/n)));
assert(abs(arc_sum(1024)-skin_length())<0.001);
assert(norm(skin_point(0)-[-27,36,120])<0.000001);

for(length=[0,1,25,50,53,skin_length()],angle=[0,25,80],i=[0:40]) {{
    t=i/40;
    s=length*peel_progress(t);
    u=skin_u(s);
    root=skin_point(u);
    tip=peel_strip_tip(t,length,angle);
    wrist=rest_wrist()+peel_offset(t,length,angle);
    assert(abs(norm(tip-root)-s)<0.000001,"Strip length changed");
    assert(abs((tip-root)*skin_normal(u))<0.000001,"Strip leaves tangent plane");
    assert(inside_workspace(wrist),str("Peel wrist outside box: ",wrist));
    assert(norm(wrist-arm_shoulder())<arm_upper_length()+arm_lower_length()-2);
    assert(norm(wrist-arm_shoulder())>abs(arm_upper_length()-arm_lower_length())+2);
    // While held, the authored pinch point and strip tip coincide.
    if(t<=0.65) assert(norm(tip-(skin_point(0)+peel_offset(t,length,angle)))<0.000001);
    if(t>=0.65) assert(abs(s-length)<0.000001,"Skin reattached during return");
}}
assert(norm(peel_offset(1))<0.000001,"Wrist failed to return");
assert(peel_pinch(1)==0 && peel_progress(1)==1);
assert(norm(peel_strip_tip(1)-peel_strip_tip(0.9))<0.000001,"Released strip follows wrist");
assert(norm(peel_strip_tip(1)-(skin_point(0)+peel_offset(1)))>1);
for(i=[0:100]) {{
    wrist=rest_wrist()+arm_reach_offset(i/100);
    assert(inside_workspace(wrist));
    assert(norm(wrist-arm_shoulder())<arm_upper_length()+arm_lower_length()-2);
}}
""")


if __name__ == "__main__":
    unittest.main()
