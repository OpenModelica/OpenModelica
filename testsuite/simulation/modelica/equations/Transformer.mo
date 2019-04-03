package PowerSystems  "Library for electrical power systems"
  extends Modelica.Icons.Package;

  model System  "System reference"
    parameter .Modelica.SIunits.Frequency f_nom = 50 "nominal frequency"annotation(Evaluate = true);
    parameter .Modelica.SIunits.Frequency f = f_nom "frequency if fType_par = true, else initial frequency"annotation(Evaluate = true);
    parameter Boolean fType_par = true "= true, if system frequency defined by parameter f, else average frequency"annotation(Evaluate = true);
    parameter .Modelica.SIunits.Frequency[2] f_lim = {0.5 * f_nom, 2 * f_nom} "limit frequencies (for supervision of average frequency)"annotation(Evaluate = true);
    parameter .Modelica.SIunits.Angle alpha0 = 0 "phase angle"annotation(Evaluate = true);
    parameter String ref = "synchron""reference frame (3-phase)"annotation(Evaluate = true);
    parameter String ini = "st""transient or steady-state initialisation"annotation(Evaluate = true);
    parameter String sim = "tr""transient or steady-state simulation"annotation(Evaluate = true);
    final parameter .Modelica.SIunits.AngularFrequency omega_nom = 2 * .Modelica.Constants.pi * f_nom "nominal angular frequency"annotation(Evaluate = true);
    final parameter .PowerSystems.Basic.Types.AngularVelocity w_nom = 2 * .Modelica.Constants.pi * f_nom "nom r.p.m."annotation(Evaluate = true);
    final parameter Boolean synRef = if transientSim then ref == "synchron"else true annotation(Evaluate = true);
    final parameter Boolean steadyIni = ini == "st""steady state initialisation of electric equations"annotation(Evaluate = true);
    final parameter Boolean transientSim = sim == "tr""transient mode of electric equations"annotation(Evaluate = true);
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
    annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "No \"system\"component is defined.
      Drag PowerSystems.System into the top level of your model.");
  end System;

  package Examples
    extends Modelica.Icons.ExamplesPackage;

    package Spot  "Examples from Modelica Power Systems Library Spot"
      extends Modelica.Icons.ExamplesPackage;

      package AC1ph_DC  "AC 1-phase and DC components"
        extends Modelica.Icons.ExamplesPackage;

        model Transformer  "Transformer"
          inner PowerSystems.System system(ref = "inertial", ini = "tr");
          PowerSystems.Blocks.Signals.TransientPhasor transPh;
          PowerSystems.Control.Relays.TapChangerRelay TapChanger(preset_1 = {0, 1, 2}, preset_2 = {0, 1, 2}, t_switch_1 = {0.9, 1.9}, t_switch_2 = {1.1, 2.1});
          PowerSystems.AC1ph_DC.Sources.ACvoltage voltage(scType_par = false);
          PowerSystems.AC1ph_DC.Sensors.PVImeter meter1;
          PowerSystems.AC1ph_DC.Sensors.PVImeter meter2(V_nom = 10);
          replaceable PowerSystems.AC1ph_DC.Transformers.TrafoStray trafo(par(v_tc1 = {1, 1.1}, v_tc2 = {1, 1.2}, V_nom = {1, 10}), use_tap_p = true, use_tap_n = true);
          PowerSystems.AC1ph_DC.ImpedancesOneTerm.Resistor res(V_nom = 10, r = 100);
          PowerSystems.AC1ph_DC.Nodes.PolarityGround polGrd1(pol = 0);
          PowerSystems.AC1ph_DC.Nodes.GroundOne grd;
        equation
          connect(transPh.y, voltage.vPhasor);
          connect(voltage.term, meter1.term_p);
          connect(meter1.term_n, trafo.term_p);
          connect(trafo.term_n, meter2.term_p);
          connect(meter2.term_n, res.term);
          connect(res.term, polGrd1.term);
          connect(grd.term, voltage.neutral);
          connect(TapChanger.tap_p, trafo.tap_p);
          connect(TapChanger.tap_n, trafo.tap_n);
          annotation(experiment(StopTime = 3, Interval = 4e-4));
        end Transformer;
      end AC1ph_DC;
    end Spot;
  end Examples;

  package PhaseSystems  "Phase systems used in power connectors"
    extends Modelica.Icons.Package;

    partial package PartialPhaseSystem  "Base package of all phase systems"
      extends Modelica.Icons.Package;
      constant String phaseSystemName = "UnspecifiedPhaseSystem";
      constant Integer n "Number of independent voltage and current components";
      constant Integer m "Number of reference angles";
      type Voltage = Real(unit = "V", quantity = "Voltage."+ phaseSystemName) "voltage for connector";
      type Current = Real(unit = "A", quantity = "Current."+ phaseSystemName) "current for connector";
    end PartialPhaseSystem;

    package TwoConductor  "Two conductors for Spot DC_AC1ph components"
      extends PartialPhaseSystem(phaseSystemName = "TwoConductor", n = 2, m = 0);
    end TwoConductor;
  end PhaseSystems;

  package AC1ph_DC  "AC 1-phase and DC components from Spot AC1ph_DC"
    extends Modelica.Icons.VariantsPackage;

    package ImpedancesOneTerm  "Impedance and admittance one terminal"
      extends Modelica.Icons.VariantsPackage;

      model Resistor  "Resistor, 1-phase"
        extends Partials.ImpedBase(final f_nom = 0);
        parameter .PowerSystems.Basic.Types.SIpu.Resistance r = 1 "resistance";
      protected
        final parameter .Modelica.SIunits.Resistance R = r * Basic.Precalculation.baseR(puUnits, V_nom, S_nom);
      equation
        R * i = v;
      end Resistor;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model ImpedBase  "One terminal impedance base, 1-phase"
          extends Ports.Port_p;
          extends Basic.Nominal.NominalAC;
          parameter Boolean stIni_en = true "enable steady-state initialization"annotation(Evaluate = true);
          parameter .Modelica.SIunits.Voltage v_start = 0 "start value of voltage drop";
          parameter .Modelica.SIunits.Current i_start = 0 "start value of current";
          .Modelica.SIunits.Voltage v(start = v_start);
          .Modelica.SIunits.Current i(start = i_start);
        protected
          final parameter Boolean steadyIni_t = system.steadyIni_t and stIni_en;
        equation
          term.i[1] + term.i[2] = 0;
          v = term.v[1] - term.v[2];
          i = term.i[1];
        end ImpedBase;
      end Partials;
    end ImpedancesOneTerm;

    package Nodes  "Nodes "
      extends Modelica.Icons.VariantsPackage;

      model PolarityGround  "Polarity grounding, 1-phase"
        extends Ports.Port_p;
        parameter Integer pol(min = -1, max = 1) = -1 "grounding scheme"annotation(Evaluate = true);
      equation
        if pol == 1 then
          term.v[1] = 0;
          term.i[2] = 0;
        elseif pol == (-1) then
          term.v[2] = 0;
          term.i[1] = 0;
        else
          term.v[1] + term.v[2] = 0;
          term.i[1] = term.i[2];
        end if;
      end PolarityGround;

      model GroundOne  "Ground, one conductor"
        Interfaces.Electric_p term;
      equation
        term.v = 0;
      end GroundOne;
    end Nodes;

    package Transformers  "Transformers 1-phase "
      extends Modelica.Icons.VariantsPackage;

      model TrafoStray  "Ideal magnetic coupling transformer, 1-phase"
        extends Partials.TrafoStrayBase;
      initial equation
        if steadyIni_t then
          der(i1) = 0;
        elseif not system.steadyIni then
          i1 = i1_start;
        end if;
      equation
        i1 + i2 = 0;
        sum(L) * der(i1) + sum(R) * i1 = v1 - v2;
      end TrafoStray;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model TrafoIdealBase  "Base for ideal transformer, 1-phase"
          extends Ports.PortTrafo_p_n(i1(start = i1_start), i2(start = i2_start));
          parameter Boolean stIni_en = true "enable steady-state initial equation"annotation(Evaluate = true);
          parameter .Modelica.SIunits.Current i1_start = 0 "start value of primary current";
          parameter .Modelica.SIunits.Current i2_start = i1_start "start value of secondary current";
          parameter Boolean dynTC = false "enable dynamic tap-changing"annotation(Evaluate = true);
          parameter Boolean use_tap_p = false "= true, if input tap_p is enabled"annotation(Evaluate = true);
          parameter Boolean use_tap_n = false "= true, if input tap_n is enabled"annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.IntegerInput tap_p if use_tap_p "1: index of voltage level";
          Modelica.Blocks.Interfaces.IntegerInput tap_n if use_tap_n "2: index of voltage level";
          replaceable parameter Parameters.TrafoIdeal1ph par "trafo parameter";
        protected
          final parameter Boolean steadyIni_t = system.steadyIni_t and stIni_en;
          Modelica.Blocks.Interfaces.IntegerInput tap_p_internal "Needed to connect to conditional connector";
          Modelica.Blocks.Interfaces.IntegerInput tap_n_internal "Needed to connect to conditional connector";
          outer System system;
          constant Real tc = 0.01 "time constant tap-chg switching";
          final parameter .Modelica.SIunits.Voltage[2] V_base = Basic.Precalculation.baseTrafoV(par.puUnits, par.V_nom);
          final parameter Real[2, 2] RL_base = Basic.Precalculation.baseTrafoRL(par.puUnits, par.V_nom, par.S_nom, 2 * .Modelica.Constants.pi * par.f_nom);
          final parameter Real W_nom = par.V_nom[2] / par.V_nom[1] annotation(Evaluate = true);
          final parameter Real[:] W1 = cat(1, {1}, par.v_tc1 * V_base[1] / par.V_nom[1]) annotation(Evaluate = true);
          final parameter Real[:] W2 = cat(1, {1}, par.v_tc2 * V_base[2] / par.V_nom[2]) * W_nom annotation(Evaluate = true);
          Real w1_set = W1[1 + tap_p_internal] "1: set voltage ratio to nominal primary";
          Real w2_set = W2[1 + tap_n_internal] "2: set voltage ratio to nominal primary";
        initial equation
          if dynTC then
            w1 = w1_set;
            w2 = w2_set;
          end if;
        equation
          connect(tap_p, tap_p_internal);
          connect(tap_n, tap_n_internal);
          if not use_tap_p then
            tap_p_internal = 0;
          end if;
          if not use_tap_n then
            tap_n_internal = 0;
          end if;
          if dynTC then
            der(w1) + (w1 - w1_set) / tc = 0;
            der(w2) + (w2 - w2_set) / tc = 0;
          else
            w1 = w1_set;
            w2 = w2_set;
          end if;
        end TrafoIdealBase;

        partial model TrafoStrayBase  "Base for ideal magnetic coupling transformer, 1-phase"
          extends TrafoIdealBase(redeclare replaceable parameter PowerSystems.AC1ph_DC.Transformers.Parameters.TrafoStray1ph par);
        protected
          final parameter .Modelica.SIunits.Resistance[2] R = par.r .* RL_base[:, 1];
          final parameter .Modelica.SIunits.Inductance[2] L = par.x .* RL_base[:, 2];
        end TrafoStrayBase;
      end Partials;

      package Parameters  "Parameter data for interactive use"
        extends Modelica.Icons.MaterialPropertiesPackage;

        record TrafoIdeal1ph  "Parameters for ideal transformer, 1-phase"
          extends Basic.Nominal.NominalDataTrafo;
          .PowerSystems.Basic.Types.SIpu.Voltage[:] v_tc1 = fill(1, 0) "1: v-levels tap-changer";
          .PowerSystems.Basic.Types.SIpu.Voltage[:] v_tc2 = fill(1, 0) "2: v-levels tap-changer";
          annotation(defaultComponentPrefixes = "parameter");
        end TrafoIdeal1ph;

        record TrafoStray1ph  "Parameters for ideal magnetic coupling transformer, 1-phase"
          extends TrafoIdeal1ph;
          .PowerSystems.Basic.Types.SIpu.Resistance[2] r = {0.05, 0.05} "{1,2}: resistance";
          .PowerSystems.Basic.Types.SIpu.Reactance[2] x = {0.05, 0.05} "{1,2}: stray reactance";
          annotation(defaultComponentPrefixes = "parameter");
        end TrafoStray1ph;
      end Parameters;
    end Transformers;

    package Sensors  "Sensors n-phase or DC"
      extends Modelica.Icons.SensorsPackage;

      model PVImeter  "Power-voltage-current meter, 1-phase"
        parameter Boolean av = false "time average power"annotation(Evaluate = true);
        parameter .Modelica.SIunits.Time tcst(min = 1e-9) = 1 "average time-constant"annotation(Evaluate = true);
        extends Partials.Meter2Base;
        output .PowerSystems.Basic.Types.SIpu.Power p(stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Power p_av = pav if av;
        output .PowerSystems.Basic.Types.SIpu.Voltage v(stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Voltage v0(stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Current i(stateSelect = StateSelect.never);
        output .PowerSystems.Basic.Types.SIpu.Current i0(stateSelect = StateSelect.never);
      protected
        outer System system;
        final parameter .Modelica.SIunits.Voltage V_base = Basic.Precalculation.baseV(puUnits, V_nom);
        final parameter .Modelica.SIunits.Current I_base = Basic.Precalculation.baseI(puUnits, V_nom, S_nom);
        .PowerSystems.Basic.Types.SIpu.Power pav;
        .PowerSystems.Basic.Types.SIpu.Voltage[2] v_ab;
        .PowerSystems.Basic.Types.SIpu.Current[2] i_ab;
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
      end PVImeter;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model Sensor2Base  "Sensor Base, 1-phase"
          extends Ports.Port_pn;
        equation
          term_p.v = term_n.v;
        end Sensor2Base;

        partial model Meter2Base  "Meter base 2 terminal, 1-phase"
          extends Sensor2Base;
          extends Basic.Nominal.Nominal;
        end Meter2Base;
      end Partials;
    end Sensors;

    package Sources  "DC voltage sources"
      extends Modelica.Icons.SourcesPackage;

      model ACvoltage  "Ideal AC voltage, 1-phase"
        extends Partials.ACvoltageBase;
        parameter .PowerSystems.Basic.Types.SIpu.Voltage veff = 1 "eff voltage";
        parameter .Modelica.SIunits.Angle alpha0 = 0 "phase angle";
      protected
        .Modelica.SIunits.Voltage V;
        .Modelica.SIunits.Angle alpha;
        .Modelica.SIunits.Angle phi;
      equation
        if scType_par then
          V = veff * sqrt(2) * V_base;
          alpha = alpha0;
        else
          V = vPhasor_internal[1] * sqrt(2) * V_base;
          alpha = vPhasor_internal[2];
        end if;
        phi = theta + alpha + system.alpha0;
        term.v[1] - term.v[2] = V * cos(phi);
      end ACvoltage;

      package Partials  "Partial models"
        extends Modelica.Icons.BasesPackage;

        partial model VoltageBase  "Voltage base"
          extends Ports.Port_n;
          extends Basic.Nominal.Nominal(final S_nom = 1);
          parameter Integer pol(min = -1, max = 1) = -1 "grounding scheme"annotation(Evaluate = true);
          parameter Boolean scType_par = true "= true: voltage defined by parameter otherwise by input signal"annotation(Evaluate = true);
          Interfaces.Electric_p neutral "(use for grounding)";
        protected
          final parameter Real V_base = Basic.Precalculation.baseV(puUnits, V_nom);
        equation
          if pol == 1 then
            term.v[1] = neutral.v;
          elseif pol == (-1) then
            term.v[2] = neutral.v;
          else
            term.v[1] + term.v[2] = neutral.v;
          end if;
          sum(term.i) + neutral.i = 0;
        end VoltageBase;

        partial model ACvoltageBase  "AC voltage base"
          parameter Boolean fType_sys = true "= true, if source has system frequency"annotation(Evaluate = true);
          parameter Boolean fType_par = true "= true, if source has parameter frequency, otherwise defined by input omega"annotation(Evaluate = true);
          parameter .Modelica.SIunits.Frequency f = system.f "source frequency";
          extends VoltageBase;
          Modelica.Blocks.Interfaces.RealInput[2] vPhasor if not scType_par "{abs(voltage), phase(voltage)}";
          Modelica.Blocks.Interfaces.RealInput omega(final unit = "rad/s") if not fType_par "Angular frequency of source";
        protected
          parameter .PowerSystems.Basic.Types.FreqType fType = if fType_sys then .PowerSystems.Basic.Types.FreqType.sys else if fType_par then .PowerSystems.Basic.Types.FreqType.par else .PowerSystems.Basic.Types.FreqType.sig "frequency type";
          Modelica.Blocks.Interfaces.RealInput omega_internal "Needed to connect to conditional connector";
          Modelica.Blocks.Interfaces.RealInput[2] vPhasor_internal "Needed to connect to conditional connector";
          outer System system;
          .Modelica.SIunits.Angle theta(stateSelect = StateSelect.prefer);
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
        end ACvoltageBase;
      end Partials;
    end Sources;

    package Ports  "Strandard electric ports"
      extends Modelica.Icons.InterfacesPackage;

      connector TwoPin_p  "AC1/DC terminal ('positive')"
        extends Interfaces.TerminalDC(redeclare package PhaseSystem = PhaseSystems.TwoConductor);
      end TwoPin_p;

      connector TwoPin_n  "AC1/DC terminal ('negative')"
        extends Interfaces.TerminalDC(redeclare package PhaseSystem = PhaseSystems.TwoConductor);
      end TwoPin_n;

      partial model Port_p  "One port, 'positive'"
        Ports.TwoPin_p term "positive terminal";
      end Port_p;

      partial model Port_n  "One port, 'negative'"
        Ports.TwoPin_n term "negative terminal";
      end Port_n;

      partial model Port_p_n  "Two port"
        Ports.TwoPin_p term_p "positive terminal";
        Ports.TwoPin_n term_n "negative terminal";
      end Port_p_n;

      partial model Port_pn  "Two port, 'current_in = current_out'"
        extends Port_p_n;
      equation
        term_p.i + term_n.i = zeros(2);
      end Port_pn;

      partial model PortTrafo_p_n  "Two port for transformers"
        extends Port_p_n;
        .Modelica.SIunits.Voltage v1 "voltage 1";
        .Modelica.SIunits.Current i1 "current 1";
        .Modelica.SIunits.Voltage v2 "voltage 2";
        .Modelica.SIunits.Current i2 "current 2";
      protected
        Real w1 "1: voltage ratio to nominal";
        Real w2 "2: voltage ratio to nominal";
      equation
        term_p.i[1] + term_p.i[2] = 0;
        term_n.i[1] + term_n.i[2] = 0;
        v1 = (term_p.v[1] - term_p.v[2]) / w1;
        term_p.i[1] = i1 / w1;
        v2 = (term_n.v[1] - term_n.v[2]) / w2;
        term_n.i[1] = i2 / w2;
      end PortTrafo_p_n;
    end Ports;
  end AC1ph_DC;

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

  package Control  "Control blocks"
    extends Modelica.Icons.Package;

    package Relays  "Relays"
      extends Modelica.Icons.VariantsPackage;

      block TapChangerRelay  "Relay for setting tap-changer "
        extends PowerSystems.Basic.Icons.Block0;
        parameter Integer[:] preset_1(each min = 0) = {0} "1: index v-levels tap-chg, 0 is nom";
        parameter Integer[:] preset_2(each min = 0) = {0} "2: index v-levels tap-chg, 0 is nom";
        parameter .Modelica.SIunits.Time[:] t_switch_1 = {1} "1: switching times";
        parameter .Modelica.SIunits.Time[:] t_switch_2 = {1} "2:switching times";
        Modelica.Blocks.Interfaces.IntegerOutput tap_p "index of voltage level of tap changer 1";
        Modelica.Blocks.Interfaces.IntegerOutput tap_n "index of voltage level of tap changer 2";
      protected
        Integer cnt_1(start = 1, fixed = true);
        Integer cnt_2(start = 1, fixed = true);
      algorithm
        when time > t_switch_1[min(cnt_1, size(t_switch_1, 1))] then
          cnt_1 := cnt_1 + 1;
          tap_p := preset_1[min(cnt_1, size(preset_1, 1))];
        end when;
        when time > t_switch_2[min(cnt_2, size(t_switch_2, 1))] then
          cnt_2 := cnt_2 + 1;
          tap_n := preset_2[min(cnt_2, size(preset_2, 1))];
        end when;
      end TapChangerRelay;
    end Relays;
  end Control;

  package Basic  "Basic utility classes"
    extends Modelica.Icons.BasesPackage;

    package Nominal  "Units and nominal values"
      extends Modelica.Icons.BasesPackage;

      partial model Nominal  "Units and nominal values"
        parameter Boolean puUnits = true "= true, if scaled with nom. values (pu), else scaled with 1 (SI)"annotation(Evaluate = true);
        parameter .Modelica.SIunits.Voltage V_nom(final min = 0) = 1 "nominal Voltage (= base for pu)"annotation(Evaluate = true);
        parameter .Modelica.SIunits.ApparentPower S_nom(final min = 0) = 1 "nominal Power (= base for pu)"annotation(Evaluate = true);
      end Nominal;

      partial model NominalAC  "Units and nominal values AC"
        extends Nominal;
        parameter .Modelica.SIunits.Frequency f_nom = system.f_nom "nominal frequency"annotation(Evaluate = true);
      protected
        outer PowerSystems.System system;
      end NominalAC;

      record NominalDataTrafo  "Units and nominal data transformer"
        extends Modelica.Icons.Record;
        Boolean puUnits = true "= true, if scaled with nom. values (pu), else scaled with 1 (SI)"annotation(Evaluate = true);
        .Modelica.SIunits.Voltage[:] V_nom(each final min = 0) = {1, 1} "{prim,sec} nom Voltage (= base of pu)"annotation(Evaluate = true);
        .Modelica.SIunits.ApparentPower S_nom(final min = 0) = 1 "nominal Power (= base of pu)"annotation(Evaluate = true);
        .Modelica.SIunits.Frequency f_nom = 50 "nominal frequency"annotation(Evaluate = true);
        annotation(defaultComponentPrefixes = "parameter");
      end NominalDataTrafo;
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

      function baseR  "Base resistance"
        extends PowerSystems.Basic.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input .Modelica.SIunits.Voltage V_nom "nom voltage";
        input .Modelica.SIunits.ApparentPower S_nom "apparent power";
        input Integer scale = 1 "scaling factor topology (Y:1, Delta:3)";
        output .Modelica.SIunits.Resistance R_base "base resistance";
      algorithm
        if puUnits then
          R_base := scale * V_nom * V_nom / S_nom;
        else
          R_base := scale;
        end if;
      end baseR;

      function baseTrafoV  "Base voltage transformers"
        extends PowerSystems.Basic.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input .Modelica.SIunits.Voltage[:] V_nom "nom voltage {prim, sec} or {prim, sec1, sec2}";
        output .Modelica.SIunits.Voltage[size(V_nom, 1)] V_base "base voltage {prim,sec} or {prim, sec1, sec2}";
      algorithm
        if puUnits then
          V_base := V_nom;
        else
          V_base := ones(size(V_nom, 1));
        end if;
      end baseTrafoV;

      function baseTrafoRL  "Base resistance and inductance transformers"
        extends PowerSystems.Basic.Icons.Function;
        input Boolean puUnits "= true if pu else SI units";
        input .Modelica.SIunits.Voltage[:] V_nom "nom voltage {prim, sec} or {prim, sec1, sec2}";
        input .Modelica.SIunits.ApparentPower S_nom "apparent power";
        input .Modelica.SIunits.AngularFrequency omega_nom "angular frequency";
        output Real[size(V_nom, 1), 2] RL_base "base [prim res, prim ind;sec res, sec ind] or
           [prim res, prim ind;sec1 res, sec1 ind;sec2 res, sec2 ind]";
      algorithm
        if puUnits then
          RL_base := fill(V_nom[1] ^ 2 / S_nom, size(V_nom, 1), 1) * [1, 1 / omega_nom];
        else
          RL_base := [(fill(V_nom[1], size(V_nom, 1)) ./ V_nom) .^ 2] * [1, 1 / omega_nom];
        end if;
      end baseTrafoRL;
    end Precalculation;

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
      type AngularVelocity = .Modelica.SIunits.AngularVelocity(displayUnit = "rpm");
    end Types;

    package Icons  "Icons"
      extends Modelica.Icons.Package;

      partial block Block  "Block icon"end Block;

      partial block Block0  "Block icon 0"
        extends Block;
      end Block0;

      partial function Function  "Function icon"end Function;
    end Icons;
  end Basic;

  package Interfaces
    extends Modelica.Icons.InterfacesPackage;

    connector TerminalDC  "Power terminal for pure DC models"
      replaceable package PhaseSystem = PhaseSystems.PartialPhaseSystem "Phase system"annotation(choicesAllMatching = true);
      PhaseSystem.Voltage[PhaseSystem.n] v "voltage vector";
      flow PhaseSystem.Current[PhaseSystem.n] i "current vector";
    end TerminalDC;

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
  annotation(version = "0.4.0", versionDate = "2015-03-14");
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
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";
      connector IntegerInput = input Integer "'input Integer' as connector";
      connector IntegerOutput = output Integer "'output Integer' as connector";
    end Interfaces;
  end Blocks;

  package Electrical  "Library of electrical models (analog, digital, machines, multi-phase)"
    extends Modelica.Icons.Package;

    package Analog  "Library for analog electrical models"
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models for Analog electrical components"
        extends Modelica.Icons.InterfacesPackage;

        connector Pin  "Pin of an electrical component"
          .Modelica.SIunits.Voltage v "Potential at the pin"annotation(unassignedMessage = "An electrical potential cannot be uniquely calculated.
        The reason could be that
        - a ground object is missing (Modelica.Electrical.Analog.Basic.Ground)
          to define the zero potential of the electrical circuit, or
        - a connector of an electrical component is not connected.");
          flow .Modelica.SIunits.Current i "Current flowing into the pin"annotation(unassignedMessage = "An electrical current cannot be uniquely calculated.
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

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center"end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin"y = asin(u);
    end asin;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin"y = exp(u);
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
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage  "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial package Package  "Icon for standard packages"end Package;

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

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)"end InternalPackage;

    partial package MaterialPropertiesPackage  "Icon for package containing property classes"
      extends Modelica.Icons.Package;
    end MaterialPropertiesPackage;

    partial function Function  "Icon for functions"end Function;

    partial record Record  "Icon for records"end Record;
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)"annotation(absoluteValue = true);
      end NonSIunits;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Time = Real(final quantity = "Time", final unit = "s");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type AngularFrequency = Real(final quantity = "AngularFrequency", final unit = "rad/s");
    type ElectricCurrent = Real(final quantity = "ElectricCurrent", final unit = "A");
    type Current = ElectricCurrent;
    type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
    type Voltage = ElectricPotential;
    type Inductance = Real(final quantity = "Inductance", final unit = "H");
    type Resistance = Real(final quantity = "Resistance", final unit = "Ohm");
    type ApparentPower = Real(final quantity = "Power", final unit = "VA");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
  annotation(version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z");
end Modelica;

model Transformer_total  "Transformer"
  extends PowerSystems.Examples.Spot.AC1ph_DC.Transformer;
 annotation(experiment(StopTime = 3, Interval = 4e-4));
end Transformer_total;
