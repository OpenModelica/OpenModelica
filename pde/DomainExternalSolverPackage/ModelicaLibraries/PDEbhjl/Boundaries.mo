package Boundaries 
  package Line 
    extends Boundary;
    
    redeclare record extends Data 
      parameter Point p1;
      parameter Point p2;
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    algorithm 
      x[1:2] := d.p1 + u*(d.p2 - d.p1);
      x[3] := d.bc.index;
    end shape;
    
  end Line;
  
  package Arc 
    extends Boundary;
    constant Real pi=3.141592654;
    
    redeclare record Data 
      extends Boundary.Data;
      parameter Point c={0,0};
      parameter Real r=1;
      parameter Real a_start=0;
      parameter Real a_end=2*pi;
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Real a=(d.a_end - d.a_start);
    algorithm 
      x[1:2] := d.c + d.r*{cos(d.a_start + a*u),sin(d.a_start + a*u)};
      x[3] := d.bc.index;
    end shape;
    
  end Arc;
  
  package Circle 
    extends Arc(Data(a_start=0, a_end=2*pi));
    
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
    
    redeclare record extends Data 
      parameter Point p;
      parameter Real w;
      parameter Real h;
      
      parameter Bnd.Data bnddata(n=4, parts={bottom,right,top,left});
      parameter Line.Data bottom(
        p1=p, 
        p2=p + {w,0}, 
        bc(index=1, name="bottom"));
      parameter Line.Data right(
        p1=p + {w,0}, 
        p2=p + {w,h}, 
        bc(index=2, name="right"));
      parameter Line.Data top(
        p1=p + {w,h}, 
        p2=p + {0,h}, 
        bc(index=3, name="top"));
      parameter Line.Data left(
        p1=p + {0,h}, 
        p2=p, 
        bc(index=4, name="left"));
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    algorithm 
      x := Bnd.shape(u, d.bnddata);
    end shape;
    
    redeclare function points = Boundary.points;
    
  end Rectangle;
  
  package HComposite 
    extends Boundary;
    replaceable package PartType = Boundary extends Boundary;
    
    redeclare replaceable record Data 
      parameter Integer n=1;
      parameter PartType.Data parts[n];
    end Data;
    
    /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Real s=d.n*u;
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
    
    redeclare replaceable record Data 
      parameter PartTypeEnum partType;
      parameter Line.Data line;
      parameter Arc.Data arc;
      parameter Circle.Data circle;
      parameter Rectangle.Data rectangle;
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    algorithm 
      if d.partType == PartTypeEnum.line then
        x := Line.shape(u, d.line);
      else
        if d.partType == PartTypeEnum.arc then
          x := Arc.shape(u, d.arc);
        else
          if d.partType == PartTypeEnum.circle then
            x := Circle.shape(u, d.circle);
          else
            if d.partType == PartTypeEnum.rectangle then
              x := Rectangle.shape(u, d.rectangle);
            end if;
          end if;
        end if;
      end if;
    end shape;
    
    redeclare function points = Boundary.points;
    
  end Generic;
  
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
    
    redeclare record extends Data 
      parameter PartTypeEnum partType;
      parameter Boundaries.Line.Data line;
      parameter Boundaries.Arc.Data arc;
      parameter Boundaries.Circle.Data circle;
      parameter Boundaries.RectangleTemp.Data rectangle;
      parameter Boundaries.Bezier.Data bezier;
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    algorithm 
      if d.partType == PartTypeEnumC.line then
        x := Boundaries.Line.shape(u, d.line);
      else
        if d.partType == PartTypeEnumC.arc then
          x := Boundaries.Arc.shape(u, d.arc);
        else
          if d.partType == PartTypeEnumC.circle then
            x := Boundaries.Circle.shape(u, d.circle);
          else
            if d.partType == PartTypeEnumC.rectangle then
              x := Boundaries.RectangleTemp.shape(u, d.rectangle);
            else
              if d.partType == PartTypeEnumC.bezier then
                x := Boundaries.Bezier.shape(u, d.bezier);
              end if;
            end if;
          end if;
        end if;
      end if;
    end shape;
    
    redeclare function points = Boundary.points;
    
  end GenericTemp;

  package Bezier 
    extends Boundary;
    
    redeclare record extends Data 
      parameter Integer n=1;
      parameter Point p[n];
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Point q[:]=d.p;
    algorithm 
      for k in 1:(d.n - 1) loop
        for i in 1:(d.n - k) loop
          q[i, :] := (1 - u)*q[i, :] + u*q[i + 1, :];
        end for;
      end for;
      x[1:2] := q[1, :];
      x[3] := d.bc.index;
    end shape;
    
    redeclare function points = Boundary.points;
    
  end Bezier;
  
  package Composite8 
    extends Boundary;
    package PartType = Boundaries.GenericTemp;
    
    redeclare replaceable record extends Data 
      parameter Integer n=8;
      parameter PartType.Data parts1(bc(index=1));
      parameter PartType.Data parts2(bc(index=2));
      parameter PartType.Data parts3(bc(index=3));
      parameter PartType.Data parts4(bc(index=4));
      parameter PartType.Data parts5(bc(index=5));
      parameter PartType.Data parts6(bc(index=6));
      parameter PartType.Data parts7(bc(index=7));
      parameter PartType.Data parts8(bc(index=8));
    end Data;
    
    /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Real s=d.n*u;
      Integer is=integer(s);
      Integer pno=is + 1;
    algorithm 
      x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
         then PartType.shape(s - is, d.parts2) else if pno == 3 then 
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.parts5)
         else if pno == 6 then PartType.shape(s - is, d.parts6) else if pno == 
        7 then PartType.shape(s - is, d.parts7) else if pno == 8 then 
        PartType.shape(s - is, d.parts8) else {-1,-1,-1};
    end shape;
    
    replaceable function points 
      input Integer n;
      input Data d;
      output BPoint x[n];
    algorithm 
      for i in 1:n loop
        x[i, :] := shape((i - 1)/n, d);
      end for;
    end points;
    
  end Composite8;
  
  package Composite8dist 
    extends Boundary;
    package PartType = Boundaries.GenericTemp;
    
    redeclare replaceable record Data 
      parameter Integer n=8;
      parameter Real distribution[n]=ones(n);
      parameter PartType.Data parts1(bc(index=1));
      parameter PartType.Data parts2(bc(index=2));
      parameter PartType.Data parts3(bc(index=3));
      parameter PartType.Data parts4(bc(index=4));
      parameter PartType.Data parts5(bc(index=5));
      parameter PartType.Data parts6(bc(index=6));
      parameter PartType.Data parts7(bc(index=7));
      parameter PartType.Data parts8(bc(index=8));
    end Data;
    
    /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Real s=d.n*u;
      Integer is=integer(s);
      Integer pno=is + 1;
    algorithm 
      x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
         then PartType.shape(s - is, d.parts2) else if pno == 3 then 
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.parts5)
         else if pno == 6 then PartType.shape(s - is, d.parts6) else if pno == 
        7 then PartType.shape(s - is, d.parts7) else if pno == 8 then 
        PartType.shape(s - is, d.parts8) else {-1,-1,1};
    end shape;
    
    replaceable function points 
      input Integer n;
      input Data d;
      output Point x[n];
    protected 
      Integer numbers[d.n]=integer(n*d.distribution);
      //Integer numbers[d.p.n]=d.p.distribution;
      Integer j1=1;
      Integer j2;
    algorithm 
      for i in 1:d.n loop
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
  
  
  package HComposite4 
    extends Boundary;
    replaceable package PartType = Boundary extends Boundary;
    
    redeclare replaceable record Data 
      parameter Integer n=4;
      parameter PartType.Data parts1(bc(index=1));
      parameter PartType.Data parts2(bc(index=2));
      parameter PartType.Data parts3(bc(index=3));
      parameter PartType.Data parts4(bc(index=4));
      
    end Data;
    
    /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Real s=d.n*u;
      Integer is=integer(s);
      Integer pno=is + 1;
    algorithm 
      x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
         then PartType.shape(s - is, d.parts2) else if pno == 3 then 
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else {-1,-1,-1};
    end shape;
    
  end HComposite4;
  
  package HComposite8 
    extends Boundary;
    replaceable package PartType = Boundary extends Boundary;
    
    redeclare replaceable record Data 
      parameter Integer n=8;
      parameter PartType.Data parts1(bc(index=1));
      parameter PartType.Data parts2(bc(index=2));
      parameter PartType.Data parts3(bc(index=3));
      parameter PartType.Data parts4(bc(index=4));
      parameter PartType.Data parts5(bc(index=5));
      parameter PartType.Data parts6(bc(index=6));
      parameter PartType.Data parts7(bc(index=7));
      parameter PartType.Data parts8(bc(index=8));
    end Data;
    
    /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Real s=d.n*u;
      Integer is=integer(s);
      Integer pno=is + 1;
    algorithm 
      x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
         then PartType.shape(s - is, d.parts2) else if pno == 3 then 
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else if pno == 5 then PartType.shape(s - is, d.parts5)
         else if pno == 6 then PartType.shape(s - is, d.parts6) else if pno == 
        7 then PartType.shape(s - is, d.parts7) else if pno == 8 then 
        PartType.shape(s - is, d.parts8) else {-1,-1,-1};
    end shape;
    
  end HComposite8;
  
  package RectangleTemp 
    extends Boundary;
    package Bnd = HComposite4 (redeclare package PartType = Boundaries.Line);
    
    redeclare record extends Data 
      parameter Point p;
      parameter Real w;
      parameter Real h;
      parameter Bnd.Data bnddata(
        n=4, 
        parts1=bottom, 
        parts2=right, 
        parts3=top, 
        parts4=left);
      parameter Boundaries.Line.Data bottom(
        p1=p, 
        p2=p + {w,0}, 
        bc(index=1, name="bottom"));
      parameter Boundaries.Line.Data right(
        p1=p + {w,0}, 
        p2=p + {w,h}, 
        bc(index=2, name="right"));
      parameter Boundaries.Line.Data top(
        p1=p + {w,h}, 
        p2=p + {0,h}, 
        bc(index=3, name="top"));
      parameter Boundaries.Line.Data left(
        p1=p + {0,h}, 
        p2=p, 
        bc(index=4, name="left"));
    end Data;
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    algorithm 
      x := Bnd.shape(u, d.bnddata);
    end shape;
    
  end RectangleTemp;
  
  package Composite4 
    extends Boundary;
    package PartType = Boundaries.GenericTemp;
    
    redeclare replaceable record Data 
      parameter Integer n=4;
      parameter PartType.Data parts1(bc(index=1));
      parameter PartType.Data parts2(bc(index=2));
      parameter PartType.Data parts3(bc(index=3));
      parameter PartType.Data parts4(bc(index=4));
    end Data;
    
    /* Bug in shape: All parts does not start at s-is==0, which causes some corners to be 
    skipped because both x and y changes. Should be fixed by somehow making sure that 
    every time new part is started, s-is starts from 0. Maybe some kind of threshold and 
    rounding s-is<e to zero. */
    
    redeclare function shape 
      input Real u;
      input Data d;
      output BPoint x;
    protected 
      Real s=d.n*u;
      Integer is=integer(s);
      Integer pno=is + 1;
    algorithm 
      x := if pno == 1 then PartType.shape(s - is, d.parts1) else if pno == 2
         then PartType.shape(s - is, d.parts2) else if pno == 3 then 
        PartType.shape(s - is, d.parts3) else if pno == 4 then PartType.shape(s
         - is, d.parts4) else {-1,-1,-1};
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
