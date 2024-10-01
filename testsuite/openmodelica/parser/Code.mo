// name: Code (3.2)
// status: correct
//
// MSL 3.2 includes a class named Code; it's not referenced anywhere so
// we only need to parse the identifiers.
//

class Code
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Code;
// Result:
// class Code
// end Code;
// endResult
