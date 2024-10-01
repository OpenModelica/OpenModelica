// name: EnumUnspecified1
// keywords:
// status: incorrect
//

model EnumUnspecified1
  replaceable type E = enumeration(:);
  E e;
end EnumUnspecified1;

// Result:
// Error processing file: EnumUnspecified1.mo
// [flattening/modelica/scodeinst/EnumUnspecified1.mo:8:3-8:6:writable] Error: Component 'e' has an unspecified enumeration type (enumeration(:)).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
