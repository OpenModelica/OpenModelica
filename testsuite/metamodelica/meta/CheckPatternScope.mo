// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica

model CheckInputScope

package P

function test
  input Integer x;
algorithm
  _ := match (x,y)
    local Integer y;
    case (x,y) then ();
  end match;
end test;

end P;

algorithm
  P.test(1);
end CheckInputScope;

// Result:
// Error processing file: CheckPatternScope.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/CheckPatternScope.mo:12:3-15:12:writable] Error: Variable y not found in scope CheckInputScope.P.test.
// Error: Error occurred while flattening model CheckInputScope
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
