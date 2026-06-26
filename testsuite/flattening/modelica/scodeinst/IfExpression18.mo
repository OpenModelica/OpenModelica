// name: IfExpression18
// keywords: if-expression start array
// status: correct
//
// Tests scalarization of a vector start value assigned with an if-expression
// with a non-constant condition. See
// https://github.com/OpenModelica/OpenModelica/issues/15937
//

model IfExpression18
  parameter Boolean useStart = true;
  parameter Real rot_start[3] = {0, 1, 0};
  Real rot[3](start = if useStart then rot_start else 2 * rot_start, each fixed = true);
equation
  der(rot) = -rot;
end IfExpression18;

// Result:
// class IfExpression18
//   parameter Boolean useStart = true;
//   parameter Real rot_start[1] = 0.0;
//   parameter Real rot_start[2] = 1.0;
//   parameter Real rot_start[3] = 0.0;
//   Real rot[1](start = if useStart then rot_start[1] else 2.0 * rot_start[1], fixed = true);
//   Real rot[2](start = if useStart then rot_start[2] else 2.0 * rot_start[2], fixed = true);
//   Real rot[3](start = if useStart then rot_start[3] else 2.0 * rot_start[3], fixed = true);
// equation
//   der(rot[1]) = -rot[1];
//   der(rot[2]) = -rot[2];
//   der(rot[3]) = -rot[3];
// end IfExpression18;
// endResult
