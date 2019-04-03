// name:     RedeclareComponent2
// keywords: redeclare component
// status:   correct
//
// Tests redeclaration of redeclared components.
//

class C
  replaceable Real r;
end C;

class C2
  extends C;
  redeclare replaceable Real r(min = 1.0);
end C2;

class RedeclareComponent2
  extends C2;

  redeclare Real r(start = 1.0);
  C2 c;
end RedeclareComponent2;

// Result:
// class RedeclareComponent2
//   Real r(start = 1.0);
//   Real c.r(min = 1.0);
// end RedeclareComponent2;
// endResult
