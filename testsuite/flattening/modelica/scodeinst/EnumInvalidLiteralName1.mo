// name: EnumInvalidLiteralName1
// keywords:
// status: incorrect
//

model EnumInvalidLiteralName1
  type E = enumeration(start, min, max);
  E e;
end EnumInvalidLiteralName1;

// Result:
// Error processing file: EnumInvalidLiteralName1.mo
// [flattening/modelica/scodeinst/EnumInvalidLiteralName1.mo:7:3-7:40:writable] Error: An element with name start is already declared in this scope.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
