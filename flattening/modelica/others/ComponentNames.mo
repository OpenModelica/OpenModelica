// name: ComponentNames
// keywords: component
// status: incorrect
//
// THIS TEST SHOULD FAIL according to Modelica Specifications.
// But MSL contains such errors, so the test only results in a warning
// Tests whether or not a component can have the same name as its type specifier
//

class TestClass
  parameter Integer x = 1;
end TestClass;

model ComponentNames
  TestClass TestClass(x = 2);
  Integer Integer;
end ComponentNames;

// Result:
// Error processing file: ComponentNames.mo
// [flattening/modelica/others/ComponentNames.mo:15:3-15:29:writable] Error: Found a component with same name when looking for type TestClass.
// Error: Error occurred while flattening model ComponentNames
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
