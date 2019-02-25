// name: ExtendReplaceable3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ExtendReplaceable3
  model A
    replaceable model B
      model C
        Real x;
      end C;
    end B;
  end A;

  extends A.B.C;
end ExtendReplaceable3;

// Result:
// Error processing file: ExtendReplaceable3.mo
// [flattening/modelica/scodeinst/ExtendReplaceable3.mo:9:17-13:10:writable] Notification: From here:
// [flattening/modelica/scodeinst/ExtendReplaceable3.mo:16:3-16:16:writable] Error: Class 'B' in 'extends A.<B>.C' is replaceable, the base class name must be transitively non-replaceable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
