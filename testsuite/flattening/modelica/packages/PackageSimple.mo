// name: PackageSimple
// keywords: package
// status: correct
// cflags: -d=-newInst
//
// Tests simple package declaration
// This test might need to be improved upon
//

package SimplePackage
end SimplePackage;

model PackageSimple
end PackageSimple;

// Result:
// class PackageSimple
// end PackageSimple;
// endResult
