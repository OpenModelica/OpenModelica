// name: NoScalarizeConnect3
// keywords:
// status: correct
//

connector Port
  Real foo;
  flow Real fooFlow;
end Port;

model Source
  parameter Real val;
  Port port;
equation
  port.foo = val;
end Source;

model M1
  Port port1, port2;
equation
  port1.fooFlow + port2.fooFlow = 0;
  port1.fooFlow = port1.foo-port2.foo;
end M1;

model M2
  parameter Boolean useM1 = false;
  Port port1, port2;
  M1 m1 if useM1;

equation
  if useM1 then
    connect(port1, m1.port1);
    connect(m1.port2, port2);
  else
    connect(port1, port2);
  end if;
end M2;

model NoScalarizeConnect3
  Source SO1(val=1), SO2(val=0);
  M2[3] m2A(useM1={true, true, true});
equation
  connect(SO1.port, m2A[1].port1);
  connect(SO2.port, m2A[3].port2);
  for i in 1:2 loop
    connect(m2A[i].port2, m2A[i+1].port1);
  end for;
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end NoScalarizeConnect3;

// Result:
// class NoScalarizeConnect3
//   parameter Real SO1.val = 1.0;
//   Real SO1.port.foo;
//   Real SO1.port.fooFlow;
//   parameter Real SO2.val = 0.0;
//   Real SO2.port.foo;
//   Real SO2.port.fooFlow;
//   final parameter Boolean[3] m2A.useM1 = {true, true, true};
//   Real[3] m2A.port1.foo;
//   Real[3] m2A.port1.fooFlow;
//   Real[3] m2A.port2.foo;
//   Real[3] m2A.port2.fooFlow;
//   Real[3] m2A.m1.port1.foo;
//   Real[3] m2A.m1.port1.fooFlow;
//   Real[3] m2A.m1.port2.foo;
//   Real[3] m2A.m1.port2.fooFlow;
// equation
//   m2A[3].m1.port2.foo = m2A[3].port2.foo;
//   m2A[3].port1.foo = m2A[3].m1.port1.foo;
//   m2A[3].m1.port1.fooFlow - m2A[3].port1.fooFlow = 0.0;
//   m2A[2].m1.port2.foo = m2A[2].port2.foo;
//   m2A[2].port1.foo = m2A[2].m1.port1.foo;
//   m2A[2].m1.port1.fooFlow - m2A[2].port1.fooFlow = 0.0;
//   m2A[1].m1.port2.foo = m2A[1].port2.foo;
//   m2A[1].port1.foo = m2A[1].m1.port1.foo;
//   m2A[1].m1.port1.fooFlow - m2A[1].port1.fooFlow = 0.0;
//   SO1.port.foo = m2A[1].port1.foo;
//   SO2.port.foo = m2A[3].port2.foo;
//   m2A[1].port2.foo = m2A[2].port1.foo;
//   m2A[2].port2.foo = m2A[3].port1.foo;
//   m2A[1].port1.fooFlow + SO1.port.fooFlow = 0.0;
//   m2A[3].port2.fooFlow + SO2.port.fooFlow = 0.0;
//   m2A[1].port2.fooFlow + m2A[2].port1.fooFlow = 0.0;
//   m2A[2].port2.fooFlow + m2A[3].port1.fooFlow = 0.0;
//   m2A[1].m1.port2.fooFlow - m2A[1].port2.fooFlow = 0.0;
//   m2A[2].m1.port2.fooFlow - m2A[2].port2.fooFlow = 0.0;
//   m2A[3].m1.port2.fooFlow - m2A[3].port2.fooFlow = 0.0;
//   SO1.port.foo = SO1.val;
//   SO2.port.foo = SO2.val;
//   for $i2 in 1:3 loop
//     m2A[$i2].m1.port1.fooFlow + m2A[$i2].m1.port2.fooFlow = 0.0;
//   end for;
//   for $i1 in 1:3 loop
//     m2A[$i1].m1.port1.fooFlow = m2A[$i1].m1.port1.foo - m2A[$i1].m1.port2.foo;
//   end for;
// end NoScalarizeConnect3;
// endResult
