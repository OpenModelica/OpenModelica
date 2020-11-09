// name:     EnumDuplicateLiteral
// keywords: enumeration enum duplicate
// status:   incorrect
// cflags: -d=-newInst
//
// Tests detection of duplicated enumeration literals.
//

model EnumDuplicateLiteral
  type E = enumeration(one, two, three, two);
  E e;
end EnumDuplicateLiteral;


// Result:
// Error processing file: EnumDuplicateLiteral.mo
// [flattening/modelica/enums/EnumDuplicateLiteral.mo:10:3-10:45:writable] Error: Enumeration has duplicate names: two in list of names one,two,three,two.
// Error: Error occurred while flattening model EnumDuplicateLiteral
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
