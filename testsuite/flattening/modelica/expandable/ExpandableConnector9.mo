// name: ExpandableConnector9
// keywords: expandable connector
// status: correct
//
//

expandable connector CellBus
  Real lossPower;
end CellBus;

expandable connector StackBus
  CellBus[3, 2] cellBus;
end StackBus;

model HeatFlowSensor
  connector RealOutput = output Real;
  RealOutput Q_flow;
end HeatFlowSensor;

model Cell
  HeatFlowSensor heatFlowSensor;
  CellBus cellBus2;
equation
  connect(heatFlowSensor.Q_flow, cellBus2.lossPower);
end Cell;

model ExpandableConnector9
  replaceable Cell[3, 2] cell;
  StackBus stackBus;
equation
  connect(cell.cellBus2, stackBus.cellBus);
end ExpandableConnector9;

// Result:
// class ExpandableConnector9
//   Real cell[1,1].heatFlowSensor.Q_flow;
//   Real cell[1,1].cellBus2.lossPower;
//   Real cell[1,2].heatFlowSensor.Q_flow;
//   Real cell[1,2].cellBus2.lossPower;
//   Real cell[2,1].heatFlowSensor.Q_flow;
//   Real cell[2,1].cellBus2.lossPower;
//   Real cell[2,2].heatFlowSensor.Q_flow;
//   Real cell[2,2].cellBus2.lossPower;
//   Real cell[3,1].heatFlowSensor.Q_flow;
//   Real cell[3,1].cellBus2.lossPower;
//   Real cell[3,2].heatFlowSensor.Q_flow;
//   Real cell[3,2].cellBus2.lossPower;
//   Real stackBus.cellBus[1,1].lossPower;
//   Real stackBus.cellBus[1,2].lossPower;
//   Real stackBus.cellBus[2,1].lossPower;
//   Real stackBus.cellBus[2,2].lossPower;
//   Real stackBus.cellBus[3,1].lossPower;
//   Real stackBus.cellBus[3,2].lossPower;
// equation
//   cell[1,1].heatFlowSensor.Q_flow = cell[1,1].cellBus2.lossPower;
//   cell[1,2].heatFlowSensor.Q_flow = cell[1,2].cellBus2.lossPower;
//   cell[2,1].heatFlowSensor.Q_flow = cell[2,1].cellBus2.lossPower;
//   cell[2,2].heatFlowSensor.Q_flow = cell[2,2].cellBus2.lossPower;
//   cell[3,1].heatFlowSensor.Q_flow = cell[3,1].cellBus2.lossPower;
//   cell[3,2].heatFlowSensor.Q_flow = cell[3,2].cellBus2.lossPower;
//   cell[1,1].cellBus2.lossPower = stackBus.cellBus[1,1].lossPower;
//   cell[1,2].cellBus2.lossPower = stackBus.cellBus[1,2].lossPower;
//   cell[2,1].cellBus2.lossPower = stackBus.cellBus[2,1].lossPower;
//   cell[2,2].cellBus2.lossPower = stackBus.cellBus[2,2].lossPower;
//   cell[3,1].cellBus2.lossPower = stackBus.cellBus[3,1].lossPower;
//   cell[3,2].cellBus2.lossPower = stackBus.cellBus[3,2].lossPower;
// end ExpandableConnector9;
// endResult
