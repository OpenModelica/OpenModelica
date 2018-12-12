// name: RecordConstructor1
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
end R;

model RecordConstructor1
  R r;
algorithm
  r := R(time);
end RecordConstructor1;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   output R res;
// end R;
//
// class RecordConstructor1
//   Real r.x;
// algorithm
//   r := R(time);
// end RecordConstructor1;
// endResult
