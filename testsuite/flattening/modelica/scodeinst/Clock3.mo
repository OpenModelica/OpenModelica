// name: Clock3
// keywords:
// status: incorrect
//

model Clock3
  model Clock
    Real t;
  end Clock;

  Clock c = Clock();
end Clock3;

// Result:
// Error processing file: Clock3.mo
// [flattening/modelica/scodeinst/Clock3.mo:11:3-11:20:writable] Error: Component 'c' may not have a binding equation due to class specialization 'model'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
