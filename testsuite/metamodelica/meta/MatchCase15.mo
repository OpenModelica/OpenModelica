// name: MatchCase15
// cflags: -g=MetaModelica -d=gen -d=-newInst
// status: correct
// suite: metamodelica

package MatchCase15

function platform
  output String str = "Linux";
end platform;

function winCitation
  output String outString;
algorithm
  outString:=
  matchcontinue ()
    case ()
      algorithm
        "WIN32" := platform();
      then
        "\"";
    case () then "";
  end matchcontinue;
end winCitation;

constant String citation = winCitation();

end MatchCase15;

// Result:
// function MatchCase15.platform
//   output String str = "Linux";
// end MatchCase15.platform;
//
// function MatchCase15.winCitation
//   output String outString;
// algorithm
//   outString := matchcontinue ()
//       case ()
//         algorithm
//           "WIN32" := "Linux";
//         then
//           "\"";
//       case () then "";
//     end matchcontinue;
// end MatchCase15.winCitation;
//
// class MatchCase15
//   constant String citation = "";
// end MatchCase15;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
