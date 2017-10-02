// name: Assert2
// keywords:
// status: correct
// cflags: -d=newInst
//

model Assert2
  Boolean b;
  String s;
equation
  assert(b, s);
end Assert2;

// Result:
// class Assert2
//   Boolean b;
//   String s;
// equation
//   assert(b, s);
// end Assert2;
// endResult
