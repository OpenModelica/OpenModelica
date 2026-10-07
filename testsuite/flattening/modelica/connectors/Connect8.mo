// name:     Connect8
// keywords: connect
// status:   correct
//
// If parameters are involved in connections, the parameters have to
// be known to generate the equations.
//

connector C
  Real r;
  flow Real x;
end C;

class Connect8
  parameter Integer N = 2;
  C c[2], cx(x=1), cy(x=time);
equation
  connect(c[N],cx);
  connect(c[2],cy);
  c[1].x=time; // Extra equation required compared to Connect7 example.
end Connect8;

// Result:
// class Connect8
//   final parameter Integer N = 2;
//   Real c[1].r;
//   Real c[1].x;
//   Real c[2].r;
//   Real c[2].x;
//   Real cx.r;
//   Real cx.x = 1.0;
//   Real cy.r;
//   Real cy.x = time;
// equation
//   c[2].r = cy.r;
//   c[2].r = cx.r;
//   -(c[2].x + cy.x + cx.x) = 0.0;
//   c[1].x = 0.0;
//   c[2].x = 0.0;
//   cx.x = 0.0;
//   cy.x = 0.0;
//   c[1].x = time;
// end Connect8;
// [flattening/modelica/connectors/Connect8.mo:15:3-15:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/Connect8.mo:16:3-16:30:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/Connect8.mo:18:3-18:19:writable] Warning: Equation sections are deprecated in class.
//
// endResult
