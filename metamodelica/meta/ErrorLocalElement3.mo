// name: ErrorLocalElement3
// cflags: +g=MetaModelica
// status: incorrect

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
// [metamodelica/meta/ErrorLocalElement3.mo:12:9-12:20:writable] Error: Class int not found in scope ErrorLocalElement3.fn.$match scope$.list.
// [metamodelica/meta/ErrorLocalElement3.mo:10:5-14:14:writable] Error: Internal error Patternm.addLocalDecls failed
// [metamodelica/meta/ErrorLocalElement3.mo:12:9-12:20:writable] Error: Class int not found in scope ErrorLocalElement3.fn.$match scope$.list.
// [metamodelica/meta/ErrorLocalElement3.mo:10:5-14:14:writable] Error: Internal error Patternm.addLocalDecls failed
// Error: Error occurred while flattening model ErrorLocalElement3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
