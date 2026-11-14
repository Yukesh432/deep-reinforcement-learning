use <../model/mounted_arm.scad>
use <../model/hand.scad>
use <../model/workspace.scad>
use <common.scad>
use <open_close.scad>

// Sweep forward and sideways, close the fingers, then retract and release.
function reach_amount(t)=smooth01(t/0.42)*(1-smooth01((t-0.56)/0.44));
function reach_grip(t)=smooth01((t-0.22)/0.28)*(1-smooth01((t-0.74)/0.26));
function arm_reach_offset(t) = [50,87,75]*reach_amount(t);
module action_arm_reach(t=0,show_arm=true,
                        workspace_lo=workspace_min(),workspace_hi=workspace_max(),reach_margin=2) {
    reach=reach_amount(t);
    wrist=rest_wrist()+arm_reach_offset(t);
    // open_close_pose closes over the first half of its periodic cycle.
    pose=open_close_pose(reach_grip(t)/2);
    if (show_arm) mounted_arm(wrist,24*reach,50*reach,workspace_lo,workspace_hi,reach_margin)
        bionic_hand(pose);
    else bionic_hand(pose);
}
$fn=24;
action_arm_reach($t);
