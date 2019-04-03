// name:     HydrogenIodide
// keywords: der
// status:   correct
//
// <insert description here>
//

type Concentration = Real(final quantity ="Concentration",final unit = "mol/m3");

class HydrogenIodide
parameter Real k1 = 0.73;
parameter Real k2 = 0.04;
Concentration H2(start=5);
Concentration I2(start=8);
Concentration HI(start=0);
equation
der(H2) = k2*HI^2 - k1*H2*I2;
der(I2) = k2*HI^2 - k1*H2*I2;
der(HI) = 2*k1*H2*I2 - 2*k2*HI^2;
end HydrogenIodide;

// Result:
// class HydrogenIodide
//   parameter Real k1 = 0.73;
//   parameter Real k2 = 0.04;
//   Real H2(quantity = "Concentration", unit = "mol/m3", start = 5.0);
//   Real I2(quantity = "Concentration", unit = "mol/m3", start = 8.0);
//   Real HI(quantity = "Concentration", unit = "mol/m3", start = 0.0);
// equation
//   der(H2) = k2 * HI ^ 2.0 - k1 * H2 * I2;
//   der(I2) = k2 * HI ^ 2.0 - k1 * H2 * I2;
//   der(HI) = 2.0 * (k1 * H2 * I2 - k2 * HI ^ 2.0);
// end HydrogenIodide;
// endResult
