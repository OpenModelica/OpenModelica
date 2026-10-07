// name:     EnumDuplicateLiteral
// keywords: enumeration enum duplicate
// status:   incorrect
//
// Tests detection of duplicated enumeration literals.
//

model EnumDuplicateLiteral
  type E = enumeration(one, two, three, two);
  E e;
end EnumDuplicateLiteral;


// Result:
// Error processing file: EnumDuplicateLiteral.mo
// [flattening/modelica/enums/EnumDuplicateLiteral.mo:9:3-9:45:writable] Error: An element with name two is already declared in this scope.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
