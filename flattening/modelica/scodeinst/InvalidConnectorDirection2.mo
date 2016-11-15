// name: InvalidConnectorDirection2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InvalidConnectorDirection2
  connector C = Real;
  connector C2 = input Real;

  C c1;
  C2 c2;
equation
  connect(c1, c2);
end InvalidConnectorDirection2;

// Result:
// Error processing file: InvalidConnectorDirection2.mo
// [flattening/modelica/scodeinst/InvalidConnectorDirection2.mo:14:3-14:18:writable] Error: Cannot connect input component c2 to non-input component c1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
