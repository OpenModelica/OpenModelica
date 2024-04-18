// name: InnerOuterConnect1
// keywords:
// status: correct
// cflags: -d=newInst
//

connector RealOutput = output Real;
connector RealInput = input Real;

model A
  RealOutput x;
  RealOutput y;
equation
  connect(x, y);
end A;

model B
  A a;
end B;

model C
  outer B b;
end C;

model InnerOuterConnect1
  C c;
end InnerOuterConnect1;

// Result:
// class InnerOuterConnect1
//   Real b.a.x;
//   Real b.a.y;
// equation
//   b.a.x = b.a.y;
// end InnerOuterConnect1;
// [flattening/modelica/scodeinst/InnerOuterConnect1.mo:22:3-22:12:writable] Warning: An inner declaration for outer component b could not be found and was automatically generated.
//
// endResult
