package PDE2D 
  type Coordinate = Real;
  type Point = Coordinate[2];
  package Boundaries 
    package Line 
      extends Boundary;
      
      redeclare record Parameters 
        Point p1;
        Point p2;
      end Parameters;
      
      redeclare record Data 
        parameter Parameters p;
      end Data;
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      algorithm 
        x := d.p.p1 + u*(d.p.p2 - d.p.p1);
      end shape;
      
    end Line;
    
    package Arc 
      extends Boundary;
      constant Real pi=3.141592654;
      
      redeclare record Parameters 
        Point c={0,0};
        Real r=1;
        Real a_start=0;
        Real a_end=2*pi;
      end Parameters;
      
      redeclare record Data 
        parameter Parameters p;
      end Data;
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      protected 
        Real a=(d.p.a_end - d.p.a_start);
      algorithm 
        x := d.p.c + d.p.r*{cos(d.p.a_start + a*u),sin(d.p.a_start + a*u)};
      end shape;
      
    end Arc;
    
    package Circle 
      extends Arc(Parameters(a_start=0, a_end=2*pi));
      
      // redeclare record Parameters = Arc.Parameters (a_start=0, a_end=2*Arc.pi);
      
      /*  
  record extends Data 
    parameter Parameters p;
    parameter Arc.Data arcData(p(c=p.c, r=p.r, a_start=0, a_end=2*Arc.pi));
  end Data;
  
  redeclare function shape 
    input Real u;
    input Data d;
    output Point x;
  algorithm 
    x := Arc.shape(u, d.arcData);
  end shape;
  */
      
    end Circle;
    
    package Rectangle 
      extends Boundary;
      package Bnd = HComposite (redeclare package PartType = Line);
      
      redeclare record Parameters 
        Point p;
        Real w;
        Real h;
      end Parameters;
      
      redeclare record Data 
        parameter Parameters p;
        parameter Bnd.Data bnddata(p(n=4), parts={bottom,right,top,left});
        parameter Line.Data bottom(p(p1=p.p, p2=p.p + {p.w,0}));
        parameter Line.Data right(p(p1=p.p + {p.w,0}, p2=p.p + {p.w,p.h}));
        parameter Line.Data top(p(p1=p.p + {p.w,p.h}, p2=p.p + {0,p.h}));
        parameter Line.Data left(p(p1=p.p + {0,p.h}, p2=p.p));
      end Data;
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      algorithm 
        x := Bnd.shape(u, d.bnddata);
      end shape;
      
      redeclare function points = Boundary.points;
      
    end Rectangle;
    
    package HComposite 
      extends Boundary;
      replaceable package PartType = Boundary extends Boundary;
      
      redeclare replaceable record Parameters 
        parameter Integer n=1;
        parameter PartType.Parameters parts[n];
      end Parameters;
      
      redeclare replaceable record Data 
        parameter Parameters p;
        parameter PartType.Data parts[p.n](p=p.parts);
      end Data;
      
      /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      protected 
        Real s=d.p.n*u;
        Integer is=integer(s);
      algorithm 
        x := PartType.shape(s - is, d.parts[1 + is]);
      end shape;
      
    end HComposite;
    
    package Generic 
      extends Boundary;
      
      type PartTypeEnum = enumeration (
          line, 
          arc, 
          circle, 
          rectangle);
      
      redeclare replaceable record Parameters 
        parameter PartTypeEnum partType;
        parameter Line.Parameters line;
        parameter Arc.Parameters arc;
        parameter Circle.Parameters circle;
        parameter Rectangle.Parameters rectangle;
      end Parameters;
      
      redeclare replaceable record Data 
        parameter Parameters p;
        parameter Line.Data line;
        parameter Arc.Data arc;
        parameter Circle.Data circle;
        parameter Rectangle.Data rectangle;
      end Data;
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      algorithm 
        if d.partType == PartType.line then
          x := Line.shape(u, d.line);
        else
          if d.partType == PartType.arc then
            x := Arc.shape(u, d.arc);
          else
            if d.partType == PartType.circle then
              x := Circle.shape(u, d.circle);
            else
              if d.partType == PartType.rectangle then
                x := Rectangle.shape(u, d.rectangle);
              end if;
            end if;
          end if;
        end if;
      end shape;
      
      redeclare function points = Boundary.points;
      
    end Generic;
    
    package Bezier 
      extends Boundary;
      
      redeclare record Parameters 
        parameter Integer n=1;
        Point p[n];
      end Parameters;
      
      redeclare record Data 
        parameter Parameters p;
      end Data;
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      protected 
        Point q[:]=d.p.p;
      algorithm 
        for k in 1:(d.p.n - 1) loop
          for i in 1:(d.p.n - k) loop
            q[i, :] := (1 - u)*q[i, :] + u*q[i + 1, :];
          end for;
        end for;
        x := q[1, :];
      end shape;
      
      redeclare function points = Boundary.points;
      
    end Bezier;
    
    package Composite8 
      extends Boundary;
      package PartType = Boundaries.GenericTemp;
      
      redeclare replaceable record Parameters 
        parameter Integer n=8;
        parameter PartType.Parameters parts1;
        parameter PartType.Parameters parts2;
        parameter PartType.Parameters parts3;
        parameter PartType.Parameters parts4;
        parameter PartType.Parameters parts5;
        parameter PartType.Parameters parts6;
        parameter PartType.Parameters parts7;
        parameter PartType.Parameters parts8;
      end Parameters;
      
      redeclare replaceable record Data 
        parameter Parameters p;
        parameter PartType.Data parts1(p=p.parts1);
        parameter PartType.Data parts2(p=p.parts2);
        parameter PartType.Data parts3(p=p.parts3);
        parameter PartType.Data parts4(p=p.parts4);
        parameter PartType.Data parts5(p=p.parts5);
        parameter PartType.Data parts6(p=p.parts6);
        parameter PartType.Data parts7(p=p.parts7);
        parameter PartType.Data parts8(p=p.parts8);
      end Data;
      
      /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      protected 
        Real s=d.p.n*u;
        Integer is=integer(s);
        Integer pno=is + 1;
      algorithm 
        x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
           then PartType.shape(s - is, d.parts2) else if pno == 3 then 
          PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(
          s - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.
          parts5) else if pno == 6 then PartType.shape(s - is, d.parts6) else 
          if pno == 7 then PartType.shape(s - is, d.parts7) else if pno == 8
           then PartType.shape(s - is, d.parts8) else {-1,-1};
      end shape;
      
      replaceable function points 
        input Integer n;
        input Data d;
        output Point x[n];
      algorithm 
        for i in 1:n loop
          x[i, :] := shape((i - 1)/n, d);
        end for;
      end points;
      
    end Composite8;
    
    package Composite8dist 
      extends Boundary;
      package PartType = Boundaries.GenericTemp;
      
      redeclare replaceable record Parameters 
        parameter Integer n=8;
        parameter PartType.Parameters parts1;
        parameter PartType.Parameters parts2;
        parameter PartType.Parameters parts3;
        parameter PartType.Parameters parts4;
        parameter PartType.Parameters parts5;
        parameter PartType.Parameters parts6;
        parameter PartType.Parameters parts7;
        parameter PartType.Parameters parts8;
        parameter Real distribution[n]=ones(n);
        //parameter Integer distribution[n];
      end Parameters;
      
      redeclare replaceable record Data 
        parameter Parameters p;
        parameter PartType.Data parts1(p=p.parts1);
        parameter PartType.Data parts2(p=p.parts2);
        parameter PartType.Data parts3(p=p.parts3);
        parameter PartType.Data parts4(p=p.parts4);
        parameter PartType.Data parts5(p=p.parts5);
        parameter PartType.Data parts6(p=p.parts6);
        parameter PartType.Data parts7(p=p.parts7);
        parameter PartType.Data parts8(p=p.parts8);
      end Data;
      
      /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      protected 
        Real s=d.p.n*u;
        Integer is=integer(s);
        Integer pno=is + 1;
      algorithm 
        x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
           then PartType.shape(s - is, d.parts2) else if pno == 3 then 
          PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(
          s - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.
          parts5) else if pno == 6 then PartType.shape(s - is, d.parts6) else 
          if pno == 7 then PartType.shape(s - is, d.parts7) else if pno == 8
           then PartType.shape(s - is, d.parts8) else {-1,-1};
      end shape;
      
      replaceable function points 
        input Integer n;
        input Data d;
        output Point x[n];
      protected 
        Integer numbers[d.p.n]=integer(n*d.p.distribution);
        //Integer numbers[d.p.n]=d.p.distribution;
        Integer j1=1;
        Integer j2;
      algorithm 
        for i in 1:d.p.n loop
          j2 := j1 + numbers[i] - 1;
          x[j1:j2, :] := if i == 1 then PartType.points(numbers[i], d.parts1)
             else if i == 2 then PartType.points(numbers[i], d.parts2) else if 
            i == 3 then PartType.points(numbers[i], d.parts3) else if i == 4
             then PartType.points(numbers[i], d.parts4) else if i == 5 then 
            PartType.points(numbers[i], d.parts5) else if i == 6 then 
            PartType.points(numbers[i], d.parts6) else if i == 7 then 
            PartType.points(numbers[i], d.parts7) else if i == 8 then 
            PartType.points(numbers[i], d.parts8) else PartType.points(numbers[
            i], d.parts1);
          /*
      for k in j1:j2 loop
        x[k, :] := {j1,j2};
      end for;
*/
          j1 := j1 + numbers[i];
        end for;
      end points;
      
    end Composite8dist;
    
    package GenericTemp 
      extends Boundary;
      
      type PartTypeEnum = Integer (min=PartTypeEnumC.Begin, max=PartTypeEnumC.
              End);
      package PartTypeEnumC 
        constant Integer Begin=1;
        constant PartTypeEnum line=Begin + 0;
        constant PartTypeEnum arc=Begin + 1;
        constant PartTypeEnum circle=Begin + 2;
        constant PartTypeEnum rectangle=Begin + 3;
        constant PartTypeEnum bezier=Begin + 4;
        constant Integer End=Begin + 4;
      end PartTypeEnumC;
      
      redeclare record Parameters 
        parameter PartTypeEnum partType;
        parameter Boundaries.Line.Parameters line;
        parameter Boundaries.Arc.Parameters arc;
        parameter Boundaries.Circle.Parameters circle;
        parameter Boundaries.RectangleTemp.Parameters rectangle;
        parameter Boundaries.Bezier.Parameters bezier;
      end Parameters;
      
      redeclare record Data 
        parameter Parameters p;
        parameter Boundaries.Line.Data line(p=p.line);
        parameter Boundaries.Arc.Data arc(p=p.arc);
        parameter Boundaries.Circle.Data circle(p=p.circle);
        parameter Boundaries.RectangleTemp.Data rectangle(p=p.rectangle);
        parameter Boundaries.Bezier.Data bezier(p=p.bezier);
      end Data;
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      algorithm 
        if d.p.partType == PartTypeEnumC.line then
          x := Boundaries.Line.shape(u, d.line);
        else
          if d.p.partType == PartTypeEnumC.arc then
            x := Boundaries.Arc.shape(u, d.arc);
          else
            if d.p.partType == PartTypeEnumC.circle then
              x := Boundaries.Circle.shape(u, d.circle);
            else
              if d.p.partType == PartTypeEnumC.rectangle then
                x := Boundaries.RectangleTemp.shape(u, d.rectangle);
              else
                if d.p.partType == PartTypeEnumC.bezier then
                  x := Boundaries.Bezier.shape(u, d.bezier);
                end if;
              end if;
            end if;
          end if;
        end if;
      end shape;
      
      redeclare function points = Boundary.points;
      
    end GenericTemp;
    
    package HComposite4 
      extends Boundary;
      replaceable package PartType = Boundary extends Boundary;
      
      redeclare replaceable record Parameters 
        parameter Integer n=4;
        parameter PartType.Parameters parts1;
        parameter PartType.Parameters parts2;
        parameter PartType.Parameters parts3;
        parameter PartType.Parameters parts4;
      end Parameters;
      
      redeclare replaceable record Data 
        parameter Parameters p;
        parameter PartType.Data parts1(p=p.parts1);
        parameter PartType.Data parts2(p=p.parts2);
        parameter PartType.Data parts3(p=p.parts3);
        parameter PartType.Data parts4(p=p.parts4);
      end Data;
      
      /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      protected 
        Real s=d.p.n*u;
        Integer is=integer(s);
        Integer pno=is + 1;
      algorithm 
        x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
           then PartType.shape(s - is, d.parts2) else if pno == 3 then 
          PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(
          s - is, d.parts4) else {-1,-1};
      end shape;
      
    end HComposite4;
    
    package HComposite8 
      extends Boundary;
      replaceable package PartType = Boundary extends Boundary;
      
      redeclare replaceable record Parameters 
        parameter Integer n=8;
        parameter PartType.Parameters parts1;
        parameter PartType.Parameters parts2;
        parameter PartType.Parameters parts3;
        parameter PartType.Parameters parts4;
        parameter PartType.Parameters parts5;
        parameter PartType.Parameters parts6;
        parameter PartType.Parameters parts7;
        parameter PartType.Parameters parts8;
      end Parameters;
      
      redeclare replaceable record Data 
        parameter Parameters p;
        parameter PartType.Data parts1(p=p.parts1);
        parameter PartType.Data parts2(p=p.parts2);
        parameter PartType.Data parts3(p=p.parts3);
        parameter PartType.Data parts4(p=p.parts4);
        parameter PartType.Data parts5(p=p.parts5);
        parameter PartType.Data parts6(p=p.parts6);
        parameter PartType.Data parts7(p=p.parts7);
        parameter PartType.Data parts8(p=p.parts8);
      end Data;
      
      /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      protected 
        Real s=d.p.n*u;
        Integer is=integer(s);
        Integer pno=is + 1;
      algorithm 
        x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
           then PartType.shape(s - is, d.parts2) else if pno == 3 then 
          PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(
          s - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.
          parts5) else if pno == 6 then PartType.shape(s - is, d.parts6) else 
          if pno == 7 then PartType.shape(s - is, d.parts7) else if pno == 8
           then PartType.shape(s - is, d.parts8) else {-1,-1};
      end shape;
      
    end HComposite8;
    
    package RectangleTemp 
      extends Boundary;
      package Bnd = HComposite4 (redeclare package PartType = Boundaries.Line);
      
      redeclare record Parameters 
        Point p;
        Real w;
        Real h;
      end Parameters;
      
      redeclare record Data 
        parameter Parameters p;
        parameter Bnd.Data bnddata(
          p(n=4), 
          parts1=bottom, 
          parts2=right, 
          parts3=top, 
          parts4=left);
        parameter Boundaries.Line.Data bottom(p(p1=p.p, p2=p.p + {p.w,0}));
        parameter Boundaries.Line.Data right(p(p1=p.p + {p.w,0}, p2=p.p + {p.w,
                p.h}));
        parameter Boundaries.Line.Data top(p(p1=p.p + {p.w,p.h}, p2=p.p + {0,p.
                h}));
        parameter Boundaries.Line.Data left(p(p1=p.p + {0,p.h}, p2=p.p));
      end Data;
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      algorithm 
        x := Bnd.shape(u, d.bnddata);
      end shape;
      
    end RectangleTemp;
    
    package Composite4 
      extends Boundary;
      package PartType = Boundaries.GenericTemp;
      
      redeclare replaceable record Parameters 
        parameter Integer n=4;
        parameter PartType.Parameters parts1;
        parameter PartType.Parameters parts2;
        parameter PartType.Parameters parts3;
        parameter PartType.Parameters parts4;
      end Parameters;
      
      redeclare replaceable record Data 
        parameter Parameters p;
        parameter PartType.Data parts1(p=p.parts1);
        parameter PartType.Data parts2(p=p.parts2);
        parameter PartType.Data parts3(p=p.parts3);
        parameter PartType.Data parts4(p=p.parts4);
      end Data;
      
      /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
      
      redeclare function shape 
        input Real u;
        input Data d;
        output Point x;
      protected 
        Real s=d.p.n*u;
        Integer is=integer(s);
        Integer pno=is + 1;
      algorithm 
        x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
           then PartType.shape(s - is, d.parts2) else if pno == 3 then 
          PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(
          s - is, d.parts4) else {-1,-1};
      end shape;
      
      replaceable function points 
        input Integer n;
        input Data d;
        output Point x[n];
      algorithm 
        for i in 1:n loop
          x[i, :] := shape((i - 1)/n, d);
        end for;
      end points;
      
    end Composite4;
  end Boundaries;
  
  package Boundary 
    
    replaceable function shape 
      input Real u;
      input Data d;
      output Point x;
    algorithm 
      x := {u,u};
    end shape;
    
    replaceable function points 
      input Integer n;
      input Data d;
      output Point x[n];
    algorithm 
      for i in 1:n loop
        x[i, :] := shape((i - 1)/n, d);
      end for;
    end points;
    
    replaceable record Data 
      parameter Parameters p;
    end Data;
    
    replaceable record Parameters = Dummy;
    
    record Dummy 
      
    end Dummy;
    
  end Boundary;
  
  package Domain 
    replaceable package boundaryP = Boundary extends Boundary;
    //  record Data = boundary.Data;
    
    /*  
  replaceable record Parameters 
    parameter boundaryP.Parameters boundary;
  end Parameters;
  */
    
    replaceable record Data 
      parameter boundaryP.Data boundary;
    end Data;
    
    function discretizeBoundary 
      input Integer n;
      input boundaryP.Data d;
      output Point p[n];
    algorithm 
      for i in 1:n loop
        p[i, :] := boundaryP.shape((i - 1)/n, d);
      end for;
    end discretizeBoundary;
    
    function boundaryPoints = boundaryP.points;
    
  end Domain;
  
  package FEM 
    package Autonomous 
      package Poisson2D "Poisson problem 2D" 
        import PDE2D.FEM.PoissonSolver.*;
        
        replaceable package domainP = Domain;
        //  replaceable package initialField = ConstField;
        /* (redeclare function value = 
  valfunc); */
        //replaceable function valfunc = ConstField.value;
        
        model Equation "Poisson equation 2D" 
          parameter Real g0=1 "Constant value of field";
          parameter domainP.Data domain;
          parameter Integer nbp=20;
          parameter Real refine=0.7;
          //parameter initialField.Parameters inifp;
          
          // internal packages  
          package rhsFieldP = ConstConstField (redeclare package domainP = 
                  domainP);
          parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
          
          package uFieldP = Field (redeclare package domainP = domainP);
          parameter uFieldP.Data uField(domain=domain);
          
          // discrete part
          package ddomainP = DiscreteDomain (redeclare package domainP = 
                  domainP);
          parameter ddomainP.Data ddomain(
            domain=domain, 
            nbp=nbp, 
            refine=refine);
          
          package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                  rhsFieldP, redeclare package ddomainP = ddomainP);
          package interpolationP = Interpolation (redeclare package dfieldP = 
                  rhsDFieldP);
          parameter rhsDFieldP.Data g_rhs(
            ddomain=ddomain, 
            field=rhsField, 
            val=interpolationP.interpolate(ddomain, rhsField, ddomain.mesh.nv));
          
          package uDFieldP = DiscreteField (redeclare package ddomainP = 
                  ddomainP, redeclare package fieldP = uFieldP);
          uDFieldP.Data fd(
            ddomain=ddomain, 
            field=uField, 
            val(start={1 for i in 1:ddomain.mesh.nv}));
          
        protected 
          parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd
              .ddomain.mesh.ne};
          //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
          //    parameter Real g[fd.ddomain.mesh.nv];
          parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=
              getMatrix_Laplace(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.ddomain
              .mesh.ne, g_rhs.val, bndcond);
          parameter Real g[fd.ddomain.mesh.nv]=getMatrix_g(fd.ddomain.mesh, fd.
              ddomain.mesh.nv, fd.ddomain.mesh.ne, g_rhs.val, bndcond);
          /*   
    parameter Real Lg[:, :]=assemble(fd.ddomain.mesh.nt, fd.ddomain.mesh.nv, fd
        .ddomain.mesh.triangle, fd.ddomain.mesh.x, g_rhs.val);
    parameter Real LgBd[:, :]=assembleBd(fd.ddomain.mesh.ne, fd.ddomain.mesh.nv, 
        fd.ddomain.mesh.edge, fd.ddomain.mesh.x, Lg, bndcond);
    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=LgBd[1:fd.
        ddomain.mesh.nv, 1:fd.ddomain.mesh.nv];
    parameter Real g[fd.ddomain.mesh.nv]=LgBd[1:fd.ddomain.mesh.nv, fd.ddomain.
        mesh.nv + 1];
  */
          //  initial equation 
          //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
          //      bndcond);
        equation 
          -Laplace*fd.val = g;
          //fd.val = g;
        end Equation;
        
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        
      end Poisson2D;
    end Autonomous;
    
    package Discretize     end Discretize;
    
    package DiscreteField 
      replaceable package fieldP = Field;
      replaceable package ddomainP = DiscreteDomain;
      //replaceable package valfunc = ConstField.value;
      //replaceable package initialDField = DiscreteConstField;
      //replaceable package initialField = ConstField;
      
      //package initialDField = DiscreteConstField (redeclare package field = 
      //        initialField, redeclare package ddomain = ddomain);
      
      replaceable record Data 
        parameter ddomainP.Data ddomain;
        parameter fieldP.Data field;
        //parameter initialDField.Parameters inip(ddom=p.ddom, fld=p.fld);
        //parameter initialDField.Data inidata(p=inip);
        fieldP.FieldType val[ddomain.mesh.nv];
        //(start=inidata.val);
        parameter Integer fieldSize=size(val, 1);
      end Data;
      
    end DiscreteField;
    
    package DiscreteDomain 
      replaceable package domainP = Domain extends Domain;
      
      replaceable record Data 
        parameter Integer nbp;
        parameter domainP.Data domain;
        parameter Real refine=0.7;
        
        parameter Point polygon[:]=domainP.discretizeBoundary(nbp, domain.
            boundary);
        //parameter Point polygon[:]=DomainType.boundaryPoints(p.nbp, bd);
        parameter Mesh.Data mesh(
          n=size(polygon, 1), 
          polygon=polygon, 
          refine=refine);
        parameter Integer boundarySize=size(polygon, 1);
      end Data;
      
    end DiscreteDomain;
    
    package Mesh "2D spatial domain" 
      import PDE2D.FEM.MeshGeneration.*;
      
      function generate = generate2D;
      function get_s = sizes2D;
      function get_v = vertices2D;
      function get_e = edges2D;
      function get_t = triangles2D;
      
      record Data 
        parameter Integer n;
        parameter Point polygon[n];
        parameter Integer bc[:]={1 for i in 1:n};
        parameter Real refine(
          min=0, 
          max=1) = 0.7 "0 < refine < 1, less is finer";
        parameter String filename="default_mesh2D.txt";
        // will be overwritten!
        
        // If Cygwin (BAMG) not installed, bypass generation of grid, just read existing files.
        parameter Integer status=generate(polygon, bc, filename, refine);
        
        //parameter Integer s[3] = get_s(mesh, status);
        // Necessary for dependency! Currently not supported by Dymola (BUG?)
        parameter Integer s[3]=get_s(filename, 1);
        
        parameter Integer nv=s[1] "Number of vertices";
        parameter Integer ne=s[2] "Number of edges on boundary";
        parameter Integer nt=s[3] "Number of triangles";
        parameter Coordinate x[:, 3]=get_v(filename, nv) 
          "Coordinates of grid-points (1:2) and inner/bd (3)";
        parameter Integer edge[:, 3]=get_e(filename, ne) 
          "Edges by vertex-tuple (1:2) and index for boundary condition (3)";
        parameter Integer triangle[:, 4]=get_t(filename, nt) 
          "Triangles by vertex-triple (1:3) and index for dependence of coefficients (4)";
      end Data;
      
    end Mesh;
    
    package MeshGeneration "Grid generation for 1D and triangular 2D" 
      function generate1D "Generates 1D mesh" 
        
        input Real xPolygon[:];
        input Integer bc[size(xPolygon, 1)];
        input String outputfile;
        input Real refine=0.1;
        // 0 < refine < 1, controls refinement of triangles, less is finer.
        output Integer status;
      external "C" oneg_generate_mesh("onegrun.bat", outputfile, status, 
          xPolygon, size(xPolygon, 1), bc, size(bc, 1), refine)
          annotation (Include="#include <oneg_generate_mesh.c>");
        /*  
//for test:
algorithm 
  status := 0;
*/
      end generate1D;
      
      function sizes1D "Reads sizes mesh-data 1D" 
        
        input String mesh;
        input Integer status;
        output Integer s[3] 
          "Sizes of mesh-data {vertices, bdpoints, intervals}";
      external "C" oneg_read_sizes(mesh, s, size(s, 1))
          annotation (Include="#include <oneg_read_sizes.c>");
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
      external "C" oneD_read_vertices(mesh, v, size(v, 1), size(v, 2))
          annotation (Include="#include <oneg_read_vertices.c>");
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
      external "C" oneD_read_bdpoints(mesh, b, size(b, 1), size(b, 2))
          annotation (Include="#include <oneg_read_bdpoints.c>");
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
          annotation (Include="#include <oneg_read_intervals.c>");
        /*  
//for test:
algorithm 
  i := [1,2,1; 2,3,1; 3,4,1; 4,5,1; 5,6,1; 6,7,1; 7,8,1; 8,9,1; 9,10,1; 10,11,1];
*/
      end intervals1D;
      
      function generate2D "Generates 2D triangular mesh" 
        
        input Real xPolygon[:, 2];
        input Integer bc[size(xPolygon, 1)];
        input String outputfile;
        input Real refine=0.5;
        // h in (0,1) controls the refinement of triangles, less is finer
        output Integer status;
      external "C" bamg_generate_mesh("bamgrun.bat", outputfile, status, 
          xPolygon, size(xPolygon, 1), size(xPolygon, 2), bc, size(bc, 1), 
          refine) annotation (Include="#include <bamg_generate_mesh.c>");
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
      external "C" bamg_read_sizes(mesh, s, size(s, 1))
          annotation (Include="#include <bamg_read_sizes.c>");
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
      external "C" bamg_read_vertices(mesh, v, size(v, 1), size(v, 2))
          annotation (Include="#include <bamg_read_vertices.c>");
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
      external "C" bamg_read_edges(mesh, e, size(e, 1), size(e, 2))
          annotation (Include="#include <bamg_read_edges.c>");
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
      external "C" bamg_read_triangles(mesh, t, size(t, 1), size(t, 2))
          annotation (Include="#include <bamg_read_triangles.c>");
        /*  
//for test:
algorithm 
  t := [1,2,3,4;5,6,7,8];
*/
      end triangles2D;
      
    end MeshGeneration;
    
    package DiscreteConstField 
      replaceable package fieldP = Field;
      
      replaceable package ddomainP = DiscreteDomain;
      
      //  package interpolation = Interpolation (redeclare package field = field);
      
      redeclare replaceable record Data 
        parameter ddomainP.Data ddomain;
        parameter fieldP.Data field;
        parameter fieldP.FieldType val[ddomain.mesh.nv];
        parameter Integer fieldSize=size(val, 1);
      end Data;
      
    end DiscreteConstField;
    
    package Interpolation 
      
      replaceable package dfieldP = DiscreteField;
      
      function interpolate 
        //input Mesh.Data mesh;
        //input Integer fieldSize;
        input dfieldP.ddomainP.Data ddomain;
        input dfieldP.fieldP.Data field;
        input Integer fieldSize;
        output dfieldP.fieldP.FieldType val[fieldSize];
      protected 
        Point x;
      algorithm 
        for i in 1:size(val, 1) loop
          x := ddomain.mesh.x[i, 1:2];
          val[i] := dfieldP.fieldP.value(x, field);
        end for;
      end interpolate;
      
    end Interpolation;
    
    package PoissonSolver 
      
      function getMatrix_Laplace 
        input Mesh.Data mesh;
        input Integer nv;
        input Integer ne;
        input Real g_rhs_val[nv];
        input Integer bndcond[ne, 2];
        output Real Laplace[nv, nv];
      protected 
        parameter Real Lg[mesh.nv, mesh.nv + 1]=assemble(mesh.nt, mesh.nv, mesh
            .triangle, mesh.x, g_rhs_val);
        parameter Real LgBd[mesh.nv, mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
            mesh.edge, mesh.x, Lg, bndcond);
      algorithm 
        Laplace := LgBd[1:mesh.nv, 1:mesh.nv];
        // For debugging
        // FEMExternal.PoissonSolver.writeMatrix_Laplace(nv,Laplace);
      end getMatrix_Laplace;
      
      function getMatrix_g 
        input Mesh.Data mesh;
        input Integer nv;
        input Integer ne;
        input Real g_rhs_val[nv];
        input Integer bndcond[ne, 2];
        output Real g[nv];
      protected 
        parameter Real Lg[mesh.nv, mesh.nv + 1]=assemble(mesh.nt, mesh.nv, mesh
            .triangle, mesh.x, g_rhs_val);
        parameter Real LgBd[mesh.nv, mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
            mesh.edge, mesh.x, Lg, bndcond);
      algorithm 
        g := LgBd[1:mesh.nv, mesh.nv + 1];
        // For debugging    
        // FEMExternal.PoissonSolver.writeMatrix_g(nv,g);
      end getMatrix_g;
      
      function assemble "Assembles stiffness and mass matrix" 
        input Integer nTriangles;
        input Integer nVertices;
        input Integer triangles[nTriangles, 4];
        input Real vertices[nVertices, 3];
        input Real g_val[:];
        output Real Ab[nVertices, nVertices + 1];
      protected 
        Integer Tk[3];
        Real Ak[3, 3];
        Real Lk[3];
        
        Integer i;
        Integer j;
      algorithm 
        Ab := zeros(nVertices, nVertices + 1);
        
        for k in 1:nTriangles loop
          Tk := triangles[k, 1:3];
          (Ak,Lk) := element(vertices[Tk, 1], vertices[Tk, 2], g_val[Tk]);
          
          for local_1 in 1:3 loop
            i := Tk[local_1];
            for local_2 in 1:3 loop
              j := Tk[local_2];
              Ab[i, j] := Ab[i, j] - Ak[local_1, local_2];
            end for;
            Ab[i, nVertices + 1] := Ab[i, nVertices + 1] + Lk[local_1];
            
          end for;
          
        end for;
        
        annotation (Documentation(info="<HTML>
<pre>
Assembles the stiffness and mass matrix according to the differential equation.
The boundary conditions are treated separately. 
</pre>
</HTML>"));
      end assemble;
      
      function assembleBd "Includes boundary conditions into stiffnes matrix" 
        
        input Integer nEdges;
        input Integer nVertices;
        input Integer edges[nEdges, 3];
        input Real vertices[nVertices, 3];
        input Real Ab[nVertices, nVertices + 1];
        input Integer type_bc[:, :];
        output Real AbBd[nVertices, nVertices + 1];
      protected 
        Real v[2, 3];
        
      algorithm 
        AbBd := Ab;
        
        for i in 1:nEdges loop
          
          if edges[i, 3] > 0 then
            v := vertices[edges[i, 1:2], :];
            //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
            
            if type_bc[integer(edges[i, 3]), 1] == 0 then
              
              for j in 1:nVertices loop
                AbBd[edges[i, 1], j] := 0;
                AbBd[edges[i, 2], j] := 0;
                
              end for;
              AbBd[edges[i, 1], edges[i, 1]] := 1;
              AbBd[edges[i, 2], edges[i, 2]] := 1;
              // Put inhomogenous Dirichlet conditions here!!
              AbBd[edges[i, 1], nVertices + 1] := 0;
              AbBd[edges[i, 2], nVertices + 1] := 0;
              
            else
              // Put inhomogenous Neumann conditions here!!
              AbBd[edges[i, 1], nVertices + 1] := 0;
              AbBd[edges[i, 2], nVertices + 1] := 0;
              
            end if;
            
          end if;
          
        end for;
        
        annotation (Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
      end assembleBd;
      
      function element "Stiffness contributions per triangle" 
        input Real Px[3];
        input Real Py[3];
        input Real g[3];
        output Real Ak[3, 3];
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
        detk := abs((Px[2] - Px[1])*(Py[3] - Py[1]) - (Px[3] - Px[1])*(Py[2] - 
          Py[1]));
        F := detk/2;
        
        for i in 1:3 loop
          
          for j in i + 1:3 loop
            l := if i + j == 3 then 3 else if i + j == 4 then 2 else 1;
            Ak[i, j] := 1/2/detk*((Px[i] - Px[l])*(Px[l] - Px[j]) + (Py[i] - Py[
              l])*(Py[l] - Py[j]));
            Ak[j, i] := Ak[i, j];
            
          end for;
          
        end for;
        
        for i in 1:3 loop
          j := if i == 1 then 2 else if i == 2 then 3 else 1;
          k := if i == 1 then 3 else if i == 2 then 1 else 2;
          Ak[i, i] := 1/2/detk*((Px[j] - Px[k])^2 + (Py[j] - Py[k])^2);
          
        end for;
        md := 1/12*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
           - Px[1]));
        mk := 1/24*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
           - Px[1]));
        Lk := {md*g[1] + mk*g[2] + mk*g[3],mk*g[1] + md*g[2] + mk*g[3],mk*g[1]
           + mk*g[2] + md*g[3]};
        annotation (Documentation(info=""));
      end element;
    end PoissonSolver;
    
  end FEM;
  
  package Field 
    replaceable type FieldType = Real;
    replaceable package domainP = Domain extends Domain;
    //replaceable package initialField = Field extends ConstField;
    
    replaceable record Data 
      parameter domainP.Data domain;
    end Data;
    
    replaceable function value 
      input Point x;
      input Data d;
      output FieldType y;
    algorithm 
      y := 0;
    end value;
    
  end Field;
  
  package ConstConstField 
    extends Field;
    
    redeclare record Data 
      parameter domainP.Data domain;
      parameter FieldType constval;
    end Data;
    
    redeclare function value 
      input Point x;
      input Data d;
      output FieldType y;
    algorithm 
      y := d.constval;
    end value;
    
  end ConstConstField;
  
  package FEMExternalMesh 
    package Autonomous 
      package Poisson2D "Poisson problem 2D" 
        import PDE2D.FEMExternalMesh.PoissonSolver.*;
        
        replaceable package domainP = Domain;
        //  replaceable package initialField = ConstField;
        /* (redeclare function value = 
  valfunc); */
        //replaceable function valfunc = ConstField.value;
        
        model Equation "Poisson equation 2D" 
          parameter Real g0=1 "Constant value of field";
          parameter domainP.Data domain;
          parameter Integer nbp=20;
          parameter Real refine=0.7;
          //parameter initialField.Parameters inifp;
          
          // internal packages  
          package rhsFieldP = ConstConstField (redeclare package domainP = 
                  domainP);
          parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
          
          package uFieldP = Field (redeclare package domainP = domainP);
          parameter uFieldP.Data uField(domain=domain);
          
          // discrete part
          package ddomainP = DiscreteDomain (redeclare package domainP = 
                  domainP);
          parameter ddomainP.Data ddomain(
            domain=domain, 
            nbp=nbp, 
            refine=refine);
          
          package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                  rhsFieldP, redeclare package ddomainP = ddomainP);
          package interpolationP = Interpolation (redeclare package dfieldP = 
                  rhsDFieldP);
          parameter rhsDFieldP.Data g_rhs(
            ddomain=ddomain, 
            field=rhsField, 
            val=interpolationP.interpolate(ddomain, rhsField, ddomain.mesh.nv));
          
          package uDFieldP = DiscreteField (redeclare package ddomainP = 
                  ddomainP, redeclare package fieldP = uFieldP);
          uDFieldP.Data fd(
            ddomain=ddomain, 
            field=uField, 
            val(start={1 for i in 1:ddomain.mesh.nv}));
          
        protected 
          parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd
              .ddomain.mesh.ne};
          //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
          //    parameter Real g[fd.ddomain.mesh.nv];
          parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=
              getMatrix_Laplace(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.ddomain
              .mesh.ne, g_rhs.val, bndcond);
          parameter Real g[fd.ddomain.mesh.nv]=getMatrix_g(fd.ddomain.mesh, fd.
              ddomain.mesh.nv, fd.ddomain.mesh.ne, g_rhs.val, bndcond);
          /*   
    parameter Real Lg[:, :]=assemble(fd.ddomain.mesh.nt, fd.ddomain.mesh.nv, fd
        .ddomain.mesh.triangle, fd.ddomain.mesh.x, g_rhs.val);
    parameter Real LgBd[:, :]=assembleBd(fd.ddomain.mesh.ne, fd.ddomain.mesh.nv, 
        fd.ddomain.mesh.edge, fd.ddomain.mesh.x, Lg, bndcond);
    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=LgBd[1:fd.
        ddomain.mesh.nv, 1:fd.ddomain.mesh.nv];
    parameter Real g[fd.ddomain.mesh.nv]=LgBd[1:fd.ddomain.mesh.nv, fd.ddomain.
        mesh.nv + 1];
  */
          //  initial equation 
          //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
          //      bndcond);
        equation 
          -Laplace*fd.val = g;
          //fd.val = g;
        end Equation;
        
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        
      end Poisson2D;
    end Autonomous;
    
    package Discretize     end Discretize;
    
    package DiscreteField 
      replaceable package fieldP = Field;
      replaceable package ddomainP = DiscreteDomain;
      //replaceable package valfunc = ConstField.value;
      //replaceable package initialDField = DiscreteConstField;
      //replaceable package initialField = ConstField;
      
      //package initialDField = DiscreteConstField (redeclare package field = 
      //        initialField, redeclare package ddomain = ddomain);
      
      replaceable record Data 
        parameter ddomainP.Data ddomain;
        parameter fieldP.Data field;
        //parameter initialDField.Parameters inip(ddom=p.ddom, fld=p.fld);
        //parameter initialDField.Data inidata(p=inip);
        fieldP.FieldType val[ddomain.mesh.nv];
        //(start=inidata.val);
        parameter Integer fieldSize=size(val, 1);
      end Data;
      
    end DiscreteField;
    
    package DiscreteDomain 
      replaceable package domainP = Domain extends Domain;
      
      replaceable record Data 
        parameter Integer nbp;
        parameter domainP.Data domain;
        parameter Real refine=0.7;
        
        parameter Point polygon[nbp]=zeros(nbp, 2);
        //=domainP.discretizeBoundary(nbp, domain.boundary);
        //parameter Point polygon[:]=DomainType.boundaryPoints(p.nbp, bd);
        parameter Mesh.Data mesh(
          n=size(polygon, 1), 
          polygon=polygon, 
          refine=refine);
        parameter Integer boundarySize=nbp;
      end Data;
      
    end DiscreteDomain;
    
    package Mesh "2D spatial domain" 
      import PDE2D.FEMExternalMesh.MeshGeneration.*;
      
      function get_s = getSizes;
      function get_vertex = getVertex;
      function get_e = getEdge;
      function get_t = getTriangle;
      
      function get_x 
        input Data mesh;
        input Integer i;
        output Coordinate x[3];
      algorithm 
        x := get_vertex(mesh.meshData, i);
      end get_x;
      
      record Data 
        parameter Integer n;
        parameter Point polygon[n];
        parameter Integer bc[:]={1 for i in 1:n};
        parameter Real refine(
          min=0, 
          max=1) = 0.7 "0 < refine < 1, less is finer";
        parameter String filename="default_mesh2D.txt";
        // will be overwritten!
        
        // If Cygwin (BAMG) not installed, bypass generation of grid, just read existing files.
        parameter MeshData meshData=MeshData(polygon, bc, refine);
        
        //parameter Integer s[3] = get_s(mesh, status);
        // Necessary for dependency! Currently not supported by Dymola (BUG?)
        parameter Integer s[3]=get_s(meshData);
        
        parameter Integer nv=s[1] "Number of vertices";
        parameter Integer ne=s[2] "Number of edges on boundary";
        parameter Integer nt=s[3] "Number of triangles";
        
      end Data;
      
    end Mesh;
    
    package MeshGeneration "Grid generation for 1D and triangular 2D" 
      
      class MeshData 
        extends ExternalObject;
        function constructor 
          annotation (Include="#include <meshext.h>", Library="meshext");
          input Real xPolygon[:, 2];
          input Integer bc[size(xPolygon, 1)];
          input Real refine=0.5;
          //  h in (0,1) controls the refinement of triangles, less is finer
          output MeshData mesh;
        external "C" mesh = create_mesh2d_data(xPolygon, size(xPolygon, 1), 
            size(xPolygon, 2), bc, size(bc, 1), refine);
          
        end constructor;
        
        function destructor "Release storage of table" 
          annotation (Include="#include <meshext.h>", Library="meshext");
          input MeshData mesh;
        external "C" free_mesh2d_data(mesh);
        end destructor;
      end MeshData;
      
      function getSizes "Reads sizes mesh-data 2D" 
        annotation (Include="#include <meshext.h>", Library="meshext");
        input MeshData mesh;
        output Integer s[3] "Sizes of mesh-data {vertices, edges, triangles}";
      external "C" get_mesh2d_sizes(mesh, s, size(s, 1));
        
      end getSizes;
      
      function getVertex "Reads one vertex coordinate" 
        annotation (Include="#include <meshext.h>", Library="meshext");
        input MeshData mesh;
        input Integer i "Vertex index";
        output Real v[3];
      external "C" get_mesh2d_vertex(mesh, i, v, size(v, 1));
      end getVertex;
      
      function getEdge "Reads one edgeon boundary 2D" 
        input MeshData mesh;
        input Integer i "Edge index";
        output Integer e[3];
      algorithm 
        e := {1,2,3};
        // not implemented yet. Not needed?
      end getEdge;
      
      function getTriangle "Reads one triangle 2D" 
        
        input MeshData mesh;
        input Integer i "Triangle index";
        output Integer t[4];
      algorithm 
        t := {1,2,3,4};
        // Not implemented yet. Needed?
      end getTriangle;
      
    end MeshGeneration;
    
    package DiscreteConstField 
      replaceable package fieldP = Field;
      
      replaceable package ddomainP = DiscreteDomain;
      
      //  package interpolation = Interpolation (redeclare package field = field);
      
      redeclare replaceable record Data 
        parameter ddomainP.Data ddomain;
        parameter fieldP.Data field;
        parameter fieldP.FieldType val[ddomain.mesh.nv];
        parameter Integer fieldSize=size(val, 1);
      end Data;
      
    end DiscreteConstField;
    
    package Interpolation 
      
      replaceable package dfieldP = DiscreteField;
      
      function interpolate 
        //input Mesh.Data mesh;
        //input Integer fieldSize;
        input dfieldP.ddomainP.Data ddomain;
        input dfieldP.fieldP.Data field;
        input Integer fieldSize;
        output dfieldP.fieldP.FieldType val[fieldSize];
      protected 
        Point x;
      algorithm 
        for i in 1:size(val, 1) loop
          x := Mesh.get_x(ddomain.mesh, i);
          val[i] := dfieldP.fieldP.value(x, field);
        end for;
      end interpolate;
      
    end Interpolation;
    
    package PoissonSolver 
      
      function getMatrix_Laplace 
        input Mesh.Data mesh;
        input Integer nv;
        input Integer ne;
        input Real g_rhs_val[nv];
        input Integer bndcond[ne, 2];
        output Real Laplace[nv, nv];
      algorithm 
        Laplace := get_rheolef_poisson_laplace(mesh.filename, nv);
      end getMatrix_Laplace;
      
      function getMatrix_g 
        input Mesh.Data mesh;
        input Integer nv;
        input Integer ne;
        input Real g_rhs_val[nv];
        input Integer bndcond[ne, 2];
        output Real g[nv];
      algorithm 
        g := get_rheolef_poisson_g(mesh.filename, nv);
      end getMatrix_g;
      
      function get_rheolef_poisson_laplace 
        annotation (Include="#include <poisson_rheolef_ext.h>", Library=
              "rheolef");
        input String meshData;
        input Integer nv;
        output Real laplace[nv, nv];
      external "C" get_rheolef_poisson_laplace(meshData, nv, laplace);
        
      end get_rheolef_poisson_laplace;
      
      function get_rheolef_poisson_g 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        input String meshData;
        input Integer nv;
        output Real g[nv];
      external "C" get_rheolef_poisson_g(meshData, nv, g);
        
      end get_rheolef_poisson_g;
      
      function writeMatrix_Laplace 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        input Integer nv;
        input Real Laplace[nv, nv];
      external "C" put_rheolef_poisson_laplace("intsolver_laplace.txt", nv, 
          Laplace);
      end writeMatrix_Laplace;
      
      function writeMatrix_g 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        input Integer nv;
        input Real g[nv];
      external "C" put_rheolef_poisson_g("intsolver_g.txt", nv, g);
      end writeMatrix_g;
      
    end PoissonSolver;
    
  end FEMExternalMesh;
  
  package FEMExternalSolver 
    package Autonomous 
      package Poisson2D "Poisson problem 2D" 
        //  import PDE2D.FEMExternal2.RheolefSolver.*;
        
        //replaceable package Solver = InternalSolver;
        replaceable package Solver = RheolefSolver;
        
        replaceable package domainP = Domain;
        //  replaceable package initialField = ConstField;
        /* (redeclare function value = 
  valfunc); */
        //replaceable function valfunc = ConstField.value;
        
        model Equation "Poisson equation 2D" 
          parameter Real g0=1 "Constant value of field";
          parameter domainP.Data domain;
          parameter Integer nbp=20;
          parameter Real refine=0.7;
          //parameter initialField.Parameters inifp;
          
          // internal packages  
          package rhsFieldP = ConstConstField (redeclare package domainP = 
                  domainP);
          parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
          
          package uFieldP = Field (redeclare package domainP = domainP);
          parameter uFieldP.Data uField(domain=domain);
          
          // discrete part
          package ddomainP = DiscreteDomain (redeclare package domainP = 
                  domainP);
          parameter ddomainP.Data ddomain(
            domain=domain, 
            nbp=nbp, 
            refine=refine);
          
          package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                  rhsFieldP, redeclare package ddomainP = ddomainP);
          package interpolationP = Interpolation (redeclare package dfieldP = 
                  rhsDFieldP);
          parameter rhsDFieldP.Data g_rhs(
            ddomain=ddomain, 
            field=rhsField, 
            val=interpolationP.interpolate(ddomain, rhsField, ddomain.mesh.nv));
          
          package uDFieldP = DiscreteField (redeclare package ddomainP = 
                  ddomainP, redeclare package fieldP = uFieldP);
          uDFieldP.Data fd(
            ddomain=ddomain, 
            field=uField, 
            val(start={1 for i in 1:ddomain.mesh.nv}));
          
        protected 
          parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd
              .ddomain.mesh.ne};
          //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
          //    parameter Real g[fd.ddomain.mesh.nv];
          parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=
              Solver.getMatrix_Laplace(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.
              ddomain.mesh.ne, g_rhs.val, bndcond);
          parameter Real g[fd.ddomain.mesh.nv]=Solver.getMatrix_g(fd.ddomain.
              mesh, fd.ddomain.mesh.nv, fd.ddomain.mesh.ne, g_rhs.val, bndcond);
          /*   
    parameter Real Lg[:, :]=assemble(fd.ddomain.mesh.nt, fd.ddomain.mesh.nv, fd
        .ddomain.mesh.triangle, fd.ddomain.mesh.x, g_rhs.val);
    parameter Real LgBd[:, :]=assembleBd(fd.ddomain.mesh.ne, fd.ddomain.mesh.nv, 
        fd.ddomain.mesh.edge, fd.ddomain.mesh.x, Lg, bndcond);
    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=LgBd[1:fd.
        ddomain.mesh.nv, 1:fd.ddomain.mesh.nv];
    parameter Real g[fd.ddomain.mesh.nv]=LgBd[1:fd.ddomain.mesh.nv, fd.ddomain.
        mesh.nv + 1];
  */
          //  initial equation 
          //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
          //      bndcond);
        equation 
          -Laplace*fd.val = g;
          //fd.val = g;
        end Equation;
        
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        
      end Poisson2D;
      
      package Diffusion2D "Poisson problem 2D" 
        //  import PDE2D.FEMExternal2.RheolefSolver.*;
        
        replaceable package Solver = InternalDiffusionSolver;
        //replaceable package Solver = RheolefSolver;
        function interior = DomainOperators.interior2D;
        
        replaceable package domainP = Domain;
        //  replaceable package initialField = ConstField;
        /* (redeclare function value = 
  valfunc); */
        //replaceable function valfunc = ConstField.value;
        
        model Equation "Poisson equation 2D" 
          parameter Real g0=1 "Constant value of field";
          parameter domainP.Data domain;
          parameter Integer nbp=20;
          parameter Real refine=0.7;
          //parameter initialField.Parameters inifp;
          
          // internal packages  
          package rhsFieldP = ConstConstField (redeclare package domainP = 
                  domainP);
          parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
          
          package uFieldP = Field (redeclare package domainP = domainP);
          parameter uFieldP.Data uField(domain=domain);
          
          // discrete part
          package ddomainP = DiscreteDomain (redeclare package domainP = 
                  domainP);
          parameter ddomainP.Data ddomain(
            domain=domain, 
            nbp=nbp, 
            refine=refine);
          
          package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                  rhsFieldP, redeclare package ddomainP = ddomainP);
          package interpolationP = Interpolation (redeclare package dfieldP = 
                  rhsDFieldP);
          parameter rhsDFieldP.Data g_rhs(
            ddomain=ddomain, 
            field=rhsField, 
            val=interpolationP.interpolate(ddomain, rhsField, ddomain.mesh.nv));
          
          package uDFieldP = DiscreteField (redeclare package ddomainP = 
                  ddomainP, redeclare package fieldP = uFieldP);
          uDFieldP.Data fd(
            ddomain=ddomain, 
            field=uField, 
            val(start={0 for i in 1:ddomain.mesh.nv}));
          
        protected 
          parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd
              .ddomain.mesh.ne};
          //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
          //    parameter Real g[fd.ddomain.mesh.nv];
          parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=
              Solver.getMatrix_Laplace(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.
              ddomain.mesh.ne, g_rhs.val, bndcond);
          parameter Real M[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv]=
              Solver.getMatrix_Mass(fd.ddomain.mesh, fd.ddomain.mesh.nv, fd.
              ddomain.mesh.ne, g_rhs.val, bndcond);
          parameter Real g[fd.ddomain.mesh.nv]=Solver.getMatrix_g(fd.ddomain.
              mesh, fd.ddomain.mesh.nv, fd.ddomain.mesh.ne, g_rhs.val, bndcond);
          //  initial equation 
          //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
          //      bndcond);
        equation 
          diagonal(interior(fd.ddomain.mesh.nv, fd.ddomain.mesh.x))*M*der(fd.
            val) = Laplace*fd.val + g;
          //fd.val = g;
        end Equation;
        
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        
      end Diffusion2D;
    end Autonomous;
    
    package Discretize     end Discretize;
    
    package DiscreteField 
      replaceable package fieldP = Field;
      replaceable package ddomainP = DiscreteDomain;
      //replaceable package valfunc = ConstField.value;
      //replaceable package initialDField = DiscreteConstField;
      //replaceable package initialField = ConstField;
      
      //package initialDField = DiscreteConstField (redeclare package field = 
      //        initialField, redeclare package ddomain = ddomain);
      
      replaceable record Data 
        parameter ddomainP.Data ddomain;
        parameter fieldP.Data field;
        //parameter initialDField.Parameters inip(ddom=p.ddom, fld=p.fld);
        //parameter initialDField.Data inidata(p=inip);
        fieldP.FieldType val[ddomain.mesh.nv](start=zeros(ddomain.mesh.nv));
        //(start=inidata.val);
        parameter Integer fieldSize=size(val, 1);
      end Data;
      
    end DiscreteField;
    
    package DiscreteDomain 
      replaceable package domainP = Domain extends Domain;
      
      replaceable record Data 
        parameter Integer nbp;
        parameter domainP.Data domain;
        parameter Real refine=0.7;
        
        parameter Point polygon[:]=domainP.discretizeBoundary(nbp, domain.
            boundary);
        //parameter Point polygon[:]=DomainType.boundaryPoints(p.nbp, bd);
        parameter Mesh.Data mesh(
          n=size(polygon, 1), 
          polygon=polygon, 
          refine=refine);
        parameter Integer boundarySize=size(polygon, 1);
      end Data;
      
    end DiscreteDomain;
    
    package Mesh "2D spatial domain" 
      import PDE2D.FEMExternalSolver.MeshGeneration.*;
      
      function generate = generate2D;
      function get_s = sizes2D;
      function get_v = vertices2D;
      function get_e = edges2D;
      function get_t = triangles2D;
      
      record Data 
        parameter Integer n;
        parameter Point polygon[n];
        parameter Integer bc[:]={1 for i in 1:n};
        parameter Real refine(
          min=0, 
          max=1) = 0.7 "0 < refine < 1, less is finer";
        parameter String filename="default_mesh2D.txt";
        // will be overwritten!
        
        // If Cygwin (BAMG) not installed, bypass generation of grid, just read existing files.
        parameter Integer status=generate(polygon, bc, filename, refine);
        
        //parameter Integer s[3] = get_s(mesh, status);
        // Necessary for dependency! Currently not supported by Dymola (BUG?)
        parameter Integer s[3]=get_s(filename, 1);
        
        parameter Integer nv=s[1] "Number of vertices";
        parameter Integer ne=s[2] "Number of edges on boundary";
        parameter Integer nt=s[3] "Number of triangles";
        parameter Coordinate x[:, 3]=get_v(filename, nv) 
          "Coordinates of grid-points (1:2) and inner/bd (3)";
        parameter Integer edge[:, 3]=get_e(filename, ne) 
          "Edges by vertex-tuple (1:2) and index for boundary condition (3)";
        parameter Integer triangle[:, 4]=get_t(filename, nt) 
          "Triangles by vertex-triple (1:3) and index for dependence of coefficients (4)";
      end Data;
      
    end Mesh;
    
    package MeshGeneration "Grid generation for 1D and triangular 2D" 
      function generate1D "Generates 1D mesh" 
        
        input Real xPolygon[:];
        input Integer bc[size(xPolygon, 1)];
        input String outputfile;
        input Real refine=0.1;
        // 0 < refine < 1, controls refinement of triangles, less is finer.
        output Integer status;
      external "C" oneg_generate_mesh("onegrun.bat", outputfile, status, 
          xPolygon, size(xPolygon, 1), bc, size(bc, 1), refine)
          annotation (Include="#include <oneg_generate_mesh.c>");
        /*  
//for test:
algorithm 
  status := 0;
*/
      end generate1D;
      
      function sizes1D "Reads sizes mesh-data 1D" 
        
        input String mesh;
        input Integer status;
        output Integer s[3] 
          "Sizes of mesh-data {vertices, bdpoints, intervals}";
      external "C" oneg_read_sizes(mesh, s, size(s, 1))
          annotation (Include="#include <oneg_read_sizes.c>");
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
      external "C" oneD_read_vertices(mesh, v, size(v, 1), size(v, 2))
          annotation (Include="#include <oneg_read_vertices.c>");
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
      external "C" oneD_read_bdpoints(mesh, b, size(b, 1), size(b, 2))
          annotation (Include="#include <oneg_read_bdpoints.c>");
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
          annotation (Include="#include <oneg_read_intervals.c>");
        /*  
//for test:
algorithm 
  i := [1,2,1; 2,3,1; 3,4,1; 4,5,1; 5,6,1; 6,7,1; 7,8,1; 8,9,1; 9,10,1; 10,11,1];
*/
      end intervals1D;
      
      function generate2D "Generates 2D triangular mesh" 
        
        input Real xPolygon[:, 2];
        input Integer bc[size(xPolygon, 1)];
        input String outputfile;
        input Real refine=0.5;
        // h in (0,1) controls the refinement of triangles, less is finer
        output Integer status;
      external "C" bamg_generate_mesh("bamgrun.bat", outputfile, status, 
          xPolygon, size(xPolygon, 1), size(xPolygon, 2), bc, size(bc, 1), 
          refine) annotation (Include="#include <bamg_generate_mesh.c>");
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
      external "C" bamg_read_sizes(mesh, s, size(s, 1))
          annotation (Include="#include <bamg_read_sizes.c>");
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
      external "C" bamg_read_vertices(mesh, v, size(v, 1), size(v, 2))
          annotation (Include="#include <bamg_read_vertices.c>");
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
      external "C" bamg_read_edges(mesh, e, size(e, 1), size(e, 2))
          annotation (Include="#include <bamg_read_edges.c>");
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
      external "C" bamg_read_triangles(mesh, t, size(t, 1), size(t, 2))
          annotation (Include="#include <bamg_read_triangles.c>");
        /*  
//for test:
algorithm 
  t := [1,2,3,4;5,6,7,8];
*/
      end triangles2D;
      
    end MeshGeneration;
    
    package DiscreteConstField 
      replaceable package fieldP = Field;
      
      replaceable package ddomainP = DiscreteDomain;
      
      //  package interpolation = Interpolation (redeclare package field = field);
      
      redeclare replaceable record Data 
        parameter ddomainP.Data ddomain;
        parameter fieldP.Data field;
        parameter fieldP.FieldType val[ddomain.mesh.nv];
        parameter Integer fieldSize=size(val, 1);
      end Data;
      
    end DiscreteConstField;
    
    package Interpolation 
      
      replaceable package dfieldP = DiscreteField;
      
      function interpolate 
        //input Mesh.Data mesh;
        //input Integer fieldSize;
        input dfieldP.ddomainP.Data ddomain;
        input dfieldP.fieldP.Data field;
        input Integer fieldSize;
        output dfieldP.fieldP.FieldType val[fieldSize];
      protected 
        Point x;
      algorithm 
        for i in 1:size(val, 1) loop
          x := ddomain.mesh.x[i, 1:2];
          val[i] := dfieldP.fieldP.value(x, field);
        end for;
      end interpolate;
      
    end Interpolation;
    
    package FEMSolver 
      
      replaceable partial function getMatrix_Laplace 
        input Mesh.Data mesh;
        input Integer nv;
        input Integer ne;
        input Real g_rhs_val[nv];
        input Integer bndcond[ne, 2];
        output Real Laplace[nv, nv];
      end getMatrix_Laplace;
      
      replaceable partial function getMatrix_Mass 
        input Mesh.Data mesh;
        input Integer nv;
        input Integer ne;
        input Real g_rhs_val[nv];
        input Integer bndcond[ne, 2];
        output Real Mass[nv, nv];
      end getMatrix_Mass;
      
      replaceable partial function getMatrix_g 
        input Mesh.Data mesh;
        input Integer nv;
        input Integer ne;
        input Real g_rhs_val[nv];
        input Integer bndcond[ne, 2];
        output Real g[nv];
      end getMatrix_g;
      
      /* For debugging */
      
      replaceable function writeMatrix 
        input String filename="foomatrix.txt";
        input Integer nv;
        input Real M[nv, nv];
      end writeMatrix;
      
      replaceable function writeVector 
        input String filename="foovector.txt";
        input Integer nv;
        input Real v[nv];
      end writeVector;
      
    end FEMSolver;
    
    package RheolefSolver 
      extends FEMSolver;
      
      redeclare function extends getMatrix_Laplace 
      algorithm 
        Laplace := get_rheolef_poisson_laplace(mesh.filename, nv);
      end getMatrix_Laplace;
      
      redeclare function extends getMatrix_Mass 
      algorithm 
        Mass := get_rheolef_poisson_mass(mesh.filename, nv);
      end getMatrix_Mass;
      
      redeclare function extends getMatrix_g 
      algorithm 
        g := get_rheolef_poisson_g(mesh.filename, nv);
      end getMatrix_g;
      
      redeclare function extends writeMatrix 
        annotation (Include="#include <read_matrix.h>", Library="rheolef");
      external "C" write_square_matrix(filename, nv, M);
      end writeMatrix;
      
      redeclare function extends writeVector 
        annotation (Include="#include <read_matrix.h>", Library="rheolef");
      external "C" write_vector(filename, nv, v);
      end writeVector;
      
      /* Package specific internal functions */
      
      function get_rheolef_poisson_laplace 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        input String meshData;
        input Integer nv;
        output Real laplace[nv, nv];
      external "C" get_rheolef_poisson_laplace(meshData, nv, laplace);
        
      end get_rheolef_poisson_laplace;
      
      function get_rheolef_poisson_mass 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        input String meshData;
        input Integer nv;
        output Real mass[nv, nv];
      external "C" get_rheolef_poisson_mass(meshData, nv, mass);
      end get_rheolef_poisson_mass;
      
      function get_rheolef_poisson_g 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        input String meshData;
        input Integer nv;
        output Real g[nv];
      external "C" get_rheolef_poisson_g(meshData, nv, g);
        
      end get_rheolef_poisson_g;
      
    end RheolefSolver;
    
    package InternalSolver 
      extends FEMSolver;
      
      redeclare function extends getMatrix_Laplace 
      protected 
        parameter Real Lg[mesh.nv, mesh.nv + 1]=assemble(mesh.nt, mesh.nv, mesh
            .triangle, mesh.x, g_rhs_val);
        parameter Real LgBd[mesh.nv, mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
            mesh.edge, mesh.x, Lg, bndcond);
      algorithm 
        Laplace := LgBd[1:mesh.nv, 1:mesh.nv];
        // For debugging
        // FEMExternal.PoissonSolver.writeMatrix_Laplace(nv,Laplace);
      end getMatrix_Laplace;
      
      redeclare function extends getMatrix_g 
      protected 
        parameter Real Lg[mesh.nv, mesh.nv + 1]=assemble(mesh.nt, mesh.nv, mesh
            .triangle, mesh.x, g_rhs_val);
        parameter Real LgBd[mesh.nv, mesh.nv + 1]=assembleBd(mesh.ne, mesh.nv, 
            mesh.edge, mesh.x, Lg, bndcond);
      algorithm 
        g := LgBd[1:mesh.nv, mesh.nv + 1];
        // For debugging    
        // FEMExternal.PoissonSolver.writeMatrix_g(nv,g);
      end getMatrix_g;
      
      /* Internal functions */
      
      function assemble "Assembles stiffness and mass matrix" 
        input Integer nTriangles;
        input Integer nVertices;
        input Integer triangles[nTriangles, 4];
        input Real vertices[nVertices, 3];
        input Real g_val[:];
        output Real Ab[nVertices, nVertices + 1];
      protected 
        Integer Tk[3];
        Real Ak[3, 3];
        Real Lk[3];
        
        Integer i;
        Integer j;
      algorithm 
        Ab := zeros(nVertices, nVertices + 1);
        
        for k in 1:nTriangles loop
          Tk := triangles[k, 1:3];
          (Ak,Lk) := element(vertices[Tk, 1], vertices[Tk, 2], g_val[Tk]);
          
          for local_1 in 1:3 loop
            i := Tk[local_1];
            for local_2 in 1:3 loop
              j := Tk[local_2];
              Ab[i, j] := Ab[i, j] - Ak[local_1, local_2];
            end for;
            Ab[i, nVertices + 1] := Ab[i, nVertices + 1] + Lk[local_1];
            
          end for;
          
        end for;
        
        annotation (Documentation(info="<HTML>
<pre>
Assembles the stiffness and mass matrix according to the differential equation.
The boundary conditions are treated separately. 
</pre>
</HTML>"));
      end assemble;
      
      function assembleBd "Includes boundary conditions into stiffnes matrix" 
        
        input Integer nEdges;
        input Integer nVertices;
        input Integer edges[nEdges, 3];
        input Real vertices[nVertices, 3];
        input Real Ab[nVertices, nVertices + 1];
        input Integer type_bc[:, :];
        output Real AbBd[nVertices, nVertices + 1];
      protected 
        Real v[2, 3];
        
      algorithm 
        AbBd := Ab;
        
        for i in 1:nEdges loop
          
          if edges[i, 3] > 0 then
            v := vertices[edges[i, 1:2], :];
            //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
            
            if type_bc[integer(edges[i, 3]), 1] == 0 then
              
              for j in 1:nVertices loop
                AbBd[edges[i, 1], j] := 0;
                AbBd[edges[i, 2], j] := 0;
                
              end for;
              AbBd[edges[i, 1], edges[i, 1]] := 1;
              AbBd[edges[i, 2], edges[i, 2]] := 1;
              // Put inhomogenous Dirichlet conditions here!!
              AbBd[edges[i, 1], nVertices + 1] := 0;
              AbBd[edges[i, 2], nVertices + 1] := 0;
              
            else
              // Put inhomogenous Neumann conditions here!!
              AbBd[edges[i, 1], nVertices + 1] := 0;
              AbBd[edges[i, 2], nVertices + 1] := 0;
              
            end if;
            
          end if;
          
        end for;
        
        annotation (Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
      end assembleBd;
      
      function element "Stiffness contributions per triangle" 
        input Real Px[3];
        input Real Py[3];
        input Real g[3];
        output Real Ak[3, 3];
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
        detk := abs((Px[2] - Px[1])*(Py[3] - Py[1]) - (Px[3] - Px[1])*(Py[2] - 
          Py[1]));
        F := detk/2;
        
        for i in 1:3 loop
          
          for j in i + 1:3 loop
            l := if i + j == 3 then 3 else if i + j == 4 then 2 else 1;
            Ak[i, j] := 1/2/detk*((Px[i] - Px[l])*(Px[l] - Px[j]) + (Py[i] - Py[
              l])*(Py[l] - Py[j]));
            Ak[j, i] := Ak[i, j];
            
          end for;
          
        end for;
        
        for i in 1:3 loop
          j := if i == 1 then 2 else if i == 2 then 3 else 1;
          k := if i == 1 then 3 else if i == 2 then 1 else 2;
          Ak[i, i] := 1/2/detk*((Px[j] - Px[k])^2 + (Py[j] - Py[k])^2);
          
        end for;
        md := 1/12*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
           - Px[1]));
        mk := 1/24*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
           - Px[1]));
        Lk := {md*g[1] + mk*g[2] + mk*g[3],mk*g[1] + md*g[2] + mk*g[3],mk*g[1]
           + mk*g[2] + md*g[3]};
        annotation (Documentation(info=""));
      end element;
    end InternalSolver;
    
    package DomainOperators 
      "Domain operators return the values of the field on the interior of the domain" 
      
      function interior1D "Field in the interior of 2D domain" 
        input Integer nVertices;
        input Real vertices[nVertices, 2];
        output Real interior[nVertices];
        
      algorithm 
        interior := zeros(nVertices);
        for i in 1:nVertices loop
          interior[i] := if vertices[i, 2] > 0 then 0 else 1;
        end for;
        annotation (Documentation(info="<HTML>
<pre>
Returns a vector with value 0 for boundary-vertices and 1 for other vertices .
</pre>
</HTML>
"));
      end interior1D;
      
      function interior2D "Field in the interior of 2D domain" 
        input Integer nVertices;
        input Real vertices[nVertices, 3];
        output Real interior[nVertices];
        
      algorithm 
        interior := zeros(nVertices);
        for i in 1:nVertices loop
          interior[i] := if vertices[i, 3] > 0 then 0 else 1;
        end for;
        annotation (Documentation(info="<HTML>
<pre>
Returns a vector with value 0 for boundary-vertices and 1 for other vertices .
</pre>
</HTML>
"));
      end interior2D;
      annotation (Documentation(info=""), Icon);
      
    end DomainOperators;
    
    package InternalDiffusionSolver 
      extends FEMSolver;
      
      redeclare function extends getMatrix_Laplace 
      protected 
        parameter Real AMb[mesh.nv, 2*mesh.nv + 1]=assemble(mesh.nt, mesh.nv, 
            mesh.triangle, mesh.x, g_rhs_val);
        parameter Real AMbBd[mesh.nv, 2*mesh.nv + 1]=assembleBd(mesh.ne, mesh.
            nv, mesh.edge, mesh.x, AMb, bndcond);
      algorithm 
        Laplace := AMbBd[1:mesh.nv, 1:mesh.nv];
        // For debugging
        RheolefSolver.writeMatrix("intsolver_laplace2.txt", nv, diagonal(
          DomainOperators.interior2D(nv, mesh.x)));
        RheolefSolver.writeMatrix("intsolver_laplace.txt", nv, Laplace);
      end getMatrix_Laplace;
      
      redeclare function extends getMatrix_Mass 
      protected 
        parameter Real AMb[mesh.nv, 2*mesh.nv + 1]=assemble(mesh.nt, mesh.nv, 
            mesh.triangle, mesh.x, g_rhs_val);
        parameter Real AMbBd[mesh.nv, 2*mesh.nv + 1]=assembleBd(mesh.ne, mesh.
            nv, mesh.edge, mesh.x, AMb, bndcond);
      algorithm 
        Mass := AMbBd[1:mesh.nv, mesh.nv + 1:2*mesh.nv];
        // For debugging
        RheolefSolver.writeMatrix("intsolver_mass.txt", nv, Mass);
      end getMatrix_Mass;
      
      redeclare function extends getMatrix_g 
      protected 
        parameter Real AMb[mesh.nv, 2*mesh.nv + 1]=assemble(mesh.nt, mesh.nv, 
            mesh.triangle, mesh.x, g_rhs_val);
        parameter Real AMbBd[mesh.nv, 2*mesh.nv + 1]=assembleBd(mesh.ne, mesh.
            nv, mesh.edge, mesh.x, AMb, bndcond);
      algorithm 
        g := AMbBd[1:mesh.nv, 2*mesh.nv + 1];
        // For debugging    
        RheolefSolver.writeVector("intsolver_g.txt", nv, g);
      end getMatrix_g;
      
      /* Internal functions */
      
      function assemble "Assembles stiffness and mass matrix" 
        input Integer nTriangles;
        input Integer nVertices;
        input Integer triangles[nTriangles, 4];
        input Real vertices[nVertices, 3];
        input Real g_val[:];
        output Real AMb[nVertices, 2*nVertices + 1];
      protected 
        Integer Tk[3];
        Real Ak[3, 3];
        Real Mk[3, 3];
        Real Lk[3];
        
        Integer i;
        Integer j;
      algorithm 
        AMb := zeros(nVertices, 2*nVertices + 1);
        
        for k in 1:nTriangles loop
          Tk := triangles[k, 1:3];
          (Ak,Mk,Lk) := element(vertices[Tk, 1], vertices[Tk, 2], g_val[Tk]);
          
          for local_1 in 1:3 loop
            i := Tk[local_1];
            
            for local_2 in 1:3 loop
              j := Tk[local_2];
              AMb[i, j] := AMb[i, j] - Ak[local_1, local_2];
              AMb[i, nVertices + j] := AMb[i, nVertices + j] + Mk[local_1, 
                local_2];
              
            end for;
            AMb[i, 2*nVertices + 1] := AMb[i, 2*nVertices + 1] + Lk[local_1];
            
          end for;
          
        end for;
        
        annotation (Documentation(info="<HTML>
<pre>
Assembles the stiffness and mass matrix according to the differential equation.
The boundary conditions are treated separately. 
</pre>
</HTML>"));
      end assemble;
      
      function assembleBd "Includes boundary conditions into stiffnes matrix" 
        input Integer nEdges;
        input Integer nVertices;
        input Integer edges[nEdges, 3];
        input Real vertices[nVertices, 3];
        input Real AMb[nVertices, 2*nVertices + 1];
        input Integer type_bc[:, :];
        output Real AMbBd[nVertices, 2*nVertices + 1];
      protected 
        Real v[2, 3];
        
      algorithm 
        AMbBd := AMb;
        
        for i in 1:nEdges loop
          
          if edges[i, 3] > 0 then
            v := vertices[edges[i, 1:2], :];
            //if type_bc[integer(v[1,3]),1] == 0 or type_bc[integer(v[2,3]),1] == 0 then
            
            if type_bc[integer(edges[i, 3]), 1] == 0 then
              
              for j in 1:nVertices loop
                AMbBd[edges[i, 1], j] := 0;
                AMbBd[edges[i, 2], j] := 0;
                
              end for;
              AMbBd[edges[i, 1], edges[i, 1]] := 1;
              AMbBd[edges[i, 2], edges[i, 2]] := 1;
              // Put inhomogenous Dirichlet conditions here!!
              AMbBd[edges[i, 1], 2*nVertices + 1] := 0;
              AMbBd[edges[i, 2], 2*nVertices + 1] := 0;
              
            else
              // Put inhomogenous Neumann conditions here!!
              AMbBd[edges[i, 1], 2*nVertices + 1] := 0;
              AMbBd[edges[i, 2], 2*nVertices + 1] := 0;
              
            end if;
            
          end if;
          
        end for;
        
        annotation (Documentation(info="<HTML>
<pre>
Modifies the assembled stiffness matrix according to the boundary conditions. 
</pre>
</HTML>"));
      end assembleBd;
      
      function element "Stiffness contributions per triangle" 
        input Real Px[3];
        input Real Py[3];
        input Real g[3];
        output Real Ak[3, 3];
        output Real Mk[3, 3];
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
        detk := abs((Px[2] - Px[1])*(Py[3] - Py[1]) - (Px[3] - Px[1])*(Py[2] - 
          Py[1]));
        F := detk/2;
        
        for i in 1:3 loop
          
          for j in i + 1:3 loop
            l := if i + j == 3 then 3 else if i + j == 4 then 2 else 1;
            Ak[i, j] := 1/2/detk*((Px[i] - Px[l])*(Px[l] - Px[j]) + (Py[i] - Py[
              l])*(Py[l] - Py[j]));
            Ak[j, i] := Ak[i, j];
            
          end for;
          
        end for;
        
        for i in 1:3 loop
          j := if i == 1 then 2 else if i == 2 then 3 else 1;
          k := if i == 1 then 3 else if i == 2 then 1 else 2;
          Ak[i, i] := 1/2/detk*((Px[j] - Px[k])^2 + (Py[j] - Py[k])^2);
          
        end for;
        md := 1/12*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
           - Px[1]));
        mk := 1/24*(Py[1]*(Px[3] - Px[2]) + Py[2]*(Px[1] - Px[3]) + Py[3]*(Px[2]
           - Px[1]));
        Mk := [md, mk, mk; mk, md, mk; mk, mk, md];
        Lk := Mk*{g[1],g[2],g[3]};
      end element;
    end InternalDiffusionSolver;
  end FEMExternalSolver;
  
  package FEMExternalSolver2 
    package Autonomous 
      package Poisson2D "Poisson problem 2D" 
        import PDE2D.FEMExternalSolver2.FEMSolver.*;
        
        // replaceable package Solver = InternalSolver;
        // replaceable package Solver = FEMSolver;
        
        replaceable package domainP = Domain;
        //  replaceable package initialField = ConstField;
        /* (redeclare function value = 
  valfunc); */
        //replaceable function valfunc = ConstField.value;
        
        model Equation "Poisson equation 2D" 
          parameter Real g0=1 "Constant value of field";
          parameter domainP.Data domain;
          parameter Integer nbp=20;
          parameter Real refine=0.7;
          //parameter initialField.Parameters inifp;
          
          // internal packages  
          package rhsFieldP = ConstConstField (redeclare package domainP = 
                  domainP);
          parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
          
          package uFieldP = Field (redeclare package domainP = domainP);
          parameter uFieldP.Data uField(domain=domain);
          
          // discrete part
          package ddomainP = DiscreteDomain (redeclare package domainP = 
                  domainP);
          parameter ddomainP.Data ddomain(
            domain=domain, 
            nbp=nbp, 
            refine=refine);
          
          // Why doesn't these work?
          // parameter FormSize formsize=getFormSize(ddomain.mesh.filename, ddomain.mesh.nv);
          // parameter FormSize formsize=getFormSize("default_mesh2d.txt", 79);
          
          parameter Integer interiorSize=integer(sum(DomainOperators.interior2D(
              ddomain.mesh.nv, ddomain.mesh.x)));
          
          // Assuming boundary blocked, i.e. all dirichlet bc.
          parameter FormSize formsize=FormSize(interiorSize, ddomain.mesh.nv - 
              interiorSize);
          parameter Integer u_indices[formsize.nu]=getUnknownIndices(ddomain.
              mesh.filename, ddomain.mesh.nv, formsize.nu);
          parameter Integer b_indices[formsize.nb]=getBlockedIndices(ddomain.
              mesh.filename, ddomain.mesh.nv, formsize.nb);
          
          package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                  rhsFieldP, redeclare package ddomainP = ddomainP);
          package interpolationP = Interpolation (redeclare package dfieldP = 
                  rhsDFieldP);
          parameter rhsDFieldP.Data g_rhs(
            ddomain=ddomain, 
            field=rhsField, 
            formsize=formsize, 
            u_indices=u_indices, 
            b_indices=b_indices, 
            val_u=interpolationP.interpolate_indirect(ddomain, rhsField, 
                formsize.nu, u_indices));
          
          package uDFieldP = DiscreteField (redeclare package ddomainP = 
                  ddomainP, redeclare package fieldP = uFieldP);
          uDFieldP.Data fd(
            ddomain=ddomain, 
            field=uField, 
            formsize=formsize, 
            u_indices=u_indices, 
            b_indices=b_indices, 
            val_u(start={1 for i in 1:formsize.nu}));
          
        protected 
          parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd
              .ddomain.mesh.ne};
          parameter Real laplace_uu[formsize.nu, formsize.nu]=
              getForm_gradgrad_uu(fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, 
              formsize.nu, formsize.nb);
        equation 
          laplace_uu*fd.val_u = g_rhs.val_u;
          fd.val_b = zeros(size(fd.val_b, 1));
        end Equation;
        
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        
      end Poisson2D;
      
      package Diffusion2D "Poisson problem 2D" 
        import PDE2D.FEMExternalSolver2.FEMSolver.*;
        
        //replaceable package Solver = InternalDiffusionSolver;
        //replaceable package Solver = RheolefSolver;
        function interior = DomainOperators.interior2D;
        
        replaceable package domainP = Domain;
        //  replaceable package initialField = ConstField;
        /* (redeclare function value = 
  valfunc); */
        //replaceable function valfunc = ConstField.value;
        
        model Equation "Poisson equation 2D" 
          parameter Real g0=1 "Constant value of field";
          parameter domainP.Data domain;
          parameter Integer nbp=20;
          parameter Real refine=0.7;
          //parameter initialField.Parameters inifp;
          
          // internal packages  
          package rhsFieldP = ConstConstField (redeclare package domainP = 
                  domainP);
          parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
          
          package uFieldP = Field (redeclare package domainP = domainP);
          parameter uFieldP.Data uField(domain=domain);
          
          // discrete part
          package ddomainP = DiscreteDomain (redeclare package domainP = 
                  domainP);
          parameter ddomainP.Data ddomain(
            domain=domain, 
            nbp=nbp, 
            refine=refine);
          
          // Why doesn't these work?
          // parameter FormSize formsize=getFormSize(ddomain.mesh.filename, ddomain.mesh.nv);
          // parameter FormSize formsize=getFormSize("default_mesh2d.txt", 79);
          
          parameter Integer interiorSize=integer(sum(DomainOperators.interior2D(
              ddomain.mesh.nv, ddomain.mesh.x)));
          
          // Assuming boundary blocked, i.e. all dirichlet bc.
          parameter FormSize formsize=FormSize(interiorSize, ddomain.mesh.nv - 
              interiorSize);
          parameter Integer u_indices[formsize.nu]=getUnknownIndices(ddomain.
              mesh.filename, ddomain.mesh.nv, formsize.nu);
          parameter Integer b_indices[formsize.nb]=getBlockedIndices(ddomain.
              mesh.filename, ddomain.mesh.nv, formsize.nb);
          
          package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                  rhsFieldP, redeclare package ddomainP = ddomainP);
          package interpolationP = Interpolation (redeclare package dfieldP = 
                  rhsDFieldP);
          parameter rhsDFieldP.Data g_rhs(
            ddomain=ddomain, 
            field=rhsField, 
            formsize=formsize, 
            u_indices=u_indices, 
            b_indices=b_indices, 
            val_u=interpolationP.interpolate_indirect(ddomain, rhsField, 
                formsize.nu, u_indices), 
            val_b=fill(5, formsize.nb));
          //val_b=interpolationP.interpolate_indirect(ddomain, rhsField, formsize.nb, 
          //   b_indices));
          
          package uDFieldP = DiscreteField (redeclare package ddomainP = 
                  ddomainP, redeclare package fieldP = uFieldP);
          uDFieldP.Data fd(
            ddomain=ddomain, 
            field=uField, 
            formsize=formsize, 
            u_indices=u_indices, 
            b_indices=b_indices, 
            val_u(start={0 for i in 1:formsize.nu}), 
            val_b(start={0 for i in 1:formsize.nb}));
          
        protected 
          parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd
              .ddomain.mesh.ne};
          //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
          //    parameter Real g[fd.ddomain.mesh.nv];
          parameter Real laplace_uu[formsize.nu, formsize.nu]=
              getForm_gradgrad_uu(fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, 
              formsize.nu, formsize.nb);
          parameter Real laplace_ub[formsize.nu, formsize.nb]=
              getForm_gradgrad_ub(fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, 
              formsize.nu, formsize.nb);
          
          parameter Real mass_uu[formsize.nu, formsize.nu]=getForm_mass_uu(fd.
              ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.
              nb);
          parameter Real mass_ub[formsize.nu, formsize.nb]=getForm_mass_ub(fd.
              ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.
              nb);
          
          //  initial equation 
          //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
          //      bndcond);
        equation 
          //writeSquareMatrix("mass_uu.txt", formsize.nu, mass_uu);
          //writeMatrix("mass_ub.txt", formsize.nu, formsize.nb, mass_ub);
          //writeSquareMatrix("laplace_uu.txt", formsize.nu, laplace_uu);
          //writeMatrix("laplace_ub.txt", formsize.nu, formsize.nb, laplace_ub);
          //writeVector("g_u.txt", formsize.nu, g_rhs.val_u);
          //writeVector("g_b.txt", formsize.nb, g_rhs.val_b);
          mass_uu*der(fd.val_u) = -laplace_uu*fd.val_u - laplace_ub*fd.val_b + 
            mass_uu*g_rhs.val_u + mass_ub*g_rhs.val_b;
          fd.val_b = zeros(size(fd.val_b, 1));
          //fd.val = g;
        end Equation;
        
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        
      end Diffusion2D;

      package DiffusionBnd2D "Poisson problem 2D" 
        import PDE2D.FEMExternalSolver2.FEMSolver.*;
        
        //replaceable package Solver = InternalDiffusionSolver;
        //replaceable package Solver = RheolefSolver;
        function interior = DomainOperators.interior2D;
        
        replaceable package domainP = Domain;
        //  replaceable package initialField = ConstField;
        /* (redeclare function value = 
  valfunc); */
        //replaceable function valfunc = ConstField.value;
        
        model Equation "Poisson equation 2D" 
          parameter Real g0=1 "Constant value of field";
          parameter domainP.Data domain;
          parameter Integer nbp=20;
          parameter Real refine=0.7;
          //parameter initialField.Parameters inifp;
          
          // internal packages  
          package rhsFieldP = ConstConstField (redeclare package domainP = 
                  domainP);
          parameter rhsFieldP.Data rhsField(domain=domain, constval=g0);
          
          package uFieldP = Field (redeclare package domainP = domainP);
          parameter uFieldP.Data uField(domain=domain);
          
          // discrete part
          package ddomainP = DiscreteDomain (redeclare package domainP = 
                  domainP);
          parameter ddomainP.Data ddomain(
            domain=domain, 
            nbp=nbp, 
            refine=refine);
          
          // Why doesn't these work?
          // parameter FormSize formsize=getFormSize(ddomain.mesh.filename, ddomain.mesh.nv);
          // parameter FormSize formsize=getFormSize("default_mesh2d.txt", 79);
          
          parameter Integer interiorSize=integer(sum(DomainOperators.interior2D(
              ddomain.mesh.nv, ddomain.mesh.x)));
          
          // Assuming boundary blocked, i.e. all dirichlet bc.
          parameter FormSize formsize=FormSize(interiorSize, ddomain.mesh.nv - 
              interiorSize);
          parameter Integer u_indices[formsize.nu]=getUnknownIndices(ddomain.
              mesh.filename, ddomain.mesh.nv, formsize.nu);
          parameter Integer b_indices[formsize.nb]=getBlockedIndices(ddomain.
              mesh.filename, ddomain.mesh.nv, formsize.nb);
          
          package rhsDFieldP = DiscreteConstField (redeclare package fieldP = 
                  rhsFieldP, redeclare package ddomainP = ddomainP);
          package interpolationP = Interpolation (redeclare package dfieldP = 
                  rhsDFieldP);
          parameter rhsDFieldP.Data g_rhs(
            ddomain=ddomain, 
            field=rhsField, 
            formsize=formsize, 
            u_indices=u_indices, 
            b_indices=b_indices, 
            val_u=interpolationP.interpolate_indirect(ddomain, rhsField, 
                formsize.nu, u_indices), 
            val_b=fill(5, formsize.nb));
          //val_b=interpolationP.interpolate_indirect(ddomain, rhsField, formsize.nb, 
          //   b_indices));
          
          package uDFieldP = DiscreteField (redeclare package ddomainP = 
                  ddomainP, redeclare package fieldP = uFieldP);
          uDFieldP.Data fd(
            ddomain=ddomain, 
            field=uField, 
            formsize=formsize, 
            u_indices=u_indices, 
            b_indices=b_indices, 
            val_u(start={0 for i in 1:formsize.nu}), 
            val_b(start={0 for i in 1:formsize.nb}));
          
        protected 
          parameter Integer bndcond[fd.ddomain.mesh.ne, 2]={{0,1} for i in 1:fd
              .ddomain.mesh.ne};
          //    parameter Real Laplace[fd.ddomain.mesh.nv, fd.ddomain.mesh.nv];
          //    parameter Real g[fd.ddomain.mesh.nv];
          parameter Real laplace_uu[formsize.nu, formsize.nu]=
              getForm_gradgrad_uu(fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, 
              formsize.nu, formsize.nb);
          parameter Real laplace_ub[formsize.nu, formsize.nb]=
              getForm_gradgrad_ub(fd.ddomain.mesh.filename, fd.ddomain.mesh.nv, 
              formsize.nu, formsize.nb);
          
          parameter Real mass_uu[formsize.nu, formsize.nu]=getForm_mass_uu(fd.
              ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.
              nb);
          parameter Real mass_ub[formsize.nu, formsize.nb]=getForm_mass_ub(fd.
              ddomain.mesh.filename, fd.ddomain.mesh.nv, formsize.nu, formsize.
              nb);
          
          //  initial equation 
          //    (Laplace,g) = getMatrix(fd.ddomain.mesh, fd.ddomain.mesh.nv, g_rhs.val, 
          //      bndcond);
        equation 
          //writeSquareMatrix("mass_uu.txt", formsize.nu, mass_uu);
          //writeMatrix("mass_ub.txt", formsize.nu, formsize.nb, mass_ub);
          //writeSquareMatrix("laplace_uu.txt", formsize.nu, laplace_uu);
          //writeMatrix("laplace_ub.txt", formsize.nu, formsize.nb, laplace_ub);
          //writeVector("g_u.txt", formsize.nu, g_rhs.val_u);
          //writeVector("g_b.txt", formsize.nb, g_rhs.val_b);
          mass_uu*der(fd.val_u) = -laplace_uu*fd.val_u - laplace_ub*fd.val_b + 
            mass_uu*g_rhs.val_u + mass_ub*g_rhs.val_b;
          fd.val_b = zeros(size(fd.val_b, 1));
          //fd.val = g;
        end Equation;
        
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        annotation (Documentation(info="<HTML>
<pre>
The Poisson problem in 2D for a field f(x) is defined by the Poisson-equation 
 -lambda*(d2f/dx^2 + d2f/dy^2) = g(x,y)
together with specific boundary conditions.
</pre>
</HTML>"), Icon(
            Rectangle(extent=[-80, 80; 80, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                fillColor=7, 
                rgbfillColor={255,255,255})), 
            Line(points=[-100, 80; -100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Line(points=[100, 80; 100, -80], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2)), 
            Text(
              extent=[60, -20; -60, 0], 
              style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1), 
              string="Poisson 2D"), 
            Line(points=[-70, 100; 70, 100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1)), 
            Line(points=[-70, -100; 70, -100], style(
                color=62, 
                rgbcolor={0,127,127}, 
                thickness=2, 
                fillColor=7, 
                rgbfillColor={255,255,255}, 
                fillPattern=1))));
        
      end DiffusionBnd2D;
    end Autonomous;
    
    package Discretize     end Discretize;
    
    package DiscreteField 
      replaceable package fieldP = Field;
      replaceable package ddomainP = DiscreteDomain;
      //replaceable package valfunc = ConstField.value;
      //replaceable package initialDField = DiscreteConstField;
      //replaceable package initialField = ConstField;
      
      //package initialDField = DiscreteConstField (redeclare package field = 
      //        initialField, redeclare package ddomain = ddomain);
      
      replaceable record Data 
        parameter ddomainP.Data ddomain;
        parameter fieldP.Data field;
        parameter FEMSolver.FormSize formsize;
        parameter Integer u_indices[formsize.nu];
        parameter Integer b_indices[formsize.nb];
        //parameter initialDField.Parameters inip(ddom=p.ddom, fld=p.fld);
        //parameter initialDField.Data inidata(p=inip);
        fieldP.FieldType val_u[formsize.nu](start=zeros(formsize.nu));
        fieldP.FieldType val_b[formsize.nb];
        
        // What should fieldSize be? Just unknowns?
        parameter Integer fieldSize_u=size(val_u, 1);
        parameter Integer fieldSize_b=size(val_b, 1);
      end Data;
      
    end DiscreteField;
    
    package DiscreteDomain 
      replaceable package domainP = Domain extends Domain;
      
      replaceable record Data 
        parameter Integer nbp;
        parameter domainP.Data domain;
        parameter Real refine=0.7;
        
        parameter Point polygon[:]=domainP.discretizeBoundary(nbp, domain.
            boundary);
        //parameter Point polygon[:]=DomainType.boundaryPoints(p.nbp, bd);
        parameter Mesh.Data mesh(
          n=size(polygon, 1), 
          polygon=polygon, 
          refine=refine);
        parameter Integer boundarySize=size(polygon, 1);
      end Data;
      
    end DiscreteDomain;
    
    package Mesh "2D spatial domain" 
      import PDE2D.FEMExternalSolver2.MeshGeneration.*;
      
      function generate = generate2D;
      function get_s = sizes2D;
      function get_v = vertices2D;
      function get_e = edges2D;
      function get_t = triangles2D;
      
      record Data 
        parameter Integer n;
        parameter Point polygon[n];
        parameter Integer bc[:]={1 for i in 1:n};
        parameter Real refine(
          min=0, 
          max=1) = 0.7 "0 < refine < 1, less is finer";
        parameter String filename="default_mesh2D.txt";
        // will be overwritten!
        
        // If Cygwin (BAMG) not installed, bypass generation of grid, just read existing files.
        parameter Integer status=generate(polygon, bc, filename, refine);
        
        //parameter Integer s[3] = get_s(mesh, status);
        // Necessary for dependency! Currently not supported by Dymola (BUG?)
        parameter Integer s[3]=get_s(filename, 1);
        
        parameter Integer nv=s[1] "Number of vertices";
        parameter Integer ne=s[2] "Number of edges on boundary";
        parameter Integer nt=s[3] "Number of triangles";
        parameter Coordinate x[:, 3]=get_v(filename, nv) 
          "Coordinates of grid-points (1:2) and inner/bd (3)";
        parameter Integer edge[:, 3]=get_e(filename, ne) 
          "Edges by vertex-tuple (1:2) and index for boundary condition (3)";
        parameter Integer triangle[:, 4]=get_t(filename, nt) 
          "Triangles by vertex-triple (1:3) and index for dependence of coefficients (4)";
      end Data;
      
    end Mesh;
    
    package MeshGeneration "Grid generation for 1D and triangular 2D" 
      function generate1D "Generates 1D mesh" 
        
        input Real xPolygon[:];
        input Integer bc[size(xPolygon, 1)];
        input String outputfile;
        input Real refine=0.1;
        // 0 < refine < 1, controls refinement of triangles, less is finer.
        output Integer status;
      external "C" oneg_generate_mesh("onegrun.bat", outputfile, status, 
          xPolygon, size(xPolygon, 1), bc, size(bc, 1), refine)
          annotation (Include="#include <oneg_generate_mesh.c>");
        /*  
//for test:
algorithm 
  status := 0;
*/
      end generate1D;
      
      function sizes1D "Reads sizes mesh-data 1D" 
        
        input String mesh;
        input Integer status;
        output Integer s[3] 
          "Sizes of mesh-data {vertices, bdpoints, intervals}";
      external "C" oneg_read_sizes(mesh, s, size(s, 1))
          annotation (Include="#include <oneg_read_sizes.c>");
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
      external "C" oneD_read_vertices(mesh, v, size(v, 1), size(v, 2))
          annotation (Include="#include <oneg_read_vertices.c>");
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
      external "C" oneD_read_bdpoints(mesh, b, size(b, 1), size(b, 2))
          annotation (Include="#include <oneg_read_bdpoints.c>");
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
          annotation (Include="#include <oneg_read_intervals.c>");
        /*  
//for test:
algorithm 
  i := [1,2,1; 2,3,1; 3,4,1; 4,5,1; 5,6,1; 6,7,1; 7,8,1; 8,9,1; 9,10,1; 10,11,1];
*/
      end intervals1D;
      
      function generate2D "Generates 2D triangular mesh" 
        
        input Real xPolygon[:, 2];
        input Integer bc[size(xPolygon, 1)];
        input String outputfile;
        input Real refine=0.5;
        // h in (0,1) controls the refinement of triangles, less is finer
        output Integer status;
      external "C" bamg_generate_mesh("bamgrun.bat", outputfile, status, 
          xPolygon, size(xPolygon, 1), size(xPolygon, 2), bc, size(bc, 1), 
          refine) annotation (Include="#include <bamg_generate_mesh.c>");
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
      external "C" bamg_read_sizes(mesh, s, size(s, 1))
          annotation (Include="#include <bamg_read_sizes.c>");
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
      external "C" bamg_read_vertices(mesh, v, size(v, 1), size(v, 2))
          annotation (Include="#include <bamg_read_vertices.c>");
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
      external "C" bamg_read_edges(mesh, e, size(e, 1), size(e, 2))
          annotation (Include="#include <bamg_read_edges.c>");
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
      external "C" bamg_read_triangles(mesh, t, size(t, 1), size(t, 2))
          annotation (Include="#include <bamg_read_triangles.c>");
        /*  
//for test:
algorithm 
  t := [1,2,3,4;5,6,7,8];
*/
      end triangles2D;
      
    end MeshGeneration;
    
    package DiscreteConstField 
      replaceable package fieldP = Field;
      
      replaceable package ddomainP = DiscreteDomain;
      
      //  package interpolation = Interpolation (redeclare package field = field);
      
      redeclare replaceable record Data 
        parameter ddomainP.Data ddomain;
        parameter fieldP.Data field;
        parameter FEMSolver.FormSize formsize;
        parameter Integer u_indices[formsize.nu];
        parameter Integer b_indices[formsize.nb];
        parameter fieldP.FieldType val_u[formsize.nu]=fill(5, formsize.nu);
        parameter fieldP.FieldType val_b[formsize.nb]=fill(5, formsize.nb);
        parameter Integer fieldSize_u=size(val_u, 1);
        parameter Integer fieldSize_b=size(val_b, 1);
      end Data;
      
    end DiscreteConstField;
    
    package Interpolation 
      
      replaceable package dfieldP = DiscreteField;
      
      function interpolate 
        //input Mesh.Data mesh;
        //input Integer fieldSize;
        input dfieldP.ddomainP.Data ddomain;
        input dfieldP.fieldP.Data field;
        input Integer fieldSize;
        output dfieldP.fieldP.FieldType val[fieldSize];
      protected 
        Point x;
      algorithm 
        for i in 1:size(val, 1) loop
          x := ddomain.mesh.x[i, 1:2];
          val[i] := dfieldP.fieldP.value(x, field);
        end for;
      end interpolate;
      
      function interpolate_indirect 
        //input Mesh.Data mesh;
        //input Integer fieldSize;
        input dfieldP.ddomainP.Data ddomain;
        input dfieldP.fieldP.Data field;
        input Integer vecSize;
        input Integer indices[vecSize];
        output dfieldP.fieldP.FieldType val[vecSize];
      protected 
        Point x;
      algorithm 
        for i in 1:size(val, 1) loop
          x := ddomain.mesh.x[indices[i], 1:2];
          val[i] := dfieldP.fieldP.value(x, field);
        end for;
      end interpolate_indirect;
      
    end Interpolation;
    
    package FEMSolver 
      
      record FormSize 
        parameter Integer nu;
        parameter Integer nb;
      end FormSize;
      
      record Form 
        parameter Integer nu;
        parameter Integer nb;
        parameter Real uu[nu, nu];
        parameter Real ub[nu, nb];
        parameter Real bu[nb, nu];
        parameter Real bb[nb, nb];
      end Form;
      
      function getFormSize 
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        output FormSize s;
      algorithm 
        (s.nu,s.nb) := getFormSize_internal(meshfilename, meshnv);
      end getFormSize;
      
      function getForm_gradgrad 
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input FormSize s;
        output Form form(nu=s.nu, nb=s.nb);
      protected 
        Real auu[s.nu, s.nu];
        Real aub[s.nu, s.nb];
        Real abu[s.nb, s.nu];
        Real abb[s.nb, s.nb];
      algorithm 
        (auu,aub,abu,abb) := getForm_gradgrad_internal(meshfilename, meshnv, s);
        form.uu := auu;
        form.ub := aub;
        form.bu := abu;
        form.bb := abb;
        form.nu := s.nu;
        form.nb := s.nb;
      end getForm_gradgrad;
      
      function getUnknownIndices 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input Integer nbr_unknowns;
        output Integer indices[nbr_unknowns];
      external "C" get_rheolef_unknown_indices(meshfilename, meshnv, 
          nbr_unknowns, indices);
      end getUnknownIndices;
      
      function getForm_gradgrad_internal 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input Integer nu;
        input Integer nb;
        output Real auu[nu, nu];
        output Real aub[nu, nb];
        output Real abu[nb, nu];
        output Real abb[nb, nb];
      external "C" get_rheolef_form_grad_grad(meshfilename, meshnv, nu, nb, auu, 
          aub, abu, abb);
      end getForm_gradgrad_internal;
      /* For debugging */
      
      function writeMatrix 
        annotation (Include="#include <read_matrix.h>", Library="rheolef");
        input String filename="foomatrix.txt";
        input Integer n;
        input Integer m;
        input Real M[n, m];
      external "C" write_matrix(filename, n, m, M);
      end writeMatrix;
      
      function writeVector 
        annotation (Include="#include <read_matrix.h>", Library="rheolef");
        input String filename="foovector.txt";
        input Integer nv;
        input Real v[nv];
      external "C" write_vector(filename, nv, v);
      end writeVector;
      
      function getForm_gradgrad_uu 
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input Integer nu;
        input Integer nb;
        output Real uu[nu, nu];
      protected 
        Real auu[nu, nu];
        Real aub[nu, nb];
        Real abu[nb, nu];
        Real abb[nb, nb];
      algorithm 
        (auu,aub,abu,abb) := getForm_gradgrad_internal(meshfilename, meshnv, nu, 
          nb);
        uu := auu;
      end getForm_gradgrad_uu;
      
      function getFormSize_internal 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        output Integer nu;
        output Integer nb;
      external "C" get_rheolef_form_size(meshfilename, meshnv, nu, nb);
      end getFormSize_internal;
      
      function getBlockedIndices 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input Integer nbr_blockeds;
        output Integer indices[nbr_blockeds];
      external "C" get_rheolef_blocked_indices(meshfilename, meshnv, 
          nbr_blockeds, indices);
      end getBlockedIndices;
      
      function getForm_mass_internal 
        annotation (Include="#include <poisson_rheolef.h>", Library="rheolef");
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input Integer nu;
        input Integer nb;
        output Real auu[nu, nu];
        output Real aub[nu, nb];
        output Real abu[nb, nu];
        output Real abb[nb, nb];
      external "C" get_rheolef_form_mass(meshfilename, meshnv, nu, nb, auu, aub, 
          abu, abb);
      end getForm_mass_internal;
      
      function getForm_mass 
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input FormSize s;
        output Form form(nu=s.nu, nb=s.nb);
      protected 
        Real auu[s.nu, s.nu];
        Real aub[s.nu, s.nb];
        Real abu[s.nb, s.nu];
        Real abb[s.nb, s.nb];
      algorithm 
        (auu,aub,abu,abb) := getForm_mass_internal(meshfilename, meshnv, s);
        form.uu := auu;
        form.ub := aub;
        form.bu := abu;
        form.bb := abb;
        form.nu := s.nu;
        form.nb := s.nb;
      end getForm_mass;
      
      function getForm_mass_uu 
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input Integer nu;
        input Integer nb;
        output Real uu[nu, nu];
      protected 
        Real auu[nu, nu];
        Real aub[nu, nb];
        Real abu[nb, nu];
        Real abb[nb, nb];
      algorithm 
        (auu,aub,abu,abb) := getForm_mass_internal(meshfilename, meshnv, nu, nb);
        uu := auu;
      end getForm_mass_uu;
      
      function getForm_mass_ub 
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input Integer nu;
        input Integer nb;
        output Real ub[nu, nb];
      protected 
        Real auu[nu, nu];
        Real aub[nu, nb];
        Real abu[nb, nu];
        Real abb[nb, nb];
      algorithm 
        (auu,aub,abu,abb) := getForm_mass_internal(meshfilename, meshnv, nu, nb);
        ub := aub;
      end getForm_mass_ub;
      
      function getForm_gradgrad_ub 
        //input Mesh.Data mesh;
        input String meshfilename;
        input Integer meshnv;
        input Integer nu;
        input Integer nb;
        output Real ub[nu, nb];
      protected 
        Real auu[nu, nu];
        Real aub[nu, nb];
        Real abu[nb, nu];
        Real abb[nb, nb];
      algorithm 
        (auu,aub,abu,abb) := getForm_gradgrad_internal(meshfilename, meshnv, nu, 
          nb);
        ub := aub;
      end getForm_gradgrad_ub;

      function writeSquareMatrix 
        annotation (Include="#include <read_matrix.h>", Library="rheolef");
        input String filename="foomatrix.txt";
        input Integer nv;
        input Real M[nv, nv];
      external "C" write_square_matrix(filename, nv, M);
      end writeSquareMatrix;
    end FEMSolver;
    
    package DomainOperators 
      "Domain operators return the values of the field on the interior of the domain" 
      
      function interior1D "Field in the interior of 2D domain" 
        input Integer nVertices;
        input Real vertices[nVertices, 2];
        output Real interior[nVertices];
        
      algorithm 
        interior := zeros(nVertices);
        for i in 1:nVertices loop
          interior[i] := if vertices[i, 2] > 0 then 0 else 1;
        end for;
        annotation (Documentation(info="<HTML>
<pre>
Returns a vector with value 0 for boundary-vertices and 1 for other vertices .
</pre>
</HTML>
"));
      end interior1D;
      
      function interior2D "Field in the interior of 2D domain" 
        input Integer nVertices;
        input Real vertices[nVertices, 3];
        output Real interior[nVertices];
        
      algorithm 
        interior := zeros(nVertices);
        for i in 1:nVertices loop
          interior[i] := if vertices[i, 3] > 0 then 0 else 1;
        end for;
        annotation (Documentation(info="<HTML>
<pre>
Returns a vector with value 0 for boundary-vertices and 1 for other vertices .
</pre>
</HTML>
"));
      end interior2D;
      annotation (Documentation(info=""), Icon);
      
    end DomainOperators;
    
  end FEMExternalSolver2;
end PDE2D;

