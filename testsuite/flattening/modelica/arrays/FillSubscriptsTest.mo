// name:     FillSubscriptsTest.mo
// keywords: tests that filling of subscripts in Static.elabCref2 is properly handled (for component mfr_2)
// status:   correct
//

package Buildings
  extends Modelica.Icons.Package;

  package Fluid
    extends Modelica.Icons.Package;

    package FixedResistances
      extends Modelica.Icons.VariantsPackage;

      model FixedResistanceDpM
        extends Buildings.Fluid.BaseClasses.PartialResistance(final m_flow_turbulent = if computeFlowResistance and use_dh then eta_default * dh / 4 * Modelica.Constants.pi * ReC elseif computeFlowResistance then deltaM * m_flow_nominal_pos else 0);
        parameter Boolean use_dh = false;
        parameter Modelica.SIunits.Length dh = 1;
        parameter Real ReC(min = 0) = 4000;
        parameter Real deltaM(min = 0.01) = 0.3;
        final parameter Real k(unit = "") = if computeFlowResistance then m_flow_nominal_pos / sqrt(dp_nominal_pos) else 0;
      protected
        final parameter Boolean computeFlowResistance = dp_nominal_pos > Modelica.Constants.eps annotation(Evaluate = true);
      initial equation
        if computeFlowResistance then
          assert(m_flow_turbulent > 0, "m_flow_turbulent must be bigger than zero.");
        end if;
        assert(m_flow_nominal_pos > 0, "m_flow_nominal_pos must be non-zero. Check parameters.");
        if m_flow_turbulent > m_flow_nominal_pos then
          Modelica.Utilities.Streams.print("Warning: In FixedResistanceDpM, m_flow_nominal is smaller than m_flow_turbulent." + "\n" + "  m_flow_nominal = " + String(m_flow_nominal) + "\n" + "  dh      = " + String(dh) + "\n" + "  To fix, set dh < " + String(4 * m_flow_nominal / eta_default / Modelica.Constants.pi / ReC) + "\n" + "  Suggested value: dh = " + String(1 / 10 * 4 * m_flow_nominal / eta_default / Modelica.Constants.pi / ReC));
        end if;
      equation
        if computeFlowResistance then
          if linearized then
            m_flow * m_flow_nominal_pos = k ^ 2 * dp;
          else
            if homotopyInitialization then
              if from_dp then
                m_flow = homotopy(actual = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_dp(dp = dp, k = k, m_flow_turbulent = m_flow_turbulent), simplified = m_flow_nominal_pos * dp / dp_nominal_pos);
              else
                dp = homotopy(actual = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(m_flow = m_flow, k = k, m_flow_turbulent = m_flow_turbulent), simplified = dp_nominal_pos * m_flow / m_flow_nominal_pos);
              end if;
            else
              if from_dp then
                m_flow = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_dp(dp = dp, k = k, m_flow_turbulent = m_flow_turbulent);
              else
                dp = Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(m_flow = m_flow, k = k, m_flow_turbulent = m_flow_turbulent);
              end if;
            end if;
          end if;
        else
          dp = 0;
        end if;
      end FixedResistanceDpM;
    end FixedResistances;

    package HeatExchangers
      extends Modelica.Icons.VariantsPackage;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        model CoilHeader
          extends Buildings.BaseClasses.BaseIcon;
          outer Modelica.Fluid.System system;
          replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
          parameter Boolean allowFlowReversal = system.allowFlowReversal annotation(Evaluate = true);
          parameter Integer nPipPar(min = 1);
          parameter Modelica.SIunits.MassFlowRate mStart_flow_a;
          Modelica.Fluid.Interfaces.FluidPort_a[nPipPar] port_a(redeclare each final package Medium = Medium, each m_flow(start = mStart_flow_a / nPipPar, min = if allowFlowReversal then -Modelica.Constants.inf else 0));
          Modelica.Fluid.Interfaces.FluidPort_b[nPipPar] port_b(redeclare each final package Medium = Medium, each m_flow(start = -mStart_flow_a / nPipPar, max = if allowFlowReversal then +Modelica.Constants.inf else 0));
        equation
          connect(port_a, port_b);
        end CoilHeader;

        model DuctManifoldFixedResistance
          extends PartialDuctManifold;
          parameter Boolean use_dh = false annotation(Evaluate = true);
          parameter Modelica.SIunits.MassFlowRate m_flow_nominal;
          parameter Modelica.SIunits.Pressure dp_nominal(min = 0);
          parameter Modelica.SIunits.Length dh = 1;
          parameter Real ReC = 4000;
          parameter Boolean linearized = false;
          parameter Real deltaM(min = 0) = 0.3;
          parameter Boolean from_dp = false annotation(Evaluate = true);
          Fluid.FixedResistances.FixedResistanceDpM fixRes(redeclare each package Medium = Medium, each m_flow_nominal = m_flow_nominal, each dp_nominal = dp_nominal, each dh = dh, each from_dp = from_dp, each deltaM = deltaM, each ReC = ReC, each use_dh = use_dh, each linearized = linearized);
        protected
          DuctManifoldFlowDistributor floDis(redeclare package Medium = Medium, nPipPar = nPipPar, mStart_flow_a = mStart_flow_a, nPipSeg = nPipSeg, allowFlowReversal = allowFlowReversal);
        equation
          connect(fixRes.port_a, port_a);
          connect(fixRes.port_b, floDis.port_a);
          connect(floDis.port_b, port_b);
        end DuctManifoldFixedResistance;

        model DuctManifoldFlowDistributor
          extends PartialDuctManifold;
        equation
          port_b[1, 1].m_flow = -port_a.m_flow / nPipPar / nPipSeg;
          for j in 2:nPipSeg loop
            port_b[1, j].m_flow = port_b[1, 1].m_flow;
          end for;
          for i in 2:nPipPar loop
            for j in 1:nPipSeg loop
              port_b[i, j].m_flow = port_b[1, 1].m_flow;
            end for;
          end for;
          port_b[1, 1].p = port_a.p;
          for i in 1:nPipPar loop
            for j in 1:nPipSeg loop
              inStream(port_a.h_outflow) = port_b[i, j].h_outflow;
              inStream(port_a.Xi_outflow) = port_b[i, j].Xi_outflow;
              inStream(port_a.C_outflow) = port_b[i, j].C_outflow;
            end for;
          end for;
          port_a.h_outflow = sum(sum(inStream(port_b[i, j].h_outflow) for i in 1:nPipPar) for j in 1:nPipSeg) / nPipPar / nPipSeg;
          port_a.Xi_outflow = sum(sum(inStream(port_b[i, j].Xi_outflow) for i in 1:nPipPar) for j in 1:nPipSeg) / nPipPar / nPipSeg;
          port_a.C_outflow = sum(sum(inStream(port_b[i, j].C_outflow) for i in 1:nPipPar) for j in 1:nPipSeg) / nPipPar / nPipSeg;
        end DuctManifoldFlowDistributor;

        model DuctManifoldNoResistance
          extends PartialDuctManifold;
        equation
          for i in 1:nPipPar loop
            for j in 1:nPipSeg loop
              connect(port_a, port_b[i, j]);
            end for;
          end for;
        end DuctManifoldNoResistance;

        partial model PartialDuctManifold
          extends PartialDuctPipeManifold;
          parameter Integer nPipSeg(min = 1);
          Modelica.Fluid.Interfaces.FluidPort_b[nPipPar, nPipSeg] port_b(redeclare each package Medium = Medium, each m_flow(start = -mStart_flow_a / nPipSeg / nPipPar, max = if allowFlowReversal then +Modelica.Constants.inf else 0));
        end PartialDuctManifold;

        partial model PartialDuctPipeManifold
          extends Buildings.BaseClasses.BaseIcon;
          outer Modelica.Fluid.System system;
          replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
          parameter Boolean allowFlowReversal = system.allowFlowReversal annotation(Evaluate = true);
          parameter Integer nPipPar(min = 1);
          parameter Modelica.SIunits.MassFlowRate mStart_flow_a;
          Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare package Medium = Medium, m_flow(start = mStart_flow_a, min = if allowFlowReversal then -Modelica.Constants.inf else 0));
        end PartialDuctPipeManifold;

        partial model PartialPipeManifold
          extends PartialDuctPipeManifold;
          Modelica.Fluid.Interfaces.FluidPort_b[nPipPar] port_b(redeclare each package Medium = Medium, each m_flow(start = -mStart_flow_a / nPipPar, max = if allowFlowReversal then +Modelica.Constants.inf else 0));
        end PartialPipeManifold;

        model PipeManifoldFixedResistance
          extends PartialPipeManifold;
          parameter Modelica.SIunits.MassFlowRate m_flow_nominal;
          parameter Modelica.SIunits.Pressure dp_nominal(min = 0);
          parameter Boolean use_dh = false annotation(Evaluate = true);
          parameter Modelica.SIunits.Length dh = 0.025;
          parameter Real ReC = 4000;
          parameter Boolean linearized = false;
          parameter Real deltaM(min = 0) = 0.3;
          parameter Boolean from_dp = false annotation(Evaluate = true);
          Fluid.FixedResistances.FixedResistanceDpM fixRes(redeclare package Medium = Medium, m_flow_nominal = m_flow_nominal, dp_nominal = dp_nominal, dh = dh, from_dp = from_dp, deltaM = deltaM, ReC = ReC, use_dh = use_dh, linearized = linearized);
        protected
          PipeManifoldFlowDistributor floDis(redeclare package Medium = Medium, nPipPar = nPipPar, mStart_flow_a = mStart_flow_a, allowFlowReversal = allowFlowReversal);
        equation
          connect(fixRes.port_b, floDis.port_a);
          connect(floDis.port_b, port_b);
          connect(fixRes.port_a, port_a);
        end PipeManifoldFixedResistance;

        model PipeManifoldFlowDistributor
          extends PartialPipeManifold;
        equation
          port_b[1].m_flow = -port_a.m_flow / nPipPar;
          for i in 2:nPipPar loop
            port_b[i].m_flow = port_b[1].m_flow;
          end for;
          port_b[1].p = port_a.p;
          for i in 1:nPipPar loop
            inStream(port_a.h_outflow) = port_b[i].h_outflow;
            inStream(port_a.Xi_outflow) = port_b[i].Xi_outflow;
            inStream(port_a.C_outflow) = port_b[i].C_outflow;
          end for;
          port_a.h_outflow = sum(inStream(port_b[i].h_outflow) for i in 1:nPipPar) / nPipPar;
          port_a.Xi_outflow = sum(inStream(port_b[i].Xi_outflow) for i in 1:nPipPar) / nPipPar;
          port_a.C_outflow = sum(inStream(port_b[i].C_outflow) for i in 1:nPipPar) / nPipPar;
        end PipeManifoldFlowDistributor;

        model PipeManifoldNoResistance
          extends PartialPipeManifold;
          parameter Boolean connectAllPressures = true;
          Modelica.Fluid.Fittings.MultiPort mulPor(redeclare package Medium = Medium, final nPorts_b = nPipPar);
        equation
          connect(port_a, mulPor.port_a);
          connect(mulPor.ports_b, port_b);
        end PipeManifoldNoResistance;

        package Examples
          extends Modelica.Icons.ExamplesPackage;

          model Manifold
            package Medium1 = Buildings.Media.ConstantPropertyLiquidWater;
            package Medium2 = Buildings.Media.PerfectGases.MoistAirUnsaturated;
            extends Modelica.Icons.Example;
            parameter Integer nPipPar = 3;
            parameter Integer nPipSeg = 4;
            Buildings.Fluid.Sources.Boundary_pT sin_1(nPorts = 1, T = 283.15, redeclare package Medium = Medium1);
            Buildings.Fluid.Sources.Boundary_pT sou_1(use_p_in = true, use_T_in = true, p = 101335, T = 293.15, nPorts = 1, redeclare package Medium = Medium1);
            Fluid.FixedResistances.FixedResistanceDpM res_1(m_flow_nominal = 5, use_dh = true, from_dp = false, dp_nominal = 3000, redeclare package Medium = Medium1);
            Buildings.Fluid.Sensors.MassFlowRate[nPipPar] mfr_1(redeclare package Medium = Medium1);
            Modelica.Blocks.Sources.Ramp TDb(height = 1, duration = 1, offset = 293.15);
            Modelica.Blocks.Sources.Ramp P(duration = 1, height = 12E3, offset = 3E5 - 6E3);
            Buildings.Fluid.HeatExchangers.BaseClasses.PipeManifoldFixedResistance pipFixRes_1(nPipPar = nPipPar, m_flow_nominal = 5, linearized = false, mStart_flow_a = 5, dp_nominal(displayUnit = "Pa") = 3000, redeclare package Medium = Medium1);
            Buildings.Fluid.HeatExchangers.BaseClasses.PipeManifoldNoResistance pipNoRes_1(nPipPar = nPipPar, mStart_flow_a = 5, redeclare package Medium = Medium1);
            Fluid.FixedResistances.FixedResistanceDpM res_2(m_flow_nominal = 5, dp_nominal = 10, use_dh = true, from_dp = false, redeclare package Medium = Medium2);
            Buildings.Fluid.Sensors.MassFlowRate[nPipPar, nPipSeg] mfr_2(redeclare package Medium = Medium2);
            Buildings.Fluid.HeatExchangers.BaseClasses.DuctManifoldFixedResistance ducFixRes_2(nPipPar = nPipPar, nPipSeg = nPipSeg, m_flow_nominal = 5, linearized = false, mStart_flow_a = 5, dp_nominal = 10, redeclare package Medium = Medium2);
            Buildings.Fluid.HeatExchangers.BaseClasses.DuctManifoldNoResistance ducNoRes_2(nPipPar = nPipPar, nPipSeg = nPipSeg, mStart_flow_a = 5, redeclare package Medium = Medium2);
            Buildings.Fluid.HeatExchangers.BaseClasses.CoilHeader hea1(nPipPar = nPipPar, mStart_flow_a = 5, redeclare package Medium = Medium1);
            Buildings.Fluid.HeatExchangers.BaseClasses.CoilHeader hea2(nPipPar = nPipPar, mStart_flow_a = 5, redeclare package Medium = Medium1);
            inner Modelica.Fluid.System system;
            Buildings.Fluid.Sources.Boundary_pT sou_2(use_p_in = true, use_T_in = true, p = 101335, T = 293.15, nPorts = 1, redeclare package Medium = Medium2);
            Buildings.Fluid.Sources.Boundary_pT sin_2(nPorts = 1, T = 283.15, redeclare package Medium = Medium2);
            Modelica.Blocks.Sources.Ramp P1(duration = 1, height = 40, offset = 101305);
          equation
            connect(TDb.y, sou_1.T_in);
            connect(P.y, sou_1.p_in);
            connect(res_1.port_a, pipNoRes_1.port_a);
            connect(res_2.port_a, ducNoRes_2.port_a);
            connect(pipFixRes_1.port_b, hea1.port_a);
            connect(hea1.port_b, mfr_1.port_a);
            connect(mfr_1.port_b, hea2.port_a);
            connect(hea2.port_b, pipNoRes_1.port_b);
            connect(ducFixRes_2.port_b, mfr_2.port_a);
            connect(mfr_2.port_b, ducNoRes_2.port_b);
            connect(sou_1.ports[1], pipFixRes_1.port_a);
            connect(sin_1.ports[1], res_1.port_b);
            connect(TDb.y, sou_2.T_in);
            connect(sin_2.ports[1], res_2.port_b);
            connect(P1.y, sou_2.p_in);
            connect(sou_2.ports[1], ducFixRes_2.port_a);
          end Manifold;
        end Examples;
      end BaseClasses;
    end HeatExchangers;

    package Sensors
      extends Modelica.Icons.SensorsPackage;

      model MassFlowRate
        extends Buildings.Fluid.Sensors.BaseClasses.PartialFlowSensor(final m_flow_nominal = 0, final m_flow_small = 0);
        extends Modelica.Icons.RotationalSensor;
        Modelica.Blocks.Interfaces.RealOutput m_flow(quantity = "MassFlowRate", final unit = "kg/s");
      equation
        m_flow = port_a.m_flow;
      end MassFlowRate;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        partial model PartialFlowSensor
          extends Modelica.Fluid.Interfaces.PartialTwoPort;
          parameter Modelica.SIunits.MassFlowRate m_flow_nominal(min = 0);
          parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * m_flow_nominal;
        equation
          port_b.m_flow = -port_a.m_flow;
          port_a.p = port_b.p;
          port_a.h_outflow = inStream(port_b.h_outflow);
          port_b.h_outflow = inStream(port_a.h_outflow);
          port_a.Xi_outflow = inStream(port_b.Xi_outflow);
          port_b.Xi_outflow = inStream(port_a.Xi_outflow);
          port_a.C_outflow = inStream(port_b.C_outflow);
          port_b.C_outflow = inStream(port_a.C_outflow);
        end PartialFlowSensor;
      end BaseClasses;
    end Sensors;

    package Sources
      extends Modelica.Icons.SourcesPackage;

      model Boundary_pT
        extends Modelica.Fluid.Sources.BaseClasses.PartialSource;
        parameter Boolean use_p_in = false annotation(Evaluate = true, HideResult = true);
        parameter Boolean use_T_in = false annotation(Evaluate = true, HideResult = true);
        parameter Boolean use_X_in = false annotation(Evaluate = true, HideResult = true);
        parameter Boolean use_C_in = false annotation(Evaluate = true, HideResult = true);
        parameter Medium.AbsolutePressure p = Medium.p_default;
        parameter Medium.Temperature T = Medium.T_default;
        parameter Medium.MassFraction[Medium.nX] X = Medium.X_default;
        parameter Medium.ExtraProperty[Medium.nC] C(quantity = Medium.extraPropertiesNames) = fill(0, Medium.nC);
        Modelica.Blocks.Interfaces.RealInput p_in if use_p_in;
        Modelica.Blocks.Interfaces.RealInput T_in if use_T_in;
        Modelica.Blocks.Interfaces.RealInput[Medium.nX] X_in if use_X_in;
        Modelica.Blocks.Interfaces.RealInput[Medium.nC] C_in if use_C_in;
      protected
        Modelica.Blocks.Interfaces.RealInput p_in_internal;
        Modelica.Blocks.Interfaces.RealInput T_in_internal;
        Modelica.Blocks.Interfaces.RealInput[Medium.nX] X_in_internal;
        Modelica.Blocks.Interfaces.RealInput[Medium.nC] C_in_internal;
      equation
        Modelica.Fluid.Utilities.checkBoundary(Medium.mediumName, Medium.substanceNames, Medium.singleState, true, X_in_internal, "Boundary_pT");
        connect(p_in, p_in_internal);
        connect(T_in, T_in_internal);
        connect(X_in, X_in_internal);
        connect(C_in, C_in_internal);
        if not use_p_in then
          p_in_internal = p;
        end if;
        if not use_T_in then
          T_in_internal = T;
        end if;
        if not use_X_in then
          X_in_internal = X;
        end if;
        if not use_C_in then
          C_in_internal = C;
        end if;
        medium.p = p_in_internal;
        medium.T = T_in_internal;
        medium.Xi = X_in_internal[1:Medium.nXi];
        ports.C_outflow = fill(C_in_internal, nPorts);
      end Boundary_pT;
    end Sources;

    package BaseClasses
      extends Modelica.Icons.BasesPackage;

      package FlowModels
        extends Modelica.Icons.BasesPackage;

        function basicFlowFunction_dp
          input Modelica.SIunits.Pressure dp(displayUnit = "Pa");
          input Real k(min = 0, unit = "");
          input Modelica.SIunits.MassFlowRate m_flow_turbulent(min = 0);
          output Modelica.SIunits.MassFlowRate m_flow;
        protected
          Modelica.SIunits.Pressure dp_turbulent(displayUnit = "Pa");
          Real kSqu(unit = "kg.m");
        algorithm
          kSqu := k * k;
          dp_turbulent := m_flow_turbulent ^ 2 / kSqu;
          m_flow := Modelica.Fluid.Utilities.regRoot2(x = dp, x_small = dp_turbulent, k1 = kSqu, k2 = kSqu);
        end basicFlowFunction_dp;

        function basicFlowFunction_m_flow
          input Modelica.SIunits.MassFlowRate m_flow;
          input Real k(unit = "");
          input Modelica.SIunits.MassFlowRate m_flow_turbulent(min = 0);
          output Modelica.SIunits.Pressure dp(displayUnit = "Pa");
        protected
          Real kSquInv(unit = "1/(kg.m)");
        algorithm
          kSquInv := 1 / k ^ 2;
          dp := Modelica.Fluid.Utilities.regSquare2(x = m_flow, x_small = m_flow_turbulent, k1 = kSquInv, k2 = kSquInv);
        end basicFlowFunction_m_flow;
      end FlowModels;

      partial model PartialResistance
        extends Buildings.Fluid.Interfaces.PartialTwoPortInterface(show_T = false, m_flow(start = 0, nominal = m_flow_nominal_pos), dp(start = 0, nominal = dp_nominal_pos), final m_flow_small = 1E-4 * abs(m_flow_nominal));
        parameter Boolean from_dp = false annotation(Evaluate = true);
        parameter Modelica.SIunits.Pressure dp_nominal(displayUnit = "Pa");
        parameter Boolean homotopyInitialization = true annotation(Evaluate = true);
        parameter Boolean linearized = false annotation(Evaluate = true);
        parameter Modelica.SIunits.MassFlowRate m_flow_turbulent(min = 0);
      protected
        parameter Medium.ThermodynamicState sta_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default);
        parameter Modelica.SIunits.DynamicViscosity eta_default = Medium.dynamicViscosity(sta_default);
        final parameter Modelica.SIunits.MassFlowRate m_flow_nominal_pos = abs(m_flow_nominal);
        final parameter Modelica.SIunits.Pressure dp_nominal_pos = abs(dp_nominal);
      equation
        port_a.h_outflow = inStream(port_b.h_outflow);
        port_b.h_outflow = inStream(port_a.h_outflow);
        port_a.m_flow + port_b.m_flow = 0;
        port_a.Xi_outflow = inStream(port_b.Xi_outflow);
        port_b.Xi_outflow = inStream(port_a.Xi_outflow);
        port_a.C_outflow = inStream(port_b.C_outflow);
        port_b.C_outflow = inStream(port_a.C_outflow);
      end PartialResistance;
    end BaseClasses;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;

      partial model PartialTwoPortInterface
        extends Modelica.Fluid.Interfaces.PartialTwoPort(port_a(p(start = Medium.p_default, nominal = Medium.p_default)), port_b(p(start = Medium.p_default, nominal = Medium.p_default)));
        parameter Modelica.SIunits.MassFlowRate m_flow_nominal;
        parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * abs(m_flow_nominal);
        parameter Boolean show_T = false;
        Modelica.SIunits.MassFlowRate m_flow(start = 0) = port_a.m_flow;
        Modelica.SIunits.Pressure dp(start = 0, displayUnit = "Pa");
        Medium.ThermodynamicState sta_a = Medium.setState_phX(port_a.p, noEvent(actualStream(port_a.h_outflow)), noEvent(actualStream(port_a.Xi_outflow))) if show_T;
        Medium.ThermodynamicState sta_b = Medium.setState_phX(port_b.p, noEvent(actualStream(port_b.h_outflow)), noEvent(actualStream(port_b.Xi_outflow))) if show_T;
      equation
        dp = port_a.p - port_b.p;
      end PartialTwoPortInterface;
    end Interfaces;
  end Fluid;

  package Media
    extends Modelica.Icons.Package;

    package ConstantPropertyLiquidWater
      extends Buildings.Media.Interfaces.PartialSimpleMedium(mediumName = "SimpleLiquidWater", cp_const = 4184, cv_const = 4184, d_const = 995.586, eta_const = 1.e-3, lambda_const = 0.598, a_const = 1484, T_min = Modelica.SIunits.Conversions.from_degC(-1), T_max = Modelica.SIunits.Conversions.from_degC(130), T0 = 273.15, MM_const = 0.018015268, fluidConstants = .Modelica.Media.Water.ConstantPropertyLiquidWater.simpleWaterConstants, ThermoStates = Interfaces.Choices.IndependentVariables.T);

      redeclare replaceable function extends specificInternalEnergy
      algorithm
        u := cv_const * (state.T - T0);
      end specificInternalEnergy;
    end ConstantPropertyLiquidWater;

    package PerfectGases
      extends Modelica.Icons.MaterialPropertiesPackage;

      package MoistAir
        extends Modelica.Media.Interfaces.PartialCondensingGases(mediumName = "Moist air perfect gas", substanceNames = {"water", "air"}, final reducedX = true, final singleState = false, reference_X = {0.01, 0.99}, fluidConstants = {Modelica.Media.IdealGases.Common.FluidData.H2O, Modelica.Media.IdealGases.Common.FluidData.N2});
        constant Integer Water = 1;
        constant Integer Air = 2;
        constant Real k_mair = steam.MM / dryair.MM;
        constant Buildings.Media.PerfectGases.Common.DataRecord dryair = Common.SingleGasData.Air;
        constant Buildings.Media.PerfectGases.Common.DataRecord steam = Common.SingleGasData.H2O;
        constant Modelica.SIunits.Temperature TMin = 200;
        constant Modelica.SIunits.Temperature TMax = 400;

        redeclare record extends ThermodynamicState  end ThermodynamicState;

        redeclare replaceable model extends BaseProperties
          MassFraction x_water;
          Real phi;
        protected
          constant .Modelica.SIunits.MolarMass[2] MMX = {steam.MM, dryair.MM};
          MassFraction X_liquid;
          MassFraction X_steam;
          MassFraction X_air;
          MassFraction X_sat;
          MassFraction x_sat;
          AbsolutePressure p_steam_sat;
        equation
          assert(T >= TMin and T <= TMax, "
          Temperature T is not in the allowed range " + String(TMin) + " <= (T =" + String(T) + " K) <= " + String(TMax) + " K
          required from medium model \"" + mediumName + "\".");
          MM = 1 / (Xi[Water] / MMX[Water] + (1.0 - Xi[Water]) / MMX[Air]);
          p_steam_sat = min(saturationPressure(T), 0.999 * p);
          X_sat = min(p_steam_sat * k_mair / max(100 * Modelica.Constants.eps, p - p_steam_sat) * (1 - Xi[Water]), 1.0);
          X_liquid = max(Xi[Water] - X_sat, 0.0);
          X_steam = Xi[Water] - X_liquid;
          X_air = 1 - Xi[Water];
          h = specificEnthalpy_pTX(p, T, Xi);
          R = dryair.R * (1 - X_steam / (1 - X_liquid)) + steam.R * X_steam / (1 - X_liquid);
          u = h - R * T;
          d = p / (R * T);
          state.p = p;
          state.T = T;
          state.X = X;
          x_sat = k_mair * p_steam_sat / max(100 * Modelica.Constants.eps, p - p_steam_sat);
          x_water = Xi[Water] / max(X_air, 100 * Modelica.Constants.eps);
          phi = p / p_steam_sat * Xi[Water] / (Xi[Water] + k_mair * X_air);
        end BaseProperties;

        redeclare function setState_pTX
          extends Modelica.Media.Air.MoistAir.setState_pTX;
        end setState_pTX;

        redeclare function setState_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X;
          output ThermodynamicState state;
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T_phX(p, h, X), X = X) else ThermodynamicState(p = p, T = T_phX(p, h, X), X = cat(1, X, {1 - sum(X)}));
        end setState_phX;

        redeclare function setState_dTX
          extends Modelica.Media.Air.MoistAir.setState_dTX;
        end setState_dTX;

        redeclare function gasConstant
          extends Modelica.Media.Air.MoistAir.gasConstant;
        end gasConstant;

        function saturationPressureLiquid
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat;
          output .Modelica.SIunits.AbsolutePressure psat;
        algorithm
          psat := 611.657 * Modelica.Math.exp(17.2799 - 4102.99 / (Tsat - 35.719));
        end saturationPressureLiquid;

        function saturationPressureLiquid_der
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat;
          input Real dTsat(unit = "K/s");
          output Real psat_der(unit = "Pa/s");
        algorithm
          psat_der := 611.657 * Modelica.Math.exp(17.2799 - 4102.99 / (Tsat - 35.719)) * 4102.99 * dTsat / (Tsat - 35.719) / (Tsat - 35.719);
        end saturationPressureLiquid_der;

        function sublimationPressureIce = Modelica.Media.Air.MoistAir.sublimationPressureIce;

        redeclare function extends saturationPressure
        algorithm
          psat := Buildings.Utilities.Math.Functions.spliceFunction(saturationPressureLiquid(Tsat), sublimationPressureIce(Tsat), Tsat - 273.16, 1.0);
        end saturationPressure;

        redeclare function pressure
          extends Modelica.Media.Air.MoistAir.pressure;
        end pressure;

        redeclare function temperature
          extends Modelica.Media.Air.MoistAir.temperature;
        end temperature;

        redeclare function density
          extends Modelica.Media.Air.MoistAir.density;
        end density;

        redeclare function specificEntropy
          extends Modelica.Media.Air.MoistAir.specificEntropy;
        end specificEntropy;

        redeclare function extends enthalpyOfVaporization
        algorithm
          r0 := 2501014.5;
        end enthalpyOfVaporization;

        redeclare replaceable function extends enthalpyOfLiquid
        algorithm
          h := (T - 273.15) * 4186;
        end enthalpyOfLiquid;

        replaceable function der_enthalpyOfLiquid
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T;
          output Real der_h;
        algorithm
          der_h := 4186 * der_T;
        end der_enthalpyOfLiquid;

        redeclare function enthalpyOfCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        algorithm
          h := (T - 273.15) * steam.cp + enthalpyOfVaporization(T);
        end enthalpyOfCondensingGas;

        replaceable function der_enthalpyOfCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T;
          output Real der_h;
        algorithm
          der_h := steam.cp * der_T;
        end der_enthalpyOfCondensingGas;

        redeclare function enthalpyOfNonCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        algorithm
          h := enthalpyOfDryAir(T);
        end enthalpyOfNonCondensingGas;

        replaceable function der_enthalpyOfNonCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T;
          output Real der_h;
        algorithm
          der_h := der_enthalpyOfDryAir(T, der_T);
        end der_enthalpyOfNonCondensingGas;

        redeclare replaceable function extends enthalpyOfGas
        algorithm
          h := enthalpyOfCondensingGas(T) * X[Water] + enthalpyOfDryAir(T) * (1.0 - X[Water]);
        end enthalpyOfGas;

        replaceable function enthalpyOfDryAir
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        algorithm
          h := (T - 273.15) * dryair.cp;
        end enthalpyOfDryAir;

        replaceable function der_enthalpyOfDryAir
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T;
          output Real der_h;
        algorithm
          der_h := dryair.cp * der_T;
        end der_enthalpyOfDryAir;

        redeclare replaceable function extends specificHeatCapacityCp
        algorithm
          cp := dryair.cp * (1 - state.X[Water]) + steam.cp * state.X[Water];
        end specificHeatCapacityCp;

        redeclare replaceable function extends specificHeatCapacityCv
        algorithm
          cv := dryair.cv * (1 - state.X[Water]) + steam.cv * state.X[Water];
        end specificHeatCapacityCv;

        redeclare function extends dynamicViscosity
        algorithm
          eta := 1.85E-5;
        end dynamicViscosity;

        redeclare function extends thermalConductivity
        algorithm
          lambda := Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluate({-4.8737307422969E-008, 7.67803133753502E-005, 0.0241814385504202}, Modelica.SIunits.Conversions.to_degC(state.T));
        end thermalConductivity;

        function h_pTX
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[:] X;
          output .Modelica.SIunits.SpecificEnthalpy h;
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction x_sat;
          .Modelica.SIunits.MassFraction X_liquid;
          .Modelica.SIunits.MassFraction X_steam;
          .Modelica.SIunits.MassFraction X_air;
          .Modelica.SIunits.SpecificEnthalpy hDryAir;
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := k_mair * p_steam_sat / (p - p_steam_sat);
          X_liquid := max(X[Water] - x_sat / (1 + x_sat), 0.0);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          hDryAir := (T - 273.15) * dryair.cp;
          h := hDryAir * X_air + ((T - 273.15) * steam.cp + 2501014.5) * X_steam + (T - 273.15) * 4186 * X_liquid;
        end h_pTX;

        redeclare function extends specificEnthalpy
        algorithm
          h := h_pTX(state.p, state.T, state.X);
        end specificEnthalpy;

        redeclare function extends specificInternalEnergy
          extends Modelica.Icons.Function;
        algorithm
          u := h_pTX(state.p, state.T, state.X) - gasConstant(state) * state.T;
        end specificInternalEnergy;

        redeclare function extends specificGibbsEnergy
          extends Modelica.Icons.Function;
        algorithm
          g := h_pTX(state.p, state.T, state.X) - state.T * specificEntropy(state);
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy
          extends Modelica.Icons.Function;
        algorithm
          f := h_pTX(state.p, state.T, state.X) - gasConstant(state) * state.T - state.T * specificEntropy(state);
        end specificHelmholtzEnergy;

        function T_phX
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X;
          output Temperature T;

        protected
          package Internal
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data
              extends Modelica.Media.IdealGases.Common.DataRecord;
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear
            algorithm
              y := h_pTX(p, x, X);
            end f_nonlinear;

            redeclare function extends solve  end solve;
          end Internal;

          constant Modelica.Media.IdealGases.Common.DataRecord steam = Modelica.Media.IdealGases.Common.SingleGasesData.H2O;
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction x_sat;
        algorithm
          T := 273.15 + (h - 2501014.5 * X[Water]) / ((1 - X[Water]) * dryair.cp + X[Water] * Buildings.Media.PerfectGases.Common.SingleGasData.H2O.cp);
          p_steam_sat := saturationPressure(T);
          x_sat := k_mair * p_steam_sat / (p - p_steam_sat);
          if X[Water] > x_sat / (1 + x_sat) then
            T := Internal.solve(h, TMin, TMax, p, X[1:nXi], steam);
          else
          end if;
        end T_phX;
      end MoistAir;

      package MoistAirUnsaturated
        extends Modelica.Media.Interfaces.PartialCondensingGases(mediumName = "Moist air unsaturated perfect gas", substanceNames = {"water", "air"}, final reducedX = true, final singleState = false, reference_X = {0.01, 0.99}, fluidConstants = {Modelica.Media.IdealGases.Common.FluidData.H2O, Modelica.Media.IdealGases.Common.FluidData.N2});
        constant Integer Water = 1;
        constant Integer Air = 2;
        constant Real k_mair = steam.MM / dryair.MM;
        constant Buildings.Media.PerfectGases.Common.DataRecord dryair = Common.SingleGasData.Air;
        constant Buildings.Media.PerfectGases.Common.DataRecord steam = Common.SingleGasData.H2O;

        redeclare record extends ThermodynamicState  end ThermodynamicState;

        redeclare replaceable model extends BaseProperties
          MassFraction x_water;
          Real phi;
        protected
          constant .Modelica.SIunits.MolarMass[2] MMX = {steam.MM, dryair.MM};
          MassFraction X_steam;
          MassFraction X_air;
          MassFraction X_sat;
          MassFraction x_sat;
          AbsolutePressure p_steam_sat;
        equation
          assert(T >= 200.0 and T <= 423.15, "
          Temperature T is not in the allowed range
          200.0 K <= (T =" + String(T) + " K) <= 423.15 K
          required from medium model \"" + mediumName + "\".");
          MM = 1 / (Xi[Water] / MMX[Water] + (1.0 - Xi[Water]) / MMX[Air]);
          p_steam_sat = min(saturationPressure(T), 0.999 * p);
          X_sat = min(p_steam_sat * k_mair / max(100 * Modelica.Constants.eps, p - p_steam_sat) * (1 - Xi[Water]), 1.0);
          X_steam = Xi[Water];
          X_air = 1 - Xi[Water];
          h = specificEnthalpy_pTX(p, T, Xi);
          R = dryair.R * (1 - X_steam) + steam.R * X_steam;
          u = h - R * T;
          d = p / (R * T);
          state.p = p;
          state.T = T;
          state.X = X;
          x_sat = k_mair * p_steam_sat / max(100 * Modelica.Constants.eps, p - p_steam_sat);
          x_water = Xi[Water] / max(X_air, 100 * Modelica.Constants.eps);
          phi = p / p_steam_sat * Xi[Water] / (Xi[Water] + k_mair * X_air);
        end BaseProperties;

        redeclare function setState_pTX
          extends Buildings.Media.PerfectGases.MoistAir.setState_pTX;
        end setState_pTX;

        redeclare function setState_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X;
          output ThermodynamicState state;
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T_phX(p, h, X), X = X) else ThermodynamicState(p = p, T = T_phX(p, h, X), X = cat(1, X, {1 - sum(X)}));
        end setState_phX;

        redeclare function setState_dTX
          extends Buildings.Media.PerfectGases.MoistAir.setState_dTX;
        end setState_dTX;

        redeclare function gasConstant
          extends Buildings.Media.PerfectGases.MoistAir.gasConstant;
        end gasConstant;

        function saturationPressureLiquid
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat;
          output .Modelica.SIunits.AbsolutePressure psat;
        algorithm
          psat := 611.657 * Modelica.Math.exp(17.2799 - 4102.99 / (Tsat - 35.719));
        end saturationPressureLiquid;

        function saturationPressureLiquid_der
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat;
          input Real dTsat(unit = "K/s");
          output Real psat_der(unit = "Pa/s");
        algorithm
          psat_der := 611.657 * Modelica.Math.exp(17.2799 - 4102.99 / (Tsat - 35.719)) * 4102.99 * dTsat / (Tsat - 35.719) / (Tsat - 35.719);
        end saturationPressureLiquid_der;

        function sublimationPressureIce = Buildings.Media.PerfectGases.MoistAir.sublimationPressureIce;

        redeclare function extends saturationPressure
        algorithm
          psat := Buildings.Utilities.Math.Functions.spliceFunction(saturationPressureLiquid(Tsat), sublimationPressureIce(Tsat), Tsat - 273.16, 1.0);
        end saturationPressure;

        redeclare function pressure
          extends Buildings.Media.PerfectGases.MoistAir.pressure;
        end pressure;

        redeclare function temperature
          extends Buildings.Media.PerfectGases.MoistAir.temperature;
        end temperature;

        redeclare function density
          extends Buildings.Media.PerfectGases.MoistAir.density;
        end density;

        redeclare function specificEntropy
          extends Buildings.Media.PerfectGases.MoistAir.specificEntropy;
        end specificEntropy;

        redeclare function extends enthalpyOfVaporization
        algorithm
          r0 := 2501014.5;
        end enthalpyOfVaporization;

        redeclare replaceable function extends enthalpyOfLiquid
        algorithm
          h := (T - 273.15) * 4186;
        end enthalpyOfLiquid;

        replaceable function der_enthalpyOfLiquid
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T;
          output Real der_h;
        algorithm
          der_h := 4186 * der_T;
        end der_enthalpyOfLiquid;

        redeclare function enthalpyOfCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        algorithm
          h := (T - 273.15) * steam.cp + enthalpyOfVaporization(T);
        end enthalpyOfCondensingGas;

        replaceable function der_enthalpyOfCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T;
          output Real der_h;
        algorithm
          der_h := steam.cp * der_T;
        end der_enthalpyOfCondensingGas;

        redeclare function enthalpyOfNonCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        algorithm
          h := enthalpyOfDryAir(T);
        end enthalpyOfNonCondensingGas;

        replaceable function der_enthalpyOfNonCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T;
          output Real der_h;
        algorithm
          der_h := der_enthalpyOfDryAir(T, der_T);
        end der_enthalpyOfNonCondensingGas;

        redeclare replaceable function extends enthalpyOfGas
        algorithm
          h := enthalpyOfCondensingGas(T) * X[Water] + enthalpyOfDryAir(T) * (1.0 - X[Water]);
        end enthalpyOfGas;

        replaceable function enthalpyOfDryAir
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        algorithm
          h := (T - 273.15) * dryair.cp;
        end enthalpyOfDryAir;

        replaceable function der_enthalpyOfDryAir
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T;
          output Real der_h;
        algorithm
          der_h := dryair.cp * der_T;
        end der_enthalpyOfDryAir;

        redeclare replaceable function extends specificHeatCapacityCp
        algorithm
          cp := dryair.cp * (1 - state.X[Water]) + steam.cp * state.X[Water];
        end specificHeatCapacityCp;

        replaceable function der_specificHeatCapacityCp
          input ThermodynamicState state;
          input ThermodynamicState der_state;
          output Real der_cp(unit = "J/(kg.K.s)");
        algorithm
          der_cp := (steam.cp - dryair.cp) * der_state.X[Water];
        end der_specificHeatCapacityCp;

        redeclare replaceable function extends specificHeatCapacityCv
        algorithm
          cv := dryair.cv * (1 - state.X[Water]) + steam.cv * state.X[Water];
        end specificHeatCapacityCv;

        replaceable function der_specificHeatCapacityCv
          input ThermodynamicState state;
          input ThermodynamicState der_state;
          output Real der_cv(unit = "J/(kg.K.s)");
        algorithm
          der_cv := (steam.cv - dryair.cv) * der_state.X[Water];
        end der_specificHeatCapacityCv;

        redeclare function extends dynamicViscosity
        algorithm
          eta := 1.85E-5;
        end dynamicViscosity;

        redeclare function extends thermalConductivity
        algorithm
          lambda := Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluate({-4.8737307422969E-008, 7.67803133753502E-005, 0.0241814385504202}, Modelica.SIunits.Conversions.to_degC(state.T));
        end thermalConductivity;

        function h_pTX
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[:] X;
          output .Modelica.SIunits.SpecificEnthalpy h;
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction x_sat;
          .Modelica.SIunits.SpecificEnthalpy hDryAir;
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := k_mair * p_steam_sat / (p - p_steam_sat);
          hDryAir := (T - 273.15) * dryair.cp;
          h := hDryAir * (1 - X[Water]) + ((T - 273.15) * steam.cp + 2501014.5) * X[Water];
        end h_pTX;

        redeclare function extends specificEnthalpy
        algorithm
          h := h_pTX(state.p, state.T, state.X);
        end specificEnthalpy;

        redeclare function extends specificInternalEnergy
          extends Modelica.Icons.Function;
        algorithm
          u := h_pTX(state.p, state.T, state.X) - gasConstant(state) * state.T;
        end specificInternalEnergy;

        redeclare function extends specificGibbsEnergy
          extends Modelica.Icons.Function;
        algorithm
          g := h_pTX(state.p, state.T, state.X) - state.T * specificEntropy(state);
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy
          extends Modelica.Icons.Function;
        algorithm
          f := h_pTX(state.p, state.T, state.X) - gasConstant(state) * state.T - state.T * specificEntropy(state);
        end specificHelmholtzEnergy;

        function T_phX
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X;
          output Temperature T;
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction x_sat;
        algorithm
          T := 273.15 + (h - 2501014.5 * X[Water]) / ((1 - X[Water]) * dryair.cp + X[Water] * steam.cp);
          p_steam_sat := saturationPressure(T);
          x_sat := k_mair * p_steam_sat / (p - p_steam_sat);
        end T_phX;
      end MoistAirUnsaturated;

      package Common
        extends Modelica.Icons.MaterialPropertiesPackage;

        record DataRecord
          extends Modelica.Icons.Record;
          String name;
          Modelica.SIunits.MolarMass MM;
          Modelica.SIunits.SpecificHeatCapacity R;
          Modelica.SIunits.SpecificHeatCapacity cp;
          Modelica.SIunits.SpecificHeatCapacity cv;
        end DataRecord;

        package SingleGasData
          extends Modelica.Icons.MaterialPropertiesPackage;
          constant PerfectGases.Common.DataRecord Air(name = Modelica.Media.IdealGases.Common.SingleGasesData.Air.name, R = Modelica.Media.IdealGases.Common.SingleGasesData.Air.R, MM = Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, cp = 1006, cv = 1006 - Modelica.Media.IdealGases.Common.SingleGasesData.Air.R);
          constant PerfectGases.Common.DataRecord H2O(name = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.name, R = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.R, MM = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.MM, cp = 1860, cv = 1860 - Modelica.Media.IdealGases.Common.SingleGasesData.H2O.R);
        end SingleGasData;
      end Common;
    end PerfectGases;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;

      package Choices
        type IndependentVariables = enumeration(T, pT, ph, phX, pTX, dTX);
      end Choices;

      partial package PartialSimpleMedium
        extends Modelica.Media.Interfaces.PartialPureSubstance(ThermoStates = Choices.IndependentVariables.pT, final singleState = true, reference_p = p0, p_default = p0);
        constant SpecificHeatCapacity cp_const;
        constant SpecificHeatCapacity cv_const;
        constant Density d_const;
        constant DynamicViscosity eta_const;
        constant ThermalConductivity lambda_const;
        constant VelocityOfSound a_const;
        constant Temperature T_min;
        constant Temperature T_max;
        constant Temperature T0 = reference_T;
        constant MolarMass MM_const;
        constant FluidConstants[nS] fluidConstants;

        redeclare record extends ThermodynamicState
          AbsolutePressure p(start = p_default);
          Temperature T(start = T_default);
        end ThermodynamicState;

        constant Modelica.SIunits.AbsolutePressure p0 = 3E5;

        redeclare replaceable model extends BaseProperties
        equation
          assert(T >= T_min and T <= T_max, "
          Temperature T (= " + String(T) + " K) is not
          in the allowed range (" + String(T_min) + " K <= T <= " + String(T_max) + " K)
          required from medium model \"" + mediumName + "\".
          ");
          h = specificEnthalpy_pTX(p, T, X);
          u = cv_const * (T - T0);
          d = d_const;
          R = 0;
          MM = MM_const;
          state.T = T;
          state.p = p;
        end BaseProperties;

        redeclare function setState_pTX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := ThermodynamicState(p = p, T = T);
        end setState_pTX;

        redeclare function setState_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := ThermodynamicState(p = p, T = temperature_phX(p, h, X));
        end setState_phX;

        redeclare replaceable function setState_psX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEntropy s;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := ThermodynamicState(p = p, T = Modelica.Math.exp(s / cp_const + Modelica.Math.log(T0)));
        end setState_psX;

        redeclare function setState_dTX
          extends Modelica.Icons.Function;
          input Density d;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          assert(false, "pressure can not be computed from temperature and density for an incompressible fluid!");
        end setState_dTX;

        redeclare function extends setSmoothState
        algorithm
          state := ThermodynamicState(p = Modelica.Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), T = Modelica.Media.Common.smoothStep(x, state_a.T, state_b.T, x_small));
        end setSmoothState;

        redeclare function extends dynamicViscosity
        algorithm
          eta := eta_const;
        end dynamicViscosity;

        redeclare function extends thermalConductivity
        algorithm
          lambda := lambda_const;
        end thermalConductivity;

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
          d := d_const;
        end density;

        redeclare function extends specificEnthalpy
        algorithm
          h := cp_const * (state.T - T0);
        end specificEnthalpy;

        redeclare function extends specificHeatCapacityCp
        algorithm
          cp := cp_const;
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv
        algorithm
          cv := cv_const;
        end specificHeatCapacityCv;

        redeclare function extends isentropicExponent
        algorithm
          gamma := cp_const / cv_const;
        end isentropicExponent;

        redeclare function extends velocityOfSound
        algorithm
          a := a_const;
        end velocityOfSound;

        redeclare function specificEnthalpy_pTX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input Temperature T;
          input MassFraction[nX] X;
          output SpecificEnthalpy h;
        algorithm
          h := cp_const * (T - T0);
        end specificEnthalpy_pTX;

        redeclare function temperature_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[nX] X;
          output Temperature T;
        algorithm
          T := T0 + h / cp_const;
        end temperature_phX;
      end PartialSimpleMedium;
    end Interfaces;
  end Media;

  package Utilities
    extends Modelica.Icons.Package;

    package Math
      extends Modelica.Icons.Package;

      package Functions
        extends Modelica.Icons.VariantsPackage;

        function spliceFunction
          input Real pos;
          input Real neg;
          input Real x;
          input Real deltax;
          output Real out;
        protected
          Real scaledX1;
          Real y;
          constant Real asin1 = Modelica.Math.asin(1);
        algorithm
          scaledX1 := x / deltax;
          if scaledX1 <= (-0.999999999) then
            out := neg;
          elseif scaledX1 >= 0.999999999 then
            out := pos;
          else
            y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX1 * asin1)) + 1) / 2;
            out := pos * y + (1 - y) * neg;
          end if;
        end spliceFunction;

        package BaseClasses
          extends Modelica.Icons.BasesPackage;

          function der_spliceFunction
            input Real pos;
            input Real neg;
            input Real x;
            input Real deltax = 1;
            input Real dpos;
            input Real dneg;
            input Real dx;
            input Real ddeltax = 0;
            output Real out;
          protected
            Real scaledX;
            Real scaledX1;
            Real dscaledX1;
            Real y;
            constant Real asin1 = Modelica.Math.asin(1);
          algorithm
            scaledX1 := x / deltax;
            if scaledX1 <= (-0.99999999999) then
              out := dneg;
            elseif scaledX1 >= 0.9999999999 then
              out := dpos;
            else
              scaledX := scaledX1 * asin1;
              dscaledX1 := (dx - scaledX1 * ddeltax) / deltax;
              y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX)) + 1) / 2;
              out := dpos * y + (1 - y) * dneg;
              out := out + (pos - neg) * dscaledX1 * asin1 / 2 / (Modelica.Math.cosh(Modelica.Math.tan(scaledX)) * Modelica.Math.cos(scaledX)) ^ 2;
            end if;
          end der_spliceFunction;
        end BaseClasses;
      end Functions;
    end Math;
  end Utilities;

  package BaseClasses
    extends Modelica.Icons.BasesPackage;

    block BaseIcon  end BaseIcon;
  end BaseClasses;
