// name: ErrorInvalidPattern3
// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica
package ErrorInvalidPattern3

uniontype Ut
  record UT
    Integer exp;
  end UT;
end Ut;

function fn
  input Ut ut;
  output String str;
algorithm
  str := match ut
    case UT(exp = 1, exp = 2, exp = 3) then "fail1";
    else "fail2";
  end match;
end fn;

constant String str = fn(UT(1));

end ErrorInvalidPattern3;

// Result:
// Error processing file: ErrorInvalidPattern3.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/ErrorInvalidPattern3.mo:18:10-18:40:writable] Error: Invalid named fields: exp,exp. Valid field names: exp.
// Error: Error occurred while flattening model ErrorInvalidPattern3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
