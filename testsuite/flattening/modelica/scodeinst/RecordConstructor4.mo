// name: RecordConstructor4
// keywords:
// status: correct
//
//

record R
  parameter Real x(start = 1.0);
end R;

model RecordConstructor4
  R r;
equation
  r = R(time);
end RecordConstructor4;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   output R res;
// end R;
//
// class RecordConstructor4
//   parameter Real r.x(start = 1.0);
// equation
//   r = R(time);
// end RecordConstructor4;
// [flattening/modelica/scodeinst/RecordConstructor4.mo:8:3-8:32:writable] Warning: Parameter r.x has no value, and is fixed during initialization (fixed=true), using available start value (start=1.0) as default value.
//
// endResult
