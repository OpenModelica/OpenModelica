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
//   der(HI) = 2.0 * k1 * H2 * I2 - 2.0 * k2 * HI ^ 2.0;
// end HydrogenIodide;
// [flattening/modelica/equations/HydrogenIodide.mo:11:1-11:25:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/HydrogenIodide.mo:12:1-12:25:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/HydrogenIodide.mo:13:1-13:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/HydrogenIodide.mo:14:1-14:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/HydrogenIodide.mo:15:1-15:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/HydrogenIodide.mo:17:1-17:29:writable] Warning: Equation sections are deprecated in class.
//
// endResult
