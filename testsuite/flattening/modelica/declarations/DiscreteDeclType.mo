// name: DiscreteDeclType
// keywords: discrete
// status: correct
//
// Tests the discrete prefix on a regular type
//

class DiscreteDeclType
  discrete Real rDiscrete = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end DiscreteDeclType;

// Result:
// class DiscreteDeclType
//   discrete Real rDiscrete = 1.0;
// end DiscreteDeclType;
// endResult
