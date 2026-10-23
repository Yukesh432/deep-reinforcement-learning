use <../model/hand.scad>
use <common.scad>

// Authored visual pose. These angles do NOT adapt to changes in object size.
// Edit the four finger arrays to tune closure; edit thumb separately.
function cylinder_grasp_pose(t)=let(g=cycle(t)) pack_pose(
    [-5,40*g,85*g,55*g], [-1,45*g,85*g,55*g],
    [3,43*g,85*g,55*g], [9,30*g,85*g,50*g],
    [-75*g,0,100*g,-30*g], [0,0,0]);

module action_cylinder_grasp(t=0,show_object=true,
    object_position=[0,26,110],object_radius=15,object_length=100) {
    assert(object_radius>0 && object_length>0,"Object dimensions must be positive");
    bionic_hand(cylinder_grasp_pose(t));
    if(show_object) color([1,0.5,0,0.55])
        translate(object_position) rotate([0,90,0])
            cylinder(h=object_length,r=object_radius,center=true,$fn=48);
}
$fn=24;
action_cylinder_grasp($t);
