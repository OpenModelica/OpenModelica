// name: EmptyWithin
// status: correct
//
// Checks that within; gives the top level scope

within;

class EmptyWithin
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end EmptyWithin;
// Result:
// class EmptyWithin
// end EmptyWithin;
// endResult
