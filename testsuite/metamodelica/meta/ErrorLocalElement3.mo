// name: ErrorLocalElement3
// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica

class ErrorLocalElement3
  function fn
    input Integer i;
    output Integer o;
  algorithm
    o := match i
      local
        list<int> t;
      case t then t;
    end match;
  end fn;

  constant Integer i = fn(1);
end ErrorLocalElement3;

// Result:
// Error processing file: ErrorLocalElement3.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/ErrorLocalElement3.mo:13:9-13:20:writable] Error: Class int not found in scope ErrorLocalElement3.fn.$match scope$.list.
// [metamodelica/meta/ErrorLocalElement3.mo:11:5-15:14:writable] Error: Internal error Patternm.addLocalDecls failed
// [metamodelica/meta/ErrorLocalElement3.mo:13:9-13:20:writable] Error: Class int not found in scope ErrorLocalElement3.fn.$match scope$.list.
// [metamodelica/meta/ErrorLocalElement3.mo:11:5-15:14:writable] Error: Internal error Patternm.addLocalDecls failed
// Error: Error occurred while flattening model ErrorLocalElement3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
