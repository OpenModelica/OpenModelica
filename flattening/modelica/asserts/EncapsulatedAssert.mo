// status: correct
encapsulated model EncapsulatedAssert

Real x;

equation
  assert(x>1,"message");

  x = 10;

end EncapsulatedAssert;
// Result:
// class EncapsulatedAssert
//   Real x;
// equation
//   assert(x > 1.0, "message");
//   x = 10.0;
// end EncapsulatedAssert;
// endResult
