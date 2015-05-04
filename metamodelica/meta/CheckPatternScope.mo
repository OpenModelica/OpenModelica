// cflags: +g=MetaModelica
// status: incorrect

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
// [metamodelica/meta/CheckPatternScope.mo:11:3-14:12:writable] Error: Variable y not found in scope CheckInputScope.P.test.
// Error: Error occurred while flattening model CheckInputScope
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
