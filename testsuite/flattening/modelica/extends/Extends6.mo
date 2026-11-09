// name:     Extends6
// keywords: extends
// status:   correct
//
// Testing that you can extend packages and use its constants in instances of
// models defined in that package.

package PartialMedium

  constant Integer nX = 3;
  constant Real reference_X[nX] = fill(1/nX, nX);

  model BaseProperties
    Real[nX] X(start=reference_X[1:nX]);
  end BaseProperties;

end PartialMedium;

package TableBased
  extends PartialMedium;
end TableBased;

package Glycol
  extends TableBased;
end Glycol;

model Extends6
  package Medium = Glycol;
  Glycol.BaseProperties medium;
end Extends6;

// Result:
// class Extends6
//   Real medium.X[1](start = 0.3333333333333333);
//   Real medium.X[2](start = 0.3333333333333333);
//   Real medium.X[3](start = 0.3333333333333333);
// end Extends6;
// endResult
