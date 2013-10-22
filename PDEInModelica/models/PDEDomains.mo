//approach 1:
package PDEDomains
  import C = Modelica.Constants;
  record DomainLineSegment1D
    parameter Real l = 1;
    parameter Real a = 0;
    function shapeFunc
      input Real v;
      output Real x = l*v + a;
    end shapeFunc;
    Coordinate x (name = "cartesian");
    Region1D interior(shape = shapeFunc, interval = {0,1});
    Region0D left(shape = shapeFunc, interval = 0);
    Region0D right(shape = shapeFunc, interval = 1);
    Region0D boundary = left + right;
  end DomainLineSegment1D;

//approach 2:
  record DomainLineSegment1D
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
//    Coordinate r (name = "polar");
//    Coordinate theta (name = "polar");
//    equation
//      r = sqrt(x^2 + y^2);
//      theta = arctg(y/x);
    Region2D interior(shape = shapeFunc, interval = {{0,1},{0,1}});
    Region1D right(shape = shapeFunc, interval = {1,{0,1}});
    Region1D bottom(shape = shapeFunc, interval = {{0,1},0});
    Region1D left(shape = shapeFunc, interval = {0,{0,1}});
    Region1D top(shape = shapeFunc, interval = {{0,1},1});
    Region1D boundary = right + bottom + left + top;
  end DomainRectangle2D;

//approach 2:
  class DomainRectangle2D
    Coordinate x (name = "cartesian");
    Coordinate y (name = "cartesian");
//    Coordinate r (name = "polar");
//    Coordinate theta (name = "polar");
    parameter Real L1 = 1;  //rectangle length, assign implicit value
    parameter Real L2 = 1;  //rectangle height, assign implicit value
    parameter Real a1 = 0;  //x-coordinate of left side, implicitly 0
    parameter Real a2 = 0;  //y-coorinate of lower side, implicitly 0
    parameter Real b1 = a1 + L1;  //x-coordinate of right side
    parameter Real b2 = a2 + L2;  //y-coorinate of upper side
//    equation
//      r = sqrt(x^2 + y^2);
//      theta = arctg(y/x);
    Region2D interior (x in (a1,b1), y in (a2,b2));  //or rather (x,y) in (a1,b1)@(a2,b2)??
    Region1D right    (x = a, y in (a2,b2));
    Region1D bottom   (x in (a1,b1), y = b1);
    Region1D left     (x = a1, y = (a2,b2));
    Region1D top      (x in (a1,b1), y = b2);
    Region1D boundary = right + bottom + left + top;
  end DomainRectangle2D;

//approach 1:
  class DomainCircular2D
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
    Coordinate x (name="cartesian");
    Coordinate y (name="cartesian";
    Coordinate r (name="polar");
    Coordinate theta (name="polar");
    equation
      r = sqrt(x^2 + y^2);
      theta = arctg(y/x);
    Region2D interior(shape = shapeFunc, interval = {{O,1},{O,1}});
    Region1D boundary(shape = shapeFunc, interval = {1,{0,1}});
  end DomainCircular2D;

//approach 2:
  class DomainCircular2D
    parameter Real radius = 1;
    parameter Real cx = 0;
    parameter Real cy = 0;
    Real u,v;
    Coordinate x (name="cartesian");
    Coordinate y (name="cartesian";
    Coordinate r (name="polar");
    Coordinate theta (name="polar");
    equation
      x = r*cos(theta) + cx;
      y = r*sin(theta) + cy;
    Region2D interior(theta in (O,2*C.pi), r in (O,radius));
    Region1D boundary(theta in (O,2*C.pi), r = radius);
  end DomainCircular2D;

//approach 1:
  record DomainBlock3D
    parameter Real Lx = 1, Ly = 1, Lz = 1;
    parameter Real ax = 0, ay = 0, az = 0;
    function shapeFunc
      input Real vx, vy, vz;
      output Real x = ax + Lx * vx, y = ay + Ly * vy, z = az + Lz * vz;
    end shapeFunc;
    Coordinate x (name="cartesian");
    Coordinate y (name="cartesian");
    Coordinate z (name="cartesian");
    Region3D interior(shape = shapeFunc, interval = {{0,1},{0,1},{0,1}});
    Region2D right(shape = shapeFunc, interval = {1,{0,1},{0,1}});
    Region2D bottom(shape = shapeFunc, interval = {{0,1},{0,1},1});
    Region2D left(shape = shapeFunc, interval = {0,{0,1},{0,1}});
    Region2D top(shape = shapeFunc, interval = {{0,1},{0,1},1});
    Region2D front(shape = shapeFunc, interval = {{0,1},0,{0,1}});
    Region2D rear(shape = shapeFunc, interval = {{0,1},1,{0,1}});
    Region2D boundary = right + bottom + left + top + front + rare;
  end DomainBlock3D;

  //and others ...
end PDEDomains;

