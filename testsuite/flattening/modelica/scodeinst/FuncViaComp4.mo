// name: FuncViaComp4
// keywords:
// status: correct
//
// Checks that the default arguments of a function called via a component
// in an array of components refer to the right element of the array.
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

model Cell
  parameter Real k = 1;
  Obj obj(k = k);
  Real y = obj.g(time);
end Cell;

model FuncViaComp4
  Cell cell[3](k = {1, 2, 3});
end FuncViaComp4;

// Result:
// function FuncViaComp4.cell.obj.g
//   input Real x;
//   final input Real k = 1.0;
//   output Real y = k * x;
// end FuncViaComp4.cell.obj.g;
//
// class FuncViaComp4
//   parameter Real cell[1].k = 1.0;
//   parameter Real cell[1].obj.k = cell[1].k;
//   Real cell[1].y = FuncViaComp4.cell.obj.g(time, cell[1].obj.k);
//   parameter Real cell[2].k = 2.0;
//   parameter Real cell[2].obj.k = cell[2].k;
//   Real cell[2].y = FuncViaComp4.cell.obj.g(time, cell[2].obj.k);
//   parameter Real cell[3].k = 3.0;
//   parameter Real cell[3].obj.k = cell[3].k;
//   Real cell[3].y = FuncViaComp4.cell.obj.g(time, cell[3].obj.k);
// end FuncViaComp4;
// endResult
