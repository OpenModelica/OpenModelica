// name: NonfixedParamSubscript
// keywords: parameter fixed subscript
// status: correct
//
// Tests non-fixed parameters as subscripts.
//

model M
  parameter Integer p(fixed=false,min=1,max=1);
  Real r[1];
initial equation
  p = 1;
equation
  r[p] = 2.0;
end M;

// Result:
// class M
//   parameter Integer p(min = 1, max = 1, fixed = false);
//   Real r[1];
// initial equation
//   p = 1;
// equation
//   r[p] = 2.0;
// end M;
// endResult
