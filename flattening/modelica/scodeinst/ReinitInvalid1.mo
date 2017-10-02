// name: ReinitInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

class ReinitInvalid1
  Boolean b(start = false);
equation
  when b then
    reinit(b, true);
  end when;
end ReinitInvalid1;

// Result:
// Error processing file: ReinitInvalid1.mo
// [flattening/modelica/scodeinst/ReinitInvalid1.mo:11:5-11:20:writable] Error: The first argument to reinit must be a subtype of Real, but b has type Boolean.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
