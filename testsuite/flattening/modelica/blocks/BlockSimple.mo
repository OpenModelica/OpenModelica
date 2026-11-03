// name: BlockSimple
// keywords: block
// status: correct
//
// Tests simple block declaration and instantiation
//

block TestBlock
end TestBlock;

model BlockSimple
  TestBlock tb;
end BlockSimple;

// Result:
// class BlockSimple
// end BlockSimple;
// endResult
