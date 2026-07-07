// name: WhenIllegalContext5
// keywords:
// status: incorrect
//

model WhenIllegalContext5
  Real x;
  parameter Boolean b = true annotation(Evaluate=false);
equation
  if b then
    when time > 1 then
      x = 1.0;
    end when;
  end if;
end WhenIllegalContext5;

// Result:
// Error processing file: WhenIllegalContext5.mo
// [flattening/modelica/scodeinst/WhenIllegalContext5.mo:11:5-13:13:writable] Error: when may not be used inside if- or for-equations with non-evaluable conditions or iteration ranges.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
