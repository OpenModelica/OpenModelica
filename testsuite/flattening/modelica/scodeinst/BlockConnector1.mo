// name: BlockConnector1
// keywords:
// status: incorrect
//
// Checks that an error is given for a public connector in a block that has
// variables that are neither input nor output.
//

connector Pin
  Real v;
  flow Real i;
end Pin;

block BlockConnector1
  Pin p;
  output Real y;
equation
  y = p.v;
end BlockConnector1;

// Result:
// Error processing file: BlockConnector1.mo
// [flattening/modelica/scodeinst/BlockConnector1.mo:15:3-15:8:writable] Error: Public connector p in a block may only have variables that are input or output, but the following are neither: p.v, p.i.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
