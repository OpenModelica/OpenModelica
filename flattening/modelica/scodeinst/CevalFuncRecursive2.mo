// name: CevalFuncRecursive2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
algorithm
  y := f(x + 1);
end f;

model CevalFuncRecursive2
  constant Real x = f(3.0);
end CevalFuncRecursive2;

// Result:
// function f
//   input Real x;
//   output Real y;
// algorithm
//   y := f(x + 1.0);
// end f;
//
// class CevalFuncRecursive2
//   constant Real x = f(3.0);
// end CevalFuncRecursive2;
// [flattening/modelica/scodeinst/CevalFuncRecursive2.mo:8:1-13:6:writable] Error: The recursion limit (--evalRecursionLimit=256) was exceeded during evaluation of f.
//
// endResult
