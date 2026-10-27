// name:     DeclarationOrder1
// keywords: declaration order
// status:   correct
//
// A model or component is available in its entire scope,
// even before before it is declared.

package A
  model B
    extends C;
  end B;
  model C
    Real y(start=x);
    parameter Real x=pi;
  equation
    der(y)=x;
  end C;
  constant Real pi=3.14;
end A;

model DeclarationOrder1
  A.B b;
end DeclarationOrder1;

// Result:
// class DeclarationOrder1
//   Real b.y(start = b.x);
//   parameter Real b.x = 3.14;
// equation
//   der(b.y) = b.x;
// end DeclarationOrder1;
// endResult
