use <../model/hand.scad>
use <common.scad>
use <pinch.scad>

// 0-.20 pinch; .20-.65 pull; .65-.80 release; .80-1 return.
function peel_pinch(t)=smooth01(t/0.20)*(1-smooth01((t-0.65)/0.15));
function peel_pull(t)=smooth01((t-0.20)/0.45)*(1-smooth01((t-0.80)/0.20));
function peel_offset(t,pull_distance=50,lift_distance=25)=
    [0,pull_distance*peel_pull(t),lift_distance*peel_pull(t)];

module action_peel(t=0,show_object=true,pull_distance=50,lift_distance=25) {
    // Whole wrist base moves too: this represents an unmodeled arm carrying it.
    translate(peel_offset(t,pull_distance,lift_distance))
        bionic_hand(pinch_pose(peel_pinch(t)));
    if(show_object) {
        // Stationary support and a schematic ribbon; no adhesion physics.
        color([0.45,0.50,0.58]) translate([-27,64,114])
            cube([30,68,8],center=true);
        // After release the ribbon remains lifted, then resets with the loop.
        held=t<0.65 ? smooth01((t-0.20)/0.45) :
             t<0.80 ? 1 : 1-smooth01((t-0.80)/0.20);
        tip=[-27,36+pull_distance*held,120+lift_distance*held];
        bend=[-27,64+pull_distance*held*0.25,120+lift_distance*held*0.6];
        color([0.1,0.75,0.65]) {
            ribbon_section([-27,90,120],bend);
            ribbon_section(bend,tip);
        }
    }
}
module ribbon_section(a,b) {
    hull() { translate(a) cube([10,0.8,0.8],center=true);
             translate(b) cube([10,0.8,0.8],center=true); }
}
$fn=24;
action_peel($t);
