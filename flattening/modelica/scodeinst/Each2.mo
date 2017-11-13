// name: Each2
// keywords:
// status: correct
// cflags: -d=newInst
//

model Each2
  type MyReal = Real[3];
  MyReal r(each start = 1.0);
end Each2;

// Result:
// class Each2
//   Real r[1](start = 1.0);
//   Real r[2](start = 1.0);
//   Real r[3](start = 1.0);
// end Each2;
// endResult
