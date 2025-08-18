// name: NonScalarizedWithRecords1
// status: correct

model M
  record R1
    Real x;
    Real y;
    Real z[3];
  end R1;

  record R2
    R1 r;
    R1 ra[3];
    Real w;
  end R2;

  constant R1 cr1 = R1(0, 0, zeros(3));
  constant R2 cr2 = R2(cr1, fill(cr1, 3), 0);
  R1 r1;
  R1 ra1[3];
  R2 r2;
  R2 ra2[3];
equation
  r1 = cr1;
  r1.x = 0;
  r1.z[1] = 0;

  ra1.x = zeros(3);
  ra1.z = zeros(3, 3);
  ra1.z[1] = zeros(3);
  ra1[2] = cr1;
  ra1[1].y = 0;
  ra1[1].z = zeros(3);
  ra1[1].z[2] = 0;

  ra2.r = fill(cr1, 3);
  ra2.r.x = zeros(3);
  ra2.ra.y = zeros(3, 3);

  ra2[2].ra = fill(cr1, 3);
  ra2[2].ra.y = zeros(3);
  ra2[1].ra[2].y = 0;
end M;

model NonScalarizedWithoutRecords1
  extends M;
  M m;
  M ma[3];
equation
  m.r1.x = 0;
  m.ra1[1].x = 0;
  ma[1].r1.x = 0;
  ma[1].r1.z[2] = 0;
  ma[1].r1 = cr1;
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f --newBackend --baseModelicaFormat=withoutRecords");
end NonScalarizedWithoutRecords1;

