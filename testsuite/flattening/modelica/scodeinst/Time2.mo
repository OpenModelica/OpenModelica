// name: Time2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = time;
end A;

model Time2
  A a;
end Time2;

// Result:
// class Time2
//   Real a.x = time;
// end Time2;
// endResult
