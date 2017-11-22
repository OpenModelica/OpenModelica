// name: PackageConstant2
// keywords:
// status: correct
// cflags: -d=newInst,-replacePackageConstants
//
// Tests that package constants are collected correctly when the
// replacePackageConstants debug flag is disabled.
//

package P
  constant Real x1 = 1.0;
  constant Real x2 = 2.0;
  constant Real x3 = 3.0;
  constant Real x4 = 4.0;
end P;

model PackageConstant2
  Real y = P.x1;
  Real z;
equation
  z = P.x2;
algorithm
  z := P.x3;
end PackageConstant2;

// Result:
// class PackageConstant2
//   constant Real P.x3 = 3.0;
//   constant Real P.x2 = 2.0;
//   constant Real P.x1 = 1.0;
//   Real y = P.x1;
//   Real z;
// equation
//   z = P.x2;
// algorithm
//   z := P.x3;
// end PackageConstant2;
// endResult
