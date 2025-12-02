// name: Assert4
// keywords:
// status: correct
//

model Assert4
  parameter AssertionLevel level = AssertionLevel.warning;
equation
  assert(time > 2, "message", level);
end Assert4;

// Result:
// class Assert4
//   final parameter enumeration(warning, error) level = AssertionLevel.warning;
// equation
//   assert(time > 2.0, "message", AssertionLevel.warning);
// end Assert4;
// endResult
