// name: PackageIllegal
// keywords: package
// status: correct
//
// Tests to make sure that a package cannot have non-class components
// THIS TEST SHOULD FAIL
//

package IllegalPackage

class LegalClass
  Integer i;
end LegalClass;

Integer i;

equation
  i = 1;
end IllegalPackage;

model PackageIllegal
  IllegalPackage.LegalClass lc;
equation
  lc.i = 1;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end PackageIllegal;

// Result:
// class PackageIllegal
//   Integer lc.i;
// equation
//   lc.i = 1;
// end PackageIllegal;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
