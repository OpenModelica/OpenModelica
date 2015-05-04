// name: InStreamInvalidArgument
// keywords: inStream invalid argument
// status: incorrect
//
// Checks that an error message is generated if the argument to inStream is not
// a stream connector.
//

model InStreamInvalidArgument
  Real r;
  Real instream;
equation
  instream = inStream(r);
end InStreamInvalidArgument;

// Result:
// Error processing file: InStreamInvalidArgument.mo
// [flattening/modelica/streams/InStreamInvalidArgument.mo:13:3-13:25:writable] Error: Operand r to operator inStream is not a stream variable.
// Error: Error occurred while flattening model InStreamInvalidArgument
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
