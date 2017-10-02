// name: Terminate1
// keywords:
// status: correct
// cflags: -d=newInst
//

model Terminate1
equation
  terminate("test");
end Terminate1;

// Result:
// class Terminate1
// equation
//   terminate("test");
// end Terminate1;
// endResult
