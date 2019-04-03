// name:     InvalidInheritedExtends1
// keywords: extends invalid
// status:   incorrect
//
// This test tests that the compiler issues an error if the name of an extends
// depends on an inherited element.
//

class B
  class C
    Integer i;
  end C;
end B;

class C
  Integer j;
end C;

class InvalidInheritedExtends1
  extends B;
  extends C; // C has been inherited from B, so this extends is illegal.
end InvalidInheritedExtends1;

// Result:
// Error processing file: InvalidInheritedExtends1.mo
// [flattening/modelica/extends/InvalidInheritedExtends1.mo:21:3-21:12:writable] Error: The base class name C was found in one or more base classes:
// [flattening/modelica/extends/InvalidInheritedExtends1.mo:10:3-12:8:writable] Notification: From here:
// [flattening/modelica/extends/InvalidInheritedExtends1.mo:20:3-20:12:writable] Error: C was found in base class B.
// Error: Error occurred while flattening model InvalidInheritedExtends1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
