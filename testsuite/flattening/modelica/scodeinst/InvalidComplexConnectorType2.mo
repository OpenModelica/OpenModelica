// name: InvalidComplexConnectorType2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidComplexConnectorType2
  connector C
    Real y;
    parameter Real x;
    flow Real f;
  end C;

  connector C2
    parameter Real y;
    Real x;
    flow Real f;
  end C2;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidComplexConnectorType2;

// Result:
// Error processing file: InvalidComplexConnectorType2.mo
// [flattening/modelica/scodeinst/InvalidComplexConnectorType2.mo:23:3-23:18:writable] Error: Cannot connect parameter c1.x to non-constant/parameter c2.x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
