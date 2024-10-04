// name: WhenClockedElse2
// keywords:
// status: incorrect
//

model WhenClockedElse2
  Real x, y;
equation
  when time > 0 then
    x = 0;
    y = 1;
  elsewhen Clock(0.2) then
    x = 2;
    y = 3;
  end when;
end WhenClockedElse2;

// Result:
// Error processing file: WhenClockedElse2.mo
// [flattening/modelica/scodeinst/WhenClockedElse2.mo:9:3-15:11:writable] Error: Clocked when branch in when equation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
