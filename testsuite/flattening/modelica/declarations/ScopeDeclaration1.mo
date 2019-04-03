// name:     ScopeDeclaration1
// keywords: scoping,declaration
// status:   correct
//
// Modelica was a originally defined as a strict define-before-use language.
// That was changed in Modelica 1.4, and thus the following is legal.

class ScopeDeclaration1
  Real a = -a;
end ScopeDeclaration1;

// Result:
// class ScopeDeclaration1
//   Real a = -a;
// end ScopeDeclaration1;
// endResult
