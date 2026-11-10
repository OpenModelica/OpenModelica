// name:     MissingModifiersPackages.mo [BUG: #3095]
// keywords: class modification handling
// status:   correct
//

package Types
  type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
  type SpecificEnthalpy1 = SpecificEnergy;
  type SpecificEnthalpy = SpecificEnthalpy1(min = -1.0e10, max = 1.e10, nominal = 1.e6);
end Types;

package A
 extends Types;
 model M
  parameter SpecificEnthalpy h = 1;
 end M;
end A;

package B
 extends A(SpecificEnthalpy(start = 1.0e5, nominal = 5.0e5));
end B;

package C = B;

model MissingModifiersPackages
 A.M m1;
 B.M m2;
 C.M m3;
end MissingModifiersPackages;

// Result:
// class MissingModifiersPackages
//   parameter Real m1.h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0) = 1.0;
//   parameter Real m2.h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, start = 100000.0, nominal = 500000.0) = 1.0;
//   parameter Real m3.h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, start = 100000.0, nominal = 500000.0) = 1.0;
// end MissingModifiersPackages;
// endResult
