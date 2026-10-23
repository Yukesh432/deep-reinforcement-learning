use <../model/hand.scad>
use <common.scad>
function wave_pose(t)=pack_pose(
    [8,0,0,0],[3,0,0,0],[-3,0,0,0],[-8,0,0,0],
    [5,0,5,0],[0,18*sin(360*t),0]);
module action_wave(t=0) { bionic_hand(wave_pose(t)); }
$fn=24;
action_wave($t);
