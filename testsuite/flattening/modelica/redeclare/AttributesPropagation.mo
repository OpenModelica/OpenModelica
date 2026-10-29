// name:     AttributesPropagation.mo
// keywords: tests if attributes are properly propagated from original to redeclared component
// status:   correct
//
// A redeclaration without type prefixes keeps the parameter prefix of the
// original declaration (MLS 3.7, section 7.3). Reduced from the borehole
// segment of the Buildings library, where matSoi is redeclared this way.
//

model AttributesPropagation
  record Generic
    Real k(unit = "W/(m.K)") "Heat conductivity";
    Real d(unit = "kg/m3") "Density";
  end Generic;

  record Concrete = Generic(k = 3.1, d = 2000);

  model Segment
    replaceable parameter Generic matSoi;
    final parameter Real kSoi = matSoi.k;
  end Segment;

  Segment seg(redeclare Concrete matSoi);
end AttributesPropagation;

// Result:
// class AttributesPropagation
//   parameter Real seg.matSoi.k(unit = "W/(m.K)") = 3.1 "Heat conductivity";
//   parameter Real seg.matSoi.d(unit = "kg/m3") = 2000.0 "Density";
//   final parameter Real seg.kSoi = seg.matSoi.k;
// end AttributesPropagation;
// endResult
