// name: ConstantConnector2
// keywords:
// status: incorrect
//

model ConstantConnector2
  connector C = constant Real;

  C c1 = 1, c2 = 2;
equation
  connect(c1, c2);
end ConstantConnector2;

// Result:
// Error processing file: ConstantConnector2.mo
// [flattening/modelica/scodeinst/ConstantConnector2.mo:9:3-9:19:writable] Error: Invalid variability constant on connector 'c1'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
