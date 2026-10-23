// Reusable geometry. Millimeters and degrees. No action-specific globals.
// ORCA-inspired visual model; not official ORCA CAD or a physical mechanism.
// Pose order: 4 index + 4 middle + 4 ring + 4 little + 4 thumb + 3 wrist.
function zero_pose() = [for(i=[0:22]) 0];
function pose4(p,i) = [for(j=[0:3]) p[i+j]];

module bionic_hand(pose=zero_pose(),upright=true,highlighted=-1) {
    assert(len(pose)==23,"Pose must contain exactly 23 angles");
    translate(upright ? [0,13,44] : [0,0,0])
    rotate(upright ? [90,0,0] : [0,0,0]) {
        color([0.17,0.20,0.26]) rounded_block([-23,-44,0],[46,32,26],5);
        color([0.38,0.24,0.92]) rounded_block([-13,-35,25],[26,17,4],3);
        translate([0,-8,15]) {
            joint_ball(12,[20,21,22],highlighted);
            rotate([-pose[20],pose[22],pose[21]])
                translate([0,8,-15]) hand(pose,highlighted);
        }
    }
}

// Direct-file preview; ignored when loaded with use<>.
$fn=24;
bionic_hand();

module hand(pose,highlighted) {
    index_angles=pose4(pose,0);
    middle_angles=pose4(pose,4);
    ring_angles=pose4(pose,8);
    little_angles=pose4(pose,12);
    color([0.78,0.82,0.88]) hull() {
        rounded_block([-20,-4,3],[40,20,25],5);
        rounded_block([-36,35,3],[72,34,25],7);
    }
    color([0.38,0.24,0.92]) rounded_block([-24,18,26],[48,40,4],5);
    finger(-27,70,70,15,5,index_angles,0,highlighted);
    finger(-9,72,80,16,1,middle_angles,4,highlighted);
    finger(10,71,74,15,-3,ring_angles,8,highlighted);
    finger(28,68,57,13,-9,little_angles,12,highlighted);
    thumb(pose4(pose,16),highlighted);
}

// Nested transforms keep every distal segment attached to its parent joint.
module finger(x,y,len,w,rest_spread,q,id,highlighted) {
    l1=len*0.43; l2=len*0.33; l3=len*0.24;
    translate([x,y,15]) {
        joint_ball(w*0.52,[id,id+1],highlighted);
        rotate([0,0,rest_spread+q[0]])
        rotate([-q[1],0,0]) {
            phalanx(l1,w);
            translate([0,l1,0]) {
                joint_ball(w*0.46,[id+2],highlighted);
                rotate([-q[2],0,0]) {
                    phalanx(l2,w*0.88);
                    translate([0,l2,0]) {
                        joint_ball(w*0.39,[id+3],highlighted);
                        rotate([-q[3],0,0])
                            phalanx(l3,w*0.75);
                    }
                }
            }
        }
    }
}

module thumb(q,highlighted) {
    translate([-29,25,15]) {
        joint_ball(10,[16,17],highlighted);
        rotate([0,0,36+q[0]])
        rotate([0,q[1],0]) {
            phalanx(26,19);
            translate([0,26,0]) {
                joint_ball(8.5,[18],highlighted);
                rotate([-q[2],0,0]) {
                    phalanx(25,17);
                    translate([0,25,0]) {
                        joint_ball(7,[19],highlighted);
                        rotate([-q[3],0,0])
                            phalanx(21,14);
                    }
                }
            }
        }
    }
}

module joint_ball(r,ids,highlighted) {
    color((highlighted>=0 && len(search(highlighted,ids))>0) ? [1,0.55,0.12] : [0.17,0.20,0.26]) sphere(r=r);
}

module phalanx(len,w) {
    // Local origin is the proximal pivot; next pivot is at [0,len,0].
    color([0.78,0.82,0.88]) hull() {
        translate([0,w*0.33,0]) scale([1,1,0.8]) sphere(r=w*0.46);
        translate([0,len-w*0.28,0]) scale([1,1,0.8]) sphere(r=w*0.38);
    }
    color([0.38,0.24,0.92])
        rounded_block([-w*0.29,len*0.22,w*0.26],
                      [w*0.58,len*0.46,2.5],1.2);
}

module rounded_block(p,size,r=3) {
    translate(p) hull()
        for(x=[r,size[0]-r]) for(y=[r,size[1]-r])
            translate([x,y,0]) cylinder(h=size[2],r=r);
}
