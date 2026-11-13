// name: DiscreteDeclType
// keywords: discrete
// status: correct
//
// Tests the discrete prefix on a regular type
//

model DiscreteDeclType
  discrete Real rDiscrete;
equation
  when initial() then
    rDiscrete = 1.0;
  end when;
end DiscreteDeclType;

// Result:
// class DiscreteDeclType
//   discrete Real rDiscrete;
// equation
//   when initial() then
//     rDiscrete = 1.0;
//   end when;
// end DiscreteDeclType;
// endResult
