package BoundariesParams 
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
    package PartType = GenericTemp;
    
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
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.parts5)
         else if pno == 6 then PartType.shape(s - is, d.parts6) else if pno == 
        7 then PartType.shape(s - is, d.parts7) else if pno == 8 then 
        PartType.shape(s - is, d.parts8) else {-1,-1};
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
    package PartType = GenericTemp;
    
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
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.parts5)
         else if pno == 6 then PartType.shape(s - is, d.parts6) else if pno == 
        7 then PartType.shape(s - is, d.parts7) else if pno == 8 then 
        PartType.shape(s - is, d.parts8) else {-1,-1};
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
           else if i == 2 then PartType.points(numbers[i], d.parts2) else if i
           == 3 then PartType.points(numbers[i], d.parts3) else if i == 4 then 
          PartType.points(numbers[i], d.parts4) else if i == 5 then 
          PartType.points(numbers[i], d.parts5) else if i == 6 then 
          PartType.points(numbers[i], d.parts6) else if i == 7 then 
          PartType.points(numbers[i], d.parts7) else if i == 8 then 
          PartType.points(numbers[i], d.parts8) else PartType.points(numbers[i], 
          d.parts1);
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
    
    type PartTypeEnum = Integer (min=PartTypeEnumC.Begin, max=PartTypeEnumC.End);
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
      parameter Line.Parameters line;
      parameter Arc.Parameters arc;
      parameter Circle.Parameters circle;
      parameter RectangleTemp.Parameters rectangle;
      parameter Bezier.Parameters bezier;
    end Parameters;
    
    redeclare record Data 
      parameter Parameters p;
      parameter Line.Data line(p=p.line);
      parameter Arc.Data arc(p=p.arc);
      parameter Circle.Data circle(p=p.circle);
      parameter RectangleTemp.Data rectangle(p=p.rectangle);
      parameter Bezier.Data bezier(p=p.bezier);
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output Point x;
    algorithm 
      if d.p.partType == PartTypeEnumC.line then
        x := Line.shape(u, d.line);
      else
        if d.p.partType == PartTypeEnumC.arc then
          x := Arc.shape(u, d.arc);
        else
          if d.p.partType == PartTypeEnumC.circle then
            x := Circle.shape(u, d.circle);
          else
            if d.p.partType == PartTypeEnumC.rectangle then
              x := RectangleTemp.shape(u, d.rectangle);
            else
              if d.p.partType == PartTypeEnumC.bezier then
                x := Bezier.shape(u, d.bezier);
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
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else {-1,-1};
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
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.parts5)
         else if pno == 6 then PartType.shape(s - is, d.parts6) else if pno == 
        7 then PartType.shape(s - is, d.parts7) else if pno == 8 then 
        PartType.shape(s - is, d.parts8) else {-1,-1};
    end shape;
    
  end HComposite8;
  
  package RectangleTemp 
    extends Boundary;
    package Bnd = HComposite4 (redeclare package PartType 
          import PDEbhjl;
          extends PDEbhjl.BoundariesParams.Line;
      end PartType);
    
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
    
  end RectangleTemp;
  
  package Composite4 
    extends Boundary;
    package PartType = GenericTemp;
    
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
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else {-1,-1};
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
end BoundariesParams;
