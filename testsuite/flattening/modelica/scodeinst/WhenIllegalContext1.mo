// name: WhenIllegalContext1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

function f
  input Real x;
  output Real y = x;
algorithm
  when x > 1 then
    y := x * 2;
  end when;
end f;

model WhenIllegalContext1
  Real x = f(time);
end WhenIllegalContext1;

// Result:
// Error processing file: WhenIllegalContext1.mo
// [flattening/modelica/scodeinst/WhenIllegalContext1.mo:11:3-13:11:writable] Error: A when-statement may not be used inside a function or a while, if, or for-clause.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
