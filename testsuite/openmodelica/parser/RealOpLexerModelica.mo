// name: RealOpLexerModelica
// keywords: real, lexing
// status: incorrect
//
// tests that the lexer/parser handles proper Modelica syntax for real operations
// also tests that the MetaModelica realAdd operator works
//

model A
constant Real x = 1+.2 "1+.2";
constant Real y = 1+. 2 "1+. 2"; // Invalid Modelica syntax
constant Real z = 1+ .2 "1+ .2";
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end A;

// Result:
// Error processing file: RealOpLexerModelica.mo
// Failed to parse file: RealOpLexerModelica.mo!
//
// [openmodelica/parser/RealOpLexerModelica.mo:11:23-11:24:writable] Error: No viable alternative near token: 2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: RealOpLexerModelica.mo!
//
// Execution failed!
// endResult
