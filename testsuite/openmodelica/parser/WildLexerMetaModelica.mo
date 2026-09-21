// name: WildLexerMetaModelica
// status: incorrect
// cflags: -g=MetaModelica -d=-newInst
// suite: antlr
//

class WildLexerModelica
Real _ = 1.0;
end WildLexerModelica;

// Result:
// Error processing file: WildLexerMetaModelica.mo
// Failed to parse file: WildLexerMetaModelica.mo!
//
// [openmodelica/parser/WildLexerMetaModelica.mo:8:1-8:5:writable] Error: No viable alternative near token: Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: WildLexerMetaModelica.mo!
//
// Execution failed!
// endResult
