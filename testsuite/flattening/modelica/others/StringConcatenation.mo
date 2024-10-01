// name: StringConcatenation
// keywords: string
// status: correct
//
// Tests string concatenation
//

model StringConcatenation
  String s;
equation
  s = "te" + "st";
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end StringConcatenation;

// Result:
// class StringConcatenation
//   String s;
// equation
//   s = "test";
// end StringConcatenation;
// endResult
