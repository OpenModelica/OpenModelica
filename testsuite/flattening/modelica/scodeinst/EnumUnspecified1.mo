// name: EnumUnspecified1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model EnumUnspecified1
  replaceable type E = enumeration(:);
  E e;
end EnumUnspecified1;

// Result:
// Error processing file: EnumUnspecified1.mo
// [flattening/modelica/scodeinst/EnumUnspecified1.mo:9:3-9:6:writable] Error: Component 'e' has an unspecified enumeration type (enumeration(:)).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
