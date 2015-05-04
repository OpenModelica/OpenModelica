// name:     StructuralParameter1
// keywords: parameter, array
// status:   correct
//
// This is a test of structural parameters. A structural parameter is a
// parameter that affects the structure of the model, i.e. used in array
// dimensions of components.
//

model StructuralParam
  parameter Integer m=n;

  parameter Integer n=1;
   Real x[m],y[m];
equation
x=y;
end StructuralParam;

// Result:
// class StructuralParam
//   parameter Integer m = n;
//   parameter Integer n = 1;
//   Real x[1];
//   Real y[1];
// equation
//   x[1] = y[1];
// end StructuralParam;
// endResult
