package PowerSystems  "Library for electrical power systems" 
  extends Modelica.Icons.Package;
  import Modelica.Constants.pi;
  import PowerSystems.Types.SI;
  import PowerSystems.Types.SIpu;

  model System  "System reference" 
    parameter Types.SystemFrequency fType = PowerSystems.Types.SystemFrequency.Parameter "system frequency type" annotation(Evaluate = true, Dialog(group = "Frequency"));
    parameter SI.Frequency f = f_nom "frequency if type is parameter, else initial frequency" annotation(Evaluate = true, Dialog(group = "Frequency", enable = fType == PowerSystems.Types.SystemFrequency.Parameter));
    parameter SI.Frequency f_nom = 50 "nominal frequency" annotation(Evaluate = true, Dialog(group = "Nominal"), choices(choice = 50, choice = 60));
    parameter SI.Frequency[2] f_lim = {0.5 * f_nom, 2 * f_nom} "limit frequencies (for supervision of average frequency)" annotation(Evaluate = true, Dialog(group = "Frequency", enable = fType <> PowerSystems.Types.SystemFrequency.Parameter));
    parameter SI.Angle alpha0 = 0 "phase angle" annotation(Evaluate = true, Dialog(group = "System"));
    parameter Types.ReferenceFrame refType = PowerSystems.Types.ReferenceFrame.Synchron "reference frame (3-phase)" annotation(Evaluate = true, Dialog(group = "System", enable = dynType <> PowerSystems.Types.Dynamics.SteadyState));
    parameter Types.Dynamics dynType = PowerSystems.Types.Dynamics.SteadyInitial "transient or steady-state model" annotation(Evaluate = true, Dialog(group = "Initialization"));
    final parameter SI.AngularFrequency omega_nom = 2 * pi * f_nom "nominal angular frequency" annotation(Evaluate = true);
    final parameter SI.AngularVelocity w_nom = 2 * pi * f_nom "nom r.p.m." annotation(Evaluate = true, Dialog(group = "Nominal"));
    final parameter Boolean synRef = refType == PowerSystems.Types.ReferenceFrame.Synchron or dynType == PowerSystems.Types.Dynamics.SteadyState annotation(Evaluate = true);
    discrete SI.Time initime;
    SI.Angle theta(final start = 0, stateSelect = if fType == Types.SystemFrequency.Parameter then StateSelect.default else StateSelect.always) "system angle";
    SI.Angle thetaRel = theta - thetaRef "angle relative to reference frame";
    SI.Angle thetaRef = if synRef then theta else 0 "angle of reference frame";
    SI.AngularFrequency omega(final start = 2 * pi * f);
    Modelica.Blocks.Interfaces.RealInput omega_in(min = 0) if fType == PowerSystems.Types.SystemFrequency.Signal "system angular frequency (optional if fType==Signal)" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
    Interfaces.Frequency receiveFreq "receives weighted frequencies from generators" annotation(Placement(transformation(extent = {{-96, 64}, {-64, 96}})));
  protected
    Modelica.Blocks.Interfaces.RealInput omega_internal;
  initial equation
    if fType <> Types.SystemFrequency.Parameter then
      theta = omega * time;
    end if;
  equation
    connect(omega_in, omega_internal);
    omega = omega_internal;
    when initial() then
      initime = time;
    end when;
    if fType == Types.SystemFrequency.Parameter then
      omega = 2 * pi * f;
      theta = omega * time;
    elseif fType == Types.SystemFrequency.Signal then
      theta = omega * time;
    else
      omega = if initial() then 2 * pi * f else receiveFreq.w_H / receiveFreq.H;
      der(theta) = omega;
      when omega < 2 * pi * f_lim[1] or omega > 2 * pi * f_lim[2] then
        terminate("FREQUENCY EXCEEDS BOUNDS!");
      end when;
    end if;
    receiveFreq.h = 0.0;
    receiveFreq.w_h = 0.0;
    annotation(preferredView = "info", defaultComponentName = "system", defaultComponentPrefixes = "inner", missingInnerMessage = "No \"system\" component is defined.
      Drag PowerSystems.System into the top level of your model.", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-100, 100}, {100, 60}}, lineColor = {0, 120, 120}, fillColor = {0, 120, 120}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 100}, {100, 60}}, lineColor = {215, 215, 215}, textString = "%name"), Text(extent = {{-100, 50}, {100, 20}}, lineColor = {0, 0, 0}, textString = "f:%fType"), Text(extent = {{-100, -20}, {100, 10}}, lineColor = {0, 0, 0}, textString = "f_nom=%f_nom"), Text(extent = {{-100, -30}, {100, -60}}, lineColor = {0, 120, 120}, textString = "%refType"), Text(extent = {{-100, -70}, {100, -100}}, lineColor = {176, 0, 0}, textString = "%dynType")}), Documentation(info = "<html>
  <p>The model <b>System</b> represents a global reference for the following purposes:</p>
  <p>It allows the choice of </p>
  <ul>
  <li> nominal frequency (default 50 or 60 Hertz, but arbitrary positive choice allowed)
  <li> system frequency or initial system frequency, depending on frequency type</li>
  <li> frequency type: parameter, signal, or average (machine-dependent) system frequency</li>
  <li> lower and upper limit-frequencies</li>
  <li> common phase angle for AC-systems</li>
  <li> synchronous or inertial reference frame for AC-3phase-systems</li>
  <li> transient or steady-state initialisation and simulation modes<br>
       For 'transient' initialisation no specific initial equations are defined.<br>
       This case allows also to use Dymola's steady-state initialisation, that is DIFFERENT from ours.<br>
       <b>Note:</b> the parameter 'sim' only affects AC three-phase components.</li>
  </ul>
  <p>It provides</p>
  <ul>
  <li> the system angular-frequency omega<br>
       For fType Parameter this is simply a parameter value.<br>
       For fType Signal it is a positive input signal.<br>
       For fType Average it is a weighted average over the relevant generator frequencies.</li>
  <li> the system angle theta by integration of <pre> der(theta) = omega </pre></li>
  <li> the reference angle <tt>thetaRef</tt> for defining the coordinate-orientation:<br>
       <tt>thetaRef = theta if refType == Synchron</tt> (reference frame is synchronously rotating with theta).<br>
       <tt>thetaRef = 0 if refType == Inertial</tt> (inertial reference frame, not rotating).<br></li>
  <li> the angle <tt>thetaRel = theta - thetaRef</tt></li>
  </ul>
  The angles allow the definition of a rotating or stationary electrical <b>coordinate system</b>.<br>
  Root-nodes defining coordinate-orientation will have the connector variable <tt>theta = {thetaRel, thetaRef}</tt>
  <p><b>Note</b>: Each model using <b>System</b> must use it with an <b>inner</b> declaration and
  instance name <b>system</b> in order that it can be accessed from all objects in the model.<br>
  When dragging the 'System' from the package browser into the diagram layer, declaration and instance name are automatically generated.</p>
  <p><a href=\"modelica://PowerSystems.UsersGuide.Overview\">up users guide</a></p>
  </html>
  ")); 
  end System;

  package Examples  
    extends Modelica.Icons.ExamplesPackage;

    package AC3ph  "Examples for AC3ph components" 
      extends Modelica.Icons.ExamplesPackage;

      package Inverters  "Inverters dq0" 
        extends Modelica.Icons.ExamplesPackage;

        model Rectifier  "Rectifier" 
          inner PowerSystems.System system(dynType = PowerSystems.Types.Dynamics.FixedInitial, refType = PowerSystems.Types.ReferenceFrame.Inertial) annotation(Placement(transformation(extent = {{-100, 80}, {-80, 100}})));
          PowerSystems.Blocks.Signals.TransientPhasor transPh(t_change = 0.1, t_duration = 0.1, a_start = 2, a_end = 1) annotation(Placement(transformation(extent = {{-100, 20}, {-80, 40}})));
          PowerSystems.AC3ph.Sources.Voltage vAC(use_vPhasor_in = true, V_nom = 100) annotation(Placement(transformation(extent = {{-80, 0}, {-60, 20}})));
          PowerSystems.AC3ph.Impedances.Inductor ind(r = 0.05, V_nom = 100, S_nom = 1e3) annotation(Placement(transformation(extent = {{-50, 0}, {-30, 20}})));
          PowerSystems.AC3ph.Sensors.PVImeter meterAC(abc = true, av = true, tcst = 0.1, V_nom = 100, S_nom = 1e3) annotation(Placement(transformation(extent = {{-20, 0}, {0, 20}})));
          PowerSystems.AC3ph.Inverters.Rectifier rectifier(redeclare model Rectifier = PowerSystems.AC3ph.Inverters.Components.RectifierEquation(redeclare record Data = PowerSystems.Examples.Data.Semiconductors.IdealSC100V_10A)) annotation(Placement(transformation(extent = {{30, 0}, {10, 20}})));
          PowerSystems.AC1ph_DC.Sensors.PVImeter meterDC(av = true, tcst = 0.1, V_nom = 100, S_nom = 1e3) annotation(Placement(transformation(extent = {{40, 0}, {60, 20}})));
          PowerSystems.AC1ph_DC.Sources.DCvoltage vDC(pol = 0, V_nom = 100) annotation(Placement(transformation(extent = {{90, 0}, {70, 20}})));
          PowerSystems.AC3ph.Nodes.GroundOne grd1 annotation(Placement(transformation(extent = {{-80, 0}, {-100, 20}})));
          PowerSystems.AC3ph.Nodes.GroundOne grd2 annotation(Placement(transformation(extent = {{90, 0}, {110, 20}})));
          PowerSystems.Common.Thermal.BdCondV bdCond(m = 3) annotation(Placement(transformation(extent = {{10, 20}, {30, 40}})));
        equation
          connect(vAC.term, ind.term_p) annotation(Line(points = {{-60, 10}, {-50, 10}}, color = {0, 110, 110}));
          connect(ind.term_n, meterAC.term_p) annotation(Line(points = {{-30, 10}, {-20, 10}}, color = {0, 110, 110}));
          connect(meterAC.term_n, rectifier.AC) annotation(Line(points = {{0, 10}, {10, 10}}, color = {0, 110, 110}));
          connect(rectifier.DC, meterDC.term_p) annotation(Line(points = {{30, 10}, {40, 10}}, color = {0, 0, 255}));
          connect(meterDC.term_n, vDC.term) annotation(Line(points = {{60, 10}, {70, 10}}, color = {0, 0, 255}));
          connect(transPh.y, vAC.vPhasor_in) annotation(Line(points = {{-80, 30}, {-64, 30}, {-64, 20}}, color = {0, 0, 127}));
          connect(grd1.term, vAC.neutral) annotation(Line(points = {{-80, 10}, {-80, 10}}, color = {0, 0, 255}));
          connect(vDC.neutral, grd2.term) annotation(Line(points = {{90, 10}, {90, 10}}, color = {0, 0, 255}));
          connect(rectifier.heat, bdCond.heat) annotation(Line(points = {{20, 20}, {20, 20}}, color = {176, 0, 0}));
          annotation(Documentation(info = "<html>
        <p>3-phase rectifier. Compare 'equation' and 'modular' version.</p>
        <p><a href=\"modelica://PowerSystems.Examples.AC3ph.Inverters\">up users guide</a></p>
        </html>
        "), experiment(StopTime = 0.2, Interval = 0.2e-3, Tolerance = 1e-005)); 
        end Rectifier;
        annotation(preferredView = "info", Documentation(info = "<html>
      <p>Comparison of different three-phase rectifier and inverter models.</p>
      <p><a href=\"modelica://PowerSystems.Examples\">up users guide</a></p>
      </html>
      ")); 
      end Inverters;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Introductory examples for detailed component models in AC3ph.</p>
    <p><a href=\"modelica://PowerSystems.Examples\">up users guide</a></p>
    </html>")); 
    end AC3ph;

    package Data  "Data" 
      extends Modelica.Icons.MaterialPropertiesPackage;

      package Semiconductors  "Breaker example data" 
        extends Modelica.Icons.MaterialPropertiesPackage;

        record IdealSC100V_10A  "Ideal semiconductor parameters, example" 
          extends PowerSystems.Semiconductors.Ideal.SCparameter(V_nom = 100, I_nom = 10, eps = {1e-4, 1e-4}, Vf = 1, Hsw_nom = 2e-3, cT_loss = fill(0, 0), T0_loss = 300);
          annotation(defaultComponentName = "idealSC100_10", defaultComponentPrefixes = "parameter", Documentation(info = "<html>
        </html>")); 
        end IdealSC100V_10A;
        annotation(preferredView = "info", Documentation(info = "<html>
      </html>")); 
      end Semiconductors;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Example data used in package SpotExamples.</p>
    <p><a href=\"modelica://PowerSystems.Examples\">up users guide</a></p>
    </html>")); 
    end Data;
  end Examples;

  package PhaseSystems  "Phase systems used in power connectors" 
    extends Modelica.Icons.Package;

    partial package PartialPhaseSystem  "Base package of all phase systems" 
      extends Modelica.Icons.Package;
      constant String phaseSystemName = "UnspecifiedPhaseSystem";
      constant Integer n "Number of independent voltage and current components";
      constant Integer m "Number of reference angles";
      constant SI.Voltage v_nominal = 1000 "Nominal voltage";
      constant SI.Current i_nominal = 1 "Nominal current";
      type Voltage = Real(unit = "V", quantity = "Voltage." + phaseSystemName, nominal = v_nominal, displayUnit = "kV") "voltage for connector";
      type Current = Real(unit = "A", quantity = "Current." + phaseSystemName, nominal = i_nominal) "current for connector";
      type ReferenceAngle = Types.ReferenceAngle "Reference angle for connector";

      replaceable function map  "Map vector of higher order phase system to this phase system" 
        input Real[:] x;
        output Real[n] y;
      algorithm
        y := x[1:n];
        annotation(Inline = true); 
      end map;

      replaceable partial function j  "Return vector rotated by 90 degrees" 
        extends Modelica.Icons.Function;
        input Real[n] x;
        output Real[n] y;
      end j;

      replaceable partial function phasePowers_vi  "Return phase powers" 
        extends Modelica.Icons.Function;
        input Voltage[n] v "phase voltages";
        input Current[n] i "phase currents";
        output SI.Power[n] p "phase powers";
      end phasePowers_vi;
    end PartialPhaseSystem;

    package TwoConductor  "Two conductors for Spot DC_AC1ph components" 
      extends PartialPhaseSystem(phaseSystemName = "TwoConductor", n = 2, m = 0);

      redeclare function j  "Direct current has no complex component" 
        extends Modelica.Icons.Function;
        input Real[n] x;
        output Real[n] y;
      algorithm
        y := zeros(n);
        annotation(Inline = true); 
      end j;

      redeclare function phasePowers_vi  "Return phase powers" 
        extends Modelica.Icons.Function;
        input Voltage[n] v "phase voltages";
        input Current[n] i "phase currents";
        output SI.Power[n] p "phase powers";
      algorithm
        p := v .* i;
        annotation(Inline = true); 
      end phasePowers_vi;
      annotation(Icon(graphics = {Line(points = {{-70, -28}, {50, -28}}, color = {95, 95, 95}, smooth = Smooth.None), Line(points = {{-70, 6}, {50, 6}}, color = {95, 95, 95}, smooth = Smooth.None)})); 
    end TwoConductor;

    package ThreePhase_dq0  "AC system in dq0 representation" 
      extends PartialPhaseSystem(phaseSystemName = "ThreePhase_dq0", n = 3, m = 2);

      redeclare function j  "Rotation(pi/2) of vector around {0,0,1} and projection on orth plane" 
        extends Modelica.Icons.Function;
        input Real[:] x;
        output Real[size(x, 1)] y;
      algorithm
        y := cat(1, {-x[2], x[1]}, zeros(size(x, 1) - 2));
        annotation(Inline = true); 
      end j;

      redeclare function phasePowers_vi  "Return phase powers" 
        extends Modelica.Icons.Function;
        input Voltage[n] v "phase voltages";
        input Current[n] i "phase currents";
        output SI.Power[n] p "phase powers";
      algorithm
        p := {v[1:2] * i[1:2], -j(v[1:2]) * i[1:2], v[3] * i[3]};
        annotation(Inline = true); 
      end phasePowers_vi;
      annotation(Icon(graphics = {Line(points = {{-70, 28}, {-58, 48}, {-38, 68}, {-22, 48}, {-10, 28}, {2, 8}, {22, -12}, {40, 8}, {50, 28}}, color = {95, 95, 95}, smooth = Smooth.Bezier), Line(points = {{-70, -54}, {50, -54}}, color = {95, 95, 95}, smooth = Smooth.None), Line(points = {{-70, -78}, {50, -78}}, color = {95, 95, 95}, smooth = Smooth.None), Line(points = {{-70, -28}, {50, -28}}, color = {95, 95, 95}, smooth = Smooth.None)}), Diagram(graphics = {Ellipse(extent = {{-60, 60}, {60, -60}}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid, pattern = LinePattern.None), Line(points = {{0, 0}, {90, 0}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}), Line(points = {{0, 0}, {-58, 68}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}), Line(points = {{0, 0}, {-58, -68}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}), Ellipse(extent = {{-50, 50}, {50, -50}}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, pattern = LinePattern.None), Ellipse(extent = {{-45, 46}, {45, -46}}, fillColor = {170, 213, 255}, fillPattern = FillPattern.Solid, pattern = LinePattern.None), Polygon(points = {{-26, 42}, {-4, 32}, {-28, -20}, {-46, -12}, {-46, 14}, {-32, 36}, {-26, 42}}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, pattern = LinePattern.None), Polygon(points = {{46, 10}, {28, 18}, {4, -34}, {22, -42}, {38, -30}, {48, -6}, {46, 10}}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, pattern = LinePattern.None), Line(points = {{0, 0}, {-82, 38}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}, thickness = 0.5), Line(points = {{0, 0}, {38, 82}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}, thickness = 0.5), Line(points = {{72, 0}, {72, 4}, {70, 18}, {66, 30}, {62, 38}, {56, 46}, {48, 54}, {36, 62}, {30, 65}}, color = {0, 0, 0}, arrow = {Arrow.None, Arrow.Filled}, smooth = Smooth.Bezier), Text(extent = {{60, 46}, {76, 36}}, pattern = LinePattern.None, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 0}, fontName = "Symbol", textString = "q", textStyle = {TextStyle.Italic}), Text(extent = {{76, 0}, {92, -10}}, pattern = LinePattern.None, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 0}, textString = "a", textStyle = {TextStyle.Italic}), Text(extent = {{-64, 64}, {-48, 54}}, pattern = LinePattern.None, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 0}, textString = "b", textStyle = {TextStyle.Italic}), Text(extent = {{-58, -60}, {-42, -70}}, pattern = LinePattern.None, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 0}, textString = "c", textStyle = {TextStyle.Italic}), Text(extent = {{22, 82}, {38, 72}}, pattern = LinePattern.None, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 0}, textString = "d", textStyle = {TextStyle.Italic}), Text(extent = {{-86, 36}, {-70, 26}}, pattern = LinePattern.None, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 0}, textString = "q", textStyle = {TextStyle.Italic}), Text(extent = {{-8, 0}, {8, -10}}, pattern = LinePattern.None, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 0}, textString = "0")})); 
    end ThreePhase_dq0;
    annotation(Icon(graphics = {Line(points = {{-70, -52}, {50, -52}}, color = {95, 95, 95}, smooth = Smooth.None), Line(points = {{-70, 8}, {-58, 28}, {-38, 48}, {-22, 28}, {-10, 8}, {2, -12}, {22, -32}, {40, -12}, {50, 8}}, color = {95, 95, 95}, smooth = Smooth.Bezier)})); 
  end PhaseSystems;

  package AC1ph_DC  "AC 1-phase and DC components from Spot AC1ph_DC" 
    extends Modelica.Icons.VariantsPackage;

    package Sensors  "Sensors n-phase or DC" 
      extends Modelica.Icons.SensorsPackage;

      model PVImeter  "Power-voltage-current meter, 1-phase" 
        parameter Boolean av = false "time average power" annotation(Evaluate = true, Dialog(group = "Options"));
        parameter SI.Time tcst(min = 1e-9) = 1 "average time-constant" annotation(Evaluate = true, Dialog(group = "Options", enable = av));
        extends Partials.Meter2Base;
        output SIpu.Power p(stateSelect = StateSelect.never);
        output SIpu.Power p_av = pav if av;
        output SIpu.Voltage v(stateSelect = StateSelect.never);
        output SIpu.Voltage v0(stateSelect = StateSelect.never);
        output SIpu.Current i(stateSelect = StateSelect.never);
        output SIpu.Current i0(stateSelect = StateSelect.never);
      protected
        outer System system;
        final parameter PS.Voltage V_base = Utilities.Precalculation.baseV(puUnits, V_nom);
        final parameter PS.Current I_base = Utilities.Precalculation.baseI(puUnits, V_nom, S_nom);
        SIpu.Power pav;
        SIpu.Voltage[2] v_ab;
        SIpu.Current[2] i_ab;
      initial equation
        if av then
          pav = p;
        end if;
      equation
        v_ab = term_p.v / V_base;
        i_ab = term_p.i / I_base;
        v = v_ab[1] - v_ab[2];
        v0 = (v_ab[1] + v_ab[2]) / 2;
        i = (i_ab[1] - i_ab[2]) / 2;
        i0 = i_ab[1] + i_ab[2];
        p = v_ab * i_ab;
        if av then
          der(pav) = (p - pav) / tcst;
        else
          pav = 0;
        end if;
        annotation(defaultComponentName = "PVImeter1", Documentation(info = "<html>
      <p>'Meters' are intended as diagnostic instruments. They allow displaying signals both in SI-units or in 'pu'.
      Use them only when and where needed. Otherwise use 'Sensors'.</p>
      <p>Output variables:</p>
      <pre>
        p     power term_p to term_n
        v     difference voltage 'plus' - 'minus'
        v0    average voltage ('plus' + 'minus')/2
        i     current term_p to term_n, ('plus' - 'minus')/2</pre>
        i0    sum current term_p to term_n, 'plus' + 'minus'
      </pre>
      </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-20, 20}, {20, -20}}, lineColor = {135, 135, 135}), Ellipse(extent = {{-8, 8}, {8, -8}}, lineColor = {135, 135, 135}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Line(points = {{0, 0}, {20, 0}}, color = {0, 0, 255}), Line(points = {{-15, 45}, {15, 59}}, color = {135, 135, 135}), Line(points = {{-15, 35}, {15, 49}}, color = {135, 135, 135})})); 
      end PVImeter;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model Sensor2Base  "Sensor Base, 1-phase" 
          extends Ports.Port_pn;
        equation
          term_p.v = term_n.v;
          annotation(Documentation(info = "<html>
        </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-70, 70}, {70, -70}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, 20}, {0, 90}}, color = {135, 135, 135}), Line(points = {{-88, 0}, {-20, 0}}, color = {0, 0, 255}), Line(points = {{0, 0}, {88, 0}}, color = {0, 0, 255}), Line(points = {{30, 20}, {70, 0}, {30, -20}}, color = {0, 0, 255})})); 
        end Sensor2Base;

        partial model Meter2Base  "Meter base 2 terminal, 1-phase" 
          extends Sensor2Base;
          extends Common.Nominal.Nominal;
          annotation(Icon(graphics = {Ellipse(extent = {{-70, 70}, {70, -70}}, lineColor = {135, 135, 135})})); 
        end Meter2Base;
      end Partials;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Sensors directly output terminal signals (voltage, current, power).</p>
    <p>Meters allow choosing base-units for output variables.</p>
    </html>
    ")); 
    end Sensors;

    package Sources  "DC voltage sources" 
      extends Modelica.Icons.SourcesPackage;

      model DCvoltage  "Ideal DC voltage" 
        extends Partials.DCvoltageBase(pol = -1);
        parameter SIpu.Voltage v0 = 1 "fixed DC voltage" annotation(Dialog(enable = not use_vDC_in));
      protected
        PS.Voltage v;
      equation
        if not use_vDC_in then
          vDC_internal = v0;
        end if;
        v = vDC_internal * V_base;
        term.v[1] - term.v[2] = v;
        annotation(defaultComponentName = "voltage1", Documentation(info = "<html>
      <p>DC voltage with constant amplitude when 'vType' is 'parameter',<br>
      with variable amplitude when 'vType' is 'signal'.</p>
      <p>Optional input:
      <pre>  vDC_in     DC voltage in SI or pu, depending on choice of 'units' </pre></p>
      </html>
      ")); 
      end DCvoltage;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model VoltageBase  "Voltage base" 
          extends Ports.Port_n;
          extends Common.Nominal.Nominal(final S_nom = 1);
          parameter Integer pol(min = -1, max = 1) = -1 "grounding scheme" annotation(Evaluate = true, choices(choice = 1, choice = 0, choice = -1));
          Interfaces.Electric_p neutral "(use for grounding)" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
        protected
          final parameter Real V_base = Utilities.Precalculation.baseV(puUnits, V_nom);
        equation
          if pol == 1 then
            term.v[1] = neutral.v;
          elseif pol == (-1) then
            term.v[2] = neutral.v;
          else
            term.v[1] + term.v[2] = neutral.v;
          end if;
          sum(term.i) + neutral.i = 0;
          annotation(Documentation(info = "<html>
        <p>Allows positive, symmetrical, and negativ grounding according to the choice of parameter 'pol'.<br>
        If the connector 'neutral' remains unconnected, then the source is NOT grounded. In all other cases connect 'neutral' to the desired circuit or ground.</p>
        </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-70, -70}, {70, 70}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-70, 0}, {70, 0}}, color = {176, 0, 0}, thickness = 0.5)})); 
        end VoltageBase;

        partial model DCvoltageBase  "DC voltage base" 
          extends VoltageBase;
          parameter Integer pol(min = -1, max = 1) = -1 "grounding scheme" annotation(Evaluate = true, choices(choice = 1, choice = 0, choice = -1));
          parameter Boolean use_vDC_in = false "= true to use input signal vDC_in, otherwise use fixed value" annotation(Evaluate = true, choices(checkBox = true));
          Modelica.Blocks.Interfaces.RealInput vDC_in if use_vDC_in "DC voltage" annotation(Placement(transformation(origin = {60, 100}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        protected
          Modelica.Blocks.Interfaces.RealInput vDC_internal "Needed to connect to conditional connector";
        equation
          connect(vDC_in, vDC_internal);
          annotation(Documentation(info = "<html>
        </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Text(extent = {{-50, 10}, {50, -60}}, lineColor = {176, 0, 0}, lineThickness = 0.5, fillColor = {127, 0, 255}, fillPattern = FillPattern.Solid, textString = "=")})); 
        end DCvoltageBase;
      end Partials;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>AC sources have the optional inputs:</p>
    <pre>
      vPhasor_in:   voltage {norm, phase}
      omega_in:     angular frequency
    </pre>
    <p>DC sources have the optional input:</p>
    <pre>  vDC_in:       DC voltage</pre>
    <p>To use signal inputs, choose parameters use_vPhasor_in=signal and/or fType=Signal.</p>
    </html>")); 
    end Sources;

    package Ports  "Strandard electric ports" 
      extends Modelica.Icons.InterfacesPackage;

      partial model PortBase  "base model defining PhaseSystem" 
        package PS = PhaseSystems.TwoConductor;
      end PortBase;

      connector TwoPin_p  "AC1/DC terminal ('positive')" 
        extends Interfaces.TerminalDC(redeclare package PhaseSystem = PhaseSystems.TwoConductor);
        annotation(defaultComponentName = "term_p", Documentation(info = "<html>
      <p>Electric connector with a vector of 'pin's, positive.</p>
      </html>
      "), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Polygon(points = {{-120, 0}, {0, -120}, {120, 0}, {0, 120}, {-120, 0}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 60}, {60, -60}}, lineColor = {255, 255, 255}, pattern = LinePattern.None, textString = "")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Text(extent = {{-120, 120}, {100, 60}}, lineColor = {0, 0, 255}, textString = "%name"), Polygon(points = {{-20, 0}, {40, -60}, {100, 0}, {40, 60}, {-20, 0}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-10, 50}, {90, -50}}, lineColor = {255, 255, 255}, pattern = LinePattern.None, textString = "")})); 
      end TwoPin_p;

      connector TwoPin_n  "AC1/DC terminal ('negative')" 
        extends Interfaces.TerminalDC(redeclare package PhaseSystem = PhaseSystems.TwoConductor);
        annotation(defaultComponentName = "term_n", Documentation(info = "<html>
      <p>Electric connector with a vector of 'pin's, negative.</p>
      </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Polygon(points = {{-120, 0}, {0, -120}, {120, 0}, {0, 120}, {-120, 0}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 60}, {60, -60}}, lineColor = {0, 0, 255}, pattern = LinePattern.None, lineThickness = 0.5, textString = "")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Text(extent = {{-100, 120}, {120, 60}}, lineColor = {0, 0, 255}, textString = "%name"), Polygon(points = {{-100, 0}, {-40, -60}, {20, 0}, {-40, 60}, {-100, 0}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-90, 50}, {10, -50}}, lineColor = {0, 0, 255}, pattern = LinePattern.None, lineThickness = 0.5, textString = "")})); 
      end TwoPin_n;

      partial model Port_n  "One port, 'negative'" 
        extends PortBase;
        Ports.TwoPin_n term "negative terminal" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
        annotation(Icon(graphics = {Text(extent = {{-100, -90}, {100, -130}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html></html>")); 
      end Port_n;

      partial model Port_p_n  "Two port" 
        extends PortBase;
        Ports.TwoPin_p term_p "positive terminal" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
        Ports.TwoPin_n term_n "negative terminal" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
        annotation(Icon(graphics = {Text(extent = {{-100, -90}, {100, -130}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html>
      </html>")); 
      end Port_p_n;

      partial model Port_pn  "Two port, 'current_in = current_out'" 
        extends Port_p_n;
      equation
        term_p.i + term_n.i = zeros(2);
        annotation(Documentation(info = "<html>
      </html>")); 
      end Port_pn;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Electrical ports with connectors Ports.AC1ph_DC:</p>
    <p>The index notation <tt>_p_n</tt> and <tt>_pn</tt> is used for</p>
    <pre>
      _p_n:     no conservation of current
      _pn:      with conservation of current
    </pre>
    </html>
    ")); 
    end Ports;
    annotation(preferredView = "info", Documentation(info = "<html>
  <p><a href=\"modelica://PowerSystems.UsersGuide\">up users guide</a></p>
  </html>
  ")); 
  end AC1ph_DC;

  package AC3ph  "AC three phase components from Spot ACdq0" 
    extends Modelica.Icons.VariantsPackage;
    replaceable package PackagePhaseSystem = PhaseSystems.ThreePhase_dq0 "Default phase system for AC3ph" annotation(choicesAllMatching = true);

    package Impedances  "Impedance and admittance two terminal" 
      extends Modelica.Icons.VariantsPackage;

      model Inductor  "Inductor with series resistor, 3-phase dq0" 
        extends Partials.ImpedBase;
        parameter SIpu.Resistance r = 0 "resistance";
        parameter SIpu.Reactance x_s = 1 "self reactance";
        parameter SIpu.Reactance x_m = 0 "mutual reactance, -x_s/2 < x_m < x_s";
      protected
        final parameter SI.Resistance[2] RL_base = Utilities.Precalculation.baseRL(puUnits, V_nom, S_nom, 2 * pi * f_nom);
        final parameter SI.Resistance R = r * RL_base[1];
        final parameter SI.Inductance L = (x_s - x_m) * RL_base[2];
        final parameter SI.Inductance L0 = (x_s + 2 * x_m) * RL_base[2];
      initial equation
        if dynType == Types.Dynamics.SteadyInitial then
          der(i) = omega[1] * j(i);
        elseif dynType == Types.Dynamics.FixedInitial then
          i = i_start;
        end if;
      equation
        if dynType <> Types.Dynamics.SteadyState then
          PS.map({L, L, L0}) .* der(i) + omega[2] * L * j(i) + R * i = v;
        else
          omega[2] * L * j(i) + R * i = v;
        end if;
        annotation(defaultComponentName = "ind1", Documentation(info = "<html>
      <p>Info see package ACdq0.Impedances.</p>
      </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Rectangle(extent = {{-80, 30}, {-40, -30}}, lineColor = {0, 120, 120}, lineThickness = 0.5, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-40, 30}, {80, -30}}, lineColor = {0, 120, 120}, lineThickness = 0.5, fillColor = {0, 120, 120}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Rectangle(extent = {{-60, 60}, {-40, 40}}, lineColor = {0, 0, 255}, lineThickness = 0.5, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-40, 60}, {60, 40}}, lineColor = {0, 0, 255}, lineThickness = 0.5, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-60, 10}, {-40, -10}}, lineColor = {0, 0, 255}, lineThickness = 0.5, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-40, 10}, {60, -10}}, lineColor = {0, 0, 255}, lineThickness = 0.5, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-60, -40}, {-40, -60}}, lineColor = {0, 0, 255}, lineThickness = 0.5, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-40, -40}, {60, -60}}, lineColor = {0, 0, 255}, lineThickness = 0.5, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-40, 30}, {60, 20}}, lineColor = {175, 175, 175}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-40, -20}, {60, -30}}, lineColor = {175, 175, 175}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-40, -70}, {60, -80}}, lineColor = {175, 175, 175}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid)})); 
      end Inductor;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model ImpedBase  "Impedance base, 3-phase dq0" 
          extends Ports.Port_pn;
          extends Common.Nominal.NominalAC;
          parameter Types.Dynamics dynType = system.dynType "transient or steady-state model" annotation(Evaluate = true, Dialog(tab = "Initialization"));
          parameter PS.Voltage[PS.n] v_start = zeros(PS.n) "start value of voltage drop" annotation(Dialog(tab = "Initialization"));
          parameter PS.Current[PS.n] i_start = zeros(PS.n) "start value of current" annotation(Dialog(tab = "Initialization"));
          PS.Voltage[PS.n] v(start = v_start);
          PS.Current[PS.n] i(start = i_start);
        protected
          SI.AngularFrequency[2] omega;
        equation
          omega = der(term_p.theta);
          v = term_p.v - term_n.v;
          i = term_p.i;
          annotation(Documentation(info = "<html>
        </html>
        "), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Line(points = {{-80, 50}, {-60, 50}}, color = {0, 0, 255}), Line(points = {{-80, 0}, {-60, 0}}, color = {0, 0, 255}), Line(points = {{-80, -50}, {-60, -50}}, color = {0, 0, 255}), Line(points = {{60, 50}, {80, 50}}, color = {0, 0, 255}), Line(points = {{60, 0}, {80, 0}}, color = {0, 0, 255}), Line(points = {{60, -50}, {80, -50}}, color = {0, 0, 255})})); 
        end ImpedBase;
      end Partials;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Contains lumped impedance models and can also be regarded as a collection of basic formulas. Shunts are part of a separate package.</p>
    <p>General relations.</p>
    <pre>
      r = R / R_base                  resistance
      x = 2*pi*f_nom*L/R_base         reactance
      g = G / G_base                  conductance
      b = (2*pi*f_nom*C) / G_base     susceptance
      G_base = 1/R_base
    </pre>
    <p>A) <b>Symmetric systems</b>.</p>
    <p>The reactance-matrix in abc-representation is</p>
    <pre>
              [x_s, x_m, x_m
      x_abc =  x_m, x_s, x_m
               x_m, x_m, x_s]
    </pre>
    <p>and corresponds to the following diagonal matrix in dq0-representation</p>
    <pre>
              [x, 0, 0
      x_dq0 =  0, x, 0
               0, 0, x0]
    </pre>
    <p>with the relations</p>
    <pre>
      x   = x_s - x_m           stray reactance (dq-components)
      x0  = x_s + 2*x_m         zero-reactance (o-component)
      x_s =  (2*x + x0)/3       self reactance single conductor
      x_m = -(x - x0)/3         mutual reactance
    </pre>
    <p>Coupling.</p>
    <pre>
      -x_s/2 &lt;  x_m &lt;  x_s
      uncoupled limit:          x_m = 0,               x0 = x
      fully positive coupled:   x_m = x_s,             x0 = 3*x_s
      fully negative coupled:   x_m = -x_s/2,          x0 = 0
      'practical' value:        x_m = -x_s*(2/13),     x0 = (3/5)*x
    </pre>
    <p>The corresponding resistance matrix is</p>
    <pre>
                      [r, 0, 0
      r_abc = r_dq0 =  0, r, 0
                       0, 0, r]
    </pre>
    <p>The susceptance matrices in abc- and in dq0-representation are</p>
    <pre>
              [ b_pg + 2b_pp, -b_pp,         -b_pp
      b_abc =  -b_pp,          b_pg + 2b_pp, -b_pp
               -b_pp,         -b_pp,          b_pg + 2b_pp]
              [ b_pg + 3*b_pp, 0,             0
      b_dq0 =   0,             b_pg + 3*b_pp, 0
                0,             0,             b_pg]
    </pre>
    <p>where <tt>_pg</tt> denotes 'phase-to-ground' and <tt>_pp</tt> 'phase-to-phase'.</p>
    <p>The corresponding conduction matrices are (in analogy to susceptance)</p>
    <pre>
              [ g_pg + 2g_pp, -g_pp,         -g_pp
      g_abc =  -g_pp,          g_pg + 2g_pp, -g_pp
               -g_pp,         -g_pp,          g_pg + 2g_pp]
              [ g_pg + 3*g_pp, 0,             0
      g_dq0 =   0,             g_pg + 3*g_pp, 0
                0,             0,             g_pg]
    </pre>
    <p>B) <b>Non symmetric systems</b>.</p>
    <p><tt>&nbsp; x_abc</tt> is an arbitrary symmetric matrix with positive diagonal elements</p>
    <p><tt>&nbsp; r_abc</tt> is an arbitrary diagonal matrix with positive elements</p>
    <p><tt>&nbsp; b_abc</tt> (phase-to-ground) is an arbitrary diagonal matrix with positive elements</p>
    <p><tt>&nbsp; b_abc</tt> (phase-to-phase) is of the form</p>
    <pre>
              [b_pp[2] + b_pp[3], -b_pp[3],           -b_pp[2]
      b_abc = -b_pp[3],            b_pp[3] + b_pp[1], -b_pp[1]
              -b_pp[2],           -b_pp[1],            b_pp[1] + b_pp[2]]
    </pre>
    <p><tt>&nbsp; g_abc(phase-to-ground)</tt> is an arbitrary diagonal matrix with positive elements</p>
    <p><tt>&nbsp; g_abc(phase-to-phase)</tt> is of the form</p>
    <pre>
              [g_pp[2] + g_pp[3], -g_pp[3],           -g_pp[2]
      g_abc = -g_pp[3],            g_pp[3] + g_pp[1], -g_pp[1]
              -g_pp[2],           -g_pp[1],            g_pp[1] + g_pp[2]]
    </pre>
    <p>where</p>
    <pre>
      index 1 denotes pair 2-3
      index 2 denotes pair 3-1
      index 3 denotes pair 1-2
    </pre>
    <p>The corresponding dq0-matrices are all obtained by Park-transformation P</p>
    <pre>
      x_dq0 = P*x_abc*transpose(P)
      r_dq0 = P*r_abc*transpose(P)
      b_dq0 = P*b_abc*transpose(P)
      g_dq0 = P*g_abc*transpose(P)
    </pre>
    </html>")); 
    end Impedances;

    package Inverters  "Rectifiers and Inverters" 
      extends Modelica.Icons.VariantsPackage;

      model Rectifier  "Rectifier, 3-phase dq0" 
        extends Partials.AC_DC_base(heat(final m = 3));
        replaceable model Rectifier = PowerSystems.AC3ph.Inverters.Components.RectifierEquation "rectifier model" annotation(choices(choice(redeclare model Rectifier = PowerSystems.AC3ph.Inverters.Components.RectifierEquation "equation, with losses"), choice(redeclare model Rectifier = PowerSystems.AC3ph.Inverters.Components.RectifierModular "modular, with losses")));
        Rectifier rectifier "rectifier model" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
      equation
        connect(AC, rectifier.AC) annotation(Line(points = {{100, 0}, {10, 0}}, color = {0, 120, 120}));
        connect(rectifier.DC, DC) annotation(Line(points = {{-10, 0}, {-100, 0}}, color = {0, 0, 255}));
        connect(rectifier.heat, heat) annotation(Line(points = {{0, 10}, {0, 100}}, color = {176, 0, 0}));
        annotation(defaultComponentName = "rectifier", Documentation(info = "<html>
      <p>Passive rectifier, allows choosing between equation-based and modular version.</p>
      </html>
      ")); 
      end Rectifier;

      package Components  "Equation-based and modular components" 
        extends Modelica.Icons.VariantsPackage;

        model RectifierEquation  "Rectifier equation, 3-phase dq0" 
          extends Partials.SwitchEquation(heat(final m = 3));
          replaceable record Data = PowerSystems.Semiconductors.Ideal.SCparameter(final Hsw_nom = 0) "SC parameters" annotation(choicesAllMatching = true);
          final parameter Data par "SC parameters" annotation(Placement(transformation(extent = {{-80, -80}, {-60, -60}})));
        protected
          PS.Voltage[3] V;
          PS.Voltage[3] v "voltage in inertial abc representation";
          PS.Voltage[3] i_sc "current scaled to voltage in inertial abc representation";
          Real[3] s(each start = 0.5) "arc-length on characteristic";
          Real[3] switch "switch function in inertial abc representation";
          Real[3, 3] Park = Utilities.Transforms.park(AC.theta[2]);
        equation
          i_sc = transpose(Park) * AC.i * par.V_nom / par.I_nom;
          for k in 1:3 loop
            V[k] = if size(par.cT_loss, 1) == 0 then vDC1 + par.Vf else vDC1 + par.Vf * loss(T[k] - par.T0_loss, par.cT_loss);
            if s[k] > V[k] then
              {v[k], i_sc[k]} = {par.eps[1] * s[k] + (1 - par.eps[1]) * V[k], s[k] - (1 - par.eps[2]) * V[k]};
            elseif s[k] < (-V[k]) then
              {v[k], i_sc[k]} = {par.eps[1] * s[k] - (1 - par.eps[1]) * V[k], s[k] + (1 - par.eps[2]) * V[k]};
            else
              {v[k], i_sc[k]} = {s[k], par.eps[2] * s[k]};
            end if;
            switch[k] = noEvent(sign(s[k]));
          end for;
          v_dq0 = Park * v;
          switch_dq0 = Park * switch;
          Q_flow = (v - switch * vDC1) .* i_sc * par.I_nom / par.V_nom;
          annotation(defaultComponentName = "rectifier", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Text(extent = {{-60, -70}, {60, -90}}, lineColor = {176, 0, 0}, textString = "eq")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Polygon(points = {{-10, -38}, {0, -18}, {10, -38}, {-10, -38}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-10, 18}, {0, 38}, {10, 18}, {-10, 18}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, -18}, {0, 18}}, color = {0, 0, 255}), Line(points = {{-10, -18}, {10, -18}}, color = {0, 0, 255}), Line(points = {{-10, 38}, {10, 38}}, color = {0, 0, 255}), Line(points = {{0, 0}, {60, 0}}, color = {0, 0, 255}), Text(extent = {{-40, -60}, {40, -80}}, lineColor = {176, 0, 0}, textString = "time resolved equation"), Line(points = {{-70, 10}, {-60, 10}, {-60, 52}, {0, 52}, {0, 40}}, color = {0, 0, 255}), Line(points = {{-70, -10}, {-60, -10}, {-60, -50}, {0, -50}, {0, -38}}, color = {0, 0, 255})}), Documentation(info = "<html>
        <p>Passive rectifier, based on switch-equation.<br>
        Blocking losses are neglected in the expression of dissipated heat <tt>Q_flow</tt>.</p>
        </html>")); 
        end RectifierEquation;
        annotation(preferredView = "info", Documentation(info = "<html>
      <p>Contains alternative components:
      <ul>
      <li>Equation-based: faster code, restricted to ideal V-I characteristic, but including forward threshold voltage, needed for calculation of thermal losses.</li>
      <li>Modular: composed from semiconductor-switches and diodes. These components with ideal V-I characteristic can be replaced by custom-specified semiconductor models.</li>
      </ul>
      </html>")); 
      end Components;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model AC_DC_base  "AC-DC base, 3-phase dq0" 
          extends PowerSystems.Icons.Inverter_dq0;
          extends Ports.PortBase;
          Ports.ACdq0_n AC "AC 3-phase connection" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
          AC1ph_DC.Ports.TwoPin_p DC "DC connection" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
          Interfaces.ThermalV_n heat(m = 3) "vector heat port" annotation(Placement(transformation(origin = {0, 100}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
          annotation(Documentation(info = "<html>
        </html>")); 
        end AC_DC_base;

        partial model SwitchEquation  "Switch equation, 3-phase dq0" 
          extends AC_DC_base;
        protected
          PS.Voltage vDC1 = 0.5 * (DC.v[1] - DC.v[2]);
          PS.Voltage vDC0 = 0.5 * (DC.v[1] + DC.v[2]);
          PS.Current iDC1 = DC.i[1] - DC.i[2];
          PS.Current iDC0 = DC.i[1] + DC.i[2];
          Real[PS.n] v_dq0 "switching function voltage in dq0 representation";
          Real[PS.n] switch_dq0 "switching function in dq0 representation";
          SI.Temperature[heat.m] T "component temperature";
          SI.HeatFlowRate[heat.m] Q_flow "component loss-heat flow";
          function loss = Utilities.Math.taylor "temp dependence of losses";
          SI.Conductance C0 = 1 "for dq phase system";
        equation
          AC.v = v_dq0 + PS.map({0, 0, sqrt(3) * vDC0});
          iDC1 + switch_dq0 * AC.i = 0;
          if PS.n > 2 then
            iDC0 + sqrt(3) * AC.i[3] = 0;
          else
            iDC0 = C0 * vDC0 "iDC0 = 0, vDC0 = 0";
          end if;
          T = heat.ports.T;
          heat.ports.Q_flow = -Q_flow;
          annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{68, 18}, {72, 22}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Ellipse(extent = {{68, -2}, {72, 2}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Ellipse(extent = {{68, -22}, {72, -18}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Text(extent = {{76, 24}, {84, 16}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, textString = "a"), Text(extent = {{76, 4}, {84, -4}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, textString = "b"), Text(extent = {{76, -16}, {84, -24}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, textString = "c"), Ellipse(extent = {{-72, 12}, {-68, 8}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-72, -8}, {-68, -12}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-86, 16}, {-74, 4}}, lineColor = {0, 0, 255}, textString = "+"), Text(extent = {{-86, -4}, {-74, -16}}, lineColor = {0, 0, 255}, textString = "-")}), Documentation(info = "<html>
        </html>")); 
        end SwitchEquation;
        annotation(Documentation(info = "<html>
      </html>")); 
      end Partials;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>The package contains passive rectifiers and switched/modulated inverters. Different implementations use:
    <ul>
    <li>Phase-modules (pairs of diodes or pairs of IGBT's with antiparallel diodes).</li>
    <li>The switch-equation for ideal components.</li>
    <li>The time-averaged switch-equation. As models based on single-switching are generally slow in simulation, alternative 'averaged' models are useful in cases, where details of current and voltage signals can be ignored.</li>
    </ul>
    <p>Thermal losses are proportional to the forward voltage drop V, which may depend on temperature.<br>
    The temperature dependence is given by
    <pre>  V(T) = Vf*(1 + cT[1]*(T - T0) + cT[2]*(T - T0)^2 + ...)</pre>
    where <tt>Vf</tt> denotes the parameter value. With input <tt>cT</tt> empty, no temperature dependence of losses is calculated.</p>
    <p>The switching losses are approximated by
    <pre>
      h = Hsw_nom*v*i/(V_nom*I_nom)
      use:
      S_nom = V_nom*I_nom
    </pre>
    where <tt>Hsw_nom</tt> denotes the dissipated heat per switching operation at nominal voltage and current, averaged over 'on' and 'off'. The same temperature dependence is assumed as for Vf. A generalisation to powers of i and v is straightforward.</p>
    <p>NOTE: actually the switching losses are only implemented for time-averaged components!</p>
    </html>
    ")); 
    end Inverters;

    package Nodes  "Nodes and adaptors" 
      extends Modelica.Icons.VariantsPackage;

      model GroundOne  "Ground, one conductor" 
        Interfaces.Electric_p term "positive scalar terminal" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
      equation
        term.v = 0;
        annotation(defaultComponentName = "grd1", Documentation(info = "<html>
      <p>Zero voltage on terminal.</p>
      </html>
      "), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Text(extent = {{-100, -90}, {100, -130}}, lineColor = {0, 0, 0}, textString = "%name"), Rectangle(extent = {{-4, 50}, {4, -50}}, lineColor = {128, 128, 128}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid), Line(points = {{-90, 0}, {-4, 0}}, color = {0, 0, 255})}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Line(points = {{-60, 0}, {-80, 0}}, color = {0, 0, 255}), Rectangle(extent = {{-60, 20}, {-54, -20}}, lineColor = {128, 128, 128}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid)})); 
      end GroundOne;
      annotation(preferredView = "info", Documentation(info = "<html>
    </html>
    ")); 
    end Nodes;

    package Sensors  "Sensors and meters 3-phase" 
      extends Modelica.Icons.SensorsPackage;

      model PVImeter  "Power-voltage-current meter, 3-phase dq0" 
        extends Partials.Meter2Base;
        parameter Boolean av = false "time average power" annotation(Evaluate = true, Dialog(group = "Options"));
        parameter SI.Time tcst(min = 1e-9) = 1 "average time-constant" annotation(Evaluate = true, Dialog(group = "Options", enable = av));

        function v2vpp_abc  
          input SIpu.Voltage[3] v_abc;
          output SIpu.Voltage[3] vpp_abc;
        algorithm
          vpp_abc := {v_abc[2], v_abc[3], v_abc[1]} - {v_abc[3], v_abc[1], v_abc[2]};
        end v2vpp_abc;

        output SIpu.Power[PS.n] p(each stateSelect = StateSelect.never);
        output SIpu.Power[PS.n] p_av = pav if av;
        output SIpu.Voltage[PS.n] v(each stateSelect = StateSelect.never);
        output SIpu.Voltage[2] vpp(each stateSelect = StateSelect.never);
        output SIpu.Current[PS.n] i(each stateSelect = StateSelect.never);
        output SIpu.Voltage[3] v_abc(each stateSelect = StateSelect.never) = transpose(Park) * v if abc;
        output SIpu.Voltage[3] vpp_abc(each stateSelect = StateSelect.never) = v2vpp_abc(transpose(Park) * v) if abc;
        output SIpu.Current[3] i_abc(each stateSelect = StateSelect.never) = transpose(Park) * i if abc;
        output SIpu.Voltage v_norm(stateSelect = StateSelect.never);
        output SI.Angle alpha_v(stateSelect = StateSelect.never);
        output SIpu.Current i_norm(stateSelect = StateSelect.never);
        output SI.Angle alpha_i(stateSelect = StateSelect.never);
        output Real cos_phi(stateSelect = StateSelect.never);
      protected
        outer System system;
        final parameter PS.Voltage V_base = Utilities.Precalculation.baseV(puUnits, V_nom);
        final parameter PS.Current I_base = Utilities.Precalculation.baseI(puUnits, V_nom, S_nom);
        SIpu.Power[PS.n] pav;
      initial equation
        if av then
          pav = p;
        end if;
      equation
        v = term_p.v / V_base;
        vpp = sqrt(3) * {v[2], -v[1]};
        i = term_p.i / I_base;
        p = PS.phasePowers_vi(v, i);
        if av then
          der(pav) = (p - pav) / tcst;
        else
          pav = zeros(PS.n);
        end if;
        v_norm = sqrt(v * v);
        alpha_v = atan2(Rot_dq[:, 2] * v[1:2], Rot_dq[:, 1] * v[1:2]);
        i_norm = sqrt(i * i);
        alpha_i = atan2(Rot_dq[:, 2] * i[1:2], Rot_dq[:, 1] * i[1:2]);
        cos_phi = cos(alpha_v - alpha_i);
        annotation(defaultComponentName = "PVImeter1", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Rectangle(extent = {{-20, 24}, {20, 20}}, lineColor = {135, 135, 135}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-8, 8}, {8, -8}}, lineColor = {135, 135, 135}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Line(points = {{0, 0}, {20, 0}}, color = {0, 100, 100}, thickness = 0.5), Line(points = {{-15, 50}, {15, 64}}, color = {135, 135, 135}), Line(points = {{-15, 40}, {15, 54}}, color = {135, 135, 135}), Line(points = {{-15, 30}, {15, 44}}, color = {135, 135, 135})}), Documentation(info = "<html>
      <p>'Meters' are intended as diagnostic instruments. They allow displaying signals in alternative representations, both in SI-units or in 'pu'.<br>
      As they use time-dependent coordinate transforms, use them only when and where needed. Otherwise use 'Sensors'.</p>
      <p>Output variables in the chosen reference system:</p>
      <pre>
        p         {AC active, AC reactive, DC} power term_p to term_n
        v          voltage phase-to-ground dq0
        vpp        voltage phase-to-phase dq
        i          current dq0, term_p to term_n
      </pre>
      <p>Optional output variables:</p>
      <pre>
        p_av       power term_p to term_n, time tau average of p
        v_abc      voltage phase-to-ground,  abc-inertial system
        vpp_abc    voltage phase-to-phase,   abc-inertial system
        i_abc      current term_p to term_n, abc-inertial system
        v_norm     norm(v)
        i_norm     norm(i)
        alpha_v    phase(v)
        alpha_i    phase(i)
        cos_phi    cos(alpha_v - alpha_i)
      </pre>
      <p><i>Comment on the sign-definition of reactive power see</i> ACdq0.Sensors.</p>
      </html>
      ")); 
      end PVImeter;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model Sensor2Base  "Sensor 2 terminal base, 3-phase dq0" 
          extends Ports.Port_pn;
          parameter Integer signalTrsf = 0 "signal in which reference frame?" annotation(Evaluate = true, Dialog(group = "Options"), choices(choice = 0, choice = 1, choice = 2, choice = 3));
        protected
          function park = Utilities.Transforms.park;
          function rot_dq = Utilities.Transforms.rotation_dq;
        equation
          term_p.v = term_n.v;
          annotation(Documentation(info = "<html>
        </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-70, 70}, {70, -70}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, 20}, {0, 90}}, color = {135, 135, 135}), Line(points = {{-90, 0}, {-20, 0}}, color = {0, 100, 100}, thickness = 0.5), Line(points = {{0, 0}, {90, 0}}, color = {0, 100, 100}, thickness = 0.5), Line(points = {{30, 20}, {70, 0}, {30, -20}}, color = {0, 100, 100}, thickness = 0.5), Ellipse(extent = {{-20, 20}, {20, -20}}, lineColor = {135, 135, 135})})); 
        end Sensor2Base;

        partial model Meter2Base  "Meter 2 terminal base, 3-phase dq0" 
          extends Sensor2Base(final signalTrsf = 0);
          extends Common.Nominal.Nominal;
          parameter Boolean abc = false "abc inertial" annotation(Evaluate = true, Dialog(group = "Options"));
        protected
          Real[3, 3] Park;
          Real[2, 2] Rot_dq;
          function atan2 = Modelica.Math.atan2;
        equation
          if abc then
            Park = park(term_p.theta[2]);
          else
            Park = zeros(3, 3);
          end if;
          Rot_dq = rot_dq(term_p.theta[1]);
          annotation(Documentation(info = "<html>
        </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-70, 70}, {70, -70}}, lineColor = {135, 135, 135})})); 
        end Meter2Base;
      end Partials;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Sensors output terminal signals (voltage, current, power) in a defined reference system chosen by the user.</p>
    <p>Meters allow choosing base-units for output variables.</p>
    <p><i>Comment on the sign-definition of reactive power:</i></p>
    <p>From a mathematical point of view, it would be desirable to define power in the following way:
    <pre>
      p_active = v*i
      p_reactive = (J*v)*i
    </pre>
    <p>with</p>
    <pre>  J = [0,-1,0; 1,0,0; 0,0,0]</pre>
    <p>the rotation of pi/2 in the positive sense.</p>
    <p>This definition keeps all coordinate systems positively oriented.
    The power-vector then can be interpreted as current-vector, normalised by voltage and transformed into a positively oriented coordinate system, whose first axis is given by the voltage vector <tt>v</tt>, and second axis by <tt>J*v</tt>.</p>
    <p>From a practical point of view it is more convenient to use the inverse sign for reactive power, in order to obtain positive reactive power in the standard-situation of power-transfer
    across an inductive line.
    We adapt the sign-definition to this practical convention:</p>
    <pre>  p_reactive = -(J*v)*i</pre>
    </html>
    ")); 
    end Sensors;

    package Sources  "Voltage and Power Sources" 
      extends Modelica.Icons.SourcesPackage;

      model Voltage  "Ideal voltage, 3-phase dq0" 
        extends Partials.VoltageBase;
        parameter SIpu.Voltage v0 = 1 "fixed voltage" annotation(Dialog(enable = not use_vPhasor_in));
        parameter SI.Angle alpha0 = 0 "fixed phase angle" annotation(Dialog(enable = not use_vPhasor_in));
      protected
        PS.Voltage V;
        SI.Angle alpha;
        SI.Angle phi;
      equation
        if not use_vPhasor_in then
          vPhasor_internal = {v0, alpha0};
        end if;
        V = vPhasor_internal[1] * V_base;
        alpha = vPhasor_internal[2];
        phi = term.theta[1] + alpha + system.alpha0;
        term.v = PS.map({V * cos(phi), V * sin(phi), sqrt(3) * neutral.v});
        annotation(defaultComponentName = "voltage1", Documentation(info = "<html>
      <p>Voltage with constant amplitude and phase when 'vType' is 'parameter',<br>
      with variable amplitude and phase when 'vType' is 'signal'.</p>
      <p>Optional input:
      <pre>
        omega_in           angular frequency (choose fType == \"Signal\")
        vPhasor_in         {norm(v), phase(v)}, amplitude(v_abc)=sqrt(2/3)*vPhasor_in[1]
         vPhasor_in[1]     in SI or pu, depending on choice of 'units'
         vPhasor_in[2]     in rad
      </pre></p>
      </html>
      ")); 
      end Voltage;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model SourceBase  "Voltage base, 3-phase dq0" 
          extends Ports.Port_n;
          extends Common.Nominal.Nominal;
          Interfaces.Electric_p neutral "(use for grounding)" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
        protected
          outer System system;
          final parameter PS.Voltage V_base = Utilities.Precalculation.baseV(puUnits, V_nom);
          SI.Angle theta(stateSelect = StateSelect.prefer) "absolute angle";
        equation
          Connections.potentialRoot(term.theta);
          if Connections.isRoot(term.theta) then
            term.theta = {system.thetaRel, system.thetaRef};
          end if;
          if PS.n > 2 then
            sqrt(3) * term.i[3] + neutral.i = 0;
          else
            neutral.i = 0;
          end if;
          annotation(Documentation(info = "<html>
        <p>If the connector 'neutral' remains unconnected, then the source has an isolated neutral point. In all other cases connect 'neutral' to the desired circuit or ground.</p>
        </html>")); 
        end SourceBase;

        partial model VoltageBase  "Voltage base, 3-phase dq0" 
          extends SourceBase(final S_nom = 1);
          parameter Types.SourceFrequency fType = PowerSystems.Types.SourceFrequency.System "frequency type" annotation(Evaluate = true, Dialog(group = "Frequency"));
          parameter SI.Frequency f = system.f "frequency if type is parameter" annotation(Dialog(group = "Frequency", enable = fType == PowerSystems.Types.SourceFrequency.Parameter));
          parameter Boolean use_vPhasor_in = false "= true to use input signal vPhasor_in, otherwise use fixed values" annotation(Evaluate = true, choices(checkBox = true));
          Modelica.Blocks.Interfaces.RealInput omega_in(final unit = "rad/s") if fType == PowerSystems.Types.SourceFrequency.Signal "angular frequency" annotation(Placement(transformation(origin = {-60, 100}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
          Modelica.Blocks.Interfaces.RealInput[2] vPhasor_in if use_vPhasor_in "{abs(voltage), phase}" annotation(Placement(transformation(origin = {60, 100}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        protected
          Modelica.Blocks.Interfaces.RealInput omega_internal "Needed to connect to conditional connector";
          Modelica.Blocks.Interfaces.RealInput[2] vPhasor_internal "Needed to connect to conditional connector";
        initial equation
          if fType == Types.SourceFrequency.Signal then
            theta = 0;
          end if;
        equation
          connect(omega_in, omega_internal);
          connect(vPhasor_in, vPhasor_internal);
          if fType <> Types.SourceFrequency.Signal then
            omega_internal = 0.0;
          end if;
          if fType == Types.SourceFrequency.System then
            theta = system.theta;
          elseif fType == Types.SourceFrequency.Parameter then
            theta = 2 * pi * f * (time - system.initime);
          elseif fType == Types.SourceFrequency.Signal then
            der(theta) = omega_internal;
          end if;
          annotation(Documentation(info = "<html>
        </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-70, -70}, {70, 70}}, lineColor = {0, 100, 100}, lineThickness = 0.5, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-70, 0}, {70, 0}}, color = {176, 0, 0}, thickness = 0.5), Text(extent = {{-50, 30}, {50, -70}}, lineColor = {176, 0, 0}, lineThickness = 0.5, fillColor = {127, 0, 255}, fillPattern = FillPattern.Solid, textString = "~")})); 
        end VoltageBase;
      end Partials;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>The sources have optional inputs:</p>
    <pre>
      vPhasor_in:   voltage {norm, phase}
      omega_in:     angular frequency
      pv:        {active power, abs(voltage)}  (only PVsource)
      p:         {active power, rective power} (only PQsource)
    </pre>
    <p>To use signal inputs, choose parameters vType=signal and/or fType=Signal.</p>
    <p>General relations between voltage-norms, effective- and peak-values is shown in the table, both
    relative to each other (pu, norm = 1) and as example (SI, 400 V).</p>
    <table border=1 cellspacing=0 cellpadding=4>
    <tr> <th></th> <th></th> <th><b>pu</b></th> <th><b>V</b></th> </tr>
    <tr><td>Three-phase norm</td><td>|v_abc|</td><td><b>1</b></td><td><b>400</b></td></tr>
    <tr><td>Single-phase amplitude</td><td>ampl (v_a), ..</td><td>sqrt(2/3)</td> <td>326</td> </tr>
    <tr><td>Single-phase effective</td><td>eff (v_a), ..</td><td><b>1/sqrt(3)</b></td><td><b>230</b></td></tr>
    <tr><td>Phase to phase amplitude</td><td>ampl (v_b - v_c), ..</td><td>sqrt(2)</td><td>565</td></tr>
    <tr><td>Phase to phase effective</td><td>eff (v_b - v_c), ..</td><td><b>1</b></td><td><b>400</b></td></tr>
    <tr><td>Three-phase norm</td><td>|v_dq0|</td><td><b>1</b></td><td><b>400</b></td> </tr>
    <tr><td>Phase to phase dq-norm</td><td>|vpp_dq|</td><td>sqrt(2)</td><td>565</td></tr>
    </table>
    </html>
    ")); 
    end Sources;

    package Ports  "AC three-phase ports dq0 representation" 
      extends Modelica.Icons.InterfacesPackage;

      partial model PortBase  "base model adapting Spot to PowerSystems" 
        package PS = PackagePhaseSystem;
        function j = PS.j annotation(Inline = true);
      end PortBase;

      connector ACdq0_p  "AC terminal, 3-phase dq0 ('positive')" 
        extends Interfaces.Terminal(redeclare package PhaseSystem = PackagePhaseSystem);
        annotation(defaultComponentName = "term_p", Documentation(info = "<html>
      <p>AC connector with vector variables in dq0-representation, positive.</p>
      </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 120, 120}, fillColor = {0, 120, 120}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 60}, {60, -60}}, lineColor = {255, 255, 255}, textString = "dq0")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{0, 50}, {100, -50}}, lineColor = {0, 120, 120}, fillColor = {0, 120, 120}, fillPattern = FillPattern.Solid), Text(extent = {{12, 40}, {90, -40}}, lineColor = {255, 255, 255}, pattern = LinePattern.None, textString = "dq0"), Text(extent = {{-120, 120}, {100, 60}}, lineColor = {0, 120, 120}, textString = "%name")})); 
      end ACdq0_p;

      connector ACdq0_n  "AC terminal, 3-phase dq0 ('negative')" 
        extends Interfaces.Terminal(redeclare package PhaseSystem = PackagePhaseSystem);
        annotation(defaultComponentName = "term_n", Documentation(info = "<html>
      <p>AC connector with vector variables in dq0-representation, negative.</p>
      </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 60}, {60, -60}}, lineColor = {0, 120, 120}, textString = "dq0")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-100, 50}, {0, -50}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-90, 40}, {-10, -40}}, lineColor = {0, 120, 120}, textString = "dq0"), Text(extent = {{-100, 120}, {120, 60}}, lineColor = {0, 120, 120}, fillColor = {0, 100, 100}, fillPattern = FillPattern.Solid, textString = "%name")})); 
      end ACdq0_n;

      partial model Port_n  "AC one port 'negative', 3-phase" 
        extends PortBase;
        Ports.ACdq0_n term "negative terminal" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
        annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-100, -90}, {100, -130}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html></html>")); 
      end Port_n;

      partial model Port_p_n  "AC two port, 3-phase" 
        extends PortBase;
        Ports.ACdq0_p term_p "positive terminal" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
        Ports.ACdq0_n term_n "negative terminal" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
      equation
        Connections.branch(term_p.theta, term_n.theta);
        term_n.theta = term_p.theta;
        annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-100, -90}, {100, -130}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html>
      </html>")); 
      end Port_p_n;

      partial model Port_pn  "AC two port 'current_in = current_out', 3-phase" 
        extends Port_p_n;
      equation
        term_p.i + term_n.i = zeros(PS.n);
        annotation(Documentation(info = "<html>
      </html>")); 
      end Port_pn;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Electrical ports with connectors ACdq0:</p>
    <p>The index notation <tt>_p_n</tt> and <tt>_pn</tt> is used for</p>
    <pre>
      _p_n:     no conservation of current
      _pn:      with conservation of current
    </pre>
    </html>
    ")); 
    end Ports;
  end AC3ph;

  package Blocks  "Blocks" 
    extends Modelica.Icons.Package;

    package Signals  "Special signals" 
      extends Modelica.Icons.VariantsPackage;

      block TransientPhasor  "Transient {norm, phase} of vector" 
        extends Partials.MO(final n = 2);
        parameter SI.Time t_change = 0.5 "time when change";
        parameter SI.Time t_duration = 1 "transition duration";
        parameter Real a_start = 1 "initial norm |y|";
        parameter Real a_end = 1 "final norm |y|";
        parameter SI.Angle ph_start = 0 "initial phase (y)";
        parameter SI.Angle ph_end = 0 "final phase (y)";
      protected
        final parameter SI.Frequency coef = 2 * exp(1) / t_duration;
      equation
        y = 0.5 * ({a_end + a_start, ph_end + ph_start} + {a_end - a_start, ph_end - ph_start} * tanh(coef * (time - t_change)));
        annotation(defaultComponentName = "transPh1", Documentation(info = "<html>
      <p>The signal is a two-dimensional vector in polar representation.<br>
      Norm and phase change from <tt>{a_start, ph_start}</tt> to <tt>{a_end, ph_end}</tt><br>
      at time <tt>t_change</tt> with a transition duration <tt>t_duration</tt>.<br><br>
      The transition function is a hyperbolic tangent for both norm and phase.</p>
      </html>
      "), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Text(extent = {{-100, 100}, {100, 60}}, lineColor = {175, 175, 175}, textString = "phasor"), Text(extent = {{-102, -10}, {18, -50}}, lineColor = {160, 160, 164}, textString = "start"), Text(extent = {{-10, 50}, {110, 10}}, lineColor = {160, 160, 164}, textString = "end"), Line(points = {{-80, -60}, {-64, -60}, {-44, -58}, {-34, -54}, {-26, -48}, {-20, -40}, {-14, -30}, {-8, -18}, {-2, -6}, {2, 4}, {8, 18}, {14, 30}, {20, 40}, {26, 48}, {34, 54}, {44, 58}, {64, 60}, {80, 60}}, color = {95, 0, 191})})); 
      end TransientPhasor;
      annotation(preferredView = "info", Documentation(info = "<html>
    </html>")); 
    end Signals;

    package Partials  "Partial models" 
      extends Modelica.Icons.BasesPackage;

      partial block MO  
        extends PowerSystems.Icons.Block0;
        Modelica.Blocks.Interfaces.RealOutput[n] y "output signal-vector" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
        parameter Integer n = 1 "dim of output signal-vector";
        annotation(Documentation(info = "<html>
      </html>")); 
      end MO;
      annotation(Documentation(info = "<html>
    </html>")); 
    end Partials;
    annotation(preferredView = "info", Documentation(info = "<html>
  <p><a href=\"modelica://PowerSystems.UsersGuide.Overview\">up users guide</a></p>
  </html>")); 
  end Blocks;

  package Common  "Common components" 
    extends Modelica.Icons.Package;

    package Thermal  "Thermal boundary and adaptors" 
      extends Modelica.Icons.VariantsPackage;

      model BdCondV  "Default (Neumann) boundary condition, vector port" 
        parameter Integer m(final min = 1) = 1 "dimension of heat port";
        extends Partials.BdCondBase;
        PowerSystems.Interfaces.ThermalV_p heat(final m = m) "vector heat port" annotation(Placement(transformation(origin = {0, -100}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
      equation
        heat.ports.T = fill(T_amb, heat.m);
        annotation(defaultComponentName = "bdCond", Documentation(info = "<html>
      <p>Deault thermal boundary condition for applications where the thermal output of heat-producing components is not needed.<br>
      Boundary has fixed temperature T = 0.</p>
      </html>
      
      ")); 
      end BdCondV;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        model BdCondBase  "Default (Neumann) boundary condition base" 
          parameter SI.Temperature T_amb = 300 "ambient temperature";
          annotation(defaultComponentName = "bdCond", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-100, 0}, {100, -40}}, lineColor = {0, 0, 0}, textString = "%name"), Rectangle(extent = {{-80, -50}, {80, -80}}, lineColor = {0, 0, 0}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Backward), Line(points = {{-80, -50}, {80, -50}}, color = {255, 255, 255})}), Documentation(info = "<html>
        <p>Deault thermal boundary condition for applications where the thermal output of heat-producing components is not needed.<br>
        Boundary has fixed temperature T = 0.</p>
        </html>
        
        ")); 
        end BdCondBase;
        annotation(Documentation(info = "<html>
      </html>
      ")); 
      end Partials;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Auxiliary thermal boundary-conditions, boundary-elements and adptors.</p>
    </html>")); 
    end Thermal;

    package Nominal  "Units and nominal values" 
      extends Modelica.Icons.BasesPackage;

      partial model Nominal  "Units and nominal values" 
        parameter Boolean puUnits = true "= true, if scaled with nom. values (pu), else scaled with 1 (SI)" annotation(Evaluate = true, Dialog(group = "Parameter Scaling"));
        parameter SI.Voltage V_nom(final min = 0) = 1 "nominal Voltage (= base for pu)" annotation(Evaluate = true, Dialog(enable = puUnits, group = "Nominal"));
        parameter SI.ApparentPower S_nom(final min = 0) = 1 "nominal Power (= base for pu)" annotation(Evaluate = true, Dialog(enable = puUnits, group = "Nominal"));
        annotation(Documentation(info = "<html>
      <p>'Nominal' values that are used to define 'base'-values in the case where input is in 'pu'-units</p>
      <p>The parameter 'units' allows choosing between SI ('Amp Volt') and pu ('per unit') for input-parameters of components and output-variables of meters.<br>
      The default setting is 'pu'.</p>
      <p>pu ('per unit'):</p>
      <pre>
        V_base = V_nom
        S_base = S_nom
        R_base = V_nom*V_nom/S_nom
        I_base = S_nom/V_nom
      </pre>
      <p>SI ('Amp Volt'):</p>
      <pre>
        V_base = 1
        S_base = 1
        R_base = 1
        I_base = 1
      </pre>
      <p>Note that the choice between SI and pu does <b>not</b> affect state- and connector variables.
      These remain <b>always</b> in SI-units. It only affects input of parameter values and output variables.</p>
      </html>
      ")); 
      end Nominal;

      partial model NominalAC  "Units and nominal values AC" 
        extends Nominal;
        parameter SI.Frequency f_nom = system.f_nom "nominal frequency" annotation(Evaluate = true, Dialog(group = "Nominal"), choices(choice = 50, choice = 60));
      protected
        outer PowerSystems.System system;
        annotation(Documentation(info = "<html>
      <p>Same as 'Nominal', but with additional parameter 'nominal frequency'.</p>
      </html>
      ")); 
      end NominalAC;

      record NominalDataVI  "Units and nominal data" 
        extends Modelica.Icons.Record;
        SI.Voltage V_nom(final min = 0) = 1 "nom Voltage" annotation(Evaluate = true, Dialog(group = "Nominal"));
        SI.Current I_nom(final min = 0) = 1 "nom Current" annotation(Evaluate = true, Dialog(group = "Nominal"));
        annotation(defaultComponentPrefixes = "parameter"); 
      end NominalDataVI;
      annotation(preferredView = "info", Documentation(info = "<html>
    </html>
    ")); 
    end Nominal;
    annotation(preferredView = "info", Documentation(info = "<html>
  <p><a href=\"modelica://PowerSystems.UsersGuide.Overview\">up users guide</a></p>
  </html>
  ")); 
  end Common;

  package Semiconductors  "Semiconductors" 
    extends Modelica.Icons.Package;

    package Ideal  "Custom models" 
      extends Modelica.Icons.VariantsPackage;

      record SCparameter  "Ideal semiconductor parameters" 
        extends Common.Nominal.NominalDataVI;
        parameter Real[2] eps(final min = {0, 0}, each final unit = "1") = {1e-4, 1e-4} "{resistance 'on', conductance 'off'}";
        parameter SI.Voltage Vf(final min = 0) = 0 "forward threshold-voltage" annotation(Evaluate = true);
        parameter SI.Heat Hsw_nom = 0 "switching loss at V_nom, I_nom (av on off)" annotation(Evaluate = true);
        parameter Real[:] cT_loss = fill(0, 0) "{cT1,cT2,...} T-coef thermal losses" annotation(Evaluate = true);
        parameter SI.Temperature T0_loss = 300 "reference T for cT_loss expansion" annotation(Dialog(enable = size(cT_loss, 1) > 0), Evaluate = true);
        annotation(Documentation(info = "<html>
      <p>The small parameters epsR and epsG are given in dimensionless units. This allows to work with deault values also in cases where the exact semiconductor data are missing. A resonable (approximate) value for <tt>Z_nom</tt> is needed for scaling.
      <pre>
        epsR = (dV/dI)/Z_nom at I_nom
        Z_nom = V_nom/I_nom
      </pre></p>
      <p>Thermal losses are proportional to the forward drop voltage V, which may depend on temperature.<br>
      The temperature dependence is given by
      <pre>  V(T) = Vf*(1 + cT[1]*(T - T0) + cT[2]*(T - T0)^2 + ...)</pre>
      where <tt>Vf</tt> denotes the parameter value. With input <tt>cT</tt> empty,  no temperature dependence of losses is calculated.</p>
      <p>The switching losses are approximated by
      <pre>  h = hSw_nom*v*i/S_nom,   S_nom = V_nom*I_nom</pre>
      where <tt>q</tt> denotes the dissipated heat per switching operation at nominal voltage and current, averaged over 'on' and 'off'.<br>
      A generalisation to powers of i and v is straightforward.</p>
      </html>")); 
      end SCparameter;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Ideal semiconductor models (default choice).</p>
    </html>
    ")); 
    end Ideal;
    annotation(preferredView = "info", Documentation(info = "<html>
  <p><a href=\"modelica://PowerSystems.UsersGuide.Overview\">up users guide</a></p>
  </html>
  ")); 
  end Semiconductors;

  package Interfaces  
    extends Modelica.Icons.InterfacesPackage;

    connector Terminal  "General power terminal" 
      replaceable package PhaseSystem = PhaseSystems.PartialPhaseSystem "Phase system" annotation(choicesAllMatching = true);
      PhaseSystem.Voltage[PhaseSystem.n] v "voltage vector";
      flow PhaseSystem.Current[PhaseSystem.n] i "current vector";
      PhaseSystem.ReferenceAngle[PhaseSystem.m] theta "optional vector of phase angles";
    end Terminal;

    connector TerminalDC  "Power terminal for pure DC models" 
      replaceable package PhaseSystem = PhaseSystems.PartialPhaseSystem "Phase system" annotation(choicesAllMatching = true);
      PhaseSystem.Voltage[PhaseSystem.n] v "voltage vector";
      flow PhaseSystem.Current[PhaseSystem.n] i "current vector";
    end TerminalDC;

    connector Electric_p  "Electric terminal ('positive')" 
      extends Modelica.Electrical.Analog.Interfaces.PositivePin;
      annotation(defaultComponentName = "term_p", Documentation(info = "<html>
    </html>
    ")); 
    end Electric_p;

    connector ThermalV_p  "Thermal vector heat port ('positive')" 
      parameter Integer m(final min = 1) = 1 "number of single heat-ports";
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[m] ports "vector of single heat ports";
      annotation(defaultComponentName = "heat_p", Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-120, 120}, {100, 60}}, lineColor = {176, 0, 0}, textString = "%name"), Polygon(points = {{-20, 0}, {40, -60}, {100, 0}, {40, 60}, {-20, 0}}, lineColor = {176, 0, 0}, fillColor = {176, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-10, 50}, {90, -50}}, lineColor = {235, 235, 235}, pattern = LinePattern.None, textString = "%m")}), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-120, 0}, {0, -120}, {120, 0}, {0, 120}, {-120, 0}}, lineColor = {176, 0, 0}, fillColor = {176, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 60}, {60, -60}}, lineColor = {255, 255, 255}, pattern = LinePattern.None, textString = "%m")}), Documentation(info = "<html>
    <p>Thermal connector with a vector of 'port's, positive.</p>
    </html>
    ")); 
    end ThermalV_p;

    connector ThermalV_n  "Thermal vector heat port ('negative')" 
      parameter Integer m(final min = 1) = 1 "number of single heat-ports";
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[m] ports "vector of single heat ports";
      annotation(defaultComponentName = "heat_n", Documentation(info = "<html>
    <p>Thermal connector with a vector of 'port's, negative.</p>
    </html>
    "), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-100, 120}, {120, 60}}, lineColor = {176, 0, 0}, textString = "%name"), Polygon(points = {{-100, 0}, {-40, -60}, {20, 0}, {-40, 60}, {-100, 0}}, lineColor = {176, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-90, 50}, {10, -50}}, lineColor = {176, 0, 0}, textString = "%m")}), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-120, 0}, {0, -120}, {120, 0}, {0, 120}, {-120, 0}}, lineColor = {176, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 60}, {60, -60}}, lineColor = {176, 0, 0}, textString = "%m")})); 
    end ThermalV_n;

    connector Frequency  "Weighted frequency" 
      flow SI.Time H "inertia constant";
      flow SI.Angle w_H "angular velocity, inertia-weighted";
      Real h "Dummy potential-variable to balance flow-variable H";
      Real w_h "Dummy potential-variable to balance flow-variable w_H";
      annotation(defaultComponentName = "frequency", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-80, 80}, {80, -80}}, lineColor = {120, 0, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 30}, {60, -30}}, lineColor = {120, 0, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, textString = "f")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Text(extent = {{-120, 120}, {120, 60}}, lineColor = {120, 0, 120}, textString = "%name"), Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {120, 0, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
    <p>System frequency reference.<br>
    Used in 'System' for sending/receiving weighted frequency-data.</p>
    <pre>
      H:        weight, i.e. inertia constant of machine (dimension time)
      H_omega:  weighted angular frequency H*omega
    </pre>
    </html>")); 
    end Frequency;
  end Interfaces;

  package Utilities  "Basic utilities" 
    extends Modelica.Icons.UtilitiesPackage;

    package Math  "Mathematical functions" 
      extends Modelica.Icons.Package;

      function taylor  "Taylor series" 
        extends Modelica.Icons.Function;
        input Real x "argument";
        input Real[:] c "coefficients";
        output Real y "sum(c[n]*x^n)";
      protected
        Real x_k;
      algorithm
        y := 1;
        x_k := 1;
        for k in 1:size(c, 1) loop
          x_k := x * x_k;
          y := y + c[k] * x_k;
        end for;
        annotation(Documentation(info = "<html>
      <p>Calculates the Taylor series
      <pre>  y = 1 + sum(c[k]*x^k)</pre></p>
      </html>")); 
      end taylor;
      annotation(preferredView = "info", Documentation(info = "<html>
    </html>
    ")); 
    end Math;

    package Precalculation  "Precalculation functions" 
      extends Modelica.Icons.Package;

      function baseV  "Base voltage" 
        extends Modelica.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input SI.Voltage V_nom "nom voltage";
        output SI.Voltage V_base "base voltage";
      algorithm
        if puUnits then
          V_base := V_nom;
        else
          V_base := 1;
        end if;
        annotation(Documentation(info = "<html>
      <p>Calculates base-voltage depending on the choice of units.</p>
      <p>\"pu\":
      <pre>
        V_base = V_nom
      </pre>
      \"SI\":
      <pre>
        V_base = 1
      </pre></p>
      </html>
      ")); 
      end baseV;

      function baseI  "Base current" 
        extends Modelica.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input SI.Voltage V_nom "nom voltage";
        input SI.ApparentPower S_nom "apparent power";
        output SI.Current I_base "base current";
      algorithm
        if puUnits then
          I_base := S_nom / V_nom;
        else
          I_base := 1;
        end if;
        annotation(Documentation(info = "<html>
      <p>Calculates base-current depending on the choice of units.</p>
      <p>\"pu\":
      <pre>
        I_base = S_nom/V_nom;
      </pre>
      \"SI\":
      <pre>
        I_base = 1;
      </pre></p>
      </html>
      ")); 
      end baseI;

      function baseRL  "Base resistance and inductance" 
        extends Modelica.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input SI.Voltage V_nom "nom voltage";
        input SI.ApparentPower S_nom "apparent power";
        input SI.AngularFrequency omega_nom "angular frequency";
        input Integer scale = 1 "scaling factor topology (Y:1, Delta:3)";
        output Real[2] RL_base "base {resistance, inductance}";
      algorithm
        if puUnits then
          RL_base := scale * (V_nom * V_nom / S_nom) * {1, 1 / omega_nom};
        else
          RL_base := scale * {1, 1 / omega_nom};
        end if;
        annotation(Documentation(info = "<html>
      <p>Calculates base-resistance and -inductance depending on the choice of units (fist component is R, second is L).</p>
      <p>\"pu\":
      <pre>
        RL_base = (V_nom*V_nom/S_nom)*{1, 1/omega_nom}
      </pre>
      \"SI\":
      <pre>
        RL_base = {1, 1/omega_nom} (converts reactance X to inductance L!)
      </pre></p>
      </html>
      ")); 
      end baseRL;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p>Functions needed for the determination of coefficient-matrices from a set of phenomenological input parameters.</p>
    <p><a href=\"modelica://PowerSystems.UsersGuide.Introduction.Precalculation\">up users guide</a></p>
    <p>The second part of this package has been written in honour of <b>I. M. Canay</b>, one of the important electrical engeneers of the 20th century. He understood, what he wrote, and his results were exact. The package is based on his ideas and formulated in full mathematical generality.</p>
    <p>Literature:
    <ul>
    <li>Canay, I. M.: Modelling of Alternating-Current Machines Having Multiple Rotor Circuits.<br>
    IEEE Transactions on Energy Conversion, Vol. 8, No. 2, June 1993.</li>
    <li>Canay, I. M.: Determination of the Model Parameters of Machines from the Reactance Operators x_d(p), x_q(p).<br>
    IEEE Transactions on Energy Conversion, Vol. 8, No. 2, June 1993.</li>
    </ul></p>
    </html>")); 
    end Precalculation;

    package Transforms  "Transform functions" 
      extends Modelica.Icons.Package;

      function park  "Park transform" 
        extends Modelica.Icons.Function;
        input SI.Angle theta "transformation angle";
        output Real[3, 3] P "Park transformation matrix";
      protected
        constant Real s13 = sqrt(1 / 3);
        constant Real s23 = sqrt(2 / 3);
        constant Real dph_b = 2 * Modelica.Constants.pi / 3;
        constant Real dph_c = 4 * Modelica.Constants.pi / 3;
        Real[3] c;
        Real[3] s;
      algorithm
        c := cos({theta, theta - dph_b, theta - dph_c});
        s := sin({theta, theta - dph_b, theta - dph_c});
        P := transpose([s23 * c, -s23 * s, {s13, s13, s13}]);
        annotation(Inline = true, derivative = PowerSystems.Utilities.Transforms.der_park, Documentation(info = "<html>
      <p>The function <tt>park</tt> calculates the matrix <tt>P</tt> that transforms abc variables into dq0 variables with arbitrary angular orientation <tt>theta</tt>.<br>
      <tt>P</tt> can be factorised into a constant, angle independent orthogonal matrix <tt>P0</tt> and an angle-dependent rotation <tt>R</tt></p>
      <pre>
        P(theta) = R'(theta)*P0
      </pre>
      <p>Using the definition</p>
      <pre>
        c_k = cos(theta - k*2*pi/3),  k=0,1,2 (phases a, b, c)
        s_k = sin(theta - k*2*pi/3),  k=0,1,2 (phases a, b, c)
      </pre>
      <p>it takes the form
      <pre>
                             [ c_0,  c_1, c_2]
        P(theta) = sqrt(2/3)*[-s_0, -s_1,-s_2]
                             [ w,    w,   w  ]
      </pre>
      with
      <pre>
                              [ 1,      -1/2,       -1/2]
        P0 = P(0) = sqrt(2/3)*[ 0, sqrt(3)/2, -sqrt(3)/2]
                              [ w,         w,          w]
      </pre>
      and
      <pre>
                   [c_0, -s_0, 0]
        R(theta) = [s_0,  c_0, 0]
                   [  0,  0,   1]
      </pre></p>
      <p><a href=\"modelica://PowerSystems.UsersGuide.Introduction.Transforms\">up users guide</a></p>
      </html>")); 
      end park;

      function der_park  "Derivative of Park transform" 
        extends Modelica.Icons.Function;
        input SI.Angle theta "transformation angle";
        input SI.AngularFrequency omega "d/dt theta";
        output Real[3, 3] der_P "d/dt park";
      protected
        constant Real s23 = sqrt(2 / 3);
        constant Real dph_b = 2 * Modelica.Constants.pi / 3;
        constant Real dph_c = 4 * Modelica.Constants.pi / 3;
        Real[3] c;
        Real[3] s;
        Real s23omega;
      algorithm
        s23omega := s23 * omega;
        c := cos({theta, theta - dph_b, theta - dph_c});
        s := sin({theta, theta - dph_b, theta - dph_c});
        der_P := transpose([-s23omega * s, -s23omega * c, {0, 0, 0}]);
        annotation(Inline = true, derivative(order = 2) = PowerSystems.Utilities.Transforms.der2_park, Documentation(info = "<html>
      <p>First derivative of function park(theta) with respect to time.</p>
      </html>")); 
      end der_park;

      function der2_park  "2nd derivative of Park transform" 
        extends Modelica.Icons.Function;
        input SI.Angle theta "transformation angle";
        input SI.AngularFrequency omega "d/dt theta";
        input SI.AngularAcceleration omega_dot "d/dt omega";
        output Real[3, 3] der2_P "d2/dt2 park";
      protected
        constant Real s23 = sqrt(2 / 3);
        constant Real dph_b = 2 * Modelica.Constants.pi / 3;
        constant Real dph_c = 4 * Modelica.Constants.pi / 3;
        Real[3] c;
        Real[3] s;
        Real s23omega_dot;
        Real s23omega2;
      algorithm
        s23omega_dot := s23 * omega_dot;
        s23omega2 := s23 * omega * omega;
        c := cos({theta, theta - dph_b, theta - dph_c});
        s := sin({theta, theta - dph_b, theta - dph_c});
        der2_P := transpose([(-s23omega_dot * s) - s23omega2 * c, (-s23omega_dot * c) + s23omega2 * s, {0, 0, 0}]);
        annotation(Inline = true, Documentation(info = "<html>
      <p>Second derivative of function park(theta) with respect to time.</p>
      </html>")); 
      end der2_park;

      function rotation_dq  "Rotation matrix dq" 
        extends Modelica.Icons.Function;
        input SI.Angle theta "rotation angle";
        output Real[2, 2] R_dq "rotation matrix";
      protected
        Real c;
        Real s;
      algorithm
        c := cos(theta);
        s := sin(theta);
        R_dq := [c, -s; s, c];
        annotation(Inline = true, derivative = PowerSystems.Utilities.Transforms.der_rotation_dq, Documentation(info = "<html>
      <p>The function <tt>rotation_dq</tt> calculates the matrix <tt>R_dq</tt> that is the restriction of <tt>R_dq0</tt> from dq0 to dq.</p>
      <p>The matrix <tt>R_dq0</tt> rotates dq0 variables around the o-axis in dq0-space with arbitrary angle <tt>theta</tt>.
      <p>It takes the form
      <pre>
                       [cos(theta), -sin(theta), 0]
        R_dq0(theta) = [sin(theta),  cos(theta), 0]
                       [  0,           0,        1]
      </pre>
      and has the real eigenvector
      <pre>  {0, 0, 1}</pre>
      in the dq0 reference-frame.</p>
      <p>Coefficient matrices of the form (symmetrical systems)
      <pre>
            [x, 0, 0 ]
        X = [0, x, 0 ]
            [0, 0, xo]
      </pre>
      are invariant under transformations R_dq0</p>
      <p>The connection between R_dq0 and R_abc is the following
      <pre>  R_dq0 = P0*R_abc*P0'.</pre>
      with P0 the orthogonal transform 'Transforms.P0'.</p>
      <p><a href=\"modelica://PowerSystems.UsersGuide.Introduction.Transforms\">up users guide</a></p>
      </html>
      ")); 
      end rotation_dq;

      function der_rotation_dq  "Derivative of rotation matrix dq" 
        extends Modelica.Icons.Function;
        input SI.Angle theta;
        input SI.AngularFrequency omega "d/dt theta";
        output Real[2, 2] der_R_dq "d/dt rotation_dq";
      protected
        Real dc;
        Real ds;
      algorithm
        dc := -omega * sin(theta);
        ds := omega * cos(theta);
        der_R_dq := [dc, -ds; ds, dc];
        annotation(Inline = true, derivative(order = 2) = PowerSystems.Utilities.Transforms.der2_rotation_dq, Documentation(info = "<html>
      <p>First derivative of function rotation_dq(theta) with respect to time.</p>
      </html>")); 
      end der_rotation_dq;

      function der2_rotation_dq  "2nd derivative of rotation matrix dq" 
        extends Modelica.Icons.Function;
        input SI.Angle theta;
        input SI.AngularFrequency omega "d/dt theta";
        input SI.AngularAcceleration omega_dot "d/dt omega";
        output Real[2, 2] der2_R_dq "d/2dt2 rotation_dq";
      protected
        Real c;
        Real s;
        Real d2c;
        Real d2s;
        Real omega2 = omega * omega;
      algorithm
        c := cos(theta);
        s := sin(theta);
        d2c := (-omega_dot * s) - omega2 * c;
        d2s := omega_dot * c - omega2 * s;
        der2_R_dq := [d2c, -d2s; d2s, d2c];
        annotation(Inline = true, Documentation(info = "<html>
      <p>Second derivative of function rotation_dq(theta) with respect to time.</p>
      </html>")); 
      end der2_rotation_dq;
      annotation(preferredView = "info", Documentation(info = "<html>
    <p><a href=\"modelica://PowerSystems.UsersGuide.Introduction.Transforms\">up users guide</a></p>
    </html>
    ")); 
    end Transforms;
  end Utilities;

  package Types  
    extends Modelica.Icons.TypesPackage;

    package SI  "SI types with custom attributes, like display units" 
      extends Modelica.Icons.Package;
      import MSI = Modelica.SIunits;
      type Time = MSI.Time;
      type Frequency = MSI.Frequency;
      type Angle = MSI.Angle;
      type AngularVelocity = MSI.AngularVelocity(displayUnit = "rpm");
      type AngularAcceleration = MSI.AngularAcceleration;
      type AngularFrequency = MSI.AngularFrequency;
      type Voltage = MSI.Voltage(displayUnit = "kV");
      type Current = MSI.Current;
      type Resistance = MSI.Resistance;
      type Conductance = MSI.Conductance;
      type Inductance = MSI.Inductance;
      type Power = MSI.Power(displayUnit = "MW");
      type ApparentPower = MSI.ApparentPower(displayUnit = "MVA");
      type Temperature = MSI.Temperature;
      type Heat = MSI.Heat;
      type HeatFlowRate = MSI.HeatFlowRate;
      annotation(Documentation(info = "<html>
    </html>
    ")); 
    end SI;

    package SIpu  "Additional types for power systems" 
      extends Modelica.Icons.Package;
      type Voltage = Real(final quantity = "ElectricPotential", unit = "V/V");
      type Current = Real(final quantity = "ElectricCurrent", unit = "A/A");
      type Power = Real(final quantity = "Power", unit = "W/W");
      type Resistance = Real(final quantity = "Resistance", unit = "Ohm/(V.V/VA)", final min = 0);
      type Reactance = Real(final quantity = "Reactance", unit = "Ohm/Ohm");
      annotation(Documentation(info = "<html>
    </html>
    ")); 
    end SIpu;

    type SourceFrequency = enumeration(Parameter "Parameter f", Signal "Signal omega_in", System "System defined") "Options for specification of frequency" annotation(Documentation(info = "<html>
    <p><pre>
      Parameter: parameter f
      Signal:    signal input omega_in
      System:    system defined frequency
    </pre></p>
    </html>"));
    type SystemFrequency = enumeration(Parameter "Parameter f", Signal "Signal omega_in", Average "Average generators") "Options for specification of frequency in system object" annotation(Documentation(info = "<html>
    <p><pre>
      Parameter: parameter f
      Signal:    signal input omega_in
      Average:   average frequency over involved generators
    </pre></p>
    </html>"));
    type ReferenceFrame = enumeration(Synchron "Synchronously rotating", Inertial "Inertial (signals oscillate)") "Options for specification of reference frame" annotation(Documentation(info = "<html>
    <p><pre>
      Synchron: synchronously rotating (stationary signals are constant)
      Inertial: inertial (stationary signals are oscillating)
    </pre></p>
    </html>"));
    type Dynamics = enumeration(FreeInitial "Free initial conditions", FixedInitial "Fixed initial conditions", SteadyInitial "Steady-state initial conditions", SteadyState "Steady-state (quasi-stationary)") "Options for specification of simulation" annotation(Documentation(info = "<html>
    <p><pre>
      FreeInitial:     Transient simulation with free initial conditions
      FixedInitial:    Transient simulation with fixed initial conditions
      SteadyInitial:   Transient simulation with steady-state initial conditions
      SteadyState:     Quasi-stationary simulation using steady-state model
    </pre></p>
    </html>"));

    type ReferenceAngle  "Reference angle" 
      extends SI.Angle;

      function equalityConstraint  
        input ReferenceAngle[:] theta1;
        input ReferenceAngle[:] theta2;
        output Real[0] residue "No constraints";
      algorithm
        for i in 1:size(theta1, 1) loop
          assert(abs(theta1[i] - theta2[i]) < Modelica.Constants.eps, "angles theta1 and theta2 not equal over connection!");
        end for;
      end equalityConstraint;
      annotation(Documentation(info = "<html>
    <p>Type ReferenceAngle specifies the variable-type that contains relative frequency and angular orientation of a rotating electrical reference system.
    In the case of three phase AC models we have:</p>
    <pre>
      theta[1]       angle relative to reference-system
      theta[2]       reference angle, defining reference-system
    
      der(theta[1])  relative frequency in reference-system with orientation theta[2]
      der(theta[1] + theta[2])  absolute frequency
    </pre>
    </html>")); 
    end ReferenceAngle;
  end Types;

  package Icons  "Icons" 
    extends Modelica.Icons.IconsPackage;

    partial block Block  "Block icon"  annotation(Documentation(info = "
    "), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Rectangle(extent = {{-80, 60}, {80, -60}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)})); end Block;

    partial block Block0  "Block icon 0" 
      extends Block;
      annotation(Documentation(info = "
    "), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Text(extent = {{-100, -80}, {100, -120}}, lineColor = {0, 0, 0}, textString = "%name")})); 
    end Block0;

    partial model Inverter_dq0  "Inverter icon"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Rectangle(extent = {{-80, 60}, {80, -60}}, lineColor = {0, 120, 120}, lineThickness = 0.5, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-80, -60}, {80, 60}}, color = {0, 120, 120}), Text(extent = {{10, 20}, {70, -10}}, lineColor = {0, 120, 120}, lineThickness = 0.5, textString = "~"), Text(extent = {{10, 0}, {70, -30}}, lineColor = {0, 120, 120}, lineThickness = 0.5, textString = "~"), Line(points = {{24, 0}, {56, 0}}, color = {0, 120, 120}), Line(points = {{24, -20}, {56, -20}}, color = {0, 120, 120}), Line(points = {{24, -40}, {56, -40}}, color = {0, 120, 120}), Text(extent = {{-100, -90}, {100, -130}}, lineColor = {0, 0, 0}, textString = "%name"), Text(extent = {{-80, 40}, {0, 0}}, textString = "=")}), Documentation(info = "")); end Inverter_dq0;
    annotation(preferredView = "info", Documentation(info = "<html>
  </html>
  ")); 
  end Icons;
  annotation(preferredView = "info", version = "0.6.0", versionDate = "2017-01-18", Documentation(info = "<html>
<p>The Modelica PowerSystems library is intended for the modeling of electrical <b>power systems</b> at different <b>levels of detail</b> both in <b>transient</b> and <b>steady-state</b> mode.</p>
<p>The Users Guide to the library is <a href=\"modelica://PowerSystems.UsersGuide\"><b>here</b></a>.</p>
<p><br/>Copyright &copy; 2007-2017, Modelica Association. </p>
<p>Copyright &copy; 2004-2008, H.J. Wiesmann (&dagger; 2015).</p>
<p><i>This Modelica package is <b>Open Source</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license, version 2.0, see the license conditions and
the accompanying disclaimer <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a>.</b></i> </p>
<p><i>This work was in parts supported by the ITEA2 MODRIO project by funding of BMBF under contract
number ITEA 2 - 11004. Work on the predecessor PowerFlow library was in parts supported by
the ITEA2 EUROSYSLIB project by funding of BMBF under contract number ITEA 2 - 06020.
Work on the predecessor Spot library was in parts supported by the RealSim project
by funding of the IST Programme, Contract No. IST-1999-11979. </i></p>
<p/>
</html>
"), uses(Modelica(version = "3.2.2")), Icon(graphics = {Line(points = {{-60, -16}, {38, -16}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{-60, -16}, {-60, -42}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{38, -16}, {38, -42}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{-10, 10}, {-10, -16}}, color = {0, 0, 0}, smooth = Smooth.None), Ellipse(extent = {{-20, 30}, {0, 10}}, lineColor = {0, 0, 0}), Ellipse(extent = {{-20, 42}, {0, 22}}, lineColor = {0, 0, 0}), Ellipse(extent = {{-70, -42}, {-50, -62}}, lineColor = {0, 0, 0}), Ellipse(extent = {{28, -42}, {48, -62}}, lineColor = {0, 0, 0}), Line(points = {{-10, 52}, {-10, 42}}, color = {0, 0, 0}, smooth = Smooth.None)})); 
end PowerSystems;

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation" 
  extends Modelica.Icons.Package;

  package ExternalReferences  "Library of functions to access external resources" 
    extends Modelica.Icons.Package;

    function loadResource  "Return the absolute path name of a URI or local file name (in this default implementation URIs are not supported, but only local file names)" 
      extends Modelica.Utilities.Internal.PartialModelicaServices.ExternalReferences.PartialLoadResource;
    algorithm
      fileReference := OpenModelica.Scripting.uriToFilename(uri);
      annotation(Documentation(info = "<html>
    <p>
    The interface of this model is documented at
    <a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>.
    </p>
    </html>")); 
    end loadResource;
  end ExternalReferences;

  package Machine  
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1.e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1.e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    annotation(Documentation(info = "<html>
  <p>
  Package in which processor specific constants are defined that are needed
  by numerical algorithms. Typically these constants are not directly used,
  but indirectly via the alias definition in
  <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
  </p>
  </html>")); 
  end Machine;
  annotation(Protection(access = Access.hide), preferredView = "info", version = "3.2.2", versionBuild = 0, versionDate = "2016-01-15", dateModified = "2016-01-15 08:44:41Z", revisionId = "$Id::                                       $", uses(Modelica(version = "3.2.2")), conversion(noneFromVersion = "1.0", noneFromVersion = "1.1", noneFromVersion = "1.2", noneFromVersion = "3.2.1"), Documentation(info = "<html>
<p>
This package contains a set of functions and models to be used in the
Modelica Standard Library that requires a tool specific implementation.
These are:
</p>

<ul>
<li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Shape</a>
     provides a 3-dim. visualization of elementary
     mechanical objects. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Surface</a>
     provides a 3-dim. visualization of
     moveable parameterized surface. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">loadResource</a>
     provides a function to return the absolute path name of an URI or a local file name. It is used in
<a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Machine\">ModelicaServices.Machine</a>
     provides a package of machine constants. It is used in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

<li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
     provides a string defining the integration method to solve differential equations in
     a clocked discretized continuous-time partition (see Modelica 3.3 language specification).
     It is not yet used in the Modelica Standard Library, but in the Modelica_Synchronous library
     that provides convenience blocks for the clock operators of Modelica version &ge; 3.3.</li>
</ul>

<p>
This is the default implementation, if no tool-specific implementation is available.
This ModelicaServices package provides only \"dummy\" models that do nothing.
</p>

<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 2009-2016, DLR and Dassault Syst&egrave;mes AB.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

</html>")); 
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.2" 
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)" 
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks" 
      import Modelica.SIunits;
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector" annotation(defaultComponentName = "u", Icon(graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}, coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}, preserveAspectRatio = true, initialScale = 0.2)), Diagram(coordinateSystem(preserveAspectRatio = true, initialScale = 0.2, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid, points = {{0.0, 50.0}, {100.0, 0.0}, {0.0, -50.0}, {0.0, 50.0}}), Text(lineColor = {0, 0, 127}, extent = {{-10.0, 60.0}, {-10.0, 85.0}}, textString = "%name")}), Documentation(info = "<html>
      <p>
      Connector with one input signal of type Real.
      </p>
      </html>"));
      connector RealOutput = output Real "'output Real' as connector" annotation(defaultComponentName = "y", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 50.0}, {0.0, 0.0}, {-100.0, -50.0}}), Text(lineColor = {0, 0, 127}, extent = {{30.0, 60.0}, {30.0, 110.0}}, textString = "%name")}), Documentation(info = "<html>
      <p>
      Connector with one output signal of type Real.
      </p>
      </html>"));
      annotation(Documentation(info = "<html>
    <p>
    This package contains interface definitions for
    <b>continuous</b> input/output blocks with Real,
    Integer and Boolean signals. Furthermore, it contains
    partial models for continuous and discrete blocks.
    </p>

    </html>", revisions = "<html>
    <ul>
    <li><i>Oct. 21, 2002</i>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
           and Christian Schweiger:<br>
           Added several new interfaces.</li>
    <li><i>Oct. 24, 1999</i>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           RealInputSignal renamed to RealInput. RealOutputSignal renamed to
           output RealOutput. GraphBlock renamed to BlockIcon. SISOreal renamed to
           SISO. SOreal renamed to SO. I2SOreal renamed to M2SO.
           SignalGenerator renamed to SignalSource. Introduced the following
           new models: MIMO, MIMOs, SVcontrol, MVcontrol, DiscreteBlockIcon,
           DiscreteBlock, DiscreteSISO, DiscreteMIMO, DiscreteMIMOs,
           BooleanBlockIcon, BooleanSISO, BooleanSignalSource, MI2BooleanMOs.</li>
    <li><i>June 30, 1999</i>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           Realized a first version, based on an existing Dymola library
           of Dieter Moormann and Hilding Elmqvist.</li>
    </ul>
    </html>")); 
    end Interfaces;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Rectangle(origin = {0.0, 35.1488}, fillColor = {255, 255, 255}, extent = {{-30.0, -20.1488}, {30.0, 20.1488}}), Rectangle(origin = {0.0, -34.8512}, fillColor = {255, 255, 255}, extent = {{-30.0, -20.1488}, {30.0, 20.1488}}), Line(origin = {-51.25, 0.0}, points = {{21.25, -35.0}, {-13.75, -35.0}, {-13.75, 35.0}, {6.25, 35.0}}), Polygon(origin = {-40.0, 35.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{10.0, 0.0}, {-5.0, 5.0}, {-5.0, -5.0}}), Line(origin = {51.25, 0.0}, points = {{-21.25, 35.0}, {13.75, 35.0}, {13.75, -35.0}, {-6.25, -35.0}}), Polygon(origin = {40.0, -35.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.0, 0.0}, {5.0, 5.0}, {5.0, -5.0}})}), Documentation(info = "<html>
  <p>
  This library contains input/output blocks to build up block diagrams.
  </p>

  <dl>
  <dt><b>Main Author:</b></dt>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
      Oberpfaffenhofen<br>
      Postfach 1116<br>
      D-82230 Wessling<br>
      email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br></dd>
  </dl>
  <p>
  Copyright &copy; 1998-2016, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>June 23, 2004</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Introduced new block connectors and adapted all blocks to the new connectors.
         Included subpackages Continuous, Discrete, Logical, Nonlinear from
         package ModelicaAdditions.Blocks.
         Included subpackage ModelicaAdditions.Table in Modelica.Blocks.Sources
         and in the new package Modelica.Blocks.Tables.
         Added new blocks to Blocks.Sources and Blocks.Logical.
         </li>
  <li><i>October 21, 2002</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
         and Christian Schweiger:<br>
         New subpackage Examples, additional components.
         </li>
  <li><i>June 20, 2000</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
         Michael Tiller:<br>
         Introduced a replaceable signal type into
         Blocks.Interfaces.RealInput/RealOutput:
  <pre>
     replaceable type SignalType = Real
  </pre>
         in order that the type of the signal of an input/output block
         can be changed to a physical type, for example:
  <pre>
     Sine sin1(outPort(redeclare type SignalType=Modelica.SIunits.Torque))
  </pre>
        </li>
  <li><i>Sept. 18, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Renamed to Blocks. New subpackages Math, Nonlinear.
         Additional components in subpackages Interfaces, Continuous
         and Sources. </li>
  <li><i>June 30, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized a first version, based on an existing Dymola library
         of Dieter Moormann and Hilding Elmqvist.</li>
  </ul>
  </html>")); 
  end Blocks;

  package Electrical  "Library of electrical models (analog, digital, machines, multi-phase)" 
    extends Modelica.Icons.Package;

    package Analog  "Library for analog electrical models" 
      import SI = Modelica.SIunits;
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models for Analog electrical components" 
        extends Modelica.Icons.InterfacesPackage;

        connector PositivePin  "Positive pin of an electric component" 
          SI.Voltage v "Potential at the pin" annotation(unassignedMessage = "An electrical potential cannot be uniquely calculated.
        The reason could be that
        - a ground object is missing (Modelica.Electrical.Analog.Basic.Ground)
          to define the zero potential of the electrical circuit, or
        - a connector of an electrical component is not connected.");
          flow SI.Current i "Current flowing into the pin" annotation(unassignedMessage = "An electrical current cannot be uniquely calculated.
        The reason could be that
        - a ground object is missing (Modelica.Electrical.Analog.Basic.Ground)
          to define the zero potential of the electrical circuit, or
        - a connector of an electrical component is not connected.");
          annotation(defaultComponentName = "pin_p", Documentation(info = "<html>
        <p>Connectors PositivePin and NegativePin are nearly identical. The only difference is that the icons are different in order to identify more easily the pins of a component. Usually, connector PositivePin is used for the positive and connector NegativePin for the negative pin of an electrical component.</p>
        </html>", revisions = "<html>
        <ul>
        <li><i> 1998   </i>
               by Christoph Clauss<br> initially implemented<br>
               </li>
        </ul>
        </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-160, 110}, {40, 50}}, lineColor = {0, 0, 255}, textString = "%name")})); 
        end PositivePin;
        annotation(Documentation(info = "<html>
      <p>This package contains connectors and interfaces (partial models) for analog electrical components. The partial models contain typical combinations of pins, and internal variables which are often used. Furthermore, the thermal heat port is in this package which can be included by inheritance.</p>
      </html>", revisions = "<html>
      <dl>
      <dt>
      <b>Main Authors:</b>
      </dt>
      <dd>
      Christoph Clau&szlig;
          &lt;<a href=\"mailto:Christoph.Clauss@eas.iis.fraunhofer.de\">Christoph.Clauss@eas.iis.fraunhofer.de</a>&gt;<br>
          Andr&eacute; Schneider
          &lt;<a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>&gt;<br>
          Fraunhofer Institute for Integrated Circuits<br>
          Design Automation Department<br>
          Zeunerstra&szlig;e 38<br>
          D-01069 Dresden
      </dd>
      <dt>
      <b>Copyright:</b>
      </dt>
      <dd>
      Copyright &copy; 1998-2016, Modelica Association and Fraunhofer-Gesellschaft.<br>
      <i>The Modelica package is <b>free</b> software; it can be redistributed and/or modified
      under the terms of the <b>Modelica license</b>, see the license conditions
      and the accompanying <b>disclaimer</b> in the documentation of package
      Modelica in file \"Modelica/package.mo\".</i>
      </dd>
      </dl>

      <ul>
      <li><i> 1998</i>
             by Christoph Clauss<br> initially implemented<br>
             </li>
      </ul>
      </html>")); 
      end Interfaces;
      annotation(Documentation(info = "<html>
    <p>
    This package contains packages for analog electrical components:</p>
    <ul>
    <li>Basic: basic components (resistor, capacitor, conductor, inductor, transformer, gyrator)</li>
    <li>Semiconductors: semiconductor devices (diode, bipolar and MOS transistors)</li>
    <li>Lines: transmission lines (lossy and lossless)</li>
    <li>Ideal: ideal elements (switches, diode, transformer, idle, short, ...)</li>
    <li>Sources: time-dependent and controlled voltage and current sources</li>
    <li>Sensors: sensors to measure potential, voltage, and current</li>
    </ul>
    <dl>
    <dt>
    <b>Main Authors:</b>
    </dt>
    <dd>
    Christoph Clau&szlig;
        &lt;<a href=\"mailto:Christoph.Clauss@eas.iis.fraunhofer.de\">Christoph.Clauss@eas.iis.fraunhofer.de</a>&gt;<br>
        Andr&eacute; Schneider
        &lt;<a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>&gt;<br>
        Fraunhofer Institute for Integrated Circuits<br>
        Design Automation Department<br>
        Zeunerstra&szlig;e 38<br>
        D-01069 Dresden, Germany
    </dd>
    </dl>
    </html>"), Icon(graphics = {Line(points = {{12, 60}, {12, -60}}), Line(points = {{-12, 60}, {-12, -60}}), Line(points = {{-80, 0}, {-12, 0}}), Line(points = {{12, 0}, {80, 0}})})); 
    end Analog;
    annotation(Documentation(info = "<html>
  <p>
  This library contains electrical components to build up analog and digital circuits,
  as well as machines to model electrical motors and generators,
  especially three phase induction machines such as an asynchronous motor.
  </p>

  </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Rectangle(origin = {20.3125, 82.8571}, extent = {{-45.3125, -57.8571}, {4.6875, -27.8571}}), Line(origin = {8.0, 48.0}, points = {{32.0, -58.0}, {72.0, -58.0}}), Line(origin = {9.0, 54.0}, points = {{31.0, -49.0}, {71.0, -49.0}}), Line(origin = {-2.0, 55.0}, points = {{-83.0, -50.0}, {-33.0, -50.0}}), Line(origin = {-3.0, 45.0}, points = {{-72.0, -55.0}, {-42.0, -55.0}}), Line(origin = {1.0, 50.0}, points = {{-61.0, -45.0}, {-61.0, -10.0}, {-26.0, -10.0}}), Line(origin = {7.0, 50.0}, points = {{18.0, -10.0}, {53.0, -10.0}, {53.0, -45.0}}), Line(origin = {6.2593, 48.0}, points = {{53.7407, -58.0}, {53.7407, -93.0}, {-66.2593, -93.0}, {-66.2593, -58.0}})})); 
  end Electrical;

  package Thermal  "Library of thermal system components to model heat transfer and simple thermo-fluid pipe flow" 
    extends Modelica.Icons.Package;

    package HeatTransfer  "Library of 1-dimensional heat transfer with lumped elements" 
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models" 
        extends Modelica.Icons.InterfacesPackage;

        partial connector HeatPort  "Thermal port for 1-dim. heat transfer" 
          Modelica.SIunits.Temperature T "Port temperature";
          flow Modelica.SIunits.HeatFlowRate Q_flow "Heat flow rate (positive if flowing from outside into the component)";
          annotation(Documentation(info = "<html>

        </html>")); 
        end HeatPort;

        connector HeatPort_a  "Thermal port for 1-dim. heat transfer (filled rectangular icon)" 
          extends HeatPort;
          annotation(defaultComponentName = "port_a", Documentation(info = "<html>
        <p>This connector is used for 1-dimensional heat flow between components.
        The variables in the connector are:</p>
        <pre>
           T       Temperature in [Kelvin].
           Q_flow  Heat flow rate in [Watt].
        </pre>
        <p>According to the Modelica sign convention, a <b>positive</b> heat flow
        rate <b>Q_flow</b> is considered to flow <b>into</b> a component. This
        convention has to be used whenever this connector is used in a model
        class.</p>
        <p>Note, that the two connector classes <b>HeatPort_a</b> and
        <b>HeatPort_b</b> are identical with the only exception of the different
        <b>icon layout</b>.</p></html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-50, 50}, {50, -50}}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-120, 120}, {100, 60}}, lineColor = {191, 0, 0}, textString = "%name")})); 
        end HeatPort_a;

        connector HeatPort_b  "Thermal port for 1-dim. heat transfer (unfilled rectangular icon)" 
          extends HeatPort;
          annotation(defaultComponentName = "port_b", Documentation(info = "<html>
        <p>This connector is used for 1-dimensional heat flow between components.
        The variables in the connector are:</p>
        <pre>
           T       Temperature in [Kelvin].
           Q_flow  Heat flow rate in [Watt].
        </pre>
        <p>According to the Modelica sign convention, a <b>positive</b> heat flow
        rate <b>Q_flow</b> is considered to flow <b>into</b> a component. This
        convention has to be used whenever this connector is used in a model
        class.</p>
        <p>Note, that the two connector classes <b>HeatPort_a</b> and
        <b>HeatPort_b</b> are identical with the only exception of the different
        <b>icon layout</b>.</p></html>"), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-50, 50}, {50, -50}}, lineColor = {191, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-100, 120}, {120, 60}}, lineColor = {191, 0, 0}, textString = "%name")}), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {191, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)})); 
        end HeatPort_b;
        annotation(Documentation(info = "<html>

      </html>")); 
      end Interfaces;
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {13.758, 27.517}, lineColor = {128, 128, 128}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{-54, -6}, {-61, -7}, {-75, -15}, {-79, -24}, {-80, -34}, {-78, -42}, {-73, -49}, {-64, -51}, {-57, -51}, {-47, -50}, {-41, -43}, {-38, -35}, {-40, -27}, {-40, -20}, {-42, -13}, {-47, -7}, {-54, -5}, {-54, -6}}), Polygon(origin = {13.758, 27.517}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{-75, -15}, {-79, -25}, {-80, -34}, {-78, -42}, {-72, -49}, {-64, -51}, {-57, -51}, {-47, -50}, {-57, -47}, {-65, -45}, {-71, -40}, {-74, -33}, {-76, -23}, {-75, -15}, {-75, -15}}), Polygon(origin = {13.758, 27.517}, lineColor = {160, 160, 164}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{39, -6}, {32, -7}, {18, -15}, {14, -24}, {13, -34}, {15, -42}, {20, -49}, {29, -51}, {36, -51}, {46, -50}, {52, -43}, {55, -35}, {53, -27}, {53, -20}, {51, -13}, {46, -7}, {39, -5}, {39, -6}}), Polygon(origin = {13.758, 27.517}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{18, -15}, {14, -25}, {13, -34}, {15, -42}, {21, -49}, {29, -51}, {36, -51}, {46, -50}, {36, -47}, {28, -45}, {22, -40}, {19, -33}, {17, -23}, {18, -15}, {18, -15}}), Polygon(origin = {13.758, 27.517}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid, points = {{-9, -23}, {-9, -10}, {18, -17}, {-9, -23}}), Line(origin = {13.758, 27.517}, points = {{-41, -17}, {-9, -17}}, color = {191, 0, 0}, thickness = 0.5), Line(origin = {13.758, 27.517}, points = {{-17, -40}, {15, -40}}, color = {191, 0, 0}, thickness = 0.5), Polygon(origin = {13.758, 27.517}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid, points = {{-17, -46}, {-17, -34}, {-40, -40}, {-17, -46}})}), Documentation(info = "<html>
    <p>
    This package contains components to model <b>1-dimensional heat transfer</b>
    with lumped elements. This allows especially to model heat transfer in
    machines provided the parameters of the lumped elements, such as
    the heat capacity of a part, can be determined by measurements
    (due to the complex geometries and many materials used in machines,
    calculating the lumped element parameters from some basic analytic
    formulas is usually not possible).
    </p>
    <p>
    Example models how to use this library are given in subpackage <b>Examples</b>.<br>
    For a first simple example, see <b>Examples.TwoMasses</b> where two masses
    with different initial temperatures are getting in contact to each
    other and arriving after some time at a common temperature.<br>
    <b>Examples.ControlledTemperature</b> shows how to hold a temperature
    within desired limits by switching on and off an electric resistor.<br>
    A more realistic example is provided in <b>Examples.Motor</b> where the
    heating of an electrical motor is modelled, see the following screen shot
    of this example:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Thermal/HeatTransfer/driveWithHeatTransfer.png\" ALT=\"driveWithHeatTransfer\">
    </p>

    <p>
    The <b>filled</b> and <b>non-filled red squares</b> at the left and
    right side of a component represent <b>thermal ports</b> (connector HeatPort).
    Drawing a line between such squares means that they are thermally connected.
    The variables of a HeatPort connector are the temperature <b>T</b> at the port
    and the heat flow rate <b>Q_flow</b> flowing into the component (if Q_flow is positive,
    the heat flows into the element, otherwise it flows out of the element):
    </p>
    <pre>   Modelica.SIunits.Temperature  T  \"absolute temperature at port in Kelvin\";
       Modelica.SIunits.HeatFlowRate Q_flow  \"flow rate at the port in Watt\";
    </pre>
    <p>
    Note, that all temperatures of this package, including initial conditions,
    are given in Kelvin. For convenience, in subpackages <b>HeatTransfer.Celsius</b>,
     <b>HeatTransfer.Fahrenheit</b> and <b>HeatTransfer.Rankine</b> components are provided such that source and
    sensor information is available in degree Celsius, degree Fahrenheit, or degree Rankine,
    respectively. Additionally, in package <b>SIunits.Conversions</b> conversion
    functions between the units Kelvin and Celsius, Fahrenheit, Rankine are
    provided. These functions may be used in the following way:
    </p>
    <pre>  <b>import</b> SI=Modelica.SIunits;
      <b>import</b> Modelica.SIunits.Conversions.*;
         ...
      <b>parameter</b> SI.Temperature T = from_degC(25);  // convert 25 degree Celsius to Kelvin
    </pre>

    <p>
    There are several other components available, such as AxialConduction (discretized PDE in
    axial direction), which have been temporarily removed from this library. The reason is that
    these components reference material properties, such as thermal conductivity, and currently
    the Modelica design group is discussing a general scheme to describe material properties.
    </p>
    <p>
    For technical details in the design of this library, see the following reference:<br>
    <b>Michael Tiller (2001)</b>: <a href=\"http://www.amazon.de\">
    Introduction to Physical Modeling with Modelica</a>.
    Kluwer Academic Publishers Boston.
    </p>
    <p>
    <b>Acknowledgements:</b><br>
    Several helpful remarks from the following persons are acknowledged:
    John Batteh, Ford Motors, Dearborn, U.S.A;
    <a href=\"http://www.haumer.at/\">Anton Haumer</a>, Technical Consulting &amp; Electrical Engineering, Austria;
    Ludwig Marvan, VA TECH ELIN EBG Elektronik GmbH, Wien, Austria;
    Hans Olsson, Dassault Syst&egrave;mes AB, Sweden;
    Hubertus Tummescheit, Lund Institute of Technology, Lund, Sweden.
    </p>
    <dl>
      <dt><b>Main Authors:</b></dt>
      <dd>
      <p>
      <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
      Technical Consulting &amp; Electrical Engineering<br>
      A-3423 St.Andrae-Woerdern, Austria<br>
      email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
    </p>
      </dd>
    </dl>
    <p><b>Copyright &copy; 2001-2016, Modelica Association, Michael Tiller and DLR.</b></p>

    <p>
    <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
    </p>
    </html>", revisions = "<html>
    <ul>
    <li><i>July 15, 2002</i>
           by Michael Tiller, <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
           and Nikolaus Sch&uuml;rmann:<br>
           Implemented.
    </li>
    <li><i>June 13, 2005</i>
           by <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
           Refined placing of connectors (cosmetic).<br>
           Refined all Examples; removed Examples.FrequencyInverter, introducing Examples.Motor<br>
           Introduced temperature dependent correction (1 + alpha*(T - T_ref)) in Fixed/PrescribedHeatFlow<br>
    </li>
      <li> v1.1.1 2007/11/13 Anton Haumer<br>
           components moved to sub-packages</li>
      <li> v1.2.0 2009/08/26 Anton Haumer<br>
           added component ThermalCollector</li>

    </ul>
    </html>")); 
    end HeatTransfer;
    annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Line(origin = {-47.5, 11.6667}, points = {{-2.5, -91.6667}, {17.5, -71.6667}, {-22.5, -51.6667}, {17.5, -31.6667}, {-22.5, -11.667}, {17.5, 8.3333}, {-2.5, 28.3333}, {-2.5, 48.3333}}, smooth = Smooth.Bezier), Polygon(origin = {-50.0, 68.333}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{0.0, 21.667}, {-10.0, -8.333}, {10.0, -8.333}}), Line(origin = {2.5, 11.6667}, points = {{-2.5, -91.6667}, {17.5, -71.6667}, {-22.5, -51.6667}, {17.5, -31.6667}, {-22.5, -11.667}, {17.5, 8.3333}, {-2.5, 28.3333}, {-2.5, 48.3333}}, smooth = Smooth.Bezier), Polygon(origin = {0.0, 68.333}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{0.0, 21.667}, {-10.0, -8.333}, {10.0, -8.333}}), Line(origin = {52.5, 11.6667}, points = {{-2.5, -91.6667}, {17.5, -71.6667}, {-22.5, -51.6667}, {17.5, -31.6667}, {-22.5, -11.667}, {17.5, 8.3333}, {-2.5, 28.3333}, {-2.5, 48.3333}}, smooth = Smooth.Bezier), Polygon(origin = {50.0, 68.333}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{0.0, 21.667}, {-10.0, -8.333}, {10.0, -8.333}})}), Documentation(info = "<html>
  <p>
  This package contains libraries to model heat transfer
  and fluid heat flow.
  </p>
  </html>")); 
  end Thermal;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices" 
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math" 
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {0, 68}}, color = {192, 192, 192}), Polygon(points = {{0, 90}, {-8, 68}, {8, 68}, {0, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(graphics = {Line(points = {{0, 80}, {-8, 80}}, color = {95, 95, 95}), Line(points = {{0, -80}, {-8, -80}}, color = {95, 95, 95}), Line(points = {{0, -90}, {0, 84}}, color = {95, 95, 95}), Text(extent = {{5, 104}, {25, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{0, 98}, {-6, 82}, {6, 82}, {0, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
      <p>
      Icon for a mathematical function, consisting of an y-axis in the middle.
      It is expected, that an x-axis is added and a plot of the function.
      </p>
      </html>")); end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output SI.Angle y;
      external "builtin" y = asin(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = asin(u), with -1 &le; u &le; +1:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = asin(u), with -1 &le; u &le; +1:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
    </p>
    </html>")); 
    end asin;

    function atan2  "Four quadrant inverse tangent" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      output SI.Angle y;
      external "builtin" y = atan2(u1, u2) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {8.93, -67.2}, {17.1, -59.3}, {27.3, -53.6}, {42.1, -49.4}, {69.9, -45.8}, {80, -45.1}}), Line(points = {{-80, -34.9}, {-46.1, -31.4}, {-29.4, -27.1}, {-18.3, -21.5}, {-10.3, -14.5}, {-2.03, -3.17}, {7.97, 11.6}, {15.5, 19.4}, {24.3, 25}, {39, 30}, {62.1, 33.5}, {80, 34.9}}), Line(points = {{-80, 45.1}, {-45.9, 48.7}, {-29.1, 52.9}, {-18.1, 58.6}, {-10.2, 65.8}, {-1.82, 77.2}, {0, 80}}), Text(extent = {{-90, -46}, {-18, -94}}, lineColor = {192, 192, 192}, textString = "atan2")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{96, 0}, {80, 6}, {80, -6}, {96, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {8.93, -67.2}, {17.1, -59.3}, {27.3, -53.6}, {42.1, -49.4}, {69.9, -45.8}, {80, -45.1}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-80, -34.9}, {-46.1, -31.4}, {-29.4, -27.1}, {-18.3, -21.5}, {-10.3, -14.5}, {-2.03, -3.17}, {7.97, 11.6}, {15.5, 19.4}, {24.3, 25}, {39, 30}, {62.1, 33.5}, {80, 34.9}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-80, 45.1}, {-45.9, 48.7}, {-29.1, 52.9}, {-18.1, 58.6}, {-10.2, 65.8}, {-1.82, 77.2}, {0, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-32, 89}, {-10, 74}}, textString = "pi", lineColor = {0, 0, 255}), Text(extent = {{-32, -72}, {-4, -88}}, textString = "-pi", lineColor = {0, 0, 255}), Text(extent = {{0, 55}, {20, 42}}, textString = "pi/2", lineColor = {0, 0, 255}), Line(points = {{0, 40}, {-8, 40}}, color = {192, 192, 192}), Line(points = {{0, -40}, {-8, -40}}, color = {192, 192, 192}), Text(extent = {{0, -23}, {20, -42}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{62, -4}, {94, -26}}, lineColor = {95, 95, 95}, textString = "u1, u2"), Line(points = {{-88, 40}, {86, 40}}, color = {175, 175, 175}), Line(points = {{-86, -40}, {86, -40}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = atan2(u1,u2) such that tan(y) = u1/u2 and
    y is in the range -pi &lt; y &le; pi. u2 may be zero, provided
    u1 is not zero. Usually u1, u2 is provided in such a form that
    u1 = sin(y) and u2 = cos(y):
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/atan2.png\">
    </p>

    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {8.93, -67.2}, {17.1, -59.3}, {27.3, -53.6}, {42.1, -49.4}, {69.9, -45.8}, {80, -45.1}}), Line(points = {{-80, -34.9}, {-46.1, -31.4}, {-29.4, -27.1}, {-18.3, -21.5}, {-10.3, -14.5}, {-2.03, -3.17}, {7.97, 11.6}, {15.5, 19.4}, {24.3, 25}, {39, 30}, {62.1, 33.5}, {80, 34.9}}), Line(points = {{-80, 45.1}, {-45.9, 48.7}, {-29.1, 52.9}, {-18.1, 58.6}, {-10.2, 65.8}, {-1.82, 77.2}, {0, 80}}), Text(extent = {{-90, -46}, {-18, -94}}, lineColor = {192, 192, 192}, textString = "atan2")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{96, 0}, {80, 6}, {80, -6}, {96, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {8.93, -67.2}, {17.1, -59.3}, {27.3, -53.6}, {42.1, -49.4}, {69.9, -45.8}, {80, -45.1}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-80, -34.9}, {-46.1, -31.4}, {-29.4, -27.1}, {-18.3, -21.5}, {-10.3, -14.5}, {-2.03, -3.17}, {7.97, 11.6}, {15.5, 19.4}, {24.3, 25}, {39, 30}, {62.1, 33.5}, {80, 34.9}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-80, 45.1}, {-45.9, 48.7}, {-29.1, 52.9}, {-18.1, 58.6}, {-10.2, 65.8}, {-1.82, 77.2}, {0, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-32, 89}, {-10, 74}}, textString = "pi", lineColor = {0, 0, 255}), Text(extent = {{-32, -72}, {-4, -88}}, textString = "-pi", lineColor = {0, 0, 255}), Text(extent = {{0, 55}, {20, 42}}, textString = "pi/2", lineColor = {0, 0, 255}), Line(points = {{0, 40}, {-8, 40}}, color = {192, 192, 192}), Line(points = {{0, -40}, {-8, -40}}, color = {192, 192, 192}), Text(extent = {{0, -23}, {20, -42}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{62, -4}, {94, -26}}, lineColor = {95, 95, 95}, textString = "u1, u2"), Line(points = {{-88, 40}, {86, 40}}, color = {175, 175, 175}), Line(points = {{-86, -40}, {86, -40}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = atan2(u1,u2) such that tan(y) = u1/u2 and
    y is in the range -pi &lt; y &le; pi. u2 may be zero, provided
    u1 is not zero. Usually u1, u2 is provided in such a form that
    u1 = sin(y) and u2 = cos(y):
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/atan2.png\">
    </p>

    </html>")); 
    end atan2;

    function exp  "Exponential, base e" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
    </p>
    </html>")); 
    end exp;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.4}, {-49.4, 74.6}, {-43.8, 79.1}, {-38.2, 79.8}, {-32.6, 76.6}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.1}, {35, -78.4}, {40.6, -80}, {46.2, -77.6}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}), Documentation(info = "<html>
  <p>
  This package contains <b>basic mathematical functions</b> (such as sin(..)),
  as well as functions operating on
  <a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
  <a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
  <a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
  <a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
  </p>

  <dl>
  <dt><b>Main Authors:</b></dt>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
      Marcus Baur<br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
      Institut f&uuml;r Robotik und Mechatronik<br>
      Postfach 1116<br>
      D-82230 Wessling<br>
      Germany<br>
      email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br></dd>
  </dl>

  <p>
  Copyright &copy; 1998-2016, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>October 21, 2002</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
         and Christian Schweiger:<br>
         Function tempInterpol2 added.</li>
  <li><i>Oct. 24, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Icons for icon and diagram level introduced.</li>
  <li><i>June 30, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized.</li>
  </ul>

  </html>")); 
  end Math;

  package Utilities  "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)" 
    extends Modelica.Icons.Package;

    package Files  "Functions to work with files and directories" 
      extends Modelica.Icons.FunctionsPackage;

      function loadResource  "Return the absolute path name of a URI or local file name" 
        extends Modelica.Utilities.Internal.PartialModelicaServices.ExternalReferences.PartialLoadResource;
        extends ModelicaServices.ExternalReferences.loadResource;
        annotation(Documentation(info = "<html>
      <h4>Syntax</h4>
      <blockquote><pre>
      fileReference = FileSystem.<b>loadResource</b>(uri);
      </pre></blockquote>
      <h4>Description</h4>
      <p>
      The function call \"<code>FileSystem.<b>loadResource</b>(uri)</code>\" returns the
      <b>absolute path name</b> of the file that is either defined by an URI or by a local
      path name. With the returned file name it is possible to
      access the file with function calls of the C standard library.
      If the data or file is stored in a data-base,
      this might require copying the resource to a temporary folder and referencing that.
      </p>

      <p>
      The implementation of this function is tool specific. However, at least Modelica URIs
      (see \"chapter 13.2.3 External Resources\" of the Modelica Specification),
      as well as absolute local file path names are supported.
      </p>

      <h4>Example</h4>
      <blockquote><pre>
        file1 = loadResource(\"modelica://Modelica/Resources/Data/Utilities/Examples_readRealParameters.txt\")
                // file1 is the absolute path name of the file
        file2 = loadResource(\"C:\\\\data\\\\readParameters.txt\")
                file2 = \"C:/data/readParameters.txt\"
      </pre></blockquote>
      </html>")); 
      end loadResource;
      annotation(Documentation(info = "<html>
    <p>
    This package contains functions to work with files and directories.
    As a general convention of this package, '/' is used as directory
    separator both for input and output arguments of all functions.
    For example:
    </p>
    <pre>
       exist(\"Modelica/Mechanics/Rotational.mo\");
    </pre>
    <p>
    The functions provide the mapping to the directory separator of the
    underlying operating system. Note, that on Windows system the usage
    of '\\' as directory separator would be inconvenient, because this
    character is also the escape character in Modelica and C Strings.
    </p>
    <p>
    In the table below an example call to every function is given:
    </p>
    <table border=1 cellspacing=0 cellpadding=2>
      <tr><th><b><i>Function/type</i></b></th><th><b><i>Description</i></b></th></tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Files.list\">list</a>(name)</td>
          <td valign=\"top\"> List content of file or of directory.</td>
      </tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Files.copy\">copy</a>(oldName, newName)<br>
              <a href=\"modelica://Modelica.Utilities.Files.copy\">copy</a>(oldName, newName, replace=false)</td>
          <td valign=\"top\"> Generate a copy of a file or of a directory.</td>
      </tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Files.move\">move</a>(oldName, newName)<br>
              <a href=\"modelica://Modelica.Utilities.Files.move\">move</a>(oldName, newName, replace=false)</td>
          <td valign=\"top\"> Move a file or a directory to another place.</td>
      </tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Files.remove\">remove</a>(name)</td>
          <td valign=\"top\"> Remove file or directory (ignore call, if it does not exist).</td>
      </tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Files.removeFile\">removeFile</a>(name)</td>
          <td valign=\"top\"> Remove file (ignore call, if it does not exist)</td>
      </tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Files.createDirectory\">createDirectory</a>(name)</td>
          <td valign=\"top\"> Create directory (if directory already exists, ignore call).</td>
      </tr>
      <tr><td valign=\"top\">result = <a href=\"modelica://Modelica.Utilities.Files.exist\">exist</a>(name)</td>
          <td valign=\"top\"> Inquire whether file or directory exists.</td>
      </tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Files.assertNew\">assertNew</a>(name,message)</td>
          <td valign=\"top\"> Trigger an assert, if a file or directory exists.</td>
      </tr>
      <tr><td valign=\"top\">fullName = <a href=\"modelica://Modelica.Utilities.Files.fullPathName\">fullPathName</a>(name)</td>
          <td valign=\"top\"> Get full path name of file or directory name.</td>
      </tr>
      <tr><td valign=\"top\">(directory, name, extension) = <a href=\"modelica://Modelica.Utilities.Files.splitPathName\">splitPathName</a>(name)</td>
          <td valign=\"top\"> Split path name in directory, file name kernel, file name extension.</td>
      </tr>
      <tr><td valign=\"top\">fileName = <a href=\"modelica://Modelica.Utilities.Files.temporaryFileName\">temporaryFileName</a>()</td>
          <td valign=\"top\"> Return arbitrary name of a file that does not exist<br>
               and is in a directory where access rights allow to <br>
               write to this file (useful for temporary output of files).</td>
      </tr>
    </table>
    </html>")); 
    end Files;

    package Internal  "Internal components that a user should usually not directly utilize" 
      extends Modelica.Icons.InternalPackage;

      partial package PartialModelicaServices  "Interfaces of components requiring a tool specific implementation" 
        extends Modelica.Icons.InternalPackage;

        package ExternalReferences  "Functions to access external resources" 
          extends Modelica.Icons.InternalPackage;

          partial function PartialLoadResource  "Interface for tool specific function to return the absolute path name of a URI or local file name" 
            extends Modelica.Icons.Function;
            input String uri "URI or local file name";
            output String fileReference "Absolute path name of file";
            annotation(Documentation(info = "<html>
          <p>
          This partial function defines the function interface of a tool-specific implementation
          in package ModelicaServices. The interface is documented at
          <a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Internal.FileSystem.loadResource</a>.
          </p>

          </html>")); 
          end PartialLoadResource;
        end ExternalReferences;
        annotation(Documentation(info = "<html>

      <p>
      This package contains interfaces of a set of functions and models used in the
      Modelica Standard Library that requires a <b>tool specific implementation</b>.
      There is an associated package called <b>ModelicaServices</b>. A tool vendor
      should provide a proper implementation of this library for the corresponding
      tool. The default implementation is \"do nothing\".
      In the Modelica Standard Library, the models and functions of ModelicaServices
      are used.
      </p>
      </html>")); 
      end PartialModelicaServices;
    end Internal;
    annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {1.3835, -4.1418}, rotation = 45.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.0, 93.333}, {-15.0, 68.333}, {0.0, 58.333}, {15.0, 68.333}, {15.0, 93.333}, {20.0, 93.333}, {25.0, 83.333}, {25.0, 58.333}, {10.0, 43.333}, {10.0, -41.667}, {25.0, -56.667}, {25.0, -76.667}, {10.0, -91.667}, {0.0, -91.667}, {0.0, -81.667}, {5.0, -81.667}, {15.0, -71.667}, {15.0, -61.667}, {5.0, -51.667}, {-5.0, -51.667}, {-15.0, -61.667}, {-15.0, -71.667}, {-5.0, -81.667}, {0.0, -81.667}, {0.0, -91.667}, {-10.0, -91.667}, {-25.0, -76.667}, {-25.0, -56.667}, {-10.0, -41.667}, {-10.0, 43.333}, {-25.0, 58.333}, {-25.0, 83.333}, {-20.0, 93.333}}), Polygon(origin = {10.1018, 5.218}, rotation = -45.0, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-15.0, 87.273}, {15.0, 87.273}, {20.0, 82.273}, {20.0, 27.273}, {10.0, 17.273}, {10.0, 7.273}, {20.0, 2.273}, {20.0, -2.727}, {5.0, -2.727}, {5.0, -77.727}, {10.0, -87.727}, {5.0, -112.727}, {-5.0, -112.727}, {-10.0, -87.727}, {-5.0, -77.727}, {-5.0, -2.727}, {-20.0, -2.727}, {-20.0, 2.273}, {-10.0, 7.273}, {-10.0, 17.273}, {-20.0, 27.273}, {-20.0, 82.273}})}), Documentation(info = "<html>
  <p>
  This package contains Modelica <b>functions</b> that are
  especially suited for <b>scripting</b>. The functions might
  be used to work with strings, read data from file, write data
  to file or copy, move and remove files.
  </p>
  <p>
  For an introduction, have especially a look at:
  </p>
  <ul>
  <li> <a href=\"modelica://Modelica.Utilities.UsersGuide\">Modelica.Utilities.User's Guide</a>
       discusses the most important aspects of this library.</li>
  <li> <a href=\"modelica://Modelica.Utilities.Examples\">Modelica.Utilities.Examples</a>
       contains examples that demonstrate the usage of this library.</li>
  </ul>
  <p>
  The following main sublibraries are available:
  </p>
  <ul>
  <li> <a href=\"modelica://Modelica.Utilities.Files\">Files</a>
       provides functions to operate on files and directories, e.g.,
       to copy, move, remove files.</li>
  <li> <a href=\"modelica://Modelica.Utilities.Streams\">Streams</a>
       provides functions to read from files and write to files.</li>
  <li> <a href=\"modelica://Modelica.Utilities.Strings\">Strings</a>
       provides functions to operate on strings. E.g.
       substring, find, replace, sort, scanToken.</li>
  <li> <a href=\"modelica://Modelica.Utilities.System\">System</a>
       provides functions to interact with the environment.
       E.g., get or set the working directory or environment
       variables and to send a command to the default shell.</li>
  </ul>

  <p>
  Copyright &copy; 1998-2016, Modelica Association, DLR, and Dassault Syst&egrave;mes AB.
  </p>

  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>

  </html>")); 
  end Utilities;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)" 
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Modelica.Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
    annotation(Documentation(info = "<html>
  <p>
  This package provides often needed constants from mathematics, machine
  dependent constants and constants from nature. The latter constants
  (name, value, description) are from the following source:
  </p>

  <dl>
  <dt>Peter J. Mohr, David B. Newell, and Barry N. Taylor:</dt>
  <dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 2014</b>.
  <a href= \"http://dx.doi.org/10.5281/zenodo.22826\">http://dx.doi.org/10.5281/zenodo.22826</a>, 2015. See also <a href=
  \"http://physics.nist.gov/cuu/Constants/index.html\">http://physics.nist.gov/cuu/Constants/index.html</a></dd>
  </dl>

  <p>CODATA is the Committee on Data for Science and Technology.</p>

  <dl>
  <dt><b>Main Author:</b></dt>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
      Oberpfaffenhofen<br>
      Postfach 1116<br>
      D-82230 We&szlig;ling<br>
      email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  </dl>

  <p>
  Copyright &copy; 1998-2016, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>Nov 4, 2015</i>
         by Thomas Beutlich:<br>
         Constants updated according to 2014 CODATA values.</li>
  <li><i>Nov 8, 2004</i>
         by Christian Schweiger:<br>
         Constants updated according to 2002 CODATA values.</li>
  <li><i>Dec 9, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Constants updated according to 1998 CODATA values. Using names, values
         and description text from this source. Included magnetic and
         electric constant.</li>
  <li><i>Sep 18, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Constants eps, inf, small introduced.</li>
  <li><i>Nov 15, 1997</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized.</li>
  </ul>
  </html>"), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-9.2597, 25.6673}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{48.017, 11.336}, {48.017, 11.336}, {10.766, 11.336}, {-25.684, 10.95}, {-34.944, -15.111}, {-34.944, -15.111}, {-32.298, -15.244}, {-32.298, -15.244}, {-22.112, 0.168}, {11.292, 0.234}, {48.267, -0.097}, {48.267, -0.097}}, smooth = Smooth.Bezier), Polygon(origin = {-19.9923, -8.3993}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{3.239, 37.343}, {3.305, 37.343}, {-0.399, 2.683}, {-16.936, -20.071}, {-7.808, -28.604}, {6.811, -22.519}, {9.986, 37.145}, {9.986, 37.145}}, smooth = Smooth.Bezier), Polygon(origin = {23.753, -11.5422}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.873, 41.478}, {-10.873, 41.478}, {-14.048, -4.162}, {-9.352, -24.8}, {7.912, -24.469}, {16.247, 0.27}, {16.247, 0.27}, {13.336, 0.071}, {13.336, 0.071}, {7.515, -9.983}, {-3.134, -7.271}, {-2.671, 41.214}, {-2.671, 41.214}}, smooth = Smooth.Bezier)})); 
  end Constants;

  package Icons  "Library of icons" 
    extends Icons.Package;

    partial package ExamplesPackage  "Icon for packages containing runnable examples" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {8.0, 14.0}, lineColor = {78, 138, 73}, fillColor = {78, 138, 73}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-58.0, 46.0}, {42.0, -14.0}, {-58.0, -74.0}, {-58.0, 46.0}})}), Documentation(info = "<html>
    <p>This icon indicates a package that contains executable examples.</p>
    </html>")); 
    end ExamplesPackage;

    partial package Package  "Icon for standard packages"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {248, 248, 248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Rectangle(lineColor = {128, 128, 128}, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0)}), Documentation(info = "<html>
    <p>Standard package icon.</p>
    </html>")); end Package;

    partial package BasesPackage  "Icon for packages containing base classes" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-30.0, -30.0}, {30.0, 30.0}}, lineColor = {128, 128, 128}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
    <p>This icon shall be used for a package/library that contains base models and classes, respectively.</p>
    </html>")); 
    end BasesPackage;

    partial package VariantsPackage  "Icon for package containing variants" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(origin = {10.0, 10.0}, fillColor = {76, 76, 76}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-80.0, -80.0}, {-20.0, -20.0}}), Ellipse(origin = {10.0, 10.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{0.0, -80.0}, {60.0, -20.0}}), Ellipse(origin = {10.0, 10.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{0.0, 0.0}, {60.0, 60.0}}), Ellipse(origin = {10.0, 10.0}, lineColor = {128, 128, 128}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-80.0, 0.0}, {-20.0, 60.0}})}), Documentation(info = "<html>
    <p>This icon shall be used for a package/library that contains several variants of one component.</p>
    </html>")); 
    end VariantsPackage;

    partial package InterfacesPackage  "Icon for packages containing interfaces" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {20.0, 0.0}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-10.0, 70.0}, {10.0, 70.0}, {40.0, 20.0}, {80.0, 20.0}, {80.0, -20.0}, {40.0, -20.0}, {10.0, -70.0}, {-10.0, -70.0}}), Polygon(fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-100.0, 20.0}, {-60.0, 20.0}, {-30.0, 70.0}, {-10.0, 70.0}, {-10.0, -70.0}, {-30.0, -70.0}, {-60.0, -20.0}, {-100.0, -20.0}})}), Documentation(info = "<html>
    <p>This icon indicates packages containing interfaces.</p>
    </html>")); 
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {23.3333, 0.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-23.333, 30.0}, {46.667, 0.0}, {-23.333, -30.0}}), Rectangle(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-70, -4.5}, {0, 4.5}})}), Documentation(info = "<html>
    <p>This icon indicates a package which contains sources.</p>
    </html>")); 
    end SourcesPackage;

    partial package SensorsPackage  "Icon for packages containing sensors" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(origin = {0.0, -30.0}, fillColor = {255, 255, 255}, extent = {{-90.0, -90.0}, {90.0, 90.0}}, startAngle = 20.0, endAngle = 160.0), Ellipse(origin = {0.0, -30.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-20.0, -20.0}, {20.0, 20.0}}), Line(origin = {0.0, -30.0}, points = {{0.0, 60.0}, {0.0, 90.0}}), Ellipse(origin = {-0.0, -30.0}, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-10.0, -10.0}, {10.0, 10.0}}), Polygon(origin = {-0.0, -30.0}, rotation = -35.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-7.0, 0.0}, {-3.0, 85.0}, {0.0, 90.0}, {3.0, 85.0}, {7.0, 0.0}})}), Documentation(info = "<html>
    <p>This icon indicates a package containing sensors.</p>
    </html>")); 
    end SensorsPackage;

    partial package UtilitiesPackage  "Icon for utility packages" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {1.3835, -4.1418}, rotation = 45.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.0, 93.333}, {-15.0, 68.333}, {0.0, 58.333}, {15.0, 68.333}, {15.0, 93.333}, {20.0, 93.333}, {25.0, 83.333}, {25.0, 58.333}, {10.0, 43.333}, {10.0, -41.667}, {25.0, -56.667}, {25.0, -76.667}, {10.0, -91.667}, {0.0, -91.667}, {0.0, -81.667}, {5.0, -81.667}, {15.0, -71.667}, {15.0, -61.667}, {5.0, -51.667}, {-5.0, -51.667}, {-15.0, -61.667}, {-15.0, -71.667}, {-5.0, -81.667}, {0.0, -81.667}, {0.0, -91.667}, {-10.0, -91.667}, {-25.0, -76.667}, {-25.0, -56.667}, {-10.0, -41.667}, {-10.0, 43.333}, {-25.0, 58.333}, {-25.0, 83.333}, {-20.0, 93.333}}), Polygon(origin = {10.1018, 5.218}, rotation = -45.0, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-15.0, 87.273}, {15.0, 87.273}, {20.0, 82.273}, {20.0, 27.273}, {10.0, 17.273}, {10.0, 7.273}, {20.0, 2.273}, {20.0, -2.727}, {5.0, -2.727}, {5.0, -77.727}, {10.0, -87.727}, {5.0, -112.727}, {-5.0, -112.727}, {-10.0, -87.727}, {-5.0, -77.727}, {-5.0, -2.727}, {-20.0, -2.727}, {-20.0, 2.273}, {-10.0, 7.273}, {-10.0, 17.273}, {-20.0, 27.273}, {-20.0, 82.273}})}), Documentation(info = "<html>
    <p>This icon indicates a package containing utility classes.</p>
    </html>")); 
    end UtilitiesPackage;

    partial package TypesPackage  "Icon for packages containing type definitions" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-12.167, -23}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{12.167, 65}, {14.167, 93}, {36.167, 89}, {24.167, 20}, {4.167, -30}, {14.167, -30}, {24.167, -30}, {24.167, -40}, {-5.833, -50}, {-15.833, -30}, {4.167, 20}, {12.167, 65}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Polygon(origin = {2.7403, 1.6673}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{49.2597, 22.3327}, {31.2597, 24.3327}, {7.2597, 18.3327}, {-26.7403, 10.3327}, {-46.7403, 14.3327}, {-48.7403, 6.3327}, {-32.7403, 0.3327}, {-6.7403, 4.3327}, {33.2597, 14.3327}, {49.2597, 14.3327}, {49.2597, 22.3327}}, smooth = Smooth.Bezier)})); 
    end TypesPackage;

    partial package FunctionsPackage  "Icon for packages containing functions" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {128, 128, 128}, extent = {{-90, -90}, {90, 90}}, textString = "f")})); 
    end FunctionsPackage;

    partial package IconsPackage  "Icon for packages containing icons" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})})); 
    end IconsPackage;

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {215, 215, 215}, fillColor = {255, 255, 255}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100, -100}, {100, 100}}, radius = 25), Rectangle(lineColor = {215, 215, 215}, extent = {{-100, -100}, {100, 100}}, radius = 25), Ellipse(extent = {{-80, 80}, {80, -80}}, lineColor = {215, 215, 215}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-55, 55}, {55, -55}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-60, 14}, {60, -14}}, lineColor = {215, 215, 215}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid, rotation = 45)}), Documentation(info = "<html>

    <p>
    This icon shall be used for a package that contains internal classes not to be
    directly utilized by a user.
    </p>
    </html>")); end InternalPackage;

    partial package MaterialPropertiesPackage  "Icon for package containing property classes" 
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {102, 102, 102}, fillColor = {204, 204, 204}, pattern = LinePattern.None, fillPattern = FillPattern.Sphere, extent = {{-60.0, -60.0}, {60.0, 60.0}})}), Documentation(info = "<html>
    <p>This icon indicates a package that contains properties</p>
    </html>")); 
    end MaterialPropertiesPackage;

    partial function Function  "Icon for functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 105}, {150, 145}}, textString = "%name"), Ellipse(lineColor = {108, 88, 49}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Text(lineColor = {108, 88, 49}, extent = {{-90.0, -90.0}, {90.0, 90.0}}, textString = "f")}), Documentation(info = "<html>
    <p>This icon indicates Modelica functions.</p>
    </html>")); end Function;

    partial record Record  "Icon for records"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 60}, {150, 100}}, textString = "%name"), Rectangle(origin = {0.0, -25.0}, lineColor = {64, 64, 64}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100.0, -75.0}, {100.0, 75.0}}, radius = 25.0), Line(points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -50.0}, points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -25.0}, points = {{0.0, 75.0}, {0.0, -75.0}}, color = {64, 64, 64})}), Documentation(info = "<html>
    <p>
    This icon is indicates a record.
    </p>
    </html>")); end Record;
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}), Documentation(info = "<html>
  <p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer. </p>

  <h4>Main Authors:</h4>

  <dl>
  <dt><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dt>
      <dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd>
      <dd>Oberpfaffenhofen</dd>
      <dd>Postfach 1116</dd>
      <dd>D-82230 Wessling</dd>
      <dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  <dt>Christian Kral</dt>

      <dd>  <a href=\"http://christiankral.net/\">Electric Machines, Drives and Systems</a><br>
  </dd>
      <dd>1060 Vienna, Austria</dd>
      <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
  <dt>Johan Andreasson</dt>
      <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>
      <dd>Ideon Science Park</dd>
      <dd>22370 Lund, Sweden</dd>
      <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
  </dl>

  <p>Copyright &copy; 1998-2016, Modelica Association, DLR, AIT, and Modelon AB. </p>
  <p><i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified under the terms of the <b>Modelica license</b>, see the license conditions and the accompanying <b>disclaimer</b> in <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a>.</i> </p>
  </html>")); 
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992" 
    extends Modelica.Icons.Package;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units" 
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units" 
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
        annotation(Documentation(info = "<html>
      <p>
      This package provides predefined types, such as <b>Angle_deg</b> (angle in
      degree), <b>AngularVelocity_rpm</b> (angular velocity in revolutions per
      minute) or <b>Temperature_degF</b> (temperature in degree Fahrenheit),
      which are in common use but are not part of the international standard on
      units according to ISO 31-1992 \"General principles concerning quantities,
      units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
      the use of their multiples and of certain other units\".</p>
      <p>If possible, the types in this package should not be used. Use instead
      types of package Modelica.SIunits. For more information on units, see also
      the book of Francois Cardarelli <b>Scientific Unit Conversion - A
      Practical Guide to Metrication</b> (Springer 1997).</p>
      <p>Some units, such as <b>Temperature_degC/Temp_C</b> are both defined in
      Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
      definitions have been placed erroneously in Modelica.SIunits although they
      are not SIunits. For backward compatibility, these type definitions are
      still kept in Modelica.SIunits.</p>
      </html>"), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Text(origin = {15.0, 51.8518}, extent = {{-105.0, -86.8518}, {75.0, -16.8518}}, lineColor = {0, 0, 0}, textString = "[km/h]")})); 
      end NonSIunits;
      annotation(Documentation(info = "<html>
    <p>This package provides conversion functions from the non SI Units
    defined in package Modelica.SIunits.Conversions.NonSIunits to the
    corresponding SI Units defined in package Modelica.SIunits and vice
    versa. It is recommended to use these functions in the following
    way (note, that all functions have one Real input and one Real output
    argument):</p>
    <pre>
      <b>import</b> SI = Modelica.SIunits;
      <b>import</b> Modelica.SIunits.Conversions.*;
         ...
      <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
      <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
      <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                          // to radian per seconds
    </pre>

    </html>")); 
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Time = Real(final quantity = "Time", final unit = "s");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type AngularAcceleration = Real(final quantity = "AngularAcceleration", final unit = "rad/s2");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type AngularFrequency = Real(final quantity = "AngularFrequency", final unit = "rad/s");
    type Power = Real(final quantity = "Power", final unit = "W");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temperature = ThermodynamicTemperature;
    type Heat = Real(final quantity = "Energy", final unit = "J");
    type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
    type ElectricCurrent = Real(final quantity = "ElectricCurrent", final unit = "A");
    type Current = ElectricCurrent;
    type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
    type Voltage = ElectricPotential;
    type Inductance = Real(final quantity = "Inductance", final unit = "H");
    type Resistance = Real(final quantity = "Resistance", final unit = "Ohm");
    type Conductance = Real(final quantity = "Conductance", final unit = "S");
    type ApparentPower = Real(final quantity = "Power", final unit = "VA");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-80, -40}, {-80, -40}, {-55, 50}, {-52.5, 62.5}, {-65, 60}, {-65, 65}, {-35, 77.5}, {-32.5, 60}, {-50, 0}, {-50, 0}, {-30, 15}, {-20, 27.5}, {-32.5, 27.5}, {-32.5, 27.5}, {-32.5, 32.5}, {-32.5, 32.5}, {2.5, 32.5}, {2.5, 32.5}, {2.5, 27.5}, {2.5, 27.5}, {-7.5, 27.5}, {-30, 7.5}, {-30, 7.5}, {-25, -25}, {-17.5, -28.75}, {-10, -25}, {-5, -26.25}, {-5, -32.5}, {-16.25, -41.25}, {-31.25, -43.75}, {-40, -33.75}, {-45, -5}, {-45, -5}, {-52.5, -10}, {-52.5, -10}, {-60, -40}, {-60, -40}}, smooth = Smooth.Bezier), Polygon(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{87.5, 30}, {62.5, 30}, {62.5, 30}, {55, 33.75}, {36.25, 35}, {16.25, 25}, {7.5, 6.25}, {11.25, -7.5}, {22.5, -12.5}, {22.5, -12.5}, {6.25, -22.5}, {6.25, -35}, {16.25, -38.75}, {16.25, -38.75}, {21.25, -41.25}, {21.25, -41.25}, {45, -48.75}, {47.5, -61.25}, {32.5, -70}, {12.5, -65}, {7.5, -51.25}, {21.25, -41.25}, {21.25, -41.25}, {16.25, -38.75}, {16.25, -38.75}, {6.25, -41.25}, {-6.25, -50}, {-3.75, -68.75}, {30, -76.25}, {65, -62.5}, {63.75, -35}, {27.5, -26.25}, {22.5, -20}, {27.5, -15}, {27.5, -15}, {30, -7.5}, {30, -7.5}, {27.5, -2.5}, {28.75, 11.25}, {36.25, 27.5}, {47.5, 30}, {53.75, 22.5}, {51.25, 8.75}, {45, -6.25}, {35, -11.25}, {30, -7.5}, {30, -7.5}, {27.5, -15}, {27.5, -15}, {43.75, -16.25}, {65, -6.25}, {72.5, 10}, {70, 20}, {70, 20}, {80, 20}}, smooth = Smooth.Bezier)}), Documentation(info = "<html>
  <p>This package provides predefined types, such as <i>Mass</i>,
  <i>Angle</i>, <i>Time</i>, based on the international standard
  on units, e.g.,
  </p>

  <pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                       <b>final</b> unit     = \"rad\",
                       displayUnit    = \"deg\");
  </pre>

  <p>
  Some of the types are derived SI units that are utilized in package Modelica
  (such as ComplexCurrent, which is a complex number where both the real and imaginary
  part have the SI unit Ampere).
  </p>

  <p>
  Furthermore, conversion functions from non SI-units to SI-units and vice versa
  are provided in subpackage
  <a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
  </p>

  <p>
  For an introduction how units are used in the Modelica standard library
  with package SIunits, have a look at:
  <a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
  </p>

  <p>
  Copyright &copy; 1998-2016, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added molar units for energy and enthalpy.</li>
  <li><i>Jan. 27, 2010</i> by Christian Kral:<br/>Added complex units.</li>
  <li><i>Dec. 14, 2005</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
  <li><i>October 21, 2002</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Christian Schweiger:<br/>Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
  <li><i>June 6, 2000</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
  <li><i>Oct. 27, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
  <li><i>Sept. 18, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
  <li><i>Aug 12, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
  <li><i>June 29, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
  <li><i>April 8, 1998</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
  <li><i>Nov. 15, 1997</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Hubertus Tummescheit:<br/>Some chapters realized.</li>
  </ul>
  </html>")); 
  end SIunits;
  annotation(preferredView = "info", version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z", revisionId = "$Id::                                       $", uses(Complex(version = "3.2.2"), ModelicaServices(version = "3.2.2")), conversion(noneFromVersion = "3.2.1", noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-6.9888, 20.048}, fillColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112, 10.3188}, {-93.0112, 10.3188}, {-73.011, 24.6}, {-63.011, 31.221}, {-51.219, 36.777}, {-39.842, 38.629}, {-31.376, 36.248}, {-25.819, 29.369}, {-24.232, 22.49}, {-23.703, 17.463}, {-15.501, 25.135}, {-6.24, 32.015}, {3.02, 36.777}, {15.191, 39.423}, {27.097, 37.306}, {32.653, 29.633}, {35.035, 20.108}, {43.501, 28.046}, {54.085, 35.19}, {65.991, 39.952}, {77.897, 39.688}, {87.422, 33.338}, {91.126, 21.696}, {90.068, 9.525}, {86.099, -1.058}, {79.749, -10.054}, {71.283, -21.431}, {62.816, -33.337}, {60.964, -32.808}, {70.489, -16.14}, {77.368, -2.381}, {81.072, 10.054}, {79.749, 19.05}, {72.605, 24.342}, {61.758, 23.019}, {49.587, 14.817}, {39.003, 4.763}, {29.214, -6.085}, {21.012, -16.669}, {13.339, -26.458}, {5.401, -36.777}, {-1.213, -46.037}, {-6.24, -53.446}, {-8.092, -52.387}, {-0.684, -40.746}, {5.401, -30.692}, {12.81, -17.198}, {19.424, -3.969}, {23.658, 7.938}, {22.335, 18.785}, {16.514, 23.283}, {8.047, 23.019}, {-1.478, 19.05}, {-11.267, 11.113}, {-19.734, 2.381}, {-29.259, -8.202}, {-38.519, -19.579}, {-48.044, -31.221}, {-56.511, -43.392}, {-64.449, -55.298}, {-72.386, -66.939}, {-77.678, -74.612}, {-79.53, -74.083}, {-71.857, -61.383}, {-62.861, -46.037}, {-52.278, -28.046}, {-44.869, -15.346}, {-38.784, -2.117}, {-35.344, 8.731}, {-36.403, 19.844}, {-42.488, 23.813}, {-52.013, 22.49}, {-60.744, 16.933}, {-68.947, 10.054}, {-76.884, 2.646}, {-93.0112, -12.1707}, {-93.0112, -12.1707}}, smooth = Smooth.Bezier), Ellipse(origin = {40.8208, -37.7602}, fillColor = {161, 0, 4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562, -17.8563}, {17.8563, 17.8562}})}), Documentation(info = "<html>
<p>
Package <b>Modelica&reg;</b> is a <b>standardized</b> and <b>free</b> package
that is developed together with the Modelica&reg; language from the
Modelica Association, see
<a href=\"https://www.Modelica.org\">https://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/UsersGuide/ModelicaLibraries.png\">
</p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"modelica://Modelica.UsersGuide.Overview\">Overview</a>
  provides an overview of the Modelica Standard Library
  inside the <a href=\"modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
<li><a href=\"modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
 summarizes the changes of new versions of this package.</li>
<li> <a href=\"modelica://Modelica.UsersGuide.Contact\">Contact</a>
  lists the contributors of the Modelica Standard Library.</li>
<li> The <b>Examples</b> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li><b>1600</b> models and blocks, and</li>
<li><b>1350</b> functions</li>
</ul>
<p>
that are directly usable (= number of public, non-partial classes). It is fully compliant
to <a href=\"https://www.modelica.org/documents/ModelicaSpec32Revision2.pdf\">Modelica Specification Version 3.2 Revision 2</a>
and it has been tested with Modelica tools from different vendors.
</p>

<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 1998-2016, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, ESI ITI, Fraunhofer,
A.&nbsp;Haumer, C.&nbsp;Kral, Modelon, TU Hamburg-Harburg, Politecnico di Milano, XRG Simulation.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

<p>
<b>Modelica&reg;</b> is a registered trademark of the Modelica Association.
</p>
</html>")); 
end Modelica;

model Rectifier_total  "Rectifier"
  extends PowerSystems.Examples.AC3ph.Inverters.Rectifier;
 annotation(Documentation(info = "<html>
<p>3-phase rectifier. Compare 'equation' and 'modular' version.</p>
<p><a href=\"modelica://PowerSystems.Examples.AC3ph.Inverters\">up users guide</a></p>
</html>
"), experiment(StopTime = 0.2, Interval = 0.2e-3, Tolerance = 1e-005));
end Rectifier_total;
