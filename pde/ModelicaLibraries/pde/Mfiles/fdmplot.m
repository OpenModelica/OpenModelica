function steps=fdmplot(dymstr,fieldname,varargin)
% get_grid  Get the grid from a FDM field
% get_grid(dymstr,fieldname), where dymstr is the dymola struct loaded by
% dymload(), and fieldname is the name of the field. The grid is then found
% in fieldname.domain.grid.
[x,y,val,steps]=get_grid(dymstr,fieldname,varargin{:});
[X,Y]=meshgrid(x,y);
mesh(X,Y,val');