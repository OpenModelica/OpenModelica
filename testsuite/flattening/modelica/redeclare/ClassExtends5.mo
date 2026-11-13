// name: ClassExtends4
// keywords: class, extends
// status: correct
//
// Checks that repeated class extends are handled correctly.
//

model P1
  replaceable model C Real r1; end C;
  C c1;
end P1;

model P2
  extends P1;
  redeclare replaceable model extends C Real r2; end C;
  C c2;
end P2;

model P3
  extends P2;
  redeclare model extends C Real r3; end C;

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
// endResult
