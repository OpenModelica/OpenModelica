// name: MultipleInheritanceConnect
// keywords: connector
// status: correct
//
// Tests that multiple inheritance is handled correctly with regards to connect.
//

connector Conn
  Real p "potential Variable";
  flow Real f "flow Variable";
end Conn;

partial model A
  Conn port;
end A;

partial model B
  extends A;
end B;

partial model C
  extends A;
end C;

model D
  extends B;
  extends C;
equation
  port.f = port.p;
end D;

model E
  Conn port;
  D d;
equation
  connect(d.port, port);
end E;

model MultipleInheritanceConnect
  E e;
end MultipleInheritanceConnect;

// Result:
// class MultipleInheritanceConnect
//   Real e.port.p "potential Variable";
//   Real e.port.f "flow Variable";
//   Real e.d.port.p "potential Variable";
//   Real e.d.port.f "flow Variable";
// equation
//   e.d.port.f = e.d.port.p;
//   e.port.f = 0.0;
//   (-e.port.f) + e.d.port.f = 0.0;
//   e.d.port.p = e.port.p;
// end MultipleInheritanceConnect;
// endResult
