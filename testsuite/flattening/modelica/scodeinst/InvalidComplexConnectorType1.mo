// name: InvalidComplexConnectorType1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidComplexConnectorType1
  connector C
    parameter Real x;
    Real y;
    flow Real f;
  end C;

  connector C2
    Real x;
    parameter Real y;
    flow Real f;
  end C2;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidComplexConnectorType1;

// Result:
// Error processing file: InvalidComplexConnectorType1.mo
// [flattening/modelica/scodeinst/InvalidComplexConnectorType1.mo:23:3-23:18:writable] Error: Cannot connect parameter c2.y to non-constant/parameter c1.y.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
