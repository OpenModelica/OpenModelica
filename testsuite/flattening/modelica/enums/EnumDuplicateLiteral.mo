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
// [flattening/modelica/enums/EnumDuplicateLiteral.mo:9:3-9:45:writable] Error: Enumeration has duplicate names: two in list of names one,two,three,two.
// Error: Error occurred while flattening model EnumDuplicateLiteral
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
