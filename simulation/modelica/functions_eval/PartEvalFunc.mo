within ;
package PartEvalFunc
  record record1
    Real x;
    Real y;

    annotation ();
  end record1;

  record record2
    Real x;
    Real y;
    Real z;

    annotation ();
  end record2;

  function func
    input Real in1;
    input Real in2;
    output Real out;
  protected
    Real x;
  algorithm
    x := in1+in2;
    out := 8;
    annotation ();
  end func;

  function func1
    input Real in1;
    input Real in2;
    output Real out;
  protected
    Real x;
    Real y;
  algorithm
    x := in1+in2;
    y := if in1<5 then 1 else x;
    out := 8+y;
    annotation ();
  end func1;

  function func2
    input Real in1;
    input Real in2;
    output Real out;
  protected
    Real x;
    Real y;
  algorithm
    x := in1+in2;
    if ((in1 > 0.0) and (func(1.0,2.0)) > 0.0) then
      out := 5.5;
    elseif
          ((in1 <= 0.0) and 8.0 > 0.0) then
          //((in1 <= 0.0) and (func(1.0,2.0)) > 0.0) then
      out := 7.7;
    else out := 1.1;
  end if;
    annotation ();
  end func2;

  function recfunc
    input record1 in1;
    input Real in2;
    output record1 out1;
  protected
    Real a;
  algorithm
    out1.x := 5.0;
    out1.y := in1.y;
    annotation ();
  end recfunc;

  function recfunc2
    input record2 in1;
    input Real in2;
    output record2 out1;
  protected
    Real a;
  algorithm
    out1.x := 5.0;
    out1.y := in1.y;
    out1.z := in2;
    annotation ();
  end recfunc2;

  function recfunc3
    input record2 in1;
    input Real in2;
    output record2 out1;
  protected
    Real a;
    Real b;
    Real c;
  algorithm
    a := -7;
    b := 3;
    c := 6;
    (a,b,c) := recfuncTuple2(in1,a); // a becomes 5.0, c becomes a, b becomes in1.y
    out1.x := 5.0;
    out1.y := in1.z;
    out1.z := a+b+c;
    annotation ();
  end recfunc3;

  function recfunc4
    input record2 in1;
    input Real in2;
    output record2 out1;
  protected
    Real a;
  algorithm
    out1.y := 0.0;
    out1.x := 1.0;
    out1.y := in2;
    out1.y := in1.y + out1.y + out1.x;
    out1.y := 0.0;
    out1.x := 1.0;
    out1.x := in2;
    out1.z := in2 + out1.x;
    out1.x := 5.0;
    annotation ();
  end recfunc4;

  function recfuncTuple
    input record1 in1;
    input Real in2;
    output Real out1_x;
    output Real out1_y;
  protected
    Real a;
  algorithm
    out1_x := 5.0;
    out1_y := in1.y;
    annotation ();
  end recfuncTuple;

  function recfuncTuple2
    input record2 in1;
    input Real in2;
    output Real out1_x;
    output Real out1_y;
    output Real out1_z;
  protected
    Real a;
  algorithm
    out1_x := 5.0;
    out1_y := in1.y;
    out1_z := in2;
    annotation ();
  end recfuncTuple2;

  model functionTest
    Real a;
    Real b;
    Real c;
    Real d;
    parameter Real x = 10;
  equation

  a = x * sin(time);
  b = func(a,b);
  c = b+a;
  d = der(c);

    annotation ();
  end functionTest;

  model functionTest1
    Real a;
    Real b;
    Real c;
    Real d;
    parameter Real x=10;
  equation

  a = x * sin(time);
  b = func(a, 10.0);
  c = b+a;
  d = der(c);

  end functionTest1;

  model functionTest2
    Real a;
    Real b;
    Real c;
    Real d;
    parameter Real x = 10;
  equation

  a = x * sin(time);
  b = func1(3,a);
  c = b+a;
  d = der(c);

    annotation ();
  end functionTest2;

  model functionTest3_elseif
    Real a;
    Real b;
    Real c;
    Real d;
    parameter Real x = 10;
  equation

  a = x * sin(time);
  b = func2(-3.0, a);
  c = b+a;
  d = der(c);

    annotation ();
  end functionTest3_elseif;

  model functionTest4
    Real a;
    Real b;
    Real c;
    Real d;

    record1 r1;
    record1 r2;

  equation
  a = time;
  b = 2.0;
  r1 = record1(b,a);
  r2 = recfunc(r1,a);
  c = r2.y + a;
  c = der(d);

    annotation ();
  end functionTest4;

  model functionTest4Tuple
    Real a;
    Real b;
    Real c;
    Real d;

    record1 r1;
    record1 r2;

  equation
  a = sin(time);
  b = 2;
  r1 = record1(b,a);
  (r2.x, r2.y) = recfuncTuple(r1,a);
  c = r1.x + a;
  d = der(c);

    annotation ();
  end functionTest4Tuple;

  model functionTest5
    Real a;
    Real b;
    Real c;
    Real d( start= 0.0, fixed=true);

    record2 r1;
    record2 r2;

  equation
  a = time;
  b = 2.0;
  r1 = record2(b,a,3.0);
  r2 = recfunc2(r1,a);
  c = r2.y + a;
  c = der(d);

    annotation ();
  end functionTest5;

  model functionTest6
    Real a;
    Real b;
    Real c;
    Real d;

    record2 r1;
    record2 r2;

  equation
  a = time;
  b = 2.0;
  r1 = record2(b,3.0,a);
  r2 = recfunc3(r1,a);//x is 5.0,y is a(time),z is -7.0,
  d = r2.y + a +b+ r1.x +r2.z;
  d = der(c);

    annotation ();
  end functionTest6;

  model functionTest7
    Real a;
    Real b;
    Real c;
    Real d( start= 0.0, fixed=true);

    record2 r1;
    record2 r2;

  equation
  a = time;
  b = 2.0;
  r1 = record2(b,a,3.0);
  r2 = recfunc4(r1,a);
  c = r2.y + a +r2.z;
  c = der(d);

    annotation ();
  end functionTest7;

  model functionTest8
    Real a;
    Real b;
    Real c;
    Real d( start= 0.0, fixed=true);
    Real e;
    record2 r1;
    record2 r2;

  equation
  a = time;
  b = 2.0;
  r1 = record2(b,a,3.0);
  r2 = recfunc4(r1,a);
  c = r2.y + a;
  c = der(d);
  e =r2.z;
    annotation ();
  end functionTest8;

  package SimplifyIfBranches
    model simplify1
      Real r1, r2;
      Real x;
    equation
      (r1,r2) = funcSimplify1(time < 0.5, time < 0.7);
      r2 = (1.0 - r1)*der(x) + x;
    end simplify1;

    function funcSimplify1
      input Boolean b1;
      input Boolean b2;
      output Real r1;
      output Real r2;
    protected
      Real r3;
    algorithm
      if (b1) then
        r1 := 1.0;
        r2 := 1.0;
      elseif (b2) then
        r2 := 2.0;
        r1 := 1.0;
      else
        r1 := 1.0;
        r2 := 3.0;
        r3 := 5.0;
      end if;
    end funcSimplify1;

    model simplify2
      Real r1, r2;
      Real x;
    equation
      (r1,r2) = funcSimplify2a(time < 0.5);
      r2 = (1.0 - r1)*der(x) + x;
    end simplify2;

    function funcSimplify2a
      input Boolean b;
      output Real r1;
      output Real r2;
    algorithm
      if (b) then
        (r1,r2) := funcSimplify2b(b, 1.0);
      else
        (r1,r2) := funcSimplify2b(b, 2.0);
        r1 := r1 - 1.0;
      end if;
    end funcSimplify2a;

    function funcSimplify2b
      input Boolean b;
      input Real r_in;
      output Real r1_out;
      output Real r2_out;
    algorithm
      if (b) then
        r1_out := r_in;
        r2_out := 1.0;
      else
        r1_out := r_in;
        r2_out := 2.0;
      end if;
    end funcSimplify2b;
  end SimplifyIfBranches;
end PartEvalFunc;
