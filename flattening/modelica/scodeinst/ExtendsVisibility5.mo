// name: ExtendsVisibility5
// keywords: extends visibility
// status: correct
// cflags: -d=newInst
//

model A
  function f
    output Real x = 1.0;
  end f;
end A;

model B
protected
  extends A;
end B;

model C
  extends A;
end C;

model ExtendsVisibility5
  Real x = c.f();
  C c;
  B b;
end ExtendsVisibility5;

// Result:
// class ExtendsVisibility5
//   Real x = 1.0;
// end ExtendsVisibility5;
// endResult
