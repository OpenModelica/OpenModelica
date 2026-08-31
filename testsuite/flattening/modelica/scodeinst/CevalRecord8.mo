// name: CevalRecord8
// keywords:
// status: incorrect
//
// Checks that the division by zero error is shown when in a record.
//

record R
  parameter Real x[:];
end R;

record R2
  parameter Real x;
end R2;

function f
  input R r;
  output R2 r2;
algorithm
  r2.x := if max(r.x) < 0 then 0 else 1;
end f;

model CevalRecord8
  parameter R r(x = 1/0*{0, 1, 2});
  parameter R2 r2 = f(r) annotation(Evaluate=true);
end CevalRecord8;

// Result:
// Error processing file: CevalRecord8.mo
// [flattening/modelica/scodeinst/CevalRecord8.mo:24:17-24:34:writable] Notification: From here:
// [flattening/modelica/scodeinst/CevalRecord8.mo:20:3-20:40:writable] Error: Division by zero in 1.0 / 0.0
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
