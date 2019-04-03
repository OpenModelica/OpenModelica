// name: ceval3.mo
// status: correct
// cflags: -d=newInst

model A
  Real x(start=2.0, fixed=init_x);
  parameter Boolean init_x = p1 or p2;
  parameter Boolean p1 = false;
  parameter Boolean p2 = true;
equation
  der(x) = -1;
end A;

// Result:
// class A
//   Real x(start = 2.0, fixed = true);
//   parameter Boolean init_x = true;
//   parameter Boolean p1 = false;
//   parameter Boolean p2 = true;
// equation
//   der(x) = -1.0;
// end A;
// endResult
