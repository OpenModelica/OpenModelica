

package testDomain 
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
      
      parameter Line.Data bottom(
        p1=p0, 
        p2=p0 + {w,0}, 
        index=1);
      parameter Line.Data top(
        p1=p0 + {w,h}, 
        p2=p0 + {0,h}, 
        index=2);
      parameter Line.Data left(
        p1=p0 + {0,h}, 
        p2=p0, 
        index=3);
      
      parameter Bezier.Data right(
        n=8, 
        p=fill(cc, 8) + {{0.0,-0.5},{0.0,-0.2},{0.0,0.0},{-0.85,-0.85},{-0.85,
            0.85},{0.0,0.0},{0.0,0.2},{0.0,0.5}}*{{cw,0},{0,ch}}, 
        index=4);
      
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
  
  package MyGenericBoundary 
    import PDEbhjl.*;
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnum;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnumC;
    
    extends Boundary;
    
    redeclare record extends Data 
      
      parameter Point p0;
      parameter Real w;
      parameter Real h;
      parameter Real r;
      parameter Real cw;
      
      parameter Point b1=p0 + {r,0};
      parameter Point b2=p0 + {w - r,0};
      parameter Point r1=p0 + {w,r};
      parameter Point r2=p0 + {w,h - r};
      parameter Point t1=p0 + {w - r,h};
      parameter Point t2=p0 + {r,h};
      parameter Point l1=p0 + {0,h - r};
      parameter Point l2=p0 + {0,r};
      parameter Point blc=p0 + {r,r};
      parameter Point brc=p0 + {w - r,r};
      parameter Point trc=p0 + {w - r,h - r};
      parameter Point tlc=p0 + {r,h - r};
      
      parameter Real ch=r2[2] - r1[2];
      parameter Point cc=p0 + {w,h/2};
      
      parameter Line.Data bottom(p1=b1, p2=b2);
      parameter Line.Data top(p1=t1, p2=t2);
      parameter Line.Data left(p1=l1, p2=l2);
      parameter Arc.Data bl(
        c=blc, 
        r=r, 
        a_start=Arc.pi, 
        a_end=2*Arc.pi*3/4);
      parameter Arc.Data br(
        c=brc, 
        r=r, 
        a_start=2*Arc.pi*3/4, 
        a_end=2*Arc.pi);
      parameter Arc.Data tr(
        c=trc, 
        r=r, 
        a_start=0, 
        a_end=Arc.pi/2);
      parameter Arc.Data tl(
        c=tlc, 
        r=r, 
        a_start=Arc.pi/2, 
        a_end=Arc.pi);
      
      parameter Bezier.Data right(n=8, p=fill(cc, 8) + {{0.0,-0.5},{0.0,-0.2},{
            0.0,0.0},{-0.85,-0.85},{-0.85,0.85},{0.0,0.0},{0.0,0.2},{0.0,0.5}}*
            {{cw,0},{0,ch}});
      
      parameter Composite8.Data boundary(
        parts1(arc=bl, partType=PartTypeEnumC.arc), 
        parts2(line=bottom, partType=PartTypeEnumC.line), 
        parts3(arc=br, partType=PartTypeEnumC.arc), 
        parts4(bezier=right, partType=PartTypeEnumC.bezier), 
        parts5(arc=tr, partType=PartTypeEnumC.arc), 
        parts6(line=top, partType=PartTypeEnumC.line), 
        parts7(arc=tl, partType=PartTypeEnumC.arc), 
        parts8(line=left, partType=PartTypeEnumC.line));
      
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    algorithm 
      x := Composite8.shape(u, d.boundary);
    end shape;
    
  end MyGenericBoundary;
  
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
        index=1);
      parameter Line.Data right(
        p1=p + {w,0}, 
        p2=p + {w,h - r}, 
        index=2);
      parameter Line.Data top(
        p1=p + {w - r,h}, 
        p2=p + {0,h}, 
        index=3);
      parameter Line.Data left(
        p1=p + {0,h}, 
        p2=p, 
        index=4);
      parameter Arc.Data roundedCorner(
        c=p + {w - r,h - r}, 
        r=r, 
        a_start=0, 
        a_end=Arc.pi/2, 
        index=5);
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
  
  model CircleTest 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    package DomainType = Domain (redeclare package boundaryP = Circle);
    parameter Integer n=10;
    parameter Circle.Data bnd(c={5,4}, r=3);
    
    parameter Point x[n]=DomainType.discretizeBoundary(n, bnd);
    Point u[n];
  equation 
    u = x;
  end CircleTest;
  
  model RectangleTest 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    package DomainType = Domain (redeclare package boundaryP = Rectangle);
    parameter Integer n=10;
    parameter Rectangle.Data bnd(
      p={1,1}, 
      w=3, 
      h=2);
    
    parameter BPoint x[n]=DomainType.discretizeBoundary(n, bnd);
    BPoint u[n];
  equation 
    u = x;
  end RectangleTest;
  
  model RectangleTestTemp 
    package DomainType = PDEbhjl.Domain (redeclare package boundaryP = 
            PDEbhjl.Boundaries.RectangleTemp);
    parameter Integer n=70;
    parameter DomainType.boundaryP.Data bnd(
      p={1,1}, 
      w=3, 
      h=2);
    
    parameter PDEbhjl.BPoint x[n]=DomainType.discretizeBoundary(n, bnd);
    //parameter Real bc[n, 3]=DomainType.getBoundaryConditions(n, bnd);
    PDEbhjl.BPoint u[n];
  equation 
    u = x;
  end RectangleTestTemp;
  
  model MyBoundaryTest 
    import PDEbhjl.*;
    
    package DomainType = Domain (redeclare package boundaryP = MyBoundary);
    parameter Integer n=50;
    parameter MyBoundary.Data bnd(
      p={10,10}, 
      w=5, 
      h=3, 
      r=2);
    
    parameter BPoint x[n]=DomainType.discretizeBoundary(n, bnd);
    BPoint u[n];
  equation 
    u = x;
  end MyBoundaryTest;
  
  model MyBoundaryDDTest 
    import PDEbhjl.*;
    
    package DomainType = Domain (redeclare package boundaryP = MyBoundary);
    parameter Integer n=50;
    parameter MyBoundary.Data bnd(
      p={1,1}, 
      w=5, 
      h=3, 
      r=2);
    parameter DomainType.Data domain(boundary=bnd);
    
    package DD = FEMForms.DiscreteDomain (redeclare package domainP = 
            DomainType);
    parameter DD.Data ddomain(
      nbp=n, 
      domain=domain, 
      refine=0.7);
    Point u[n];
    parameter Integer bc[n]=ddomain.mesh.bc;
  equation 
    u = ddomain.mesh.polygon;
  end MyBoundaryDDTest;
  
  model GenericCompositeTestTemp 
    import PDEbhjl.*;
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnum;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnumC;
    package DomainType = Domain (redeclare package boundaryP = Composite8);
    parameter Integer n=70;
    parameter Point p={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=1;
    
    parameter Point b1=p + {r,0};
    parameter Point b2=p + {w - r,0};
    parameter Point r1=p + {w,r};
    parameter Point r2=p + {w,h - r};
    parameter Point t1=p + {w - r,h};
    parameter Point t2=p + {r,h};
    parameter Point l1=p + {0,h - r};
    parameter Point l2=p + {0,r};
    parameter Point blc=p + {r,r};
    parameter Point brc=p + {w - r,r};
    parameter Point trc=p + {w - r,h - r};
    parameter Point tlc=p + {r,h - r};
    
    parameter Line.Data bottom(
      p1=b1, 
      p2=b2, 
      index=1);
    parameter Line.Data right(
      p1=r1, 
      p2=r2, 
      index=3);
    parameter Line.Data top(
      p1=t1, 
      p2=t2, 
      index=5);
    parameter Line.Data left(
      p1=l1, 
      p2=l2, 
      index=7);
    parameter Arc.Data bl(
      c=blc, 
      r=r, 
      a_start=Arc.pi, 
      a_end=2*Arc.pi*3/4, 
      index=8);
    parameter Arc.Data br(
      c=brc, 
      r=r, 
      a_start=2*Arc.pi*3/4, 
      a_end=2*Arc.pi, 
      index=2);
    parameter Arc.Data tr(
      c=trc, 
      r=r, 
      a_start=0, 
      a_end=Arc.pi/2, 
      index=4);
    parameter Arc.Data tl(
      c=tlc, 
      r=r, 
      a_start=Arc.pi/2, 
      a_end=Arc.pi, 
      index=6);
    parameter Composite8.Data bnd(
      parts1(arc=bl, partType=PartTypeEnumC.arc), 
      parts2(line=bottom, partType=PartTypeEnumC.line), 
      parts3(arc=br, partType=PartTypeEnumC.arc), 
      parts4(line=right, partType=PartTypeEnumC.line), 
      parts5(arc=tr, partType=PartTypeEnumC.arc), 
      parts6(line=top, partType=PartTypeEnumC.line), 
      parts7(arc=tl, partType=PartTypeEnumC.arc), 
      parts8(line=left, partType=PartTypeEnumC.line));
    
    parameter PDEbhjl.BPoint x[n]=DomainType.discretizeBoundary(n, bnd);
    PDEbhjl.Point u[n];
  equation 
    u = x[:, 1:2];
  end GenericCompositeTestTemp;
  
  model GenericCompositeTest2Temp 
    import PDEbhjl.*;
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnum;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnumC;
    package DomainType = Domain (redeclare package boundaryP = Composite8dist);
    parameter Integer n=150;
    parameter Point p={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    
    parameter Point b1=p + {r,0};
    parameter Point b2=p + {w - r,0};
    parameter Point r1=p + {w,r};
    parameter Point r2=p + {w,h - r};
    parameter Point t1=p + {w - r,h};
    parameter Point t2=p + {r,h};
    parameter Point l1=p + {0,h - r};
    parameter Point l2=p + {0,r};
    parameter Point blc=p + {r,r};
    parameter Point brc=p + {w - r,r};
    parameter Point trc=p + {w - r,h - r};
    parameter Point tlc=p + {r,h - r};
    
    parameter Real ch=r2[2] - r1[2];
    parameter Point cc=p + {w,h/2};
    
    parameter Line.Data bottom(p1=b1, p2=b2);
    parameter Line.Data top(p1=t1, p2=t2);
    parameter Line.Data left(p1=l1, p2=l2);
    parameter Arc.Data bl(
      c=blc, 
      r=r, 
      a_start=Arc.pi, 
      a_end=2*Arc.pi*3/4);
    parameter Arc.Data br(
      c=brc, 
      r=r, 
      a_start=2*Arc.pi*3/4, 
      a_end=2*Arc.pi);
    parameter Arc.Data tr(
      c=trc, 
      r=r, 
      a_start=0, 
      a_end=Arc.pi/2);
    parameter Arc.Data tl(
      c=tlc, 
      r=r, 
      a_start=Arc.pi/2, 
      a_end=Arc.pi);
    
    parameter Bezier.Data right(n=8, p=fill(cc, 8) + {{0.0,-0.5},{0.0,-0.2},{
          0.0,0.0},{-0.85,-0.85},{-0.85,0.85},{0.0,0.0},{0.0,0.2},{0.0,0.5}}*{{
          cw,0},{0,ch}});
    
    parameter Composite8dist.Data bnd(
      parts1(arc=bl, partType=PartTypeEnumC.arc), 
      parts2(line=bottom, partType=PartTypeEnumC.line), 
      parts3(arc=br, partType=PartTypeEnumC.arc), 
      parts4(bezier=right, partType=PartTypeEnumC.bezier), 
      parts5(arc=tr, partType=PartTypeEnumC.arc), 
      parts6(line=top, partType=PartTypeEnumC.line), 
      parts7(arc=tl, partType=PartTypeEnumC.arc), 
      parts8(line=left, partType=PartTypeEnumC.line), 
      distribution={0.5,0.2,0.5,1,0.5,0.2,0.5,0.2});
    
    parameter PDEbhjl.BPoint x[n]=DomainType.discretizeBoundary(n, bnd);
    PDEbhjl.Point u[n];
    parameter Integer bc[n]=integer(x[:, 3]);
  equation 
    u = x[:, 1:2];
  end GenericCompositeTest2Temp;
  
  model GenericCompositeDDTestTemp 
    import PDEbhjl.*;
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnum;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnumC;
    package DomainType = Domain (redeclare package boundaryP = Composite8);
    
    parameter Integer n=70;
    parameter Real refine=0.3;
    parameter Point p={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=1;
    
    parameter Point b1=p + {r,0};
    parameter Point b2=p + {w - r,0};
    parameter Point r1=p + {w,r};
    parameter Point r2=p + {w,h - r};
    parameter Point t1=p + {w - r,h};
    parameter Point t2=p + {r,h};
    parameter Point l1=p + {0,h - r};
    parameter Point l2=p + {0,r};
    parameter Point blc=p + {r,r};
    parameter Point brc=p + {w - r,r};
    parameter Point trc=p + {w - r,h - r};
    parameter Point tlc=p + {r,h - r};
    
    parameter Line.Data bottom(p1=b1, p2=b2);
    parameter Line.Data right(p1=r1, p2=r2);
    parameter Line.Data top(p1=t1, p2=t2);
    parameter Line.Data left(p1=l1, p2=l2);
    parameter Arc.Data bl(
      c=blc, 
      r=r, 
      a_start=Arc.pi, 
      a_end=2*Arc.pi*3/4);
    parameter Arc.Data br(
      c=brc, 
      r=r, 
      a_start=2*Arc.pi*3/4, 
      a_end=2*Arc.pi);
    parameter Arc.Data tr(
      c=trc, 
      r=r, 
      a_start=0, 
      a_end=Arc.pi/2);
    parameter Arc.Data tl(
      c=tlc, 
      r=r, 
      a_start=Arc.pi/2, 
      a_end=Arc.pi);
    parameter Composite8.Data bnd(
      parts1(arc=bl, partType=PartTypeEnumC.arc), 
      parts2(line=bottom, partType=PartTypeEnumC.line), 
      parts3(arc=br, partType=PartTypeEnumC.arc), 
      parts4(line=right, partType=PartTypeEnumC.line), 
      parts5(arc=tr, partType=PartTypeEnumC.arc), 
      parts6(line=top, partType=PartTypeEnumC.line), 
      parts7(arc=tl, partType=PartTypeEnumC.arc), 
      parts8(line=left, partType=PartTypeEnumC.line));
    
    parameter DomainType.Data domain(boundary=bnd);
    
    package DD = FEMForms.DiscreteDomain (redeclare package domainP = 
            DomainType);
    parameter DD.Data ddomain(
      nbp=n, 
      domain=domain, 
      refine=refine);
    
    PDEbhjl.Point u[n];
  equation 
    u = ddomain.mesh.polygon;
  end GenericCompositeDDTestTemp;
  
  model GenericCompositeDDTest2Temp 
    import PDEbhjl.*;
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnum;
    import PDEbhjl.Boundaries.GenericTemp.PartTypeEnumC;
    package domainP = Domain (redeclare package boundaryP = Composite8);
    
    parameter Integer n=64;
    parameter Real refine=0.8;
    parameter Point p={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    
    parameter Point b1=p + {r,0};
    parameter Point b2=p + {w - r,0};
    parameter Point r1=p + {w,r};
    parameter Point r2=p + {w,h - r};
    parameter Point t1=p + {w - r,h};
    parameter Point t2=p + {r,h};
    parameter Point l1=p + {0,h - r};
    parameter Point l2=p + {0,r};
    parameter Point blc=p + {r,r};
    parameter Point brc=p + {w - r,r};
    parameter Point trc=p + {w - r,h - r};
    parameter Point tlc=p + {r,h - r};
    
    parameter Real ch=r2[2] - r1[2];
    parameter Point cc=p + {w,h/2};
    
    parameter Line.Data bottom(p1=b1, p2=b2);
    parameter Line.Data top(p1=t1, p2=t2);
    parameter Line.Data left(p1=l1, p2=l2);
    parameter Arc.Data bl(
      c=blc, 
      r=r, 
      a_start=Arc.pi, 
      a_end=2*Arc.pi*3/4);
    parameter Arc.Data br(
      c=brc, 
      r=r, 
      a_start=2*Arc.pi*3/4, 
      a_end=2*Arc.pi);
    parameter Arc.Data tr(
      c=trc, 
      r=r, 
      a_start=0, 
      a_end=Arc.pi/2);
    parameter Arc.Data tl(
      c=tlc, 
      r=r, 
      a_start=Arc.pi/2, 
      a_end=Arc.pi);
    
    parameter Bezier.Data right(n=8, p=fill(cc, 8) + {{0.0,-0.5},{0.0,-0.2},{
          0.0,0.0},{-0.85,-0.85},{-0.85,0.85},{0.0,0.0},{0.0,0.2},{0.0,0.5}}*{{
          cw,0},{0,ch}});
    
    parameter Composite8.Data bnd(
      parts1(arc=bl, partType=PartTypeEnumC.arc), 
      parts2(line=bottom, partType=PartTypeEnumC.line), 
      parts3(arc=br, partType=PartTypeEnumC.arc), 
      parts4(bezier=right, partType=PartTypeEnumC.bezier), 
      parts5(arc=tr, partType=PartTypeEnumC.arc), 
      parts6(line=top, partType=PartTypeEnumC.line), 
      parts7(arc=tl, partType=PartTypeEnumC.arc), 
      parts8(line=left, partType=PartTypeEnumC.line));
    //    distribution={0.125,0.125,0.125,0.125,0.125,0.125,0.125,0.125});
    //   distribution={10,2,10,20,10,2,10,2});
    
    parameter domainP.Data domain(boundary=bnd);
    
    package DD = FEMForms.DiscreteDomain (redeclare package domainP = domainP);
    parameter DD.Data dd(
      nbp=n, 
      domain=domain, 
      refine=refine);
    
    PDEbhjl.Point u[n];
  equation 
    u = dd.mesh.polygon;
  end GenericCompositeDDTest2Temp;
  
  model CircleDDTest 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    package DomainType = Domain (redeclare package boundaryP = Circle);
    parameter Integer n=20;
    parameter Real refine=0.7;
    
    parameter Circle.Data bnd(c={5,4}, r=3);
    parameter DomainType.Data domain(boundary=bnd);
    
    package DD = FEMForms.DiscreteDomain (redeclare package domainP = 
            DomainType);
    parameter DD.Data ddomain(
      nbp=n, 
      domain=domain, 
      refine=refine);
    
    Point u[n];
  equation 
    u = ddomain.mesh.polygon;
  end CircleDDTest;
  
  model CircleFieldTest 
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    
    package MyDomain = Domain (redeclare package boundaryP = Circle);
    parameter Integer n=20;
    parameter Real refine=0.5;
    
    parameter Circle.Data bnd(c={0,0}, r=2);
    
    parameter MyDomain.Data domain(boundary=bnd);
    
    function myfunc 
      input Point x;
      input MyField.Data d;
      output MyField.FieldType y;
    algorithm 
      y := cos(2*Arc.pi*x[1]/6) + sin(2*Arc.pi*x[2]/6);
    end myfunc;
    
    function peaks 
      input Point x;
      input MyField.Data d;
      output MyField.FieldType y;
    algorithm 
      y := 3*(1 - x[1])^2.*exp(-(x[1]^2) - (x[2] + 1)^2) - 10*(x[1]/5 - x[1]^3
         - x[2]^5)*exp(-x[1]^2 - x[2]^2) - 1/3*exp(-(x[1] + 1)^2 - x[2]^2);
    end peaks;
    
    package MyField = Field (redeclare package domainP = MyDomain, redeclare 
          function value = myfunc);
    parameter MyField.Data field(domain=domain);
    
    // discrete part
    package MyDDomain = FEMForms.DiscreteDomain (redeclare package domainP = 
            MyDomain);
    parameter MyDDomain.Data ddomain(
      nbp=n, 
      domain=domain, 
      refine=refine);
    
    FEMForms.FEMSolver.FormSize formsize(nu=20, nb=10);
    
    package MyDField = FEMForms.DiscreteConstField (redeclare package fieldP = 
            MyField, redeclare package ddomainP = MyDDomain);
    
    MyDField.Data dfield(ddomain=ddomain, formsize=formsize);
    
    // Modelica part
    
    Point b[dfield.ddomain.boundarySize];
    MyDField.fieldP.FieldType u[dfield.fieldSize_u];
  equation 
    b = dfield.ddomain.mesh.polygon;
    u = dfield.val_u;
  end CircleFieldTest;
  
  
  model GenericBoundaryDDTest2Temp 
    import PDEbhjl.*;
    import PDEbhjl.Boundaries.*;
    
    package domainP = Domain (redeclare package boundaryP = MyGenericBoundary);
    parameter Integer n=64;
    parameter Real refine=0.8;
    parameter Point p0={1,1};
    parameter Real w=5;
    parameter Real h=3;
    parameter Real r=0.5;
    parameter Real cw=5;
    
    parameter MyGenericBoundary.Data bnd(
      p0=p0, 
      w=w, 
      h=h, 
      r=r, 
      cw=cw);
    
    parameter domainP.Data domain(boundary=bnd);
    
    package DD = FEMForms.DiscreteDomain (redeclare package domainP = domainP);
    parameter DD.Data dd(
      nbp=n, 
      domain=domain, 
      refine=refine);
    
    PDEbhjl.Point u[n];
  equation 
    u = dd.mesh.polygon;
  end GenericBoundaryDDTest2Temp;
  
  model ExtMeshTest 
    import PDEbhjl.FEMExternalMesh.*;
    parameter PDEbhjl.Point poly[:]={{0,0},{1,0},{1,1},{0,1}};
    parameter Integer bc[:]={1,1,1,1};
    Mesh.Data data(
      n=4, 
      polygon=poly, 
      bc=bc);
    Real x[3];
  equation 
    x = Mesh.get_x(data, 1);
  end ExtMeshTest;
  
  model ExtMeshTest2 
    import PDEbhjl.FEMExternalMesh.*;
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    
    package CircularDomain = Domain (redeclare package boundaryP = Circle);
    
    parameter Circle.Data bnd;
    
    CircularDomain.Data omega(boundary=bnd);
    
    package DiscreteCircularDomain = DiscreteDomain (redeclare package domainP 
          = CircularDomain);
    
    DiscreteCircularDomain.Data d_omega(nbp=20, domain=omega);
    Real x[3];
  equation 
    x = Mesh.get_x(d_omega.mesh, 7);
  end ExtMeshTest2;
  
  model ExtMeshTest3 
    import PDEbhjl.FEMExternalMesh.*;
    import PDEbhjl.Boundaries.*;
    import PDEbhjl.*;
    
    parameter Circle.Data bnd;
    
    package CircularDomain = Domain (redeclare package boundaryP = Circle);
    CircularDomain.Data omega(boundary=bnd);
    
    package CircularField = Field (redeclare package domainP = CircularDomain);
    CircularField.Data u(domain=omega);
    
    package DiscreteCircularDomain = DiscreteDomain (redeclare package domainP 
          = CircularDomain);
    DiscreteCircularDomain.Data d_omega(nbp=20, domain=omega);
    
    package DiscreteCircularField = DiscreteField (redeclare package fieldP = 
            CircularField, redeclare package ddomainP = DiscreteCircularDomain);
    package MyInterpolation = Interpolation (redeclare package dfieldP = 
            DiscreteCircularField);
    
    DiscreteCircularField.Data du(
      field=u, 
      ddomain=d_omega, 
      val=MyInterpolation.interpolate(d_omega, u, d_omega.mesh.nv));
    
  end ExtMeshTest3;
end testDomain;
