// name:     RecursiveDefinition
// keywords: recursive definition
// status:   incorrect
//
// Checks that compiler gives an error for recursive definitions.
//

class A

  class B
    A x;
  end B;

  B b;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end A;

// Result:
// Error processing file: RecursiveDefinition.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/others/RecursiveDefinition.mo:11:5-11:8:writable] Error: Declaration of element x causes recursive definition of class A.
// Error: Error occurred while flattening model A
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
