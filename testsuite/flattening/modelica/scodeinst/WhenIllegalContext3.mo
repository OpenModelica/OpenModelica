// name: WhenIllegalContext3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenIllegalContext3
  Real x;
algorithm
  for i in 1:3 loop
    when time > 1 then
      x := 1.0;
    end when;
  end for;
end WhenIllegalContext3;

// Result:
// Error processing file: WhenIllegalContext3.mo
// [flattening/modelica/scodeinst/WhenIllegalContext3.mo:11:5-13:13:writable] Error: A when-statement may not be used inside a function or a while, if, or for-clause.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
