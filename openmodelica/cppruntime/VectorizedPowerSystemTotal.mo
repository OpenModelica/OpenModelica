model VectorizedPowerSystemTest
  import SI = Modelica.SIunits;
  parameter Integer n = 3 "number of loads";

  model BusBar
    replaceable package PhaseSystem = PowerSystems.PackagePhaseSystem constrainedby PowerSystems.PhaseSystems.PartialPhaseSystem;
    package PS = PhaseSystem;
    parameter PS.Voltage[PhaseSystem.n] v_start = zeros(PhaseSystem.n) "Start value for voltage drop";
    parameter PS.Current[PhaseSystem.n] i_start = zeros(PhaseSystem.n) "Start value for current";
    parameter Integer n_n = n;
    PowerSystems.Generic.Ports.Terminal_p terminal_p(redeclare package PhaseSystem = PhaseSystem);
    PowerSystems.Generic.Ports.Terminal_n[n_n] terminal_n(redeclare each package PhaseSystem = PhaseSystem);
    PS.Voltage[PhaseSystem.n] v(start = v_start) = terminal_p.v;
    PS.Current[PhaseSystem.n] i(start = i_start) = terminal_p.i;
    SI.Power[PhaseSystem.n] p = PhaseSystem.phasePowers_vi(v, i);
    PS.Voltage V = PhaseSystem.systemVoltage(v);
    PS.Current I = PhaseSystem.systemCurrent(i);
    SI.Angle phi = PhaseSystem.phase(v) - PhaseSystem.phase(i);
  equation
    terminal_n.v = fill(terminal_p.v, n_n);
    //terminal_p.i = sum(terminal_n[i].i for i in 1:n_n);
    for i in 1:PS.n loop
      terminal_p.i[i] = -sum(terminal_n[:].i[i]);
    end for;
    //Connections.branch(terminal_p.theta, terminal_n.theta);
  end BusBar;

  PowerSystems.Generic.FixedVoltageSource fixedVoltageSource1;
  inner PowerSystems.System system;
  PowerSystems.Generic.FixedLoad[n] fixedLoad1(P = 1e6:1e6:1e6 * n, phi = 0.1:0.1:0.1 * n);
  BusBar busBar1;
equation
  connect(busBar1.terminal_n, fixedLoad1.terminal);
  connect(fixedVoltageSource1.terminal, busBar1.terminal_p);
end VectorizedPowerSystemTest;

