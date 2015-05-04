package ThermoPower
  extends Modelica.Icons.Package;

  model System
    parameter Boolean allowFlowReversal = true;
    parameter ThermoPower.Choices.System.Dynamics Dynamics = Choices.System.Dynamics.DynamicFreeInitial;
  end System;

  package Icons
    extends Modelica.Icons.Package;

    package Gas
      extends Modelica.Icons.Package;

      partial model SourceP  end SourceP;

      partial model SourceW  end SourceW;

      partial model Tube  end Tube;

      partial model Mixer  end Mixer;

      partial model Compressor  end Compressor;

      partial model Turbine  end Turbine;
    end Gas;
  end Icons;

  package Functions
    extends Modelica.Icons.Package;

    function squareReg
      extends Modelica.Icons.Function;
      input Real x;
      input Real delta = 0.01;
      output Real y;
    algorithm
      y := x * sqrt(x * x + delta * delta);
    end squareReg;
  end Functions;

  package Electrical
    extends Modelica.Icons.Package;

    connector PowerConnection
      flow .Modelica.SIunits.Power W;
      .Modelica.SIunits.Frequency f;
    end PowerConnection;

    model Generator
      parameter Real eta = 1;
      parameter Modelica.SIunits.MomentOfInertia J = 0;
      parameter Integer Np = 2;
      parameter Modelica.SIunits.Frequency fstart = 50;
      parameter ThermoPower.Choices.Init.Options initOpt = ThermoPower.Choices.Init.Options.noInit;
      Modelica.SIunits.Power Pm;
      Modelica.SIunits.Power Pe;
      Modelica.SIunits.Power Ploss;
      Modelica.SIunits.Torque tau;
      Modelica.SIunits.AngularVelocity omega_m(start = 2 * Modelica.Constants.pi * fstart / Np);
      Modelica.SIunits.AngularVelocity omega_e;
      .Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm n;
      Modelica.SIunits.Frequency f;
      PowerConnection powerConnection;
      Modelica.Mechanics.Rotational.Interfaces.Flange_a shaft;
    initial equation
      if initOpt == ThermoPower.Choices.Init.Options.noInit then
      elseif initOpt == ThermoPower.Choices.Init.Options.steadyState then
        der(omega_m) = 0;
      else
        assert(false, "Unsupported initialisation option");
      end if;
    equation
      omega_m = der(shaft.phi);
      omega_e = omega_m * Np;
      f = omega_e / (2 * Modelica.Constants.pi);
      n = Modelica.SIunits.Conversions.to_rpm(omega_m);
      Pm = omega_m * tau;
      if J > 0 then
        Ploss = J * der(omega_m) * omega_m;
      else
        Ploss = 0;
      end if;
      Pm = Pe / eta + Ploss;
      f = powerConnection.f;
      Pe = -powerConnection.W;
      tau = shaft.tau;
    end Generator;

    partial model Network1portBase
      parameter Boolean hasBreaker = false;
      parameter Modelica.SIunits.Angle deltaStart = 0;
      parameter ThermoPower.Choices.Init.Options initOpt = ThermoPower.Choices.Init.Options.noInit;
      parameter Modelica.SIunits.Power C;
      Modelica.SIunits.Power Pe;
      Modelica.SIunits.Power Ploss;
      Modelica.SIunits.AngularVelocity omega;
      Modelica.SIunits.AngularVelocity omegaRef;
      Modelica.SIunits.Angle delta(stateSelect = StateSelect.prefer, start = deltaStart);
      PowerConnection powerConnection;
      Modelica.Blocks.Interfaces.BooleanInput closed if hasBreaker;
    protected
      Modelica.Blocks.Interfaces.BooleanInput closedInternal;
    public
      Modelica.Blocks.Interfaces.RealOutput delta_out;
    initial equation
      if initOpt == ThermoPower.Choices.Init.Options.noInit then
      elseif initOpt == ThermoPower.Choices.Init.Options.steadyState then
        der(delta) = 0;
      else
        assert(false, "Unsupported initialisation option");
      end if;
    equation
      der(delta) = omega - omegaRef;
      if closedInternal then
        Pe = homotopy(C * Modelica.Math.sin(delta), C * delta);
      else
        Pe = 0;
      end if;
      Pe + Ploss = powerConnection.W;
      omega = 2 * Modelica.Constants.pi * powerConnection.f;
      if not hasBreaker then
        closedInternal = true;
      end if;
      connect(closed, closedInternal);
      delta_out = delta;
    end Network1portBase;

    model NetworkGrid_Pmax
      extends ThermoPower.Electrical.Network1portBase(final C = Pmax);
      parameter Modelica.SIunits.Power Pmax;
      parameter Modelica.SIunits.Frequency fnom = 50;
      parameter Modelica.SIunits.MomentOfInertia J = 0;
      parameter Real r = 0.2;
      parameter Integer Np = 2;
      Real D;
    equation
      omegaRef = 2 * Modelica.Constants.pi * fnom;
      if J > 0 then
        D = 2 * r * sqrt(C * J * 2 * Modelica.Constants.pi * fnom * Np / Np ^ 2);
      else
        D = 0;
      end if;
      if closedInternal then
        Ploss = D * der(delta);
      else
        Ploss = 0;
      end if;
    end NetworkGrid_Pmax;
  end Electrical;

  package Choices
    extends Modelica.Icons.Package;

    package PressDrop
      type FFtypes = enumeration(Kf, OpPoint, Kinetic);
    end PressDrop;

    package TurboMachinery
      type TableTypes = enumeration(matrix, file);
    end TurboMachinery;

    package Init
      type Options = enumeration(noInit, steadyState, steadyStateNoP, steadyStateNoT, steadyStateNoPT);
    end Init;

    package System
      type Dynamics = enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState);
    end System;
  end Choices;

  package Examples
    extends Modelica.Icons.ExamplesPackage;

    package RankineCycle
      extends Modelica.Icons.Package;

      package Models
        extends Modelica.Icons.Package;

        model PID
          parameter Real Kp;
          parameter Modelica.SIunits.Time Ti;
          parameter Boolean integralAction = true;
          parameter Modelica.SIunits.Time Td = 0;
          parameter Real Nd = 1;
          parameter Real Ni = 1;
          parameter Real b = 1;
          parameter Real c = 0;
          parameter Real PVmin;
          parameter Real PVmax;
          parameter Real CSmin;
          parameter Real CSmax;
          parameter Real PVstart = 0.5;
          parameter Real CSstart = 0.5;
          parameter Boolean holdWhenSimplified = false;
          parameter Boolean steadyStateInit = false;
          Real CSs_hom;
          Real P;
          Real I(start = CSstart / Kp);
          Real D;
          Real Dx(start = c * PVstart - PVstart);
          Real PVs;
          Real SPs;
          Real CSs(start = CSstart);
          Real CSbs(start = CSstart);
          Real track;
          Modelica.Blocks.Interfaces.RealInput PV;
          Modelica.Blocks.Interfaces.RealOutput CS;
          Modelica.Blocks.Interfaces.RealInput SP;
        initial equation
          if steadyStateInit then
            if Ti > 0 then
              der(I) = 0;
            end if;
            if Td > 0 then
              D = 0;
            end if;
          end if;
        equation
          SPs = (SP - PVmin) / (PVmax - PVmin);
          PVs = (PV - PVmin) / (PVmax - PVmin);
          CS = CSmin + CSs * (CSmax - CSmin);
          P = b * SPs - PVs;
          if integralAction then
            assert(Ti > 0, "Integral time must be positive");
            Ti * der(I) = SPs - PVs + track;
          else
            I = 0;
          end if;
          if Td > 0 then
            Td / Nd * der(Dx) + Dx = c * SPs - PVs;
            D = Nd * (c * SPs - PVs - Dx);
          else
            Dx = 0;
            D = 0;
          end if;
          if holdWhenSimplified then
            CSs_hom = CSstart;
          else
            CSs_hom = CSbs;
          end if;
          CSbs = Kp * (P + I + D);
          CSs = homotopy(smooth(0, if CSbs > 1 then 1 else if CSbs < 0 then 0 else CSbs), CSs_hom);
          track = (CSs - CSbs) / (Kp * Ni);
        end PID;
      end Models;
    end RankineCycle;

    package BraytonCycle
      extends Modelica.Icons.Package;

      model Plant
      protected
        parameter Real[6, 4] tableEtaC = [0, 95, 100, 105; 1, 0.825, 0.81, 0.805; 2, 0.84, 0.829, 0.82; 3, 0.832, 0.822, 0.815; 4, 0.825, 0.812, 0.79; 5, 0.795, 0.78, 0.765];
        parameter Real[6, 4] tablePhicC = [0, 95, 100, 105; 1, 0.0383, 0.043, 0.0468; 2, 0.0393, 0.0438, 0.0479; 3, 0.0406, 0.0452, 0.0484; 4, 0.0416, 0.0461, 0.0489; 5, 0.0423, 0.0466, 0.0493];
        parameter Real[6, 4] tablePR = [0, 95, 100, 105; 1, 22.6, 27, 32; 2, 22, 26.6, 30.8; 3, 20.8, 25.5, 29; 4, 19, 24.3, 27.1; 5, 17, 21.5, 24.2];
        parameter Real[5, 4] tablePhicT = [1, 90, 100, 110; 2.36, 0.00468, 0.00468, 0.00468; 2.88, 0.00468, 0.00468, 0.00468; 3.56, 0.00468, 0.00468, 0.00468; 4.46, 0.00468, 0.00468, 0.00468];
        parameter Real[5, 4] tableEtaT = [1, 90, 100, 110; 2.36, 0.89, 0.895, 0.893; 2.88, 0.9, 0.906, 0.905; 3.56, 0.905, 0.906, 0.905; 4.46, 0.902, 0.903, 0.9];
      public
        Electrical.Generator generator(initOpt = ThermoPower.Choices.Init.Options.steadyState, J = 30);
        Electrical.NetworkGrid_Pmax network(deltaStart = 0.4, initOpt = ThermoPower.Choices.Init.Options.steadyState, Pmax = 10000000.0, J = 30000);
        Modelica.Blocks.Interfaces.RealInput fuelFlowRate;
        Modelica.Blocks.Interfaces.RealOutput generatedPower;
        Gas.Compressor compressor(redeclare package Medium = Media.Air, tablePhic = tablePhicC, tableEta = tableEtaC, pstart_in = 34300.0, pstart_out = 830000.0, Tstart_in = 244.4, tablePR = tablePR, Table = ThermoPower.Choices.TurboMachinery.TableTypes.matrix, Tstart_out = 600.4, explicitIsentropicEnthalpy = true, Tdes_in = 244.4, Ndesign = 157.08);
        Gas.Turbine turbine(redeclare package Medium = Media.FlueGas, pstart_in = 785000.0, pstart_out = 152000.0, tablePhic = tablePhicT, tableEta = tableEtaT, Table = ThermoPower.Choices.TurboMachinery.TableTypes.matrix, Tstart_out = 800, Tdes_in = 1400, Tstart_in = 1370, Ndesign = 157.08);
        Gas.CombustionChamber CombustionChamber1(gamma = 1, Cm = 1, pstart = 811000.0, Tstart = 1370, V = 0.05, S = 0.05, initOpt = ThermoPower.Choices.Init.Options.steadyState, HH = 41600000.0);
        Gas.SourcePressure SourceP1(redeclare package Medium = Media.Air, p0 = 34300.0, T = 244.4);
        Gas.SinkPressure SinkP1(redeclare package Medium = Media.FlueGas, p0 = 152000.0, T = 800);
        Gas.SourceMassFlow SourceW1(redeclare package Medium = Media.NaturalGas, w0 = 2.02, p0 = 811000, T = 300, use_in_w0 = true);
        Gas.PressDrop PressDrop1(redeclare package Medium = Media.FlueGas, FFtype = ThermoPower.Choices.PressDrop.FFtypes.OpPoint, A = 1, pstart = 811000.0, dpnom = 26000.0, wnom = 102, Tstart = 1370, rhonom = 2);
        Gas.PressDrop PressDrop2(pstart = 830000.0, FFtype = ThermoPower.Choices.PressDrop.FFtypes.OpPoint, A = 1, redeclare package Medium = Media.Air, dpnom = 19000.0, wnom = 100, rhonom = 4.7, Tstart = 600);
        Modelica.Mechanics.Rotational.Sensors.PowerSensor powerSensor;
        Modelica.Blocks.Continuous.FirstOrder gasFlowActuator(k = 1, T = 4, y_start = 500, initType = Modelica.Blocks.Types.Init.SteadyState);
        Modelica.Blocks.Continuous.FirstOrder powerSensor1(k = 1, T = 1, y_start = 56800000.0, initType = Modelica.Blocks.Types.Init.SteadyState);
        PowerPlants.HRSG.Components.StateReader_gas stateInletCC(redeclare package Medium = Media.Air);
        PowerPlants.HRSG.Components.StateReader_gas stateOutletCC(redeclare package Medium = Media.FlueGas);
        inner System system(allowFlowReversal = false);
      equation
        connect(network.powerConnection, generator.powerConnection);
        connect(SourceW1.flange, CombustionChamber1.inf);
        connect(turbine.outlet, SinkP1.flange);
        connect(SourceP1.flange, compressor.inlet);
        connect(PressDrop1.outlet, turbine.inlet);
        connect(compressor.outlet, PressDrop2.inlet);
        connect(compressor.shaft_b, turbine.shaft_a);
        connect(powerSensor.flange_a, turbine.shaft_b);
        connect(gasFlowActuator.u, fuelFlowRate);
        connect(gasFlowActuator.y, SourceW1.in_w0);
        connect(powerSensor.power, powerSensor1.u);
        connect(powerSensor1.y, generatedPower);
        connect(CombustionChamber1.ina, stateInletCC.outlet);
        connect(stateInletCC.inlet, PressDrop2.outlet);
        connect(stateOutletCC.inlet, CombustionChamber1.out);
        connect(stateOutletCC.outlet, PressDrop1.inlet);
        connect(generator.shaft, powerSensor.flange_b);
      end Plant;

      model ClosedLoopSimulator
        Plant plant;
        Modelica.Blocks.Sources.Ramp powerSetPoint(offset = 4000000.0, height = 2000000.0, duration = 10, startTime = 500);
        RankineCycle.Models.PID pID(Ti = 5, PVmin = 2000000.0, PVmax = 12000000.0, CSmin = 0, CSmax = 4, steadyStateInit = true, Kp = 0.25, holdWhenSimplified = true);
        inner System system;
      equation
        connect(plant.fuelFlowRate, pID.CS);
        connect(pID.SP, powerSetPoint.y);
        connect(pID.PV, plant.generatedPower);
      end ClosedLoopSimulator;
    end BraytonCycle;
  end Examples;

  package Gas
    connector Flange
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
      flow Medium.MassFlowRate m_flow;
      Medium.AbsolutePressure p;
      stream Medium.SpecificEnthalpy h_outflow;
      stream Medium.MassFraction[Medium.nXi] Xi_outflow;
      stream Medium.ExtraProperty[Medium.nC] C_outflow;
    end Flange;

    connector FlangeA
      extends Flange;
    end FlangeA;

    connector FlangeB
      extends Flange;
    end FlangeB;

    extends Modelica.Icons.Package;

    model SourcePressure
      extends Icons.Gas.SourceP;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
      Medium.BaseProperties gas(p(start = p0), T(start = T), Xi(start = Xnom[1:Medium.nXi]));
      parameter .Modelica.SIunits.Pressure p0 = 101325;
      parameter HydraulicResistance R = 0;
      parameter AbsoluteTemperature T = 300;
      parameter .Modelica.SIunits.MassFraction[Medium.nX] Xnom = Medium.reference_X;
      parameter Boolean allowFlowReversal = system.allowFlowReversal;
      parameter Boolean use_in_p0 = false;
      parameter Boolean use_in_T = false;
      parameter Boolean use_in_X = false;
      outer ThermoPower.System system;
      FlangeB flange(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
      Modelica.Blocks.Interfaces.RealInput in_p0 if use_in_p0;
      Modelica.Blocks.Interfaces.RealInput in_T if use_in_T;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X if use_in_X;
    protected
      Modelica.Blocks.Interfaces.RealInput in_p0_internal;
      Modelica.Blocks.Interfaces.RealInput in_T_internal;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X_internal;
    equation
      if R == 0 then
        flange.p = gas.p;
      else
        flange.p = gas.p + flange.m_flow * R;
      end if;
      gas.p = in_p0_internal;
      if not use_in_p0 then
        in_p0_internal = p0;
      end if;
      gas.T = in_T_internal;
      if not use_in_T then
        in_T_internal = T;
      end if;
      gas.Xi = in_X_internal[1:Medium.nXi];
      if not use_in_X then
        in_X_internal = Xnom;
      end if;
      flange.h_outflow = gas.h;
      flange.Xi_outflow = gas.Xi;
      connect(in_p0, in_p0_internal);
      connect(in_T, in_T_internal);
      connect(in_X, in_X_internal);
    end SourcePressure;

    model SinkPressure
      extends Icons.Gas.SourceP;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
      Medium.BaseProperties gas(p(start = p0), T(start = T), Xi(start = Xnom[1:Medium.nXi]));
      parameter .Modelica.SIunits.Pressure p0 = 101325;
      parameter AbsoluteTemperature T = 300;
      parameter .Modelica.SIunits.MassFraction[Medium.nX] Xnom = Medium.reference_X;
      parameter HydraulicResistance R = 0;
      parameter Boolean allowFlowReversal = system.allowFlowReversal;
      parameter Boolean use_in_p0 = false;
      parameter Boolean use_in_T = false;
      parameter Boolean use_in_X = false;
      outer ThermoPower.System system;
      FlangeA flange(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      Modelica.Blocks.Interfaces.RealInput in_p0 if use_in_p0;
      Modelica.Blocks.Interfaces.RealInput in_T if use_in_T;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X if use_in_X;
    protected
      Modelica.Blocks.Interfaces.RealInput in_p0_internal;
      Modelica.Blocks.Interfaces.RealInput in_T_internal;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X_internal;
    equation
      if R == 0 then
        flange.p = gas.p;
      else
        flange.p = gas.p + flange.m_flow * R;
      end if;
      gas.p = in_p0_internal;
      if not use_in_p0 then
        in_p0_internal = p0;
      end if;
      gas.T = in_T_internal;
      if not use_in_T then
        in_T_internal = T;
      end if;
      gas.Xi = in_X_internal[1:Medium.nXi];
      if not use_in_X then
        in_X_internal = Xnom;
      end if;
      flange.h_outflow = gas.h;
      flange.Xi_outflow = gas.Xi;
      connect(in_p0, in_p0_internal);
      connect(in_T, in_T_internal);
      connect(in_X, in_X_internal);
    end SinkPressure;

    model SourceMassFlow
      extends Icons.Gas.SourceW;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
      Medium.BaseProperties gas(p(start = p0), T(start = T), Xi(start = Xnom[1:Medium.nXi]));
      parameter .Modelica.SIunits.Pressure p0 = 101325;
      parameter AbsoluteTemperature T = 300;
      parameter .Modelica.SIunits.MassFraction[Medium.nX] Xnom = Medium.reference_X;
      parameter .Modelica.SIunits.MassFlowRate w0 = 0;
      parameter HydraulicConductance G = 0;
      parameter Boolean allowFlowReversal = system.allowFlowReversal;
      parameter Boolean use_in_w0 = false;
      parameter Boolean use_in_T = false;
      parameter Boolean use_in_X = false;
      outer ThermoPower.System system;
      .Modelica.SIunits.MassFlowRate w;
      FlangeB flange(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
      Modelica.Blocks.Interfaces.RealInput in_w0 if use_in_w0;
      Modelica.Blocks.Interfaces.RealInput in_T if use_in_T;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X if use_in_X;
    protected
      Modelica.Blocks.Interfaces.RealInput in_w0_internal;
      Modelica.Blocks.Interfaces.RealInput in_T_internal;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X_internal;
    equation
      if G == 0 then
        flange.m_flow = -w;
      else
        flange.m_flow = -w + (flange.p - p0) * G;
      end if;
      w = in_w0_internal;
      if not use_in_w0 then
        in_w0_internal = w0;
      end if;
      gas.T = in_T_internal;
      if not use_in_T then
        in_T_internal = T;
      end if;
      gas.Xi = in_X_internal[1:Medium.nXi];
      if not use_in_X then
        in_X_internal = Xnom;
      end if;
      flange.p = gas.p;
      flange.h_outflow = gas.h;
      flange.Xi_outflow = gas.Xi;
      connect(in_w0, in_w0_internal);
      connect(in_T, in_T_internal);
      connect(in_X, in_X_internal);
    end SourceMassFlow;

    model PressDrop
      extends Icons.Gas.Tube;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
      Medium.BaseProperties gas(p(start = pstart), T(start = Tstart), Xi(start = Xstart[1:Medium.nXi]));
      parameter .Modelica.SIunits.MassFlowRate wnom;
      parameter .ThermoPower.Choices.PressDrop.FFtypes FFtype = .ThermoPower.Choices.PressDrop.FFtypes.Kf;
      parameter Real Kf(fixed = if FFtype == .ThermoPower.Choices.PressDrop.FFtypes.Kf then true else false, unit = "Pa.kg/(m3.kg2/s2)");
      parameter .Modelica.SIunits.Pressure dpnom = 0;
      parameter Density rhonom = 0;
      parameter Real K = 0;
      parameter .Modelica.SIunits.Area A = 0;
      parameter Real wnf = 0.01;
      parameter Real Kfc = 1;
      parameter Boolean allowFlowReversal = system.allowFlowReversal;
      outer ThermoPower.System system;
      parameter .Modelica.SIunits.Pressure pstart = 101325;
      parameter AbsoluteTemperature Tstart = 300;
      parameter .Modelica.SIunits.MassFraction[Medium.nX] Xstart = Medium.reference_X;
      function squareReg = ThermoPower.Functions.squareReg;
    protected
      parameter Real Kfl(fixed = false);
    public
      .Modelica.SIunits.MassFlowRate w;
      .Modelica.SIunits.Pressure pin;
      .Modelica.SIunits.Pressure pout;
      .Modelica.SIunits.Pressure dp;
      FlangeA inlet(redeclare package Medium = Medium, m_flow(start = wnom, min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      FlangeB outlet(redeclare package Medium = Medium, m_flow(start = -wnom, max = if allowFlowReversal then +Modelica.Constants.inf else 0));
    initial equation
      if FFtype == .ThermoPower.Choices.PressDrop.FFtypes.OpPoint then
        Kf = dpnom * rhonom / wnom ^ 2 * Kfc;
      elseif FFtype == .ThermoPower.Choices.PressDrop.FFtypes.Kinetic then
        Kf = K / (2 * A ^ 2) * Kfc;
      end if;
      Kfl = wnom * wnf * Kf;
      assert(Kf >= 0, "Negative friction coefficient");
    equation
      assert(dpnom > 0, "dpnom=0 not supported, it is also used in the homotopy trasformation during the inizialization");
      gas.p = homotopy(if not allowFlowReversal then pin else if inlet.m_flow >= 0 then pin else pout, pin);
      gas.h = homotopy(if not allowFlowReversal then inStream(inlet.h_outflow) else actualStream(inlet.h_outflow), inStream(inlet.h_outflow));
      gas.Xi = homotopy(if not allowFlowReversal then inStream(inlet.Xi_outflow) else actualStream(inlet.Xi_outflow), inStream(inlet.Xi_outflow));
      pin - pout = homotopy(smooth(1, Kf * squareReg(w, wnom * wnf)) / gas.d, dpnom / wnom * w);
      w = inlet.m_flow;
      pin = inlet.p;
      pout = outlet.p;
      dp = pin - pout;
      inlet.m_flow + outlet.m_flow = 0;
      inlet.h_outflow = inStream(outlet.h_outflow);
      inStream(inlet.h_outflow) = outlet.h_outflow;
      inlet.Xi_outflow = inStream(outlet.Xi_outflow);
      inStream(inlet.Xi_outflow) = outlet.Xi_outflow;
    end PressDrop;

    partial model CombustionChamberBase
      extends Icons.Gas.Mixer;
      replaceable package Air = Modelica.Media.Interfaces.PartialMedium;
      replaceable package Fuel = Modelica.Media.Interfaces.PartialMedium;
      replaceable package Exhaust = Modelica.Media.Interfaces.PartialMedium;
      parameter .Modelica.SIunits.Volume V;
      parameter .Modelica.SIunits.Area S = 0;
      parameter .Modelica.SIunits.CoefficientOfHeatTransfer gamma = 0;
      parameter .Modelica.SIunits.HeatCapacity Cm = 0;
      parameter .Modelica.SIunits.Temperature Tmstart = 300;
      parameter .Modelica.SIunits.SpecificEnthalpy HH;
      parameter Boolean allowFlowReversal = system.allowFlowReversal;
      outer ThermoPower.System system;
      parameter .Modelica.SIunits.Pressure pstart = 101325;
      parameter AbsoluteTemperature Tstart = 300;
      parameter .Modelica.SIunits.MassFraction[Exhaust.nX] Xstart = Exhaust.reference_X;
      parameter Choices.Init.Options initOpt = Choices.Init.Options.noInit;
      Exhaust.BaseProperties fluegas(p(start = pstart), T(start = Tstart), Xi(start = Xstart[1:Exhaust.nXi]));
      .Modelica.SIunits.Mass M;
      .Modelica.SIunits.Mass[Exhaust.nXi] MX;
      .Modelica.SIunits.InternalEnergy E;
      AbsoluteTemperature Tm(start = Tmstart);
      Air.SpecificEnthalpy hia;
      Fuel.SpecificEnthalpy hif;
      Exhaust.SpecificEnthalpy ho;
      .Modelica.SIunits.Power HR;
      .Modelica.SIunits.Time Tr;
      FlangeA ina(redeclare package Medium = Air, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      FlangeA inf(redeclare package Medium = Fuel, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      FlangeB out(redeclare package Medium = Exhaust, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
    initial equation
      if initOpt == Choices.Init.Options.noInit then
      elseif initOpt == Choices.Init.Options.steadyState then
        der(fluegas.p) = 0;
        der(fluegas.T) = 0;
        der(fluegas.Xi) = zeros(Exhaust.nXi);
        if Cm > 0 and gamma > 0 then
          der(Tm) = 0;
        end if;
      elseif initOpt == Choices.Init.Options.steadyStateNoP then
        der(fluegas.T) = 0;
        der(fluegas.Xi) = zeros(Exhaust.nXi);
        if Cm > 0 and gamma > 0 then
          der(Tm) = 0;
        end if;
      else
        assert(false, "Unsupported initialisation option");
      end if;
    equation
      M = fluegas.d * V;
      E = fluegas.u * M;
      MX = fluegas.Xi * M;
      HR = inf.m_flow * HH;
      der(M) = ina.m_flow + inf.m_flow + out.m_flow;
      der(E) = ina.m_flow * hia + inf.m_flow * hif + out.m_flow * ho + HR - gamma * S * (fluegas.T - Tm);
      if Cm > 0 and gamma > 0 then
        Cm * der(Tm) = gamma * S * (fluegas.T - Tm);
      else
        Tm = fluegas.T;
      end if;
      out.p = fluegas.p;
      out.h_outflow = fluegas.h;
      out.Xi_outflow = fluegas.Xi;
      ina.p = fluegas.p;
      ina.h_outflow = 0;
      ina.Xi_outflow = Air.reference_X[1:Air.nXi];
      inf.p = fluegas.p;
      inf.h_outflow = 0;
      inf.Xi_outflow = Fuel.reference_X[1:Fuel.nXi];
      assert(ina.m_flow >= 0, "The model does not support flow reversal");
      hia = inStream(ina.h_outflow);
      assert(inf.m_flow >= 0, "The model does not support flow reversal");
      hif = inStream(inf.h_outflow);
      assert(out.m_flow <= 0, "The model does not support flow reversal");
      ho = fluegas.h;
      Tr = noEvent(M / max(abs(out.m_flow), Modelica.Constants.eps));
    end CombustionChamberBase;

    model CombustionChamber
      extends CombustionChamberBase(redeclare package Air = Media.Air, redeclare package Fuel = Media.NaturalGas, redeclare package Exhaust = Media.FlueGas);
      Real wcomb(final quantity = "MolarFlowRate", unit = "mol/s");
      Real lambda;
    protected
      Real[Air.nXi] ina_X = inStream(ina.Xi_outflow);
      Real[Fuel.nXi] inf_X = inStream(inf.Xi_outflow);
    equation
      wcomb = inf.m_flow * inf_X[3] / Fuel.data[3].MM;
      lambda = ina.m_flow * ina_X[1] / Air.data[1].MM / (2 * wcomb);
      assert(lambda >= 1, "Not enough oxygen flow");
      der(MX[1]) = ina.m_flow * ina_X[1] + out.m_flow * fluegas.X[1] - 2 * wcomb * Exhaust.data[1].MM;
      der(MX[2]) = ina.m_flow * ina_X[3] + out.m_flow * fluegas.X[2];
      der(MX[3]) = ina.m_flow * ina_X[2] + out.m_flow * fluegas.X[3] + 2 * wcomb * Exhaust.data[3].MM;
      der(MX[4]) = inf.m_flow * inf_X[2] + out.m_flow * fluegas.X[4] + wcomb * Exhaust.data[4].MM;
      der(MX[5]) = ina.m_flow * ina_X[4] + out.m_flow * fluegas.X[5] + inf.m_flow * inf_X[1];
    end CombustionChamber;

    partial model CompressorBase
      extends ThermoPower.Icons.Gas.Compressor;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
      parameter Boolean explicitIsentropicEnthalpy = true;
      parameter Real eta_mech = 0.98;
      parameter Modelica.SIunits.Pressure pstart_in;
      parameter Modelica.SIunits.Pressure pstart_out;
      parameter ThermoPower.AbsoluteTemperature Tdes_in;
      parameter Boolean allowFlowReversal = system.allowFlowReversal;
      outer ThermoPower.System system;
      parameter ThermoPower.AbsoluteTemperature Tstart_in = Tdes_in;
      parameter ThermoPower.AbsoluteTemperature Tstart_out;
      parameter Modelica.SIunits.MassFraction[Medium.nX] Xstart = Medium.reference_X;
      Medium.BaseProperties gas_in(p(start = pstart_in), T(start = Tstart_in), Xi(start = Xstart[1:Medium.nXi]));
      Medium.BaseProperties gas_iso(p(start = pstart_out), T(start = Tstart_out), Xi(start = Xstart[1:Medium.nXi]));
      Medium.SpecificEnthalpy hout_iso;
      Medium.SpecificEnthalpy hout;
      Medium.SpecificEntropy s_in;
      Medium.AbsolutePressure pout(start = pstart_out);
      Modelica.SIunits.MassFlowRate w;
      Modelica.SIunits.Angle phi;
      Modelica.SIunits.AngularVelocity omega;
      Modelica.SIunits.Torque tau;
      Real eta;
      Real PR;
      FlangeA inlet(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      FlangeB outlet(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a shaft_a;
      Modelica.Mechanics.Rotational.Interfaces.Flange_b shaft_b;
    equation
      w = inlet.m_flow;
      assert(w >= 0, "The compressor model does not support flow reversal");
      inlet.m_flow + outlet.m_flow = 0;
      gas_in.p = inlet.p;
      gas_in.h = inStream(inlet.h_outflow);
      gas_in.Xi = inStream(inlet.Xi_outflow);
      outlet.p = pout;
      outlet.h_outflow = hout;
      outlet.Xi_outflow = gas_in.Xi;
      inlet.h_outflow = inStream(outlet.h_outflow);
      inlet.Xi_outflow = inStream(outlet.Xi_outflow);
      gas_iso.Xi = gas_in.Xi;
      if explicitIsentropicEnthalpy then
        hout_iso = Medium.isentropicEnthalpy(outlet.p, gas_in.state);
        hout - gas_in.h = 1 / eta * (hout_iso - gas_in.h);
        s_in = 0;
        gas_iso.p = 100000.0;
        gas_iso.T = 300;
      else
        gas_iso.p = pout;
        s_in = Medium.specificEntropy(gas_in.state);
        s_in = Medium.specificEntropy(gas_iso.state);
        hout - gas_in.h = 1 / eta * (gas_iso.h - gas_in.h);
        hout_iso = 0;
      end if;
      w * (hout - gas_in.h) = tau * omega * eta_mech;
      PR = pout / gas_in.p;
      shaft_a.phi = phi;
      shaft_b.phi = phi;
      shaft_a.tau + shaft_b.tau = tau;
      der(phi) = omega;
    end CompressorBase;

    model Compressor
      extends CompressorBase;
      parameter .Modelica.SIunits.AngularVelocity Ndesign;
      parameter Real[:, :] tablePhic = fill(0, 0, 2);
      parameter Real[:, :] tableEta = fill(0, 0, 2);
      parameter Real[:, :] tablePR = fill(0, 0, 2);
      parameter String fileName = "noName";
      parameter .ThermoPower.Choices.TurboMachinery.TableTypes Table;
      Modelica.Blocks.Tables.CombiTable2D Eta(tableOnFile = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then false else true, table = tableEta, tableName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else "tabEta", fileName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else fileName, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative);
      Modelica.Blocks.Tables.CombiTable2D PressRatio(tableOnFile = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then false else true, table = tablePR, tableName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else "tabPR", fileName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else fileName, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative);
      Modelica.Blocks.Tables.CombiTable2D Phic(tableOnFile = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then false else true, table = tablePhic, tableName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else "tabPhic", fileName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else fileName, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative);
      Real N_T;
      Real N_T_design;
      Real phic(final unit = "(kg/s)*(T^0.5)/Pa");
      Real beta(start = integer(size(tablePhic, 1) / 2));
    equation
      N_T_design = Ndesign / sqrt(Tdes_in);
      N_T = 100 * omega / (sqrt(gas_in.T) * N_T_design);
      phic = w * sqrt(gas_in.T) / gas_in.p;
      Phic.u1 = beta;
      Phic.u2 = N_T;
      phic = Phic.y;
      Eta.u1 = beta;
      Eta.u2 = N_T;
      eta = Eta.y;
      PressRatio.u1 = beta;
      PressRatio.u2 = N_T;
      PR = PressRatio.y;
    end Compressor;

    partial model TurbineBase
      extends ThermoPower.Icons.Gas.Turbine;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
      parameter Boolean explicitIsentropicEnthalpy = true;
      parameter Real eta_mech = 0.98;
      parameter ThermoPower.AbsoluteTemperature Tdes_in;
      parameter Boolean allowFlowReversal = system.allowFlowReversal;
      outer ThermoPower.System system;
      parameter Modelica.SIunits.Pressure pstart_in;
      parameter Modelica.SIunits.Pressure pstart_out;
      parameter ThermoPower.AbsoluteTemperature Tstart_in = Tdes_in;
      parameter ThermoPower.AbsoluteTemperature Tstart_out;
      parameter Modelica.SIunits.MassFraction[Medium.nX] Xstart = Medium.reference_X;
      Medium.BaseProperties gas_in(p(start = pstart_in), T(start = Tstart_in), Xi(start = Xstart[1:Medium.nXi]));
      Medium.BaseProperties gas_iso(p(start = pstart_out), T(start = Tstart_out), Xi(start = Xstart[1:Medium.nXi]));
      Modelica.SIunits.Angle phi;
      Modelica.SIunits.Torque tau;
      Modelica.SIunits.AngularVelocity omega;
      Modelica.SIunits.MassFlowRate w;
      Medium.SpecificEntropy s_in;
      Medium.SpecificEnthalpy hout_iso;
      Medium.SpecificEnthalpy hout;
      Medium.AbsolutePressure pout(start = pstart_out);
      Real PR;
      Real eta;
      Modelica.Mechanics.Rotational.Interfaces.Flange_a shaft_a;
      Modelica.Mechanics.Rotational.Interfaces.Flange_b shaft_b;
      FlangeA inlet(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      FlangeB outlet(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
    equation
      w = inlet.m_flow;
      assert(w >= 0, "The turbine model does not support flow reversal");
      inlet.m_flow + outlet.m_flow = 0;
      gas_in.p = inlet.p;
      gas_in.h = inStream(inlet.h_outflow);
      gas_in.Xi = inStream(inlet.Xi_outflow);
      outlet.p = pout;
      outlet.h_outflow = hout;
      outlet.Xi_outflow = gas_in.Xi;
      inlet.h_outflow = inStream(outlet.h_outflow);
      inlet.Xi_outflow = inStream(outlet.Xi_outflow);
      gas_iso.Xi = gas_in.Xi;
      if explicitIsentropicEnthalpy then
        hout_iso = Medium.isentropicEnthalpy(outlet.p, gas_in.state);
        hout - gas_in.h = eta * (hout_iso - gas_in.h);
        s_in = 0;
        gas_iso.p = 100000.0;
        gas_iso.T = 300;
      else
        gas_iso.p = pout;
        s_in = Medium.specificEntropy(gas_in.state);
        s_in = Medium.specificEntropy(gas_iso.state);
        hout - gas_in.h = eta * (gas_iso.h - gas_in.h);
        hout_iso = 0;
      end if;
      w * (hout - gas_in.h) * eta_mech = tau * omega;
      PR = gas_in.p / pout;
      shaft_a.phi = phi;
      shaft_b.phi = phi;
      shaft_a.tau + shaft_b.tau = tau;
      der(phi) = omega;
    end TurbineBase;

    model Turbine
      extends TurbineBase;
      parameter .Modelica.SIunits.AngularVelocity Ndesign;
      parameter Real[:, :] tablePhic = fill(0, 0, 2);
      parameter Real[:, :] tableEta = fill(0, 0, 2);
      parameter String fileName = "NoName";
      parameter .ThermoPower.Choices.TurboMachinery.TableTypes Table;
      Real N_T;
      Real N_T_design;
      Real phic;
      Modelica.Blocks.Tables.CombiTable2D Phic(tableOnFile = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then false else true, table = tablePhic, tableName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else "tabPhic", fileName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else fileName, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative);
      Modelica.Blocks.Tables.CombiTable2D Eta(tableOnFile = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then false else true, table = tableEta, tableName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else "tabEta", fileName = if Table == .ThermoPower.Choices.TurboMachinery.TableTypes.matrix then "NoName" else fileName, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative);
    equation
      N_T_design = Ndesign / sqrt(Tdes_in);
      N_T = 100 * omega / (sqrt(gas_in.T) * N_T_design);
      phic = w * sqrt(gas_in.T) / gas_in.p;
      Phic.u1 = PR;
      Phic.u2 = N_T;
      phic = Phic.y;
      Eta.u1 = PR;
      Eta.u2 = N_T;
      eta = Eta.y;
    end Turbine;
  end Gas;

  package Media
    extends Modelica.Icons.Package;

    package Air
      extends .Modelica.Media.IdealGases.Common.MixtureGasNasa(mediumName = "Air", data = {.Modelica.Media.IdealGases.Common.SingleGasesData.O2, .Modelica.Media.IdealGases.Common.SingleGasesData.H2O, .Modelica.Media.IdealGases.Common.SingleGasesData.Ar, .Modelica.Media.IdealGases.Common.SingleGasesData.N2}, fluidConstants = {.Modelica.Media.IdealGases.Common.FluidData.O2, .Modelica.Media.IdealGases.Common.FluidData.H2O, .Modelica.Media.IdealGases.Common.FluidData.Ar, .Modelica.Media.IdealGases.Common.FluidData.N2}, substanceNames = {"Oxygen", "Water", "Argon", "Nitrogen"}, reference_X = {0.23, 0.015, 0.005, 0.75});
    end Air;

    package NaturalGas
      extends .Modelica.Media.IdealGases.Common.MixtureGasNasa(mediumName = "NaturalGas", data = {.Modelica.Media.IdealGases.Common.SingleGasesData.N2, .Modelica.Media.IdealGases.Common.SingleGasesData.CO2, .Modelica.Media.IdealGases.Common.SingleGasesData.CH4}, substanceNames = {"Nitrogen", "Carbondioxide", "Methane"}, reference_X = {0.02, 0.012, 0.968});
    end NaturalGas;

    package FlueGas
      extends .Modelica.Media.IdealGases.Common.MixtureGasNasa(mediumName = "FlueGas", data = {.Modelica.Media.IdealGases.Common.SingleGasesData.O2, .Modelica.Media.IdealGases.Common.SingleGasesData.Ar, .Modelica.Media.IdealGases.Common.SingleGasesData.H2O, .Modelica.Media.IdealGases.Common.SingleGasesData.CO2, .Modelica.Media.IdealGases.Common.SingleGasesData.N2}, fluidConstants = {.Modelica.Media.IdealGases.Common.FluidData.O2, .Modelica.Media.IdealGases.Common.FluidData.Ar, .Modelica.Media.IdealGases.Common.FluidData.H2O, .Modelica.Media.IdealGases.Common.FluidData.CO2, .Modelica.Media.IdealGases.Common.FluidData.N2}, substanceNames = {"Oxygen", "Argon", "Water", "Carbondioxide", "Nitrogen"}, reference_X = {0.23, 0.02, 0.01, 0.04, 0.7});
    end FlueGas;
  end Media;

  package PowerPlants
    extends Modelica.Icons.Package;

    package HRSG
      package Components
        model BaseReader_gas
          replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
          parameter Boolean allowFlowReversal = system.allowFlowReversal;
          outer ThermoPower.System system;
          Gas.FlangeA inlet(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
          Gas.FlangeB outlet(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
        equation
          inlet.m_flow + outlet.m_flow = 0;
          inlet.p = outlet.p;
          inlet.h_outflow = inStream(outlet.h_outflow);
          inStream(inlet.h_outflow) = outlet.h_outflow;
          inlet.Xi_outflow = inStream(outlet.Xi_outflow);
          inStream(inlet.Xi_outflow) = outlet.Xi_outflow;
        end BaseReader_gas;

        model StateReader_gas
          extends BaseReader_gas;
          Medium.BaseProperties gas;
          .Modelica.SIunits.Temperature T;
          .Modelica.SIunits.Pressure p;
          .Modelica.SIunits.SpecificEnthalpy h;
          .Modelica.SIunits.MassFlowRate w;
        equation
          inlet.p = gas.p;
          gas.h = homotopy(if not allowFlowReversal then inStream(inlet.h_outflow) else actualStream(inlet.h_outflow), inStream(inlet.h_outflow));
          gas.Xi = homotopy(if not allowFlowReversal then inStream(inlet.Xi_outflow) else actualStream(inlet.Xi_outflow), inStream(inlet.Xi_outflow));
          T = gas.T;
          p = gas.p;
          h = gas.h;
          w = inlet.m_flow;
        end StateReader_gas;
      end Components;
    end HRSG;
  end PowerPlants;

  type HydraulicConductance = Real(final quantity = "HydraulicConductance", final unit = "(kg/s)/Pa");
  type HydraulicResistance = Real(final quantity = "HydraulicResistance", final unit = "Pa/(kg/s)");
  type Density = Modelica.SIunits.Density(start = 40);
  type AbsoluteTemperature = .Modelica.SIunits.Temperature(start = 300, nominal = 500);
end ThermoPower;

package ModelicaServices
  extends Modelica.Icons.Package;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 0.000000000000001;
    final constant Real small = 1e-60;
    final constant Real inf = 1e+60;
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax();
  end Machine;
end ModelicaServices;

package Modelica
  extends Modelica.Icons.Package;

  package Blocks
    extends Modelica.Icons.Package;

    package Continuous
      extends Modelica.Icons.Package;

      block FirstOrder
        parameter Real k(unit = "1") = 1;
        parameter .Modelica.SIunits.Time T(start = 1);
        parameter Modelica.Blocks.Types.Init initType = Modelica.Blocks.Types.Init.NoInit;
        parameter Real y_start = 0;
        extends .Modelica.Blocks.Interfaces.SISO(y(start = y_start));
      initial equation
        if initType == .Modelica.Blocks.Types.Init.SteadyState then
          der(y) = 0;
        elseif initType == .Modelica.Blocks.Types.Init.InitialState or initType == .Modelica.Blocks.Types.Init.InitialOutput then
          y = y_start;
        end if;
      equation
        der(y) = (k * u - y) / T;
      end FirstOrder;
    end Continuous;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real;
      connector RealOutput = output Real;
      connector BooleanInput = input Boolean;

      partial block SO
        extends Modelica.Blocks.Icons.Block;
        RealOutput y;
      end SO;

      partial block SISO
        extends Modelica.Blocks.Icons.Block;
        RealInput u;
        RealOutput y;
      end SISO;

      partial block SI2SO
        extends Modelica.Blocks.Icons.Block;
        RealInput u1;
        RealInput u2;
        RealOutput y;
      end SI2SO;
    end Interfaces;

    package Sources
      extends Modelica.Icons.SourcesPackage;

      block Ramp
        parameter Real height = 1;
        parameter Modelica.SIunits.Time duration(min = 0.0, start = 2);
        parameter Real offset = 0;
        parameter Modelica.SIunits.Time startTime = 0;
        extends .Modelica.Blocks.Interfaces.SO;
      equation
        y = offset + (if time < startTime then 0 else if time < startTime + duration then (time - startTime) * height / duration else height);
      end Ramp;
    end Sources;

    package Tables
      extends Modelica.Icons.Package;

      block CombiTable2D
        extends Modelica.Blocks.Interfaces.SI2SO;
        parameter Boolean tableOnFile = false;
        parameter Real[:, :] table = fill(0.0, 0, 2);
        parameter String tableName = "NoName";
        parameter String fileName = "NoName";
        parameter Boolean verboseRead = true;
        parameter Modelica.Blocks.Types.Smoothness smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments;
      protected
        Modelica.Blocks.Types.ExternalCombiTable2D tableID = Modelica.Blocks.Types.ExternalCombiTable2D(if tableOnFile then tableName else "NoName", if tableOnFile and fileName <> "NoName" and not Modelica.Utilities.Strings.isEmpty(fileName) then fileName else "NoName", table, smoothness);
        Real tableOnFileRead;

        function readTableData
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTable2D tableID;
          input Boolean forceRead = false;
          input Boolean verboseRead;
          output Real readSuccess;
          external "C" readSuccess = ModelicaStandardTables_CombiTable2D_read(tableID, forceRead, verboseRead);
        end readTableData;

        function getTableValue
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTable2D tableID;
          input Real u1;
          input Real u2;
          input Real tableAvailable;
          output Real y;
          external "C" y = ModelicaStandardTables_CombiTable2D_getValue(tableID, u1, u2);
        end getTableValue;

        function getTableValueNoDer
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTable2D tableID;
          input Real u1;
          input Real u2;
          input Real tableAvailable;
          output Real y;
          external "C" y = ModelicaStandardTables_CombiTable2D_getValue(tableID, u1, u2);
        end getTableValueNoDer;

        function getDerTableValue
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTable2D tableID;
          input Real u1;
          input Real u2;
          input Real tableAvailable;
          input Real der_u1;
          input Real der_u2;
          output Real der_y;
          external "C" der_y = ModelicaStandardTables_CombiTable2D_getDerValue(tableID, u1, u2, der_u1, der_u2);
        end getDerTableValue;
      equation
        when initial() then
          if tableOnFile then
            tableOnFileRead = readTableData(tableID, false, verboseRead);
          else
            tableOnFileRead = 1.0;
          end if;
        end when;
        if tableOnFile then
          assert(tableName <> "NoName", "tableOnFile = true and no table name given");
        else
          assert(size(table, 1) > 0 and size(table, 2) > 0, "tableOnFile = false and parameter table is an empty matrix");
        end if;
        if smoothness == Modelica.Blocks.Types.Smoothness.ConstantSegments then
          y = getTableValueNoDer(tableID, u1, u2, tableOnFileRead);
        else
          y = getTableValue(tableID, u1, u2, tableOnFileRead);
        end if;
      end CombiTable2D;
    end Tables;

    package Types
      extends Modelica.Icons.TypesPackage;
      type Smoothness = enumeration(LinearSegments, ContinuousDerivative, ConstantSegments);
      type Init = enumeration(NoInit, SteadyState, InitialState, InitialOutput);

      class ExternalCombiTable2D
        extends ExternalObject;

        function constructor
          extends Modelica.Icons.Function;
          input String tableName;
          input String fileName;
          input Real[:, :] table;
          input Modelica.Blocks.Types.Smoothness smoothness;
          output ExternalCombiTable2D externalCombiTable2D;
          external "C" externalCombiTable2D = ModelicaStandardTables_CombiTable2D_init(tableName, fileName, table, size(table, 1), size(table, 2), smoothness);
        end constructor;

        function destructor
          extends Modelica.Icons.Function;
          input ExternalCombiTable2D externalCombiTable2D;
          external "C" ModelicaStandardTables_CombiTable2D_close(externalCombiTable2D);
        end destructor;
      end ExternalCombiTable2D;
    end Types;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial block Block  end Block;
    end Icons;
  end Blocks;

  package Mechanics
    extends Modelica.Icons.Package;

    package Rotational
      extends Modelica.Icons.Package;

      package Sensors
        extends Modelica.Icons.SensorsPackage;

        model PowerSensor
          extends Rotational.Interfaces.PartialRelativeSensor;
          Modelica.Blocks.Interfaces.RealOutput power(unit = "W");
        equation
          flange_a.phi = flange_b.phi;
          power = flange_a.tau * der(flange_a.phi);
        end PowerSensor;
      end Sensors;

      package Interfaces
        extends Modelica.Icons.InterfacesPackage;

        connector Flange_a
          .Modelica.SIunits.Angle phi;
          flow .Modelica.SIunits.Torque tau;
        end Flange_a;

        connector Flange_b
          .Modelica.SIunits.Angle phi;
          flow .Modelica.SIunits.Torque tau;
        end Flange_b;

        partial model PartialRelativeSensor
          extends Modelica.Icons.RotationalSensor;
          Flange_a flange_a;
          Flange_b flange_b;
        equation
          0 = flange_a.tau + flange_b.tau;
        end PartialRelativeSensor;
      end Interfaces;
    end Rotational;
  end Mechanics;

  package Media
    extends Modelica.Icons.Package;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;

      partial package PartialMedium
        extends Modelica.Media.Interfaces.Types;
        extends Modelica.Icons.MaterialPropertiesPackage;
        constant Modelica.Media.Interfaces.Choices.IndependentVariables ThermoStates;
        constant String mediumName = "unusablePartialMedium";
        constant String[:] substanceNames = {mediumName};
        constant String[:] extraPropertiesNames = fill("", 0);
        constant Boolean singleState;
        constant Boolean reducedX = true;
        constant Boolean fixedX = false;
        constant AbsolutePressure reference_p = 101325;
        constant MassFraction[nX] reference_X = fill(1 / nX, nX);
        constant AbsolutePressure p_default = 101325;
        constant Temperature T_default = Modelica.SIunits.Conversions.from_degC(20);
        constant MassFraction[nX] X_default = reference_X;
        final constant Integer nS = size(substanceNames, 1);
        constant Integer nX = nS;
        constant Integer nXi = if fixedX then 0 else if reducedX then nS - 1 else nS;
        final constant Integer nC = size(extraPropertiesNames, 1);
        replaceable record FluidConstants = Modelica.Media.Interfaces.Types.Basic.FluidConstants;

        replaceable record ThermodynamicState
          extends Modelica.Icons.Record;
        end ThermodynamicState;

        replaceable partial model BaseProperties
          InputAbsolutePressure p;
          InputMassFraction[nXi] Xi(start = reference_X[1:nXi]);
          InputSpecificEnthalpy h;
          Density d;
          Temperature T;
          MassFraction[nX] X(start = reference_X);
          SpecificInternalEnergy u;
          SpecificHeatCapacity R;
          MolarMass MM;
          ThermodynamicState state;
          parameter Boolean preferredMediumStates = false;
          parameter Boolean standardOrderComponents = true;
          .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_degC = Modelica.SIunits.Conversions.to_degC(T);
          .Modelica.SIunits.Conversions.NonSIunits.Pressure_bar p_bar = Modelica.SIunits.Conversions.to_bar(p);
          connector InputAbsolutePressure = input .Modelica.SIunits.AbsolutePressure;
          connector InputSpecificEnthalpy = input .Modelica.SIunits.SpecificEnthalpy;
          connector InputMassFraction = input .Modelica.SIunits.MassFraction;
        equation
          if standardOrderComponents then
            Xi = X[1:nXi];
            if fixedX then
              X = reference_X;
            end if;
            if reducedX and not fixedX then
              X[nX] = 1 - sum(Xi);
            end if;
            for i in 1:nX loop
              assert(X[i] >= -0.00001 and X[i] <= 1 + 0.00001, "Mass fraction X[" + String(i) + "] = " + String(X[i]) + "of substance " + substanceNames[i] + "\nof medium " + mediumName + " is not in the range 0..1");
            end for;
          end if;
          assert(p >= 0.0, "Pressure (= " + String(p) + " Pa) of medium \"" + mediumName + "\" is negative\n(Temperature = " + String(T) + " K)");
        end BaseProperties;

        replaceable partial function setState_pTX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        end setState_pTX;

        replaceable partial function setState_psX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEntropy s;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        end setState_psX;

        replaceable partial function setSmoothState
          extends Modelica.Icons.Function;
          input Real x;
          input ThermodynamicState state_a;
          input ThermodynamicState state_b;
          input Real x_small(min = 0);
          output ThermodynamicState state;
        end setSmoothState;

        replaceable partial function dynamicViscosity
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output DynamicViscosity eta;
        end dynamicViscosity;

        replaceable partial function thermalConductivity
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output ThermalConductivity lambda;
        end thermalConductivity;

        replaceable partial function pressure
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output AbsolutePressure p;
        end pressure;

        replaceable partial function temperature
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output Temperature T;
        end temperature;

        replaceable partial function density
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output Density d;
        end density;

        replaceable partial function specificEnthalpy
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output SpecificEnthalpy h;
        end specificEnthalpy;

        replaceable partial function specificInternalEnergy
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output SpecificEnergy u;
        end specificInternalEnergy;

        replaceable partial function specificEntropy
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output SpecificEntropy s;
        end specificEntropy;

        replaceable partial function specificGibbsEnergy
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output SpecificEnergy g;
        end specificGibbsEnergy;

        replaceable partial function specificHelmholtzEnergy
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output SpecificEnergy f;
        end specificHelmholtzEnergy;

        replaceable partial function specificHeatCapacityCp
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output SpecificHeatCapacity cp;
        end specificHeatCapacityCp;

        replaceable partial function specificHeatCapacityCv
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output SpecificHeatCapacity cv;
        end specificHeatCapacityCv;

        replaceable partial function isentropicExponent
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output IsentropicExponent gamma;
        end isentropicExponent;

        replaceable partial function isentropicEnthalpy
          extends Modelica.Icons.Function;
          input AbsolutePressure p_downstream;
          input ThermodynamicState refState;
          output SpecificEnthalpy h_is;
        end isentropicEnthalpy;

        replaceable partial function velocityOfSound
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output VelocityOfSound a;
        end velocityOfSound;

        replaceable partial function isobaricExpansionCoefficient
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output IsobaricExpansionCoefficient beta;
        end isobaricExpansionCoefficient;

        replaceable partial function isothermalCompressibility
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output .Modelica.SIunits.IsothermalCompressibility kappa;
        end isothermalCompressibility;

        replaceable partial function density_derp_T
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output DerDensityByPressure ddpT;
        end density_derp_T;

        replaceable partial function density_derT_p
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output DerDensityByTemperature ddTp;
        end density_derT_p;

        replaceable partial function molarMass
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output MolarMass MM;
        end molarMass;

        replaceable function specificEnthalpy_pTX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output SpecificEnthalpy h;
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X));
        end specificEnthalpy_pTX;

        replaceable function specificEnthalpy_psX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEntropy s;
          input MassFraction[:] X = reference_X;
          output SpecificEnthalpy h;
        algorithm
          h := specificEnthalpy(setState_psX(p, s, X));
        end specificEnthalpy_psX;

        type MassFlowRate = .Modelica.SIunits.MassFlowRate(quantity = "MassFlowRate." + mediumName, min = -100000.0, max = 100000.0);
      end PartialMedium;

      partial package PartialMixtureMedium
        extends PartialMedium(redeclare replaceable record FluidConstants = Modelica.Media.Interfaces.Types.IdealGas.FluidConstants);

        redeclare replaceable record extends ThermodynamicState
          AbsolutePressure p;
          Temperature T;
          MassFraction[nX] X;
        end ThermodynamicState;

        constant FluidConstants[nS] fluidConstants;

        replaceable function gasConstant
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output .Modelica.SIunits.SpecificHeatCapacity R;
        end gasConstant;

        function massToMoleFractions
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.MassFraction[:] X;
          input .Modelica.SIunits.MolarMass[:] MMX;
          output .Modelica.SIunits.MoleFraction[size(X, 1)] moleFractions;
        protected
          Real[size(X, 1)] invMMX;
          .Modelica.SIunits.MolarMass Mmix;
        algorithm
          for i in 1:size(X, 1) loop
            invMMX[i] := 1 / MMX[i];
          end for;
          Mmix := 1 / (X * invMMX);
          for i in 1:size(X, 1) loop
            moleFractions[i] := Mmix * X[i] / MMX[i];
          end for;
        end massToMoleFractions;
      end PartialMixtureMedium;

      package Choices
        extends Modelica.Icons.Package;
        type IndependentVariables = enumeration(T, pT, ph, phX, pTX, dTX);
        type ReferenceEnthalpy = enumeration(ZeroAt0K, ZeroAt25C, UserDefined);
      end Choices;

      package Types
        extends Modelica.Icons.Package;
        type AbsolutePressure = .Modelica.SIunits.AbsolutePressure(min = 0, max = 100000000.0, nominal = 100000.0, start = 100000.0);
        type Density = .Modelica.SIunits.Density(min = 0, max = 100000.0, nominal = 1, start = 1);
        type DynamicViscosity = .Modelica.SIunits.DynamicViscosity(min = 0, max = 100000000.0, nominal = 0.001, start = 0.001);
        type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1);
        type MoleFraction = Real(quantity = "MoleFraction", final unit = "mol/mol", min = 0, max = 1, nominal = 0.1);
        type MolarMass = .Modelica.SIunits.MolarMass(min = 0.001, max = 0.25, nominal = 0.032);
        type MolarVolume = .Modelica.SIunits.MolarVolume(min = 0.000001, max = 1000000.0, nominal = 1.0);
        type IsentropicExponent = .Modelica.SIunits.RatioOfSpecificHeatCapacities(min = 1, max = 500000, nominal = 1.2, start = 1.2);
        type SpecificEnergy = .Modelica.SIunits.SpecificEnergy(min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
        type SpecificInternalEnergy = SpecificEnergy;
        type SpecificEnthalpy = .Modelica.SIunits.SpecificEnthalpy(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
        type SpecificEntropy = .Modelica.SIunits.SpecificEntropy(min = -10000000.0, max = 10000000.0, nominal = 1000.0);
        type SpecificHeatCapacity = .Modelica.SIunits.SpecificHeatCapacity(min = 0, max = 10000000.0, nominal = 1000.0, start = 1000.0);
        type Temperature = .Modelica.SIunits.Temperature(min = 1, max = 10000.0, nominal = 300, start = 300);
        type ThermalConductivity = .Modelica.SIunits.ThermalConductivity(min = 0, max = 500, nominal = 1, start = 1);
        type VelocityOfSound = .Modelica.SIunits.Velocity(min = 0, max = 100000.0, nominal = 1000, start = 1000);
        type ExtraProperty = Real(min = 0.0, start = 1.0);
        type IsobaricExpansionCoefficient = Real(min = 0, max = 100000000.0, unit = "1/K");
        type DipoleMoment = Real(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
        type DerDensityByPressure = .Modelica.SIunits.DerDensityByPressure;
        type DerDensityByTemperature = .Modelica.SIunits.DerDensityByTemperature;

        package Basic
          extends Icons.Package;

          record FluidConstants
            extends Modelica.Icons.Record;
            String iupacName;
            String casRegistryNumber;
            String chemicalFormula;
            String structureFormula;
            MolarMass molarMass;
          end FluidConstants;
        end Basic;

        package IdealGas
          extends Icons.Package;

          record FluidConstants
            extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
            Temperature criticalTemperature;
            AbsolutePressure criticalPressure;
            MolarVolume criticalMolarVolume;
            Real acentricFactor;
            Temperature meltingPoint;
            Temperature normalBoilingPoint;
            DipoleMoment dipoleMoment;
            Boolean hasIdealGasHeatCapacity = false;
            Boolean hasCriticalData = false;
            Boolean hasDipoleMoment = false;
            Boolean hasFundamentalEquation = false;
            Boolean hasLiquidHeatCapacity = false;
            Boolean hasSolidHeatCapacity = false;
            Boolean hasAccurateViscosityData = false;
            Boolean hasAccurateConductivityData = false;
            Boolean hasVapourPressureCurve = false;
            Boolean hasAcentricFactor = false;
            SpecificEnthalpy HCRIT0 = 0.0;
            SpecificEntropy SCRIT0 = 0.0;
            SpecificEnthalpy deltah = 0.0;
            SpecificEntropy deltas = 0.0;
          end FluidConstants;
        end IdealGas;
      end Types;
    end Interfaces;

    package Common
      extends Modelica.Icons.Package;
      constant Real MINPOS = 0.000000001;

      function smoothStep
        extends Modelica.Icons.Function;
        input Real x;
        input Real y1;
        input Real y2;
        input Real x_small(min = 0) = 0.00001;
        output Real y;
      algorithm
        y := smooth(1, if x > x_small then y1 else if x < -x_small then y2 else if abs(x_small) > 0 then x / x_small * ((x / x_small) ^ 2 - 3) * (y2 - y1) / 4 + (y1 + y2) / 2 else (y1 + y2) / 2);
      end smoothStep;

      package OneNonLinearEquation
        extends Modelica.Icons.Package;

        replaceable record f_nonlinear_Data
          extends Modelica.Icons.Record;
        end f_nonlinear_Data;

        replaceable partial function f_nonlinear
          extends Modelica.Icons.Function;
          input Real x;
          input Real p = 0.0;
          input Real[:] X = fill(0, 0);
          input f_nonlinear_Data f_nonlinear_data;
          output Real y;
        end f_nonlinear;

        replaceable function solve
          extends Modelica.Icons.Function;
          input Real y_zero;
          input Real x_min;
          input Real x_max;
          input Real pressure = 0.0;
          input Real[:] X = fill(0, 0);
          input f_nonlinear_Data f_nonlinear_data;
          input Real x_tol = 100 * Modelica.Constants.eps;
          output Real x_zero;
        protected
          constant Real eps = Modelica.Constants.eps;
          constant Real x_eps = 0.0000000001;
          Real x_min2 = x_min - x_eps;
          Real x_max2 = x_max + x_eps;
          Real a = x_min2;
          Real b = x_max2;
          Real c;
          Real d;
          Real e;
          Real m;
          Real s;
          Real p;
          Real q;
          Real r;
          Real tol;
          Real fa;
          Real fb;
          Real fc;
          Boolean found = false;
        algorithm
          fa := f_nonlinear(x_min2, pressure, X, f_nonlinear_data) - y_zero;
          fb := f_nonlinear(x_max2, pressure, X, f_nonlinear_data) - y_zero;
          fc := fb;
          if fa > 0.0 and fb > 0.0 or fa < 0.0 and fb < 0.0 then
            .Modelica.Utilities.Streams.error("The arguments x_min and x_max to OneNonLinearEquation.solve(..)\n" + "do not bracket the root of the single non-linear equation:\n" + "  x_min  = " + String(x_min2) + "\n" + "  x_max  = " + String(x_max2) + "\n" + "  y_zero = " + String(y_zero) + "\n" + "  fa = f(x_min) - y_zero = " + String(fa) + "\n" + "  fb = f(x_max) - y_zero = " + String(fb) + "\n" + "fa and fb must have opposite sign which is not the case");
          else
          end if;
          c := a;
          fc := fa;
          e := b - a;
          d := e;
          while not found loop
            if abs(fc) < abs(fb) then
              a := b;
              b := c;
              c := a;
              fa := fb;
              fb := fc;
              fc := fa;
            else
            end if;
            tol := 2 * eps * abs(b) + x_tol;
            m := (c - b) / 2;
            if abs(m) <= tol or fb == 0.0 then
              found := true;
              x_zero := b;
            else
              if abs(e) < tol or abs(fa) <= abs(fb) then
                e := m;
                d := e;
              else
                s := fb / fa;
                if a == c then
                  p := 2 * m * s;
                  q := 1 - s;
                else
                  q := fa / fc;
                  r := fb / fc;
                  p := s * (2 * m * q * (q - r) - (b - a) * (r - 1));
                  q := (q - 1) * (r - 1) * (s - 1);
                end if;
                if p > 0 then
                  q := -q;
                else
                  p := -p;
                end if;
                s := e;
                e := d;
                if 2 * p < 3 * m * q - abs(tol * q) and p < abs(0.5 * s * q) then
                  d := p / q;
                else
                  e := m;
                  d := e;
                end if;
              end if;
              a := b;
              fa := fb;
              b := b + (if abs(d) > tol then d else if m > 0 then tol else -tol);
              fb := f_nonlinear(b, pressure, X, f_nonlinear_data) - y_zero;
              if fb > 0 and fc > 0 or fb < 0 and fc < 0 then
                c := a;
                fc := fa;
                e := b - a;
                d := e;
              else
              end if;
            end if;
          end while;
        end solve;
      end OneNonLinearEquation;
    end Common;

    package IdealGases
      extends Modelica.Icons.VariantsPackage;

      package Common
        extends Modelica.Icons.Package;

        record DataRecord
          extends Modelica.Icons.Record;
          String name;
          .Modelica.SIunits.MolarMass MM;
          .Modelica.SIunits.SpecificEnthalpy Hf;
          .Modelica.SIunits.SpecificEnthalpy H0;
          .Modelica.SIunits.Temperature Tlimit;
          Real[7] alow;
          Real[2] blow;
          Real[7] ahigh;
          Real[2] bhigh;
          .Modelica.SIunits.SpecificHeatCapacity R;
        end DataRecord;

        package Functions
          extends Modelica.Icons.Package;
          constant Boolean excludeEnthalpyOfFormation = true;
          constant Modelica.Media.Interfaces.Choices.ReferenceEnthalpy referenceChoice = Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K;
          constant Modelica.Media.Interfaces.Types.SpecificEnthalpy h_offset = 0.0;

          function cp_T
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            output .Modelica.SIunits.SpecificHeatCapacity cp;
          algorithm
            cp := smooth(0, if T < data.Tlimit then data.R * 1 / (T * T) * (data.alow[1] + T * (data.alow[2] + T * (1.0 * data.alow[3] + T * (data.alow[4] + T * (data.alow[5] + T * (data.alow[6] + data.alow[7] * T)))))) else data.R * 1 / (T * T) * (data.ahigh[1] + T * (data.ahigh[2] + T * (1.0 * data.ahigh[3] + T * (data.ahigh[4] + T * (data.ahigh[5] + T * (data.ahigh[6] + data.ahigh[7] * T)))))));
          end cp_T;

          function h_T
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            input Boolean exclEnthForm = excludeEnthalpyOfFormation;
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy refChoice = referenceChoice;
            input .Modelica.SIunits.SpecificEnthalpy h_off = h_offset;
            output .Modelica.SIunits.SpecificEnthalpy h;
          algorithm
            h := smooth(0, (if T < data.Tlimit then data.R * (-data.alow[1] + T * (data.blow[1] + data.alow[2] * Math.log(T) + T * (1.0 * data.alow[3] + T * (0.5 * data.alow[4] + T * (1 / 3 * data.alow[5] + T * (0.25 * data.alow[6] + 0.2 * data.alow[7] * T)))))) / T else data.R * (-data.ahigh[1] + T * (data.bhigh[1] + data.ahigh[2] * Math.log(T) + T * (1.0 * data.ahigh[3] + T * (0.5 * data.ahigh[4] + T * (1 / 3 * data.ahigh[5] + T * (0.25 * data.ahigh[6] + 0.2 * data.ahigh[7] * T)))))) / T) + (if exclEnthForm then -data.Hf else 0.0) + (if refChoice == .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K then data.H0 else 0.0) + (if refChoice == .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined then h_off else 0.0));
          end h_T;

          function s0_T
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            output .Modelica.SIunits.SpecificEntropy s;
          algorithm
            s := if T < data.Tlimit then data.R * (data.blow[2] - 0.5 * data.alow[1] / (T * T) - data.alow[2] / T + data.alow[3] * Math.log(T) + T * (data.alow[4] + T * (0.5 * data.alow[5] + T * (1 / 3 * data.alow[6] + 0.25 * data.alow[7] * T)))) else data.R * (data.bhigh[2] - 0.5 * data.ahigh[1] / (T * T) - data.ahigh[2] / T + data.ahigh[3] * Math.log(T) + T * (data.ahigh[4] + T * (0.5 * data.ahigh[5] + T * (1 / 3 * data.ahigh[6] + 0.25 * data.ahigh[7] * T))));
          end s0_T;

          function dynamicViscosityLowPressure
            extends Modelica.Icons.Function;
            input .Modelica.SIunits.Temp_K T;
            input .Modelica.SIunits.Temp_K Tc;
            input .Modelica.SIunits.MolarMass M;
            input .Modelica.SIunits.MolarVolume Vc;
            input Real w;
            input Interfaces.PartialMedium.DipoleMoment mu;
            input Real k = 0.0;
            output .Modelica.SIunits.DynamicViscosity eta;
          protected
            parameter Real Const1_SI = 40.785 * 10 ^ (-9.5);
            parameter Real Const2_SI = 131.3 / 1000.0;
            Real mur = Const2_SI * mu / sqrt(Vc * Tc);
            Real Fc = 1 - 0.2756 * w + 0.059035 * mur ^ 4 + k;
            Real Tstar;
            Real Ov;
          algorithm
            Tstar := 1.2593 * T / Tc;
            Ov := 1.16145 * Tstar ^ (-0.14874) + 0.52487 * Modelica.Math.exp(-0.7732 * Tstar) + 2.16178 * Modelica.Math.exp(-2.43787 * Tstar);
            eta := Const1_SI * Fc * sqrt(M * T) / (Vc ^ (2 / 3) * Ov);
          end dynamicViscosityLowPressure;

          function thermalConductivityEstimate
            extends Modelica.Icons.Function;
            input Interfaces.PartialMedium.SpecificHeatCapacity Cp;
            input Interfaces.PartialMedium.DynamicViscosity eta;
            input Integer method(min = 1, max = 2) = 1;
            input IdealGases.Common.DataRecord data;
            output Interfaces.PartialMedium.ThermalConductivity lambda;
          algorithm
            lambda := if method == 1 then eta * (Cp - data.R + 9 / 4 * data.R) else eta * (Cp - data.R) * (1.32 + 1.77 / (Cp / Modelica.Constants.R - 1.0));
          end thermalConductivityEstimate;
        end Functions;

        partial package MixtureGasNasa
          extends Modelica.Media.Interfaces.PartialMixtureMedium(ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.pTX, substanceNames = data[:].name, reducedX = false, singleState = false, reference_X = fill(1 / nX, nX), SpecificEnthalpy(start = if referenceChoice == .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K then 300000.0 else if referenceChoice == .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined then h_offset else 0, nominal = 100000.0), Density(start = 10, nominal = 10), AbsolutePressure(start = 1000000.0, nominal = 1000000.0), Temperature(min = 200, max = 6000, start = 500, nominal = 500));

          redeclare record extends ThermodynamicState  end ThermodynamicState;

          constant Modelica.Media.IdealGases.Common.DataRecord[:] data;
          constant Boolean excludeEnthalpyOfFormation = true;
          constant .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy referenceChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K;
          constant SpecificEnthalpy h_offset = 0.0;
          constant MolarMass[nX] MMX = data[:].MM;
          constant Integer methodForThermalConductivity(min = 1, max = 2) = 1;

          redeclare replaceable model extends BaseProperties
          equation
            assert(T >= 200 and T <= 6000, "
            Temperature T (=" + String(T) + " K = 200 K) is not in the allowed range
            200 K <= T <= 6000 K
            required from medium model \"" + mediumName + "\".");
            MM = molarMass(state);
            h = h_TX(T, X);
            R = data.R * X;
            u = h - R * T;
            d = p / (R * T);
            state.T = T;
            state.p = p;
            state.X = if fixedX then reference_X else X;
          end BaseProperties;

          redeclare function setState_pTX
            extends Modelica.Icons.Function;
            input AbsolutePressure p;
            input Temperature T;
            input MassFraction[:] X = reference_X;
            output ThermodynamicState state;
          algorithm
            state := if size(X, 1) == 0 then ThermodynamicState(p = p, T = T, X = reference_X) else if size(X, 1) == nX then ThermodynamicState(p = p, T = T, X = X) else ThermodynamicState(p = p, T = T, X = cat(1, X, {1 - sum(X)}));
          end setState_pTX;

          redeclare function setState_psX
            extends Modelica.Icons.Function;
            input AbsolutePressure p;
            input SpecificEntropy s;
            input MassFraction[:] X = reference_X;
            output ThermodynamicState state;
          algorithm
            state := if size(X, 1) == 0 then ThermodynamicState(p = p, T = T_psX(p, s, reference_X), X = reference_X) else if size(X, 1) == nX then ThermodynamicState(p = p, T = T_psX(p, s, X), X = X) else ThermodynamicState(p = p, T = T_psX(p, s, X), X = cat(1, X, {1 - sum(X)}));
          end setState_psX;

          redeclare function extends setSmoothState
          algorithm
            state := ThermodynamicState(p = Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), T = Media.Common.smoothStep(x, state_a.T, state_b.T, x_small), X = Media.Common.smoothStep(x, state_a.X, state_b.X, x_small));
          end setSmoothState;

          redeclare function extends pressure
          algorithm
            p := state.p;
          end pressure;

          redeclare function extends temperature
          algorithm
            T := state.T;
          end temperature;

          redeclare function extends density
          algorithm
            d := state.p / (state.X * data.R * state.T);
          end density;

          redeclare function extends specificEnthalpy
            extends Modelica.Icons.Function;
          algorithm
            h := h_TX(state.T, state.X);
          end specificEnthalpy;

          redeclare function extends specificInternalEnergy
            extends Modelica.Icons.Function;
          algorithm
            u := h_TX(state.T, state.X) - gasConstant(state) * state.T;
          end specificInternalEnergy;

          redeclare function extends specificEntropy
          protected
            Real[nX] Y(unit = "mol/mol") = massToMoleFractions(state.X, data.MM);
          algorithm
            s := s_TX(state.T, state.X) - sum(state.X[i] * Modelica.Constants.R / MMX[i] * (if state.X[i] < Modelica.Constants.eps then Y[i] else Modelica.Math.log(Y[i] * state.p / reference_p)) for i in 1:nX);
          end specificEntropy;

          redeclare function extends specificGibbsEnergy
            extends Modelica.Icons.Function;
          algorithm
            g := h_TX(state.T, state.X) - state.T * specificEntropy(state);
          end specificGibbsEnergy;

          redeclare function extends specificHelmholtzEnergy
            extends Modelica.Icons.Function;
          algorithm
            f := h_TX(state.T, state.X) - gasConstant(state) * state.T - state.T * specificEntropy(state);
          end specificHelmholtzEnergy;

          function h_TX
            extends Modelica.Icons.Function;
            input .Modelica.SIunits.Temperature T;
            input MassFraction[:] X = reference_X;
            input Boolean exclEnthForm = excludeEnthalpyOfFormation;
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy refChoice = referenceChoice;
            input .Modelica.SIunits.SpecificEnthalpy h_off = h_offset;
            output .Modelica.SIunits.SpecificEnthalpy h;
          algorithm
            h := (if fixedX then reference_X else X) * array(Modelica.Media.IdealGases.Common.Functions.h_T(data[i], T, exclEnthForm, refChoice, h_off) for i in 1:nX);
          end h_TX;

          redeclare function extends gasConstant
          algorithm
            R := data.R * state.X;
          end gasConstant;

          redeclare function extends specificHeatCapacityCp
          algorithm
            cp := array(Modelica.Media.IdealGases.Common.Functions.cp_T(data[i], state.T) for i in 1:nX) * state.X;
          end specificHeatCapacityCp;

          redeclare function extends specificHeatCapacityCv
          algorithm
            cv := array(Modelica.Media.IdealGases.Common.Functions.cp_T(data[i], state.T) for i in 1:nX) * state.X - data.R * state.X;
          end specificHeatCapacityCv;

          function s_TX
            extends Modelica.Icons.Function;
            input Temperature T;
            input MassFraction[nX] X;
            output SpecificEntropy s;
          algorithm
            s := sum(Modelica.Media.IdealGases.Common.Functions.s0_T(data[i], T) * X[i] for i in 1:size(X, 1));
          end s_TX;

          redeclare function extends isentropicExponent
          algorithm
            gamma := specificHeatCapacityCp(state) / specificHeatCapacityCv(state);
          end isentropicExponent;

          redeclare function extends velocityOfSound
            extends Modelica.Icons.Function;
            input ThermodynamicState state;
          algorithm
            a := sqrt(max(0, gasConstant(state) * state.T * specificHeatCapacityCp(state) / specificHeatCapacityCv(state)));
          end velocityOfSound;

          function isentropicEnthalpyApproximation
            extends Modelica.Icons.Function;
            input AbsolutePressure p2;
            input ThermodynamicState state;
            output SpecificEnthalpy h_is;
          protected
            SpecificEnthalpy h;
            SpecificEnthalpy[nX] h_component;
            IsentropicExponent gamma = isentropicExponent(state);
            MassFraction[nX] X;
          algorithm
            X := if reducedX then cat(1, state.X, {1 - sum(state.X)}) else state.X;
            h_component := array(Modelica.Media.IdealGases.Common.Functions.h_T(data[i], state.T, excludeEnthalpyOfFormation, referenceChoice, h_offset) for i in 1:nX);
            h := h_component * X;
            h_is := h + gamma / (gamma - 1.0) * state.T * gasConstant(state) * ((p2 / state.p) ^ ((gamma - 1) / gamma) - 1.0);
          end isentropicEnthalpyApproximation;

          redeclare function extends isentropicEnthalpy
            input Boolean exact = false;
          algorithm
            h_is := if exact then specificEnthalpy_psX(p_downstream, specificEntropy(refState), refState.X) else isentropicEnthalpyApproximation(p_downstream, refState);
          end isentropicEnthalpy;

          function gasMixtureViscosity
            extends Modelica.Icons.Function;
            input MoleFraction[:] yi;
            input MolarMass[:] M;
            input DynamicViscosity[:] eta;
            output DynamicViscosity etam;
          protected
            Real[size(yi, 1), size(yi, 1)] fi;
          algorithm
            for i in 1:size(eta, 1) loop
              assert(fluidConstants[i].hasDipoleMoment, "Dipole moment for " + fluidConstants[i].chemicalFormula + " not known. Can not compute viscosity.");
              assert(fluidConstants[i].hasCriticalData, "Critical data for " + fluidConstants[i].chemicalFormula + " not known. Can not compute viscosity.");
              for j in 1:size(eta, 1) loop
                if i == 1 then
                  fi[i, j] := (1 + (eta[i] / eta[j]) ^ (1 / 2) * (M[j] / M[i]) ^ (1 / 4)) ^ 2 / (8 * (1 + M[i] / M[j])) ^ (1 / 2);
                elseif j < i then
                  fi[i, j] := eta[i] / eta[j] * M[j] / M[i] * fi[j, i];
                else
                  fi[i, j] := (1 + (eta[i] / eta[j]) ^ (1 / 2) * (M[j] / M[i]) ^ (1 / 4)) ^ 2 / (8 * (1 + M[i] / M[j])) ^ (1 / 2);
                end if;
              end for;
            end for;
            etam := sum(yi[i] * eta[i] / sum(yi[j] * fi[i, j] for j in 1:size(eta, 1)) for i in 1:size(eta, 1));
          end gasMixtureViscosity;

          redeclare replaceable function extends dynamicViscosity
          protected
            DynamicViscosity[nX] etaX;
          algorithm
            for i in 1:nX loop
              etaX[i] := Modelica.Media.IdealGases.Common.Functions.dynamicViscosityLowPressure(state.T, fluidConstants[i].criticalTemperature, fluidConstants[i].molarMass, fluidConstants[i].criticalMolarVolume, fluidConstants[i].acentricFactor, fluidConstants[i].dipoleMoment);
            end for;
            eta := gasMixtureViscosity(massToMoleFractions(state.X, fluidConstants[:].molarMass), fluidConstants[:].molarMass, etaX);
          end dynamicViscosity;

          function lowPressureThermalConductivity
            extends Modelica.Icons.Function;
            input MoleFraction[:] y;
            input Temperature T;
            input Temperature[:] Tc;
            input AbsolutePressure[:] Pc;
            input MolarMass[:] M;
            input ThermalConductivity[:] lambda;
            output ThermalConductivity lambdam;
          protected
            MolarMass[size(y, 1)] gamma;
            Real[size(y, 1)] Tr;
            Real[size(y, 1), size(y, 1)] A;
            constant Real epsilon = 1.0;
          algorithm
            for i in 1:size(y, 1) loop
              gamma[i] := 210 * (Tc[i] * M[i] ^ 3 / Pc[i] ^ 4) ^ (1 / 6);
              Tr[i] := T / Tc[i];
            end for;
            for i in 1:size(y, 1) loop
              for j in 1:size(y, 1) loop
                A[i, j] := epsilon * (1 + (gamma[j] * (.Modelica.Math.exp(0.0464 * Tr[i]) - .Modelica.Math.exp(-0.2412 * Tr[i])) / (gamma[i] * (.Modelica.Math.exp(0.0464 * Tr[j]) - .Modelica.Math.exp(-0.2412 * Tr[j])))) ^ (1 / 2) * (M[i] / M[j]) ^ (1 / 4)) ^ 2 / (8 * (1 + M[i] / M[j])) ^ (1 / 2);
              end for;
            end for;
            lambdam := sum(y[i] * lambda[i] / sum(y[j] * A[i, j] for j in 1:size(y, 1)) for i in 1:size(y, 1));
          end lowPressureThermalConductivity;

          redeclare replaceable function extends thermalConductivity
            input Integer method = methodForThermalConductivity;
          protected
            ThermalConductivity[nX] lambdaX;
            DynamicViscosity[nX] eta;
            SpecificHeatCapacity[nX] cp;
          algorithm
            for i in 1:nX loop
              assert(fluidConstants[i].hasCriticalData, "Critical data for " + fluidConstants[i].chemicalFormula + " not known. Can not compute thermal conductivity.");
              eta[i] := Modelica.Media.IdealGases.Common.Functions.dynamicViscosityLowPressure(state.T, fluidConstants[i].criticalTemperature, fluidConstants[i].molarMass, fluidConstants[i].criticalMolarVolume, fluidConstants[i].acentricFactor, fluidConstants[i].dipoleMoment);
              cp[i] := Modelica.Media.IdealGases.Common.Functions.cp_T(data[i], state.T);
              lambdaX[i] := Modelica.Media.IdealGases.Common.Functions.thermalConductivityEstimate(Cp = cp[i], eta = eta[i], method = method, data = data[i]);
            end for;
            lambda := lowPressureThermalConductivity(massToMoleFractions(state.X, fluidConstants[:].molarMass), state.T, fluidConstants[:].criticalTemperature, fluidConstants[:].criticalPressure, fluidConstants[:].molarMass, lambdaX);
          end thermalConductivity;

          redeclare function extends isobaricExpansionCoefficient
          algorithm
            beta := 1 / state.T;
          end isobaricExpansionCoefficient;

          redeclare function extends isothermalCompressibility
          algorithm
            kappa := 1.0 / state.p;
          end isothermalCompressibility;

          redeclare function extends density_derp_T
          algorithm
            ddpT := 1 / (state.T * gasConstant(state));
          end density_derp_T;

          redeclare function extends density_derT_p
          algorithm
            ddTp := -state.p / (state.T * state.T * gasConstant(state));
          end density_derT_p;

          redeclare function extends molarMass
          algorithm
            MM := 1 / sum(state.X[j] / data[j].MM for j in 1:size(state.X, 1));
          end molarMass;

          function T_psX
            extends Modelica.Icons.Function;
            input AbsolutePressure p;
            input SpecificEntropy s;
            input MassFraction[:] X;
            output Temperature T;
          protected
            MassFraction[nX] Xfull = if size(X, 1) == nX then X else cat(1, X, {1 - sum(X)});

            package Internal
              extends Modelica.Media.Common.OneNonLinearEquation;

              redeclare record extends f_nonlinear_Data
                extends Modelica.Media.IdealGases.Common.DataRecord;
              end f_nonlinear_Data;

              redeclare function extends f_nonlinear
              protected
                MassFraction[nX] Xfull = if size(X, 1) == nX then X else cat(1, X, {1 - sum(X)});
                Real[nX] Y(unit = "mol/mol") = massToMoleFractions(if size(X, 1) == nX then X else cat(1, X, {1 - sum(X)}), data.MM);
              algorithm
                y := s_TX(x, Xfull) - sum(Xfull[i] * Modelica.Constants.R / MMX[i] * (if Xfull[i] < Modelica.Constants.eps then Y[i] else Modelica.Math.log(Y[i] * p / reference_p)) for i in 1:nX);
              end f_nonlinear;

              redeclare function extends solve  end solve;
            end Internal;
          algorithm
            T := Internal.solve(s, 200, 6000, p, Xfull, data[1]);
          end T_psX;
        end MixtureGasNasa;

        package FluidData
          extends Modelica.Icons.Package;
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants N2(chemicalFormula = "N2", iupacName = "unknown", structureFormula = "unknown", casRegistryNumber = "7727-37-9", meltingPoint = 63.15, normalBoilingPoint = 77.35, criticalTemperature = 126.2, criticalPressure = 3398000.0, criticalMolarVolume = 0.0000901, acentricFactor = 0.037, dipoleMoment = 0.0, molarMass = SingleGasesData.N2.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants O2(chemicalFormula = "O2", iupacName = "unknown", structureFormula = "unknown", casRegistryNumber = "7782-44-7", meltingPoint = 54.36, normalBoilingPoint = 90.17, criticalTemperature = 154.58, criticalPressure = 5043000.0, criticalMolarVolume = 0.00007337, acentricFactor = 0.022, dipoleMoment = 0.0, molarMass = SingleGasesData.O2.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants CO2(chemicalFormula = "CO2", iupacName = "unknown", structureFormula = "unknown", casRegistryNumber = "124-38-9", meltingPoint = 216.58, normalBoilingPoint = -1.0, criticalTemperature = 304.12, criticalPressure = 7374000.0, criticalMolarVolume = 0.00009407, acentricFactor = 0.225, dipoleMoment = 0.0, molarMass = SingleGasesData.CO2.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants H2O(chemicalFormula = "H2O", iupacName = "oxidane", structureFormula = "H2O", casRegistryNumber = "7732-18-5", meltingPoint = 273.15, normalBoilingPoint = 373.124, criticalTemperature = 647.096, criticalPressure = 22064000.0, criticalMolarVolume = 0.00005595, acentricFactor = 0.344, dipoleMoment = 1.8, molarMass = SingleGasesData.H2O.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants Ar(chemicalFormula = "Ar", iupacName = "unknown", structureFormula = "unknown", casRegistryNumber = "7440-37-1", meltingPoint = 83.8, normalBoilingPoint = 87.27, criticalTemperature = 150.86, criticalPressure = 4898000.0, criticalMolarVolume = 0.00007457, acentricFactor = -0.002, dipoleMoment = 0.0, molarMass = SingleGasesData.Ar.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
        end FluidData;

        package SingleGasesData
          extends Modelica.Icons.Package;
          constant IdealGases.Common.DataRecord Ar(name = "Ar", MM = 0.039948, Hf = 0, H0 = 155137.3785921698, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 4.37967491}, ahigh = {20.10538475, -0.05992661069999999, 2.500069401, -0.0000000399214116, 0.0000000000120527214, -0.000000000000001819015576, 0.0000000000000000001078576636}, bhigh = {-744.993961, 4.37918011}, R = 208.1323720837088);
          constant IdealGases.Common.DataRecord CH4(name = "CH4", MM = 0.01604246, Hf = -4650159.63885838, H0 = 624355.7409524474, Tlimit = 1000, alow = {-176685.0998, 2786.18102, -12.0257785, 0.0391761929, -0.0000361905443, 0.00000002026853043, -0.000000000004976705489999999}, blow = {-23313.1436, 89.0432275}, ahigh = {3730042.76, -13835.01485, 20.49107091, -0.001961974759, 0.000000472731304, -0.0000000000372881469, 0.000000000000001623737207}, bhigh = {75320.6691, -121.9124889}, R = 518.2791167938085);
          constant IdealGases.Common.DataRecord CH3OH(name = "CH3OH", MM = 0.03204186, Hf = -6271171.523750494, H0 = 356885.5553329301, Tlimit = 1000, alow = {-241664.2886, 4032.14719, -20.46415436, 0.0690369807, -0.0000759893269, 0.0000000459820836, -0.00000000001158706744}, blow = {-44332.61169999999, 140.014219}, ahigh = {3411570.76, -13455.00201, 22.61407623, -0.002141029179, 0.000000373005054, -0.0000000000349884639, 0.000000000000001366073444}, bhigh = {56360.8156, -127.7814279}, R = 259.4878075117987);
          constant IdealGases.Common.DataRecord CO(name = "CO", MM = 0.0280101, Hf = -3946262.098314536, H0 = 309570.6191695138, Tlimit = 1000, alow = {14890.45326, -292.2285939, 5.72452717, -0.008176235030000001, 0.00001456903469, -0.00000001087746302, 0.000000000003027941827}, blow = {-13031.31878, -7.85924135}, ahigh = {461919.725, -1944.704863, 5.91671418, -0.0005664282830000001, 0.000000139881454, -0.00000000001787680361, 0.000000000000000962093557}, bhigh = {-2466.261084, -13.87413108}, R = 296.8383547363272);
          constant IdealGases.Common.DataRecord CO2(name = "CO2", MM = 0.0440095, Hf = -8941478.544405185, H0 = 212805.6215135368, Tlimit = 1000, alow = {49436.5054, -626.411601, 5.30172524, 0.002503813816, -0.0000002127308728, -0.000000000768998878, 0.0000000000002849677801}, blow = {-45281.9846, -7.04827944}, ahigh = {117696.2419, -1788.791477, 8.29152319, -0.0000922315678, 0.00000000486367688, -0.000000000001891053312, 0.0000000000000006330036589999999}, bhigh = {-39083.5059, -26.52669281}, R = 188.9244822140674);
          constant IdealGases.Common.DataRecord C2H2_vinylidene(name = "C2H2_vinylidene", MM = 0.02603728, Hf = 15930556.80163212, H0 = 417638.4015534649, Tlimit = 1000, alow = {-14660.42239, 278.9475593, 1.276229776, 0.01395015463, -0.00001475702649, 0.00000000947629811, -0.000000000002567602217}, blow = {47361.1018, 16.58225704}, ahigh = {1940838.725, -6892.718150000001, 13.39582494, -0.0009368968669999999, 0.0000001470804368, -0.00000000001220040365, 0.000000000000000412239166}, bhigh = {91071.1293, -63.3750293}, R = 319.3295152181795);
          constant IdealGases.Common.DataRecord C2H4(name = "C2H4", MM = 0.02805316, Hf = 1871446.924339362, H0 = 374955.5843263291, Tlimit = 1000, alow = {-116360.5836, 2554.85151, -16.09746428, 0.0662577932, -0.00007885081859999999, 0.0000000512522482, -0.00000000001370340031}, blow = {-6176.19107, 109.3338343}, ahigh = {3408763.67, -13748.47903, 23.65898074, -0.002423804419, 0.000000443139566, -0.0000000000435268339, 0.000000000000001775410633}, bhigh = {88204.2938, -137.1278108}, R = 296.3827247982046);
          constant IdealGases.Common.DataRecord C2H6(name = "C2H6", MM = 0.03006904, Hf = -2788633.890539904, H0 = 395476.3437741943, Tlimit = 1000, alow = {-186204.4161, 3406.19186, -19.51705092, 0.0756583559, -0.0000820417322, 0.000000050611358, -0.00000000001319281992}, blow = {-27029.3289, 129.8140496}, ahigh = {5025782.13, -20330.22397, 33.2255293, -0.00383670341, 0.000000723840586, -0.000000000073191825, 0.000000000000003065468699}, bhigh = {111596.395, -203.9410584}, R = 276.5127187299628);
          constant IdealGases.Common.DataRecord C2H5OH(name = "C2H5OH", MM = 0.04606844, Hf = -5100020.751733725, H0 = 315659.1801241805, Tlimit = 1000, alow = {-234279.1392, 4479.18055, -27.44817302, 0.1088679162, -0.0001305309334, 0.00000008437346399999999, -0.00000000002234559017}, blow = {-50222.29, 176.4829211}, ahigh = {4694817.65, -19297.98213, 34.4758404, -0.00323616598, 0.000000578494772, -0.0000000000556460027, 0.0000000000000022262264}, bhigh = {86016.22709999999, -203.4801732}, R = 180.4808671619877);
          constant IdealGases.Common.DataRecord C3H6_propylene(name = "C3H6_propylene", MM = 0.04207974, Hf = 475288.1077687267, H0 = 322020.9535515191, Tlimit = 1000, alow = {-191246.2174, 3542.07424, -21.14878626, 0.0890148479, -0.0001001429154, 0.00000006267959389999999, -0.00000000001637870781}, blow = {-15299.61824, 140.7641382}, ahigh = {5017620.34, -20860.84035, 36.4415634, -0.00388119117, 0.000000727867719, -0.00000000007321204500000001, 0.000000000000003052176369}, bhigh = {126124.5355, -219.5715757}, R = 197.588483198803);
          constant IdealGases.Common.DataRecord C3H8(name = "C3H8", MM = 0.04409562, Hf = -2373931.923397381, H0 = 334301.1845620949, Tlimit = 1000, alow = {-243314.4337, 4656.27081, -29.39466091, 0.1188952745, -0.0001376308269, 0.00000008814823909999999, -0.00000000002342987994}, blow = {-35403.3527, 184.1749277}, ahigh = {6420731.680000001, -26597.91134, 45.3435684, -0.00502066392, 0.0000009471216939999999, -0.0000000000957540523, 0.00000000000000400967288}, bhigh = {145558.2459, -281.8374734}, R = 188.5555073270316);
          constant IdealGases.Common.DataRecord C4H8_1_butene(name = "C4H8_1_butene", MM = 0.05610631999999999, Hf = -9624.584182316717, H0 = 305134.9651875226, Tlimit = 1000, alow = {-272149.2014, 5100.079250000001, -31.8378625, 0.1317754442, -0.0001527359339, 0.00000009714761109999999, -0.0000000000256020447}, blow = {-25230.96386, 200.6932108}, ahigh = {6257948.609999999, -26603.76305, 47.6492005, -0.00438326711, 0.000000712883844, -0.0000000000599102084, 0.000000000000002051753504}, bhigh = {156925.2657, -291.3869761}, R = 148.1913623991023);
          constant IdealGases.Common.DataRecord C4H10_n_butane(name = "C4H10_n_butane", MM = 0.0581222, Hf = -2164233.28779709, H0 = 330832.0228759407, Tlimit = 1000, alow = {-317587.254, 6176.331819999999, -38.9156212, 0.1584654284, -0.0001860050159, 0.0000001199676349, -0.0000000000320167055}, blow = {-45403.63390000001, 237.9488665}, ahigh = {7682322.45, -32560.5151, 57.3673275, -0.00619791681, 0.000001180186048, -0.0000000001221893698, 0.000000000000005250635250000001}, bhigh = {177452.656, -358.791876}, R = 143.0515706563069);
          constant IdealGases.Common.DataRecord C5H10_1_pentene(name = "C5H10_1_pentene", MM = 0.07013290000000001, Hf = -303423.9279995551, H0 = 309127.3852927798, Tlimit = 1000, alow = {-534054.813, 9298.91738, -56.6779245, 0.2123100266, -0.000257129829, 0.0000001666834304, -0.0000000000443408047}, blow = {-47906.8218, 339.60364}, ahigh = {3744014.97, -21044.85321, 47.3612699, -0.00042442012, -0.0000000389897505, 0.00000000001367074243, -0.000000000000000931319423}, bhigh = {115409.1373, -278.6177449000001}, R = 118.5530899192818);
          constant IdealGases.Common.DataRecord C5H12_n_pentane(name = "C5H12_n_pentane", MM = 0.07214878, Hf = -2034130.029641527, H0 = 335196.2430965569, Tlimit = 1000, alow = {-276889.4625, 5834.28347, -36.1754148, 0.1533339707, -0.0001528395882, 0.00000008191092, -0.00000000001792327902}, blow = {-46653.7525, 226.5544053}, ahigh = {-2530779.286, -8972.59326, 45.3622326, -0.002626989916, 0.000003135136419, -0.000000000531872894, 0.00000000000002886896868}, bhigh = {14846.16529, -251.6550384}, R = 115.2406457877736);
          constant IdealGases.Common.DataRecord C6H6(name = "C6H6", MM = 0.07811184, Hf = 1061042.730525872, H0 = 181735.4577743912, Tlimit = 1000, alow = {-167734.0902, 4404.50004, -37.1737791, 0.1640509559, -0.0002020812374, 0.0000001307915264, -0.000000000034442841}, blow = {-10354.55401, 216.9853345}, ahigh = {4538575.72, -22605.02547, 46.940073, -0.004206676830000001, 0.000000790799433, -0.000000000079683021, 0.00000000000000332821208}, bhigh = {139146.4686, -286.8751333}, R = 106.4431717393932);
          constant IdealGases.Common.DataRecord C6H12_1_hexene(name = "C6H12_1_hexene", MM = 0.08415948000000001, Hf = -498458.4030224521, H0 = 311788.9986962847, Tlimit = 1000, alow = {-666883.165, 11768.64939, -72.7099833, 0.2709398396, -0.00033332464, 0.0000002182347097, -0.0000000000585946882}, blow = {-62157.8054, 428.682564}, ahigh = {733290.696, -14488.48641, 46.7121549, 0.00317297847, -0.000000524264652, 0.0000000000428035582, -0.000000000000001472353254}, bhigh = {66977.4041, -262.3643854}, R = 98.79424159940152);
          constant IdealGases.Common.DataRecord C6H14_n_hexane(name = "C6H14_n_hexane", MM = 0.08617535999999999, Hf = -1936980.593988816, H0 = 333065.0431863586, Tlimit = 1000, alow = {-581592.67, 10790.97724, -66.3394703, 0.2523715155, -0.0002904344705, 0.0000001802201514, -0.00000000004617223680000001}, blow = {-72715.4457, 393.828354}, ahigh = {-3106625.684, -7346.087920000001, 46.94131760000001, 0.001693963977, 0.000002068996667, -0.000000000421214168, 0.00000000000002452345845}, bhigh = {523.750312, -254.9967718}, R = 96.48317105956971);
          constant IdealGases.Common.DataRecord C7H14_1_heptene(name = "C7H14_1_heptene", MM = 0.09818605999999999, Hf = -639194.6066478277, H0 = 313588.3036756949, Tlimit = 1000, alow = {-744940.284, 13321.79893, -82.81694379999999, 0.3108065994, -0.000378677992, 0.0000002446841042, -0.00000000006488763869999999}, blow = {-72178.8501, 485.667149}, ahigh = {-1927608.174, -9125.024420000002, 47.4817797, 0.00606766053, -0.000000868485908, 0.0000000000581399526, -0.000000000000001473979569}, bhigh = {26009.14656, -256.2880707}, R = 84.68077851377274);
          constant IdealGases.Common.DataRecord C7H16_n_heptane(name = "C7H16_n_heptane", MM = 0.10020194, Hf = -1874015.612871368, H0 = 331540.487140269, Tlimit = 1000, alow = {-612743.289, 11840.85437, -74.87188599999999, 0.2918466052, -0.000341679549, 0.0000002159285269, -0.0000000000565585273}, blow = {-80134.0894, 440.721332}, ahigh = {9135632.469999999, -39233.1969, 78.8978085, -0.00465425193, 0.000002071774142, -0.00000000034425393, 0.00000000000001976834775}, bhigh = {205070.8295, -485.110402}, R = 82.97715593131232);
          constant IdealGases.Common.DataRecord C8H10_ethylbenz(name = "C8H10_ethylbenz", MM = 0.106165, Hf = 281825.4603682946, H0 = 209862.0072528611, Tlimit = 1000, alow = {-469494, 9307.16836, -65.2176947, 0.2612080237, -0.000318175348, 0.0000002051355473, -0.0000000000540181735}, blow = {-40738.7021, 378.090436}, ahigh = {5551564.100000001, -28313.80598, 60.6124072, 0.001042112857, -0.000001327426719, 0.0000000002166031743, -0.00000000000001142545514}, bhigh = {164224.1062, -369.176982}, R = 78.31650732350586);
          constant IdealGases.Common.DataRecord C8H18_n_octane(name = "C8H18_n_octane", MM = 0.11422852, Hf = -1827477.060895125, H0 = 330740.51909278, Tlimit = 1000, alow = {-698664.715, 13385.01096, -84.1516592, 0.327193666, -0.000377720959, 0.0000002339836988, -0.0000000000601089265}, blow = {-90262.2325, 493.922214}, ahigh = {6365406.949999999, -31053.64657, 69.6916234, 0.01048059637, -0.00000412962195, 0.0000000005543226319999999, -0.00000000000002651436499}, bhigh = {150096.8785, -416.989565}, R = 72.78805678301707);
          constant IdealGases.Common.DataRecord CL2(name = "CL2", MM = 0.07090600000000001, Hf = 0, H0 = 129482.8364313316, Tlimit = 1000, alow = {34628.1517, -554.712652, 6.20758937, -0.002989632078, 0.00000317302729, -0.000000001793629562, 0.0000000000004260043590000001}, blow = {1534.069331, -9.438331107}, ahigh = {6092569.42, -19496.27662, 28.54535795, -0.01449968764, 0.00000446389077, -0.000000000635852586, 0.0000000000000332736029}, bhigh = {121211.7724, -169.0778824}, R = 117.2604857134798);
          constant IdealGases.Common.DataRecord F2(name = "F2", MM = 0.0379968064, Hf = 0, H0 = 232259.1511269747, Tlimit = 1000, alow = {10181.76308, 22.74241183, 1.97135304, 0.00815160401, -0.0000114896009, 0.00000000795865253, -0.000000000002167079526}, blow = {-958.6943, 11.30600296}, ahigh = {-2941167.79, 9456.5977, -7.73861615, 0.00764471299, -0.000002241007605, 0.0000000002915845236, -0.00000000000001425033974}, bhigh = {-60710.0561, 84.2383508}, R = 218.8202848542556);
          constant IdealGases.Common.DataRecord H2(name = "H2", MM = 0.00201588, Hf = 0, H0 = 4200697.462150524, Tlimit = 1000, alow = {40783.2321, -800.918604, 8.21470201, -0.01269714457, 0.00001753605076, -0.0000000120286027, 0.00000000000336809349}, blow = {2682.484665, -30.43788844}, ahigh = {560812.801, -837.150474, 2.975364532, 0.001252249124, -0.000000374071619, 0.000000000059366252, -0.0000000000000036069941}, bhigh = {5339.82441, -2.202774769}, R = 4124.487568704486);
          constant IdealGases.Common.DataRecord H2O(name = "H2O", MM = 0.01801528, Hf = -13423382.81725291, H0 = 549760.6476280135, Tlimit = 1000, alow = {-39479.6083, 575.573102, 0.931782653, 0.00722271286, -0.00000734255737, 0.00000000495504349, -0.000000000001336933246}, blow = {-33039.7431, 17.24205775}, ahigh = {1034972.096, -2412.698562, 4.64611078, 0.002291998307, -0.0000006836830479999999, 0.00000000009426468930000001, -0.00000000000000482238053}, bhigh = {-13842.86509, -7.97814851}, R = 461.5233290850878);
          constant IdealGases.Common.DataRecord He(name = "He", MM = 0.004002602, Hf = 0, H0 = 1548349.798456104, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 0.9287239740000001}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, 0.9287239740000001}, R = 2077.26673798694);
          constant IdealGases.Common.DataRecord NH3(name = "NH3", MM = 0.01703052, Hf = -2697510.117130892, H0 = 589713.1150428759, Tlimit = 1000, alow = {-76812.2615, 1270.951578, -3.89322913, 0.02145988418, -0.00002183766703, 0.00000001317385706, -0.00000000000333232206}, blow = {-12648.86413, 43.66014588}, ahigh = {2452389.535, -8040.89424, 12.71346201, -0.000398018658, 0.0000000355250275, 0.00000000000253092357, -0.000000000000000332270053}, bhigh = {43861.91959999999, -64.62330602}, R = 488.2101075011215);
          constant IdealGases.Common.DataRecord NO(name = "NO", MM = 0.0300061, Hf = 3041758.509103149, H0 = 305908.1320131574, Tlimit = 1000, alow = {-11439.16503, 153.6467592, 3.43146873, -0.002668592368, 0.00000848139912, -0.00000000768511105, 0.000000000002386797655}, blow = {9098.21441, 6.72872549}, ahigh = {223901.8716, -1289.651623, 5.43393603, -0.00036560349, 0.00000009880966450000001, -0.00000000001416076856, 0.000000000000000938018462}, bhigh = {17503.17656, -8.50166909}, R = 277.0927244793559);
          constant IdealGases.Common.DataRecord NO2(name = "NO2", MM = 0.0460055, Hf = 743237.6346306421, H0 = 221890.3174620426, Tlimit = 1000, alow = {-56420.3878, 963.308572, -2.434510974, 0.01927760886, -0.00001874559328, 0.000000009145497730000001, -0.000000000001777647635}, blow = {-1547.925037, 40.6785121}, ahigh = {721300.157, -3832.6152, 11.13963285, -0.002238062246, 0.000000654772343, -0.000000000076113359, 0.00000000000000332836105}, bhigh = {25024.97403, -43.0513004}, R = 180.7277825477389);
          constant IdealGases.Common.DataRecord N2(name = "N2", MM = 0.0280134, Hf = 0, H0 = 309498.4543111511, Tlimit = 1000, alow = {22103.71497, -381.846182, 6.08273836, -0.00853091441, 0.00001384646189, -0.00000000962579362, 0.000000000002519705809}, blow = {710.846086, -10.76003744}, ahigh = {587712.406, -2239.249073, 6.06694922, -0.00061396855, 0.0000001491806679, -0.00000000001923105485, 0.000000000000001061954386}, bhigh = {12832.10415, -15.86640027}, R = 296.8033869505308);
          constant IdealGases.Common.DataRecord N2O(name = "N2O", MM = 0.0440128, Hf = 1854006.107314236, H0 = 217685.1961247637, Tlimit = 1000, alow = {42882.2597, -644.011844, 6.03435143, 0.0002265394436, 0.00000347278285, -0.00000000362774864, 0.000000000001137969552}, blow = {11794.05506, -10.0312857}, ahigh = {343844.804, -2404.557558, 9.12563622, -0.000540166793, 0.0000001315124031, -0.000000000014142151, 0.000000000000000638106687}, bhigh = {21986.32638, -31.47805016}, R = 188.9103169986913);
          constant IdealGases.Common.DataRecord Ne(name = "Ne", MM = 0.0201797, Hf = 0, H0 = 307111.9986917546, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 3.35532272}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, 3.35532272}, R = 412.0215860493466);
          constant IdealGases.Common.DataRecord O2(name = "O2", MM = 0.0319988, Hf = 0, H0 = 271263.4223783392, Tlimit = 1000, alow = {-34255.6342, 484.700097, 1.119010961, 0.00429388924, -0.000000683630052, -0.0000000020233727, 0.000000000001039040018}, blow = {-3391.45487, 18.4969947}, ahigh = {-1037939.022, 2344.830282, 1.819732036, 0.001267847582, -0.0000002188067988, 0.00000000002053719572, -0.0000000000000008193467050000001}, bhigh = {-16890.10929, 17.38716506}, R = 259.8369938872708);
          constant IdealGases.Common.DataRecord SO2(name = "SO2", MM = 0.0640638, Hf = -4633037.690552231, H0 = 164650.3485587805, Tlimit = 1000, alow = {-53108.4214, 909.031167, -2.356891244, 0.02204449885, -0.00002510781471, 0.00000001446300484, -0.00000000000336907094}, blow = {-41137.52080000001, 40.45512519}, ahigh = {-112764.0116, -825.226138, 7.61617863, -0.000199932761, 0.0000000565563143, -0.00000000000545431661, 0.0000000000000002918294102}, bhigh = {-33513.0869, -16.55776085}, R = 129.7842463294403);
          constant IdealGases.Common.DataRecord SO3(name = "SO3", MM = 0.0800632, Hf = -4944843.573576874, H0 = 145990.9046852986, Tlimit = 1000, alow = {-39528.5529, 620.857257, -1.437731716, 0.02764126467, -0.00003144958662, 0.00000001792798, -0.00000000000412638666}, blow = {-51841.0617, 33.91331216}, ahigh = {-216692.3781, -1301.022399, 10.96287985, -0.000383710002, 0.0000000846688904, -0.00000000000970539929, 0.000000000000000449839754}, bhigh = {-43982.83990000001, -36.55217314}, R = 103.8488594010732);
        end SingleGasesData;
      end Common;
    end IdealGases;
  end Media;

  package Math
    extends Modelica.Icons.Package;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  end AxisLeft;

      partial function AxisCenter  end AxisCenter;
    end Icons;

    function sin
      extends Modelica.Math.Icons.AxisLeft;
      input Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = sin(u);
    end sin;

    function asin
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function exp
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
    end exp;

    function log
      extends Modelica.Math.Icons.AxisLeft;
      input Real u;
      output Real y;
      external "builtin" y = log(u);
    end log;
  end Math;

  package Utilities
    extends Modelica.Icons.Package;

    package Streams
      extends Modelica.Icons.Package;

      function error
        extends Modelica.Icons.Function;
        input String string;
        external "C" ModelicaError(string);
      end error;
    end Streams;

    package Strings
      extends Modelica.Icons.Package;

      function length
        extends Modelica.Icons.Function;
        input String string;
        output Integer result;
        external "C" result = ModelicaStrings_length(string);
      end length;

      function isEmpty
        extends Modelica.Icons.Function;
        input String string;
        output Boolean result;
      protected
        Integer nextIndex;
        Integer len;
      algorithm
        nextIndex := Strings.Advanced.skipWhiteSpace(string);
        len := Strings.length(string);
        if len < 1 or nextIndex > len then
          result := true;
        else
          result := false;
        end if;
      end isEmpty;

      package Advanced
        extends Modelica.Icons.Package;

        function skipWhiteSpace
          extends Modelica.Icons.Function;
          input String string;
          input Integer startIndex(min = 1) = 1;
          output Integer nextIndex;
          external "C" nextIndex = ModelicaStrings_skipWhiteSpace(string, startIndex);
        end skipWhiteSpace;
      end Advanced;
    end Strings;
  end Utilities;

  package Constants
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps;
    final constant Real inf = ModelicaServices.Machine.inf;
    final constant .Modelica.SIunits.Velocity c = 299792458;
    final constant Real R(final unit = "J/(mol.K)") = 8.314472;
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 0.0000001;
    final constant .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_zero = -273.15;
  end Constants;

  package Icons
    extends Icons.Package;

    partial package ExamplesPackage
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial package Package  end Package;

    partial package VariantsPackage
      extends Modelica.Icons.Package;
    end VariantsPackage;

    partial package InterfacesPackage
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package SensorsPackage
      extends Modelica.Icons.Package;
    end SensorsPackage;

    partial package TypesPackage
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package IconsPackage
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package MaterialPropertiesPackage
      extends Modelica.Icons.Package;
    end MaterialPropertiesPackage;

    partial class RotationalSensor  end RotationalSensor;

    partial function Function  end Function;

    partial record Record  end Record;
  end Icons;

  package SIunits
    extends Modelica.Icons.Package;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial function Conversion  end Conversion;
    end Icons;

    package Conversions
      extends Modelica.Icons.Package;

      package NonSIunits
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC");
        type AngularVelocity_rpm = Real(final quantity = "AngularVelocity", final unit = "1/min");
        type Pressure_bar = Real(final quantity = "Pressure", final unit = "bar");
      end NonSIunits;

      function to_degC
        extends Modelica.SIunits.Icons.Conversion;
        input Temperature Kelvin;
        output NonSIunits.Temperature_degC Celsius;
      algorithm
        Celsius := Kelvin + Modelica.Constants.T_zero;
      end to_degC;

      function from_degC
        extends Modelica.SIunits.Icons.Conversion;
        input NonSIunits.Temperature_degC Celsius;
        output Temperature Kelvin;
      algorithm
        Kelvin := Celsius - Modelica.Constants.T_zero;
      end from_degC;

      function to_rpm
        extends Modelica.SIunits.Icons.Conversion;
        input AngularVelocity rs;
        output NonSIunits.AngularVelocity_rpm rpm;
      algorithm
        rpm := 30 / Modelica.Constants.pi * rs;
      end to_rpm;

      function to_bar
        extends Modelica.SIunits.Icons.Conversion;
        input Pressure Pa;
        output NonSIunits.Pressure_bar bar;
      algorithm
        bar := Pa / 100000.0;
      end to_bar;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Area = Real(final quantity = "Area", final unit = "m2");
    type Volume = Real(final quantity = "Volume", final unit = "m3");
    type Time = Real(final quantity = "Time", final unit = "s");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type MomentOfInertia = Real(final quantity = "MomentOfInertia", final unit = "kg.m2");
    type Torque = Real(final quantity = "Torque", final unit = "N.m");
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type AbsolutePressure = Pressure(min = 0.0, nominal = 100000.0);
    type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
    type Energy = Real(final quantity = "Energy", final unit = "J");
    type Power = Real(final quantity = "Power", final unit = "W");
    type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
    type MomentumFlux = Real(final quantity = "MomentumFlux", final unit = "N");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC");
    type Temp_K = ThermodynamicTemperature;
    type Temperature = ThermodynamicTemperature;
    type Compressibility = Real(final quantity = "Compressibility", final unit = "1/Pa");
    type IsothermalCompressibility = Compressibility;
    type Heat = Real(final quantity = "Energy", final unit = "J");
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type CoefficientOfHeatTransfer = Real(final quantity = "CoefficientOfHeatTransfer", final unit = "W/(m2.K)");
    type HeatCapacity = Real(final quantity = "HeatCapacity", final unit = "J/K");
    type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
    type RatioOfSpecificHeatCapacities = Real(final quantity = "RatioOfSpecificHeatCapacities", final unit = "1");
    type Entropy = Real(final quantity = "Entropy", final unit = "J/K");
    type SpecificEntropy = Real(final quantity = "SpecificEntropy", final unit = "J/(kg.K)");
    type InternalEnergy = Heat;
    type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
    type SpecificEnthalpy = SpecificEnergy;
    type DerDensityByPressure = Real(final unit = "s2/m2");
    type DerDensityByTemperature = Real(final unit = "kg/(m3.K)");
    type AmountOfSubstance = Real(final quantity = "AmountOfSubstance", final unit = "mol", min = 0);
    type MolarMass = Real(final quantity = "MolarMass", final unit = "kg/mol", min = 0);
    type MolarVolume = Real(final quantity = "MolarVolume", final unit = "m3/mol", min = 0);
    type MassFraction = Real(final quantity = "MassFraction", final unit = "1", min = 0, max = 1);
    type MoleFraction = Real(final quantity = "MoleFraction", final unit = "1", min = 0, max = 1);
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
end Modelica;
