// status: correct

model BooleanEnumDims
  type E = enumeration(False,True);
  Real r[Boolean,E];
equation
  r[false,E.False] = 1.5;
  r[false,E.True] = 1.5;
  r[true,E.False] = 3.5;
  r[true,E.True] = 4.5;
end BooleanEnumDims;
// Result:
// class BooleanEnumDims
//   Real r[false,E.False];
//   Real r[false,E.True];
//   Real r[true,E.False];
//   Real r[true,E.True];
// equation
//   r[false,E.False] = 1.5;
//   r[false,E.True] = 1.5;
//   r[true,E.False] = 3.5;
//   r[true,E.True] = 4.5;
// end BooleanEnumDims;
// endResult
