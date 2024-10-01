// name: CevalRecordArray8
// keywords:
// status: correct
//

model SolarRadiationExchange
  parameter ParameterConstructionWithWindow[1] datConExtWin(each til = 0);
  parameter Boolean[1] isFloorConExtWin;
end SolarRadiationExchange;

record ParameterConstructionWithWindow
  parameter Real til;
  final parameter Boolean isFloor = til > 2.74889125 annotation(Evaluate = true);
end ParameterConstructionWithWindow;

model MixedAir
  parameter ParameterConstructionWithWindow[1] datConExtWin(each til = 0);
  SolarRadiationExchange solRadExc(final datConExtWin = datConExtWin, final isFloorConExtWin = isFloorConExtWin);
protected
  final parameter Boolean[1] isFloorConExtWin = datConExtWin.isFloor;
end MixedAir;

model ThermalZone
  MixedAir roo(datConExtWin(til = {0}));
end ThermalZone;

model MultiZone
  parameter Integer nZon(min = 1) = 1;
  parameter Integer nFlo(min = 1) = 1;
  ThermalZone[nZon, nFlo] theZon;
end MultiZone;

model CevalRecordArray8
  parameter Integer nZon(min = 1) = 2;
  parameter Integer nFlo(min = 1) = 1;
  MultiZone multiZone(nZon = nZon, nFlo = nFlo);
end CevalRecordArray8;

// Result:
// class CevalRecordArray8
//   final parameter Integer nZon(min = 1) = 2;
//   final parameter Integer nFlo(min = 1) = 1;
//   final parameter Integer multiZone.nZon(min = 1) = 2;
//   final parameter Integer multiZone.nFlo(min = 1) = 1;
//   final parameter Real multiZone.theZon[1,1].roo.datConExtWin[1].til = 0.0;
//   final parameter Boolean multiZone.theZon[1,1].roo.datConExtWin[1].isFloor = false;
//   final parameter Real multiZone.theZon[1,1].roo.solRadExc.datConExtWin[1].til = 0.0;
//   final parameter Boolean multiZone.theZon[1,1].roo.solRadExc.datConExtWin[1].isFloor = false;
//   final parameter Boolean multiZone.theZon[1,1].roo.solRadExc.isFloorConExtWin[1] = false;
//   protected final parameter Boolean multiZone.theZon[1,1].roo.isFloorConExtWin[1] = false;
//   final parameter Real multiZone.theZon[2,1].roo.datConExtWin[1].til = 0.0;
//   final parameter Boolean multiZone.theZon[2,1].roo.datConExtWin[1].isFloor = false;
//   final parameter Real multiZone.theZon[2,1].roo.solRadExc.datConExtWin[1].til = 0.0;
//   final parameter Boolean multiZone.theZon[2,1].roo.solRadExc.datConExtWin[1].isFloor = false;
//   final parameter Boolean multiZone.theZon[2,1].roo.solRadExc.isFloorConExtWin[1] = false;
//   protected final parameter Boolean multiZone.theZon[2,1].roo.isFloorConExtWin[1] = false;
// end CevalRecordArray8;
// endResult
