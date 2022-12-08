within NewDataReconciliationSimpleTests;
model MergerDynInit
  parameter Real rho = 1.0;
  Real Q1(uncertain = Uncertainty.refine, start=2.1) "Mass flow at inlet 1";    // Measured variable of interest
  Real Q2(uncertain = Uncertainty.refine, start=1.05) "Mass flow at inlet 2";   // Measured variable of interest
  Real Q3(uncertain = Uncertainty.refine, start=3.0) "Mass flow at outlet";     // Measured variable of interest
  Real P1(uncertain = Uncertainty.refine, start=3.1) "Pressure at inlet 1";     // Measured variable of interest
  Real P2;
  Real P3(uncertain = Uncertainty.refine, start=1.1) "Pressure at outlet";      // Measured variable of interest
  Real P(uncertain = Uncertainty.propagate) "Pressure inside merger";           // Unmeasured variable of interest
  Real V(uncertain = Uncertainty.refine, start=8) "Initial volume";             // Measured variable of interest

  Real BQ "Mass balance";

  parameter Real P01(uncertain = Uncertainty.refine, start=3) = 3.93397 "Pressure bc at inlet 1" annotation(__OpenModelica_BoundaryCondition = true) ;  // Boundary condition
  parameter Real P02(uncertain = Uncertainty.propagate) = 5.73935 "Pressure bc at inlet 2" annotation(__OpenModelica_BoundaryCondition = true);   // Boundary condition
  parameter Real P03(uncertain = Uncertainty.propagate) = 0.937834 "Pressure bc at outlet" annotation(__OpenModelica_BoundaryCondition = true);   // Boundary condition

  parameter Real der_V = -0.000907595; // der_V = 0 is uncertain
  parameter Real k1 = 1;
  parameter Real k2 = 1;
  parameter Real k3 = 1;

  parameter Boolean dynamic = false;

initial equation
  if dynamic then
    der(V) = der_V;
  end if;

equation
  P1 = P01;
  P2 = P02;
  P3 = P03;

  BQ = Q1 + Q2 - Q3;

  if dynamic then
    rho*der(V) = BQ;
  else
    rho*der_V = BQ;
  end if;

  P1 - P = k1*Q1*abs(Q1);
  P2 - P = k2*Q2*abs(Q2);
  P - P3 = k3*Q3*abs(Q3);

  P = rho*V/2;

end MergerDynInit;
