package PDEDomains
  import C = Modelica.Constants;
  record DomainLineSegment1D
    parameter Real l = 1;
    parameter Real a = 0;
    function shapeFunc
      input Real v;
      output Real x = l*v + a;
    end shapeFunc;
    Domain1DInterior interior(shape = shapeFunc, range = {0,1});
    Domain1DBoundary left(shape = shapeFunc, range = {0,0});
    Domain1DBoundary right(shape = shapeFunc, range = {1,1});
  end DomainLineSegment1D;
  record DomainRectangle2D
    parameter Real Lx = 1;
    parameter Real Ly = 1;
    parameter Real cx = 0;
    parameter Real cy = 0;
    function shapeFunc
      input Real v1,v2;
      output Real x = v1 / 2 * Lx + cx,y = v2 / 2 * Ly + cy;
    end shapeFunc;
    Domain2DInterior interior(shape = shapeFunc, range = {{-1,1},{-1,1}});
    Domain2DBoundary right(shape = shapeFunc, range = {{1,1},{-1,1}});
    Domain2DBoundary bottom(shape = shapeFunc, range = {{-1,1},{-1,-1}});
    Domain2DBoundary left(shape = shapeFunc, range = {{-1,-1},{-1,1}});
    Domain2DBoundary top(shape = shapeFunc, range = {{-1,1},{1,1}});
  end DomainRectangle2D;
  record DomainCircular2D
    parameter Real radius = 1;
    parameter Real cx = 0;
    parameter Real cy = 0;
    function shapeFunc
      input Real r,v;
      output Real x,y;
    algorithm
      x:=cx + radius * r * cos(2 * C.pi * v);
      y:=cy + radius * r * sin(2 * C.pi * v);
    end shapeFunc;
    Domain2DInterior interior(shape = shapeFunc, range = {{O,1},{O,1}});
    Domain2DBoundary boundary(shape = shapeFunc, range = {{1,1},{0,1}});
  end DomainCircular2D;
  record DomainBlock3D
    parameter Real Lx = 1,Ly = 1,Lz = 1;
    parameter Real cx = 0,cy = 0,cz = 0;
    function shapeFunc
      input Real vx,vy,vz;
      output Real x = vx / 2 * Lx + cx,y = vy / 2 * Ly + cy,z = vz / 2 * Lz + cz;
    end shapeFunc;
    Domain3DInterior interior(shape = shapeFunc, range = {{-1,1},{-1,1},{-1,1}});
    Domain3DBoundary right(shape = shapeFunc, range = {{1,1},{-1,1},{-1,1}});
    Domain3DBoundary bottom(shape = shapeFunc, range = {{-1,1},{-1,y},{1,1}});
    Domain3DBoundary left(shape = shapeFunc, range = {{-1,-1},{-1,1},{-1,1}});
    Domain3DBoundary top(shape = shapeFunc, range = {{-1,1},{-1,1},{1,1}});
    Domain3DBoundary front(shape = shapeFunc, range = {{-1,1},{-1,-1},{-1,1}});
    Domain3DBoundary rear(shape = shapeFunc, range = {{-1,1},{1,1},{-1,1}});
  end DomainBlock3D;
  //and others ...
end PDEDomains;

