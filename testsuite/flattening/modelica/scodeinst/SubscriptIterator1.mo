// name: SubscriptIterator1
// keywords:
// status: incorrect
//

model SubscriptIterator1
  Real x[3];
equation
  for i in 1:3 loop
    x[i] = i[1];
  end for;
end SubscriptIterator1;

// Result:
// Error processing file: SubscriptIterator1.mo
// [flattening/modelica/scodeinst/SubscriptIterator1.mo:10:5-10:16:writable] Error: Wrong number of subscripts in i[1] (1 subscripts for 0 dimensions).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
