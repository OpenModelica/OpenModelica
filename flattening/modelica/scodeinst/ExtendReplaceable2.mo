// name: ExtendReplaceable2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ExtendReplaceable2
  model A
    replaceable model B
      Real x;
    end B;
  end A;

  extends A.B;
end ExtendReplaceable2;

// Result:
// Error processing file: ExtendReplaceable2.mo
// [flattening/modelica/scodeinst/ExtendReplaceable2.mo:9:17-11:10:writable] Notification: From here:
// [flattening/modelica/scodeinst/ExtendReplaceable2.mo:14:3-14:14:writable] Error: Class 'B' in 'extends A.<B>' is replaceable, the base class name must be transitively non-replaceable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
