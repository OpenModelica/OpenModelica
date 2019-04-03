// name: MatchCase17
// cflags: +g=MetaModelica
// status: correct

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
// endResult
