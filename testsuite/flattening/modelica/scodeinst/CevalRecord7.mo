// name: CevalRecord7
// keywords:
// status: correct
//

package PB
  record RB
    constant Integer n;
    parameter Real a[n] = ones(n);
  end RB;
end PB;

package P
  record R
    extends PB.RB(final n=1);
  end R;

  replaceable constant R g;
end P;

model CevalRecord7
  PB.RB r = P.g;
end CevalRecord7;

// Result:
// class CevalRecord7
//   constant Integer r.n = 1;
//   parameter Real r.a[1] = 1.0;
// end CevalRecord7;
// endResult
