// name: ErrorMatchInOut1.mo
// cflags: +g=MetaModelica
// status: incorrect
package ErrorMatchInOut1

function fn
  input String str;
  output String outStr;
algorithm
  outStr := match strx
    case str then str;
  end match;
end fn;

constant String str = fn("");

end ErrorMatchInOut1;
// Result:
// Error processing file: ErrorMatchInOut1.mo
// [metamodelica/meta/ErrorMatchInOut1.mo:10:3-12:12:writable] Error: Variable strx not found in scope ErrorMatchInOut1.fn.
// Error: Error occurred while flattening model ErrorMatchInOut1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
