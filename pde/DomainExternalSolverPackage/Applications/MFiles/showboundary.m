function showboundary(matfile,name)

res=dymload(matfile);
nodes=cell2mat(dymget(res,[name '.polygon']));
x=nodes(2:2:size(nodes,1),1);
y=nodes(2:2:size(nodes,1),2);
fill(x,y,'b');