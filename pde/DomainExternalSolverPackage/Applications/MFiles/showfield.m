function showfield(matfile, name)

res=dymload(matfile);
nodes=cell2mat(dymget(res,[name '.ddomain.mesh.x']));
tris=cell2mat(dymget(res,[name '.ddomain.mesh.triangle']));
vals=cell2mat(dymget(res,[name '.val']))';
t=tris(2:2:size(tris,1),1:3);
x=nodes(2:2:size(nodes,1),1);
y=nodes(2:2:size(nodes,1),2);
z=vals(:,1);
trimesh(t,x,y,z);