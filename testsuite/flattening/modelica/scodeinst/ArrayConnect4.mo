// name: ArrayConnect4
// keywords:
// status: correct
// cflags: -d=newInst,-nfScalarize
//

connector Port
  Real v;
  flow Real i;
end Port;

model M
  Port port;
equation
  port.v = 10 * port.i;
end M;

model S
  parameter Integer N = 3;
  M m[N];
equation
  for i in 1:N-1 loop
    connect(m[i].port, m[i+1].port);
  end for;
end S;

// Result:
// class S
//   final parameter Integer N = 3;
//   Real[3] m.port.v;
//   Real[3] m.port.i;
// equation
//   m[2].port.v = m[3].port.v;
//   m[2].port.v = m[1].port.v;
//   m[3].port.i + m[2].port.i + m[1].port.i = 0.0;
//   for $i1 in 1:3 loop
//     m[$i1].port.v = 10.0 * m[$i1].port.i;
//   end for;
// end S;
// endResult
