package drumBoiler
  model DrumBoiler "Complete drum boiler model, including evaporator and supplementary components"
    extends Modelica.Icons.Example;
    parameter Boolean use_inputs = false "use external inputs instead of test data contained internally" annotation(Evaluate = true);
    Modelica.Fluid.Examples.DrumBoiler.BaseClasses.EquilibriumDrumBoiler evaporator(m_D = 300000.0, cp_D = 500, V_t = 100, V_l_start = 67, redeclare package Medium = Modelica.Media.Water.StandardWater, energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, massDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, p_start = 100000) annotation(Placement(transformation(extent = {{-46, -30}, {-26, -10}}, rotation = 0)));
    Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow furnace annotation(Placement(transformation(origin = {-36, -53}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Modelica.Fluid.Sources.FixedBoundary sink(nPorts = 1, p = Modelica.SIunits.Conversions.from_bar(0.5), redeclare package Medium = Modelica.Media.Water.StandardWaterOnePhase, T = 500) annotation(Placement(transformation(origin = {90, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    Modelica.Fluid.Sensors.MassFlowRate massFlowRate(redeclare package Medium = Modelica.Media.Water.StandardWater) annotation(Placement(transformation(origin = {30, -20}, extent = {{10, 10}, {-10, -10}}, rotation = 180)));
    Modelica.Fluid.Sensors.Temperature temperature(redeclare package Medium = Modelica.Media.Water.StandardWater) annotation(Placement(transformation(origin = {-3, -1}, extent = {{10, 10}, {-10, -10}}, rotation = 180)));
    Modelica.Fluid.Sensors.Pressure pressure(redeclare package Medium = Modelica.Media.Water.StandardWater) annotation(Placement(transformation(extent = {{10, 18}, {30, 38}}, rotation = 0)));
    Modelica.Blocks.Continuous.PI controller(T = 120, k = 10, initType = Modelica.Blocks.Types.Init.InitialState) annotation(Placement(transformation(extent = {{-49, 23}, {-63, 37}}, rotation = 0)));
    Modelica.Fluid.Sources.MassFlowSource_h pump(nPorts = 1, h = 500000.0, redeclare package Medium = Modelica.Media.Water.StandardWater, use_m_flow_in = true) annotation(Placement(transformation(extent = {{-80, -30}, {-60, -10}}, rotation = 0)));
    Modelica.Blocks.Math.Feedback feedback annotation(Placement(transformation(extent = {{-22, 20}, {-42, 40}}, rotation = 0)));
    Modelica.Blocks.Sources.Constant levelSetPoint(k = 67) annotation(Placement(transformation(extent = {{-38, 48}, {-24, 62}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput T_S "steam temperature" annotation(Placement(transformation(extent = {{100, 48}, {112, 60}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput p_S "steam pressure" annotation(Placement(transformation(extent = {{100, 22}, {112, 34}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput qm_S "steam flow rate" annotation(Placement(transformation(extent = {{100, -2}, {112, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput V_l "liquid volume inside drum" annotation(Placement(transformation(extent = {{100, 74}, {112, 86}}, rotation = 0)));
    Modelica.Blocks.Math.Gain MW2W(k = 1000000.0) annotation(Placement(transformation(extent = {{-54, -75.5}, {-44, -64.5}}, rotation = 0)));
    Modelica.Blocks.Math.Gain Pa2bar(k = 1e-05) annotation(Placement(transformation(extent = {{37, 23}, {47, 33}}, rotation = 0)));
    Modelica.Thermal.HeatTransfer.Celsius.FromKelvin K2degC annotation(Placement(transformation(extent = {{38, 49}, {48, 59}}, rotation = 0)));
    Modelica.Blocks.Nonlinear.Limiter limiter(uMin = 0, uMax = 500) annotation(Placement(transformation(origin = {-78, 30}, extent = {{-7, 7}, {7, -7}}, rotation = 180)));
    Modelica.Fluid.Valves.ValveLinear SteamValve(redeclare package Medium = Modelica.Media.Water.StandardWater, dp_nominal = 9000000, m_flow_nominal = 180) annotation(Placement(transformation(extent = {{50, -10}, {70, -30}}, rotation = 0)));
    inner Modelica.Fluid.System system annotation(Placement(transformation(extent = {{-90, 70}, {-70, 90}})));
    Modelica.Blocks.Sources.TimeTable q_F_Tab(table = [0, 0; 3600, 400; 7210, 400]) if not use_inputs annotation(Placement(transformation(extent = {{-90, -80}, {-70, -60}}, rotation = 0)));
    Modelica.Blocks.Sources.TimeTable Y_Valve_Tab(table = [0, 0; 900, 1; 7210, 1]) if not use_inputs annotation(Placement(transformation(extent = {{30, -80}, {50, -60}}, rotation = 0)));
    /*Modelica.Blocks.Interfaces.RealInput*/
    Real q_F(unit = "MW") if use_inputs "fuel flow rate" annotation(Placement(transformation(extent = {{-112, -56}, {-100, -44}})));
    Modelica.Blocks.Interfaces.RealInput Y_Valve if use_inputs "valve opening" annotation(Placement(transformation(extent = {{-112, -96}, {-100, -84}})));
    //Modelica.Blocks.Sources.RealExpression sigma_D_expr(y = (-1000.0 * der(evaporator.T_D)) + 1e-05 * evaporator.p) annotation(Placement(transformation(extent = {{24, -108}, {82, -92}})));
    //Modelica.Blocks.Interfaces.RealOutput sigma_D(unit = "N/mm2") "thermal stress of drum" annotation(Placement(transformation(extent = {{100, -68}, {112, -56}}, rotation = 0)));
  equation
    connect(furnace.port, evaporator.heatPort) annotation(Line(points = {{-36, -43}, {-36, -30}}, color = {191, 0, 0}));
    connect(controller.u, feedback.y) annotation(Line(points = {{-47.6, 30}, {-41, 30}}, color = {0, 0, 127}));
    connect(massFlowRate.m_flow, qm_S) annotation(Line(points = {{30, -9}, {30, 4}, {106, 4}}, color = {0, 0, 127}));
    connect(evaporator.V, V_l) annotation(Line(points = {{-32, -9}, {-32, 16}, {-4, 16}, {-4, 80}, {106, 80}}, color = {0, 0, 127}));
    connect(MW2W.y, furnace.Q_flow) annotation(Line(points = {{-43.5, -70}, {-36, -70}, {-36, -63}}, color = {0, 0, 127}));
    connect(pressure.p, Pa2bar.u) annotation(Line(points = {{31, 28}, {36, 28}}, color = {0, 0, 127}));
    connect(Pa2bar.y, p_S) annotation(Line(points = {{47.5, 28}, {106, 28}}, color = {0, 0, 127}));
    connect(K2degC.Celsius, T_S) annotation(Line(points = {{48.5, 54}, {106, 54}}, color = {0, 0, 127}));
    connect(controller.y, limiter.u) annotation(Line(points = {{-63.7, 30}, {-69.59999999999999, 30}}, color = {0, 0, 127}));
    connect(limiter.y, pump.m_flow_in) annotation(Line(points = {{-85.7, 30}, {-90, 30}, {-90, -12}, {-80, -12}}, color = {0, 0, 127}));
    connect(temperature.T, K2degC.Kelvin) annotation(Line(points = {{4, -1}, {4, -1}, {8, -1}, {8, 54}, {37, 54}}, color = {0, 0, 127}));
    connect(pressure.port, massFlowRate.port_a) annotation(Line(points = {{20, 18}, {20, -20}}, color = {0, 127, 255}));
    connect(pump.ports[1], evaporator.port_a) annotation(Line(points = {{-60, -20}, {-46, -20}}, color = {0, 127, 255}));
    connect(massFlowRate.port_b, SteamValve.port_a) annotation(Line(points = {{40, -20}, {50, -20}}, color = {0, 127, 255}));
    connect(SteamValve.port_b, sink.ports[1]) annotation(Line(points = {{70, -20}, {75, -20}, {80, -20}}, color = {0, 127, 255}));
    connect(evaporator.port_b, massFlowRate.port_a) annotation(Line(points = {{-26, -20}, {20, -20}}, color = {0, 127, 255}));
    connect(temperature.port, massFlowRate.port_a) annotation(Line(points = {{-3, -11}, {-3, -20}, {20, -20}}, color = {0, 127, 255}, smooth = Smooth.None));
    connect(q_F_Tab.y, MW2W.u) annotation(Line(points = {{-69, -70}, {-55, -70}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(Y_Valve_Tab.y, SteamValve.opening) annotation(Line(points = {{51, -70}, {60, -70}, {60, -28}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(q_F, MW2W.u) annotation(Line(points = {{-106, -50}, {-62, -50}, {-62, -70}, {-55, -70}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(Y_Valve, SteamValve.opening) annotation(Line(points = {{-106, -90}, {60, -90}, {60, -28}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(evaporator.V, feedback.u2) annotation(Line(points = {{-32, -9}, {-32, 6}, {-32, 6}, {-32, 22}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(levelSetPoint.y, feedback.u1) annotation(Line(points = {{-23.3, 55}, {-16, 55}, {-16, 30}, {-24, 30}}, color = {0, 0, 127}, smooth = Smooth.None));
    //connect(sigma_D_expr.y, sigma_D) annotation(Line(points = {{84.90000000000001, -100}, {94, -100}, {94, -62}, {106, -62}}, color = {0, 0, 127}, smooth = Smooth.None));
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-151, 165}, {138, 102}}, lineColor = {0, 0, 255}, textString = "%name"), Text(extent = {{-79, 67}, {67, 21}}, lineColor = {0, 0, 0}, textString = "drum"), Text(extent = {{-90, -14}, {88, -64}}, lineColor = {0, 0, 0}, textString = "boiler")}), experiment(StopTime = 5400), Documentation(info = "<html>
       <p>The DrumBoiler example provides a simple test case for optimization and estimation. It exhibits the following features:</p>
       <p><ul>
       <li>simple model based on MSL, including Media and Fluid</li>
       <li>simple embedded control using Blocks, including PI controller and discontinuous limiter</li>
       <li>three states: drum boiler pressure, drum boiler water level, integral part of controller</li>
       </ul></p>
       <p>The optimization should care about</p>
       <p><ul>
       <li>usage of regular Modelica simulation model as optimization contraints</li>
       <li>initialization of states from parameters</li>
       <li>treatment of nominal values (e.g. 100 bar is represented as 1e7 Pa in the pressure state, while the valve is fully open at 1)</li>
       <li>physical state/output constraint for thermal stress</li>
       <li>controller state/output constraint for limiter (i.e. avoid negative feedwater flow)</li>
       <li>appropriate discretization of path contraints, avoiding oscillation around sample points</li>
       </ul></p>
       <p>The test case is taken from: </p>
       <p><i>R. Franke, M. Rode, K. Kr&uuml;ger: On-line Optimization of Drum Boiler Startup, Modelica 2003. </i></p>
       <p>See: <a href=\"https://www.modelica.org/events/Conference2003/papers/h29_Franke.pdf\">https://www.modelica.org/events/Conference2003/papers/h29_Franke.pdf</a></p>
       <p><h4><font color=\"#008000\">Simulation model for optimization and estimation</font></h4></p>
       <p>The simulation model can be translated to an ODE of the form:</p>
       <pre>  der(x) = f(x,u)
         y = h(x,u)</pre>
       <p>with:</p>
       <pre>  x = {evaporator.p, evaporator.V_l, controller.x}
         u = {q_F, Y_Valve}
         y = {T_S, p_S, qm_S, V_l, sigma_D}</pre>
       <p>Compared to the base model Modelica.Fluid.Examples.DrumBoiler.DrumBoiler, the fifth output sigma_D adds a simplified model for thermal stress and membrane stress</p>
       <pre>  sigma_D = -1e3*der(evaporator.T_D) + 1e-5*evaporator.p</pre>
       <p>The initial states are defined by model parameters to:</p>
       <pre>  x(0) = f0(p)</pre>
       <p>with the parameter values:</p>
       <pre>  evaporator.p_start = 1 bar
         evaporator.V_start = 67 m3
         controller.x_start = 0</pre>
       <p><h4><font color=\"#008000\">Trajectory optimization</font></h4></p>
       <p>The aim is to obtain an optimal startup control for fuel flow rate and steam flow considering a constraint on termal stress. </p>
       <p>This is:</p>
       <pre> 3600s
          &int;  1e-3*(p_S - 110)^2 + 1e-4*(qm_S - 180)^2 dt  --&GT; min
          0                                                   u(t) </pre>
       <p>subject to the model:</p>
       <pre>  der(x) = f(x,u)
         x(0) = f0(p)</pre>
       <p>the control bounds:</p>
       <pre>  0          &LT;= Y_Valve  &LT;= 1
         0          &LT;=   q_F    &LT;= 500 MW
         -25 MW/min &LT;= der(q_F) &LT;= 25 MW/min
         q_F(0) = 0</pre>
       <p>and the state/output constraint:</p>
       <pre>  -150 N/mm2 &LT;= sigma_D</pre>
       <p>An appropriate discretization of the control inputs is piecewise linear with a discretization step size of 60s. The model variables can be initialized with the results of an initial-value simulation keeping the valve fully open and constantly ramping up the fuel flow rate, e.g. by 400MW/1h (see also table data provided with the simulation model in q_F_tab and Y_Valve_tab).</p>
       <p><h4><font color=\"#008000\">Initial state and parameter estimation</font></h4></p>
       <p>The aim is to estimate initial states and the heating value of the fuel for given measurement data. The conversion parameter MW2W.k is used instead of an explicitly modeled heating value. </p>
       <p>The estimation problem is:</p>
       <pre>  10
          &Sigma;  [(y(60*kk) - y_measured(60*kk))./{100,100,100,10,100}].^2  --&GT; min
         kk=0                                                             x(0), MW2W.k </pre>
       <p>subject to the model:</p>
       <pre>  der(x) = f(p,x,u)
         x(0) = f0(p)</pre>
       <p>The measurement data can be generated by performing an initial value simulation, e.g. using the provided table data as inputs. The estimation should start from a point away from the solution, e.g. MW2W.k=5e5. Moreover, noise may be added to the simulated measurement data.</p>
       <p><h4><font color=\"#008000\">Steady-state optimization</font></h4></p>
       <p>The goal of the steady-state optimization is to find values for the fuel flow rate q_F and the opening of the steam valve Y_Valve for which the heat input is minimized, subject to required steam pressure and mass flow rate.</p>
       <p>This is:</p>
       <pre>  q_F  --&GT;  min
                   x,u </pre>
       <p>subject to the steady-state model:</p>
       <pre>  0 = f(x,u)</pre>
       <p>and the constraints:</p>
       <pre>  0        &LT;= q_F     &LT;= 500 MW
         0        &LT;= Y_Valve &LT;= 1
         150 kg/s &LT;= qm_S    &LT;= 200 kg/s
         100 bar  &LT;= p_S     &LT;= 120 bar</pre>
       <p>The solution can be found at q_F = 328 MW, Y_Valve = 0.63 with the states evaporator.p = 120 bar, evaporator.V_liquid = 67 m3, and controller.x = 15.</p>
       </html>"), uses(Modelica(version = "3.2.1")));
  end DrumBoiler;

  model optDrumBoiler "
    On-line Optimization of DrumBoilerStartup
    Ruediger Franke, Manfred Rode and Klaus Krueger
    Paper presented at the 3rd International Modelica Conference

    see: https://openmodelica.org/images/docs/openmodelica2015/OpenModelica2015-talk02-Franke_Optimization.pdf
    "
    extends DrumBoiler(Y_Valve(min = 0, max = 1, nominal = 1, start = 0.5), q_F(min = 0, max = 500, start = 0, fixed = true, nominal = 400), controller.x(nominal = 10), use_inputs = true);
    drumBoiler.optimizationFormulation.ObjectFunction.Minimize cost_q_S(u = (p_S - 110) ^ 2, gain = 1e-3);
    drumBoiler.optimizationFormulation.ObjectFunction.Minimize cost_qm_S(u = (qm_S - 180) ^ 2, gain = 1e-4);
    drumBoiler.optimizationFormulation.Constraints.Band conSigma(MaxValue = 150, MinValue = -150, u = (-1.0e3 * der(evaporator.T_D)) + 1.0e-05 * evaporator.p);
    input Real dq_F(min = -25 / 60, max = 25 / 60, start = 0.1);
	  Real der_V_v(min = -0.02, max =0.025) = der(evaporator.V_v);
	  Real der_evaporator_p(min=0, max=3.2e4) = der(evaporator.p);
  equation
  
    der(q_F) = dq_F;
    annotation(experiment(StopTime = 3600, Tolerance = 1e-5));
  end optDrumBoiler;

  package optimizationFormulation
    package Constraints
      model Band
        parameter Real MaxValue(start = 1e120);
        parameter Real MinValue(start = -1e120);
        parameter Real gain=1;
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-114, 4}, extent = {{-14, -18}, {14, 10}}, rotation = 0)));
      protected
        Real con(min = MinValue, max = MaxValue) = gain * u annotation(isConstraint = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-25, -2}, extent = {{-57, 28}, {57, -28}}, textString = "u_min <= u(t) <= u_max")}));
      end Band;

      model BandFinal
        parameter Real MaxValue(start = 1e120);
        parameter Real MinValue(start = -1e120);
        parameter Real gain=1;
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-114, 4}, extent = {{-14, -18}, {14, 10}}, rotation = 0)));
      protected
        Real con(min = MinValue, max = MaxValue) = gain * u annotation(isFinalConstraint = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-25, -2}, extent = {{-57, 28}, {57, -28}}, textString = "u_min <= u(stopTime) <= u_max")}));
      end BandFinal;

      model GreaterEqual
        parameter Real gain(min = 0)=1;
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-114, 4}, extent = {{-14, -18}, {14, 10}}, rotation = 0)));
        Modelica.Blocks.Interfaces.RealInput u1 annotation(Placement(visible = true, transformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180), iconTransformation(origin = {116, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      protected
        Real con(max = 0) = gain * (u - u1) annotation(isConstraint = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-5, 6}, extent = {{-57, 28}, {57, -28}}, textString = " <= ")}));
      end GreaterEqual;

      model LessEqual
        parameter Real gain(min = 0)=1;
        Modelica.Blocks.Interfaces.RealInput u1 annotation(Placement(visible = true, transformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180), iconTransformation(origin = {112, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-114, 4}, extent = {{-14, -18}, {14, 10}}, rotation = 0)));
      protected
        Real con(min = 0) = gain * (u - u1) annotation(isConstraint = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-5, 6}, extent = {{-57, 28}, {57, -28}}, textString = " >= ")}));
      end LessEqual;

      model Equal
        parameter Real gain(min = 0) = 1;
        Modelica.Blocks.Interfaces.RealInput u1 annotation(Placement(visible = true, transformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180), iconTransformation(origin = {116, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-114, 4}, extent = {{-14, -18}, {14, 10}}, rotation = 0)));
      protected
        Real con(min = 0, max = 0) = gain * (u - u1) annotation(isConstraint = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-5, 6}, extent = {{-57, 28}, {57, -28}}, textString = " == "), Text(origin = {-6, -17}, extent = {{-14, 7}, {14, -7}}, textString = "at stop time")}));
      end Equal;

      model GreaterEqualFinal
        parameter Real gain(min = 0) = 1;
        Modelica.Blocks.Interfaces.RealInput u1 annotation(Placement(visible = true, transformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180), iconTransformation(origin = {112, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-114, 4}, extent = {{-14, -18}, {14, 10}}, rotation = 0)));
      protected
        Real con(max = 0) = gain * (u - u1) annotation(isFinalConstraint = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-5, 6}, extent = {{-57, 28}, {57, -28}}, textString = " <= ")}));
      end GreaterEqualFinal;

      model LessEqualFinal
        parameter Real gain(min = 0) = 1;
        Modelica.Blocks.Interfaces.RealInput u1 annotation(Placement(visible = true, transformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180), iconTransformation(origin = {112, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-114, 4}, extent = {{-14, -18}, {14, 10}}, rotation = 0)));
      protected
        Real con(min = 0) = gain * (u - u1) annotation(isFinalConstraint = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-5, 6}, extent = {{-57, 28}, {57, -28}}, textString = " >= "), Text(origin = {-2, -31}, extent = {{-14, 9}, {14, -9}}, textString = "at stop time")}));
      end LessEqualFinal;

      model EqualFinal
        parameter Real gain(min = 0)=1;
        Modelica.Blocks.Interfaces.RealInput u1 annotation(Placement(visible = true, transformation(origin = {110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 180), iconTransformation(origin = {112, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-114, 4}, extent = {{-14, -18}, {14, 10}}, rotation = 0)));
      protected
        Real con(min = 0, max = 0) = gain * (u - u1) annotation(isFinalConstraint = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-5, 6}, extent = {{-57, 28}, {57, -28}}, textString = " == "), Text(origin = {-6, -28}, extent = {{-24, 6}, {24, -6}}, textString = "at stop time")}));
      end EqualFinal;
      annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
    end Constraints;

    package ObjectFunction
      model MinimizeFinal
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-117, 1}, extent = {{-17, -17}, {17, 17}}, rotation = 0), iconTransformation(origin = {-118, -6}, extent = {{-18, -12}, {18, 24}}, rotation = 0)));
        parameter Real gain=1;
      protected
        Real signal = gain * u annotation(isMayer = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-25, 38}, extent = {{-35, 18}, {105, -70}}, textString = "minimize signal"), Text(origin = {-23, 14}, extent = {{-35, 18}, {105, -70}}, textString = "at the end time point")}));
      end MinimizeFinal;

      model MaximizeFinal
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-117, 1}, extent = {{-17, -17}, {17, 17}}, rotation = 0), iconTransformation(origin = {-118, -6}, extent = {{-18, -12}, {18, 24}}, rotation = 0)));
        parameter Real gain=1;
      protected
        Real signal = -gain * u annotation(isMayer = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-43, 38}, extent = {{-35, 18}, {105, -70}}, textString = "maximize signal"), Text(origin = {-43, 18}, extent = {{-35, 18}, {105, -70}}, textString = "at the end time point")}));
      end MaximizeFinal;

      model Maximize
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-117, 1}, extent = {{-17, -17}, {17, 17}}, rotation = 0), iconTransformation(origin = {-118, -6}, extent = {{-18, -12}, {18, 24}}, rotation = 0)));
        parameter Real gain=1;
      protected
        Real signal = -gain * u annotation(isLagrange = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-29, 38}, extent = {{-35, 18}, {105, -70}}, textString = "maximize signal"), Text(origin = {-29, 14}, extent = {{-35, 18}, {105, -70}}, textString = "over the time")}));
      end Maximize;

      model Minimize
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-117, 1}, extent = {{-17, -17}, {17, 17}}, rotation = 0), iconTransformation(origin = {-118, -6}, extent = {{-18, -12}, {18, 24}}, rotation = 0)));
        parameter Real gain=1;
      protected
        Real signal = gain * u annotation(isLagrange = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-35, 38}, extent = {{-35, 18}, {105, -70}}, textString = "minimize signal"), Text(origin = {-35, 12}, extent = {{-35, 18}, {105, -70}}, textString = "over the time")}));
      end Minimize;

      model MinimizeDifferenc
        parameter Real gain=1;
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-117, 81}, extent = {{-17, -17}, {17, 17}}, rotation = 0), iconTransformation(origin = {-118, -6}, extent = {{-18, -72}, {18, -36}}, rotation = 0)));
        Modelica.Blocks.Interfaces.RealInput u1 annotation(Placement(visible = true, transformation(origin = {-118, -60}, extent = {{-17, -17}, {17, 17}}, rotation = 0), iconTransformation(origin = {-116, 80}, extent = {{-17, -17}, {17, 17}}, rotation = 0)));
      protected
        Real signal = gain * (u - u1) ^ 2 annotation(isLagrange = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-41, 38}, extent = {{-35, 18}, {105, -70}}, textString = "minimize differenc"), Text(origin = {-41, 14}, extent = {{-35, 18}, {105, -70}}, textString = "over the time")}));
      end MinimizeDifferenc;

      model MinimizeDifferencFinal
        parameter Real gain=1;
        Modelica.Blocks.Interfaces.RealInput u annotation(Placement(visible = true, transformation(origin = {-117, 81}, extent = {{-17, -17}, {17, 17}}, rotation = 0), iconTransformation(origin = {-118, -6}, extent = {{-18, -72}, {18, -36}}, rotation = 0)));
        Modelica.Blocks.Interfaces.RealInput u1 annotation(Placement(visible = true, transformation(origin = {-118, -60}, extent = {{-17, -17}, {17, 17}}, rotation = 0), iconTransformation(origin = {-116, 80}, extent = {{-17, -17}, {17, 17}}, rotation = 0)));
      protected
        Real signal = gain * (u - u1) ^ 2 annotation(isMayer = true);
        annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics = {Text(origin = {-39, 36}, extent = {{-35, 18}, {105, -70}}, textString = "minimize difference"), Text(origin = {-39, 12}, extent = {{-35, 18}, {105, -70}}, textString = "at the end time")}));
      end MinimizeDifferencFinal;
      annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
    end ObjectFunction;
  end optimizationFormulation;
end drumBoiler;
