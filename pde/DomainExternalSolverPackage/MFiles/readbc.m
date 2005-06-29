function [bctype,bcgval,bcqval,bcind]=readbc(filename)
fid=fopen(filename);
n=fscanf(fid,' { %d , %d ',2);
nbc=n(1);
bcdim=n(2);
if bcdim ~= 4
    error('bcdim must be 4');
end
fscanf(fid,' , { ',1);
for i=1:nbc,
    val=fscanf(fid,' { %f , %f , %f , %f }', 4);
    bctype(i)=val(1);
    bcgval(i)=val(2);
    bcqval(i)=val(3);
    bcind(i)=val(4);
    fscanf(fid,' , ',1);
end
fclose(fid);