// Point rotations use the same X-then-Y-then-Z convention as OpenSCAD rotate().
function rotate_x_point(p,a)=[p.x,p.y*cos(a)-p.z*sin(a),p.y*sin(a)+p.z*cos(a)];
function rotate_y_point(p,a)=[p.x*cos(a)+p.z*sin(a),p.y,-p.x*sin(a)+p.z*cos(a)];
function rotate_z_point(p,a)=[p.x*cos(a)-p.y*sin(a),p.x*sin(a)+p.y*cos(a),p.z];
function rotate_point(p,angles)=
    rotate_z_point(rotate_y_point(rotate_x_point(p,angles.x),angles.y),angles.z);
function unit_vector(v)=v/norm(v);
