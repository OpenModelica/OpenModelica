// status: incorrect

model WhenNotInitial
  discrete Real r(start=0, fixed=true);
equation
  when not initial() then
    r=1;
  end when;
end WhenNotInitial;

// Result:
// Error processing file: WhenNotInitial.mo
// [flattening/modelica/equations/WhenNotInitial.mo:6:3-8:11:writable] Warning: The standard says that initial() may only be used as a when condition (when initial() or when {..., initial(), ...}), but got condition not initial().
// [flattening/modelica/equations/WhenNotInitial.mo:6:3-8:11:writable] Error: Failed to instantiate equation
// when not initial() then
//   r = 1;
// end when;.
// Error: Error occurred while flattening model WhenNotInitial
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
