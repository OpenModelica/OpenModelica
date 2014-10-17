

package PDEDomains
  import C = Modelica.Constants;

  type Domain  //Domain is built-in, but this is its "interface"
    prameter Integer ndim;
    Coordinate coord[ndim];
    replaceable Region interior;
    replaceable function shapeFunc
      input Real u[ndim];
      output Real coord[ndim];
    end shapeFunc;
  end Domain

type Region //Region is built-in, looks like
  parameter Integer ndimS; //dimension of the space, where the region exists
  parameter Integer  ndim; //dimension of the region
  //e.g. sphere in 3D has ndimS = 3, ndim = 2
  replaceable function shape;
    input Real u[ndimS];
    output Real coord[ndimS];
  end shape;
  parameter Real[ndimS][2] interval;
equation
  assert(ndim <= ndimS, "Dimension of region must be lower or equal to dimension of space where it is defined.");
end Region;

type Region0D = Region(ndim = 0);
type Region1D = Region(ndim = 1);
type Region2D = Region(ndim = 2);
type Region3D = Region(ndim = 3);





//approach 1:
  class DomainLineSegment1D
    extends Domain;
    parameter Real l = 1;
    parameter Real a = 0;
    redeclare function shapeFunc
      input Real v;
      output Real x = l*v + a;
    end shapeFunc;
    Coordinate x(name = "cartesian") = coord[1];
    Region1D interior(shape = shapeFunc, interval = {0,1});
    Region0D left(shape = shapeFunc, interval = 0);
    Region0D right(shape = shapeFunc, interval = 1);
    Region0D boundary = left + right; //{left, right};
  end DomainLineSegment1D;

//approach 2:
  class DomainLineSegment1D
    extends Domain;
    parameter Real l = 1;
    parameter Real a = 0;
    parameter Real b = a + l;
    Coordinate x (name = "cartesian");
    Region1D interior(x in (a,b));
    Region0D left(x = a);
    Region0D right(x = b);
    Region0D boundary = left + right;
  end DomainLineSegment1D;

//approach 1:
  class DomainRectangle2D
    extends Domain;
    parameter Real Lx = 1;
    parameter Real Ly = 1;
    parameter Real ax = 0;
    parameter Real ay = 0;
    function shapeFunc
      input Real v1, v2;
      output Real x = ax + Lx * v1, y = ay + Ly * v2;
    end shapeFunc;
    Coordinate x (name = "cartesian");
    Coordinate y (name = "cartesian");
    Coordinate r (name = "polar");
    Coordinate phi (name = "polar");
    equation
      r = sqrt(x^2 + y^2);
      phi = arctg(y/x);
    Region2D interior(shape = shapeFunc, interval = {{0,1},{0,1}});
    Region1D right(shape = shapeFunc, interval = {1,{0,1}});
    Region1D bottom(shape = shapeFunc, interval = {{0,2},0});
    Region1D left(shape = shapeFunc, interval = {0,{0,1}});
    Region1D top(shape = shapeFunc, interval = {{0,1},1});
    Region1D boundary = right + bottom + left + top;
    Region1D boundary(union = {right,  bottom, left, top});
  end DomainRectangle2D;

//approach 2:
  class DomainRectangle2D
    extends Domain;
    Coordinate x (name = "cartesian");
    Coordinate y (name = "cartesian");
//    Coordinate r (name = "polar");
//    Coordinate phi (name = "polar");
    parameter Real L1 = 1;  //rectangle length, assign implicit value
    parameter Real L2 = 1;  //rectangle height, assign implicit value
    parameter Real a1 = 0;  //x-coordinate of left side, implicitly 0
    parameter Real a2 = 0;  //y-coorinate of lower side, implicitly 0
    parameter Real b1 = a1 + L1;  //x-coordinate of right side
    parameter Real b2 = a2 + L2;  //y-coorinate of upper side
//    equation
//      r = sqrt(x^2 + y^2);
//      phi = arctg(y/x);
    Region2D interior (x in (a1,b1), y in (a2,b2));  //or rather (x,y) in (a1,b1)@(a2,b2)??
    Region1D right    (x = a, y in (a2,b2));
    Region1D bottom   (x in (a1,b1), y = b1);
    Region1D left     (x = a1, y = (a2,b2));
    Region1D top      (x in (a1,b1), y = b2);
    Region1D boundary = right + bottom + left + top;
  end DomainRectangle2D;

//approach 1:
  class DomainCircular2D
    extends Domain;
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
    coordinate x (name="cartesian");
    coordinate y (name="cartesian";
    coordinate cartesian[2] = {x,y};
    // Coordinate r (name="polar");
    // Coordinate phi (name="polar");
    // equation
    //   r = sqrt(x^2 + y^2);
    //   phi = arctg(y/x);
    Region2D interior(shape = shapeFunc, interval = {{O,1},{O,1}});
    Region1D boundary(shape = shapeFunc, interval = {1,{0,1}});
  end DomainCircular2D;

//approach 2:
  class DomainCircular2D
    extends Domain;
    parameter Real radius = 1;
    parameter Real cx = 0;
    parameter Real cy = 0;
    coordinate x (name="cartesian");
    coordinate y (name="cartesian";
    coordinate r (name="polar");
    coordinate phi (name="polar");
    coordinate cartesian[2] = {x,y};
    coordinate polar[2] = {r,phi};
    equation
      x = r*cos(phi) + cx;
      y = r*sin(phi) + cy;
    Region2D interior(phi in (O,2*C.pi), r in (O,radius));
    Region1D boundary(phi in (O,2*C.pi), r = radius);
  end DomainCircular2D;

//approach 2:
  type DomainElliptic2D
    extends Domain(ndim=2);
    parameter Real cx, cy, rx, ry; //x/y center, x/y radius
    coordinate Real cartesian[ndim], x = cartesian[1], y = cartesian[2];
    coordinate modPolar[ndim], r = modPolar[1], phi = modPolar[2];
    equation
      x = rx*r*cos(phi) + cx;
      y = ry*r*sin(phi) + cy;
    Region2D interior(phi in (O,2*C.pi), r in (O,1));
    Region1D boundary(phi in (O,2*C.pi), r = 1);
  end DomainElliptic2D

//approach 1:
  class DomainBlock3D
    extends Domain(ndim=3);
    parameter Real Lx = 1, Ly = 1, Lz = 1;
    parameter Real ax = 0, ay = 0, az = 0;
    redeclare function shapeFunc
      input Real vx, vy, vz;
      output Real x = ax + Lx * vx, y = ay + Ly * vy, z = az + Lz * vz;
    end shapeFunc;
    Coordinate x (name="cartesian");
    Coordinate y (name="cartesian");
    Coordinate z (name="cartesian");
    coord = {x,y,z};
    Region3D interior(shape = shapeFunc, interval = {{0,1},{0,1},{0,1}});
    Region2D right(shape = shapeFunc, interval = {1,{0,1},{0,1}});
    Region2D bottom(shape = shapeFunc, interval = {{0,1},{0,1},1});
    Region2D left(shape = shapeFunc, interval = {0,{0,1},{0,1}});
    Region2D top(shape = shapeFunc, interval = {{0,1},{0,1},1});
    Region2D front(shape = shapeFunc, interval = {{0,1},0,{0,1}});
    Region2D rear(shape = shapeFunc, interval = {{0,1},1,{0,1}});
  end DomainBlock3D;

  //and others ...

end PDEDomains;

