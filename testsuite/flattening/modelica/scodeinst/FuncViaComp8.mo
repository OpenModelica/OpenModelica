// name: FuncViaComp8
// keywords:
// status: correct
//
// Checks that a function called via an outer component whose inner is
// generated (no inner declared) gets its default arguments from the
// generated inner, like world.gravityAcceleration in MSL MultiBody.
//

function gravityTypes
  input Real r;
  input Real g0;
  input Real n0;
  output Real a = -g0 * r * n0;
end gravityTypes;

model World
  parameter Real g = 9.81;
  parameter Real n = 2;
  function gravity = gravityTypes(g0 = g, n0 = n);
end World;

model Fixed
  outer World world;
  Real a = world.gravity(time);
end Fixed;

model FuncViaComp8
  Fixed fixed;
end FuncViaComp8;

// Result:
// function FuncViaComp8.fixed.world.gravity
//   input Real r;
//   input Real g0 = 9.81;
//   input Real n0 = 2.0;
//   output Real a = -g0 * r * n0;
// end FuncViaComp8.fixed.world.gravity;
//
// class FuncViaComp8
//   Real fixed.a = FuncViaComp8.fixed.world.gravity(time, world.g, world.n);
//   parameter Real world.g = 9.81;
//   parameter Real world.n = 2.0;
// end FuncViaComp8;
// [flattening/modelica/scodeinst/FuncViaComp8.mo:24:3-24:20:writable] Warning: An inner declaration for outer component world could not be found and was automatically generated.
//
// endResult
