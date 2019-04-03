// name: InvalidConnectorDirection3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidConnectorDirection3
  connector C
    input Real x;
    Real y;
    flow Real f;
  end C;

  connector C2
    Real x;
    input Real y;
    flow Real f;
  end C2;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidConnectorDirection3;

// Result:
// Error processing file: InvalidConnectorDirection3.mo
// [flattening/modelica/scodeinst/InvalidConnectorDirection3.mo:23:3-23:18:writable] Error: Cannot connect input component c2.y to non-input component c1.y.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
