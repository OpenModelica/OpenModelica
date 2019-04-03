// status: incorrect
// cflags: +g=MetaModelica

model PatternMatchInvalidType

public function test1
algorithm
  _ := match (1)
    case ({}) then ();
    else fail();
  end match;
end test1;

algorithm
  test1();
end PatternMatchInvalidType;

// Result:
// Error processing file: PatternMatchInvalidType.mo
// [metamodelica/meta/PatternMatchInvalidType.mo:9:10-9:15:writable] Error: Type mismatch in pattern {}
// expression type:
//   Integer
// pattern type:
//   list<#T_UNKNOWN#>
// Error: Error occurred while flattening model PatternMatchInvalidType
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
