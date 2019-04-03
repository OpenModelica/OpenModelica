// name:     Redeclare4
// keywords: redeclare, bug #36
// status:   correct
//

package A
  model B
    parameter Real b=1.0;
    Real x;
  end B;
end A;

package E
model BB
  extends A.B;
equation
  der(x) = b;
end BB;
end E;

package F
model C
  parameter Real b=2.0;
  replaceable A.B d(final b=b);
equation
end C;
end F;

model D
  F.C c(b=5, redeclare E.BB d);
end D;


// Result:
// class D
//   parameter Real c.b = 5.0;
//   parameter Real c.d.b = c.b;
//   Real c.d.x;
// equation
//   der(c.d.x) = c.d.b;
// end D;
// endResult
