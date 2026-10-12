// name: FuncViaComp7
// keywords:
// status: correct
//
// Checks that a function called via a component from an inherited equation,
// with arguments that refer to components of the extending class, works in an
// array of components.
//

function f
  input Real x;
  input Real k;
  output Real y = k * x;
end f;

model Obj
  parameter Real k = 1;
  function g = f(final k = k);
end Obj;

partial model Base
  parameter Real k = 1;
  Obj obj(k = k);
  Real x;
  Real y;
equation
  y = obj.g(x);
end Base;

model Cell
  extends Base;
equation
  x = time;
end Cell;

model FuncViaComp7
  Cell cell[2](k = {1, 2});
end FuncViaComp7;

// Result:
// function FuncViaComp7.cell.obj.g
//   input Real x;
//   final input Real k = 1.0;
//   output Real y = k * x;
// end FuncViaComp7.cell.obj.g;
//
// class FuncViaComp7
//   parameter Real cell[1].k = 1.0;
//   parameter Real cell[1].obj.k = cell[1].k;
//   Real cell[1].x;
//   Real cell[1].y;
//   parameter Real cell[2].k = 2.0;
//   parameter Real cell[2].obj.k = cell[2].k;
//   Real cell[2].x;
//   Real cell[2].y;
// equation
//   cell[1].x = time;
//   cell[1].y = FuncViaComp7.cell.obj.g(cell[1].x, cell[1].obj.k);
//   cell[2].x = time;
//   cell[2].y = FuncViaComp7.cell.obj.g(cell[2].x, cell[2].obj.k);
// end FuncViaComp7;
// endResult
