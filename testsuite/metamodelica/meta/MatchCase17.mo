// name: MatchCase17
// cflags: +g=MetaModelica -d=-newInst
// status: correct
// suite: metamodelica

package MatchCase17

function fn
  input String str;
  output String outStr;
algorithm
  outStr := match ""
    case _ then str;
  end match;
end fn;

constant String str = fn("");

end MatchCase17;

// Result:
// function MatchCase17.fn
//   input String str;
//   output String outStr;
// algorithm
//   outStr := str;
// end MatchCase17.fn;
//
// class MatchCase17
//   constant String str = "";
// end MatchCase17;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
