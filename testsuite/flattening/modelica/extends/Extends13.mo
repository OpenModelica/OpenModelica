// name:     Extends13
// keywords: extends
// status:   correct
//
// Testing extension of local class with the same name as the extending class.
//

model A
  Real x;
end A;

model Test
  extends Test;
  model Test
    extends A;
  end Test;
end Test;

// Result:
// class Test
//   Real x;
// end Test;
// endResult
