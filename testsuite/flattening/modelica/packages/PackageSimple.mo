// name: PackageSimple
// keywords: package
// status: correct
//
// Tests simple package declaration
// This test might need to be improved upon
//

package SimplePackage
end SimplePackage;

model PackageSimple
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end PackageSimple;

// Result:
// class PackageSimple
// end PackageSimple;
// endResult
