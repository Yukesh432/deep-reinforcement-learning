// OPEN THIS FILE. Keep the actions/ and model/ folders beside it.
// View > Animate (or Window > Animate): FPS=24, Steps=960 for peel_whole; 240 otherwise.
// For joint_test with all joints, use Steps=690.
// For peel_whole, use Steps=960 (60 frames per band at the default 16 bands).
// Pure visual animation: no contact forces, friction, adhesion, or joint stops.
use <model/mounted_arm.scad>
use <model/workspace.scad>
use <actions/common.scad>
use <actions/arm_reach.scad>
use <actions/joint_test.scad>
use <actions/open_close.scad>
use <actions/cylinder_grasp.scad>
use <actions/pinch.scad>
use <actions/peel.scad>
use <actions/peel_whole.scad>
use <actions/wave.scad>
use <actions/manual.scad>

/* [Choose action] */
action = "arm_reach"; // [peel_whole,arm_reach,joint_test,open_close,cylinder_grasp,pinch,peel,wave,manual]
show_arm = true;
animate = true;
// Uncheck animate to inspect the action at a fixed time.
pose_time = 0.5; // [0:0.01:1]
show_object = true;
quality = 24; // [12:4:48]

/* [Wrist workspace in world millimeters] */
show_workspace = true;
fill_workspace = true;
workspace_lower = [-55,145,385];
workspace_upper = [55,285,477];
// Clearance from both full extension and full folding; validates the entire box.
reach_margin = 2; // [0:1:20]

/* [Joint test] */
// -1 cycles through all. 0..22 selects one joint rotation.
selected_joint = -1; // [-1:1:22]

/* [Cylinder] */
cylinder_position = [0,26,110];
cylinder_radius = 15; // [5:1:40]
cylinder_length = 100; // [30:1:150]

/* [Peel motion] */
// Surface length removed; the wrist follows the free end of this strip.
peel_length = 50; // [0:1:53]
// Strip angle above the potato's surface tangent, in degrees.
peel_lift_angle = 25; // [0:1:80]

/* [Whole potato peeling] */
// Hand travels once around each band of the stationary potato.
whole_peel_bands = 16; // [8:1:24]
show_potato_holder = true;
show_whole_peel_strip = true;
// Larger wrist envelope for reaching every side of the fixed potato.
whole_workspace_lower = [-155,25,385];
whole_workspace_upper = [155,335,645];

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
active_workspace_lower=action=="peel_whole" ? whole_workspace_lower : workspace_lower;
active_workspace_upper=action=="peel_whole" ? whole_workspace_upper : workspace_upper;
if(show_arm) {
    validate_workspace(lo=active_workspace_lower,hi=active_workspace_upper,
                       shoulder=arm_shoulder(),upper=arm_upper_length(),lower=arm_lower_length(),
                       margin=reach_margin,require_full_box=action!="peel_whole");
    if(show_workspace)
        workspace_volume(lo=active_workspace_lower,hi=active_workspace_upper,filled=fill_workspace);
}

// Free reaches carry the hand with the forearm; prop actions keep world alignment.
free_motion = action=="open_close" || action=="wave";
reach_offset = action=="open_close" ? [0,35,40]*cycle(t) :
               action=="wave" ? [10*sin(360*t),15*cycle(t),15*cycle(t)] : [0,0,0];
swivel = action=="wave" ? 18*sin(360*t) :
         action=="open_close" ? 24*cycle(t) :
         action=="pinch" || action=="cylinder_grasp" ? 12*cycle(t) : 0;
roll = action=="wave" ? 25*sin(360*t) : action=="open_close" ? 35*cycle(t) : 0;

if(action=="peel_whole")
    action_peel_whole(t=t,show_arm=show_arm,show_object=show_object,bands=whole_peel_bands,
                     show_holder=show_potato_holder,show_strip=show_whole_peel_strip,
                     workspace_lo=active_workspace_lower,workspace_hi=active_workspace_upper,
                     reach_margin=reach_margin);
else if(action=="arm_reach")
    action_arm_reach(t,show_arm,workspace_lower,workspace_upper,reach_margin);
else if(action=="peel") {
    validate_peel(peel_length,peel_lift_angle);
    if(show_arm) {
        mounted_arm(rest_wrist()+peel_offset(t,peel_length,peel_lift_angle),
                    10*peel_progress(t),0,workspace_lower,workspace_upper,reach_margin,
                    world_aligned=true) peel_hand(t);
        // Prop frame stays fixed while the wrist and released strip move independently.
        if(show_object) translate(rest_wrist()) peel_object(t,peel_length,peel_lift_angle);
    } else action_peel(t,show_object,peel_length,peel_lift_angle);
} else if(show_arm)
    mounted_arm(rest_wrist()+reach_offset,swivel,roll,workspace_lower,workspace_upper,
                reach_margin,world_aligned=!free_motion) hand_action();
else hand_action();

module hand_action() {
    if(action=="joint_test") action_joint_test(t,selected_joint);
    else if(action=="open_close") action_open_close(t);
    else if(action=="cylinder_grasp")
        action_cylinder_grasp(t,show_object,cylinder_position,cylinder_radius,cylinder_length);
    else if(action=="pinch") action_pinch(t,show_object);
    else if(action=="wave") action_wave(t);
    else if(action=="manual")
        action_manual(index_angles,middle_angles,ring_angles,little_angles,thumb_angles,wrist_angles);
    else assert(false,str("Unknown action: ",action));
}
