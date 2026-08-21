// name: CevalBinding11
// status: correct
//
//

model SOS10ComponentsModelica
  final parameter Integer dominantSpecies = integer(X_start[1]);
  parameter Real X_start[1];
  constant Real MM[1] = {0};
  parameter Real MMmix_start = MM[dominantSpecies];
end SOS10ComponentsModelica;

model HomotopyInitializerX
  parameter Real X_start[1];
  SOS10ComponentsModelica refFluid(X_start = X_start);
  Real x;
equation
  x = X_start[1];
end HomotopyInitializerX;

model CevalBinding11
  parameter Real X_start_Anode[2, 1] = ones(2, 1) annotation(Evaluate = false);
  HomotopyInitializerX homotopyInitializerAnodeIn(X_start = X_start_Anode[1, :]);
end CevalBinding11;

// Result:
// class CevalBinding11
//   parameter Real X_start_Anode[1,1] = 1.0;
//   parameter Real X_start_Anode[2,1] = 1.0;
//   final parameter Real homotopyInitializerAnodeIn.X_start[1] = X_start_Anode[1,1];
//   final parameter Integer homotopyInitializerAnodeIn.refFluid.dominantSpecies = integer(X_start_Anode[1,:]);
//   final parameter Real homotopyInitializerAnodeIn.refFluid.X_start[1] = X_start_Anode[1,1];
//   constant Real homotopyInitializerAnodeIn.refFluid.MM[1] = 0.0;
//   parameter Real homotopyInitializerAnodeIn.refFluid.MMmix_start = 0.0;
//   Real homotopyInitializerAnodeIn.x;
// equation
//   homotopyInitializerAnodeIn.x = X_start_Anode[1,:];
// end CevalBinding11;
// endResult
