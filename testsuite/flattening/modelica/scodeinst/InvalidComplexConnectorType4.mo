// name: InvalidComplexConnectorType4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidComplexConnectorType4
  connector C
    flow parameter Real x;
    Real y;
    flow Real f;
  end C;

  C c1, c2;
equation
  connect(c1, c2);
end InvalidComplexConnectorType4;

// Result:
// Error processing file: InvalidComplexConnectorType4.mo
// [flattening/modelica/scodeinst/InvalidComplexConnectorType4.mo:16:3-16:18:writable] Error: Connector element c1.x may not be both parameter and flow.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
