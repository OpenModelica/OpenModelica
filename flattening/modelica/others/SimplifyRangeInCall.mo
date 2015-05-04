// name:     SimplifyRangeInCall
// keywords: simplify call range
// status:   correct
//
// Checks that ranges in calls are simplified.
//

class SimplifyRangeInClass
  Real r[2] = sin(1:2);
end SimplifyRangeInClass;

// Result:
// class SimplifyRangeInClass
//   Real r[1];
//   Real r[2];
// equation
//   r = {0.8414709848078965, 0.9092974268256817};
// end SimplifyRangeInClass;
// endResult
