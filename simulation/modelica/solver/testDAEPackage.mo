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
    Real v = cos(time)*x;
    Real w = der(x)+x*y;
    Real z(start=-3);
    Real x,y(start=1);
  equation
    when x > 1.2 then
      z = cos(y);
    end when;
    der(x) = sin(time)+v*z;
    der(y) = x^2-y*w;
  end p5;

  model p6
    Real x[2];
    Real A[2,2] = [3,1;2,1];
  equation
    A*der(x)={1,2};
  end p6;

end testDAE;
