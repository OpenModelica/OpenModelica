// name:     ScopeDeclaration3
// keywords: scoping,declaration
// status:   correct
//
// Modelica is a strict define-before-use language. A variable must be
// fully instantiated (defined after end of declaration, semicolon)
// before it is referenced.
// This has been changed from Modelica v1.4. Now use before declaration
//is allowed.

class ScopeDeclaration3
  Real x;
equation
  x = y;
public
  Real y;
end ScopeDeclaration3;

// Result:
// class ScopeDeclaration3
//   Real x;
//   Real y;
// equation
//   x = y;
// end ScopeDeclaration3;
// [flattening/modelica/declarations/ScopeDeclaration3.mo:12:3-12:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/ScopeDeclaration3.mo:16:3-16:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/ScopeDeclaration3.mo:14:3-14:8:writable] Warning: Equation sections are deprecated in class.
//
// endResult
