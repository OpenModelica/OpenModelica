// name: ExtendReplaceable2
// keywords:
// status: incorrect
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
// [flattening/modelica/scodeinst/ExtendReplaceable2.mo:8:17-10:10:writable] Notification: From here:
// [flattening/modelica/scodeinst/ExtendReplaceable2.mo:13:3-13:14:writable] Error: Class 'B' in 'extends A.<B>' is replaceable, the base class name must be transitively non-replaceable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
