// name: FuncWildcard
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that _ can be used as a function name, since the Modelica grammar
// actually allows that.
//

function _
  input Real x;
  output Real y;
algorithm
  y := x;
end _;

model FuncWildcard
  Real x = _(3.0);
end FuncWildcard;

// Result:
// class FuncWildcard
//   Real x = 3.0;
// end FuncWildcard;
// endResult
