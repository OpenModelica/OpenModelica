package FVM "Partial Differential Equations, Finite Element Method" 
  
package Boundaries "Contains the definition of boundaries" 
    
  record Boundary1D "Boundary of 1D domain" 
    parameter Elements.Point1D left;
    parameter Elements.Point1D right;
    //parameter Elements.Polygon1D polygon; later, if subdivision of interval desired.
    parameter BdConditions1D bcond;
    annotation(
            Documentation(info="<HTML>
<pre>
Boundary of arbitrary one-dimensional spatial domain.
</pre>
</HTML>"));
  end Boundary1D;
    
record BdConditions1D "Boundary conditions on boundary curve in R2" 
  parameter Integer type_bc[2,:]=[0;0] 
        "Type of boundary cond left/right, 2nd index # of field";
    annotation(Documentation(info="<HTML>
<pre>
Contains the specification of boundary conditions on the boundary points in 1D.
Allows to store data for several different equations on the same domain. 

Example for 2nd order equation: index = 0 for Dirichlet, index = 1 for Neumann.
</pre>
</HTML>"));
end BdConditions1D;
    
  record Boundary2D "Boundary of 2D domain" 
    parameter Elements.Curve2D curve;
    parameter BdConditions2D bcond;
      annotation(Documentation(info="<HTML>
<pre>
Boundary of arbitrary two-dimensional spatial domain. 

>>> not yet implemented!
</pre>
</HTML>"));
  end Boundary2D;
    
record BdConditions2D "Boundary conditions on boundary curve in R2" 
      
/* fails when called by function defineBdConditions
  Integer bdCond[:,:]=[1] "Type of boundary cond left/right, 2nd index # of field";;
*/
  //explicit for rectangle:
  parameter Integer type_bc[4,1]=[0;0;0;0] 
        "Type of boundary cond, 2nd index # of field";
    annotation(Documentation(info="<HTML>
<pre>
Contains the specification of boundary conditions on the boundary curve in 2D.
Allows to store data for several different equations on the same domain. 

Example for 2nd order equation: index = 0 for Dirichlet, index = 1 for Neumann.
</pre>
</HTML>"));
end BdConditions2D;
    
end Boundaries;
  
package Domains 
    "Contains the definition of discretised domains with given boundaries" 
    
  record Domain1D "1D spatial domain" 
      
    parameter Boundaries.Boundary1D boundary;
    parameter Grids.Grid1D grid(polygon(x={boundary.left.x,boundary.right.x}));
  annotation(
          Documentation(info="<HTML>
<pre>
Arbitrary one-dimensional spatial domain with grid. 
</pre>
</HTML>"));
  end Domain1D;
    
  record Domain2D "2D spatial domain" 
    function convert = Graphical.convtoPolygon;
      
    parameter Boundaries.Boundary2D boundary;
    //parameter Grids.Grid2D grid(polygon=convert(boundary)); //does not work
    parameter Grids.Grid2D grid(polygon(x=boundary.curve.x));
  annotation(
          Documentation(info="<HTML>
<pre>
Arbitrary two-dimensional spatial domain with triangulation. 
>>> domain is presently just a rectangle, due to lack of time.
</pre>
</HTML>"),   DymolaStoredErrors);
  end Domain2D;
    
end Domains;
  
package Grids 
    "Contains the definition of discretised domains with given boundaries" 
    
  record Grid1D "1D spatial domain" 
      
    parameter Elements.Polygon1D polygon;
    parameter Real refine(min=0,max=1)=0.3 "0 < refine < 1, less is finer";
      
    function generate = GridGeneration.generate1D;
    function get_s = GridGeneration.sizes1D;
    function get_v = GridGeneration.vertices1D;
    function get_b = GridGeneration.bdpoints1D;
    function get_i = GridGeneration.intervals1D;
      
    parameter String mesh="default_mesh1D.txt"; // will be overwritten!
    parameter Integer bc[:]=  {i for i in 1:size(polygon.x,1)};
      
    parameter Integer status=  generate(polygon.x, bc, mesh, refine);
    parameter Integer s[3]=  get_s(mesh, status);
    parameter Integer nv=  s[1] "Number of vertices";
    parameter Integer nb=  s[2] "Number of boundary points";
    parameter Integer ni=  s[3] "Number of intervals";
    parameter Coordinate x[:,2]=  get_v(mesh, nv) 
        "Coordinates of grid-points (1) and inner/bd (2)";
    parameter Integer bdpoint[:,2]=  get_b(mesh, nb) 
        "Boundary vertices (1) and index for boundary condition (2)";
    parameter Integer interval[:,3]=  get_i(mesh, ni) 
        "Intervals by vertex-tuple (1:2) and index for dependence of coefficients (3)";
  annotation(
          Documentation(info="<HTML>
<pre>
Grid on arbitrary one-dimensional spatial domain. 
</pre>
</HTML>"));
  end Grid1D;
    
  model Grid1Ddummy "1D spatial domain" 
      
    parameter Elements.Polygon1D polygon(x={0,1});
    parameter Real refine(min=0,max=1)=0.9 "0 < refine < 1, less is finer";
      
    function generate = GridGeneration.generate1D;
    function get_s = GridGeneration.sizes1D;
    function get_v = GridGeneration.vertices1D;
    function get_b = GridGeneration.bdpoints1D;
    function get_i = GridGeneration.intervals1D;
      
    parameter String mesh="default_mesh1D.txt"; // will be overwritten!
    parameter Integer bc[:]=  {i for i in 1:size(polygon.x,1)};
      
    parameter Integer status=  generate(polygon.x, bc, mesh, refine);
    parameter Integer s[3]=  get_s(mesh, status);
    parameter Integer nv=  s[1] "Number of vertices";
    parameter Integer nb=  s[2] "Number of boundary points";
    parameter Integer ni=  s[3] "Number of intervals";
    parameter Coordinate x[:,2]=  get_v(mesh, nv) 
        "Coordinates of grid-points (1) and inner/bd (2)";
    parameter Integer bdpoint[:,2]=  get_b(mesh, nb) 
        "Boundary vertices (1) and index for boundary condition (2)";
    parameter Integer interval[:,3]=  get_i(mesh, ni) 
        "Intervals by vertex-tuple (1:2) and index for dependence of coefficients (3)";
  annotation(
          Documentation(info="<HTML>
<pre>
This model tests the grid generation for a grid on arbitrary one-dimensional spatial domain. 
</pre>
</HTML>"));
  end Grid1Ddummy;
    
  record Grid2D "2D spatial domain" 
      
    parameter Elements.Polygon2D polygon;
    parameter Real refine(min=0,max=1)=0.7 "0 < refine < 1, less is finer";
      
    function generate = GridGeneration.generate2D;
    function get_s = GridGeneration.sizes2D;
    function get_v = GridGeneration.vertices2D;
    function get_e = GridGeneration.edges2D;
    function get_t = GridGeneration.triangles2D;
      
    parameter String mesh=  "default_mesh2D.txt"; // will be overwritten!
    parameter Integer bc[:]=  {i for i in 1:size(polygon.x,1)};
      
  // If Cygwin (BAMG) not installed, bypass generation of grid, just read existing files.
    parameter Integer status=  generate(polygon.x, bc, mesh, refine);
      
    //parameter Integer s[3] = get_s(mesh, status);
    // Necessary for dependency! Currently not supported by Dymola (BUG?)
    parameter Integer s[3]=  get_s(mesh, 1);
      
    parameter Integer nv=  s[1] "Number of vertices";
    parameter Integer ne=  s[2] "Number of edges on boundary";
    parameter Integer nt=  s[3] "Number of triangles";
    parameter Coordinate x[:,3]=  get_v(mesh, nv) 
        "Coordinates of grid-points (1:2) and inner/bd (3)";
    parameter Integer edge[:,3]=  get_e(mesh, ne) 
        "Edges by vertex-tuple (1:2) and index for boundary condition (3)";
    parameter Integer triangle[:,4]=  get_t(mesh, nt) 
        "Triangles by vertex-triple (1:3) and index for dependence of coefficients (4)";
      
      annotation(Documentation(info="<HTML>
<pre>
Triangular grid on arbitrary two-dimensional spatial domain. 
>>> domain is presently just a rectangle, due to lack of time.
</pre>
</HTML>"));
  end Grid2D;
    
  model Grid2Ddummy "2D spatial domain" 
      
    parameter Elements.Polygon2D polygon(x=[0,0;1,0;1,1;0,1]);
    parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
      
    function generate = GridGeneration.generate2D;
    function get_s = GridGeneration.sizes2D;
    function get_v = GridGeneration.vertices2D;
    function get_e = GridGeneration.edges2D;
    function get_t = GridGeneration.triangles2D;
      
    parameter String mesh=  "default_mesh2D.txt"; // will be overwritten!
    parameter Integer bc[:]=  {i for i in 1:size(polygon.x,1)};
      
  // If Cygwin (BAMG) not installed, generation of grid is not supported.
    parameter Integer status=  generate(polygon.x, bc, mesh, refine);
    parameter Integer s[3]=  get_s(mesh, status); // Necessary for dependency!
      
      annotation(Documentation(info="<HTML>
<pre>
This model tests the grid generation for a triangular grid on arbitrary two-dimensional spatial domain. 
>>> domain is presently just a rectangle, due to lack of time.
</pre>
</HTML>"));
  end Grid2Ddummy;
end Grids;
  
package GridGeneration "Grid generation for 1D and triangular 2D" 
  function generate1D "Generates 1D mesh" 
      
    input Real xPolygon[:];
    input Integer bc[size(xPolygon,1)];
    input String outputfile;
    input Real refine=0.1; // 0 < refine < 1, controls refinement of triangles, less is finer.
    output Integer status;
    external "C" oneg_generate_mesh(
                                  "onegrun.bat", outputfile, status, xPolygon, 
      size(xPolygon,1), bc, size(bc,1), refine) 
    annotation( Include="#include <oneg_generate_mesh.c>");
  /*  
//for test:
algorithm 
  status := 0;
*/
  end generate1D;
    
  function sizes1D "Reads sizes mesh-data 1D" 
      
    input String mesh;
    input Integer status;
    output Integer s[3] "Sizes of mesh-data {vertices, bdpoints, intervals}";
    external "C" oneg_read_sizes(
                               mesh, s, size(s, 1)) 
    annotation( Include="#include <oneg_read_sizes.c>");
  /*  
//for test:
algorithm 
  s :={11,2,10};
*/
  end sizes1D;
    
  function vertices1D "Reads vertex coordinates 1D" 
      
    input String mesh;
    input Integer n "Number of vertices";
    output Coordinate v[n, 2];
    external "C" oneD_read_vertices(
                                  mesh, v, size(v, 1), size(v, 2)) 
    annotation( Include="#include <oneg_read_vertices.c>");
  /* 
//for test:
algorithm 
  v := [0,1; 0.1,1; 0.2,1; 0.3,1; 0.4,1; 0.5,1; 0.6,1; 0.7,1; 0.8,1; 0.9,1; 1,1];
*/
  end vertices1D;
    
  function bdpoints1D "Reads sequence of boundary points 1D" 
      
    input String mesh;
    input Integer n "Number of boundary-points";
    output Integer b[n, 2];
    external "C" oneD_read_bdpoints(
                                  mesh, b, size(b, 1), size(b, 2)) 
    annotation( Include="#include <oneg_read_bdpoints.c>");
  /*  
//for test:
algorithm 
  b := [0,1;1,1];
*/
  end bdpoints1D;
    
  function intervals1D "Reads sequence of intervals 1D" 
      
    input String mesh;
    input Integer n "Number of intervals";
    output Integer i[n, 3];
    external "C" oneD_read_intervals(mesh, i, size(i, 1), size(i, 2)) 
    annotation( Include="#include <oneg_read_intervals.c>");
  /*  
//for test:
algorithm 
  i := [1,2,1; 2,3,1; 3,4,1; 4,5,1; 5,6,1; 6,7,1; 7,8,1; 8,9,1; 9,10,1; 10,11,1];
*/
  end intervals1D;
    
  function generate2D "Generates 2D triangular mesh" 
      
    input Real xPolygon[:,2];
    input Integer bc[size(xPolygon,1)];
    input String outputfile;
    input Real refine=0.5; // h in (0,1) controls the refinement of triangles, less is finer
    output Integer status;
    external "C" bamg_generate_mesh(
                                  "bamgrun.bat", outputfile, status, xPolygon, 
      size(xPolygon,1), size(xPolygon,2), bc, size(bc,1), refine) 
    annotation( Include="#include <bamg_generate_mesh.c>");
  /*  
//for test:  
algorithm 
  status := 0;
*/
  end generate2D;
    
  function sizes2D "Reads sizes mesh-data 2D" 
      
    input String mesh;
    input Integer status;
    output Integer s[3] "Sizes of mesh-data {vertices, edges, triangles}";
    external "C" bamg_read_sizes(
                               mesh, s, size(s, 1)) 
    annotation( Include="#include <bamg_read_sizes.c>");
  /*  
//for test:
algorithm 
  s :={2,2,2};
*/
  end sizes2D;
    
  function vertices2D "Reads vertex coordinates 2D" 
      
    input String mesh;
    input Integer n "Number of vertices";
    output Real v[n, 3];
    external "C" bamg_read_vertices(
                                  mesh, v, size(v, 1), size(v, 2)) 
    annotation( Include="#include <bamg_read_vertices.c>");
  /*  
//for test:
algorithm 
  v := [1,2,3;0.1,0.2,4];
*/
  end vertices2D;
    
  function edges2D "Reads sequence of edges on boundary 2D" 
      
    input String mesh;
    input Integer n "Number of edges";
    output Integer e[n, 3];
    external "C" bamg_read_edges(
                               mesh, e, size(e, 1), size(e, 2)) 
    annotation( Include="#include <bamg_read_edges.c>");
  /*  
//for test:
algorithm 
  e := [1,2,3;4,5,6];
*/
  end edges2D;
    
  function triangles2D "Reads sequence of triangles 2D" 
      
    input String mesh;
    input Integer n "Number of triangles";
    output Integer t[n, 4];
    external "C" bamg_read_triangles(
                                   mesh, t, size(t, 1), size(t, 2)) 
    annotation( Include="#include <bamg_read_triangles.c>");
  /*  
//for test:
algorithm 
  t := [1,2,3,4;5,6,7,8];
*/
  end triangles2D;
    
end GridGeneration;
  
package Fields 
    "Contains the definition of fields upon domains with given boundaries" 
    
  record Field1D "Scalar field over 1D domain" 
    replaceable type fieldType = Real;
      
    parameter Domains.Domain1D domain;
    parameter fieldType ini_val[domain.grid.nv]=zeros(domain.grid.nv);
    fieldType val[domain.grid.nv](start=ini_val) 
        "Field-values over grid of domain";
    annotation(
          Documentation(info="<HTML>
<pre>
Scalar field over an arbitrary one-dimensional spatial domain.
</pre>
</HTML>"));
  end Field1D;
    
  record Field2D "Scalar field over 2D domain" 
    replaceable type fieldType = Real;
      
    parameter Domains.Domain2D domain;
    parameter fieldType ini_val[domain.grid.nv]=zeros(domain.grid.nv);
    fieldType val[domain.grid.nv](start=ini_val) 
        "Field-values over grid of domain";
      
    annotation(
          Documentation(info="<HTML>
<pre>
Scalar field over an arbitrary two-dimensional spatial domain.
</pre>
</HTML>"));
      
  end Field2D;
    
  record VectorField2D "Vector field over 2D domain" 
    replaceable type fieldType = Real;
      
    parameter Domains.Domain2D domain;
    parameter fieldType ini_val[domain.grid.nv, 2]=zeros(domain.grid.nv, 2);
    fieldType val[domain.grid.nv,2](start=ini_val) 
        "Field-values over grid of domain";
      
    annotation(
          Documentation(info="<HTML>
<pre>
Vector field over an arbitrary two-dimensional spatial domain.
</pre>
</HTML>"));
      
  end VectorField2D;
end Fields;
  
package SpecialFields "Contains explicit definition of special fields" 
    
    annotation( Documentation(info=""));
    record Const1D "Constant scalar field over 1D domain" 
      extends Fields.Field1D(val=  fill(c, domain.grid.nv));
      
      parameter fieldType c;
      
    annotation(
            Documentation(info="<HTML>
<pre>
Constant scalar field over an arbitrary one-dimensional spatial domain.
</pre>
</HTML>"));
    end Const1D;
    
    record Const2D "Constant scalar field over 2D domain" 
      extends Fields.Field2D(val=  fill(c, domain.grid.nv));
      
      parameter fieldType c;
      
    annotation(
            Documentation(info="<HTML>
<pre>
Constant scalar field over an arbitrary two-dimensional spatial domain.
</pre>
</HTML>"));
    end Const2D;
    
end SpecialFields;
  
package DifferentialOperators "Partial differential operators" 
    
  function tder1D "Time derivative 1D" 
      
    input Fields.Field1D f;
    //output Real f_t[f.domain.grid.n-2]; ???
    output Real f_t[size(f.val,1)-2];
  algorithm 
    f_t := zeros(f.domain.grid.n-2);
  /*
  no formulation for partial time derivative yet,
  formally we should have: tder1D(f) = der(DomainOperators.interior1D(f)).
*/
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of the time derivative of a 1D field as a vector.
Does NOT work with present Modelica, preliminary return value is 0.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-110,-110; 90,90], style(color=79, rgbcolor={170,
                  85,255}))));
  end tder1D;
    
  function tder2D "Time derivative 2D" 
      
    input Fields.Field2D f;
    //output Real f_t[f.domain.grid.n[1]-2, f.domain.grid.n[2]-2]; ???
    output Real f_t[size(f.val,1)-2, size(f.val,2)-2];
  algorithm 
    f_t := zeros(f.domain.grid.n[1]-2, f.domain.grid.n[2]-2);
  /*
  no formulation for partial time derivative yet,
  formally we should have: tder2D(f) = der(DomainOperators.interior2D(f)).
*/
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of the time derivative of a 2D field as a vector.
Does NOT work with present Modelica, preliminary return value is 0.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end tder2D;
    
  function xder1D "Spatial derivatives 1D" 
      import PDE.FDM.DifferentialOperators.DiffOrd2.*;
      
    input Fields.Field1D f;
    input Integer N(min=0,max=2)=1 "# derivative";
    //output Real f_x[f.domain.grid.n-2]; ???
    output Real f_x[size(f.val,1)-2];
    protected 
    Real dx;
  algorithm 
    // preliminary:
    dx := f.domain.grid.x[2] - f.domain.grid.x[1];
      
    f_x := if N == 0 then f.val else 
           if N == 1 then diff1D_1(f.val, dx) else 
           if N == 2 then diff1D_2(f.val, dx) else 
           zeros(f.domain.grid.n-2);
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of first or second spatial derivative of a 1D field as a vector.
The approximation is second order.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end xder1D;
    
  function xder2D "Spatial derivatives 2D." 
      import PDE.FDM.DifferentialOperators.DiffOrd2.*;
      
    input Fields.Field2D f;
    input Integer N1(min=0,max=2)=1 "# derivative in x1 direction";
    input Integer N2(min=0,max=2)=1 "# derivative in x2 direction";
    //output Real f_x[f.domain.grid.n[1]-2, f.domain.grid.n[2]-2]; ???
    output Real f_x[size(f.val,1)-2, size(f.val,2)-2];
    protected 
    Real dx1;
    Real dx2;
  algorithm 
    // preliminary:
    dx1 := f.domain.grid.x1[2] - f.domain.grid.x1[1];
    dx2 := f.domain.grid.x2[2] - f.domain.grid.x2[1];
      
    f_x := if N1==0 and N2==0 then f.val else 
           if N1==1 and N2==0 then diff2D_1(f.val, dx1) else 
           if N1==0 and N2==1 then transpose(diff2D_1(transpose(f.val), dx2)) else 
           if N1==2 and N2==0 then diff2D_2(f.val, dx1) else 
           if N1==0 and N2==2 then transpose(diff2D_2(transpose(f.val), dx2)) else 
           if N1==1 and N2==1 then diff2D_1(transpose(diff2D_1(transpose(f.val), dx2)), dx1) else 
           zeros(f.domain.grid.n[1]-2,f.domain.grid.n[2]-2);
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of first or second spatial derivative of a 2D field as a matrix.
The approximation is second order.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end xder2D;
    
    annotation( Documentation(info=""),
           Icon);
    
  function grad2D "Gradient 2D" 
      
    input Fields.Field2D f;
    //output Real grad_f[2, f.domain.grid.n[1]-2, f.domain.grid.n[2]-2]; ???
    output Real grad_f[2, size(f.val,1)-2, size(f.val,2)-2];
  algorithm 
      
    grad_f := {xder2D(f, 1, 0), xder2D(f, 0, 1)};
      
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of the gradient of a 2D field as a matrix.
The approximation is second order.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end grad2D;
    
  function div2D "Divergence 2D" 
      
    input Fields.Field2D f;
    //output Real div_f[f.domain.grid.n[1]-2, f.domain.grid.n[2]-2]; ???
    output Real div_f[size(f.val,1)-2, size(f.val,2)-2];
  algorithm 
      
    div_f := xder2D(f, 1, 0) + xder2D(f, 0, 1);
      
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of the divergence of a 2D field as a matrix.
The approximation is second order.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end div2D;
    
  function laplace2D "Laplace operator 2D" 
      
    input Fields.Field2D f;
    //output Real laplace_f[f.domain.grid.n[1]-2, f.domain.grid.n[2]-2]; ???
    output Real laplace_f[size(f.val,1)-2, size(f.val,2)-2];
  algorithm 
      
    laplace_f := xder2D(f, 2, 0) + xder2D(f, 0, 2);
      
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of the laplace operator applied to a 2D field as a matrix.
The approximation is second order.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end laplace2D;
    
  function laplace_r_z "Laplace operator 3D reduced to 2D(r,z)" 
  // modify! not yet valid.    
    input Fields.Field2D f;
    //output Real laplace_f[f.domain.grid.n[1]-2, f.domain.grid.n[2]-2]; ???
    output Real laplace_f[size(f.val,1)-2, size(f.val,2)-2];
  algorithm 
      
    laplace_f := xder2D(f, 2, 0) + xder2D(f, 0, 2);
      
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of the laplace operator in cylindrical coordinates under the restriction d/dphi = 0, 
applied to a 3D field as a matrix. The approximation is second order.

The general form in cylindrical coordinates is

 laplace3D = (1/r)*d/dr(r*d/dr)f + (1/r^2)*d2f/dphi^2 + d2f/dz^2

If the system has rotational symmetry, d/dphi = 0, 
the remaining coordinates are r ('x-axis') and z ('y-axis') with

 laplace_r_z = (1/r)*d/dr(r*d/dr)f + d2f/dz^2

>>> PUT THE CORRECT DIFFERENTIAL OPERATORS INTO THE EQUATIONS LATER.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-80; 80,100],   style(color=1, rgbcolor={255,
                  0,0})),
                Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end laplace_r_z;
    
  function laplace_r_phi "Laplace operator 3D reduced to 2D(r,phi)" 
  // modify! not yet valid.  
    input Fields.Field2D f;
    //output Real laplace_f[f.domain.grid.n[1]-2, f.domain.grid.n[2]-2]; ???
    output Real laplace_f[size(f.val,1)-2, size(f.val,2)-2];
  algorithm 
      
    laplace_f := xder2D(f, 2, 0) + xder2D(f, 0, 2);
      
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of the laplace operator in cylindrical coordinates under the restriction d/dz = 0, 
applied to a 3D field as a matrix. The approximation is second order.

The general form in cylindrical coordinates is

 laplace3D = (1/r)*d/dr(r*d/dr)f + (1/r^2)*d2f/dphi^2 + d2f/dz^2

If the system has translational symmetry, d/dz = 0, 
the remaining coordinates are r ('x-axis') and phi ('y-axis') with

 laplace_r_phi = (1/r)*d/dr(r*d/dr)f + (1/r^2)*d2f/dphi^2

>>> PUT THE CORRECT DIFFERENTIAL OPERATORS INTO THE EQUATIONS LATER.

THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-80; 80,100],   style(color=1, rgbcolor={255,
                  0,0})),
                Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end laplace_r_phi;
    
  function nder1D "Normal derivative 1D" 
      import PDE.FDM.DifferentialOperators.NormalDiffOrd2.*;
      
    input Fields.Field1D f;
    input Integer N(min=0,max=2)=1 "# derivative";
    input Boolean side "begin-side=true, end-side=false";
    output Real f_n;
    protected 
    Real dx;
  algorithm 
    // preliminary:
    dx := f.domain.grid.x[2] - f.domain.grid.x[1];
      
    f_n := if N == 0 then ndiff1D_0(f.val, dx, side) else 
           if N == 1 then ndiff1D_1(f.val, dx, side) else 
           if N == 2 then ndiff1D_2(f.val, dx, side) else 
           0;
    annotation( Documentation(info="<HTML>
<pre>
Returns the value of the normal derivative of a 1D field at the boundary as a scalar.
The approximation is second order. 

Sign-convention:
 We choose the outer normal in accordance with flow-variables defined positive, when flowing into device.


THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end nder1D;
    
  function nder2Dx "Normal derivative 1D, x-direction" 
      import PDE.FDM.DifferentialOperators.NormalDiffOrd2.*;
      
    input Fields.Field2D f;
    input Integer N(min=0,max=2)=1 "# derivative";
    input Boolean side "begin-side=true, end-side=false";
    //output Real f_n[f.domain.grid.n[2]]; ???
    output Real f_n[size(f.val,2)];
    protected 
    Real dx1;
  algorithm 
    // preliminary:
    dx1 := f.domain.grid.x1[2] - f.domain.grid.x1[1];
      
    f_n := if N==0 then ndiff2D_0(f.val, dx1, side) else 
           if N==1 then ndiff2D_1(f.val, dx1, side) else 
           if N==2 then ndiff2D_2(f.val, dx1, side) else 
           zeros(size(f.val,2));
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of first or second spatial derivative of a 2D field as a vector.
The approximation is second order. 

Sign-convention:
 We choose the outer normal in accordance with flow-variables defined positive, when flowing into device.


THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end nder2Dx;
    
  function nder2Dy "Normal derivative 1D, x-direction" 
      import PDE.FDM.DifferentialOperators.NormalDiffOrd2.*;
      
    input Fields.Field2D f;
    input Integer N(min=0,max=2)=1 "# derivative";
    input Boolean side "begin-side=true, end-side=false";
    //output Real f_n[f.domain.grid.n[1]-2]; ???
    output Real f_n[size(f.val,1) - 2];
    protected 
    Real dx2;
  algorithm 
  // preliminary:
    dx2 := f.domain.grid.x2[2] - f.domain.grid.x2[1];
      
    f_n := if N==0 then ndiff2D_0(transpose(f.val[2:end-1,:]), dx2, side) else 
           if N==1 then ndiff2D_1(transpose(f.val[2:end-1,:]), dx2, side) else 
           if N==2 then ndiff2D_2(transpose(f.val[2:end-1,:]), dx2, side) else 
           zeros(size(f.val,1) - 2);
    annotation( Documentation(info="<HTML>
<pre>
Returns the values of first or second spatial derivative of a 2D field as a vector.
The approximation is second order. 

Sign-convention:
 We choose the outer normal in accordance with flow-variables defined positive, when flowing into device.


THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end nder2Dy;
    
  function zero1D "Zero field 1D" 
      
    input Fields.Field1D f;
    //output Real fzero[f.domain.grid.n-2]; ???
    output Real fzero[size(f.val,1)-2];
  algorithm 
    fzero := zeros(f.domain.grid.n-2);
    annotation( Documentation(info="<HTML>
<pre>
Returns zero restricted to the interior of the domain 1D as a vector.


THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end zero1D;
    
  function zero2D "Zero field 2D" 
      
    input Fields.Field2D f;
    //output Real fzero[f.domain.grid.n[1]-2, f.domain.grid.n[2]-2]; ???
    output Real fzero[size(f.val,1)-2, size(f.val,2)-2];
  algorithm 
    fzero := zeros(f.domain.grid.n[1]-2, f.domain.grid.n[2]-2);
    annotation( Documentation(info="<HTML>
<pre>
Returns zero restricted to the interior of the domain 2D as a vector.


THIS IS STILL A COPY FROM PACKAGE FDM!
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=79, rgbcolor={170,
                  85,255}))));
  end zero2D;
    
package DiffOrd2 "First and second spatial derivative" 
      
  function diff1D_1 "First derivative 1D" 
    input Real u[:];
    input Real dx;
    output Real u_x[size(u, 1) - 2];
    //constant Integer c20[3]={-1,0,1} "2*weights, central pt";
  algorithm 
    u_x := (-u[1:end - 2] + u[3:end])/(2*dx);
        
  /* boundary included:
  constant Integer c21[3]={-3,4,-1} "2*weights, central pt +-1";
  u_x := cat(1, {c21*u[1:3]}, -u[1:end - 2] + u[3:end], -{c21*u[end:-1:
    end - 2]})/(2*dx);
*/
    annotation( Documentation(info="<HTML>
<pre>
First spatial derivative in 1D, 2nd order symmetric. Ordinary polynomials.
Returns derivatives restricted to interior points.
</pre>
</HTML>"));
  end diff1D_1;
      
  function diff1D_2 "Second derivative 1D" 
    input Real u[:];
    input Real dx;
    output Real u_xx[size(u, 1) - 2];
    //constant Integer c20[3]={1,-2,1} "weights, central pt";
  algorithm 
    u_xx := (u[3:end] - 2*u[2:end - 1] + u[1:end - 2])/(dx*dx);
        
  /* boundary included:
  constant Integer c3bd[4]={2,-5,4,-1} "weights, 3rd order boundary pt";
  u_xx := cat(1, {c3bd*u[1:4]}, u[3:end] - 2*u[2:end - 1] + u[1:end - 2],
   {c3bd*u[end:-1:end - 3]})/(dx*dx);
*/
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative in 1D, 2nd order symmetric. Ordinary polynomials.
Returns derivatives restricted to interior points.
</pre>
</HTML>"));
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative. Ordinary polynomials.
Interior points 2nd order symmetric,
boundary points 3rd order one-sided.
</pre>
</HTML>"));
  end diff1D_2;
      
      annotation( Documentation(info="<HTML>
<pre>
Central differences (the derivatives are only taken in the interior of the domain).
Second order approximation with ordinary polynomials.
</pre>
</HTML>"));
      
  function diff2D_1 "First derivative 2D" 
    input Real u[:,:];
    input Real dx;
    output Real u_x[size(u, 1) - 2, size(u, 2) - 2];
    //constant Integer c20[3]={-1,0,1} "2*weights, central pt";
  algorithm 
    u_x := (-u[1:end - 2,2:end-1] + u[3:end,2:end-1])/(2*dx);
        
  /* boundary included:
  constant Integer c21[3]={-3,4,-1} "2*weights, central pt +-1";
  u_x := cat(1, {c21*u[1:3,:]}, -u[1:end - 2,:] + u[3:end,:], -{c21*u[end:-1:
    end - 2,:]})/(2*dx);
*/
    annotation( Documentation(info="<HTML>
<pre>
First spatial derivative in 2D, 2nd order symmetric. Ordinary polynomials.
Returns derivatives restricted to interior points.
</pre>
</HTML>"));
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative. Ordinary polynomials.
Interior points 2nd order symmetric,
boundary points 3rd order one-sided.
</pre>
</HTML>"));
  end diff2D_1;
      
  function diff2D_2 "Second derivative 2D" 
    input Real u[:,:];
    input Real dx;
    output Real u_xx[size(u, 1) - 2, size(u, 2) - 2];
    //constant Integer c20[3]={1,-2,1} "weights, central pt";
  algorithm 
    u_xx := (u[3:end,2:end-1] - 2*u[2:end - 1,2:end-1] + u[1:end - 2,2:end-1])/(dx*dx);
        
  /* boundary included:
  constant Integer c3bd[4]={2,-5,4,-1} "weights, 3rd order boundary pt";
  u_xx := cat(1, {c3bd*u[1:4],:}, u[3:end,:] - 2*u[2:end - 1,:] + u[1:end - 2,:],
   {c3bd*u[end:-1:end - 3],:})/(dx*dx);
*/
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative in 2D, 2nd order symmetric. Ordinary polynomials.
Returns derivatives restricted to interior points.
</pre>
</HTML>"));
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative. Ordinary polynomials.
Interior points 2nd order symmetric,
boundary points 3rd order one-sided.
</pre>
</HTML>"));
  end diff2D_2;
end DiffOrd2;
    
package NormalDiffOrd2 "First and second normal derivative at boundary" 
  function ndiff1D_0 "Zero derivative 1D" 
    input Real u[:];
    input Real dx;
    input Boolean side;
    output Real u_x;
  algorithm 
        
    if side then
      u_x := u[1];
          
    else
      u_x := u[end];
          
    end if;
    annotation( Documentation(info="<HTML>
<pre>
Zero normal derivative in 1D = function-value.
side == true: 'left' side.
</pre>
</HTML>"));
  end ndiff1D_0;
      
  function ndiff1D_1 "First derivative 1D" 
    input Real u[:];
    input Real dx;
    input Boolean side;
    output Real u_x;
      protected 
    constant Integer c21[3]={-3,4,-1} "2*weights, central pt +-1";
  algorithm 
        
    if side then
      u_x := -c21*u[1:3]/(2*dx);
    else
      u_x := +c21*u[end:-1:end-2]/(2*dx);
    end if;
    annotation( Documentation(info="<HTML>
<pre>
First normal derivative in 1D, 2nd order one-sided. Ordinary polynomials.
side == true: 'left' side.
</pre>
</HTML>"));
  end ndiff1D_1;
      
  function ndiff1D_2 "Second derivative 1D" 
    input Real u[:];
    input Real dx;
    input Boolean side;
    output Real u_xx;
      protected 
    constant Integer c3bd[4]={2,-5,4,-1} "weights, 3rd order boundary pt";
  algorithm 
        
    if side then
      u_xx := -c3bd*u[1:4]/(dx*dx);
    else
      u_xx := +c3bd*u[end:-1:end-3]/(dx*dx);
    end if;
    annotation( Documentation(info="<HTML>
<pre>
Second normal derivative in 1D, 3rd order one-sided. Ordinary polynomials.
side == true: 'left' side.
</HTML>"));
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative. Ordinary polynomials.
Interior points 2nd order symmetric,
boundary points 3rd order one-sided.
</pre>
</HTML>"));
  end ndiff1D_2;
      
      annotation( Documentation(info="<HTML>
<pre>
One sided differences at boundary points.
Second/third order approximation with ordinary polynomials. 

Sign-convention:
 We choose the outer normal in accordance with flow-variables defined positive, when flowing into device.
</pre>
</HTML>"));
      
  function ndiff2D_0 "First derivative 2D" 
    input Real u[:,:];
    input Real dx;
    input Boolean side;
    output Real u_x[size(u, 2)];
  algorithm 
        
    if side then
      u_x := u[1,:];
    else
      u_x := u[end,:];
    end if;
    annotation( Documentation(info="<HTML>
<pre>
Zero normal derivative in 2D = function-value.
side == true: 'left' or 'lower' side.
</pre>
</HTML>"));
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative. Ordinary polynomials.
Interior points 2nd order symmetric,
boundary points 3rd order one-sided.
</pre>
</HTML>"));
  end ndiff2D_0;
      
  function ndiff2D_1 "First derivative 2D" 
    input Real u[:,:];
    input Real dx;
    input Boolean side;
    output Real u_x[size(u, 2)];
      protected 
    constant Integer c21[3]={-3,4,-1} "2*weights, central pt +-1";
  algorithm 
        
    if side then
      u_x := -c21*u[1:3,:]/(2*dx);
          
    else
      u_x := +c21*u[end:-1:end-2,:]/(2*dx);
          
    end if;
    annotation( Documentation(info="<HTML>
<pre>
First normal derivatives in 2D, 2nd order one-sided. Ordinary polynomials.
side == true: 'left' or 'lower' side.
</pre>
</HTML>"));
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative. Ordinary polynomials.
Interior points 2nd order symmetric,
boundary points 3rd order one-sided.
</pre>
</HTML>"));
  end ndiff2D_1;
      
  function ndiff2D_2 "Second derivative 2D" 
    input Real u[:,:];
    input Real dx;
    input Boolean side;
    output Real u_xx[size(u, 2)];
      protected 
    constant Integer c3bd[4]={2,-5,4,-1} "weights, 3rd order boundary pt";
  algorithm 
        
    if side then
      u_xx := -c3bd*u[1:4,:]/(dx*dx);
          
    else
      u_xx := +c3bd*u[end:-1:end-3,:]/(dx*dx);
          
    end if;
    annotation( Documentation(info="<HTML>
<pre>
Second normal derivatives in 2D, 3rd order one-sided. Ordinary polynomials.
side == true: 'left' or 'lower' side.
</pre>
</HTML>"));
    annotation( Documentation(info="<HTML>
<pre>
Second spatial derivative. Ordinary polynomials.
Interior points 2nd order symmetric,
boundary points 3rd order one-sided.
</pre>
</HTML>"));
  end ndiff2D_2;
end NormalDiffOrd2;
end DifferentialOperators;
  
  package IntegralOperators 
    function gaussLegendreFormula 
       input Integer n;
       output Real x[n];
       output Real w[n];
    protected 
       constant Real pi=Modelica.Constants.pi;
       constant Real eps=Modelica.Constants.eps;
       Integer m;
       Real xm;
       Real xl;
       Real z;
       Real z1;
       Real pp;
       Real p1;
       Real p2;
       Real p3;
    algorithm 
      x:=zeros(n);
      w:=zeros(n);
      m:=integer((n+1)/2);
      xm:=0.0;
      xl:=1.0;
      for i in 1:m loop
        z:=cos(pi*(i-0.25)/(n+0.5));
        z1:=z+2*eps;
        while (abs(z-z1)>eps) loop
          p1:=1.0;
          p2:=0.0;
          for j in 1:n loop
            p3:=p2;
            p2:=p1;
            p1:=((2.0*j-1.0)*z*p2-(j-1.0)*p3)/j;
          end for;
          pp:=n*(z*p1-p2)/(z*z-1.0);
          z1:=z;
          z:=z1-p1/pp;
        end while;
        x[i]:=xm-xl*z;
        x[n+1-i]:=xm+xl*z;
        w[i]:=2.0*xl/((1.0-z*z)*pp*pp);
        w[n+1-i]:=w[i];
      end for;
    end gaussLegendreFormula;
  end IntegralOperators;
  
package DomainOperators 
    "Domain operators return the values of the field on the interior of the domain"
    
    
  function interior1D "Field in the interior of 2D domain" 
    input Integer nVertices;
    input Real vertices[nVertices,2];
    output Real interior[nVertices];
      
  algorithm 
    interior:=zeros(nVertices);
    for i in 1:nVertices loop
       interior[i] := if vertices[i,2] > 0 then 0 else 1;
    end for;
      annotation( Documentation(info="<HTML>
<pre>
Returns a vector with value 0 for boundary-vertices and 1 for other vertices .
</pre>
</HTML>
"));
  end interior1D;
    
  function interior2D "Field in the interior of 2D domain" 
    input Integer nVertices;
    input Real vertices[nVertices,3];
    output Real interior[nVertices];
      
  algorithm 
    interior:=zeros(nVertices);
    for i in 1:nVertices loop
       interior[i] := if vertices[i,3] > 0 then 0 else 1;
    end for;
      annotation( Documentation(info="<HTML>
<pre>
Returns a vector with value 0 for boundary-vertices and 1 for other vertices .
</pre>
</HTML>
"));
  end interior2D;
  annotation( Documentation(info=""),
           Icon);
    
end DomainOperators;
  
package Graphical "Graphical definitions" 
  function defineBdCurve 
      "'Draws' boundary curve and defines index of boundary conditions" 
      
    constant Real xRectangle[4,2]=[0,0;1,0;1,1;0,1] "Example data";
    output Elements.Curve2D bdCurve;
  algorithm 
    bdCurve.typeCurve := ones(size(xRectangle,1));
    bdCurve.auxCurve := fill(1,1); //desired would be: fill(1,0), see ComposedCurve2D!
    bdCurve.x := xRectangle;
    annotation(Documentation(info="<HTML>
<pre>
This function replaces a generic graphical specification of the boundary. 
The present example is a rectangle with all sides of curve type 1 and no auxiliary data.
</pre>
</HTML>"));
  end defineBdCurve;
    
  function defineBdConditions 
      "'Draws' boundary curve and defines index of boundary conditions" 
      
    output Boundaries.BdConditions2D bdCond;
  algorithm 
    bdCond.type_bc := [1;0;1;0];
    annotation(Documentation(info="<HTML>
<pre>
This function replaces a generic graphical specification of the boundary conditions. 
The present example is a rectangle with:
 Index = 0 (for example for Dirichlet conditions) on left and right side,
 Index = 1 (for example for Neumann conditions) on lower and upper side.
</pre>
</HTML>"));
  end defineBdConditions;
    
  function convtoPolygon "Polygone conversion of boundary" 
      
    input Boundaries.Boundary2D boundary;
    output Elements.Polygon2D polygon;
  algorithm 
    polygon.x := boundary.curve.x;
    annotation(Documentation(info="<HTML>
<pre>
This function converts a boundary to a polygone. 
Nonlinear curves are represented in a polygone-approximation. This is not yet contained here!
</pre>
</HTML>"));
  end convtoPolygon;
    annotation(Documentation(info="<HTML>
<pre>
Marks elements of a furture GUI for drawing boundaries and specifying boundary conditions.
</pre>
</HTML>"));
end Graphical;
  
  package Autonomous "Autonomous PDE's without connectors" 
    model Poisson1D "Poisson problem 2D" 
      
    model Equation "Poisson equation 2D" 
        
      function interior = DomainOperators.interior1D;
        
      parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
      parameter Integer type_bc[2,1]=[0;1] 
          "Boundary condition {left, right} (D=0, N=1)";
      parameter Real g0=0.1 "Constant value of rhs";
      parameter Real refine(min=0,max=1)=0.9 "0 < refine < 1, less is finer";
        
      parameter Domains.Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2]), bcond(type_bc=[type_bc])), grid(refine=refine));
      Fields.Field1D field(domain=interval);
      parameter SpecialFields.Const1D g_rhs(c=g0, domain=interval);
        
      protected 
      parameter Real Lg[:,:]=  assemble(interval.grid.ni, interval.grid.nv, interval.grid.interval, interval.grid.x, g_rhs.val);
      parameter Real LgBd[:,:]=  assembleBd(interval.grid.nb, interval.grid.nv, interval.grid.bdpoint, interval.grid.x, Lg, interval.boundary.bcond.type_bc);
      parameter Real Laplace[interval.grid.nv, interval.grid.nv]=  LgBd[1:interval.grid.nv, 1:interval.grid.nv];
      parameter Real g[interval.grid.nv]=  LgBd[1:interval.grid.nv, interval.grid.nv+1];
        
    equation 
      -Laplace*field.val = g;
    end Equation;
      
    function assemble "Assembles stiffness and mass matrix" 
        input Integer nIntervals;
        input Integer nVertices;
        input Integer intervals[nIntervals,3];
        input Real vertices[nVertices,2];
        input Real g_val[nVertices];
        output Real Ab[nVertices, nVertices+1];
      protected 
        Integer Ik[2];
        Real Ak[2,2];
        Real Lk[2];
        
        Integer i;
        Integer j;
    algorithm 
      Ab:=zeros(nVertices, nVertices+1);
        
      for k in 1:nIntervals loop
         Ik := intervals[k,1:2];
         (Ak,Lk):=element(vertices[Ik,1],g_val[Ik]);
          
         for local_1 in 1:2 loop
            i:=Ik[local_1];
            
            for local_2 in 1:2 loop
              j:=Ik[local_2];
              Ab[i,j] := Ab[i,j] - Ak[local_1,local_2];
              
            end for;
            Ab[i, nVertices+1] := Ab[i, nVertices+1] + Lk[local_1];
            
         end for;
      end for;
    end assemble;
      
    function assembleBd 
        input Integer nBdPoints;
        input Integer nVertices;
        input Integer bdpoints[nBdPoints,2];
        input Real vertices[nVertices,2];
        input Real Ab[nVertices, nVertices+1];
        input Integer type_bc[:,:];
        output Real AbBd[nVertices, nVertices+1];
      protected 
        Real v[2];
        
    algorithm 
      AbBd := Ab;
        
      for i in 1:nBdPoints loop
          
         if bdpoints[i,2] > 0 then
           v := vertices[bdpoints[i,1],:];
           if type_bc[integer(bdpoints[i,2]),1] == 0 then
              
             for j in 1:nVertices loop
               AbBd[bdpoints[i,1],j] := 0;
             end for;
             AbBd[bdpoints[i,1], bdpoints[i,1]] := 1;
             // Put inhomogenous Dirichlet conditions here!!
             AbBd[bdpoints[i,1], nVertices+1] := 0;
              
           else
             // Put inhomogenous Neumann conditions here!!
             AbBd[bdpoints[i,1], nVertices+1] := 0;
              
           end if;
            
         end if;
          
      end for;
        
          annotation(Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
    end assembleBd;
      
      function element "Stiffness contributions per triangle" 
          input Real P[2];
          input Real g[2];
          output Real Ak[2,2];
          output Real Lk[2];
      protected 
          parameter Integer p=2;
          Real x[p];
          Real w[p];
          Real l[p];
          Real h;
          Real px;
          Real N1[p];
          Real N2[p];
          function gauleg = IntegralOperators.gaussLegendreFormula;
        
      algorithm 
          h := abs(P[2]-P[1]);
          Ak := 2/h*[1/2, -1/2; -1/2, 1/2];
        
          (x,w):=gauleg(2);
          for i in 1:p loop
            px := P[1] + h/2*(1+x[i]);
            l[i] := (g[1]*(px-P[1])+g[2]*(P[2]-px))/(P[2]-P[1]);
          end for;
        
          N1 := (ones(size(x,1)) - x)/2;
          N2 := (ones(size(x,1)) + x)/2;
        
          Lk[1] := diagonal(N1)*l*w;
          Lk[2] := diagonal(N2)*l*w;
          Lk := h/2*Lk;
        
      end element;
      
        annotation( Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 

 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)

together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80,80; 80,-80], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,80; -100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,80; 100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Text(
            extent=[60,-20; -60,0],
            style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1),
            string="Poisson 2D"),
          Line(points=[-70,100; 70,100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1)),
          Line(points=[-70,-100; 70,-100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1))));
        annotation( Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80,80; 80,-80], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,80; -100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,80; 100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Text(
            extent=[60,-20; -60,0],
            style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1),
            string="Poisson 2D"),
          Line(points=[-70,100; 70,100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1)),
          Line(points=[-70,-100; 70,-100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1))));
      
    end Poisson1D;
    
    model Diffusion1D "Poisson problem 2D" 
      
    model Equation "Poisson equation 2D" 
        
      function interior = DomainOperators.interior1D;
        
      parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
      parameter Integer type_bc[2,1]=[0;0] 
          "Boundary condition {left, right} (D=0, N=1)";
      parameter Real g0=0.1 "Constant value of rhs";
      parameter Real refine(min=0,max=1)=0.9 "0 < refine < 1, less is finer";
        
      parameter Domains.Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2]), bcond(type_bc=[type_bc])), grid(refine=refine));
      Fields.Field1D field(domain=interval);
      parameter SpecialFields.Const1D g_rhs(c=g0, domain=interval);
        
      protected 
      parameter Real AMb[:,:]=  assemble(interval.grid.ni, interval.grid.nv, interval.grid.interval, interval.grid.x, g_rhs.val);
      parameter Real AMbBd[:,:]=  assembleBd(interval.grid.nb, interval.grid.nv, interval.grid.bdpoint, interval.grid.x, AMb, interval.boundary.bcond.type_bc);
      parameter Real Laplace[interval.grid.nv, interval.grid.nv]=  AMbBd[1:interval.grid.nv, 1:interval.grid.nv];
      parameter Real M[interval.grid.nv, interval.grid.nv]=  AMbBd[1:interval.grid.nv, interval.grid.nv+1:2*interval.grid.nv];
      parameter Real g[interval.grid.nv]=  AMbBd[1:interval.grid.nv, 2*interval.grid.nv+1];
        
    equation 
      //diagonal(interior(interval.grid.nv, interval.grid.x))*der(field.val) = Laplace*field.val + g;
      //-Laplace*field.val = g;
      diagonal(interior(interval.grid.nv, interval.grid.x))*M*der(field.val) = Laplace*field.val + g;
    end Equation;
      
    function assemble "Assembles stiffness and mass matrix" 
        input Integer nIntervals;
        input Integer nVertices;
        input Integer intervals[nIntervals,3];
        input Real vertices[nVertices,2];
        input Real g_val[nVertices];
        output Real AMb[nVertices, 2*nVertices+1];
      protected 
        Integer Ik[2];
        Real Ak[2,2];
        Real Mk[2,2];
        Real Lk[2];
        
        Integer i;
        Integer j;
    algorithm 
      AMb:=zeros(nVertices, 2*nVertices+1);
        
      for k in 1:nIntervals loop
         Ik := intervals[k,1:2];
         (Ak,Mk,Lk):=element(vertices[Ik,1],g_val[Ik]);
          
         for local_1 in 1:2 loop
            i:=Ik[local_1];
            
            for local_2 in 1:2 loop
              j:=Ik[local_2];
              AMb[i,j] := AMb[i,j] - Ak[local_1,local_2];
              AMb[i, nVertices+j] := AMb[i, nVertices+j] + Mk[local_1,local_2];
              
            end for;
            AMb[i, 2*nVertices+1] := AMb[i, 2*nVertices+1] + Lk[local_1];
            
         end for;
      end for;
    end assemble;
      
    function assembleBd 
        input Integer nBdPoints;
        input Integer nVertices;
        input Integer bdpoints[nBdPoints,2];
        input Real vertices[nVertices,2];
        input Real AMb[nVertices, 2*nVertices+1];
        input Integer type_bc[:,:];
        output Real AMbBd[nVertices, 2*nVertices+1];
      protected 
        Real v[2];
        
    algorithm 
      AMbBd := AMb;
        
      for i in 1:nBdPoints loop
          
         if bdpoints[i,2] > 0 then
           v := vertices[bdpoints[i,1],:];
           if type_bc[integer(bdpoints[i,2]),1] == 0 then
              
             for j in 1:2*nVertices loop
               AMbBd[bdpoints[i,1],j] := 0;
             end for;
             AMbBd[bdpoints[i,1], bdpoints[i,1]] := 1;
             // Put inhomogenous Dirichlet conditions here!!
             AMbBd[bdpoints[i,1], 2*nVertices+1] := 0;
              
           else
             // Put inhomogenous Neumann conditions here!!
             AMbBd[bdpoints[i,1], 2*nVertices+1] := 0;
              
           end if;
            
         end if;
          
      end for;
        
          annotation(Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
    end assembleBd;
      
      function element "Stiffness contributions per triangle" 
          input Real P[2];
          input Real g[2];
          output Real Ak[2,2];
          output Real Mk[2,2];
          output Real Lk[2];
      protected 
          parameter Integer p=2;
          Real x[p];
          Real w[p];
          Real l[p];
          Real h;
          Real px;
          Real N1[p];
          Real N2[p];
          function gauleg = IntegralOperators.gaussLegendreFormula;
      algorithm 
          h := abs(P[2]-P[1]);
          Ak := 2/h*[1/2, -1/2; -1/2, 1/2];
        
          (x,w):=gauleg(2);
          for i in 1:p loop
            px := P[1] + h/2*(1+x[i]);
            l[i] := (g[1]*(px-P[1])+g[2]*(P[2]-px))/(P[2]-P[1]);
          end for;
        
          N1 := (ones(size(x,1)) - x)/2;
          N2 := (ones(size(x,1)) + x)/2;
        
          Mk[1,1]:=diagonal(N1)*N1*w;
          Mk[1,2]:=diagonal(N1)*N2*w;
          Mk[2,1]:=Mk[1,2];
          Mk[2,2]:=diagonal(N2)*N2*w;
          Mk:= h/2*Mk;
        
          Lk[1] := diagonal(N1)*l*w;
          Lk[2] := diagonal(N2)*l*w;
          Lk := h/2*Lk;
        
      end element;
      
        annotation( Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 

 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)

together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80,80; 80,-80], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,80; -100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,80; 100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Text(
            extent=[60,-20; -60,0],
            style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1),
            string="Poisson 2D"),
          Line(points=[-70,100; 70,100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1)),
          Line(points=[-70,-100; 70,-100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1))));
        annotation( Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80,80; 80,-80], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,80; -100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,80; 100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Text(
            extent=[60,-20; -60,0],
            style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1),
            string="Poisson 2D"),
          Line(points=[-70,100; 70,100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1)),
          Line(points=[-70,-100; 70,-100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1))));
      
    end Diffusion1D;
    
  model MultiPhysics1D "Problem with multiple equations in 2D" 
      
  model Equation "One of several equations in 1D" 
        
    function interior = DomainOperators.interior1D;
        
    parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
    parameter Integer type_bc[2,2]=[0,0;0,0] 
          "Boundary condition {left, right} (D=0, N=1)";
    parameter Real g10=0.1 "Constant value of rhs";
    parameter Real g20=0.1 "Constant value of rhs";
    parameter Real refine(min=0,max=1)=0.9 "0 < refine < 1, less is finer";
        
    parameter Domains.Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2]), bcond(type_bc=[type_bc])), grid(refine=refine));
    Fields.Field1D f1(domain=interval);
    Fields.Field1D f2(domain=interval);
    parameter SpecialFields.Const1D g1_rhs(c=g10, domain=interval);
    parameter SpecialFields.Const1D g2_rhs(c=g20, domain=interval);
        
      protected 
    parameter Real AMb[:,:]=  assemble(interval.grid.ni, interval.grid.nv, interval.grid.interval, interval.grid.x, g1_rhs.val, g2_rhs.val);
    parameter Real Lg[:,:]=  AMb[1:interval.grid.nv,cat(1,1:interval.grid.nv,{2*interval.grid.nv+1})];
    parameter Real LgBd[:,:]=  assemble1Bd(interval.grid.nb, interval.grid.nv, interval.grid.bdpoint, interval.grid.x, Lg, interval.boundary.bcond.type_bc);
    parameter Real Laplace1[interval.grid.nv, interval.grid.nv]=  LgBd[1:interval.grid.nv, 1:interval.grid.nv];
    parameter Real g1[interval.grid.nv]=  LgBd[1:interval.grid.nv, interval.grid.nv+1];
    parameter Real Laplace2[interval.grid.nv, interval.grid.nv]=  AMbBd[1:interval.grid.nv, 1:interval.grid.nv];
    parameter Real AMbtemp[:,:]=  AMb[1:interval.grid.nv,cat(1,1:2*interval.grid.nv,{2*interval.grid.nv+2})];
    parameter Real AMbBd[:,:]=  assemble2Bd(interval.grid.nb, interval.grid.nv, interval.grid.bdpoint, interval.grid.x, AMbtemp, interval.boundary.bcond.type_bc);
    parameter Real M[interval.grid.nv, interval.grid.nv]=  AMbBd[1:interval.grid.nv, interval.grid.nv+1:2*interval.grid.nv];
    parameter Real g2[interval.grid.nv]=  AMbBd[1:interval.grid.nv, 2*interval.grid.nv+1];
        
      annotation(Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations and boundary conditions in 2D. 
The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
  equation 
    -Laplace1*f1.val = g1;
    //diagonal(interior(interval.grid.nv, interval.grid.x))*der(f2.val) = Laplace2*f2.val + g2;
    // Check M, seems to be a problem due to symbolic transformation
    diagonal(interior(interval.grid.nv, interval.grid.x))*M*der(f2.val) = Laplace2*f2.val + g2;
  end Equation;
      
      annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations 
and different boundary conditions in 2D, an individual set for each field. 
</pre>
</HTML>"),
         Icon(
        Rectangle(extent=[-80,80; 80,-80], style(
            color=62,
            rgbcolor={0,127,127},
            fillColor=7,
            rgbfillColor={255,255,255})),
        Line(points=[-100,80; -100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Line(points=[100,80; 100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Text(
          extent=[60,-20; -60,0],
          style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1),
          string="multi 2D"),
        Line(points=[-70,100; 70,100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1)),
        Line(points=[-70,-100; 70,-100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1))));
      annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations and boundary conditions in 2D. 
The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"),
      Icon(
        Rectangle(extent=[-80,80; 80,-80], style(
            color=62,
            rgbcolor={0,127,127},
            fillColor=7,
            rgbfillColor={255,255,255})),
        Line(points=[-100,80; -100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Line(points=[100,80; 100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Text(
          extent=[60,-20; -60,0],
          style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1),
          string="multi"),
        Line(points=[-70,100; 70,100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1)),
        Line(points=[-70,-100; 70,-100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1))),
      Diagram);
      
  function assemble "Assembles stiffness and mass matrix" 
      input Integer nIntervals;
      input Integer nVertices;
      input Integer intervals[nIntervals,3];
      input Real vertices[nVertices,2];
      input Real g1_val[nVertices];
      input Real g2_val[nVertices];
      output Real AMb[nVertices, 2*nVertices+2];
      protected 
      Integer Ik[2];
      Real Ak[2,2];
      Real Mk[2,2];
      Real Lk1[2];
      Real Lk2[2];
        
      Integer i;
      Integer j;
  algorithm 
    AMb:=zeros(nVertices, 2*nVertices+2);
        
    for k in 1:nIntervals loop
       Ik := intervals[k,1:2];
       (Ak,Mk,Lk1,Lk2):=element(vertices[Ik,1],g1_val[Ik],g2_val[Ik]);
          
       for local_1 in 1:2 loop
          i:=Ik[local_1];
            
          for local_2 in 1:2 loop
            j:=Ik[local_2];
            AMb[i,j] := AMb[i,j] - Ak[local_1,local_2];
            AMb[i, nVertices+j] := AMb[i, nVertices+j] + Mk[local_1,local_2];
              
          end for;
          AMb[i, 2*nVertices+1] := AMb[i, 2*nVertices+1] + Lk1[local_1];
          AMb[i, 2*nVertices+2] := AMb[i, 2*nVertices+2] + Lk2[local_1];
            
       end for;
    end for;
  end assemble;
      
  function assemble1Bd 
      input Integer nBdPoints;
      input Integer nVertices;
      input Integer bdpoints[nBdPoints,2];
      input Real vertices[nVertices,2];
      input Real Ab[nVertices, nVertices+1];
      input Integer type_bc[:,:];
      output Real AbBd[nVertices, nVertices+1];
      protected 
      Real v[2];
        
  algorithm 
    AbBd := Ab;
        
    for i in 1:nBdPoints loop
          
       if bdpoints[i,2] > 0 then
         v := vertices[bdpoints[i,1],:];
         if type_bc[integer(bdpoints[i,2]),1] == 0 then
              
           for j in 1:nVertices loop
             AbBd[bdpoints[i,1],j] := 0;
           end for;
           AbBd[bdpoints[i,1], bdpoints[i,1]] := 1;
           // Put inhomogenous Dirichlet conditions here!!
           AbBd[bdpoints[i,1], nVertices+1] := 0;
              
         else
           // Put inhomogenous Neumann conditions here!!
           AbBd[bdpoints[i,1], nVertices+1] := 0;
              
         end if;
            
       end if;
          
    end for;
        
        annotation(Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
  end assemble1Bd;
      
  function assemble2Bd 
      input Integer nBdPoints;
      input Integer nVertices;
      input Integer bdpoints[nBdPoints,2];
      input Real vertices[nVertices,2];
      input Real AMb[nVertices, 2*nVertices+1];
      input Integer type_bc[:,:];
      output Real AMbBd[nVertices, 2*nVertices+1];
      protected 
      Real v[2];
        
  algorithm 
    AMbBd := AMb;
        
    for i in 1:nBdPoints loop
          
       if bdpoints[i,2] > 0 then
         v := vertices[bdpoints[i,1],:];
         if type_bc[integer(bdpoints[i,2]),1] == 0 then
              
           for j in 1:2*nVertices loop
             AMbBd[bdpoints[i,1],j] := 0;
           end for;
           AMbBd[bdpoints[i,1], bdpoints[i,1]] := 1;
           // Put inhomogenous Dirichlet conditions here!!
           AMbBd[bdpoints[i,1], 2*nVertices+1] := 0;
              
         else
           // Put inhomogenous Neumann conditions here!!
           AMbBd[bdpoints[i,1], 2*nVertices+1] := 0;
              
         end if;
            
       end if;
          
    end for;
        
        annotation(Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
  end assemble2Bd;
      
    function element "Stiffness contributions per triangle" 
        input Real P[2];
        input Real g1[2];
        input Real g2[2];
        output Real Ak[2,2];
        output Real Mk[2,2];
        output Real Lk1[2];
        output Real Lk2[2];
      protected 
        parameter Integer p=2;
        Real x[p];
        Real w[p];
        Real l1[p];
        Real l2[p];
        Real h;
        Real px;
        Real N1[p];
        Real N2[p];
        function gauleg = IntegralOperators.gaussLegendreFormula;
    algorithm 
        h := abs(P[2]-P[1]);
        Ak := 2/h*[1/2, -1/2; -1/2, 1/2];
        
        (x,w):=gauleg(2);
        for i in 1:p loop
          px := P[1] + h/2*(1+x[i]);
          l1[i] := (g1[1]*(px-P[1])+g1[2]*(P[2]-px))/(P[2]-P[1]);
          l2[i] := (g2[1]*(px-P[1])+g2[2]*(P[2]-px))/(P[2]-P[1]);
        end for;
        
        N1 := (ones(size(x,1)) - x)/2;
        N2 := (ones(size(x,1)) + x)/2;
        
        Mk[1,1]:=diagonal(N1)*N1*w;
        Mk[1,2]:=diagonal(N1)*N2*w;
        Mk[2,1]:=Mk[1,2];
        Mk[2,2]:=diagonal(N2)*N2*w;
        Mk:= h/2*Mk;
        
        Lk1[1] := diagonal(N1)*l1*w;
        Lk1[2] := diagonal(N2)*l1*w;
        Lk1 := h/2*Lk1;
        
        Lk2[1] := diagonal(N1)*l2*w;
        Lk2[2] := diagonal(N2)*l2*w;
        Lk2 := h/2*Lk2;
        
    end element;
  end MultiPhysics1D;
    
    model Poisson2D "Poisson problem 2D" 
      
    model Equation "Poisson equation 2D" 
        
      function defineBdCurve = Graphical.defineBdCurve;
      function defineBdConditions = Graphical.defineBdConditions;
        
      parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
      /* Compile twice in order to get a change in grid 
     that is: boundary, grid, and/or boundary conditions*/
        
      parameter Real g0=1 "Constant value of field";
        
      // defineBdConditions() does not return desired values !? 
      //parameter Domains.Domain2D rectangle(boundary(curve=defineBdCurve(),bcond=defineBdConditions()), grid(refine=refine));
      parameter Domains.Domain2D rectangle(boundary(curve=defineBdCurve(), bcond(
                                                                          type_bc     = [1;0;1;0])),grid(refine=refine));
      parameter SpecialFields.Const2D g_rhs(c=g0, domain=rectangle);
      Fields.Field2D field(domain=rectangle);
      protected 
      parameter Real Lg[:,:]=  assemble(rectangle.grid.nt, rectangle.grid.nv, rectangle.grid.triangle, rectangle.grid.x, g_rhs.val);
      parameter Real LgBd[:,:]=  assembleBd(rectangle.grid.ne, rectangle.grid.nv, rectangle.grid.edge, rectangle.grid.x, Lg, rectangle.boundary.bcond.type_bc);
      parameter Real Laplace[rectangle.grid.nv, rectangle.grid.nv]=  LgBd[1:rectangle.grid.nv, 1:rectangle.grid.nv];
      parameter Real g[rectangle.grid.nv]=  LgBd[1:rectangle.grid.nv, rectangle.grid.nv+1];
        
    equation 
      -Laplace*field.val = g;
        
        annotation(Documentation(info="<HTML>
<pre>
The Poisson equation in 2D for a field f(x) is defined as 

 0 = lambda*(d2f/dx^2 + d2f/dy^2) + g(x,y)

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
    end Equation;
      
    function assemble "Assembles stiffness and mass matrix" 
        input Integer nTriangles;
        input Integer nVertices;
        input Integer triangles[nTriangles,4];
        input Real vertices[nVertices,3];
        input Real g_val[:];
        output Real Ab[nVertices, nVertices+1];
      protected 
        Integer Tk[3];
        Real Ak[3,3];
        Real Lk[3];
        
        Integer i;
        Integer j;
    algorithm 
      Ab:=zeros(nVertices, nVertices+1);
        
      for k in 1:nTriangles loop
         Tk := triangles[k,1:3];
         (Ak,Lk):=element(vertices[Tk,1],vertices[Tk,2],g_val[Tk]);
          
         for local_1 in 1:3 loop
            i:=Tk[local_1];
            for local_2 in 1:3 loop
              j:=Tk[local_2];
              Ab[i,j] := Ab[i,j]-Ak[local_1,local_2];
            end for;
            Ab[i, nVertices+1] := Ab[i, nVertices+1] + Lk[local_1];
            
         end for;
          
      end for;
        
        annotation(Documentation(info="<HTML>
<pre>
Assembles the stiffness and mass matrix according to the differential equation.
The boundary conditions are treated separately. 
</pre>
</HTML>"));
    end assemble;
      
    function assembleBd "Includes boundary conditions into stiffnes matrix" 
        
        input Integer nEdges;
        input Integer nVertices;
        input Integer edges[nEdges,3];
        input Real vertices[nVertices,3];
        input Real Ab[nVertices, nVertices+1];
        input Integer type_bc[:,:];
        output Real AbBd[nVertices, nVertices+1];
      protected 
        Real v[2,3];
        
    algorithm 
      AbBd := Ab;
        
      for i in 1:nEdges loop
          
         if edges[i,3] > 0 then
           v := vertices[edges[i,1:2],:];
           //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
            
           if type_bc[integer(edges[i,3]),1] == 0 then
              
             for j in 1:nVertices loop
               AbBd[edges[i,1],j] := 0;
               AbBd[edges[i,2],j] := 0;
                
             end for;
             AbBd[edges[i,1], edges[i,1]] := 1;
             AbBd[edges[i,2], edges[i,2]] := 1;
             // Put inhomogenous Dirichlet conditions here!!
             AbBd[edges[i,1], nVertices+1] := 0;
             AbBd[edges[i,2], nVertices+1] := 0;
              
           else
             // Put inhomogenous Neumann conditions here!!
             AbBd[edges[i,1], nVertices+1] := 0;
             AbBd[edges[i,2], nVertices+1] := 0;
              
           end if;
            
         end if;
          
      end for;
        
        annotation(Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
    end assembleBd;
      
      function element "Stiffness contributions per triangle" 
           input Real Px[3];
           input Real Py[3];
           input Real g[3];
           output Real Ak[3,3];
           output Real Lk[3];
      protected 
           Real md;
           Real mk;
           Real detk;
           Real F;
           Integer l;
           Integer j;
           Integer k;
      algorithm 
          // Get midpoint of triangle
          // Calculate corresponding length of dual grid edge sk[3]
          // Determine corresponding area contribution Fk[3]
          // Calculate lengths of edges ek[3]
          // Right-Hand side is taken into account using values on the vertices 
          detk := abs((Px[2]-Px[1])*(Py[3]-Py[1]) - (Px[3]-Px[1])*(Py[2]-Py[1]));
          F := detk/2;
        
          for i in 1:3 loop
          
            for j in i+1:3 loop
              l := if i+j==3 then 3 else 
                        if i+j==4 then 2 else 
                        1;
              Ak[i,j] := 1/2/detk*((Px[i]-Px[l])*(Px[l]-Px[j]) + (Py[i]-Py[l])*(Py[l]-Py[j]));
              Ak[j,i] := Ak[i,j];
            
            end for;
          
          end for;
        
          for i in 1:3 loop
            j := if i==1 then 2 else 
                      if i==2 then 3 else 
                      1;
            k := if i==1 then 3 else 
                      if i==2 then 1 else 
                      2;
            Ak[i,i] := 1/2/detk*((Px[j]-Px[k])^2 + (Py[j]-Py[k])^2);
          
          end for;
          md := 1/12*(Py[1]*(Px[3]-Px[2]) + Py[2]*(Px[1]-Px[3]) + Py[3]*(Px[2]-Px[1]));
          mk := 1/24*(Py[1]*(Px[3]-Px[2]) + Py[2]*(Px[1]-Px[3]) + Py[3]*(Px[2]-Px[1]));
          Lk := {md*g[1] + mk*g[2] + mk*g[3],
                 mk*g[1] + md*g[2] + mk*g[3],
                 mk*g[1] + mk*g[2] + md*g[3]};
        annotation(Documentation(info="Idea:
Run through the triangles and get contribution to the discretization matrix. Within the context of Finite Volumn methods it is not called Stiffness matrix (look up right formalism!). Contribution is given by calculating the dual grid-information. This approach only works properly, if the triangulation has no angles above 90 degrees.   "));
      end element;
      
        annotation( Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 

 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)

together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80,80; 80,-80], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,80; -100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,80; 100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Text(
            extent=[60,-20; -60,0],
            style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1),
            string="Poisson 2D"),
          Line(points=[-70,100; 70,100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1)),
          Line(points=[-70,-100; 70,-100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1))));
        annotation( Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80,80; 80,-80], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,80; -100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,80; 100,-80], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Text(
            extent=[60,-20; -60,0],
            style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1),
            string="Poisson 2D"),
          Line(points=[-70,100; 70,100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1)),
          Line(points=[-70,-100; 70,-100], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2,
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1))));
      
    end Poisson2D;
    
  model Diffusion2D "Diffusion problem 2D" 
      
  model Equation "Diffusion equation 2D" 
        
    function defineBdCurve = Graphical.defineBdCurve;
    function defineBdConditions = Graphical.defineBdConditions;
    function interior = DomainOperators.interior2D;
        
    parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
    /* Compile twice in order to get a change in grid 
     that is: boundary, grid, and/or boundary conditions*/
        
    parameter Real g0=1 "Constant value of field";
        
    // defineBdConditions() does not return desired values !? 
    // parameter Domains.Domain2D rectangle(boundary(curve=defineBdCurve(),bcond=defineBdConditions()), grid(refine=refine));
    parameter Domains.Domain2D rectangle(boundary(curve=defineBdCurve(), bcond(type_bc=  [1;0;1;0])),grid(refine=refine));
    parameter SpecialFields.Const2D g_rhs(c=g0, domain=rectangle);
    Fields.Field2D field(domain=rectangle);
      protected 
    parameter Real AMb[:,:]=  assemble(rectangle.grid.nt, rectangle.grid.nv, rectangle.grid.triangle, rectangle.grid.x, g_rhs.val);
    parameter Real AMbBd[:,:]=  assembleBd(rectangle.grid.ne, rectangle.grid.nv, rectangle.grid.edge, rectangle.grid.x, AMb, rectangle.boundary.bcond.type_bc);
    parameter Real Laplace[rectangle.grid.nv, rectangle.grid.nv]=  AMbBd[1:rectangle.grid.nv, 1:rectangle.grid.nv];
    parameter Real M[rectangle.grid.nv, rectangle.grid.nv]=  AMbBd[1:rectangle.grid.nv, rectangle.grid.nv+1:2*rectangle.grid.nv];
    parameter Real g[rectangle.grid.nv]=  AMbBd[1:rectangle.grid.nv, 2*rectangle.grid.nv+1];
        
  equation 
    diagonal(interior(rectangle.grid.nv, rectangle.grid.x))*M*der(field.val) = Laplace*field.val + g;
        
        annotation(Documentation(info="<HTML>
<pre>
The Diffusion equation in 2D for a field f(x) is 
 df/dt = lambda*(d2f/dx2 + d2f/dy2) + g(x,y)
The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
  end Equation;
      
  function assemble 
      input Integer nTriangles;
      input Integer nVertices;
      input Integer triangles[nTriangles,4];
      input Real vertices[nVertices,3];
      input Real g_val[:];
      output Real AMb[nVertices, 2*nVertices+1];
      protected 
      Integer Tk[3];
      Real Ak[3,3];
      Real Mk[3,3];
      Real Lk[3];
        
      Integer i;
      Integer j;
  algorithm 
    AMb:=zeros(nVertices, 2*nVertices+1);
        
    for k in 1:nTriangles loop
       Tk := triangles[k,1:3];
       (Ak,Mk,Lk):=element(vertices[Tk,1],vertices[Tk,2],g_val[Tk]);
          
       for local_1 in 1:3 loop
          i:=Tk[local_1];
            
          for local_2 in 1:3 loop
            j:=Tk[local_2];
            AMb[i,j] := AMb[i,j] - Ak[local_1,local_2];
            AMb[i, nVertices+j] := AMb[i, nVertices+j] + Mk[local_1,local_2];
              
          end for;
          AMb[i, 2*nVertices+1] := AMb[i, 2*nVertices+1] + Lk[local_1];
            
       end for;
          
    end for;
        
        annotation(Documentation(info="<HTML>
<pre>
Assembles the stiffness and mass matrix according to the differential equation.
The boundary conditions are treated separately. 
</pre>
</HTML>"));
  end assemble;
      
  function assembleBd 
      input Integer nEdges;
      input Integer nVertices;
      input Integer edges[nEdges,3];
      input Real vertices[nVertices,3];
      input Real AMb[nVertices, 2*nVertices+1];
      input Integer type_bc[:,:];
      output Real AMbBd[nVertices, 2*nVertices+1];
      protected 
      Real v[2,3];
        
  algorithm 
    AMbBd := AMb;
        
    for i in 1:nEdges loop
          
       if edges[i,3] > 0 then
         v := vertices[edges[i,1:2],:];
         //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
            
         if type_bc[integer(edges[i,3]),1] == 0 then
              
           for j in 1:nVertices loop
             AMbBd[edges[i,1],j] := 0;
             AMbBd[edges[i,2],j] := 0;
                
           end for;
           AMbBd[edges[i,1], edges[i,1]] := 1;
           AMbBd[edges[i,2], edges[i,2]] := 1;
           // Put inhomogenous Dirichlet conditions here!!
           AMbBd[edges[i,1], 2*nVertices+1] := 0;
           AMbBd[edges[i,2], 2*nVertices+1] := 0;
              
         else
           // Put inhomogenous Neumann conditions here!!
           AMbBd[edges[i,1], 2*nVertices+1] := 0;
           AMbBd[edges[i,2], 2*nVertices+1] := 0;
              
         end if;
            
       end if;
          
    end for;
        
        annotation(Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
  end assembleBd;
      
    function element "Stiffness contributions per triangle" 
         input Real Px[3];
         input Real Py[3];
         input Real g[3];
         output Real Ak[3,3];
         output Real Mk[3,3];
         output Real Lk[3];
      protected 
         Real md;
         Real mk;
         Real detk;
         Real F;
         Integer l;
         Integer j;
         Integer k;
    algorithm 
        detk := abs((Px[2]-Px[1])*(Py[3]-Py[1]) - (Px[3]-Px[1])*(Py[2]-Py[1]));
        F := detk/2;
        
        for i in 1:3 loop
          
          for j in i+1:3 loop
            l := if i+j==3 then 3 else 
                      if i+j==4 then 2 else 
                      1;
            Ak[i,j] := 1/2/detk*((Px[i]-Px[l])*(Px[l]-Px[j]) + (Py[i]-Py[l])*(Py[l]-Py[j]));
            Ak[j,i] := Ak[i,j];
            
          end for;
          
        end for;
        
        for i in 1:3 loop
          j := if i==1 then 2 else 
                    if i==2 then 3 else 
                    1;
          k := if i==1 then 3 else 
                    if i==2 then 1 else 
                    2;
          Ak[i,i] := 1/2/detk*((Px[j]-Px[k])^2 + (Py[j]-Py[k])^2);
          
        end for;
        md := 1/12*(Py[1]*(Px[3]-Px[2]) + Py[2]*(Px[1]-Px[3]) + Py[3]*(Px[2]-Px[1]));
        mk := 1/24*(Py[1]*(Px[3]-Px[2]) + Py[2]*(Px[1]-Px[3]) + Py[3]*(Px[2]-Px[1]));
        Mk := [md, mk, mk; mk, md, mk; mk, mk, md];
        Lk := Mk*{g[1], g[2], g[3]};
    end element;
      annotation( Documentation(info="<HTML>
<pre>
The Diffusion problem in 2D for a field f(x) is defined by the Diffusion-equation
 df/dt = lambda*(d2f/dx2 + d2f/dy2) + g(x,y)

together with specific boundary conditions.
</pre>
</HTML>"),
         Icon(
        Rectangle(extent=[-80,80; 80,-80], style(
            color=62,
            rgbcolor={0,127,127},
            fillColor=7,
            rgbfillColor={255,255,255})),
        Line(points=[-100,80; -100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Line(points=[100,80; 100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Text(
          extent=[60,-20; -60,0],
          style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1),
          string="Diffusion 2D"),
        Line(points=[-70,100; 70,100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1)),
        Line(points=[-70,-100; 70,-100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1))));
      
  end Diffusion2D;
    
  model MultiPhysics2D "Problem with multiple equations in 2D" 
      
  model Equation "One of several equations in 2D" 
        
    function defineBdCurve = Graphical.defineBdCurve;
    function defineBdConditions = Graphical.defineBdConditions;
    function interior = DomainOperators.interior2D;
        
    parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
    /* Compile twice in order to get a change in grid 
     that is: boundary, grid, and/or boundary conditions*/
        
    parameter Real g10=1 "Constant value of field";
    parameter Real g20=1 "Constant value of field";
        
    // defineBdConditions() does not return desired values !? 
    //parameter Domains.Domain2D rectangle(boundary(curve=defineBdCurve(),bcond=defineBdConditions()), grid(refine=refine));
    parameter Domains.Domain2D rectangle(boundary(curve=defineBdCurve(), bcond(
                                                                        type_bc   = [1;0;1;0])),grid(refine=refine));
    parameter SpecialFields.Const2D g1_rhs(c=g10, domain=rectangle);
    parameter SpecialFields.Const2D g2_rhs(c=g20, domain=rectangle);
        
    Fields.Field2D f1(domain=rectangle);
    Fields.Field2D f2(domain=rectangle);
        
      protected 
    parameter Real AMb[:,:]=  assemble(rectangle.grid.nt, rectangle.grid.nv, rectangle.grid.triangle, rectangle.grid.x, g1_rhs.val, g2_rhs.val);
    parameter Real Lg[:,:]=  AMb[1:rectangle.grid.nv,cat(1,1:rectangle.grid.nv,{2*rectangle.grid.nv+1})];
    //parameter Real LgBd[:,:] = assemble1Bd(rectangle.grid.ne, rectangle.grid.nv, rectangle.grid.edge, rectangle.grid.x, Lg, rectangle.boundary.bcond.type_bc);
    parameter Real LgBd[:,:]=  assemble1Bd(rectangle.grid.ne, rectangle.grid.nv, rectangle.grid.edge, rectangle.grid.x, Lg, [0;1;1;0]);
    parameter Real Laplace1[rectangle.grid.nv, rectangle.grid.nv]=  LgBd[1:rectangle.grid.nv, 1:rectangle.grid.nv];
    parameter Real g1[rectangle.grid.nv]=  LgBd[1:rectangle.grid.nv, rectangle.grid.nv+1];
        
    parameter Real AMbtemp[:,:]=  AMb[1:rectangle.grid.nv,cat(1,1:2*rectangle.grid.nv,{2*rectangle.grid.nv+2})];
    //parameter Real AMbBd[:,:] = assemble2Bd(rectangle.grid.ne, rectangle.grid.nv, rectangle.grid.edge, rectangle.grid.x, AMb, rectangle.boundary.bcond.type_bc);
    parameter Real AMbBd[:,:]=  assemble2Bd(rectangle.grid.ne, rectangle.grid.nv, rectangle.grid.edge, rectangle.grid.x, AMbtemp, [1;0;1;0]);
    parameter Real Laplace2[rectangle.grid.nv, rectangle.grid.nv]=  AMbBd[1:rectangle.grid.nv, 1:rectangle.grid.nv];
    parameter Real M[rectangle.grid.nv, rectangle.grid.nv]=  AMbBd[1:rectangle.grid.nv, rectangle.grid.nv+1:2*rectangle.grid.nv];
    parameter Real g2[rectangle.grid.nv]=  AMbBd[1:rectangle.grid.nv, 2*rectangle.grid.nv+1];
        
  equation 
    -Laplace1*f1.val = g1;
        
    diagonal(interior(rectangle.grid.nv, rectangle.grid.x))*M*der(f2.val) = Laplace2*f2.val + g2;
        
      annotation(Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations and boundary conditions in 2D. 

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
  end Equation;
      
      annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations 
and different boundary conditions in 2D, an individual set for each field. 
</pre>
</HTML>"),
         Icon(
        Rectangle(extent=[-80,80; 80,-80], style(
            color=62,
            rgbcolor={0,127,127},
            fillColor=7,
            rgbfillColor={255,255,255})),
        Line(points=[-100,80; -100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Line(points=[100,80; 100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Text(
          extent=[60,-20; -60,0],
          style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1),
          string="multi 2D"),
        Line(points=[-70,100; 70,100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1)),
        Line(points=[-70,-100; 70,-100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1))));
      annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations and boundary conditions in 2D. 
The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"),
      Icon(
        Rectangle(extent=[-80,80; 80,-80], style(
            color=62,
            rgbcolor={0,127,127},
            fillColor=7,
            rgbfillColor={255,255,255})),
        Line(points=[-100,80; -100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Line(points=[100,80; 100,-80], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2)),
        Text(
          extent=[60,-20; -60,0],
          style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1),
          string="multi"),
        Line(points=[-70,100; 70,100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1)),
        Line(points=[-70,-100; 70,-100], style(
            color=62,
            rgbcolor={0,127,127},
            thickness=2,
            fillColor=7,
            rgbfillColor={255,255,255},
            fillPattern=1))),
      Diagram);
      
  function assemble 
      input Integer nTriangles;
      input Integer nVertices;
      input Integer triangles[nTriangles,4];
      input Real vertices[nVertices,3];
      input Real g1_val[:];
      input Real g2_val[:];
      output Real AMb[nVertices, 2*nVertices+2];
      protected 
      Integer Tk[3];
      Real Ak[3,3];
      Real Mk[3,3];
      Real Lk1[3];
      Real Lk2[3];
        
      Integer i;
      Integer j;
  algorithm 
    AMb:=zeros(nVertices, 2*nVertices+1);
        
    for k in 1:nTriangles loop
       Tk := triangles[k,1:3];
       (Ak,Mk,Lk1,Lk2):=element(vertices[Tk,1],vertices[Tk,2],g1_val[Tk],g2_val[Tk]);
          
       for local_1 in 1:3 loop
          i:=Tk[local_1];
            
          for local_2 in 1:3 loop
            j:=Tk[local_2];
            AMb[i,j] := AMb[i,j] - Ak[local_1,local_2];
            AMb[i, nVertices+j] := AMb[i, nVertices+j] + Mk[local_1,local_2];
              
          end for;
          AMb[i, 2*nVertices+1] := AMb[i, 2*nVertices+1] + Lk1[local_1];
          AMb[i, 2*nVertices+2] := AMb[i, 2*nVertices+2] + Lk2[local_1];
            
       end for;
          
    end for;
        
        annotation(Documentation(info="<HTML>
<pre>
Assembles the stiffness and mass matrix according to the differential equation.
The boundary conditions are treated separately. 
</pre>
</HTML>"));
  end assemble;
      
  function assemble1Bd "Includes boundary conditions into stiffnes matrix" 
        
      input Integer nEdges;
      input Integer nVertices;
      input Integer edges[nEdges,3];
      input Real vertices[nVertices,3];
      input Real Ab[nVertices, nVertices+1];
      input Integer type_bc[:,:];
      output Real AbBd[nVertices, nVertices+1];
      protected 
      Real v[2,3];
        
  algorithm 
    AbBd := Ab;
        
    for i in 1:nEdges loop
          
       if edges[i,3] > 0 then
         v := vertices[edges[i,1:2],:];
         //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
            
         if type_bc[integer(edges[i,3]),1] == 0 then
              
           for j in 1:nVertices loop
             AbBd[edges[i,1],j] := 0;
             AbBd[edges[i,2],j] := 0;
                
           end for;
           AbBd[edges[i,1], edges[i,1]] := 1;
           AbBd[edges[i,2], edges[i,2]] := 1;
           // Put inhomogenous Dirichlet conditions here!!
           AbBd[edges[i,1], nVertices+1] := 0;
           AbBd[edges[i,2], nVertices+1] := 0;
              
         else
           // Put inhomogenous Neumann conditions here!!
           AbBd[edges[i,1], nVertices+1] := 0;
           AbBd[edges[i,2], nVertices+1] := 0;
              
         end if;
            
       end if;
          
    end for;
        
      annotation(Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
  end assemble1Bd;
      
  function assemble2Bd 
      input Integer nEdges;
      input Integer nVertices;
      input Integer edges[nEdges,3];
      input Real vertices[nVertices,3];
      input Real AMb[nVertices, 2*nVertices+1];
      input Integer type_bc[:,:];
      output Real AMbBd[nVertices, 2*nVertices+1];
      protected 
      Real v[2,3];
        
  algorithm 
    AMbBd := AMb;
        
    for i in 1:nEdges loop
          
       if edges[i,3] > 0 then
         v := vertices[edges[i,1:2],:];
         //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
            
         if type_bc[integer(edges[i,3]),1] == 0 then
              
           for j in 1:nVertices loop
             AMbBd[edges[i,1],j] := 0;
             AMbBd[edges[i,2],j] := 0;
                
           end for;
           AMbBd[edges[i,1], edges[i,1]] := 1;
           AMbBd[edges[i,2], edges[i,2]] := 1;
           // Put inhomogenous Dirichlet conditions here!!
           AMbBd[edges[i,1], 2*nVertices+1] := 0;
           AMbBd[edges[i,2], 2*nVertices+1] := 0;
              
         else
           // Put inhomogenous Neumann conditions here!!
           AMbBd[edges[i,1], 2*nVertices+1] := 0;
           AMbBd[edges[i,2], 2*nVertices+1] := 0;
              
         end if;
            
       end if;
          
    end for;
        
        annotation(Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
  end assemble2Bd;
      
    function element "Stiffness contributions per triangle" 
         input Real Px[3];
         input Real Py[3];
         input Real g1[3];
         input Real g2[3];
         output Real Ak[3,3];
         output Real Mk[3,3];
         output Real Lk1[3];
         output Real Lk2[3];
      protected 
         Real md;
         Real mk;
         Real detk;
         Real F;
         Integer l;
         Integer j;
         Integer k;
    algorithm 
        detk := abs((Px[2]-Px[1])*(Py[3]-Py[1]) - (Px[3]-Px[1])*(Py[2]-Py[1]));
        F := detk/2;
        
        for i in 1:3 loop
          
          for j in i+1:3 loop
            l := if i+j==3 then 3 else 
                      if i+j==4 then 2 else 
                      1;
            Ak[i,j] := 1/2/detk*((Px[i]-Px[l])*(Px[l]-Px[j]) + (Py[i]-Py[l])*(Py[l]-Py[j]));
            Ak[j,i] := Ak[i,j];
            
          end for;
          
        end for;
        
        for i in 1:3 loop
          j := if i==1 then 2 else 
                    if i==2 then 3 else 
                    1;
          k := if i==1 then 3 else 
                    if i==2 then 1 else 
                    2;
          Ak[i,i] := 1/2/detk*((Px[j]-Px[k])^2 + (Py[j]-Py[k])^2);
          
        end for;
        md := 1/12*(Py[1]*(Px[3]-Px[2]) + Py[2]*(Px[1]-Px[3]) + Py[3]*(Px[2]-Px[1]));
        mk := 1/24*(Py[1]*(Px[3]-Px[2]) + Py[2]*(Px[1]-Px[3]) + Py[3]*(Px[2]-Px[1]));
        Mk := [md, mk, mk; mk, md, mk; mk, mk, md];
        Lk1 := Mk*{g1[1], g1[2], g1[3]};
        Lk2 := Mk*{g2[1], g2[2], g2[3]};
    end element;
  end MultiPhysics2D;
    annotation(Documentation(info="<HTML>
<pre>
The models Autonomous.* add specific boundary conditions to the corresponding models Equations.*. 
They are used as autonomous models, i.e. there are no connectors defined for 
using the models as components in an ODE environment.
</pre>
</HTML>"));
  end Autonomous;
  
  package Components "PDE objects as components of ODE system" 
  model ThermalResistor2D 
      "Example component 2D to be embedded in ODE environment" 
      annotation( Documentation(info="<HTML>
<pre>
Example of a PDE component containig external connections for current and heat. 

TO BE FINISHED LATER!
- additional functions are needed for integration (current-densities on boundary etc.)
- physically reasonable parameters have to be put in.
</pre>
</HTML>"),   Diagram(
        Line(points=[-90,0; -60,0], style(color=3, rgbcolor={0,0,255})),
        Line(points=[90,0; 60,0], style(color=3, rgbcolor={0,0,255})),
        Line(points=[0,90; 0,60], style(color=42)),
        Line(points=[0,-88; 0,-60], style(color=42))));
    Modelica.Electrical.Analog.Interfaces.PositivePin electrode_p 
      annotation(extent=[-110,-10; -90,12]);
    Modelica.Electrical.Analog.Interfaces.NegativePin electrode_n 
      annotation(extent=[90,-10; 110,10]);
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b heatPort_a 
      annotation(extent=[-10,110; 10,90]);
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b heatPort_b 
      annotation(extent=[-10,-108; 10,-88]);
      Autonomous.MultiPhysics2D ThermalResistor2D 
        annotation(extent=[-60,-60; 60,60]);
  equation 
      
  end ThermalResistor2D;
    annotation(Documentation(info="<HTML>
<pre>
The models Components.* add physically reasonable connectors to the corresponding models Autonomous.*. 
They can be used (hopefully, when everything will work) as components in an ODE environment.
</pre>
</HTML>"));
  end Components;
end FVM;
