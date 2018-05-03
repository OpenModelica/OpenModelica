// name: CevalFunc1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
algorithm
  y := x * 2;
end f;

model CevalFunc1
  constant Real x = f(3.0);
end CevalFunc1;

// Result:
// class CevalFunc1
//   constant Real x = 6.0;
// end CevalFunc1;
// endResult
