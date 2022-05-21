within ;
package HeatingSystemDiscrete

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

  model TestHysteresis
    Real p = 3*sin(time);
    Real x(start = 0, fixed = true);
    Real y;
  equation
    der(x) = 50*hist(x,p);
    y = sat(15*x, -0.5, 0.5)+0.5;
    annotation (experiment(
        StopTime=20,
        __Dymola_NumberOfIntervals=5000,
        Tolerance=1e-006), __Dymola_experimentSetupOutput);
  end TestHysteresis;

  block Controller
    input Real T "Temperature in degC";
    output Real u "Heater activation";
  protected
    Boolean active(start = false, fixed = true);
  equation
  when not pre(active) and T <= 19.5 then
      active = true;
    elsewhen pre(active) and T >= 20.5 then
      active = false;
    end when;
    u = if active then 1 else 0;
  end Controller;

  model HeatingSystem
    import SI = Modelica.Units.SI;
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
    Controller c[N] "Controllers";
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
        __Dymola_NumberOfIntervals=5000,
        Tolerance=1e-006), __Dymola_experimentSetupOutput,
      __OpenModelica_simulationFlags(gmfsolver = "sdirk2", gmsolver = "sdirk2", lv = "LOG_STATS", gmnls = "kinsol", gmratio = "1", s = "gmode"));
  end HeatingSystem;
  annotation (uses(Modelica(version="4.0.0")));
end HeatingSystemDiscrete;