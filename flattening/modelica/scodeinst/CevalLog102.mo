// name: CevalLog102
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model CevalLog102
  constant Real r1 = log10(-1);
end CevalLog102;

// Result:
// Error processing file: CevalLog102.mo
// [flattening/modelica/scodeinst/CevalLog102.mo:9:3-9:31:writable] Error: Argument -1 of log10 is out of range (x > 0)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
