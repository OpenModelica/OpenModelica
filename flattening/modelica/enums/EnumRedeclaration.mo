// name:     EnumRedeclaration
// keywords: enumeration enum
// status:   correct
//
// cflags:   -i=Ex
//


model Ex
  class Foo1
    extends Foo(redeclare type T = enumeration(One, Two));
  end Foo1;
  class Foo2 = Foo(redeclare type T = enumeration(One));
  parameter Foo1.T f1 = Foo1.T.Two;
  parameter Foo2.T f2 = Foo2.T.One;
end Ex;

class Foo
  replaceable type T = enumeration(:);
end Foo;

// Result:
// class Ex
//   parameter enumeration(One, Two) f1 = Ex.Foo1.T.Two;
//   parameter enumeration(One) f2 = Ex.Foo2.T.One;
// end Ex;
// endResult
