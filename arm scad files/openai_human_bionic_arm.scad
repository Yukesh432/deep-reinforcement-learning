// HUMAN-LIKE BIONIC ARM -- replacement for the bracket-based robot generator
// Units: mm. Visual / kinematic concept, not a fabrication-ready prosthesis.
// Seven arm DOF: shoulder yaw/pitch/roll, elbow flexion,
// forearm rotation, wrist flexion/deviation. Finger joints are additional.
// F5 = preview. View > Animate: FPS 24, Steps 120; set animate_motion=true.

/* [Appearance] */
style = "hybrid"; // [anatomical,skeletal,armored,hybrid]
side = "right"; // [right,left]
show_base = true;
model_scale = 1; // [0.25:0.05:2]
$fn = 36;

/* [Proportions in mm] */
arm_length = 180;
arm_width = 58;
forearm_length = 155;
forearm_width = 49;
hand_length = 70;
hand_width = 64;
hand_depth = 23;
finger_lengths = [68, 78, 72, 56]; // index, middle, ring, little
thumb_length = 51;
hole = 5; // visible joint axle bore diameter
base_width = 150;
thick = 8;

/* [Pose in degrees] */
shoulder_yaw = 0;
arm_pitch = 12;
shoulder_roll = 0;
elbow_flex = 48;
forearm_roll = -15;
hand_pitch = 0;
wrist_deviation = 0;
finger_pitch = 12; // base joint curl; distal joints follow
finger_spread = 5;
thumb_opposition = 35;
thumb_pitch = 15;

/* [Motion] */
animate_motion = true;

/* [Hidden] */
shell_color = style == "anatomical" ? [0.76,0.79,0.83] : [0.88,0.91,0.94];
metal_color = [0.25,0.29,0.35];
joint_color = [0.10,0.12,0.16];
accent_color = [0.38,0.24,0.92];
cycle = (1-cos(360*$t))/2;
elbow_angle = animate_motion ? 20+65*cycle : elbow_flex;
curl_angle = animate_motion ? 55*cycle : finger_pitch;
thumb_angle = animate_motion ? 8+30*cycle : thumb_pitch;
shoulder_height = arm_length+forearm_length+hand_length+max(finger_lengths)+65;

assert(arm_length > arm_width && forearm_length > forearm_width,
       "Limb lengths must exceed their widths.");
assert(hand_width > 36 && hand_length > 30 && hole > 0 && hole < 12,
       "Use hand_width>36, hand_length>30, and 0<hole<12.");
assert(style == "anatomical" || style == "skeletal" ||
       style == "armored" || style == "hybrid", "Unknown style.");
assert(side == "left" || side == "right", "Unknown side.");

scale([model_scale,model_scale,model_scale]) {
    if(show_base) display_stand();
    translate([0,0,shoulder_height]) {
        if(side == "left") mirror([1,0,0]) human_arm();
        else human_arm();
    }
}

// Each child is attached at its parent's joint origin.
// Local +Z points toward the next joint; fingers curl toward local -Y.
module human_arm() {
    color(joint_color) sphere(d=arm_width*0.90);
    rotate([180,0,0])
    rotate([0,0,shoulder_yaw])
    rotate([arm_pitch,0,0])
    rotate([0,shoulder_roll,0]) {
        if(style != "skeletal")
            color(shell_color)
            difference() {
                scale([1,0.88,0.90]) sphere(d=arm_width*1.12);
                translate([-arm_width,-arm_width,5])
                    cube([2*arm_width,2*arm_width,arm_width]);
            }
        limb(arm_length,arm_width,arm_width*0.68);
        translate([0,0,arm_length]) {
            hinge(arm_width*0.78,arm_width*0.53);
            rotate([elbow_angle,0,0]) {
                rotate([0,0,forearm_roll]) {
                    limb(forearm_length,forearm_width,forearm_width*0.61);
                    translate([0,0,forearm_length]) {
                        color(joint_color) sphere(d=forearm_width*0.63);
                        rotate([hand_pitch,0,0])
                        rotate([0,wrist_deviation,0]) hand();
                    }
                }
            }
        }
    }
}

// Tapered ellipsoid sections give a muscle-like silhouette.
module envelope(len,w0,w1) {
    hull() {
        translate([0,0,len*0.16]) scale([1,0.78,0.85]) sphere(d=w0*0.88);
        translate([0,0,len*0.39]) scale([1,0.76,1.05]) sphere(d=w0);
        translate([0,0,len*0.80]) scale([1,0.78,0.85]) sphere(d=w1);
    }
}

