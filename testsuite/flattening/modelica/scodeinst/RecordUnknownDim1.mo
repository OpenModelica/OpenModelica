// name: RecordUnknownDim1
// keywords:
// status: correct
//
//

record R2
  Integer i[:];
end R2;

record R
  R2 r;
end R;

function f
  output R2 r;
algorithm
  r := R2({1, 2});
end f;

model RecordUnknownDim1
  R r = R(f());
end RecordUnknownDim1;

// Result:
// class RecordUnknownDim1
//   Integer r.r.i[1];
//   Integer r.r.i[2];
// equation
//   r.r.i = {1, 2};
// end RecordUnknownDim1;
// endResult
