// name: ReinitInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

class ReinitInvalid1
  discrete Real x = 1.0;
equation
  when time > 1.0 then
    reinit(x, 2.0);
  end when;
end ReinitInvalid1;

// Result:
// Error processing file: ReinitInvalid1.mo
// [flattening/modelica/scodeinst/ReinitInvalid1.mo:11:5-11:19:writable] Error: The first argument to reinit must be a continuous time variable, but x is discrete.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
