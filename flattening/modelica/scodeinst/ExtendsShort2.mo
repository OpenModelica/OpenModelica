// name: ExtendsShort2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

package P
  function f
    input Real x;
    output Real y;
  algorithm
    y := f2(x);
  end f;

  function f2
    input Real x;
    output Real y = x * 2;
  end f2;
end P;

model ExtendsShort2
  function f = P.f;
  Real x = f(2.0);
end ExtendsShort2;

// Result:
// class ExtendsShort2
//   Real x = 4.0;
// end ExtendsShort2;
// endResult
