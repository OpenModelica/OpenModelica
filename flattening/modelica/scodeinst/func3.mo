// name: func3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


function _
  input Real x;
  output Real y;
algorithm
  y := x;
end _;

model A
  Real x = _(3.0);
end A;

// Result:
// function _
//   input Real x;
//   output Real y;
// algorithm
//   y := x;
// end _;
//
// class A
//   Real x = _(3.0);
// end A;
// endResult
