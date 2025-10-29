// name: ConstantConnector1
// keywords:
// status: incorrect
//

model ConstantConnector1
  connector C = parameter Real;

  C c1 = 0, c2 = 0;
equation
  connect(c1, c2);
end ConstantConnector1;

// Result:
// Error processing file: ConstantConnector1.mo
// [flattening/modelica/scodeinst/ConstantConnector1.mo:9:3-9:19:writable] Error: Invalid variability parameter on connector 'c1'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
