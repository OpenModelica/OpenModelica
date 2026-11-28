// name: MergeComponents12
// keywords:
// status: correct
// teardown_command: rm MergeComponents12_merged_table.json
//
// Checks that components with identical redeclare modifiers are merged.
//

package P1
  constant Real c = 1.0;
end P1;

package P2
  constant Real c = 2.0;
end P2;

record R
  Real r = 1.0;
end R;

record R2
  extends R(r = 2.0);
end R2;

model A
  replaceable package P = P1;
  replaceable R rec;
  Real x;
equation
  x = P.c + rec.r;
end A;

model B
  Real y = 3.0;
end B;

model MergeComponents12
  B b1;
  B b2;
  A a1(redeclare package P = P2, redeclare R2 rec, x(start = 1.0));
  A a2(redeclare package P = P2, redeclare R2 rec, x(start = 2.0));
  A a3(redeclare package P = P1, redeclare R2 rec, x(start = 3.0));
  A a4(redeclare package P = P1, redeclare R2 rec, x(start = 4.0));
  A a5(redeclare package P = P1, redeclare R rec, x(start = 5.0));
  A a6(redeclare package P = P1, redeclare R rec(r = b2.y), x(start = 6.0));
  A a7(redeclare package P = P1, redeclare R rec(r = b2.y), x(start = 7.0));
  annotation(__OpenModelica_commandLineOptions="-d=mergeComponents");
end MergeComponents12;

// Result:
// class MergeComponents12
//   Real a5.rec.r = 1.0;
//   Real a5.x(start = 5.0);
//   Real $A1[1].rec.r = $B4[2].y;
//   Real $A1[1].x(start = 6.0);
//   Real $A1[2].rec.r = $B4[2].y;
//   Real $A1[2].x(start = 7.0);
//   Real $A2[1].rec.r = 2.0;
//   Real $A2[1].x(start = 3.0);
//   Real $A2[2].rec.r = 2.0;
//   Real $A2[2].x(start = 4.0);
//   Real $A3[1].rec.r = 2.0;
//   Real $A3[1].x(start = 1.0);
//   Real $A3[2].rec.r = 2.0;
//   Real $A3[2].x(start = 2.0);
//   Real $B4[1].y = 3.0;
//   Real $B4[2].y = 3.0;
// equation
//   a5.x = 1.0 + a5.rec.r;
//   $A1[1].x = 1.0 + $A1[1].rec.r;
//   $A1[2].x = 1.0 + $A1[2].rec.r;
//   $A2[1].x = 1.0 + $A2[1].rec.r;
//   $A2[2].x = 1.0 + $A2[2].rec.r;
//   $A3[1].x = 2.0 + $A3[1].rec.r;
//   $A3[2].x = 2.0 + $A3[2].rec.r;
// end MergeComponents12;
// endResult
