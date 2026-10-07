// name: ErrorMatchInOut1.mo
// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica
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
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/ErrorMatchInOut1.mo:11:3-13:12:writable] Error: Variable strx not found in scope ErrorMatchInOut1.fn.
// Error: Error occurred while flattening model ErrorMatchInOut1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
