// name:     Redeclare6
// keywords: redeclare
// status:   correct
//

package Lib
  package TypePackage
    type Type = Real;
  end TypePackage;

  model PackageModel
    replaceable package Pack = TypePackage;
    Pack.Type v;
  equation
    v = 1;
  end PackageModel;
end Lib;

model Redeclare6
  package Pack = Lib.TypePackage;

  Lib.PackageModel mod1(redeclare package Pack = Pack);
  Lib.PackageModel mod2(redeclare package Pack = Lib.TypePackage);
end Redeclare6;

// Result:
// class Redeclare6
//   Real mod1.v;
//   Real mod2.v;
// equation
//   mod1.v = 1.0;
//   mod2.v = 1.0;
// end Redeclare6;
// endResult
