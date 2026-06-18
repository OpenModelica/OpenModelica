// name: DimUnknown19
// keywords:
// status: correct
//
//

record flowParameters
  parameter Real V_flow[:];
end flowParameters;

record Generic
  parameter flowParameters pressure(V_flow = {0, 0});
end Generic;

record PumpMultiple
  parameter Integer nPum;
  parameter Generic per[nPum](pressure(V_flow = fill({0, 1, 2}, nPum)));
end PumpMultiple;

model Multiple
  parameter Integer nPum;
  parameter PumpMultiple dat(final nPum = nPum);
end Multiple;

model DimUnknown19
  parameter PumpMultiple datPumMul(final nPum = pumMul.nPum);
  Multiple pumMul(nPum = 2, final dat = datPumMul);
end DimUnknown19;

// Result:
// class DimUnknown19
//   final parameter Integer datPumMul.nPum = 2;
//   parameter Real datPumMul.per[1].pressure.V_flow[1] = 0.0;
//   parameter Real datPumMul.per[1].pressure.V_flow[2] = 1.0;
//   parameter Real datPumMul.per[1].pressure.V_flow[3] = 2.0;
//   parameter Real datPumMul.per[2].pressure.V_flow[1] = 0.0;
//   parameter Real datPumMul.per[2].pressure.V_flow[2] = 1.0;
//   parameter Real datPumMul.per[2].pressure.V_flow[3] = 2.0;
//   final parameter Integer pumMul.nPum = 2;
//   final parameter Integer pumMul.dat.nPum = 2;
//   final parameter Real pumMul.dat.per[1].pressure.V_flow[1] = datPumMul.per[1].pressure.V_flow[1];
//   final parameter Real pumMul.dat.per[1].pressure.V_flow[2] = datPumMul.per[1].pressure.V_flow[2];
//   final parameter Real pumMul.dat.per[1].pressure.V_flow[3] = datPumMul.per[1].pressure.V_flow[3];
//   final parameter Real pumMul.dat.per[2].pressure.V_flow[1] = datPumMul.per[2].pressure.V_flow[1];
//   final parameter Real pumMul.dat.per[2].pressure.V_flow[2] = datPumMul.per[2].pressure.V_flow[2];
//   final parameter Real pumMul.dat.per[2].pressure.V_flow[3] = datPumMul.per[2].pressure.V_flow[3];
// end DimUnknown19;
// endResult
