

package testFEM 
  package MyGenericBoundary2 
    import PDEbhjl.*;
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnum;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnumC;
    
    extends Boundary;
    
    redeclare record extends Data 
      parameter Point p0;
      parameter Real w;
      parameter Real h;
      parameter Real cw;
      
      parameter Real ch=h;
      parameter Point cc=p0 + {w,h/2};
      
      parameter Line.Data bottom(p1=p0, p2=p0 + {w,0});
      parameter Line.Data top(p1=p0 + {w,h}, p2=p0 + {0,h});
      parameter Line.Data left(p1=p0 + {0,h}, p2=p0);
      
      parameter Bezier.Data right(n=8, p=fill(cc, 8) + {{0.0,-0.5},{0.0,-0.2},{
            0.0,0.0},{-0.85,-0.85},{-0.85,0.85},{0.0,0.0},{0.0,0.2},{0.0,0.5}}*
            {{cw,0},{0,ch}});
      
      parameter Composite4.Data boundary(
        parts1(line=bottom, partType=PartTypeEnumC.line), 
        parts2(bezier=right, partType=PartTypeEnumC.bezier), 
        parts3(line=top, partType=PartTypeEnumC.line), 
        parts4(line=left, partType=PartTypeEnumC.line));
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    algorithm 
      x := Composite4.shape(u, d.boundary);
    end shape;
    
  end MyGenericBoundary2;
  
  model CirclePoissonTest 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    parameter Integer n=20;
    parameter Real refine=0.5;
    parameter Circle.Data circle(c={0,0}, r=2);
    
    package myDomainP = Domain (redeclare package boundaryP = Circle);
    parameter myDomainP.Data mydomain(boundary=circle);
    
    function myfunc 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package myFieldP = Field (redeclare package domainP = myDomainP, redeclare 
          function value = myfunc);
    myFieldP.Data myfield(domain=mydomain);
    
    package PDE = PDEbhjl.FEMForms.Autonomous.Poisson2D (redeclare package 
          domainP = myDomainP);
    PDE.Equation pde(
      domain=mydomain, 
      nbp=n, 
      refine=refine);
  end CirclePoissonTest;
  
  package MyBoundary 
    import PDEbhjl.*;
    import PDEbhjl.Boundaries.*;
    extends Boundary;
    
    redeclare record extends Data 
      parameter Point p;
      parameter Real w;
      parameter Real h;
      parameter Real r;
      parameter Line.Data bottom(
        p1=p, 
        p2=p + {w,0}, 
        bc(index=1));
      parameter Line.Data right(
        p1=p + {w,0}, 
        p2=p + {w,h - r}, 
        bc(index=2));
      parameter Line.Data top(
        p1=p + {w - r,h}, 
        p2=p + {0,h}, 
        bc(index=3));
      parameter Line.Data left(
        p1=p + {0,h}, 
        p2=p, 
        bc(index=4));
      parameter Arc.Data roundedCorner(
        c=p + {w - r,h - r}, 
        r=r, 
        a_start=0, 
        a_end=Arc.pi/2, 
        bc(index=5));
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Real s=5*u;
      Integer is=integer(s);
      Integer pno=is + 1;
    algorithm 
      x := if pno == 1 then Line.shape(s - is, d.bottom) else if pno == 2 then 
        Line.shape(s - is, d.right) else if pno == 3 then Arc.shape(s - is, d.
        roundedCorner) else if pno == 4 then Line.shape(s - is, d.top) else if 
        pno == 5 then Line.shape(s - is, d.left) else {-1,-1,-1};
    end shape;
    
  end MyBoundary;
  
  model MyBoundaryPoissonTest 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    parameter Integer n=64;
    parameter Real refine=0.5;
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=2;
    parameter Real cw=5;
    
    parameter BoundaryCondition.Data dirzero(
      bcType=BoundaryCondition.dirichlet, 
      val=0, 
      index=1, 
      name="dirzero");
    
    parameter BoundaryCondition.Data dirfive(
      bcType=BoundaryCondition.dirichlet, 
      val=5, 
      index=2, 
      name="dirfive");
    
    parameter MyBoundary.Data bnd(
      p=p0, 
      w=w, 
      h=h, 
      r=r, 
      bottom(bc=dirzero), 
      top(bc=dirzero), 
      right(bc=dirzero), 
      left(bc=dirzero), 
      roundedCorner(bc=dirfive));
    
    package myDomainP = Domain (redeclare package boundaryP = MyBoundary);
    parameter myDomainP.Data mydomain(boundary=bnd);
    
    function myfunc 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package myFieldP = Field (redeclare package domainP = myDomainP, redeclare 
          function value = myfunc);
    myFieldP.Data myfield(domain=mydomain);
    
    parameter BoundaryCondition.Buildbc buildbc(n=2, data={dirzero,dirfive});
    /* 
 parameter BCType bc[2]={{dirzero.bcType,dirzero.val,dirzero.index},{dirfive.
      bcType,dirfive.val,dirfive.index}};
*/
    package PDE = PDEbhjl.FEMForms.Autonomous.Poisson2D (redeclare package 
          domainP = myDomainP);
    PDE.Equation pde(
      domain=mydomain, 
      nbp=n, 
      refine=refine, 
      nbc=2, 
      bc=buildbc.bc);
  end MyBoundaryPoissonTest;
  
  model Possion2DTest 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    package myDomain = Domain (redeclare package boundaryP = Circle);
    parameter Integer n=20;
    parameter Real refine=0.5;
    
    parameter BoundaryCondition.Data dirzero(
      bcType=BoundaryCondition.dirichlet, 
      val=0, 
      index=1, 
      name="dirzero");
    
    parameter Circle.Data bnd(
      c={0,0}, 
      r=2, 
      bc=dirzero);
    
    parameter myDomain.Data domain(boundary=bnd);
    
    function myfunc 
      input Point x;
      input myField.Data d;
      output myField.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input myField.Data d;
      output myField.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package myField = Field (redeclare package domainP = myDomain);
    
    /*, redeclare 
        function value = myfunc*/
    /*  
  package PDE = FEMForms.Autonomous.Poisson2D (redeclare package domainP = 
          myDomain, redeclare package initialField = myField);
*/
    parameter BoundaryCondition.Buildbc buildbc(n=1, data={dirzero});
    
    package PDE = PDEbhjl.FEMForms.Autonomous.Poisson2D (redeclare package 
          domainP = myDomain);
    PDE.Equation pde(
      nbp=n, 
      refine=refine, 
      domain=domain, 
      nbc=1, 
      bc=buildbc.bc);
    
    // Modelica part
    
  end Possion2DTest;
  
  model MyGenericBoundaryDiffusionTest 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    
    parameter Integer n=40;
    parameter Real refine=0.5;
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    
    package MyBoundary = MyGenericBoundary2;
    
    parameter BoundaryCondition.Data dirzero(
      bcType=BoundaryCondition.dirichlet, 
      val=0, 
      index=1, 
      name="dirzero");
    
    parameter BoundaryCondition.Data dirfive(
      bcType=BoundaryCondition.dirichlet, 
      val=5, 
      index=2, 
      name="dirfive");
    
    parameter MyBoundary.Data bnd(
      p0=p0, 
      w=w, 
      h=h, 
      cw=cw, 
      bottom(bc=dirzero), 
      right(bc=dirfive), 
      top(bc=dirzero), 
      left(bc=dirzero));
    
    package myDomainP = Domain (redeclare package boundaryP = MyBoundary);
    parameter myDomainP.Data mydomain(boundary=bnd);
    
    function myfunc 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input myFieldP.Data d;
      output myFieldP.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package myFieldP = Field (redeclare package domainP = myDomainP, redeclare 
          function value = myfunc);
    myFieldP.Data myfield(domain=mydomain);
    
    parameter BoundaryCondition.Buildbc buildbc(n=2, data={dirzero,dirfive});
    
    // package PDE = PDEbhjl.FEMForms.Autonomous.Poisson2D (redeclare package 
    //      domainP = myDomainP);
    package PDE = PDEbhjl.FEMForms.Autonomous.Diffusion2D (redeclare package 
          domainP = myDomainP);
    PDE.Equation pde(
      domain=mydomain, 
      nbp=n, 
      refine=refine, 
      g0=1, 
      nbc=2, 
      bc=buildbc.bc);
  end MyGenericBoundaryDiffusionTest;
end testFEM;
