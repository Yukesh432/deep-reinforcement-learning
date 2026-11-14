// World coordinates in millimeters. This operating box sits inside the
// two-link arm's reachable shell at every point, including its eight corners.
function workspace_min() = [-55,145,385];
function workspace_max() = [55,285,477];
// Whole-potato wrist trajectory envelope. Its corners need not be reachable;
// mounted_arm checks every wrist target against the arm's reachable shell.
function whole_workspace_min() = [-155,25,385];
function whole_workspace_max() = [155,335,645];
function inside_workspace(p,lo=workspace_min(),hi=workspace_max()) =
    min(p-lo) >= -0.00001 && min(hi-p) >= -0.00001;

// Minimum/maximum shoulder distance over the whole box, not just its corners.
function workspace_reach_bounds(lo,hi,shoulder) =
    let(nearest=[for(i=[0:2]) max(lo[i],min(hi[i],shoulder[i]))],
        farthest=[for(i=[0:2]) max(abs(lo[i]-shoulder[i]),abs(hi[i]-shoulder[i]))])
    [norm(nearest-shoulder),norm(farthest)];

module validate_workspace(lo,hi,shoulder,upper,lower,margin=2,require_full_box=true) {
    assert(len(lo)==3 && len(hi)==3 && min(hi-lo)>0,
           "Workspace bounds must be ordered 3D vectors with positive volume");
    assert(margin>=0,"Reach margin must be nonnegative");
    distances=workspace_reach_bounds(lo,hi,shoulder);
    if(require_full_box)
      assert(distances[0]>abs(upper-lower)+margin && distances[1]<upper+lower-margin,
           str("Workspace crosses the arm reach margin. Shoulder distances: ",distances,
               "; allowed: ", [abs(upper-lower)+margin,upper+lower-margin],
               ". Adjust the workspace bounds or margin."));
}

module workspace_edges(lo=workspace_min(),hi=workspace_max()) {
    color([0.2,0.68,0.82]) for (axis=[0:2], a=[0,1], b=[0,1]) {
        start=[for(i=[0:2]) i==axis ? lo[i] :
               ((i==(axis+1)%3 ? a : b) ? hi[i] : lo[i])];
        end=[for(i=[0:2]) i==axis ? hi[i] : start[i]];
        hull() for(p=[start,end]) translate(p) sphere(r=0.9,$fn=8);
    }
}

module workspace_volume(lo=workspace_min(),hi=workspace_max(),filled=false) {
    workspace_edges(lo,hi);
    // Preview background: the optional fill is never a solid export obstacle.
    if(filled) %color([0.2,0.68,0.82,0.10]) translate(lo) cube(hi-lo);
}
