// name:     WaveEquationSample
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
//
// Drmodelica: "15: Pressure Dynamics in 1D Ducts - Solving Wave Equations by Discretized PDEs (p. 587)
//
model WaveEquationSample

  function initialPressure
    input Integer n;
    output Real p[n];
    protected
    parameter Modelica.SIunits.Length L = 10;
  algorithm
    for i in 1:n loop
    p[i] := exp(-(-L/2 + (i - 1) / (n - 1) * L)^2);
    end for;
  end initialPressure;

  import Modelica.SIunits;
  parameter SIunits.Length L = 10 "Length of duct";
  parameter Integer n = 30 "Number of sections";
  parameter SIunits.Length dL = L/n "Section length";
  parameter SIunits.Velocity c = 1;
  SIunits.Pressure[n] p(start = initialPressure(n));
  Real[n] dp(start = fill(0,n));
equation
  p[1] = exp(-(-L/2)^2);
  p[n] = exp(-(L/2)^2);
  dp = der(p);
  for i in 2:n-1 loop
  der(dp[i]) = c^2 * (p[i+1] - 2 * p[i] + p[i-1]) / dL^2;
  end for;
end WaveEquationSample;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class WaveEquationSample
//  parameter Real L(quantity = "Length", unit = "m") = 10 "Length of duct";
//  parameter Integer n = 30 "Number of sections";
//  parameter Real dL(quantity = "Length", unit = "m") = L / Real(n) "Section length";
//  parameter Real c(quantity = "Velocity", unit = "m/s") = 1;
//  Real p[1](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[2](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[3](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[4](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[5](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[6](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[7](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[8](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[9](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[10](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[11](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[12](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[13](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[14](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[15](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[16](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[17](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[18](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[19](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[20](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[21](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[22](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[23](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[24](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[25](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[26](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[27](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[28](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[29](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real p[30](quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//  Real dp[1](start = 0.0);
//  Real dp[2](start = 0.0);
//  Real dp[3](start = 0.0);
//  Real dp[4](start = 0.0);
//  Real dp[5](start = 0.0);
//  Real dp[6](start = 0.0);
//  Real dp[7](start = 0.0);
//  Real dp[8](start = 0.0);
//  Real dp[9](start = 0.0);
//  Real dp[10](start = 0.0);
//  Real dp[11](start = 0.0);
//  Real dp[12](start = 0.0);
//  Real dp[13](start = 0.0);
//  Real dp[14](start = 0.0);
//  Real dp[15](start = 0.0);
//  Real dp[16](start = 0.0);
//  Real dp[17](start = 0.0);
//  Real dp[18](start = 0.0);
//  Real dp[19](start = 0.0);
//  Real dp[20](start = 0.0);
//  Real dp[21](start = 0.0);
//  Real dp[22](start = 0.0);
//  Real dp[23](start = 0.0);
//  Real dp[24](start = 0.0);
//  Real dp[25](start = 0.0);
//  Real dp[26](start = 0.0);
//  Real dp[27](start = 0.0);
//  Real dp[28](start = 0.0);
//  Real dp[29](start = 0.0);
//  Real dp[30](start = 0.0);
// equation
//  p[1] = exp(-((-L) / 2.0) ^ 2.0);
//  p[30] = exp(-(L / 2.0) ^ 2.0);
//  dp[1] = der(p[1]);
//  dp[2] = der(p[2]);
//  dp[3] = der(p[3]);
//  dp[4] = der(p[4]);
//  dp[5] = der(p[5]);
//  dp[6] = der(p[6]);
//  dp[7] = der(p[7]);
//  dp[8] = der(p[8]);
//  dp[9] = der(p[9]);
//  dp[10] = der(p[10]);
//  dp[11] = der(p[11]);
//  dp[12] = der(p[12]);
//  dp[13] = der(p[13]);
//  dp[14] = der(p[14]);
//  dp[15] = der(p[15]);
//  dp[16] = der(p[16]);
//  dp[17] = der(p[17]);
//  dp[18] = der(p[18]);
//  dp[19] = der(p[19]);
//  dp[20] = der(p[20]);
//  dp[21] = der(p[21]);
//  dp[22] = der(p[22]);
//  dp[23] = der(p[23]);
//  dp[24] = der(p[24]);
//  dp[25] = der(p[25]);
//  dp[26] = der(p[26]);
//  dp[27] = der(p[27]);
//  dp[28] = der(p[28]);
//  dp[29] = der(p[29]);
//  dp[30] = der(p[30]);
//  der(dp[2]) = (c ^ 2.0 * (p[3] + -2.0 * p[2] + p[1])) / dL ^ 2.0;
//  der(dp[3]) = (c ^ 2.0 * (p[4] + -2.0 * p[3] + p[2])) / dL ^ 2.0;
//  der(dp[4]) = (c ^ 2.0 * (p[5] + -2.0 * p[4] + p[3])) / dL ^ 2.0;
//  der(dp[5]) = (c ^ 2.0 * (p[6] + -2.0 * p[5] + p[4])) / dL ^ 2.0;
//  der(dp[6]) = (c ^ 2.0 * (p[7] + -2.0 * p[6] + p[5])) / dL ^ 2.0;
//  der(dp[7]) = (c ^ 2.0 * (p[8] + -2.0 * p[7] + p[6])) / dL ^ 2.0;
//  der(dp[8]) = (c ^ 2.0 * (p[9] + -2.0 * p[8] + p[7])) / dL ^ 2.0;
//  der(dp[9]) = (c ^ 2.0 * (p[10] + -2.0 * p[9] + p[8])) / dL ^ 2.0;
//  der(dp[10]) = (c ^ 2.0 * (p[11] + -2.0 * p[10] + p[9])) / dL ^ 2.0;
//  der(dp[11]) = (c ^ 2.0 * (p[12] + -2.0 * p[11] + p[10])) / dL ^ 2.0;
//  der(dp[12]) = (c ^ 2.0 * (p[13] + -2.0 * p[12] + p[11])) / dL ^ 2.0;
//  der(dp[13]) = (c ^ 2.0 * (p[14] + -2.0 * p[13] + p[12])) / dL ^ 2.0;
//  der(dp[14]) = (c ^ 2.0 * (p[15] + -2.0 * p[14] + p[13])) / dL ^ 2.0;
//  der(dp[15]) = (c ^ 2.0 * (p[16] + -2.0 * p[15] + p[14])) / dL ^ 2.0;
//  der(dp[16]) = (c ^ 2.0 * (p[17] + -2.0 * p[16] + p[15])) / dL ^ 2.0;
//  der(dp[17]) = (c ^ 2.0 * (p[18] + -2.0 * p[17] + p[16])) / dL ^ 2.0;
//  der(dp[18]) = (c ^ 2.0 * (p[19] + -2.0 * p[18] + p[17])) / dL ^ 2.0;
//  der(dp[19]) = (c ^ 2.0 * (p[20] + -2.0 * p[19] + p[18])) / dL ^ 2.0;
//  der(dp[20]) = (c ^ 2.0 * (p[21] + -2.0 * p[20] + p[19])) / dL ^ 2.0;
//  der(dp[21]) = (c ^ 2.0 * (p[22] + -2.0 * p[21] + p[20])) / dL ^ 2.0;
//  der(dp[22]) = (c ^ 2.0 * (p[23] + -2.0 * p[22] + p[21])) / dL ^ 2.0;
//  der(dp[23]) = (c ^ 2.0 * (p[24] + -2.0 * p[23] + p[22])) / dL ^ 2.0;
//  der(dp[24]) = (c ^ 2.0 * (p[25] + -2.0 * p[24] + p[23])) / dL ^ 2.0;
//  der(dp[25]) = (c ^ 2.0 * (p[26] + -2.0 * p[25] + p[24])) / dL ^ 2.0;
//  der(dp[26]) = (c ^ 2.0 * (p[27] + -2.0 * p[26] + p[25])) / dL ^ 2.0;
//  der(dp[27]) = (c ^ 2.0 * (p[28] + -2.0 * p[27] + p[26])) / dL ^ 2.0;
//  der(dp[28]) = (c ^ 2.0 * (p[29] + -2.0 * p[28] + p[27])) / dL ^ 2.0;
//  der(dp[29]) = (c ^ 2.0 * (p[30] + -2.0 * p[29] + p[28])) / dL ^ 2.0;
// end WaveEquationSample;
