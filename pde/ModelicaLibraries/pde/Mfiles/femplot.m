function steps=femplot(dymstr,fieldname,varargin)
% femplot Plot a field in a dymola result struct
% femplot (dymstr,fieldname), where dymstr is the dymola struct loaded by
% dymload(), and fieldname is the name of the field.

[x,y,val,t,steps]=get_mesh(dymstr,fieldname,varargin{:});
%trisurf(t,x,y,val);
trimesh(t,x,y,val);