// name: MatchCase16
// cflags: -g=MetaModelica -d=gen
// status: correct

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
// endResult
