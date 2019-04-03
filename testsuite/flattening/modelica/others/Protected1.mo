// name:     Protected1
// keywords: protected
// status:   correct
//
// This file tests information hiding using the 'protect' keyword
//
// The file is not valid, the compiler should complaint about y and a
// being protected.

class A
  Real a = 1;
end A;

class B
  Real x = 1;
protected
  extends A;
  Real y = 1;
end B;

model Protected1
  B a(y=18);
  B b(a=3);
  B c;
end Protected1;

// Result:
// class Protected1
//   protected Real a.a = 1.0;
//   Real a.x = 1.0;
//   protected Real a.y = 18.0;
//   protected Real b.a = 3.0;
//   Real b.x = 1.0;
//   protected Real b.y = 1.0;
//   protected Real c.a = 1.0;
//   Real c.x = 1.0;
//   protected Real c.y = 1.0;
// end Protected1;
// endResult