package PowerSystems  "Library for electrical power systems"
  extends Modelica.Icons.Package;
  import Modelica.Constants.pi;
  import PowerSystems.Types.SI;
  import PowerSystems.Types.SIpu;
  replaceable package PackagePhaseSystem = PhaseSystems.ThreePhase_d "Default phase system" annotation(choicesAllMatching = true);

  model System  "System reference"
    parameter Types.SystemFrequency fType = PowerSystems.Types.SystemFrequency.Parameter "system frequency type" annotation(Evaluate = true);
    parameter SI.Frequency f = f_nom "frequency if type is parameter, else initial frequency" annotation(Evaluate = true);
    parameter SI.Frequency f_nom = 50 "nominal frequency" annotation(Evaluate = true);
    parameter SI.Frequency[2] f_lim = {0.5 * f_nom, 2 * f_nom} "limit frequencies (for supervision of average frequency)" annotation(Evaluate = true);
    parameter SI.Angle alpha0 = 0 "phase angle" annotation(Evaluate = true);
    parameter Types.ReferenceFrame refType = PowerSystems.Types.ReferenceFrame.Synchron "reference frame (3-phase)" annotation(Evaluate = true);
    parameter Types.Dynamics dynType = PowerSystems.Types.Dynamics.SteadyInitial "transient or steady-state model" annotation(Evaluate = true);
    final parameter SI.AngularFrequency omega_nom = 2 * pi * f_nom "nominal angular frequency" annotation(Evaluate = true);
    final parameter SI.AngularVelocity w_nom = 2 * pi * f_nom "nom r.p.m." annotation(Evaluate = true);
    final parameter Boolean synRef = refType == PowerSystems.Types.ReferenceFrame.Synchron or dynType == PowerSystems.Types.Dynamics.SteadyState annotation(Evaluate = true);
    discrete SI.Time initime;
    SI.Angle theta(final start = 0, stateSelect = if fType == Types.SystemFrequency.Parameter then StateSelect.default else StateSelect.always) "system angle";
    SI.Angle thetaRel = theta - thetaRef "angle relative to reference frame";
    SI.Angle thetaRef = if synRef then theta else 0 "angle of reference frame";
    SI.AngularFrequency omega(final start = 2 * pi * f);
    Modelica.Blocks.Interfaces.RealInput omega_in(min = 0) if fType == PowerSystems.Types.SystemFrequency.Signal "system angular frequency (optional if fType==Signal)";
    Interfaces.Frequency receiveFreq "receives weighted frequencies from generators";
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
    annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "No \"system\" component is defined.
      Drag PowerSystems.System into the top level of your model.");
  end System;

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

      replaceable partial function thetaRel  "Return absolute angle of rotating system as offset to thetaRef"
        input SI.Angle[m] theta;
        output SI.Angle thetaRel;
      end thetaRel;

      replaceable partial function theta  "Return angle of rotating reference system"
        input SI.Angle thetaRel;
        input SI.Angle thetaRef;
        output SI.Angle[m] theta;
      end theta;

      replaceable partial function phase  "Return phase"
        extends Modelica.Icons.Function;
        input Real[n] x;
        output SI.Angle phase;
      end phase;

      replaceable partial function phaseVoltages  "Return phase voltages"
        extends Modelica.Icons.Function;
        input Voltage V "system voltage";
        input SI.Angle phi = 0 "phase angle";
        output Voltage[n] v "phase voltages";
      end phaseVoltages;

      replaceable partial function phasePowers  "Return phase powers"
        extends Modelica.Icons.Function;
        input SI.ActivePower P "active system power";
        input SI.Angle phi = 0 "phase angle";
        output SI.Power[n] p "phase powers";
      end phasePowers;

      replaceable partial function phasePowers_vi  "Return phase powers"
        extends Modelica.Icons.Function;
        input Voltage[n] v "phase voltages";
        input Current[n] i "phase currents";
        output SI.Power[n] p "phase powers";
      end phasePowers_vi;

      replaceable partial function systemVoltage  "Return system voltage as function of phase voltages"
        extends Modelica.Icons.Function;
        input Voltage[n] v;
        output Voltage V;
      end systemVoltage;

      replaceable partial function systemCurrent  "Return system current as function of phase currents"
        extends Modelica.Icons.Function;
        input Current[n] i;
        output Current I;
      end systemCurrent;
    end PartialPhaseSystem;

    package DirectCurrent  "DC system"
      extends PartialPhaseSystem(phaseSystemName = "DirectCurrent", n = 1, m = 0);

      redeclare function thetaRel  "Return absolute angle of rotating system as offset to thetaRef"
        input SI.Angle[m] theta;
        output SI.Angle thetaRel;
      algorithm
        thetaRel := 0;
        annotation(Inline = true);
      end thetaRel;

      redeclare function theta  "Return angle of rotating reference system"
        input SI.Angle thetaRel;
        input SI.Angle thetaRef;
        output SI.Angle[m] theta;
      algorithm
        theta := zeros(m);
        annotation(Inline = true);
      end theta;

      redeclare function phase  "Return phase"
        extends Modelica.Icons.Function;
        input Real[n] x;
        output SI.Angle phase;
      algorithm
        phase := 0;
        annotation(Inline = true);
      end phase;

      redeclare replaceable function phaseVoltages  "Return phase voltages"
        extends Modelica.Icons.Function;
        input Voltage V "system voltage";
        input SI.Angle phi = 0 "phase angle";
        output Voltage[n] v "phase voltages";
      algorithm
        v := {V};
        annotation(Inline = true);
      end phaseVoltages;

      redeclare function phasePowers  "Return phase powers"
        extends Modelica.Icons.Function;
        input SI.ActivePower P "active system power";
        input SI.Angle phi = 0 "phase angle";
        output SI.Power[n] p "phase powers";
      algorithm
        p := {P};
        annotation(Inline = true);
      end phasePowers;

      redeclare function phasePowers_vi  "Return phase powers"
        extends Modelica.Icons.Function;
        input Voltage[n] v "phase voltages";
        input Current[n] i "phase currents";
        output SI.Power[n] p "phase powers";
      algorithm
        p := {v * i};
        annotation(Inline = true);
      end phasePowers_vi;

      redeclare replaceable function systemVoltage  "Return system voltage as function of phase voltages"
        extends Modelica.Icons.Function;
        input Voltage[n] v;
        output Voltage V;
      algorithm
        V := v[1];
        annotation(Inline = true);
      end systemVoltage;

      redeclare function systemCurrent  "Return system current as function of phase currents"
        extends Modelica.Icons.Function;
        input Current[n] i;
        output Current I;
      algorithm
        I := i[1];
        annotation(Inline = true);
      end systemCurrent;
    end DirectCurrent;

    package ThreePhase_d  "AC system covering only resistive loads with three symmetric phases"
      extends DirectCurrent(phaseSystemName = "ThreePhase_d");

      redeclare function phaseVoltages  "Return phase voltages"
        extends Modelica.Icons.Function;
        input Voltage V "system voltage";
        input SI.Angle phi = 0 "phase angle";
        output Voltage[n] v "phase voltages";
      algorithm
        v := {V};
        annotation(Inline = true);
      end phaseVoltages;

      redeclare function systemVoltage  "Return system voltage as function of phase voltages"
        extends Modelica.Icons.Function;
        input Voltage[n] v;
        output Voltage V;
      algorithm
        V := v[1];
        annotation(Inline = true);
      end systemVoltage;
    end ThreePhase_d;
  end PhaseSystems;

  package Generic  "Simple components for basic investigations"
    extends Modelica.Icons.VariantsPackage;

    model FixedVoltageSource
      extends PowerSystems.Generic.Ports.PartialVoltageSource;
      parameter PS.Voltage V = 10e3 "value of constant voltage";
    equation
      terminal.v = PhaseSystem.phaseVoltages(V, PhaseSystem.thetaRel(terminal.theta));
    end FixedVoltageSource;

    model FixedLoad
      extends PowerSystems.Generic.Ports.PartialLoad;
      parameter SI.Power P = 0 "rms value of constant active power";
      parameter SI.Angle phi = 0 "phase angle";
    equation
      PhaseSystem.phasePowers_vi(terminal.v, terminal.i) = PhaseSystem.phasePowers(P, phi);
    end FixedLoad;

    package Ports  "Interfaces for generic components"
      extends Modelica.Icons.InterfacesPackage;

      connector Terminal_p  "Positive terminal"
        extends PowerSystems.Interfaces.Terminal;
      end Terminal_p;

      connector Terminal_n  "Negative terminal"
        extends PowerSystems.Interfaces.Terminal;
      end Terminal_n;

      partial model PartialSource
        replaceable package PhaseSystem = PackagePhaseSystem constrainedby PowerSystems.PhaseSystems.PartialPhaseSystem;
        package PS = PhaseSystem;
        PowerSystems.Generic.Ports.Terminal_n terminal(redeclare package PhaseSystem = PhaseSystem);
        SI.Power[PhaseSystem.n] p = PhaseSystem.phasePowers_vi(terminal.v, terminal.i);
        SI.Angle phi = PhaseSystem.phase(terminal.v) - PhaseSystem.phase(-terminal.i);
        parameter Boolean potentialReference = true "serve as potential root" annotation(Evaluate = true);
        parameter Boolean definiteReference = false "serve as definite root" annotation(Evaluate = true);
      end PartialSource;

      partial model PartialVoltageSource
        extends PartialSource;
      protected
        outer System system;
      equation
        if potentialReference then
          if definiteReference then
            Connections.root(terminal.theta);
          else
            Connections.potentialRoot(terminal.theta);
          end if;
        end if;
        if Connections.isRoot(terminal.theta) then
          terminal.theta = PhaseSystem.theta(system.thetaRel, system.thetaRef);
        end if;
      end PartialVoltageSource;

      partial model PartialLoad
        replaceable package PhaseSystem = PackagePhaseSystem constrainedby PowerSystems.PhaseSystems.PartialPhaseSystem;
        package PS = PhaseSystem;
        parameter PS.Voltage[PhaseSystem.n] v_start = ones(PhaseSystem.n) "Start value for voltage drop";
        PowerSystems.Generic.Ports.Terminal_p terminal(redeclare package PhaseSystem = PhaseSystem, v(start = v_start));
        SI.Power[PhaseSystem.n] p = PhaseSystem.phasePowers_vi(terminal.v, terminal.i);
      end PartialLoad;
    end Ports;
  end Generic;

  package Interfaces
    extends Modelica.Icons.InterfacesPackage;

    connector Terminal  "General power terminal"
      replaceable package PhaseSystem = PhaseSystems.PartialPhaseSystem "Phase system" annotation(choicesAllMatching = true);
      PhaseSystem.Voltage[PhaseSystem.n] v "voltage vector";
      flow PhaseSystem.Current[PhaseSystem.n] i "current vector";
      PhaseSystem.ReferenceAngle[PhaseSystem.m] theta "optional vector of phase angles";
    end Terminal;

    connector Frequency  "Weighted frequency"
      flow SI.Time H "inertia constant";
      flow SI.Angle w_H "angular velocity, inertia-weighted";
      Real h "Dummy potential-variable to balance flow-variable H";
      Real w_h "Dummy potential-variable to balance flow-variable w_H";
    end Frequency;
  end Interfaces;

  package Types
    extends Modelica.Icons.TypesPackage;

    package SI  "SI types with custom attributes, like display units"
      extends Modelica.Icons.Package;
      import MSI = Modelica.SIunits;
      type Time = MSI.Time;
      type Frequency = MSI.Frequency;
      type Angle = MSI.Angle;
      type AngularVelocity = MSI.AngularVelocity(displayUnit = "rpm");
      type AngularFrequency = MSI.AngularFrequency;
      type Voltage = MSI.Voltage(displayUnit = "kV");
      type Current = MSI.Current;
      type Power = MSI.Power(displayUnit = "MW");
      type ActivePower = MSI.ActivePower(displayUnit = "MW");
    end SI;

    type SystemFrequency = enumeration(Parameter "Parameter f", Signal "Signal omega_in", Average "Average generators") "Options for specification of frequency in system object";
    type ReferenceFrame = enumeration(Synchron "Synchronously rotating", Inertial "Inertial (signals oscillate)") "Options for specification of reference frame";
    type Dynamics = enumeration(FreeInitial "Free initial conditions", FixedInitial "Fixed initial conditions", SteadyInitial "Steady-state initial conditions", SteadyState "Steady-state (quasi-stationary)") "Options for specification of simulation";

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
    end ReferenceAngle;
  end Types;
  annotation(version = "1.0.0", versionDate = "2018-11-12");
