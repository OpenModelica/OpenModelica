
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

      package DrivesAC3ph  "AC drives, dq0" 
        extends Modelica.Icons.ExamplesPackage;

        model SM_ctrlAv  "AC synchronous pm machine, current controlled with average inverter" 
          inner PowerSystems.System system;
          PowerSystems.AC1ph_DC.Nodes.GroundOne grd;
          PowerSystems.AC1ph_DC.Sources.DCvoltage voltage(pol = 0, V_nom = sqrt(2 / 3) * 2 * 400);
          PowerSystems.AC3ph.Drives.SM_ctrl sm_ctrl(
		    redeclare model Rotor = PowerSystems.Mechanics.Rotation.ElectricRotor(J = 0.3), 
			redeclare model Inverter = PowerSystems.AC3ph.Inverters.InverterAverage(
			  redeclare record Data = PowerSystems.Examples.Spot.Data.Semiconductors.IdealSC1kV_100A), 
			redeclare model Motor = PowerSystems.AC3ph.Machines.Synchron3rd_pm_ctrl(
			  redeclare record Data = PowerSystems.Examples.Spot.Data.Machines.Synchron3rd_pm400V_30kVA));
          PowerSystems.Common.Thermal.BdCondV bdCond(m = 3);
          PowerSystems.Mechanics.Rotation.Rotor loadInertia(J = 0.5);
          PowerSystems.Mechanics.Rotation.FrictionTorque frictTorq(cFrict = {0.1, 0.01});
          Modelica.Mechanics.Rotational.Sources.TorqueStep torqueStep(offsetTorque = 0, startTime = 6, stepTorque = -100, useSupport = false);
          PowerSystems.Blocks.Signals.Transient i_q(t_change = 3, s_ini = 0.1) "phase of modulation signal";
          PowerSystems.Blocks.Signals.Transient i_d(t_change = 3, s_ini = 0, s_fin = 0) "phase of modulation signal";
          Modelica.Blocks.Continuous.LimPID PI_i_q(Ti = 0.2, Td = 0.1, controllerType = Modelica.Blocks.Types.SimpleController.PI, initType = Modelica.Blocks.Types.InitPID.SteadyState, yMax = 1, gainPID(y(start = 0.1)));
        equation
          connect(sm_ctrl.heat, bdCond.heat);
          connect(grd.term, voltage.neutral);
          connect(i_q.y, PI_i_q.u_s);
          connect(sm_ctrl.flange, loadInertia.flange_p);
          connect(loadInertia.flange_n, frictTorq.flange);
          connect(loadInertia.flange_n, torqueStep.flange);
          connect(voltage.term, sm_ctrl.term);
          connect(sm_ctrl.i_meas[2], PI_i_q.u_m);
          connect(PI_i_q.y, sm_ctrl.i_act[2]);
          connect(i_d.y, sm_ctrl.i_act[1]);
          annotation(experiment(StopTime = 10)); 
        end SM_ctrlAv;
      end DrivesAC3ph;

      package Data  "Data" 
        extends Modelica.Icons.MaterialPropertiesPackage;

        package Machines  "Machine example data" 
          extends Modelica.Icons.MaterialPropertiesPackage;

          record Synchron3rd_pm400V_30kVA  "Synchronous machine pm, 3rd order model, example" 
            extends PowerSystems.AC3ph.Machines.Parameters.Synchron3rd_pm(neu_iso = false, pp = 2, psi_pm = 1.1, x_d = 0.4, x_q = 0.4, x_o = 0.1, r_s = 0.03, r_n = 1, puUnits = true, V_nom = 400, S_nom = 30e3, f_nom = 50);
            annotation(defaultComponentPrefixes = "parameter"); 
          end Synchron3rd_pm400V_30kVA;
        end Machines;

        package Semiconductors  "Breaker example data" 
          extends Modelica.Icons.MaterialPropertiesPackage;

          record IdealSC1kV_100A  "Ideal semiconductor parameters, example" 
            extends PowerSystems.Semiconductors.Ideal.SCparameter(V_nom = 100, I_nom = 10, eps = {1e-4, 1e-4}, Vf = 2.5, Hsw_nom = 0.25, cT_loss = fill(0, 0), T0_loss = 300);
            annotation(defaultComponentPrefixes = "parameter"); 
          end IdealSC1kV_100A;
        end Semiconductors;
      end Data;
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
    end PartialPhaseSystem;

    package TwoConductor  "Two conductors for Spot DC_AC1ph components" 
      extends PartialPhaseSystem(phaseSystemName = "TwoConductor", n = 2, m = 0);
    end TwoConductor;

    package ThreePhase_dq0  "AC system in dq0 representation" 
      extends PartialPhaseSystem(phaseSystemName = "ThreePhase_dq0", n = 3, m = 2);
    end ThreePhase_dq0;
  end PhaseSystems;

  package AC1ph_DC  "AC 1-phase and DC components from Spot AC1ph_DC" 
    extends Modelica.Icons.VariantsPackage;

    package Nodes  "Nodes " 
      extends Modelica.Icons.VariantsPackage;

      model GroundOne  "Ground, one conductor" 
        Interfaces.Electric_p term;
      equation
        term.v = 0;
      end GroundOne;
    end Nodes;

    package Sources  "DC voltage sources" 
      extends Modelica.Icons.SourcesPackage;

      model DCvoltage  "Ideal DC voltage" 
        extends Partials.DCvoltageBase(pol = -1);
        parameter .PowerSystems.Basic.Types.SIpu.Voltage v0 = 1 "DC voltage";
      protected
        .Modelica.SIunits.Voltage v;
      equation
        if scType_par then
          v = v0 * V_base;
        else
          v = vDC_internal * V_base;
        end if;
        term.v[1] - term.v[2] = v;
      end DCvoltage;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model VoltageBase  "Voltage base" 
          extends Ports.Port_n;
          extends Basic.Nominal.Nominal(final S_nom = 1);
          parameter Integer pol(min = -1, max = 1) = -1 "grounding scheme" annotation(Evaluate = true);
          parameter Boolean scType_par = true "= true: voltage defined by parameter otherwise by input signal" annotation(Evaluate = true);
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

        partial model DCvoltageBase  "DC voltage base" 
          extends VoltageBase;
          parameter Integer pol(min = -1, max = 1) = -1 "grounding scheme" annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.RealInput vDC if not scType_par "DC voltage";
        protected
          Modelica.Blocks.Interfaces.RealInput vDC_internal "Needed to connect to conditional connector";
        equation
          connect(vDC, vDC_internal);
          if scType_par then
            vDC_internal = 0.0;
          end if;
        end DCvoltageBase;
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

      partial model Port_n  "One port, 'negative'" 
        Ports.TwoPin_n term "negative terminal";
      end Port_n;
    end Ports;
  end AC1ph_DC;

  package AC3ph  "AC three phase components from Spot ACdq0" 
    extends Modelica.Icons.VariantsPackage;

    package Inverters  "Rectifiers and Inverters" 
      extends Modelica.Icons.VariantsPackage;

      model InverterAverage  "Inverter time-average, 3-phase dq0" 
        extends Partials.SwitchEquation(heat(final m = 1));
        replaceable record Data = PowerSystems.Semiconductors.Ideal.SCparameter "SC parameters" annotation(choicesAllMatching = true);
        final parameter Data par "SC parameters";
        parameter Integer modulation = 1 "equivalent modulation :" annotation(Evaluate = true);
        parameter Boolean syn = false "synchronous, asynchronous" annotation(Evaluate = true);
        parameter Integer m_carr(min = 1) = 1 "f_carr/f, pulses/period" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Frequency f_carr = 1e3 "carrier frequency" annotation(Evaluate = true);
        parameter Real width0 = 2 / 3 "relative width, (0 - 1)";
        Modelica.Blocks.Interfaces.RealInput theta "abs angle, der(theta)=omega";
        Modelica.Blocks.Interfaces.RealInput[2] uPhasor "desired {abs(u), phase(u)}";
      protected
        outer System system;
        final parameter .Modelica.SIunits.Resistance R_nom = par.V_nom / par.I_nom;
        final parameter Real factor = if modulation == 1 then sqrt(3 / 2) else if modulation == 2 then 4 / 3 * sqrt(3 / 2) else if modulation == 3 then 4 / .Modelica.Constants.pi * sin(width0 * .Modelica.Constants.pi / 2) * sqrt(3 / 2) else 0 annotation(Evaluate = true);
        .Modelica.SIunits.Angle phi;
        .Modelica.SIunits.Voltage Vloss;
        Real iAC2;
        Real cT;
        Real hsw_nom;
      equation
        Connections.potentialRoot(AC.theta);
        if Connections.isRoot(AC.theta) then
          AC.theta = if system.synRef then {0, theta} else {theta, 0};
        end if;
        Vloss = if par.Vf < 1e-3 then 0 else tanh(10 * iDC1 / par.I_nom) * 2 * par.Vf;
        iAC2 = AC.i * AC.i;
        cT = if size(par.cT_loss, 1) == 0 then 1 else loss(T[1] - par.T0_loss, par.cT_loss);
        hsw_nom = if syn then 2 * par.Hsw_nom * m_carr / (.Modelica.Constants.pi * par.V_nom * par.I_nom) * der(theta) else 4 * par.Hsw_nom * f_carr / (par.V_nom * par.I_nom);
        phi = AC.theta[1] + uPhasor[2] + system.alpha0;
        switch_dq0 = factor * uPhasor[1] * {cos(phi), sin(phi), 0};
        v_dq0 = (vDC1 - cT * Vloss) * switch_dq0;
        Q_flow = {par.eps[1] * R_nom * iAC2 + 2 * sqrt(6) / .Modelica.Constants.pi * cT * (par.Vf + hsw_nom * abs(vDC1)) * sqrt(iAC2)};
      end InverterAverage;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model AC_DC_base  "AC-DC base, 3-phase dq0" 
          extends PowerSystems.Basic.Icons.Inverter_dq0;
          extends Ports.PortBase;
          Ports.ACdq0_n AC "AC 3-phase connection";
          AC1ph_DC.Ports.TwoPin_p DC "DC connection";
          Interfaces.ThermalV_n heat(m = 3) "vector heat port";
        end AC_DC_base;

        partial model SwitchEquation  "Switch equation, 3-phase dq0" 
          extends AC_DC_base;
        protected
          .Modelica.SIunits.Voltage vDC1 = 0.5 * (DC.v[1] - DC.v[2]);
          .Modelica.SIunits.Voltage vDC0 = 0.5 * (DC.v[1] + DC.v[2]);
          .Modelica.SIunits.Current iDC1 = DC.i[1] - DC.i[2];
          .Modelica.SIunits.Current iDC0 = DC.i[1] + DC.i[2];
          Real[3] v_dq0 "switching function voltage in dq0 representation";
          Real[3] switch_dq0 "switching function in dq0 representation";
          .Modelica.SIunits.Temperature[heat.m] T "component temperature";
          .Modelica.SIunits.HeatFlowRate[heat.m] Q_flow "component loss-heat flow";
          function loss = Basic.Math.taylor "temp dependence of losses";
        equation
          AC.v = v_dq0 + {0, 0, sqrt(3) * vDC0};
          iDC1 + switch_dq0 * AC.i = 0;
          iDC0 + sqrt(3) * AC.i[3] = 0;
          T = heat.ports.T;
          heat.ports.Q_flow = -Q_flow;
        end SwitchEquation;
      end Partials;
    end Inverters;

    package Machines  "AC machines, electric part " 
      extends Modelica.Icons.VariantsPackage;

      model Synchron3rd_pm_ctrl  "Synchronous machine, for field-oriented control, 3rd order model, 3-phase dq0" 
        extends Partials.Synchron3rdBase(redeclare replaceable record Data = PowerSystems.AC3ph.Machines.Parameters.Synchron3rd_pm);
        Modelica.Blocks.Interfaces.RealOutput[2] i_meas(each final unit = "1") "measured current {i_d, i_q} pu";
        Modelica.Blocks.Interfaces.RealInput[2] i_act(each final unit = "1") "actuated current {i_d, i_q} pu";
        Modelica.Blocks.Interfaces.RealOutput phiRotor = phi_el "rotor angle el";
        Modelica.Blocks.Interfaces.RealOutput[2] uPhasor "desired {abs(u), phase(u)}";
      protected
        final parameter .Modelica.SIunits.Current I_nom = par.S_nom / par.V_nom;
        .Modelica.SIunits.Voltage[2] v_dq "voltage demand {v_d, v_q} pu";
        .Modelica.SIunits.Current[2] i_dq "current demand {i_d, i_q} pu";
      initial equation
        phi_el = phi_el_ini;
        if system.steadyIni then
          der(w_el) = 0;
        else
          w_el = w_el_ini;
        end if;
      equation
        if par.excite == 1 then
          assert(false, "machine-parameter must be excite = 2 (pm) or 3 (reluctance)");
        elseif par.excite == 2 then
          psi_e = c.Psi_pm;
        elseif par.excite == 3 then
          psi_e = 0;
        end if;
        i_meas = i_s[1:2] / I_nom;
        i_dq = i_act * I_nom;
        v_dq = w_el * {-c.L_s[2] * i_dq[2], c.L_s[1] * i_dq[1] + psi_e} + c.R_s * i_dq;
        uPhasor = {sqrt(v_dq * v_dq) / par.V_nom, atan2(v_dq[2], v_dq[1])};
      end Synchron3rd_pm_ctrl;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model ACmachine  "AC machine base, 3-phase dq0" 
          extends Ports.YDport_p(i(start = i_start));
          parameter Boolean stIni_en = true "enable steady-state initialization" annotation(Evaluate = true);
          parameter .Modelica.SIunits.Current[3] i_start = zeros(3) "start value of current conductor";
          parameter .Modelica.SIunits.Angle phi_el_ini = 0 "initial rotor angle electric";
          parameter .Modelica.SIunits.AngularVelocity w_ini = 0 "initial rotor angular velocity";
          parameter Integer pp = 1 "pole-pair number";
          .Modelica.SIunits.Angle phi_el(stateSelect = StateSelect.prefer, start = phi_el_ini) "rotor angle electric (syn: +pi/2)";
          .Modelica.SIunits.AngularVelocity w_el(stateSelect = StateSelect.prefer, start = w_el_ini) "rotor angular velocity el";
          .Modelica.SIunits.Torque tau_el "electromagnetic torque";
          Interfaces.Rotation_n airgap "electro-mechanical connection";
          Interfaces.ThermalV_n heat(m = 2) "heat source port {stator, rotor}";
        protected
          outer System system;
          final parameter Boolean steadyIni_t = system.steadyIni_t and stIni_en;
          final parameter .Modelica.SIunits.AngularVelocity w_el_ini = w_ini * pp "initial rotor angular velocity electric";
          .Modelica.SIunits.AngularFrequency[2] omega;
          function atan2 = Modelica.Math.atan2;
        equation
          omega = der(term.theta);
          pp * airgap.phi = phi_el;
          airgap.tau = -pp * tau_el;
          w_el = der(phi_el);
        end ACmachine;

        partial model SynTransform  "Rotation transform dq" 
          extends ACmachine;
          parameter .Modelica.SIunits.Current[3] i_s_start = zeros(3) "start value of stator current dq0 in rotor-system";
        protected
          .Modelica.SIunits.MagneticFlux psi_e "excitation flux";
          .Modelica.SIunits.Voltage[3] v_s "stator voltage dq0 in rotor-system";
          .Modelica.SIunits.Current[3] i_s(each stateSelect = StateSelect.prefer, start = i_s_start) "stator current dq0 in rotor-system";
          Real[2, 2] Rot_dq "Rotation reference-dq0 to rotor-dq0 system";
        equation
          Rot_dq = Basic.Transforms.rotation_dq(phi_el - term.theta[2]);
          v_s = cat(1, transpose(Rot_dq) * v[1:2], {v[3]});
          i = cat(1, Rot_dq * i_s[1:2], {i_s[3]});
        end SynTransform;

        partial model Synchron3rdBase  "Synchronous machine 3rd base, 3-phase dq0" 
          extends SynTransform(final pp = par.pp, v(start = {cos(system.alpha0), sin(system.alpha0), 0} * par.V_nom));
          replaceable record Data = PowerSystems.AC3ph.Machines.Parameters.Synchron3rd(f_nom = system.f_nom) "machine parameters" annotation(choicesAllMatching = true);
          final parameter Data par "machine parameters";
        protected
          final parameter Coefficients.Synchron3rd c = Basic.Precalculation.machineSyn3rd(par, top.scale);
          .Modelica.SIunits.MagneticFlux[2] psi_s "magnetic flux stator dq";
        initial equation
          if steadyIni_t then
            der(psi_s) = zeros(2);
            der(c.L_s[3] * i_s[3]) = 0;
          end if;
        equation
          psi_s = {c.L_s[1] * i_s[1] + psi_e, c.L_s[2] * i_s[2]};
          if system.transientSim then
            der(psi_s) + w_el * {-psi_s[2], psi_s[1]} + c.R_s * i_s[1:2] = v_s[1:2];
            c.L_s[3] * der(i_s[3]) + c.R_s * i_s[3] = v_s[3];
          else
            w_el * {-psi_s[2], psi_s[1]} + c.R_s * i_s[1:2] = v_s[1:2];
            c.R_s * i_s[3] = v_s[3];
          end if;
          if par.neu_iso then
            i_n = zeros(top.n_n);
          else
            v_n = c.R_n * i_n "equation neutral to ground (relevant if Y-topology)";
          end if;
          tau_el = i_s[1:2] * {-psi_s[2], psi_s[1]};
          heat.ports.Q_flow = -{c.R_s * i_s * i_s, 0};
        end Synchron3rdBase;
      end Partials;

      package Parameters  "Parameter data for interactive use" 
        extends Modelica.Icons.MaterialPropertiesPackage;

        record Synchron3rd  "Synchronous machine 3rd order parameters" 
          extends PowerSystems.Basic.Nominal.NominalDataAC;
          Boolean neu_iso "isolated neutral if Y";
          Integer pp "pole-pair number";
          Integer excite(min = 0, max = 3) "excitation (1:el, 2:pm, 3:reluctance)" annotation(Evaluate = true);
          .PowerSystems.Basic.Types.SIpu.MagneticFlux psi_pm "magnetisation (V/V_nom at open term at omega_nom)";
          .PowerSystems.Basic.Types.SIpu.Reactance x_d "syn reactance d-axis";
          .PowerSystems.Basic.Types.SIpu.Reactance x_q "syn reactance q-axis";
          .PowerSystems.Basic.Types.SIpu.Reactance x_o "reactance o-axis";
          .PowerSystems.Basic.Types.SIpu.Resistance r_s "resistance armature";
          .PowerSystems.Basic.Types.SIpu.Resistance r_n "resistance neutral to grd (if Y)";
          annotation(defaultComponentPrefixes = "parameter"); 
        end Synchron3rd;

        record Synchron3rd_pm  "Synchronous machine pm 3rd order parameters" 
          extends Synchron3rd(neu_iso = false, pp = 2, final excite = 2, psi_pm = 1.2, x_d = 0.4, x_q = 0.4, x_o = 0.1, r_s = 0.05, r_n = 1);
          annotation(defaultComponentPrefixes = "parameter"); 
        end Synchron3rd_pm;
      end Parameters;

      package Coefficients  "Coefficient matrices of machine equations" 
        extends Modelica.Icons.MaterialPropertiesPackage;

        record Synchron3rd  "Coefficient matrices of synchronous machine, 3rd order" 
          extends Modelica.Icons.Record;
          .Modelica.SIunits.Inductance[3] L_s "L matrix stator dq0";
          .Modelica.SIunits.Resistance R_s "R stator (armature)";
          .Modelica.SIunits.Resistance R_n "resistance neutral to grd (if Y)";
          .Modelica.SIunits.MagneticFlux Psi_pm "flux permanent magnet";
          .Modelica.SIunits.AngularFrequency omega_nom;
          annotation(defaultComponentPrefixes = "final parameter"); 
        end Synchron3rd;
      end Coefficients;
    end Machines;

    package Drives  "AC-drives dq0" 
      extends Modelica.Icons.VariantsPackage;

      model SM_ctrl  "Synchronous machine, current-control" 
        extends Partials.DriveBase_ctrl(heat_adapt(final m = {2, inverter.heat.m}));
        replaceable model Inverter = PowerSystems.AC3ph.Inverters.InverterAverage constrainedby PowerSystems.AC3ph.Inverters.Partials.AC_DC_base;
        Inverter inverter "inverter (average or modulated)";
        replaceable model Motor = PowerSystems.AC3ph.Machines.Synchron3rd_pm_ctrl(final w_ini = w_ini) "syn motor, current controlled";
        Motor motor "syn motor, current controlled";
      equation
        connect(motor.airgap, rotor.rotor);
        connect(term, inverter.DC);
        connect(inverter.AC, motor.term);
        connect(motor.heat, heat_adapt.port_a);
        connect(inverter.heat, heat_adapt.port_b);
        connect(motor.phiRotor, inverter.theta);
        connect(motor.uPhasor, inverter.uPhasor);
        connect(motor.i_meas, i_meas);
        connect(i_act, motor.i_act);
      end SM_ctrl;

      package Partials  "Partial models" 
        partial model DriveBase0  "AC drives base mechanical" 
          Interfaces.Rotation_n flange "mechanical flange";
          replaceable model Rotor = PowerSystems.Mechanics.Rotation.ElectricRotor "machine rotor" annotation(choicesAllMatching = true);
          Rotor rotor "machine rotor";
          replaceable model Gear = PowerSystems.Mechanics.Rotation.NoGear "type of gear";
          Gear gear "type of gear";
          Interfaces.ThermalV_n heat(m = 2) "heat source port {stator, rotor}";
        protected
          outer System system;
        equation
          connect(rotor.flange_n, gear.flange_p);
          connect(gear.flange_n, flange);
        end DriveBase0;

        extends Modelica.Icons.BasesPackage;

        partial model DriveBase_ctrl  "AC drives base control" 
          parameter .PowerSystems.Basic.Types.AngularVelocity w_ini = 0 "initial rpm (start-value if ini='st')";
          extends DriveBase0(heat(final m = sum(heat_adapt.m)), rotor(w(start = w_ini)));
          AC1ph_DC.Ports.TwoPin_p term "electric terminal DC";
          Modelica.Blocks.Interfaces.RealOutput[2] i_meas(each final unit = "1") "measured current {i_d, i_q} pu";
          Modelica.Blocks.Interfaces.RealInput[2] i_act(each final unit = "1") "actuated current {i_d, i_q} pu";
        protected
          Common.Thermal.HeatV_a_b_ab heat_adapt;
        equation
          connect(heat_adapt.port_ab, heat);
        end DriveBase_ctrl;
      end Partials;
    end Drives;

    package Ports  "AC three-phase ports dq0 representation" 
      extends Modelica.Icons.InterfacesPackage;

      partial model PortBase  "base model adapting Spot to PowerSystems" end PortBase;

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

      partial model YDport_p  "AC one port Y or Delta topology 'positive'" 
        extends Port_p;
        replaceable model Topology_p = Topology.Y constrainedby Topology.TopologyBase;
        Topology_p top(v_cond = v, i_cond = i, v_n = v_n);
        .Modelica.SIunits.Voltage[3] v "voltage conductor";
        .Modelica.SIunits.Current[3] i "current conductor";
        .Modelica.SIunits.Voltage[n_n] v_n "voltage neutral";
        .Modelica.SIunits.Current[n_n] i_n = top.i_n "current neutral to ground";
      protected
        final parameter Integer n_n = top.n_n annotation(Evaluate = true);
      equation
        term.v = top.v_term;
        term.i = top.i_term;
      end YDport_p;

      package Topology  "Topology transforms " 
        extends Modelica.Icons.BasesPackage;

        partial model TopologyBase  "Topology transform base" 
          parameter Integer n_n(min = 0, max = 1) = 1 "1 for Y, 0 for Delta";
          parameter Integer sh(min = -1, max = 1) = 0 "(-1,0,+1)*120deg phase shift" annotation(Evaluate = true);
          .Modelica.SIunits.Voltage[3] v_term "terminal voltage";
          .Modelica.SIunits.Current[3] i_term "terminal current";
          input .Modelica.SIunits.Voltage[3] v_cond "conductor voltage";
          input .Modelica.SIunits.Current[3] i_cond "conductor current";
          input .Modelica.SIunits.Voltage[n_n] v_n(start = fill(0, n_n)) "voltage neutral";
          .Modelica.SIunits.Current[n_n] i_n(start = fill(0, n_n)) "current neutral to ground";
        protected
          constant Real s3 = sqrt(3);
        end TopologyBase;

        model Y  "Y transform" 
          extends TopologyBase(final n_n = 1, final sh = 0);
          constant Integer scale = 1 "for scaling of impedance values";
        equation
          v_cond = v_term - {0, 0, s3 * v_n[1]};
          i_term = i_cond;
          i_n[1] = s3 * i_term[3];
        end Y;
      end Topology;
    end Ports;
  end AC3ph;

  package Blocks  "Blocks" 
    extends Modelica.Icons.Package;

    package Signals  "Special signals" 
      extends Modelica.Icons.VariantsPackage;

      block Transient  "Transient vector" 
        extends Partials.SO;
        parameter .Modelica.SIunits.Time t_change = 0.5 "time when change";
        parameter .Modelica.SIunits.Time t_duration = 1 "transition duration";
        parameter Real s_ini = 1 "initial value";
        parameter Real s_fin = 1 "final value";
      protected
        final parameter .Modelica.SIunits.Frequency coef = 2 * exp(1) / t_duration;
      equation
        y = 0.5 * (s_fin + s_ini + (s_fin - s_ini) * tanh(coef * (time - t_change)));
      end Transient;
    end Signals;

    package Partials  "Partial models" 
      extends Modelica.Icons.BasesPackage;

      partial block SO  
        extends PowerSystems.Basic.Icons.Block0;
        Modelica.Blocks.Interfaces.RealOutput y "output signal";
      end SO;
    end Partials;
  end Blocks;

  package Common  "Common components" 
    extends Modelica.Icons.Package;

    package Thermal  "Thermal boundary and adaptors" 
      extends Modelica.Icons.VariantsPackage;

      model BdCondV  "Default (Neumann) boundary condition, vector port" 
        parameter Integer m(final min = 1) = 1 "dimension of heat port";
        extends Partials.BdCondBase;
        PowerSystems.Interfaces.ThermalV_p heat(final m = m) "vector heat port";
      equation
        heat.ports.T = fill(T_amb, heat.m);
      end BdCondV;

      model HeatV_a_b_ab  "Adaptor 2 x ThermalV (vector) to ThermalV (vector)" 
        parameter Integer[2] m = {1, 1} "dimension {port_a, port_b}";
        PowerSystems.Interfaces.ThermalV_p port_a(final m = m[1]) "vector port a";
        PowerSystems.Interfaces.ThermalV_p port_b(final m = m[2]) "vector port b";
        PowerSystems.Interfaces.ThermalV_n port_ab(final m = sum(m)) "vector port {a,b}";
      equation
        cat(1, port_a.ports.T, port_b.ports.T) = port_ab.ports.T;
        cat(1, port_a.ports.Q_flow, port_b.ports.Q_flow) + port_ab.ports.Q_flow = zeros(sum(m));
      end HeatV_a_b_ab;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        model BdCondBase  "Default (Neumann) boundary condition base" 
          parameter .Modelica.SIunits.Temperature T_amb = 300 "ambient temperature";
        end BdCondBase;
      end Partials;
    end Thermal;
  end Common;

  package Mechanics  "Mechanical components" 
    extends Modelica.Icons.Package;

    package Rotation  "Rotating parts " 
      extends Modelica.Icons.VariantsPackage;

      package Ports  "One- and two-flange base for rotating mechanical components." 
        extends Modelica.Icons.BasesPackage;

        partial model Flange_p  "One flange, 'positive'" 
          Interfaces.Rotation_p flange "positive flange";
        end Flange_p;

        partial model Flange_p_n  "Two flange" 
          Interfaces.Rotation_p flange_p "positive flange";
          Interfaces.Rotation_n flange_n "negative flange";
        end Flange_p_n;

        partial model Rigid  "Rigid two-flange" 
          extends Flange_p_n;
        equation
          flange_p.phi = flange_n.phi;
        end Rigid;
      end Ports;

      model FrictionTorque  "Friction torque" 
        extends Ports.Flange_p;
        parameter Real[2] cFrict(each min = 0) = {0, 0} "friction cst {lin, quadr} in {[N.s/m], [N.s2/m2]}";
        .Modelica.SIunits.Angle phi;
        .Modelica.SIunits.AngularVelocity w;
      protected
        constant Real cFrictUnit1(unit = "N.s/m") = 1 annotation(HideResult = true);
        constant Real cFrictUnit2(unit = "N.s2/m2") = 1 annotation(HideResult = true);
      equation
        phi = flange.phi;
        w = der(phi);
        flange.tau = (cFrict[1] * cFrictUnit1 + cFrict[2] * cFrictUnit2 * noEvent(abs(w))) * w;
      end FrictionTorque;

      model Rotor  "Rigid rotating mass" 
        extends Partials.RigidRotorBase;
      equation
        J * a = flange_p.tau + flange_n.tau;
      end Rotor;

      model ElectricRotor  "Electric generator/motor rotor, mechanical" 
        extends Partials.RigidRotorCase;
      end ElectricRotor;

      model NoGear  "Placeholder for gear" 
        extends Ports.Flange_p_n;
      equation
        flange_p.phi = flange_n.phi;
        flange_p.tau + flange_n.tau = 0;
      end NoGear;

      package Partials  "Partial models" 
        extends Modelica.Icons.BasesPackage;

        partial model RigidRotorBase  "Rigid rotor base" 
          extends Ports.Rigid;
          parameter .Modelica.SIunits.Inertia J = 1 "inertia";
          parameter .Modelica.SIunits.AngularVelocity w_start = 0 "start value of angular velocity";
          .Modelica.SIunits.Angle phi "rotation angle absolute";
          .Modelica.SIunits.AngularVelocity w(start = w_start);
          .Modelica.SIunits.AngularAcceleration a;
        equation
          phi = flange_p.phi;
          w = der(phi);
          a = der(w);
        end RigidRotorBase;

        partial model RigidRotorCase  "Rigid rotor with case" 
          extends RigidRotorBase;
          Interfaces.Rotation_p rotor "connector to turbine (mech) or airgap (el) torque";
          Interfaces.Rotation_p stator "access for stator reaction moment";
          Interfaces.Rotation_n friction "access for friction model";
        equation
          if cardinality(stator) == 0 then
            stator.phi = 0;
          else
            rotor.tau + stator.tau + friction.tau = 0;
          end if;
          rotor.phi = phi - stator.phi;
          friction.phi = rotor.phi;
          J * a = rotor.tau + flange_p.tau + flange_n.tau + friction.tau;
        end RigidRotorCase;
      end Partials;
    end Rotation;
  end Mechanics;

  package Semiconductors  "Semiconductors" 
    extends Modelica.Icons.Package;

    package Ideal  "Custom models" 
      extends Modelica.Icons.VariantsPackage;

      record SCparameter  "Ideal semiconductor parameters" 
        extends Basic.Nominal.NominalDataVI;
        parameter Real[2] eps(final min = {0, 0}, each final unit = "1") = {1e-4, 1e-4} "{resistance 'on', conductance 'off'}";
        parameter .Modelica.SIunits.Voltage Vf(final min = 0) = 0 "forward threshold-voltage" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Heat Hsw_nom = 0 "switching loss at V_nom, I_nom (av on off)" annotation(Evaluate = true);
        parameter Real[:] cT_loss = fill(0, 0) "{cT1,cT2,...} T-coef thermal losses" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Temp_K T0_loss = 300 "reference T for cT_loss expansion" annotation(Evaluate = true);
      end SCparameter;
    end Ideal;
  end Semiconductors;

  package Basic  "Basic utility classes" 
    extends Modelica.Icons.BasesPackage;

    package Math  "Mathematical functions" 
      extends Modelica.Icons.Package;

      function taylor  "Taylor series" 
        extends PowerSystems.Basic.Icons.Function;
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
      end taylor;
    end Math;

    package Nominal  "Units and nominal values" 
      extends Modelica.Icons.BasesPackage;

      partial model Nominal  "Units and nominal values" 
        parameter Boolean puUnits = true "= true, if scaled with nom. values (pu), else scaled with 1 (SI)" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Voltage V_nom(final min = 0) = 1 "nominal Voltage (= base for pu)" annotation(Evaluate = true);
        parameter .Modelica.SIunits.ApparentPower S_nom(final min = 0) = 1 "nominal Power (= base for pu)" annotation(Evaluate = true);
      end Nominal;

      record NominalData  "Units and nominal data" 
        extends Modelica.Icons.Record;
        Boolean puUnits = true "= true, if scaled with nom. values (pu), else scaled with 1 (SI)" annotation(Evaluate = true);
        .Modelica.SIunits.Voltage V_nom(final min = 0) = 1 "nominal Voltage (= base for pu)" annotation(Evaluate = true);
        .Modelica.SIunits.ApparentPower S_nom(final min = 0) = 1 "nominal Power (= base for pu)" annotation(Evaluate = true);
        annotation(defaultComponentPrefixes = "parameter"); 
      end NominalData;

      record NominalDataAC  "Units and nominal data AC" 
        extends NominalData;
        .Modelica.SIunits.Frequency f_nom = 50 "nominal frequency" annotation(Evaluate = true);
        annotation(defaultComponentPrefixes = "parameter"); 
      end NominalDataAC;

      record NominalDataVI  "Units and nominal data" 
        extends Modelica.Icons.Record;
        .Modelica.SIunits.Voltage V_nom(final min = 0) = 1 "nom Voltage" annotation(Evaluate = true);
        .Modelica.SIunits.Current I_nom(final min = 0) = 1 "nom Current" annotation(Evaluate = true);
        annotation(defaultComponentPrefixes = "parameter"); 
      end NominalDataVI;
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

      function machineSyn3rd  "Calculates coefficient matrices of synchronous machine, 3rd order" 
        extends PowerSystems.Basic.Icons.Function;
        input AC3ph.Machines.Parameters.Synchron3rd p "parameters synchronous machine 3rd order";
        input Integer scale = 1 "scaling factor topology (Y:1, Delta:3)";
        output AC3ph.Machines.Coefficients.Synchron3rd c "coefficient matrices synchronous machine 3rd order";
      protected
        final parameter .Modelica.SIunits.AngularFrequency omega_nom = 2 * .Modelica.Constants.pi * p.f_nom;
        final parameter Real[2] RL_base = Basic.Precalculation.baseRL(p.puUnits, p.V_nom, p.S_nom, omega_nom, scale) "base resistance inductance";
      algorithm
        c.L_s := {p.x_d, p.x_q, p.x_o} * RL_base[2];
        c.R_s := p.r_s * RL_base[1];
        c.R_n := p.r_n * RL_base[1];
        c.Psi_pm := p.psi_pm * (p.V_nom / omega_nom);
        c.omega_nom := omega_nom;
      end machineSyn3rd;
    end Precalculation;

    package Transforms  "Transform functions" 
      extends Modelica.Icons.Package;

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
        type Resistance = Real(final quantity = "Resistance", unit = "Ohm/(V.V/VA)", final min = 0);
        type Reactance = Real(final quantity = "Reactance", unit = "Ohm/(V.V/VA)");
        type MagneticFlux = Real(final quantity = "MagneticFlux", unit = "Wb/Wb");
      end SIpu;

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

      partial model Inverter_dq0  "Inverter icon" end Inverter_dq0;

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

    connector TerminalDC  "Power terminal for pure DC models" 
      replaceable package PhaseSystem = PhaseSystems.PartialPhaseSystem "Phase system" annotation(choicesAllMatching = true);
      PhaseSystem.Voltage[PhaseSystem.n] v "voltage vector";
      flow PhaseSystem.Current[PhaseSystem.n] i "current vector";
    end TerminalDC;

    connector Electric_p  "Electric terminal ('positive')" 
      extends Modelica.Electrical.Analog.Interfaces.Pin;
    end Electric_p;

    connector Rotation_p = Modelica.Mechanics.Rotational.Interfaces.Flange_a;
    connector Rotation_n = Modelica.Mechanics.Rotational.Interfaces.Flange_b;

    connector ThermalV_p  "Thermal vector heat port ('positive')" 
      parameter Integer m(final min = 1) = 1 "number of single heat-ports";
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[m] ports "vector of single heat ports";
    end ThermalV_p;

    connector ThermalV_n  "Thermal vector heat port ('negative')" 
      parameter Integer m(final min = 1) = 1 "number of single heat-ports";
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[m] ports "vector of single heat ports";
    end ThermalV_n;

    connector Frequency  "Weighted frequency" 
      flow .Modelica.SIunits.Time H "inertia constant";
      flow .Modelica.SIunits.Angle w_H "angular velocity, inertia-weighted";
      Real h "Dummy potential-variable to balance flow-variable H";
      Real w_h "Dummy potential-variable to balance flow-variable w_H";
    end Frequency;
  end Interfaces;
  annotation(version = "0.5 dev", versionDate = "2016-03-25"); 
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

    package Continuous  "Library of continuous control blocks with internal states" 
      extends Modelica.Icons.Package;

      block Integrator  "Output the integral of the input signal" 
        parameter Real k(unit = "1") = 1 "Integrator gain";
        parameter Modelica.Blocks.Types.Init initType = Modelica.Blocks.Types.Init.InitialState "Type of initialization (1: no init, 2: steady state, 3,4: initial output)" annotation(Evaluate = true);
        parameter Real y_start = 0 "Initial or guess value of output (= state)";
        extends .Modelica.Blocks.Interfaces.SISO(y(start = y_start));
      initial equation
        if initType == .Modelica.Blocks.Types.Init.SteadyState then
          der(y) = 0;
        elseif initType == .Modelica.Blocks.Types.Init.InitialState or initType == .Modelica.Blocks.Types.Init.InitialOutput then
          y = y_start;
        end if;
      equation
        der(y) = k * u;
      end Integrator;

      block Derivative  "Approximated derivative block" 
        parameter Real k(unit = "1") = 1 "Gains";
        parameter .Modelica.SIunits.Time T(min = Modelica.Constants.small) = 0.01 "Time constants (T>0 required; T=0 is ideal derivative block)";
        parameter Modelica.Blocks.Types.Init initType = Modelica.Blocks.Types.Init.NoInit "Type of initialization (1: no init, 2: steady state, 3: initial state, 4: initial output)" annotation(Evaluate = true);
        parameter Real x_start = 0 "Initial or guess value of state";
        parameter Real y_start = 0 "Initial value of output (= state)";
        extends .Modelica.Blocks.Interfaces.SISO;
        output Real x(start = x_start) "State of block";
      protected
        parameter Boolean zeroGain = abs(k) < Modelica.Constants.eps;
      initial equation
        if initType == .Modelica.Blocks.Types.Init.SteadyState then
          der(x) = 0;
        elseif initType == .Modelica.Blocks.Types.Init.InitialState then
          x = x_start;
        elseif initType == .Modelica.Blocks.Types.Init.InitialOutput then
          if zeroGain then
            x = u;
          else
            y = y_start;
          end if;
        end if;
      equation
        der(x) = if zeroGain then 0 else (u - x) / T;
        y = if zeroGain then 0 else k / T * (u - x);
      end Derivative;

      block LimPID  "P, PI, PD, and PID controller with limited output, anti-windup compensation and setpoint weighting" 
        extends .Modelica.Blocks.Interfaces.SVcontrol;
        output Real controlError = u_s - u_m "Control error (set point - measurement)";
        parameter .Modelica.Blocks.Types.SimpleController controllerType = .Modelica.Blocks.Types.SimpleController.PID "Type of controller";
        parameter Real k(min = 0, unit = "1") = 1 "Gain of controller";
        parameter .Modelica.SIunits.Time Ti(min = Modelica.Constants.small) = 0.5 "Time constant of Integrator block";
        parameter .Modelica.SIunits.Time Td(min = 0) = 0.1 "Time constant of Derivative block";
        parameter Real yMax(start = 1) "Upper limit of output";
        parameter Real yMin = -yMax "Lower limit of output";
        parameter Real wp(min = 0) = 1 "Set-point weight for Proportional block (0..1)";
        parameter Real wd(min = 0) = 0 "Set-point weight for Derivative block (0..1)";
        parameter Real Ni(min = 100 * Modelica.Constants.eps) = 0.9 "Ni*Ti is time constant of anti-windup compensation";
        parameter Real Nd(min = 100 * Modelica.Constants.eps) = 10 "The higher Nd, the more ideal the derivative block";
        parameter .Modelica.Blocks.Types.InitPID initType = .Modelica.Blocks.Types.InitPID.DoNotUse_InitialIntegratorState "Type of initialization (1: no init, 2: steady state, 3: initial state, 4: initial output)" annotation(Evaluate = true);
        parameter Boolean limitsAtInit = true "= false, if limits are ignored during initialization" annotation(Evaluate = true);
        parameter Real xi_start = 0 "Initial or guess value value for integrator output (= integrator state)";
        parameter Real xd_start = 0 "Initial or guess value for state of derivative block";
        parameter Real y_start = 0 "Initial value of output";
        parameter Boolean strict = false "= true, if strict limits with noEvent(..)" annotation(Evaluate = true);
        constant .Modelica.SIunits.Time unitTime = 1 annotation(HideResult = true);
        Blocks.Math.Add addP(k1 = wp, k2 = -1);
        Blocks.Math.Add addD(k1 = wd, k2 = -1) if with_D;
        Blocks.Math.Gain P(k = 1);
        Blocks.Continuous.Integrator I(k = unitTime / Ti, y_start = xi_start, initType = if initType == .Modelica.Blocks.Types.InitPID.SteadyState then .Modelica.Blocks.Types.Init.SteadyState else if initType == .Modelica.Blocks.Types.InitPID.InitialState or initType == .Modelica.Blocks.Types.InitPID.DoNotUse_InitialIntegratorState then .Modelica.Blocks.Types.Init.InitialState else .Modelica.Blocks.Types.Init.NoInit) if with_I;
        Blocks.Continuous.Derivative D(k = Td / unitTime, T = max([Td / Nd, 1.e-14]), x_start = xd_start, initType = if initType == .Modelica.Blocks.Types.InitPID.SteadyState or initType == .Modelica.Blocks.Types.InitPID.InitialOutput then .Modelica.Blocks.Types.Init.SteadyState else if initType == .Modelica.Blocks.Types.InitPID.InitialState then .Modelica.Blocks.Types.Init.InitialState else .Modelica.Blocks.Types.Init.NoInit) if with_D;
        Blocks.Math.Gain gainPID(k = k);
        Blocks.Math.Add3 addPID;
        Blocks.Math.Add3 addI(k2 = -1) if with_I;
        Blocks.Math.Add addSat(k1 = +1, k2 = -1) if with_I;
        Blocks.Math.Gain gainTrack(k = 1 / (k * Ni)) if with_I;
        Blocks.Nonlinear.Limiter limiter(uMax = yMax, uMin = yMin, strict = strict, limitsAtInit = limitsAtInit);
      protected
        parameter Boolean with_I = controllerType == .Modelica.Blocks.Types.SimpleController.PI or controllerType == .Modelica.Blocks.Types.SimpleController.PID annotation(Evaluate = true, HideResult = true);
        parameter Boolean with_D = controllerType == .Modelica.Blocks.Types.SimpleController.PD or controllerType == .Modelica.Blocks.Types.SimpleController.PID annotation(Evaluate = true, HideResult = true);
      public
        Sources.Constant Dzero(k = 0) if not with_D;
        Sources.Constant Izero(k = 0) if not with_I;
      initial equation
        if initType == .Modelica.Blocks.Types.InitPID.InitialOutput then
          gainPID.y = y_start;
        end if;
      equation
        if initType == .Modelica.Blocks.Types.InitPID.InitialOutput and (y_start < yMin or y_start > yMax) then
          Modelica.Utilities.Streams.error("LimPID: Start value y_start (=" + String(y_start) + ") is outside of the limits of yMin (=" + String(yMin) + ") and yMax (=" + String(yMax) + ")");
        end if;
        connect(u_s, addP.u1);
        connect(u_s, addD.u1);
        connect(u_s, addI.u1);
        connect(addP.y, P.u);
        connect(addD.y, D.u);
        connect(addI.y, I.u);
        connect(P.y, addPID.u1);
        connect(D.y, addPID.u2);
        connect(I.y, addPID.u3);
        connect(addPID.y, gainPID.u);
        connect(gainPID.y, addSat.u2);
        connect(gainPID.y, limiter.u);
        connect(limiter.y, addSat.u1);
        connect(limiter.y, y);
        connect(addSat.y, gainTrack.u);
        connect(gainTrack.y, addI.u3);
        connect(u_m, addP.u2);
        connect(u_m, addD.u2);
        connect(u_m, addI.u2);
        connect(Dzero.y, addPID.u2);
        connect(Izero.y, addPID.u3);
      end LimPID;
    end Continuous;

    package Interfaces  "Library of connectors and partial models for input/output blocks" 
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
      connector RealOutput = output Real "'output Real' as connector";

      partial block SO  "Single Output continuous control block" 
        extends Modelica.Blocks.Icons.Block;
        RealOutput y "Connector of Real output signal";
      end SO;

      partial block SISO  "Single Input Single Output continuous control block" 
        extends Modelica.Blocks.Icons.Block;
        RealInput u "Connector of Real input signal";
        RealOutput y "Connector of Real output signal";
      end SISO;

      partial block SI2SO  "2 Single Input / 1 Single Output continuous control block" 
        extends Modelica.Blocks.Icons.Block;
        RealInput u1 "Connector of Real input signal 1";
        RealInput u2 "Connector of Real input signal 2";
        RealOutput y "Connector of Real output signal";
      end SI2SO;

      partial block SVcontrol  "Single-Variable continuous controller" 
        extends Modelica.Blocks.Icons.Block;
        RealInput u_s "Connector of setpoint input signal";
        RealInput u_m "Connector of measurement input signal";
        RealOutput y "Connector of actuator output signal";
      end SVcontrol;
    end Interfaces;

    package Math  "Library of Real mathematical functions as input/output blocks" 
      extends Modelica.Icons.Package;

      block Gain  "Output the product of a gain value with the input signal" 
        parameter Real k(start = 1, unit = "1") "Gain value multiplied with input signal";
        .Modelica.Blocks.Interfaces.RealInput u "Input signal connector";
        .Modelica.Blocks.Interfaces.RealOutput y "Output signal connector";
      equation
        y = k * u;
      end Gain;

      block Add  "Output the sum of the two inputs" 
        extends .Modelica.Blocks.Interfaces.SI2SO;
        parameter Real k1 = +1 "Gain of upper input";
        parameter Real k2 = +1 "Gain of lower input";
      equation
        y = k1 * u1 + k2 * u2;
      end Add;

      block Add3  "Output the sum of the three inputs" 
        extends Modelica.Blocks.Icons.Block;
        parameter Real k1 = +1 "Gain of upper input";
        parameter Real k2 = +1 "Gain of middle input";
        parameter Real k3 = +1 "Gain of lower input";
        .Modelica.Blocks.Interfaces.RealInput u1 "Connector 1 of Real input signals";
        .Modelica.Blocks.Interfaces.RealInput u2 "Connector 2 of Real input signals";
        .Modelica.Blocks.Interfaces.RealInput u3 "Connector 3 of Real input signals";
        .Modelica.Blocks.Interfaces.RealOutput y "Connector of Real output signals";
      equation
        y = k1 * u1 + k2 * u2 + k3 * u3;
      end Add3;
    end Math;

    package Nonlinear  "Library of discontinuous or non-differentiable algebraic control blocks" 
      extends Modelica.Icons.Package;

      block Limiter  "Limit the range of a signal" 
        parameter Real uMax(start = 1) "Upper limits of input signals";
        parameter Real uMin = -uMax "Lower limits of input signals";
        parameter Boolean strict = false "= true, if strict limits with noEvent(..)" annotation(Evaluate = true);
        parameter Boolean limitsAtInit = true "Has no longer an effect and is only kept for backwards compatibility (the implementation uses now the homotopy operator)" annotation(Evaluate = true);
        extends .Modelica.Blocks.Interfaces.SISO;
      equation
        assert(uMax >= uMin, "Limiter: Limits must be consistent. However, uMax (=" + String(uMax) + ") < uMin (=" + String(uMin) + ")");
        if strict then
          y = homotopy(actual = smooth(0, noEvent(if u > uMax then uMax else if u < uMin then uMin else u)), simplified = u);
        else
          y = homotopy(actual = smooth(0, if u > uMax then uMax else if u < uMin then uMin else u), simplified = u);
        end if;
      end Limiter;
    end Nonlinear;

    package Sources  "Library of signal source blocks generating Real and Boolean signals" 
      extends Modelica.Icons.SourcesPackage;

      block Constant  "Generate constant signal of type Real" 
        parameter Real k(start = 1) "Constant output value";
        extends .Modelica.Blocks.Interfaces.SO;
      equation
        y = k;
      end Constant;
    end Sources;

    package Types  "Library of constants and types with choices, especially to build menus" 
      extends Modelica.Icons.TypesPackage;
      type Init = enumeration(NoInit "No initialization (start values are used as guess values with fixed=false)", SteadyState "Steady state initialization (derivatives of states are zero)", InitialState "Initialization with initial states", InitialOutput "Initialization with initial outputs (and steady state of the states if possible)") "Enumeration defining initialization of a block" annotation(Evaluate = true);
      type InitPID = enumeration(NoInit "No initialization (start values are used as guess values with fixed=false)", SteadyState "Steady state initialization (derivatives of states are zero)", InitialState "Initialization with initial states", InitialOutput "Initialization with initial outputs (and steady state of the states if possible)", DoNotUse_InitialIntegratorState "Do not use, only for backward compatibility (initialize only integrator state)") "Enumeration defining initialization of PID and LimPID blocks" annotation(Evaluate = true);
      type SimpleController = enumeration(P "P controller", PI "PI controller", PD "PD controller", PID "PID controller") "Enumeration defining P, PI, PD, or PID simple controller type" annotation(Evaluate = true);
    end Types;

    package Icons  "Icons for Blocks" 
      extends Modelica.Icons.IconsPackage;

      partial block Block  "Basic graphical layout of input/output block" end Block;
    end Icons;
  end Blocks;

  package Electrical  "Library of electrical models (analog, digital, machines, multi-phase)" 
    extends Modelica.Icons.Package;

    package Analog  "Library for analog electrical models" 
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models for Analog electrical components" 
        extends Modelica.Icons.InterfacesPackage;

        connector Pin  "Pin of an electrical component" 
          .Modelica.SIunits.Voltage v "Potential at the pin" annotation(unassignedMessage = "An electrical potential cannot be uniquely calculated.
        The reason could be that
        - a ground object is missing (Modelica.Electrical.Analog.Basic.Ground)
          to define the zero potential of the electrical circuit, or
        - a connector of an electrical component is not connected.");
          flow .Modelica.SIunits.Current i "Current flowing into the pin" annotation(unassignedMessage = "An electrical current cannot be uniquely calculated.
        The reason could be that
        - a ground object is missing (Modelica.Electrical.Analog.Basic.Ground)
          to define the zero potential of the electrical circuit, or
        - a connector of an electrical component is not connected.");
        end Pin;
      end Interfaces;
    end Analog;
  end Electrical;

  package Mechanics  "Library of 1-dim. and 3-dim. mechanical components (multi-body, rotational, translational)" 
    extends Modelica.Icons.Package;

    package Rotational  "Library to model 1-dimensional, rotational mechanical systems" 
      extends Modelica.Icons.Package;

      package Sources  "Sources to drive 1D rotational mechanical components" 
        extends Modelica.Icons.SourcesPackage;

        model TorqueStep  "Constant torque, not dependent on speed" 
          extends Modelica.Mechanics.Rotational.Interfaces.PartialTorque;
          parameter Modelica.SIunits.Torque stepTorque(start = 1) "Height of torque step (if negative, torque is acting as load)";
          parameter Modelica.SIunits.Torque offsetTorque(start = 0) "Offset of torque";
          parameter Modelica.SIunits.Time startTime = 0 "Torque = offset for time < startTime";
          Modelica.SIunits.Torque tau "Accelerating torque acting at flange (= -flange.tau)";
        equation
          tau = -flange.tau;
          tau = offsetTorque + (if time < startTime then 0 else stepTorque);
        end TorqueStep;
      end Sources;

      package Interfaces  "Connectors and partial models for 1D rotational mechanical components" 
        extends Modelica.Icons.InterfacesPackage;

        connector Flange_a  "1-dim. rotational flange of a shaft (filled square icon)" 
          .Modelica.SIunits.Angle phi "Absolute rotation angle of flange";
          flow .Modelica.SIunits.Torque tau "Cut torque in the flange";
        end Flange_a;

        connector Flange_b  "1-dim. rotational flange of a shaft (non-filled square icon)" 
          .Modelica.SIunits.Angle phi "Absolute rotation angle of flange";
          flow .Modelica.SIunits.Torque tau "Cut torque in the flange";
        end Flange_b;

        connector Support  "Support/housing of a 1-dim. rotational shaft" 
          .Modelica.SIunits.Angle phi "Absolute rotation angle of the support/housing";
          flow .Modelica.SIunits.Torque tau "Reaction torque in the support/housing";
        end Support;

        partial model PartialElementaryOneFlangeAndSupport2  "Partial model for a component with one rotational 1-dim. shaft flange and a support used for textual modeling, i.e., for elementary models" 
          parameter Boolean useSupport = false "= true, if support flange enabled, otherwise implicitly grounded" annotation(Evaluate = true, HideResult = true);
          Flange_b flange "Flange of shaft";
          Support support(phi = phi_support, tau = -flange.tau) if useSupport "Support/housing of component";
        protected
          Modelica.SIunits.Angle phi_support "Absolute angle of support flange";
        equation
          if not useSupport then
            phi_support = 0;
          end if;
        end PartialElementaryOneFlangeAndSupport2;

        partial model PartialTorque  "Partial model of a torque acting at the flange (accelerates the flange)" 
          extends Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport2;
          Modelica.SIunits.Angle phi "Angle of flange with respect to support (= flange.phi - support.phi)";
        equation
          phi = flange.phi - phi_support;
        end PartialTorque;
      end Interfaces;
    end Rotational;
  end Mechanics;

  package Thermal  "Library of thermal system components to model heat transfer and simple thermo-fluid pipe flow" 
    extends Modelica.Icons.Package;

    package HeatTransfer  "Library of 1-dimensional heat transfer with lumped elements" 
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models" 
        extends Modelica.Icons.InterfacesPackage;

        partial connector HeatPort  "Thermal port for 1-dim. heat transfer" 
          Modelica.SIunits.Temperature T "Port temperature";
          flow Modelica.SIunits.HeatFlowRate Q_flow "Heat flow rate (positive if flowing from outside into the component)";
        end HeatPort;

        connector HeatPort_a  "Thermal port for 1-dim. heat transfer (filled rectangular icon)" 
          extends HeatPort;
        end HeatPort_a;

        connector HeatPort_b  "Thermal port for 1-dim. heat transfer (unfilled rectangular icon)" 
          extends HeatPort;
        end HeatPort_b;
      end Interfaces;
    end HeatTransfer;
  end Thermal;

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

    package Streams  "Read from files and write to files" 
      extends Modelica.Icons.Package;

      function error  "Print error message and cancel all actions" 
        extends Modelica.Icons.Function;
        input String string "String to be printed to error message window";
        external "C" ModelicaError(string) annotation(Library = "ModelicaExternalC");
      end error;
    end Streams;

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
    final constant Real small = ModelicaServices.Machine.small "Smallest number such that small and -small are representable on the machine";
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

    partial package TypesPackage  "Icon for packages containing type definitions" 
      extends Modelica.Icons.Package;
    end TypesPackage;

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
    type Time = Real(final quantity = "Time", final unit = "s");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type AngularAcceleration = Real(final quantity = "AngularAcceleration", final unit = "rad/s2");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type AngularFrequency = Real(final quantity = "AngularFrequency", final unit = "rad/s");
    type MomentOfInertia = Real(final quantity = "MomentOfInertia", final unit = "kg.m2");
    type Inertia = MomentOfInertia;
    type Torque = Real(final quantity = "Torque", final unit = "N.m");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temp_K = ThermodynamicTemperature;
    type Temperature = ThermodynamicTemperature;
    type Heat = Real(final quantity = "Energy", final unit = "J");
    type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
    type ElectricCurrent = Real(final quantity = "ElectricCurrent", final unit = "A");
    type Current = ElectricCurrent;
    type ElectricPotential = Real(final quantity = "ElectricPotential", final unit = "V");
    type Voltage = ElectricPotential;
    type MagneticFlux = Real(final quantity = "MagneticFlux", final unit = "Wb");
    type Inductance = Real(final quantity = "Inductance", final unit = "H");
    type Resistance = Real(final quantity = "Resistance", final unit = "Ohm");
    type ApparentPower = Real(final quantity = "Power", final unit = "VA");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
  annotation(version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z"); 
end Modelica;

model SM_ctrlAv_total  "AC synchronous pm machine, current controlled with average inverter"
  extends PowerSystems.Examples.Spot.DrivesAC3ph.SM_ctrlAv;
 annotation(experiment(StopTime = 10));
end SM_ctrlAv_total;


