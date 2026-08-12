// name: ErrorInvalidPattern1
// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica

package ErrorInvalidPattern1

function fn
  input String str;
  output String outStr;
algorithm
  outStr := match str
    case (str+"") then str;
  end match;
end fn;

constant String str = fn("");

end ErrorInvalidPattern1;

// Result:
// Error processing file: ErrorInvalidPattern1.mo
// [metamodelica/meta/ErrorInvalidPattern1.mo:13:10-13:19:writable] Error: Invalid pattern: str + "" of type String
// Error: Error occurred while flattening model ErrorInvalidPattern1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
