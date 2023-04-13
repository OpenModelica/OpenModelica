// name: ConnectStream1
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

type AbsolutePressure = Real(min = 0, max = 1.e8);
type SpecificEnthalpy = Real(min = -1.0e10, max = 1.e10);
type MassFlowRate = Real(min = -1.0e5, max = 1.e5);

connector FluidPort
  flow MassFlowRate m_flow;
  AbsolutePressure p;
  stream SpecificEnthalpy h_outflow;
end FluidPort;

model IdealSource
  FluidPort port_b(m_flow(max = 1e60));
end IdealSource;

model RelativePressure
  FluidPort port_a(m_flow(min = 0));
end RelativePressure;

model ConnectStream1
  FluidPort port_b(m_flow(max = 1e60));
protected
  IdealSource preSou;
  RelativePressure senRelPre;
equation
  connect(preSou.port_b, port_b);
  connect(senRelPre.port_a, preSou.port_b);
end ConnectStream1;

// Result:
// class ConnectStream1
//   Real port_b.m_flow(min = -100000.0, max = 9.999999999999999e+59);
//   Real port_b.p(min = 0.0, max = 100000000.0);
//   Real port_b.h_outflow(min = -10000000000.0, max = 10000000000.0);
//   protected Real preSou.port_b.m_flow(min = -100000.0, max = 9.999999999999999e+59);
//   protected Real preSou.port_b.p(min = 0.0, max = 100000000.0);
//   protected Real preSou.port_b.h_outflow(min = -10000000000.0, max = 10000000000.0);
//   protected Real senRelPre.port_a.m_flow(min = 0.0, max = 100000.0);
//   protected Real senRelPre.port_a.p(min = 0.0, max = 100000000.0);
//   protected Real senRelPre.port_a.h_outflow(min = -10000000000.0, max = 10000000000.0);
// equation
//   senRelPre.port_a.p = preSou.port_b.p;
//   senRelPre.port_a.p = port_b.p;
//   senRelPre.port_a.m_flow + preSou.port_b.m_flow - port_b.m_flow = 0.0;
//   preSou.port_b.h_outflow = port_b.h_outflow;
//   port_b.m_flow = 0.0;
// end ConnectStream1;
// endResult
