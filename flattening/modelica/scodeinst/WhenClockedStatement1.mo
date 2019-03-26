// name: WhenClockedStatement1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenClockedStatement1
  Real x, y;
algorithm
  when Clock(1) then
    x := 0;
    y := 1;
  end when;
end WhenClockedStatement1;

// Result:
// Error processing file: WhenClockedStatement1.mo
// [flattening/modelica/scodeinst/WhenClockedStatement1.mo:10:3-13:11:writable] Error: Type error in when conditional 'Clock(1, 1)'. Expected Boolean scalar or vector, got Clock.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
