// name: PackageComponents
// keywords: package
// status: correct
//
// Tests simple package creation and instantation of its components
//

package TestPackage

class TestClass
  Integer i;
end TestClass;

end TestPackage;

model PackageComponents
  TestPackage.TestClass tc;
equation
  tc.i = 1;
end PackageComponents;

// Result:
// class PackageComponents
//   Integer tc.i;
// equation
//   tc.i = 1;
// end PackageComponents;
// [flattening/modelica/packages/PackageComponents.mo:11:3-11:12:writable] Warning: Components are deprecated in class.
//
// endResult
