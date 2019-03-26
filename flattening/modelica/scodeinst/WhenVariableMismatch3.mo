// name: WhenVariableMismatch3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenVariableMismatch3
  Real x, y;
equation
  when time > 0 then
    if x > 0 then 
      x = 0;
    else
      y = 0;
    end if;
  elsewhen time > 1 then
    x = 0;
  end when;
end WhenVariableMismatch3;

// Result:
// Error processing file: WhenVariableMismatch3.mo
// [flattening/modelica/scodeinst/WhenVariableMismatch3.mo:11:5-15:11:writable] Error: The branches of an if-equation inside a when-equation must have the same set of component references on the left-hand side.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
