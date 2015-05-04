package PowerSystems  "Library for electrical power systems"
  extends Modelica.Icons.Package;

  model System  "System reference"
    parameter .Modelica.SIunits.Frequency f_nom = 50 "nominal frequency" annotation(Evaluate = true);
    parameter .Modelica.SIunits.Frequency f = f_nom "frequency if fType_par = true, else initial frequency" annotation(Evaluate = true);
    parameter Boolean fType_par = true "= true, if system frequency defined by parameter f, else average frequency" annotation(Evaluate = true);
    parameter .Modelica.SIunits.Frequency[2] f_lim = {0.5 * f_nom, 2 * f_nom} "limit frequencies (for supervision of average frequency)" annotation(Evaluate = true);
    parameter .Modelica.SIunits.Angle alpha0 = 0 "phase angle" annotation(Evaluate = true);
    parameter String ref = "synchron" "reference frame (3-phase)" annotation(Evaluate = true);
    parameter String ini = "st" "transient or steady-state initialisation" annotation(Evaluate = true);
    parameter String sim = "tr" "transient or steady-state simulation" annotation(Evaluate = true);
    final parameter .Modelica.SIunits.AngularFrequency omega_nom = 2 * .Modelica.Constants.pi * f_nom "nominal angular frequency" annotation(Evaluate = true);
    final parameter .PowerSystems.Basic.Types.AngularVelocity w_nom = 2 * .Modelica.Constants.pi * f_nom "nom r.p.m." annotation(Evaluate = true);
    final parameter Boolean synRef = if transientSim then ref == "synchron" else true annotation(Evaluate = true);
    final parameter Boolean steadyIni = ini == "st" "steady state initialisation of electric equations" annotation(Evaluate = true);
    final parameter Boolean transientSim = sim == "tr" "transient mode of electric equations" annotation(Evaluate = true);
    final parameter Boolean steadyIni_t = steadyIni and transientSim annotation(Evaluate = true);
    discrete .Modelica.SIunits.Time initime;
    .Modelica.SIunits.Angle theta(final start = 0, stateSelect = if fType_par then StateSelect.default else StateSelect.always);
    .Modelica.SIunits.AngularFrequency omega(final start = 2 * .Modelica.Constants.pi * f);
    Interfaces.Frequency receiveFreq "receives weighted frequencies from generators";
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
    annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "No \"system\" component is defined.
      Drag PowerSystems.System into the top level of your model.");
  end System;

  package Examples
    extends Modelica.Icons.ExamplesPackage;

    package Spot  "Examples from Modelica Power Systems Library Spot"
      extends Modelica.Icons.ExamplesPackage;

      package AC3ph  "AC 3-phase components dq0"
        extends Modelica.Icons.ExamplesPackage;

        model Breaker  "Breaker"
          inner PowerSystems.System system;
          PowerSystems.AC3ph.Nodes.Ground grd2;
          PowerSystems.Blocks.Signals.TransientPhasor transPh;
          PowerSystems.AC3ph.Sources.Voltage voltage(V_nom = 10e3, scType_par = false);
          PowerSystems.AC3ph.Impedances.Inductor ind(r = 0.1, V_nom = 10e3, S_nom = 1e6);
          PowerSystems.AC3ph.Sensors.PVImeter meter(V_nom = 10e3, S_nom = 1e6);
          replaceable PowerSystems.AC3ph.Breakers.Breaker breaker(V_nom = 10e3, I_nom = 100);
          PowerSystems.Control.Relays.SwitchRelay relay(t_switch = {0.1});
          PowerSystems.AC3ph.Nodes.GroundOne grd1;
        equation
          connect(transPh.y, voltage.vPhasor);
          connect(relay.y, breaker.control);
          connect(voltage.term, ind.term_p);
          connect(ind.term_n, meter.term_p);
          connect(meter.term_n, breaker.term_p);
          connect(breaker.term_n, grd2.term);
          connect(grd1.term, voltage.neutral);
          annotation(experiment(StopTime = 0.2, Interval = 1e-4));
        end Breaker;
      end AC3ph;
    end Spot;
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
    end PartialPhaseSystem;

    package ThreePhase_dq0  "AC system in dq0 representation"
      extends PartialPhaseSystem(phaseSystemName = "ThreePhase_dq0", n = 3, m = 2);

      redeclare function j  "Rotation(pi/2) of vector around {0,0,1} and projection on orth plane"
        extends Modelica.Icons.Function;
        input Real[:] x;
        output Real[size(x, 1)] y;
      algorithm
        y := cat(1, {-x[2], x[1]}, zeros(size(x, 1) - 2));
      end j;
    end ThreePhase_dq0;
  end PhaseSystems;

  package AC3ph  "AC three phase components from Spot ACdq0"
    extends Modelica.Icons.VariantsPackage;

    package Breakers  "Switches and Breakers 3-phase"
      extends Modelica.Icons.VariantsPackage;

      model Breaker  "Breaker, 3-phase dq0"
        extends Partials.SwitchTrsfBase;
        replaceable parameter Parameters.BreakerArc par "breaker parameter";
      protected
        replaceable Common.Switching.Breaker breaker_a(D = par.D, t_opening = par.t_opening, Earc = par.Earc, R0 = par.R0, epsR = epsR, epsG = epsG);
        replaceable Common.Switching.Breaker breaker_b(D = par.D, t_opening = par.t_opening, Earc = par.Earc, R0 = par.R0, epsR = epsR, epsG = epsG);
        replaceable Common.Switching.Breaker breaker_c(D = par.D, t_opening = par.t_opening, Earc = par.Earc, R0 = par.R0, epsR = epsR, epsG = epsG);
      equation
        breaker_a.v = v_abc[1];
        breaker_a.i = i_abc[1];
        breaker_b.v = v_abc[2];
        breaker_b.i = i_abc[2];
        breaker_c.v = v_abc[3];
        breaker_c.i = i_abc[3];
        connect(control[1], breaker_a.closed);
        connect(control[2], breaker_b.closed);
        connect(control[3], breaker_c.closed);
      end Breaker;

      package Partials  "Partial models"
        extends Modelica.Icons.MaterialPropertiesPackage;

        partial model SwitchBase  "Switch base, 3-phase dq0"
          extends Ports.Port_pn;
          extends PowerSystems.Basic.Nominal.NominalVI;
          parameter Integer n = 3 "number of independent switches";
          parameter Real[2] eps(final min = {0, 0}, each unit = "1") = {1e-4, 1e-4} "{resistance 'closed', conductance 'open'}";
          .Modelica.SIunits.Voltage[3] v;
          .Modelica.SIunits.Current[3] i;
          Modelica.Blocks.Interfaces.BooleanInput[n] control "true:closed, false:open";
        protected
          final parameter .Modelica.SIunits.Resistance epsR = eps[1] * V_nom / I_nom;
          final parameter .Modelica.SIunits.Conductance epsG = eps[2] * I_nom / V_nom;
        equation
          v = term_p.v - term_n.v;
          term_p.i = i;
        end SwitchBase;

        partial model SwitchTrsfBase  "Switch base, additional abc-variables, 3-phase dq0"
          extends SwitchBase(final n = 3);
          .Modelica.SIunits.Voltage[3] v_abc(each stateSelect = StateSelect.never) "voltage switch a, b, c";
          .Modelica.SIunits.Current[3] i_abc(each stateSelect = StateSelect.never) "current switch a, b, c";
        protected
          Real[3, 3] Park = PowerSystems.Basic.Transforms.park(term_p.theta[2]);
        equation
          v = Park * v_abc;
          i_abc = transpose(Park) * i;
        end SwitchTrsfBase;
      end Partials;

      package Parameters  "Parameter data for interactive use"
        extends Modelica.Icons.BasesPackage;

        record BreakerArc  "Breaker parameters, 3-phase"
          extends Modelica.Icons.Record;
          .Modelica.SIunits.Distance D = 50e-3 "contact distance open";
          .Modelica.SIunits.Time t_opening = 30e-3 "opening duration";
          .Modelica.SIunits.ElectricFieldStrength Earc = 50e3 "electric field arc";
          Real R0 = 1 "small signal resistance arc";
          annotation(defaultComponentPrefixes = "parameter");
        end BreakerArc;
      end Parameters;
    end Breakers;

    package Impedances  "Impedance and admittance two terminal"
      extends Modelica.Icons.VariantsPackage;

      model Inductor  "Inductor with series resistor, 3-phase dq0"
        extends Partials.ImpedBase;
        parameter .PowerSystems.Basic.Types.SIpu.Resistance r = 0 "resistance";
        parameter .PowerSystems.Basic.Types.SIpu.Reactance x_s = 1 "self reactance";
        parameter .PowerSystems.Basic.Types.SIpu.Reactance x_m = 0 "mutual reactance, -x_s/2 < x_m < x_s";
      protected
        final parameter .Modelica.SIunits.Resistance[2] RL_base = Basic.Precalculation.baseRL(puUnits, V_nom, S_nom, 2 * .Modelica.Constants.pi * f_nom);
        final parameter .Modelica.SIunits.Resistance R = r * RL_base[1];
        final parameter .Modelica.SIunits.Inductance L = (x_s - x_m) * RL_base[2];
        final parameter .Modelica.SIunits.Inductance L0 = (x_s + 2 * x_m) * RL_base[2];
      initial equation
        if steadyIni_t then
          der(i) = omega[1] * j_dq0(i);
        elseif not system.steadyIni then
          i = i_start;
        end if;
      equation
        if system.transientSim then
          diagonal({L, L, L0}) * der(i) + omega[2] * L * j_dq0(i) + R * i = v;
        else
          omega[2] * L * j_dq0(i) + R * i = v;
        end if;
      end Inductor;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model ImpedBase  "Impedance base, 3-phase dq0"
          extends Ports.Port_pn;
          extends Basic.Nominal.NominalAC;
          parameter Boolean stIni_en = true "enable steady-state initial equation" annotation(Evaluate = true);
          parameter .Modelica.SIunits.Voltage[3] v_start = zeros(3) "start value of voltage drop";
          parameter .Modelica.SIunits.Current[3] i_start = zeros(3) "start value of current";
          .Modelica.SIunits.Voltage[3] v(start = v_start);
          .Modelica.SIunits.Current[3] i(start = i_start);
        protected
          final parameter Boolean steadyIni_t = system.steadyIni_t and stIni_en;
          .Modelica.SIunits.AngularFrequency[2] omega;
        equation
          omega = der(term_p.theta);
          v = term_p.v - term_n.v;
          i = term_p.i;
        end ImpedBase;
      end Partials;
    end Impedances;

    package Nodes  "Nodes and adaptors"
      extends Modelica.Icons.VariantsPackage;

      model Ground  "AC Ground, 3-phase dq0"
        extends Ports.Port_p;
      equation
        term.v = zeros(3);
      end Ground;

      model GroundOne  "Ground, one conductor"
        Interfaces.Electric_p term "positive scalar terminal";
      equation
        term.v = 0;
      end GroundOne;
    end Nodes;

    package Sensors  "Sensors and meters 3-phase"
      extends Modelica.Icons.SensorsPackage;

      model PVImeter  "Power-voltage-current meter, 3-phase dq0"
        extends Partials.Meter2Base;
        parameter Boolean av = false "time average power" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Time tcst(min = 1e-9) = 1 "average time-constant" annotation(Evaluate = true);

        function v2vpp_abc
          input .PowerSystems.Basic.Types.SIpu.Voltage[3] v_abc;
          output .PowerSystems.Basic.Types.SIpu.Voltage[3] vpp_abc;
        algorithm
          vpp_abc := {v_abc[2], v_abc[3], v_abc[1]} - {v_abc[3], v_abc[1], v_abc[2]};
        end v2vpp_abc;

        output .PowerSystems.Basic.Types.SIpu.Power[3] p(each stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Power[3] p_av = pav if av;
        output .PowerSystems.Basic.Types.SIpu.Voltage[3] v(each stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Voltage[2] vpp(each stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Current[3] i(each stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Voltage[3] v_abc(each stateSelect = StateSelect.never) = transpose(Park) * v if abc;
        output .PowerSystems.Basic.Types.SIpu.Voltage[3] vpp_abc(each stateSelect = StateSelect.never) = v2vpp_abc(transpose(Park) * v) if abc;
        output .PowerSystems.Basic.Types.SIpu.Current[3] i_abc(each stateSelect = StateSelect.never) = transpose(Park) * i if abc;
        output .PowerSystems.Basic.Types.SIpu.Voltage v_norm(stateSelect = StateSelect.never) = sqrt(v * v) if phasor;
        output .Modelica.SIunits.Angle alpha_v(stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Current i_norm(stateSelect = StateSelect.never) = sqrt(i * i) if phasor;
        output .Modelica.SIunits.Angle alpha_i(stateSelect = StateSelect.never);
        output Real cos_phi(stateSelect = StateSelect.never) = cos(alpha_v - alpha_i) if phasor;
      protected
        outer System system;
        final parameter .Modelica.SIunits.Voltage V_base = Basic.Precalculation.baseV(puUnits, V_nom);
        final parameter .Modelica.SIunits.Current I_base = Basic.Precalculation.baseI(puUnits, V_nom, S_nom);
        .PowerSystems.Basic.Types.SIpu.Power[3] pav;
      initial equation
        if av then
          pav = p;
        end if;
      equation
        v = term_p.v / V_base;
        vpp = sqrt(3) * {v[2], -v[1]};
        i = term_p.i / I_base;
        p = {v[1:2] * i[1:2], -j_dq0(v[1:2]) * i[1:2], v[3] * i[3]};
        if av then
          der(pav) = (p - pav) / tcst;
        else
          pav = zeros(3);
        end if;
        if phasor then
          alpha_v = atan2(Rot_dq[:, 2] * v[1:2], Rot_dq[:, 1] * v[1:2]);
          alpha_i = atan2(Rot_dq[:, 2] * i[1:2], Rot_dq[:, 1] * i[1:2]);
        else
          alpha_v = 0;
          alpha_i = 0;
        end if;
      end PVImeter;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model Sensor2Base  "Sensor 2 terminal base, 3-phase dq0"
          extends Ports.Port_pn;
          parameter Integer signalTrsf = 0 "signal in which reference frame?" annotation(Evaluate = true);
        protected
          function park = Basic.Transforms.park;
          function rot_dq = Basic.Transforms.rotation_dq;
        equation
          term_p.v = term_n.v;
        end Sensor2Base;

        partial model Meter2Base  "Meter 2 terminal base, 3-phase dq0"
          extends Sensor2Base(final signalTrsf = 0);
          parameter Boolean abc = false "abc inertial" annotation(Evaluate = true);
          parameter Boolean phasor = false "phasor" annotation(Evaluate = true);
          extends Basic.Nominal.Nominal;
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
          if phasor then
            Rot_dq = rot_dq(term_p.theta[1]);
          else
            Rot_dq = zeros(2, 2);
          end if;
        end Meter2Base;
      end Partials;
    end Sensors;

    package Sources  "Voltage and Power Sources"
      extends Modelica.Icons.SourcesPackage;

      model Voltage  "Ideal voltage, 3-phase dq0"
        extends Partials.VoltageBase;
        parameter .PowerSystems.Basic.Types.SIpu.Voltage v0 = 1 "voltage";
        parameter .Modelica.SIunits.Angle alpha0 = 0 "phase angle";
      protected
        .Modelica.SIunits.Voltage V;
        .Modelica.SIunits.Angle alpha;
        .Modelica.SIunits.Angle phi;
      equation
        if scType_par then
          V = v0 * V_base;
          alpha = alpha0;
        else
          V = vPhasor_internal[1] * V_base;
          alpha = vPhasor_internal[2];
        end if;
        phi = term.theta[1] + alpha + system.alpha0;
        term.v = {V * cos(phi), V * sin(phi), sqrt(3) * neutral.v};
      end Voltage;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model SourceBase  "Voltage base, 3-phase dq0"
          extends Ports.Port_n;
          extends Basic.Nominal.Nominal;
          Interfaces.Electric_p neutral "(use for grounding)";
        protected
          outer System system;
          final parameter Real V_base = Basic.Precalculation.baseV(puUnits, V_nom);
          .Modelica.SIunits.Angle theta(stateSelect = StateSelect.prefer) "absolute angle";
        equation
          Connections.potentialRoot(term.theta);
          if Connections.isRoot(term.theta) then
            term.theta = if system.synRef then {0, theta} else {theta, 0};
          end if;
          sqrt(3) * term.i[3] + neutral.i = 0;
        end SourceBase;

        partial model VoltageBase  "Voltage base, 3-phase dq0"
          extends SourceBase(final S_nom = 1);
          parameter Boolean fType_sys = true "= true, if source has system frequency" annotation(Evaluate = true);
          parameter Boolean fType_par = true "= true, if source has parameter frequency, otherwise defined by input omega" annotation(Evaluate = true);
          parameter .Modelica.SIunits.Frequency f = system.f "frequency";
          parameter Boolean scType_par = true "= true: voltage defined by parameter otherwise by input signal" annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.RealInput omega(final unit = "rad/s") if not fType_par "ang frequency";
          Modelica.Blocks.Interfaces.RealInput[2] vPhasor if not scType_par "({abs(voltage), phase})";
        protected
          parameter .PowerSystems.Basic.Types.FreqType fType = if fType_sys then .PowerSystems.Basic.Types.FreqType.sys else if fType_par then .PowerSystems.Basic.Types.FreqType.par else .PowerSystems.Basic.Types.FreqType.sig "frequency type";
          Modelica.Blocks.Interfaces.RealInput omega_internal "Needed to connect to conditional connector";
          Modelica.Blocks.Interfaces.RealInput[2] vPhasor_internal "Needed to connect to conditional connector";
        initial equation
          if fType == .PowerSystems.Basic.Types.FreqType.sig then
            theta = 0;
          end if;
        equation
          connect(omega, omega_internal);
          connect(vPhasor, vPhasor_internal);
          if fType <> .PowerSystems.Basic.Types.FreqType.sig then
            omega_internal = 0.0;
          end if;
          if scType_par then
            vPhasor_internal = {0, 0};
          end if;
          if fType == .PowerSystems.Basic.Types.FreqType.sys then
            theta = system.theta;
          elseif fType == .PowerSystems.Basic.Types.FreqType.par then
            theta = 2 * .Modelica.Constants.pi * f * (time - system.initime);
          elseif fType == .PowerSystems.Basic.Types.FreqType.sig then
            der(theta) = omega_internal;
          end if;
        end VoltageBase;
      end Partials;
    end Sources;

    package Ports  "AC three-phase ports dq0 representation"
      extends Modelica.Icons.InterfacesPackage;

      partial model PortBase  "base model adapting Spot to PowerSystems"
        function j_dq0 = PhaseSystems.ThreePhase_dq0.j;
      end PortBase;

      connector ACdq0_p  "AC terminal, 3-phase dq0 ('positive')"
        extends Interfaces.Terminal(redeclare package PhaseSystem = PhaseSystems.ThreePhase_dq0);
      end ACdq0_p;

      connector ACdq0_n  "AC terminal, 3-phase dq0 ('negative')"
        extends Interfaces.Terminal(redeclare package PhaseSystem = PhaseSystems.ThreePhase_dq0);
      end ACdq0_n;

      partial model Port_p  "AC one port 'positive', 3-phase"
        extends PortBase;
        Ports.ACdq0_p term "positive terminal";
      end Port_p;

      partial model Port_n  "AC one port 'negative', 3-phase"
        extends PortBase;
        Ports.ACdq0_n term "negative terminal";
      end Port_n;

      partial model Port_p_n  "AC two port, 3-phase"
        extends PortBase;
        Ports.ACdq0_p term_p "positive terminal";
        Ports.ACdq0_n term_n "negative terminal";
      equation
        Connections.branch(term_p.theta, term_n.theta);
        term_n.theta = term_p.theta;
      end Port_p_n;

      partial model Port_pn  "AC two port 'current_in = current_out', 3-phase"
        extends Port_p_n;
      equation
        term_p.i + term_n.i = zeros(3);
      end Port_pn;
    end Ports;
  end AC3ph;

  package Blocks  "Blocks"
    extends Modelica.Icons.Package;

    package Signals  "Special signals"
      extends Modelica.Icons.VariantsPackage;

      block TransientPhasor  "Transient {norm, phase} of vector"
        extends Partials.MO(final n = 2);
        parameter .Modelica.SIunits.Time t_change = 0.5 "time when change";
        parameter .Modelica.SIunits.Time t_duration = 1 "transition duration";
        parameter Real a_ini = 1 "initial norm |y|";
        parameter Real a_fin = 1 "final norm |y|";
        parameter .Modelica.SIunits.Angle ph_ini = 0 "initial phase (y)";
        parameter .Modelica.SIunits.Angle ph_fin = 0 "final phase (y)";
      protected
        final parameter .Modelica.SIunits.Frequency coef = 2 * exp(1) / t_duration;
      equation
        y = 0.5 * ({a_fin + a_ini, ph_fin + ph_ini} + {a_fin - a_ini, ph_fin - ph_ini} * tanh(coef * (time - t_change)));
      end TransientPhasor;
    end Signals;

    package Partials  "Partial models"
      extends Modelica.Icons.BasesPackage;

      partial block MO
        extends PowerSystems.Basic.Icons.Block0;
        Modelica.Blocks.Interfaces.RealOutput[n] y "output signal-vector";
        parameter Integer n = 1 "dim of output signal-vector";
      end MO;
    end Partials;
  end Blocks;

  package Common  "Common components"
    extends Modelica.Icons.Package;

    package Plasma  "Plasma arcs"
      extends Modelica.Icons.Package;

      model ArcBreaker  "Arc voltage for breakers"
        extends Partials.ArcBase;
        parameter .Modelica.SIunits.ElectricFieldStrength E "av electric field arc";
        parameter Real r(unit = "1/A") "= R0/(d*Earc), R0 small signal resistance";
        input .Modelica.SIunits.Distance d "contact distance";
      equation
        v = d * E * tanh(r * i);
        annotation(__Dymola_structurallyIncomplete = true);
      end ArcBreaker;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model ArcBase  "Arc voltage base"
          connector InputVoltage = input .Modelica.SIunits.Voltage;
          InputVoltage v;
          .Modelica.SIunits.Current i;
        end ArcBase;
      end Partials;
    end Plasma;

    package Switching  "Common switching components"
      extends Modelica.Icons.Package;

      model Breaker  "Breaker kernel, no terminals"
        extends Partials.SwitchBase;
        parameter .Modelica.SIunits.Distance D = 50e-3 "contact distance open";
        parameter .Modelica.SIunits.Time t_opening = 20e-3 "opening duration";
        parameter .Modelica.SIunits.ElectricFieldStrength Earc = 50e3 "electric field arc";
        parameter .Modelica.SIunits.Resistance R0 = 1 "small signal resistance arc";
        replaceable Plasma.ArcBreaker arcBreaker(E = Earc, r = R0 / (D * Earc));
      protected
        .Modelica.SIunits.Voltage v_arc;
        .Modelica.SIunits.Current i_arc;
        .Modelica.SIunits.Time t0(start = Modelica.Constants.inf, fixed = true) "start opening";
        .Modelica.SIunits.Distance d "contact distance";
        Boolean opening(start = false, fixed = true);
      initial equation
        pre(open) = not closed;
      equation
        arcBreaker.d = d;
        arcBreaker.v = v_arc;
        arcBreaker.i = i_arc;
        when {open and i < 0, open and i > 0, closed} then
          arc = edge(open) or opening;
        end when;
        when pre(arc) then
          t0 = time;
        end when;
        opening = t0 < time and time < t0 + t_opening;
        d = if opening then ((time - t0) / t_opening) ^ 2 * D else D "d not needed if closed (d=0)";
        i_arc = if arc then s else 0;
        {v, i} = if closed then {epsR * s, s} else if arc then {v_arc, i_arc} else {s, epsG * s};
      end Breaker;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model SwitchBase  "Switch base kernel, no terminals"
          parameter .Modelica.SIunits.Resistance epsR = 1e-5 "resistance 'closed'";
          parameter .Modelica.SIunits.Conductance epsG = 1e-5 "conductance 'open'";
          connector InputVoltage = input .Modelica.SIunits.Voltage;
          InputVoltage v;
          .Modelica.SIunits.Current i;
          Boolean arc(start = false, fixed = true) "arc on";
          Boolean open(start = true) = not closed;
          Modelica.Blocks.Interfaces.BooleanInput closed(start = false) "true:closed, false:open";
        protected
          Real s(start = 0.5);
        end SwitchBase;
      end Partials;
    end Switching;
  end Common;

  package Control  "Control blocks"
    extends Modelica.Icons.Package;

    package Relays  "Relays"
      extends Modelica.Icons.VariantsPackage;

      block SwitchRelay  "Relay for sequential switching "
        extends PowerSystems.Basic.Icons.Block0;
        parameter Integer n(min = 1) = 3 "number of signals";
        parameter Integer[:] switched = 1:n "switched signals";
        parameter Boolean ini_state = true "initial state (closed true, open false)";
        parameter .Modelica.SIunits.Time[:] t_switch = {1} "switching time vector";
        Modelica.Blocks.Interfaces.BooleanOutput[n] y(start = fill(ini_state, n), each fixed = true) "boolean state of switch (closed:true, open:false)";
      protected
        Integer cnt(start = 1, fixed = true);
      algorithm
        when time > t_switch[cnt] then
          cnt := min(cnt + 1, size(t_switch, 1));
          for k in switched loop
            y[k] := not y[k];
          end for;
        end when;
      end SwitchRelay;
    end Relays;
  end Control;

  package Basic  "Basic utility classes"
    extends Modelica.Icons.BasesPackage;

    package Nominal  "Units and nominal values"
      extends Modelica.Icons.BasesPackage;

      partial model Nominal  "Units and nominal values"
        parameter Boolean puUnits = true "= true, if scaled with nom. values (pu), else scaled with 1 (SI)" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Voltage V_nom(final min = 0) = 1 "nominal Voltage (= base for pu)" annotation(Evaluate = true);
        parameter .Modelica.SIunits.ApparentPower S_nom(final min = 0) = 1 "nominal Power (= base for pu)" annotation(Evaluate = true);
      end Nominal;

      partial model NominalAC  "Units and nominal values AC"
        extends Nominal;
        parameter .Modelica.SIunits.Frequency f_nom = system.f_nom "nominal frequency" annotation(Evaluate = true);
      protected
        outer PowerSystems.System system;
      end NominalAC;

      partial model NominalVI  "Nominal values"
        parameter .Modelica.SIunits.Voltage V_nom(final min = 0) = 1 "nom Voltage" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Current I_nom(final min = 0) = 1 "nom Current" annotation(Evaluate = true);
      end NominalVI;
    end Nominal;

    package Precalculation  "Precalculation functions"
      extends Modelica.Icons.Package;

      function baseV  "Base voltage"
        extends PowerSystems.Basic.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input .Modelica.SIunits.Voltage V_nom "nom voltage";
        output .Modelica.SIunits.Voltage V_base "base voltage";
      algorithm
        if puUnits then
          V_base := V_nom;
        else
          V_base := 1;
        end if;
      end baseV;

      function baseI  "Base current"
        extends PowerSystems.Basic.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input .Modelica.SIunits.Voltage V_nom "nom voltage";
        input .Modelica.SIunits.ApparentPower S_nom "apparent power";
        output .Modelica.SIunits.Current I_base "base current";
      algorithm
        if puUnits then
          I_base := S_nom / V_nom;
        else
          I_base := 1;
        end if;
      end baseI;

      function baseRL  "Base resistance and inductance"
        extends PowerSystems.Basic.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input .Modelica.SIunits.Voltage V_nom "nom voltage";
        input .Modelica.SIunits.ApparentPower S_nom "apparent power";
        input .Modelica.SIunits.AngularFrequency omega_nom "angular frequency";
        input Integer scale = 1 "scaling factor topology (Y:1, Delta:3)";
        output Real[2] RL_base "base {resistance, inductance}";
      algorithm
        if puUnits then
          RL_base := scale * (V_nom * V_nom / S_nom) * {1, 1 / omega_nom};
        else
          RL_base := scale * {1, 1 / omega_nom};
        end if;
      end baseRL;
    end Precalculation;

    package Transforms  "Transform functions"
      extends Modelica.Icons.Package;

      function park  "Park transform"
        extends PowerSystems.Basic.Icons.Function;
        input Modelica.SIunits.Angle theta "transformation angle";
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
        annotation(derivative = PowerSystems.Basic.Transforms.der_park);
      end park;

      function der_park  "Derivative of Park transform"
        extends PowerSystems.Basic.Icons.Function;
        input Modelica.SIunits.Angle theta "transformation angle";
        input Modelica.SIunits.AngularFrequency omega "d/dt theta";
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
        annotation(derivative(order = 2) = PowerSystems.Basic.Transforms.der2_park);
      end der_park;

      function der2_park  "2nd derivative of Park transform"
        extends PowerSystems.Basic.Icons.Function;
        input Modelica.SIunits.Angle theta "transformation angle";
        input Modelica.SIunits.AngularFrequency omega "d/dt theta";
        input Modelica.SIunits.AngularAcceleration omega_dot "d/dt omega";
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
      end der2_park;

      function rotation_dq  "Rotation matrix dq"
        extends PowerSystems.Basic.Icons.Function;
        input Modelica.SIunits.Angle theta "rotation angle";
        output Real[2, 2] R_dq "rotation matrix";
      protected
        Real c;
        Real s;
      algorithm
        c := cos(theta);
        s := sin(theta);
        R_dq := [c, -s; s, c];
        annotation(derivative = PowerSystems.Basic.Transforms.der_rotation_dq);
      end rotation_dq;

      function der_rotation_dq  "Derivative of rotation matrix dq"
        extends PowerSystems.Basic.Icons.Function;
        input Modelica.SIunits.Angle theta;
        input Modelica.SIunits.AngularFrequency omega "d/dt theta";
        output Real[2, 2] der_R_dq "d/dt rotation_dq";
      protected
        Real dc;
        Real ds;
      algorithm
        dc := -omega * sin(theta);
        ds := omega * cos(theta);
        der_R_dq := [dc, -ds; ds, dc];
        annotation(derivative(order = 2) = PowerSystems.Basic.Transforms.der2_rotation_dq);
      end der_rotation_dq;

      function der2_rotation_dq  "2nd derivative of rotation matrix dq"
        extends PowerSystems.Basic.Icons.Function;
        input Modelica.SIunits.Angle theta;
        input Modelica.SIunits.AngularFrequency omega "d/dt theta";
        input Modelica.SIunits.AngularAcceleration omega_dot "d/dt omega";
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
      end der2_rotation_dq;
    end Transforms;

    package Types
      extends Modelica.Icons.Package;

      package SIpu  "Additional types for power systems"
        extends Modelica.Icons.Package;
        type Voltage = Real(final quantity = "Voltage", unit = "V/V");
        type Current = Real(final quantity = "Current", unit = "A/A");
        type Resistance = Real(final quantity = "Resistance", unit = "Ohm/(V.V/VA)", final min = 0);
        type Reactance = Real(final quantity = "Reactance", unit = "Ohm/(V.V/VA)");
        type Power = Real(final quantity = "Power", unit = "W/W");
      end SIpu;

      type FreqType = enumeration(par "parameter", sig "signal", sys "system") "Frequency type";

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
      end ReferenceAngle;

      type AngularVelocity = .Modelica.SIunits.AngularVelocity(displayUnit = "rpm");
    end Types;

    package Icons  "Icons"
      extends Modelica.Icons.Package;

      partial block Block  "Block icon" end Block;

      partial block Block0  "Block icon 0"
        extends Block;
      end Block0;

      partial function Function  "Function icon" end Function;
    end Icons;
  end Basic;

  package Interfaces
    extends Modelica.Icons.InterfacesPackage;

    connector Terminal  "General power terminal"
      replaceable package PhaseSystem = PhaseSystems.PartialPhaseSystem "Phase system" annotation(choicesAllMatching = true);
      PhaseSystem.Voltage[PhaseSystem.n] v "voltage vector";
      flow PhaseSystem.Current[PhaseSystem.n] i "current vector";
      PhaseSystem.ReferenceAngle[PhaseSystem.m] theta "optional vector of phase angles";
    end Terminal;

    connector Electric_p  "Electric terminal ('positive')"
      extends Modelica.Electrical.Analog.Interfaces.Pin;
    end Electric_p;

    connector Frequency  "Weighted frequency"
      flow .Modelica.SIunits.Time H "inertia constant";
      flow .Modelica.SIunits.Angle w_H "angular velocity, inertia-weighted";
      Real h "Dummy potential-variable to balance flow-variable H";
      Real w_h "Dummy potential-variable to balance flow-variable w_H";
    end Frequency;
  end Interfaces;
  annotation(version = "0.3", versionDate = "2014-10-20");
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
  annotation(Protection(access = Access.hide), version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z");
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 3)"
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";
      connector BooleanInput = input Boolean "'input Boolean' as connector";
      connector BooleanOutput = output Boolean "'output Boolean' as connector";
    end Interfaces;
  end Blocks;

  package Electrical  "Library of electrical models (analog, digital, machines, multi-phase)"
    extends Modelica.Icons.Package;

    package Analog  "Library for analog electrical models"
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models for Analog electrical components"
        extends Modelica.Icons.InterfacesPackage;

        connector Pin  "Pin of an electrical component"
          Modelica.SIunits.Voltage v "Potential at the pin" annotation(unassignedMessage = "An electrical potential cannot be uniquely calculated.
          The reason could be that
          - a ground object is missing (Modelica.Electrical.Analog.Basic.Ground)
            to define the zero potential of the electrical circuit, or
          - a connector of an electrical component is not connected.");
          flow Modelica.SIunits.Current i "Current flowing into the pin" annotation(unassignedMessage = "An electrical current cannot be uniquely calculated.
          The reason could be that
          - a ground object is missing (Modelica.Electrical.Analog.Basic.Ground)
            to define the zero potential of the electrical circuit, or
          - a connector of an electrical component is not connected.");
        end Pin;
      end Interfaces;
    end Analog;
  end Electrical;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function atan2  "Four quadrant inverse tangent"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = atan2(u1, u2);
    end atan2;

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
      extends Modelica.Icons.Package;

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
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant Real inf = ModelicaServices.Machine.inf "Biggest Real number such that inf and -inf are representable on the machine";
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage  "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial package Package  "Icon for standard packages" end Package;

    partial package BasesPackage  "Icon for packages containing base classes"
      extends Modelica.Icons.Package;
    end BasesPackage;

    partial package VariantsPackage  "Icon for package containing variants"
      extends Modelica.Icons.Package;
    end VariantsPackage;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources"
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package SensorsPackage  "Icon for packages containing sensors"
      extends Modelica.Icons.Package;
    end SensorsPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)" end InternalPackage;

    partial package MaterialPropertiesPackage  "Icon for package containing property classes"
      extends Modelica.Icons.Package;
    end MaterialPropertiesPackage;

    partial function Function  "Icon for functions" end Function;

    partial record Record  "Icon for records" end Record;
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
    type Length = Real(final quantity = "Length", final unit = "m");
    type Distance = Length(min = 0);
    type Time = Real(final quantity = "Time", final unit = "s");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type AngularAcceleration = Real(final quantity = "AngularAcceleration", final unit = "rad/s2");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type AngularFrequency = Real(final quantity = "AngularFrequency", final unit = "rad/s");
    type ElectricCurrent = Real(final quantity = "ElectricCurrent", final unit = "A");
    type Current = ElectricCurrent;
    type ElectricFieldStrength = Real(final quantity = "ElectricFieldStrength", final unit = "V/m");
    type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
    type Voltage = ElectricPotential;
    type Inductance = Real(final quantity = "Inductance", final unit = "H");
    type Resistance = Real(final quantity = "Resistance", final unit = "Ohm");
    type Conductance = Real(final quantity = "Conductance", final unit = "S");
    type ApparentPower = Real(final quantity = "Power", final unit = "VA");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
  annotation(version = "3.2.1", versionBuild = 3, versionDate = "2013-08-14", dateModified = "2014-06-27 19:30:00Z");
end Modelica;

model Breaker_total  "Breaker"
  extends PowerSystems.Examples.Spot.AC3ph.Breaker;
 annotation(experiment(StopTime = 0.2, Interval = 1e-4));
end Breaker_total;
