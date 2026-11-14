use <../model/hand.scad>
use <common.scad>

function open_close_pose(t)=let(g=cycle(t)) pack_pose(
    [-7*g,55*g,75*g,45*g], [-2*g,55*g,75*g,45*g],
    [3*g,55*g,75*g,45*g], [8*g,60*g,75*g,45*g],
    [-45*g,25*g,40*g,30*g], [12*g,7*g,-10*g]);
module action_open_close(t=0) { bionic_hand(open_close_pose(t)); }
$fn=24;
action_open_close($t);
