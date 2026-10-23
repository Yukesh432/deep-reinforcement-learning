use <../model/hand.scad>
use <common.scad>

// joint=-1 cycles through all 23 controls. 0..22 tests only that control.
function joint_test_pose(t,joint=-1)=
    let(phase=clamp01(t)*23,
        selected=joint<0 ? min(22,floor(phase)) : joint,
        u=joint<0 ? phase-selected : clamp01(t),
        amplitudes=[10,55,65,40, 10,55,65,40, 10,55,65,40, 10,55,65,40,
                    15,35,40,50, 25,18,35])
    [for(i=[0:22]) i==selected ? amplitudes[i]*cycle(u) : 0];

module action_joint_test(t=0,joint=-1) {
    assert(joint>=-1 && joint<=22 && floor(joint)==joint,"Joint must be -1 or 0..22");
    selected=joint<0 ? min(22,floor(clamp01(t)*23)) : joint;
    bionic_hand(joint_test_pose(t,joint),highlighted=selected);
}
$fn=24;
action_joint_test($t);
