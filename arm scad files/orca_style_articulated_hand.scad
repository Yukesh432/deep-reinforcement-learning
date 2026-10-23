// ORCA-inspired articulated display hand; not official ORCA hardware CAD.
// Self-contained: no STL imports or external libraries required.
// Preview animation, not a physics simulation or print-in-place mechanism.
// Open this file directly, press F5, then View > Animate (or Window > Animate).
// Set FPS=24, Steps=690 for a complete sequential cycle of 23 rotation controls.
// For synchronized movement, set motion_mode="together", Steps=120.
// STL export captures only the current pose and cannot retain animation.

/* [Orientation] */
stand_upright = true;

/* [Animation] */
animate_motion = false;
motion_mode = "sequential"; // [sequential,together]
show_active_joint = true;
$fn = 24;

/* [Manual finger angles - used when animate_motion is false] */
// Each vector is [spread, base bend (MCP), middle bend (PIP), tip bend (DIP)].

// Opens and closes the hand repeatedly
grip = (1 - cos(180 * $t)) / 2;


thumb_angles = [0, 35*grip, 35*grip, 25*grip];
wrist_angles = [0, 0, 0];

index_angles  = [-5, 40*grip, 85*grip, 55*grip];
middle_angles = [-1, 45*grip, 85*grip, 55*grip];
ring_angles   = [ 3, 43*grip, 85*grip, 55*grip];
little_angles = [ 9, 30*grip, 85*grip, 50*grip];

/* [Hidden] */
body_color = [0.78,0.82,0.88];
joint_color = [0.17,0.20,0.26];
accent_color = [0.38,0.24,0.92];
active_color = [1,0.55,0.12];
joint_count = 23;
phase = ($t-floor($t))*joint_count;
active_joint = min(joint_count-1,floor(phase));
joint_names = [
 "Index spread", "Index base bend", "Index middle bend", "Index tip bend",
 "Middle spread", "Middle base bend", "Middle middle bend", "Middle tip bend",
 "Ring spread", "Ring base bend", "Ring middle bend", "Ring tip bend",
 "Little spread", "Little base bend", "Little middle bend", "Little tip bend",
 "Thumb spread", "Thumb opposition", "Thumb base bend", "Thumb tip bend",
 "Wrist bend", "Wrist side-to-side", "Wrist axial rotation"
];

// Smooth out-and-back motion; every sequential interval begins and ends at rest.
function pulse(t) = (1-cos(360*t))/2;
function angle(id,manual,amplitude) = !animate_motion ? manual :
    motion_mode == "together" ? amplitude*pulse($t) :
    id == active_joint ? amplitude*pulse(phase-active_joint) : 0;
function selected(ids) = animate_motion && show_active_joint &&
    motion_mode == "sequential" && len(search(active_joint,ids)) > 0;

assert(motion_mode == "sequential" || motion_mode == "together", "Unknown motion mode");
assert(len(index_angles)==4 && len(middle_angles)==4 &&
       len(ring_angles)==4 && len(little_angles)==4 &&
       len(thumb_angles)==4 && len(wrist_angles)==3, "Incorrect angle vector length");

if(animate_motion && show_active_joint && motion_mode=="sequential")
    echo(active_joint=active_joint, moving=joint_names[active_joint]);

// Map the finger direction (+Y) to vertical (+Z), with the wrist base at Z=0.
// This fixed outer transform preserves every local joint pivot and animation.
translate(stand_upright ? [0,13,44] : [0,0,0])
rotate(stand_upright ? [90,0,0] : [0,0,0]) {
    // Fixed wrist mounting block.
    color(joint_color) rounded_block([-23,-44,0],[46,32,26],5);
    color(accent_color) rounded_block([-13,-35,25],[26,17,4],3);

    // Entire hand inherits these three wrist rotations.
    translate([0,-8,15]) {
        joint_ball(12,[20,21,22]);
        rotate([-angle(20,wrist_angles[0],25),
                angle(22,wrist_angles[2],35),
                angle(21,wrist_angles[1],18)])
            translate([0,8,-15]) hand();
    }
}

module hand() {
    color(body_color) hull() {
        rounded_block([-20,-4,3],[40,20,25],5);
        rounded_block([-36,35,3],[72,34,25],7);
    }
    color(accent_color) rounded_block([-24,18,26],[48,40,4],5);
    finger(-27,70,70,15,5,index_angles,0);
    finger(-9,72,80,16,1,middle_angles,4);
    finger(10,71,74,15,-3,ring_angles,8);
    finger(28,68,57,13,-9,little_angles,12);
    thumb();
}

// Nested transforms keep every distal segment attached to its parent joint.
module finger(x,y,len,w,rest_spread,q,id) {
    l1=len*0.43; l2=len*0.33; l3=len*0.24;
    translate([x,y,15]) {
        joint_ball(w*0.52,[id,id+1]);
        rotate([0,0,rest_spread+angle(id,q[0],10)])
        rotate([-angle(id+1,q[1],55),0,0]) {
            phalanx(l1,w);
            translate([0,l1,0]) {
                joint_ball(w*0.46,[id+2]);
                rotate([-angle(id+2,q[2],65),0,0]) {
                    phalanx(l2,w*0.88);
                    translate([0,l2,0]) {
                        joint_ball(w*0.39,[id+3]);
                        rotate([-angle(id+3,q[3],40),0,0])
                            phalanx(l3,w*0.75);
                    }
                }
            }
        }
    }
}

module thumb() {
    translate([-29,25,15]) {
        joint_ball(10,[16,17]);
        rotate([0,0,36+angle(16,thumb_angles[0],15)])
        rotate([0,angle(17,thumb_angles[1],35),0]) {
            phalanx(26,19);
            translate([0,26,0]) {
                joint_ball(8.5,[18]);
                rotate([-angle(18,thumb_angles[2],40),0,0]) {
                    phalanx(25,17);
                    translate([0,25,0]) {
                        joint_ball(7,[19]);
                        rotate([-angle(19,thumb_angles[3],50),0,0])
                            phalanx(21,14);
                    }
                }
            }
        }
    }
}

module joint_ball(r,ids) {
    color(selected(ids) ? active_color : joint_color) sphere(r=r);
}

module phalanx(len,w) {
    // Local origin is the proximal pivot; next pivot is at [0,len,0].
    color(body_color) hull() {
        translate([0,w*0.33,0]) scale([1,1,0.8]) sphere(r=w*0.46);
        translate([0,len-w*0.28,0]) scale([1,1,0.8]) sphere(r=w*0.38);
    }
    color(accent_color)
        rounded_block([-w*0.29,len*0.22,w*0.26],
                      [w*0.58,len*0.46,2.5],1.2);
}

module rounded_block(p,size,r=3) {
    translate(p) hull()
        for(x=[r,size[0]-r]) for(y=[r,size[1]-r])
            translate([x,y,0]) cylinder(h=size[2],r=r);
}
// Cylinder across the palm, positioned lower
color([1, 0.5, 0, 0.6])
translate([0, 26, 110])
rotate([0, 90, 0])
    cylinder(h=100, r=15, center=true, $fn=64);