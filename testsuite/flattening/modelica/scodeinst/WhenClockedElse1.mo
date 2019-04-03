// name: WhenClockedElse1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenClockedElse1
  Real x, y;
equation
  when Clock(0.1) then
    x = 0;
    y = 1;
  elsewhen Clock(0.2) then
    x = 2;
    y = 3;
  end when;
end WhenClockedElse1;

// Result:
// Error processing file: WhenClockedElse1.mo
// [flattening/modelica/scodeinst/WhenClockedElse1.mo:10:3-16:11:writable] Error: Clocked when equation can not contain elsewhen part.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
