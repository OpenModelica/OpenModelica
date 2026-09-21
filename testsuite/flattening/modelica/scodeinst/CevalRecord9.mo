// name: CevalRecord9
// keywords:
// status: correct
//

record MaterialThermalGeneral
  parameter Real c = 1000.0;
end MaterialThermalGeneral;

model HeatConduction1DNodes
  parameter MaterialThermalGeneral material annotation(Evaluate = true);
end HeatConduction1DNodes;

model MultiLayerHeatConduction1DNodes
  HeatConduction1DNodes layer(material = material);
  parameter MaterialThermalGeneral material;
end MultiLayerHeatConduction1DNodes;

model WallThermal1DNodes
  parameter MaterialThermalGeneral material;
  MultiLayerHeatConduction1DNodes construction(material = material);
end WallThermal1DNodes;

model CevalRecord9
  parameter Real AAmb = 1.0 annotation(Evaluate = false);
  WallThermal1DNodes ambientConstructions(material(final c = 1/AAmb));
end CevalRecord9;

// Result:
// class CevalRecord9
//   parameter Real AAmb = 1.0;
//   final parameter Real ambientConstructions.material.c = 1.0 / AAmb;
//   parameter Real ambientConstructions.construction.layer.material.c = ambientConstructions.material.c;
//   parameter Real ambientConstructions.construction.material.c = 1.0;
// end CevalRecord9;
// endResult
