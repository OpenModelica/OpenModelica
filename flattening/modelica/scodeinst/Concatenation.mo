// status: correct
// cflags: -d=newInst

model Concatenation
  Real z[1,2] = [{{2}},{1.0}];
  Real z1[2,1,1] = [{{{2}}};{1.0}];
  Real r[2] = cat(1, {1}, {2});
end Concatenation;

// Result:
// class Concatenation
//   Real z[1,1];
//   Real z[1,2];
//   Real z1[1,1,1];
//   Real z1[2,1,1];
//   Real r[1];
//   Real r[2];
// equation
//   z = {{2.0, 1.0}};
//   z1 = {{{2.0}}, {{1.0}}};
//   r = {1.0, 2.0};
// end Concatenation;
// endResult
