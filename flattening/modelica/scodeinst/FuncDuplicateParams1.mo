// name: FuncDuplicateParams1
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that duplicate elements are handled correctly in functions.
//

function f1
  input Real x;
  output Real y;
end f1;

function f2
  input Real x;
  output Real y;
end f2;

function f
  extends f1;
  extends f2;
algorithm
  y := x; 
end f;

model FuncDuplicateParams1
  constant Real x = f(1.0);
end FuncDuplicateParams1;

// Result:
// class FuncDuplicateParams1
//   constant Real x = 1.0;
// end FuncDuplicateParams1;
// endResult
