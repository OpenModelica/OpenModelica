within ModelicaDataReconciliationSimpleTests.Models;
model DistillationTower
  Real F(
    uncertain=Uncertainty.refine,
    start=1095.47) = 1095.47;
  Real B(
    uncertain=Uncertainty.refine,
    start=488.23) = 488.23;
  Real D(uncertain=Uncertainty.refine, start=478.4);
  Real xF1(uncertain=Uncertainty.refine, start=48.22);
  Real xF2(uncertain=Uncertainty.refine, start=51.70);
  Real xB1(
    uncertain=Uncertainty.refine,
    start=1.97) = 1.97;
  Real xB2(uncertain=Uncertainty.refine, start=97.48);
  Real xD1(
    uncertain=Uncertainty.refine,
    start=94.1) = 94.1;
  Real xD2(uncertain=Uncertainty.refine, start=5.01);
equation
  F*xF1 - B*xB1 - D*xD1 = 0;
  F*xF2 - B*xB2 - D*xD2 = 0;
  xF1 + xF2 = 100;
  xB1 + xB2 = 100;
  xD1 + xD2 = 100;
  annotation (__OpenModelica_simulationFlags(
      lv="LOG_JAC",eps = "0.023",
      s="dassl",
      sx="modelica://ModelicaDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.DistillationTower_Inputs.csv"));
end DistillationTower;
