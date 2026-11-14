use <common.scad>
use <pinch.scad>
use <peel.scad>
use <../model/hand.scad>
use <../model/kinematics.scad>
use <../model/mounted_arm.scad>
use <../model/workspace.scad>

// The potato and holder are fixed. The hand travels around each latitude band,
// retracting before moving to the next band. Both polar caps are included.
function whole_pass(t,bands=16)=min(bands-1,floor(clamp01(t)*bands));
function whole_phase(t,bands=16)=clamp01(t)*bands-whole_pass(t,bands);
function whole_cut(t,bands=16)=
    let(u=(whole_phase(t,bands)-0.16)/0.60)
    u<0.000000001 ? 0 : u>0.999999999 ? 1 : smooth01(u);
function whole_band_low(t,bands=16)=-90+180*whole_pass(t,bands)/bands;
function whole_band_high(t,bands=16)=whole_band_low(t,bands)+180/bands;
function whole_band_latitude(t,bands=16)=whole_band_low(t,bands)+90/bands;
function whole_index(t,bands=16)=smooth01((whole_phase(t,bands)-0.88)/0.12);
function whole_latitude(t,bands=16)=whole_band_latitude(t,bands)+
    (whole_pass(t,bands)<bands-1 ? 180/bands*whole_index(t,bands) : 0);
function whole_longitude(t,bands=16)=360*(whole_pass(t,bands)+whole_cut(t,bands));
// Relative to rest_wrist(): mounted world centre is always [0,180,548] mm.
function whole_center()=[0,-5,163];
function whole_clearance(t,bands=16)=
    10*(1-smooth01(whole_phase(t,bands)/0.14))+
    10*smooth01((whole_phase(t,bands)-0.78)/0.10);

function whole_surface_point(latitude,longitude)=
    let(r=potato_radii()) [r.x*cos(latitude)*cos(longitude),
                          r.y*cos(latitude)*sin(longitude),r.z*sin(latitude)];
function whole_contact(t,bands=16)=whole_center()+
    whole_surface_point(whole_latitude(t,bands),whole_longitude(t,bands));
function whole_normal(t,bands=16)=
    let(r=potato_radii(),lat=whole_latitude(t,bands),lon=whole_longitude(t,bands))
    unit_vector([cos(lat)*cos(lon)/r.x,cos(lat)*sin(lon)/r.y,sin(lat)/r.z]);
// Keep the palm on the outward side of the surface while circling the object.
// Map the hand's local +X to the surface normal; +Z follows the meridian tangent.
function whole_hand_angles(t,bands=16)=
    let(n=whole_normal(t,bands)) [0,-atan2(n.z,norm([n.x,n.y])),atan2(n.y,n.x)];
function whole_wrist_angles(t,bands=16)=
    [2*sin(360*t),sin(whole_longitude(t,bands)),2*sin(whole_longitude(t,bands))];
function whole_grip(t,bands=16)=smooth01(t*bands/0.12)*
    (1-smooth01((t*bands-(bands-0.14))/0.14));
function whole_hand_pose(t,bands=16)=
    let(pose=pinch_pose(whole_grip(t,bands)))
    concat([for(i=[0:19]) pose[i]],whole_wrist_angles(t,bands));
function whole_handle_point(t,bands=16)=
    whole_contact(t,bands)+whole_normal(t,bands)*(12+whole_clearance(t,bands));
function whole_grip_offset(t,bands=16)=rotate_point(
    hand_wrist_point(skin_point(0),whole_wrist_angles(t,bands)),whole_hand_angles(t,bands));
function whole_wrist_offset(t,bands=16)=whole_handle_point(t,bands)-whole_grip_offset(t,bands);

// Query the body-fixed removal mask (longitude 0..360, latitude -90..90).
function whole_surface_peeled(t,latitude,longitude,bands=16)=
    (whole_pass(t,bands)>0 && latitude<=whole_band_low(t,bands)) ||
    (latitude<=whole_band_high(t,bands) && whole_cut(t,bands)>0 && longitude<=360*whole_cut(t,bands));

// Removed strip centreline length: latitude-scaled elliptical arc, 96 chords.
function whole_strip_length(t,bands=16,samples=96,i=0,length=0)=
    i==samples ? length :
    let(lat=whole_band_latitude(t,bands),sweep=360*whole_cut(t,bands))
    whole_strip_length(t,bands,samples,i+1,length+
        norm(whole_surface_point(lat,sweep*(i+1)/samples)-whole_surface_point(lat,sweep*i/samples)));
function whole_discard(t,bands=16)=smooth01((whole_phase(t,bands)-0.78)/0.22);
function whole_ribbon_time(t,bands=16)=min(t,(whole_pass(t,bands)+0.78)/bands);
function whole_strip_direction(t,bands=16)=
    let(n=whole_normal(t,bands),gravity=[0,0,-1])
    unit_vector(gravity-n*(gravity*n)+0.4*n);

module validate_whole_peel(bands) {
    assert(bands>=8 && bands<=24 && floor(bands)==bands,"Whole peel bands must be an integer from 8 to 24");
}

