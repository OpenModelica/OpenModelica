// name: FuncViaComp6
// keywords:
// status: correct
//
// Checks that the default arguments of a function called via a component
// in nested arrays of components with different sizes refer to the right
// elements.
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

model HX
  parameter Integer n = 1;
  parameter Real base = 0;
  Cell cell[n](k = {base + i for i in 1:n});
end HX;

model FuncViaComp6
  HX hx[2](n = {1, 2}, base = {10, 20});
end FuncViaComp6;

// Result:
// function FuncViaComp6.hx.cell.obj.g
//   input Real x;
//   final input Real k = 11.0;
//   output Real y = k * x;
// end FuncViaComp6.hx.cell.obj.g;
//
// class FuncViaComp6
//   final parameter Integer hx[1].n = 1;
//   parameter Real hx[1].base = 10.0;
//   parameter Real hx[1].cell[1].k = hx[1].base + 1.0;
//   parameter Real hx[1].cell[1].obj.k = hx[1].cell[1].k;
//   Real hx[1].cell[1].y = FuncViaComp6.hx.cell.obj.g(time, hx[1].cell[1].obj.k);
//   final parameter Integer hx[2].n = 2;
//   parameter Real hx[2].base = 20.0;
//   parameter Real hx[2].cell[1].k = hx[2].base + 1.0;
//   parameter Real hx[2].cell[1].obj.k = hx[2].cell[1].k;
//   Real hx[2].cell[1].y = FuncViaComp6.hx.cell.obj.g(time, hx[2].cell[1].obj.k);
//   parameter Real hx[2].cell[2].k = hx[2].base + 2.0;
//   parameter Real hx[2].cell[2].obj.k = hx[2].cell[2].k;
//   Real hx[2].cell[2].y = FuncViaComp6.hx.cell.obj.g(time, hx[2].cell[2].obj.k);
// end FuncViaComp6;
// endResult
