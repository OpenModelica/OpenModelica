// name: WhenNested1
// keywords:
// status: incorrect
//

model WhenNested1
  Real x;
equation
  when time > 1 then
    when time > 2 then
      reinit(x, 2.0);
    end when;
  end when;
end WhenNested1;

// Result:
// Error processing file: WhenNested1.mo
// [flattening/modelica/scodeinst/WhenNested1.mo:10:5-12:13:writable] Error: Nested when statements are not allowed.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
