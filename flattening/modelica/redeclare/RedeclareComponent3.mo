// name:     RedeclareComponent3
// keywords: redeclare component modifier
// status:   correct
//
// Tests that modifiers are merged when redeclaring components.
//

class C
  replaceable Real r(max = 2.0);
end C;

class C2
  extends C;
  redeclare replaceable Real r(min = 1.0);
end C2;

class RedeclareComponent3
  extends C2;

  redeclare Real r(start = 1.0);
  C2 c;
end RedeclareComponent3;

// Result:
// class RedeclareComponent3
//   Real r(start = 1.0, max = 2.0);
//   Real c.r(min = 1.0, max = 2.0);
// end RedeclareComponent3;
// endResult
