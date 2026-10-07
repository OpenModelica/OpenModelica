// name:     Connect7
// keywords: connect
// status:   correct
//
// If parameters are involved in connections, the parameters have to
// be known to generate the equations.  If the parameter N would have
// been set to 2 instead, only one big connection set would have been
// generated.
//

connector C
  Real r;
  flow Real x;
end C;

class Connect7
  parameter Integer N = 1;
  C c[2], cx(x=2), cy(x=time);
equation
  connect(c[N],cx);
  connect(c[2],cy);
end Connect7;

// Result:
// class Connect7
//   final parameter Integer N = 1;
//   Real c[1].r;
//   Real c[1].x;
//   Real c[2].r;
//   Real c[2].x;
//   Real cx.r;
//   Real cx.x = 2.0;
//   Real cy.r;
//   Real cy.x = time;
// equation
//   c[1].r = cx.r;
//   -(c[1].x + cx.x) = 0.0;
//   c[2].r = cy.r;
//   -(c[2].x + cy.x) = 0.0;
//   c[1].x = 0.0;
//   c[2].x = 0.0;
//   cx.x = 0.0;
//   cy.x = 0.0;
// end Connect7;
// [flattening/modelica/connectors/Connect7.mo:17:3-17:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/Connect7.mo:18:3-18:30:writable] Warning: Components are deprecated in class.
// [flattening/modelica/connectors/Connect7.mo:20:3-20:19:writable] Warning: Equation sections are deprecated in class.
//
// endResult
