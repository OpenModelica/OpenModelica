// name: Range1.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model Range1
  type E = enumeration(one, two, three);
  E x[E] = E.one:E.three;
end Range1;

// Result:
// Error processing file: Range1.mo
// [flattening/modelica/scodeinst/Range1.mo:10:3-10:28:writable] Error: Expected E to be a component, but found class instead.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
