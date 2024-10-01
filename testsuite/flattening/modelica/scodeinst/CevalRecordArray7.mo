// name: CevalRecordArray7
// keywords:
// status: correct
//

function anyTrue
  input Boolean[:] b;
  output Boolean result;
algorithm
  result := false;
  for i in 1:size(b, 1) loop
    result := result or b[i];
  end for;
end anyTrue;

model ExteriorBoundaryConditionsWithWindow
  replaceable parameter ParameterConstructionWithWindow[1] conPar;
  final parameter Boolean haveOverhangOrSideFins = anyTrue(conPar.haveOverhangOrSideFins);
  Real x if haveOverhangOrSideFins;
end ExteriorBoundaryConditionsWithWindow;

model RoomHeatMassBalance
  parameter ParameterConstructionWithWindow[1] datConExtWin;
  ExteriorBoundaryConditionsWithWindow bouConExtWin(final conPar = datConExtWin);
end RoomHeatMassBalance;

record Overhang
  parameter Real dep(min = 0);
  final parameter Boolean haveOverhang = dep > 0;
end Overhang;

record ParameterConstructionWithWindow
  parameter Overhang ove;
  final parameter Boolean haveOverhangOrSideFins = ove.dep > 1E-8;
end ParameterConstructionWithWindow;

model CevalRecordArray7
  RoomHeatMassBalance roo(datConExtWin(ove(dep = {1})));
end CevalRecordArray7;

// Result:
// class CevalRecordArray7
//   parameter Real roo.datConExtWin[1].ove.dep(min = 0.0) = 1.0;
//   final parameter Boolean roo.datConExtWin[1].ove.haveOverhang = roo.datConExtWin[1].ove.dep > 0.0;
//   final parameter Boolean roo.datConExtWin[1].haveOverhangOrSideFins = true;
//   final parameter Real roo.bouConExtWin.conPar[1].ove.dep(min = 0.0) = roo.datConExtWin[1].ove.dep;
//   final parameter Boolean roo.bouConExtWin.conPar[1].ove.haveOverhang = roo.datConExtWin[1].ove.haveOverhang;
//   final parameter Boolean roo.bouConExtWin.conPar[1].haveOverhangOrSideFins = true;
//   final parameter Boolean roo.bouConExtWin.haveOverhangOrSideFins = true;
//   Real roo.bouConExtWin.x;
// end CevalRecordArray7;
// endResult
