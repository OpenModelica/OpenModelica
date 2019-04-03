within ;
package Bug
  partial block Interface
    input Real x;
    output Real y;
  end Interface;

  block Impl
    extends Interface;
  equation
    y = 2*x;
  end Impl;

  model A
    outer block R = Interface;
    R r(x = 1);
    Real y = r.y;
  end A;

  model B
    inner block R = Impl;
    A a;
    Real xa(start = 1);
  equation
    der(xa) = a.y;
  end B;
end Bug;
