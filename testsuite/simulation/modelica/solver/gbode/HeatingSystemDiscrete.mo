within ;
package HeatingSystemDiscrete
  import SI = Modelica.Units.SI;

  function sat "Smooth saturation of input x between xmin and xmax"
    input Real x;
    input Real xmin;
    input Real xmax;
    output Real y;
  algorithm
    y := Modelica.Math.tanh(2*(x-xmin)/(xmax-xmin)-1)*(xmax-xmin)/2 + (xmax+xmin)/2;
  end sat;

  model test_sat
    Real x = -20 + time*40;
    Real y;
  equation
    y = sat(x,-3,6);
    annotation (experiment(__Dymola_NumberOfIntervals=5000, Tolerance=1e-006),
        __Dymola_experimentSetupOutput);
  end test_sat;

  block Controller
    parameter SI.Time Ta "Time constant of actuator";
    input Real T "Temperature in degC";
    output Real u "Heater activation";
    Real x(start = 0, fixed = true) "Actuator state variable";
  protected
    Boolean active(start = false, fixed = true);
  equation
  when not pre(active) and T <= 19.5 then
      active = true;
    elsewhen pre(active) and T >= 20.5 then
      active = false;
    end when;
    Ta*der(x) + x = if active then 1 else 0;
    u = x;
  end Controller;

  model HeatingSystem
    constant Real pi = Modelica.Constants.pi;
    parameter Integer N = 3 "Number of heated units";
    parameter SI.HeatCapacity Cu[N] = (ones(N)+ linspace(0,1.348,N))*1e7
      "Heat capacity of heated units";
    parameter SI.HeatCapacity Cd = 2e6*N
      "Heat capacity of distribution circuit";
    parameter SI.ThermalConductance Gh = 200
      "Thermal conductance of heating elements";
    parameter SI.ThermalConductance Gu = 150
      "Thermal conductance of heated units to the atmosphere";
    parameter SI.Power Qmax = N*3000
      "Maximum power output of heat generation unit";
    parameter SI.TemperatureDifference Teps = 0.5
      "Threshold of heated unit temperature controllers";
    parameter SI.Temperature Td0 = 343.15
      "Set point of distribution circuit temperature";
    parameter SI.Temperature Tu0 = 293.15;
    parameter SI.Time Ta = 10
      "Time constant of heater actuator";
    parameter Real Kp = Qmax/4
      "Proportional gain of heat generation unit temperature controller";

    // State variables
    SI.Temperature Td(start = Td0, fixed = true)
      "Temperature of the fluid in the distribution system";
    SI.Temperature Tu[N](each start = Tu0, each fixed = true)
      "Temperature of individual heated units";

    // Time-varying prescribed signals
    SI.Temperature Text "External temperature";

    // Other intermediate algebraic variables
    SI.Power Que[N] "Heat flows from heated units to the outside";
    SI.Power Qh[N] "Heat flows to each heated unit";
    SI.Power Qd "Heat flow to the distribution system";
    Controller c[N](each Ta = Ta) "Controllers";
  equation
    Text = 278.15 + 8*sin(2*pi*time/86400);
    Cd*der(Td) =Qd - sum(Qh);
    Qd = sat(Kp*(Td0-Td),0, Qmax);
    for i in 1:N loop
      Qh[i] = Gh*(Td - Tu[i])*c[i].u;
      Que[i] =  Gu*(Tu[i] - Text);
      Cu[i]*der(Tu[i]) = Qh[i] - Que[i];
      c[i].T = Tu[i] - 273.15;
    end for;

    annotation (experiment(
        StopTime=864000,
        Interval = 300,
        Tolerance=1e-006), __Dymola_experimentSetupOutput,
      __OpenModelica_simulationFlags(lv = "LOG_STATS", s = "gbode", gbm = "fehlberg78", gbratio = ".05"));
  end HeatingSystem;
  annotation (uses(Modelica(version="4.0.0")));
end HeatingSystemDiscrete;
