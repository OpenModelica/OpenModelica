// name: MetaModelicaStringOpModelicaLexer
// keywords: string, lexing
// status: incorrect
//
// tests that the lexer/parser handles proper Modelica syntax for string operations

model MetaModelicaStringOpModelicaLexer
constant String s = "1" +& "2";
end MetaModelicaStringOpModelicaLexer;

// Result:
// Error processing file: MetaModelicaStringOpModelicaLexer.mo
// Failed to parse file: MetaModelicaStringOpModelicaLexer.mo!
//
// [openmodelica/parser/MetaModelicaStringOpModelicaLexer.mo:8:28-8:28:writable] Error: Lexer got '& ' but failed to recognize the rest: '"2";
// end Me'
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: MetaModelicaStringOpModelicaLexer.mo!
//
// Execution failed!
// endResult
