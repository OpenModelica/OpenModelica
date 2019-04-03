// name: RecordConstructor2
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that constants in a record becomes protected in the default
// constructor.
//

record R
  Real x;
  constant Real y = 1.0;
end R;

model RecordConstructor2
  R r;
algorithm
  r := R(time);
end RecordConstructor2;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   protected Real y = 1.0;
//   output R res;
// end R;
//
// class RecordConstructor2
//   Real r.x;
//   constant Real r.y = 1.0;
// algorithm
//   r := R(time);
// end RecordConstructor2;
// endResult
