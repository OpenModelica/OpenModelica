// name:     InnerOuter2
// keywords: dynamic scope, lookup
// status:   correct
//
//  components with inner prefix references an outer component with
//  the same name and one variable is generated for all of them.
//
class A
  outer Real TI;
  class B
    Real TI;
    class C
      Real TI;
      class D
  outer Real TI; //
      end D;
      D d;
    end C;
    C c;
  end B;
  B b;
end A;
class E
  inner Real TI;
  class F
    inner Real TI;
    class G
      Real TI;
      class H
  A a;
      end H;
      H h;
    end G;
    G g;
  end F;
  F f;
end E;
class I
  inner Real TI;
  E e;
  // e.f.g.h.a.TI, e.f.g.h.a.b.c.d.TI, and e.f.TI is the same variable
  // But e.f.TI, e.TI and TI are different variables
  A a; // a.TI, a.b.c.d.TI, and TI is the same variable
end I;

// Result:
// class I
//   Real TI;
//   Real e.TI;
//   Real e.f.TI;
//   Real e.f.g.TI;
//   Real e.f.g.h.a.b.TI;
//   Real e.f.g.h.a.b.c.TI;
//   Real a.b.TI;
//   Real a.b.c.TI;
// end I;
// endResult
