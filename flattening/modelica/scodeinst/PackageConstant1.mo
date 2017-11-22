// name: PackageConstant1
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  constant Real x = 1.0;
end P;

model PackageConstant1
  Real y = P.x;
end PackageConstant1;

// Result:
// class PackageConstant1
//   Real y = 1.0;
// end PackageConstant1;
// endResult
