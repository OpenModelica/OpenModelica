// name: ErrorLocalElement1
// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica

class ErrorLocalElement1
  function fn
    input Integer i;
    output Integer o;
  algorithm
    o := match i
      local
        type T = Integer;
        T t;
      case t then t;
    end match;
  end fn;

  constant Integer i = fn(1);
end ErrorLocalElement1;

// Result:
// Error processing file: ErrorLocalElement1.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/ErrorLocalElement1.mo:11:5-16:14:writable] Error: Only components without direction are allowed in local declarations, got: type T = Integer
// Error: Error occurred while flattening model ErrorLocalElement1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
