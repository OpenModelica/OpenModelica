// name: RedeclarationComponentNames
// keywords: component
// status: incorrect
//
// This test should produce a warning (or even fail, according to Modelica Specifications)
// Tests whether or not a component can have the same name as its type specifier in a redeclaraton
//

class A
  Real x;
end A;

class B
  Real x;
  Real y;
end B;

model Legal
  replaceable A B;
end Legal;

model IllegalRedeclaredComponentName
  extends Legal(redeclare B B);
end IllegalRedeclaredComponentName;

// Result:
// Error processing file: ComponentNamesRedecl.mo
// [flattening/modelica/others/ComponentNamesRedecl.mo:23:17-23:30:writable] Error: Found a component with same name when looking for type B.
// Error: Error occurred while flattening model IllegalRedeclaredComponentName
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
