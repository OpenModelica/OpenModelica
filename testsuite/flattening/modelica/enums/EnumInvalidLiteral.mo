// name:     EnumInvalidLiteral
// keywords: enumeration enum invalid
// status:   incorrect
//
// Tests detection of invalid enumeration literals.
//

model EnumInvalidLiteral
  type enum = enumeration(one, start);
  type enum2 = enumeration(quantity, two);
  enum e;
  enum2 e2;
end EnumInvalidLiteral;


// Result:
// Error processing file: EnumInvalidLiteral.mo
// [flattening/modelica/enums/EnumInvalidLiteral.mo:9:3-9:38:writable] Error: Invalid use of reserved attribute name start as enumeration literal.
// Error: Error occurred while flattening model EnumInvalidLiteral
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
