// name: ErrorLocalElement2
// cflags: +g=MetaModelica
// status: incorrect

class ErrorLocalElement2
  function fn
    input Integer i;
    output Integer o;
  algorithm
    o := match i
      local
        input Integer t;
      case t then t;
    end match;
  end fn;

  constant Integer i = fn(1);
end ErrorLocalElement2;

// Result:
// Error processing file: ErrorLocalElement2.mo
// [metamodelica/meta/ErrorLocalElement2.mo:10:5-14:14:writable] Error: Only components without direction are allowed in local declarations, got: input Integer t
// Error: Error occurred while flattening model ErrorLocalElement2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
