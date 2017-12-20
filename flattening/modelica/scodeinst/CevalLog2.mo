// name: CevalLog2
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model CevalLog2
  constant Real r1 = log(-1);
end CevalLog2;

// Result:
// Error processing file: CevalLog2.mo
// [flattening/modelica/scodeinst/CevalLog2.mo:9:3-9:29:writable] Error: Argument -1 of log is out of range (x > 0)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
