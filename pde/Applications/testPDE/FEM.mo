package FEM 
  import PDE.FEM.Boundaries.*;
  import PDE.FEM.Domains.*;
  import PDE.FEM.Grids.*;
  import PDE.FEM.GridGeneration.*;
  import PDE.FEM.Fields.*;
  import PDE.FEM.SpecialFields.*;
  import PDE.FEM.DifferentialOperators.*;
  import PDE.FEM.IntegralOperators.*;
  import PDE.FEM.DomainOperators.*;
  import PDE.FEM.Autonomous.*;
  import PDE.FEM.Graphical.*;
  import PDE.Elements.*;
  import PDE.Shape.*;
  
 model FEMdomain1D "Test of domain grid 1D" 
    
   parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
   parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
    
   parameter Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2])), grid(refine=refine));
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains only the 1D domain-definition, including a grid, without any fields. 
</pre>
</HTML>"));
    
 end FEMdomain1D;
  
annotation( Documentation(info=""));
  
 model FEMfield1D "Test of field 1D" 
    
   parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
   parameter Real c0=2 "Constant value of field";
   parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
    
   parameter Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2])), grid(refine=refine));
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
 end FEMfield1D;
  
 model FEMboundary1D "Test of equation 1D" 
    
 model Equation "Poisson equation 1D" 
      
   parameter Coordinate x_bd[2]={-0.5,0.5} "Bounds axis {left, right}";
   parameter Integer type_bc[2,1]=[0;1] 
        "Boundary condition {left, right} (D=0, N=1)";
   parameter Real g0=0.1 "Constant value of rhs";
   parameter Real refine(min=0,max=1)=0.9 "0 < refine < 1, less is finer";
      
   parameter Domain1D interval(boundary(left(x=x_bd[1]),right(x=x_bd[2]), bcond(type_bc=[type_bc])), grid(refine=refine));
   Field1D f(domain=interval);
   parameter Const1D g_rhs(c=g0, domain=interval);
      
    protected 
   parameter Real Lg[:,:]=  assemble(interval.grid.ni, interval.grid.nv, interval.grid.interval, interval.grid.x, g_rhs.val);
   parameter Real LgBd[:,:]=  assembleBd(interval.grid.nb, interval.grid.nv, interval.grid.bdpoint, interval.grid.x, Lg, interval.boundary.bcond.type_bc);
   parameter Real Laplace[interval.grid.nv, interval.grid.nv]=  LgBd[1:interval.grid.nv, 1:interval.grid.nv];
   parameter Real g[interval.grid.nv]=  LgBd[1:interval.grid.nv, interval.grid.nv+1];
      
 equation 
   -Laplace*f.val = g;
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
    
 function assembleBd "Includes boundary conditions into stiffnes matrix" 
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
    
   function element "Stiffness contributions per interval" 
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
      
   algorithm 
       h := abs(P[2]-P[1]);
       Ak := 2/h*[1/2, -1/2; -1/2, 1/2];
      
       (x,w):=gaussLegendreFormula(2);
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
The Poisson problem in 1D for a field f(x) is defined by the Poisson-equation 

 -lambda*d2f/dx^2 = g(x)

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
    
 end FEMboundary1D;
  
 model FEMdomain2D "Test of domain with grid 2D" 
    
   parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
    
   parameter Domain2D rectangle(boundary(curve=defineBdCurve()), grid(refine=refine));
    
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains only the 2D domain-definition, including a grid, without any fields.

FAILS ??? 
</pre>
</HTML>"));
 equation 
    
 end FEMdomain2D;
  
 model FEMfield2D "Test of field 2D" 
    
   // defineBdConditions() does not return desired values !? 
   //parameter Domains.Domain2D rectangle(boundary(curve=defineBdCurve(),bcond=defineBdConditions()), grid(refine=refine));
    
   parameter Real c0=1 "Constant value of field";
   parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
   /* Compile twice in order to get a change in grid 
     that is: boundary, grid, and/or boundary conditions*/
    
   parameter Domain2D rectangle(boundary(curve=defineBdCurve(),bcond(type_bc=[1;0;1;0])),grid(refine=refine));
   Field2D f(domain=rectangle);
   Const2D f0(c=c0, domain=rectangle);
    
    annotation(
           Icon, Documentation(info="<HTML>
<pre>
Contains the field definition upon a 2D domain and specifies boundary conditions. 

FAILS ???
</pre>
</HTML>
"));
 equation 
   f.val = f0.val;
 end FEMfield2D;
  
 model FEMboundary2D "Test equation 2D" 
 model Equation "Poisson equation 2D" 
      
   parameter Real refine(min=0,max=1)=0.2 "0 < refine < 1, less is finer";
   /* Compile twice in order to get a change in grid 
     that is: boundary, grid, and/or boundary conditions*/
      
   parameter Real g0=1 "Constant value of field";
      
   // defineBdConditions() does not return desired values !? 
   //parameter Domains.Domain2D rectangle(boundary(curve=defineBdCurve(),bcond=defineBdConditions()), grid(refine=refine));
   parameter Domain2D rectangle(boundary(curve=defineBdCurve(),bcond(type_bc=[1;0;1;0])),grid(refine=refine));
   parameter Const2D g_rhs(c=g0, domain=rectangle);
   Field2D f(domain=rectangle);
    protected 
   parameter Real Lg[:,:]=  assemble(rectangle.grid.nt, rectangle.grid.nv, rectangle.grid.triangle, rectangle.grid.x, g_rhs.val);
   parameter Real LgBd[:,:]=  assembleBd(rectangle.grid.ne, rectangle.grid.nv, rectangle.grid.edge, rectangle.grid.x, Lg, rectangle.boundary.bcond.type_bc);
   parameter Real Laplace[rectangle.grid.nv, rectangle.grid.nv]=  LgBd[1:rectangle.grid.nv, 1:rectangle.grid.nv];
   parameter Real g[rectangle.grid.nv]=  LgBd[1:rectangle.grid.nv, rectangle.grid.nv+1];
      
 equation 
   -Laplace*f.val = g;
      
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
     output Real Ab[size(g_val,1), size(g_val,1)+1];
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
     annotation(Documentation(info=""));
   end element;
    
     annotation( Documentation(info="<HTML>
<pre>
Contains the field definition upon a 2D domain with boundary conditions together with a differential equation. 
</pre>
</HTML>
"),     Icon);
     annotation( Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
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
    
 end FEMboundary2D;
  
end FEM;
