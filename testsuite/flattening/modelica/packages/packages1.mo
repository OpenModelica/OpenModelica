// name:     package-s-1
// keywords: package, declaration
// status:   correct

//
//   Instantiation of models residing in packages.
//

package P

class C
  Real x;
end C;

end P;

package Modelica
  package SIunits
    type Area = Real (final quantity="Area", final unit="m2");
  end SIunits;
end Modelica;

model World
  P.C c;
  Modelica.SIunits.Area a;
end World;

// Result:
// class World
//   Real c.x;
//   Real a(quantity = "Area", unit = "m2");
// end World;
// [flattening/modelica/packages/packages1.mo:12:3-12:9:writable] Warning: Components are deprecated in class.
//
// endResult
