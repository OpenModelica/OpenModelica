// name: CevalAdd1
// keywords:
// status: correct
// cflags: -d=newInst
//

model CevalAdd1
  constant Integer i1 = 1 + 2;
  constant Integer i2[:] = {1, 2, 3} + {3, 4, 5};
  constant Integer i3[:, :] = {{1, 2}, {3, 4}} + {{5, 6}, {7, 8}};
  constant Integer i4[:] = 1 .+ {1, 2, 3};
  constant Integer i5[:] = {1, 2, 3} .+ 1;

  constant Real r1 = 1 + 2;
  constant Real r2[:] = {1, 2, 3} + {3, 4, 5};
  constant Real r3[:, :] = {{1, 2}, {3, 4}} + {{5, 6}, {7, 8}};
  constant Real r4[:] = 1 .+ {1, 2, 3};
  constant Real r5[:] = {1, 2, 3} .+ 1;

  constant String s1 = "1" + "2";
  constant String s2[:] = {"1", "2", "3"} + {"4", "5", "6"};
  constant String s3[:, :] = {{"1", "2"}, {"3", "4"}} + {{"5", "6"}, {"7", "8"}};
  constant String s4[:] = "1" .+ {"1", "2", "3"};
  constant String s5[:] = {"1", "2", "3"} .+ "1";
end CevalAdd1;

// Result:
// class CevalAdd1
//   constant Integer i1 = 3;
//   constant Integer i2[1] = 4;
//   constant Integer i2[2] = 6;
//   constant Integer i2[3] = 8;
//   constant Integer i3[1,1] = 6;
//   constant Integer i3[1,2] = 8;
//   constant Integer i3[2,1] = 10;
//   constant Integer i3[2,2] = 12;
//   constant Integer i4[1] = 2;
//   constant Integer i4[2] = 3;
//   constant Integer i4[3] = 4;
//   constant Integer i5[1] = 2;
//   constant Integer i5[2] = 3;
//   constant Integer i5[3] = 4;
//   constant Real r1 = 3.0;
//   constant Real r2[1] = 4.0;
//   constant Real r2[2] = 6.0;
//   constant Real r2[3] = 8.0;
//   constant Real r3[1,1] = 6.0;
//   constant Real r3[1,2] = 8.0;
//   constant Real r3[2,1] = 10.0;
//   constant Real r3[2,2] = 12.0;
//   constant Real r4[1] = 2.0;
//   constant Real r4[2] = 3.0;
//   constant Real r4[3] = 4.0;
//   constant Real r5[1] = 2.0;
//   constant Real r5[2] = 3.0;
//   constant Real r5[3] = 4.0;
//   constant String s1 = "12";
//   constant String s2[1] = "14";
//   constant String s2[2] = "25";
//   constant String s2[3] = "36";
//   constant String s3[1,1] = "15";
//   constant String s3[1,2] = "26";
//   constant String s3[2,1] = "37";
//   constant String s3[2,2] = "48";
//   constant String s4[1] = "11";
//   constant String s4[2] = "12";
//   constant String s4[3] = "13";
//   constant String s5[1] = "11";
//   constant String s5[2] = "21";
//   constant String s5[3] = "31";
// end CevalAdd1;
// endResult
