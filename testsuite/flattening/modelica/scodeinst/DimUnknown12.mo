// name: DimUnknown12
// keywords:
// status: correct
//
//

package ElectricEIR
  record Generic
    parameter Real mEva_flow_nominal;
  end Generic;
end ElectricEIR;

package Movers
  record Generic
    parameter flowParameters pressure(V_flow = {0, 0}, dp = {0, 0}) annotation(Evaluate = true);
  end Generic;
end Movers;

record flowParameters
  parameter Real[:] V_flow;
  parameter Real[size(V_flow, 1)] dp;
end flowParameters;

model CentralCoolingPlant
  parameter Integer numChi = 2;
  parameter ElectricEIR.Generic perChi;
  parameter Movers.Generic perCHWPum;
end CentralCoolingPlant;

model DimUnknown12
  parameter Real mCHW_flow_nominal = 2*(cooPla.perChi.mEva_flow_nominal);
  parameter Movers.Generic perCHWPum(pressure = flowParameters(V_flow = ((mCHW_flow_nominal/cooPla.numChi)/1000)*{0.1, 1, 1.2}, dp = 200000*{1.2, 1, 0.1}));
  CentralCoolingPlant cooPla(perChi(mEva_flow_nominal = 1000), perCHWPum = perCHWPum);
end DimUnknown12;

// Result:
// class DimUnknown12
//   final parameter Real mCHW_flow_nominal = 2000.0;
//   parameter Real perCHWPum.pressure.V_flow[1] = 0.1;
//   parameter Real perCHWPum.pressure.V_flow[2] = 1.0;
//   parameter Real perCHWPum.pressure.V_flow[3] = 1.2;
//   parameter Real perCHWPum.pressure.dp[1] = 2.4e5;
//   parameter Real perCHWPum.pressure.dp[2] = 2e5;
//   parameter Real perCHWPum.pressure.dp[3] = 2e4;
//   final parameter Integer cooPla.numChi = 2;
//   final parameter Real cooPla.perChi.mEva_flow_nominal = 1000.0;
//   parameter Real cooPla.perCHWPum.pressure.V_flow[1] = perCHWPum.pressure.V_flow[1];
//   parameter Real cooPla.perCHWPum.pressure.V_flow[2] = perCHWPum.pressure.V_flow[2];
//   parameter Real cooPla.perCHWPum.pressure.V_flow[3] = perCHWPum.pressure.V_flow[3];
//   parameter Real cooPla.perCHWPum.pressure.dp[1] = perCHWPum.pressure.dp[1];
//   parameter Real cooPla.perCHWPum.pressure.dp[2] = perCHWPum.pressure.dp[2];
//   parameter Real cooPla.perCHWPum.pressure.dp[3] = perCHWPum.pressure.dp[3];
// end DimUnknown12;
// endResult
