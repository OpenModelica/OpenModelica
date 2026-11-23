// name:    ExpandableConnectorArray1
// keyword: expandable
// status:  correct
//
// model by Pavol Privitzer
//

connector RealOutput = output Real;

expandable connector Sensor_TSP_Bus
  Real torque;
  Real speed;
  Real power;
end Sensor_TSP_Bus;

model Extract_Abs_Max_TSP_Bus
  parameter Integer nu(min = 0) = 0;
  input Sensor_TSP_Bus[nu] sensor_TSP_bus_in;
protected
  RealOutput[nu] yi_torque;
  RealOutput[nu] yi_speed;
equation
  for i in 1:nu loop
    connect(yi_torque[i], sensor_TSP_bus_in[i].torque);
    connect(yi_speed[i], sensor_TSP_bus_in[i].speed);
  end for;
end Extract_Abs_Max_TSP_Bus;

model ExpandableConnectorArray1
  Extract_Abs_Max_TSP_Bus b(nu=2);
end ExpandableConnectorArray1;

// Result:
// class ExpandableConnectorArray1
//   final parameter Integer b.nu(min = 0) = 2;
//   Real b.sensor_TSP_bus_in[1].torque;
//   Real b.sensor_TSP_bus_in[1].speed;
//   Real b.sensor_TSP_bus_in[2].torque;
//   Real b.sensor_TSP_bus_in[2].speed;
//   protected Real b.yi_torque[1];
//   protected Real b.yi_torque[2];
//   protected Real b.yi_speed[1];
//   protected Real b.yi_speed[2];
// equation
//   b.yi_torque[1] = b.sensor_TSP_bus_in[1].torque;
//   b.yi_speed[1] = b.sensor_TSP_bus_in[1].speed;
//   b.yi_torque[2] = b.sensor_TSP_bus_in[2].torque;
//   b.yi_speed[2] = b.sensor_TSP_bus_in[2].speed;
// end ExpandableConnectorArray1;
// endResult
