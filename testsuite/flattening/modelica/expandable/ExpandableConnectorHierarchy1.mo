// name:    ExpandableConnectorHierarchy1
// keyword: expandable
// status:  correct
//
// model by Pavol Privitzer
//

connector RealInput = input Real;
connector RealOutput = output Real;

expandable connector BusConnector
end BusConnector;

block Integrator
  parameter Real k = 1;
  parameter Real y_start = 0;
  RealInput u;
  RealOutput y;
initial equation
  y = y_start;
equation
  der(y) = k*u;
end Integrator;

block Constant
  parameter Real k(start = 1);
  RealOutput y;
equation
  y = k;
end Constant;

model BusSources
  BusConnector busConnector;
  Constant osmolarityConstant(k = 3);
  Constant MyConstant(k = 7);
equation
  connect(osmolarityConstant.y, busConnector.MyOmolarity);
  connect(MyConstant.y, busConnector.MyConstant);
end BusSources;

model BusConsumeGroup
  BusConnector busConnector;
  Integrator integrator;
equation
  connect(busConnector.MyOmolarity, integrator.u);
end BusConsumeGroup;

model ExpandableConnectorHierarchy1
  BusSources busSources;
  BusConsumeGroup busConsumeGroup;
  BusConsumeGroup busConsumeGroup2;
equation
  connect(busSources.busConnector, busConsumeGroup.busConnector);
  connect(busSources.busConnector, busConsumeGroup2.busConnector);
end ExpandableConnectorHierarchy1;


// Result:
// class ExpandableConnectorHierarchy1
//   Real busSources.busConnector.MyOmolarity "variable added to expandable connector";
//   Real busSources.busConnector.MyConstant "variable added to expandable connector";
//   Real busConsumeGroup.busConnector.MyOmolarity "variable added to expandable connector";
//   Real busConsumeGroup.busConnector.MyConstant "variable added to expandable connector";
//   Real busConsumeGroup2.busConnector.MyOmolarity "variable added to expandable connector";
//   Real busConsumeGroup2.busConnector.MyConstant "variable added to expandable connector";
//   parameter Real busSources.osmolarityConstant.k(start = 1.0) = 3.0;
//   Real busSources.osmolarityConstant.y;
//   parameter Real busSources.MyConstant.k(start = 1.0) = 7.0;
//   Real busSources.MyConstant.y;
//   parameter Real busConsumeGroup.integrator.k = 1.0;
//   parameter Real busConsumeGroup.integrator.y_start = 0.0;
//   Real busConsumeGroup.integrator.u;
//   Real busConsumeGroup.integrator.y;
//   parameter Real busConsumeGroup2.integrator.k = 1.0;
//   parameter Real busConsumeGroup2.integrator.y_start = 0.0;
//   Real busConsumeGroup2.integrator.u;
//   Real busConsumeGroup2.integrator.y;
// initial equation
//   busConsumeGroup.integrator.y = busConsumeGroup.integrator.y_start;
//   busConsumeGroup2.integrator.y = busConsumeGroup2.integrator.y_start;
// equation
//   busSources.osmolarityConstant.y = busSources.busConnector.MyOmolarity;
//   busSources.MyConstant.y = busSources.busConnector.MyConstant;
//   busConsumeGroup.busConnector.MyOmolarity = busConsumeGroup.integrator.u;
//   busConsumeGroup2.busConnector.MyOmolarity = busConsumeGroup2.integrator.u;
//   busSources.busConnector.MyConstant = busConsumeGroup2.busConnector.MyConstant;
//   busSources.busConnector.MyConstant = busConsumeGroup.busConnector.MyConstant;
//   busSources.busConnector.MyOmolarity = busConsumeGroup2.busConnector.MyOmolarity;
//   busSources.busConnector.MyOmolarity = busConsumeGroup.busConnector.MyOmolarity;
//   busSources.osmolarityConstant.y = busSources.osmolarityConstant.k;
//   busSources.MyConstant.y = busSources.MyConstant.k;
//   der(busConsumeGroup.integrator.y) = busConsumeGroup.integrator.k * busConsumeGroup.integrator.u;
//   der(busConsumeGroup2.integrator.y) = busConsumeGroup2.integrator.k * busConsumeGroup2.integrator.u;
// end ExpandableConnectorHierarchy1;
// endResult
