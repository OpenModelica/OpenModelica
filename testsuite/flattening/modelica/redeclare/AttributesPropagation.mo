// name:     AttributesPropagation.mo
// keywords: tests if attributes are properly propagated from original to redeclared component
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

      package Boreholes
        extends Modelica.Icons.VariantsPackage;

        package BaseClasses
          extends Modelica.Icons.BasesPackage;

          model BoreholeSegment
            extends Buildings.Fluid.Interfaces.PartialFourPortInterface(redeclare final package Medium1 = Medium, redeclare final package Medium2 = Medium, final m1_flow_nominal = m_flow_nominal, final m2_flow_nominal = m_flow_nominal, final m1_flow_small = m_flow_small, final m2_flow_small = m_flow_small, final allowFlowReversal1 = allowFlowReversal, final allowFlowReversal2 = allowFlowReversal);
            extends Buildings.Fluid.Interfaces.TwoPortFlowResistanceParameters;
            extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations(T_start = TFil_start);
            replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
            replaceable parameter Buildings.HeatTransfer.Data.Soil.Generic matSoi annotation(choicesAllMatching = true);
            replaceable parameter Buildings.HeatTransfer.Data.BoreholeFillings.Generic matFil annotation(choicesAllMatching = true);
            parameter Modelica.SIunits.MassFlowRate m_flow_nominal;
            parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * abs(m_flow_nominal);
            parameter Boolean homotopyInitialization = true annotation(Evaluate = true);
            parameter Modelica.SIunits.Radius rTub = 0.02;
            parameter Modelica.SIunits.ThermalConductivity kTub = 0.5;
            parameter Modelica.SIunits.Length eTub = 0.002;
            parameter Modelica.SIunits.Temperature TFil_start = 283.15;
            parameter Modelica.SIunits.Radius rExt = 3;
            parameter Modelica.SIunits.Temperature TExt_start = 283.15;
            parameter Integer nSta(min = 1) = 10;
            parameter Modelica.SIunits.Time samplePeriod = 604800;
            parameter Modelica.SIunits.Radius rBor = 0.1;
            parameter Modelica.SIunits.Height hSeg;
            parameter Modelica.SIunits.Length xC = 0.05;
            parameter Boolean allowFlowReversal = true annotation(Evaluate = true);
            Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.HexInternalElement pipFil(redeclare final package Medium = Medium, final matFil = matFil, final matSoi = matSoi, final hSeg = hSeg, final rTub = rTub, final eTub = eTub, final kTub = kTub, final kSoi = matSoi.k, final xC = xC, final rBor = rBor, final TFil_start = TFil_start, final m1_flow_nominal = m_flow_nominal, final m2_flow_nominal = m_flow_nominal, final dp1_nominal = dp_nominal, final dp2_nominal = 0, final from_dp1 = from_dp, final from_dp2 = from_dp, final linearizeFlowResistance1 = linearizeFlowResistance, final linearizeFlowResistance2 = linearizeFlowResistance, final deltaM1 = deltaM, final deltaM2 = deltaM, final m1_flow_small = m_flow_small, final m2_flow_small = m_flow_small, final allowFlowReversal1 = allowFlowReversal, final allowFlowReversal2 = allowFlowReversal, final homotopyInitialization = homotopyInitialization, final energyDynamics = energyDynamics, final massDynamics = massDynamics, final p1_start = p_start, T1_start = T_start, X1_start = X_start, C1_start = C_start, C1_nominal = C_nominal, final p2_start = p_start, T2_start = T_start, X2_start = X_start, C2_start = C_start, C2_nominal = C_nominal);
            Buildings.HeatTransfer.Conduction.SingleLayerCylinder soi(final material = matSoi, final h = hSeg, final nSta = nSta, final r_a = rBor, final r_b = rExt, final steadyStateInitial = false, final TInt_start = TFil_start, final TExt_start = TExt_start);
            Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.SingleUTubeBoundaryCondition TBouCon(final matSoi = matSoi, final rExt = rExt, final hSeg = hSeg, final TExt_start = TExt_start, final samplePeriod = samplePeriod);
          protected
            Modelica.Thermal.HeatTransfer.Sensors.HeatFlowSensor heaFlo;
          equation
            connect(pipFil.port_b1, port_b1);
            connect(pipFil.port_a2, port_a2);
            connect(pipFil.port_b2, port_b2);
            connect(pipFil.port, heaFlo.port_a);
            connect(heaFlo.port_b, soi.port_a);
            connect(soi.port_b, TBouCon.port);
            connect(port_a1, pipFil.port_a1);
            connect(heaFlo.Q_flow, TBouCon.Q_flow);
          end BoreholeSegment;

          model HexInternalElement
            extends Buildings.Fluid.Interfaces.FourPortHeatMassExchanger(redeclare final package Medium1 = Medium, redeclare final package Medium2 = Medium, T1_start = TFil_start, T2_start = TFil_start, final tau1 = Modelica.Constants.pi * rTub ^ 2 * hSeg * rho1_nominal / m1_flow_nominal, final tau2 = Modelica.Constants.pi * rTub ^ 2 * hSeg * rho2_nominal / m2_flow_nominal, vol1(final energyDynamics = energyDynamics, final massDynamics = massDynamics, final prescribedHeatFlowRate = false, final allowFlowReversal = allowFlowReversal1, final V = m2_flow_nominal * tau2 / rho2_nominal, final m_flow_small = m1_flow_small), final vol2(final energyDynamics = energyDynamics, final massDynamics = massDynamics, final prescribedHeatFlowRate = false, final V = m1_flow_nominal * tau1 / rho1_nominal, final m_flow_small = m2_flow_small));
            replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
            replaceable parameter Buildings.HeatTransfer.Data.BoreholeFillings.Generic matFil annotation(choicesAllMatching = true);
            replaceable parameter Buildings.HeatTransfer.Data.Soil.Generic matSoi annotation(choicesAllMatching = true);
            parameter Modelica.SIunits.Radius rTub = 0.02;
            parameter Modelica.SIunits.ThermalConductivity kTub = 0.5;
            parameter Modelica.SIunits.Length eTub = 0.002;
            parameter Modelica.SIunits.ThermalConductivity kSoi;
            parameter Modelica.SIunits.Temperature TFil_start = 283.15;
            parameter Modelica.SIunits.Height hSeg;
            parameter Modelica.SIunits.Radius rBor;
            parameter Modelica.SIunits.Length xC = 0.05;
            Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port;
            Modelica.Thermal.HeatTransfer.Components.HeatCapacitor capFil1(final C = Co_fil / 2, T(final start = TFil_start, fixed = energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial), der_T(fixed = energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial));
            Modelica.Thermal.HeatTransfer.Components.HeatCapacitor capFil2(final C = Co_fil / 2, T(final start = TFil_start, fixed = energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial), der_T(fixed = energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial));
          protected
            final parameter Modelica.SIunits.SpecificHeatCapacity cpFil = matFil.c;
            final parameter Modelica.SIunits.ThermalConductivity kFil = matFil.k;
            final parameter Modelica.SIunits.Density dFil = matFil.d;
            parameter Modelica.SIunits.HeatCapacity Co_fil = dFil * cpFil * hSeg * Modelica.Constants.pi * (rBor ^ 2 - 2 * (rTub + eTub) ^ 2);
            parameter Modelica.SIunits.SpecificHeatCapacity cpMed = Medium.specificHeatCapacityCp(Medium.setState_pTX(Medium.p_default, Medium.T_default, Medium.X_default));
            parameter Modelica.SIunits.ThermalConductivity kMed = Medium.thermalConductivity(Medium.setState_pTX(Medium.p_default, Medium.T_default, Medium.X_default));
            parameter Modelica.SIunits.DynamicViscosity mueMed = Medium.dynamicViscosity(Medium.setState_pTX(Medium.p_default, Medium.T_default, Medium.X_default));
            parameter Modelica.SIunits.ThermalResistance Rgb_val(fixed = false);
            parameter Modelica.SIunits.ThermalResistance Rgg_val(fixed = false);
            parameter Modelica.SIunits.ThermalResistance RCondGro_val(fixed = false);
            parameter Real x(fixed = false);
            Modelica.Thermal.HeatTransfer.Components.ConvectiveResistor RConv1;
            Modelica.Thermal.HeatTransfer.Components.ConvectiveResistor RConv2;
            Modelica.Thermal.HeatTransfer.Components.ThermalResistor Rpg1(final R = RCondGro_val);
            Modelica.Thermal.HeatTransfer.Components.ThermalResistor Rpg2(final R = RCondGro_val);
            Modelica.Thermal.HeatTransfer.Components.ThermalResistor Rgb1(final R = Rgb_val);
            Modelica.Thermal.HeatTransfer.Components.ThermalResistor Rgb2(final R = Rgb_val);
            Modelica.Thermal.HeatTransfer.Components.ThermalResistor Rgg(final R = Rgg_val);
            Modelica.Blocks.Sources.RealExpression RVol1(y = convectionResistance(hSeg = hSeg, rTub = rTub, kMed = kMed, mueMed = mueMed, cpMed = cpMed, m_flow = m1_flow, m_flow_nominal = m1_flow_nominal));
            Modelica.Blocks.Sources.RealExpression RVol2(y = convectionResistance(hSeg = hSeg, rTub = rTub, kMed = kMed, mueMed = mueMed, cpMed = cpMed, m_flow = m2_flow, m_flow_nominal = m2_flow_nominal));
          initial equation
            (Rgb_val, Rgg_val, RCondGro_val, x) = singleUTubeResistances(hSeg = hSeg, rBor = rBor, rTub = rTub, eTub = eTub, xC = xC, kSoi = matSoi.k, kFil = matFil.k, kTub = kTub);
          equation
            connect(vol1.heatPort, RConv1.fluid);
            connect(RConv1.solid, Rpg1.port_a);
            connect(Rpg1.port_b, capFil1.port);
            connect(capFil1.port, Rgb1.port_a);
            connect(capFil1.port, Rgg.port_a);
            connect(Rgb1.port_b, port);
            connect(RConv2.solid, Rpg2.port_a);
            connect(Rpg2.port_b, capFil2.port);
            connect(RConv2.fluid, vol2.heatPort);
            connect(capFil2.port, Rgb2.port_a);
            connect(Rgg.port_b, capFil2.port);
            connect(Rgb2.port_b, port);
            connect(RVol1.y, RConv1.Rc);
            connect(RVol2.y, RConv2.Rc);
          end HexInternalElement;

          model SingleUTubeBoundaryCondition
            replaceable parameter Buildings.HeatTransfer.Data.Soil.Generic matSoi annotation(choicesAllMatching = true);
            parameter Modelica.SIunits.Radius rExt = 3;
            parameter Modelica.SIunits.Height hSeg = 10;
            parameter Modelica.SIunits.Temperature TExt_start = 283.15;
            parameter Modelica.SIunits.Time samplePeriod = 604800;
            ExtendableArray table = ExtendableArray();
            Modelica.SIunits.HeatFlowRate QAve_flow;
            Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W");
            Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port;
          protected
            final parameter Modelica.SIunits.SpecificHeatCapacity c = matSoi.c;
            final parameter Modelica.SIunits.ThermalConductivity k = matSoi.k;
            final parameter Modelica.SIunits.Density d = matSoi.d;
            Modelica.SIunits.Energy UOld;
            Modelica.SIunits.Energy U;
            final parameter Modelica.SIunits.Time startTime(fixed = false);
            Integer iSam(min = 1);
          initial algorithm
            U := 0;
            UOld := 0;
            startTime := time;
            iSam := 1;
          equation
            der(U) = Q_flow;
          algorithm
            when initial() or sample(startTime, samplePeriod) then
              QAve_flow := (U - UOld) / samplePeriod;
              UOld := U;
              port.T := TExt_start + Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.temperatureDrop(table = table, iSam = iSam, Q_flow = QAve_flow, samplePeriod = samplePeriod, rExt = rExt, hSeg = hSeg, k = k, d = d, c = c);
              iSam := iSam + 1;
            end when;
          end SingleUTubeBoundaryCondition;

          class ExtendableArray
            extends ExternalObject;

            function constructor
              output ExtendableArray table;
              external "C" table = initArray() annotation(Include = "#include <initArray.c>", IncludeDirectory = "modelica://Buildings/Resources/C-Sources");
            end constructor;

            function destructor
              input ExtendableArray table;
              external "C" freeArray(table) annotation(Include = " #include <freeArray.c>", IncludeDirectory = "modelica://Buildings/Resources/C-Sources");
            end destructor;
          end ExtendableArray;

          function convectionResistance
            input Modelica.SIunits.Height hSeg;
            input Modelica.SIunits.Radius rTub;
            input Modelica.SIunits.ThermalConductivity kMed;
            input Modelica.SIunits.DynamicViscosity mueMed;
            input Modelica.SIunits.SpecificHeatCapacity cpMed;
            input Modelica.SIunits.MassFlowRate m_flow;
            input Modelica.SIunits.MassFlowRate m_flow_nominal;
            output Modelica.SIunits.ThermalResistance R;
          protected
            Modelica.SIunits.CoefficientOfHeatTransfer h;
            Real k(unit = "s/kg");
          algorithm
            k := 2 / (mueMed * Modelica.Constants.pi * rTub);
            h := 0.023 * kMed * (cpMed * mueMed / kMed) ^ 0.35 / (2 * rTub) * Buildings.Utilities.Math.Functions.regNonZeroPower(x = m_flow * k, n = 0.8, delta = 0.01 * m_flow_nominal * k);
            R := 1 / (2 * Modelica.Constants.pi * rTub * hSeg * h);
          end convectionResistance;

          function exchangeValues
            input ExtendableArray table;
            input Integer iX;
            input Real x;
            input Integer iY;
            output Real y;
            external "C" y = exchangeValues(table, iX, x, iY) annotation(Include = "#include <exchangeValues.c>", IncludeDirectory = "modelica://Buildings/Resources/C-Sources");
          end exchangeValues;

          function factorial
            input Integer j;
            output Integer f;
          algorithm
            f := 1;
            for i in 1:j loop
              f := f * i;
            end for;
          end factorial;

          function powerSeries
            input Real u;
            input Integer N;
            output Real W;
          algorithm
            W := (-0.5772) - Modelica.Math.log(u) + sum((-1) ^ (j + 1) * u ^ j / (j * factorial(j)) for j in 1:N);
          end powerSeries;

          function temperatureDrop
            input ExtendableArray table;
            input Integer iSam(min = 1);
            input Modelica.SIunits.HeatFlowRate Q_flow;
            input Modelica.SIunits.Time samplePeriod;
            input Modelica.SIunits.Radius rExt;
            input Modelica.SIunits.Height hSeg;
            input Modelica.SIunits.ThermalConductivity k;
            input Modelica.SIunits.Density d;
            input Modelica.SIunits.SpecificHeatCapacity c;
            output Modelica.SIunits.TemperatureDifference dT;
          protected
            Modelica.SIunits.Time minSamplePeriod = rExt ^ 2 / (4 * (k / c / d) * 3.8);
            Modelica.SIunits.HeatFlowRate QL_flow;
            Modelica.SIunits.HeatFlowRate QU_flow;
          algorithm
            assert(rExt * rExt / (4 * (k / c / d) * samplePeriod) <= 3.8, "The samplePeriod has to be bigger than " + String(minSamplePeriod) + " for convergence purpose.
              samplePeriod = " + String(samplePeriod));
            if iSam == 1 then
              dT := 0;
              QL_flow := Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues(table = table, iX = iSam, x = Q_flow, iY = iSam);
            else
              dT := 0;
              for i in 1:iSam - 1 loop
                QL_flow := Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues(table = table, iX = iSam, x = Q_flow, iY = iSam + 1 - i);
                QU_flow := Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues(table = table, iX = iSam, x = Q_flow, iY = iSam - i);
                dT := dT + 1 / (4 * Modelica.Constants.pi * k) * Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.powerSeries(u = c * d / (4 * k * i * samplePeriod) * rExt ^ 2, N = 10) * (QL_flow - QU_flow) / hSeg;
              end for;
            end if;
          end temperatureDrop;

          function singleUTubeResistances
            input Modelica.SIunits.Height hSeg;
            input Modelica.SIunits.Radius rBor;
            input Modelica.SIunits.Radius rTub;
            input Modelica.SIunits.Length eTub;
            input Modelica.SIunits.Length xC;
            input Modelica.SIunits.ThermalConductivity kSoi;
            input Modelica.SIunits.ThermalConductivity kFil;
            input Modelica.SIunits.ThermalConductivity kTub;
            output Modelica.SIunits.ThermalResistance Rgb;
            output Modelica.SIunits.ThermalResistance Rgg;
            output Modelica.SIunits.ThermalResistance RCondGro;
            output Real x;
          protected
            Boolean test = false;
            Modelica.SIunits.ThermalResistance Rg;
            Modelica.SIunits.ThermalResistance Rar;
            Modelica.SIunits.ThermalResistance RCondPipe;
            Real Rb;
            Real Ra;
            Real sigma;
            Real beta;
            Real R_1delta_LS;
            Real R_1delta_MP;
            Real Ra_LS;
            Integer i = 1;
          algorithm
            RCondPipe := Modelica.Math.log((rTub + eTub) / rTub) / (2 * Modelica.Constants.pi * hSeg * kTub);
            sigma := (kFil - kSoi) / (kFil + kSoi);
            R_1delta_LS := 1 / (2 * Modelica.Constants.pi * kFil) * (log(rBor / (rTub + eTub)) + log(rBor / (2 * xC)) + sigma * log(rBor ^ 4 / (rBor ^ 4 - xC ^ 4)));
            R_1delta_MP := R_1delta_LS - 1 / (2 * Modelica.Constants.pi * kFil) * ((rTub + eTub) ^ 2 / (4 * xC ^ 2) * (1 - sigma * 4 * xC ^ 4 / (rBor ^ 4 - xC ^ 4)) ^ 2) / ((1 + beta) / (1 - beta) + (rTub + eTub) ^ 2 / (4 * xC ^ 2) * (1 + sigma * 16 * xC ^ 4 * rBor ^ 4 / (rBor ^ 4 - xC ^ 4) ^ 2));
            Ra_LS := 1 / (Modelica.Constants.pi * kFil) * (log(2 * xC / rTub) + sigma * log((rBor ^ 2 + xC ^ 2) / (rBor ^ 2 - xC ^ 2)));
            beta := 2 * Modelica.Constants.pi * kFil * RCondPipe;
            Rb := R_1delta_MP / 2;
            Ra := Ra_LS - 1 / (Modelica.Constants.pi * kFil) * (rTub ^ 2 / (4 * xC ^ 2) * (1 + sigma * 4 * rBor ^ 4 * xC ^ 2 / (rBor ^ 4 - xC ^ 4)) / ((1 + beta) / (1 - beta) - rTub ^ 2 / (4 * xC ^ 2) + sigma * 2 * rTub ^ 2 * rBor ^ 2 * (rBor ^ 4 + xC ^ 4) / (rBor ^ 4 - xC ^ 4) ^ 2));
            Rg := 2 * Rb / hSeg;
            Rar := Ra / hSeg;
            while test == false and i <= 15 loop
              x := Modelica.Math.log(sqrt(rBor ^ 2 + 2 * (rTub + eTub) ^ 2) / (2 * (rTub + eTub))) / Modelica.Math.log(rBor / (sqrt(2) * (rTub + eTub))) * ((15 - i + 1) / 15);
              Rgb := (1 - x) * Rg;
              Rgg := 2 * Rgb * (Rar - 2 * x * Rg) / (2 * Rgb - Rar + 2 * x * Rg);
              test := 1 / Rgg + 1 / 2 / Rgb > 0;
              i := i + 1;
            end while;
            assert(test, "Maximum number of iterations exceeded. Check the borehole geometry.
              The tubes may be too close to the borehole wall.
              Input to the function
              Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.singleUTubeResistances
              is
                       hSeg = " + String(hSeg) + " m
                       rBor = " + String(rBor) + " m
                       rTub = " + String(rTub) + " m
                       eTub = " + String(eTub) + " m
                       xC   = " + String(xC) + " m
                       kSoi = " + String(kSoi) + " W/m/K
                       kFil = " + String(kFil) + " W/m/K
                       kTub = " + String(kTub) + " W/m/K
              Computed x    = " + String(x) + " K/W
                       Rgb  = " + String(Rgb) + " K/W
                       Rgg  = " + String(Rgg) + " K/W");
            RCondGro := x * Rg + RCondPipe;
          end singleUTubeResistances;

          package Examples
            extends Modelica.Icons.ExamplesPackage;

            model BoreholeSegment
              extends Modelica.Icons.Example;
              inner Modelica.Fluid.System system;
              package Medium = Buildings.Media.ConstantPropertyLiquidWater;
              parameter Buildings.HeatTransfer.Data.BoreholeFillings.Bentonite bento;
              Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.BoreholeSegment seg(redeclare package Medium = Medium, matFil = bento, m_flow_nominal = 0.2, dp_nominal = 5, rTub = 0.02, eTub = 0.002, rBor = 0.1, rExt = 3, nSta = 9, samplePeriod = 604800, kTub = 0.5, hSeg = 10, xC = 0.05, redeclare Buildings.HeatTransfer.Data.Soil.Concrete matSoi, energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial, TFil_start = 283.15, TExt_start = 283.15);
              Fluid.Sources.Boundary_pT sou_1(redeclare package Medium = Medium, nPorts = 1, use_T_in = false, p = 101340, T = 303.15);
              Fluid.Sources.Boundary_pT sin_2(redeclare package Medium = Medium, use_p_in = false, use_T_in = false, nPorts = 1, p = 101330, T = 283.15);
            equation
              connect(sou_1.ports[1], seg.port_a1);
              connect(seg.port_b1, seg.port_a2);
              connect(seg.port_b2, sin_2.ports[1]);
            end BoreholeSegment;
          end Examples;
        end BaseClasses;
      end Boreholes;
    end HeatExchangers;

    package MixingVolumes
      extends Modelica.Icons.VariantsPackage;

      model MixingVolume
        extends Buildings.Fluid.MixingVolumes.BaseClasses.PartialMixingVolume;
      protected
        Modelica.Blocks.Sources.Constant masExc(k = 0);
      equation
        connect(masExc.y, dynBal.mWat_flow);
        connect(masExc.y, steBal.mWat_flow);
        connect(QSen_flow.y, steBal.Q_flow);
        connect(QSen_flow.y, dynBal.Q_flow);
      end MixingVolume;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        partial model PartialMixingVolume
          outer Modelica.Fluid.System system;
          extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
          parameter Modelica.SIunits.MassFlowRate m_flow_nominal(min = 0);
          parameter Integer nPorts = 0 annotation(Evaluate = true);
          parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * abs(m_flow_nominal);
          parameter Boolean allowFlowReversal = system.allowFlowReversal annotation(Evaluate = true);
          parameter Modelica.SIunits.Volume V;
          parameter Boolean prescribedHeatFlowRate = false annotation(Evaluate = true);
          parameter Boolean initialize_p = not Medium.singleState;
          Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b[nPorts] ports(redeclare each package Medium = Medium);
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort;
          Modelica.SIunits.Temperature T;
          Modelica.SIunits.Pressure p;
          Modelica.SIunits.MassFraction[Medium.nXi] Xi;
          Medium.ExtraProperty[Medium.nC] C(nominal = C_nominal);
        protected
          Buildings.Fluid.Interfaces.StaticTwoPortConservationEquation steBal(sensibleOnly = true, redeclare final package Medium = Medium, final m_flow_nominal = m_flow_nominal, final allowFlowReversal = allowFlowReversal, final m_flow_small = m_flow_small) if useSteadyStateTwoPort;
          Buildings.Fluid.Interfaces.ConservationEquation dynBal(redeclare final package Medium = Medium, final energyDynamics = energyDynamics, final massDynamics = massDynamics, final p_start = p_start, final T_start = T_start, final X_start = X_start, final C_start = C_start, final C_nominal = C_nominal, final fluidVolume = V, final initialize_p = initialize_p, m(start = V * rho_start), U(start = V * rho_start * Medium.specificInternalEnergy(state_start)), nPorts = nPorts) if not useSteadyStateTwoPort;
          parameter Modelica.SIunits.Density rho_default = Medium.density(state = state_default);
          parameter Modelica.SIunits.Density rho_start = Medium.density(state = state_start);
          final parameter Medium.ThermodynamicState state_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default[1:Medium.nXi]);
          final parameter Medium.ThermodynamicState state_start = Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi]);
          final parameter Boolean useSteadyStateTwoPort = nPorts == 2 and prescribedHeatFlowRate and energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.RealOutput hOut_internal(unit = "J/kg");
          Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut_internal(each unit = "1");
          Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut_internal(each unit = "1");
          Modelica.Blocks.Sources.RealExpression QSen_flow(y = heatPort.Q_flow);
        equation
          if not allowFlowReversal then
            assert(ports[1].m_flow > (-m_flow_small), "Model has flow reversal, but the parameter allowFlowReversal is set to false.
              m_flow_small    = " + String(m_flow_small) + "
              ports[1].m_flow = " + String(ports[1].m_flow) + "
            ");
          end if;
          if useSteadyStateTwoPort then
            connect(steBal.port_a, ports[1]);
            connect(steBal.port_b, ports[2]);
            connect(hOut_internal, steBal.hOut);
            connect(XiOut_internal, steBal.XiOut);
            connect(COut_internal, steBal.COut);
          else
            connect(dynBal.ports, ports);
            connect(hOut_internal, dynBal.hOut);
            connect(XiOut_internal, dynBal.XiOut);
            connect(COut_internal, dynBal.COut);
          end if;
          p = if nPorts > 0 then ports[1].p else p_start;
          T = Medium.temperature_phX(p = p, h = hOut_internal, X = cat(1, Xi, {1 - sum(Xi)}));
          Xi = XiOut_internal;
          C = COut_internal;
          heatPort.T = T;
        end PartialMixingVolume;
      end BaseClasses;
    end MixingVolumes;

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

      model ConservationEquation
        extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
        parameter Integer nPorts = 0 annotation(Evaluate = true);
        parameter Boolean initialize_p = not Medium.singleState;
        Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b[nPorts] ports(redeclare each package Medium = Medium);
        Medium.BaseProperties medium(preferredMediumStates = not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState, p(start = p_start, nominal = Medium.p_default, stateSelect = if not massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then StateSelect.prefer else StateSelect.default), h(start = hStart), T(start = T_start, nominal = Medium.T_default, stateSelect = if not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then StateSelect.prefer else StateSelect.default), Xi(start = X_start[1:Medium.nXi], nominal = Medium.X_default[1:Medium.nXi], each stateSelect = if not substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then StateSelect.prefer else StateSelect.default), d(start = rho_nominal));
        Modelica.SIunits.Energy U;
        Modelica.SIunits.Mass m;
        Modelica.SIunits.Mass[Medium.nXi] mXi;
        Modelica.SIunits.Mass[Medium.nC] mC;
        Medium.ExtraProperty[Medium.nC] C(nominal = C_nominal);
        Modelica.SIunits.MassFlowRate mb_flow;
        Modelica.SIunits.MassFlowRate[Medium.nXi] mbXi_flow;
        Medium.ExtraPropertyFlowRate[Medium.nC] mbC_flow;
        Modelica.SIunits.EnthalpyFlowRate Hb_flow;
        input Modelica.SIunits.Volume fluidVolume;
        Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W");
        Modelica.Blocks.Interfaces.RealInput mWat_flow(unit = "kg/s");
        Modelica.Blocks.Interfaces.RealOutput hOut(unit = "J/kg", start = hStart);
        Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut(each unit = "1", each min = 0, each max = 1);
        Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut(each min = 0);
      protected
        Medium.EnthalpyFlowRate[nPorts] ports_H_flow;
        Modelica.SIunits.MassFlowRate[nPorts, Medium.nXi] ports_mXi_flow;
        Medium.ExtraPropertyFlowRate[nPorts, Medium.nC] ports_mC_flow;
        parameter Modelica.SIunits.Density rho_nominal = Medium.density(Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi]));
        final parameter Real[Medium.nXi] s = array(if Modelica.Utilities.Strings.isEqual(string1 = Medium.substanceNames[i], string2 = "Water", caseSensitive = false) then 1 else 0 for i in 1:Medium.nXi);
        parameter Modelica.SIunits.SpecificEnthalpy hStart = Medium.specificEnthalpy_pTX(p_start, T_start, X_start);
      initial equation
        assert(Medium.nXi == 0 or abs(sum(s) - 1) < 1e-5, "If Medium.nXi > 1, then substance 'water' must be present for one component.'" + Medium.mediumName + "'.\n" + "Check medium model.");
        if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          assert(massDynamics == energyDynamics, "
                   If 'massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState', then it is
                   required that 'energyDynamics==Modelica.Fluid.Types.Dynamics.SteadyState'.
                   Otherwise, the system of equations may not be consistent.
                   You need to select other parameter values.");
        end if;
        if energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
          medium.T = T_start;
        else
          if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
            der(medium.T) = 0;
          end if;
        end if;
        if massDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
          if initialize_p then
            medium.p = p_start;
          end if;
        else
          if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
            if initialize_p then
              der(medium.p) = 0;
            end if;
          end if;
        end if;
        if substanceDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
          medium.Xi = X_start[1:Medium.nXi];
        else
          if substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
            der(medium.Xi) = zeros(Medium.nXi);
          end if;
        end if;
        if traceDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
          C = C_start[1:Medium.nC];
        else
          if traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
            der(C) = zeros(Medium.nC);
          end if;
        end if;
      equation
        m = fluidVolume * medium.d;
        mXi = m * medium.Xi;
        U = m * medium.u;
        mC = m * C;
        hOut = medium.h;
        XiOut = medium.Xi;
        COut = C;
        for i in 1:nPorts loop
          ports_H_flow[i] = ports[i].m_flow * actualStream(ports[i].h_outflow);
          ports_mXi_flow[i, :] = ports[i].m_flow * actualStream(ports[i].Xi_outflow);
          ports_mC_flow[i, :] = ports[i].m_flow * actualStream(ports[i].C_outflow);
        end for;
        for i in 1:Medium.nXi loop
          mbXi_flow[i] = sum(ports_mXi_flow[:, i]);
        end for;
        for i in 1:Medium.nC loop
          mbC_flow[i] = sum(ports_mC_flow[:, i]);
        end for;
        mb_flow = sum(ports.m_flow);
        Hb_flow = sum(ports_H_flow);
        if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          0 = Hb_flow + Q_flow;
        else
          der(U) = Hb_flow + Q_flow;
        end if;
        if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          0 = mb_flow + mWat_flow;
        else
          der(m) = mb_flow + mWat_flow;
        end if;
        if substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          zeros(Medium.nXi) = mbXi_flow + mWat_flow * s;
        else
          der(mXi) = mbXi_flow + mWat_flow * s;
        end if;
        if traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          zeros(Medium.nC) = mbC_flow;
        else
          der(mC) = mbC_flow;
        end if;
        for i in 1:nPorts loop
          ports[i].p = medium.p;
          ports[i].h_outflow = medium.h;
          ports[i].Xi_outflow = medium.Xi;
          ports[i].C_outflow = C;
        end for;
      end ConservationEquation;

      model FourPort
        outer Modelica.Fluid.System system;
        replaceable package Medium1 = Modelica.Media.Interfaces.PartialMedium;
        replaceable package Medium2 = Modelica.Media.Interfaces.PartialMedium;
        parameter Boolean allowFlowReversal1 = system.allowFlowReversal annotation(Evaluate = true);
        parameter Boolean allowFlowReversal2 = system.allowFlowReversal annotation(Evaluate = true);
        parameter Modelica.SIunits.SpecificEnthalpy h_outflow_a1_start = Medium1.h_default;
        parameter Modelica.SIunits.SpecificEnthalpy h_outflow_b1_start = Medium1.h_default;
        parameter Modelica.SIunits.SpecificEnthalpy h_outflow_a2_start = Medium2.h_default;
        parameter Modelica.SIunits.SpecificEnthalpy h_outflow_b2_start = Medium2.h_default;
        Modelica.Fluid.Interfaces.FluidPort_a port_a1(redeclare package Medium = Medium1, m_flow(min = if allowFlowReversal1 then -Modelica.Constants.inf else 0), h_outflow(nominal = 1E5, start = h_outflow_a1_start), Xi_outflow(each nominal = 0.01));
        Modelica.Fluid.Interfaces.FluidPort_b port_b1(redeclare package Medium = Medium1, m_flow(max = if allowFlowReversal1 then +Modelica.Constants.inf else 0), h_outflow(nominal = 1E5, start = h_outflow_b1_start), Xi_outflow(each nominal = 0.01));
        Modelica.Fluid.Interfaces.FluidPort_a port_a2(redeclare package Medium = Medium2, m_flow(min = if allowFlowReversal2 then -Modelica.Constants.inf else 0), h_outflow(nominal = 1E5, start = h_outflow_a2_start), Xi_outflow(each nominal = 0.01));
        Modelica.Fluid.Interfaces.FluidPort_b port_b2(redeclare package Medium = Medium2, m_flow(max = if allowFlowReversal2 then +Modelica.Constants.inf else 0), h_outflow(nominal = 1E5, start = h_outflow_b2_start), Xi_outflow(each nominal = 0.01));
      end FourPort;

      record FourPortFlowResistanceParameters
        parameter Boolean computeFlowResistance1 = true annotation(Evaluate = true);
        parameter Boolean from_dp1 = false annotation(Evaluate = true);
        parameter Modelica.SIunits.Pressure dp1_nominal(min = 0, displayUnit = "Pa");
        parameter Boolean linearizeFlowResistance1 = false;
        parameter Real deltaM1 = 0.1;
        parameter Boolean computeFlowResistance2 = true annotation(Evaluate = true);
        parameter Boolean from_dp2 = false annotation(Evaluate = true);
        parameter Modelica.SIunits.Pressure dp2_nominal(min = 0, displayUnit = "Pa");
        parameter Boolean linearizeFlowResistance2 = false;
        parameter Real deltaM2 = 0.1;
      end FourPortFlowResistanceParameters;

      model FourPortHeatMassExchanger
        extends Buildings.Fluid.Interfaces.PartialFourPortInterface(final h_outflow_a1_start = h1_outflow_start, final h_outflow_b1_start = h1_outflow_start, final h_outflow_a2_start = h2_outflow_start, final h_outflow_b2_start = h2_outflow_start);
        extends Buildings.Fluid.Interfaces.FourPortFlowResistanceParameters(final computeFlowResistance1 = true, final computeFlowResistance2 = true);
        parameter Modelica.SIunits.Time tau1 = 30;
        parameter Modelica.SIunits.Time tau2 = 30;
        parameter Boolean homotopyInitialization = true annotation(Evaluate = true);
        parameter Modelica.Fluid.Types.Dynamics energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial annotation(Evaluate = true);
        parameter Modelica.Fluid.Types.Dynamics massDynamics = energyDynamics annotation(Evaluate = true);
        parameter Medium1.AbsolutePressure p1_start = Medium1.p_default;
        parameter Medium1.Temperature T1_start = Medium1.T_default;
        parameter Medium1.MassFraction[Medium1.nX] X1_start = Medium1.X_default;
        parameter Medium1.ExtraProperty[Medium1.nC] C1_start(quantity = Medium1.extraPropertiesNames) = fill(0, Medium1.nC);
        parameter Medium1.ExtraProperty[Medium1.nC] C1_nominal(quantity = Medium1.extraPropertiesNames) = fill(1E-2, Medium1.nC);
        parameter Medium2.AbsolutePressure p2_start = Medium2.p_default;
        parameter Medium2.Temperature T2_start = Medium2.T_default;
        parameter Medium2.MassFraction[Medium2.nX] X2_start = Medium2.X_default;
        parameter Medium2.ExtraProperty[Medium2.nC] C2_start(quantity = Medium2.extraPropertiesNames) = fill(0, Medium2.nC);
        parameter Medium2.ExtraProperty[Medium2.nC] C2_nominal(quantity = Medium2.extraPropertiesNames) = fill(1E-2, Medium2.nC);
        Buildings.Fluid.MixingVolumes.MixingVolume vol1(redeclare final package Medium = Medium1, nPorts = 2, V = m1_flow_nominal * tau1 / rho1_nominal, final m_flow_nominal = m1_flow_nominal, energyDynamics = if tau1 > Modelica.Constants.eps then energyDynamics else Modelica.Fluid.Types.Dynamics.SteadyState, massDynamics = if tau1 > Modelica.Constants.eps then massDynamics else Modelica.Fluid.Types.Dynamics.SteadyState, final p_start = p1_start, final T_start = T1_start, final X_start = X1_start, final C_start = C1_start, final C_nominal = C1_nominal);
        replaceable Buildings.Fluid.MixingVolumes.MixingVolume vol2 constrainedby Buildings.Fluid.MixingVolumes.BaseClasses.PartialMixingVolume(redeclare final package Medium = Medium2, nPorts = 2, V = m2_flow_nominal * tau2 / rho2_nominal, final m_flow_nominal = m2_flow_nominal, energyDynamics = if tau2 > Modelica.Constants.eps then energyDynamics else Modelica.Fluid.Types.Dynamics.SteadyState, massDynamics = if tau2 > Modelica.Constants.eps then massDynamics else Modelica.Fluid.Types.Dynamics.SteadyState, final p_start = p2_start, final T_start = T2_start, final X_start = X2_start, final C_start = C2_start, final C_nominal = C2_nominal);
        Modelica.SIunits.HeatFlowRate Q1_flow = vol1.heatPort.Q_flow;
        Modelica.SIunits.HeatFlowRate Q2_flow = vol2.heatPort.Q_flow;
        Buildings.Fluid.FixedResistances.FixedResistanceDpM preDro1(redeclare package Medium = Medium1, final use_dh = false, final m_flow_nominal = m1_flow_nominal, final deltaM = deltaM1, final allowFlowReversal = allowFlowReversal1, final show_T = false, final from_dp = from_dp1, final linearized = linearizeFlowResistance1, final homotopyInitialization = homotopyInitialization, final dp_nominal = dp1_nominal, final dh = 1, final ReC = 4000);
        Buildings.Fluid.FixedResistances.FixedResistanceDpM preDro2(redeclare package Medium = Medium2, final use_dh = false, final m_flow_nominal = m2_flow_nominal, final deltaM = deltaM2, final allowFlowReversal = allowFlowReversal2, final show_T = false, final from_dp = from_dp2, final linearized = linearizeFlowResistance2, final homotopyInitialization = homotopyInitialization, final dp_nominal = dp2_nominal, final dh = 1, final ReC = 4000);
      protected
        parameter Medium1.ThermodynamicState sta1_nominal = Medium1.setState_pTX(T = Medium1.T_default, p = Medium1.p_default, X = Medium1.X_default);
        parameter Modelica.SIunits.Density rho1_nominal = Medium1.density(sta1_nominal);
        parameter Medium2.ThermodynamicState sta2_nominal = Medium2.setState_pTX(T = Medium2.T_default, p = Medium2.p_default, X = Medium2.X_default);
        parameter Modelica.SIunits.Density rho2_nominal = Medium2.density(sta2_nominal);
        parameter Medium1.ThermodynamicState sta1_start = Medium1.setState_pTX(T = T1_start, p = p1_start, X = X1_start);
        parameter Modelica.SIunits.SpecificEnthalpy h1_outflow_start = Medium1.specificEnthalpy(sta1_start);
        parameter Medium2.ThermodynamicState sta2_start = Medium2.setState_pTX(T = T2_start, p = p2_start, X = X2_start);
        parameter Modelica.SIunits.SpecificEnthalpy h2_outflow_start = Medium2.specificEnthalpy(sta2_start);
      initial algorithm
        assert(energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState or tau1 > Modelica.Constants.eps, "The parameter tau1, or the volume of the model from which tau may be derived, is unreasonably small.
         You need to set energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState to model steady-state.
         Received tau1 = " + String(tau1) + "\n");
        assert(massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState or tau1 > Modelica.Constants.eps, "The parameter tau1, or the volume of the model from which tau may be derived, is unreasonably small.
         You need to set massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState to model steady-state.
         Received tau1 = " + String(tau1) + "\n");
        assert(energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState or tau2 > Modelica.Constants.eps, "The parameter tau2, or the volume of the model from which tau may be derived, is unreasonably small.
         You need to set energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState to model steady-state.
         Received tau2 = " + String(tau2) + "\n");
        assert(massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState or tau2 > Modelica.Constants.eps, "The parameter tau2, or the volume of the model from which tau may be derived, is unreasonably small.
         You need to set massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState to model steady-state.
         Received tau2 = " + String(tau2) + "\n");
      equation
        connect(vol1.ports[2], port_b1);
        connect(vol2.ports[2], port_b2);
        connect(port_a1, preDro1.port_a);
        connect(preDro1.port_b, vol1.ports[1]);
        connect(port_a2, preDro2.port_a);
        connect(preDro2.port_b, vol2.ports[1]);
      end FourPortHeatMassExchanger;

      record LumpedVolumeDeclarations
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
        parameter Modelica.Fluid.Types.Dynamics energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial annotation(Evaluate = true);
        parameter Modelica.Fluid.Types.Dynamics massDynamics = energyDynamics annotation(Evaluate = true);
        final parameter Modelica.Fluid.Types.Dynamics substanceDynamics = energyDynamics annotation(Evaluate = true);
        final parameter Modelica.Fluid.Types.Dynamics traceDynamics = energyDynamics annotation(Evaluate = true);
        parameter Medium.AbsolutePressure p_start = Medium.p_default;
        parameter Medium.Temperature T_start = Medium.T_default;
        parameter Medium.MassFraction[Medium.nX] X_start = Medium.X_default;
        parameter Medium.ExtraProperty[Medium.nC] C_start(quantity = Medium.extraPropertiesNames) = fill(0, Medium.nC);
        parameter Medium.ExtraProperty[Medium.nC] C_nominal(quantity = Medium.extraPropertiesNames) = fill(1E-2, Medium.nC);
      end LumpedVolumeDeclarations;

      partial model PartialFourPortInterface
        extends Buildings.Fluid.Interfaces.FourPort;
        parameter Modelica.SIunits.MassFlowRate m1_flow_nominal(min = 0);
        parameter Modelica.SIunits.MassFlowRate m2_flow_nominal(min = 0);
        parameter Medium1.MassFlowRate m1_flow_small(min = 0) = 1E-4 * abs(m1_flow_nominal);
        parameter Medium2.MassFlowRate m2_flow_small(min = 0) = 1E-4 * abs(m2_flow_nominal);
        parameter Boolean show_T = false;
        Medium1.MassFlowRate m1_flow(start = 0) = port_a1.m_flow;
        Modelica.SIunits.Pressure dp1(start = 0, displayUnit = "Pa");
        Medium2.MassFlowRate m2_flow(start = 0) = port_a2.m_flow;
        Modelica.SIunits.Pressure dp2(start = 0, displayUnit = "Pa");
        Medium1.ThermodynamicState sta_a1 = Medium1.setState_phX(port_a1.p, noEvent(actualStream(port_a1.h_outflow)), noEvent(actualStream(port_a1.Xi_outflow))) if show_T;
        Medium1.ThermodynamicState sta_b1 = Medium1.setState_phX(port_b1.p, noEvent(actualStream(port_b1.h_outflow)), noEvent(actualStream(port_b1.Xi_outflow))) if show_T;
        Medium2.ThermodynamicState sta_a2 = Medium2.setState_phX(port_a2.p, noEvent(actualStream(port_a2.h_outflow)), noEvent(actualStream(port_a2.Xi_outflow))) if show_T;
        Medium2.ThermodynamicState sta_b2 = Medium2.setState_phX(port_b2.p, noEvent(actualStream(port_b2.h_outflow)), noEvent(actualStream(port_b2.Xi_outflow))) if show_T;
      protected
        Medium1.ThermodynamicState state_a1_inflow = Medium1.setState_phX(port_a1.p, inStream(port_a1.h_outflow), inStream(port_a1.Xi_outflow));
        Medium1.ThermodynamicState state_b1_inflow = Medium1.setState_phX(port_b1.p, inStream(port_b1.h_outflow), inStream(port_b1.Xi_outflow));
        Medium2.ThermodynamicState state_a2_inflow = Medium2.setState_phX(port_a2.p, inStream(port_a2.h_outflow), inStream(port_a2.Xi_outflow));
        Medium2.ThermodynamicState state_b2_inflow = Medium2.setState_phX(port_b2.p, inStream(port_b2.h_outflow), inStream(port_b2.Xi_outflow));
      equation
        dp1 = port_a1.p - port_b1.p;
        dp2 = port_a2.p - port_b2.p;
      end PartialFourPortInterface;

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

      model StaticTwoPortConservationEquation
        extends Buildings.Fluid.Interfaces.PartialTwoPortInterface(showDesignFlowDirection = false);
        constant Boolean sensibleOnly;
        Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W");
        Modelica.Blocks.Interfaces.RealInput mWat_flow(unit = "kg/s");
        Modelica.Blocks.Interfaces.RealOutput hOut(unit = "J/kg", start = Medium.specificEnthalpy_pTX(p = Medium.p_default, T = Medium.T_default, X = Medium.X_default));
        Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut(each unit = "1", each min = 0, each max = 1);
        Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut(each min = 0);
        constant Boolean use_safeDivision = true;
      protected
        Real m_flowInv(unit = "s/kg");
        Modelica.SIunits.MassFlowRate[Medium.nXi] mXi_flow;
        final parameter Real[Medium.nXi] s = array(if Modelica.Utilities.Strings.isEqual(string1 = Medium.substanceNames[i], string2 = "Water", caseSensitive = false) then 1 else 0 for i in 1:Medium.nXi);
      initial equation
        assert(Medium.nXi == 0 or abs(sum(s) - 1) < 1e-5, "If Medium.nXi > 1, then substance 'water' must be present for one component.'" + Medium.mediumName + "'.\n" + "Check medium model.");
      equation
        mXi_flow = mWat_flow * s;
        if use_safeDivision then
          m_flowInv = Buildings.Utilities.Math.Functions.inverseXRegularized(x = port_a.m_flow, delta = m_flow_small / 1E3);
        else
          m_flowInv = 0;
        end if;
        if allowFlowReversal then
          hOut = Buildings.Utilities.Math.Functions.spliceFunction(pos = port_b.h_outflow, neg = port_a.h_outflow, x = port_a.m_flow, deltax = m_flow_small / 1E3);
          XiOut = Buildings.Utilities.Math.Functions.spliceFunction(pos = port_b.Xi_outflow, neg = port_a.Xi_outflow, x = port_a.m_flow, deltax = m_flow_small / 1E3);
          COut = Buildings.Utilities.Math.Functions.spliceFunction(pos = port_b.C_outflow, neg = port_a.C_outflow, x = port_a.m_flow, deltax = m_flow_small / 1E3);
        else
          hOut = port_b.h_outflow;
          XiOut = port_b.Xi_outflow;
          COut = port_b.C_outflow;
        end if;
        if sensibleOnly then
          port_a.m_flow = -port_b.m_flow;
          if use_safeDivision then
            port_b.h_outflow = inStream(port_a.h_outflow) + Q_flow * m_flowInv;
            port_a.h_outflow = inStream(port_b.h_outflow) - Q_flow * m_flowInv;
          else
            port_a.m_flow * (inStream(port_a.h_outflow) - port_b.h_outflow) = -Q_flow;
            port_a.m_flow * (inStream(port_b.h_outflow) - port_a.h_outflow) = +Q_flow;
          end if;
          port_a.Xi_outflow = inStream(port_b.Xi_outflow);
          port_b.Xi_outflow = inStream(port_a.Xi_outflow);
          port_a.C_outflow = inStream(port_b.C_outflow);
          port_b.C_outflow = inStream(port_a.C_outflow);
        else
          port_a.m_flow + port_b.m_flow = -mWat_flow;
          if use_safeDivision then
            port_b.h_outflow = inStream(port_a.h_outflow) + Q_flow * m_flowInv;
            port_a.h_outflow = inStream(port_b.h_outflow) - Q_flow * m_flowInv;
            port_b.Xi_outflow = inStream(port_a.Xi_outflow) + mXi_flow * m_flowInv;
            port_a.Xi_outflow = inStream(port_b.Xi_outflow) - mXi_flow * m_flowInv;
          else
            port_a.m_flow * (inStream(port_a.h_outflow) - port_b.h_outflow) = -Q_flow;
            port_a.m_flow * (inStream(port_b.h_outflow) - port_a.h_outflow) = +Q_flow;
            port_a.m_flow * (inStream(port_a.Xi_outflow) - port_b.Xi_outflow) = -mXi_flow;
            port_a.m_flow * (inStream(port_b.Xi_outflow) - port_a.Xi_outflow) = +mXi_flow;
          end if;
          port_a.m_flow * port_a.C_outflow = -port_b.m_flow * inStream(port_b.C_outflow);
          port_b.m_flow * port_b.C_outflow = -port_a.m_flow * inStream(port_a.C_outflow);
        end if;
        port_a.p = port_b.p;
      end StaticTwoPortConservationEquation;

      record TwoPortFlowResistanceParameters
        parameter Boolean computeFlowResistance = true annotation(Evaluate = true);
        parameter Boolean from_dp = false annotation(Evaluate = true);
        parameter Modelica.SIunits.Pressure dp_nominal(min = 0, displayUnit = "Pa");
        parameter Boolean linearizeFlowResistance = false;
        parameter Real deltaM = 0.1;
      end TwoPortFlowResistanceParameters;
    end Interfaces;
  end Fluid;

  package HeatTransfer
    extends Modelica.Icons.Package;

    package Conduction
      extends Modelica.Icons.VariantsPackage;

      model SingleLayerCylinder
        replaceable parameter Buildings.HeatTransfer.Data.Soil.Generic material annotation(choicesAllMatching = true);
        parameter Modelica.SIunits.Height h;
        parameter Modelica.SIunits.Radius r_a;
        parameter Modelica.SIunits.Radius r_b;
        parameter Integer nSta(min = 1);
        parameter Modelica.SIunits.Temperature TInt_start = 293.15;
        parameter Modelica.SIunits.Temperature TExt_start = 293.15;
        parameter Boolean steadyStateInitial = false annotation(Evaluate = true);
        parameter Real griFac(min = 1) = 2;
        Modelica.SIunits.TemperatureDifference dT;
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a;
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b;
        Modelica.SIunits.Temperature[nSta] T(start = array(TInt_start + (TExt_start - TInt_start) / Modelica.Math.log(r_b / r_a) * Modelica.Math.log((r_a + (r_b - r_a) / nSta * (i - 0.5)) / r_a) for i in 1:nSta));
        Modelica.SIunits.HeatFlowRate[nSta + 1] Q_flow;
      protected
        parameter Modelica.SIunits.Radius[nSta + 1] r(each fixed = false);
        parameter Modelica.SIunits.Radius[nSta] rC(each fixed = false);
        final parameter Modelica.SIunits.SpecificHeatCapacity c = material.c;
        final parameter Modelica.SIunits.ThermalConductivity k = material.k;
        final parameter Modelica.SIunits.Density d = material.d;
        parameter Modelica.SIunits.ThermalConductance[nSta + 1] G(each fixed = false);
        parameter Modelica.SIunits.HeatCapacity[nSta] C(each fixed = false);
      initial equation
        assert(r_a < r_b, "Error: Model requires r_a < r_b.");
        assert(0 < r_a, "Error: Model requires 0 < r_a.");
        r[1] = r_a;
        for i in 2:nSta + 1 loop
          r[i] = r[i - 1] + (r_b - r_a) * (1 - griFac) / (1 - griFac ^ nSta) * griFac ^ (i - 2);
        end for;
        assert(abs(r[nSta + 1] - r_b) < 1E-10, "Error: Wrong computation of radius. r[nSta+1]=" + String(r[nSta + 1]));
        for i in 1:nSta loop
          rC[i] = (r[i] + r[i + 1]) / 2;
        end for;
        G[1] = 2 * Modelica.Constants.pi * k * h / Modelica.Math.log(rC[1] / r_a);
        G[nSta + 1] = 2 * Modelica.Constants.pi * k * h / Modelica.Math.log(r_b / rC[nSta]);
        for i in 2:nSta loop
          G[i] = 2 * Modelica.Constants.pi * k * h / Modelica.Math.log(rC[i] / rC[i - 1]);
        end for;
        for i in 1:nSta loop
          C[i] = d * Modelica.Constants.pi * c * h * (r[i + 1] ^ 2 - r[i] ^ 2);
        end for;
        if not material.steadyState then
          if steadyStateInitial then
            der(T) = zeros(nSta);
          else
            for i in 1:nSta loop
              T[i] = TInt_start + (TExt_start - TInt_start) / Modelica.Math.log(r_b / r_a) * Modelica.Math.log(rC[i] / r_a);
            end for;
          end if;
        end if;
      equation
        dT = port_a.T - port_b.T;
        port_a.Q_flow = +Q_flow[1];
        port_b.Q_flow = -Q_flow[nSta + 1];
        Q_flow[1] = G[1] * (port_a.T - T[1]);
        Q_flow[nSta + 1] = G[nSta + 1] * (T[nSta] - port_b.T);
        for i in 2:nSta loop
          Q_flow[i] = G[i] * (T[i - 1] - T[i]);
        end for;
        if material.steadyState then
          for i in 2:nSta + 1 loop
            Q_flow[i] = Q_flow[1];
          end for;
        else
          for i in 1:nSta loop
            der(T[i]) = (Q_flow[i] - Q_flow[i + 1]) / C[i];
          end for;
        end if;
      end SingleLayerCylinder;
    end Conduction;

    package Data
      extends Modelica.Icons.MaterialPropertiesPackage;

      package BoreholeFillings
        extends Modelica.Icons.MaterialPropertiesPackage;
        record Generic = Buildings.HeatTransfer.Data.BaseClasses.ThermalProperties;
        record Bentonite = Buildings.HeatTransfer.Data.BoreholeFillings.Generic(k = 1.15, d = 1600, c = 800);
      end BoreholeFillings;

      package Soil
        extends Modelica.Icons.MaterialPropertiesPackage;

        record Generic
          extends Buildings.HeatTransfer.Data.BaseClasses.ThermalProperties;
        end Generic;

        record Concrete = Buildings.HeatTransfer.Data.Soil.Generic(k = 3.1, d = 2000, c = 840);
      end Soil;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        record ThermalProperties
          extends Modelica.Icons.Record;
          parameter Modelica.SIunits.ThermalConductivity k;
          parameter Modelica.SIunits.SpecificHeatCapacity c;
          parameter Modelica.SIunits.Density d;
          parameter Boolean steadyState = c == 0 or d == 0 annotation(Evaluate = true);
        end ThermalProperties;
      end BaseClasses;
    end Data;
  end HeatTransfer;

  package Media
    extends Modelica.Icons.Package;

    package ConstantPropertyLiquidWater
      extends Buildings.Media.Interfaces.PartialSimpleMedium(mediumName = "SimpleLiquidWater", cp_const = 4184, cv_const = 4184, d_const = 995.586, eta_const = 1.e-3, lambda_const = 0.598, a_const = 1484, T_min = Modelica.SIunits.Conversions.from_degC(-1), T_max = Modelica.SIunits.Conversions.from_degC(130), T0 = 273.15, MM_const = 0.018015268, fluidConstants = .Modelica.Media.Water.ConstantPropertyLiquidWater.simpleWaterConstants, ThermoStates = Interfaces.Choices.IndependentVariables.T);

      redeclare replaceable function extends specificInternalEnergy
      algorithm
        u := cv_const * (state.T - T0);
      end specificInternalEnergy;
    end ConstantPropertyLiquidWater;

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

        function inverseXRegularized
          input Real x;
          input Real delta(min = 0);
          output Real y;
        protected
          Real delta2;
          Real x2_d2;
        algorithm
          if abs(x) > delta then
            y := 1 / x;
          else
            delta2 := delta * delta;
            x2_d2 := x * x / delta2;
            y := x / delta2 + x * abs(x / delta2 / delta * (2 - x2_d2 * (3 - x2_d2)));
          end if;
        end inverseXRegularized;

        function regNonZeroPower
          input Real x;
          input Real n;
          input Real delta = 0.01;
          output Real y;
        protected
          Real a1;
          Real a3;
          Real a5;
          Real delta2;
          Real x2;
          Real y_d;
          Real yP_d;
          Real yPP_d;
        algorithm
          if abs(x) > delta then
            y := abs(x) ^ n;
          else
            delta2 := delta * delta;
            x2 := x * x;
            y_d := delta ^ n;
            yP_d := n * delta ^ (n - 1);
            yPP_d := n * (n - 1) * delta ^ (n - 2);
            a1 := -(yP_d / delta - yPP_d) / delta2 / 8;
            a3 := (yPP_d - 12 * a1 * delta2) / 2;
            a5 := y_d - delta2 * (a3 + delta2 * a1);
            y := a5 + x2 * (a3 + x2 * a1);
            assert(a5 > 0, "Delta is too small for this exponent.");
          end if;
        end regNonZeroPower;

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

          function der_2_regNonZeroPower
            input Real x;
            input Real n;
            input Real delta = 0.01;
            input Real der_x;
            input Real der_2_x;
            output Real der_2_y;
          protected
            Real a1;
            Real a3;
            Real delta2;
            Real x2;
            Real y_d;
            Real yP_d;
            Real yPP_d;
          algorithm
            if abs(x) > delta then
              der_2_y := n * (n - 1) * abs(x) ^ (n - 2);
            else
              delta2 := delta * delta;
              x2 := x * x;
              y_d := delta ^ n;
              yP_d := n * delta ^ (n - 1);
              yPP_d := n * (n - 1) * delta ^ (n - 2);
              a1 := -(yP_d / delta - yPP_d) / delta2 / 8;
              a3 := (yPP_d - 12 * a1 * delta2) / 2;
              der_2_y := 12 * a1 * x2 + 2 * a3;
            end if;
          end der_2_regNonZeroPower;

          function der_regNonZeroPower
            input Real x;
            input Real n;
            input Real delta = 0.01;
            input Real der_x;
            output Real der_y;
          protected
            Real a1;
            Real a3;
            Real delta2;
            Real x2;
            Real y_d;
            Real yP_d;
            Real yPP_d;
          algorithm
            if abs(x) > delta then
              der_y := sign(x) * n * abs(x) ^ (n - 1);
            else
              delta2 := delta * delta;
              x2 := x * x;
              y_d := delta ^ n;
              yP_d := n * delta ^ (n - 1);
              yPP_d := n * (n - 1) * delta ^ (n - 2);
              a1 := -(yP_d / delta - yPP_d) / delta2 / 8;
              a3 := (yPP_d - 12 * a1 * delta2) / 2;
              der_y := x * (4 * a1 * x * x + 2 * a3);
            end if;
          end der_regNonZeroPower;

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

      block RealExpression
        Modelica.Blocks.Interfaces.RealOutput y = 0.0;
      end RealExpression;

      block Constant
        parameter Real k(start = 1);
        extends .Modelica.Blocks.Interfaces.SO;
      equation
        y = k;
      end Constant;
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

    package Vessels
      extends Modelica.Icons.VariantsPackage;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        connector VesselFluidPorts_b
          extends Interfaces.FluidPort;
        end VesselFluidPorts_b;
      end BaseClasses;
    end Vessels;

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
        constant SpecificEnthalpy h_default = specificEnthalpy_pTX(p_default, T_default, X_default);
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
      end Choices;

      package Types
        extends Modelica.Icons.Package;
        type AbsolutePressure = .Modelica.SIunits.AbsolutePressure(min = 0, max = 1.e8, nominal = 1.e5, start = 1.e5);
        type Density = .Modelica.SIunits.Density(min = 0, max = 1.e5, nominal = 1, start = 1);
        type DynamicViscosity = .Modelica.SIunits.DynamicViscosity(min = 0, max = 1.e8, nominal = 1.e-3, start = 1.e-3);
        type EnthalpyFlowRate = .Modelica.SIunits.EnthalpyFlowRate(nominal = 1000.0, min = -1.0e8, max = 1.e8);
        type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1);
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
        type ExtraPropertyFlowRate = Real(unit = "kg/s");
        type IsobaricExpansionCoefficient = Real(min = 0, max = 1.0e8, unit = "1/K");
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
    end Common;

    package Water
      extends Modelica.Icons.VariantsPackage;

      package ConstantPropertyLiquidWater
        constant Modelica.Media.Interfaces.Types.Basic.FluidConstants[1] simpleWaterConstants(each chemicalFormula = "H2O", each structureFormula = "H2O", each casRegistryNumber = "7732-18-5", each iupacName = "oxidane", each molarMass = 0.018015268);
        extends Interfaces.PartialSimpleMedium(mediumName = "SimpleLiquidWater", cp_const = 4184, cv_const = 4184, d_const = 995.586, eta_const = 1.e-3, lambda_const = 0.598, a_const = 1484, T_min = .Modelica.SIunits.Conversions.from_degC(-1), T_max = .Modelica.SIunits.Conversions.from_degC(130), T0 = 273.15, MM_const = 0.018015268, fluidConstants = simpleWaterConstants);
      end ConstantPropertyLiquidWater;
    end Water;
  end Media;

  package Thermal
    extends Modelica.Icons.Package;

    package HeatTransfer
      extends Modelica.Icons.Package;

      package Components
        extends Modelica.Icons.Package;

        model HeatCapacitor
          parameter Modelica.SIunits.HeatCapacity C;
          Modelica.SIunits.Temperature T(start = 293.15, displayUnit = "degC");
          Modelica.SIunits.TemperatureSlope der_T(start = 0);
          Interfaces.HeatPort_a port;
        equation
          T = port.T;
          der_T = der(T);
          C * der(T) = port.Q_flow;
        end HeatCapacitor;

        model ThermalResistor
          extends Interfaces.Element1D;
          parameter Modelica.SIunits.ThermalResistance R;
        equation
          dT = R * Q_flow;
        end ThermalResistor;

        model ConvectiveResistor
          Modelica.SIunits.HeatFlowRate Q_flow;
          Modelica.SIunits.TemperatureDifference dT;
          Modelica.Blocks.Interfaces.RealInput Rc(unit = "K/W");
          Interfaces.HeatPort_a solid;
          Interfaces.HeatPort_b fluid;
        equation
          dT = solid.T - fluid.T;
          solid.Q_flow = Q_flow;
          fluid.Q_flow = -Q_flow;
          dT = Rc * Q_flow;
        end ConvectiveResistor;
      end Components;

      package Sensors
        extends Modelica.Icons.SensorsPackage;

        model HeatFlowSensor
          extends Modelica.Icons.RotationalSensor;
          Modelica.Blocks.Interfaces.RealOutput Q_flow(unit = "W");
          Interfaces.HeatPort_a port_a;
          Interfaces.HeatPort_b port_b;
        equation
          port_a.T = port_b.T;
          port_a.Q_flow + port_b.Q_flow = 0;
          Q_flow = port_a.Q_flow;
        end HeatFlowSensor;
      end Sensors;

      package Interfaces
        extends Modelica.Icons.InterfacesPackage;

        partial connector HeatPort
          Modelica.SIunits.Temperature T;
          flow Modelica.SIunits.HeatFlowRate Q_flow;
        end HeatPort;

        connector HeatPort_a
          extends HeatPort;
        end HeatPort_a;

        connector HeatPort_b
          extends HeatPort;
        end HeatPort_b;

        partial model Element1D
          Modelica.SIunits.HeatFlowRate Q_flow;
          Modelica.SIunits.TemperatureDifference dT;
          HeatPort_a port_a;
          HeatPort_b port_b;
        equation
          dT = port_a.T - port_b.T;
          port_a.Q_flow = Q_flow;
          port_b.Q_flow = -Q_flow;
        end Element1D;
      end Interfaces;
    end HeatTransfer;
  end Thermal;

  package Math
    extends Modelica.Icons.Package;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  end AxisLeft;

      partial function AxisCenter  end AxisCenter;
    end Icons;

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

    package Strings
      extends Modelica.Icons.Package;

      function compare
        extends Modelica.Icons.Function;
        input String string1;
        input String string2;
        input Boolean caseSensitive = true;
        output Modelica.Utilities.Types.Compare result;
        external "C" result = ModelicaStrings_compare(string1, string2, caseSensitive) annotation(Library = "ModelicaExternalC");
      end compare;

      function isEqual
        extends Modelica.Icons.Function;
        input String string1;
        input String string2;
        input Boolean caseSensitive = true;
        output Boolean identical;
      algorithm
        identical := compare(string1, string2, caseSensitive) == Types.Compare.Equal;
      end isEqual;
    end Strings;

    package Types
      extends Modelica.Icons.TypesPackage;
      type Compare = enumeration(Less, Equal, Greater);
    end Types;
  end Utilities;

  package Constants
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps;
    final constant Real inf = ModelicaServices.Machine.inf;
    final constant .Modelica.SIunits.Velocity c = 299792458;
    final constant .Modelica.SIunits.Acceleration g_n = 9.80665;
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
    type Height = Length(min = 0);
    type Radius = Length(min = 0);
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
    type EnthalpyFlowRate = Real(final quantity = "EnthalpyFlowRate", final unit = "W");
    type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
    type MomentumFlux = Real(final quantity = "MomentumFlux", final unit = "N");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC");
    type Temperature = ThermodynamicTemperature;
    type TemperatureDifference = Real(final quantity = "ThermodynamicTemperature", final unit = "K");
    type TemperatureSlope = Real(final quantity = "TemperatureSlope", final unit = "K/s");
    type Compressibility = Real(final quantity = "Compressibility", final unit = "1/Pa");
    type IsothermalCompressibility = Compressibility;
    type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type CoefficientOfHeatTransfer = Real(final quantity = "CoefficientOfHeatTransfer", final unit = "W/(m2.K)");
    type ThermalResistance = Real(final quantity = "ThermalResistance", final unit = "K/W");
    type ThermalConductance = Real(final quantity = "ThermalConductance", final unit = "W/K");
    type HeatCapacity = Real(final quantity = "HeatCapacity", final unit = "J/K");
    type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
    type RatioOfSpecificHeatCapacities = Real(final quantity = "RatioOfSpecificHeatCapacities", final unit = "1");
    type Entropy = Real(final quantity = "Entropy", final unit = "J/K");
    type SpecificEntropy = Real(final quantity = "SpecificEntropy", final unit = "J/(kg.K)");
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

model BoreholeSegment
  extends Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.Examples.BoreholeSegment;
  annotation(experiment(StopTime = 157680000), __Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/Fluid/HeatExchangers/Boreholes/BaseClasses/Examples/BoreholeSegment.mos"));
end BoreholeSegment;

// Result:
// function BoreholeSegment.Medium.ThermodynamicState "Automatically generated record constructor for BoreholeSegment.Medium.ThermodynamicState"
//   input Real p;
//   input Real T;
//   output ThermodynamicState res;
// end BoreholeSegment.Medium.ThermodynamicState;
//
// function BoreholeSegment.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = {"MassFraction"}, unit = {"kg/kg"}, min = {0.0}, max = {1.0}, nominal = {0.1});
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
// algorithm
//   h := 4184.0 * (T - 273.15);
// end BoreholeSegment.Medium.specificEnthalpy_pTX;
//
// function BoreholeSegment.Medium.temperature_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   input Real[1] X(quantity = {"MassFraction"}, unit = {"kg/kg"}, min = {0.0}, max = {1.0}, nominal = {0.1});
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0);
// algorithm
//   T := 273.15 + h / 4184.0;
// end BoreholeSegment.Medium.temperature_phX;
//
// function BoreholeSegment.seg.Medium1.setState_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   input Real[:] X(quantity = fill("MassFraction", size(X, 1)), unit = fill("kg/kg", size(X, 1)), min = fill(0.0, size(X, 1)), max = fill(1.0, size(X, 1)), nominal = fill(0.1, size(X, 1))) = {1.0};
//   output BoreholeSegment.Medium.ThermodynamicState state;
// algorithm
//   state := BoreholeSegment.Medium.ThermodynamicState(p, BoreholeSegment.Medium.temperature_phX(p, h, X));
// end BoreholeSegment.seg.Medium1.setState_phX;
//
// function BoreholeSegment.seg.pipFil.Medium1.specificEnthalpy
//   input BoreholeSegment.Medium.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
// algorithm
//   h := 4184.0 * (state.T - 273.15);
// end BoreholeSegment.seg.pipFil.Medium1.specificEnthalpy;
//
// function BoreholeSegment.seg.pipFil.vol1.Medium.specificInternalEnergy
//   input BoreholeSegment.Medium.ThermodynamicState state;
//   output Real u(quantity = "SpecificEnergy", unit = "J/kg", min = -1e8, max = 1e8, nominal = 1e6);
// algorithm
//   u := 4184.0 * (state.T - 273.15);
// end BoreholeSegment.seg.pipFil.vol1.Medium.specificInternalEnergy;
//
// function BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.density
//   input BoreholeSegment.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 1e5, start = 1.0, nominal = 1.0);
// algorithm
//   d := 995.586;
// end BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.density;
//
// function BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = fill("MassFraction", size(X, 1)), unit = fill("kg/kg", size(X, 1)), min = fill(0.0, size(X, 1)), max = fill(1.0, size(X, 1)), nominal = fill(0.1, size(X, 1))) = {1.0};
//   output BoreholeSegment.Medium.ThermodynamicState state;
// algorithm
//   state := BoreholeSegment.Medium.ThermodynamicState(p, T);
// end BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.setState_pTX;
//
// function Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow
//   input Real m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   input Real k(unit = "");
//   input Real m_flow_turbulent(quantity = "MassFlowRate", unit = "kg/s", min = 0.0);
//   output Real dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa");
//   protected Real kSquInv(unit = "1/(kg.m)");
// algorithm
//   kSquInv := 1.0 / k ^ 2.0;
//   dp := Modelica.Fluid.Utilities.regSquare2(m_flow, m_flow_turbulent, kSquInv, kSquInv, false, 1.0);
// end Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow;
//
// impure function Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray.constructor
//   output Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray table;
//
//   external "C" table = initArray();
// end Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray.constructor;
//
// impure function Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray.destructor
//   input Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray table;
//
//   external "C" freeArray(table);
// end Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray.destructor;
//
// function Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.convectionResistance
//   input Real hSeg(quantity = "Length", unit = "m", min = 0.0);
//   input Real rTub(quantity = "Length", unit = "m", min = 0.0);
//   input Real kMed(quantity = "ThermalConductivity", unit = "W/(m.K)");
//   input Real mueMed(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0);
//   input Real cpMed(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real m_flow(quantity = "MassFlowRate", unit = "kg/s");
//   input Real m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s");
//   output Real R(quantity = "ThermalResistance", unit = "K/W");
//   protected Real h(quantity = "CoefficientOfHeatTransfer", unit = "W/(m2.K)");
//   protected Real k(unit = "s/kg");
// algorithm
//   k := 2.0 / (mueMed * 3.141592653589793 * rTub);
//   h := 0.023 * kMed * (cpMed * mueMed / kMed) ^ 0.35 / (2.0 * rTub) * Buildings.Utilities.Math.Functions.regNonZeroPower(m_flow * k, 0.8, 0.01 * m_flow_nominal * k);
//   R := 1.0 / (6.283185307179586 * rTub * hSeg * h);
// end Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.convectionResistance;
//
// impure function Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues
//   input Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray table;
//   input Integer iX;
//   input Real x;
//   input Integer iY;
//   output Real y;
//
//   external "C" y = exchangeValues(table, iX, x, iY);
// end Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues;
//
// function Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.factorial
//   input Integer j;
//   output Integer f;
// algorithm
//   f := 1;
//   for i in 1:j loop
//     f := f * i;
//   end for;
// end Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.factorial;
//
// function Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.powerSeries
//   input Real u;
//   input Integer N;
//   output Real W;
// algorithm
//   W := sum((-1.0) ^ (/*Real*/(j) + 1.0) * u ^ /*Real*/(j) / (/*Real*/(j) * /*Real*/(Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.factorial(j))) for j in 1:N) - (0.5772 + log(u));
// end Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.powerSeries;
//
// function Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.singleUTubeResistances
//   input Real hSeg(quantity = "Length", unit = "m", min = 0.0);
//   input Real rBor(quantity = "Length", unit = "m", min = 0.0);
//   input Real rTub(quantity = "Length", unit = "m", min = 0.0);
//   input Real eTub(quantity = "Length", unit = "m");
//   input Real xC(quantity = "Length", unit = "m");
//   input Real kSoi(quantity = "ThermalConductivity", unit = "W/(m.K)");
//   input Real kFil(quantity = "ThermalConductivity", unit = "W/(m.K)");
//   input Real kTub(quantity = "ThermalConductivity", unit = "W/(m.K)");
//   output Real Rgb(quantity = "ThermalResistance", unit = "K/W");
//   output Real Rgg(quantity = "ThermalResistance", unit = "K/W");
//   output Real RCondGro(quantity = "ThermalResistance", unit = "K/W");
//   output Real x;
//   protected Boolean test = false;
//   protected Real Rg(quantity = "ThermalResistance", unit = "K/W");
//   protected Real Rar(quantity = "ThermalResistance", unit = "K/W");
//   protected Real RCondPipe(quantity = "ThermalResistance", unit = "K/W");
//   protected Real Rb;
//   protected Real Ra;
//   protected Real sigma;
//   protected Real beta;
//   protected Real R_1delta_LS;
//   protected Real R_1delta_MP;
//   protected Real Ra_LS;
//   protected Integer i = 1;
// algorithm
//   RCondPipe := log((rTub + eTub) / rTub) / (6.283185307179586 * hSeg * kTub);
//   sigma := (kFil - kSoi) / (kFil + kSoi);
//   R_1delta_LS := 1.0 / (6.283185307179586 * kFil) * (log(rBor / (rTub + eTub)) + log(rBor / (2.0 * xC)) + sigma * log(rBor ^ 4.0 / (rBor ^ 4.0 - xC ^ 4.0)));
//   R_1delta_MP := R_1delta_LS - 1.0 / (6.283185307179586 * kFil) * (rTub + eTub) ^ 2.0 / (4.0 * xC ^ 2.0) * (1.0 - sigma * 4.0 * xC ^ 4.0 / (rBor ^ 4.0 - xC ^ 4.0)) ^ 2.0 / ((1.0 + beta) / (1.0 - beta) + (rTub + eTub) ^ 2.0 / (4.0 * xC ^ 2.0) * (1.0 + sigma * 16.0 * xC ^ 4.0 * rBor ^ 4.0 / (rBor ^ 4.0 - xC ^ 4.0) ^ 2.0));
//   Ra_LS := 1.0 / (3.141592653589793 * kFil) * (log(2.0 * xC / rTub) + sigma * log((rBor ^ 2.0 + xC ^ 2.0) / (rBor ^ 2.0 - xC ^ 2.0)));
//   beta := 6.283185307179586 * kFil * RCondPipe;
//   Rb := R_1delta_MP / 2.0;
//   Ra := Ra_LS - 1.0 / (3.141592653589793 * kFil) * rTub ^ 2.0 / (4.0 * xC ^ 2.0) * (1.0 + sigma * 4.0 * rBor ^ 4.0 * xC ^ 2.0 / (rBor ^ 4.0 - xC ^ 4.0)) / ((1.0 + beta) / (1.0 - beta) - rTub ^ 2.0 / (4.0 * xC ^ 2.0) + sigma * 2.0 * rTub ^ 2.0 * rBor ^ 2.0 * (rBor ^ 4.0 + xC ^ 4.0) / (rBor ^ 4.0 - xC ^ 4.0) ^ 2.0);
//   Rg := 2.0 * Rb / hSeg;
//   Rar := Ra / hSeg;
//   while test == false and i <= 15 loop
//     x := log(sqrt(rBor ^ 2.0 + 2.0 * (rTub + eTub) ^ 2.0) / (2.0 * (rTub + eTub))) / log(rBor / (1.4142135623730951 * (rTub + eTub))) * (15.0 - /*Real*/(i) + 1.0) / 15.0;
//     Rgb := (1.0 - x) * Rg;
//     Rgg := 2.0 * Rgb * (Rar - 2.0 * x * Rg) / (2.0 * Rgb - Rar + 2.0 * x * Rg);
//     test := 1.0 / Rgg + 0.5 / Rgb > 0.0;
//     i := i + 1;
//   end while;
//   assert(test, "Maximum number of iterations exceeded. Check the borehole geometry.
//                 The tubes may be too close to the borehole wall.
//                 Input to the function
//                 Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.singleUTubeResistances
//                 is
//                          hSeg = " + String(hSeg, 6, 0, true) + " m
//                          rBor = " + String(rBor, 6, 0, true) + " m
//                          rTub = " + String(rTub, 6, 0, true) + " m
//                          eTub = " + String(eTub, 6, 0, true) + " m
//                          xC   = " + String(xC, 6, 0, true) + " m
//                          kSoi = " + String(kSoi, 6, 0, true) + " W/m/K
//                          kFil = " + String(kFil, 6, 0, true) + " W/m/K
//                          kTub = " + String(kTub, 6, 0, true) + " W/m/K
//                 Computed x    = " + String(x, 6, 0, true) + " K/W
//                          Rgb  = " + String(Rgb, 6, 0, true) + " K/W
//                          Rgg  = " + String(Rgg, 6, 0, true) + " K/W");
//   RCondGro := x * Rg + RCondPipe;
// end Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.singleUTubeResistances;
//
// impure function Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.temperatureDrop
//   input Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray table;
//   input Integer iSam(min = 1);
//   input Real Q_flow(quantity = "Power", unit = "W");
//   input Real samplePeriod(quantity = "Time", unit = "s");
//   input Real rExt(quantity = "Length", unit = "m", min = 0.0);
//   input Real hSeg(quantity = "Length", unit = "m", min = 0.0);
//   input Real k(quantity = "ThermalConductivity", unit = "W/(m.K)");
//   input Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
//   input Real c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   output Real dT(quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real minSamplePeriod(quantity = "Time", unit = "s") = rExt ^ 2.0 / (4.0 * k / c / d * 3.8);
//   protected Real QL_flow(quantity = "Power", unit = "W");
//   protected Real QU_flow(quantity = "Power", unit = "W");
// algorithm
//   assert(rExt * rExt / (4.0 * k / c / d * samplePeriod) <= 3.8, "The samplePeriod has to be bigger than " + String(minSamplePeriod, 6, 0, true) + " for convergence purpose.
//                 samplePeriod = " + String(samplePeriod, 6, 0, true));
//   if iSam == 1 then
//     dT := 0.0;
//     QL_flow := Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues(table, iSam, Q_flow, iSam);
//   else
//     dT := 0.0;
//     for i in 1:iSam - 1 loop
//       QL_flow := Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues(table, iSam, Q_flow, iSam + 1 - i);
//       QU_flow := Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues(table, iSam, Q_flow, iSam - i);
//       dT := dT + 1.0 / (12.566370614359172 * k) * Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.powerSeries(c * d / (4.0 * k * /*Real*/(i) * samplePeriod) * rExt ^ 2.0, 10) * (QL_flow - QU_flow) / hSeg;
//     end for;
//   end if;
// end Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.temperatureDrop;
//
// function Buildings.Utilities.Math.Functions.regNonZeroPower
//   input Real x;
//   input Real n;
//   input Real delta = 0.01;
//   output Real y;
//   protected Real a1;
//   protected Real a3;
//   protected Real a5;
//   protected Real delta2;
//   protected Real x2;
//   protected Real y_d;
//   protected Real yP_d;
//   protected Real yPP_d;
// algorithm
//   if abs(x) > delta then
//     y := abs(x) ^ n;
//   else
//     delta2 := delta * delta;
//     x2 := x * x;
//     y_d := delta ^ n;
//     yP_d := n * delta ^ (n - 1.0);
//     yPP_d := n * (n - 1.0) * delta ^ (n - 2.0);
//     a1 := -(yP_d / delta - yPP_d) / delta2 / 8.0;
//     a3 := (yPP_d - 12.0 * a1 * delta2) / 2.0;
//     a5 := y_d - delta2 * (a3 + delta2 * a1);
//     y := a5 + x2 * (a3 + x2 * a1);
//     assert(a5 > 0.0, "Delta is too small for this exponent.");
//   end if;
// end Buildings.Utilities.Math.Functions.regNonZeroPower;
//
// function Modelica.Fluid.Utilities.checkBoundary
//   input String mediumName;
//   input String[:] substanceNames;
//   input Boolean singleState;
//   input Boolean define_p;
//   input Real[:] X_boundary;
//   input String modelName = "??? boundary ???";
//   protected Integer nX = size(X_boundary, 1);
//   protected String X_str;
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
//   if nX > 0 and abs(sum(X_boundary) - 1.0) > 1e-10 then
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
//   a2 := 3.0 * y1 - x1 * y1d - 2.0 * a1;
//   a3 := y1 - a2 - a1;
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
//   y := smooth(2, if x >= x_small then k1 * x ^ 2.0 else if x <= (-x_small) then -k2 * x ^ 2.0 else if k1 >= k2 then Modelica.Fluid.Utilities.regSquare2.regSquare2_utility(x, x_small, k1, k2, use_yd0, yd0) else -Modelica.Fluid.Utilities.regSquare2.regSquare2_utility(-x, x_small, k2, k1, use_yd0, yd0));
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
//     y := -k2 * x ^ 2.0;
//   else
//     y1 := k1 * x1 ^ 2.0;
//     y2 := -k2 * x2 ^ 2.0;
//     y1d := k1 * 2.0 * x1;
//     y2d := -k2 * 2.0 * x2;
//     if use_yd0 then
//       y0d := yd0;
//     else
//       w := x2 / x1;
//       y0d := ((3.0 * y2 - x2 * y2d) / w - (3.0 * y1 - x1 * y1d) * w) / (2.0 * x1 * (1.0 - w));
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
// function Modelica.SIunits.Conversions.to_bar
//   input Real Pa(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   output Real bar(quantity = "Pressure", unit = "bar");
// algorithm
//   bar := Pa / 1e5;
// end Modelica.SIunits.Conversions.to_bar;
//
// function Modelica.SIunits.Conversions.to_degC
//   input Real Kelvin(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real Celsius(quantity = "ThermodynamicTemperature", unit = "degC");
// algorithm
//   Celsius := Kelvin - 273.15;
// end Modelica.SIunits.Conversions.to_degC;
//
// function Modelica.Utilities.Streams.error
//   input String string;
//
//   external "C" ModelicaError(string);
// end Modelica.Utilities.Streams.error;
//
// class BoreholeSegment
//   parameter Real system.p_ambient(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 1e5) = 101325.0;
//   parameter Real system.T_ambient(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 293.15;
//   parameter Real system.g(quantity = "Acceleration", unit = "m/s2") = 9.80665;
//   final parameter Boolean system.allowFlowReversal = true;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.massDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.substanceDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.traceDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) system.momentumDynamics = Modelica.Fluid.Types.Dynamics.SteadyState;
//   parameter Real system.m_flow_start(quantity = "MassFlowRate", unit = "kg/s") = 0.0;
//   parameter Real system.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 1e5) = system.p_ambient;
//   parameter Real system.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = system.T_ambient;
//   final parameter Boolean system.use_eps_Re = false;
//   parameter Real system.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 100.0 * system.m_flow_small;
//   parameter Real system.eps_m_flow(min = 0.0) = 1e-4;
//   parameter Real system.dp_small(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 1e5) = 1.0;
//   parameter Real system.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.01;
//   parameter Real bento.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = 1.15;
//   final parameter Real bento.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = 800.0;
//   final parameter Real bento.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 1600.0;
//   final parameter Boolean bento.steadyState = false;
//   final parameter Boolean seg.allowFlowReversal1 = true;
//   final parameter Boolean seg.allowFlowReversal2 = true;
//   parameter Real seg.h_outflow_a1_start(quantity = "SpecificEnergy", unit = "J/kg") = 83680.0;
//   parameter Real seg.h_outflow_b1_start(quantity = "SpecificEnergy", unit = "J/kg") = 83680.0;
//   parameter Real seg.h_outflow_a2_start(quantity = "SpecificEnergy", unit = "J/kg") = 83680.0;
//   parameter Real seg.h_outflow_b2_start(quantity = "SpecificEnergy", unit = "J/kg") = 83680.0;
//   Real seg.port_a1.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e60, max = 1e5);
//   Real seg.port_a1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.port_a1.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, start = seg.h_outflow_a1_start, nominal = 1e5);
//   Real seg.port_b1.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e60);
//   Real seg.port_b1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.port_b1.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, start = seg.h_outflow_b1_start, nominal = 1e5);
//   Real seg.port_a2.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e60, max = 1e5);
//   Real seg.port_a2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.port_a2.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, start = seg.h_outflow_a2_start, nominal = 1e5);
//   Real seg.port_b2.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e60);
//   Real seg.port_b2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.port_b2.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, start = seg.h_outflow_b2_start, nominal = 1e5);
//   final parameter Real seg.m1_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.2;
//   final parameter Real seg.m2_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.2;
//   final parameter Real seg.m1_flow_small(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = 0.0, max = 1e5) = seg.m_flow_small;
//   final parameter Real seg.m2_flow_small(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = 0.0, max = 1e5) = seg.m_flow_small;
//   final parameter Boolean seg.show_T = false;
//   Real seg.m1_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5, start = 0.0) = seg.port_a1.m_flow;
//   Real seg.dp1(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0);
//   Real seg.m2_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5, start = 0.0) = seg.port_a2.m_flow;
//   Real seg.dp2(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0);
//   protected Real seg.state_a1_inflow.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.state_a1_inflow.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   protected Real seg.state_b1_inflow.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.state_b1_inflow.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   protected Real seg.state_a2_inflow.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.state_a2_inflow.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   protected Real seg.state_b2_inflow.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.state_b2_inflow.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   final parameter Boolean seg.computeFlowResistance = true;
//   final parameter Boolean seg.from_dp = false;
//   final parameter Real seg.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", min = 0.0) = 5.0;
//   final parameter Boolean seg.linearizeFlowResistance = false;
//   final parameter Real seg.deltaM = 0.1;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.massDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.substanceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.traceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   parameter Real seg.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = 3e5;
//   parameter Real seg.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = seg.TFil_start;
//   parameter Real seg.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   parameter Real seg.matSoi.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = 3.1;
//   final parameter Real seg.matSoi.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = 840.0;
//   final parameter Real seg.matSoi.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 2000.0;
//   final parameter Boolean seg.matSoi.steadyState = false;
//   parameter Real seg.matFil.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = bento.k;
//   parameter Real seg.matFil.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = 800.0;
//   parameter Real seg.matFil.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 1600.0;
//   parameter Boolean seg.matFil.steadyState = false;
//   final parameter Real seg.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 0.2;
//   parameter Real seg.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 2e-5;
//   final parameter Boolean seg.homotopyInitialization = true;
//   parameter Real seg.rTub(quantity = "Length", unit = "m", min = 0.0) = 0.02;
//   parameter Real seg.kTub(quantity = "ThermalConductivity", unit = "W/(m.K)") = 0.5;
//   parameter Real seg.eTub(quantity = "Length", unit = "m") = 0.002;
//   parameter Real seg.TFil_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 283.15;
//   parameter Real seg.rExt(quantity = "Length", unit = "m", min = 0.0) = 3.0;
//   parameter Real seg.TExt_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 283.15;
//   final parameter Integer seg.nSta(min = 1) = 9;
//   parameter Real seg.samplePeriod(quantity = "Time", unit = "s") = 604800.0;
//   parameter Real seg.rBor(quantity = "Length", unit = "m", min = 0.0) = 0.1;
//   parameter Real seg.hSeg(quantity = "Length", unit = "m", min = 0.0) = 10.0;
//   parameter Real seg.xC(quantity = "Length", unit = "m") = 0.05;
//   final parameter Boolean seg.allowFlowReversal = true;
//   final parameter Boolean seg.pipFil.allowFlowReversal1 = true;
//   final parameter Boolean seg.pipFil.allowFlowReversal2 = true;
//   final parameter Real seg.pipFil.h_outflow_a1_start(quantity = "SpecificEnergy", unit = "J/kg") = seg.pipFil.h1_outflow_start;
//   final parameter Real seg.pipFil.h_outflow_b1_start(quantity = "SpecificEnergy", unit = "J/kg") = seg.pipFil.h1_outflow_start;
//   final parameter Real seg.pipFil.h_outflow_a2_start(quantity = "SpecificEnergy", unit = "J/kg") = seg.pipFil.h2_outflow_start;
//   final parameter Real seg.pipFil.h_outflow_b2_start(quantity = "SpecificEnergy", unit = "J/kg") = seg.pipFil.h2_outflow_start;
//   Real seg.pipFil.port_a1.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e60, max = 1e5);
//   Real seg.pipFil.port_a1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.pipFil.port_a1.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, start = seg.pipFil.h_outflow_a1_start, nominal = 1e5);
//   Real seg.pipFil.port_b1.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e60);
//   Real seg.pipFil.port_b1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.pipFil.port_b1.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, start = seg.pipFil.h_outflow_b1_start, nominal = 1e5);
//   Real seg.pipFil.port_a2.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e60, max = 1e5);
//   Real seg.pipFil.port_a2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.pipFil.port_a2.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, start = seg.pipFil.h_outflow_a2_start, nominal = 1e5);
//   Real seg.pipFil.port_b2.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e60);
//   Real seg.pipFil.port_b2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.pipFil.port_b2.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, start = seg.pipFil.h_outflow_b2_start, nominal = 1e5);
//   final parameter Real seg.pipFil.m1_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.2;
//   final parameter Real seg.pipFil.m2_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.2;
//   final parameter Real seg.pipFil.m1_flow_small(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = 0.0, max = 1e5) = seg.m_flow_small;
//   final parameter Real seg.pipFil.m2_flow_small(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = 0.0, max = 1e5) = seg.m_flow_small;
//   final parameter Boolean seg.pipFil.show_T = false;
//   Real seg.pipFil.m1_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5, start = 0.0) = seg.pipFil.port_a1.m_flow;
//   Real seg.pipFil.dp1(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0);
//   Real seg.pipFil.m2_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5, start = 0.0) = seg.pipFil.port_a2.m_flow;
//   Real seg.pipFil.dp2(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0);
//   protected Real seg.pipFil.state_a1_inflow.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.pipFil.state_a1_inflow.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   protected Real seg.pipFil.state_b1_inflow.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.pipFil.state_b1_inflow.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   protected Real seg.pipFil.state_a2_inflow.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.pipFil.state_a2_inflow.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   protected Real seg.pipFil.state_b2_inflow.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.pipFil.state_b2_inflow.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   final parameter Boolean seg.pipFil.computeFlowResistance1 = true;
//   final parameter Boolean seg.pipFil.from_dp1 = false;
//   final parameter Real seg.pipFil.dp1_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", min = 0.0) = 5.0;
//   final parameter Boolean seg.pipFil.linearizeFlowResistance1 = false;
//   final parameter Real seg.pipFil.deltaM1 = 0.1;
//   final parameter Boolean seg.pipFil.computeFlowResistance2 = true;
//   final parameter Boolean seg.pipFil.from_dp2 = false;
//   final parameter Real seg.pipFil.dp2_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", min = 0.0) = 0.0;
//   final parameter Boolean seg.pipFil.linearizeFlowResistance2 = false;
//   final parameter Real seg.pipFil.deltaM2 = 0.1;
//   final parameter Real seg.pipFil.tau1(quantity = "Time", unit = "s") = 3.141592653589793 * seg.pipFil.rTub ^ 2.0 * seg.pipFil.hSeg * 995.586 / 0.2;
//   final parameter Real seg.pipFil.tau2(quantity = "Time", unit = "s") = 3.141592653589793 * seg.pipFil.rTub ^ 2.0 * seg.pipFil.hSeg * 995.586 / 0.2;
//   final parameter Boolean seg.pipFil.homotopyInitialization = true;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.massDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter Real seg.pipFil.p1_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = seg.p_start;
//   parameter Real seg.pipFil.T1_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = seg.T_start;
//   parameter Real seg.pipFil.X1_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = seg.X_start[1];
//   final parameter Real seg.pipFil.p2_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = seg.p_start;
//   parameter Real seg.pipFil.T2_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = seg.T_start;
//   parameter Real seg.pipFil.X2_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = seg.X_start[1];
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol1.energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol1.massDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol1.substanceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol1.traceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter Real seg.pipFil.vol1.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = seg.pipFil.p1_start;
//   final parameter Real seg.pipFil.vol1.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = seg.pipFil.T1_start;
//   final parameter Real seg.pipFil.vol1.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = seg.pipFil.X1_start[1];
//   final parameter Real seg.pipFil.vol1.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.2;
//   final parameter Integer seg.pipFil.vol1.nPorts = 2;
//   final parameter Real seg.pipFil.vol1.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = seg.pipFil.m1_flow_small;
//   final parameter Boolean seg.pipFil.vol1.allowFlowReversal = true;
//   final parameter Real seg.pipFil.vol1.V(quantity = "Volume", unit = "m3") = 0.2 * seg.pipFil.tau2 / 995.586;
//   final parameter Boolean seg.pipFil.vol1.prescribedHeatFlowRate = false;
//   final parameter Boolean seg.pipFil.vol1.initialize_p = false;
//   Real seg.pipFil.vol1.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5);
//   Real seg.pipFil.vol1.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.pipFil.vol1.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   Real seg.pipFil.vol1.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5);
//   Real seg.pipFil.vol1.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.pipFil.vol1.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   Real seg.pipFil.vol1.heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.pipFil.vol1.heatPort.Q_flow(quantity = "Power", unit = "W");
//   Real seg.pipFil.vol1.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.pipFil.vol1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol1.dynBal.energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol1.dynBal.massDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol1.dynBal.substanceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol1.dynBal.traceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   protected final parameter Real seg.pipFil.vol1.dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = seg.pipFil.vol1.p_start;
//   protected final parameter Real seg.pipFil.vol1.dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = seg.pipFil.vol1.T_start;
//   protected final parameter Real seg.pipFil.vol1.dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = seg.pipFil.vol1.X_start[1];
//   protected final parameter Integer seg.pipFil.vol1.dynBal.nPorts = 2;
//   protected final parameter Boolean seg.pipFil.vol1.dynBal.initialize_p = false;
//   protected Real seg.pipFil.vol1.dynBal.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5);
//   protected Real seg.pipFil.vol1.dynBal.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   protected Real seg.pipFil.vol1.dynBal.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   protected Real seg.pipFil.vol1.dynBal.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5);
//   protected Real seg.pipFil.vol1.dynBal.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   protected Real seg.pipFil.vol1.dynBal.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   protected Real seg.pipFil.vol1.dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = seg.pipFil.vol1.dynBal.p_start, nominal = 3e5, stateSelect = StateSelect.prefer);
//   protected Real seg.pipFil.vol1.dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = seg.pipFil.vol1.dynBal.hStart);
//   protected Real seg.pipFil.vol1.dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 1e5, start = seg.pipFil.vol1.dynBal.rho_nominal, nominal = 1.0);
//   protected Real seg.pipFil.vol1.dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = seg.pipFil.vol1.dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected Real seg.pipFil.vol1.dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   protected Real seg.pipFil.vol1.dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -1e8, max = 1e8, nominal = 1e6);
//   protected Real seg.pipFil.vol1.dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 1e7, start = 1000.0, nominal = 1000.0);
//   protected Real seg.pipFil.vol1.dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected Real seg.pipFil.vol1.dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected Real seg.pipFil.vol1.dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   protected final parameter Boolean seg.pipFil.vol1.dynBal.medium.preferredMediumStates = true;
//   protected final parameter Boolean seg.pipFil.vol1.dynBal.medium.standardOrderComponents = true;
//   protected Real seg.pipFil.vol1.dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(seg.pipFil.vol1.dynBal.medium.T);
//   protected Real seg.pipFil.vol1.dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(seg.pipFil.vol1.dynBal.medium.p);
//   protected Real seg.pipFil.vol1.dynBal.U(quantity = "Energy", unit = "J", start = seg.pipFil.vol1.V * seg.pipFil.vol1.rho_start * BoreholeSegment.seg.pipFil.vol1.Medium.specificInternalEnergy(seg.pipFil.vol1.state_start));
//   protected Real seg.pipFil.vol1.dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = seg.pipFil.vol1.V * seg.pipFil.vol1.rho_start);
//   protected Real seg.pipFil.vol1.dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected Real seg.pipFil.vol1.dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected final Real seg.pipFil.vol1.dynBal.fluidVolume(quantity = "Volume", unit = "m3") = seg.pipFil.vol1.V;
//   protected Real seg.pipFil.vol1.dynBal.Q_flow(unit = "W");
//   protected Real seg.pipFil.vol1.dynBal.mWat_flow(unit = "kg/s");
//   protected Real seg.pipFil.vol1.dynBal.hOut(unit = "J/kg", start = seg.pipFil.vol1.dynBal.hStart);
//   protected Real seg.pipFil.vol1.dynBal.ports_H_flow[1](quantity = "EnthalpyFlowRate", unit = "W", min = -1e8, max = 1e8, nominal = 1000.0);
//   protected Real seg.pipFil.vol1.dynBal.ports_H_flow[2](quantity = "EnthalpyFlowRate", unit = "W", min = -1e8, max = 1e8, nominal = 1000.0);
//   protected parameter Real seg.pipFil.vol1.dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.density(BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.setState_pTX(seg.pipFil.vol1.dynBal.p_start, seg.pipFil.vol1.dynBal.T_start, {}));
//   protected parameter Real seg.pipFil.vol1.dynBal.hStart(quantity = "SpecificEnergy", unit = "J/kg") = BoreholeSegment.Medium.specificEnthalpy_pTX(seg.pipFil.vol1.dynBal.p_start, seg.pipFil.vol1.dynBal.T_start, seg.pipFil.vol1.dynBal.X_start);
//   protected parameter Real seg.pipFil.vol1.rho_default(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 995.586;
//   protected parameter Real seg.pipFil.vol1.rho_start(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.density(seg.pipFil.vol1.state_start);
//   protected final parameter Real seg.pipFil.vol1.state_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5) = 3e5;
//   protected final parameter Real seg.pipFil.vol1.state_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0) = 293.15;
//   protected final parameter Real seg.pipFil.vol1.state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5) = seg.pipFil.vol1.p_start;
//   protected final parameter Real seg.pipFil.vol1.state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0) = seg.pipFil.vol1.T_start;
//   protected final parameter Boolean seg.pipFil.vol1.useSteadyStateTwoPort = false;
//   protected Real seg.pipFil.vol1.hOut_internal(unit = "J/kg");
//   protected Real seg.pipFil.vol1.QSen_flow.y = seg.pipFil.vol1.heatPort.Q_flow;
//   protected final parameter Real seg.pipFil.vol1.masExc.k(start = 1.0) = 0.0;
//   protected Real seg.pipFil.vol1.masExc.y;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol2.energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol2.massDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol2.substanceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol2.traceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   final parameter Real seg.pipFil.vol2.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = seg.pipFil.p2_start;
//   final parameter Real seg.pipFil.vol2.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = seg.pipFil.T2_start;
//   final parameter Real seg.pipFil.vol2.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = seg.pipFil.X2_start[1];
//   final parameter Real seg.pipFil.vol2.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.2;
//   final parameter Integer seg.pipFil.vol2.nPorts = 2;
//   final parameter Real seg.pipFil.vol2.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = seg.pipFil.m2_flow_small;
//   final parameter Boolean seg.pipFil.vol2.allowFlowReversal = true;
//   final parameter Real seg.pipFil.vol2.V(quantity = "Volume", unit = "m3") = 0.2 * seg.pipFil.tau1 / 995.586;
//   final parameter Boolean seg.pipFil.vol2.prescribedHeatFlowRate = false;
//   final parameter Boolean seg.pipFil.vol2.initialize_p = false;
//   Real seg.pipFil.vol2.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5);
//   Real seg.pipFil.vol2.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.pipFil.vol2.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   Real seg.pipFil.vol2.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5);
//   Real seg.pipFil.vol2.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real seg.pipFil.vol2.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   Real seg.pipFil.vol2.heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.pipFil.vol2.heatPort.Q_flow(quantity = "Power", unit = "W");
//   final Real seg.pipFil.vol2.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   final Real seg.pipFil.vol2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol2.dynBal.energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol2.dynBal.massDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol2.dynBal.substanceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) seg.pipFil.vol2.dynBal.traceDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial;
//   protected final parameter Real seg.pipFil.vol2.dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = seg.pipFil.vol2.p_start;
//   protected final parameter Real seg.pipFil.vol2.dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = seg.pipFil.vol2.T_start;
//   protected final parameter Real seg.pipFil.vol2.dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = seg.pipFil.vol2.X_start[1];
//   protected final parameter Integer seg.pipFil.vol2.dynBal.nPorts = 2;
//   protected final parameter Boolean seg.pipFil.vol2.dynBal.initialize_p = false;
//   protected Real seg.pipFil.vol2.dynBal.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5);
//   protected Real seg.pipFil.vol2.dynBal.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   protected Real seg.pipFil.vol2.dynBal.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   protected Real seg.pipFil.vol2.dynBal.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e5);
//   protected Real seg.pipFil.vol2.dynBal.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   protected Real seg.pipFil.vol2.dynBal.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   protected Real seg.pipFil.vol2.dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = seg.pipFil.vol2.dynBal.p_start, nominal = 3e5, stateSelect = StateSelect.prefer);
//   protected Real seg.pipFil.vol2.dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = seg.pipFil.vol2.dynBal.hStart);
//   protected final Real seg.pipFil.vol2.dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 1e5, start = seg.pipFil.vol2.dynBal.rho_nominal, nominal = 1.0);
//   protected final Real seg.pipFil.vol2.dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = seg.pipFil.vol2.dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected final Real seg.pipFil.vol2.dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   protected final Real seg.pipFil.vol2.dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -1e8, max = 1e8, nominal = 1e6);
//   protected final Real seg.pipFil.vol2.dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 1e7, start = 1000.0, nominal = 1000.0);
//   protected final Real seg.pipFil.vol2.dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected final Real seg.pipFil.vol2.dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   protected final Real seg.pipFil.vol2.dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   protected final parameter Boolean seg.pipFil.vol2.dynBal.medium.preferredMediumStates = true;
//   protected final parameter Boolean seg.pipFil.vol2.dynBal.medium.standardOrderComponents = true;
//   protected final Real seg.pipFil.vol2.dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(seg.pipFil.vol2.dynBal.medium.T);
//   protected final Real seg.pipFil.vol2.dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(seg.pipFil.vol2.dynBal.medium.p);
//   protected final Real seg.pipFil.vol2.dynBal.U(quantity = "Energy", unit = "J", start = seg.pipFil.vol2.V * seg.pipFil.vol2.rho_start * BoreholeSegment.seg.pipFil.vol1.Medium.specificInternalEnergy(seg.pipFil.vol2.state_start));
//   protected final Real seg.pipFil.vol2.dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = seg.pipFil.vol2.V * seg.pipFil.vol2.rho_start);
//   protected final Real seg.pipFil.vol2.dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected final Real seg.pipFil.vol2.dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected final Real seg.pipFil.vol2.dynBal.fluidVolume(quantity = "Volume", unit = "m3") = seg.pipFil.vol2.V;
//   protected Real seg.pipFil.vol2.dynBal.Q_flow(unit = "W");
//   protected Real seg.pipFil.vol2.dynBal.mWat_flow(unit = "kg/s");
//   protected Real seg.pipFil.vol2.dynBal.hOut(unit = "J/kg", start = seg.pipFil.vol2.dynBal.hStart);
//   protected final Real seg.pipFil.vol2.dynBal.ports_H_flow[1](quantity = "EnthalpyFlowRate", unit = "W", min = -1e8, max = 1e8, nominal = 1000.0);
//   protected final Real seg.pipFil.vol2.dynBal.ports_H_flow[2](quantity = "EnthalpyFlowRate", unit = "W", min = -1e8, max = 1e8, nominal = 1000.0);
//   protected final parameter Real seg.pipFil.vol2.dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.density(BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.setState_pTX(seg.pipFil.vol2.dynBal.p_start, seg.pipFil.vol2.dynBal.T_start, {}));
//   protected final parameter Real seg.pipFil.vol2.dynBal.hStart(quantity = "SpecificEnergy", unit = "J/kg") = BoreholeSegment.Medium.specificEnthalpy_pTX(seg.pipFil.vol2.dynBal.p_start, seg.pipFil.vol2.dynBal.T_start, seg.pipFil.vol2.dynBal.X_start);
//   protected final parameter Real seg.pipFil.vol2.rho_default(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 995.586;
//   protected final parameter Real seg.pipFil.vol2.rho_start(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.density(seg.pipFil.vol2.state_start);
//   protected final parameter Real seg.pipFil.vol2.state_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5) = 3e5;
//   protected final parameter Real seg.pipFil.vol2.state_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0) = 293.15;
//   protected final parameter Real seg.pipFil.vol2.state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5) = seg.pipFil.vol2.p_start;
//   protected final parameter Real seg.pipFil.vol2.state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0) = seg.pipFil.vol2.T_start;
//   protected final parameter Boolean seg.pipFil.vol2.useSteadyStateTwoPort = false;
//   protected Real seg.pipFil.vol2.hOut_internal(unit = "J/kg");
//   protected Real seg.pipFil.vol2.QSen_flow.y = seg.pipFil.vol2.heatPort.Q_flow;
//   protected final parameter Real seg.pipFil.vol2.masExc.k(start = 1.0) = 0.0;
//   protected Real seg.pipFil.vol2.masExc.y;
//   Real seg.pipFil.Q1_flow(quantity = "Power", unit = "W") = seg.pipFil.vol1.heatPort.Q_flow;
//   Real seg.pipFil.Q2_flow(quantity = "Power", unit = "W") = seg.pipFil.vol2.heatPort.Q_flow;
//   final parameter Boolean seg.pipFil.preDro1.allowFlowReversal = true;
//   Real seg.pipFil.preDro1.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e60, max = 1e5);
//   Real seg.pipFil.preDro1.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 3e5);
//   Real seg.pipFil.preDro1.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   Real seg.pipFil.preDro1.port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e60);
//   Real seg.pipFil.preDro1.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 3e5);
//   Real seg.pipFil.preDro1.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   protected final parameter Boolean seg.pipFil.preDro1.port_a_exposesState = false;
//   protected final parameter Boolean seg.pipFil.preDro1.port_b_exposesState = false;
//   protected final parameter Boolean seg.pipFil.preDro1.showDesignFlowDirection = true;
//   final parameter Real seg.pipFil.preDro1.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 0.2;
//   final parameter Real seg.pipFil.preDro1.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 2e-5;
//   final parameter Boolean seg.pipFil.preDro1.show_T = false;
//   Real seg.pipFil.preDro1.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = 0.0, nominal = 0.2) = seg.pipFil.preDro1.port_a.m_flow;
//   Real seg.pipFil.preDro1.dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0, nominal = 5.0);
//   final parameter Boolean seg.pipFil.preDro1.from_dp = false;
//   final parameter Real seg.pipFil.preDro1.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa") = 5.0;
//   final parameter Boolean seg.pipFil.preDro1.homotopyInitialization = true;
//   final parameter Boolean seg.pipFil.preDro1.linearized = false;
//   final parameter Real seg.pipFil.preDro1.m_flow_turbulent(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.020000000000000004;
//   protected parameter Real seg.pipFil.preDro1.sta_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5) = 3e5;
//   protected parameter Real seg.pipFil.preDro1.sta_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0) = 293.15;
//   protected final parameter Real seg.pipFil.preDro1.eta_default(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0) = 0.001;
//   protected final parameter Real seg.pipFil.preDro1.m_flow_nominal_pos(quantity = "MassFlowRate", unit = "kg/s") = 0.2;
//   protected final parameter Real seg.pipFil.preDro1.dp_nominal_pos(quantity = "Pressure", unit = "Pa", displayUnit = "bar") = 5.0;
//   final parameter Boolean seg.pipFil.preDro1.use_dh = false;
//   final parameter Real seg.pipFil.preDro1.dh(quantity = "Length", unit = "m") = 1.0;
//   final parameter Real seg.pipFil.preDro1.ReC(min = 0.0) = 4000.0;
//   final parameter Real seg.pipFil.preDro1.deltaM(min = 0.01) = 0.1;
//   final parameter Real seg.pipFil.preDro1.k(unit = "") = 0.08944271909999159;
//   protected final parameter Boolean seg.pipFil.preDro1.computeFlowResistance = true;
//   final parameter Boolean seg.pipFil.preDro2.allowFlowReversal = true;
//   Real seg.pipFil.preDro2.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e60, max = 1e5);
//   Real seg.pipFil.preDro2.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 3e5);
//   Real seg.pipFil.preDro2.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   Real seg.pipFil.preDro2.port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e5, max = 1e60);
//   Real seg.pipFil.preDro2.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 3e5);
//   Real seg.pipFil.preDro2.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   protected final parameter Boolean seg.pipFil.preDro2.port_a_exposesState = false;
//   protected final parameter Boolean seg.pipFil.preDro2.port_b_exposesState = false;
//   protected final parameter Boolean seg.pipFil.preDro2.showDesignFlowDirection = true;
//   final parameter Real seg.pipFil.preDro2.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 0.2;
//   final parameter Real seg.pipFil.preDro2.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 2e-5;
//   final parameter Boolean seg.pipFil.preDro2.show_T = false;
//   Real seg.pipFil.preDro2.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = 0.0, nominal = 0.2) = seg.pipFil.preDro2.port_a.m_flow;
//   Real seg.pipFil.preDro2.dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0, nominal = 0.0);
//   final parameter Boolean seg.pipFil.preDro2.from_dp = false;
//   final parameter Real seg.pipFil.preDro2.dp_nominal(quantity = "Pressure", unit = "Pa", displayUnit = "Pa") = 0.0;
//   final parameter Boolean seg.pipFil.preDro2.homotopyInitialization = true;
//   final parameter Boolean seg.pipFil.preDro2.linearized = false;
//   final parameter Real seg.pipFil.preDro2.m_flow_turbulent(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   protected parameter Real seg.pipFil.preDro2.sta_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5) = 3e5;
//   protected parameter Real seg.pipFil.preDro2.sta_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0) = 293.15;
//   protected final parameter Real seg.pipFil.preDro2.eta_default(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0) = 0.001;
//   protected final parameter Real seg.pipFil.preDro2.m_flow_nominal_pos(quantity = "MassFlowRate", unit = "kg/s") = 0.2;
//   protected final parameter Real seg.pipFil.preDro2.dp_nominal_pos(quantity = "Pressure", unit = "Pa", displayUnit = "bar") = 0.0;
//   final parameter Boolean seg.pipFil.preDro2.use_dh = false;
//   final parameter Real seg.pipFil.preDro2.dh(quantity = "Length", unit = "m") = 1.0;
//   final parameter Real seg.pipFil.preDro2.ReC(min = 0.0) = 4000.0;
//   final parameter Real seg.pipFil.preDro2.deltaM(min = 0.01) = 0.1;
//   final parameter Real seg.pipFil.preDro2.k(unit = "") = 0.0;
//   protected final parameter Boolean seg.pipFil.preDro2.computeFlowResistance = false;
//   protected parameter Real seg.pipFil.sta1_nominal.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5) = 3e5;
//   protected parameter Real seg.pipFil.sta1_nominal.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0) = 293.15;
//   protected final parameter Real seg.pipFil.rho1_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 995.586;
//   protected parameter Real seg.pipFil.sta2_nominal.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5) = 3e5;
//   protected parameter Real seg.pipFil.sta2_nominal.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0) = 293.15;
//   protected final parameter Real seg.pipFil.rho2_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 995.586;
//   protected parameter Real seg.pipFil.sta1_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, fixed = false, nominal = 1e5);
//   protected parameter Real seg.pipFil.sta1_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, fixed = false, nominal = 300.0);
//   protected parameter Real seg.pipFil.h1_outflow_start(quantity = "SpecificEnergy", unit = "J/kg") = BoreholeSegment.seg.pipFil.Medium1.specificEnthalpy(seg.pipFil.sta1_start);
//   protected parameter Real seg.pipFil.sta2_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, fixed = false, nominal = 1e5);
//   protected parameter Real seg.pipFil.sta2_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, fixed = false, nominal = 300.0);
//   protected parameter Real seg.pipFil.h2_outflow_start(quantity = "SpecificEnergy", unit = "J/kg") = BoreholeSegment.seg.pipFil.Medium1.specificEnthalpy(seg.pipFil.sta2_start);
//   final parameter Real seg.pipFil.matFil.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.matFil.k;
//   final parameter Real seg.pipFil.matFil.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = seg.matFil.c;
//   final parameter Real seg.pipFil.matFil.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = seg.matFil.d;
//   final parameter Boolean seg.pipFil.matFil.steadyState = seg.matFil.steadyState;
//   final parameter Real seg.pipFil.matSoi.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.matSoi.k;
//   final parameter Real seg.pipFil.matSoi.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = 840.0;
//   final parameter Real seg.pipFil.matSoi.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 2000.0;
//   final parameter Boolean seg.pipFil.matSoi.steadyState = false;
//   final parameter Real seg.pipFil.rTub(quantity = "Length", unit = "m", min = 0.0) = seg.rTub;
//   final parameter Real seg.pipFil.kTub(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.kTub;
//   final parameter Real seg.pipFil.eTub(quantity = "Length", unit = "m") = seg.eTub;
//   final parameter Real seg.pipFil.kSoi(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.matSoi.k;
//   final parameter Real seg.pipFil.TFil_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = seg.TFil_start;
//   final parameter Real seg.pipFil.hSeg(quantity = "Length", unit = "m", min = 0.0) = seg.hSeg;
//   final parameter Real seg.pipFil.rBor(quantity = "Length", unit = "m", min = 0.0) = seg.rBor;
//   final parameter Real seg.pipFil.xC(quantity = "Length", unit = "m") = seg.xC;
//   Real seg.pipFil.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.pipFil.port.Q_flow(quantity = "Power", unit = "W");
//   final parameter Real seg.pipFil.capFil1.C(quantity = "HeatCapacity", unit = "J/K") = seg.pipFil.Co_fil / 2.0;
//   Real seg.pipFil.capFil1.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.pipFil.TFil_start, fixed = false, nominal = 300.0);
//   Real seg.pipFil.capFil1.der_T(quantity = "TemperatureSlope", unit = "K/s", start = 0.0, fixed = true);
//   Real seg.pipFil.capFil1.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.pipFil.capFil1.port.Q_flow(quantity = "Power", unit = "W");
//   final parameter Real seg.pipFil.capFil2.C(quantity = "HeatCapacity", unit = "J/K") = seg.pipFil.Co_fil / 2.0;
//   Real seg.pipFil.capFil2.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.pipFil.TFil_start, fixed = false, nominal = 300.0);
//   Real seg.pipFil.capFil2.der_T(quantity = "TemperatureSlope", unit = "K/s", start = 0.0, fixed = true);
//   Real seg.pipFil.capFil2.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.pipFil.capFil2.port.Q_flow(quantity = "Power", unit = "W");
//   protected final parameter Real seg.pipFil.cpFil(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = seg.pipFil.matFil.c;
//   protected final parameter Real seg.pipFil.kFil(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.pipFil.matFil.k;
//   protected final parameter Real seg.pipFil.dFil(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = seg.pipFil.matFil.d;
//   protected parameter Real seg.pipFil.Co_fil(quantity = "HeatCapacity", unit = "J/K") = seg.pipFil.dFil * seg.pipFil.cpFil * seg.pipFil.hSeg * 3.141592653589793 * (seg.pipFil.rBor ^ 2.0 - 2.0 * (seg.pipFil.rTub + seg.pipFil.eTub) ^ 2.0);
//   protected final parameter Real seg.pipFil.cpMed(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = 4184.0;
//   protected final parameter Real seg.pipFil.kMed(quantity = "ThermalConductivity", unit = "W/(m.K)") = 0.598;
//   protected final parameter Real seg.pipFil.mueMed(quantity = "DynamicViscosity", unit = "Pa.s", min = 0.0) = 0.001;
//   protected parameter Real seg.pipFil.Rgb_val(quantity = "ThermalResistance", unit = "K/W", fixed = false);
//   protected parameter Real seg.pipFil.Rgg_val(quantity = "ThermalResistance", unit = "K/W", fixed = false);
//   protected parameter Real seg.pipFil.RCondGro_val(quantity = "ThermalResistance", unit = "K/W", fixed = false);
//   protected parameter Real seg.pipFil.x(fixed = false);
//   protected Real seg.pipFil.RConv1.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.RConv1.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real seg.pipFil.RConv1.Rc(unit = "K/W");
//   protected Real seg.pipFil.RConv1.solid.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.RConv1.solid.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.RConv1.fluid.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.RConv1.fluid.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.RConv2.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.RConv2.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real seg.pipFil.RConv2.Rc(unit = "K/W");
//   protected Real seg.pipFil.RConv2.solid.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.RConv2.solid.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.RConv2.fluid.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.RConv2.fluid.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rpg1.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rpg1.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real seg.pipFil.Rpg1.port_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rpg1.port_a.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rpg1.port_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rpg1.port_b.Q_flow(quantity = "Power", unit = "W");
//   protected final parameter Real seg.pipFil.Rpg1.R(quantity = "ThermalResistance", unit = "K/W") = seg.pipFil.RCondGro_val;
//   protected Real seg.pipFil.Rpg2.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rpg2.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real seg.pipFil.Rpg2.port_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rpg2.port_a.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rpg2.port_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rpg2.port_b.Q_flow(quantity = "Power", unit = "W");
//   protected final parameter Real seg.pipFil.Rpg2.R(quantity = "ThermalResistance", unit = "K/W") = seg.pipFil.RCondGro_val;
//   protected Real seg.pipFil.Rgb1.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rgb1.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real seg.pipFil.Rgb1.port_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rgb1.port_a.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rgb1.port_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rgb1.port_b.Q_flow(quantity = "Power", unit = "W");
//   protected final parameter Real seg.pipFil.Rgb1.R(quantity = "ThermalResistance", unit = "K/W") = seg.pipFil.Rgb_val;
//   protected Real seg.pipFil.Rgb2.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rgb2.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real seg.pipFil.Rgb2.port_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rgb2.port_a.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rgb2.port_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rgb2.port_b.Q_flow(quantity = "Power", unit = "W");
//   protected final parameter Real seg.pipFil.Rgb2.R(quantity = "ThermalResistance", unit = "K/W") = seg.pipFil.Rgb_val;
//   protected Real seg.pipFil.Rgg.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rgg.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real seg.pipFil.Rgg.port_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rgg.port_a.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.pipFil.Rgg.port_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.pipFil.Rgg.port_b.Q_flow(quantity = "Power", unit = "W");
//   protected final parameter Real seg.pipFil.Rgg.R(quantity = "ThermalResistance", unit = "K/W") = seg.pipFil.Rgg_val;
//   protected Real seg.pipFil.RVol1.y = Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.convectionResistance(seg.pipFil.hSeg, seg.pipFil.rTub, 0.598, 0.001, 4184.0, seg.pipFil.m1_flow, 0.2);
//   protected Real seg.pipFil.RVol2.y = Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.convectionResistance(seg.pipFil.hSeg, seg.pipFil.rTub, 0.598, 0.001, 4184.0, seg.pipFil.m2_flow, 0.2);
//   final parameter Real seg.soi.material.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.matSoi.k;
//   final parameter Real seg.soi.material.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = 840.0;
//   final parameter Real seg.soi.material.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 2000.0;
//   final parameter Boolean seg.soi.material.steadyState = false;
//   final parameter Real seg.soi.h(quantity = "Length", unit = "m", min = 0.0) = seg.hSeg;
//   final parameter Real seg.soi.r_a(quantity = "Length", unit = "m", min = 0.0) = seg.rBor;
//   final parameter Real seg.soi.r_b(quantity = "Length", unit = "m", min = 0.0) = seg.rExt;
//   final parameter Integer seg.soi.nSta(min = 1) = 9;
//   final parameter Real seg.soi.TInt_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = seg.TFil_start;
//   final parameter Real seg.soi.TExt_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = seg.TExt_start;
//   final parameter Boolean seg.soi.steadyStateInitial = false;
//   parameter Real seg.soi.griFac(min = 1.0) = 2.0;
//   Real seg.soi.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   Real seg.soi.port_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.soi.port_a.Q_flow(quantity = "Power", unit = "W");
//   Real seg.soi.port_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.soi.port_b.Q_flow(quantity = "Power", unit = "W");
//   Real seg.soi.T[1](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 0.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.T[2](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 1.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.T[3](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 2.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.T[4](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 3.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.T[5](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 4.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.T[6](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 5.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.T[7](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 6.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.T[8](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 7.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.T[9](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log((seg.soi.r_a + (seg.soi.r_b - seg.soi.r_a) / 9.0 * 8.5) / seg.soi.r_a), nominal = 300.0);
//   Real seg.soi.Q_flow[1](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[2](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[3](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[4](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[5](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[6](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[7](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[8](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[9](quantity = "Power", unit = "W");
//   Real seg.soi.Q_flow[10](quantity = "Power", unit = "W");
//   protected parameter Real seg.soi.r[1](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[2](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[3](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[4](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[5](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[6](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[7](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[8](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[9](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.r[10](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[1](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[2](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[3](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[4](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[5](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[6](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[7](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[8](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected parameter Real seg.soi.rC[9](quantity = "Length", unit = "m", min = 0.0, fixed = false);
//   protected final parameter Real seg.soi.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = seg.soi.material.c;
//   protected final parameter Real seg.soi.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.soi.material.k;
//   protected final parameter Real seg.soi.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = seg.soi.material.d;
//   protected parameter Real seg.soi.G[1](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[2](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[3](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[4](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[5](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[6](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[7](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[8](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[9](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.G[10](quantity = "ThermalConductance", unit = "W/K", fixed = false);
//   protected parameter Real seg.soi.C[1](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   protected parameter Real seg.soi.C[2](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   protected parameter Real seg.soi.C[3](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   protected parameter Real seg.soi.C[4](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   protected parameter Real seg.soi.C[5](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   protected parameter Real seg.soi.C[6](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   protected parameter Real seg.soi.C[7](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   protected parameter Real seg.soi.C[8](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   protected parameter Real seg.soi.C[9](quantity = "HeatCapacity", unit = "J/K", fixed = false);
//   final parameter Real seg.TBouCon.matSoi.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.matSoi.k;
//   final parameter Real seg.TBouCon.matSoi.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = 840.0;
//   final parameter Real seg.TBouCon.matSoi.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 2000.0;
//   final parameter Boolean seg.TBouCon.matSoi.steadyState = false;
//   final parameter Real seg.TBouCon.rExt(quantity = "Length", unit = "m", min = 0.0) = seg.rExt;
//   final parameter Real seg.TBouCon.hSeg(quantity = "Length", unit = "m", min = 0.0) = seg.hSeg;
//   final parameter Real seg.TBouCon.TExt_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = seg.TExt_start;
//   final parameter Real seg.TBouCon.samplePeriod(quantity = "Time", unit = "s") = seg.samplePeriod;
//   Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray seg.TBouCon.table = Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.ExtendableArray.constructor();
//   Real seg.TBouCon.QAve_flow(quantity = "Power", unit = "W");
//   Real seg.TBouCon.Q_flow(unit = "W");
//   Real seg.TBouCon.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real seg.TBouCon.port.Q_flow(quantity = "Power", unit = "W");
//   protected final parameter Real seg.TBouCon.c(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = seg.TBouCon.matSoi.c;
//   protected final parameter Real seg.TBouCon.k(quantity = "ThermalConductivity", unit = "W/(m.K)") = seg.TBouCon.matSoi.k;
//   protected final parameter Real seg.TBouCon.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = seg.TBouCon.matSoi.d;
//   protected Real seg.TBouCon.UOld(quantity = "Energy", unit = "J");
//   protected Real seg.TBouCon.U(quantity = "Energy", unit = "J");
//   protected final parameter Real seg.TBouCon.startTime(quantity = "Time", unit = "s", fixed = false);
//   protected Integer seg.TBouCon.iSam(min = 1);
//   protected Real seg.heaFlo.Q_flow(unit = "W");
//   protected Real seg.heaFlo.port_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.heaFlo.port_a.Q_flow(quantity = "Power", unit = "W");
//   protected Real seg.heaFlo.port_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real seg.heaFlo.port_b.Q_flow(quantity = "Power", unit = "W");
//   final parameter Integer sou_1.nPorts = 1;
//   Real sou_1.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 1e5);
//   Real sou_1.medium.h(quantity = "SpecificEnergy", unit = "J/kg");
//   Real sou_1.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 1e5, start = 1.0, nominal = 1.0);
//   Real sou_1.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0);
//   Real sou_1.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   Real sou_1.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -1e8, max = 1e8, nominal = 1e6);
//   Real sou_1.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 1e7, start = 1000.0, nominal = 1000.0);
//   Real sou_1.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   Real sou_1.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   Real sou_1.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   final parameter Boolean sou_1.medium.preferredMediumStates = false;
//   final parameter Boolean sou_1.medium.standardOrderComponents = true;
//   Real sou_1.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(sou_1.medium.T);
//   Real sou_1.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(sou_1.medium.p);
//   Real sou_1.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e60, max = 1e60);
//   Real sou_1.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real sou_1.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   protected final parameter enumeration(Entering, Leaving, Bidirectional) sou_1.flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional;
//   final parameter Boolean sou_1.use_p_in = false;
//   final parameter Boolean sou_1.use_T_in = false;
//   final parameter Boolean sou_1.use_X_in = false;
//   final parameter Boolean sou_1.use_C_in = false;
//   parameter Real sou_1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = 101340.0;
//   parameter Real sou_1.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = 303.15;
//   parameter Real sou_1.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   protected Real sou_1.p_in_internal;
//   protected Real sou_1.T_in_internal;
//   protected Real sou_1.X_in_internal[1];
//   final parameter Integer sin_2.nPorts = 1;
//   Real sin_2.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 1e5);
//   Real sin_2.medium.h(quantity = "SpecificEnergy", unit = "J/kg");
//   Real sin_2.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 1e5, start = 1.0, nominal = 1.0);
//   Real sin_2.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0);
//   Real sin_2.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   Real sin_2.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -1e8, max = 1e8, nominal = 1e6);
//   Real sin_2.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 1e7, start = 1000.0, nominal = 1000.0);
//   Real sin_2.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   Real sin_2.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 3e5, nominal = 1e5);
//   Real sin_2.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 293.15, nominal = 300.0);
//   final parameter Boolean sin_2.medium.preferredMediumStates = false;
//   final parameter Boolean sin_2.medium.standardOrderComponents = true;
//   Real sin_2.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(sin_2.medium.T);
//   Real sin_2.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(sin_2.medium.p);
//   Real sin_2.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -1e60, max = 1e60);
//   Real sin_2.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5);
//   Real sin_2.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -1e10, max = 1e10, nominal = 1e6);
//   protected final parameter enumeration(Entering, Leaving, Bidirectional) sin_2.flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional;
//   final parameter Boolean sin_2.use_p_in = false;
//   final parameter Boolean sin_2.use_T_in = false;
//   final parameter Boolean sin_2.use_X_in = false;
//   final parameter Boolean sin_2.use_C_in = false;
//   parameter Real sin_2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 1e8, start = 1e5, nominal = 1e5) = 101330.0;
//   parameter Real sin_2.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 1e4, start = 300.0, nominal = 300.0) = 283.15;
//   parameter Real sin_2.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   protected Real sin_2.p_in_internal;
//   protected Real sin_2.T_in_internal;
//   protected Real sin_2.X_in_internal[1];
// initial equation
//   der(seg.pipFil.vol1.dynBal.medium.T) = 0.0;
//   der(seg.pipFil.vol2.dynBal.medium.T) = 0.0;
//   seg.pipFil.sta1_start = BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.setState_pTX(seg.pipFil.p1_start, seg.pipFil.T1_start, seg.pipFil.X1_start);
//   seg.pipFil.sta2_start = BoreholeSegment.seg.pipFil.vol1.dynBal.Medium.setState_pTX(seg.pipFil.p2_start, seg.pipFil.T2_start, seg.pipFil.X2_start);
//   (seg.pipFil.Rgb_val, seg.pipFil.Rgg_val, seg.pipFil.RCondGro_val, seg.pipFil.x) = Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.singleUTubeResistances(seg.pipFil.hSeg, seg.pipFil.rBor, seg.pipFil.rTub, seg.pipFil.eTub, seg.pipFil.xC, seg.pipFil.matSoi.k, seg.pipFil.matFil.k, seg.pipFil.kTub);
//   assert(seg.soi.r_a < seg.soi.r_b, "Error: Model requires r_a < r_b.");
//   assert(0.0 < seg.soi.r_a, "Error: Model requires 0 < r_a.");
//   seg.soi.r[1] = seg.soi.r_a;
//   seg.soi.r[2] = seg.soi.r[1] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0);
//   seg.soi.r[3] = seg.soi.r[2] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0) * seg.soi.griFac;
//   seg.soi.r[4] = seg.soi.r[3] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0) * seg.soi.griFac ^ 2.0;
//   seg.soi.r[5] = seg.soi.r[4] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0) * seg.soi.griFac ^ 3.0;
//   seg.soi.r[6] = seg.soi.r[5] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0) * seg.soi.griFac ^ 4.0;
//   seg.soi.r[7] = seg.soi.r[6] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0) * seg.soi.griFac ^ 5.0;
//   seg.soi.r[8] = seg.soi.r[7] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0) * seg.soi.griFac ^ 6.0;
//   seg.soi.r[9] = seg.soi.r[8] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0) * seg.soi.griFac ^ 7.0;
//   seg.soi.r[10] = seg.soi.r[9] + (seg.soi.r_b - seg.soi.r_a) * (1.0 - seg.soi.griFac) / (1.0 - seg.soi.griFac ^ 9.0) * seg.soi.griFac ^ 8.0;
//   assert(abs(seg.soi.r[10] - seg.soi.r_b) < 1e-10, "Error: Wrong computation of radius. r[nSta+1]=" + String(seg.soi.r[9 + 1], 6, 0, true));
//   seg.soi.rC[1] = (seg.soi.r[1] + seg.soi.r[2]) / 2.0;
//   seg.soi.rC[2] = (seg.soi.r[2] + seg.soi.r[3]) / 2.0;
//   seg.soi.rC[3] = (seg.soi.r[3] + seg.soi.r[4]) / 2.0;
//   seg.soi.rC[4] = (seg.soi.r[4] + seg.soi.r[5]) / 2.0;
//   seg.soi.rC[5] = (seg.soi.r[5] + seg.soi.r[6]) / 2.0;
//   seg.soi.rC[6] = (seg.soi.r[6] + seg.soi.r[7]) / 2.0;
//   seg.soi.rC[7] = (seg.soi.r[7] + seg.soi.r[8]) / 2.0;
//   seg.soi.rC[8] = (seg.soi.r[8] + seg.soi.r[9]) / 2.0;
//   seg.soi.rC[9] = (seg.soi.r[9] + seg.soi.r[10]) / 2.0;
//   seg.soi.G[1] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[1] / seg.soi.r_a);
//   seg.soi.G[10] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.r_b / seg.soi.rC[9]);
//   seg.soi.G[2] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[2] / seg.soi.rC[1]);
//   seg.soi.G[3] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[3] / seg.soi.rC[2]);
//   seg.soi.G[4] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[4] / seg.soi.rC[3]);
//   seg.soi.G[5] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[5] / seg.soi.rC[4]);
//   seg.soi.G[6] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[6] / seg.soi.rC[5]);
//   seg.soi.G[7] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[7] / seg.soi.rC[6]);
//   seg.soi.G[8] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[8] / seg.soi.rC[7]);
//   seg.soi.G[9] = 6.283185307179586 * seg.soi.k * seg.soi.h / log(seg.soi.rC[9] / seg.soi.rC[8]);
//   seg.soi.C[1] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[2] ^ 2.0 - seg.soi.r[1] ^ 2.0);
//   seg.soi.C[2] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[3] ^ 2.0 - seg.soi.r[2] ^ 2.0);
//   seg.soi.C[3] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[4] ^ 2.0 - seg.soi.r[3] ^ 2.0);
//   seg.soi.C[4] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[5] ^ 2.0 - seg.soi.r[4] ^ 2.0);
//   seg.soi.C[5] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[6] ^ 2.0 - seg.soi.r[5] ^ 2.0);
//   seg.soi.C[6] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[7] ^ 2.0 - seg.soi.r[6] ^ 2.0);
//   seg.soi.C[7] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[8] ^ 2.0 - seg.soi.r[7] ^ 2.0);
//   seg.soi.C[8] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[9] ^ 2.0 - seg.soi.r[8] ^ 2.0);
//   seg.soi.C[9] = seg.soi.d * 3.141592653589793 * seg.soi.c * seg.soi.h * (seg.soi.r[10] ^ 2.0 - seg.soi.r[9] ^ 2.0);
//   if not seg.soi.material.steadyState then
//     seg.soi.T[1] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[1] / seg.soi.r_a);
//     seg.soi.T[2] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[2] / seg.soi.r_a);
//     seg.soi.T[3] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[3] / seg.soi.r_a);
//     seg.soi.T[4] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[4] / seg.soi.r_a);
//     seg.soi.T[5] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[5] / seg.soi.r_a);
//     seg.soi.T[6] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[6] / seg.soi.r_a);
//     seg.soi.T[7] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[7] / seg.soi.r_a);
//     seg.soi.T[8] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[8] / seg.soi.r_a);
//     seg.soi.T[9] = seg.soi.TInt_start + (seg.soi.TExt_start - seg.soi.TInt_start) / log(seg.soi.r_b / seg.soi.r_a) * log(seg.soi.rC[9] / seg.soi.r_a);
//   end if;
// initial algorithm
//   assert(seg.pipFil.tau1 > 1e-15, "The parameter tau1, or the volume of the model from which tau may be derived, is unreasonably small.
//            You need to set energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState to model steady-state.
//            Received tau1 = " + String(seg.pipFil.tau1, 6, 0, true) + "
//   ");
//   assert(seg.pipFil.tau1 > 1e-15, "The parameter tau1, or the volume of the model from which tau may be derived, is unreasonably small.
//            You need to set massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState to model steady-state.
//            Received tau1 = " + String(seg.pipFil.tau1, 6, 0, true) + "
//   ");
//   assert(seg.pipFil.tau2 > 1e-15, "The parameter tau2, or the volume of the model from which tau may be derived, is unreasonably small.
//            You need to set energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState to model steady-state.
//            Received tau2 = " + String(seg.pipFil.tau2, 6, 0, true) + "
//   ");
//   assert(seg.pipFil.tau2 > 1e-15, "The parameter tau2, or the volume of the model from which tau may be derived, is unreasonably small.
//            You need to set massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState to model steady-state.
//            Received tau2 = " + String(seg.pipFil.tau2, 6, 0, true) + "
//   ");
// initial algorithm
//   seg.TBouCon.U := 0.0;
//   seg.TBouCon.UOld := 0.0;
//   seg.TBouCon.startTime := time;
//   seg.TBouCon.iSam := 1;
// equation
//   seg.pipFil.vol1.masExc.y = seg.pipFil.vol1.dynBal.mWat_flow;
//   seg.pipFil.vol1.QSen_flow.y = seg.pipFil.vol1.dynBal.Q_flow;
//   seg.pipFil.vol1.dynBal.ports[1].p = seg.pipFil.vol1.ports[1].p;
//   seg.pipFil.vol1.dynBal.ports[1].h_outflow = seg.pipFil.vol1.ports[1].h_outflow;
//   seg.pipFil.vol1.dynBal.ports[2].p = seg.pipFil.vol1.ports[2].p;
//   seg.pipFil.vol1.dynBal.ports[2].h_outflow = seg.pipFil.vol1.ports[2].h_outflow;
//   seg.pipFil.vol1.hOut_internal = seg.pipFil.vol1.dynBal.hOut;
//   seg.pipFil.vol2.masExc.y = seg.pipFil.vol2.dynBal.mWat_flow;
//   seg.pipFil.vol2.QSen_flow.y = seg.pipFil.vol2.dynBal.Q_flow;
//   seg.pipFil.vol2.dynBal.ports[1].p = seg.pipFil.vol2.ports[1].p;
//   seg.pipFil.vol2.dynBal.ports[1].h_outflow = seg.pipFil.vol2.ports[1].h_outflow;
//   seg.pipFil.vol2.dynBal.ports[2].p = seg.pipFil.vol2.ports[2].p;
//   seg.pipFil.vol2.dynBal.ports[2].h_outflow = seg.pipFil.vol2.ports[2].h_outflow;
//   seg.pipFil.vol2.hOut_internal = seg.pipFil.vol2.dynBal.hOut;
//   seg.pipFil.vol1.heatPort.T = seg.pipFil.RConv1.fluid.T;
//   seg.pipFil.RConv1.solid.T = seg.pipFil.Rpg1.port_a.T;
//   seg.pipFil.capFil1.port.T = seg.pipFil.Rgg.port_a.T;
//   seg.pipFil.capFil1.port.T = seg.pipFil.Rgb1.port_a.T;
//   seg.pipFil.capFil1.port.T = seg.pipFil.Rpg1.port_b.T;
//   seg.pipFil.Rgb2.port_b.T = seg.pipFil.port.T;
//   seg.pipFil.Rgb2.port_b.T = seg.pipFil.Rgb1.port_b.T;
//   seg.pipFil.RConv2.solid.T = seg.pipFil.Rpg2.port_a.T;
//   seg.pipFil.Rgg.port_b.T = seg.pipFil.capFil2.port.T;
//   seg.pipFil.Rgg.port_b.T = seg.pipFil.Rgb2.port_a.T;
//   seg.pipFil.Rgg.port_b.T = seg.pipFil.Rpg2.port_b.T;
//   seg.pipFil.RConv2.fluid.T = seg.pipFil.vol2.heatPort.T;
//   seg.pipFil.RVol1.y = seg.pipFil.RConv1.Rc;
//   seg.pipFil.RVol2.y = seg.pipFil.RConv2.Rc;
//   seg.pipFil.vol1.ports[2].p = seg.pipFil.port_b1.p;
//   seg.pipFil.vol1.ports[2].h_outflow = seg.pipFil.port_b1.h_outflow;
//   seg.pipFil.vol2.ports[2].p = seg.pipFil.port_b2.p;
//   seg.pipFil.vol2.ports[2].h_outflow = seg.pipFil.port_b2.h_outflow;
//   seg.pipFil.port_a1.p = seg.pipFil.preDro1.port_a.p;
//   seg.pipFil.preDro1.port_a.m_flow - seg.pipFil.port_a1.m_flow = 0.0;
//   seg.pipFil.preDro1.port_a.h_outflow = seg.pipFil.port_a1.h_outflow;
//   seg.pipFil.preDro1.port_b.p = seg.pipFil.vol1.ports[1].p;
//   seg.pipFil.port_a2.p = seg.pipFil.preDro2.port_a.p;
//   seg.pipFil.preDro2.port_a.m_flow - seg.pipFil.port_a2.m_flow = 0.0;
//   seg.pipFil.preDro2.port_a.h_outflow = seg.pipFil.port_a2.h_outflow;
//   seg.pipFil.preDro2.port_b.p = seg.pipFil.vol2.ports[1].p;
//   seg.pipFil.port_b1.p = seg.port_b1.p;
//   seg.pipFil.port_b1.h_outflow = seg.port_b1.h_outflow;
//   seg.pipFil.port_a2.p = seg.port_a2.p;
//   seg.pipFil.port_a2.h_outflow = seg.port_a2.h_outflow;
//   seg.pipFil.port_b2.p = seg.port_b2.p;
//   seg.pipFil.port_b2.h_outflow = seg.port_b2.h_outflow;
//   seg.pipFil.port.T = seg.heaFlo.port_a.T;
//   seg.heaFlo.port_b.T = seg.soi.port_a.T;
//   seg.soi.port_b.T = seg.TBouCon.port.T;
//   seg.port_a1.p = seg.pipFil.port_a1.p;
//   seg.pipFil.port_a1.m_flow - seg.port_a1.m_flow = 0.0;
//   seg.pipFil.port_a1.h_outflow = seg.port_a1.h_outflow;
//   seg.heaFlo.Q_flow = seg.TBouCon.Q_flow;
//   sou_1.ports[1].p = seg.port_a1.p;
//   seg.port_b1.p = seg.port_a2.p;
//   seg.port_b2.p = sin_2.ports[1].p;
//   seg.port_a2.m_flow + seg.port_b1.m_flow = 0.0;
//   sin_2.ports[1].m_flow + seg.port_b2.m_flow = 0.0;
//   seg.pipFil.port_b1.m_flow - seg.port_b1.m_flow = 0.0;
//   seg.pipFil.port_a2.m_flow - seg.port_a2.m_flow = 0.0;
//   seg.pipFil.port_b2.m_flow - seg.port_b2.m_flow = 0.0;
//   seg.pipFil.vol1.ports[2].m_flow - seg.pipFil.port_b1.m_flow = 0.0;
//   seg.pipFil.RConv1.fluid.Q_flow + seg.pipFil.vol1.heatPort.Q_flow = 0.0;
//   seg.pipFil.vol1.dynBal.ports[1].m_flow - seg.pipFil.vol1.ports[1].m_flow = 0.0;
//   seg.pipFil.vol1.dynBal.ports[2].m_flow - seg.pipFil.vol1.ports[2].m_flow = 0.0;
//   seg.pipFil.vol2.ports[2].m_flow - seg.pipFil.port_b2.m_flow = 0.0;
//   seg.pipFil.vol2.dynBal.ports[1].m_flow - seg.pipFil.vol2.ports[1].m_flow = 0.0;
//   seg.pipFil.vol2.dynBal.ports[2].m_flow - seg.pipFil.vol2.ports[2].m_flow = 0.0;
//   seg.pipFil.preDro1.port_b.m_flow + seg.pipFil.vol1.ports[1].m_flow = 0.0;
//   seg.pipFil.preDro2.port_b.m_flow + seg.pipFil.vol2.ports[1].m_flow = 0.0;
//   seg.heaFlo.port_a.Q_flow + seg.pipFil.port.Q_flow = 0.0;
//   seg.pipFil.Rpg1.port_a.Q_flow + seg.pipFil.RConv1.solid.Q_flow = 0.0;
//   seg.pipFil.Rpg2.port_a.Q_flow + seg.pipFil.RConv2.solid.Q_flow = 0.0;
//   seg.pipFil.RConv2.fluid.Q_flow + seg.pipFil.vol2.heatPort.Q_flow = 0.0;
//   seg.pipFil.Rgg.port_a.Q_flow + seg.pipFil.Rgb1.port_a.Q_flow + seg.pipFil.Rpg1.port_b.Q_flow + seg.pipFil.capFil1.port.Q_flow = 0.0;
//   seg.pipFil.Rgg.port_b.Q_flow + seg.pipFil.Rgb2.port_a.Q_flow + seg.pipFil.Rpg2.port_b.Q_flow + seg.pipFil.capFil2.port.Q_flow = 0.0;
//   seg.pipFil.Rgb2.port_b.Q_flow + seg.pipFil.Rgb1.port_b.Q_flow - seg.pipFil.port.Q_flow = 0.0;
//   seg.TBouCon.port.Q_flow + seg.soi.port_b.Q_flow = 0.0;
//   seg.heaFlo.port_b.Q_flow + seg.soi.port_a.Q_flow = 0.0;
//   sou_1.ports[1].m_flow + seg.port_a1.m_flow = 0.0;
//   seg.state_a1_inflow = BoreholeSegment.seg.Medium1.setState_phX(seg.port_a1.p, sou_1.ports[1].h_outflow, {});
//   seg.state_b1_inflow = BoreholeSegment.seg.Medium1.setState_phX(seg.port_b1.p, seg.port_a2.h_outflow, {});
//   seg.state_a2_inflow = BoreholeSegment.seg.Medium1.setState_phX(seg.port_a2.p, seg.port_b1.h_outflow, {});
//   seg.state_b2_inflow = BoreholeSegment.seg.Medium1.setState_phX(seg.port_b2.p, sin_2.ports[1].h_outflow, {});
//   seg.pipFil.state_a1_inflow = BoreholeSegment.seg.Medium1.setState_phX(seg.pipFil.port_a1.p, sou_1.ports[1].h_outflow, {});
//   seg.pipFil.state_b1_inflow = BoreholeSegment.seg.Medium1.setState_phX(seg.pipFil.port_b1.p, seg.port_a2.h_outflow, {});
//   seg.pipFil.state_a2_inflow = BoreholeSegment.seg.Medium1.setState_phX(seg.pipFil.port_a2.p, seg.port_b1.h_outflow, {});
//   seg.pipFil.state_b2_inflow = BoreholeSegment.seg.Medium1.setState_phX(seg.pipFil.port_b2.p, sin_2.ports[1].h_outflow, {});
//   assert(seg.pipFil.vol1.dynBal.medium.T >= 272.15 and seg.pipFil.vol1.dynBal.medium.T <= 403.15, "
//             Temperature T (= " + String(seg.pipFil.vol1.dynBal.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   seg.pipFil.vol1.dynBal.medium.h = BoreholeSegment.Medium.specificEnthalpy_pTX(seg.pipFil.vol1.dynBal.medium.p, seg.pipFil.vol1.dynBal.medium.T, seg.pipFil.vol1.dynBal.medium.X);
//   seg.pipFil.vol1.dynBal.medium.u = 4184.0 * (seg.pipFil.vol1.dynBal.medium.T - 273.15);
//   seg.pipFil.vol1.dynBal.medium.d = 995.586;
//   seg.pipFil.vol1.dynBal.medium.R = 0.0;
//   seg.pipFil.vol1.dynBal.medium.MM = 0.018015268;
//   seg.pipFil.vol1.dynBal.medium.state.T = seg.pipFil.vol1.dynBal.medium.T;
//   seg.pipFil.vol1.dynBal.medium.state.p = seg.pipFil.vol1.dynBal.medium.p;
//   seg.pipFil.vol1.dynBal.medium.X[1] = 1.0;
//   assert(seg.pipFil.vol1.dynBal.medium.X[1] >= -1e-5 and seg.pipFil.vol1.dynBal.medium.X[1] <= 1.00001, "Mass fraction X[" + String(1, 0, true) + "] = " + String(seg.pipFil.vol1.dynBal.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(seg.pipFil.vol1.dynBal.medium.p >= 0.0, "Pressure (= " + String(seg.pipFil.vol1.dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(seg.pipFil.vol1.dynBal.medium.T, 6, 0, true) + " K)");
//   seg.pipFil.vol1.dynBal.m = seg.pipFil.vol1.dynBal.fluidVolume * seg.pipFil.vol1.dynBal.medium.d;
//   seg.pipFil.vol1.dynBal.U = seg.pipFil.vol1.dynBal.m * seg.pipFil.vol1.dynBal.medium.u;
//   seg.pipFil.vol1.dynBal.hOut = seg.pipFil.vol1.dynBal.medium.h;
//   seg.pipFil.vol1.dynBal.ports_H_flow[1] = smooth(0, seg.pipFil.vol1.dynBal.ports[1].m_flow * (if seg.pipFil.vol1.dynBal.ports[1].m_flow > 0.0 then seg.pipFil.preDro1.port_b.h_outflow else seg.pipFil.vol1.dynBal.ports[1].h_outflow));
//   seg.pipFil.vol1.dynBal.ports_H_flow[2] = smooth(0, seg.pipFil.vol1.dynBal.ports[2].m_flow * (if seg.pipFil.vol1.dynBal.ports[2].m_flow > 0.0 then seg.port_a2.h_outflow else seg.pipFil.vol1.dynBal.ports[2].h_outflow));
//   seg.pipFil.vol1.dynBal.mb_flow = seg.pipFil.vol1.dynBal.ports[1].m_flow + seg.pipFil.vol1.dynBal.ports[2].m_flow;
//   seg.pipFil.vol1.dynBal.Hb_flow = seg.pipFil.vol1.dynBal.ports_H_flow[1] + seg.pipFil.vol1.dynBal.ports_H_flow[2];
//   der(seg.pipFil.vol1.dynBal.U) = seg.pipFil.vol1.dynBal.Hb_flow + seg.pipFil.vol1.dynBal.Q_flow;
//   der(seg.pipFil.vol1.dynBal.m) = seg.pipFil.vol1.dynBal.mb_flow + seg.pipFil.vol1.dynBal.mWat_flow;
//   seg.pipFil.vol1.dynBal.ports[1].p = seg.pipFil.vol1.dynBal.medium.p;
//   seg.pipFil.vol1.dynBal.ports[1].h_outflow = seg.pipFil.vol1.dynBal.medium.h;
//   seg.pipFil.vol1.dynBal.ports[2].p = seg.pipFil.vol1.dynBal.medium.p;
//   seg.pipFil.vol1.dynBal.ports[2].h_outflow = seg.pipFil.vol1.dynBal.medium.h;
//   seg.pipFil.vol1.masExc.y = 0.0;
//   seg.pipFil.vol1.p = seg.pipFil.vol1.ports[1].p;
//   seg.pipFil.vol1.T = BoreholeSegment.Medium.temperature_phX(seg.pipFil.vol1.p, seg.pipFil.vol1.hOut_internal, {1.0});
//   seg.pipFil.vol1.heatPort.T = seg.pipFil.vol1.T;
//   assert(seg.pipFil.vol2.dynBal.medium.T >= 272.15 and seg.pipFil.vol2.dynBal.medium.T <= 403.15, "
//             Temperature T (= " + String(seg.pipFil.vol2.dynBal.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   seg.pipFil.vol2.dynBal.medium.h = BoreholeSegment.Medium.specificEnthalpy_pTX(seg.pipFil.vol2.dynBal.medium.p, seg.pipFil.vol2.dynBal.medium.T, seg.pipFil.vol2.dynBal.medium.X);
//   seg.pipFil.vol2.dynBal.medium.u = 4184.0 * (seg.pipFil.vol2.dynBal.medium.T - 273.15);
//   seg.pipFil.vol2.dynBal.medium.d = 995.586;
//   seg.pipFil.vol2.dynBal.medium.R = 0.0;
//   seg.pipFil.vol2.dynBal.medium.MM = 0.018015268;
//   seg.pipFil.vol2.dynBal.medium.state.T = seg.pipFil.vol2.dynBal.medium.T;
//   seg.pipFil.vol2.dynBal.medium.state.p = seg.pipFil.vol2.dynBal.medium.p;
//   seg.pipFil.vol2.dynBal.medium.X[1] = 1.0;
//   assert(seg.pipFil.vol2.dynBal.medium.X[1] >= -1e-5 and seg.pipFil.vol2.dynBal.medium.X[1] <= 1.00001, "Mass fraction X[" + String(1, 0, true) + "] = " + String(seg.pipFil.vol2.dynBal.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(seg.pipFil.vol2.dynBal.medium.p >= 0.0, "Pressure (= " + String(seg.pipFil.vol2.dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(seg.pipFil.vol2.dynBal.medium.T, 6, 0, true) + " K)");
//   seg.pipFil.vol2.dynBal.m = seg.pipFil.vol2.dynBal.fluidVolume * seg.pipFil.vol2.dynBal.medium.d;
//   seg.pipFil.vol2.dynBal.U = seg.pipFil.vol2.dynBal.m * seg.pipFil.vol2.dynBal.medium.u;
//   seg.pipFil.vol2.dynBal.hOut = seg.pipFil.vol2.dynBal.medium.h;
//   seg.pipFil.vol2.dynBal.ports_H_flow[1] = smooth(0, seg.pipFil.vol2.dynBal.ports[1].m_flow * (if seg.pipFil.vol2.dynBal.ports[1].m_flow > 0.0 then seg.pipFil.preDro2.port_b.h_outflow else seg.pipFil.vol2.dynBal.ports[1].h_outflow));
//   seg.pipFil.vol2.dynBal.ports_H_flow[2] = smooth(0, seg.pipFil.vol2.dynBal.ports[2].m_flow * (if seg.pipFil.vol2.dynBal.ports[2].m_flow > 0.0 then sin_2.ports[1].h_outflow else seg.pipFil.vol2.dynBal.ports[2].h_outflow));
//   seg.pipFil.vol2.dynBal.mb_flow = seg.pipFil.vol2.dynBal.ports[1].m_flow + seg.pipFil.vol2.dynBal.ports[2].m_flow;
//   seg.pipFil.vol2.dynBal.Hb_flow = seg.pipFil.vol2.dynBal.ports_H_flow[1] + seg.pipFil.vol2.dynBal.ports_H_flow[2];
//   der(seg.pipFil.vol2.dynBal.U) = seg.pipFil.vol2.dynBal.Hb_flow + seg.pipFil.vol2.dynBal.Q_flow;
//   der(seg.pipFil.vol2.dynBal.m) = seg.pipFil.vol2.dynBal.mb_flow + seg.pipFil.vol2.dynBal.mWat_flow;
//   seg.pipFil.vol2.dynBal.ports[1].p = seg.pipFil.vol2.dynBal.medium.p;
//   seg.pipFil.vol2.dynBal.ports[1].h_outflow = seg.pipFil.vol2.dynBal.medium.h;
//   seg.pipFil.vol2.dynBal.ports[2].p = seg.pipFil.vol2.dynBal.medium.p;
//   seg.pipFil.vol2.dynBal.ports[2].h_outflow = seg.pipFil.vol2.dynBal.medium.h;
//   seg.pipFil.vol2.masExc.y = 0.0;
//   seg.pipFil.vol2.p = seg.pipFil.vol2.ports[1].p;
//   seg.pipFil.vol2.T = BoreholeSegment.Medium.temperature_phX(seg.pipFil.vol2.p, seg.pipFil.vol2.hOut_internal, {1.0});
//   seg.pipFil.vol2.heatPort.T = seg.pipFil.vol2.T;
//   seg.pipFil.preDro1.dp = homotopy(Buildings.Fluid.BaseClasses.FlowModels.basicFlowFunction_m_flow(seg.pipFil.preDro1.m_flow, seg.pipFil.preDro1.k, 0.020000000000000004), 5.0 * seg.pipFil.preDro1.m_flow / 0.2);
//   seg.pipFil.preDro1.port_a.h_outflow = seg.pipFil.vol1.ports[1].h_outflow;
//   seg.pipFil.preDro1.port_b.h_outflow = sou_1.ports[1].h_outflow;
//   seg.pipFil.preDro1.port_a.m_flow + seg.pipFil.preDro1.port_b.m_flow = 0.0;
//   seg.pipFil.preDro1.dp = seg.pipFil.preDro1.port_a.p - seg.pipFil.preDro1.port_b.p;
//   seg.pipFil.preDro2.dp = 0.0;
//   seg.pipFil.preDro2.port_a.h_outflow = seg.pipFil.vol2.ports[1].h_outflow;
//   seg.pipFil.preDro2.port_b.h_outflow = seg.port_b1.h_outflow;
//   seg.pipFil.preDro2.port_a.m_flow + seg.pipFil.preDro2.port_b.m_flow = 0.0;
//   seg.pipFil.preDro2.dp = seg.pipFil.preDro2.port_a.p - seg.pipFil.preDro2.port_b.p;
//   seg.pipFil.capFil1.T = seg.pipFil.capFil1.port.T;
//   seg.pipFil.capFil1.der_T = der(seg.pipFil.capFil1.T);
//   seg.pipFil.capFil1.C * der(seg.pipFil.capFil1.T) = seg.pipFil.capFil1.port.Q_flow;
//   seg.pipFil.capFil2.T = seg.pipFil.capFil2.port.T;
//   seg.pipFil.capFil2.der_T = der(seg.pipFil.capFil2.T);
//   seg.pipFil.capFil2.C * der(seg.pipFil.capFil2.T) = seg.pipFil.capFil2.port.Q_flow;
//   seg.pipFil.RConv1.dT = seg.pipFil.RConv1.solid.T - seg.pipFil.RConv1.fluid.T;
//   seg.pipFil.RConv1.solid.Q_flow = seg.pipFil.RConv1.Q_flow;
//   seg.pipFil.RConv1.fluid.Q_flow = -seg.pipFil.RConv1.Q_flow;
//   seg.pipFil.RConv1.dT = seg.pipFil.RConv1.Rc * seg.pipFil.RConv1.Q_flow;
//   seg.pipFil.RConv2.dT = seg.pipFil.RConv2.solid.T - seg.pipFil.RConv2.fluid.T;
//   seg.pipFil.RConv2.solid.Q_flow = seg.pipFil.RConv2.Q_flow;
//   seg.pipFil.RConv2.fluid.Q_flow = -seg.pipFil.RConv2.Q_flow;
//   seg.pipFil.RConv2.dT = seg.pipFil.RConv2.Rc * seg.pipFil.RConv2.Q_flow;
//   seg.pipFil.Rpg1.dT = seg.pipFil.Rpg1.R * seg.pipFil.Rpg1.Q_flow;
//   seg.pipFil.Rpg1.dT = seg.pipFil.Rpg1.port_a.T - seg.pipFil.Rpg1.port_b.T;
//   seg.pipFil.Rpg1.port_a.Q_flow = seg.pipFil.Rpg1.Q_flow;
//   seg.pipFil.Rpg1.port_b.Q_flow = -seg.pipFil.Rpg1.Q_flow;
//   seg.pipFil.Rpg2.dT = seg.pipFil.Rpg2.R * seg.pipFil.Rpg2.Q_flow;
//   seg.pipFil.Rpg2.dT = seg.pipFil.Rpg2.port_a.T - seg.pipFil.Rpg2.port_b.T;
//   seg.pipFil.Rpg2.port_a.Q_flow = seg.pipFil.Rpg2.Q_flow;
//   seg.pipFil.Rpg2.port_b.Q_flow = -seg.pipFil.Rpg2.Q_flow;
//   seg.pipFil.Rgb1.dT = seg.pipFil.Rgb1.R * seg.pipFil.Rgb1.Q_flow;
//   seg.pipFil.Rgb1.dT = seg.pipFil.Rgb1.port_a.T - seg.pipFil.Rgb1.port_b.T;
//   seg.pipFil.Rgb1.port_a.Q_flow = seg.pipFil.Rgb1.Q_flow;
//   seg.pipFil.Rgb1.port_b.Q_flow = -seg.pipFil.Rgb1.Q_flow;
//   seg.pipFil.Rgb2.dT = seg.pipFil.Rgb2.R * seg.pipFil.Rgb2.Q_flow;
//   seg.pipFil.Rgb2.dT = seg.pipFil.Rgb2.port_a.T - seg.pipFil.Rgb2.port_b.T;
//   seg.pipFil.Rgb2.port_a.Q_flow = seg.pipFil.Rgb2.Q_flow;
//   seg.pipFil.Rgb2.port_b.Q_flow = -seg.pipFil.Rgb2.Q_flow;
//   seg.pipFil.Rgg.dT = seg.pipFil.Rgg.R * seg.pipFil.Rgg.Q_flow;
//   seg.pipFil.Rgg.dT = seg.pipFil.Rgg.port_a.T - seg.pipFil.Rgg.port_b.T;
//   seg.pipFil.Rgg.port_a.Q_flow = seg.pipFil.Rgg.Q_flow;
//   seg.pipFil.Rgg.port_b.Q_flow = -seg.pipFil.Rgg.Q_flow;
//   seg.pipFil.dp1 = seg.pipFil.port_a1.p - seg.pipFil.port_b1.p;
//   seg.pipFil.dp2 = seg.pipFil.port_a2.p - seg.pipFil.port_b2.p;
//   seg.soi.dT = seg.soi.port_a.T - seg.soi.port_b.T;
//   seg.soi.port_a.Q_flow = seg.soi.Q_flow[1];
//   seg.soi.port_b.Q_flow = -seg.soi.Q_flow[10];
//   seg.soi.Q_flow[1] = seg.soi.G[1] * (seg.soi.port_a.T - seg.soi.T[1]);
//   seg.soi.Q_flow[10] = seg.soi.G[10] * (seg.soi.T[9] - seg.soi.port_b.T);
//   seg.soi.Q_flow[2] = seg.soi.G[2] * (seg.soi.T[1] - seg.soi.T[2]);
//   seg.soi.Q_flow[3] = seg.soi.G[3] * (seg.soi.T[2] - seg.soi.T[3]);
//   seg.soi.Q_flow[4] = seg.soi.G[4] * (seg.soi.T[3] - seg.soi.T[4]);
//   seg.soi.Q_flow[5] = seg.soi.G[5] * (seg.soi.T[4] - seg.soi.T[5]);
//   seg.soi.Q_flow[6] = seg.soi.G[6] * (seg.soi.T[5] - seg.soi.T[6]);
//   seg.soi.Q_flow[7] = seg.soi.G[7] * (seg.soi.T[6] - seg.soi.T[7]);
//   seg.soi.Q_flow[8] = seg.soi.G[8] * (seg.soi.T[7] - seg.soi.T[8]);
//   seg.soi.Q_flow[9] = seg.soi.G[9] * (seg.soi.T[8] - seg.soi.T[9]);
//   if seg.soi.material.steadyState then
//     seg.soi.Q_flow[2] = seg.soi.Q_flow[1];
//     seg.soi.Q_flow[3] = seg.soi.Q_flow[1];
//     seg.soi.Q_flow[4] = seg.soi.Q_flow[1];
//     seg.soi.Q_flow[5] = seg.soi.Q_flow[1];
//     seg.soi.Q_flow[6] = seg.soi.Q_flow[1];
//     seg.soi.Q_flow[7] = seg.soi.Q_flow[1];
//     seg.soi.Q_flow[8] = seg.soi.Q_flow[1];
//     seg.soi.Q_flow[9] = seg.soi.Q_flow[1];
//     seg.soi.Q_flow[10] = seg.soi.Q_flow[1];
//   else
//     der(seg.soi.T[1]) = (seg.soi.Q_flow[1] - seg.soi.Q_flow[2]) / seg.soi.C[1];
//     der(seg.soi.T[2]) = (seg.soi.Q_flow[2] - seg.soi.Q_flow[3]) / seg.soi.C[2];
//     der(seg.soi.T[3]) = (seg.soi.Q_flow[3] - seg.soi.Q_flow[4]) / seg.soi.C[3];
//     der(seg.soi.T[4]) = (seg.soi.Q_flow[4] - seg.soi.Q_flow[5]) / seg.soi.C[4];
//     der(seg.soi.T[5]) = (seg.soi.Q_flow[5] - seg.soi.Q_flow[6]) / seg.soi.C[5];
//     der(seg.soi.T[6]) = (seg.soi.Q_flow[6] - seg.soi.Q_flow[7]) / seg.soi.C[6];
//     der(seg.soi.T[7]) = (seg.soi.Q_flow[7] - seg.soi.Q_flow[8]) / seg.soi.C[7];
//     der(seg.soi.T[8]) = (seg.soi.Q_flow[8] - seg.soi.Q_flow[9]) / seg.soi.C[8];
//     der(seg.soi.T[9]) = (seg.soi.Q_flow[9] - seg.soi.Q_flow[10]) / seg.soi.C[9];
//   end if;
//   der(seg.TBouCon.U) = seg.TBouCon.Q_flow;
//   seg.heaFlo.port_a.T = seg.heaFlo.port_b.T;
//   seg.heaFlo.port_a.Q_flow + seg.heaFlo.port_b.Q_flow = 0.0;
//   seg.heaFlo.Q_flow = seg.heaFlo.port_a.Q_flow;
//   seg.dp1 = seg.port_a1.p - seg.port_b1.p;
//   seg.dp2 = seg.port_a2.p - seg.port_b2.p;
//   assert(sou_1.medium.T >= 272.15 and sou_1.medium.T <= 403.15, "
//             Temperature T (= " + String(sou_1.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   sou_1.medium.h = BoreholeSegment.Medium.specificEnthalpy_pTX(sou_1.medium.p, sou_1.medium.T, sou_1.medium.X);
//   sou_1.medium.u = 4184.0 * (sou_1.medium.T - 273.15);
//   sou_1.medium.d = 995.586;
//   sou_1.medium.R = 0.0;
//   sou_1.medium.MM = 0.018015268;
//   sou_1.medium.state.T = sou_1.medium.T;
//   sou_1.medium.state.p = sou_1.medium.p;
//   sou_1.medium.X[1] = 1.0;
//   assert(sou_1.medium.X[1] >= -1e-5 and sou_1.medium.X[1] <= 1.00001, "Mass fraction X[" + String(1, 0, true) + "] = " + String(sou_1.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(sou_1.medium.p >= 0.0, "Pressure (= " + String(sou_1.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(sou_1.medium.T, 6, 0, true) + " K)");
//   Modelica.Fluid.Utilities.checkBoundary("SimpleLiquidWater", {"SimpleLiquidWater"}, true, true, sou_1.X_in_internal, "Boundary_pT");
//   sou_1.p_in_internal = sou_1.p;
//   sou_1.T_in_internal = sou_1.T;
//   sou_1.X_in_internal[1] = sou_1.X[1];
//   sou_1.medium.p = sou_1.p_in_internal;
//   sou_1.medium.T = sou_1.T_in_internal;
//   sou_1.ports[1].p = sou_1.medium.p;
//   sou_1.ports[1].h_outflow = sou_1.medium.h;
//   assert(sin_2.medium.T >= 272.15 and sin_2.medium.T <= 403.15, "
//             Temperature T (= " + String(sin_2.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   sin_2.medium.h = BoreholeSegment.Medium.specificEnthalpy_pTX(sin_2.medium.p, sin_2.medium.T, sin_2.medium.X);
//   sin_2.medium.u = 4184.0 * (sin_2.medium.T - 273.15);
//   sin_2.medium.d = 995.586;
//   sin_2.medium.R = 0.0;
//   sin_2.medium.MM = 0.018015268;
//   sin_2.medium.state.T = sin_2.medium.T;
//   sin_2.medium.state.p = sin_2.medium.p;
//   sin_2.medium.X[1] = 1.0;
//   assert(sin_2.medium.X[1] >= -1e-5 and sin_2.medium.X[1] <= 1.00001, "Mass fraction X[" + String(1, 0, true) + "] = " + String(sin_2.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(sin_2.medium.p >= 0.0, "Pressure (= " + String(sin_2.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(sin_2.medium.T, 6, 0, true) + " K)");
//   Modelica.Fluid.Utilities.checkBoundary("SimpleLiquidWater", {"SimpleLiquidWater"}, true, true, sin_2.X_in_internal, "Boundary_pT");
//   sin_2.p_in_internal = sin_2.p;
//   sin_2.T_in_internal = sin_2.T;
//   sin_2.X_in_internal[1] = sin_2.X[1];
//   sin_2.medium.p = sin_2.p_in_internal;
//   sin_2.medium.T = sin_2.T_in_internal;
//   sin_2.ports[1].p = sin_2.medium.p;
//   sin_2.ports[1].h_outflow = sin_2.medium.h;
// algorithm
//   when initial() or sample(seg.TBouCon.startTime, seg.TBouCon.samplePeriod) then
//     seg.TBouCon.QAve_flow := (seg.TBouCon.U - seg.TBouCon.UOld) / seg.TBouCon.samplePeriod;
//     seg.TBouCon.UOld := seg.TBouCon.U;
//     seg.TBouCon.port.T := seg.TBouCon.TExt_start + Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.temperatureDrop(seg.TBouCon.table, seg.TBouCon.iSam, seg.TBouCon.QAve_flow, seg.TBouCon.samplePeriod, seg.TBouCon.rExt, seg.TBouCon.hSeg, seg.TBouCon.k, seg.TBouCon.d, seg.TBouCon.c);
//     seg.TBouCon.iSam := seg.TBouCon.iSam + 1;
//   end when;
// end BoreholeSegment;
// [flattening/modelica/redeclare/AttributesPropagation.mo:978:11-978:87:writable] Warning: In relation bento.c == 0.0, == on Real operands is deprecated in non-function contexts.
// [flattening/modelica/redeclare/AttributesPropagation.mo:978:11-978:87:writable] Warning: In relation bento.d == 0.0, == on Real operands is deprecated in non-function contexts.
// [flattening/modelica/redeclare/AttributesPropagation.mo:978:11-978:87:writable] Warning: In relation seg.matSoi.c == 0.0, == on Real operands is deprecated in non-function contexts.
// [flattening/modelica/redeclare/AttributesPropagation.mo:978:11-978:87:writable] Warning: In relation seg.matSoi.d == 0.0, == on Real operands is deprecated in non-function contexts.
// [flattening/modelica/redeclare/AttributesPropagation.mo:314:13-314:298:writable] Warning: beta was used before it was defined (given a value). Additional such uses may exist for the variable, but some messages were suppressed.
// [flattening/modelica/redeclare/AttributesPropagation.mo:186:13-191:21:writable] Warning: initial() may only be used as a when condition (when initial() or when {..., initial(), ...}), but got condition 'initial() or sample(seg.TBouCon.startTime, seg.TBouCon.samplePeriod)'.
// [flattening/modelica/redeclare/AttributesPropagation.mo:253:11-282:30:writable] Warning: Pure function 'Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.temperatureDrop' contains a call to impure function 'Buildings.Fluid.HeatExchangers.Boreholes.BaseClasses.exchangeValues'.
//
// endResult
