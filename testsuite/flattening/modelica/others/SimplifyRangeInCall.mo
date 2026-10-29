// name:     SimplifyRangeInCall
// keywords: simplify call range
// status:   correct
//
// Checks that ranges in calls are simplified.
//

model SimplifyRangeInClass
  Real r[2] = sin(1:2);
end SimplifyRangeInClass;

// Result:
// class SimplifyRangeInClass
//   Real r[1];
//   Real r[2];
// equation
//   r = array(sin((1.0:2.0)[$i0]) for $i0 in 1:2);
// end SimplifyRangeInClass;
// endResult
