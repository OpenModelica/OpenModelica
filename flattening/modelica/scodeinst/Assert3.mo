// name: Assert3
// keywords:
// status: correct
// cflags: -d=newInst
//

model Assert3
equation
  assert(time > 2, "message", AssertionLevel.warning);
end Assert3;

// Result:
// class Assert3
// equation
//   assert(time > 2, "message", AssertionLevel.warning);
// end Assert3;
// endResult
