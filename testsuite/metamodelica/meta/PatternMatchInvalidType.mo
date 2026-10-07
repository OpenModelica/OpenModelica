// status: incorrect
// cflags: +g=MetaModelica -d=-newInst
// suite: metamodelica

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
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/PatternMatchInvalidType.mo:10:10-10:15:writable] Error: Type mismatch in pattern {}
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
