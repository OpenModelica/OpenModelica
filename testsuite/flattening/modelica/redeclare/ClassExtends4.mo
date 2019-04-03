// name: ClassExtends4
// keywords: class, extends
// status: correct
//
// Tests that partial packages may be extended, and functions inside
// redeclared.
//

partial package A
  function usePart
    input Integer a;
    output Integer b;
  algorithm
    b := part(a);
  end usePart;

  replaceable partial function part
    input Integer a;
    output Integer b;
  end part;

  replaceable partial function part2
    input Integer a;
    output Integer b;
  end part2;
end A;

package B
  extends A;

  redeclare function extends part2
  algorithm
    b := a;
  end part2;

  redeclare function extends part
  algorithm
    b := part2(a);
  end part;

  Integer b = usePart(integer(time));
end B;

model ClassExtends4
  Integer b = B.usePart(integer(time));
end ClassExtends4;

// Result:
// function B.part
//   input Integer a;
//   output Integer b;
// algorithm
//   b := B.part2(a);
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
//   b := B.part(a);
// end B.usePart;
//
// class ClassExtends4
//   Integer b = B.usePart(integer(time));
// end ClassExtends4;
// endResult
