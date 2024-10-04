// name: FuncUnknownDim3
// keywords:
// status: correct
//

function f
  input Real[n] v;
  output Real[n] result = fill(1.0, n);
protected
  Integer n = size(v, 1);
end f;

model FuncUnknownDim3
  Real x[2] = f({time, 1});
end FuncUnknownDim3;

// Result:
// function f
//   input Real[n] v;
//   output Real[n] result = fill(1.0, n);
//   protected Integer n = size(v, 1);
// end f;
//
// class FuncUnknownDim3
//   Real x[1];
//   Real x[2];
// equation
//   x = f({time, 1.0});
// end FuncUnknownDim3;
// endResult
