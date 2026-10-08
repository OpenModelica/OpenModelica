// name: FuncViaComp5
// keywords:
// status: correct
//
// Checks that the default arguments of a function called via a component
// in an array of components refer to the right element also when the
// default refers to a component between the array and the function.
//

function f
  input Real x;
  input Real k = 0;
  output Real y = k * x;
end f;

model Sub
  function g = f;
end Sub;

model Obj
  parameter Real kk = 1;
  Sub sub(g(k = kk));
end Obj;

model Cell
  parameter Real k = 1;
  Obj obj(kk = k);
  Real y = obj.sub.g(time);
end Cell;

model FuncViaComp5
  Cell cell[2](k = {1, 2});
end FuncViaComp5;

// Result:
// function FuncViaComp5.cell.obj.sub.g
//   input Real x;
//   input Real k = 1.0;
//   output Real y = k * x;
// end FuncViaComp5.cell.obj.sub.g;
//
// class FuncViaComp5
//   parameter Real cell[1].k = 1.0;
//   parameter Real cell[1].obj.kk = cell[1].k;
//   Real cell[1].y = FuncViaComp5.cell.obj.sub.g(time, cell[1].obj.kk);
//   parameter Real cell[2].k = 2.0;
//   parameter Real cell[2].obj.kk = cell[2].k;
//   Real cell[2].y = FuncViaComp5.cell.obj.sub.g(time, cell[2].obj.kk);
// end FuncViaComp5;
// endResult
