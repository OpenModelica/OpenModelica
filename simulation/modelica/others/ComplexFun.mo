  model problem1
    function f
      input Real x;
      input Real y;
      output Real a;
      output Real b;
    algorithm
      a := x + y;
      b := x - y;
    end f;

    Real x, y(start =0);
  equation
    (x, y) = f(time, 2 * y + sqrt(time));
  end problem1;

  model problem2
    function f
      input Real x;
      input Real y;
      output Real a;
      output Real b;
    algorithm
      a := x + y;
      b := x - y;
    end f;

    Real z = -y;
    Real x, y;
  equation
    (x, y) = f(time, 1 + sqrt(time));
  end problem2;

