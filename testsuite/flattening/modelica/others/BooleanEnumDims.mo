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
//   Real r[false,BooleanEnumDims.E.False];
//   Real r[false,BooleanEnumDims.E.True];
//   Real r[true,BooleanEnumDims.E.False];
//   Real r[true,BooleanEnumDims.E.True];
// equation
//   r[false,BooleanEnumDims.E.False] = 1.5;
//   r[false,BooleanEnumDims.E.True] = 1.5;
//   r[true,BooleanEnumDims.E.False] = 3.5;
//   r[true,BooleanEnumDims.E.True] = 4.5;
// end BooleanEnumDims;
// endResult
