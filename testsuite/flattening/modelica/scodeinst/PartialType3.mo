// name: PartialType3
// keywords:
// status: correct
//

partial model A
  Real x;
end A;

model B
  extends A;
end B;

model PartialType3
  B b;
end PartialType3;

// Result:
// class PartialType3
//   Real b.x;
// end PartialType3;
// endResult