end PowerSystems;

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package ExternalReferences  "Library of functions to access external resources"
    extends Modelica.Icons.Package;

    function loadResource  "Return the absolute path name of a URI or local file name (in this default implementation URIs are not supported, but only local file names)"
      extends Modelica.Utilities.Internal.PartialModelicaServices.ExternalReferences.PartialLoadResource;
    algorithm
      fileReference := OpenModelica.Scripting.uriToFilename(uri);
    end loadResource;
  end ExternalReferences;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1.e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1.e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(Protection(access = Access.hide), version = "3.2.2", versionBuild = 0, versionDate = "2016-01-15", dateModified = "2016-01-15 08:44:41Z");
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.2"
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks"
      import Modelica.SIunits;
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
    end Interfaces;
  end Blocks;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output SI.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
    end exp;
  end Math;

  package Utilities  "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)"
    extends Modelica.Icons.Package;

    package Files  "Functions to work with files and directories"
      extends Modelica.Icons.FunctionsPackage;

      function loadResource  "Return the absolute path name of a URI or local file name"
        extends Modelica.Utilities.Internal.PartialModelicaServices.ExternalReferences.PartialLoadResource;
        extends ModelicaServices.ExternalReferences.loadResource;
      end loadResource;
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
          end PartialLoadResource;
        end ExternalReferences;
      end PartialModelicaServices;
    end Internal;
  end Utilities;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Modelica.Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package Package  "Icon for standard packages" end Package;

    partial package VariantsPackage  "Icon for package containing variants"
      extends Modelica.Icons.Package;
    end VariantsPackage;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package TypesPackage  "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package FunctionsPackage  "Icon for packages containing functions"
      extends Modelica.Icons.Package;
    end FunctionsPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)" end InternalPackage;

    partial function Function  "Icon for functions" end Function;
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
      end NonSIunits;
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
    type ActivePower = Real(final quantity = "Power", final unit = "W");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
  annotation(version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z");
end Modelica;
