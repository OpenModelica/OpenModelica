// name: ExpandableConnector13
// keywords: expandable connector
// status: correct
//
// Checks that potentially present non-connector variables in an expandable
// connector doesn't generate warnings about unbalanced connectors.
//

connector Pin
  Real v;
  flow Real i;
end Pin;

model Ground
  Pin p;
equation
  p.v = 0;
end Ground;

expandable connector C
end C;

model ModelA
  C c;
  Ground ground1;
  Ground ground2;
  Ground ground3;
equation
  connect(ground1.p, c.p1);
  connect(ground2.p, c.p2);
  connect(ground3.p, c.p3);
end ModelA;

model ModelB
  C c;
  Ground ground1;
equation
  connect(ground1.p, c.p1);
end ModelB;

model ExpandableConnector13
  ModelA m1;
  ModelA m2;
  ModelB m3;
equation
  connect(m1.c, m2.c);
  connect(m1.c, m3.c);
end ExpandableConnector13;

// Result:
// class ExpandableConnector13
//   Real m1.c.p1.i "virtual variable in expandable connector";
//   Real m1.c.p1.v "virtual variable in expandable connector";
//   Real m1.c.p2.i "virtual variable in expandable connector";
//   Real m1.c.p2.v "virtual variable in expandable connector";
//   Real m1.c.p3.i "virtual variable in expandable connector";
//   Real m1.c.p3.v "virtual variable in expandable connector";
//   Real m2.c.p1.i "virtual variable in expandable connector";
//   Real m2.c.p1.v "virtual variable in expandable connector";
//   Real m2.c.p2.i "virtual variable in expandable connector";
//   Real m2.c.p2.v "virtual variable in expandable connector";
//   Real m2.c.p3.i "virtual variable in expandable connector";
//   Real m2.c.p3.v "virtual variable in expandable connector";
//   Real m3.c.p1.i "virtual variable in expandable connector";
//   Real m3.c.p1.v "virtual variable in expandable connector";
//   Real m3.c.p2.i "virtual variable in expandable connector";
//   Real m3.c.p2.v "virtual variable in expandable connector";
//   Real m3.c.p3.i "virtual variable in expandable connector";
//   Real m3.c.p3.v "virtual variable in expandable connector";
//   Real m1.ground1.p.v;
//   Real m1.ground1.p.i;
//   Real m1.ground2.p.v;
//   Real m1.ground2.p.i;
//   Real m1.ground3.p.v;
//   Real m1.ground3.p.i;
//   Real m2.ground1.p.v;
//   Real m2.ground1.p.i;
//   Real m2.ground2.p.v;
//   Real m2.ground2.p.i;
//   Real m2.ground3.p.v;
//   Real m2.ground3.p.i;
//   Real m3.ground1.p.v;
//   Real m3.ground1.p.i;
// equation
//   m1.ground1.p.v = m1.c.p1.v;
//   m1.ground2.p.v = m1.c.p2.v;
//   m1.ground3.p.v = m1.c.p3.v;
//   m2.ground1.p.v = m2.c.p1.v;
//   m2.ground2.p.v = m2.c.p2.v;
//   m2.ground3.p.v = m2.c.p3.v;
//   m3.ground1.p.v = m3.c.p1.v;
//   m1.c.p1.v = m3.c.p1.v;
//   m1.c.p1.v = m2.c.p1.v;
//   m1.c.p2.v = m3.c.p2.v;
//   m1.c.p2.v = m2.c.p2.v;
//   m1.c.p3.v = m3.c.p3.v;
//   m1.c.p3.v = m2.c.p3.v;
//   m3.c.p1.i + m2.c.p1.i + m1.c.p1.i = 0.0;
//   m3.c.p2.i + m2.c.p2.i + m1.c.p2.i = 0.0;
//   m3.c.p3.i + m2.c.p3.i + m1.c.p3.i = 0.0;
//   m3.c.p2.i = 0.0;
//   m3.c.p3.i = 0.0;
//   m1.ground1.p.i - m1.c.p1.i = 0.0;
//   m1.ground2.p.i - m1.c.p2.i = 0.0;
//   m1.ground3.p.i - m1.c.p3.i = 0.0;
//   m2.ground1.p.i - m2.c.p1.i = 0.0;
//   m2.ground2.p.i - m2.c.p2.i = 0.0;
//   m2.ground3.p.i - m2.c.p3.i = 0.0;
//   m3.ground1.p.i - m3.c.p1.i = 0.0;
//   m1.ground1.p.v = 0.0;
//   m1.ground2.p.v = 0.0;
//   m1.ground3.p.v = 0.0;
//   m2.ground1.p.v = 0.0;
//   m2.ground2.p.v = 0.0;
//   m2.ground3.p.v = 0.0;
//   m3.ground1.p.v = 0.0;
// end ExpandableConnector13;
// endResult
