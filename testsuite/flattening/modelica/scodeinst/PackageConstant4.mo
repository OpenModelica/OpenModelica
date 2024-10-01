// name: PackageConstant4
// keywords:
// status: correct
//

package P
  record R
    Real x;
  end R;

  constant R r1(x = 1);
  constant R r2[1] = {r1};
end P;

model PackageConstant4
  Real x = P.r2[1].x;
end PackageConstant4;

// Result:
// class PackageConstant4
//   Real x = 1.0;
// end PackageConstant4;
// endResult
