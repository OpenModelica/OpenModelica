// name: InvalidConnectorDirection4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidConnectorDirection4
  connector C
    flow Real f;
    Real y;
    input Real x;
  end C;

  connector C2
    flow Real f;
    input Real y;
    Real x;
  end C2;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidConnectorDirection4;

// Result:
// Error processing file: InvalidConnectorDirection4.mo
// [flattening/modelica/scodeinst/InvalidConnectorDirection4.mo:23:3-23:18:writable] Error: Cannot connect input component c1.x to non-input component c2.x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
