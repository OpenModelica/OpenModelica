// name: PackageConstant3
// keywords:
// status: correct
//

package P
  record R
    Real x = 1;
  end R;

  constant R r[3];
end P;

model PackageConstant3
  Real x = P.r[1].x;
end PackageConstant3;

// Result:
// class PackageConstant3
//   Real x = 1.0;
// end PackageConstant3;
// endResult
