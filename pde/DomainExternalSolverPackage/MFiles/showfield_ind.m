function showfield_ind(matfile, name)

res=dymload(matfile);
nodes=cell2mat(dymget(res,[name '.ddomain.mesh.x']));
tris=cell2mat(dymget(res,[name '.ddomain.mesh.triangle']));
valsu=cell2mat(dymget(res,[name '.val_u']))';
valsb=cell2mat(dymget(res,[name '.val_b']))';
uindices=cell2mat(dymget(res,[name '.u_indices']))';
bindices=cell2mat(dymget(res,[name '.b_indices']))';
t=tris(2:2:size(tris,1),1:3);
x=nodes(2:2:size(nodes,1),1);
y=nodes(2:2:size(nodes,1),2);
ui=uindices(:,1);
bi=bindices(:,1);
z(ui)=valsu(:,1);
z(bi)=valsb(:,1);
%trimesh(t,x,y,z);
trisurf(t,x,y,z,'FaceColor','interp','EdgeColor','interp');