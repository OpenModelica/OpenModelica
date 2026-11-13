// name: DiscreteDeclRecord
// keywords: discrete
// status: correct
//
// Tests the discrete prefix on a record type
//

record DiscreteRecord
  Real r;
end DiscreteRecord;

model DiscreteDeclRecord
  discrete DiscreteRecord dr;
equation
  when initial() then
    dr.r = 1.0;
  end when;
end DiscreteDeclRecord;

// Result:
// class DiscreteDeclRecord
//   discrete Real dr.r;
// equation
//   when initial() then
//     dr.r = 1.0;
//   end when;
// end DiscreteDeclRecord;
// endResult
