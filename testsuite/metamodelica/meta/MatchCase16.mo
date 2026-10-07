// name: MatchCase16
// cflags: -g=MetaModelica -d=gen -d=-newInst
// status: correct
// suite: metamodelica

package MatchCase16

function fn
  input String str;
  output String outStr;
algorithm
  "" := match str
    case _ then str;
  end match;
  outStr := "";
end fn;

constant String str = fn("");

end MatchCase16;

// Result:
// function MatchCase16.fn
//   input String str;
//   output String outStr;
// algorithm
//   "" := str;
//   outStr := "";
// end MatchCase16.fn;
//
// class MatchCase16
//   constant String str = "";
// end MatchCase16;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
