// name: FuncUnknownDim2
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Integer n;
  output Real x[:];
algorithm
  x := ones(n);
end f;

model FuncUnknownDim2
  Real x[3] = f(3);
end FuncUnknownDim2; 

// Result:
// function f
//   input Integer n;
//   output Real[:] x;
// algorithm
//   x := /*Real[n]*/(ones(n));
// end f;
//
// class FuncUnknownDim2
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = f(3);
// end FuncUnknownDim2;
// endResult
