package FDM 
  import PDE.FDM.Boundaries.*;
  import PDE.FDM.Domains.*;
  import PDE.FDM.Grids.*;
  import PDE.FDM.GridGeneration.*;
  import PDE.FDM.Fields.*;
  import PDE.FDM.SpecialFields.*;
  import PDE.FDM.DifferentialOperators.*;
  import PDE.FDM.DomainOperators.*;
  import PDE.Elements.*;
  import PDE.Shape.*;
  
 model FDMdomain1D "Test of domain with grid 1D" 
    
   parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
   parameter Integer N=10 "Number of intervals";
   final parameter Integer n_grid=N+1 "Number of grid-points";
    
   parameter Domain1D interval(boundary(left(x=x_bd[1]), right(x=x_bd[2])), grid(n=n_grid));
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains only the 1D domain-definition, including a grid, without any fields. 
</pre>
</HTML>
"));
    
 end FDMdomain1D;
  
annotation( Documentation(info=""));
  
 model FDMfield1D "Test of field 1D" 
    
   parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
   parameter Integer N=10 "Number of intervals";
   final parameter Integer n_grid=N+1 "Number of grid-points";
   parameter Real c0=2 "Constant value of field";
    
   parameter Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2])), grid(n=n_grid));
   Field1D f(domain=interval);
   Const1D f0(c=c0, domain=interval);
    
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains the field definition upon a 1D domain and specifies boundary conditions. 
</pre>
</HTML>
"));
 equation 
   f.val = f0.val;
    
 end FDMfield1D;
  
 model FDMboundary1D "Test of equation 1D" 
    
   parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
   parameter Integer bc[2](min=0,max=1)={0,0} 
      "Type of bc {left, right} 0=Dirichlet, 1=Neumann";
   final parameter Integer type_bc[2,1]=[bc];
   parameter Integer N=10 "Number of intervals";
   final parameter Integer n_grid=N+1 "Number of grid-points";
   parameter Real g0=0.1 "Constant value of rhs";
    
   parameter Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2]), bcond(type_bc=[type_bc])), grid(n=n_grid));
   Field1D f(domain=interval);
   Const1D g(c=g0, domain=interval);
    
   replaceable function f_bd_left = default_bdfct1D "Boundary fct left";
   replaceable function f_bd_right = default_bdfct1D "Boundary fct right";
  protected 
   constant Boolean beg_axis=true;
   constant Boolean end_axis=false;
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains the field definition upon a 1D domain with boundary conditions together with a differential equation. 
</pre>
</HTML>
"));
 equation 
    
   //- xder1D(f, 2) = interior1D(g); // Poisson
    
   //tder1D(f) = xder1D(f, 2) + interior1D(g); // desired version Diffusion!
    
   interiorRe1D(der(f.val)) = xder1D(f, 2) + interior1D(g); // Diffusion
    
 //boundary equation
    
   //nder1D(f, type_bc[1,1], beg_axis) = f_bd_left(time, 0);
   //nder1D(f, type_bc[2,1], end_axis) = f_bd_right(time, 0);
    
   f.val[1] = 0; // preliminary (Dirichlet)
   f.val[end] = 0;  // preliminary (Dirichlet)
 end FDMboundary1D;
  
 model FDMdomain2D "Test of domain with grid 2D" 
    
   parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds x-axis {left, right}";
   parameter Coordinate y_bd[2]={-0.5,0.5} "Bounds y-axis {lower, upper}";
   parameter Integer N[2]={10,5} "Number of intervals {Nx, Ny}";
   final parameter Coordinate xa0[2]={x_bd[1], y_bd[1]} "Origin of axes";
   final parameter Coordinate xa1[2]={x_bd[2], y_bd[1]} "Endpoint of 1-axis";
   final parameter Coordinate xa2[2]={x_bd[1], y_bd[2]} "Endpoint of 2-axis";
   final parameter Integer n_grid[2]=N+{1,1} "Number of grid-points";
    
   parameter Domain2D rectangle(boundary(axis1(x1=xa0, x2=xa1), axis2(x1=xa0, x2=xa2)), grid(n=n_grid));
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains only the 2D domain-definition, including a grid, without any fields. 
</pre>
</HTML>"));
 end FDMdomain2D;
  
 model FDMfield2D "Test of field 2D" 
    
   parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds x-axis {left, right}";
   parameter Coordinate y_bd[2]={-0.5,0.5} "Bounds y-axis {lower, upper}";
   parameter Integer N[2]={10,5} "Number of intervals {Nx, Ny}";
   parameter Real c0=2 "Constant value of field";
   final parameter Coordinate xa0[2]={x_bd[1], y_bd[1]} "Origin of axes";
   final parameter Coordinate xa1[2]={x_bd[2], y_bd[1]} "Endpoint of 1-axis";
   final parameter Coordinate xa2[2]={x_bd[1], y_bd[2]} "Endpoint of 2-axis";
   final parameter Integer n_grid[2]=N+{1,1} "Number of grid-points";
    
   parameter Domain2D rectangle(boundary(axis1(x1=xa0, x2=xa1), axis2(x1=xa0, x2=xa2)), grid(n=n_grid));
   Field2D f(domain=rectangle);
   Const2D f0(c=c0, domain=rectangle);
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains the field definition upon a 2D domain and specifies boundary conditions. 
</pre>
</HTML>"));
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains the field definition upon a domain. 
</pre>
</HTML>
"));
 equation 
   f.val = f0.val;
 end FDMfield2D;
  
 model FDMboundary2D "Test equation 2D" 
    
   parameter Coordinate x_bd[2]={0,1} "Bounds x-axis {left, right}";
   parameter Coordinate y_bd[2]={0,1} "Bounds y-axis {lower, upper}";
   parameter Integer bc_x[2](min=0,max=1)={0,0} 
      "Type of bc {left, right} 0=Dirichlet, 1=Neumann";
   final parameter Integer type_bc_x[2,1]=[bc_x];
   parameter Integer bc_y[2](min=0,max=1)={0,0} 
      "Type of bc {lower, upper} 0=Dirichlet, 1=Neumann";
   final parameter Integer type_bc_y[2,1]=[bc_y];
   parameter Integer N[2]={10,5} "Number of intervals {Nx, Ny}";
   parameter Real g0=0.1 "Constant value of rhs";
   final parameter Coordinate xa0[2]={x_bd[1], y_bd[1]} "Origin of axes";
   final parameter Coordinate xa1[2]={x_bd[2], y_bd[1]} "Endpoint of 1-axis";
   final parameter Coordinate xa2[2]={x_bd[1], y_bd[2]} "Endpoint of 2-axis";
   final parameter Integer n_grid[2]=N+{1,1} "Number of grid-points";
    
   parameter Domain2D rectangle(boundary(axis1(x1=xa0, x2=xa1), axis2(x1=xa0, x2=xa2), bcond(type_bc_x=[type_bc_x],type_bc_y=[type_bc_y])), grid(n=n_grid));
   Field2D f(domain=rectangle);
   Const2D g(c=g0, domain=rectangle);
    
   replaceable function f_bd_left = default_bdfct2Dx "Boundary fct left";
   replaceable function f_bd_right = default_bdfct2Dx "Boundary fct right";
   replaceable function f_bd_lower = default_bdfct2Dy "Boundary fct lower";
   replaceable function f_bd_upper = default_bdfct2Dy "Boundary fct upper";
  protected 
   constant Boolean beg_axis=true;
   constant Boolean end_axis=false;
   parameter Integer n[2]=  rectangle.grid.n;
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains the field definition upon a 2D domain with boundary conditions together with a differential equation. 
</pre>
</HTML>
"));
 equation 
    
   //-laplace2D(f) = interior2D(g); // Poisson
    
 //  tder2D(f) =  laplace2D(f) + interior2D(g); // desired version Diffusion!
    
   interiorRe2D(der(f.val)) = xder2D(f, 2) + interior2D(g); // Diffusion
    
 //boundary equation
    
   //nder2Dx(f, type_bc_x[1,1], beg_axis) = f_bd_left(time, 0, n[2]);
   //nder2Dx(f, type_bc_x[2,1], end_axis) = f_bd_right(time, 0, n[2]);
   //nder2Dy(f, type_bc_y[1,1], beg_axis) = f_bd_lower(time, 0, n[1]);
   //nder2Dy(f, type_bc_y[2,1], end_axis) = f_bd_upper(time, 0, n[1]);
    
   f.val[1,:] = zeros(n[2]); // preliminary (Dirichlet)
   f.val[end,:] = zeros(n[2]); // preliminary (Dirichlet)
   f.val[2:end-1,1] = zeros(n[1] - 2); // preliminary (Dirichlet)
   f.val[2:end-1,end] = zeros(n[1] - 2); // preliminary (Dirichlet)  
 end FDMboundary2D;
end FDM;
