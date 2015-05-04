// name:     ScopeDeclaration4
// keywords: scoping,extends
// status:   incorrect
//
// The extended class should be instantiated by itself, and the
// defined componends are copied into the extending class afterwards.
// This means that the following should not be allowed, since y is not
// known in A.
//

class A
  Real x;
equation
  x = y;
end A;

class ScopeDeclaration4
  Real y;
  extends A;
end ScopeDeclaration4;
