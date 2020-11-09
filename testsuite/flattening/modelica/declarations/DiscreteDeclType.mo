// name: DiscreteDeclType
// keywords: discrete
// status: correct
// cflags: -d=-newInst
//
// Tests the discrete prefix on a regular type
//

class DiscreteDeclType
  discrete Real rDiscrete = 1.0;
end DiscreteDeclType;

// Result:
// class DiscreteDeclType
//   discrete Real rDiscrete = 1.0;
// end DiscreteDeclType;
// endResult
