// name: CevalRecordArray6
// keywords:
// status: correct
//

model MultiLayer
  parameter Generic layers;
  SingleLayer[3] lay(nSta = {layers.nSta[i] for i in 1:3});
end MultiLayer;

model SingleLayer
  Real[nSta] u;
  parameter Integer nSta;
end SingleLayer;

record Generic
  parameter Integer[3] nSta = {1 for i in 1:3};
end Generic;

model Construction
  parameter Generic layers;
  MultiLayer opa(layers = layers);
end Construction;

record ParameterConstruction
  parameter Generic layers;
end ParameterConstruction;

model RoomHeatMassBalance
  parameter ParameterConstruction[1] datConExtWin;
  Construction[1] conExtWin(layers = datConExtWin.layers);
end RoomHeatMassBalance;

model CevalRecordArray6
  final parameter Generic conExtWal;
  RoomHeatMassBalance roo(datConExtWin(layers = {conExtWal}));
end CevalRecordArray6;

// Result:
// class CevalRecordArray6
//   final parameter Integer conExtWal.nSta[1] = 1;
//   final parameter Integer conExtWal.nSta[2] = 1;
//   final parameter Integer conExtWal.nSta[3] = 1;
//   parameter Integer roo.datConExtWin[1].layers.nSta[1] = conExtWal.nSta[1];
//   parameter Integer roo.datConExtWin[1].layers.nSta[2] = conExtWal.nSta[2];
//   parameter Integer roo.datConExtWin[1].layers.nSta[3] = conExtWal.nSta[3];
//   parameter Integer roo.conExtWin[1].layers.nSta[1] = roo.datConExtWin[1].layers.nSta[1];
//   parameter Integer roo.conExtWin[1].layers.nSta[2] = roo.datConExtWin[1].layers.nSta[2];
//   parameter Integer roo.conExtWin[1].layers.nSta[3] = roo.datConExtWin[1].layers.nSta[3];
//   final parameter Integer roo.conExtWin[1].opa.layers.nSta[1] = 1;
//   final parameter Integer roo.conExtWin[1].opa.layers.nSta[2] = 1;
//   final parameter Integer roo.conExtWin[1].opa.layers.nSta[3] = 1;
//   Real roo.conExtWin[1].opa.lay[1].u[1];
//   final parameter Integer roo.conExtWin[1].opa.lay[1].nSta = 1;
//   Real roo.conExtWin[1].opa.lay[2].u[1];
//   final parameter Integer roo.conExtWin[1].opa.lay[2].nSta = 1;
//   Real roo.conExtWin[1].opa.lay[3].u[1];
//   final parameter Integer roo.conExtWin[1].opa.lay[3].nSta = 1;
// end CevalRecordArray6;
// endResult
