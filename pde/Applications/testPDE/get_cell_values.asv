function val = get_cell_values(dymstr,varname,stepno)

valc=dymget(dymstr,varname);
s=size(valc);
for i=1:size(s)
    for j=1:s(i)
    tmp=valc{i};
    val(i)=tmp(stepno);
end
