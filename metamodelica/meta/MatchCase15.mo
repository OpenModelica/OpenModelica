// name: MatchCase15
// cflags: -g=MetaModelica -d=gen
// status: correct

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
// endResult
