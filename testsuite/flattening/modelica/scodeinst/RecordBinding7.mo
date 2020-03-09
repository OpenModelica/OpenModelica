// name: RecordBinding7
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
  constant Real y = x / 2.0;
  Real z;
end R;

model RecordBinding7
  constant R r = R(1.0, 3.0);
  constant Real x = r.x;
  constant Real y = r.y;
  constant Real z = r.z;
end RecordBinding7;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   protected Real y = 2.0;
//   input Real z;
//   output R res;
// end R;
//
// class RecordBinding7
//   Real r.x;
//   constant Real r.y = 2.0;
//   Real r.z;
// algorithm
//   r := R(1.0, 3.0);
// end RecordBinding7;
// endResult
