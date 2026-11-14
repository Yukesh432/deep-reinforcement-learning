// Reuse the reference stand, limb shells and elbow hinge at their native scale.
use <../../../arm scad files/openai_human_bionic_arm.scad>

use <workspace.scad>

function rest_wrist() = [0,185,385];
function arm_upper_length() = 180;
function arm_lower_length() = 155;
function arm_shoulder() = [0,0,548];

// The modular hand actions use an upright frame at the wrist socket.
// Solve the shoulder and elbow in the target azimuth plane so the original hand paths
// and object placements can be reused, including the translating peel action.
// Swivel the bending plane about the shoulder-to-wrist line. This permits
// shoulder rotation even while a grasp target holds the socket in place.
module mounted_arm(wrist, swivel=0, roll=0,
                   workspace_lo=workspace_min(),workspace_hi=workspace_max(),
                   reach_margin=2,world_aligned=false) {
    upper = arm_upper_length();
    lower = arm_lower_length();
    shoulder = arm_shoulder(); // Reference stand's shoulder_height at default scale.
    delta = wrist - shoulder;
    reach = norm(delta);
    assert(inside_workspace(wrist,workspace_lo,workspace_hi),
           str("Wrist outside operating workspace: ", wrist));
    assert(reach_margin>=0 && reach > abs(upper-lower)+reach_margin &&
           reach < upper+lower-reach_margin,"Wrist target violates the arm reach margin");
    elbow = acos(max(-1,min(1,(reach*reach-upper*upper-lower*lower)/(2*upper*lower))));
    yaw = -atan2(delta.x,delta.y);
    pitch = atan2(norm([delta.x,delta.y]),-delta.z) - atan2(lower*sin(elbow),upper+lower*cos(elbow));

    display_stand();
    translate(shoulder) {
        color([0.10,0.12,0.16]) sphere(d=52);
        rotate(a=swivel,v=delta) rotate([0,0,yaw]) rotate([180+pitch,0,0]) {
            limb(upper,58,58*0.68);
            translate([0,0,upper]) {
                hinge(58*0.78,58*0.53);
                rotate([elbow,0,0]) rotate([0,0,roll]) {
                    limb(lower,49,49*0.61);
                    translate([0,0,lower]) color([0.25,0.29,0.35]) sphere(d=25);
                    // Preserve the original upright rest pose. Subsequent changes in
                    // elbow pitch, swivel and forearm roll carry the hand with them.
                    if(!world_aligned)
                      translate([0,0,lower]) rotate([-neutral_forearm_pitch(),0,0])
                        children();
                }
            }
        }
    }
    // Contact tasks compensate forearm rotation to hold the authored world
    // orientation. Free reaches inherit the forearm's transform above.
    if(world_aligned) translate(wrist) children();
}


// Absolute orientation of the forearm at the start of the open/close loop.
function neutral_forearm_pitch() =
    let(delta=rest_wrist()-arm_shoulder(), upper=arm_upper_length(), lower=arm_lower_length(),
        elbow=acos((norm(delta)*norm(delta)-upper*upper-lower*lower)/(2*upper*lower)))
    180 + atan2(delta.y,-delta.z)
        - atan2(lower*sin(elbow), upper+lower*cos(elbow)) + elbow;
