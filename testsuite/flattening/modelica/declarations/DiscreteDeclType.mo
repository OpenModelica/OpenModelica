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
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
