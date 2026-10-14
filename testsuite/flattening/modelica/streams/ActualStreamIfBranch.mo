// name: ActualStreamIfBranch
// keywords: stream actualStream inStream if-expression array constructor
// status: correct
//
// Checks that stream operators are only evaluated in the branch of an
// if-expression that is taken when the condition depends on structural
// parameters only, since the other branch may refer to connectors that don't
// exist (cell[n + 1]). With a non-structural parameter or an iterator of a
// for-equation in the condition both branches are kept.
//

model ActualStreamIfBranch
  connector FluidPort
    Real p;
    flow Real m_flow;
    stream Real h;
  end FluidPort;

  model Cell
    FluidPort portA, portB;
    Real h;
  equation
    portA.m_flow + portB.m_flow = 0;
    portA.p - portB.p = portA.m_flow;
    portA.h = h;
    portB.h = h;
  end Cell;

  model Source
    FluidPort port;
    parameter Real p0;
    parameter Real h0;
  equation
    port.p = p0;
    port.h = h0;
  end Source;

  parameter Integer n = 2;
  parameter Real k = 1;
  Cell cell[n];
  Source a(p0 = 2, h0 = 3), b(p0 = 1, h0 = 1);
  Real hPort[n + 1] = {if i < n + 1 then actualStream(cell[i].portA.h) else actualStream(cell[n].portB.h) for i in 1:n + 1};
  Real hIn = if k > 0 then inStream(cell[1].portA.h) else inStream(cell[n].portB.h);
  Real hFor[n];
equation
  for i in 1:n loop
    hFor[i] = if i == 1 then inStream(cell[1].portA.h) else actualStream(cell[i].portA.h);
  end for;
  connect(a.port, cell[1].portA);
  for i in 1:n - 1 loop
    connect(cell[i].portB, cell[i + 1].portA);
  end for;
  connect(cell[n].portB, b.port);
end ActualStreamIfBranch;

// Result:
// class ActualStreamIfBranch
//   final parameter Integer n = 2;
//   parameter Real k = 1.0;
//   Real cell[1].portA.p;
//   Real cell[1].portA.m_flow;
//   Real cell[1].portA.h;
//   Real cell[1].portB.p;
//   Real cell[1].portB.m_flow;
//   Real cell[1].portB.h;
//   Real cell[1].h;
//   Real cell[2].portA.p;
//   Real cell[2].portA.m_flow;
//   Real cell[2].portA.h;
//   Real cell[2].portB.p;
//   Real cell[2].portB.m_flow;
//   Real cell[2].portB.h;
//   Real cell[2].h;
//   Real a.port.p;
//   Real a.port.m_flow;
//   Real a.port.h;
//   parameter Real a.p0 = 2.0;
//   parameter Real a.h0 = 3.0;
//   Real b.port.p;
//   Real b.port.m_flow;
//   Real b.port.h;
//   parameter Real b.p0 = 1.0;
//   parameter Real b.h0 = 1.0;
//   Real hPort[1];
//   Real hPort[2];
//   Real hPort[3];
//   Real hIn = if k > 0.0 then a.port.h else b.port.h;
//   Real hFor[1];
//   Real hFor[2];
// equation
//   a.port.p = cell[1].portA.p;
//   cell[1].portB.p = cell[2].portA.p;
//   cell[2].portB.p = b.port.p;
//   cell[2].portA.m_flow + cell[1].portB.m_flow = 0.0;
//   b.port.m_flow + cell[2].portB.m_flow = 0.0;
//   a.port.m_flow + cell[1].portA.m_flow = 0.0;
//   cell[1].portA.m_flow + cell[1].portB.m_flow = 0.0;
//   cell[1].portA.p - cell[1].portB.p = cell[1].portA.m_flow;
//   cell[1].portA.h = cell[1].h;
//   cell[1].portB.h = cell[1].h;
//   cell[2].portA.m_flow + cell[2].portB.m_flow = 0.0;
//   cell[2].portA.p - cell[2].portB.p = cell[2].portA.m_flow;
//   cell[2].portA.h = cell[2].h;
//   cell[2].portB.h = cell[2].h;
//   a.port.p = a.p0;
//   a.port.h = a.h0;
//   b.port.p = b.p0;
//   b.port.h = b.h0;
//   hPort = {if cell[1].portA.m_flow > 0.0 then a.port.h else cell[1].portA.h, if cell[2].portA.m_flow > 0.0 then cell[1].portB.h else cell[2].portA.h, if cell[2].portB.m_flow > 0.0 then b.port.h else cell[2].portB.h};
//   hFor[1] = a.port.h;
//   hFor[2] = if cell[2].portA.m_flow > 0.0 then cell[1].portB.h else cell[2].portA.h;
// end ActualStreamIfBranch;
// endResult
