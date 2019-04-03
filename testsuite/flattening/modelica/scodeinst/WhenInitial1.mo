// name: WhenInitial1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenInitial1
initial equation
  when time > 0 then
  end when;
end WhenInitial1;

// Result:
// Error processing file: WhenInitial1.mo
// [flattening/modelica/scodeinst/WhenInitial1.mo:9:3-10:11:writable] Error: when-clause is not allowed in initial section.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
