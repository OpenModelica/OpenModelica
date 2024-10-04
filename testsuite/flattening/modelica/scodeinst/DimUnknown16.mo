// name: DimUnknown16
// keywords:
// status: correct
//
//

function f
  input Integer nrow;
  input Integer ncol;
  output Real[nrow, ncol] matrix;
external "C" f(nrow, ncol, matrix);
end f;

impure function f2
  input Integer dummy;
  output Integer dim;
external "C" dim = strlen("aa");
end f2;

model DimUnknown16
  parameter Integer dummy = 0;
  parameter Integer dim = f2(dummy);
  parameter Real A[:, :] = f(dim, dim);
end DimUnknown16;

// Result:
// impure function f
//   input Integer nrow;
//   input Integer ncol;
//   output Real[nrow, ncol] matrix;
//
//   external "C" f(nrow, ncol, matrix);
// end f;
//
// class DimUnknown16
//   final parameter Integer dummy = 0;
//   final parameter Integer dim = 2;
//   parameter Real[2, 2] A = f(2, 2);
// end DimUnknown16;
// endResult
