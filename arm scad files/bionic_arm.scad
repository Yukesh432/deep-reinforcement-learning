// Human-like bionic arm (right arm hangs along -Z, palm faces +X, thumb on -Y)
// Shoulder 3 DOF, elbow 1 DOF, forearm pronation, wrist 2 DOF, 5-finger hand
$fn=32;

// ---- Variations ----
hand_style=0;   // 0 = 5-finger hand, 1 = 3-finger gripper (thumb, index, middle)
link_style=0;   // 0 = tapered round limbs, 1 = flat plate limbs
scale_f=1;      // 1 = human size in mm, 0.2 = desk model

// ---- Proportions (mm) ----
shoulder_d=60;
upper_len=300; upper_d=70;
fore_len=250;  fore_d=55;
palm_len=90; palm_w=80; palm_t=25;
finger_len=[75,85,80,65];   // index, middle, ring, pinky
finger_w=16;
thumb_len=60;

// ---- Joint angles (degrees), animate with $t ----
shoulder_flex = 40*sin(360*$t);        // arm forward/back
shoulder_abd  = 20*(1+sin(360*$t))/2;  // arm out to side
shoulder_rot  = 30*sin(360*$t);        // upper arm twist
elbow_flex    = 70*(1+sin(360*$t))/2;  // 0 = straight
pronation     = 60*sin(360*$t);        // forearm twist
wrist_flex    = 30*sin(2*360*$t);
wrist_dev     = 15*sin(360*$t);
curl          = 70*(1+sin(2*360*$t))/2;

scale(scale_f) arm();

module arm(){
    // torso mount
    translate([-20,-60,40]) cube([20,120,160]);
    // shoulder joint
    translate([0,-shoulder_d/2-10,0]) shoulder();
}

module limb(len,d){
    if(link_style==0)
        translate([0,0,-len]) cylinder(h=len,d1=d*0.7,d2=d);
    else
        translate([-5,-d/2,-len]) cube([10,d,len]);
}

module ball(d){ sphere(d=d); }

module shoulder(){
    ball(shoulder_d);
    rotate([-shoulder_abd,0,0])
    rotate([0,-shoulder_flex,0])
    rotate([0,0,shoulder_rot]){
        translate([0,0,-shoulder_d/4]) limb(upper_len,upper_d);
        translate([0,0,-upper_len]) elbow();
    }
}

module elbow(){
    ball(upper_d*0.8);
    rotate([0,-elbow_flex,0]){
        rotate([0,0,pronation]){
            limb(fore_len,fore_d);
            translate([0,0,-fore_len]) wrist();
        }
    }
}

module wrist(){
    ball(fore_d*0.7);
    rotate([-wrist_dev,0,0])
    rotate([0,-wrist_flex,0])
    hand();
}

module hand(){
    // palm
    translate([-palm_t/2,-palm_w/2,-palm_len]) cube([palm_t,palm_w,palm_len]);
    // fingers (y from index side +Y to pinky side -Y; thumb is on -Y)
    ys=[palm_w*0.375, palm_w*0.125, -palm_w*0.125, -palm_w*0.375];
    for(i=[0:3]){
        if(hand_style==0 || i<2)
            translate([0,ys[i],-palm_len]) finger(finger_len[i],finger_w,curl);
    }
    // thumb
    translate([palm_t/2,-palm_w/2,-palm_len*0.35])
    rotate([0,-40,0])
    finger(thumb_len,finger_w*1.1,curl*0.7);
}

module seg(l,w){
    ball(w);
    translate([0,0,-l]) cylinder(h=l,d1=w*0.9,d2=w*0.8);
}

module finger(len,w,c){
    p=[0.5,0.3,0.2]*len;   // three phalanges
    rotate([0,-c,0]) {
        seg(p[0],w);
        translate([0,0,-p[0]]) rotate([0,-c*0.9,0]) {
            seg(p[1],w*0.9);
            translate([0,0,-p[1]]) rotate([0,-c*0.6,0]) seg(p[2],w*0.8);
        }
    }
}
