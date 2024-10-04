// name: ExtendsShort2
// keywords:
// status: correct
//
//

package P1
  package P2
    model B
      Real x;
    equation
      P3.f(x);
    end B;
  end P2;

  package P3
    function f
      input Real x;
    end f;
  end P3;
end P1;

model ExtendsShort3
  model M = P1.P2.B;
  M a1;
  M a2;
end ExtendsShort3;

// Result:
// function P1.P3.f
//   input Real x;
// end P1.P3.f;
//
// class ExtendsShort3
//   Real a1.x;
//   Real a2.x;
// equation
//   P1.P3.f(a1.x);
//   P1.P3.f(a2.x);
// end ExtendsShort3;
// endResult
