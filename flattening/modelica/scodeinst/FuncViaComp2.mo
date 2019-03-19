// name: FuncViaComp2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y = x;
end f;

model M
  Real mx;
  function mf = f(x = mx);
  Real my = mf();
end M;

model FuncViaComp2
  M m;
  M m2;
end FuncViaComp2;

// Result:
// function FuncViaComp2.m.mf
//   input Real x = m.mx;
//   output Real y = x;
// end FuncViaComp2.m.mf;
//
// function FuncViaComp2.m2.mf
//   input Real x = m2.mx;
//   output Real y = x;
// end FuncViaComp2.m2.mf;
//
// class FuncViaComp2
//   Real m.mx;
//   Real m.my = FuncViaComp2.m.mf(m.mx);
//   Real m2.mx;
//   Real m2.my = FuncViaComp2.m2.mf(m2.mx);
// end FuncViaComp2;
// endResult
