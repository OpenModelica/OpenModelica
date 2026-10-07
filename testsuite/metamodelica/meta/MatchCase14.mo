// name: MatchCase14
// cflags: -g=MetaModelica -d=gen -d=-newInst
// status: correct
// teardown_command: rm -f MatchCase14_*
// suite: metamodelica
package MatchCase14

function fn
  input Integer i;
  output Integer outInt;
algorithm
  outInt := match i
    case -3 then -3;
  end match;
end fn;

constant Integer i = fn(-3);

end MatchCase14;
// Result:
// function MatchCase14.fn
//   input Integer i;
//   output Integer outInt;
// algorithm
//   outInt := match (i)
//     case (-3) then -3;
//   end match;
// end MatchCase14.fn;
//
// class MatchCase14
//   constant Integer i = -3;
// end MatchCase14;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
