function [x,y,val,t,steps] = get_mesh_1d(dymstr,fieldname,varargin)
% get_mesh  Get the mesh from a field
% get_mesh(dymstr,fieldname), where dymstr is the dymola struct loaded by
% dymload(), and fieldname is the name of the field. The mesh is then found
% in fieldname.domain.grid.
gridname=[fieldname, '.domain.grid'];
triname=[gridname, '.interval'];
nodename=[gridname, '.x'];
valname=[fieldname, '.val'];

tric=dymget(dymstr,triname);
nodec=dymget(dymstr,nodename);
valc=dymget(dymstr,valname);

nodes=cell2mat(nodec);
tris=cell2mat(tric);

% get the number of result values 
maxstepno=size(valc{1,1},1); 
stepno=2; % always at least 2. take the second one by default
if nargin == 3
    stepno=varargin{1};
    if (stepno > maxstepno)
        error('Too big time index');
    end
end

% get every other line because of double values
x=nodes(:,1);
t=tris(s,1),1:3);
val=
val=val(stepno,:);
steps=maxstepno;