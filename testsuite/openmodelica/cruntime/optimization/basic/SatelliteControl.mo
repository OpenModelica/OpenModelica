model SatelliteControl
  // see:  Tamimi, J.: Development of the Efficient Algorithms for Model Predictive Control of Fast Systems.
  // PhD Thesis, Technische Universität Ilmenau, VDI Verlag, 2011
  constant Real I1 = 1e6;
  constant Real I2 = 833333;
  constant Real I3 = 916667;
  constant Real T1S = 550;
  constant Real T2S = 50;
  constant Real T3S = 550;
  Real e1(start = 0, fixed = true);
  Real e2(start = 0, fixed = true);
  Real e3(start = 0, fixed = true);
  Real e4(start = 1, fixed = true);
  Real w1(start = 0.01, fixed = true);
  Real w2(start = 0.005, fixed = true);
  Real w3(start = 0.001, fixed = true);
  input Real T1(start = 0);
  input Real T2(start = 0);
  input Real T3(start = 0);
equation
  der(e1) = 0.5*(w1*e4 -w2*e3 + w3*e2);
  der(e2) = 0.5*(w1*e3 + w2*e4 - w3*e1);
  der(e3) = 0.5*(-w1*e2 + w2*e1 + w3*e4);
  der(e4) = -0.5*(w1*e1 + w2*e3 + w3*e3);
  der(w1) = ((I2-I3)*w2*w3 + T1*T1S)/I1;
  der(w2) = ((I3-I1)*w3*w1 + T2*T2S)/I2;
  der(w3) = ((I1-I2)*w1*w2 + T3*T3S)/I3;
end SatelliteControl;


optimization nmpcSatelliteControl(objective = cost, objectiveIntegrand = costPath)
  Real cost = w1^2 + w2^2 + w3^2 + (e1-0.70106)^2 + (e2 - 0.0923)^2 + (e4 - 0.43047)^2;
  Real costPath = 0.5*(T1^2 + T2^2 + T3^2);
  extends SatelliteControl;
end nmpcSatelliteControl;
