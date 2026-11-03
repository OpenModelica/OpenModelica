// name: RangeSlicing
// keywords: array range slicing subscript
// status: correct
//
// Tests array slicing with range subscripts.
//

model RangeSlicing
  constant Real ra[10] = {i for i in 1:10};
  constant Real rs1[:] = ra[1:10];
  constant Real rs2[:] = ra[1:2:10];
  constant Real rs3[:] = ra[3:-1:1];
  constant Real rs4[:] = ra[3:1];
  constant Real rs5[:] = ra[2:2];
  constant Real rs6[:] = ra[4:end];
  constant Real rs7[:] = ra[end:-4:2];

  constant Real ba[Boolean] = {1.0, 2.0};
  constant Real bs1[:] = ba[true:false];
  constant Real bs2[:] = ba[false:true];
  constant Real bs3[:] = ba[true:true];
  constant Real bs4[:] = ba[false:false];

  type E = enumeration(one, two, three, four);
  constant Real ea[E] = {1.0, 2.0, 3.0, 4.0};
  constant Real es1[:] = ea[E.one:E.four];
  constant Real es2[:] = ea[E.two:E.three];
end RangeSlicing;

// Result:
// class RangeSlicing
//   constant Real ra[1] = 1.0;
//   constant Real ra[2] = 2.0;
//   constant Real ra[3] = 3.0;
//   constant Real ra[4] = 4.0;
//   constant Real ra[5] = 5.0;
//   constant Real ra[6] = 6.0;
//   constant Real ra[7] = 7.0;
//   constant Real ra[8] = 8.0;
//   constant Real ra[9] = 9.0;
//   constant Real ra[10] = 10.0;
//   constant Real rs1[1] = 1.0;
//   constant Real rs1[2] = 2.0;
//   constant Real rs1[3] = 3.0;
//   constant Real rs1[4] = 4.0;
//   constant Real rs1[5] = 5.0;
//   constant Real rs1[6] = 6.0;
//   constant Real rs1[7] = 7.0;
//   constant Real rs1[8] = 8.0;
//   constant Real rs1[9] = 9.0;
//   constant Real rs1[10] = 10.0;
//   constant Real rs2[1] = 1.0;
//   constant Real rs2[2] = 3.0;
//   constant Real rs2[3] = 5.0;
//   constant Real rs2[4] = 7.0;
//   constant Real rs2[5] = 9.0;
//   constant Real rs3[1] = 3.0;
//   constant Real rs3[2] = 2.0;
//   constant Real rs3[3] = 1.0;
//   constant Real rs5[1] = 2.0;
//   constant Real rs6[1] = 4.0;
//   constant Real rs6[2] = 5.0;
//   constant Real rs6[3] = 6.0;
//   constant Real rs6[4] = 7.0;
//   constant Real rs6[5] = 8.0;
//   constant Real rs6[6] = 9.0;
//   constant Real rs6[7] = 10.0;
//   constant Real rs7[1] = 10.0;
//   constant Real rs7[2] = 6.0;
//   constant Real rs7[3] = 2.0;
//   constant Real ba[false] = 1.0;
//   constant Real ba[true] = 2.0;
//   constant Real bs2[1] = 1.0;
//   constant Real bs2[2] = 2.0;
//   constant Real bs3[1] = 2.0;
//   constant Real bs4[1] = 1.0;
//   constant Real ea[E.one] = 1.0;
//   constant Real ea[E.two] = 2.0;
//   constant Real ea[E.three] = 3.0;
//   constant Real ea[E.four] = 4.0;
//   constant Real es1[1] = 1.0;
//   constant Real es1[2] = 2.0;
//   constant Real es1[3] = 3.0;
//   constant Real es1[4] = 4.0;
//   constant Real es2[1] = 2.0;
//   constant Real es2[2] = 3.0;
// end RangeSlicing;
// endResult
