// name: InvalidConnectorDirection1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidConnectorDirection1
  connector C = input Real;
  connector C2 = Real;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidConnectorDirection1;

// Result:
// Error processing file: InvalidConnectorDirection1.mo
// [flattening/modelica/scodeinst/InvalidConnectorDirection1.mo:14:3-14:18:writable] Error: Cannot connect input component c1 to non-input component c2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
