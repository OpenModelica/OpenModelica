// name:     LotkaVolterra
// keywords: der
// status:   correct
//
// <insert description here>
//

class LotkaVolterra
  parameter Real g_r =0.04 "Natural growth rate for rabbits";
  parameter Real d_rf=0.0005 "Death rate of rabbits due to foxes";
  parameter Real d_f =0.09 "Natural deathrate for foxes";
  parameter Real g_fr=0.1 "Efficency in growing foxes from rabbits";
  Real rabbits(start=700) "Rabbits,(R) with start population 700";
  Real foxes(start=10) "Foxes,(F) with start population 10";
equation
  der(rabbits) = g_r*rabbits - d_rf*rabbits*foxes;
  der(foxes) = g_fr*d_rf*rabbits*foxes -d_f*foxes;
end LotkaVolterra;


// Result:
// class LotkaVolterra
//   parameter Real g_r = 0.04 "Natural growth rate for rabbits";
//   parameter Real d_rf = 5e-4 "Death rate of rabbits due to foxes";
//   parameter Real d_f = 0.09 "Natural deathrate for foxes";
//   parameter Real g_fr = 0.1 "Efficency in growing foxes from rabbits";
//   Real rabbits(start = 700.0) "Rabbits,(R) with start population 700";
//   Real foxes(start = 10.0) "Foxes,(F) with start population 10";
// equation
//   der(rabbits) = g_r * rabbits - d_rf * rabbits * foxes;
//   der(foxes) = g_fr * d_rf * rabbits * foxes - d_f * foxes;
// end LotkaVolterra;
// [flattening/modelica/equations/LotkaVolterra.mo:9:3-9:61:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/LotkaVolterra.mo:10:3-10:66:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/LotkaVolterra.mo:11:3-11:57:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/LotkaVolterra.mo:12:3-12:68:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/LotkaVolterra.mo:13:3-13:66:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/LotkaVolterra.mo:14:3-14:60:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/LotkaVolterra.mo:16:3-16:50:writable] Warning: Equation sections are deprecated in class.
//
// endResult
