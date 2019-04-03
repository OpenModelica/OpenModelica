//
//  Package that defines a set of testcases
//  to test for DAE integration method.
//
//

package testDAE

  // problem1: simple dae
  model p1
    Real x,y(start=1);
  equation
    der(x) = sin(time);
    der(y) = x^2-y;
  end p1;

  // problem2: simple dae with algebraic equations
  model p2
    Real v = cos(time)*x;
    Real w = der(x)+x*y;
    Real x,y(start=1);
  equation
    der(x) = sin(time)+v;
    der(y) = x^2-y*w;
  end p2;

  // problem3: simple dae with algebraic loops, dynamicState selection
  model p3
    Real x(start = 0.9,fixed=true);
    Real y(fixed=false);
  equation
    (1 + 0.5*sin(y))*der(x) + der(y) = 2*sin(time);
    x-y = exp(-0.9*x)*cos(y);
  end p3;

  // problem4: simple dae with algebraic loop with states and algebraic equations
  model p4
    Real x(start = 0.9,fixed=true);
    Real y(fixed=false);
    Real v = cos(time)*der(y);
    Real w = der(x)+x*y;
  equation
    (1 + 0.5*sin(y))*der(x) + y = 2*sin(v+w);
    x-der(y) = exp(-0.9*x)*cos(y)+v*w;
  end p4;

  // problem5: simple dae with when equation
  model p5
    Real v = -cos(time)*x;
    Real w = der(x)+x*v;
    Real z(start=-3);
    Real x(start=1),y(start=1);
  equation
    when v < -1.2 then
      z = cos(y);
    end when;
    der(x) = sin(time)+v*z;
    der(y) = x^2-y*w;
  end p5;

  // problem6: simple dae with array and matrix elements
  model p6
    Real x[2];
    Real A[2,2] = [3,1;2,1];
  equation
    A*der(x)={1,2};
  end p6;

  // problem7: simple dae with record functions
  model p7
    record R
      Real a;
      Real b;
    end R;
    function inRecordF
      input R r;
      output Real y;
    algorithm
      y := exp(-0.9*r.a)*cos(r.b);
    end inRecordF;
    function outRecordF
      input Real x;
      input Real y;
      output R r;
    algorithm
      r.a := exp(-0.9*x)*cos(y);
      r.b := sin(x*y);
    end outRecordF;

    Real x(start = 0.9,fixed=true);
    Real y(fixed=false);
    Real v = cos(time)*der(y);
    Real w = der(x)+x*y;
    R r = outRecordF(x,y);
    Real r1,r2;
  equation
    R(r1,r2) = outRecordF(2*x,3*y);
    (1 + 0.5*sin(y))*der(x) + y = 2*sin(v+w);
    x-der(y) = inRecordF(r)+v*w;
  end p7;

  // problem8: event trigger example
  model p8
    Real v = cos(time)*x;
    Real w = der(x)+x*y;
    Real z(start=-3);
    Real x(start=0.8),y(start=1);
  equation
    z = if x > 1.2 then 10*cos(y) else sin(y);
    der(x) = sin(time)+v*z;
    der(y) = x^2-y*w;
  end p8;

  // problem9: array equations
  model p9
    function f1
      input Real dx;
      input Real x[2];
      input Real y[2];
      output Real z[2];
    algorithm
      for i in 1:2 loop
        z[i] := dx + x[i]*y[i];
      end for;
    end f1;
    Real v[2] = cos(time)*x;
    Real w[2]; // = f1(der(x), x, y);
    Real z(start=-3);
    Real[2] x(each start=0.8),y(each start=1);
  equation
    w = f1(der(y[1]), x, y);
    z = 10*cos(y[1]);
    der(x) = sin(time)*{1,1}+v*z;
    der(y) = x[1]*x+x[2]*x-y*w[1]+w[2]*y;
  end p9;

end testDAE;
