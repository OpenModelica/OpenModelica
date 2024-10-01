// name: ExtendsLoop1
// keywords:
// status: incorrect
// cflags: -i=ExtendsLoop1.M
//

model ExtendsLoop1
  model M
    extends ExtendsLoop1;
  end M;
  annotation(__OpenModelica_commandLineOptions="-i=ExtendsLoop1.M");
end ExtendsLoop1;

// Result:
// Error processing file: ExtendsLoop1.mo
// [flattening/modelica/scodeinst/ExtendsLoop1.mo:9:5-9:25:writable] Error: extends ExtendsLoop1 causes an instantiation loop.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
