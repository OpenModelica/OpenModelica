// name: CevalRecordArray9
// keywords:
// status: correct
//

connector HeatPort_a
  Real T;
  flow Real Q_flow;
end HeatPort_a;

record Material
  parameter Real x;
  parameter Integer nSta = max(1, integer(ceil(x)));
end Material;

model SingleLayer
  HeatPort_a port_b;
  Real[nSta + 1] Q_flow;
  parameter Integer nSta;
equation
  port_b.Q_flow = -Q_flow[end];
end SingleLayer;

record Generic
  parameter Integer nLay;
  parameter Material[nLay] material;
  parameter Integer[nLay] nSta = {i for i in material.nSta};
end Generic;

model Construction
  parameter Generic layers;
  parameter Integer nLay = size(layers.material, 1);
  parameter Integer[nLay] nSta = {i for i in layers.material.nSta};
  SingleLayer[nLay] lay(nSta = {i for i in layers.nSta});
end Construction;

model MixedAir
  parameter Generic layers[2];
  Construction[2] conBou(layers = layers);
end MixedAir;

model CevalRecordArray9
  MixedAir roo(layers = {matFlo, matEWWal});
  parameter Generic matFlo(nLay = 3, material = {Material(x = 5.28), Material(x = 0.01905), Material(x = 0.01905)});
  parameter Generic matEWWal(nLay = 2, material = {Material(x = 0.133), Material(x = 0.015875)});
end CevalRecordArray9;

