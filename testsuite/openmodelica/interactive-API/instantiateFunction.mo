model Base
  function Foo
    parameter Integer foo = 0;
  end Foo;
end Base;

model Derived
  extends Base;
end Derived;
