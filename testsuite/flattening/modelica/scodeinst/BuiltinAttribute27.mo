// name: BuiltinAttribute27
// keywords:
// status: correct
//

model BuiltinAttribute27
  parameter Boolean useStart=true;
  parameter Real rot_start[3]={0,1,0};
  Real rot[3](start=if useStart then rot_start else 2*rot_start);
equation
  der(rot) = -rot;
end BuiltinAttribute27;

// Result:
// class BuiltinAttribute27
//   parameter Boolean useStart = true;
//   parameter Real rot_start[1] = 0.0;
//   parameter Real rot_start[2] = 1.0;
//   parameter Real rot_start[3] = 0.0;
//   Real rot[1](start = if useStart then rot_start[1] else 2.0 * rot_start[1]);
//   Real rot[2](start = if useStart then rot_start[2] else 2.0 * rot_start[2]);
//   Real rot[3](start = if useStart then rot_start[3] else 2.0 * rot_start[3]);
// equation
//   der(rot[1]) = -rot[1];
//   der(rot[2]) = -rot[2];
//   der(rot[3]) = -rot[3];
// end BuiltinAttribute27;
// endResult
