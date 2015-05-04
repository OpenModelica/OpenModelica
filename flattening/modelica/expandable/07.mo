
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

  model Test07
    Extract_Abs_Max_TSP_Bus b(nu=2);
  end Test07;