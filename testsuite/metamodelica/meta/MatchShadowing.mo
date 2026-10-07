// name: MatchShadowing
// status: incorrect
// cflags: +g=MetaModelica -d=-newInst
// suite: metamodelica

model MatchShadowing

function f
  input Real x;
  output Real y;
algorithm
  y := match x
    local
      Real x;
    case x then if x > 200000.0 then x else f(x+1.0);
  end match;
end f;

Real r = f(0.5);

end MatchShadowing;

// Result:
// Error processing file: MatchShadowing.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/MatchShadowing.mo:14:7-14:13:writable] Error: Local variable 'x' shadows another variable.
// Error: Error occurred while flattening model MatchShadowing
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
