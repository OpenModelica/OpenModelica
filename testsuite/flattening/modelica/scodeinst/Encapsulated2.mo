// name: Encapsulated2
// keywords: operator
// status: correct
//
// Checks that builtin functions can be accessed from an encapsulated scope.
//

encapsulated model Encapsulated2
  Real x = div(1, time);
end Encapsulated2;

// Result:
// class Encapsulated2
//   Real x = div(1.0, time);
// end Encapsulated2;
// endResult
