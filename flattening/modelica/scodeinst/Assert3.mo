// name: Assert3
// keywords:
// status: correct
// cflags: -d=newInst
//

model Assert3
equation
  assert(false, "message", AssertionLevel.warning);
end Assert3;

// Result:
// class Assert3
// equation
//   assert(false, "message", AssertionLevel.warning);
// end Assert3;
// endResult
