// name: LhsIf
// keywords: if flattening
// status: correct
//
// Tests flattening of if-expressions, to make sure that the parentheses are
// kept in the flattened model.
//

model LhsIf
  Real x, y, z;
equation
  (if x > 1 then y else z) = x;
end LhsIf;

// Result:
// class LhsIf
//   Real x;
//   Real y;
//   Real z;
// equation
//   (if x > 1.0 then y else z) = x;
// end LhsIf;
// endResult
