// name: RecordBinding5
// keywords:
// status: correct
//

record R1
  Real [:, :] table;
end R1;

record R2
  R1 r1_table[:];
end R2;

record R3
  R2 r2_table[:];
end R3;

model RecordBinding5
  parameter R1 r1(table = {{1, 2, 3}, {4, 5, 6}});
  parameter R2 r2(r1_table = {r1});
  parameter R3 r3(r2_table = {r2});
end RecordBinding5;

// Result:
// class RecordBinding5
//   parameter Real r1.table[1,1] = 1.0;
//   parameter Real r1.table[1,2] = 2.0;
//   parameter Real r1.table[1,3] = 3.0;
//   parameter Real r1.table[2,1] = 4.0;
//   parameter Real r1.table[2,2] = 5.0;
//   parameter Real r1.table[2,3] = 6.0;
//   parameter Real r2.r1_table[1].table[1,1] = r1.table[1,1];
//   parameter Real r2.r1_table[1].table[1,2] = r1.table[1,2];
//   parameter Real r2.r1_table[1].table[1,3] = r1.table[1,3];
//   parameter Real r2.r1_table[1].table[2,1] = r1.table[2,1];
//   parameter Real r2.r1_table[1].table[2,2] = r1.table[2,2];
//   parameter Real r2.r1_table[1].table[2,3] = r1.table[2,3];
//   parameter Real r3.r2_table[1].r1_table[1].table[1,1] = r2.r1_table[1].table[1,1];
//   parameter Real r3.r2_table[1].r1_table[1].table[1,2] = r2.r1_table[1].table[1,2];
//   parameter Real r3.r2_table[1].r1_table[1].table[1,3] = r2.r1_table[1].table[1,3];
//   parameter Real r3.r2_table[1].r1_table[1].table[2,1] = r2.r1_table[1].table[2,1];
//   parameter Real r3.r2_table[1].r1_table[1].table[2,2] = r2.r1_table[1].table[2,2];
//   parameter Real r3.r2_table[1].r1_table[1].table[2,3] = r2.r1_table[1].table[2,3];
// end RecordBinding5;
// endResult
