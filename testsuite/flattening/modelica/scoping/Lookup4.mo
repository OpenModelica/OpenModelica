// name:     Lookup4
// keywords: scoping
// status:   correct
//
// Constants can be referred to using names of previously defined
// classes.
//
// Note that Container must satisfy the requirement of a package.

class Container
  constant Real a = 3.0;
end Container;

class Lookup4
  Real b = Container.a;
end Lookup4;


// Result:
// class Lookup4
//   Real b = 3.0;
// end Lookup4;
// endResult
