// name: WhenIllegalContext4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenIllegalContext4
  Real x;
algorithm
  while time < 1 loop
    when time > 1 then
      x := 1.0;
    end when;
  end while;
end WhenIllegalContext4;

// Result:
// Error processing file: WhenIllegalContext4.mo
// [flattening/modelica/scodeinst/WhenIllegalContext4.mo:11:5-13:13:writable] Error: A when-statement may not be used inside a function or a while, if, or for-clause.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
