// OPEN THIS FILE. Keep the actions/ and model/ folders beside it.
// View > Animate (or Window > Animate): FPS=24, Steps=240.
// For joint_test with all joints, use Steps=690.
// Pure visual animation: no contact forces, friction, adhesion, or joint stops.
use <actions/joint_test.scad>
use <actions/open_close.scad>
use <actions/cylinder_grasp.scad>
use <actions/pinch.scad>
use <actions/peel.scad>
use <actions/wave.scad>
use <actions/manual.scad>

/* [Choose action] */
action = "joint_test"; // [joint_test,open_close,cylinder_grasp,pinch,peel,wave,manual]
animate = true;
// Uncheck animate to inspect the action at a fixed time.
pose_time = 0.5; // [0:0.01:1]
show_object = true;
quality = 24; // [12:4:48]

/* [Joint test] */
// -1 cycles through all. 0..22 selects one joint rotation.
selected_joint = -1; // [-1:1:22]

/* [Cylinder] */
cylinder_position = [0,26,110];
cylinder_radius = 15; // [5:1:40]
cylinder_length = 100; // [30:1:150]

/* [Peel motion] */
pull_distance = 50; // [0:1:100]
lift_distance = 25; // [0:1:80]

/* [Manual pose] */
// Finger order: spread, base bend, middle bend, tip bend. Degrees.
index_angles = [0,0,0,0];
middle_angles = [0,0,0,0];
ring_angles = [0,0,0,0];
little_angles = [0,0,0,0];
// Thumb: spread, opposition, base bend, tip bend.
thumb_angles = [0,0,0,0];
// Wrist: bend, side-to-side, axial rotation.
wrist_angles = [0,0,0];

/* [Hidden] */
$fn=quality;
t=animate ? $t : pose_time;
assert(t>=0 && t<=1,"Time must be between 0 and 1");
if(action=="joint_test") action_joint_test(t,selected_joint);
else if(action=="open_close") action_open_close(t);
else if(action=="cylinder_grasp")
    action_cylinder_grasp(t,show_object,cylinder_position,cylinder_radius,cylinder_length);
else if(action=="pinch") action_pinch(t,show_object);
else if(action=="peel") action_peel(t,show_object,pull_distance,lift_distance);
else if(action=="wave") action_wave(t);
else if(action=="manual")
    action_manual(index_angles,middle_angles,ring_angles,little_angles,thumb_angles,wrist_angles);
else assert(false,str("Unknown action: ",action));
