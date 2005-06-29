function [v,e,vh]=readgeom(filename)
fid=fopen(filename);
findToken(fid,'Vertices');
nv=fscanf(fid,'%d',1);
for i = 1:nv,
    v(:,i)=fscanf(fid,'%f %f %d',3);
end;
findToken(fid,'Edges');
ne=fscanf(fid,'%d',1);
for i = 1:nv,
    e(:,i)=fscanf(fid,'%d %d %d',3);
end;
findToken(fid,'hVertices');
for i = 1:nv,
    vh(i)=fscanf(fid,'%f',1);
end;
v=v';
e=e';


function findToken(fid, token)
t=fscanf(fid, '%s', 1);
while strcmp(token,t) == 0 || feof(fid)
    t=fscanf(fid, '%s', 1);
end;
