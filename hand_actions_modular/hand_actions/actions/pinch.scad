use <../model/hand.scad>
use <common.scad>

// Near-contact pose for this model; visual fitting, not force closure.
function pinch_pose(amount)=let(g=clamp01(amount)) pack_pose(
    [-5,26.8*g,77.3*g,51.2*g],
    [0,15,20,10], [0,20,25,15], [0,25,30,15],
    [-56.9*g,26.3*g,40*g,41.3*g], [0,0,0]);

module action_pinch(t=0,show_object=true) {
    bionic_hand(pinch_pose(cycle(t)));
    if(show_object) color([1,0.5,0,0.6])
        translate([-27,36,120]) cube([10,2,14],center=true);
}
$fn=24;
action_pinch($t);
