// name:     RedeclareComponent1
// keywords: redeclare component
// status:   correct
//
// Tests simple redeclaration of an inherited component.
//

class C
  replaceable Real r;
end C;

class RedeclareComponent1
  extends C;

  redeclare Real r(start = 1.0);
end RedeclareComponent1;

// Result:
// class RedeclareComponent1
//   Real r(start = 1.0);
// end RedeclareComponent1;
// endResult
