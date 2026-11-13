// name: BlockConnector2
// keywords:
// status: incorrect
//
// Checks that an error is given for a public connector in a block that is
// missing the input/output prefix.
//

connector RealSig = Real;

block BlockConnector2
  RealSig u;
  output RealSig y;
equation
  y = 2*u;
end BlockConnector2;

// Result:
// Error processing file: BlockConnector2.mo
// [flattening/modelica/scodeinst/BlockConnector2.mo:12:3-12:12:writable] Warning: Connector u is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/scodeinst/BlockConnector2.mo:12:3-12:12:writable] Error: Public connector u in a block may only have variables that are input or output, but the following are neither: u.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
