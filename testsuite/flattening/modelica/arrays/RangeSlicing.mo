// name: RangeSlicing
// keywords: array range slicing subscript
// status: correct
//
// Tests array slicing with range subscripts.
//

model RangeSlicing
  Real ra[10] = {i for i in 1:10};
  Real rs1[:] = ra[1:10];
  Real rs2[:] = ra[1:2:10];
  Real rs3[:] = ra[3:-1:1];
  Real rs4[:] = ra[3:1];
  Real rs5[:] = ra[2:2];
  Real rs6[:] = ra[4:end];
  Real rs7[:] = ra[end:-4:2];

  Real ba[Boolean] = {1.0, 2.0};
  Real bs1[:] = ba[true:false];
  Real bs2[:] = ba[false:true];
  Real bs3[:] = ba[true:true];
  Real bs4[:] = ba[false:false];

  type E = enumeration(one, two, three, four);
  Real ea[E] = {1.0, 2.0, 3.0, 4.0};
  Real es1[:] = ea[E.one:E.four];
  Real es2[:] = ea[E.two:E.three];
end RangeSlicing;

// Result:
// class RangeSlicing
//   Real ra[1];
//   Real ra[2];
//   Real ra[3];
//   Real ra[4];
//   Real ra[5];
//   Real ra[6];
//   Real ra[7];
//   Real ra[8];
//   Real ra[9];
//   Real ra[10];
//   Real rs1[1];
//   Real rs1[2];
//   Real rs1[3];
//   Real rs1[4];
//   Real rs1[5];
//   Real rs1[6];
//   Real rs1[7];
//   Real rs1[8];
//   Real rs1[9];
//   Real rs1[10];
//   Real rs2[1];
//   Real rs2[2];
//   Real rs2[3];
//   Real rs2[4];
//   Real rs2[5];
//   Real rs3[1];
//   Real rs3[2];
//   Real rs3[3];
//   Real rs5[1];
//   Real rs6[1];
//   Real rs6[2];
//   Real rs6[3];
//   Real rs6[4];
//   Real rs6[5];
//   Real rs6[6];
//   Real rs6[7];
//   Real rs7[1];
//   Real rs7[2];
//   Real rs7[3];
//   Real ba[false];
//   Real ba[true];
//   Real bs2[1];
//   Real bs2[2];
//   Real bs3[1];
//   Real bs4[1];
//   Real ea[RangeSlicing.E.one];
//   Real ea[RangeSlicing.E.two];
//   Real ea[RangeSlicing.E.three];
//   Real ea[RangeSlicing.E.four];
//   Real es1[1];
//   Real es1[2];
//   Real es1[3];
//   Real es1[4];
//   Real es2[1];
//   Real es2[2];
// equation
//   ra = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0};
//   rs1 = {ra[1], ra[2], ra[3], ra[4], ra[5], ra[6], ra[7], ra[8], ra[9], ra[10]};
//   rs2 = {ra[1], ra[3], ra[5], ra[7], ra[9]};
//   rs3 = {ra[3], ra[2], ra[1]};
//   rs5 = {ra[2]};
//   rs6 = {ra[4], ra[5], ra[6], ra[7], ra[8], ra[9], ra[10]};
//   rs7 = {ra[10], ra[6], ra[2]};
//   ba = {1.0, 2.0};
//   bs2 = {ba[false], ba[true]};
//   bs3 = {ba[true]};
//   bs4 = {ba[false]};
//   ea = {1.0, 2.0, 3.0, 4.0};
//   es1 = {ea[RangeSlicing.E.one], ea[RangeSlicing.E.two], ea[RangeSlicing.E.three], ea[RangeSlicing.E.four]};
//   es2 = {ea[RangeSlicing.E.two], ea[RangeSlicing.E.three]};
// end RangeSlicing;
// endResult
