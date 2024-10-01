// name: RecordConstructor2
// keywords:
// status: correct
//
// Checks that final components in a record becomes protected in the default
// constructor.
//

record R
  Real x;
  final constant Real y = 1.0;
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
//   final constant Real r.y = 1.0;
// algorithm
//   r := R(time, 1.0);
// end RecordConstructor2;
// endResult
