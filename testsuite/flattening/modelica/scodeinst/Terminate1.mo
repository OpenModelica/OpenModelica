// name: Terminate1
// keywords:
// status: correct
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
