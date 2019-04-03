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
end A;

// Result:
// Error processing file: RealOpLexerModelica.mo
// Failed to parse file: RealOpLexerModelica.mo!
//
// [openmodelica/parser/RealOpLexerModelica.mo:10:21-10:23:writable] Warning: Treating .2 as 0.2. This is not standard Modelica and only done for compatibility with old code. Support for this feature may be removed in the future.
// [openmodelica/parser/RealOpLexerModelica.mo:12:22-12:24:writable] Warning: Treating .2 as 0.2. This is not standard Modelica and only done for compatibility with old code. Support for this feature may be removed in the future.
// [openmodelica/parser/RealOpLexerModelica.mo:11:23-11:24:writable] Error: No viable alternative near token: 2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: RealOpLexerModelica.mo!
//
// Execution failed!
// endResult
