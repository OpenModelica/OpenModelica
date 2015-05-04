within ;
package nonlinear_system
  model nonlinearDelayTest
    Real x1;
    Real x2;
    Real y;
  equation
    der(y) = x1+x2;
    x1 + 2*x2-delay(y,0.1) = 0;
    x1^2 + 4*delay(x2,0.1)^4-4 = 0;
  end nonlinearDelayTest;
end nonlinear_system;
