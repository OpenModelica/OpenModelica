package AcausalStream "acausal components with stream connectors exported with --fmuAcausalComponent"
  connector Port
    Real p;
    flow Real m_flow;
    stream Real h_outflow;
  end Port;

  model Volume "an incompressible mixing volume with the specific enthalpy as state"
    parameter Real m = 1;
    Port a, b;
    Real h(start = 1, fixed = true);
  equation
    a.p = b.p;
    a.m_flow + b.m_flow = 0;
    m*der(h) = a.m_flow*actualStream(a.h_outflow) + b.m_flow*actualStream(b.h_outflow);
    a.h_outflow = h;
    b.h_outflow = h;
  end Volume;

  model Sink "a fixed pressure and enthalpy"
    parameter Real p = 1e5, h = 0;
    Port port;
    Real hIn = inStream(port.h_outflow);
  equation
    port.p = p;
    port.h_outflow = h;
  end Sink;
end AcausalStream;