// Result:
// class CevalRecordArray9
//   final parameter Integer roo.layers[1].nLay = 3;
//   parameter Real roo.layers[1].material[1].x = matFlo.material[1].x;
//   parameter Integer roo.layers[1].material[1].nSta = 6;
//   parameter Real roo.layers[1].material[2].x = matFlo.material[2].x;
//   parameter Integer roo.layers[1].material[2].nSta = 1;
//   parameter Real roo.layers[1].material[3].x = matFlo.material[3].x;
//   parameter Integer roo.layers[1].material[3].nSta = 1;
//   parameter Integer roo.layers[1].nSta[1] = matFlo.nSta[1];
//   parameter Integer roo.layers[1].nSta[2] = matFlo.nSta[2];
//   parameter Integer roo.layers[1].nSta[3] = matFlo.nSta[3];
//   final parameter Integer roo.layers[2].nLay = 2;
//   parameter Real roo.layers[2].material[1].x = matEWWal.material[1].x;
//   parameter Integer roo.layers[2].material[1].nSta = 1;
//   parameter Real roo.layers[2].material[2].x = matEWWal.material[2].x;
//   parameter Integer roo.layers[2].material[2].nSta = 1;
//   parameter Integer roo.layers[2].nSta[1] = matEWWal.nSta[1];
//   parameter Integer roo.layers[2].nSta[2] = matEWWal.nSta[2];
//   final parameter Integer roo.conBou[1].layers.nLay = 3;
//   parameter Real roo.conBou[1].layers.material[1].x = roo.layers[1].material[1].x;
//   final parameter Integer roo.conBou[1].layers.material[1].nSta = 6;
//   parameter Real roo.conBou[1].layers.material[2].x = roo.layers[1].material[2].x;
//   final parameter Integer roo.conBou[1].layers.material[2].nSta = 1;
//   parameter Real roo.conBou[1].layers.material[3].x = roo.layers[1].material[3].x;
//   final parameter Integer roo.conBou[1].layers.material[3].nSta = 1;
//   final parameter Integer roo.conBou[1].layers.nSta[1] = 6;
//   final parameter Integer roo.conBou[1].layers.nSta[2] = 1;
//   final parameter Integer roo.conBou[1].layers.nSta[3] = 1;
//   final parameter Integer roo.conBou[1].nLay = 3;
//   parameter Integer roo.conBou[1].nSta[1] = 6;
//   parameter Integer roo.conBou[1].nSta[2] = 1;
//   parameter Integer roo.conBou[1].nSta[3] = 1;
//   Real roo.conBou[1].lay[1].port_b.T;
//   Real roo.conBou[1].lay[1].port_b.Q_flow;
//   Real roo.conBou[1].lay[1].Q_flow[1];
//   Real roo.conBou[1].lay[1].Q_flow[2];
//   Real roo.conBou[1].lay[1].Q_flow[3];
//   Real roo.conBou[1].lay[1].Q_flow[4];
//   Real roo.conBou[1].lay[1].Q_flow[5];
//   Real roo.conBou[1].lay[1].Q_flow[6];
//   Real roo.conBou[1].lay[1].Q_flow[7];
//   final parameter Integer roo.conBou[1].lay[1].nSta = 6;
//   Real roo.conBou[1].lay[2].port_b.T;
//   Real roo.conBou[1].lay[2].port_b.Q_flow;
//   Real roo.conBou[1].lay[2].Q_flow[1];
//   Real roo.conBou[1].lay[2].Q_flow[2];
//   final parameter Integer roo.conBou[1].lay[2].nSta = 1;
//   Real roo.conBou[1].lay[3].port_b.T;
//   Real roo.conBou[1].lay[3].port_b.Q_flow;
//   Real roo.conBou[1].lay[3].Q_flow[1];
//   Real roo.conBou[1].lay[3].Q_flow[2];
//   final parameter Integer roo.conBou[1].lay[3].nSta = 1;
//   final parameter Integer roo.conBou[2].layers.nLay = 2;
//   parameter Real roo.conBou[2].layers.material[1].x = roo.layers[2].material[1].x;
//   final parameter Integer roo.conBou[2].layers.material[1].nSta = 1;
//   parameter Real roo.conBou[2].layers.material[2].x = roo.layers[2].material[2].x;
//   final parameter Integer roo.conBou[2].layers.material[2].nSta = 1;
//   final parameter Integer roo.conBou[2].layers.nSta[1] = 1;
//   final parameter Integer roo.conBou[2].layers.nSta[2] = 1;
//   final parameter Integer roo.conBou[2].nLay = 2;
//   parameter Integer roo.conBou[2].nSta[1] = 1;
//   parameter Integer roo.conBou[2].nSta[2] = 1;
//   Real roo.conBou[2].lay[1].port_b.T;
//   Real roo.conBou[2].lay[1].port_b.Q_flow;
//   Real roo.conBou[2].lay[1].Q_flow[1];
//   Real roo.conBou[2].lay[1].Q_flow[2];
//   final parameter Integer roo.conBou[2].lay[1].nSta = 1;
//   Real roo.conBou[2].lay[2].port_b.T;
//   Real roo.conBou[2].lay[2].port_b.Q_flow;
//   Real roo.conBou[2].lay[2].Q_flow[1];
//   Real roo.conBou[2].lay[2].Q_flow[2];
//   final parameter Integer roo.conBou[2].lay[2].nSta = 1;
//   final parameter Integer matFlo.nLay = 3;
//   parameter Real matFlo.material[1].x = 5.28;
//   final parameter Integer matFlo.material[1].nSta = 6;
//   parameter Real matFlo.material[2].x = 0.01905;
//   final parameter Integer matFlo.material[2].nSta = 1;
//   parameter Real matFlo.material[3].x = 0.01905;
//   final parameter Integer matFlo.material[3].nSta = 1;
//   parameter Integer matFlo.nSta[1] = 6;
//   parameter Integer matFlo.nSta[2] = 1;
//   parameter Integer matFlo.nSta[3] = 1;
//   final parameter Integer matEWWal.nLay = 2;
//   parameter Real matEWWal.material[1].x = 0.133;
//   final parameter Integer matEWWal.material[1].nSta = 1;
//   parameter Real matEWWal.material[2].x = 0.015875;
//   final parameter Integer matEWWal.material[2].nSta = 1;
//   parameter Integer matEWWal.nSta[1] = 1;
//   parameter Integer matEWWal.nSta[2] = 1;
// equation
//   roo.conBou[1].lay[1].port_b.Q_flow = 0.0;
//   roo.conBou[1].lay[2].port_b.Q_flow = 0.0;
//   roo.conBou[1].lay[3].port_b.Q_flow = 0.0;
//   roo.conBou[2].lay[1].port_b.Q_flow = 0.0;
//   roo.conBou[2].lay[2].port_b.Q_flow = 0.0;
//   roo.conBou[1].lay[1].port_b.Q_flow = -roo.conBou[1].lay[1].Q_flow[7];
//   roo.conBou[1].lay[2].port_b.Q_flow = -roo.conBou[1].lay[2].Q_flow[2];
//   roo.conBou[1].lay[3].port_b.Q_flow = -roo.conBou[1].lay[3].Q_flow[2];
//   roo.conBou[2].lay[1].port_b.Q_flow = -roo.conBou[2].lay[1].Q_flow[2];
//   roo.conBou[2].lay[2].port_b.Q_flow = -roo.conBou[2].lay[2].Q_flow[2];
// end CevalRecordArray9;
// endResult
