function showmesh(matfile,name)

res=dymload(matfile);
nodes=cell2mat(dymget(res,[name '.mesh.x']));
tris=cell2mat(dymget(res,[name '.mesh.triangle']));
t=tris(2:2:size(tris,1),1:3);
x=nodes(2:2:size(nodes,1),1);
y=nodes(2:2:size(nodes,1),2);
trimesh(t,x,y);