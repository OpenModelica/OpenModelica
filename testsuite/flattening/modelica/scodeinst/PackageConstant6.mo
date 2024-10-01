// name: PackageConstant6
// keywords:
// status: correct
//

model PackageConstant6
  model A
    constant Integer n = 2;
  end A;

  A a;

  model B
    Real x[a.n];
  end B;

  B b;
end PackageConstant6;

// Result:
// class PackageConstant6
//   constant Integer a.n = 2;
//   Real b.x[1];
//   Real b.x[2];
// end PackageConstant6;
// endResult
