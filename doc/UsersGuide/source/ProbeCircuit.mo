package EQ
  connector Pin
    Real v;
    flow Real i;
  end Pin;
  model R
    parameter Real r = 2;
    Pin p, n;
  equation
    p.v - n.v = r*p.i;
    p.i + n.i = 0;
  end R;
  model V
    Pin p, n;
  equation
    p.v - n.v = sin(time);
    p.i + n.i = 0;
  end V;
  model G
    Pin p;
  equation
    p.v = 0;
  end G;
  model B
    V src;
    R r1(r = 3), r2;
    G gnd;
  equation
    connect(src.p, r1.p);
    connect(r1.n, r2.p);
    connect(r2.n, src.n);
    connect(src.n, gnd.p);
  end B;
end EQ;
