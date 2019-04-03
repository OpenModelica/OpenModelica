// name: MatchShadowing
// status: incorrect
// cflags: +g=MetaModelica

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
// [metamodelica/meta/MatchShadowing.mo:13:7-13:13:writable] Error: Local variable 'x' shadows another variable.
// Error: Error occurred while flattening model MatchShadowing
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
