// name: ClassExtends4
// keywords: class, extends
// status: correct
//
// Checks that repeated class extends are handled correctly.
//

class P1
  replaceable class C Real r1; end C;
  C c1;
end P1;

class P2
  extends P1;
  redeclare replaceable class extends C Real r2; end C;
  C c2;
end P2;

class P3
  extends P2;
  redeclare class extends C Real r3; end C;

  C c3;
end P3;

// Result:
// class P3
//   Real c1.r1;
//   Real c1.r2;
//   Real c1.r3;
//   Real c2.r1;
//   Real c2.r2;
//   Real c2.r3;
//   Real c3.r1;
//   Real c3.r2;
//   Real c3.r3;
// end P3;
// [flattening/modelica/redeclare/ClassExtends5.mo:21:29-21:36:writable] Warning: Components are deprecated in class.
// [flattening/modelica/redeclare/ClassExtends5.mo:23:3-23:7:writable] Warning: Components are deprecated in class.
//
// endResult
