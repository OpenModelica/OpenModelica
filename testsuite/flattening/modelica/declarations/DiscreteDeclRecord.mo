// name: DiscreteDeclRecord
// keywords: discrete
// status: correct
//
// Tests the discrete prefix on a record type
//

record DiscreteRecord
  Real r;
end DiscreteRecord;

class DiscreteDeclRecord
  discrete DiscreteRecord dr;
equation
  dr.r = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end DiscreteDeclRecord;

// Result:
// function DiscreteRecord "Automatically generated record constructor for DiscreteRecord"
//   input Real r;
//   output DiscreteRecord res;
// end DiscreteRecord;
//
// class DiscreteDeclRecord
//   discrete Real dr.r;
// equation
//   dr.r = 1.0;
// end DiscreteDeclRecord;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
