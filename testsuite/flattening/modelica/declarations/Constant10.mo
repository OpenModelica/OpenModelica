// name:     Constant10
// keywords: constant, package
// status:   correct
//
// Constants in packages can lead to infinite recursion in lookup.
// In example below, the package A would be instantiated over and over again unless this is caught by
// investigating current scope.


package A
  constant Real x=1;
  constant Real y=A.x;
end A;

model test
  Real x=A.y;
end test;

// Result:
// class test
//   Real x = 1.0;
// end test;
// endResult
