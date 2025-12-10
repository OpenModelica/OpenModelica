// name: CevalRecordArray11
// keywords:
// status: correct
//

model SpeedControlled_y
  replaceable parameter Generic per;
  FlowMachineInterface eff(V_flow = per.V_flow);
end SpeedControlled_y;

record Generic
  parameter Real V_flow[:] = {0, 0} annotation(Evaluate=true);
end Generic;

model FlowMachineInterface
  parameter Real V_flow[:];
  parameter Integer curve = if abs(V_flow[1]) < 0 then 2 else 3;
equation
  if curve == 1 then
  end if;
end FlowMachineInterface;

model Multiple
  parameter PumpMultiple dat;
  replaceable SpeedControlled_y pum[2](final per = dat.per);
end Multiple;

record PumpMultiple
  replaceable parameter Generic per[2](V_flow = if true then {{0, 1, 2} for i in 1:2} else [0]);
end PumpMultiple;

model CevalRecordArray11
  parameter PumpMultiple datPumPriCom;
  Multiple pumPriHdr(dat = datPumPriCom);
end CevalRecordArray11;

// Result:
// class CevalRecordArray11
//   final parameter Real datPumPriCom.per[1].V_flow[1] = 0.0;
//   final parameter Real datPumPriCom.per[1].V_flow[2] = 1.0;
//   final parameter Real datPumPriCom.per[1].V_flow[3] = 2.0;
//   final parameter Real datPumPriCom.per[2].V_flow[1] = 0.0;
//   final parameter Real datPumPriCom.per[2].V_flow[2] = 1.0;
//   final parameter Real datPumPriCom.per[2].V_flow[3] = 2.0;
//   parameter Real pumPriHdr.dat.per[1].V_flow[1] = 0.0;
//   parameter Real pumPriHdr.dat.per[1].V_flow[2] = 1.0;
//   parameter Real pumPriHdr.dat.per[1].V_flow[3] = 2.0;
//   parameter Real pumPriHdr.dat.per[2].V_flow[1] = 0.0;
//   parameter Real pumPriHdr.dat.per[2].V_flow[2] = 1.0;
//   parameter Real pumPriHdr.dat.per[2].V_flow[3] = 2.0;
//   final parameter Real pumPriHdr.pum[1].per.V_flow[1] = 0.0;
//   final parameter Real pumPriHdr.pum[1].per.V_flow[2] = 1.0;
//   final parameter Real pumPriHdr.pum[1].per.V_flow[3] = 2.0;
//   final parameter Real pumPriHdr.pum[1].eff.V_flow[1] = 0.0;
//   final parameter Real pumPriHdr.pum[1].eff.V_flow[2] = 1.0;
//   final parameter Real pumPriHdr.pum[1].eff.V_flow[3] = 2.0;
//   final parameter Integer pumPriHdr.pum[1].eff.curve = 3;
//   final parameter Real pumPriHdr.pum[2].per.V_flow[1] = 0.0;
//   final parameter Real pumPriHdr.pum[2].per.V_flow[2] = 1.0;
//   final parameter Real pumPriHdr.pum[2].per.V_flow[3] = 2.0;
//   final parameter Real pumPriHdr.pum[2].eff.V_flow[1] = 0.0;
//   final parameter Real pumPriHdr.pum[2].eff.V_flow[2] = 1.0;
//   final parameter Real pumPriHdr.pum[2].eff.V_flow[3] = 2.0;
//   final parameter Integer pumPriHdr.pum[2].eff.curve = 3;
// end CevalRecordArray11;
// endResult
