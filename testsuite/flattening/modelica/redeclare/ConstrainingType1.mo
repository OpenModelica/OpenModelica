// name:     ConstrainType1
// keywords: redeclare component constrainedby
// status:   incorrect
//
// Tests that the constraining class of a replaceable component is implicitly
// the type of the component if no constraining class is defined.
//

model C
 replaceable Real r constrainedby Real(start = 3.0);
end C;

class ConstrainType1
  extends C;

  redeclare Real r(min = 3.0);
end ConstrainType1;

// Result:
// class ConstrainType1
//   Real r(min = 3.0, start = 3.0);
// end ConstrainType1;
// endResult
