use <../model/hand.scad>
use <common.scad>
module action_manual(index=[0,0,0,0],middle=[0,0,0,0],ring=[0,0,0,0],
    little=[0,0,0,0],thumb=[0,0,0,0],wrist=[0,0,0]) {
    assert(len(index)==4 && len(middle)==4 && len(ring)==4 && len(little)==4 &&
           len(thumb)==4 && len(wrist)==3,"Invalid angle vector length");
    bionic_hand(pack_pose(index,middle,ring,little,thumb,wrist));
}
$fn=24;
action_manual();