end Buildings;

package ModelicaServices
  extends Modelica.Icons.Package;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15;
    final constant Real small = 1.e-60;
    final constant Real inf = 1.e+60;
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax();
  end Machine;
end ModelicaServices;

package Modelica
  extends Modelica.Icons.Package;

  package Blocks
    extends Modelica.Icons.Package;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real;
      connector RealOutput = output Real;

      partial block SO
        extends Modelica.Blocks.Icons.Block;
        RealOutput y;
      end SO;
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

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial block Block  end Block;
    end Icons;
  end Blocks;

  package Fluid
    extends Modelica.Icons.Package;

    model System
      parameter Modelica.SIunits.AbsolutePressure p_ambient = 101325;
      parameter Modelica.SIunits.Temperature T_ambient = 293.15;
      parameter Modelica.SIunits.Acceleration g = Modelica.Constants.g_n;
      parameter Boolean allowFlowReversal = true annotation(Evaluate = true);
      parameter Modelica.Fluid.Types.Dynamics energyDynamics = Types.Dynamics.DynamicFreeInitial annotation(Evaluate = true);
      parameter Modelica.Fluid.Types.Dynamics massDynamics = energyDynamics annotation(Evaluate = true);
      final parameter Modelica.Fluid.Types.Dynamics substanceDynamics = massDynamics annotation(Evaluate = true);
      final parameter Modelica.Fluid.Types.Dynamics traceDynamics = massDynamics annotation(Evaluate = true);
      parameter Modelica.Fluid.Types.Dynamics momentumDynamics = Types.Dynamics.SteadyState annotation(Evaluate = true);
      parameter Modelica.SIunits.MassFlowRate m_flow_start = 0;
      parameter Modelica.SIunits.AbsolutePressure p_start = p_ambient;
      parameter Modelica.SIunits.Temperature T_start = T_ambient;
      parameter Boolean use_eps_Re = false annotation(Evaluate = true);
      parameter Modelica.SIunits.MassFlowRate m_flow_nominal = if use_eps_Re then 1 else 1e2 * m_flow_small;
      parameter Real eps_m_flow(min = 0) = 1e-4;
      parameter Modelica.SIunits.AbsolutePressure dp_small(min = 0) = 1;
      parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1e-2;
    end System;

    package Fittings
      extends Modelica.Icons.VariantsPackage;

      model MultiPort
        function positiveMax
          extends Modelica.Icons.Function;
          input Real x;
          output Real y;
        algorithm
          y := max(x, 1e-10);
        end positiveMax;

        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
        parameter Integer nPorts_b = 0;
        Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare package Medium = Medium);
        Modelica.Fluid.Interfaces.FluidPorts_b[nPorts_b] ports_b(redeclare each package Medium = Medium);
        Medium.MassFraction[nPorts_b, Medium.nXi] ports_b_Xi_inStream;
        Medium.ExtraProperty[nPorts_b, Medium.nC] ports_b_C_inStream;
      equation
        for i in 1:nPorts_b loop
          assert(cardinality(ports_b[i]) <= 1, "
          each ports_b[i] of boundary shall at most be connected to one component.
          If two or more connections are present, ideal mixing takes
          place with these connections, which is usually not the intention
          of the modeller. Increase nPorts_b to add an additional port.
          ");
        end for;
        0 = port_a.m_flow + sum(ports_b.m_flow);
        ports_b.p = fill(port_a.p, nPorts_b);
        port_a.h_outflow = sum(array(positiveMax(ports_b[j].m_flow) * inStream(ports_b[j].h_outflow) for j in 1:nPorts_b)) / sum(array(positiveMax(ports_b[j].m_flow) for j in 1:nPorts_b));
        for j in 1:nPorts_b loop
          ports_b[j].h_outflow = inStream(port_a.h_outflow);
          ports_b[j].Xi_outflow = inStream(port_a.Xi_outflow);
          ports_b[j].C_outflow = inStream(port_a.C_outflow);
          ports_b_Xi_inStream[j, :] = inStream(ports_b[j].Xi_outflow);
          ports_b_C_inStream[j, :] = inStream(ports_b[j].C_outflow);
        end for;
        for i in 1:Medium.nXi loop
          port_a.Xi_outflow[i] = positiveMax(ports_b.m_flow) * ports_b_Xi_inStream[:, i] / sum(positiveMax(ports_b.m_flow));
        end for;
        for i in 1:Medium.nC loop
          port_a.C_outflow[i] = positiveMax(ports_b.m_flow) * ports_b_C_inStream[:, i] / sum(positiveMax(ports_b.m_flow));
        end for;
      end MultiPort;
    end Fittings;

    package Sources
      extends Modelica.Icons.SourcesPackage;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        partial model PartialSource
          parameter Integer nPorts = 0;
          replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
          Medium.BaseProperties medium;
          Interfaces.FluidPorts_b[nPorts] ports(redeclare each package Medium = Medium, m_flow(each max = if flowDirection == Types.PortFlowDirection.Leaving then 0 else +.Modelica.Constants.inf, each min = if flowDirection == Types.PortFlowDirection.Entering then 0 else -.Modelica.Constants.inf));
        protected
          parameter Types.PortFlowDirection flowDirection = Types.PortFlowDirection.Bidirectional annotation(Evaluate = true);
        equation
          for i in 1:nPorts loop
            assert(cardinality(ports[i]) <= 1, "
            each ports[i] of boundary shall at most be connected to one component.
            If two or more connections are present, ideal mixing takes
            place with these connections, which is usually not the intention
            of the modeller. Increase nPorts to add an additional port.
            ");
            ports[i].p = medium.p;
            ports[i].h_outflow = medium.h;
            ports[i].Xi_outflow = medium.Xi;
          end for;
        end PartialSource;
      end BaseClasses;
    end Sources;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;

      connector FluidPort
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
        flow Medium.MassFlowRate m_flow;
        Medium.AbsolutePressure p;
        stream Medium.SpecificEnthalpy h_outflow;
        stream Medium.MassFraction[Medium.nXi] Xi_outflow;
        stream Medium.ExtraProperty[Medium.nC] C_outflow;
      end FluidPort;

      connector FluidPort_a
        extends FluidPort;
      end FluidPort_a;

      connector FluidPort_b
        extends FluidPort;
      end FluidPort_b;

      connector FluidPorts_b
        extends FluidPort;
      end FluidPorts_b;

      partial model PartialTwoPort
        outer Modelica.Fluid.System system;
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
        parameter Boolean allowFlowReversal = system.allowFlowReversal annotation(Evaluate = true);
        Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -.Modelica.Constants.inf else 0));
        Modelica.Fluid.Interfaces.FluidPort_b port_b(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +.Modelica.Constants.inf else 0));
      protected
        parameter Boolean port_a_exposesState = false;
        parameter Boolean port_b_exposesState = false;
        parameter Boolean showDesignFlowDirection = true;
      end PartialTwoPort;
    end Interfaces;

    package Types
      extends Modelica.Icons.TypesPackage;
      type Dynamics = enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState);
      type PortFlowDirection = enumeration(Entering, Leaving, Bidirectional);
    end Types;

    package Utilities
      extends Modelica.Icons.UtilitiesPackage;

      function checkBoundary
        extends Modelica.Icons.Function;
        input String mediumName;
        input String[:] substanceNames;
        input Boolean singleState;
        input Boolean define_p;
        input Real[:] X_boundary;
        input String modelName = "??? boundary ???";
      protected
        Integer nX = size(X_boundary, 1);
        String X_str;
      algorithm
        assert(not singleState or singleState and define_p, "
        Wrong value of parameter define_p (= false) in model \"" + modelName + "\":
        The selected medium \"" + mediumName + "\" has Medium.singleState=true.
        Therefore, an boundary density cannot be defined and
        define_p = true is required.
        ");
        for i in 1:nX loop
          assert(X_boundary[i] >= 0.0, "
          Wrong boundary mass fractions in medium \"" + mediumName + "\" in model \"" + modelName + "\":
          The boundary value X_boundary(" + String(i) + ") = " + String(X_boundary[i]) + "
          is negative. It must be positive.
          ");
        end for;
        if nX > 0 and abs(sum(X_boundary) - 1.0) > 1.e-10 then
          X_str := "";
          for i in 1:nX loop
            X_str := X_str + "   X_boundary[" + String(i) + "] = " + String(X_boundary[i]) + " \"" + substanceNames[i] + "\"\n";
          end for;
          Modelica.Utilities.Streams.error("The boundary mass fractions in medium \"" + mediumName + "\" in model \"" + modelName + "\"\n" + "do not sum up to 1. Instead, sum(X_boundary) = " + String(sum(X_boundary)) + ":\n" + X_str);
        else
        end if;
      end checkBoundary;

      function regRoot2
        extends Modelica.Icons.Function;
        input Real x;
        input Real x_small(min = 0) = 0.01;
        input Real k1(min = 0) = 1;
        input Real k2(min = 0) = 1;
        input Boolean use_yd0 = false;
        input Real yd0(min = 0) = 1;
        output Real y;

      protected
        encapsulated function regRoot2_utility
          extends .Modelica.Icons.Function;
          input Real x;
          input Real x1;
          input Real k1;
          input Real k2;
          input Boolean use_yd0;
          input Real yd0(min = 0);
          output Real y;
        protected
          Real x2;
          Real xsqrt1;
          Real xsqrt2;
          Real y1;
          Real y2;
          Real y1d;
          Real y2d;
          Real w;
          Real y0d;
          Real w1;
          Real w2;
          Real sqrt_k1 = if k1 > 0 then sqrt(k1) else 0;
          Real sqrt_k2 = if k2 > 0 then sqrt(k2) else 0;
        algorithm
          if k2 > 0 then
            x2 := -x1 * (k2 / k1);
          elseif k1 > 0 then
            x2 := -x1;
          else
            y := 0;
            return;
          end if;
          if x <= x2 then
            y := -sqrt_k2 * sqrt(abs(x));
          else
            y1 := sqrt_k1 * sqrt(x1);
            y2 := -sqrt_k2 * sqrt(abs(x2));
            y1d := sqrt_k1 / sqrt(x1) / 2;
            y2d := sqrt_k2 / sqrt(abs(x2)) / 2;
            if use_yd0 then
              y0d := yd0;
            else
              w := x2 / x1;
              y0d := ((3 * y2 - x2 * y2d) / w - (3 * y1 - x1 * y1d) * w) / (2 * x1 * (1 - w));
            end if;
            w1 := sqrt_k1 * sqrt(8.75 / x1);
            w2 := sqrt_k2 * sqrt(8.75 / abs(x2));
            y0d := smooth(2, min(y0d, 0.9 * min(w1, w2)));
            y := y1 * (if x >= 0 then .Modelica.Fluid.Utilities.evaluatePoly3_derivativeAtZero(x / x1, 1, 1, y1d * x1 / y1, y0d * x1 / y1) else .Modelica.Fluid.Utilities.evaluatePoly3_derivativeAtZero(x / x1, x2 / x1, y2 / y1, y2d * x1 / y1, y0d * x1 / y1));
          end if;
        end regRoot2_utility;
      algorithm
        y := smooth(2, if x >= x_small then sqrt(k1 * x) else if x <= (-x_small) then -sqrt(k2 * abs(x)) else if k1 >= k2 then regRoot2_utility(x, x_small, k1, k2, use_yd0, yd0) else -regRoot2_utility(-x, x_small, k2, k1, use_yd0, yd0));
      end regRoot2;

      function regSquare2
        extends Modelica.Icons.Function;
        input Real x;
        input Real x_small(min = 0) = 0.01;
        input Real k1(min = 0) = 1;
        input Real k2(min = 0) = 1;
        input Boolean use_yd0 = false;
        input Real yd0(min = 0) = 1;
        output Real y;

      protected
        encapsulated function regSquare2_utility
          extends .Modelica.Icons.Function;
          input Real x;
          input Real x1;
          input Real k1;
          input Real k2;
          input Boolean use_yd0 = false;
          input Real yd0(min = 0) = 1;
          output Real y;
        protected
          Real x2;
          Real y1;
          Real y2;
          Real y1d;
          Real y2d;
          Real w;
          Real w1;
          Real w2;
          Real y0d;
          Real ww;
        algorithm
          x2 := -x1;
          if x <= x2 then
            y := -k2 * x ^ 2;
          else
            y1 := k1 * x1 ^ 2;
            y2 := -k2 * x2 ^ 2;
            y1d := k1 * 2 * x1;
            y2d := -k2 * 2 * x2;
            if use_yd0 then
              y0d := yd0;
            else
              w := x2 / x1;
              y0d := ((3 * y2 - x2 * y2d) / w - (3 * y1 - x1 * y1d) * w) / (2 * x1 * (1 - w));
            end if;
            w1 := sqrt(5) * k1 * x1;
            w2 := sqrt(5) * k2 * abs(x2);
            ww := 0.9 * (if w1 < w2 then w1 else w2);
            if ww < y0d then
              y0d := ww;
            else
            end if;
            y := if x >= 0 then .Modelica.Fluid.Utilities.evaluatePoly3_derivativeAtZero(x, x1, y1, y1d, y0d) else .Modelica.Fluid.Utilities.evaluatePoly3_derivativeAtZero(x, x2, y2, y2d, y0d);
          end if;
        end regSquare2_utility;
      algorithm
        y := smooth(2, if x >= x_small then k1 * x ^ 2 else if x <= (-x_small) then -k2 * x ^ 2 else if k1 >= k2 then regSquare2_utility(x, x_small, k1, k2, use_yd0, yd0) else -regSquare2_utility(-x, x_small, k2, k1, use_yd0, yd0));
      end regSquare2;

      function evaluatePoly3_derivativeAtZero
        extends Modelica.Icons.Function;
        input Real x;
        input Real x1;
        input Real y1;
        input Real y1d;
        input Real y0d;
        output Real y;
      protected
        Real a1;
        Real a2;
        Real a3;
        Real xx;
      algorithm
        a1 := x1 * y0d;
        a2 := 3 * y1 - x1 * y1d - 2 * a1;
        a3 := y1 - a2 - a1;
        xx := x / x1;
        y := xx * (a1 + xx * (a2 + xx * a3));
      end evaluatePoly3_derivativeAtZero;
    end Utilities;
  end Fluid;

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
        constant Temperature reference_T = 298.15;
        constant MassFraction[nX] reference_X = fill(1 / nX, nX);
        constant AbsolutePressure p_default = 101325;
        constant Temperature T_default = Modelica.SIunits.Conversions.from_degC(20);
        constant MassFraction[nX] X_default = reference_X;
        final constant Integer nS = size(substanceNames, 1) annotation(Evaluate = true);
        constant Integer nX = nS annotation(Evaluate = true);
        constant Integer nXi = if fixedX then 0 else if reducedX then nS - 1 else nS annotation(Evaluate = true);
        final constant Integer nC = size(extraPropertiesNames, 1) annotation(Evaluate = true);
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
          parameter Boolean preferredMediumStates = false annotation(Evaluate = true);
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
              assert(X[i] >= (-1.e-5) and X[i] <= 1 + 1.e-5, "Mass fraction X[" + String(i) + "] = " + String(X[i]) + "of substance " + substanceNames[i] + "\nof medium " + mediumName + " is not in the range 0..1");
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

        replaceable partial function setState_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        end setState_phX;

        replaceable partial function setState_psX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEntropy s;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        end setState_psX;

        replaceable partial function setState_dTX
          extends Modelica.Icons.Function;
          input Density d;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        end setState_dTX;

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

        replaceable partial function density_derp_h
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output DerDensityByPressure ddph;
        end density_derp_h;

        replaceable partial function density_derh_p
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output DerDensityByEnthalpy ddhp;
        end density_derh_p;

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

        replaceable partial function density_derX
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output Density[nX] dddX;
        end density_derX;

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

        replaceable function temperature_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X = reference_X;
          output Temperature T;
        algorithm
          T := temperature(setState_phX(p, h, X));
        end temperature_phX;

        type MassFlowRate = .Modelica.SIunits.MassFlowRate(quantity = "MassFlowRate." + mediumName, min = -1.0e5, max = 1.e5);
      end PartialMedium;

      partial package PartialPureSubstance
        extends PartialMedium(final reducedX = true, final fixedX = true);

        redeclare replaceable partial model extends BaseProperties  end BaseProperties;
      end PartialPureSubstance;

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

      partial package PartialCondensingGases
        extends PartialMixtureMedium(ThermoStates = Choices.IndependentVariables.pTX);

        replaceable partial function saturationPressure
          extends Modelica.Icons.Function;
          input Temperature Tsat;
          output AbsolutePressure psat;
        end saturationPressure;

        replaceable partial function enthalpyOfVaporization
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy r0;
        end enthalpyOfVaporization;

        replaceable partial function enthalpyOfLiquid
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        end enthalpyOfLiquid;

        replaceable partial function enthalpyOfGas
          extends Modelica.Icons.Function;
          input Temperature T;
          input MassFraction[:] X;
          output SpecificEnthalpy h;
        end enthalpyOfGas;

        replaceable partial function enthalpyOfCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        end enthalpyOfCondensingGas;

        replaceable partial function enthalpyOfNonCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEnthalpy h;
        end enthalpyOfNonCondensingGas;
      end PartialCondensingGases;

      partial package PartialSimpleMedium
        extends Interfaces.PartialPureSubstance(final ThermoStates = Choices.IndependentVariables.pT, final singleState = true);
        constant SpecificHeatCapacity cp_const;
        constant SpecificHeatCapacity cv_const;
        constant Density d_const;
        constant DynamicViscosity eta_const;
        constant ThermalConductivity lambda_const;
        constant VelocityOfSound a_const;
        constant Temperature T_min;
        constant Temperature T_max;
        constant Temperature T0 = reference_T;
        constant MolarMass MM_const;
        constant FluidConstants[nS] fluidConstants;

        redeclare record extends ThermodynamicState
          AbsolutePressure p;
          Temperature T;
        end ThermodynamicState;

        redeclare replaceable model extends BaseProperties
        equation
          assert(T >= T_min and T <= T_max, "
          Temperature T (= " + String(T) + " K) is not
          in the allowed range (" + String(T_min) + " K <= T <= " + String(T_max) + " K)
          required from medium model \"" + mediumName + "\".
          ");
          h = specificEnthalpy_pTX(p, T, X);
          u = cv_const * (T - T0);
          d = d_const;
          R = 0;
          MM = MM_const;
          state.T = T;
          state.p = p;
        end BaseProperties;

        redeclare function setState_pTX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := ThermodynamicState(p = p, T = T);
        end setState_pTX;

        redeclare function setState_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := ThermodynamicState(p = p, T = T0 + h / cp_const);
        end setState_phX;

        redeclare replaceable function setState_psX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEntropy s;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := ThermodynamicState(p = p, T = Modelica.Math.exp(s / cp_const + Modelica.Math.log(reference_T)));
        end setState_psX;

        redeclare function setState_dTX
          extends Modelica.Icons.Function;
          input Density d;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          assert(false, "Pressure can not be computed from temperature and density for an incompressible fluid!");
        end setState_dTX;

        redeclare function extends setSmoothState
        algorithm
          state := ThermodynamicState(p = Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), T = Media.Common.smoothStep(x, state_a.T, state_b.T, x_small));
        end setSmoothState;

        redeclare function extends dynamicViscosity
        algorithm
          eta := eta_const;
        end dynamicViscosity;

        redeclare function extends thermalConductivity
        algorithm
          lambda := lambda_const;
        end thermalConductivity;

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
          d := d_const;
        end density;

        redeclare function extends specificEnthalpy
        algorithm
          h := cp_const * (state.T - T0);
        end specificEnthalpy;

        redeclare function extends specificHeatCapacityCp
        algorithm
          cp := cp_const;
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv
        algorithm
          cv := cv_const;
        end specificHeatCapacityCv;

        redeclare function extends isentropicExponent
        algorithm
          gamma := cp_const / cv_const;
        end isentropicExponent;

        redeclare function extends velocityOfSound
        algorithm
          a := a_const;
        end velocityOfSound;

        redeclare function specificEnthalpy_pTX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input Temperature T;
          input MassFraction[nX] X;
          output SpecificEnthalpy h;
        algorithm
          h := cp_const * (T - T0);
        end specificEnthalpy_pTX;

        redeclare function temperature_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[nX] X;
          output Temperature T;
        algorithm
          T := T0 + h / cp_const;
        end temperature_phX;

        redeclare function extends specificInternalEnergy
          extends Modelica.Icons.Function;
        algorithm
          u := cv_const * (state.T - T0);
        end specificInternalEnergy;

        redeclare function extends specificEntropy
          extends Modelica.Icons.Function;
        algorithm
          s := cv_const * Modelica.Math.log(state.T / T0);
        end specificEntropy;

        redeclare function extends specificGibbsEnergy
          extends Modelica.Icons.Function;
        algorithm
          g := specificEnthalpy(state) - state.T * specificEntropy(state);
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy
          extends Modelica.Icons.Function;
        algorithm
          f := specificInternalEnergy(state) - state.T * specificEntropy(state);
        end specificHelmholtzEnergy;

        redeclare function extends isentropicEnthalpy
        algorithm
          h_is := cp_const * (temperature(refState) - T0);
        end isentropicEnthalpy;

        redeclare function extends isobaricExpansionCoefficient
        algorithm
          beta := 0.0;
        end isobaricExpansionCoefficient;

        redeclare function extends isothermalCompressibility
        algorithm
          kappa := 0;
        end isothermalCompressibility;

        redeclare function extends density_derp_T
        algorithm
          ddpT := 0;
        end density_derp_T;

        redeclare function extends density_derT_p
        algorithm
          ddTp := 0;
        end density_derT_p;

        redeclare function extends density_derX
        algorithm
          dddX := fill(0, nX);
        end density_derX;

        redeclare function extends molarMass
        algorithm
          MM := MM_const;
        end molarMass;
      end PartialSimpleMedium;

      package Choices
        extends Modelica.Icons.Package;
        type IndependentVariables = enumeration(T, pT, ph, phX, pTX, dTX);
        type ReferenceEnthalpy = enumeration(ZeroAt0K, ZeroAt25C, UserDefined);
      end Choices;

      package Types
        extends Modelica.Icons.Package;
        type AbsolutePressure = .Modelica.SIunits.AbsolutePressure(min = 0, max = 1.e8, nominal = 1.e5, start = 1.e5);
        type Density = .Modelica.SIunits.Density(min = 0, max = 1.e5, nominal = 1, start = 1);
        type DynamicViscosity = .Modelica.SIunits.DynamicViscosity(min = 0, max = 1.e8, nominal = 1.e-3, start = 1.e-3);
        type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1);
        type MoleFraction = Real(quantity = "MoleFraction", final unit = "mol/mol", min = 0, max = 1, nominal = 0.1);
        type MolarMass = .Modelica.SIunits.MolarMass(min = 0.001, max = 0.25, nominal = 0.032);
        type MolarVolume = .Modelica.SIunits.MolarVolume(min = 1e-6, max = 1.0e6, nominal = 1.0);
        type IsentropicExponent = .Modelica.SIunits.RatioOfSpecificHeatCapacities(min = 1, max = 500000, nominal = 1.2, start = 1.2);
        type SpecificEnergy = .Modelica.SIunits.SpecificEnergy(min = -1.0e8, max = 1.e8, nominal = 1.e6);
        type SpecificInternalEnergy = SpecificEnergy;
        type SpecificEnthalpy = .Modelica.SIunits.SpecificEnthalpy(min = -1.0e10, max = 1.e10, nominal = 1.e6);
        type SpecificEntropy = .Modelica.SIunits.SpecificEntropy(min = -1.e7, max = 1.e7, nominal = 1.e3);
        type SpecificHeatCapacity = .Modelica.SIunits.SpecificHeatCapacity(min = 0, max = 1.e7, nominal = 1.e3, start = 1.e3);
        type Temperature = .Modelica.SIunits.Temperature(min = 1, max = 1.e4, nominal = 300, start = 300);
        type ThermalConductivity = .Modelica.SIunits.ThermalConductivity(min = 0, max = 500, nominal = 1, start = 1);
        type VelocityOfSound = .Modelica.SIunits.Velocity(min = 0, max = 1.e5, nominal = 1000, start = 1000);
        type ExtraProperty = Real(min = 0.0, start = 1.0);
        type IsobaricExpansionCoefficient = Real(min = 0, max = 1.0e8, unit = "1/K");
        type DipoleMoment = Real(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
        type DerDensityByPressure = .Modelica.SIunits.DerDensityByPressure;
        type DerDensityByEnthalpy = .Modelica.SIunits.DerDensityByEnthalpy;
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

        package TwoPhase
          extends Icons.Package;

          record FluidConstants
            extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
            Temperature criticalTemperature;
            AbsolutePressure criticalPressure;
            MolarVolume criticalMolarVolume;
            Real acentricFactor;
            Temperature triplePointTemperature;
            AbsolutePressure triplePointPressure;
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
        end TwoPhase;
      end Types;
    end Interfaces;

    package Common
      extends Modelica.Icons.Package;
      constant Real MINPOS = 1.0e-9;

      function smoothStep
        extends Modelica.Icons.Function;
        input Real x;
        input Real y1;
        input Real y2;
        input Real x_small(min = 0) = 1e-5;
        output Real y;
      algorithm
        y := smooth(1, if x > x_small then y1 else if x < (-x_small) then y2 else if abs(x_small) > 0 then x / x_small * ((x / x_small) ^ 2 - 3) * (y2 - y1) / 4 + (y1 + y2) / 2 else (y1 + y2) / 2);
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
          constant Real x_eps = 1e-10;
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

    package Air
      extends Modelica.Icons.VariantsPackage;

      package MoistAir
        extends .Modelica.Media.Interfaces.PartialCondensingGases(mediumName = "Moist air", substanceNames = {"water", "air"}, final reducedX = true, final singleState = false, reference_X = {0.01, 0.99}, fluidConstants = {IdealGases.Common.FluidData.H2O, IdealGases.Common.FluidData.N2}, Temperature(min = 190, max = 647));
        constant Integer Water = 1;
        constant Integer Air = 2;
        constant Real k_mair = steam.MM / dryair.MM;
        constant IdealGases.Common.DataRecord dryair = IdealGases.Common.SingleGasesData.Air;
        constant IdealGases.Common.DataRecord steam = IdealGases.Common.SingleGasesData.H2O;
        constant .Modelica.SIunits.MolarMass[2] MMX = {steam.MM, dryair.MM};

        redeclare record extends ThermodynamicState  end ThermodynamicState;

        redeclare replaceable model extends BaseProperties
          MassFraction x_water;
          Real phi;
        protected
          MassFraction X_liquid;
          MassFraction X_steam;
          MassFraction X_air;
          MassFraction X_sat;
          MassFraction x_sat;
          AbsolutePressure p_steam_sat;
        equation
          assert(T >= 190 and T <= 647, "
          Temperature T is not in the allowed range
          190.0 K <= (T =" + String(T) + " K) <= 647.0 K
          required from medium model \"" + mediumName + "\".");
          MM = 1 / (Xi[Water] / MMX[Water] + (1.0 - Xi[Water]) / MMX[Air]);
          p_steam_sat = min(saturationPressure(T), 0.999 * p);
          X_sat = min(p_steam_sat * k_mair / max(100 * .Modelica.Constants.eps, p - p_steam_sat) * (1 - Xi[Water]), 1.0);
          X_liquid = max(Xi[Water] - X_sat, 0.0);
          X_steam = Xi[Water] - X_liquid;
          X_air = 1 - Xi[Water];
          h = specificEnthalpy_pTX(p, T, Xi);
          R = dryair.R * (X_air / (1 - X_liquid)) + steam.R * X_steam / (1 - X_liquid);
          u = h - R * T;
          d = p / (R * T);
          state.p = p;
          state.T = T;
          state.X = X;
          x_sat = k_mair * p_steam_sat / max(100 * .Modelica.Constants.eps, p - p_steam_sat);
          x_water = Xi[Water] / max(X_air, 100 * .Modelica.Constants.eps);
          phi = p / p_steam_sat * Xi[Water] / (Xi[Water] + k_mair * X_air);
        end BaseProperties;

        redeclare function setState_pTX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T, X = X) else ThermodynamicState(p = p, T = T, X = cat(1, X, {1 - sum(X)}));
        end setState_pTX;

        redeclare function setState_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T_phX(p, h, X), X = X) else ThermodynamicState(p = p, T = T_phX(p, h, X), X = cat(1, X, {1 - sum(X)}));
        end setState_phX;

        redeclare function setState_dTX
          extends Modelica.Icons.Function;
          input Density d;
          input Temperature T;
          input MassFraction[:] X = reference_X;
          output ThermodynamicState state;
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = d * ({steam.R, dryair.R} * X) * T, T = T, X = X) else ThermodynamicState(p = d * ({steam.R, dryair.R} * cat(1, X, {1 - sum(X)})) * T, T = T, X = cat(1, X, {1 - sum(X)}));
        end setState_dTX;

        redeclare function extends setSmoothState
        algorithm
          state := ThermodynamicState(p = Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), T = Media.Common.smoothStep(x, state_a.T, state_b.T, x_small), X = Media.Common.smoothStep(x, state_a.X, state_b.X, x_small));
        end setSmoothState;

        redeclare function extends gasConstant
        algorithm
          R := dryair.R * (1 - state.X[Water]) + steam.R * state.X[Water];
        end gasConstant;

        function saturationPressureLiquid
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat;
          output .Modelica.SIunits.AbsolutePressure psat;
        protected
          .Modelica.SIunits.Temperature Tcritical = 647.096;
          .Modelica.SIunits.AbsolutePressure pcritical = 22.064e6;
          Real r1 = 1 - Tsat / Tcritical;
          Real[:] a = {-7.85951783, 1.84408259, -11.7866497, 22.6807411, -15.9618719, 1.80122502};
          Real[:] n = {1.0, 1.5, 3.0, 3.5, 4.0, 7.5};
        algorithm
          psat := exp((a[1] * r1 ^ n[1] + a[2] * r1 ^ n[2] + a[3] * r1 ^ n[3] + a[4] * r1 ^ n[4] + a[5] * r1 ^ n[5] + a[6] * r1 ^ n[6]) * Tcritical / Tsat) * pcritical;
        end saturationPressureLiquid;

        function saturationPressureLiquid_der
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat;
          input Real dTsat(unit = "K/s");
          output Real psat_der(unit = "Pa/s");
        protected
          .Modelica.SIunits.Temperature Tcritical = 647.096;
          .Modelica.SIunits.AbsolutePressure pcritical = 22.064e6;
          Real r1 = 1 - Tsat / Tcritical;
          Real r1_der = -1 / Tcritical * dTsat;
          Real[:] a = {-7.85951783, 1.84408259, -11.7866497, 22.6807411, -15.9618719, 1.80122502};
          Real[:] n = {1.0, 1.5, 3.0, 3.5, 4.0, 7.5};
          Real r2 = a[1] * r1 ^ n[1] + a[2] * r1 ^ n[2] + a[3] * r1 ^ n[3] + a[4] * r1 ^ n[4] + a[5] * r1 ^ n[5] + a[6] * r1 ^ n[6];
        algorithm
          psat_der := exp(r2 * Tcritical / Tsat) * pcritical * ((a[1] * (r1 ^ (n[1] - 1) * n[1] * r1_der) + a[2] * (r1 ^ (n[2] - 1) * n[2] * r1_der) + a[3] * (r1 ^ (n[3] - 1) * n[3] * r1_der) + a[4] * (r1 ^ (n[4] - 1) * n[4] * r1_der) + a[5] * (r1 ^ (n[5] - 1) * n[5] * r1_der) + a[6] * (r1 ^ (n[6] - 1) * n[6] * r1_der)) * Tcritical / Tsat - r2 * Tcritical * dTsat / Tsat ^ 2);
        end saturationPressureLiquid_der;

        function sublimationPressureIce
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat;
          output .Modelica.SIunits.AbsolutePressure psat;
        protected
          .Modelica.SIunits.Temperature Ttriple = 273.16;
          .Modelica.SIunits.AbsolutePressure ptriple = 611.657;
          Real r1 = Tsat / Ttriple;
          Real[:] a = {-13.9281690, 34.7078238};
          Real[:] n = {-1.5, -1.25};
        algorithm
          psat := exp(a[1] - a[1] * r1 ^ n[1] + a[2] - a[2] * r1 ^ n[2]) * ptriple;
        end sublimationPressureIce;

        function sublimationPressureIce_der
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat;
          input Real dTsat(unit = "K/s");
          output Real psat_der(unit = "Pa/s");
        protected
          .Modelica.SIunits.Temperature Ttriple = 273.16;
          .Modelica.SIunits.AbsolutePressure ptriple = 611.657;
          Real r1 = Tsat / Ttriple;
          Real r1_der = dTsat / Ttriple;
          Real[:] a = {-13.9281690, 34.7078238};
          Real[:] n = {-1.5, -1.25};
        algorithm
          psat_der := exp(a[1] - a[1] * r1 ^ n[1] + a[2] - a[2] * r1 ^ n[2]) * ptriple * ((-a[1] * (r1 ^ (n[1] - 1) * n[1] * r1_der)) - a[2] * (r1 ^ (n[2] - 1) * n[2] * r1_der));
        end sublimationPressureIce_der;

        redeclare function extends saturationPressure
        algorithm
          psat := Utilities.spliceFunction(saturationPressureLiquid(Tsat), sublimationPressureIce(Tsat), Tsat - 273.16, 1.0);
        end saturationPressure;

        function saturationPressure_der
          extends Modelica.Icons.Function;
          input Temperature Tsat;
          input Real dTsat(unit = "K/s");
          output Real psat_der(unit = "Pa/s");
        algorithm
          psat_der := Utilities.spliceFunction_der(saturationPressureLiquid(Tsat), sublimationPressureIce(Tsat), Tsat - 273.16, 1.0, saturationPressureLiquid_der(Tsat = Tsat, dTsat = dTsat), sublimationPressureIce_der(Tsat = Tsat, dTsat = dTsat), dTsat, 0);
        end saturationPressure_der;

        redeclare function extends enthalpyOfVaporization
        protected
          Real Tcritical = 647.096;
          Real dcritical = 322;
          Real pcritical = 22.064e6;
          Real[:] n = {1, 1.5, 3, 3.5, 4, 7.5};
          Real[:] a = {-7.85951783, 1.84408259, -11.7866497, 22.6807411, -15.9618719, 1.80122502};
          Real[:] m = {1 / 3, 2 / 3, 5 / 3, 16 / 3, 43 / 3, 110 / 3};
          Real[:] b = {1.99274064, 1.09965342, -0.510839303, -1.75493479, -45.5170352, -6.74694450e5};
          Real[:] o = {2 / 6, 4 / 6, 8 / 6, 18 / 6, 37 / 6, 71 / 6};
          Real[:] c = {-2.03150240, -2.68302940, -5.38626492, -17.2991605, -44.7586581, -63.9201063};
          Real tau = 1 - T / Tcritical;
          Real r1 = a[1] * Tcritical * tau ^ n[1] / T + a[2] * Tcritical * tau ^ n[2] / T + a[3] * Tcritical * tau ^ n[3] / T + a[4] * Tcritical * tau ^ n[4] / T + a[5] * Tcritical * tau ^ n[5] / T + a[6] * Tcritical * tau ^ n[6] / T;
          Real r2 = a[1] * n[1] * tau ^ n[1] + a[2] * n[2] * tau ^ n[2] + a[3] * n[3] * tau ^ n[3] + a[4] * n[4] * tau ^ n[4] + a[5] * n[5] * tau ^ n[5] + a[6] * n[6] * tau ^ n[6];
          Real dp = dcritical * (1 + b[1] * tau ^ m[1] + b[2] * tau ^ m[2] + b[3] * tau ^ m[3] + b[4] * tau ^ m[4] + b[5] * tau ^ m[5] + b[6] * tau ^ m[6]);
          Real dpp = dcritical * exp(c[1] * tau ^ o[1] + c[2] * tau ^ o[2] + c[3] * tau ^ o[3] + c[4] * tau ^ o[4] + c[5] * tau ^ o[5] + c[6] * tau ^ o[6]);
        algorithm
          r0 := -(dp - dpp) * exp(r1) * pcritical * (r2 + r1 * tau) / (dp * dpp * tau);
        end enthalpyOfVaporization;

        redeclare function extends enthalpyOfLiquid
        algorithm
          h := (T - 273.15) * 1e3 * (4.2166 - 0.5 * (T - 273.15) * (0.0033166 + 0.333333 * (T - 273.15) * (0.00010295 - 0.25 * (T - 273.15) * (1.3819e-6 + 0.2 * (T - 273.15) * 7.3221e-9))));
        end enthalpyOfLiquid;

        redeclare function extends enthalpyOfGas
        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5) * X[Water] + Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684) * (1.0 - X[Water]);
        end enthalpyOfGas;

        redeclare function extends enthalpyOfCondensingGas
        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5);
        end enthalpyOfCondensingGas;

        redeclare function extends enthalpyOfNonCondensingGas
        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684);
        end enthalpyOfNonCondensingGas;

        function enthalpyOfWater
          extends Modelica.Icons.Function;
          input SIunits.Temperature T;
          output SIunits.SpecificEnthalpy h;
        algorithm
          h := Utilities.spliceFunction(4200 * (T - 273.15), 2050 * (T - 273.15) - 333000, T - 273.16, 0.1);
        end enthalpyOfWater;

        function enthalpyOfWater_der
          extends Modelica.Icons.Function;
          input SIunits.Temperature T;
          input Real dT(unit = "K/s");
          output Real dh(unit = "J/(kg.s)");
        algorithm
          dh := Utilities.spliceFunction_der(4200 * (T - 273.15), 2050 * (T - 273.15) - 333000, T - 273.16, 0.1, 4200 * dT, 2050 * dT, dT, 0);
        end enthalpyOfWater_der;

        redeclare function extends pressure
        algorithm
          p := state.p;
        end pressure;

        redeclare function extends temperature
        algorithm
          T := state.T;
        end temperature;

        function T_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X;
          output Temperature T;

        protected
          package Internal
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data
              extends Modelica.Media.IdealGases.Common.DataRecord;
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear
            algorithm
              y := h_pTX(p, x, X);
            end f_nonlinear;

            redeclare function extends solve  end solve;
          end Internal;
        algorithm
          T := Internal.solve(h, 190, 647, p, X[1:nXi], steam);
        end T_phX;

        redeclare function extends density
        algorithm
          d := state.p / (gasConstant(state) * state.T);
        end density;

        redeclare function extends specificEnthalpy
        algorithm
          h := h_pTX(state.p, state.T, state.X);
        end specificEnthalpy;

        function h_pTX
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[:] X;
          output .Modelica.SIunits.SpecificEnthalpy h;
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction X_sat;
          .Modelica.SIunits.MassFraction X_liquid;
          .Modelica.SIunits.MassFraction X_steam;
          .Modelica.SIunits.MassFraction X_air;
        algorithm
          p_steam_sat := saturationPressure(T);
          X_sat := min(p_steam_sat * k_mair / max(100 * .Modelica.Constants.eps, p - p_steam_sat) * (1 - X[Water]), 1.0);
          X_liquid := max(X[Water] - X_sat, 0.0);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          h := {Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5), Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684)} * {X_steam, X_air} + enthalpyOfWater(T) * X_liquid;
        end h_pTX;

        function h_pTX_der
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[:] X;
          input Real dp(unit = "Pa/s");
          input Real dT(unit = "K/s");
          input Real[:] dX(each unit = "1/s");
          output Real h_der(unit = "J/(kg.s)");
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction X_sat;
          .Modelica.SIunits.MassFraction X_liquid;
          .Modelica.SIunits.MassFraction X_steam;
          .Modelica.SIunits.MassFraction X_air;
          .Modelica.SIunits.MassFraction x_sat;
          Real dX_steam(unit = "1/s");
          Real dX_air(unit = "1/s");
          Real dX_liq(unit = "1/s");
          Real dps(unit = "Pa/s");
          Real dx_sat(unit = "1/s");
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := p_steam_sat * k_mair / max(100 * Modelica.Constants.eps, p - p_steam_sat);
          X_sat := min(x_sat * (1 - X[Water]), 1.0);
          X_liquid := Utilities.smoothMax(X[Water] - X_sat, 0.0, 1e-5);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          dX_air := -dX[Water];
          dps := saturationPressure_der(Tsat = T, dTsat = dT);
          dx_sat := k_mair * (dps * (p - p_steam_sat) - p_steam_sat * (dp - dps)) / (p - p_steam_sat) / (p - p_steam_sat);
          dX_liq := Utilities.smoothMax_der(X[Water] - X_sat, 0.0, 1e-5, (1 + x_sat) * dX[Water] - (1 - X[Water]) * dx_sat, 0, 0);
          dX_steam := dX[Water] - dX_liq;
          h_der := X_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5, dT = dT) + dX_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5) + X_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684, dT = dT) + dX_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684) + X_liquid * enthalpyOfWater_der(T = T, dT = dT) + dX_liq * enthalpyOfWater(T);
        end h_pTX_der;

        redeclare function extends isentropicExponent
        algorithm
          gamma := specificHeatCapacityCp(state) / specificHeatCapacityCv(state);
        end isentropicExponent;

        redeclare function extends specificInternalEnergy
          extends Modelica.Icons.Function;
          output .Modelica.SIunits.SpecificInternalEnergy u;
        algorithm
          u := specificInternalEnergy_pTX(state.p, state.T, state.X);
        end specificInternalEnergy;

        function specificInternalEnergy_pTX
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[:] X;
          output .Modelica.SIunits.SpecificInternalEnergy u;
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction X_liquid;
          .Modelica.SIunits.MassFraction X_steam;
          .Modelica.SIunits.MassFraction X_air;
          .Modelica.SIunits.MassFraction X_sat;
          Real R_gas;
        algorithm
          p_steam_sat := saturationPressure(T);
          X_sat := min(p_steam_sat * k_mair / max(100 * .Modelica.Constants.eps, p - p_steam_sat) * (1 - X[Water]), 1.0);
          X_liquid := max(X[Water] - X_sat, 0.0);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          R_gas := dryair.R * X_air / (1 - X_liquid) + steam.R * X_steam / (1 - X_liquid);
          u := X_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5) + X_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684) + enthalpyOfWater(T) * X_liquid - R_gas * T;
        end specificInternalEnergy_pTX;

        function specificInternalEnergy_pTX_der
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[:] X;
          input Real dp(unit = "Pa/s");
          input Real dT(unit = "K/s");
          input Real[:] dX(each unit = "1/s");
          output Real u_der(unit = "J/(kg.s)");
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction X_liquid;
          .Modelica.SIunits.MassFraction X_steam;
          .Modelica.SIunits.MassFraction X_air;
          .Modelica.SIunits.MassFraction X_sat;
          .Modelica.SIunits.SpecificHeatCapacity R_gas;
          .Modelica.SIunits.MassFraction x_sat;
          Real dX_steam(unit = "1/s");
          Real dX_air(unit = "1/s");
          Real dX_liq(unit = "1/s");
          Real dps(unit = "Pa/s");
          Real dx_sat(unit = "1/s");
          Real dR_gas(unit = "J/(kg.K.s)");
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := p_steam_sat * k_mair / max(100 * Modelica.Constants.eps, p - p_steam_sat);
          X_sat := min(x_sat * (1 - X[Water]), 1.0);
          X_liquid := Utilities.spliceFunction(X[Water] - X_sat, 0.0, X[Water] - X_sat, 1e-6);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          R_gas := steam.R * X_steam / (1 - X_liquid) + dryair.R * X_air / (1 - X_liquid);
          dX_air := -dX[Water];
          dps := saturationPressure_der(Tsat = T, dTsat = dT);
          dx_sat := k_mair * (dps * (p - p_steam_sat) - p_steam_sat * (dp - dps)) / (p - p_steam_sat) / (p - p_steam_sat);
          dX_liq := Utilities.spliceFunction_der(X[Water] - X_sat, 0.0, X[Water] - X_sat, 1e-6, (1 + x_sat) * dX[Water] - (1 - X[Water]) * dx_sat, 0.0, (1 + x_sat) * dX[Water] - (1 - X[Water]) * dx_sat, 0.0);
          dX_steam := dX[Water] - dX_liq;
          dR_gas := (steam.R * (dX_steam * (1 - X_liquid) + dX_liq * X_steam) + dryair.R * (dX_air * (1 - X_liquid) + dX_liq * X_air)) / (1 - X_liquid) / (1 - X_liquid);
          u_der := X_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5, dT = dT) + dX_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5) + X_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684, dT = dT) + dX_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684) + X_liquid * enthalpyOfWater_der(T = T, dT = dT) + dX_liq * enthalpyOfWater(T) - dR_gas * T - R_gas * dT;
        end specificInternalEnergy_pTX_der;

        redeclare function extends specificEntropy
        algorithm
          s := s_pTX(state.p, state.T, state.X);
        end specificEntropy;

        redeclare function extends specificGibbsEnergy
          extends Modelica.Icons.Function;
        algorithm
          g := h_pTX(state.p, state.T, state.X) - state.T * specificEntropy(state);
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy
          extends Modelica.Icons.Function;
        algorithm
          f := h_pTX(state.p, state.T, state.X) - gasConstant(state) * state.T - state.T * specificEntropy(state);
        end specificHelmholtzEnergy;

        redeclare function extends specificHeatCapacityCp
        protected
          Real dT(unit = "s/K") = 1.0;
        algorithm
          cp := h_pTX_der(state.p, state.T, state.X, 0.0, 1.0, zeros(size(state.X, 1))) * dT;
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv
        algorithm
          cv := Modelica.Media.IdealGases.Common.Functions.cp_Tlow(dryair, state.T) * (1 - state.X[Water]) + Modelica.Media.IdealGases.Common.Functions.cp_Tlow(steam, state.T) * state.X[Water] - gasConstant(state);
        end specificHeatCapacityCv;

        redeclare function extends dynamicViscosity
        algorithm
          eta := 1e-6 * .Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluateWithRange({9.7391102886305869E-15, -3.1353724870333906E-11, 4.3004876595642225E-08, -3.8228016291758240E-05, 5.0427874367180762E-02, 1.7239260139242528E+01}, .Modelica.SIunits.Conversions.to_degC(123.15), .Modelica.SIunits.Conversions.to_degC(1273.15), .Modelica.SIunits.Conversions.to_degC(state.T));
        end dynamicViscosity;

        redeclare function extends thermalConductivity
        algorithm
          lambda := 1e-3 * .Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluateWithRange({6.5691470817717812E-15, -3.4025961923050509E-11, 5.3279284846303157E-08, -4.5340839289219472E-05, 7.6129675309037664E-02, 2.4169481088097051E+01}, .Modelica.SIunits.Conversions.to_degC(123.15), .Modelica.SIunits.Conversions.to_degC(1273.15), .Modelica.SIunits.Conversions.to_degC(state.T));
        end thermalConductivity;

        package Utilities
          extends Modelica.Icons.UtilitiesPackage;

          function spliceFunction
            extends Modelica.Icons.Function;
            input Real pos;
            input Real neg;
            input Real x;
            input Real deltax = 1;
            output Real out;
          protected
            Real scaledX;
            Real scaledX1;
            Real y;
          algorithm
            scaledX1 := x / deltax;
            scaledX := scaledX1 * Modelica.Math.asin(1);
            if scaledX1 <= (-0.999999999) then
              y := 0;
            elseif scaledX1 >= 0.999999999 then
              y := 1;
            else
              y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX)) + 1) / 2;
            end if;
            out := pos * y + (1 - y) * neg;
          end spliceFunction;

          function spliceFunction_der
            extends Modelica.Icons.Function;
            input Real pos;
            input Real neg;
            input Real x;
            input Real deltax = 1;
            input Real dpos;
            input Real dneg;
            input Real dx;
            input Real ddeltax = 0;
            output Real out;
          protected
            Real scaledX;
            Real scaledX1;
            Real dscaledX1;
            Real y;
          algorithm
            scaledX1 := x / deltax;
            scaledX := scaledX1 * Modelica.Math.asin(1);
            dscaledX1 := (dx - scaledX1 * ddeltax) / deltax;
            if scaledX1 <= (-0.99999999999) then
              y := 0;
            elseif scaledX1 >= 0.9999999999 then
              y := 1;
            else
              y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX)) + 1) / 2;
            end if;
            out := dpos * y + (1 - y) * dneg;
            if abs(scaledX1) < 1 then
              out := out + (pos - neg) * dscaledX1 * Modelica.Math.asin(1) / 2 / (Modelica.Math.cosh(Modelica.Math.tan(scaledX)) * Modelica.Math.cos(scaledX)) ^ 2;
            else
            end if;
          end spliceFunction_der;

          function smoothMax
            extends Modelica.Icons.Function;
            input Real x1;
            input Real x2;
            input Real dx;
            output Real y;
          algorithm
            y := max(x1, x2) + .Modelica.Math.log(exp(4 / dx * (x1 - max(x1, x2))) + exp(4 / dx * (x2 - max(x1, x2)))) / (4 / dx);
          end smoothMax;

          function smoothMax_der
            extends Modelica.Icons.Function;
            input Real x1;
            input Real x2;
            input Real dx;
            input Real dx1;
            input Real dx2;
            input Real ddx;
            output Real dy;
          algorithm
            dy := (if x1 > x2 then dx1 else dx2) + 0.25 * (((4 * (dx1 - (if x1 > x2 then dx1 else dx2)) / dx - 4 * (x1 - max(x1, x2)) * ddx / dx ^ 2) * .Modelica.Math.exp(4 * (x1 - max(x1, x2)) / dx) + (4 * (dx2 - (if x1 > x2 then dx1 else dx2)) / dx - 4 * (x2 - max(x1, x2)) * ddx / dx ^ 2) * .Modelica.Math.exp(4 * (x2 - max(x1, x2)) / dx)) * dx / (.Modelica.Math.exp(4 * (x1 - max(x1, x2)) / dx) + .Modelica.Math.exp(4 * (x2 - max(x1, x2)) / dx)) + .Modelica.Math.log(.Modelica.Math.exp(4 * (x1 - max(x1, x2)) / dx) + .Modelica.Math.exp(4 * (x2 - max(x1, x2)) / dx)) * ddx);
          end smoothMax_der;
        end Utilities;

        redeclare function extends velocityOfSound
        algorithm
          a := sqrt(isentropicExponent(state) * gasConstant(state) * temperature(state));
        end velocityOfSound;

        redeclare function extends isobaricExpansionCoefficient
        algorithm
          beta := 1 / temperature(state);
        end isobaricExpansionCoefficient;

        redeclare function extends isothermalCompressibility
        algorithm
          kappa := 1 / pressure(state);
        end isothermalCompressibility;

        redeclare function extends density_derp_h
        algorithm
          ddph := 1 / (gasConstant(state) * temperature(state));
        end density_derp_h;

        redeclare function extends density_derh_p
        algorithm
          ddhp := -density(state) / (specificHeatCapacityCp(state) * temperature(state));
        end density_derh_p;

        redeclare function extends density_derp_T
        algorithm
          ddpT := 1 / (gasConstant(state) * temperature(state));
        end density_derp_T;

        redeclare function extends density_derT_p
        algorithm
          ddTp := -density(state) / temperature(state);
        end density_derT_p;

        redeclare function extends density_derX
        algorithm
          dddX[Water] := pressure(state) * (steam.R - dryair.R) / ((steam.R - dryair.R) * state.X[Water] * temperature(state) + dryair.R * temperature(state)) ^ 2;
          dddX[Air] := pressure(state) * (dryair.R - steam.R) / ((dryair.R - steam.R) * state.X[Air] * temperature(state) + steam.R * temperature(state)) ^ 2;
        end density_derX;

        redeclare function extends molarMass
        algorithm
          MM := Modelica.Media.Air.MoistAir.gasConstant(state) / Modelica.Constants.R;
        end molarMass;

        function T_psX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEntropy s;
          input MassFraction[:] X;
          output Temperature T;

        protected
          package Internal
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data
              extends Modelica.Media.IdealGases.Common.DataRecord;
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear
            algorithm
              y := s_pTX(p, x, X);
            end f_nonlinear;

            redeclare function extends solve  end solve;
          end Internal;
        algorithm
          T := Internal.solve(s, 190, 647, p, X[1:nX], steam);
        end T_psX;

        redeclare function extends setState_psX
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T_psX(p, s, X), X = X) else ThermodynamicState(p = p, T = T_psX(p, s, X), X = cat(1, X, {1 - sum(X)}));
        end setState_psX;

        function s_pTX
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[:] X;
          output .Modelica.SIunits.SpecificEntropy s;
        protected
          MoleFraction[2] Y = massToMoleFractions(X, {steam.MM, dryair.MM});
        algorithm
          s := Modelica.Media.IdealGases.Common.Functions.s0_Tlow(dryair, T) * (1 - X[Water]) + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(steam, T) * X[Water] - Modelica.Constants.R * (Utilities.smoothMax(X[Water] / MMX[Water] * Modelica.Math.log(max(Y[Water], Modelica.Constants.eps) * p / reference_p), 0.0, 1e-9) - Utilities.smoothMax((1 - X[Water]) / MMX[Air] * Modelica.Math.log(max(Y[Air], Modelica.Constants.eps) * p / reference_p), 0.0, 1e-9));
        end s_pTX;

        function s_pTX_der
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[:] X;
          input Real dp(unit = "Pa/s");
          input Real dT(unit = "K/s");
          input Real[nX] dX(unit = "1/s");
          output Real ds(unit = "J/(kg.K.s)");
        protected
          MoleFraction[2] Y = massToMoleFractions(X, {steam.MM, dryair.MM});
        algorithm
          ds := Modelica.Media.IdealGases.Common.Functions.s0_Tlow_der(dryair, T, dT) * (1 - X[Water]) + Modelica.Media.IdealGases.Common.Functions.s0_Tlow_der(steam, T, dT) * X[Water] + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(dryair, T) * dX[Air] + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(steam, T) * dX[Water] - Modelica.Constants.R * (1 / MMX[Water] * Utilities.smoothMax_der(X[Water] * Modelica.Math.log(max(Y[Water], Modelica.Constants.eps) * p / reference_p), 0.0, 1e-9, (Modelica.Math.log(max(Y[Water], Modelica.Constants.eps) * p / reference_p) + X[Water] / Y[Water] * (X[Air] * MMX[Water] / (X[Air] * MMX[Water] + X[Water] * MMX[Air]) ^ 2)) * dX[Water] + X[Water] * reference_p / p * dp, 0, 0) - 1 / MMX[Air] * Utilities.smoothMax_der((1 - X[Water]) * Modelica.Math.log(max(Y[Air], Modelica.Constants.eps) * p / reference_p), 0.0, 1e-9, (Modelica.Math.log(max(Y[Air], Modelica.Constants.eps) * p / reference_p) + X[Air] / Y[Air] * (X[Water] * MMX[Air] / (X[Air] * MMX[Water] + X[Water] * MMX[Air]) ^ 2)) * dX[Air] + X[Air] * reference_p / p * dp, 0, 0));
        end s_pTX_der;

        redeclare function extends isentropicEnthalpy
          extends Modelica.Icons.Function;
        algorithm
          h_is := Modelica.Media.Air.MoistAir.h_pTX(p_downstream, Modelica.Media.Air.MoistAir.T_psX(p_downstream, Modelica.Media.Air.MoistAir.specificEntropy(refState), refState.X), refState.X);
        end isentropicEnthalpy;
      end MoistAir;
    end Air;

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

          function cp_Tlow
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            output .Modelica.SIunits.SpecificHeatCapacity cp;
          algorithm
            cp := data.R * (1 / (T * T) * (data.alow[1] + T * (data.alow[2] + T * (1. * data.alow[3] + T * (data.alow[4] + T * (data.alow[5] + T * (data.alow[6] + data.alow[7] * T)))))));
          end cp_Tlow;

          function cp_Tlow_der
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            input Real dT;
            output Real cp_der;
          algorithm
            cp_der := dT * data.R / (T * T * T) * ((-2 * data.alow[1]) + T * ((-data.alow[2]) + T * T * (data.alow[4] + T * (2. * data.alow[5] + T * (3. * data.alow[6] + 4. * data.alow[7] * T)))));
          end cp_Tlow_der;

          function h_Tlow
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            input Boolean exclEnthForm = excludeEnthalpyOfFormation;
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy refChoice = referenceChoice;
            input .Modelica.SIunits.SpecificEnthalpy h_off = h_offset;
            output .Modelica.SIunits.SpecificEnthalpy h;
          algorithm
            h := data.R * (((-data.alow[1]) + T * (data.blow[1] + data.alow[2] * Math.log(T) + T * (1. * data.alow[3] + T * (0.5 * data.alow[4] + T * (1 / 3 * data.alow[5] + T * (0.25 * data.alow[6] + 0.2 * data.alow[7] * T)))))) / T) + (if exclEnthForm then -data.Hf else 0.0) + (if refChoice == .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K then data.H0 else 0.0) + (if refChoice == .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined then h_off else 0.0);
          end h_Tlow;

          function h_Tlow_der
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            input Boolean exclEnthForm = excludeEnthalpyOfFormation;
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy refChoice = referenceChoice;
            input .Modelica.SIunits.SpecificEnthalpy h_off = h_offset;
            input Real dT(unit = "K/s");
            output Real h_der(unit = "J/(kg.s)");
          algorithm
            h_der := dT * Modelica.Media.IdealGases.Common.Functions.cp_Tlow(data, T);
          end h_Tlow_der;

          function s0_Tlow
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            output .Modelica.SIunits.SpecificEntropy s;
          algorithm
            s := data.R * (data.blow[2] - 0.5 * data.alow[1] / (T * T) - data.alow[2] / T + data.alow[3] * Math.log(T) + T * (data.alow[4] + T * (0.5 * data.alow[5] + T * (1 / 3 * data.alow[6] + 0.25 * data.alow[7] * T))));
          end s0_Tlow;

          function s0_Tlow_der
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data;
            input .Modelica.SIunits.Temperature T;
            input Real T_der;
            output .Modelica.SIunits.SpecificEntropy s;
          algorithm
            s := data.R * (data.blow[2] - 0.5 * data.alow[1] / (T * T) - data.alow[2] / T + data.alow[3] * Math.log(T) + T * (data.alow[4] + T * (0.5 * data.alow[5] + T * (1 / 3 * data.alow[6] + 0.25 * data.alow[7] * T))));
          end s0_Tlow_der;
        end Functions;

        package FluidData
          extends Modelica.Icons.Package;
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants N2(chemicalFormula = "N2", iupacName = "unknown", structureFormula = "unknown", casRegistryNumber = "7727-37-9", meltingPoint = 63.15, normalBoilingPoint = 77.35, criticalTemperature = 126.20, criticalPressure = 33.98e5, criticalMolarVolume = 90.10e-6, acentricFactor = 0.037, dipoleMoment = 0.0, molarMass = SingleGasesData.N2.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants H2O(chemicalFormula = "H2O", iupacName = "oxidane", structureFormula = "H2O", casRegistryNumber = "7732-18-5", meltingPoint = 273.15, normalBoilingPoint = 373.124, criticalTemperature = 647.096, criticalPressure = 220.64e5, criticalMolarVolume = 55.95e-6, acentricFactor = 0.344, dipoleMoment = 1.8, molarMass = SingleGasesData.H2O.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
        end FluidData;

        package SingleGasesData
          extends Modelica.Icons.Package;
          constant IdealGases.Common.DataRecord Air(name = "Air", MM = 0.0289651159, Hf = -4333.833858403446, H0 = 298609.6803431054, Tlimit = 1000, alow = {10099.5016, -196.827561, 5.00915511, -0.00576101373, 1.06685993e-05, -7.94029797e-09, 2.18523191e-012}, blow = {-176.796731, -3.921504225}, ahigh = {241521.443, -1257.8746, 5.14455867, -0.000213854179, 7.06522784e-08, -1.07148349e-011, 6.57780015e-016}, bhigh = {6462.26319, -8.147411905}, R = 287.0512249529787);
          constant IdealGases.Common.DataRecord Ar(name = "Ar", MM = 0.039948, Hf = 0, H0 = 155137.3785921698, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 4.37967491}, ahigh = {20.10538475, -0.05992661069999999, 2.500069401, -3.99214116e-08, 1.20527214e-011, -1.819015576e-015, 1.078576636e-019}, bhigh = {-744.993961, 4.37918011}, R = 208.1323720837088);
          constant IdealGases.Common.DataRecord CH4(name = "CH4", MM = 0.01604246, Hf = -4650159.63885838, H0 = 624355.7409524474, Tlimit = 1000, alow = {-176685.0998, 2786.18102, -12.0257785, 0.0391761929, -3.61905443e-05, 2.026853043e-08, -4.976705489999999e-012}, blow = {-23313.1436, 89.0432275}, ahigh = {3730042.76, -13835.01485, 20.49107091, -0.001961974759, 4.72731304e-07, -3.72881469e-011, 1.623737207e-015}, bhigh = {75320.6691, -121.9124889}, R = 518.2791167938085);
          constant IdealGases.Common.DataRecord CH3OH(name = "CH3OH", MM = 0.03204186, Hf = -6271171.523750494, H0 = 356885.5553329301, Tlimit = 1000, alow = {-241664.2886, 4032.14719, -20.46415436, 0.0690369807, -7.59893269e-05, 4.59820836e-08, -1.158706744e-011}, blow = {-44332.61169999999, 140.014219}, ahigh = {3411570.76, -13455.00201, 22.61407623, -0.002141029179, 3.73005054e-07, -3.49884639e-011, 1.366073444e-015}, bhigh = {56360.8156, -127.7814279}, R = 259.4878075117987);
          constant IdealGases.Common.DataRecord CO(name = "CO", MM = 0.0280101, Hf = -3946262.098314536, H0 = 309570.6191695138, Tlimit = 1000, alow = {14890.45326, -292.2285939, 5.72452717, -0.008176235030000001, 1.456903469e-05, -1.087746302e-08, 3.027941827e-012}, blow = {-13031.31878, -7.85924135}, ahigh = {461919.725, -1944.704863, 5.91671418, -0.0005664282830000001, 1.39881454e-07, -1.787680361e-011, 9.62093557e-016}, bhigh = {-2466.261084, -13.87413108}, R = 296.8383547363272);
          constant IdealGases.Common.DataRecord CO2(name = "CO2", MM = 0.0440095, Hf = -8941478.544405185, H0 = 212805.6215135368, Tlimit = 1000, alow = {49436.5054, -626.411601, 5.30172524, 0.002503813816, -2.127308728e-07, -7.68998878e-010, 2.849677801e-013}, blow = {-45281.9846, -7.04827944}, ahigh = {117696.2419, -1788.791477, 8.29152319, -9.22315678e-05, 4.86367688e-09, -1.891053312e-012, 6.330036589999999e-016}, bhigh = {-39083.5059, -26.52669281}, R = 188.9244822140674);
          constant IdealGases.Common.DataRecord C2H2_vinylidene(name = "C2H2_vinylidene", MM = 0.02603728, Hf = 15930556.80163212, H0 = 417638.4015534649, Tlimit = 1000, alow = {-14660.42239, 278.9475593, 1.276229776, 0.01395015463, -1.475702649e-05, 9.476298110000001e-09, -2.567602217e-012}, blow = {47361.1018, 16.58225704}, ahigh = {1940838.725, -6892.718150000001, 13.39582494, -0.0009368968669999999, 1.470804368e-07, -1.220040365e-011, 4.12239166e-016}, bhigh = {91071.1293, -63.3750293}, R = 319.3295152181795);
          constant IdealGases.Common.DataRecord C2H4(name = "C2H4", MM = 0.02805316, Hf = 1871446.924339362, H0 = 374955.5843263291, Tlimit = 1000, alow = {-116360.5836, 2554.85151, -16.09746428, 0.0662577932, -7.885081859999999e-05, 5.12522482e-08, -1.370340031e-011}, blow = {-6176.19107, 109.3338343}, ahigh = {3408763.67, -13748.47903, 23.65898074, -0.002423804419, 4.43139566e-07, -4.35268339e-011, 1.775410633e-015}, bhigh = {88204.2938, -137.1278108}, R = 296.3827247982046);
          constant IdealGases.Common.DataRecord C2H6(name = "C2H6", MM = 0.03006904, Hf = -2788633.890539904, H0 = 395476.3437741943, Tlimit = 1000, alow = {-186204.4161, 3406.19186, -19.51705092, 0.0756583559, -8.20417322e-05, 5.0611358e-08, -1.319281992e-011}, blow = {-27029.3289, 129.8140496}, ahigh = {5025782.13, -20330.22397, 33.2255293, -0.00383670341, 7.23840586e-07, -7.3191825e-011, 3.065468699e-015}, bhigh = {111596.395, -203.9410584}, R = 276.5127187299628);
          constant IdealGases.Common.DataRecord C2H5OH(name = "C2H5OH", MM = 0.04606844, Hf = -5100020.751733725, H0 = 315659.1801241805, Tlimit = 1000, alow = {-234279.1392, 4479.18055, -27.44817302, 0.1088679162, -0.0001305309334, 8.437346399999999e-08, -2.234559017e-011}, blow = {-50222.29, 176.4829211}, ahigh = {4694817.65, -19297.98213, 34.4758404, -0.00323616598, 5.78494772e-07, -5.56460027e-011, 2.2262264e-015}, bhigh = {86016.22709999999, -203.4801732}, R = 180.4808671619877);
          constant IdealGases.Common.DataRecord C3H6_propylene(name = "C3H6_propylene", MM = 0.04207974, Hf = 475288.1077687267, H0 = 322020.9535515191, Tlimit = 1000, alow = {-191246.2174, 3542.07424, -21.14878626, 0.0890148479, -0.0001001429154, 6.267959389999999e-08, -1.637870781e-011}, blow = {-15299.61824, 140.7641382}, ahigh = {5017620.34, -20860.84035, 36.4415634, -0.00388119117, 7.27867719e-07, -7.321204500000001e-011, 3.052176369e-015}, bhigh = {126124.5355, -219.5715757}, R = 197.588483198803);
          constant IdealGases.Common.DataRecord C3H8(name = "C3H8", MM = 0.04409562, Hf = -2373931.923397381, H0 = 334301.1845620949, Tlimit = 1000, alow = {-243314.4337, 4656.27081, -29.39466091, 0.1188952745, -0.0001376308269, 8.814823909999999e-08, -2.342987994e-011}, blow = {-35403.3527, 184.1749277}, ahigh = {6420731.680000001, -26597.91134, 45.3435684, -0.00502066392, 9.471216939999999e-07, -9.57540523e-011, 4.00967288e-015}, bhigh = {145558.2459, -281.8374734}, R = 188.5555073270316);
          constant IdealGases.Common.DataRecord C4H8_1_butene(name = "C4H8_1_butene", MM = 0.05610631999999999, Hf = -9624.584182316718, H0 = 305134.9651875226, Tlimit = 1000, alow = {-272149.2014, 5100.079250000001, -31.8378625, 0.1317754442, -0.0001527359339, 9.714761109999999e-08, -2.56020447e-011}, blow = {-25230.96386, 200.6932108}, ahigh = {6257948.609999999, -26603.76305, 47.6492005, -0.00438326711, 7.12883844e-07, -5.991020839999999e-011, 2.051753504e-015}, bhigh = {156925.2657, -291.3869761}, R = 148.1913623991023);
          constant IdealGases.Common.DataRecord C4H10_n_butane(name = "C4H10_n_butane", MM = 0.0581222, Hf = -2164233.28779709, H0 = 330832.0228759407, Tlimit = 1000, alow = {-317587.254, 6176.331819999999, -38.9156212, 0.1584654284, -0.0001860050159, 1.199676349e-07, -3.20167055e-011}, blow = {-45403.63390000001, 237.9488665}, ahigh = {7682322.45, -32560.5151, 57.3673275, -0.00619791681, 1.180186048e-06, -1.221893698e-010, 5.250635250000001e-015}, bhigh = {177452.656, -358.791876}, R = 143.0515706563069);
          constant IdealGases.Common.DataRecord C5H10_1_pentene(name = "C5H10_1_pentene", MM = 0.07013290000000001, Hf = -303423.9279995551, H0 = 309127.3852927798, Tlimit = 1000, alow = {-534054.813, 9298.917380000001, -56.6779245, 0.2123100266, -0.000257129829, 1.666834304e-07, -4.43408047e-011}, blow = {-47906.8218, 339.60364}, ahigh = {3744014.97, -21044.85321, 47.3612699, -0.00042442012, -3.89897505e-08, 1.367074243e-011, -9.31319423e-016}, bhigh = {115409.1373, -278.6177449000001}, R = 118.5530899192818);
          constant IdealGases.Common.DataRecord C5H12_n_pentane(name = "C5H12_n_pentane", MM = 0.07214878, Hf = -2034130.029641527, H0 = 335196.2430965569, Tlimit = 1000, alow = {-276889.4625, 5834.28347, -36.1754148, 0.1533339707, -0.0001528395882, 8.191092e-08, -1.792327902e-011}, blow = {-46653.7525, 226.5544053}, ahigh = {-2530779.286, -8972.59326, 45.3622326, -0.002626989916, 3.135136419e-06, -5.31872894e-010, 2.886896868e-014}, bhigh = {14846.16529, -251.6550384}, R = 115.2406457877736);
          constant IdealGases.Common.DataRecord C6H6(name = "C6H6", MM = 0.07811184, Hf = 1061042.730525872, H0 = 181735.4577743912, Tlimit = 1000, alow = {-167734.0902, 4404.50004, -37.1737791, 0.1640509559, -0.0002020812374, 1.307915264e-07, -3.4442841e-011}, blow = {-10354.55401, 216.9853345}, ahigh = {4538575.72, -22605.02547, 46.940073, -0.004206676830000001, 7.90799433e-07, -7.9683021e-011, 3.32821208e-015}, bhigh = {139146.4686, -286.8751333}, R = 106.4431717393932);
          constant IdealGases.Common.DataRecord C6H12_1_hexene(name = "C6H12_1_hexene", MM = 0.08415948000000001, Hf = -498458.4030224521, H0 = 311788.9986962847, Tlimit = 1000, alow = {-666883.165, 11768.64939, -72.70998330000001, 0.2709398396, -0.00033332464, 2.182347097e-07, -5.85946882e-011}, blow = {-62157.8054, 428.682564}, ahigh = {733290.696, -14488.48641, 46.7121549, 0.00317297847, -5.24264652e-07, 4.28035582e-011, -1.472353254e-015}, bhigh = {66977.4041, -262.3643854}, R = 98.79424159940152);
          constant IdealGases.Common.DataRecord C6H14_n_hexane(name = "C6H14_n_hexane", MM = 0.08617535999999999, Hf = -1936980.593988816, H0 = 333065.0431863586, Tlimit = 1000, alow = {-581592.67, 10790.97724, -66.3394703, 0.2523715155, -0.0002904344705, 1.802201514e-07, -4.617223680000001e-011}, blow = {-72715.4457, 393.828354}, ahigh = {-3106625.684, -7346.087920000001, 46.94131760000001, 0.001693963977, 2.068996667e-06, -4.21214168e-010, 2.452345845e-014}, bhigh = {523.750312, -254.9967718}, R = 96.48317105956971);
          constant IdealGases.Common.DataRecord C7H14_1_heptene(name = "C7H14_1_heptene", MM = 0.09818605999999999, Hf = -639194.6066478277, H0 = 313588.3036756949, Tlimit = 1000, alow = {-744940.284, 13321.79893, -82.81694379999999, 0.3108065994, -0.000378677992, 2.446841042e-07, -6.488763869999999e-011}, blow = {-72178.8501, 485.667149}, ahigh = {-1927608.174, -9125.024420000002, 47.4817797, 0.00606766053, -8.684859080000001e-07, 5.81399526e-011, -1.473979569e-015}, bhigh = {26009.14656, -256.2880707}, R = 84.68077851377274);
          constant IdealGases.Common.DataRecord C7H16_n_heptane(name = "C7H16_n_heptane", MM = 0.10020194, Hf = -1874015.612871368, H0 = 331540.487140269, Tlimit = 1000, alow = {-612743.289, 11840.85437, -74.87188599999999, 0.2918466052, -0.000341679549, 2.159285269e-07, -5.65585273e-011}, blow = {-80134.0894, 440.721332}, ahigh = {9135632.469999999, -39233.1969, 78.8978085, -0.00465425193, 2.071774142e-06, -3.4425393e-010, 1.976834775e-014}, bhigh = {205070.8295, -485.110402}, R = 82.97715593131233);
          constant IdealGases.Common.DataRecord C8H10_ethylbenz(name = "C8H10_ethylbenz", MM = 0.106165, Hf = 281825.4603682946, H0 = 209862.0072528611, Tlimit = 1000, alow = {-469494, 9307.16836, -65.2176947, 0.2612080237, -0.000318175348, 2.051355473e-07, -5.40181735e-011}, blow = {-40738.7021, 378.090436}, ahigh = {5551564.100000001, -28313.80598, 60.6124072, 0.001042112857, -1.327426719e-06, 2.166031743e-010, -1.142545514e-014}, bhigh = {164224.1062, -369.176982}, R = 78.31650732350586);
          constant IdealGases.Common.DataRecord C8H18_n_octane(name = "C8H18_n_octane", MM = 0.11422852, Hf = -1827477.060895125, H0 = 330740.51909278, Tlimit = 1000, alow = {-698664.715, 13385.01096, -84.1516592, 0.327193666, -0.000377720959, 2.339836988e-07, -6.01089265e-011}, blow = {-90262.2325, 493.922214}, ahigh = {6365406.949999999, -31053.64657, 69.6916234, 0.01048059637, -4.12962195e-06, 5.543226319999999e-010, -2.651436499e-014}, bhigh = {150096.8785, -416.989565}, R = 72.78805678301707);
          constant IdealGases.Common.DataRecord CL2(name = "CL2", MM = 0.07090600000000001, Hf = 0, H0 = 129482.8364313316, Tlimit = 1000, alow = {34628.1517, -554.7126520000001, 6.20758937, -0.002989632078, 3.17302729e-06, -1.793629562e-09, 4.260043590000001e-013}, blow = {1534.069331, -9.438331107}, ahigh = {6092569.42, -19496.27662, 28.54535795, -0.01449968764, 4.46389077e-06, -6.35852586e-010, 3.32736029e-014}, bhigh = {121211.7724, -169.0778824}, R = 117.2604857134798);
          constant IdealGases.Common.DataRecord F2(name = "F2", MM = 0.0379968064, Hf = 0, H0 = 232259.1511269747, Tlimit = 1000, alow = {10181.76308, 22.74241183, 1.97135304, 0.008151604010000001, -1.14896009e-05, 7.95865253e-09, -2.167079526e-012}, blow = {-958.6943, 11.30600296}, ahigh = {-2941167.79, 9456.5977, -7.73861615, 0.00764471299, -2.241007605e-06, 2.915845236e-010, -1.425033974e-014}, bhigh = {-60710.0561, 84.23835080000001}, R = 218.8202848542556);
          constant IdealGases.Common.DataRecord H2(name = "H2", MM = 0.00201588, Hf = 0, H0 = 4200697.462150524, Tlimit = 1000, alow = {40783.2321, -800.918604, 8.21470201, -0.01269714457, 1.753605076e-05, -1.20286027e-08, 3.36809349e-012}, blow = {2682.484665, -30.43788844}, ahigh = {560812.801, -837.150474, 2.975364532, 0.001252249124, -3.74071619e-07, 5.936625200000001e-011, -3.6069941e-015}, bhigh = {5339.82441, -2.202774769}, R = 4124.487568704486);
          constant IdealGases.Common.DataRecord H2O(name = "H2O", MM = 0.01801528, Hf = -13423382.81725291, H0 = 549760.6476280135, Tlimit = 1000, alow = {-39479.6083, 575.573102, 0.931782653, 0.00722271286, -7.34255737e-06, 4.95504349e-09, -1.336933246e-012}, blow = {-33039.7431, 17.24205775}, ahigh = {1034972.096, -2412.698562, 4.64611078, 0.002291998307, -6.836830479999999e-07, 9.426468930000001e-011, -4.82238053e-015}, bhigh = {-13842.86509, -7.97814851}, R = 461.5233290850878);
          constant IdealGases.Common.DataRecord He(name = "He", MM = 0.004002602, Hf = 0, H0 = 1548349.798456104, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 0.9287239740000001}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, 0.9287239740000001}, R = 2077.26673798694);
          constant IdealGases.Common.DataRecord NH3(name = "NH3", MM = 0.01703052, Hf = -2697510.117130892, H0 = 589713.1150428759, Tlimit = 1000, alow = {-76812.26149999999, 1270.951578, -3.89322913, 0.02145988418, -2.183766703e-05, 1.317385706e-08, -3.33232206e-012}, blow = {-12648.86413, 43.66014588}, ahigh = {2452389.535, -8040.89424, 12.71346201, -0.000398018658, 3.55250275e-08, 2.53092357e-012, -3.32270053e-016}, bhigh = {43861.91959999999, -64.62330602}, R = 488.2101075011215);
          constant IdealGases.Common.DataRecord NO(name = "NO", MM = 0.0300061, Hf = 3041758.509103149, H0 = 305908.1320131574, Tlimit = 1000, alow = {-11439.16503, 153.6467592, 3.43146873, -0.002668592368, 8.48139912e-06, -7.685111050000001e-09, 2.386797655e-012}, blow = {9098.214410000001, 6.72872549}, ahigh = {223901.8716, -1289.651623, 5.43393603, -0.00036560349, 9.880966450000001e-08, -1.416076856e-011, 9.380184619999999e-016}, bhigh = {17503.17656, -8.50166909}, R = 277.0927244793559);
          constant IdealGases.Common.DataRecord NO2(name = "NO2", MM = 0.0460055, Hf = 743237.6346306421, H0 = 221890.3174620426, Tlimit = 1000, alow = {-56420.3878, 963.308572, -2.434510974, 0.01927760886, -1.874559328e-05, 9.145497730000001e-09, -1.777647635e-012}, blow = {-1547.925037, 40.6785121}, ahigh = {721300.157, -3832.6152, 11.13963285, -0.002238062246, 6.54772343e-07, -7.6113359e-011, 3.32836105e-015}, bhigh = {25024.97403, -43.0513004}, R = 180.7277825477389);
          constant IdealGases.Common.DataRecord N2(name = "N2", MM = 0.0280134, Hf = 0, H0 = 309498.4543111511, Tlimit = 1000, alow = {22103.71497, -381.846182, 6.08273836, -0.00853091441, 1.384646189e-05, -9.62579362e-09, 2.519705809e-012}, blow = {710.846086, -10.76003744}, ahigh = {587712.406, -2239.249073, 6.06694922, -0.00061396855, 1.491806679e-07, -1.923105485e-011, 1.061954386e-015}, bhigh = {12832.10415, -15.86640027}, R = 296.8033869505308);
          constant IdealGases.Common.DataRecord N2O(name = "N2O", MM = 0.0440128, Hf = 1854006.107314236, H0 = 217685.1961247637, Tlimit = 1000, alow = {42882.2597, -644.011844, 6.03435143, 0.0002265394436, 3.47278285e-06, -3.62774864e-09, 1.137969552e-012}, blow = {11794.05506, -10.0312857}, ahigh = {343844.804, -2404.557558, 9.125636220000001, -0.000540166793, 1.315124031e-07, -1.4142151e-011, 6.38106687e-016}, bhigh = {21986.32638, -31.47805016}, R = 188.9103169986913);
          constant IdealGases.Common.DataRecord Ne(name = "Ne", MM = 0.0201797, Hf = 0, H0 = 307111.9986917546, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 3.35532272}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, 3.35532272}, R = 412.0215860493466);
          constant IdealGases.Common.DataRecord O2(name = "O2", MM = 0.0319988, Hf = 0, H0 = 271263.4223783392, Tlimit = 1000, alow = {-34255.6342, 484.700097, 1.119010961, 0.00429388924, -6.83630052e-07, -2.0233727e-09, 1.039040018e-012}, blow = {-3391.45487, 18.4969947}, ahigh = {-1037939.022, 2344.830282, 1.819732036, 0.001267847582, -2.188067988e-07, 2.053719572e-011, -8.193467050000001e-016}, bhigh = {-16890.10929, 17.38716506}, R = 259.8369938872708);
          constant IdealGases.Common.DataRecord SO2(name = "SO2", MM = 0.0640638, Hf = -4633037.690552231, H0 = 164650.3485587805, Tlimit = 1000, alow = {-53108.4214, 909.031167, -2.356891244, 0.02204449885, -2.510781471e-05, 1.446300484e-08, -3.36907094e-012}, blow = {-41137.52080000001, 40.45512519}, ahigh = {-112764.0116, -825.226138, 7.61617863, -0.000199932761, 5.65563143e-08, -5.45431661e-012, 2.918294102e-016}, bhigh = {-33513.0869, -16.55776085}, R = 129.7842463294403);
          constant IdealGases.Common.DataRecord SO3(name = "SO3", MM = 0.0800632, Hf = -4944843.573576874, H0 = 145990.9046852986, Tlimit = 1000, alow = {-39528.5529, 620.857257, -1.437731716, 0.02764126467, -3.144958662e-05, 1.792798e-08, -4.12638666e-012}, blow = {-51841.0617, 33.91331216}, ahigh = {-216692.3781, -1301.022399, 10.96287985, -0.000383710002, 8.466889039999999e-08, -9.70539929e-012, 4.49839754e-016}, bhigh = {-43982.83990000001, -36.55217314}, R = 103.8488594010732);
        end SingleGasesData;
      end Common;
    end IdealGases;

    package Incompressible
      extends Modelica.Icons.VariantsPackage;

      package Common
        extends Modelica.Icons.Package;

        record BaseProps_Tpoly
          extends Modelica.Icons.Record;
          .Modelica.SIunits.Temperature T;
          .Modelica.SIunits.Pressure p;
        end BaseProps_Tpoly;
      end Common;

      package TableBased
        extends Modelica.Media.Interfaces.PartialMedium(ThermoStates = if enthalpyOfT then Modelica.Media.Interfaces.Choices.IndependentVariables.T else Modelica.Media.Interfaces.Choices.IndependentVariables.pT, final reducedX = true, final fixedX = true, mediumName = "tableMedium", redeclare record ThermodynamicState = Common.BaseProps_Tpoly, singleState = true, reference_p = 1.013e5, Temperature(min = T_min, max = T_max));
        constant Boolean enthalpyOfT = true;
        constant Boolean densityOfT = size(tableDensity, 1) > 1;
        constant Modelica.SIunits.Temperature T_min;
        constant Modelica.SIunits.Temperature T_max;
        constant Temperature T0 = 273.15;
        constant SpecificEnthalpy h0 = 0;
        constant SpecificEntropy s0 = 0;
        constant MolarMass MM_const = 0.1;
        constant Integer npol = 2;
        constant Integer npolDensity = npol;
        constant Integer npolHeatCapacity = npol;
        constant Integer npolViscosity = npol;
        constant Integer npolVaporPressure = npol;
        constant Integer npolConductivity = npol;
        constant Integer neta = size(tableViscosity, 1);
        constant Real[:, 2] tableDensity;
        constant Real[:, 2] tableHeatCapacity;
        constant Real[:, 2] tableViscosity;
        constant Real[:, 2] tableVaporPressure;
        constant Real[:, 2] tableConductivity;
        constant Boolean TinK;
        constant Boolean hasDensity = not size(tableDensity, 1) == 0;
        constant Boolean hasHeatCapacity = not size(tableHeatCapacity, 1) == 0;
        constant Boolean hasViscosity = not size(tableViscosity, 1) == 0;
        constant Boolean hasVaporPressure = not size(tableVaporPressure, 1) == 0;
        final constant Real[neta] invTK = if size(tableViscosity, 1) > 0 then if TinK then 1 ./ tableViscosity[:, 1] else 1 ./ .Modelica.SIunits.Conversions.from_degC(tableViscosity[:, 1]) else fill(0, neta);
        final constant Real[:] poly_rho = if hasDensity then Polynomials_Temp.fitting(tableDensity[:, 1], tableDensity[:, 2], npolDensity) else zeros(npolDensity + 1);
        final constant Real[:] poly_Cp = if hasHeatCapacity then Polynomials_Temp.fitting(tableHeatCapacity[:, 1], tableHeatCapacity[:, 2], npolHeatCapacity) else zeros(npolHeatCapacity + 1);
        final constant Real[:] poly_eta = if hasViscosity then Polynomials_Temp.fitting(invTK, .Modelica.Math.log(tableViscosity[:, 2]), npolViscosity) else zeros(npolViscosity + 1);
        final constant Real[:] poly_lam = if size(tableConductivity, 1) > 0 then Polynomials_Temp.fitting(tableConductivity[:, 1], tableConductivity[:, 2], npolConductivity) else zeros(npolConductivity + 1);

        redeclare model extends BaseProperties
          .Modelica.SIunits.SpecificHeatCapacity cp;
          parameter .Modelica.SIunits.Temperature T_start = 298.15;
        equation
          assert(hasDensity, "Medium " + mediumName + " can not be used without assigning tableDensity.");
          assert(T >= T_min and T <= T_max, "Temperature T (= " + String(T) + " K) is not in the allowed range (" + String(T_min) + " K <= T <= " + String(T_max) + " K) required from medium model \"" + mediumName + "\".");
          R = Modelica.Constants.R;
          cp = Polynomials_Temp.evaluate(poly_Cp, if TinK then T else T_degC);
          h = if enthalpyOfT then h_T(T) else h_pT(p, T, densityOfT);
          u = h - (if singleState then reference_p / d else state.p / d);
          d = Polynomials_Temp.evaluate(poly_rho, if TinK then T else T_degC);
          state.T = T;
          state.p = p;
          MM = MM_const;
        end BaseProperties;

        redeclare function extends setState_pTX
        algorithm
          state := ThermodynamicState(p = p, T = T);
        end setState_pTX;

        redeclare function extends setState_dTX
        algorithm
          assert(false, "For incompressible media with d(T) only, state can not be set from density and temperature");
        end setState_dTX;

        redeclare function extends setState_phX
        algorithm
          state := ThermodynamicState(p = p, T = T_ph(p, h));
        end setState_phX;

        redeclare function extends setState_psX
        algorithm
          state := ThermodynamicState(p = p, T = T_ps(p, s));
        end setState_psX;

        redeclare function extends setSmoothState
        algorithm
          state := ThermodynamicState(p = Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), T = Media.Common.smoothStep(x, state_a.T, state_b.T, x_small));
        end setSmoothState;

        redeclare function extends specificHeatCapacityCv
        algorithm
          assert(hasHeatCapacity, "Specific Heat Capacity, Cv, is not defined for medium " + mediumName + ".");
          cv := Polynomials_Temp.evaluate(poly_Cp, if TinK then state.T else state.T - 273.15);
        end specificHeatCapacityCv;

        redeclare function extends specificHeatCapacityCp
        algorithm
          assert(hasHeatCapacity, "Specific Heat Capacity, Cv, is not defined for medium " + mediumName + ".");
          cp := Polynomials_Temp.evaluate(poly_Cp, if TinK then state.T else state.T - 273.15);
        end specificHeatCapacityCp;

        redeclare function extends dynamicViscosity
        algorithm
          assert(size(tableViscosity, 1) > 0, "DynamicViscosity, eta, is not defined for medium " + mediumName + ".");
          eta := .Modelica.Math.exp(Polynomials_Temp.evaluate(poly_eta, 1 / state.T));
        end dynamicViscosity;

        redeclare function extends thermalConductivity
        algorithm
          assert(size(tableConductivity, 1) > 0, "ThermalConductivity, lambda, is not defined for medium " + mediumName + ".");
          lambda := Polynomials_Temp.evaluate(poly_lam, if TinK then state.T else .Modelica.SIunits.Conversions.to_degC(state.T));
        end thermalConductivity;

        function s_T
          extends Modelica.Icons.Function;
          input Temperature T;
          output SpecificEntropy s;
        algorithm
          s := s0 + (if TinK then Polynomials_Temp.integralValue(poly_Cp[1:npol], T, T0) else Polynomials_Temp.integralValue(poly_Cp[1:npol], .Modelica.SIunits.Conversions.to_degC(T), .Modelica.SIunits.Conversions.to_degC(T0))) + Modelica.Math.log(T / T0) * Polynomials_Temp.evaluate(poly_Cp, if TinK then 0 else Modelica.Constants.T_zero);
        end s_T;

        redeclare function extends specificEntropy
        protected
          Integer npol = size(poly_Cp, 1) - 1;
        algorithm
          assert(hasHeatCapacity, "Specific Entropy, s(T), is not defined for medium " + mediumName + ".");
          s := s_T(state.T);
        end specificEntropy;

        function h_T
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature T;
          output .Modelica.SIunits.SpecificEnthalpy h;
        algorithm
          h := h0 + Polynomials_Temp.integralValue(poly_Cp, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T), if TinK then T0 else .Modelica.SIunits.Conversions.to_degC(T0));
        end h_T;

        function h_T_der
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature T;
          input Real dT;
          output Real dh;
        algorithm
          dh := Polynomials_Temp.evaluate(poly_Cp, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T)) * dT;
        end h_T_der;

        function h_pT
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input Boolean densityOfT = false;
          output .Modelica.SIunits.SpecificEnthalpy h;
        algorithm
          h := h0 + Polynomials_Temp.integralValue(poly_Cp, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T), if TinK then T0 else .Modelica.SIunits.Conversions.to_degC(T0)) + (p - reference_p) / Polynomials_Temp.evaluate(poly_rho, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T)) * (if densityOfT then 1 + T / Polynomials_Temp.evaluate(poly_rho, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T)) * Polynomials_Temp.derivativeValue(poly_rho, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T)) else 1.0);
        end h_pT;

        redeclare function extends temperature
        algorithm
          T := state.T;
        end temperature;

        redeclare function extends pressure
        algorithm
          p := state.p;
        end pressure;

        redeclare function extends density
        algorithm
          d := Polynomials_Temp.evaluate(poly_rho, if TinK then state.T else .Modelica.SIunits.Conversions.to_degC(state.T));
        end density;

        redeclare function extends specificEnthalpy
        algorithm
          h := if enthalpyOfT then h_T(state.T) else h_pT(state.p, state.T);
        end specificEnthalpy;

        redeclare function extends specificInternalEnergy
        algorithm
          u := (if enthalpyOfT then h_T(state.T) else h_pT(state.p, state.T)) - (if singleState then reference_p else state.p) / density(state);
        end specificInternalEnergy;

        function T_ph
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          output Temperature T;

        protected
          package Internal
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data
              constant Real[5] dummy = {1, 2, 3, 4, 5};
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear
            algorithm
              y := if singleState then h_T(x) else h_pT(p, x);
            end f_nonlinear;

            redeclare function extends solve  end solve;
          end Internal;
        algorithm
          T := Internal.solve(h, T_min, T_max, p, {1}, Internal.f_nonlinear_Data());
        end T_ph;

        function T_ps
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEntropy s;
          output Temperature T;

        protected
          package Internal
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data
              constant Real[5] dummy = {1, 2, 3, 4, 5};
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear
            algorithm
              y := s_T(x);
            end f_nonlinear;

            redeclare function extends solve  end solve;
          end Internal;
        algorithm
          T := Internal.solve(s, T_min, T_max, p, {1}, Internal.f_nonlinear_Data());
        end T_ps;

        package Polynomials_Temp
          extends Modelica.Icons.Package;

          function evaluate
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real u;
            output Real y;
          algorithm
            y := p[1];
            for j in 2:size(p, 1) loop
              y := p[j] + u * y;
            end for;
          end evaluate;

          function evaluateWithRange
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real uMin;
            input Real uMax;
            input Real u;
            output Real y;
          algorithm
            if u < uMin then
              y := evaluate(p, uMin) - evaluate_der(p, uMin, uMin - u);
            elseif u > uMax then
              y := evaluate(p, uMax) + evaluate_der(p, uMax, u - uMax);
            else
              y := evaluate(p, u);
            end if;
          end evaluateWithRange;

          function derivativeValue
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real u;
            output Real y;
          protected
            Integer n = size(p, 1);
          algorithm
            y := p[1] * (n - 1);
            for j in 2:size(p, 1) - 1 loop
              y := p[j] * (n - j) + u * y;
            end for;
          end derivativeValue;

          function secondDerivativeValue
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real u;
            output Real y;
          protected
            Integer n = size(p, 1);
          algorithm
            y := p[1] * (n - 1) * (n - 2);
            for j in 2:size(p, 1) - 2 loop
              y := p[j] * (n - j) * (n - j - 1) + u * y;
            end for;
          end secondDerivativeValue;

          function integralValue
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real u_high;
            input Real u_low = 0;
            output Real integral = 0.0;
          protected
            Integer n = size(p, 1);
            Real y_low = 0;
          algorithm
            for j in 1:n loop
              integral := u_high * (p[j] / (n - j + 1) + integral);
              y_low := u_low * (p[j] / (n - j + 1) + y_low);
            end for;
            integral := integral - y_low;
          end integralValue;

          function fitting
            extends Modelica.Icons.Function;
            input Real[:] u;
            input Real[size(u, 1)] y;
            input Integer n(min = 1);
            output Real[n + 1] p;
          protected
            Real[size(u, 1), n + 1] V;
          algorithm
            V[:, n + 1] := ones(size(u, 1));
            for j in n:(-1):1 loop
              V[:, j] := array(u[i] * V[i, j + 1] for i in 1:size(u, 1));
            end for;
            p := Modelica.Math.Matrices.leastSquares(V, y);
          end fitting;

          function evaluate_der
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real u;
            input Real du;
            output Real dy;
          protected
            Integer n = size(p, 1);
          algorithm
            dy := p[1] * (n - 1);
            for j in 2:size(p, 1) - 1 loop
              dy := p[j] * (n - j) + u * dy;
            end for;
            dy := dy * du;
          end evaluate_der;

          function evaluateWithRange_der
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real uMin;
            input Real uMax;
            input Real u;
            input Real du;
            output Real dy;
          algorithm
            if u < uMin then
              dy := evaluate_der(p, uMin, du);
            elseif u > uMax then
              dy := evaluate_der(p, uMax, du);
            else
              dy := evaluate_der(p, u, du);
            end if;
          end evaluateWithRange_der;

          function integralValue_der
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real u_high;
            input Real u_low = 0;
            input Real du_high;
            input Real du_low = 0;
            output Real dintegral = 0.0;
          algorithm
            dintegral := evaluate(p, u_high) * du_high;
          end integralValue_der;

          function derivativeValue_der
            extends Modelica.Icons.Function;
            input Real[:] p;
            input Real u;
            input Real du;
            output Real dy;
          protected
            Integer n = size(p, 1);
          algorithm
            dy := secondDerivativeValue(p, u) * du;
          end derivativeValue_der;
        end Polynomials_Temp;
      end TableBased;
    end Incompressible;

    package Water
      extends Modelica.Icons.VariantsPackage;

      package ConstantPropertyLiquidWater
        constant Modelica.Media.Interfaces.Types.Basic.FluidConstants[1] simpleWaterConstants(each chemicalFormula = "H2O", each structureFormula = "H2O", each casRegistryNumber = "7732-18-5", each iupacName = "oxidane", each molarMass = 0.018015268);
        extends Interfaces.PartialSimpleMedium(mediumName = "SimpleLiquidWater", cp_const = 4184, cv_const = 4184, d_const = 995.586, eta_const = 1.e-3, lambda_const = 0.598, a_const = 1484, T_min = .Modelica.SIunits.Conversions.from_degC(-1), T_max = .Modelica.SIunits.Conversions.from_degC(130), T0 = 273.15, MM_const = 0.018015268, fluidConstants = simpleWaterConstants);
      end ConstantPropertyLiquidWater;
    end Water;
  end Media;

  package Math
    extends Modelica.Icons.Package;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  end AxisLeft;

      partial function AxisCenter  end AxisCenter;
    end Icons;

    package Matrices
      extends Modelica.Icons.Package;

      function leastSquares
        extends Modelica.Icons.Function;
        input Real[:, :] A;
        input Real[size(A, 1)] b;
        input Real rcond = 100 * Modelica.Constants.eps;
        output Real[size(A, 2)] x;
        output Integer rank;
      protected
        Integer info;
        Real[max(size(A, 1), size(A, 2))] xx;
      algorithm
        if min(size(A)) > 0 then
          (xx, info, rank) := LAPACK.dgelsx_vec(A, b, rcond);
          x := xx[1:size(A, 2)];
          assert(info == 0, "Solving an overdetermined or underdetermined linear system\n" + "of equations with function \"Matrices.leastSquares\" failed.");
        else
          x := fill(0.0, size(A, 2));
        end if;
      end leastSquares;

      package LAPACK
        extends Modelica.Icons.Package;

        function dgelsx_vec
          extends Modelica.Icons.Function;
          input Real[:, :] A;
          input Real[size(A, 1)] b;
          input Real rcond = 0.0;
          output Real[max(size(A, 1), size(A, 2))] x = cat(1, b, zeros(max(nrow, ncol) - nrow));
          output Integer info;
          output Integer rank;
        protected
          Integer nrow = size(A, 1);
          Integer ncol = size(A, 2);
          Integer nx = max(nrow, ncol);
          Integer lwork = max(min(nrow, ncol) + 3 * ncol, 2 * min(nrow, ncol) + 1);
          Real[max(min(size(A, 1), size(A, 2)) + 3 * size(A, 2), 2 * min(size(A, 1), size(A, 2)) + 1)] work;
          Real[size(A, 1), size(A, 2)] Awork = A;
          Integer[size(A, 2)] jpvt = zeros(ncol);
          external "FORTRAN 77" dgelsx(nrow, ncol, 1, Awork, nrow, x, nx, jpvt, rcond, rank, work, lwork, info) annotation(Library = "lapack");
        end dgelsx_vec;
      end LAPACK;
    end Matrices;

    function cos
      extends Modelica.Math.Icons.AxisLeft;
      input .Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = cos(u);
    end cos;

    function tan
      extends Modelica.Math.Icons.AxisCenter;
      input .Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = tan(u);
    end tan;

    function asin
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function cosh
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = cosh(u);
    end cosh;

    function tanh
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = tanh(u);
    end tanh;

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

      function print
        extends Modelica.Icons.Function;
        input String string = "";
        input String fileName = "";
        external "C" ModelicaInternal_print(string, fileName) annotation(Library = "ModelicaExternalC");
      end print;

      function error
        extends Modelica.Icons.Function;
        input String string;
        external "C" ModelicaError(string) annotation(Library = "ModelicaExternalC");
      end error;
    end Streams;
  end Utilities;

  package Constants
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps;
    final constant Real inf = ModelicaServices.Machine.inf;
    final constant .Modelica.SIunits.Velocity c = 299792458;
    final constant .Modelica.SIunits.Acceleration g_n = 9.80665;
    final constant Real R(final unit = "J/(mol.K)") = 8.314472;
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7;
    final constant .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_zero = -273.15;
  end Constants;

  package Icons
    extends Icons.Package;

    partial package ExamplesPackage
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial model Example  end Example;

    partial package Package  end Package;

    partial package BasesPackage
      extends Modelica.Icons.Package;
    end BasesPackage;

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

    partial package UtilitiesPackage
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

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

      function to_bar
        extends Modelica.SIunits.Icons.Conversion;
        input Pressure Pa;
        output NonSIunits.Pressure_bar bar;
      algorithm
        bar := Pa / 1e5;
      end to_bar;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Length = Real(final quantity = "Length", final unit = "m");
    type Area = Real(final quantity = "Area", final unit = "m2");
    type Volume = Real(final quantity = "Volume", final unit = "m3");
    type Time = Real(final quantity = "Time", final unit = "s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type AbsolutePressure = Pressure(min = 0.0, nominal = 1e5);
    type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
    type Energy = Real(final quantity = "Energy", final unit = "J");
    type Power = Real(final quantity = "Power", final unit = "W");
    type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
    type MomentumFlux = Real(final quantity = "MomentumFlux", final unit = "N");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC");
    type Temperature = ThermodynamicTemperature;
    type Compressibility = Real(final quantity = "Compressibility", final unit = "1/Pa");
    type IsothermalCompressibility = Compressibility;
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
    type RatioOfSpecificHeatCapacities = Real(final quantity = "RatioOfSpecificHeatCapacities", final unit = "1");
    type Entropy = Real(final quantity = "Entropy", final unit = "J/K");
    type SpecificEntropy = Real(final quantity = "SpecificEntropy", final unit = "J/(kg.K)");
    type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
    type SpecificInternalEnergy = SpecificEnergy;
    type SpecificEnthalpy = SpecificEnergy;
    type DerDensityByEnthalpy = Real(final unit = "kg.s2/m5");
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

model Manifold
  extends Buildings.Fluid.HeatExchangers.BaseClasses.Examples.Manifold;
  annotation(experiment(StopTime = 1.0), __Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/Fluid/HeatExchangers/BaseClasses/Examples/Manifold.mos"));
end Manifold;

// Result:
// function Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow
//   input Real m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   input Real k(unit = "");
//   input Real m_flow_turbulent(quantity = "MassFlowRate", unit = "kg/s", min = 0.0);
//   output Real dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa");
//   protected Real kSquInv(unit = "1/(kg.m)");
// algorithm
//   kSquInv := k ^ (-2.0);
//   dp := Modelica.Fluid.Utilities.regSquare2(m_flow, m_flow_turbulent, kSquInv, kSquInv, false, 1.0);
// end Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.FluidConstants;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.ThermodynamicState;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.dynamicViscosity
//   input Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.ThermodynamicState state;
//   output Real eta(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0, max = 100000000.0, start = 0.001, nominal = 0.001);
// algorithm
//   eta := 1.85e-05;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.dynamicViscosity;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.setState_pTX;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.FluidConstants;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.ThermodynamicState"
//   input Real p(start = 300000.0, min = 0.0, max = 100000000.0, nominal = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(start = 293.15, min = 1.0, max = 10000.0, nominal = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.ThermodynamicState;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.dynamicViscosity
//   input Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.ThermodynamicState state;
//   output Real eta(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0, max = 100000000.0, start = 0.001, nominal = 0.001);
// algorithm
//   eta := 0.001;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.dynamicViscosity;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.setState_pTX;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.FluidConstants;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.ThermodynamicState"
//   input Real p(start = 300000.0, min = 0.0, max = 100000000.0, nominal = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(start = 293.15, min = 1.0, max = 10000.0, nominal = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.ThermodynamicState;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.dynamicViscosity
//   input Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.ThermodynamicState state;
//   output Real eta(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0, max = 100000000.0, start = 0.001, nominal = 0.001);
// algorithm
//   eta := 0.001;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.dynamicViscosity;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.setState_pTX;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.FluidConstants;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.ThermodynamicState;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.dynamicViscosity
//   input Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.ThermodynamicState state;
//   output Real eta(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0, max = 100000000.0, start = 0.001, nominal = 0.001);
// algorithm
//   eta := 1.85e-05;
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.dynamicViscosity;
//
// function Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.setState_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.FluidConstants;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.ThermodynamicState"
//   input Real p(start = 300000.0, min = 0.0, max = 100000000.0, nominal = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(start = 293.15, min = 1.0, max = 10000.0, nominal = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.FluidConstants;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.h_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg");
//   protected Real p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real x_sat(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real hDryAir(quantity = "SpecificEnergy", unit = "J/kg");
// algorithm
//   p_steam_sat := Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.saturationPressure(T);
//   x_sat := 0.6219647130774989 * p_steam_sat / (p - p_steam_sat);
//   hDryAir := 1006.0 * (-273.15 + T);
//   h := hDryAir * (1.0 - X[1]) + (2501014.5 + 1860.0 * (-273.15 + T)) * X[1];
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.h_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.saturationPressure
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
// algorithm
//   psat := Buildings.Utilities.Math.Functions.spliceFunction(Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.saturationPressureLiquid(Tsat), Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.sublimationPressureIce(Tsat), -273.16 + Tsat, 1.0);
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.saturationPressure;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.saturationPressureLiquid
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
// algorithm
//   psat := 611.657 * exp(17.2799 + (-4102.99) / (-35.719 + Tsat));
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.saturationPressureLiquid;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.setState_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.specificEnthalpy
//   input Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.specificEnthalpy;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.specificEnthalpy(/*.Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.ThermodynamicState*/(Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.setState_pTX(p, T, X)));
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.sublimationPressureIce
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real Ttriple(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 273.16;
//   protected Real ptriple(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 611.657;
//   protected Real[2] a = {-13.928169, 34.7078238};
//   protected Real[2] n = {-1.5, -1.25};
//   protected Real r1 = Tsat / Ttriple;
// algorithm
//   psat := exp(a[1] + a[2] + (-a[1]) * r1 ^ n[1] - a[2] * r1 ^ n[2]) * ptriple;
// end Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.sublimationPressureIce;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.FluidConstants;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.ThermodynamicState"
//   input Real p(start = 300000.0, min = 0.0, max = 100000000.0, nominal = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(start = 293.15, min = 1.0, max = 10000.0, nominal = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.FluidConstants;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.h_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg");
//   protected Real p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real x_sat(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real hDryAir(quantity = "SpecificEnergy", unit = "J/kg");
// algorithm
//   p_steam_sat := Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.saturationPressure(T);
//   x_sat := 0.6219647130774989 * p_steam_sat / (p - p_steam_sat);
//   hDryAir := 1006.0 * (-273.15 + T);
//   h := hDryAir * (1.0 - X[1]) + (2501014.5 + 1860.0 * (-273.15 + T)) * X[1];
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.h_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.saturationPressure
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
// algorithm
//   psat := Buildings.Utilities.Math.Functions.spliceFunction(Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.saturationPressureLiquid(Tsat), Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.sublimationPressureIce(Tsat), -273.16 + Tsat, 1.0);
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.saturationPressure;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.saturationPressureLiquid
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
// algorithm
//   psat := 611.657 * exp(17.2799 + (-4102.99) / (-35.719 + Tsat));
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.saturationPressureLiquid;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.setState_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.specificEnthalpy
//   input Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.specificEnthalpy;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.specificEnthalpy(/*.Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.ThermodynamicState*/(Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.setState_pTX(p, T, X)));
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.sublimationPressureIce
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real Ttriple(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 273.16;
//   protected Real ptriple(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 611.657;
//   protected Real[2] a = {-13.928169, 34.7078238};
//   protected Real[2] n = {-1.5, -1.25};
//   protected Real r1 = Tsat / Ttriple;
// algorithm
//   psat := exp(a[1] + a[2] + (-a[1]) * r1 ^ n[1] - a[2] * r1 ^ n[2]) * ptriple;
// end Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.sublimationPressureIce;
//
// function Buildings.Media.PerfectGases.Common.DataRecord "Automatically generated record constructor for Buildings.Media.PerfectGases.Common.DataRecord"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cp(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cv(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   output DataRecord res;
// end Buildings.Media.PerfectGases.Common.DataRecord;
//
// function Buildings.Media.PerfectGases.Common.DataRecord$Air "Automatically generated record constructor for Buildings.Media.PerfectGases.Common.DataRecord$Air"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cp(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cv(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   output DataRecord$Air res;
// end Buildings.Media.PerfectGases.Common.DataRecord$Air;
//
// function Buildings.Media.PerfectGases.Common.DataRecord$H2O "Automatically generated record constructor for Buildings.Media.PerfectGases.Common.DataRecord$H2O"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cp(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cv(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   output DataRecord$H2O res;
// end Buildings.Media.PerfectGases.Common.DataRecord$H2O;
//
// function Buildings.Media.PerfectGases.MoistAir.FluidConstants "Automatically generated record constructor for Buildings.Media.PerfectGases.MoistAir.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Buildings.Media.PerfectGases.MoistAir.FluidConstants;
//
// function Buildings.Utilities.Math.Functions.spliceFunction
//   input Real pos;
//   input Real neg;
//   input Real x;
//   input Real deltax;
//   output Real out;
//   protected Real scaledX1;
//   protected Real y;
//   protected constant Real asin1 = 1.570796326794897;
// algorithm
//   scaledX1 := x / deltax;
//   if scaledX1 <= -0.999999999 then
//     out := neg;
//   elseif scaledX1 >= 0.999999999 then
//     out := pos;
//   else
//     y := 0.5 + 0.5 * tanh(tan(1.570796326794897 * scaledX1));
//     out := pos * y + (1.0 - y) * neg;
//   end if;
// end Buildings.Utilities.Math.Functions.spliceFunction;
//
// function Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.Medium.FluidConstants;
//
// function Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.positiveMax
//   input Real x;
//   output Real y;
// algorithm
//   y := max(x, 1e-10);
// end Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.positiveMax;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$fixRes$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$fixRes$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$fixRes$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$floDis$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$floDis$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$floDis$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$ducFixRes_2$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$ducNoRes_2$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$ducNoRes_2$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$ducNoRes_2$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$hea1$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$hea1$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$hea1$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$hea2$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$hea2$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$hea2$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$mfr_1$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$mfr_1$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$mfr_1$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$mfr_2$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$mfr_2$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$mfr_2$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$fixRes$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$fixRes$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$fixRes$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$floDis$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$floDis$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$floDis$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$pipFixRes_1$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pipNoRes_1$mulPor$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$pipNoRes_1$mulPor$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$pipNoRes_1$mulPor$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pipNoRes_1$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$pipNoRes_1$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$pipNoRes_1$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$res_1$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$res_1$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$res_1$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$res_2$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$res_2$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$res_2$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$fixRes$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$fixRes$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$fixRes$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$floDis$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$floDis$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$floDis$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$ducFixRes_2$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$ducNoRes_2$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$ducNoRes_2$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$ducNoRes_2$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$hea1$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$hea1$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$hea1$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$hea2$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$hea2$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$hea2$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$mfr_1$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$mfr_1$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$mfr_1$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$mfr_2$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$mfr_2$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$mfr_2$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$fixRes$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$fixRes$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$fixRes$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$floDis$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$floDis$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$floDis$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$pipFixRes_1$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$pipNoRes_1$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$pipNoRes_1$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$pipNoRes_1$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$res_1$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$res_1$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$res_1$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$res_2$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$res_2$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$res_2$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$pipNoRes_1$mulPor$ports_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPorts_b$pipNoRes_1$mulPor$ports_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPorts_b$pipNoRes_1$mulPor$ports_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$sin_1$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPorts_b$sin_1$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPorts_b$sin_1$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$sin_2$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPorts_b$sin_2$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPorts_b$sin_2$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$sou_1$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPorts_b$sou_1$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPorts_b$sou_1$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$sou_2$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPorts_b$sou_2$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPorts_b$sou_2$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Utilities.checkBoundary
//   input String mediumName;
//   input String[:] substanceNames;
//   input Boolean singleState;
//   input Boolean define_p;
//   input Real[:] X_boundary;
//   input String modelName = "??? boundary ???";
//   protected String X_str;
//   protected Integer nX = size(X_boundary, 1);
// algorithm
//   assert(not singleState or singleState and define_p, "
//           Wrong value of parameter define_p (= false) in model \"" + modelName + "\":
//           The selected medium \"" + mediumName + "\" has Medium.singleState=true.
//           Therefore, an boundary density cannot be defined and
//           define_p = true is required.
//           ");
//   for i in 1:nX loop
//     assert(X_boundary[i] >= 0.0, "
//               Wrong boundary mass fractions in medium \"" + mediumName + "\" in model \"" + modelName + "\":
//               The boundary value X_boundary(" + String(i, 0, true) + ") = " + String(X_boundary[i], 6, 0, true) + "
//               is negative. It must be positive.
//               ");
//   end for;
//   if nX > 0 and abs(-1.0 + sum(X_boundary)) > 1e-10 then
//     X_str := "";
//     for i in 1:nX loop
//       X_str := X_str + "   X_boundary[" + String(i, 0, true) + "] = " + String(X_boundary[i], 6, 0, true) + " \"" + substanceNames[i] + "\"
//       ";
//     end for;
//     Modelica.Utilities.Streams.error("The boundary mass fractions in medium \"" + mediumName + "\" in model \"" + modelName + "\"
//     " + "do not sum up to 1. Instead, sum(X_boundary) = " + String(sum(X_boundary), 6, 0, true) + ":
//     " + X_str);
//   end if;
// end Modelica.Fluid.Utilities.checkBoundary;
//
// function Modelica.Fluid.Utilities.evaluatePoly3_derivativeAtZero
//   input Real x;
//   input Real x1;
//   input Real y1;
//   input Real y1d;
//   input Real y0d;
//   output Real y;
//   protected Real a1;
//   protected Real a2;
//   protected Real a3;
//   protected Real xx;
// algorithm
//   a1 := x1 * y0d;
//   a2 := 3.0 * y1 + (-2.0) * a1 - x1 * y1d;
//   a3 := y1 + (-a2) - a1;
//   xx := x / x1;
//   y := xx * (a1 + xx * (a2 + xx * a3));
// end Modelica.Fluid.Utilities.evaluatePoly3_derivativeAtZero;
//
// function Modelica.Fluid.Utilities.regSquare2
//   input Real x;
//   input Real x_small(min = 0.0) = 0.01;
//   input Real k1(min = 0.0) = 1.0;
//   input Real k2(min = 0.0) = 1.0;
//   input Boolean use_yd0 = false;
//   input Real yd0(min = 0.0) = 1.0;
//   output Real y;
// algorithm
//   y := smooth(2, if x >= x_small then k1 * x ^ 2.0 else if x <= (-x_small) then (-k2) * x ^ 2.0 else if k1 >= k2 then Modelica.Fluid.Utilities.regSquare2.regSquare2_utility(x, x_small, k1, k2, use_yd0, yd0) else -Modelica.Fluid.Utilities.regSquare2.regSquare2_utility(-x, x_small, k2, k1, use_yd0, yd0));
// end Modelica.Fluid.Utilities.regSquare2;
//
// function Modelica.Fluid.Utilities.regSquare2.regSquare2_utility
//   input Real x;
//   input Real x1;
//   input Real k1;
//   input Real k2;
//   input Boolean use_yd0 = false;
//   input Real yd0(min = 0.0) = 1.0;
//   output Real y;
//   protected Real x2;
//   protected Real y1;
//   protected Real y2;
//   protected Real y1d;
//   protected Real y2d;
//   protected Real w;
//   protected Real w1;
//   protected Real w2;
//   protected Real y0d;
//   protected Real ww;
// algorithm
//   x2 := -x1;
//   if x <= x2 then
//     y := (-k2) * x ^ 2.0;
//   else
//     y1 := k1 * x1 ^ 2.0;
//     y2 := (-k2) * x2 ^ 2.0;
//     y1d := 2.0 * k1 * x1;
//     y2d := (-2.0) * k2 * x2;
//     if use_yd0 then
//       y0d := yd0;
//     else
//       w := x2 / x1;
//       y0d := 0.5 * ((3.0 * y2 - x2 * y2d) / w + (x1 * y1d + (-3.0) * y1) * w) / ((1.0 - w) * x1);
//     end if;
//     w1 := 2.23606797749979 * k1 * x1;
//     w2 := 2.23606797749979 * k2 * abs(x2);
//     ww := 0.9 * (if w1 < w2 then w1 else w2);
//     if ww < y0d then
//       y0d := ww;
//     end if;
//     y := if x >= 0.0 then Modelica.Fluid.Utilities.evaluatePoly3_derivativeAtZero(x, x1, y1, y1d, y0d) else Modelica.Fluid.Utilities.evaluatePoly3_derivativeAtZero(x, x2, y2, y2d, y0d);
//   end if;
// end Modelica.Fluid.Utilities.regSquare2.regSquare2_utility;
//
// function Modelica.Media.Air.MoistAir.FluidConstants "Automatically generated record constructor for Modelica.Media.Air.MoistAir.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Media.Air.MoistAir.FluidConstants;
//
// function Modelica.Media.Air.MoistAir.ThermodynamicState "Automatically generated record constructor for Modelica.Media.Air.MoistAir.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 190.0, max = 647.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Modelica.Media.Air.MoistAir.ThermodynamicState;
//
// function Modelica.Media.IdealGases.Common.DataRecord "Automatically generated record constructor for Modelica.Media.IdealGases.Common.DataRecord"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real Hf(quantity = "SpecificEnergy", unit = "J/kg");
//   input Real H0(quantity = "SpecificEnergy", unit = "J/kg");
//   input Real Tlimit(quantity = "ThermodynamicTemperature", unit = "K", min = 0.0, start = 288.15, nominal = 300.0, displayUnit = "degC");
//   input Real[7] alow;
//   input Real[2] blow;
//   input Real[7] ahigh;
//   input Real[2] bhigh;
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   output DataRecord res;
// end Modelica.Media.IdealGases.Common.DataRecord;
//
// function Modelica.Media.IdealGases.Common.DataRecord$Air "Automatically generated record constructor for Modelica.Media.IdealGases.Common.DataRecord$Air"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real Hf(quantity = "SpecificEnergy", unit = "J/kg");
//   input Real H0(quantity = "SpecificEnergy", unit = "J/kg");
//   input Real Tlimit(quantity = "ThermodynamicTemperature", unit = "K", min = 0.0, start = 288.15, nominal = 300.0, displayUnit = "degC");
//   input Real[7] alow;
//   input Real[2] blow;
//   input Real[7] ahigh;
//   input Real[2] bhigh;
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   output DataRecord$Air res;
// end Modelica.Media.IdealGases.Common.DataRecord$Air;
//
// function Modelica.Media.IdealGases.Common.DataRecord$H2O "Automatically generated record constructor for Modelica.Media.IdealGases.Common.DataRecord$H2O"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real Hf(quantity = "SpecificEnergy", unit = "J/kg");
//   input Real H0(quantity = "SpecificEnergy", unit = "J/kg");
//   input Real Tlimit(quantity = "ThermodynamicTemperature", unit = "K", min = 0.0, start = 288.15, nominal = 300.0, displayUnit = "degC");
//   input Real[7] alow;
//   input Real[2] blow;
//   input Real[7] ahigh;
//   input Real[2] bhigh;
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   output DataRecord$H2O res;
// end Modelica.Media.IdealGases.Common.DataRecord$H2O;
//
// function Modelica.Media.IdealGases.Common.DataRecord$N2 "Automatically generated record constructor for Modelica.Media.IdealGases.Common.DataRecord$N2"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real Hf(quantity = "SpecificEnergy", unit = "J/kg");
//   input Real H0(quantity = "SpecificEnergy", unit = "J/kg");
//   input Real Tlimit(quantity = "ThermodynamicTemperature", unit = "K", min = 0.0, start = 288.15, nominal = 300.0, displayUnit = "degC");
//   input Real[7] alow;
//   input Real[2] blow;
//   input Real[7] ahigh;
//   input Real[2] bhigh;
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   output DataRecord$N2 res;
// end Modelica.Media.IdealGases.Common.DataRecord$N2;
//
// function Modelica.Media.Interfaces.Types.Basic.FluidConstants "Automatically generated record constructor for Modelica.Media.Interfaces.Types.Basic.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Media.Interfaces.Types.Basic.FluidConstants;
//
// function Modelica.Media.Interfaces.Types.Basic.FluidConstants$simpleWaterConstants "Automatically generated record constructor for Modelica.Media.Interfaces.Types.Basic.FluidConstants$simpleWaterConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants$simpleWaterConstants res;
// end Modelica.Media.Interfaces.Types.Basic.FluidConstants$simpleWaterConstants;
//
// function Modelica.Media.Interfaces.Types.IdealGas.FluidConstants "Automatically generated record constructor for Modelica.Media.Interfaces.Types.IdealGas.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants res;
// end Modelica.Media.Interfaces.Types.IdealGas.FluidConstants;
//
// function Modelica.Media.Interfaces.Types.IdealGas.FluidConstants$H2O "Automatically generated record constructor for Modelica.Media.Interfaces.Types.IdealGas.FluidConstants$H2O"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants$H2O res;
// end Modelica.Media.Interfaces.Types.IdealGas.FluidConstants$H2O;
//
// function Modelica.Media.Interfaces.Types.IdealGas.FluidConstants$N2 "Automatically generated record constructor for Modelica.Media.Interfaces.Types.IdealGas.FluidConstants$N2"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   input Real criticalTemperature(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real criticalPressure(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real criticalMolarVolume(min = 1e-06, max = 1000000.0, nominal = 1.0, quantity = "MolarVolume", unit = "m3/mol");
//   input Real acentricFactor;
//   input Real meltingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real normalBoilingPoint(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real dipoleMoment(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment");
//   input Boolean hasIdealGasHeatCapacity = false;
//   input Boolean hasCriticalData = false;
//   input Boolean hasDipoleMoment = false;
//   input Boolean hasFundamentalEquation = false;
//   input Boolean hasLiquidHeatCapacity = false;
//   input Boolean hasSolidHeatCapacity = false;
//   input Boolean hasAccurateViscosityData = false;
//   input Boolean hasAccurateConductivityData = false;
//   input Boolean hasVapourPressureCurve = false;
//   input Boolean hasAcentricFactor = false;
//   input Real HCRIT0(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real SCRIT0(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   input Real deltah(min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0, quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   input Real deltas(min = -10000000.0, max = 10000000.0, nominal = 1000.0, quantity = "SpecificEntropy", unit = "J/(kg.K)") = 0.0;
//   output FluidConstants$N2 res;
// end Modelica.Media.Interfaces.Types.IdealGas.FluidConstants$N2;
//
// function Modelica.Media.Water.ConstantPropertyLiquidWater.FluidConstants "Automatically generated record constructor for Modelica.Media.Water.ConstantPropertyLiquidWater.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Media.Water.ConstantPropertyLiquidWater.FluidConstants;
//
// function Modelica.SIunits.Conversions.from_degC
//   input Real Celsius(quantity = "ThermodynamicTemperature", unit = "degC");
//   output Real Kelvin(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
// algorithm
//   Kelvin := 273.15 + Celsius;
// end Modelica.SIunits.Conversions.from_degC;
//
// function Modelica.SIunits.Conversions.to_bar
//   input Real Pa(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   output Real bar(quantity = "Pressure", unit = "bar");
// algorithm
//   bar := 1e-05 * Pa;
// end Modelica.SIunits.Conversions.to_bar;
//
// function Modelica.SIunits.Conversions.to_degC
//   input Real Kelvin(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real Celsius(quantity = "ThermodynamicTemperature", unit = "degC");
// algorithm
//   Celsius := -273.15 + Kelvin;
// end Modelica.SIunits.Conversions.to_degC;
//
// function Modelica.Utilities.Streams.error
//   input String string;
//
//   external "C" ModelicaError(string);
// end Modelica.Utilities.Streams.error;
//
// class Manifold
//   parameter Integer nPipPar = 3;
//   parameter Integer nPipSeg = 4;
//   parameter Integer sin_1.nPorts = 1;
//   Real sin_1.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   Real sin_1.medium.h(quantity = "SpecificEnergy", unit = "J/kg");
//   Real sin_1.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
//   Real sin_1.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real sin_1.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   Real sin_1.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   Real sin_1.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   Real sin_1.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   Real sin_1.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 100000.0);
//   Real sin_1.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 293.15, nominal = 300.0);
//   parameter Boolean sin_1.medium.preferredMediumStates = false;
//   parameter Boolean sin_1.medium.standardOrderComponents = true;
//   Real sin_1.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(sin_1.medium.T);
//   Real sin_1.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(sin_1.medium.p);
//   Real sin_1.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if sin_1.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Entering then 0.0 else -9.999999999999999e+59, max = if sin_1.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Leaving then 0.0 else 9.999999999999999e+59);
//   Real sin_1.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sin_1.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter enumeration(Entering, Leaving, Bidirectional) sin_1.flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional;
//   parameter Boolean sin_1.use_p_in = false;
//   parameter Boolean sin_1.use_T_in = false;
//   parameter Boolean sin_1.use_X_in = false;
//   parameter Boolean sin_1.use_C_in = false;
//   parameter Real sin_1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   parameter Real sin_1.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 283.15;
//   parameter Real sin_1.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   protected Real sin_1.p_in_internal;
//   protected Real sin_1.T_in_internal;
//   protected Real sin_1.X_in_internal[1];
//   parameter Integer sou_1.nPorts = 1;
//   Real sou_1.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   Real sou_1.medium.h(quantity = "SpecificEnergy", unit = "J/kg");
//   Real sou_1.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
//   Real sou_1.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real sou_1.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   Real sou_1.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   Real sou_1.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   Real sou_1.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   Real sou_1.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 100000.0);
//   Real sou_1.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 293.15, nominal = 300.0);
//   parameter Boolean sou_1.medium.preferredMediumStates = false;
//   parameter Boolean sou_1.medium.standardOrderComponents = true;
//   Real sou_1.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(sou_1.medium.T);
//   Real sou_1.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(sou_1.medium.p);
//   Real sou_1.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if sou_1.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Entering then 0.0 else -9.999999999999999e+59, max = if sou_1.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Leaving then 0.0 else 9.999999999999999e+59);
//   Real sou_1.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sou_1.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter enumeration(Entering, Leaving, Bidirectional) sou_1.flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional;
//   parameter Boolean sou_1.use_p_in = true;
//   parameter Boolean sou_1.use_T_in = true;
//   parameter Boolean sou_1.use_X_in = false;
//   parameter Boolean sou_1.use_C_in = false;
//   parameter Real sou_1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 101335.0;
//   parameter Real sou_1.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   parameter Real sou_1.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   protected Real sou_1.p_in_internal;
//   protected Real sou_1.T_in_internal;
//   protected Real sou_1.X_in_internal[1];
//   Real sou_1.p_in;
//   Real sou_1.T_in;
//   parameter Boolean res_1.allowFlowReversal = system.allowFlowReversal;
//   Real res_1.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if res_1.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real res_1.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 300000.0);
//   Real res_1.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real res_1.port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if res_1.allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real res_1.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 300000.0);
//   Real res_1.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter Boolean res_1.port_a_exposesState = false;
//   protected parameter Boolean res_1.port_b_exposesState = false;
//   protected parameter Boolean res_1.showDesignFlowDirection = true;
//   parameter Real res_1.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   parameter Real res_1.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(res_1.m_flow_nominal);
//   parameter Boolean res_1.show_T = false;
//   Real res_1.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = 0.0, nominal = res_1.m_flow_nominal_pos) = res_1.port_a.m_flow;
//   Real res_1.dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0, nominal = res_1.dp_nominal_pos);
//   parameter Boolean res_1.from_dp = false;
//   parameter Real res_1.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa") = 3000.0;
//   parameter Boolean res_1.homotopyInitialization = true;
//   parameter Boolean res_1.linearized = false;
//   parameter Real res_1.m_flow_turbulent(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = if res_1.computeFlowResistance and res_1.use_dh then 0.7853981633974483 * res_1.eta_default * res_1.dh * res_1.ReC else if res_1.computeFlowResistance then res_1.deltaM * res_1.m_flow_nominal_pos else 0.0;
//   protected parameter Real res_1.sta_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real res_1.sta_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 293.15, nominal = 300.0) = 293.15;
//   protected parameter Real res_1.eta_default(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0) = Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_1.Medium.dynamicViscosity(res_1.sta_default);
//   protected final parameter Real res_1.m_flow_nominal_pos(quantity = "MassFlowRate", unit = "kg/s") = abs(res_1.m_flow_nominal);
//   protected final parameter Real res_1.dp_nominal_pos(quantity = "Pressure", unit = "Pa", displayUnit = "bar") = abs(res_1.dp_nominal);
//   parameter Boolean res_1.use_dh = true;
//   parameter Real res_1.dh(quantity = "Length", unit = "m") = 1.0;
//   parameter Real res_1.ReC(min = 0.0) = 4000.0;
//   parameter Real res_1.deltaM(min = 0.01) = 0.3;
//   final parameter Real res_1.k(unit = "") = if res_1.computeFlowResistance then res_1.m_flow_nominal_pos / sqrt(res_1.dp_nominal_pos) else 0.0;
//   protected final parameter Boolean res_1.computeFlowResistance = res_1.dp_nominal_pos > 1e-15;
//   parameter Boolean mfr_1[1].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_1[1].port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if mfr_1[1].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_1[1].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_1[1].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_1[1].port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if mfr_1[1].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_1[1].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_1[1].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter Boolean mfr_1[1].port_a_exposesState = false;
//   protected parameter Boolean mfr_1[1].port_b_exposesState = false;
//   protected parameter Boolean mfr_1[1].showDesignFlowDirection = true;
//   parameter Real mfr_1[1].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_1[1].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_1[1].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_1[2].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_1[2].port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if mfr_1[2].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_1[2].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_1[2].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_1[2].port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if mfr_1[2].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_1[2].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_1[2].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter Boolean mfr_1[2].port_a_exposesState = false;
//   protected parameter Boolean mfr_1[2].port_b_exposesState = false;
//   protected parameter Boolean mfr_1[2].showDesignFlowDirection = true;
//   parameter Real mfr_1[2].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_1[2].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_1[2].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_1[3].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_1[3].port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if mfr_1[3].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_1[3].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_1[3].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_1[3].port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if mfr_1[3].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_1[3].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_1[3].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter Boolean mfr_1[3].port_a_exposesState = false;
//   protected parameter Boolean mfr_1[3].port_b_exposesState = false;
//   protected parameter Boolean mfr_1[3].showDesignFlowDirection = true;
//   parameter Real mfr_1[3].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_1[3].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_1[3].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   Real TDb.y;
//   parameter Real TDb.height = 1.0;
//   parameter Real TDb.duration(quantity = "Time", unit = "s", min = 0.0, start = 2.0) = 1.0;
//   parameter Real TDb.offset = 293.15;
//   parameter Real TDb.startTime(quantity = "Time", unit = "s") = 0.0;
//   Real P.y;
//   parameter Real P.height = 12000.0;
//   parameter Real P.duration(quantity = "Time", unit = "s", min = 0.0, start = 2.0) = 1.0;
//   parameter Real P.offset = 294000.0;
//   parameter Real P.startTime(quantity = "Time", unit = "s") = 0.0;
//   parameter Boolean pipFixRes_1.allowFlowReversal = system.allowFlowReversal;
//   parameter Integer pipFixRes_1.nPipPar(min = 1) = nPipPar;
//   parameter Real pipFixRes_1.mStart_flow_a(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   Real pipFixRes_1.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if pipFixRes_1.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = pipFixRes_1.mStart_flow_a);
//   Real pipFixRes_1.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipFixRes_1.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipFixRes_1.port_b[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipFixRes_1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipFixRes_1.mStart_flow_a) / /*Real*/(pipFixRes_1.nPipPar));
//   Real pipFixRes_1.port_b[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipFixRes_1.port_b[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipFixRes_1.port_b[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipFixRes_1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipFixRes_1.mStart_flow_a) / /*Real*/(pipFixRes_1.nPipPar));
//   Real pipFixRes_1.port_b[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipFixRes_1.port_b[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipFixRes_1.port_b[3].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipFixRes_1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipFixRes_1.mStart_flow_a) / /*Real*/(pipFixRes_1.nPipPar));
//   Real pipFixRes_1.port_b[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipFixRes_1.port_b[3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   parameter Real pipFixRes_1.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   parameter Real pipFixRes_1.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", min = 0.0) = 3000.0;
//   parameter Boolean pipFixRes_1.use_dh = false;
//   parameter Real pipFixRes_1.dh(quantity = "Length", unit = "m") = 0.025;
//   parameter Real pipFixRes_1.ReC = 4000.0;
//   parameter Boolean pipFixRes_1.linearized = false;
//   parameter Real pipFixRes_1.deltaM(min = 0.0) = 0.3;
//   parameter Boolean pipFixRes_1.from_dp = false;
//   parameter Boolean pipFixRes_1.fixRes.allowFlowReversal = system.allowFlowReversal;
//   Real pipFixRes_1.fixRes.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if pipFixRes_1.fixRes.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real pipFixRes_1.fixRes.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 300000.0);
//   Real pipFixRes_1.fixRes.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipFixRes_1.fixRes.port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipFixRes_1.fixRes.allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real pipFixRes_1.fixRes.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 300000.0);
//   Real pipFixRes_1.fixRes.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter Boolean pipFixRes_1.fixRes.port_a_exposesState = false;
//   protected parameter Boolean pipFixRes_1.fixRes.port_b_exposesState = false;
//   protected parameter Boolean pipFixRes_1.fixRes.showDesignFlowDirection = true;
//   parameter Real pipFixRes_1.fixRes.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = pipFixRes_1.m_flow_nominal;
//   parameter Real pipFixRes_1.fixRes.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(pipFixRes_1.fixRes.m_flow_nominal);
//   parameter Boolean pipFixRes_1.fixRes.show_T = false;
//   Real pipFixRes_1.fixRes.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = 0.0, nominal = pipFixRes_1.fixRes.m_flow_nominal_pos) = pipFixRes_1.fixRes.port_a.m_flow;
//   Real pipFixRes_1.fixRes.dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0, nominal = pipFixRes_1.fixRes.dp_nominal_pos);
//   parameter Boolean pipFixRes_1.fixRes.from_dp = pipFixRes_1.from_dp;
//   parameter Real pipFixRes_1.fixRes.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa") = pipFixRes_1.dp_nominal;
//   parameter Boolean pipFixRes_1.fixRes.homotopyInitialization = true;
//   parameter Boolean pipFixRes_1.fixRes.linearized = pipFixRes_1.linearized;
//   parameter Real pipFixRes_1.fixRes.m_flow_turbulent(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = if pipFixRes_1.fixRes.computeFlowResistance and pipFixRes_1.fixRes.use_dh then 0.7853981633974483 * pipFixRes_1.fixRes.eta_default * pipFixRes_1.fixRes.dh * pipFixRes_1.fixRes.ReC else if pipFixRes_1.fixRes.computeFlowResistance then pipFixRes_1.fixRes.deltaM * pipFixRes_1.fixRes.m_flow_nominal_pos else 0.0;
//   protected parameter Real pipFixRes_1.fixRes.sta_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real pipFixRes_1.fixRes.sta_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 293.15, nominal = 300.0) = 293.15;
//   protected parameter Real pipFixRes_1.fixRes.eta_default(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0) = Buildings.Fluid.FixedResistances.FixedResistanceDpM$pipFixRes_1$fixRes.Medium.dynamicViscosity(pipFixRes_1.fixRes.sta_default);
//   protected final parameter Real pipFixRes_1.fixRes.m_flow_nominal_pos(quantity = "MassFlowRate", unit = "kg/s") = abs(pipFixRes_1.fixRes.m_flow_nominal);
//   protected final parameter Real pipFixRes_1.fixRes.dp_nominal_pos(quantity = "Pressure", unit = "Pa", displayUnit = "bar") = abs(pipFixRes_1.fixRes.dp_nominal);
//   parameter Boolean pipFixRes_1.fixRes.use_dh = pipFixRes_1.use_dh;
//   parameter Real pipFixRes_1.fixRes.dh(quantity = "Length", unit = "m") = pipFixRes_1.dh;
//   parameter Real pipFixRes_1.fixRes.ReC(min = 0.0) = pipFixRes_1.ReC;
//   parameter Real pipFixRes_1.fixRes.deltaM(min = 0.01) = pipFixRes_1.deltaM;
//   final parameter Real pipFixRes_1.fixRes.k(unit = "") = if pipFixRes_1.fixRes.computeFlowResistance then pipFixRes_1.fixRes.m_flow_nominal_pos / sqrt(pipFixRes_1.fixRes.dp_nominal_pos) else 0.0;
//   protected final parameter Boolean pipFixRes_1.fixRes.computeFlowResistance = pipFixRes_1.fixRes.dp_nominal_pos > 1e-15;
//   protected parameter Boolean pipFixRes_1.floDis.allowFlowReversal = pipFixRes_1.allowFlowReversal;
//   protected parameter Integer pipFixRes_1.floDis.nPipPar(min = 1) = pipFixRes_1.nPipPar;
//   protected parameter Real pipFixRes_1.floDis.mStart_flow_a(quantity = "MassFlowRate", unit = "kg/s") = pipFixRes_1.mStart_flow_a;
//   protected Real pipFixRes_1.floDis.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if pipFixRes_1.floDis.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = pipFixRes_1.floDis.mStart_flow_a);
//   protected Real pipFixRes_1.floDis.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pipFixRes_1.floDis.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real pipFixRes_1.floDis.port_b[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipFixRes_1.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipFixRes_1.floDis.mStart_flow_a) / /*Real*/(pipFixRes_1.floDis.nPipPar));
//   protected Real pipFixRes_1.floDis.port_b[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pipFixRes_1.floDis.port_b[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real pipFixRes_1.floDis.port_b[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipFixRes_1.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipFixRes_1.floDis.mStart_flow_a) / /*Real*/(pipFixRes_1.floDis.nPipPar));
//   protected Real pipFixRes_1.floDis.port_b[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pipFixRes_1.floDis.port_b[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real pipFixRes_1.floDis.port_b[3].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipFixRes_1.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipFixRes_1.floDis.mStart_flow_a) / /*Real*/(pipFixRes_1.floDis.nPipPar));
//   protected Real pipFixRes_1.floDis.port_b[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pipFixRes_1.floDis.port_b[3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   parameter Boolean pipNoRes_1.allowFlowReversal = system.allowFlowReversal;
//   parameter Integer pipNoRes_1.nPipPar(min = 1) = nPipPar;
//   parameter Real pipNoRes_1.mStart_flow_a(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   Real pipNoRes_1.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if pipNoRes_1.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = pipNoRes_1.mStart_flow_a);
//   Real pipNoRes_1.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipNoRes_1.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipNoRes_1.port_b[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipNoRes_1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipNoRes_1.mStart_flow_a) / /*Real*/(pipNoRes_1.nPipPar));
//   Real pipNoRes_1.port_b[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipNoRes_1.port_b[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipNoRes_1.port_b[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipNoRes_1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipNoRes_1.mStart_flow_a) / /*Real*/(pipNoRes_1.nPipPar));
//   Real pipNoRes_1.port_b[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipNoRes_1.port_b[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipNoRes_1.port_b[3].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pipNoRes_1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-pipNoRes_1.mStart_flow_a) / /*Real*/(pipNoRes_1.nPipPar));
//   Real pipNoRes_1.port_b[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipNoRes_1.port_b[3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   parameter Boolean pipNoRes_1.connectAllPressures = true;
//   parameter Integer pipNoRes_1.mulPor.nPorts_b = pipNoRes_1.nPipPar;
//   Real pipNoRes_1.mulPor.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real pipNoRes_1.mulPor.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipNoRes_1.mulPor.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipNoRes_1.mulPor.ports_b[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real pipNoRes_1.mulPor.ports_b[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipNoRes_1.mulPor.ports_b[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipNoRes_1.mulPor.ports_b[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real pipNoRes_1.mulPor.ports_b[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipNoRes_1.mulPor.ports_b[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pipNoRes_1.mulPor.ports_b[3].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real pipNoRes_1.mulPor.ports_b[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pipNoRes_1.mulPor.ports_b[3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   parameter Boolean res_2.allowFlowReversal = system.allowFlowReversal;
//   Real res_2.port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if res_2.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real res_2.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 101325.0, nominal = 101325.0);
//   Real res_2.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real res_2.port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real res_2.port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if res_2.allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real res_2.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 101325.0, nominal = 101325.0);
//   Real res_2.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real res_2.port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean res_2.port_a_exposesState = false;
//   protected parameter Boolean res_2.port_b_exposesState = false;
//   protected parameter Boolean res_2.showDesignFlowDirection = true;
//   parameter Real res_2.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   parameter Real res_2.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(res_2.m_flow_nominal);
//   parameter Boolean res_2.show_T = false;
//   Real res_2.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = 0.0, nominal = res_2.m_flow_nominal_pos) = res_2.port_a.m_flow;
//   Real res_2.dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0, nominal = res_2.dp_nominal_pos);
//   parameter Boolean res_2.from_dp = false;
//   parameter Real res_2.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa") = 10.0;
//   parameter Boolean res_2.homotopyInitialization = true;
//   parameter Boolean res_2.linearized = false;
//   parameter Real res_2.m_flow_turbulent(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = if res_2.computeFlowResistance and res_2.use_dh then 0.7853981633974483 * res_2.eta_default * res_2.dh * res_2.ReC else if res_2.computeFlowResistance then res_2.deltaM * res_2.m_flow_nominal_pos else 0.0;
//   protected parameter Real res_2.sta_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 101325.0;
//   protected parameter Real res_2.sta_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real res_2.sta_default.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.01;
//   protected parameter Real res_2.sta_default.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.99;
//   protected parameter Real res_2.eta_default(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0) = Buildings.Fluid.FixedResistances.FixedResistanceDpM$res_2.Medium.dynamicViscosity(res_2.sta_default);
//   protected final parameter Real res_2.m_flow_nominal_pos(quantity = "MassFlowRate", unit = "kg/s") = abs(res_2.m_flow_nominal);
//   protected final parameter Real res_2.dp_nominal_pos(quantity = "Pressure", unit = "Pa", displayUnit = "bar") = abs(res_2.dp_nominal);
//   parameter Boolean res_2.use_dh = true;
//   parameter Real res_2.dh(quantity = "Length", unit = "m") = 1.0;
//   parameter Real res_2.ReC(min = 0.0) = 4000.0;
//   parameter Real res_2.deltaM(min = 0.01) = 0.3;
//   final parameter Real res_2.k(unit = "") = if res_2.computeFlowResistance then res_2.m_flow_nominal_pos / sqrt(res_2.dp_nominal_pos) else 0.0;
//   protected final parameter Boolean res_2.computeFlowResistance = res_2.dp_nominal_pos > 1e-15;
//   parameter Boolean mfr_2[1,1].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[1,1].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[1,1].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[1,1].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[1,1].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[1,1].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[1,1].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[1,1].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[1,1].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[1,1].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[1,1].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[1,1].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[1,1].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[1,1].showDesignFlowDirection = true;
//   parameter Real mfr_2[1,1].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[1,1].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[1,1].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[1,2].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[1,2].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[1,2].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[1,2].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[1,2].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[1,2].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[1,2].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[1,2].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[1,2].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[1,2].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[1,2].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[1,2].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[1,2].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[1,2].showDesignFlowDirection = true;
//   parameter Real mfr_2[1,2].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[1,2].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[1,2].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[1,3].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[1,3].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[1,3].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[1,3].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[1,3].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[1,3].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[1,3].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[1,3].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[1,3].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[1,3].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[1,3].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[1,3].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[1,3].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[1,3].showDesignFlowDirection = true;
//   parameter Real mfr_2[1,3].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[1,3].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[1,3].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[1,4].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[1,4].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[1,4].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[1,4].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[1,4].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[1,4].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[1,4].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[1,4].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[1,4].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[1,4].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[1,4].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[1,4].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[1,4].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[1,4].showDesignFlowDirection = true;
//   parameter Real mfr_2[1,4].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[1,4].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[1,4].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[2,1].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[2,1].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[2,1].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[2,1].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[2,1].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[2,1].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[2,1].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[2,1].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[2,1].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[2,1].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[2,1].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[2,1].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[2,1].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[2,1].showDesignFlowDirection = true;
//   parameter Real mfr_2[2,1].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[2,1].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[2,1].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[2,2].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[2,2].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[2,2].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[2,2].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[2,2].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[2,2].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[2,2].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[2,2].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[2,2].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[2,2].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[2,2].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[2,2].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[2,2].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[2,2].showDesignFlowDirection = true;
//   parameter Real mfr_2[2,2].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[2,2].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[2,2].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[2,3].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[2,3].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[2,3].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[2,3].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[2,3].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[2,3].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[2,3].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[2,3].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[2,3].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[2,3].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[2,3].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[2,3].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[2,3].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[2,3].showDesignFlowDirection = true;
//   parameter Real mfr_2[2,3].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[2,3].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[2,3].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[2,4].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[2,4].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[2,4].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[2,4].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[2,4].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[2,4].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[2,4].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[2,4].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[2,4].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[2,4].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[2,4].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[2,4].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[2,4].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[2,4].showDesignFlowDirection = true;
//   parameter Real mfr_2[2,4].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[2,4].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[2,4].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[3,1].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[3,1].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[3,1].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[3,1].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[3,1].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[3,1].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[3,1].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[3,1].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[3,1].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[3,1].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[3,1].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[3,1].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[3,1].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[3,1].showDesignFlowDirection = true;
//   parameter Real mfr_2[3,1].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[3,1].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[3,1].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[3,2].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[3,2].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[3,2].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[3,2].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[3,2].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[3,2].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[3,2].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[3,2].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[3,2].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[3,2].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[3,2].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[3,2].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[3,2].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[3,2].showDesignFlowDirection = true;
//   parameter Real mfr_2[3,2].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[3,2].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[3,2].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[3,3].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[3,3].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[3,3].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[3,3].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[3,3].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[3,3].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[3,3].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[3,3].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[3,3].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[3,3].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[3,3].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[3,3].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[3,3].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[3,3].showDesignFlowDirection = true;
//   parameter Real mfr_2[3,3].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[3,3].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[3,3].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean mfr_2[3,4].allowFlowReversal = system.allowFlowReversal;
//   Real mfr_2[3,4].port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if mfr_2[3,4].allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real mfr_2[3,4].port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[3,4].port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[3,4].port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real mfr_2[3,4].port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if mfr_2[3,4].allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real mfr_2[3,4].port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real mfr_2[3,4].port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real mfr_2[3,4].port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean mfr_2[3,4].port_a_exposesState = false;
//   protected parameter Boolean mfr_2[3,4].port_b_exposesState = false;
//   protected parameter Boolean mfr_2[3,4].showDesignFlowDirection = true;
//   parameter Real mfr_2[3,4].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   parameter Real mfr_2[3,4].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real mfr_2[3,4].m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   parameter Boolean ducFixRes_2.allowFlowReversal = system.allowFlowReversal;
//   parameter Integer ducFixRes_2.nPipPar(min = 1) = nPipPar;
//   parameter Real ducFixRes_2.mStart_flow_a(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   Real ducFixRes_2.port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if ducFixRes_2.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = ducFixRes_2.mStart_flow_a);
//   Real ducFixRes_2.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   parameter Integer ducFixRes_2.nPipSeg(min = 1) = nPipSeg;
//   Real ducFixRes_2.port_b[1,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[1,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[1,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[1,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[1,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[1,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[1,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[1,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[1,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[1,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[1,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[1,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[1,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[1,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[1,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[1,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[2,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[2,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[2,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[2,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[2,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[2,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[2,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[2,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[2,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[2,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[2,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[2,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[2,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[2,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[2,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[2,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[3,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[3,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[3,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[3,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[3,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[3,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[3,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[3,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[3,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[3,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[3,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[3,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.port_b[3,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.mStart_flow_a) / (/*Real*/(ducFixRes_2.nPipPar) * /*Real*/(ducFixRes_2.nPipSeg)));
//   Real ducFixRes_2.port_b[3,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducFixRes_2.port_b[3,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.port_b[3,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   parameter Boolean ducFixRes_2.use_dh = false;
//   parameter Real ducFixRes_2.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   parameter Real ducFixRes_2.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0) = 10.0;
//   parameter Real ducFixRes_2.dh(quantity = "Length", unit = "m") = 1.0;
//   parameter Real ducFixRes_2.ReC = 4000.0;
//   parameter Boolean ducFixRes_2.linearized = false;
//   parameter Real ducFixRes_2.deltaM(min = 0.0) = 0.3;
//   parameter Boolean ducFixRes_2.from_dp = false;
//   parameter Boolean ducFixRes_2.fixRes.allowFlowReversal = system.allowFlowReversal;
//   Real ducFixRes_2.fixRes.port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if ducFixRes_2.fixRes.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real ducFixRes_2.fixRes.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 101325.0, nominal = 101325.0);
//   Real ducFixRes_2.fixRes.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.fixRes.port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducFixRes_2.fixRes.port_b.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.fixRes.allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real ducFixRes_2.fixRes.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 101325.0, nominal = 101325.0);
//   Real ducFixRes_2.fixRes.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducFixRes_2.fixRes.port_b.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean ducFixRes_2.fixRes.port_a_exposesState = false;
//   protected parameter Boolean ducFixRes_2.fixRes.port_b_exposesState = false;
//   protected parameter Boolean ducFixRes_2.fixRes.showDesignFlowDirection = true;
//   parameter Real ducFixRes_2.fixRes.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = ducFixRes_2.m_flow_nominal;
//   parameter Real ducFixRes_2.fixRes.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(ducFixRes_2.fixRes.m_flow_nominal);
//   parameter Boolean ducFixRes_2.fixRes.show_T = false;
//   Real ducFixRes_2.fixRes.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = 0.0, nominal = ducFixRes_2.fixRes.m_flow_nominal_pos) = ducFixRes_2.fixRes.port_a.m_flow;
//   Real ducFixRes_2.fixRes.dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0, nominal = ducFixRes_2.fixRes.dp_nominal_pos);
//   parameter Boolean ducFixRes_2.fixRes.from_dp = ducFixRes_2.from_dp;
//   parameter Real ducFixRes_2.fixRes.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa") = ducFixRes_2.dp_nominal;
//   parameter Boolean ducFixRes_2.fixRes.homotopyInitialization = true;
//   parameter Boolean ducFixRes_2.fixRes.linearized = ducFixRes_2.linearized;
//   parameter Real ducFixRes_2.fixRes.m_flow_turbulent(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = if ducFixRes_2.fixRes.computeFlowResistance and ducFixRes_2.fixRes.use_dh then 0.7853981633974483 * ducFixRes_2.fixRes.eta_default * ducFixRes_2.fixRes.dh * ducFixRes_2.fixRes.ReC else if ducFixRes_2.fixRes.computeFlowResistance then ducFixRes_2.fixRes.deltaM * ducFixRes_2.fixRes.m_flow_nominal_pos else 0.0;
//   protected parameter Real ducFixRes_2.fixRes.sta_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 101325.0;
//   protected parameter Real ducFixRes_2.fixRes.sta_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real ducFixRes_2.fixRes.sta_default.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.01;
//   protected parameter Real ducFixRes_2.fixRes.sta_default.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.99;
//   protected parameter Real ducFixRes_2.fixRes.eta_default(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0) = Buildings.Fluid.FixedResistances.FixedResistanceDpM$ducFixRes_2$fixRes.Medium.dynamicViscosity(ducFixRes_2.fixRes.sta_default);
//   protected final parameter Real ducFixRes_2.fixRes.m_flow_nominal_pos(quantity = "MassFlowRate", unit = "kg/s") = abs(ducFixRes_2.fixRes.m_flow_nominal);
//   protected final parameter Real ducFixRes_2.fixRes.dp_nominal_pos(quantity = "Pressure", unit = "Pa", displayUnit = "bar") = abs(ducFixRes_2.fixRes.dp_nominal);
//   parameter Boolean ducFixRes_2.fixRes.use_dh = ducFixRes_2.use_dh;
//   parameter Real ducFixRes_2.fixRes.dh(quantity = "Length", unit = "m") = ducFixRes_2.dh;
//   parameter Real ducFixRes_2.fixRes.ReC(min = 0.0) = ducFixRes_2.ReC;
//   parameter Real ducFixRes_2.fixRes.deltaM(min = 0.01) = ducFixRes_2.deltaM;
//   final parameter Real ducFixRes_2.fixRes.k(unit = "") = if ducFixRes_2.fixRes.computeFlowResistance then ducFixRes_2.fixRes.m_flow_nominal_pos / sqrt(ducFixRes_2.fixRes.dp_nominal_pos) else 0.0;
//   protected final parameter Boolean ducFixRes_2.fixRes.computeFlowResistance = ducFixRes_2.fixRes.dp_nominal_pos > 1e-15;
//   protected parameter Boolean ducFixRes_2.floDis.allowFlowReversal = ducFixRes_2.allowFlowReversal;
//   protected parameter Integer ducFixRes_2.floDis.nPipPar(min = 1) = ducFixRes_2.nPipPar;
//   protected parameter Real ducFixRes_2.floDis.mStart_flow_a(quantity = "MassFlowRate", unit = "kg/s") = ducFixRes_2.mStart_flow_a;
//   protected Real ducFixRes_2.floDis.port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if ducFixRes_2.floDis.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = ducFixRes_2.floDis.mStart_flow_a);
//   protected Real ducFixRes_2.floDis.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Integer ducFixRes_2.floDis.nPipSeg(min = 1) = ducFixRes_2.nPipSeg;
//   protected Real ducFixRes_2.floDis.port_b[1,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[1,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[1,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[1,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[1,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[1,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[1,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[1,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[1,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[1,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[1,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[1,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[1,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[1,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[1,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[1,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[2,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[2,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[2,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[2,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[2,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[2,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[2,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[2,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[2,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[2,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[2,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[2,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[2,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[2,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[2,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[2,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[3,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[3,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[3,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[3,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[3,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[3,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[3,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[3,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[3,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[3,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[3,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[3,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real ducFixRes_2.floDis.port_b[3,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducFixRes_2.floDis.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducFixRes_2.floDis.mStart_flow_a) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg)));
//   protected Real ducFixRes_2.floDis.port_b[3,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real ducFixRes_2.floDis.port_b[3,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real ducFixRes_2.floDis.port_b[3,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   parameter Boolean ducNoRes_2.allowFlowReversal = system.allowFlowReversal;
//   parameter Integer ducNoRes_2.nPipPar(min = 1) = nPipPar;
//   parameter Real ducNoRes_2.mStart_flow_a(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   Real ducNoRes_2.port_a.m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if ducNoRes_2.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = ducNoRes_2.mStart_flow_a);
//   Real ducNoRes_2.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_a.Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   parameter Integer ducNoRes_2.nPipSeg(min = 1) = nPipSeg;
//   Real ducNoRes_2.port_b[1,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[1,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[1,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[1,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[1,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[1,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[1,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[1,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[1,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[1,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[1,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[1,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[1,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[1,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[1,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[1,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[2,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[2,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[2,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[2,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[2,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[2,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[2,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[2,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[2,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[2,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[2,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[2,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[2,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[2,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[2,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[2,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[3,1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[3,1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[3,1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[3,1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[3,2].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[3,2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[3,2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[3,2].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[3,3].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[3,3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[3,3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[3,3].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real ducNoRes_2.port_b[3,4].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = -100000.0, max = if ducNoRes_2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-ducNoRes_2.mStart_flow_a) / (/*Real*/(ducNoRes_2.nPipPar) * /*Real*/(ducNoRes_2.nPipSeg)));
//   Real ducNoRes_2.port_b[3,4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real ducNoRes_2.port_b[3,4].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real ducNoRes_2.port_b[3,4].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   parameter Boolean hea1.allowFlowReversal = system.allowFlowReversal;
//   parameter Integer hea1.nPipPar(min = 1) = nPipPar;
//   parameter Real hea1.mStart_flow_a(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   Real hea1.port_a[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if hea1.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = hea1.mStart_flow_a / /*Real*/(hea1.nPipPar));
//   Real hea1.port_a[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea1.port_a[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea1.port_a[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if hea1.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = hea1.mStart_flow_a / /*Real*/(hea1.nPipPar));
//   Real hea1.port_a[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea1.port_a[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea1.port_a[3].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if hea1.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = hea1.mStart_flow_a / /*Real*/(hea1.nPipPar));
//   Real hea1.port_a[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea1.port_a[3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea1.port_b[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if hea1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-hea1.mStart_flow_a) / /*Real*/(hea1.nPipPar));
//   Real hea1.port_b[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea1.port_b[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea1.port_b[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if hea1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-hea1.mStart_flow_a) / /*Real*/(hea1.nPipPar));
//   Real hea1.port_b[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea1.port_b[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea1.port_b[3].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if hea1.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-hea1.mStart_flow_a) / /*Real*/(hea1.nPipPar));
//   Real hea1.port_b[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea1.port_b[3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   parameter Boolean hea2.allowFlowReversal = system.allowFlowReversal;
//   parameter Integer hea2.nPipPar(min = 1) = nPipPar;
//   parameter Real hea2.mStart_flow_a(quantity = "MassFlowRate", unit = "kg/s") = 5.0;
//   Real hea2.port_a[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if hea2.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = hea2.mStart_flow_a / /*Real*/(hea2.nPipPar));
//   Real hea2.port_a[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea2.port_a[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea2.port_a[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if hea2.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = hea2.mStart_flow_a / /*Real*/(hea2.nPipPar));
//   Real hea2.port_a[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea2.port_a[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea2.port_a[3].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if hea2.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = hea2.mStart_flow_a / /*Real*/(hea2.nPipPar));
//   Real hea2.port_a[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea2.port_a[3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea2.port_b[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if hea2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-hea2.mStart_flow_a) / /*Real*/(hea2.nPipPar));
//   Real hea2.port_b[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea2.port_b[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea2.port_b[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if hea2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-hea2.mStart_flow_a) / /*Real*/(hea2.nPipPar));
//   Real hea2.port_b[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea2.port_b[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real hea2.port_b[3].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if hea2.allowFlowReversal then 9.999999999999999e+59 else 0.0, start = (-hea2.mStart_flow_a) / /*Real*/(hea2.nPipPar));
//   Real hea2.port_b[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real hea2.port_b[3].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   parameter Real system.p_ambient(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 101325.0;
//   parameter Real system.T_ambient(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 293.15;
//   parameter Real system.g(quantity = "Acceleration", unit = "m/s2") = 9.806649999999999;
//   parameter Boolean system.allowFlowReversal = true;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.massDynamics = system.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.substanceDynamics = system.massDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.traceDynamics = system.massDynamics;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.momentumDynamics = Modelica.Fluid.Types.Dynamics.SteadyState;
//   parameter Real system.m_flow_start(quantity = "MassFlowRate", unit = "kg/s") = 0.0;
//   parameter Real system.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = system.p_ambient;
//   parameter Real system.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = system.T_ambient;
//   parameter Boolean system.use_eps_Re = false;
//   parameter Real system.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = if system.use_eps_Re then 1.0 else 100.0 * system.m_flow_small;
//   parameter Real system.eps_m_flow(min = 0.0) = 0.0001;
//   parameter Real system.dp_small(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 1.0;
//   parameter Real system.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.01;
//   parameter Integer sou_2.nPorts = 1;
//   Real sou_2.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   Real sou_2.medium.Xi[1](quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0, start = 0.01);
//   Real sou_2.medium.h(quantity = "SpecificEnergy", unit = "J/kg");
//   Real sou_2.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
//   Real sou_2.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real sou_2.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 0.01, nominal = 0.1);
//   Real sou_2.medium.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 0.99, nominal = 0.1);
//   Real sou_2.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   Real sou_2.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   Real sou_2.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   Real sou_2.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sou_2.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real sou_2.medium.state.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real sou_2.medium.state.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   parameter Boolean sou_2.medium.preferredMediumStates = false;
//   parameter Boolean sou_2.medium.standardOrderComponents = true;
//   Real sou_2.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(sou_2.medium.T);
//   Real sou_2.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(sou_2.medium.p);
//   Real sou_2.medium.x_water(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real sou_2.medium.phi;
//   protected constant Real sou_2.medium.MMX[1](quantity = "MolarMass", unit = "kg/mol", min = 0.0) = 0.01801528;
//   protected constant Real sou_2.medium.MMX[2](quantity = "MolarMass", unit = "kg/mol", min = 0.0) = 0.0289651159;
//   protected Real sou_2.medium.X_steam(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real sou_2.medium.X_air(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real sou_2.medium.X_sat(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real sou_2.medium.x_sat(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real sou_2.medium.p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sou_2.ports[1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if sou_2.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Entering then 0.0 else -9.999999999999999e+59, max = if sou_2.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Leaving then 0.0 else 9.999999999999999e+59);
//   Real sou_2.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sou_2.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real sou_2.ports[1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter enumeration(Entering, Leaving, Bidirectional) sou_2.flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional;
//   parameter Boolean sou_2.use_p_in = true;
//   parameter Boolean sou_2.use_T_in = true;
//   parameter Boolean sou_2.use_X_in = false;
//   parameter Boolean sou_2.use_C_in = false;
//   parameter Real sou_2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 101335.0;
//   parameter Real sou_2.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   parameter Real sou_2.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.01;
//   parameter Real sou_2.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.99;
//   protected Real sou_2.p_in_internal;
//   protected Real sou_2.T_in_internal;
//   protected Real sou_2.X_in_internal[1];
//   protected Real sou_2.X_in_internal[2];
//   Real sou_2.p_in;
//   Real sou_2.T_in;
//   parameter Integer sin_2.nPorts = 1;
//   Real sin_2.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   Real sin_2.medium.Xi[1](quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0, start = 0.01);
//   Real sin_2.medium.h(quantity = "SpecificEnergy", unit = "J/kg");
//   Real sin_2.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
//   Real sin_2.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real sin_2.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 0.01, nominal = 0.1);
//   Real sin_2.medium.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 0.99, nominal = 0.1);
//   Real sin_2.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   Real sin_2.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   Real sin_2.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   Real sin_2.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sin_2.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real sin_2.medium.state.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real sin_2.medium.state.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   parameter Boolean sin_2.medium.preferredMediumStates = false;
//   parameter Boolean sin_2.medium.standardOrderComponents = true;
//   Real sin_2.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(sin_2.medium.T);
//   Real sin_2.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(sin_2.medium.p);
//   Real sin_2.medium.x_water(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   Real sin_2.medium.phi;
//   protected constant Real sin_2.medium.MMX[1](quantity = "MolarMass", unit = "kg/mol", min = 0.0) = 0.01801528;
//   protected constant Real sin_2.medium.MMX[2](quantity = "MolarMass", unit = "kg/mol", min = 0.0) = 0.0289651159;
//   protected Real sin_2.medium.X_steam(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real sin_2.medium.X_air(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real sin_2.medium.X_sat(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real sin_2.medium.x_sat(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real sin_2.medium.p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sin_2.ports[1].m_flow(quantity = "MassFlowRate.Moist air unsaturated perfect gas", unit = "kg/s", min = if sin_2.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Entering then 0.0 else -9.999999999999999e+59, max = if sin_2.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Leaving then 0.0 else 9.999999999999999e+59);
//   Real sin_2.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sin_2.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real sin_2.ports[1].Xi_outflow[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter enumeration(Entering, Leaving, Bidirectional) sin_2.flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional;
//   parameter Boolean sin_2.use_p_in = false;
//   parameter Boolean sin_2.use_T_in = false;
//   parameter Boolean sin_2.use_X_in = false;
//   parameter Boolean sin_2.use_C_in = false;
//   parameter Real sin_2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 101325.0;
//   parameter Real sin_2.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 283.15;
//   parameter Real sin_2.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.01;
//   parameter Real sin_2.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.99;
//   protected Real sin_2.p_in_internal;
//   protected Real sin_2.T_in_internal;
//   protected Real sin_2.X_in_internal[1];
//   protected Real sin_2.X_in_internal[2];
//   Real P1.y;
//   parameter Real P1.height = 40.0;
//   parameter Real P1.duration(quantity = "Time", unit = "s", min = 0.0, start = 2.0) = 1.0;
//   parameter Real P1.offset = 101305.0;
//   parameter Real P1.startTime(quantity = "Time", unit = "s") = 0.0;
// initial equation
//   assert(res_1.m_flow_turbulent > 0.0, "m_flow_turbulent must be bigger than zero.");
//   assert(res_1.m_flow_nominal_pos > 0.0, "m_flow_nominal_pos must be non-zero. Check parameters.");
//   assert(pipFixRes_1.fixRes.m_flow_turbulent > 0.0, "m_flow_turbulent must be bigger than zero.");
//   assert(pipFixRes_1.fixRes.m_flow_nominal_pos > 0.0, "m_flow_nominal_pos must be non-zero. Check parameters.");
//   assert(res_2.m_flow_turbulent > 0.0, "m_flow_turbulent must be bigger than zero.");
//   assert(res_2.m_flow_nominal_pos > 0.0, "m_flow_nominal_pos must be non-zero. Check parameters.");
//   assert(ducFixRes_2.fixRes.m_flow_turbulent > 0.0, "m_flow_turbulent must be bigger than zero.");
//   assert(ducFixRes_2.fixRes.m_flow_nominal_pos > 0.0, "m_flow_nominal_pos must be non-zero. Check parameters.");
// equation
//   assert(sin_1.medium.T >= 272.15 and sin_1.medium.T <= 403.15, "
//             Temperature T (= " + String(sin_1.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   sin_1.medium.h = Buildings.Fluid.Sources.Boundary_pT$sin_1.Medium.specificEnthalpy_pTX(sin_1.medium.p, sin_1.medium.T, {sin_1.medium.X[1]});
//   sin_1.medium.u = 4184.0 * (-273.15 + sin_1.medium.T);
//   sin_1.medium.d = 995.586;
//   sin_1.medium.R = 0.0;
//   sin_1.medium.MM = 0.018015268;
//   sin_1.medium.state.T = sin_1.medium.T;
//   sin_1.medium.state.p = sin_1.medium.p;
//   sin_1.medium.X[1] = 1.0;
//   assert(sin_1.medium.X[1] >= -1e-05 and sin_1.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(sin_1.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(sin_1.medium.p >= 0.0, "Pressure (= " + String(sin_1.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(sin_1.medium.T, 6, 0, true) + " K)");
//   Modelica.Fluid.Utilities.checkBoundary("SimpleLiquidWater", {"SimpleLiquidWater"}, true, true, {sin_1.X_in_internal[1]}, "Boundary_pT");
//   sin_1.p_in_internal = sin_1.p;
//   sin_1.T_in_internal = sin_1.T;
//   sin_1.X_in_internal[1] = sin_1.X[1];
//   sin_1.medium.p = sin_1.p_in_internal;
//   sin_1.medium.T = sin_1.T_in_internal;
//   sin_1.ports[1].p = sin_1.medium.p;
//   sin_1.ports[1].h_outflow = sin_1.medium.h;
//   assert(sou_1.medium.T >= 272.15 and sou_1.medium.T <= 403.15, "
//             Temperature T (= " + String(sou_1.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   sou_1.medium.h = Buildings.Fluid.Sources.Boundary_pT$sou_1.Medium.specificEnthalpy_pTX(sou_1.medium.p, sou_1.medium.T, {sou_1.medium.X[1]});
//   sou_1.medium.u = 4184.0 * (-273.15 + sou_1.medium.T);
//   sou_1.medium.d = 995.586;
//   sou_1.medium.R = 0.0;
//   sou_1.medium.MM = 0.018015268;
//   sou_1.medium.state.T = sou_1.medium.T;
//   sou_1.medium.state.p = sou_1.medium.p;
//   sou_1.medium.X[1] = 1.0;
//   assert(sou_1.medium.X[1] >= -1e-05 and sou_1.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(sou_1.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(sou_1.medium.p >= 0.0, "Pressure (= " + String(sou_1.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(sou_1.medium.T, 6, 0, true) + " K)");
//   Modelica.Fluid.Utilities.checkBoundary("SimpleLiquidWater", {"SimpleLiquidWater"}, true, true, {sou_1.X_in_internal[1]}, "Boundary_pT");
//   sou_1.X_in_internal[1] = sou_1.X[1];
//   sou_1.medium.p = sou_1.p_in_internal;
//   sou_1.medium.T = sou_1.T_in_internal;
//   sou_1.ports[1].p = sou_1.medium.p;
//   sou_1.ports[1].h_outflow = sou_1.medium.h;
//   res_1.dp = homotopy(Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(res_1.m_flow, res_1.k, res_1.m_flow_turbulent), res_1.dp_nominal_pos * res_1.m_flow / res_1.m_flow_nominal_pos);
//   res_1.port_a.h_outflow = sin_1.ports[1].h_outflow;
//   res_1.port_b.h_outflow = pipNoRes_1.port_a.h_outflow;
//   res_1.port_a.m_flow + res_1.port_b.m_flow = 0.0;
//   res_1.dp = res_1.port_a.p - res_1.port_b.p;
//   mfr_1[1].m_flow = mfr_1[1].port_a.m_flow;
//   mfr_1[1].port_b.m_flow = -mfr_1[1].port_a.m_flow;
//   mfr_1[1].port_a.p = mfr_1[1].port_b.p;
//   mfr_1[1].port_a.h_outflow = hea2.port_a[1].h_outflow;
//   mfr_1[1].port_b.h_outflow = hea1.port_b[1].h_outflow;
//   mfr_1[2].m_flow = mfr_1[2].port_a.m_flow;
//   mfr_1[2].port_b.m_flow = -mfr_1[2].port_a.m_flow;
//   mfr_1[2].port_a.p = mfr_1[2].port_b.p;
//   mfr_1[2].port_a.h_outflow = hea2.port_a[2].h_outflow;
//   mfr_1[2].port_b.h_outflow = hea1.port_b[2].h_outflow;
//   mfr_1[3].m_flow = mfr_1[3].port_a.m_flow;
//   mfr_1[3].port_b.m_flow = -mfr_1[3].port_a.m_flow;
//   mfr_1[3].port_a.p = mfr_1[3].port_b.p;
//   mfr_1[3].port_a.h_outflow = hea2.port_a[3].h_outflow;
//   mfr_1[3].port_b.h_outflow = hea1.port_b[3].h_outflow;
//   TDb.y = TDb.offset + (if time < TDb.startTime then 0.0 else if time < TDb.startTime + TDb.duration then (time - TDb.startTime) * TDb.height / TDb.duration else TDb.height);
//   P.y = P.offset + (if time < P.startTime then 0.0 else if time < P.startTime + P.duration then (time - P.startTime) * P.height / P.duration else P.height);
//   pipFixRes_1.fixRes.dp = homotopy(Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(pipFixRes_1.fixRes.m_flow, pipFixRes_1.fixRes.k, pipFixRes_1.fixRes.m_flow_turbulent), pipFixRes_1.fixRes.dp_nominal_pos * pipFixRes_1.fixRes.m_flow / pipFixRes_1.fixRes.m_flow_nominal_pos);
//   pipFixRes_1.fixRes.port_a.h_outflow = pipFixRes_1.floDis.port_a.h_outflow;
//   pipFixRes_1.fixRes.port_b.h_outflow = sou_1.ports[1].h_outflow;
//   pipFixRes_1.fixRes.port_a.m_flow + pipFixRes_1.fixRes.port_b.m_flow = 0.0;
//   pipFixRes_1.fixRes.dp = pipFixRes_1.fixRes.port_a.p - pipFixRes_1.fixRes.port_b.p;
//   pipFixRes_1.floDis.port_b[1].m_flow = (-pipFixRes_1.floDis.port_a.m_flow) / /*Real*/(pipFixRes_1.floDis.nPipPar);
//   pipFixRes_1.floDis.port_b[2].m_flow = pipFixRes_1.floDis.port_b[1].m_flow;
//   pipFixRes_1.floDis.port_b[3].m_flow = pipFixRes_1.floDis.port_b[1].m_flow;
//   pipFixRes_1.floDis.port_b[1].p = pipFixRes_1.floDis.port_a.p;
//   pipFixRes_1.fixRes.port_b.h_outflow = pipFixRes_1.floDis.port_b[1].h_outflow;
//   pipFixRes_1.fixRes.port_b.h_outflow = pipFixRes_1.floDis.port_b[2].h_outflow;
//   pipFixRes_1.fixRes.port_b.h_outflow = pipFixRes_1.floDis.port_b[3].h_outflow;
//   pipFixRes_1.floDis.port_a.h_outflow = (hea1.port_a[1].h_outflow + hea1.port_a[2].h_outflow + hea1.port_a[3].h_outflow) / /*Real*/(pipFixRes_1.floDis.nPipPar);
//   0.0 = pipNoRes_1.mulPor.port_a.m_flow + pipNoRes_1.mulPor.ports_b[1].m_flow + pipNoRes_1.mulPor.ports_b[2].m_flow + pipNoRes_1.mulPor.ports_b[3].m_flow;
//   pipNoRes_1.mulPor.ports_b[1].p = pipNoRes_1.mulPor.port_a.p;
//   pipNoRes_1.mulPor.ports_b[2].p = pipNoRes_1.mulPor.port_a.p;
//   pipNoRes_1.mulPor.ports_b[3].p = pipNoRes_1.mulPor.port_a.p;
//   pipNoRes_1.mulPor.port_a.h_outflow = (Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.positiveMax(pipNoRes_1.mulPor.ports_b[1].m_flow) * hea2.port_b[1].h_outflow + Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.positiveMax(pipNoRes_1.mulPor.ports_b[2].m_flow) * hea2.port_b[2].h_outflow + Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.positiveMax(pipNoRes_1.mulPor.ports_b[3].m_flow) * hea2.port_b[3].h_outflow) / (Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.positiveMax(pipNoRes_1.mulPor.ports_b[1].m_flow) + Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.positiveMax(pipNoRes_1.mulPor.ports_b[2].m_flow) + Modelica.Fluid.Fittings.MultiPort$pipNoRes_1$mulPor.positiveMax(pipNoRes_1.mulPor.ports_b[3].m_flow));
//   pipNoRes_1.mulPor.ports_b[1].h_outflow = res_1.port_a.h_outflow;
//   pipNoRes_1.mulPor.ports_b[2].h_outflow = res_1.port_a.h_outflow;
//   pipNoRes_1.mulPor.ports_b[3].h_outflow = res_1.port_a.h_outflow;
//   res_2.dp = homotopy(Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(res_2.m_flow, res_2.k, res_2.m_flow_turbulent), res_2.dp_nominal_pos * res_2.m_flow / res_2.m_flow_nominal_pos);
//   res_2.port_a.h_outflow = sin_2.ports[1].h_outflow;
//   res_2.port_b.h_outflow = ducNoRes_2.port_a.h_outflow;
//   res_2.port_a.m_flow + res_2.port_b.m_flow = 0.0;
//   res_2.port_a.Xi_outflow[1] = sin_2.ports[1].Xi_outflow[1];
//   res_2.port_b.Xi_outflow[1] = ducNoRes_2.port_a.Xi_outflow[1];
//   res_2.dp = res_2.port_a.p - res_2.port_b.p;
//   mfr_2[1,1].m_flow = mfr_2[1,1].port_a.m_flow;
//   mfr_2[1,1].port_b.m_flow = -mfr_2[1,1].port_a.m_flow;
//   mfr_2[1,1].port_a.p = mfr_2[1,1].port_b.p;
//   mfr_2[1,1].port_a.h_outflow = ducNoRes_2.port_b[1,1].h_outflow;
//   mfr_2[1,1].port_b.h_outflow = ducFixRes_2.port_b[1,1].h_outflow;
//   mfr_2[1,1].port_a.Xi_outflow[1] = ducNoRes_2.port_b[1,1].Xi_outflow[1];
//   mfr_2[1,1].port_b.Xi_outflow[1] = ducFixRes_2.port_b[1,1].Xi_outflow[1];
//   mfr_2[1,2].m_flow = mfr_2[1,2].port_a.m_flow;
//   mfr_2[1,2].port_b.m_flow = -mfr_2[1,2].port_a.m_flow;
//   mfr_2[1,2].port_a.p = mfr_2[1,2].port_b.p;
//   mfr_2[1,2].port_a.h_outflow = ducNoRes_2.port_b[1,2].h_outflow;
//   mfr_2[1,2].port_b.h_outflow = ducFixRes_2.port_b[1,2].h_outflow;
//   mfr_2[1,2].port_a.Xi_outflow[1] = ducNoRes_2.port_b[1,2].Xi_outflow[1];
//   mfr_2[1,2].port_b.Xi_outflow[1] = ducFixRes_2.port_b[1,2].Xi_outflow[1];
//   mfr_2[1,3].m_flow = mfr_2[1,3].port_a.m_flow;
//   mfr_2[1,3].port_b.m_flow = -mfr_2[1,3].port_a.m_flow;
//   mfr_2[1,3].port_a.p = mfr_2[1,3].port_b.p;
//   mfr_2[1,3].port_a.h_outflow = ducNoRes_2.port_b[1,3].h_outflow;
//   mfr_2[1,3].port_b.h_outflow = ducFixRes_2.port_b[1,3].h_outflow;
//   mfr_2[1,3].port_a.Xi_outflow[1] = ducNoRes_2.port_b[1,3].Xi_outflow[1];
//   mfr_2[1,3].port_b.Xi_outflow[1] = ducFixRes_2.port_b[1,3].Xi_outflow[1];
//   mfr_2[1,4].m_flow = mfr_2[1,4].port_a.m_flow;
//   mfr_2[1,4].port_b.m_flow = -mfr_2[1,4].port_a.m_flow;
//   mfr_2[1,4].port_a.p = mfr_2[1,4].port_b.p;
//   mfr_2[1,4].port_a.h_outflow = ducNoRes_2.port_b[1,4].h_outflow;
//   mfr_2[1,4].port_b.h_outflow = ducFixRes_2.port_b[1,4].h_outflow;
//   mfr_2[1,4].port_a.Xi_outflow[1] = ducNoRes_2.port_b[1,4].Xi_outflow[1];
//   mfr_2[1,4].port_b.Xi_outflow[1] = ducFixRes_2.port_b[1,4].Xi_outflow[1];
//   mfr_2[2,1].m_flow = mfr_2[2,1].port_a.m_flow;
//   mfr_2[2,1].port_b.m_flow = -mfr_2[2,1].port_a.m_flow;
//   mfr_2[2,1].port_a.p = mfr_2[2,1].port_b.p;
//   mfr_2[2,1].port_a.h_outflow = ducNoRes_2.port_b[2,1].h_outflow;
//   mfr_2[2,1].port_b.h_outflow = ducFixRes_2.port_b[2,1].h_outflow;
//   mfr_2[2,1].port_a.Xi_outflow[1] = ducNoRes_2.port_b[2,1].Xi_outflow[1];
//   mfr_2[2,1].port_b.Xi_outflow[1] = ducFixRes_2.port_b[2,1].Xi_outflow[1];
//   mfr_2[2,2].m_flow = mfr_2[2,2].port_a.m_flow;
//   mfr_2[2,2].port_b.m_flow = -mfr_2[2,2].port_a.m_flow;
//   mfr_2[2,2].port_a.p = mfr_2[2,2].port_b.p;
//   mfr_2[2,2].port_a.h_outflow = ducNoRes_2.port_b[2,2].h_outflow;
//   mfr_2[2,2].port_b.h_outflow = ducFixRes_2.port_b[2,2].h_outflow;
//   mfr_2[2,2].port_a.Xi_outflow[1] = ducNoRes_2.port_b[2,2].Xi_outflow[1];
//   mfr_2[2,2].port_b.Xi_outflow[1] = ducFixRes_2.port_b[2,2].Xi_outflow[1];
//   mfr_2[2,3].m_flow = mfr_2[2,3].port_a.m_flow;
//   mfr_2[2,3].port_b.m_flow = -mfr_2[2,3].port_a.m_flow;
//   mfr_2[2,3].port_a.p = mfr_2[2,3].port_b.p;
//   mfr_2[2,3].port_a.h_outflow = ducNoRes_2.port_b[2,3].h_outflow;
//   mfr_2[2,3].port_b.h_outflow = ducFixRes_2.port_b[2,3].h_outflow;
//   mfr_2[2,3].port_a.Xi_outflow[1] = ducNoRes_2.port_b[2,3].Xi_outflow[1];
//   mfr_2[2,3].port_b.Xi_outflow[1] = ducFixRes_2.port_b[2,3].Xi_outflow[1];
//   mfr_2[2,4].m_flow = mfr_2[2,4].port_a.m_flow;
//   mfr_2[2,4].port_b.m_flow = -mfr_2[2,4].port_a.m_flow;
//   mfr_2[2,4].port_a.p = mfr_2[2,4].port_b.p;
//   mfr_2[2,4].port_a.h_outflow = ducNoRes_2.port_b[2,4].h_outflow;
//   mfr_2[2,4].port_b.h_outflow = ducFixRes_2.port_b[2,4].h_outflow;
//   mfr_2[2,4].port_a.Xi_outflow[1] = ducNoRes_2.port_b[2,4].Xi_outflow[1];
//   mfr_2[2,4].port_b.Xi_outflow[1] = ducFixRes_2.port_b[2,4].Xi_outflow[1];
//   mfr_2[3,1].m_flow = mfr_2[3,1].port_a.m_flow;
//   mfr_2[3,1].port_b.m_flow = -mfr_2[3,1].port_a.m_flow;
//   mfr_2[3,1].port_a.p = mfr_2[3,1].port_b.p;
//   mfr_2[3,1].port_a.h_outflow = ducNoRes_2.port_b[3,1].h_outflow;
//   mfr_2[3,1].port_b.h_outflow = ducFixRes_2.port_b[3,1].h_outflow;
//   mfr_2[3,1].port_a.Xi_outflow[1] = ducNoRes_2.port_b[3,1].Xi_outflow[1];
//   mfr_2[3,1].port_b.Xi_outflow[1] = ducFixRes_2.port_b[3,1].Xi_outflow[1];
//   mfr_2[3,2].m_flow = mfr_2[3,2].port_a.m_flow;
//   mfr_2[3,2].port_b.m_flow = -mfr_2[3,2].port_a.m_flow;
//   mfr_2[3,2].port_a.p = mfr_2[3,2].port_b.p;
//   mfr_2[3,2].port_a.h_outflow = ducNoRes_2.port_b[3,2].h_outflow;
//   mfr_2[3,2].port_b.h_outflow = ducFixRes_2.port_b[3,2].h_outflow;
//   mfr_2[3,2].port_a.Xi_outflow[1] = ducNoRes_2.port_b[3,2].Xi_outflow[1];
//   mfr_2[3,2].port_b.Xi_outflow[1] = ducFixRes_2.port_b[3,2].Xi_outflow[1];
//   mfr_2[3,3].m_flow = mfr_2[3,3].port_a.m_flow;
//   mfr_2[3,3].port_b.m_flow = -mfr_2[3,3].port_a.m_flow;
//   mfr_2[3,3].port_a.p = mfr_2[3,3].port_b.p;
//   mfr_2[3,3].port_a.h_outflow = ducNoRes_2.port_b[3,3].h_outflow;
//   mfr_2[3,3].port_b.h_outflow = ducFixRes_2.port_b[3,3].h_outflow;
//   mfr_2[3,3].port_a.Xi_outflow[1] = ducNoRes_2.port_b[3,3].Xi_outflow[1];
//   mfr_2[3,3].port_b.Xi_outflow[1] = ducFixRes_2.port_b[3,3].Xi_outflow[1];
//   mfr_2[3,4].m_flow = mfr_2[3,4].port_a.m_flow;
//   mfr_2[3,4].port_b.m_flow = -mfr_2[3,4].port_a.m_flow;
//   mfr_2[3,4].port_a.p = mfr_2[3,4].port_b.p;
//   mfr_2[3,4].port_a.h_outflow = ducNoRes_2.port_b[3,4].h_outflow;
//   mfr_2[3,4].port_b.h_outflow = ducFixRes_2.port_b[3,4].h_outflow;
//   mfr_2[3,4].port_a.Xi_outflow[1] = ducNoRes_2.port_b[3,4].Xi_outflow[1];
//   mfr_2[3,4].port_b.Xi_outflow[1] = ducFixRes_2.port_b[3,4].Xi_outflow[1];
//   ducFixRes_2.fixRes.dp = homotopy(Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(ducFixRes_2.fixRes.m_flow, ducFixRes_2.fixRes.k, ducFixRes_2.fixRes.m_flow_turbulent), ducFixRes_2.fixRes.dp_nominal_pos * ducFixRes_2.fixRes.m_flow / ducFixRes_2.fixRes.m_flow_nominal_pos);
//   ducFixRes_2.fixRes.port_a.h_outflow = ducFixRes_2.floDis.port_a.h_outflow;
//   ducFixRes_2.fixRes.port_b.h_outflow = sou_2.ports[1].h_outflow;
//   ducFixRes_2.fixRes.port_a.m_flow + ducFixRes_2.fixRes.port_b.m_flow = 0.0;
//   ducFixRes_2.fixRes.port_a.Xi_outflow[1] = ducFixRes_2.floDis.port_a.Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = sou_2.ports[1].Xi_outflow[1];
//   ducFixRes_2.fixRes.dp = ducFixRes_2.fixRes.port_a.p - ducFixRes_2.fixRes.port_b.p;
//   ducFixRes_2.floDis.port_b[1,1].m_flow = (-ducFixRes_2.floDis.port_a.m_flow) / (/*Real*/(ducFixRes_2.floDis.nPipPar) * /*Real*/(ducFixRes_2.floDis.nPipSeg));
//   ducFixRes_2.floDis.port_b[1,2].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[1,3].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[1,4].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[2,1].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[2,2].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[2,3].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[2,4].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[3,1].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[3,2].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[3,3].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[3,4].m_flow = ducFixRes_2.floDis.port_b[1,1].m_flow;
//   ducFixRes_2.floDis.port_b[1,1].p = ducFixRes_2.floDis.port_a.p;
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[1,1].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[1,1].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[1,2].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[1,2].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[1,3].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[1,3].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[1,4].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[1,4].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[2,1].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[2,1].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[2,2].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[2,2].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[2,3].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[2,3].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[2,4].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[2,4].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[3,1].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[3,1].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[3,2].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[3,2].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[3,3].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[3,3].Xi_outflow[1];
//   ducFixRes_2.fixRes.port_b.h_outflow = ducFixRes_2.floDis.port_b[3,4].h_outflow;
//   ducFixRes_2.fixRes.port_b.Xi_outflow[1] = ducFixRes_2.floDis.port_b[3,4].Xi_outflow[1];
//   ducFixRes_2.floDis.port_a.h_outflow = (mfr_2[1,1].port_a.h_outflow + mfr_2[2,1].port_a.h_outflow + mfr_2[3,1].port_a.h_outflow + mfr_2[1,2].port_a.h_outflow + mfr_2[2,2].port_a.h_outflow + mfr_2[3,2].port_a.h_outflow + mfr_2[1,3].port_a.h_outflow + mfr_2[2,3].port_a.h_outflow + mfr_2[3,3].port_a.h_outflow + mfr_2[1,4].port_a.h_outflow + mfr_2[2,4].port_a.h_outflow + mfr_2[3,4].port_a.h_outflow) / (/*Real*/(ducFixRes_2.floDis.nPipSeg) * /*Real*/(ducFixRes_2.floDis.nPipPar));
//   ducFixRes_2.floDis.port_a.Xi_outflow[1] = (sum(sum({ducFixRes_2.floDis.port_b[i,j].Xi_outflow[1]} for i in {1, 2, 3}) for j in {1, 2, 3, 4}) / /*Real*/(ducFixRes_2.floDis.nPipPar) / /*Real*/(ducFixRes_2.floDis.nPipSeg))[1];
//   assert(sou_2.medium.T >= 200.0 and sou_2.medium.T <= 423.15, "
//             Temperature T is not in the allowed range
//             200.0 K <= (T =" + String(sou_2.medium.T, 6, 0, true) + " K) <= 423.15 K
//             required from medium model \"" + "Moist air unsaturated perfect gas" + "\".");
//   sou_2.medium.MM = 1.0 / (34.52428788658843 + 20.98414717520355 * sou_2.medium.Xi[1]);
//   sou_2.medium.p_steam_sat = min(Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.saturationPressure(sou_2.medium.T), 0.999 * sou_2.medium.p);
//   sou_2.medium.X_sat = min(0.6219647130774989 * sou_2.medium.p_steam_sat * (1.0 - sou_2.medium.Xi[1]) / max(1e-13, sou_2.medium.p - sou_2.medium.p_steam_sat), 1.0);
//   sou_2.medium.X_steam = sou_2.medium.Xi[1];
//   sou_2.medium.X_air = 1.0 - sou_2.medium.Xi[1];
//   sou_2.medium.h = Buildings.Fluid.Sources.Boundary_pT$sou_2.Medium.specificEnthalpy_pTX(sou_2.medium.p, sou_2.medium.T, {sou_2.medium.Xi[1]});
//   sou_2.medium.R = 287.0512249529787 * (1.0 - sou_2.medium.X_steam) + 461.5233290850878 * sou_2.medium.X_steam;
//   sou_2.medium.u = sou_2.medium.h - sou_2.medium.R * sou_2.medium.T;
//   sou_2.medium.d = sou_2.medium.p / (sou_2.medium.R * sou_2.medium.T);
//   sou_2.medium.state.p = sou_2.medium.p;
//   sou_2.medium.state.T = sou_2.medium.T;
//   sou_2.medium.state.X[1] = sou_2.medium.X[1];
//   sou_2.medium.state.X[2] = sou_2.medium.X[2];
//   sou_2.medium.x_sat = 0.6219647130774989 * sou_2.medium.p_steam_sat / max(1e-13, sou_2.medium.p - sou_2.medium.p_steam_sat);
//   sou_2.medium.x_water = sou_2.medium.Xi[1] / max(sou_2.medium.X_air, 1e-13);
//   sou_2.medium.phi = sou_2.medium.p * sou_2.medium.Xi[1] / (sou_2.medium.p_steam_sat * (sou_2.medium.Xi[1] + 0.6219647130774989 * sou_2.medium.X_air));
//   sou_2.medium.Xi[1] = sou_2.medium.X[1];
//   sou_2.medium.X[2] = 1.0 - sou_2.medium.Xi[1];
//   assert(sou_2.medium.X[1] >= -1e-05 and sou_2.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(sou_2.medium.X[1], 6, 0, true) + "of substance " + "water" + "
//   of medium " + "Moist air unsaturated perfect gas" + " is not in the range 0..1");
//   assert(sou_2.medium.X[2] >= -1e-05 and sou_2.medium.X[2] <= 1.00001, "Mass fraction X[2] = " + String(sou_2.medium.X[2], 6, 0, true) + "of substance " + "air" + "
//   of medium " + "Moist air unsaturated perfect gas" + " is not in the range 0..1");
//   assert(sou_2.medium.p >= 0.0, "Pressure (= " + String(sou_2.medium.p, 6, 0, true) + " Pa) of medium \"" + "Moist air unsaturated perfect gas" + "\" is negative
//   (Temperature = " + String(sou_2.medium.T, 6, 0, true) + " K)");
//   Modelica.Fluid.Utilities.checkBoundary("Moist air unsaturated perfect gas", {"water", "air"}, false, true, {sou_2.X_in_internal[1], sou_2.X_in_internal[2]}, "Boundary_pT");
//   sou_2.X_in_internal[1] = sou_2.X[1];
//   sou_2.X_in_internal[2] = sou_2.X[2];
//   sou_2.medium.p = sou_2.p_in_internal;
//   sou_2.medium.T = sou_2.T_in_internal;
//   sou_2.medium.Xi[1] = sou_2.X_in_internal[1];
//   sou_2.ports[1].p = sou_2.medium.p;
//   sou_2.ports[1].h_outflow = sou_2.medium.h;
//   sou_2.ports[1].Xi_outflow[1] = sou_2.medium.Xi[1];
//   assert(sin_2.medium.T >= 200.0 and sin_2.medium.T <= 423.15, "
//             Temperature T is not in the allowed range
//             200.0 K <= (T =" + String(sin_2.medium.T, 6, 0, true) + " K) <= 423.15 K
//             required from medium model \"" + "Moist air unsaturated perfect gas" + "\".");
//   sin_2.medium.MM = 1.0 / (34.52428788658843 + 20.98414717520355 * sin_2.medium.Xi[1]);
//   sin_2.medium.p_steam_sat = min(Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.saturationPressure(sin_2.medium.T), 0.999 * sin_2.medium.p);
//   sin_2.medium.X_sat = min(0.6219647130774989 * sin_2.medium.p_steam_sat * (1.0 - sin_2.medium.Xi[1]) / max(1e-13, sin_2.medium.p - sin_2.medium.p_steam_sat), 1.0);
//   sin_2.medium.X_steam = sin_2.medium.Xi[1];
//   sin_2.medium.X_air = 1.0 - sin_2.medium.Xi[1];
//   sin_2.medium.h = Buildings.Fluid.Sources.Boundary_pT$sin_2.Medium.specificEnthalpy_pTX(sin_2.medium.p, sin_2.medium.T, {sin_2.medium.Xi[1]});
//   sin_2.medium.R = 287.0512249529787 * (1.0 - sin_2.medium.X_steam) + 461.5233290850878 * sin_2.medium.X_steam;
//   sin_2.medium.u = sin_2.medium.h - sin_2.medium.R * sin_2.medium.T;
//   sin_2.medium.d = sin_2.medium.p / (sin_2.medium.R * sin_2.medium.T);
//   sin_2.medium.state.p = sin_2.medium.p;
//   sin_2.medium.state.T = sin_2.medium.T;
//   sin_2.medium.state.X[1] = sin_2.medium.X[1];
//   sin_2.medium.state.X[2] = sin_2.medium.X[2];
//   sin_2.medium.x_sat = 0.6219647130774989 * sin_2.medium.p_steam_sat / max(1e-13, sin_2.medium.p - sin_2.medium.p_steam_sat);
//   sin_2.medium.x_water = sin_2.medium.Xi[1] / max(sin_2.medium.X_air, 1e-13);
//   sin_2.medium.phi = sin_2.medium.p * sin_2.medium.Xi[1] / (sin_2.medium.p_steam_sat * (sin_2.medium.Xi[1] + 0.6219647130774989 * sin_2.medium.X_air));
//   sin_2.medium.Xi[1] = sin_2.medium.X[1];
//   sin_2.medium.X[2] = 1.0 - sin_2.medium.Xi[1];
//   assert(sin_2.medium.X[1] >= -1e-05 and sin_2.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(sin_2.medium.X[1], 6, 0, true) + "of substance " + "water" + "
//   of medium " + "Moist air unsaturated perfect gas" + " is not in the range 0..1");
//   assert(sin_2.medium.X[2] >= -1e-05 and sin_2.medium.X[2] <= 1.00001, "Mass fraction X[2] = " + String(sin_2.medium.X[2], 6, 0, true) + "of substance " + "air" + "
//   of medium " + "Moist air unsaturated perfect gas" + " is not in the range 0..1");
//   assert(sin_2.medium.p >= 0.0, "Pressure (= " + String(sin_2.medium.p, 6, 0, true) + " Pa) of medium \"" + "Moist air unsaturated perfect gas" + "\" is negative
//   (Temperature = " + String(sin_2.medium.T, 6, 0, true) + " K)");
//   Modelica.Fluid.Utilities.checkBoundary("Moist air unsaturated perfect gas", {"water", "air"}, false, true, {sin_2.X_in_internal[1], sin_2.X_in_internal[2]}, "Boundary_pT");
//   sin_2.p_in_internal = sin_2.p;
//   sin_2.T_in_internal = sin_2.T;
//   sin_2.X_in_internal[1] = sin_2.X[1];
//   sin_2.X_in_internal[2] = sin_2.X[2];
//   sin_2.medium.p = sin_2.p_in_internal;
//   sin_2.medium.T = sin_2.T_in_internal;
//   sin_2.medium.Xi[1] = sin_2.X_in_internal[1];
//   sin_2.ports[1].p = sin_2.medium.p;
//   sin_2.ports[1].h_outflow = sin_2.medium.h;
//   sin_2.ports[1].Xi_outflow[1] = sin_2.medium.Xi[1];
//   P1.y = P1.offset + (if time < P1.startTime then 0.0 else if time < P1.startTime + P1.duration then (time - P1.startTime) * P1.height / P1.duration else P1.height);
//   sin_1.ports[1].m_flow + res_1.port_b.m_flow = 0.0;
//   sou_1.ports[1].m_flow + pipFixRes_1.port_a.m_flow = 0.0;
//   sou_1.p_in = sou_1.p_in_internal;
//   sou_1.T_in = sou_1.T_in_internal;
//   res_1.port_a.m_flow + pipNoRes_1.port_a.m_flow = 0.0;
//   res_2.port_a.m_flow + ducNoRes_2.port_a.m_flow = 0.0;
//   res_2.port_b.m_flow + sin_2.ports[1].m_flow = 0.0;
//   sou_2.ports[1].m_flow + ducFixRes_2.port_a.m_flow = 0.0;
//   sou_2.p_in = sou_2.p_in_internal;
//   sou_2.T_in = sou_2.T_in_internal;
//   mfr_1[3].port_a.m_flow + hea1.port_b[3].m_flow = 0.0;
//   mfr_1[3].port_b.m_flow + hea2.port_a[3].m_flow = 0.0;
//   mfr_1[2].port_a.m_flow + hea1.port_b[2].m_flow = 0.0;
//   mfr_1[2].port_b.m_flow + hea2.port_a[2].m_flow = 0.0;
//   mfr_1[1].port_a.m_flow + hea1.port_b[1].m_flow = 0.0;
//   mfr_1[1].port_b.m_flow + hea2.port_a[1].m_flow = 0.0;
//   pipFixRes_1.fixRes.port_a.m_flow + (-pipFixRes_1.port_a.m_flow) = 0.0;
//   pipFixRes_1.fixRes.port_b.m_flow + pipFixRes_1.floDis.port_a.m_flow = 0.0;
//   pipFixRes_1.port_b[3].m_flow + hea1.port_a[3].m_flow = 0.0;
//   pipFixRes_1.port_b[2].m_flow + hea1.port_a[2].m_flow = 0.0;
//   pipFixRes_1.port_b[1].m_flow + hea1.port_a[1].m_flow = 0.0;
//   (-pipFixRes_1.port_b[3].m_flow) + pipFixRes_1.floDis.port_b[3].m_flow = 0.0;
//   (-pipFixRes_1.port_b[2].m_flow) + pipFixRes_1.floDis.port_b[2].m_flow = 0.0;
//   (-pipFixRes_1.port_b[1].m_flow) + pipFixRes_1.floDis.port_b[1].m_flow = 0.0;
//   pipFixRes_1.fixRes.port_b.p = pipFixRes_1.floDis.port_a.p;
//   pipFixRes_1.port_b[1].h_outflow = pipFixRes_1.floDis.port_b[1].h_outflow;
//   pipFixRes_1.floDis.port_b[1].p = pipFixRes_1.port_b[1].p;
//   pipFixRes_1.port_b[2].h_outflow = pipFixRes_1.floDis.port_b[2].h_outflow;
//   pipFixRes_1.floDis.port_b[2].p = pipFixRes_1.port_b[2].p;
//   pipFixRes_1.port_b[3].h_outflow = pipFixRes_1.floDis.port_b[3].h_outflow;
//   pipFixRes_1.floDis.port_b[3].p = pipFixRes_1.port_b[3].p;
//   pipFixRes_1.fixRes.port_a.h_outflow = pipFixRes_1.port_a.h_outflow;
//   pipFixRes_1.fixRes.port_a.p = pipFixRes_1.port_a.p;
//   pipNoRes_1.mulPor.port_a.m_flow + (-pipNoRes_1.port_a.m_flow) = 0.0;
//   pipNoRes_1.mulPor.ports_b[3].m_flow + (-pipNoRes_1.port_b[3].m_flow) = 0.0;
//   pipNoRes_1.mulPor.ports_b[2].m_flow + (-pipNoRes_1.port_b[2].m_flow) = 0.0;
//   pipNoRes_1.mulPor.ports_b[1].m_flow + (-pipNoRes_1.port_b[1].m_flow) = 0.0;
//   pipNoRes_1.port_b[3].m_flow + hea2.port_b[3].m_flow = 0.0;
//   pipNoRes_1.port_b[2].m_flow + hea2.port_b[2].m_flow = 0.0;
//   pipNoRes_1.port_b[1].m_flow + hea2.port_b[1].m_flow = 0.0;
//   pipNoRes_1.mulPor.port_a.h_outflow = pipNoRes_1.port_a.h_outflow;
//   pipNoRes_1.mulPor.port_a.p = pipNoRes_1.port_a.p;
//   pipNoRes_1.mulPor.ports_b[1].h_outflow = pipNoRes_1.port_b[1].h_outflow;
//   pipNoRes_1.mulPor.ports_b[1].p = pipNoRes_1.port_b[1].p;
//   pipNoRes_1.mulPor.ports_b[2].h_outflow = pipNoRes_1.port_b[2].h_outflow;
//   pipNoRes_1.mulPor.ports_b[2].p = pipNoRes_1.port_b[2].p;
//   pipNoRes_1.mulPor.ports_b[3].h_outflow = pipNoRes_1.port_b[3].h_outflow;
//   pipNoRes_1.mulPor.ports_b[3].p = pipNoRes_1.port_b[3].p;
//   hea1.port_a[1].h_outflow = mfr_1[1].port_a.h_outflow;
//   hea1.port_b[1].h_outflow = pipFixRes_1.port_b[1].h_outflow;
//   (-hea1.port_a[1].m_flow) + (-hea1.port_b[1].m_flow) = 0.0;
//   hea1.port_a[1].p = hea1.port_b[1].p;
//   hea1.port_a[2].h_outflow = mfr_1[2].port_a.h_outflow;
//   hea1.port_b[2].h_outflow = pipFixRes_1.port_b[2].h_outflow;
//   (-hea1.port_a[2].m_flow) + (-hea1.port_b[2].m_flow) = 0.0;
//   hea1.port_a[2].p = hea1.port_b[2].p;
//   hea1.port_a[3].h_outflow = mfr_1[3].port_a.h_outflow;
//   hea1.port_b[3].h_outflow = pipFixRes_1.port_b[3].h_outflow;
//   (-hea1.port_a[3].m_flow) + (-hea1.port_b[3].m_flow) = 0.0;
//   hea1.port_a[3].p = hea1.port_b[3].p;
//   hea2.port_a[1].h_outflow = pipNoRes_1.port_b[1].h_outflow;
//   hea2.port_b[1].h_outflow = mfr_1[1].port_b.h_outflow;
//   (-hea2.port_a[1].m_flow) + (-hea2.port_b[1].m_flow) = 0.0;
//   hea2.port_a[1].p = hea2.port_b[1].p;
//   hea2.port_a[2].h_outflow = pipNoRes_1.port_b[2].h_outflow;
//   hea2.port_b[2].h_outflow = mfr_1[2].port_b.h_outflow;
//   (-hea2.port_a[2].m_flow) + (-hea2.port_b[2].m_flow) = 0.0;
//   hea2.port_a[2].p = hea2.port_b[2].p;
//   hea2.port_a[3].h_outflow = pipNoRes_1.port_b[3].h_outflow;
//   hea2.port_b[3].h_outflow = mfr_1[3].port_b.h_outflow;
//   (-hea2.port_a[3].m_flow) + (-hea2.port_b[3].m_flow) = 0.0;
//   hea2.port_a[3].p = hea2.port_b[3].p;
//   mfr_2[3,4].port_a.m_flow + ducFixRes_2.port_b[3,4].m_flow = 0.0;
//   mfr_2[3,4].port_b.m_flow + ducNoRes_2.port_b[3,4].m_flow = 0.0;
//   mfr_2[3,3].port_a.m_flow + ducFixRes_2.port_b[3,3].m_flow = 0.0;
//   mfr_2[3,3].port_b.m_flow + ducNoRes_2.port_b[3,3].m_flow = 0.0;
//   mfr_2[3,2].port_a.m_flow + ducFixRes_2.port_b[3,2].m_flow = 0.0;
//   mfr_2[3,2].port_b.m_flow + ducNoRes_2.port_b[3,2].m_flow = 0.0;
//   mfr_2[3,1].port_a.m_flow + ducFixRes_2.port_b[3,1].m_flow = 0.0;
//   mfr_2[3,1].port_b.m_flow + ducNoRes_2.port_b[3,1].m_flow = 0.0;
//   mfr_2[2,4].port_a.m_flow + ducFixRes_2.port_b[2,4].m_flow = 0.0;
//   mfr_2[2,4].port_b.m_flow + ducNoRes_2.port_b[2,4].m_flow = 0.0;
//   mfr_2[2,3].port_a.m_flow + ducFixRes_2.port_b[2,3].m_flow = 0.0;
//   mfr_2[2,3].port_b.m_flow + ducNoRes_2.port_b[2,3].m_flow = 0.0;
//   mfr_2[2,2].port_a.m_flow + ducFixRes_2.port_b[2,2].m_flow = 0.0;
//   mfr_2[2,2].port_b.m_flow + ducNoRes_2.port_b[2,2].m_flow = 0.0;
//   mfr_2[2,1].port_a.m_flow + ducFixRes_2.port_b[2,1].m_flow = 0.0;
//   mfr_2[2,1].port_b.m_flow + ducNoRes_2.port_b[2,1].m_flow = 0.0;
//   mfr_2[1,4].port_a.m_flow + ducFixRes_2.port_b[1,4].m_flow = 0.0;
//   mfr_2[1,4].port_b.m_flow + ducNoRes_2.port_b[1,4].m_flow = 0.0;
//   mfr_2[1,3].port_a.m_flow + ducFixRes_2.port_b[1,3].m_flow = 0.0;
//   mfr_2[1,3].port_b.m_flow + ducNoRes_2.port_b[1,3].m_flow = 0.0;
//   mfr_2[1,2].port_a.m_flow + ducFixRes_2.port_b[1,2].m_flow = 0.0;
//   mfr_2[1,2].port_b.m_flow + ducNoRes_2.port_b[1,2].m_flow = 0.0;
//   mfr_2[1,1].port_a.m_flow + ducFixRes_2.port_b[1,1].m_flow = 0.0;
//   mfr_2[1,1].port_b.m_flow + ducNoRes_2.port_b[1,1].m_flow = 0.0;
//   ducFixRes_2.fixRes.port_a.m_flow + (-ducFixRes_2.port_a.m_flow) = 0.0;
//   ducFixRes_2.fixRes.port_b.m_flow + ducFixRes_2.floDis.port_a.m_flow = 0.0;
//   (-ducFixRes_2.port_b[3,4].m_flow) + ducFixRes_2.floDis.port_b[3,4].m_flow = 0.0;
//   (-ducFixRes_2.port_b[3,3].m_flow) + ducFixRes_2.floDis.port_b[3,3].m_flow = 0.0;
//   (-ducFixRes_2.port_b[3,2].m_flow) + ducFixRes_2.floDis.port_b[3,2].m_flow = 0.0;
//   (-ducFixRes_2.port_b[3,1].m_flow) + ducFixRes_2.floDis.port_b[3,1].m_flow = 0.0;
//   (-ducFixRes_2.port_b[2,4].m_flow) + ducFixRes_2.floDis.port_b[2,4].m_flow = 0.0;
//   (-ducFixRes_2.port_b[2,3].m_flow) + ducFixRes_2.floDis.port_b[2,3].m_flow = 0.0;
//   (-ducFixRes_2.port_b[2,2].m_flow) + ducFixRes_2.floDis.port_b[2,2].m_flow = 0.0;
//   (-ducFixRes_2.port_b[2,1].m_flow) + ducFixRes_2.floDis.port_b[2,1].m_flow = 0.0;
//   (-ducFixRes_2.port_b[1,4].m_flow) + ducFixRes_2.floDis.port_b[1,4].m_flow = 0.0;
//   (-ducFixRes_2.port_b[1,3].m_flow) + ducFixRes_2.floDis.port_b[1,3].m_flow = 0.0;
//   (-ducFixRes_2.port_b[1,2].m_flow) + ducFixRes_2.floDis.port_b[1,2].m_flow = 0.0;
//   (-ducFixRes_2.port_b[1,1].m_flow) + ducFixRes_2.floDis.port_b[1,1].m_flow = 0.0;
//   ducFixRes_2.fixRes.port_a.Xi_outflow[1] = ducFixRes_2.port_a.Xi_outflow[1];
//   ducFixRes_2.fixRes.port_a.h_outflow = ducFixRes_2.port_a.h_outflow;
//   ducFixRes_2.fixRes.port_a.p = ducFixRes_2.port_a.p;
//   ducFixRes_2.fixRes.port_b.p = ducFixRes_2.floDis.port_a.p;
//   ducFixRes_2.port_b[1,1].Xi_outflow[1] = ducFixRes_2.floDis.port_b[1,1].Xi_outflow[1];
//   ducFixRes_2.port_b[1,1].h_outflow = ducFixRes_2.floDis.port_b[1,1].h_outflow;
//   ducFixRes_2.floDis.port_b[1,1].p = ducFixRes_2.port_b[1,1].p;
//   ducFixRes_2.port_b[1,2].Xi_outflow[1] = ducFixRes_2.floDis.port_b[1,2].Xi_outflow[1];
//   ducFixRes_2.port_b[1,2].h_outflow = ducFixRes_2.floDis.port_b[1,2].h_outflow;
//   ducFixRes_2.floDis.port_b[1,2].p = ducFixRes_2.port_b[1,2].p;
//   ducFixRes_2.port_b[1,3].Xi_outflow[1] = ducFixRes_2.floDis.port_b[1,3].Xi_outflow[1];
//   ducFixRes_2.port_b[1,3].h_outflow = ducFixRes_2.floDis.port_b[1,3].h_outflow;
//   ducFixRes_2.floDis.port_b[1,3].p = ducFixRes_2.port_b[1,3].p;
//   ducFixRes_2.port_b[1,4].Xi_outflow[1] = ducFixRes_2.floDis.port_b[1,4].Xi_outflow[1];
//   ducFixRes_2.port_b[1,4].h_outflow = ducFixRes_2.floDis.port_b[1,4].h_outflow;
//   ducFixRes_2.floDis.port_b[1,4].p = ducFixRes_2.port_b[1,4].p;
//   ducFixRes_2.port_b[2,1].Xi_outflow[1] = ducFixRes_2.floDis.port_b[2,1].Xi_outflow[1];
//   ducFixRes_2.port_b[2,1].h_outflow = ducFixRes_2.floDis.port_b[2,1].h_outflow;
//   ducFixRes_2.floDis.port_b[2,1].p = ducFixRes_2.port_b[2,1].p;
//   ducFixRes_2.port_b[2,2].Xi_outflow[1] = ducFixRes_2.floDis.port_b[2,2].Xi_outflow[1];
//   ducFixRes_2.port_b[2,2].h_outflow = ducFixRes_2.floDis.port_b[2,2].h_outflow;
//   ducFixRes_2.floDis.port_b[2,2].p = ducFixRes_2.port_b[2,2].p;
//   ducFixRes_2.port_b[2,3].Xi_outflow[1] = ducFixRes_2.floDis.port_b[2,3].Xi_outflow[1];
//   ducFixRes_2.port_b[2,3].h_outflow = ducFixRes_2.floDis.port_b[2,3].h_outflow;
//   ducFixRes_2.floDis.port_b[2,3].p = ducFixRes_2.port_b[2,3].p;
//   ducFixRes_2.port_b[2,4].Xi_outflow[1] = ducFixRes_2.floDis.port_b[2,4].Xi_outflow[1];
//   ducFixRes_2.port_b[2,4].h_outflow = ducFixRes_2.floDis.port_b[2,4].h_outflow;
//   ducFixRes_2.floDis.port_b[2,4].p = ducFixRes_2.port_b[2,4].p;
//   ducFixRes_2.port_b[3,1].Xi_outflow[1] = ducFixRes_2.floDis.port_b[3,1].Xi_outflow[1];
//   ducFixRes_2.port_b[3,1].h_outflow = ducFixRes_2.floDis.port_b[3,1].h_outflow;
//   ducFixRes_2.floDis.port_b[3,1].p = ducFixRes_2.port_b[3,1].p;
//   ducFixRes_2.port_b[3,2].Xi_outflow[1] = ducFixRes_2.floDis.port_b[3,2].Xi_outflow[1];
//   ducFixRes_2.port_b[3,2].h_outflow = ducFixRes_2.floDis.port_b[3,2].h_outflow;
//   ducFixRes_2.floDis.port_b[3,2].p = ducFixRes_2.port_b[3,2].p;
//   ducFixRes_2.port_b[3,3].Xi_outflow[1] = ducFixRes_2.floDis.port_b[3,3].Xi_outflow[1];
//   ducFixRes_2.port_b[3,3].h_outflow = ducFixRes_2.floDis.port_b[3,3].h_outflow;
//   ducFixRes_2.floDis.port_b[3,3].p = ducFixRes_2.port_b[3,3].p;
//   ducFixRes_2.port_b[3,4].Xi_outflow[1] = ducFixRes_2.floDis.port_b[3,4].Xi_outflow[1];
//   ducFixRes_2.port_b[3,4].h_outflow = ducFixRes_2.floDis.port_b[3,4].h_outflow;
//   ducFixRes_2.floDis.port_b[3,4].p = ducFixRes_2.port_b[3,4].p;
//   ducNoRes_2.port_b[1,1].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[1,2].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[1,3].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[1,4].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[2,1].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[2,2].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[2,3].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[2,4].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[3,1].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[3,2].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[3,3].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[3,4].Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_a.Xi_outflow[1] = ($OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.Xi_outflow[1] + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.Xi_outflow[1]) / ($OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[1,1].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[1,2].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[1,3].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[1,4].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[2,1].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[2,2].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[2,3].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[2,4].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[3,1].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[3,2].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[3,3].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_b[3,4].h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) * res_2.port_a.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_a.m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   ducNoRes_2.port_a.h_outflow = ($OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) * mfr_2[3,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) * mfr_2[3,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) * mfr_2[3,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) * mfr_2[3,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) * mfr_2[2,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) * mfr_2[2,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) * mfr_2[2,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) * mfr_2[2,1].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) * mfr_2[1,4].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) * mfr_2[1,3].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) * mfr_2[1,2].port_b.h_outflow + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07) * mfr_2[1,1].port_b.h_outflow) / ($OMC$PositiveMax(ducNoRes_2.port_b[3,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[3,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[2,1].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,4].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,3].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,2].m_flow, 1e-07) + $OMC$PositiveMax(ducNoRes_2.port_b[1,1].m_flow, 1e-07)) " equation generated by stream handling";
//   (-ducNoRes_2.port_a.m_flow) + (-ducNoRes_2.port_b[3,4].m_flow) + (-ducNoRes_2.port_b[3,3].m_flow) + (-ducNoRes_2.port_b[3,2].m_flow) + (-ducNoRes_2.port_b[3,1].m_flow) + (-ducNoRes_2.port_b[2,4].m_flow) + (-ducNoRes_2.port_b[2,3].m_flow) + (-ducNoRes_2.port_b[2,2].m_flow) + (-ducNoRes_2.port_b[2,1].m_flow) + (-ducNoRes_2.port_b[1,4].m_flow) + (-ducNoRes_2.port_b[1,3].m_flow) + (-ducNoRes_2.port_b[1,2].m_flow) + (-ducNoRes_2.port_b[1,1].m_flow) = 0.0;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[1,1].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[1,2].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[1,3].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[1,4].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[2,1].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[2,2].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[2,3].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[2,4].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[3,1].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[3,2].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[3,3].p;
//   ducNoRes_2.port_a.p = ducNoRes_2.port_b[3,4].p;
//   TDb.y = sou_1.T_in;
//   TDb.y = sou_2.T_in;
//   P.y = sou_1.p_in;
//   pipNoRes_1.port_a.p = res_1.port_a.p;
//   ducNoRes_2.port_a.p = res_2.port_a.p;
//   hea1.port_a[1].p = pipFixRes_1.port_b[1].p;
//   hea1.port_a[2].p = pipFixRes_1.port_b[2].p;
//   hea1.port_a[3].p = pipFixRes_1.port_b[3].p;
//   hea1.port_b[1].p = mfr_1[1].port_a.p;
//   hea1.port_b[2].p = mfr_1[2].port_a.p;
//   hea1.port_b[3].p = mfr_1[3].port_a.p;
//   hea2.port_a[1].p = mfr_1[1].port_b.p;
//   hea2.port_a[2].p = mfr_1[2].port_b.p;
//   hea2.port_a[3].p = mfr_1[3].port_b.p;
//   hea2.port_b[1].p = pipNoRes_1.port_b[1].p;
//   hea2.port_b[2].p = pipNoRes_1.port_b[2].p;
//   hea2.port_b[3].p = pipNoRes_1.port_b[3].p;
//   ducFixRes_2.port_b[1,1].p = mfr_2[1,1].port_a.p;
//   ducFixRes_2.port_b[1,2].p = mfr_2[1,2].port_a.p;
//   ducFixRes_2.port_b[1,3].p = mfr_2[1,3].port_a.p;
//   ducFixRes_2.port_b[1,4].p = mfr_2[1,4].port_a.p;
//   ducFixRes_2.port_b[2,1].p = mfr_2[2,1].port_a.p;
//   ducFixRes_2.port_b[2,2].p = mfr_2[2,2].port_a.p;
//   ducFixRes_2.port_b[2,3].p = mfr_2[2,3].port_a.p;
//   ducFixRes_2.port_b[2,4].p = mfr_2[2,4].port_a.p;
//   ducFixRes_2.port_b[3,1].p = mfr_2[3,1].port_a.p;
//   ducFixRes_2.port_b[3,2].p = mfr_2[3,2].port_a.p;
//   ducFixRes_2.port_b[3,3].p = mfr_2[3,3].port_a.p;
//   ducFixRes_2.port_b[3,4].p = mfr_2[3,4].port_a.p;
//   ducNoRes_2.port_b[1,1].p = mfr_2[1,1].port_b.p;
//   ducNoRes_2.port_b[1,2].p = mfr_2[1,2].port_b.p;
//   ducNoRes_2.port_b[1,3].p = mfr_2[1,3].port_b.p;
//   ducNoRes_2.port_b[1,4].p = mfr_2[1,4].port_b.p;
//   ducNoRes_2.port_b[2,1].p = mfr_2[2,1].port_b.p;
//   ducNoRes_2.port_b[2,2].p = mfr_2[2,2].port_b.p;
//   ducNoRes_2.port_b[2,3].p = mfr_2[2,3].port_b.p;
//   ducNoRes_2.port_b[2,4].p = mfr_2[2,4].port_b.p;
//   ducNoRes_2.port_b[3,1].p = mfr_2[3,1].port_b.p;
//   ducNoRes_2.port_b[3,2].p = mfr_2[3,2].port_b.p;
//   ducNoRes_2.port_b[3,3].p = mfr_2[3,3].port_b.p;
//   ducNoRes_2.port_b[3,4].p = mfr_2[3,4].port_b.p;
//   pipFixRes_1.port_a.p = sou_1.ports[1].p;
//   res_1.port_b.p = sin_1.ports[1].p;
//   res_2.port_b.p = sin_2.ports[1].p;
//   P1.y = sou_2.p_in;
//   ducFixRes_2.port_a.p = sou_2.ports[1].p;
// end Manifold;
// endResult
