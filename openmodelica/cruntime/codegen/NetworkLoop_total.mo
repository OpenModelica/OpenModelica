package PowerSystems  "Library for electrical power systems"
  extends Modelica.Icons.Package;

  model System  "System reference"
    parameter .Modelica.SIunits.Frequency f_nom = 50 "nominal frequency" annotation(Evaluate = true, Dialog(group = "System"), choices(choice = 50, choice = 60));
    parameter .Modelica.SIunits.Frequency f = f_nom "frequency if fType_par = true, else initial frequency" annotation(Evaluate = true, Dialog(group = "System"));
    parameter Boolean fType_par = true "= true, if system frequency defined by parameter f, else average frequency" annotation(Evaluate = true, Dialog(group = "System"));
    parameter .Modelica.SIunits.Frequency[2] f_lim = {0.5 * f_nom, 2 * f_nom} "limit frequencies (for supervision of average frequency)" annotation(Evaluate = true, Dialog(group = "System", enable = not fType_par));
    parameter .Modelica.SIunits.Angle alpha0 = 0 "phase angle" annotation(Evaluate = true, Dialog(group = "System"));
    parameter String ref = "synchron" "reference frame (3-phase)" annotation(Evaluate = true, Dialog(group = "System", enable = sim == "tr"), choices(choice = "synchron", choice = "inertial"));
    parameter String ini = "st" "transient or steady-state initialisation" annotation(Evaluate = true, Dialog(group = "Mode", enable = sim == "tr"), choices(choice = "tr", choice = "st"));
    parameter String sim = "tr" "transient or steady-state simulation" annotation(Evaluate = true, Dialog(group = "Mode"), choices(choice = "tr", choice = "st"));
    final parameter .Modelica.SIunits.AngularFrequency omega_nom = 2 * .Modelica.Constants.pi * f_nom "nominal angular frequency" annotation(Evaluate = true);
    final parameter .PowerSystems.Basic.Types.AngularVelocity w_nom = 2 * .Modelica.Constants.pi * f_nom "nom r.p.m." annotation(Evaluate = true, Dialog(group = "Nominal"));
    final parameter Boolean synRef = if transientSim then ref == "synchron" else true annotation(Evaluate = true);
    final parameter Boolean steadyIni = ini == "st" "steady state initialisation of electric equations" annotation(Evaluate = true);
    final parameter Boolean transientSim = sim == "tr" "transient mode of electric equations" annotation(Evaluate = true);
    final parameter Boolean steadyIni_t = steadyIni and transientSim annotation(Evaluate = true);
    discrete .Modelica.SIunits.Time initime;
    .Modelica.SIunits.Angle theta(final start = 0, stateSelect = if fType_par then StateSelect.default else StateSelect.always);
    .Modelica.SIunits.AngularFrequency omega(final start = 2 * .Modelica.Constants.pi * f);
    Interfaces.Frequency receiveFreq "receives weighted frequencies from generators" annotation(Placement(transformation(extent = {{-96, 64}, {-64, 96}})));
  initial equation
    if not fType_par then
      theta = omega * time;
    end if;
  equation
    when initial() then
      initime = time;
    end when;
    if fType_par then
      omega = 2 * .Modelica.Constants.pi * f;
      theta = omega * time;
    else
      omega = if initial() then 2 * .Modelica.Constants.pi * f else receiveFreq.w_H / receiveFreq.H;
      der(theta) = omega;
      when omega < 2 * .Modelica.Constants.pi * f_lim[1] or omega > 2 * .Modelica.Constants.pi * f_lim[2] then
        terminate("FREQUENCY EXCEEDS BOUNDS!");
      end when;
    end if;
    receiveFreq.h = 0.0;
    receiveFreq.w_h = 0.0;
    annotation(preferredView = "info", defaultComponentName = "system", defaultComponentPrefixes = "inner", missingInnerMessage = "No \"system\" component is defined.
      Drag PowerSystems.System into the top level of your model.", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-100, 100}, {100, 60}}, lineColor = {0, 120, 120}, fillColor = {0, 120, 120}, fillPattern = FillPattern.Solid), Text(extent = {{-60, 100}, {100, 60}}, lineColor = {215, 215, 215}, textString = "%name"), Text(extent = {{-100, 50}, {100, 20}}, lineColor = {0, 0, 0}, textString = "f_nom=%f_nom"), Text(extent = {{-100, -20}, {100, 10}}, lineColor = {0, 0, 0}, textString = "f par:%fType_par"), Text(extent = {{-100, -30}, {100, -60}}, lineColor = {0, 120, 120}, textString = "%ref"), Text(extent = {{-100, -70}, {100, -100}}, lineColor = {176, 0, 0}, textString = "ini:%ini  sim:%sim")}), Documentation(info = "<html>
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
       For frequency-type 'parameter' this is simply a parameter value.<br>
       For frequency-type 'signal' it is a positive input signal.<br>
       For frequency-type 'average' it is a weighted average over the relevant generator frequencies.
  <li> the system angle theta by integration of
  <pre> der(theta) = omega </pre><br>
       This angle allows the definition of a rotating electrical <b>coordinate system</b><br>
       for <b>AC three-phase models</b>.<br>
       Root-nodes defining coordinate-orientation will choose a reference angle theta_ref (connector-variable theta[2]) according to the parameter <tt>ref</tt>:<br><br>
       <tt>theta_ref = theta if ref = \"synchron\"</tt> (reference frame is synchronously rotating with theta).<br>
       <tt>theta_ref = 0 if ref = \"inertial\"</tt> (inertial reference frame, not rotating).<br>

       where<br>
       <tt>theta = 1 :</tt> reference frame is synchronously rotating.<br>
       <tt>ref=0 :</tt> reference frame is at rest.<br>
       Note: Steady-state simulation is only possible for <tt>ref = \"synchron\"</tt>.<br><br>
       <tt>ref</tt> is determined by the parameter <tt>refFrame</tt> in the following way:

       </li>
  </ul>
  <p><b>Note</b>: Each model using <b>System</b> must use it with an <b>inner</b> declaration and instance name <b>system</b> in order that it can be accessed from all objects in the model.<br>When dragging the 'System' from the package browser into the diagram layer, declaration and instance name are automatically generated.</p>
  <p><a href=\"modelica://PowerSystems.UsersGuide.Overview\">up users guide</a></p>
  </html>
  "));
  end System;

  replaceable package PackagePhaseSystem = PhaseSystems.ThreePhase_dq "Default phase system" annotation(choicesAllMatching = true);

  package Examples
    extends Modelica.Icons.ExamplesPackage;

    package Network  "Network flow calculations"
      extends Modelica.Icons.ExamplesPackage;

      model NetworkLoop  "Simple textbook example for a steady-state power flow calculation"
        extends Modelica.Icons.Example;
        replaceable package PhaseSystem = PackagePhaseSystem "Default phase system" annotation(choicesAllMatching = true);
        PowerSystems.Generic.FixedVoltageSource fixedVoltageSource1(V = 10e3, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(origin = {0, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        PowerSystems.Generic.Impedance impedance1(R = 2, L = 0, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(origin = {-50, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        PowerSystems.Generic.Impedance impedance2(R = 4, L = 0, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(origin = {-50, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        PowerSystems.Generic.Impedance impedance3(R = 2, L = 0, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{-10, -90}, {10, -70}})));
        PowerSystems.Generic.Impedance impedance4(L = 0, R = 1, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(origin = {50, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        PowerSystems.Generic.Impedance impedance5(L = 0, R = 3, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(origin = {50, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        PowerSystems.Generic.FixedCurrent fixedCurrent3(I = 50, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{70, -90}, {90, -70}})));
        PowerSystems.Generic.FixedCurrent fixedCurrent1(I = 55, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{-70, -40}, {-90, -20}})));
        PowerSystems.Generic.FixedCurrent fixedCurrent2(I = 45, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{-70, -90}, {-90, -70}})));
        PowerSystems.Generic.FixedCurrent fixedCurrent4(I = 60, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{70, -40}, {90, -20}})));
        PowerSystems.Generic.VoltageConverter transformer1(ratio = 10 / 10.4156, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(origin = {-50, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        PowerSystems.Generic.VoltageConverter transformer2(ratio = 10 / 10, redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(origin = {50, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
        inner System system annotation(Placement(transformation(extent = {{-100, 80}, {-80, 100}})));
      equation
        connect(impedance1.terminal_n, impedance2.terminal_p) annotation(Line(points = {{-50, -20}, {-50, -40}}, color = {0, 120, 120}));
        connect(impedance2.terminal_n, impedance3.terminal_p) annotation(Line(points = {{-50, -60}, {-50, -80}, {-10, -80}}, color = {0, 120, 120}));
        connect(impedance4.terminal_p, impedance5.terminal_n) annotation(Line(points = {{50, -40}, {50, -20}}, color = {0, 120, 120}));
        connect(fixedCurrent1.terminal, impedance1.terminal_n) annotation(Line(points = {{-70, -30}, {-50, -30}, {-50, -20}}, color = {0, 120, 120}));
        connect(fixedCurrent2.terminal, impedance3.terminal_p) annotation(Line(points = {{-70, -80}, {-10, -80}}, color = {0, 120, 120}));
        connect(fixedCurrent4.terminal, impedance5.terminal_n) annotation(Line(points = {{70, -30}, {50, -30}, {50, -20}}, color = {0, 120, 120}));
        connect(fixedVoltageSource1.terminal, transformer1.terminal_p) annotation(Line(points = {{-1.83697e-015, 60}, {-1.83697e-015, 50}, {-50, 50}, {-50, 40}}, color = {0, 120, 120}));
        connect(transformer1.terminal_n, impedance1.terminal_p) annotation(Line(points = {{-50, 20}, {-50, 0}}, color = {0, 120, 120}));
        connect(transformer2.terminal_n, impedance5.terminal_p) annotation(Line(points = {{50, 20}, {50, 0}}, color = {0, 120, 120}));
        connect(transformer2.terminal_p, fixedVoltageSource1.terminal) annotation(Line(points = {{50, 40}, {50, 50}, {-1.83697e-015, 50}, {-1.83697e-015, 60}}, color = {0, 120, 120}));
        connect(impedance3.terminal_n, fixedCurrent3.terminal) annotation(Line(points = {{10, -80}, {70, -80}}, color = {0, 120, 120}, smooth = Smooth.None));
        connect(impedance4.terminal_n, impedance3.terminal_n) annotation(Line(points = {{50, -60}, {50, -80}, {10, -80}}, color = {0, 120, 120}, smooth = Smooth.None));
        annotation(Documentation(info = "<html>
        <p>This textbook example demonstrates a basic power flow calculation.</p>
        <p>See Oeding, Oswald: Elektrische Kraftwerke und Netze, section 14.2.6: Leistungsfluss in Ringnetzen.</p>
      </html>"), experiment(StopTime = 1));
      end NetworkLoop;
      annotation(Documentation(info = "<html><p>The Network examples demonstrate the evolution of
      a simple powerflow calculation from a textbook to a dynamic simulation model with power/frequency control.
      </p></html>"));
    end Network;
  end Examples;

  package PhaseSystems  "Phase systems used in power connectors"
    extends Modelica.Icons.Package;

    partial package PartialPhaseSystem  "Base package of all phase systems"
      extends Modelica.Icons.Package;
      constant String phaseSystemName = "UnspecifiedPhaseSystem";
      constant Integer n "Number of independent voltage and current components";
      constant Integer m "Number of reference angles";
      type Voltage = Real(unit = "V", quantity = "Voltage." + phaseSystemName) "voltage for connector";
      type Current = Real(unit = "A", quantity = "Current." + phaseSystemName) "current for connector";
      type ReferenceAngle = Basic.Types.ReferenceAngle "Reference angle for connector";

      replaceable partial function j  "Return vector rotated by 90 degrees"
        extends Modelica.Icons.Function;
        input Real[n] x;
        output Real[n] y;
      end j;

      replaceable partial function thetaRel  "Return absolute angle of rotating system as offset to thetaRef"
        input .Modelica.SIunits.Angle[m] theta;
        output .Modelica.SIunits.Angle thetaRel;
      end thetaRel;

      replaceable partial function thetaRef  "Return absolute angle of rotating reference system"
        input .Modelica.SIunits.Angle[m] theta;
        output .Modelica.SIunits.Angle thetaRef;
      end thetaRef;

      replaceable partial function phase  "Return phase"
        extends Modelica.Icons.Function;
        input Real[n] x;
        output .Modelica.SIunits.Angle phase;
      end phase;

      replaceable partial function phaseVoltages  "Return phase to neutral voltages"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Voltage V "system voltage";
        input .Modelica.SIunits.Angle phi = 0 "phase angle";
        output .Modelica.SIunits.Voltage[n] v "phase to neutral voltages";
      end phaseVoltages;

      replaceable partial function phaseCurrents  "Return phase currents"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Current I "system current";
        input .Modelica.SIunits.Angle phi = 0 "phase angle";
        output .Modelica.SIunits.Current[n] i "phase currents";
      end phaseCurrents;

      replaceable partial function phasePowers_vi  "Return phase powers"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Voltage[n] v "phase voltages";
        input .Modelica.SIunits.Current[n] i "phase currents";
        output .Modelica.SIunits.Power[n] p "phase powers";
      end phasePowers_vi;

      replaceable partial function systemVoltage  "Return system voltage as function of phase voltages"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Voltage[n] v;
        output .Modelica.SIunits.Voltage V;
      end systemVoltage;

      replaceable partial function systemCurrent  "Return system current as function of phase currents"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Current[n] i;
        output .Modelica.SIunits.Current I;
      end systemCurrent;
    end PartialPhaseSystem;

    package ThreePhase_dq  "AC system, symmetrically loaded three phases"
      extends PartialPhaseSystem(phaseSystemName = "ThreePhase_dq", n = 2, m = 1);

      redeclare function j  "Return vector rotated by 90 degrees"
        extends Modelica.Icons.Function;
        input Real[n] x;
        output Real[n] y;
      algorithm
        y := {-x[2], x[1]};
      end j;

      redeclare function thetaRel  "Return absolute angle of rotating system as offset to thetaRef"
        input .Modelica.SIunits.Angle[m] theta;
        output .Modelica.SIunits.Angle thetaRel;
      algorithm
        thetaRel := 0;
      end thetaRel;

      redeclare function thetaRef  "Return absolute angle of rotating reference system"
        input .Modelica.SIunits.Angle[m] theta;
        output .Modelica.SIunits.Angle thetaRef;
      algorithm
        thetaRef := theta[1];
      end thetaRef;

      redeclare function phase  "Return phase"
        extends Modelica.Icons.Function;
        input Real[n] x;
        output .Modelica.SIunits.Angle phase;
      algorithm
        phase := atan2(x[2], x[1]);
      end phase;

      redeclare function phaseVoltages  "Return phase to neutral voltages"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Voltage V "system voltage";
        input .Modelica.SIunits.Angle phi = 0 "phase angle";
        output .Modelica.SIunits.Voltage[n] v "phase to neutral voltages";
      algorithm
        v := {V * cos(phi), V * sin(phi)} / sqrt(3);
      end phaseVoltages;

      redeclare function phaseCurrents  "Return phase currents"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Current I "system current";
        input .Modelica.SIunits.Angle phi = 0 "phase angle";
        output .Modelica.SIunits.Current[n] i "phase currents";
      algorithm
        i := {I * cos(phi), I * sin(phi)};
      end phaseCurrents;

      redeclare function phasePowers_vi  "Return phase powers"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Voltage[n] v "phase voltages";
        input .Modelica.SIunits.Current[n] i "phase currents";
        output .Modelica.SIunits.Power[n] p "phase powers";
      algorithm
        p := {v * i, -j(v) * i};
      end phasePowers_vi;

      redeclare function systemVoltage  "Return system voltage as function of phase voltages"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Voltage[n] v;
        output .Modelica.SIunits.Voltage V;
      algorithm
        V := sqrt(3 * v * v);
      end systemVoltage;

      redeclare function systemCurrent  "Return system current as function of phase currents"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.Current[n] i;
        output .Modelica.SIunits.Current I;
      algorithm
        I := sqrt(i * i);
      end systemCurrent;
      annotation(Icon(graphics = {Line(points = {{-70, 12}, {-58, 32}, {-38, 52}, {-22, 32}, {-10, 12}, {2, -8}, {22, -28}, {40, -8}, {50, 12}}, color = {95, 95, 95}, smooth = Smooth.Bezier), Line(points = {{-70, -70}, {50, -70}}, color = {95, 95, 95}, smooth = Smooth.None), Line(points = {{-70, -46}, {50, -46}}, color = {95, 95, 95}, smooth = Smooth.None)}));
    end ThreePhase_dq;
    annotation(Icon(graphics = {Line(points = {{-70, -52}, {50, -52}}, color = {95, 95, 95}, smooth = Smooth.None), Line(points = {{-70, 8}, {-58, 28}, {-38, 48}, {-22, 28}, {-10, 8}, {2, -12}, {22, -32}, {40, -12}, {50, 8}}, color = {95, 95, 95}, smooth = Smooth.Bezier)}));
  end PhaseSystems;

  package Generic  "Simple components for basic investigations"
    extends Modelica.Icons.VariantsPackage;

    model Impedance
      extends PowerSystems.Generic.Ports.PartialTwoTerminal;
      parameter .Modelica.SIunits.Resistance R = 1 "active component";
      parameter .Modelica.SIunits.Inductance L = 1 / 314 "reactive component";
      .Modelica.SIunits.AngularFrequency omegaRef;
    equation
      if PhaseSystem.m > 0 then
        omegaRef = der(PhaseSystem.thetaRef(terminal_p.theta));
      else
        omegaRef = 0;
      end if;
      v = R * i + omegaRef * L * j(i);
      zeros(PhaseSystem.n) = terminal_p.i + terminal_n.i;
      if PhaseSystem.m > 0 then
        terminal_p.theta = terminal_n.theta;
      end if;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-70, 30}, {70, -30}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-100, 0}, {-70, 0}}, color = {0, 120, 120}), Line(points = {{70, 0}, {100, 0}}, color = {0, 120, 120}), Text(extent = {{-150, -60}, {150, -100}}, lineColor = {0, 0, 0}, textString = "R=%R, L=%L"), Text(extent = {{-150, 60}, {150, 100}}, lineColor = {0, 0, 0}, textString = "%name"), Rectangle(extent = {{0, 10}, {66, -10}}, lineColor = {0, 120, 120}, fillColor = {0, 120, 120}, fillPattern = FillPattern.Solid)}));
    end Impedance;

    model VoltageConverter
      extends PowerSystems.Generic.Ports.PartialTwoTerminal;
      parameter Real ratio = 1 "conversion ratio terminal_p.v/terminal_n.v";
    equation
      terminal_p.v = ratio * terminal_n.v;
      zeros(PhaseSystem.n) = ratio * terminal_p.i + terminal_n.i;
      if PhaseSystem.m > 0 then
        terminal_p.theta = terminal_n.theta;
      end if;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {-70, 0}}, color = {0, 0, 0}), Line(points = {{70, 0}, {100, 0}}, color = {0, 0, 0}), Text(extent = {{-150, -60}, {150, -100}}, lineColor = {0, 0, 0}, textString = "%ratio"), Text(extent = {{-150, 60}, {150, 100}}, lineColor = {0, 0, 0}, textString = "%name"), Ellipse(extent = {{-80, 50}, {20, -50}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-20, 50}, {80, -50}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-80, 50}, {20, -50}}, lineColor = {0, 120, 120})}));
    end VoltageConverter;

    model FixedVoltageSource
      extends PowerSystems.Generic.Ports.PartialSource;
      parameter .Modelica.SIunits.Voltage V = 10e3 "value of constant voltage";
      .Modelica.SIunits.Angle thetaRel;
    protected
      outer System system;
    equation
      if PhaseSystem.m > 0 then
        if Connections.isRoot(terminal.theta) then
          PhaseSystem.thetaRef(terminal.theta) = system.theta;
          if PhaseSystem.m > 1 then
            PhaseSystem.thetaRel(terminal.theta) = 0;
          end if;
        end if;
        thetaRel = PhaseSystem.thetaRel(terminal.theta);
      else
        thetaRel = 0;
      end if;
      terminal.v = PhaseSystem.phaseVoltages(V, thetaRel);
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-90, 90}, {90, -90}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.CrossDiag), Text(extent = {{-150, 100}, {150, 140}}, lineColor = {0, 0, 0}, textString = "%name")}));
    end FixedVoltageSource;

    model FixedCurrent
      extends PowerSystems.Generic.Ports.PartialLoad;
      parameter Modelica.SIunits.Current I = 0 "rms value of constant current";
      parameter Modelica.SIunits.Angle phi = 0 "phase angle" annotation(Dialog(group = "Reference Parameters", enable = definiteReference));
    equation
      terminal.i = PhaseSystem.phaseCurrents(I, phi);
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-90, 90}, {90, -90}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-78, 22}, {80, 64}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, textString = "%I A"), Text(extent = {{-38, -74}, {38, -32}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, textString = "%phi"), Text(extent = {{-150, 100}, {150, 140}}, lineColor = {0, 0, 0}, textString = "%name")}));
    end FixedCurrent;

    package Ports  "Interfaces for generic components"
      extends Modelica.Icons.InterfacesPackage;

      connector Terminal_p  "Positive terminal"
        extends PowerSystems.Interfaces.Terminal;
        annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{60, 60}, {-60, 60}, {-60, -60}, {60, -60}, {60, 60}}, lineColor = {0, 120, 120}, fillColor = {0, 120, 120}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 60}, {150, 100}}, lineColor = {0, 0, 0}, textString = "%name")}), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{100, 100}, {-100, 100}, {-100, -100}, {100, -100}, {100, 100}}, lineColor = {0, 120, 120}, fillColor = {0, 120, 120}, fillPattern = FillPattern.Solid)}));
      end Terminal_p;

      connector Terminal_n  "Negative terminal"
        extends PowerSystems.Interfaces.Terminal;
        annotation(Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-150, 60}, {150, 100}}, lineColor = {0, 0, 0}, textString = "%name"), Rectangle(extent = {{-60, 60}, {60, -60}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 120, 120}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}));
      end Terminal_n;

      partial model PartialTwoTerminal
        replaceable package PhaseSystem = PackagePhaseSystem constrainedby PowerSystems.PhaseSystems.PartialPhaseSystem;
        function j = PhaseSystem.j;
        parameter .Modelica.SIunits.Voltage[PhaseSystem.n] v_start = zeros(PhaseSystem.n) "Start value for voltage drop" annotation(Dialog(tab = "Initialization"));
        parameter .Modelica.SIunits.Current[PhaseSystem.n] i_start = zeros(PhaseSystem.n) "Start value for current" annotation(Dialog(tab = "Initialization"));
        PowerSystems.Generic.Ports.Terminal_p terminal_p(redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
        PowerSystems.Generic.Ports.Terminal_n terminal_n(redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
        .Modelica.SIunits.Voltage[PhaseSystem.n] v(start = v_start);
        .Modelica.SIunits.Current[PhaseSystem.n] i(start = i_start);
        .Modelica.SIunits.Power[PhaseSystem.n] S = PhaseSystem.phasePowers_vi(v, i);
        .Modelica.SIunits.Voltage V = PhaseSystem.systemVoltage(v);
        .Modelica.SIunits.Current I = PhaseSystem.systemCurrent(i);
        .Modelica.SIunits.Angle phi = PhaseSystem.phase(v) - PhaseSystem.phase(i);
      equation
        v = terminal_p.v - terminal_n.v;
        i = terminal_p.i;
        if true or PhaseSystem.m > 0 then
          Connections.branch(terminal_p.theta, terminal_n.theta);
        end if;
      end PartialTwoTerminal;

      partial model PartialSource
        replaceable package PhaseSystem = PackagePhaseSystem constrainedby PowerSystems.PhaseSystems.PartialPhaseSystem;
        PowerSystems.Generic.Ports.Terminal_n terminal(redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
        .Modelica.SIunits.Power[PhaseSystem.n] S = PhaseSystem.phasePowers_vi(terminal.v, terminal.i);
        .Modelica.SIunits.Angle phi = PhaseSystem.phase(terminal.v) - PhaseSystem.phase(-terminal.i);
        parameter Boolean potentialReference = true "serve as potential root" annotation(Evaluate = true, Dialog(group = "Reference Parameters"));
        parameter Boolean definiteReference = false "serve as definite root" annotation(Evaluate = true, Dialog(group = "Reference Parameters"));
      equation
        if true or PhaseSystem.m > 0 then
          if potentialReference then
            if definiteReference then
              Connections.root(terminal.theta);
            else
              Connections.potentialRoot(terminal.theta);
            end if;
          end if;
        end if;
      end PartialSource;

      partial model PartialLoad
        replaceable package PhaseSystem = PackagePhaseSystem constrainedby PowerSystems.PhaseSystems.PartialPhaseSystem;
        PowerSystems.Generic.Ports.Terminal_p terminal(redeclare package PhaseSystem = PhaseSystem) annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
        .Modelica.SIunits.Voltage[:] v = terminal.v;
        .Modelica.SIunits.Current[:] i = terminal.i;
        .Modelica.SIunits.Power[PhaseSystem.n] S = PhaseSystem.phasePowers_vi(v, i);
      end PartialLoad;
    end Ports;
  end Generic;

  package Basic  "Basic utility classes"
    extends Modelica.Icons.BasesPackage;

    package Types
      extends Modelica.Icons.Package;

      type ReferenceAngle  "Reference angle"
        extends .Modelica.SIunits.Angle;

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

      type AngularVelocity = .Modelica.SIunits.AngularVelocity(displayUnit = "rpm");
    end Types;
  end Basic;

  package Interfaces
    extends Modelica.Icons.InterfacesPackage;

    connector Terminal  "General power terminal"
      replaceable package PhaseSystem = PhaseSystems.PartialPhaseSystem "Phase system" annotation(choicesAllMatching = true);
      PhaseSystem.Voltage[PhaseSystem.n] v "voltage vector";
      flow PhaseSystem.Current[PhaseSystem.n] i "current vector";
      PhaseSystem.ReferenceAngle[PhaseSystem.m] theta "optional vector of phase angles";
    end Terminal;

    connector Frequency  "Weighted frequency"
      flow .Modelica.SIunits.Time H "inertia constant";
      flow .Modelica.SIunits.Angle w_H "angular velocity, inertia-weighted";
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
  annotation(preferredView = "info", version = "0.3", versionDate = "2014-10-20", Documentation(info = "<html>
<p>The Modelica PowerSystems library is intended for the modeling of electrical <b>power systems</b> at different <b>levels of detail</b> both in <b>transient</b> and <b>steady-state</b> mode.</p>
<p>The Users Guide to the library is <a href=\"modelica://PowerSystems.UsersGuide\"><b>here</b></a>.</p>
<p><br/>Copyright &copy; 2007-2014, Modelica Association. </p>
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
"), uses(Modelica(version = "3.2.1")), Icon(graphics = {Line(points = {{-60, -16}, {38, -16}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{-60, -16}, {-60, -42}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{38, -16}, {38, -42}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{-10, 10}, {-10, -16}}, color = {0, 0, 0}, smooth = Smooth.None), Ellipse(extent = {{-20, 30}, {0, 10}}, lineColor = {0, 0, 0}), Ellipse(extent = {{-20, 42}, {0, 22}}, lineColor = {0, 0, 0}), Ellipse(extent = {{-70, -42}, {-50, -62}}, lineColor = {0, 0, 0}), Ellipse(extent = {{28, -42}, {48, -62}}, lineColor = {0, 0, 0}), Line(points = {{-10, 52}, {-10, 42}}, color = {0, 0, 0}, smooth = Smooth.None)}));
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
  annotation(Protection(access = Access.hide), preferredView = "info", version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z", revisionId = "$Id:: package.mo 6931 2013-08-14 11:38:51Z #$", uses(Modelica(version = "3.2.1")), conversion(noneFromVersion = "1.0", noneFromVersion = "1.1", noneFromVersion = "1.2"), Documentation(info = "<html>
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
<b>Licensed by DLR and Dassault Syst&egrave;mes AB under the Modelica License 2</b><br>
Copyright &copy; 2009-2013, DLR and Dassault Syst&egrave;mes AB.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

</html>"));
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 3)"
  extends Modelica.Icons.Package;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
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
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
      <p>
      This function returns y = asin(u), with -1 &le; u &le; +1:
      </p>

      <p>
      <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
      </p>
      </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = asin(u), with -1 &le; u &le; +1:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
    </p>
    </html>"));
    end asin;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
      <p>
      This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
      </p>

      <p>
      <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
      </p>
      </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
    </p>
    </html>"));
    end exp;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.4}, {-49.4, 74.6}, {-43.8, 79.1}, {-38.2, 79.8}, {-32.6, 76.6}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.1}, {35, -78.4}, {40.6, -80}, {46.2, -77.6}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}), Documentation(info = "<HTML>
  <p>
  This package contains <b>basic mathematical functions</b> (such as sin(..)),
  as well as functions operating on
  <a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
  <a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
  <a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
  <a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
  </p>

  <dl>
  <dt><b>Main Authors:</b>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
      Marcus Baur<br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
      Institut f&uuml;r Robotik und Mechatronik<br>
      Postfach 1116<br>
      D-82230 Wessling<br>
      Germany<br>
      email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
  </dl>

  <p>
  Copyright &copy; 1998-2013, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>October 21, 2002</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
         and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
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
      extends Modelica.Icons.Package;

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
      annotation(Documentation(info = "<HTML>
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
    </HTML>"));
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
  Copyright &copy; 1998-2013, Modelica Association, DLR, and Dassault Syst&egrave;mes AB.
  </p>

  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>

  </html>"));
  end Utilities;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
    annotation(Documentation(info = "<html>
  <p>
  This package provides often needed constants from mathematics, machine
  dependent constants and constants from nature. The latter constants
  (name, value, description) are from the following source:
  </p>

  <dl>
  <dt>Peter J. Mohr and Barry N. Taylor (1999):</dt>
  <dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
      Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
      Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also <a href=
  \"http://physics.nist.gov/cuu/Constants/\">http://physics.nist.gov/cuu/Constants/</a></dd>
  </dl>

  <p>CODATA is the Committee on Data for Science and Technology.</p>

  <dl>
  <dt><b>Main Author:</b></dt>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
      Oberpfaffenhofen<br>
      Postfach 11 16<br>
      D-82230 We&szlig;ling<br>
      email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  </dl>

  <p>
  Copyright &copy; 1998-2013, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>Nov 8, 2004</i>
         by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
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

    partial model Example  "Icon for runnable examples"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {75, 138, 73}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Polygon(lineColor = {0, 0, 255}, fillColor = {75, 138, 73}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-36, 60}, {64, 0}, {-36, -60}, {-36, 60}})}), Documentation(info = "<html>
    <p>This icon indicates an example. The play button suggests that the example can be executed.</p>
    </html>")); end Example;

    partial package Package  "Icon for standard packages"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {248, 248, 248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Rectangle(lineColor = {128, 128, 128}, fillPattern = FillPattern.None, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0)}), Documentation(info = "<html>
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
    <p>This icon shall be used for a package/library that contains several variants of one components.</p>
    </html>"));
    end VariantsPackage;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {20.0, 0.0}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-10.0, 70.0}, {10.0, 70.0}, {40.0, 20.0}, {80.0, 20.0}, {80.0, -20.0}, {40.0, -20.0}, {10.0, -70.0}, {-10.0, -70.0}}), Polygon(fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-100.0, 20.0}, {-60.0, 20.0}, {-30.0, 70.0}, {-10.0, 70.0}, {-10.0, -70.0}, {-30.0, -70.0}, {-60.0, -20.0}, {-100.0, -20.0}})}), Documentation(info = "<html>
    <p>This icon indicates packages containing interfaces.</p>
    </html>"));
    end InterfacesPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}));
    end IconsPackage;

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {215, 215, 215}, fillColor = {255, 255, 255}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100, -100}, {100, 100}}, radius = 25), Rectangle(lineColor = {215, 215, 215}, fillPattern = FillPattern.None, extent = {{-100, -100}, {100, 100}}, radius = 25), Ellipse(extent = {{-80, 80}, {80, -80}}, lineColor = {215, 215, 215}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-55, 55}, {55, -55}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-60, 14}, {60, -14}}, lineColor = {215, 215, 215}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid, origin = {0, 0}, rotation = 45)}), Documentation(info = "<html>

    <p>
    This icon shall be used for a package that contains internal classes not to be
    directly utilized by a user.
    </p>
    </html>")); end InternalPackage;

    partial function Function  "Icon for functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 105}, {150, 145}}, textString = "%name"), Ellipse(lineColor = {108, 88, 49}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Text(lineColor = {108, 88, 49}, extent = {{-90.0, -90.0}, {90.0, 90.0}}, textString = "f")}), Documentation(info = "<html>
    <p>This icon indicates Modelica functions.</p>
    </html>")); end Function;
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
      <dd><a href=\"http://christiankral.net/\">Electric Machines, Drives and Systems</a></dd>
      <dd>1060 Vienna, Austria</dd>
      <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
  <dt>Johan Andreasson</dt>
      <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>
      <dd>Ideon Science Park</dd>
      <dd>22370 Lund, Sweden</dd>
      <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
  </dl>

  <p>Copyright &copy; 1998-2013, Modelica Association, DLR, AIT, and Modelon AB. </p>
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
        annotation(Documentation(info = "<HTML>
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
      annotation(Documentation(info = "<HTML>
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
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type AngularFrequency = Real(final quantity = "AngularFrequency", final unit = "rad/s");
    type Power = Real(final quantity = "Power", final unit = "W");
    type ElectricCurrent = Real(final quantity = "ElectricCurrent", final unit = "A");
    type Current = ElectricCurrent;
    type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
    type Voltage = ElectricPotential;
    type Inductance = Real(final quantity = "Inductance", final unit = "H");
    type Resistance = Real(final quantity = "Resistance", final unit = "Ohm");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-66, 78}, {-66, -40}}, color = {64, 64, 64}, smooth = Smooth.None), Ellipse(extent = {{12, 36}, {68, -38}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-74, 78}, {-66, -40}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-66, -4}, {-66, 6}, {-16, 56}, {-16, 46}, {-66, -4}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-46, 16}, {-40, 22}, {-2, -40}, {-10, -40}, {-46, 16}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Ellipse(extent = {{22, 26}, {58, -28}}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{68, 2}, {68, -46}, {64, -60}, {58, -68}, {48, -72}, {18, -72}, {18, -64}, {46, -64}, {54, -60}, {58, -54}, {60, -46}, {60, -26}, {64, -20}, {68, -6}, {68, 2}}, lineColor = {64, 64, 64}, smooth = Smooth.Bezier, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
  <p>This package provides predefined types, such as <i>Mass</i>,
  <i>Angle</i>, <i>Time</i>, based on the international standard
  on units, e.g.,
  </p>

  <pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                       <b>final</b> unit     = \"rad\",
                       displayUnit    = \"deg\");
  </pre>

  <p>
  as well as conversion functions from non SI-units to SI-units
  and vice versa in subpackage
  <a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
  </p>

  <p>
  For an introduction how units are used in the Modelica standard library
  with package SIunits, have a look at:
  <a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
  </p>

  <p>
  Copyright &copy; 1998-2013, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added molar units for energy and enthalpy.</li>
  <li><i>Jan. 27, 2010</i> by Christian Kral:<br/>Added complex units.</li>
  <li><i>Dec. 14, 2005</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
  <li><i>October 21, 2002</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br/>Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
  <li><i>June 6, 2000</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
  <li><i>Oct. 27, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
  <li><i>Sept. 18, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
  <li><i>Aug 12, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
  <li><i>June 29, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
  <li><i>April 8, 1998</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
  <li><i>Nov. 15, 1997</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br/>Some chapters realized.</li>
  </ul>
  </html>"));
  end SIunits;
  annotation(preferredView = "info", version = "3.2.1", versionBuild = 3, versionDate = "2013-08-14", dateModified = "2014-06-27 19:30:00Z", revisionId = "$Id:: package.mo 7762 2014-06-27 09:35:59Z #$", uses(Complex(version = "3.2.1"), ModelicaServices(version = "3.2.1")), conversion(noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-6.9888, 20.048}, fillColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112, 10.3188}, {-93.0112, 10.3188}, {-73.011, 24.6}, {-63.011, 31.221}, {-51.219, 36.777}, {-39.842, 38.629}, {-31.376, 36.248}, {-25.819, 29.369}, {-24.232, 22.49}, {-23.703, 17.463}, {-15.501, 25.135}, {-6.24, 32.015}, {3.02, 36.777}, {15.191, 39.423}, {27.097, 37.306}, {32.653, 29.633}, {35.035, 20.108}, {43.501, 28.046}, {54.085, 35.19}, {65.991, 39.952}, {77.897, 39.688}, {87.422, 33.338}, {91.126, 21.696}, {90.068, 9.525}, {86.099, -1.058}, {79.749, -10.054}, {71.283, -21.431}, {62.816, -33.337}, {60.964, -32.808}, {70.489, -16.14}, {77.368, -2.381}, {81.072, 10.054}, {79.749, 19.05}, {72.605, 24.342}, {61.758, 23.019}, {49.587, 14.817}, {39.003, 4.763}, {29.214, -6.085}, {21.012, -16.669}, {13.339, -26.458}, {5.401, -36.777}, {-1.213, -46.037}, {-6.24, -53.446}, {-8.092, -52.387}, {-0.684, -40.746}, {5.401, -30.692}, {12.81, -17.198}, {19.424, -3.969}, {23.658, 7.938}, {22.335, 18.785}, {16.514, 23.283}, {8.047, 23.019}, {-1.478, 19.05}, {-11.267, 11.113}, {-19.734, 2.381}, {-29.259, -8.202}, {-38.519, -19.579}, {-48.044, -31.221}, {-56.511, -43.392}, {-64.449, -55.298}, {-72.386, -66.939}, {-77.678, -74.612}, {-79.53, -74.083}, {-71.857, -61.383}, {-62.861, -46.037}, {-52.278, -28.046}, {-44.869, -15.346}, {-38.784, -2.117}, {-35.344, 8.731}, {-36.403, 19.844}, {-42.488, 23.813}, {-52.013, 22.49}, {-60.744, 16.933}, {-68.947, 10.054}, {-76.884, 2.646}, {-93.0112, -12.1707}, {-93.0112, -12.1707}}, smooth = Smooth.Bezier), Ellipse(origin = {40.8208, -37.7602}, fillColor = {161, 0, 4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562, -17.8563}, {17.8563, 17.8562}})}), Documentation(info = "<HTML>
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
<li><b>1360</b> models and blocks, and</li>
<li><b>1280</b> functions</li>
</ul>
<p>
that are directly usable (= number of public, non-partial classes). It is fully compliant
to <a href=\"https://www.modelica.org/documents/ModelicaSpec32Revision2.pdf\">Modelica Specification Version 3.2 Revision 2</a>
and it has been tested with Modelica tools from different vendors.
</p>

<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 1998-2013, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, Fraunhofer, A.&nbsp;Haumer, ITI, C.&nbsp;Kral, Modelon,
TU Hamburg-Harburg, Politecnico di Milano, XRG Simulation.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

<p>
<b>Modelica&reg;</b> is a registered trademark of the Modelica Association.
</p>
</html>"));
end Modelica;

model NetworkLoop_total  "Simple textbook example for a steady-state power flow calculation"
  extends PowerSystems.Examples.Network.NetworkLoop;
 annotation(Documentation(info = "<html>
  <p>This textbook example demonstrates a basic power flow calculation.</p>
  <p>See Oeding, Oswald: Elektrische Kraftwerke und Netze, section 14.2.6: Leistungsfluss in Ringnetzen.</p>
</html>"), experiment(StopTime = 1));
end NetworkLoop_total;