module limb(len,w0,w1) {
    // Exposed rods remain connected to joint centers.
    color(metal_color) {
        rod([0,0,0],[0,0,len],w1*0.23);
        for(s=[-1,1]) {
            rod([s*w0*0.20,0,len*0.12],
                [s*w1*0.20,0,len*0.86],w1*0.12);
            rod([0,0,0],[s*w0*0.20,0,len*0.12],w1*0.12);
            rod([s*w1*0.20,0,len*0.86],[0,0,len],w1*0.12);
        }
    }
    if(style == "anatomical") color(shell_color) envelope(len,w0,w1);
    if(style == "armored") {
        // Three distinct armor plates separated by visible seams.
        for(i=[0:2]) color(i==1 ? accent_color : shell_color)
            intersection() {
                envelope(len,w0,w1);
                translate([-w0,-w0,len*(0.06+i*0.29)])
                    cube([2*w0,2*w0,len*0.29-3]);
            }
    }
    if(style == "hybrid") {
        color(shell_color) difference() {
            envelope(len,w0,w1);
            // Front service window exposes the internal rods.
            translate([0,-w0*0.31,len*0.49])
                rounded_box([w0*0.49,w0*0.70,len*0.52],5);
        }
        color(accent_color)
            rod([-w0*0.31,-w0*0.22,len*0.26],
                [-w1*0.34,-w1*0.23,len*0.72],2.5);
    }
}

module hinge(width,diameter) {
    color(joint_color)
        rotate([0,90,0])
        difference() {
            cylinder(h=width,d=diameter,center=true);
            cylinder(h=width+2,d=hole,center=true);
        }
    for(s=[-1,1]) color(accent_color)
        translate([s*(width/2+1),0,0]) rotate([0,90,0])
        difference() {
            cylinder(h=3,d=diameter*0.70,center=true);
            cylinder(h=5,d=hole,center=true);
        }
}

module hand() {
    color(metal_color)
        rod([0,0,0],[0,0,hand_length-6],hand_depth*0.45);
    if(style != "skeletal") color(shell_color)
        hull() {
            translate([0,0,hand_length*0.20])
                rounded_box([hand_width*0.58,hand_depth*0.78,hand_length*0.28],5);
            translate([0,0,hand_length*0.64])
                rounded_box([hand_width,hand_depth,hand_length*0.60],6);
        }
    if(style == "armored" || style == "hybrid") color(accent_color)
        translate([0,hand_depth/2,hand_length*0.57])
            rounded_box([hand_width*0.58,3,hand_length*0.36],1.4);

    // Four fingers with separate knuckles, three phalanges, varied lengths.
    for(i=[0:3]) {
        x = (i-1.5)*hand_width*0.245;
        root_z = hand_length-(i==3 ? 6 : (i==0 ? 2 : 0));
        if(style == "skeletal") color(metal_color)
            rod([0,0,hand_length*0.20],[x,0,root_z],6);
        translate([x,0,root_z])
            rotate([0,(i-1.5)*finger_spread,0])
            finger(finger_lengths[i],hand_width*(i==3 ? 0.15 : 0.17),curl_angle);
    }

    // Two-phalange thumb; its root is below the index finger.
    if(style == "skeletal") color(metal_color)
        rod([0,0,hand_length*0.2],[-hand_width*0.43,0,hand_length*0.33],7);
    translate([-hand_width*0.43,0,hand_length*0.33])
        rotate([0,-48,0]) rotate([0,0,thumb_opposition])
        thumb(thumb_length,hand_width*0.19,thumb_angle);
}

module finger(len,w,curl) {
    a = len*0.44; b = len*0.32; c = len*0.24;
    color(joint_color) sphere(d=w*1.12);
    rotate([curl,0,0]) {
        phalanx(a,w);
        translate([0,0,a]) {
            color(joint_color) sphere(d=w*0.94);
            rotate([curl*0.75,0,0]) {
                phalanx(b,w*0.88);
                translate([0,0,b]) {
                    color(joint_color) sphere(d=w*0.80);
                    rotate([curl*0.5,0,0]) phalanx(c,w*0.75);
                }
            }
        }
    }
}

module thumb(len,w,curl) {
    color(joint_color) sphere(d=w*1.15);
    rotate([curl,0,0]) {
        phalanx(len*0.55,w);
        translate([0,0,len*0.55]) {
            color(joint_color) sphere(d=w*0.92);
            rotate([curl*0.8,0,0]) phalanx(len*0.45,w*0.85);
        }
    }
}

module phalanx(len,w) {
    color(metal_color) rod([0,0,0],[0,0,len],w*0.44);
    if(style != "skeletal") color(shell_color)
        hull() {
            translate([0,0,w*0.47]) scale([1,0.82,1]) sphere(d=w);
            translate([0,0,len-w*0.34]) scale([1,0.82,1]) sphere(d=w*0.80);
        }
}

module rod(p0,p1,d) {
    hull() {
        translate(p0) sphere(d=d);
        translate(p1) sphere(d=d);
    }
}

module rounded_box(size,r) {
    hull() for(x=[-1,1]) for(y=[-1,1]) for(z=[-1,1])
        translate([x*(size[0]/2-r),y*(size[1]/2-r),z*(size[2]/2-r)])
            sphere(r=r);
}

module display_stand() {
    // Optional museum-style support behind the arm, not part of anatomy.
    color(joint_color) translate([0,-65,thick/2])
        rounded_box([base_width,base_width,thick],thick/2-0.1);
    color(metal_color) {
        rod([0,-90,thick],[0,-90,shoulder_height],14);
        rod([0,-90,shoulder_height],[0,0,shoulder_height],14);
    }
}
