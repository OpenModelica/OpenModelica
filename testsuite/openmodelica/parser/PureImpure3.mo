// name: PureImpure3
// keywords:
// status: incorrect
// cflags: -d=newInst --std=3.2 --strict
//
// Checks that pure/impure are not allowed in Modelica 3.2 when using --strict.
//

pure function f1
end f1;

impure function f2
end f2;

model PureImpure3
end PureImpure3;

// Result:
// Error processing file: PureImpure3.mo
// Failed to parse file: PureImpure3.mo!
//
// [openmodelica/parser/PureImpure3.mo:9:1-9:5:writable] Error: Parser error: Unexpected token near: pure (IDENT)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: PureImpure3.mo!
//
// Execution failed!
// endResult
