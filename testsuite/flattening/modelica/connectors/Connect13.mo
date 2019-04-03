// name: Connect13
// keywords:  connector, array components
// status: correct
//
// Test that arrays can be used n connectors.
//
connector dq_0
  Real u_dq0[3];
  flow Real i_dq0[3];
end dq_0;


model test
  dq_0 p,n;
equation
end test;
model test2
  test t1,t2;
equation
connect(t1.n,t2.p);
connect(t2.n,t1.p);
end test2;
// Result:
// class test2
//   Real t1.p.u_dq0[1];
//   Real t1.p.u_dq0[2];
//   Real t1.p.u_dq0[3];
//   Real t1.p.i_dq0[1];
//   Real t1.p.i_dq0[2];
//   Real t1.p.i_dq0[3];
//   Real t1.n.u_dq0[1];
//   Real t1.n.u_dq0[2];
//   Real t1.n.u_dq0[3];
//   Real t1.n.i_dq0[1];
//   Real t1.n.i_dq0[2];
//   Real t1.n.i_dq0[3];
//   Real t2.p.u_dq0[1];
//   Real t2.p.u_dq0[2];
//   Real t2.p.u_dq0[3];
//   Real t2.p.i_dq0[1];
//   Real t2.p.i_dq0[2];
//   Real t2.p.i_dq0[3];
//   Real t2.n.u_dq0[1];
//   Real t2.n.u_dq0[2];
//   Real t2.n.u_dq0[3];
//   Real t2.n.i_dq0[1];
//   Real t2.n.i_dq0[2];
//   Real t2.n.i_dq0[3];
// equation
//   t1.p.i_dq0[1] + t2.n.i_dq0[1] = 0.0;
//   t1.p.i_dq0[2] + t2.n.i_dq0[2] = 0.0;
//   t1.p.i_dq0[3] + t2.n.i_dq0[3] = 0.0;
//   t1.n.i_dq0[1] + t2.p.i_dq0[1] = 0.0;
//   t1.n.i_dq0[2] + t2.p.i_dq0[2] = 0.0;
//   t1.n.i_dq0[3] + t2.p.i_dq0[3] = 0.0;
//   t1.n.u_dq0[1] = t2.p.u_dq0[1];
//   t1.n.u_dq0[2] = t2.p.u_dq0[2];
//   t1.n.u_dq0[3] = t2.p.u_dq0[3];
//   t1.p.u_dq0[1] = t2.n.u_dq0[1];
//   t1.p.u_dq0[2] = t2.n.u_dq0[2];
//   t1.p.u_dq0[3] = t2.n.u_dq0[3];
// end test2;
// endResult