// Result:
// //! base 0.1.0
// package 'NonScalarizedWithoutRecords1'
//   record 'R1'
//     Real 'x';
//     Real 'y';
//     Real[3] 'z';
//   end 'R1';
//
//   record 'R2'
//     'R1' 'r';
//     'R1'[3] 'ra';
//     Real 'w';
//   end 'R2';
//
//   record 'm.R1'
//     Real 'x';
//     Real 'y';
//     Real[3] 'z';
//   end 'm.R1';
//
//   record 'm.R2'
//     'm.R1' 'r';
//     'm.R1'[3] 'ra';
//     Real 'w';
//   end 'm.R2';
//
//   record 'ma.R1'
//     Real 'x';
//     Real 'y';
//     Real[3] 'z';
//   end 'ma.R1';
//
//   record 'ma.R2'
//     'ma.R1' 'r';
//     'ma.R1'[3] 'ra';
//     Real 'w';
//   end 'ma.R2';
//
//   model 'NonScalarizedWithoutRecords1'
//     constant 'R1' 'cr1' = 'R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     constant 'R2' 'cr2' = 'R2'('R1'(0.0, 0.0, {0.0, 0.0, 0.0}), {'R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 'R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 'R1'(0.0, 0.0, {0.0, 0.0, 0.0})}, 0.0);
//     'R1' 'r1';
//     'R1'[3] 'ra1';
//     'R2' 'r2';
//     'R2'[3] 'ra2';
//     constant 'm.R1' 'm.cr1' = 'm.R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     constant 'm.R2' 'm.cr2' = 'm.R2'('m.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), {'m.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 'm.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 'm.R1'(0.0, 0.0, {0.0, 0.0, 0.0})}, 0.0);
//     'm.R1' 'm.r1';
//     'm.R1'[3] 'm.ra1';
//     'm.R2' 'm.r2';
//     'm.R2'[3] 'm.ra2';
//     constant 'ma.R1'[3] 'ma.cr1' = fill('ma.R1'(0.0, 0.0, fill(0.0, 3)), 3);
//     constant 'ma.R2'[3] 'ma.cr2' = {'ma.R2'('ma.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), fill('ma.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 3), 0.0) for '$ma1' in 1:3};
//     'ma.R1'[3] 'ma.r1';
//     'ma.R1'[3, 3] 'ma.ra1';
//     'ma.R2'[3] 'ma.r2';
//     'ma.R2'[3, 3] 'ma.ra2';
//   equation
//     'm.r1' = 'm.R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     'm.r1.x' = 0.0;
//     'm.r1.z'[1] = 0.0;
//     'm.ra1.x' = fill(0.0, 3);
//     'm.ra1.z' = fill(0.0, 3, 3);
//     'm.ra1.z'[1] = fill(0.0, 3);
//     'm.ra1'[2] = 'm.R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     'm.ra1.y'[1] = 0.0;
//     'm.ra1.z'[1] = fill(0.0, 3);
//     'm.ra1.z'[2,1] = 0.0;
//     'm.ra2.r' = fill('m.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 3);
//     'm.ra2.r.x' = fill(0.0, 3);
//     'm.ra2.ra.y' = fill(0.0, 3, 3);
//     'm.ra2.ra'[2] = fill('m.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 3);
//     'm.ra2.ra.y'[2] = fill(0.0, 3);
//     'm.ra2.ra.y'[2,1] = 0.0;
//
//     for '$i15' in 1:3 loop
//       'ma.r1'['$i15'] = 'ma.R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     end for;
//
//     for '$i14' in 1:3 loop
//       'ma.r1.x'['$i14'] = 0.0;
//     end for;
//
//     for '$i13' in 1:3 loop
//       'ma.r1.z'[1,'$i13'] = 0.0;
//     end for;
//
//     for '$i12' in 1:3 loop
//       'ma.ra1.x'['$i12'] = fill(0.0, 3);
//     end for;
//
//     for '$i11' in 1:3 loop
//       'ma.ra1.z'['$i11'] = fill(0.0, 3, 3);
//     end for;
//
//     for '$i10' in 1:3 loop
//       'ma.ra1.z'[1,'$i10'] = fill(0.0, 3);
//     end for;
//
//     for '$i9' in 1:3 loop
//       'ma.ra1'[2,'$i9'] = 'ma.R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     end for;
//
//     for '$i8' in 1:3 loop
//       'ma.ra1.y'[1,'$i8'] = 0.0;
//     end for;
//
//     for '$i7' in 1:3 loop
//       'ma.ra1.z'[1,'$i7'] = fill(0.0, 3);
//     end for;
//
//     for '$i6' in 1:3 loop
//       'ma.ra1.z'[2,1,'$i6'] = 0.0;
//     end for;
//
//     for '$i5' in 1:3 loop
//       'ma.ra2.r'['$i5'] = fill('ma.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 3);
//     end for;
//
//     for '$i4' in 1:3 loop
//       'ma.ra2.r.x'['$i4'] = fill(0.0, 3);
//     end for;
//
//     for '$i3' in 1:3 loop
//       'ma.ra2.ra.y'['$i3'] = fill(0.0, 3, 3);
//     end for;
//
//     for '$i2' in 1:3 loop
//       'ma.ra2.ra'[2,'$i2'] = fill('ma.R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 3);
//     end for;
//
//     for '$i1' in 1:3 loop
//       'ma.ra2.ra.y'[2,'$i1'] = fill(0.0, 3);
//     end for;
//
//     for '$i0' in 1:3 loop
//       'ma.ra2.ra.y'[2,1,'$i0'] = 0.0;
//     end for;
//
//     'm.r1.x' = 0.0;
//     'm.ra1.x'[1] = 0.0;
//     'ma.r1.x'[1] = 0.0;
//     'ma.r1.z'[2,1] = 0.0;
//     'ma.r1'[1] = 'R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     'r1' = 'R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     'r1.x' = 0.0;
//     'r1.z'[1] = 0.0;
//     'ra1.x' = fill(0.0, 3);
//     'ra1.z' = fill(0.0, 3, 3);
//     'ra1.z'[1] = fill(0.0, 3);
//     'ra1'[2] = 'R1'(0.0, 0.0, {0.0, 0.0, 0.0});
//     'ra1.y'[1] = 0.0;
//     'ra1.z'[1] = fill(0.0, 3);
//     'ra1.z'[2,1] = 0.0;
//     'ra2.r' = fill('R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 3);
//     'ra2.r.x' = fill(0.0, 3);
//     'ra2.ra.y' = fill(0.0, 3, 3);
//     'ra2.ra'[2] = fill('R1'(0.0, 0.0, {0.0, 0.0, 0.0}), 3);
//     'ra2.ra.y'[2] = fill(0.0, 3);
//     'ra2.ra.y'[2,1] = 0.0;
//   end 'NonScalarizedWithoutRecords1';
// end 'NonScalarizedWithoutRecords1';
// endResult
