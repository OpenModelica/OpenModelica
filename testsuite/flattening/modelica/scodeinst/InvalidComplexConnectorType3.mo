// name: InvalidComplexConnectorType3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidComplexConnectorType3
  connector C
    Real y;
    flow Real f;
  end C;

  parameter C c1;
  parameter C c2;
equation
  connect(c1, c2);
end InvalidComplexConnectorType3;

// Result:
// Error processing file: InvalidComplexConnectorType3.mo
// [flattening/modelica/scodeinst/InvalidComplexConnectorType3.mo:16:3-16:18:writable] Error: c1 is a composite connector element, and may not be declared as parameter.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
