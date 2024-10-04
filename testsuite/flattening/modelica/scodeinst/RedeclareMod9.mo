// name: RedeclareMod9
// keywords:
// status: correct
//

record NominalValues
  Real x;
end NominalValues;

record Stage
  parameter NominalValues nomVal(x = 0);
end Stage;

record NominalCondition
  parameter NominalValues per;
end NominalCondition;

model WetCoil
  parameter DXCoil datCoi;
  NominalCondition[4] uacp(per = datCoi.sta.nomVal);
end WetCoil;

record DXCoil
  parameter Stage[4] sta;
end DXCoil;

model RedeclareMod9
  parameter DXCoil datCoi;
  WetCoil eva(datCoi = datCoi, uacp(redeclare NominalValues per));
end RedeclareMod9;

// Result:
// class RedeclareMod9
//   parameter Real datCoi.sta[1].nomVal.x = 0.0;
//   parameter Real datCoi.sta[2].nomVal.x = 0.0;
//   parameter Real datCoi.sta[3].nomVal.x = 0.0;
//   parameter Real datCoi.sta[4].nomVal.x = 0.0;
//   parameter Real eva.datCoi.sta[1].nomVal.x = datCoi.sta[1].nomVal.x;
//   parameter Real eva.datCoi.sta[2].nomVal.x = datCoi.sta[2].nomVal.x;
//   parameter Real eva.datCoi.sta[3].nomVal.x = datCoi.sta[3].nomVal.x;
//   parameter Real eva.datCoi.sta[4].nomVal.x = datCoi.sta[4].nomVal.x;
//   parameter Real eva.uacp[1].per.x = eva.datCoi.sta[1].nomVal.x;
//   parameter Real eva.uacp[2].per.x = eva.datCoi.sta[2].nomVal.x;
//   parameter Real eva.uacp[3].per.x = eva.datCoi.sta[3].nomVal.x;
//   parameter Real eva.uacp[4].per.x = eva.datCoi.sta[4].nomVal.x;
// end RedeclareMod9;
// endResult
