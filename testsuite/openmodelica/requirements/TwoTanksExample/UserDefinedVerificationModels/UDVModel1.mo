within TwoTanksExample.UserDefinedVerificationModels;

model UDVModel1
  TwoTanksExample.Design.TwoTanksDesign twoTanksDesign1 annotation(
    Placement(visible = true, transformation(origin = {42, -28}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  TwoTanksExample.Requirements.Volume_of_a_tank volume_of_a_tank1 annotation(
    Placement(visible = true, transformation(origin = {-60, 34}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  TwoTanksExample.Requirements.LiquidLevel liquidLevel1 annotation(
    Placement(visible = true, transformation(origin = {-60, -26}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  TwoTanksExample.Scenarios.Overflow overflow1 annotation(
    Placement(visible = true, transformation(origin = {42, 28}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
end UDVModel1;