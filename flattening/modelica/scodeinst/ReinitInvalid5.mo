// name: ReinitInvalid5
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ReinitInvalid5
equation
  when time > 1 then
    reinit(1, 2);
  end when;
end ReinitInvalid5;

// Result:
// Error processing file: ReinitInvalid5.mo
// [flattening/modelica/scodeinst/ReinitInvalid5.mo:10:5-10:17:writable] Error: The first argument to reinit must be a variable of type Real or an array of such variables.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
