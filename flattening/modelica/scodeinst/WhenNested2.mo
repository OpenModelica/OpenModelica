// name: WhenNested2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenNested2
  Real x;
algorithm
  when time > 1 then
    when time > 2 then
      x := 1.0;
    end when;
  end when;
end WhenNested2;

// Result:
// Error processing file: WhenNested2.mo
// [flattening/modelica/scodeinst/WhenNested2.mo:11:5-13:13:writable] Error: Nested when statements are not allowed.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
