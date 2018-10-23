// name: FuncUnknownDim1
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real x[:];
end f;

model FuncUnknownDim1
  Real x[3];
equation
  f(x);
end FuncUnknownDim1; 

// Result:
// function f
//   input Real[:] x;
// end f;
//
// class FuncUnknownDim1
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   f(x);
// end FuncUnknownDim1;
// endResult