module action_peel_whole(t=0,show_arm=true,show_object=true,bands=16,
                         show_holder=true,show_strip=true,workspace_lo=whole_workspace_min(),
                         workspace_hi=whole_workspace_max(),reach_margin=2) {
    validate_whole_peel(bands);
    origin=show_arm ? rest_wrist() : [0,0,0];
    offset=whole_wrist_offset(t,bands);
    if(show_arm)
        mounted_arm(wrist=origin+offset,swivel=10*sin(360*t)+5*sin(whole_longitude(t,bands)),
                    roll=15*sin(whole_longitude(t,bands)),workspace_lo=workspace_lo,
                    workspace_hi=workspace_hi,reach_margin=reach_margin,
                    world_aligned=true) rotate(whole_hand_angles(t,bands))
                        bionic_hand(whole_hand_pose(t,bands));
    else translate(offset) rotate(whole_hand_angles(t,bands)) bionic_hand(whole_hand_pose(t,bands));
    translate(origin) {
        whole_peeler(t,bands);
        if(show_object) {
            whole_potato(t,bands);
            if(show_holder) whole_holder();
            if(show_strip) whole_ribbon(t,bands);
        }
    }
}

module whole_potato(t=0,bands=16) {
    translate(whole_center()) {
        color([0.91,0.77,0.42]) scale(potato_radii()-[0.6,0.6,0.6]) sphere(r=1,$fn=64);
        whole_remaining_skin(t,bands);
    }
}

module whole_remaining_skin(t,bands=16) {
    low=potato_radii().z*sin(whole_band_low(t,bands));
    high=potato_radii().z*sin(whole_band_high(t,bands));
    cut=whole_cut(t,bands);
    // No residual shell after the final pass, including the north polar cap.
    if(!(whole_pass(t,bands)==bands-1 && cut==1))
        color([0.52,0.32,0.16]) difference() {
            scale(potato_radii()) sphere(r=1,$fn=64);
            if(whole_pass(t,bands)>0)
                // Keep the cut overlap when a band becomes a completed band.
                translate([-60,-60,-60]) cube([120,120,low+60+0.001]);
            if(cut>0) intersection() {
                translate([-60,-60,low-0.001]) cube([120,120,high-low+0.002]);
                if(cut==1) cube([120,120,120],center=true);
                else linear_extrude(120,center=true)
                    polygon(concat([[0,0]],[for(i=[0:64]) [100*cos(360*cut*i/64),100*sin(360*cut*i/64)]]));
            }
        }
}

// Curved blade spans the current latitude band; the hand holds its short handle.
// Tool and fixed support are illustrative, without contact or cutting forces.
module whole_peeler(t,bands=16) {
    n=whole_normal(t,bands);
    centre=whole_center();
    low=whole_latitude(t,bands)-90/bands;
    blade=[for(i=[0:6]) centre+
        whole_surface_point(low+180/bands*i/6,whole_longitude(t,bands))+n*whole_clearance(t,bands)];
    color([0.75,0.79,0.83]) for(i=[0:5]) whole_rod(blade[i],blade[i+1],0.45);
    contact=whole_contact(t,bands)+n*whole_clearance(t,bands);
    color([0.20,0.23,0.28]) whole_rod(contact,whole_handle_point(t,bands),1.4);
    color([0.25,0.65,0.75]) translate(whole_handle_point(t,bands)) sphere(r=2.5,$fn=16);
}

module whole_ribbon(t,bands=16) {
    length=whole_strip_length(t,bands);
    drop=whole_discard(t,bands);
    if(length>0.000001 && drop<1) {
        released_time=whole_ribbon_time(t,bands);
        n=whole_normal(released_time,bands);
        direction=whole_strip_direction(released_time,bands);
        root=whole_contact(released_time,bands)+n*0.8+[0,0,-80]*drop;
        // Keep width aligned perpendicular to the strip centreline.
        normal=unit_vector(n-direction*(n*direction));
        width=norm(whole_surface_point(whole_band_high(t,bands),whole_longitude(t,bands))-
                   whole_surface_point(whole_band_low(t,bands),whole_longitude(t,bands)));
        color([0.60,0.39,0.19,1-drop]) peel_strip(root,root+length*direction,normal,width);
    }
}

module whole_holder() {
    translate(whole_center()) {
        color([0.34,0.38,0.43]) {
            for(s=[-1,1]) {
                whole_rod([0,0,s*43],[0,0,s*56],1.6);
                whole_rod([0,0,s*56],[-49,0,s*56],2.5);
            }
            whole_rod([-49,0,-56],[-49,0,56],2.5);
        }
        // Fixed marker helps verify that the support never turns with the hand.
        color([0.25,0.65,0.75])
            translate([0,0,-49]) cube([12,4,5],center=true);
    }
}

module whole_rod(a,b,r) {
    hull() for(p=[a,b]) translate(p) sphere(r=r,$fn=12);
}

$fn=24;
action_peel_whole($t);
