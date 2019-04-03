connector Port
  Real pressure;
  flow Real flowrate;
end Port;

model Pipe
  Port port;
  parameter Real a = 1;
equation
  port.pressure = port.flowrate * a;
end Pipe;

model Pump
 Port port;
equation
  port.flowrate = -( time - port.pressure);
end Pump;

//------------------------------
model LinearSysEq
  Pump pu;
  Pipe pi;
equation
  connect(pu.port,pi.port);
end LinearSysEq;


