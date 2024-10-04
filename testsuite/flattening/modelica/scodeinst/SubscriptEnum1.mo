// name: SubscriptEnum1
// keywords:
// status: incorrect
//
//

model SubscriptEnum1
  type E = enumeration(one, two, three);
  E e;
equation
  e = E.one[1];
end SubscriptEnum1;

// Result:
// Error processing file: SubscriptEnum1.mo
// [flattening/modelica/scodeinst/SubscriptEnum1.mo:11:3-11:15:writable] Error: Wrong number of subscripts in E.one[1] (1 subscripts for 0 dimensions).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
