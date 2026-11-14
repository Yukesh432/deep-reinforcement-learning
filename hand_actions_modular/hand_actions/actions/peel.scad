use <../model/hand.scad>
use <common.scad>
use <pinch.scad>

// 0-.20 pinch; .20-.65 peel; .65-.80 release; .80-1 return.
// Material progress stays peeled during return. A new loop at t=0 resets it.
function peel_pinch(t)=smooth01(t/0.20)*(1-smooth01((t-0.65)/0.15));
function peel_progress(t)=smooth01((t-0.20)/0.45);
function peel_return(t)=smooth01((t-0.80)/0.20);
function peel_release(t)=smooth01((t-0.72)/0.18);

function potato_center()=[-61,36,120];
function potato_radii()=[34,30,43];
// Equatorial skin path beginning at the authored pinch target [-27,36,120].
function skin_point(u)=potato_center()+[34*cos(95*u),-30*sin(95*u),0];
function skin_tangent(u)=let(v=[34*sin(95*u),30*cos(95*u),0]) v/norm(v);
function skin_normal(u)=let(v=[cos(95*u)/34,-sin(95*u)/30,0]) v/norm(v);

// Cumulative surface arc length (96 chords; sub-0.001 mm total error).
function skin_arc_table(samples=96,i=0,length=0)=
    concat([[i/samples,length]],i==samples ? [] :
        skin_arc_table(samples,i+1,length+norm(skin_point((i+1)/samples)-skin_point(i/samples))));
function skin_length()=let(table=skin_arc_table()) table[len(table)-1][1];
function skin_u(length)=
    let(table=skin_arc_table(),s=max(0,min(table[len(table)-1][1],length)),
        i=[for(j=[0:len(table)-2]) if(table[j][1]<=s && table[j+1][1]>=s) j][0],
        a=table[i],b=table[i+1])
    a[0]+(b[0]-a[0])*(s-a[1])/(b[1]-a[1]);

// The straight strip lies in the surface tangent plane, clearing the potato.
// Its length equals the removed arc; wrist displacement is derived from its tip.
function peel_direction(u,lift_angle)=skin_tangent(u)*cos(lift_angle)+[0,0,sin(lift_angle)];
function peel_grip(length,lift_angle)=
    let(u=skin_u(length)) skin_point(u)+length*peel_direction(u,lift_angle);
function peel_offset(t,peel_length=50,lift_angle=25)=
    (peel_grip(peel_length*peel_progress(t),lift_angle)-skin_point(0))*(1-peel_return(t));
function released_direction(u,lift_angle,release)=
    let(v=peel_direction(u,lift_angle)*(1-release)+[0,0,-1]*release) v/norm(v);
function peel_strip_tip(t,peel_length=50,lift_angle=25)=
    let(s=peel_length*peel_progress(t),u=skin_u(s))
    skin_point(u)+s*released_direction(u,lift_angle,peel_release(t));

module validate_peel(peel_length,lift_angle) {
    assert(peel_length>=0 && peel_length<=skin_length(),
           str("Peel length must be between 0 and ",skin_length()," mm"));
    assert(lift_angle>=0 && lift_angle<=80,"Peel lift angle must be between 0 and 80 degrees");
}

module peel_hand(t=0) { bionic_hand(pinch_pose(peel_pinch(t))); }

module action_peel(t=0,show_object=true,peel_length=50,lift_angle=25) {
    validate_peel(peel_length,lift_angle);
    translate(peel_offset(t,peel_length,lift_angle)) peel_hand(t);
    if(show_object) peel_object(t,peel_length,lift_angle);
}

module peel_object(t=0,peel_length=50,lift_angle=25) {
    validate_peel(peel_length,lift_angle);
    length=peel_length*peel_progress(t);
    u=skin_u(length);
    center=potato_center();
    color([0.91,0.77,0.42]) translate(center)
        scale(potato_radii()-[0.6,0.6,0.6]) sphere(r=1,$fn=64);
    color([0.52,0.32,0.16]) difference() {
        translate(center) scale(potato_radii()) sphere(r=1,$fn=64);
        // Only remove the material peeled so far; no pre-cut open band at t=0.
        if(length>0) translate(center+[0,0,-4]) linear_extrude(8)
            polygon(concat([[0,0]],[for(i=[0:32])
                [50*cos(95*u*i/32),-50*30/34*sin(95*u*i/32)]]));
    }
    if(length>0) color([0.60,0.39,0.19])
        peel_strip(skin_point(u),peel_strip_tip(t,peel_length,lift_angle),skin_normal(u));
}

// Thin rectangular ribbon; its centreline length is exactly norm(tip-root).
// After release it hangs from the remaining attached edge, without reattaching.
module peel_strip(root,tip,normal,width=8,thickness=0.6) {
    delta=tip-root;
    direction=delta/norm(delta);
    side=cross(direction,normal);
    multmatrix([[normal.x,side.x,direction.x,root.x],
                [normal.y,side.y,direction.y,root.y],
                [normal.z,side.z,direction.z,root.z],
                [0,0,0,1]])
        translate([-thickness/2,-width/2,0]) cube([thickness,width,norm(delta)]);
}

$fn=24;
action_peel($t);
