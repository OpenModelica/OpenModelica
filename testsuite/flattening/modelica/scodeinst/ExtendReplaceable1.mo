// name: ExtendReplaceable1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ExtendReplaceable1
  replaceable model M
    Real x;
  end M;

  extends M;
end ExtendReplaceable1;

// Result:
// Error processing file: ExtendReplaceable1.mo
// [flattening/modelica/scodeinst/ExtendReplaceable1.mo:8:15-10:8:writable] Notification: From here:
// [flattening/modelica/scodeinst/ExtendReplaceable1.mo:12:3-12:12:writable] Error: Class 'M' in 'extends M' is replaceable, the base class name must be transitively non-replaceable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
