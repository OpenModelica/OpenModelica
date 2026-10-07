// name:     reinit
// keywords: reinit
// status:   correct
//
// using reinit in when initial() is not allowed, changed to assignment
//

block FilterBlock1
  parameter Real T = 1 "Time constant";
  parameter Real k = 1 "Gain";
  input Real u = 1;
  output Real y;
protected
  Real x;
equation
  der(x) = (u - x)/T;
  y = k*x;
initial algorithm
  x := u;
algorithm
  when time > 0 then
    reinit(x, u); // if x is u since der(x) = (u - x)/T
  end when;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end FilterBlock1;

// Result:
// class FilterBlock1
//   parameter Real T = 1.0 "Time constant";
//   parameter Real k = 1.0 "Gain";
//   input Real u = 1.0;
//   output Real y;
//   protected Real x;
// initial algorithm
//   x := u;
// equation
//   der(x) = (u - x) / T;
//   y = k * x;
// algorithm
//   when time > 0.0 then
//     reinit(x, u);
//   end when;
// end FilterBlock1;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
