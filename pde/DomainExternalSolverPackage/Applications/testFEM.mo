

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
  
  package MyGenericBoundary3 
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
      
      Line.Data bottom(p1=p0, p2=p0 + {w,0});
      Line.Data top1(p1=p0 + {w,h}, p2=p0 + {2*w/3,h});
      Line.Data top2(p1=p0 + {2*w/3,h}, p2=p0 + {w/3,h});
      Line.Data top3(p1=p0 + {w/3,h}, p2=p0 + {0,h});
      Line.Data left(p1=p0 + {0,h}, p2=p0);
      
      Bezier.Data right(n=8, p=fill(cc, 8) + {{0.0,-0.5},{0.0,-0.2},{0.0,0.0},{
            -0.85,-0.85},{-0.85,0.85},{0.0,0.0},{0.0,0.2},{0.0,0.5}}*{{cw,0},{0,
            ch}});
      
      Composite6.Data boundary(
        parts1(line=bottom, partType=PartTypeEnumC.line), 
        parts2(bezier=right, partType=PartTypeEnumC.bezier), 
        parts3(line=top1, partType=PartTypeEnumC.line), 
        parts4(line=top2, partType=PartTypeEnumC.line), 
        parts5(line=top3, partType=PartTypeEnumC.line), 
        parts6(line=left, partType=PartTypeEnumC.line));
      
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    algorithm 
      x := Composite6.shape(u, d.boundary);
    end shape;
    
    annotation (Icon(
        Line(points=[-60, 60; -60, -20; 40, -20], style(color=3, rgbcolor={0,0,
                255})), 
        Line(points=[-60, 60; -20, 60], style(color=3, rgbcolor={0,0,255})), 
        Line(points=[-20, 60; 0, 60; 40, 60], style(color=3, rgbcolor={0,0,255})), 
          
        Line(points=[40, 60; 36, 48; 14, 40; 2, 20; 14, 0; 36, -10; 40, -20], 
            style(color=3, rgbcolor={0,0,255}))));
    
  end MyGenericBoundary3;
  
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
    parameter Real r=0.5;
    parameter Real cw=5;
    
    package MyBnd = MyGenericBoundary2;
    
    parameter BoundaryCondition.Data dirzero(
      bcType=BoundaryCondition.dirichlet, 
      g=0, 
      index=1, 
      name="dirzero");
    
    parameter BoundaryCondition.Data neumannzero(
      bcType=BoundaryCondition.neumann, 
      g=0, 
      index=3, 
      name="neumannzero");
    
    parameter BoundaryCondition.Data dirfive(
      bcType=BoundaryCondition.dirichlet, 
      g=5, 
      index=2, 
      name="dirfive");
    
    parameter MyBnd.Data bnd(
      p0=p0, 
      w=w, 
      h=h, 
      cw=cw, 
      bottom(bc=dirzero), 
      top(bc=dirzero), 
      right(bc=dirfive), 
      left(bc=neumannzero));
    
    package myDomainP = Domain (redeclare package boundaryP = MyBnd);
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
    
    parameter BoundaryCondition.Buildbc buildbc(n=3, data={dirzero,dirfive,
          neumannzero});
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
      nbc=3, 
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
      g=0, 
      index=1, 
      name="dirzero");
    
    parameter BoundaryCondition.Data dirfive(
      bcType=BoundaryCondition.dirichlet, 
      g=5, 
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
  
  model MyGenericBoundaryDiffusionTest3 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    
    // discretization parameters
    parameter Integer n=40;
    parameter Real refine=0.5;
    // domain geometry parameters
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    // regulator parameters
    parameter Real goalvalue=20;
    parameter Real regk=1;
    parameter Real regT=3;
    
    // Use PI regulator from Standard Library 
    Modelica.Blocks.Continuous.PI regulator(k={regk}, T={regT});
    
    package MyBoundary = MyGenericBoundary3;
    
    parameter BoundaryCondition.Data neumann(
      bcType=BoundaryCondition.neumann, 
      g=0, 
      index=1, 
      name="neumannzero");
    
    parameter BoundaryCondition.Data dirheater(
      bcType=BoundaryCondition.timedepdirichlet, 
      g=0, 
      index=2, 
      name="dirheater");
    
    parameter BoundaryCondition.Data dirthree(
      bcType=BoundaryCondition.dirichlet, 
      g=8, 
      index=3, 
      name="dirthree");
    
    parameter MyBoundary.Data bnd(
      p0=p0, 
      w=w, 
      h=h, 
      cw=cw, 
      bottom(bc=neumann), 
      right(bc=neumann), 
      top1(bc=neumann), 
      top2(bc=dirheater), 
      top3(bc=neumann), 
      left(bc=dirthree));
    
    package myDomainP = Domain (redeclare package boundaryP = MyBoundary);
    myDomainP.Data mydomain(boundary=bnd);
    
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
    
    BoundaryCondition.Buildbc buildbc(n=3, data={neumann,dirheater,dirthree});
    
    // package PDE = PDEbhjl.FEMForms.Autonomous.Poisson2D (redeclare package 
    //      domainP = myDomainP);
    package PDE = PDEbhjl.FEMForms.Autonomous.Diffusion2D (redeclare package 
          domainP = myDomainP);
    PDE.Equation pde(
      domain=mydomain, 
      nbp=n, 
      refine=refine, 
      g0=1, 
      nbc=buildbc.n, 
      bc=buildbc.bc);
    Real sensorvalue;
    Real heatervalue;
  equation 
    heatervalue = regulator.y[1];
    regulator.inPort.signal[1] = goalvalue - sensorvalue;
    sensorvalue = pde.fd.val_u[2];
    // take value at 2.6055, 2.3320 => node 38 in mesh.x
    // u_indices[2] => 38 => fd.val_u[2]
    
    pde.timeDepBndValue = heatervalue;
    
  end MyGenericBoundaryDiffusionTest3;
  
  model MyGenericBoundaryDiffusionTest4 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    // Heat transfer parameters
    parameter Real k=4920;
    // 4920 "J/m.min.K";
    parameter Real hh=54/1e-3 
      "Thermal conduct. glass J/m.min.K/m thickness=1e-3m";
    /* kg/lg, heat transfer coefficient J/m.min.K / m */
    parameter Real rho=7821;
    //7820 "Density kg/m3";
    parameter Real Cp=449;
    // 449 "J/kg.K";
    parameter Real T_inf=5 "Outside temperature K";
    parameter Real qh=0 "Source on boundary";
    parameter Real Q=0 "Source";
    
    // PDE parameters
    parameter Real c=k;
    parameter Real q=hh;
    parameter Real g=qh + hh*T_inf;
    parameter Real f=Q;
    parameter Real da=rho*Cp;
    
    // discretization parameters
    parameter Integer n=40;
    parameter Real refine=0.5;
    // domain geometry parameters
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    // regulator parameters
    parameter Real goalvalue=20;
    parameter Real regk=1;
    parameter Real regT=200;
    
    // Use PI regulator from Standard Library 
    Modelica.Blocks.Continuous.PI regulator(k={regk}, T={regT});
    
    package MyBoundary = MyGenericBoundary3;
    
    parameter BoundaryCondition.Data neumann(
      bcType=BoundaryCondition.neumann, 
      g=0, 
      index=1, 
      name="neumannzero");
    
    parameter BoundaryCondition.Data dirheater(
      bcType=BoundaryCondition.timedepdirichlet, 
      g=0, 
      index=2, 
      name="dirheater");
    
    parameter BoundaryCondition.Data robin(
      bcType=BoundaryCondition.robin, 
      q=q/c, 
      g=g, 
      index=3, 
      name="robin");
    // impl. bug workaround 
    
    parameter MyBoundary.Data bnd(
      p0=p0, 
      w=w, 
      h=h, 
      cw=cw, 
      bottom(bc=neumann), 
      right(bc=neumann), 
      top1(bc=neumann), 
      top2(bc=dirheater), 
      top3(bc=neumann), 
      left(bc=robin));
    
    package myDomainP = Domain (redeclare package boundaryP = MyBoundary);
    myDomainP.Data mydomain(boundary=bnd);
    
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
    
    BoundaryCondition.Buildbc buildbc(n=3, data={neumann,dirheater,robin});
    
    // package PDE = PDEbhjl.FEMForms.Autonomous.Poisson2D (redeclare package 
    //      domainP = myDomainP);
    package PDE = PDEbhjl.FEMForms.Autonomous.Diffusion2D (redeclare package 
          domainP = myDomainP);
    PDE.Equation pde(
      domain=mydomain, 
      nbp=n, 
      refine=refine, 
      g0=f, 
      c=c, 
      da=da, 
      nbc=buildbc.n, 
      bc=buildbc.bc);
    Real sensorvalue;
    Real heatervalue;
  equation 
    heatervalue = regulator.y[1];
    regulator.inPort.signal[1] = goalvalue - sensorvalue;
    sensorvalue = pde.fd.val_u[56];
    // take value at 2.6055, 2.3320 => node 38 in mesh.x
    // u_indices[34] => 38 => fd.val_u[34]
    // closer to window:
    // take value at 1.3958, 2.9650 => node 60 in mesh.x
    // u_indices[56] => 60 => fd.val_u[56]
    
    pde.timeDepBndValue = heatervalue;
    
  end MyGenericBoundaryDiffusionTest4;

  model MyGenericBoundaryPoissonTest3 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    
    // discretization parameters
    parameter Integer n=40;
    parameter Real refine=0.5;
    // domain geometry parameters
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    // regulator parameters
    parameter Real goalvalue=20;
    parameter Real regk=1;
    parameter Real regT=3;
    
    // Use PI regulator from Standard Library 
    // Modelica.Blocks.Continuous.PI regulator(k={regk}, T={regT});
    
    package MyBoundary = MyGenericBoundary3;
    
    parameter BoundaryCondition.Data neumann(
      bcType=BoundaryCondition.neumann, 
      g=0, 
      index=1, 
      name="neumannzero");
    
    parameter BoundaryCondition.Data dirzero(
      bcType=BoundaryCondition.dirichlet, 
      g=0, 
      index=2, 
      name="dirzero");
    
    parameter BoundaryCondition.Data dirthree(
      bcType=BoundaryCondition.dirichlet, 
      g=8, 
      index=3, 
      name="dirthree");
    
    parameter MyBoundary.Data bnd(
      p0=p0, 
      w=w, 
      h=h, 
      cw=cw, 
      bottom(bc=dirzero), 
      right(bc=dirthree), 
      top1(bc=dirzero), 
      top2(bc=dirzero), 
      top3(bc=dirzero), 
      left(bc=neumann));
    
    package myDomainP = Domain (redeclare package boundaryP = MyBoundary);
    myDomainP.Data mydomain(boundary=bnd);
    
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
    
    BoundaryCondition.Buildbc buildbc(n=3, data={neumann,dirzero,dirthree});
    
    package PDE = PDEbhjl.FEMForms.Autonomous.Poisson2D (redeclare package 
          domainP = myDomainP);
    //package PDE = PDEbhjl.FEMForms.Autonomous.Diffusion2D (redeclare package 
    //      domainP = myDomainP);
    PDE.Equation pde(
      domain=mydomain, 
      nbp=n, 
      refine=refine, 
      g0=0, 
      nbc=buildbc.n, 
      bc=buildbc.bc);
    //Real sensorvalue;
    //Real heatervalue;
  equation 
    //heatervalue = regulator.y[1];
    //regulator.inPort.signal[1] = goalvalue - sensorvalue;
    //sensorvalue = pde.fd.val_u[2];
    // take value at 2.6055, 2.3320 => node 38 in mesh.x
    // u_indices[2] => 38 => fd.val_u[2]
    
    //pde.timeDepBndValue = heatervalue;
    
  end MyGenericBoundaryPoissonTest3;

  model MyGenericBoundaryPoissonTest4 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    
    // discretization parameters
    parameter Integer n=40;
    parameter Real refine=0.5;
    // domain geometry parameters
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    // regulator parameters
    parameter Real goalvalue=20;
    parameter Real regk=1;
    parameter Real regT=3;
    
    // heat parameters
    parameter Real k_g=54 "thermal conductivity J/m.min.K";
    parameter Real l_g=0.003 "thickness m.";
    parameter Real T_inf=5 "external temperature K";
    // dimensions 0.3 x 0.2 x 1 m.
    parameter Real rho=7821.0 "density kg/m^3";
    parameter Real C=449 "heat capacity J/kg.K";
    parameter Real k=4920 "thermal conductivity J/m.min.K";
    
    parameter Real T_heater=30;
    parameter Real hh=k_g/l_g;
    // Use PI regulator from Standard Library 
    // Modelica.Blocks.Continuous.PI regulator(k={regk}, T={regT});
    
    package MyBoundary = MyGenericBoundary3;
    
    parameter BoundaryCondition.Data neumann(
      bcType=BoundaryCondition.neumann, 
      g=0, 
      index=1, 
      name="robin");
    
    parameter BoundaryCondition.Data robin(
      bcType=BoundaryCondition.robin, 
      g=hh*T_inf, 
      q=hh/k, 
      index=2, 
      name="robin");
    // q=hh/k is implementation bug workaround. form is c*(a+q*ab)
    // where ab is contribution from q*u in robin bc. If we set q=hh/k
    // we get c*a + hh*ab which is what we want. 
    
    parameter BoundaryCondition.Data dirthree(
      bcType=BoundaryCondition.dirichlet, 
      g=T_heater, 
      index=3, 
      name="dirthree");
    
    parameter MyBoundary.Data bnd(
      p0=p0, 
      w=w, 
      h=h, 
      cw=cw, 
      bottom(bc=neumann), 
      right(bc=neumann), 
      top1(bc=neumann), 
      top2(bc=dirthree), 
      top3(bc=neumann), 
      left(bc=robin));
    
    package myDomainP = Domain (redeclare package boundaryP = MyBoundary);
    myDomainP.Data mydomain(boundary=bnd);
    
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
    
    BoundaryCondition.Buildbc buildbc(n=3, data={neumann,robin,dirthree});
    
    package PDE = PDEbhjl.FEMForms.Autonomous.Poisson2D (redeclare package 
          domainP = myDomainP);
    //package PDE = PDEbhjl.FEMForms.Autonomous.Diffusion2D (redeclare package 
    //      domainP = myDomainP);
    PDE.Equation pde(
      domain=mydomain, 
      nbp=n, 
      refine=refine, 
      g0=0, 
      c=k, 
      nbc=buildbc.n, 
      bc=buildbc.bc);
    //Real sensorvalue;
    //Real heatervalue;
  equation 
    //heatervalue = regulator.y[1];
    //regulator.inPort.signal[1] = goalvalue - sensorvalue;
    //sensorvalue = pde.fd.val_u[2];
    // take value at 2.6055, 2.3320 => node 38 in mesh.x
    // u_indices[2] => 38 => fd.val_u[2]
    
    //pde.timeDepBndValue = heatervalue;
    
  end MyGenericBoundaryPoissonTest4;
end testFEM;
