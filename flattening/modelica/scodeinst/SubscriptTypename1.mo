// name: SubscriptTypename1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model SubscriptTypename1
  Real x;
equation
  for i in Boolean[1] loop
    x = 1.0;
  end for;
end SubscriptTypename1;

// Result:
// Error processing file: SubscriptTypename1.mo
// [flattening/modelica/scodeinst/SubscriptTypename1.mo:10:3-12:10:writable] Error: Wrong number of subscripts in Boolean[1] (1 subscripts for 0 dimensions).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
