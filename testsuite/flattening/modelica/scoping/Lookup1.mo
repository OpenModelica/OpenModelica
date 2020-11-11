// name:     Lookup1
// keywords: scoping
// status:   correct
// cflags: -d=-newInst
//
// Names are looked up in a partially defined class.
//

class Lookup1
  constant Real a = 3.0;
  class B
    Real c = a;
  end B;
  B b;
end Lookup1;


// Result:
// class Lookup1
//   constant Real a = 3.0;
//   Real b.c = 3.0;
// end Lookup1;
// endResult
