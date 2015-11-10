// name:     DeclarationOrder2
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
  model D
//    C c[size(c2,1)]; // causes ininite loop
    C c2[n];
    parameter Integer n=1;
  end D;
  constant Real pi=3.14;
end A;

model DeclarationOrder2
  A.D d;
end DeclarationOrder2;

// Result:
// class DeclarationOrder2
//   Real d.c2[1].y(start = d.c2[1].x);
//   parameter Real d.c2[1].x = 3.14;
//   parameter Integer d.n = 1;
// equation
//   der(d.c2[1].y) = d.c2[1].x;
// end DeclarationOrder2;
// endResult
