// name: ClassExtends3
// keywords: class, extends
// status: correct
//
// Tests that partial packages may be extended, and functions inside
// redeclared. Constants inherited will use the full functions to calculate
// their values.
//

partial package A
  function usePart
    input Integer a;
    output Integer b;
  algorithm
    b := part2(part(a));
  end usePart;

  replaceable partial function part
    input Integer a;
    output Integer b;
  end part;

  replaceable partial function part2
    input Integer a;
    output Integer b;
  end part2;

  constant Integer X = usePart(1);
  constant Integer Y = part(1);
end A;

package B
  extends A;
  redeclare function extends part
  algorithm
    b := a;
  end part;
  redeclare function extends part2
  algorithm
    b := a;
  end part2;
  Integer b = usePart(integer(time));
end B;

model ClassExtends3
  Integer b = B.usePart(integer(time));
end ClassExtends3;

// Result:
// function B.part
//   input Integer a;
//   output Integer b;
// algorithm
//   b := a;
// end B.part;
//
// function B.part2
//   input Integer a;
//   output Integer b;
// algorithm
//   b := a;
// end B.part2;
//
// function B.usePart
//   input Integer a;
//   output Integer b;
// algorithm
//   b := B.part2(B.part(a));
// end B.usePart;
//
// class ClassExtends3
//   Integer b = B.usePart(integer(time));
// end ClassExtends3;
// endResult
