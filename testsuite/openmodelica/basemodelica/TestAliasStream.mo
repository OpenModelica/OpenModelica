package TestAliasStream
  constant Real c = 4200;
  constant Real rho = 1000;
  constant Real p_atm = 1e5;
  constant Real g = 9.81;

  connector FluidPort
    Real p;
    flow Real w;
    stream Real h;
  end FluidPort;

  model Pump
    FluidPort outlet;
    parameter Real T = 20;
    input Real w;
    Real P;
  equation
    outlet.w = -w;
    outlet.h = c*T;
    P = if w > 0 then w*(outlet.p - p_atm)/rho else 0;
  end Pump;

  model FixedFlowSource
    FluidPort outlet;
    parameter Real w annotation(Evaluate = true);
    parameter Real T = 30;
  equation
    outlet.w = -w;
    outlet.h = c*T;
  end FixedFlowSource;

  model Tank
    FluidPort port;
    parameter Real A = 1e-3;
    Real y(start = 1, fixed = true);
    Real T(start = 20, fixed = true);
  equation
    rho*A*der(y) = port.w;
    rho*A*c*der(y*T) = port.w*actualStream(port.h);
    port.h = c*T;
    port.p = p_atm + rho*g*y;
  end Tank;

  model Pipe
    FluidPort inlet;
    FluidPort outlet;
  equation
    inlet.p = outlet.p;
    inlet.w + outlet.w = 0;
    inlet.h = inStream(outlet.h);
    outlet.h = inStream(inlet.h);
  end Pipe;

  model TemperatureSensor
    FluidPort port(w(min = 0));
    Real h;
    output Real T;
  equation
    port.w = 0;
    port.h = 0;
    h = inStream(port.h);
    h = c*T;
  end TemperatureSensor;

  model TemperatureSensorWrapper
    FluidPort port;
    TemperatureSensor sensor;
    Real T = sensor.T;
  equation
    connect(port, sensor.port);
  end TemperatureSensorWrapper;

  model Test1
    Pump pump(w = sin(time));
    Tank tank;
  equation
    connect(pump.outlet, tank.port);
  end Test1;

  model Test2
    FixedFlowSource source1(w = 1);
    FixedFlowSource source2(w = 2);
    Tank tank;
  equation
    connect(source1.outlet, tank.port);
    connect(source2.outlet, tank.port);
  end Test2;

  model Test3
    extends Test2(source2(w = 0));
  end Test3;

  model Test4
    Pump pump(w = sin(time));
    Tank tank;
    TemperatureSensor sensor;
  equation
    connect(pump.outlet, tank.port);
    connect(sensor.port, tank.port);
  end Test4;

  model Test5
    Pump pump(w = sin(time));
    Tank tank;
    TemperatureSensorWrapper wrapper;
  equation
    connect(pump.outlet, tank.port);
    connect(wrapper.port, tank.port);
  end Test5;

  model Test6
    Pump pump1(w(min = 0)=max(1 - time, 0));
    Pump pump2(w(min = 0)=max(1 - 2*time, 0));
    Tank tank;
  equation
    connect(pump1.outlet, tank.port);
    connect(pump2.outlet, tank.port);
  end Test6;

  model Test7
    Pump pump1(w(min = 0)=max(1 - time, 0));
    Pump pump2(w(min = 0.1)=max(1 - 2*time, 0.1));
    Tank tank;
  equation
    connect(pump1.outlet, tank.port);
    connect(pump2.outlet, tank.port);
  end Test7;

  model Test8
    Pump pump1(w(min = 0) = max(1 - time, 0));
    Pump pump2(w = 0.1);
    Tank tank;
  equation
    connect(pump1.outlet, tank.port);
    connect(pump2.outlet, tank.port);
  end Test8;

  model Test9
    Pump pump1(w(min = 0) = max(1 - time, 0.1));
    Pump pump2(w = sin(time));
    Tank tank;
  equation
    connect(pump1.outlet, tank.port);
    connect(pump2.outlet, tank.port);
  end Test9;
end TestAliasStream;
