package FDM "Partial Differential Equations, Finite Difference Method" 
  
package Boundaries "Contains the definition of boundaries" 
    
  record Boundary1D "Boundary of 1D domain" 
      
    parameter Elements.Point1D left;
    parameter Elements.Point1D right;
    parameter BdConditions1D bcond;
    annotation(
            Documentation(info="<HTML>
<pre>
Boundary of linear one-dimensional spatial domain.
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
      
    parameter Elements.Line2D axis1;
    parameter Elements.Line2D axis2;
    parameter BdConditions2D bcond;
      annotation(Documentation(info="<HTML>
<pre>
Boundary of rectangular two-dimensional spatial domain.
line1 corresponds to the 1-axis, 
line2 corresponds to the 2-axis.
</pre>
</HTML>"));
      
  end Boundary2D;
    
record BdConditions2D "Boundary conditions on boundary curve in R2" 
      
  parameter Integer type_bc_x[2,:]=[0;0] 
        "Type of boundary cond left/right, 2nd index # of field";
  parameter Integer type_bc_y[2,:]=[0;0] 
        "Type of boundary cond lower/upper, 2nd index # of field";
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
    parameter Grids.Grid1D grid(line(x1=boundary.left.x, x2=boundary.right.x));
  annotation(
          Documentation(info="<HTML>
<pre>
Linear one-dimensional spatial domain with grid. 
</pre>
</HTML>"));
      
  end Domain1D;
    
  record Domain2D "2D spatial domain" 
      
    parameter Boundaries.Boundary2D boundary;
    parameter Grids.Grid2D grid(line1(x1=boundary.axis1.x1[1], x2=boundary.axis1.x2[1]),
                      line2(x1=boundary.axis2.x1[2], x2=boundary.axis2.x2[2]));
      
  annotation(
          Documentation(info="<HTML>
<pre>
Rectangular two-dimensional spatial domain with Euclidean grid. 
</pre>
</HTML>"));
      
  end Domain2D;
    
end Domains;
  
package Grids 
    "Contains the definition of discretised domains with given boundaries" 
    
  record Grid1D "1D spatial grid" 
      
    parameter Elements.Line1D line;
    parameter Integer n=2 "Number of grid-points";
    parameter Coordinate x[:]=  grid(line,n) "Coordinates of grid-points";
      
  function grid = FDM.GridGeneration.grid1D "Generation of grid" annotation(
       Documentation(info="<HTML>
<pre>
This function should mark the future generic grid-generator.
</pre>
</HTML>"));
      
  annotation(
          Documentation(info="<HTML>
<pre>
Grid on linear one-dimensional spatial domain.
</pre>
</HTML>"));
      
  end Grid1D;
    
  record Grid2D "2D spatial grid" 
      
    parameter Elements.Line1D line1;
    parameter Elements.Line1D line2;
    parameter Integer n[2]={2,2} "Number of grid-points {x1, x2}";
    parameter Coordinate x1[n[1]]=  grid(line1,n[1]) 
        "Coordinates of grid-points x1";
    parameter Coordinate x2[n[2]]=  grid(line2,n[2]) 
        "Coordinates of grid-points x2";
      
    function grid = FDM.GridGeneration.grid1D "Generation of grid" 
    annotation(
     Documentation(info="<HTML>
<pre>
This function should mark the future generic grid-generator.
</pre>
</HTML>"));
      
  annotation(
          Documentation(info="<HTML>
<pre>
Euclidean grid on rectangular two-dimensional spatial domain.
</pre>
</HTML>"));
      
  end Grid2D;
end Grids;
  
package GridGeneration "Linear grid generator for 1D and 2D" 
    
  annotation( Documentation(info=""));
    
  function grid1D "Grid-generation 1D" 
    input Elements.Line1D line;
    input Integer n;
    output Coordinate grid[n];
    protected 
    Integer N=  n - 1;
     annotation(
            Icon, Documentation(info="<HTML>
<pre>
This function can be used for rectangular domains with Euclidean grids in all dimensions.
</pre>
</HTML>"));
  algorithm 
      
   for k in 0:N loop
     grid[k+1] := PDE.Shape.lineShape1D(k/N, line);
        
   end for;
      
  end grid1D;
    
end GridGeneration;
  
package Fields 
    "Contains the definition of fields upon domains with given boundaries" 
    
  record Field1D "Scalar field over 1D domain" 
    replaceable type fieldType = Real;
      
    parameter Domains.Domain1D domain;
    parameter fieldType ini_val[domain.grid.n]=zeros(domain.grid.n);
    fieldType val[domain.grid.n](start=ini_val) 
        "Field-values over grid of domain";
    annotation(
          Documentation(info="<HTML>
<pre>
Scalar field over a linear one-dimensional spatial domain.
</pre>
</HTML>"));
  end Field1D;
    
  record Field2D "Scalar field over 2D domain" 
    replaceable type fieldType = Real;
      
    parameter Domains.Domain2D domain;
    parameter fieldType ini_val[domain.grid.n[1],domain.grid.n[2]]=zeros(domain.grid.n[1],domain.grid.n[2]);
    fieldType val[domain.grid.n[1],domain.grid.n[2]](start=ini_val) 
        "Field-values over grid of domain";
    annotation(
          Documentation(info="<HTML>
<pre>
Scalar field over a rectangular two-dimensional spatial domain.
</pre>
</HTML>"));
  end Field2D;
    
  record VectorField2D "Vector field over 2D domain" 
    replaceable type fieldType = Real;
      
    parameter Domains.Domain2D domain;
    parameter fieldType ini_val[domain.grid.n[1],domain.grid.n[2], 2]=zeros(domain.grid.n[1],domain.grid.n[2], 2);
    fieldType val[domain.grid.n[1],domain.grid.n[2],2](start=ini_val) 
        "Field-values over grid of domain";
    annotation(
          Documentation(info="<HTML>
<pre>
Vector field over a rectangular two-dimensional spatial domain.
</pre>
</HTML>"));
  end VectorField2D;
end Fields;
  
package SpecialFields "Contains explicit definition of special fields" 
    
    annotation( Documentation(info=""));
  record Const1D "Constant scalar field over 1D domain" 
    extends Fields.Field1D(val=  fill(c, domain.grid.n));
      
    parameter fieldType c;
      
  annotation(
          Documentation(info="<HTML>
<pre>
Constant scalar field over a linear one-dimensional spatial domain.
</pre>
</HTML>"));
      
  end Const1D;
    
  record Const2D "Constant scalar field over 2D domain" 
    extends Fields.Field2D(val=  fill(c, domain.grid.n[1], domain.grid.n[2]));
      
    parameter fieldType c;
      
  annotation(
          Documentation(info="<HTML>
<pre>
Constant scalar field over a rectangular two-dimensional spatial domain.
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
  end xder2D;
    
    annotation( Documentation(info="<HTML>
<pre>
Red diagonal on icon: to be modified.
</pre>
</HTML>"));
    
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
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
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=1, rgbcolor={255,
                  0,0}))));
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
</pre>
</HTML>"), Icon(Line(points=[-100,-100; 100,100], style(color=1, rgbcolor={255,
                  0,0}))));
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
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
</pre>
</HTML>"));
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
  
package DomainOperators 
    "Domain operators return the values of the field on the interior of the domain"
    
    
  function interior1D "Field in the interior of 1D domain" 
      
    input Fields.Field1D f;
    //output Real f_int[f.domain.grid.n-2]; ???
    output Real f_int[size(f.val,1)-2];
      annotation( Documentation(info="<HTML>
<pre>
Returns the interior values of the field without boundary values as a vector.
</pre>
</HTML>
"));
  algorithm 
    f_int := f.val[2:end - 1];
  end interior1D;
    
  function interior2D "Field in the interior of 2D domain" 
      
    input Fields.Field2D f;
    //output Real f_int[f.domain.grid.n[1]-2,f.domain.grid.n[2]-2]; ???
    output Real f_int[size(f.val,1)-2,size(f.val,2)-2];
      annotation( Documentation(info="<HTML>
<pre>
Returns the interior values of the field without boundary values as a matrix.
</pre>
</HTML>
"));
  algorithm 
    f_int := f.val[2:end - 1,2:end - 1];
  end interior2D;
  annotation( Documentation(info=""));
    
  function interiorRe1D "Field in the interior of 1D domain" 
      
    input Real fval[:];
    output Real fval_int[size(fval,1) - 2];
      annotation( Documentation(info="<HTML>
<pre>
Auxiliary operator for time-derivative: acts on type 'Real' input.
Returns the interior values of the field without boundary values as a vector.
</pre>
</HTML>
"));
  algorithm 
    fval_int := fval[2:end-1];
  end interiorRe1D;
    
  function interiorRe2D "Field in the interior of 1D domain" 
      
    input Real fval[:,:];
    output Real f_int[size(fval,1) - 2, size(fval,2) - 2];
      annotation( Documentation(info="<HTML>
<pre>
Auxiliary operator for time-derivative: acts on type 'Real' input.
Returns the interior values of the field without boundary values as a matrix.
</pre>
</HTML>
"));
  algorithm 
    f_int := fval[2:end-1,2:end-1];
  end interiorRe2D;
end DomainOperators;
  
package Autonomous "Autonomous PDE's without connectors" 
    
    model Poisson1D "Poisson problem 1D" 
      extends Equations.PoissonEq1D(interval(boundary(bcond(type_bc=[type_bc]))));
      
      parameter Integer bc[2](min=0,max=1)={0,0} 
        "Type of bc {left, right} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc[2,1]=[bc];
      parameter Real a_left=0 "Parameter of bd fct left";
      parameter Real a_right=0 "Parameter of bd fct right";
      
      replaceable function f_bd_left = Elements.default_bdfct1D 
        "Boundary fct left";
      replaceable function f_bd_right = Elements.default_bdfct1D 
        "Boundary fct right";
      annotation( Documentation(info="<HTML>
<pre>
The Poisson problem in 1D for a field f(x) is defined by the Poisson-equation

 -lambda*(d2f/dx2) = g(x)

together with specific boundary conditions.
</pre>
</HTML>"),
        Icon(
          Rectangle(extent=[-80,20; 80,-40], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,20; -100,-40], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,20; 100,-40], style(
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
            string="Poisson 1D")),
        DymolaStoredErrors);
    equation 
    //boundary equation
      
      nder(f, type_bc[1,1], left) = f_bd_left(time, a_left);
      nder(f, type_bc[2,1], right) = f_bd_right(time, a_right);
    end Poisson1D;
    
    model Poisson2D "Poisson problem 2D" 
      extends Equations.PoissonEq2D(rectangle(boundary(bcond(type_bc_x=[type_bc_x],type_bc_y=[type_bc_y]))));
      
      parameter Integer bc_x[2](min=0,max=1)={0,0} 
        "Type of bc {left, right} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc_x[2,1]=[bc_x];
      parameter Integer bc_y[2](min=0,max=1)={0,0} 
        "Type of bc {lower, upper} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc_y[2,1]=[bc_y];
      parameter Real a_left=0 "Parameter of bd fct left";
      parameter Real a_right=0 "Parameter of bd fct right}";
      parameter Real a_lower=0 "Parameter of bd fct lower";
      parameter Real a_upper=0 "Parameter of bd fct upper}";
      
      replaceable function f_bd_left = Elements.default_bdfct2Dx 
        "Boundary fct left";
      replaceable function f_bd_right = Elements.default_bdfct2Dx 
        "Boundary fct right";
      replaceable function f_bd_lower = Elements.default_bdfct2Dy 
        "Boundary fct lower";
      replaceable function f_bd_upper = Elements.default_bdfct2Dy 
        "Boundary fct upper";
    protected 
      parameter Integer n[2]=  rectangle.grid.n;
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
    equation 
    //boundary equation
      
      nderx(f, type_bc_x[1,1], left) = f_bd_left(time, a_left, n[2]);
      nderx(f, type_bc_x[2,1], right) = f_bd_right(time, a_right, n[2]);
      ndery(f, type_bc_y[1,1], lower) = f_bd_lower(time, a_lower, n[1]);
      ndery(f, type_bc_y[2,1], upper) = f_bd_upper(time, a_upper, n[1]);
    end Poisson2D;
    
    model Diffusion1D "Diffusion problem 1D" 
      extends Equations.DiffusionEq1D(interval(boundary(bcond(type_bc=[type_bc]))));
      
      parameter Integer bc[2](min=0,max=1)={0,0} 
        "Type of bc {left, right} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc[2,1]=[bc];
      parameter Real a_left=0 "Parameter of bd fct left";
      parameter Real a_right=0 "Parameter of bd fct right";
      
      replaceable function f_bd_left = Elements.default_bdfct1D 
        "Boundary fct left";
      replaceable function f_bd_right = Elements.default_bdfct1D 
        "Boundary fct right";
        annotation( Documentation(info="<HTML>
<pre>
The Diffusion problem in 1D for a field f(x) is defined by the Diffusion-equation

 df/dt = lambda*(d2f/dx2) + g(x)

together with specific boundary conditions.

INDEX PROBLEM HAS TO BE SOLVED.
</pre>
</HTML>"),
        Icon(
          Rectangle(extent=[-80,20; 80,-40], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,20; -100,-40], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,20; 100,-40], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Text(
            extent=[60,-20; -60,0],
            style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1),
            string="Diffusion 1D")),
        Diagram);
    equation 
    //boundary equation, the desired version has an index problem:
      
      //nder(f, type_bc[1,1], left) = f_bd_left(time, a_left);
      //nder(f, type_bc[2,1], right) = f_bd_right(time, a_right);
      
      f.val[1] = 0; // preliminary (Dirichlet)
      f.val[end] = 0;  // preliminary (Dirichlet)
    end Diffusion1D;
    
    model Diffusion2D "Diffusion problem 2D" 
      extends Equations.DiffusionEq2D(rectangle(boundary(bcond(type_bc_x=[type_bc_x],type_bc_y=[type_bc_y]))));
      
      parameter Integer bc_x[2](min=0,max=1)={0,0} 
        "Type of bc {left, right} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc_x[2,1]=[bc_x];
      parameter Integer bc_y[2](min=0,max=1)={0,0} 
        "Type of bc {lower, upper} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc_y[2,1]=[bc_y];
      parameter Real a_left=0 "Parameter of bd fct left";
      parameter Real a_right=0 "Parameter of bd fct right}";
      parameter Real a_lower=0 "Parameter of bd fct lower";
      parameter Real a_upper=0 "Parameter of bd fct upper}";
      
      replaceable function f_bd_left = Elements.default_bdfct2Dx 
        "Boundary fct left";
      replaceable function f_bd_right = Elements.default_bdfct2Dx 
        "Boundary fct right";
      replaceable function f_bd_lower = Elements.default_bdfct2Dy 
        "Boundary fct lower";
      replaceable function f_bd_upper = Elements.default_bdfct2Dy 
        "Boundary fct upper";
    protected 
      parameter Integer n[2]=  rectangle.grid.n;
        annotation( Documentation(info="<HTML>
<pre>
The Diffusion problem in 2D for a field f(x) is defined by the Diffusion-equation
 df/dt = lambda*(d2f/dx2 + d2f/dy2) + g(x,y)

together with specific boundary conditions.

INDEX PROBLEM HAS TO BE SOLVED.
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
    equation 
    //boundary equation, the desired version has an index problem:
      
      //nderx(f, type_bc_x[1,1], left) = f_bd_left(time, a_left, n[2]);
      //nderx(f, type_bc_x[2,1], right) = f_bd_right(time, a_right, n[2]);
      //ndery(f, type_bc_y[1,1], lower) = f_bd_lower(time, a_lower, n[1]);
      //ndery(f, type_bc_y[2,1], upper) = f_bd_upper(time, a_upper, n[1]);
      
      f.val[1,:] = zeros(n[2]); // preliminary (Dirichlet)
      f.val[end,:] = zeros(n[2]); // preliminary (Dirichlet)
      f.val[2:end-1,1] = zeros(n[1] - 2); // preliminary (Dirichlet)
      f.val[2:end-1,end] = zeros(n[1] - 2); // preliminary (Dirichlet)
    end Diffusion2D;
  annotation( Documentation(info="<HTML>
<pre>
The models Autonomous.* add specific boundary conditions to the corresponding models Equations.*. 
They are used as autonomous models, i.e. there are no connectors defined for 
using the models as components in an ODE environment.
</pre>
</HTML>"));
    
    model MultiPhysics1D "More than one equation in 1D" 
      extends Equations.MultiPhysicsEq1D(interval(boundary(bcond(type_bc=[type_bc]))));
      
      parameter Integer bc1[2](min=0,max=1)={0,0} 
        "Type of bc #1 {left, right} 0=Dirichlet, 1=Neumann";
      parameter Integer bc2[2](min=0,max=1)={0,0} 
        "Type of bc #2 {left, right} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc[2,2]=[bc1,bc2];
      parameter Real a1_left=0 "Parameter of bd fct #1 left";
      parameter Real a1_right=0 "Parameter of bd fct #1 right";
      parameter Real a2_left=0 "Parameter of bd fct #2 left";
      parameter Real a2_right=0 "Parameter of bd fct #2 right";
      
      replaceable function f1_bd_left = Elements.default_bdfct1D 
        "Boundary fct 1 left";
      replaceable function f1_bd_right = Elements.default_bdfct1D 
        "Boundary fct 1 right";
      replaceable function f2_bd_left = Elements.default_bdfct1D 
        "Boundary fct 2 left";
      replaceable function f2_bd_right = Elements.default_bdfct1D 
        "Boundary fct 2 right";
      annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations 
and different boundary conditions in 1D, an individual set for each field. 

INDEX PROBLEM HAS TO BE SOLVED.
</pre>
</HTML>"),
        Icon(
          Rectangle(extent=[-80,20; 80,-40], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,20; -100,-40], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,20; 100,-40], style(
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
            string="multi 1D")),
        DymolaStoredErrors);
        annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations and boundary conditions in 1D. 

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"), Icon(
          Rectangle(extent=[-80,20; 80,-40], style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255})),
          Line(points=[-100,20; -100,-40], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Line(points=[100,20; 100,-40], style(
              color=62,
              rgbcolor={0,127,127},
              thickness=2)),
          Text(
            extent=[60,-20; -60,0],
            style(
              color=62,
              rgbcolor={0,127,127},
              fillColor=7,
              rgbfillColor={255,255,255},
              fillPattern=1),
            string="multi")));
    equation 
    //boundary equation, the desired version has an index problem:
      
      nder(f1, type_bc[1,1], left) = f1_bd_left(time, a1_left);
      nder(f1, type_bc[2,1], right) = f1_bd_right(time, a1_right);
      
      //nder(f2, type_bc[1,2], left) = f2_bd_left(time, a2_left);
      //nder(f2, type_bc[2,2], right) = f2_bd_right(time, a2_right);
      
      f2.val[1] = 0;  // preliminary (Dirichlet)
      f2.val[end] = 0; // preliminary (Dirichlet)
      
    end MultiPhysics1D;
    
    model MultiPhysics2D "Problem with multiple equations in 2D" 
      extends Equations.MultiPhysicsEq2D(rectangle(boundary(bcond(type_bc_x=[type_bc_x],type_bc_y=[type_bc_y]))));
      
      parameter Integer bc1_x[2](min=0,max=1)={0,0} 
        "Type of bc #1 {left, right} 0=Dirichlet, 1=Neumann";
      parameter Integer bc1_y[2](min=0,max=1)={0,0} 
        "Type of bc #1 {lower, upper} 0=Dirichlet, 1=Neumann";
      parameter Integer bc2_x[2](min=0,max=1)={0,0} 
        "Type of bc #2 {left, right} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc2_x[2,1]=[bc2_x];
      parameter Integer bc2_y[2](min=0,max=1)={0,0} 
        "Type of bc #2 {lower, upper} 0=Dirichlet, 1=Neumann";
      final parameter Integer type_bc_x[2,2]=[bc1_x,bc2_x];
      final parameter Integer type_bc_y[2,2]=[bc1_y,bc2_y];
      
      parameter Real a1_left=0 "Parameter of bd fct #1 left";
      parameter Real a1_right=0 "Parameter of bd fct #1 right}";
      parameter Real a1_lower=0 "Parameter of bd fct #1 lower";
      parameter Real a1_upper=0 "Parameter of bd fct #1 upper}";
      
      parameter Real a2_left=0 "Parameter of bd fct #2 left";
      parameter Real a2_right=0 "Parameter of bd fct #2 right}";
      parameter Real a2_lower=0 "Parameter of bd fct #2 lower";
      parameter Real a2_upper=0 "Parameter of bd fct #2 upper}";
      
      replaceable function f1_bd_left = Elements.default_bdfct2Dx 
        "Boundary fct 1 left";
      replaceable function f1_bd_right = Elements.default_bdfct2Dx 
        "Boundary fct 1 right";
      replaceable function f1_bd_lower = Elements.default_bdfct2Dy 
        "Boundary fct 1 lower";
      replaceable function f1_bd_upper = Elements.default_bdfct2Dy 
        "Boundary fct 1 upper";
      
      replaceable function f2_bd_left = Elements.default_bdfct2Dx 
        "Boundary fct 2 left";
      replaceable function f2_bd_right = Elements.default_bdfct2Dx 
        "Boundary fct 2 right";
      replaceable function f2_bd_lower = Elements.default_bdfct2Dy 
        "Boundary fct 2 lower";
      replaceable function f2_bd_upper = Elements.default_bdfct2Dy 
        "Boundary fct 2 upper";
    protected 
      parameter Integer n[2]=  rectangle.grid.n;
        annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations 
and different boundary conditions in 2D, an individual set for each field. 

INDEX PROBLEM HAS TO BE SOLVED.
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
    equation 
    //boundary equation
      
      nderx(f1, type_bc_x[1,1], left) = f1_bd_left(time, a1_left, n[2]);
      nderx(f1, type_bc_x[2,1], right) = f1_bd_right(time, a1_right, n[2]);
      ndery(f1, type_bc_y[1,1], lower) = f1_bd_lower(time, a1_lower, n[1]);
      ndery(f1, type_bc_y[2,1], upper) = f1_bd_upper(time, a1_upper, n[1]);
      
      //nderx(f2, type_bc_x[1,2], left) = f2_bd_left(time, a2_left, n[2]);
      //nderx(f2, type_bc_x[2,2], right) = f2_bd_right(time, a2_right, n[2]);
      //ndery(f2, type_bc_y[1,2], lower) = f2_bd_lower(time, a2_lower, n[1]);
      //ndery(f2, type_bc_y[2,2], upper) = f2_bd_upper(time, a2_upper, n[1]);
      
      f2.val[1,:] = zeros(n[2]);  // preliminary (Dirichlet)
      f2.val[end,:] =zeros(n[2]); // preliminary (Dirichlet)
      f2.val[2:end-1,1] = zeros(n[1] - 2);  // preliminary (Dirichlet)
      f2.val[2:end-1,end] = zeros(n[1] - 2); // preliminary (Dirichlet)
    end MultiPhysics2D;
    
package Equations "PD Equations without boundery equations" 
      
  partial model EquationBase1D "Equation base 1D" 
        
    parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
    parameter Integer N=10 "Number of intervals";
    final parameter Integer n_grid=N+1 "Number of grid-points";
        
    parameter Domains.Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2])), grid(n=n_grid));
        
    function tder = DifferentialOperators.tder1D;
    function xder = DifferentialOperators.xder1D;
    function nder = DifferentialOperators.nder1D;
    function zero = DifferentialOperators.zero1D;
    function interior = DomainOperators.interior1D;
      protected 
    constant Boolean left=true;
    constant Boolean right=false;
      annotation( Documentation(info="<HTML>
<pre>
Base for space-1D equations, defined on an interval. 
</pre>
</HTML>"));
  end EquationBase1D;
      
  partial model EquationBase2D "Equation base 2D" 
        
    parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds x-axis {left, right}";
    parameter Coordinate y_bd[2]={-0.5,0.5} "Bounds y-axis {lower, upper}";
    parameter Integer N[2]={10,5} "Number of intervals {Nx, Ny}";
    final parameter Coordinate xa0[2]={x_bd[1], y_bd[1]} "Origin of axes";
    final parameter Coordinate xa1[2]={x_bd[2], y_bd[1]} "Endpoint of 1-axis";
    final parameter Coordinate xa2[2]={x_bd[1], y_bd[2]} "Endpoint of 2-axis";
    final parameter Integer n_grid[2]=N+{1,1} "Number of grid-points";
        
    parameter Domains.Domain2D rectangle(boundary(axis1(x1=xa0, x2=xa1), axis2(x1=xa0, x2=xa2)), grid(n=n_grid));
        
    function tder = DifferentialOperators.tder2D;
    function xder = DifferentialOperators.xder2D;
    function nderx = DifferentialOperators.nder2Dx;
    function ndery = DifferentialOperators.nder2Dy;
    function zero = DifferentialOperators.zero2D;
    function interior = DomainOperators.interior2D;
      protected 
    constant Boolean left=true;
    constant Boolean right=false;
    constant Boolean lower=true;
    constant Boolean upper=false;
      annotation( Documentation(info="<HTML>
<pre>
Base for space-2D equations, defined on a rectangular domain. 
</pre>
</HTML>"));
  end EquationBase2D;
      
  partial model PoissonEq1D "Poisson equation 1D" 
    extends EquationBase1D;
        
    parameter Real lambda=1 "lambda";
    parameter Real g0=0.1 "Parameter of g-fct";
        
    Fields.Field1D f(domain=interval);
    replaceable SpecialFields.Const1D g(c=g0, domain=interval) 
          "rhs of Poisson eq";
        
      annotation( Documentation(info="<HTML>
<pre>
The Poisson equation in 1D for a field f(x) is defined as 

 0 = lambda*(d2f/dx2) + g(x)

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
  equation 
    zero(f) = lambda*xder(f, 2) + interior(g);
        
  end PoissonEq1D;
      
  partial model PoissonEq2D "Poisson equation 2D" 
    extends EquationBase2D;
        
    parameter Real lambda=1 "lambda";
    parameter Real g0=0.5 "Parameter of g-fct";
        
    Fields.Field2D f(domain=rectangle);
    replaceable SpecialFields.Const2D g(c=g0, domain=rectangle) 
          "rhs of Poisson eq";
        
    function laplace = DifferentialOperators.laplace2D;
      annotation( Documentation(info="<HTML>
<pre>
The Poisson equation in 2D for a field f(x) is defined as 

 0 = lambda*(d2f/dx^2 + d2f/dy^2) + g(x,y)

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
  equation 
    zero(f) =  lambda*laplace(f) + interior(g);
        
  end PoissonEq2D;
      
  partial model PoissonEq2D_r_z "Poisson equation 3D reduced to 2D(r,z)" 
    extends EquationBase2D;
        
    parameter Real lambda=1 "lambda";
    parameter Real g0=0.1 "Parameter of g-fct";
        
    Fields.Field2D f(domain=rectangle);
    replaceable SpecialFields.Const2D g(c=g0, domain=rectangle) 
          "rhs of Poisson eq";
        
    function laplace = DifferentialOperators.laplace_r_z;
      annotation( Documentation(info="<HTML>
<pre>
The Poisson equation in cylindrical coordinates for a field f(x) 
under the restriction d/dphi = 0 is defined as 

 0 = lambda*( (1/r)*d/dr(r*d/dr)f + d2f/dz^2 ) + g(r,z) 

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"), Icon);
  equation 
    zero(f) =  lambda*laplace(f) + interior(g);
        
  end PoissonEq2D_r_z;
      
  partial model PoissonEq2D_r_phi "Poisson equation 3D reduced to 2D(r,phi)" 
    extends EquationBase2D;
        
    parameter Real lambda=1 "lambda";
    parameter Real g0=0.1 "Parameter of g-fct";
        
    Fields.Field2D f(domain=rectangle);
    replaceable SpecialFields.Const2D g(c=g0, domain=rectangle) 
          "rhs of Poisson eq";
        
    function laplace = DifferentialOperators.laplace_r_phi;
      annotation( Documentation(info="<HTML>
<pre>
The Poisson equation in cylindrical coordinates for a field f(x) 
under the restriction d/dz = 0 is defined as 

 0 = lambda*( (1/r)*d/dr(r*d/dr)f + (1/r^2)*d2f/dphi^2 ) + g(r,phi)

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation. 
</pre>
</HTML>"), Icon);
  equation 
    zero(f) =  lambda*laplace(f) + interior(g);
        
  end PoissonEq2D_r_phi;
      
  partial model DiffusionEq1D "Diffusion equation 1D" 
    extends EquationBase1D;
        
    parameter Real lambda=1 "lambda";
    parameter Real g0=0.1 "Parameter of g-fct";
        
    Fields.Field1D f(domain=interval);
    replaceable SpecialFields.Const1D g(c=g0, domain=interval) 
          "rhs of Diffusion eq";
        
    function interiorRe = DomainOperators.interiorRe1D;
      annotation( Documentation(info="<HTML>
<pre>
The Diffusion equation in 1D for a field f(x) is defined as 

 df/dt = lambda*(d2f/dx2) + g(x)

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
  equation 
    //tder(f) = lambda*xder(f, 2) + interior(g); //desired version!
    interiorRe(der(f.val)) = lambda*xder(f, 2) + interior(g);
        
  end DiffusionEq1D;
      
  partial model DiffusionEq2D "Diffusion equation 2D" 
    extends EquationBase2D;
        
    parameter Real lambda=1 "lambda";
    parameter Real g0=0.1 "Parameter of g-fct";
        
    Fields.Field2D f(domain=rectangle);
    replaceable SpecialFields.Const2D g(c=g0, domain=rectangle) 
          "rhs of Diffusion eq";
        
    function laplace = DifferentialOperators.laplace2D;
    function interiorRe = DomainOperators.interiorRe2D;
      annotation( Documentation(info="<HTML>
<pre>
The Diffusion equation in 2D for a field f(x) is 
 df/dt = lambda*(d2f/dx2 + d2f/dy2) + g(x,y)

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
  equation 
    //tder(f) =  lambda*laplace(f) + interior(g); //desired version!
    interiorRe(der(f.val)) =  lambda*laplace(f) + interior(g);
        
  end DiffusionEq2D;
  annotation( Documentation(info="<HTML>
<pre>
The models Equations.* contain only the equations without any boundary conditions.
This is the reason for defining them as partial models.
</HTML>"));
      
  partial model DiffusionEq2D_r_z "Diffusion equation 3D reduced to 2D(r,z)" 
    extends EquationBase2D;
        
    parameter Real lambda=1 "lambda";
    parameter Real g0=0.1 "Parameter of g-fct";
        
    Fields.Field2D f(domain=rectangle);
    replaceable SpecialFields.Const2D g(c=g0, domain=rectangle) 
          "rhs of Diffusion eq";
        
    function laplace = DifferentialOperators.laplace_r_z;
    function interiorRe = DomainOperators.interiorRe2D;
      annotation( Documentation(info="<HTML>
<pre>
The Diffusion equation in cylindrical coordinates for a field f(x) 
under the restriction d/dphi = 0 is defined as 

 df/dt = lambda*( (1/r)*d/dr(r*d/dr)f + d2f/dz^2 ) + g(r,z) 

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"), Icon);
  equation 
    //tder(f) =  lambda*laplace(f) + interior(g); //desired version!
    interiorRe(der(f.val)) =  lambda*laplace(f) + interior(g);
        
  end DiffusionEq2D_r_z;
      
  partial model DiffusionEq2D_r_phi 
        "Diffusion equation 3D reduced to 2D(r,phi)" 
    extends EquationBase2D;
        
    parameter Real lambda=1 "lambda";
    parameter Real g0=0.1 "Parameter of g-fct";
        
    Fields.Field2D f(domain=rectangle);
    replaceable SpecialFields.Const2D g(c=g0, domain=rectangle) 
          "rhs of Diffusion eq";
        
    function laplace = DifferentialOperators.laplace_r_phi;
    function interiorRe = DomainOperators.interiorRe2D;
      annotation( Documentation(info="<HTML>
<pre>
The Diffusion equation in cylindrical coordinates for a field f(x) 
under the restriction d/dz = 0 is defined as 
 df/dt = lambda*( (1/r)*d/dr(r*d/dr)f + (1/r^2)*d2f/dphi^2 ) + g(r,phi) 

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"), Icon);
  equation 
    //tder(f) =  lambda*laplace(f) + interior(g); //desired version!
    interiorRe(der(f.val)) =  lambda*laplace(f) + interior(g);
        
  end DiffusionEq2D_r_phi;
      
  partial model MultiPhysicsEq1D "More than one equation in 1D" 
    extends EquationBase1D;
        
    parameter Real lambda1=1 "lambda first eq";
    parameter Real lambda2=1 "lambda second eq";
    parameter Real g10=0.1 "Parameter of g1-fct";
    parameter Real g20=0.1 "Parameter of g1-fct";
        
    Fields.Field1D f1(domain=interval);
    Fields.Field1D f2(domain=interval);
    replaceable SpecialFields.Const1D g1(c=g10, domain=interval) 
          "rhs of eq 1 (Poisson)";
    replaceable SpecialFields.Const1D g2(c=g20, domain=interval) 
          "rhs of eq 2 (Diffusion)";
        
    function interiorRe = DomainOperators.interiorRe1D;
      annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations and boundary conditions in 1D. 

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"));
  equation 
    zero(f1) = lambda1*xder(f1, 2) + interior(g1);
        
    //tder(f2) = lambda2*xder(f2, 2) + interior(g2); //desired version!
    interiorRe(der(f2.val)) = lambda2*xder(f2, 2) + interior(g2);
        
  end MultiPhysicsEq1D;
      
  partial model MultiPhysicsEq2D "More than one equation in 2D" 
    extends EquationBase2D;
        
    parameter Real lambda1=1 "lambda equation 1";
    parameter Real lambda2=1 "lambda equation 2";
    parameter Real g10=0.1 "Parameter of g1-fct";
    parameter Real g20=0.1 "Parameter of g2-fct";
        
    Fields.Field2D f1(domain=rectangle);
    Fields.Field2D f2(domain=rectangle);
    replaceable SpecialFields.Const2D g1(c=g10, domain=rectangle) 
          "rhs of eq 1 (Poisson)";
    replaceable SpecialFields.Const2D g2(c=g20, domain=rectangle) 
          "rhs of eq 2 (Diffusion)";
        
    function laplace = DifferentialOperators.laplace2D;
    function interiorRe = DomainOperators.interiorRe2D;
      annotation( Documentation(info="<HTML>
<pre>
Example for the treatment of several fields with possibly different equations and boundary conditions in 2D. 

The model is partial as boundary conditions are not yet contained. 
Different boundary conditions are possible with one and the same equation.
</pre>
</HTML>"),
      Icon,
      Diagram);
        
  equation 
    zero(f1) = lambda1*laplace(f1) + interior(g1);
        
    //tder(f2) = lambda2*laplace(f2) + interior(g2); //desired version!
    interiorRe(der(f2.val)) = lambda2*laplace(f2) + interior(g2);
        
  end MultiPhysicsEq2D;
      
end Equations;
end Autonomous;
  
package Components "PDE objects as components of ODE system" 
  model ThermalResistor2D 
      "Example component 2D, to be embedded in ODE environment" 
      annotation( Documentation(info="<HTML>
<pre>
Example of a PDE component containig external connections for current and heat. 

TO BE FINISHED LATER:
- mapping to connectors, both electric and thermal
- physically reasonable parameters have to be put in
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

Additional auxiliary functions will be needed, for example for integration along boundaries, in order to properly match boundaries to connectors.
</pre>
</HTML>"));
end Components;
end FDM;
