// Shared pure functions. Each action receives time explicitly.
function clamp01(t)=min(1,max(0,t));
function smooth01(t)=let(v=clamp01(t)) v*v*(3-2*v);
function cycle(t)=(1-cos(360*clamp01(t)))/2;
function mix_pose(a,b,u)=[for(i=[0:len(a)-1]) a[i]+(b[i]-a[i])*u];
function pack_pose(index,middle,ring,little,thumb,wrist)=
    concat(index,middle,ring,little,thumb,wrist);
