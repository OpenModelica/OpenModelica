// name:     Lookup2
// keywords: scoping
// status:   correct
//
// Note that in order to use Lookup2Package.a
// Either Lookup2Package must satisfy the requirements of
// a package
// or a must be an encapsulated element
// (Modelica 1.4 spec 3.1.1.2)

package Lookup2Package
  constant Real a = 3.0;
  class B
    Real c = Lookup2Package.a;
  end B;
end Lookup2Package;

model Lookup2
  extends Lookup2Package.B;
end Lookup2;


// Result:
// class Lookup2
//   Real c = 3.0;
// end Lookup2;
// endResult
