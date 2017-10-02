// name: Assert1
// keywords:
// status: correct
// cflags: -d=newInst
//

model Assert1
equation
  assert(false, "test");
end Assert1;

// Result:
// class Assert1
// equation
//   assert(false, "test");
// end Assert1;
// endResult
