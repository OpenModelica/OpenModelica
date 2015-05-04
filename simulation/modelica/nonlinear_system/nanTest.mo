within ;
package nonlinear_system
  model nanTest
    Real x,y,z;
  equation
    x = cos(y);
    y = log(x);
    z = sin(1/x);
  end nanTest;
end nonlinear_system;
