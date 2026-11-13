// name:     FilterBlock1
// keywords: initial, reinit
// status:   correct
//
// First order filter block
// Drmodelica: 9.1 reinit (p. 296)
// adrpo: reinit is not allowed in when initial(), using assingment instead!
// lochel: it is not possible to replace or even convert a reinit to an assignment! Use initial equation/algorithm instead!

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
  x := u; // if x is u since der(x) = (u - x)/T
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
// end FilterBlock1;
// endResult
