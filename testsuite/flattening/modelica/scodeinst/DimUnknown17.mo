// name: DimUnknown17
// keywords:
// status: correct
//
//

function f
  input Real v[:];
  output Real z1[size(v, 1)] = v;
  output Integer z2[size(v, 1)] = 1:size(v, 1);
end f;

model DimUnknown17
  Real x[3];
  Real y[:] = f(x);
end DimUnknown17;

// Result:
// function f
//   input Real[:] v;
//   output Real[size(v, 1)] z1 = v;
//   output Integer[size(v, 1)] z2 = 1:size(v, 1);
// end f;
//
// class DimUnknown17
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   y = f(x)[1];
// end DimUnknown17;
// endResult
