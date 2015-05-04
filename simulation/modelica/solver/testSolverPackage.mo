//
//  Package that defines a set of  test problems
//  for integration methods.
//
//

package testSolver

 model bug2231
   parameter Integer n = 1;
   parameter Real x0[n] = {1};
    Real x[n](start=x0);
    parameter Real a = 1;
  equation
   der(x) = a*x;
  end bug2231;

  model problem1 "Burgers equation"
   parameter Real h = 1/N+2;
   Real u[N+2](start=u0);
   parameter Integer N = 150;
   parameter Real v = 1000;
   parameter Real Pi = 3.14159265358979;
   parameter Real u0[N+2]={((sin(3*Pi*x[i])^3)*sin(1-x[i])^(3/2)) for i in 1:N+2};
   parameter Real x[N+2] = { i/(N+2) for i in 0:N+1};
  equation
   der(u[1]) = 0;
   for i in 2:N+1 loop
      der(u[i]) = - ((u[i+1]^2-u[i-1]^2)/(4*(x[i+1]-x[i-1])))+(v/(x[i+1]-x[i-1])^2)*(u[i+1]-2*u[i]+u[i+1]);
   end for;
   der(u[N+2]) = 0;
  end problem1;


  model problem2 "HIRES problem"
    /* solution at time: 321.8122
      0.000737131257332567
      0.000144248572631618
      0.000058887297409676
      0.001175651343283149
      0.002386356198831330
      0.006238968252742796
      0.002849998395185769
      0.002850001604814231
    */
    Real y[8](start=y0);
    parameter Real y0[8] = { 1, 0, 0, 0, 0, 0, 0, 0.0057};
  equation
    der(y[1]) = -1.71*y[1] + 0.43*y[2] + 8.32*y[3] + 0.0007;
    der(y[2]) = 1.71*y[1] - 8.75*y[2];
    der(y[3]) = -10.03*y[3] + 0.43*y[4] + 0.035*y[5];
    der(y[4]) =  8.32*y[2] + 1.71*y[3] - 1.12*y[4];
    der(y[5]) = -1.745*y[5] + 0.43*y[6] + 0.43*y[7];
    der(y[6]) = -280.0*y[6]*y[8] + 0.69*y[4] + 1.71*y[5] - 0.43*y[6] + 0.69*y[7];
    der(y[7]) =  280.0*y[6]*y[8] - 1.81*y[7];
    der(y[8]) = -der(y[7]);
  end problem2;

end testSolver;
