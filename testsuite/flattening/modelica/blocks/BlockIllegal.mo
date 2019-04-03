// name: BlockIllegal
// keywords: block
// status: correct
//
// Tests block connections of non-directional components
// THIS TEST SHOULD FAIL
//

block TestBlock
  Integer i;
end TestBlock;

model BlockIllegal
  TestBlock tb1,tb2;
equation
  tb1.i = 1;
  connect(tb1.i,tb2.i);
end BlockIllegal;

// Result:
// class BlockIllegal
//   Integer tb1.i;
//   Integer tb2.i;
// equation
//   tb1.i = 1;
//   tb1.i = tb2.i;
// end BlockIllegal;
// endResult
