// name: InnerOuter2
// keywords:
// status: correct
//
// inner/outer example from the specification.
//

model A
  model B
    model C
      model D
        outer Real TI;
      end D;

      Real TI;
      D d;
    end C;

    Real TI;
    C c;
  end B;

  outer Real TI;
  B b;
end A;

model E
  model F
    model G
      model H
        A a;
      end H;

      Real TI;
      H h;
    end G;

    inner Real TI;
    G g;
  end F;

  inner Real TI;
  F f;
end E;

model I
  inner Real TI;
  E e;
  A a;
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
