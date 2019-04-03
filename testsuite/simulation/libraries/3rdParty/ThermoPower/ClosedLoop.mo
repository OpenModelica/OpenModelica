package ThermoPower  "Open library for thermal power plant simulation"
  extends Modelica.Icons.Package;

  model System  "System wide properties and defaults"
    parameter Boolean allowFlowReversal = true "= false to restrict to design flow direction (flangeA -> flangeB)" annotation(Evaluate = true);
    parameter Choices.Init.Options initOpt = Choices.Init.Options.fixedState;
    parameter .Modelica.SIunits.Pressure p_amb = 101325 "Ambient pressure";
    parameter .Modelica.SIunits.Temperature T_amb = 293.15 "Ambient Temperature (dry bulb)";
    parameter .Modelica.SIunits.Temperature T_wb = 288.15 "Ambient temperature (wet bulb)";
    annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "The System object is missing, please drag it on the top layer of your model");
  end System;

  package Examples  "Application examples"
    extends Modelica.Icons.ExamplesPackage;

    package HRB  "Heat recovery boiler models"
      extends Modelica.Icons.ExamplesPackage;

      package Models
        extends Modelica.Icons.Library;

        model Evaporator  "Fire tube boiler, fixed heat transfer coefficient, no radiative heat transfer"
          replaceable package FlueGasMedium = ThermoPower.Media.FlueGas constrainedby Modelica.Media.Interfaces.PartialMedium;
          replaceable package FluidMedium = ThermoPower.Water.StandardWater constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
          parameter Integer N = 2 "Number of node of the gas side";
          parameter .Modelica.SIunits.MassFlowRate gasNomFlowRate "Nominal flow rate through the gas side";
          parameter .Modelica.SIunits.MassFlowRate fluidNomFlowRate "Nominal flow rate through the fluid side";
          parameter .Modelica.SIunits.Pressure gasNomPressure "Nominal pressure in the gas side inlet";
          parameter .Modelica.SIunits.Pressure fluidNomPressure "Nominal pressure in the fluid side inlet";
          parameter .Modelica.SIunits.Area exchSurface "Exchange surface between gas - metal tube";
          parameter .Modelica.SIunits.Volume gasVol "Gas volume";
          parameter .Modelica.SIunits.Volume fluidVol "Fluid volume";
          parameter .Modelica.SIunits.Volume metalVol "Volume of the metal part in the tubes";
          parameter .Modelica.SIunits.Density rhom "Metal density";
          parameter .Modelica.SIunits.SpecificHeatCapacity cm "Specific heat capacity of the metal";
          parameter .Modelica.SIunits.Temperature Tstart "Average gas temperature start value";
          parameter .Modelica.SIunits.CoefficientOfHeatTransfer gamma "Constant heat transfer coefficient in the gas side";
          parameter Choices.Flow1D.FFtypes FFtype_G = ThermoPower.Choices.Flow1D.FFtypes.NoFriction "Friction Factor Type, gas side";
          parameter Real Kfnom_G = 0 "Nominal hydraulic resistance coefficient, gas side";
          parameter .Modelica.SIunits.PressureDifference dpnom_G = 0 "Nominal pressure drop, gas side (friction term only!)";
          parameter .Modelica.SIunits.Density rhonom_G = 0 "Nominal inlet density, gas side";
          parameter Real Cfnom_G = 0 "Nominal Fanning friction factor, gsa side";
          parameter Boolean gasQuasiStatic = false "Quasi-static model of the flue gas (mass, energy and momentum static balances";
          Water.DrumEquilibrium water(cm = cm, redeclare package Medium = FluidMedium, Vd = fluidVol, Mm = metalVol * rhom, pstart = fluidNomPressure, Vlstart = fluidVol * 0.8);
          Thermal.HT_DHTVolumes adapter(N = N - 1);
          Water.FlangeA waterIn(redeclare package Medium = FluidMedium);
          Water.FlangeB waterOut(redeclare package Medium = FluidMedium);
          Gas.FlangeA gasIn(redeclare package Medium = FlueGasMedium);
          Gas.FlangeB gasOut(redeclare package Medium = FlueGasMedium);
          Gas.Flow1DFV gasFlow(Dhyd = 1, wnom = gasNomFlowRate, FFtype = ThermoPower.Choices.Flow1D.FFtypes.NoFriction, redeclare package Medium = FlueGasMedium, QuasiStatic = gasQuasiStatic, N = N, L = L, A = gasVol / L, omega = exchSurface / L, Tstartbar = Tstart, redeclare model HeatTransfer = Thermal.HeatTransferFV.ConstantHeatTransferCoefficient(gamma = gamma));
          Modelica.Blocks.Interfaces.RealOutput voidFraction;
          final parameter .Modelica.SIunits.Distance L = 1 "Tube length";
          Modelica.Blocks.Sources.RealExpression realExpression;
          Modelica.Blocks.Sources.RealExpression output1(y = water.Vv / water.Vd);
        equation
          connect(water.feed, waterIn);
          connect(water.steam, waterOut);
          connect(gasFlow.infl, gasIn);
          connect(gasFlow.outfl, gasOut);
          connect(output1.y, voidFraction);
          connect(adapter.DHT_port, gasFlow.wall);
          connect(adapter.HT_port, water.wall);
        end Evaporator;
      end Models;
    end HRB;

    package RankineCycle  "Steam power plant"
      extends Modelica.Icons.ExamplesPackage;

      package Models
        extends Modelica.Icons.Package;

        model HE  "Heat Exchanger fluid - gas"
          replaceable package FlueGasMedium = ThermoPower.Media.FlueGas constrainedby Modelica.Media.Interfaces.PartialMedium;
          replaceable package FluidMedium = ThermoPower.Water.StandardWater constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
          parameter Integer N_G = 2 "Number of node of the gas side";
          parameter Integer N_F = 2 "Number of node of the fluid side";
          parameter .Modelica.SIunits.MassFlowRate gasNomFlowRate "Nominal flow rate through the gas side";
          parameter .Modelica.SIunits.MassFlowRate fluidNomFlowRate "Nominal flow rate through the fluid side";
          parameter .Modelica.SIunits.Pressure gasNomPressure "Nominal pressure in the gas side inlet";
          parameter .Modelica.SIunits.Pressure fluidNomPressure "Nominal pressure in the fluid side inlet";
          parameter .Modelica.SIunits.Area exchSurface_G "Exchange surface between gas - metal tube";
          parameter .Modelica.SIunits.Area exchSurface_F "Exchange surface between metal tube - fluid";
          parameter .Modelica.SIunits.Area extSurfaceTub "Total external surface of the tubes";
          parameter .Modelica.SIunits.Volume gasVol "Gas volume";
          parameter .Modelica.SIunits.Volume fluidVol "Fluid volume";
          parameter .Modelica.SIunits.Volume metalVol "Volume of the metal part in the tubes";
          parameter Real rhomcm "Metal heat capacity per unit volume [J/m^3.K]";
          parameter .Modelica.SIunits.ThermalConductivity lambda "Thermal conductivity of the metal (density by specific heat capacity)";
          parameter .Modelica.SIunits.Temperature Tstart_G "Average gas temperature start value";
          parameter .Modelica.SIunits.Temperature Tstart_M "Average metal wall temperature start value";
          parameter Choices.FluidPhase.FluidPhases FluidPhaseStart = Choices.FluidPhase.FluidPhases.Liquid "Initialization fluid phase";
          parameter .Modelica.SIunits.CoefficientOfHeatTransfer gamma_G "Constant heat transfer coefficient in the gas side";
          parameter .Modelica.SIunits.CoefficientOfHeatTransfer gamma_F "Constant heat transfer coefficient in the fluid side";
          parameter Choices.Flow1D.FFtypes FFtype_G = ThermoPower.Choices.Flow1D.FFtypes.NoFriction "Friction Factor Type, gas side";
          parameter Real Kfnom_G = 0 "Nominal hydraulic resistance coefficient, gas side";
          parameter .Modelica.SIunits.PressureDifference dpnom_G = 0 "Nominal pressure drop, gas side (friction term only!)";
          parameter .Modelica.SIunits.Density rhonom_G = 0 "Nominal inlet density, gas side";
          parameter Real Cfnom_G = 0 "Nominal Fanning friction factor, gsa side";
          parameter Choices.Flow1D.FFtypes FFtype_F = ThermoPower.Choices.Flow1D.FFtypes.NoFriction "Friction Factor Type, fluid side";
          parameter Real Kfnom_F = 0 "Nominal hydraulic resistance coefficient, fluid side";
          parameter .Modelica.SIunits.PressureDifference dpnom_F = 0 "Nominal pressure drop, fluid side (friction term only!)";
          parameter .Modelica.SIunits.Density rhonom_F = 0 "Nominal inlet density, fluid side";
          parameter Real Cfnom_F = 0 "Nominal Fanning friction factor, fluid side";
          parameter Choices.Flow1D.HCtypes HCtype_F = ThermoPower.Choices.Flow1D.HCtypes.Downstream "Location of the hydraulic capacitance, fluid side";
          parameter Boolean counterCurrent = true "Counter-current flow";
          parameter Boolean gasQuasiStatic = false "Quasi-static model of the flue gas (mass, energy and momentum static balances";
          constant Real pi = Modelica.Constants.pi;
          Gas.FlangeA gasIn(redeclare package Medium = FlueGasMedium);
          Gas.FlangeB gasOut(redeclare package Medium = FlueGasMedium);
          Water.FlangeA waterIn(redeclare package Medium = FluidMedium);
          Water.FlangeB waterOut(redeclare package Medium = FluidMedium);
          Water.Flow1DFV fluidFlow(Nt = 1, N = N_F, wnom = fluidNomFlowRate, redeclare package Medium = FluidMedium, L = exchSurface_F ^ 2 / (fluidVol * pi * 4), A = (fluidVol * 4 / exchSurface_F) ^ 2 / 4 * pi, omega = fluidVol * 4 / exchSurface_F * pi, Dhyd = fluidVol * 4 / exchSurface_F, FFtype = FFtype_F, dpnom = dpnom_F, rhonom = rhonom_F, HydraulicCapacitance = HCtype_F, Kfnom = Kfnom_F, Cfnom = Cfnom_F, FluidPhaseStart = FluidPhaseStart, redeclare model HeatTransfer = ThermoPower.Thermal.HeatTransferFV.ConstantHeatTransferCoefficient(gamma = gamma_F));
          Thermal.MetalTubeFV metalTube(rhomcm = rhomcm, lambda = lambda, L = exchSurface_F ^ 2 / (fluidVol * pi * 4), rint = fluidVol * 4 / exchSurface_F / 2, WallRes = false, rext = (metalVol + fluidVol) * 4 / extSurfaceTub / 2, Tstartbar = Tstart_M, Nw = N_F - 1);
          Gas.Flow1DFV gasFlow(Dhyd = 1, wnom = gasNomFlowRate, N = N_G, redeclare package Medium = FlueGasMedium, QuasiStatic = gasQuasiStatic, L = L, A = gasVol / L, omega = exchSurface_G / L, Tstartbar = Tstart_G, dpnom = dpnom_G, rhonom = rhonom_G, Kfnom = Kfnom_G, Cfnom = Cfnom_G, FFtype = FFtype_G, redeclare model HeatTransfer = ThermoPower.Thermal.HeatTransferFV.ConstantHeatTransferCoefficient(gamma = gamma_G));
          Thermal.CounterCurrentFV cC(Nw = N_F - 1);
          final parameter .Modelica.SIunits.Distance L = 1 "Tube length";
        equation
          connect(gasFlow.infl, gasIn);
          connect(gasFlow.outfl, gasOut);
          connect(fluidFlow.outfl, waterOut);
          connect(fluidFlow.infl, waterIn);
          connect(metalTube.ext, cC.side2);
          connect(metalTube.int, fluidFlow.wall);
          connect(gasFlow.wall, cC.side1);
        end HE;

        model PrescribedSpeedPump  "Prescribed speed pump"
          replaceable package FluidMedium = Modelica.Media.Interfaces.PartialTwoPhaseMedium;
          parameter Modelica.SIunits.VolumeFlowRate[3] q_nom "Nominal volume flow rates";
          parameter Modelica.SIunits.Height[3] head_nom "Nominal heads";
          parameter Modelica.SIunits.Density rho0 "Nominal density";
          parameter Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm n0 "Nominal rpm";
          parameter Modelica.SIunits.Pressure nominalOutletPressure "Nominal live steam pressure";
          parameter Modelica.SIunits.Pressure nominalInletPressure "Nominal condensation pressure";
          parameter Modelica.SIunits.MassFlowRate nominalMassFlowRate "Nominal steam mass flow rate";
          parameter Modelica.SIunits.SpecificEnthalpy hstart = 1e5 "Fluid Specific Enthalpy Start Value";
          parameter Boolean SSInit = false "Steady-state initialization";
          function flowCharacteristic = ThermoPower.Functions.PumpCharacteristics.quadraticFlow(q_nom = q_nom, head_nom = head_nom);
          Water.FlangeA inlet(redeclare package Medium = FluidMedium);
          Water.FlangeB outlet(redeclare package Medium = FluidMedium);
          Water.Pump feedWaterPump(redeclare function flowCharacteristic = flowCharacteristic, n0 = n0, redeclare package Medium = FluidMedium, initOpt = if SSInit then Choices.Init.Options.steadyState else Choices.Init.Options.noInit, wstart = nominalMassFlowRate, w0 = nominalMassFlowRate, dp0 = nominalOutletPressure - nominalInletPressure, rho0 = rho0, hstart = hstart, use_in_n = true);
          Modelica.Blocks.Interfaces.RealInput nPump;
        equation
          connect(nPump, feedWaterPump.in_n);
          connect(feedWaterPump.infl, inlet);
          connect(feedWaterPump.outfl, outlet);
        end PrescribedSpeedPump;

        model PrescribedPressureCondenser  "Ideal condenser with prescribed pressure"
          replaceable package Medium = Water.StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
          parameter Modelica.SIunits.Pressure p "Nominal inlet pressure";
          parameter Modelica.SIunits.Volume Vtot = 10 "Total volume of the fluid side";
          parameter Modelica.SIunits.Volume Vlstart = 0.15 * Vtot "Start value of the liquid water volume";
          parameter Choices.Init.Options initOpt = system.initOpt "Initialisation option";
          outer System system "System object";
          Modelica.SIunits.Density rhol "Density of saturated liquid";
          Modelica.SIunits.Density rhov "Density of saturated steam";
          Medium.SaturationProperties sat "Saturation properties";
          Medium.SpecificEnthalpy hl "Specific enthalpy of saturated liquid";
          Medium.SpecificEnthalpy hv "Specific enthalpy of saturated vapour";
          Modelica.SIunits.Mass M "Total mass, steam+liquid";
          Modelica.SIunits.Mass Ml "Liquid mass";
          Modelica.SIunits.Mass Mv "Steam mass";
          Modelica.SIunits.Volume Vl(start = Vlstart) "Liquid volume";
          Modelica.SIunits.Volume Vv "Steam volume";
          Modelica.SIunits.Energy E "Internal energy";
          Modelica.SIunits.Power Q "Thermal power";
          Water.FlangeA steamIn(redeclare package Medium = Medium);
          Water.FlangeB waterOut(redeclare package Medium = Medium);
        initial equation
          if initOpt == Choices.Init.Options.noInit then
          elseif initOpt == Choices.Init.Options.fixedState then
            Vl = Vlstart;
          elseif initOpt == Choices.Init.Options.steadyState then
            der(Vl) = 0;
          else
            assert(false, "Unsupported initialisation option");
          end if;
        equation
          steamIn.p = p;
          steamIn.h_outflow = hl;
          sat.psat = p;
          sat.Tsat = Medium.saturationTemperature(p);
          hl = Medium.bubbleEnthalpy(sat);
          hv = Medium.dewEnthalpy(sat);
          waterOut.p = p;
          waterOut.h_outflow = hl;
          rhol = Medium.bubbleDensity(sat);
          rhov = Medium.dewDensity(sat);
          Ml = Vl * rhol;
          Mv = Vv * rhov;
          Vtot = Vv + Vl;
          M = Ml + Mv;
          E = Ml * hl + Mv * inStream(steamIn.h_outflow) - p * Vtot;
          der(M) = steamIn.m_flow + waterOut.m_flow;
          der(E) = steamIn.m_flow * hv + waterOut.m_flow * hl - Q;
        end PrescribedPressureCondenser;

        model Plant
          replaceable package FlueGas = .ThermoPower.Media.FlueGas constrainedby Modelica.Media.Interfaces.PartialMedium;
          replaceable package Water = .ThermoPower.Water.StandardWater constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
          .ThermoPower.Examples.RankineCycle.Models.PrescribedPressureCondenser condenser(p = 5390, redeclare package Medium = Water, initOpt = .ThermoPower.Choices.Init.Options.fixedState);
          .ThermoPower.Examples.RankineCycle.Models.PrescribedSpeedPump prescribedSpeedPump(n0 = 1500, nominalMassFlowRate = 55, q_nom = {0, 0.055, 0.1}, redeclare package FluidMedium = Water, head_nom = {450, 300, 0}, rho0 = 1000, nominalOutletPressure = 3000000, nominalInletPressure = 50000);
          Modelica.Blocks.Continuous.FirstOrder temperatureActuator(k = 1, y_start = 750, T = 4, initType = Modelica.Blocks.Types.Init.SteadyState);
          Modelica.Blocks.Continuous.FirstOrder powerSensor(k = 1, T = 1, y_start = 56.8e6, initType = Modelica.Blocks.Types.Init.SteadyState);
          Modelica.Blocks.Interfaces.RealOutput generatedPower;
          Modelica.Blocks.Interfaces.RealInput gasFlowRate;
          Modelica.Blocks.Interfaces.RealInput gasTemperature;
          Modelica.Blocks.Continuous.FirstOrder gasFlowActuator(k = 1, T = 4, y_start = 500, initType = Modelica.Blocks.Types.Init.SteadyState);
          Modelica.Blocks.Continuous.FirstOrder nPumpActuator(k = 1, initType = Modelica.Blocks.Types.Init.SteadyState, T = 2, y_start = 1500);
          Modelica.Blocks.Interfaces.RealInput nPump;
          Modelica.Blocks.Interfaces.RealOutput voidFraction;
          Modelica.Blocks.Continuous.FirstOrder voidFractionSensor(k = 1, T = 1, initType = Modelica.Blocks.Types.Init.SteadyState, y_start = 0.2);
          Electrical.Generator generator(J = 10000, initOpt = .ThermoPower.Choices.Init.Options.noInit);
          Electrical.NetworkGrid_Pmax network(J = 10000, Pmax = 100e6, deltaStart = 0.4);
          .ThermoPower.Water.SteamTurbineStodola steamTurbine(wstart = 55, wnom = 55, Kt = 0.0104, redeclare package Medium = Water, PRstart = 30, pnom = 3000000);
          Modelica.Mechanics.Rotational.Sensors.PowerSensor powerSensor1;
          .ThermoPower.Examples.RankineCycle.Models.HE economizer(redeclare package FluidMedium = Water, redeclare package FlueGasMedium = FlueGas, N_F = 6, exchSurface_G = 40095.9, exchSurface_F = 3439.389, extSurfaceTub = 3888.449, gasVol = 10, fluidVol = 28.977, metalVol = 8.061, rhomcm = 7900 * 578.05, lambda = 20, gasNomFlowRate = 500, fluidNomFlowRate = 55, gamma_G = 30, gamma_F = 3000, rhonom_G = 1, Kfnom_F = 150, FFtype_G = .ThermoPower.Choices.Flow1D.FFtypes.OpPoint, FFtype_F = .ThermoPower.Choices.Flow1D.FFtypes.Kfnom, N_G = 6, gasNomPressure = 101325, fluidNomPressure = 3000000, Tstart_G = 473.15, Tstart_M = 423.15, dpnom_G = 1000, dpnom_F = 20000);
          .ThermoPower.Examples.HRB.Models.Evaporator evaporator(redeclare package FluidMedium = Water, redeclare package FlueGasMedium = FlueGas, gasVol = 10, fluidVol = 12.400, metalVol = 4.801, gasNomFlowRate = 500, fluidNomFlowRate = 55, N = 4, rhom = 7900, cm = 578.05, gamma = 85, exchSurface = 24402, gasNomPressure = 101325, fluidNomPressure = 3000000, Tstart = 623.15, FFtype_G = .ThermoPower.Choices.Flow1D.FFtypes.OpPoint, dpnom_G = 1000, rhonom_G = 1);
          .ThermoPower.Examples.RankineCycle.Models.HE superheater(redeclare package FluidMedium = Water, redeclare package FlueGasMedium = FlueGas, N_F = 7, exchSurface_G = 2314.8, exchSurface_F = 450.218, extSurfaceTub = 504.652, gasVol = 10, fluidVol = 4.468, metalVol = 1.146, rhomcm = 7900 * 578.05, lambda = 20, gasNomFlowRate = 500, gamma_G = 90, gamma_F = 6000, fluidNomFlowRate = 55, rhonom_G = 1, Kfnom_F = 150, FluidPhaseStart = .ThermoPower.Choices.FluidPhase.FluidPhases.Steam, FFtype_G = .ThermoPower.Choices.Flow1D.FFtypes.OpPoint, FFtype_F = .ThermoPower.Choices.Flow1D.FFtypes.Kfnom, N_G = 7, gasNomPressure = 101325, fluidNomPressure = 3000000, Tstart_G = 723.15, Tstart_M = 573.15, dpnom_G = 1000, dpnom_F = 20000);
          .ThermoPower.PowerPlants.HRSG.Components.StateReader_gas stateGasInlet(redeclare package Medium = FlueGas);
          .ThermoPower.PowerPlants.HRSG.Components.StateReader_gas stateGasInletEvaporator(redeclare package Medium = FlueGas);
          .ThermoPower.PowerPlants.HRSG.Components.StateReader_gas stateGasInletEconomizer(redeclare package Medium = FlueGas);
          .ThermoPower.PowerPlants.HRSG.Components.StateReader_gas stateGasOutlet(redeclare package Medium = FlueGas);
          .ThermoPower.PowerPlants.HRSG.Components.StateReader_water stateWaterSuperheater_in(redeclare package Medium = Water);
          .ThermoPower.PowerPlants.HRSG.Components.StateReader_water stateWaterSuperheater_out(redeclare package Medium = Water);
          .ThermoPower.PowerPlants.HRSG.Components.StateReader_water stateWaterEvaporator_in(redeclare package Medium = Water);
          .ThermoPower.PowerPlants.HRSG.Components.StateReader_water stateWaterEconomizer_in(redeclare package Medium = Water);
          .ThermoPower.Gas.SourceMassFlow sourceW_gas(w0 = 500, redeclare package Medium = FlueGas, T = 750, use_in_w0 = true, use_in_T = true);
          .ThermoPower.Gas.SinkPressure sinkP_gas(T = 400, redeclare package Medium = FlueGas);
          inner .ThermoPower.System system(allowFlowReversal = false, initOpt = .ThermoPower.Choices.Init.Options.steadyState);
        equation
          connect(prescribedSpeedPump.inlet, condenser.waterOut);
          connect(generatedPower, powerSensor.y);
          connect(gasFlowActuator.u, gasFlowRate);
          connect(temperatureActuator.u, gasTemperature);
          connect(nPumpActuator.u, nPump);
          connect(voidFraction, voidFractionSensor.y);
          connect(powerSensor1.flange_a, steamTurbine.shaft_b);
          connect(stateGasInlet.inlet, sourceW_gas.flange);
          connect(generator.shaft, powerSensor1.flange_b);
          connect(network.powerConnection, generator.powerConnection);
          connect(condenser.steamIn, steamTurbine.outlet);
          connect(prescribedSpeedPump.outlet, stateWaterEconomizer_in.inlet);
          connect(stateWaterEconomizer_in.outlet, economizer.waterIn);
          connect(economizer.waterOut, stateWaterEvaporator_in.inlet);
          connect(stateWaterEvaporator_in.outlet, evaporator.waterIn);
          connect(economizer.gasIn, stateGasInletEconomizer.outlet);
          connect(stateGasInletEconomizer.inlet, evaporator.gasOut);
          connect(sinkP_gas.flange, stateGasOutlet.outlet);
          connect(stateGasOutlet.inlet, economizer.gasOut);
          connect(evaporator.gasIn, stateGasInletEvaporator.outlet);
          connect(stateGasInletEvaporator.inlet, superheater.gasOut);
          connect(evaporator.waterOut, stateWaterSuperheater_in.inlet);
          connect(stateWaterSuperheater_in.outlet, superheater.waterIn);
          connect(superheater.waterOut, stateWaterSuperheater_out.inlet);
          connect(stateWaterSuperheater_out.outlet, steamTurbine.inlet);
          connect(superheater.gasIn, stateGasInlet.outlet);
          connect(powerSensor.u, powerSensor1.power);
          connect(voidFractionSensor.u, evaporator.voidFraction);
          connect(gasFlowActuator.y, sourceW_gas.in_w0);
          connect(temperatureActuator.y, sourceW_gas.in_T);
          connect(nPumpActuator.y, prescribedSpeedPump.nPump);
        end Plant;

        model PID  "PID controller with anti-windup"
          parameter Real Kp "Proportional gain (normalised units)";
          parameter .Modelica.SIunits.Time Ti "Integral time";
          parameter Boolean integralAction = true "Use integral action";
          parameter .Modelica.SIunits.Time Td = 0 "Derivative time";
          parameter Real Nd = 1 "Derivative action up to Nd / Td rad/s";
          parameter Real Ni = 1 "Ni*Ti is the time constant of anti-windup compensation";
          parameter Real b = 1 "Setpoint weight on proportional action";
          parameter Real c = 0 "Setpoint weight on derivative action";
          parameter Real PVmin "Minimum value of process variable for scaling";
          parameter Real PVmax "Maximum value of process variable for scaling";
          parameter Real CSmin "Minimum value of control signal for scaling";
          parameter Real CSmax "Maximum value of control signal for scaling";
          parameter Real PVstart = 0.5 "Start value of PV (scaled)";
          parameter Real CSstart = 0.5 "Start value of CS (scaled)";
          parameter Boolean holdWhenSimplified = false "Hold CSs at start value when homotopy=simplified";
          parameter Boolean steadyStateInit = false "Initialize in steady state";
          Real CSs_hom "Control signal scaled in per units, used when homotopy=simplified";
          Real P "Proportional action / Kp";
          Real I(start = CSstart / Kp) "Integral action / Kp";
          Real D "Derivative action / Kp";
          Real Dx(start = c * PVstart - PVstart) "State of approximated derivator";
          Real PVs "Process variable scaled in per unit";
          Real SPs "Setpoint variable scaled in per unit";
          Real CSs(start = CSstart) "Control signal scaled in per unit";
          Real CSbs(start = CSstart) "Control signal scaled in per unit before saturation";
          Real track "Tracking signal for anti-windup integral action";
          Modelica.Blocks.Interfaces.RealInput PV "Process variable signal";
          Modelica.Blocks.Interfaces.RealOutput CS "Control signal";
          Modelica.Blocks.Interfaces.RealInput SP "Set point signal";
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
            Td / Nd * der(Dx) + Dx = c * SPs - PVs "State equation of approximated derivator";
            D = Nd * (c * SPs - PVs - Dx) "Output equation of approximated derivator";
          else
            Dx = 0;
            D = 0;
          end if;
          if holdWhenSimplified then
            CSs_hom = CSstart;
          else
            CSs_hom = CSbs;
          end if;
          CSbs = Kp * (P + I + D) "Control signal before saturation";
          CSs = homotopy(smooth(0, if CSbs > 1 then 1 else if CSbs < 0 then 0 else CSbs), CSs_hom) "Saturated control signal";
          track = (CSs - CSbs) / (Kp * Ni);
        end PID;
      end Models;

      package Simulators  "Simulation models for the Rankine cycle example"
        extends Modelica.Icons.ExamplesPackage;

        model ClosedLoop
          extends Modelica.Icons.Example;
          Modelica.Blocks.Sources.Ramp gasTemperature(height = 0, duration = 0, offset = 750);
          ThermoPower.Examples.RankineCycle.Models.Plant plant(economizer(gasFlow(wnm = 2)));
          Modelica.Blocks.Sources.Step voidFractionSetPoint(offset = 0.2, height = 0, startTime = 0);
          Models.PID voidFractionController(PVmin = 0.1, PVmax = 0.9, CSmax = 2500, PVstart = 0.1, CSstart = 0.5, steadyStateInit = true, CSmin = 500, Kp = -2, Ti = 300);
          Modelica.Blocks.Sources.Ramp powerSetPoint(duration = 450, startTime = 500, height = -56.8e6 * 0.35, offset = 56.8e6);
          Models.PID powerController(steadyStateInit = true, PVmin = 20e6, PVmax = 100e6, Ti = 240, CSmin = 100, CSmax = 1000, Kp = 2, CSstart = 0.7, holdWhenSimplified = true);
        equation
          connect(voidFractionController.SP, voidFractionSetPoint.y);
          connect(voidFractionController.CS, plant.nPump);
          connect(voidFractionController.PV, plant.voidFraction);
          connect(powerSetPoint.y, powerController.SP);
          connect(powerController.PV, plant.generatedPower);
          connect(gasTemperature.y, plant.gasTemperature);
          connect(powerController.CS, plant.gasFlowRate);
          annotation(experiment(StopTime = 3000, Tolerance = 1e-006), experimentSetupOutput(equdistant = false));
        end ClosedLoop;
      end Simulators;
    end RankineCycle;
  end Examples;

  package PowerPlants  "Models of thermoelectrical power plants components"
    extends Modelica.Icons.ExamplesPackage;

    package HRSG  "Models and tests of the HRSG and its main components"
      extends Modelica.Icons.Package;

      package Components  "HRSG component models"
        extends Modelica.Icons.Package;

        model BaseReader_water  "Base reader for the visualization of the state in the simulation (water)"
          replaceable package Medium = Water.StandardWater constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
          parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction";
          outer ThermoPower.System system "System wide properties";
          Water.FlangeA inlet(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
          Water.FlangeB outlet(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
        equation
          inlet.m_flow + outlet.m_flow = 0 "Mass balance";
          inlet.p = outlet.p "No pressure drop";
          inlet.h_outflow = inStream(outlet.h_outflow);
          inStream(inlet.h_outflow) = outlet.h_outflow;
        end BaseReader_water;

        model StateReader_water  "State reader for the visualization of the state in the simulation (water)"
          extends ThermoPower.PowerPlants.HRSG.Components.BaseReader_water;
          .Modelica.SIunits.Temperature T "Temperature";
          .Modelica.SIunits.Pressure p "Pressure";
          .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          .Modelica.SIunits.MassFlowRate w "Mass flow rate";
          Medium.ThermodynamicState fluidState "Thermodynamic state of the fluid";
        equation
          p = inlet.p;
          h = homotopy(if not allowFlowReversal then inStream(inlet.h_outflow) else actualStream(inlet.h_outflow), inStream(inlet.h_outflow));
          fluidState = Medium.setState_ph(p, h);
          T = Medium.temperature(fluidState);
          w = inlet.m_flow;
        end StateReader_water;

        model BaseReader_gas  "Base reader for the visualization of the state in the simulation (gas)"
          replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
          parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction";
          outer ThermoPower.System system "System wide properties";
          Gas.FlangeA inlet(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
          Gas.FlangeB outlet(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
        equation
          inlet.m_flow + outlet.m_flow = 0 "Mass balance";
          inlet.p = outlet.p "Momentum balance";
          inlet.h_outflow = inStream(outlet.h_outflow);
          inStream(inlet.h_outflow) = outlet.h_outflow;
          inlet.Xi_outflow = inStream(outlet.Xi_outflow);
          inStream(inlet.Xi_outflow) = outlet.Xi_outflow;
        end BaseReader_gas;

        model StateReader_gas  "State reader for the visualization of the state in the simulation (gas)"
          extends BaseReader_gas;
          Medium.BaseProperties gas;
          .Modelica.SIunits.Temperature T "Temperature";
          .Modelica.SIunits.Pressure p "Pressure";
          .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy";
          .Modelica.SIunits.MassFlowRate w "Mass flow rate";
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

  package Gas  "Models of components with ideal gases as working fluid"
    connector Flange  "Flange connector for gas flows"
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium;
      flow Medium.MassFlowRate m_flow "Mass flow rate from the connection point into the component";
      Medium.AbsolutePressure p "Thermodynamic pressure in the connection point";
      stream Medium.SpecificEnthalpy h_outflow "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
      stream Medium.MassFraction[Medium.nXi] Xi_outflow "Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0";
      stream Medium.ExtraProperty[Medium.nC] C_outflow "Properties c_i/m close to the connection point if m_flow < 0";
    end Flange;

    connector FlangeA  "A-type flange connector for gas flows"
      extends Flange;
    end FlangeA;

    connector FlangeB  "B-type flange connector for gas flows"
      extends Flange;
    end FlangeB;

    extends Modelica.Icons.Package;

    model SinkPressure  "Pressure sink for gas flows"
      extends Icons.Gas.SourceP;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium annotation(choicesAllMatching = true);
      Medium.BaseProperties gas(p(start = p0), T(start = T), Xi(start = Xnom[1:Medium.nXi]));
      parameter Medium.AbsolutePressure p0 = 101325 "Nominal pressure";
      parameter Medium.Temperature T = 300 "Nominal temperature";
      parameter Medium.MassFraction[Medium.nX] Xnom = Medium.reference_X "Nominal gas composition";
      parameter Units.HydraulicResistance R = 0 "Hydraulic Resistance";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
      parameter Boolean use_in_p0 = false "Use connector input for the pressure";
      parameter Boolean use_in_T = false "Use connector input for the temperature";
      parameter Boolean use_in_X = false "Use connector input for the composition";
      outer ThermoPower.System system "System wide properties";
      FlangeA flange(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      Modelica.Blocks.Interfaces.RealInput in_p0 if use_in_p0;
      Modelica.Blocks.Interfaces.RealInput in_T if use_in_T;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X if use_in_X;
    protected
      Modelica.Blocks.Interfaces.RealInput in_p0_internal;
      Modelica.Blocks.Interfaces.RealInput in_T_internal;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X_internal;
    equation
      if R > 0 then
        flange.p = gas.p + flange.m_flow * R;
      else
        flange.p = gas.p;
      end if;
      gas.p = in_p0_internal;
      if not use_in_p0 then
        in_p0_internal = p0 "Pressure set by parameter";
      end if;
      gas.T = in_T_internal;
      if not use_in_T then
        in_T_internal = T "Temperature set by parameter";
      end if;
      gas.Xi = in_X_internal[1:Medium.nXi];
      if not use_in_X then
        in_X_internal = Xnom "Composition set by parameter";
      end if;
      flange.h_outflow = gas.h;
      flange.Xi_outflow = gas.Xi;
      connect(in_p0, in_p0_internal);
      connect(in_T, in_T_internal);
      connect(in_X, in_X_internal);
    end SinkPressure;

    model SourceMassFlow  "Flow rate source for gas flows"
      extends Icons.Gas.SourceW;
      replaceable package Medium = Modelica.Media.Interfaces.PartialMedium annotation(choicesAllMatching = true);
      Medium.BaseProperties gas(p(start = p0), T(start = T), Xi(start = Xnom[1:Medium.nXi]));
      parameter Medium.AbsolutePressure p0 = 101325 "Nominal pressure";
      parameter Medium.Temperature T = 300 "Nominal temperature";
      parameter Medium.MassFraction[Medium.nX] Xnom = Medium.reference_X "Nominal gas composition";
      parameter Medium.MassFlowRate w0 = 0 "Nominal mass flowrate";
      parameter Units.HydraulicConductance G = 0 "HydraulicConductance";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
      parameter Boolean use_in_w0 = false "Use connector input for the nominal flow rate";
      parameter Boolean use_in_T = false "Use connector input for the temperature";
      parameter Boolean use_in_X = false "Use connector input for the composition";
      outer ThermoPower.System system "System wide properties";
      Medium.MassFlowRate w "Nominal mass flow rate";
      FlangeB flange(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
      Modelica.Blocks.Interfaces.RealInput in_w0 if use_in_w0;
      Modelica.Blocks.Interfaces.RealInput in_T if use_in_T;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X if use_in_X;
    protected
      Modelica.Blocks.Interfaces.RealInput in_w0_internal;
      Modelica.Blocks.Interfaces.RealInput in_T_internal;
      Modelica.Blocks.Interfaces.RealInput[Medium.nX] in_X_internal;
    equation
      if G > 0 then
        flange.m_flow = (-w) + (flange.p - p0) * G;
      else
        flange.m_flow = -w;
      end if;
      w = in_w0_internal;
      if not use_in_w0 then
        in_w0_internal = w0 "Flow rate set by parameter";
      end if;
      gas.T = in_T_internal;
      if not use_in_T then
        in_T_internal = T "Temperature set by parameter";
      end if;
      gas.Xi = in_X_internal[1:Medium.nXi];
      if not use_in_X then
        in_X_internal = Xnom "Composition set by parameter";
      end if;
      flange.p = gas.p;
      flange.h_outflow = gas.h;
      flange.Xi_outflow = gas.Xi;
      connect(in_w0, in_w0_internal);
      connect(in_T, in_T_internal);
      connect(in_X, in_X_internal);
    end SourceMassFlow;

    model Flow1DFV  "1-dimensional fluid flow model for gas (finite volumes)"
      extends BaseClasses.Flow1DBase;
      Thermal.DHTVolumes wall(final N = Nw);
      replaceable model HeatTransfer = Thermal.HeatTransferFV.IdealHeatTransfer constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFV;
      HeatTransfer heatTransfer(redeclare package Medium = Medium, final Nf = N, final Nw = Nw, final Nt = Nt, final L = L, final A = A, final Dhyd = Dhyd, final omega = omega, final wnom = wnom / Nt, final w = w * ones(N), final fluidState = gas.state) "Instantiated heat transfer model";
      parameter .Modelica.SIunits.PerUnit wnm = 1e-2 "Maximum fraction of the nominal flow rate allowed as reverse flow";
      Medium.BaseProperties[N] gas "Gas nodal properties";
      .Modelica.SIunits.Pressure Dpfric "Pressure drop due to friction";
      .Modelica.SIunits.Length omega_hyd "Wet perimeter (single tube)";
      Real Kf "Friction factor";
      Real Kfl "Linear friction factor";
      Real dwdt "Time derivative of mass flow rate";
      .Modelica.SIunits.PerUnit Cf "Fanning friction factor";
      Medium.MassFlowRate w(start = wnom / Nt) "Mass flowrate (single tube)";
      Medium.Temperature[N - 1] Ttilde(start = ones(N - 1) * Tstartin + (1:N - 1) / (N - 1) * (Tstartout - Tstartin), each stateSelect = StateSelect.prefer) "Temperature state variables";
      Medium.Temperature[N] T "Node temperatures";
      Medium.SpecificEnthalpy[N] h "Node specific enthalpies";
      Medium.Temperature Tin(start = Tstartin);
      Medium.MassFraction[if UniformComposition or Medium.fixedX then 1 else N - 1, nX] Xtilde(start = ones(size(Xtilde, 1), size(Xtilde, 2)) * diagonal(Xstart[1:nX]), each stateSelect = StateSelect.prefer) "Composition state variables";
      Medium.MassFlowRate[N - 1] wbar(each start = wnom / Nt);
      .Modelica.SIunits.Power[N - 1] Q_single = heatTransfer.Qvol / Nt "Heat flows entering the volumes from the lateral boundary (single tube)";
      .Modelica.SIunits.Velocity[N] u "Fluid velocity";
      Medium.AbsolutePressure p(start = pstart, stateSelect = StateSelect.prefer);
      .Modelica.SIunits.Time Tr "Residence time";
      .Modelica.SIunits.Mass M "Gas Mass (single tube)";
      .Modelica.SIunits.Mass Mtot "Gas Mass (total)";
      .Modelica.SIunits.Power Q "Total heat flow through the wall (all Nt tubes)";
    protected
      parameter .Modelica.SIunits.Length l = L / (N - 1) "Length of a single volume";
      Medium.Density[N - 1] rhobar "Fluid average density";
      .Modelica.SIunits.SpecificVolume[N - 1] vbar "Fluid average specific volume";
      Medium.DerDensityByPressure[N - 1] drbdp "Derivative of average density by pressure";
      Medium.DerDensityByTemperature[N - 1] drbdT1 "Derivative of average density by left temperature";
      Medium.DerDensityByTemperature[N - 1] drbdT2 "Derivative of average density by right temperature";
      Real[N - 1, nX] drbdX1(each unit = "kg/m3") "Derivative of average density by left composition";
      Real[N - 1, nX] drbdX2(each unit = "kg/m3") "Derivative of average density by right composition";
      Medium.SpecificHeatCapacity[N - 1] cvbar "Average cv";
      .Modelica.SIunits.MassFlowRate[N - 1] dMdt "Derivative of mass in a finite volume";
      Medium.SpecificHeatCapacity[N] cv;
      Medium.DerDensityByTemperature[N] dddT "Derivative of density by temperature";
      Medium.DerDensityByPressure[N] dddp "Derivative of density by pressure";
      Real[N, nX] dddX(each unit = "kg/m3") "Derivative of density by composition";
    initial equation
      if initOpt == Choices.Init.Options.noInit or QuasiStatic then
      elseif initOpt == Choices.Init.Options.fixedState then
        if not noInitialPressure then
          p = pstart;
        end if;
        Ttilde = Tstart[2:N];
      elseif initOpt == Choices.Init.Options.steadyState then
        if not Medium.singleState and not noInitialPressure then
          der(p) = 0;
        end if;
        der(Ttilde) = zeros(N - 1);
        if not Medium.fixedX then
          der(Xtilde) = zeros(size(Xtilde, 1), size(Xtilde, 2));
        end if;
      elseif initOpt == Choices.Init.Options.steadyStateNoP then
        der(Ttilde) = zeros(N - 1);
        if not Medium.fixedX then
          der(Xtilde) = zeros(size(Xtilde, 1), size(Xtilde, 2));
        end if;
      else
        assert(false, "Unsupported initialisation option");
      end if;
    equation
      assert(FFtype == ThermoPower.Choices.Flow1D.FFtypes.NoFriction or dpnom > 0, "dpnom=0 not supported, it is also used in the homotopy trasformation during the inizialization");
      omega_hyd = 4 * A / Dhyd;
      if FFtype == ThermoPower.Choices.Flow1D.FFtypes.Kfnom then
        Kf = Kfnom * Kfc;
        Cf = 2 * Kf * A ^ 3 / (omega_hyd * L);
      elseif FFtype == ThermoPower.Choices.Flow1D.FFtypes.OpPoint then
        Kf = dpnom * rhonom / (wnom / Nt) ^ 2 * Kfc;
        Cf = 2 * Kf * A ^ 3 / (omega_hyd * L);
      elseif FFtype == ThermoPower.Choices.Flow1D.FFtypes.Cfnom then
        Kf = Cfnom * omega_hyd * L / (2 * A ^ 3) * Kfc;
        Cf = Cfnom * Kfc;
      elseif FFtype == ThermoPower.Choices.Flow1D.FFtypes.Colebrook then
        Cf = f_colebrook(w, Dhyd / A, e, Medium.dynamicViscosity(gas[integer(N / 2)].state)) * Kfc;
        Kf = Cf * omega_hyd * L / (2 * A ^ 3);
      elseif FFtype == ThermoPower.Choices.Flow1D.FFtypes.NoFriction then
        Cf = 0;
        Kf = 0;
      else
        assert(false, "Unsupported FFtype");
        Cf = 0;
        Kf = 0;
      end if;
      assert(Kf >= 0, "Negative friction coefficient");
      Kfl = wnom / Nt * wnf * Kf "Linear friction factor";
      dwdt = if DynamicMomentum and not QuasiStatic then der(w) else 0;
      sum(dMdt) = (infl.m_flow + outfl.m_flow) / Nt "Mass balance";
      L / A * dwdt + outfl.p - infl.p + Dpfric = 0 "Momentum balance";
      Dpfric = if FFtype == ThermoPower.Choices.Flow1D.FFtypes.NoFriction then 0 else homotopy(smooth(1, Kf * squareReg(w, wnom / Nt * wnf)) * sum(vbar) / (N - 1), dpnom / (wnom / Nt) * w) "Pressure drop due to friction";
      for j in 1:N - 1 loop
        if not QuasiStatic then
          A * l * rhobar[j] * cvbar[j] * der(Ttilde[j]) + wbar[j] * (gas[j + 1].h - gas[j].h) = Q_single[j] "Energy balance";
          dMdt[j] = A * l * (drbdp[j] * der(p) + drbdT1[j] * der(gas[j].T) + drbdT2[j] * der(gas[j + 1].T) + vector(drbdX1[j, :]) * vector(der(gas[j].X)) + vector(drbdX2[j, :]) * vector(der(gas[j + 1].X))) "Mass balance";
          if avoidInletEnthalpyDerivative and j == 1 then
            rhobar[j] = gas[j + 1].d;
            drbdp[j] = dddp[j + 1];
            drbdT1[j] = 0;
            drbdT2[j] = dddT[j + 1];
            drbdX1[j, :] = zeros(size(Xtilde, 2));
            drbdX2[j, :] = dddX[j + 1, :];
          else
            rhobar[j] = (gas[j].d + gas[j + 1].d) / 2;
            drbdp[j] = (dddp[j] + dddp[j + 1]) / 2;
            drbdT1[j] = dddT[j] / 2;
            drbdT2[j] = dddT[j + 1] / 2;
            drbdX1[j, :] = dddX[j, :] / 2;
            drbdX2[j, :] = dddX[j + 1, :] / 2;
          end if;
          vbar[j] = 1 / rhobar[j];
          wbar[j] = homotopy(infl.m_flow / Nt - sum(dMdt[1:j - 1]) - dMdt[j] / 2, wnom / Nt);
          cvbar[j] = (cv[j] + cv[j + 1]) / 2;
        else
          wbar[j] * (gas[j + 1].h - gas[j].h) = Q_single[j] "Energy balance";
          dMdt[j] = 0 "Mass balance";
          rhobar[j] = 0;
          drbdp[j] = 0;
          drbdT1[j] = 0;
          drbdT2[j] = 0;
          drbdX1[j, :] = zeros(nX);
          drbdX2[j, :] = zeros(nX);
          vbar[j] = 0;
          wbar[j] = infl.m_flow / Nt;
          cvbar[j] = 0;
        end if;
      end for;
      Q = heatTransfer.Q "Total heat flow through the lateral boundary";
      if Medium.fixedX then
        Xtilde = fill(Medium.reference_X, 1);
      elseif QuasiStatic then
        Xtilde = fill(gas[1].X, size(Xtilde, 1)) "Gas composition equal to actual inlet";
      elseif UniformComposition then
        der(Xtilde[1, :]) = homotopy(1 / L * sum(u) / N * (gas[1].X - gas[N].X), 1 / L * unom * (gas[1].X - gas[N].X)) "Partial mass balance for the whole pipe";
      else
        for j in 1:N - 1 loop
          der(Xtilde[j, :]) = homotopy((u[j + 1] + u[j]) / (2 * l) * (gas[j].X - gas[j + 1].X), 1 / L * unom * (gas[j].X - gas[j + 1].X)) "Partial mass balance for single volume";
        end for;
      end if;
      for j in 1:N loop
        u[j] = w / (gas[j].d * A) "Gas velocity";
        gas[j].p = p;
        gas[j].T = T[j];
        gas[j].h = h[j];
      end for;
      for j in 1:N loop
        if not QuasiStatic then
          cv[j] = Medium.heatCapacity_cv(gas[j].state);
          dddT[j] = Medium.density_derT_p(gas[j].state);
          dddp[j] = Medium.density_derp_T(gas[j].state);
          if nX > 0 then
            dddX[j, :] = Medium.density_derX(gas[j].state);
          end if;
        else
          cv[j] = 0;
          dddT[j] = 0;
          dddp[j] = 0;
          dddX[j, :] = zeros(nX);
        end if;
      end for;
      if HydraulicCapacitance == ThermoPower.Choices.Flow1D.HCtypes.Upstream then
        p = infl.p;
        w = -outfl.m_flow / Nt;
      else
        p = outfl.p;
        w = infl.m_flow / Nt;
      end if;
      infl.h_outflow = gas[1].h;
      outfl.h_outflow = gas[N].h;
      infl.Xi_outflow = gas[1].Xi;
      outfl.Xi_outflow = gas[N].Xi;
      gas[1].h = inStream(infl.h_outflow);
      gas[2:N].T = Ttilde;
      gas[1].Xi = inStream(infl.Xi_outflow);
      for j in 2:N loop
        gas[j].Xi = Xtilde[if UniformComposition then 1 else j - 1, 1:nXi];
      end for;
      connect(wall, heatTransfer.wall);
      Tin = gas[1].T;
      M = sum(rhobar) * A * l "Fluid mass (single tube)";
      Mtot = M * Nt "Fluid mass (total)";
      Tr = noEvent(M / max(infl.m_flow / Nt, Modelica.Constants.eps)) "Residence time";
      assert(infl.m_flow > (-wnom * wnm), "Reverse flow not allowed, maybe you connected the component with wrong orientation");
    end Flow1DFV;

    function f_colebrook  "Fanning friction factor for water/steam flows"
      input .Modelica.SIunits.MassFlowRate w;
      input Real D_A;
      input Real e;
      input .Modelica.SIunits.DynamicViscosity mu;
      output .Modelica.SIunits.PerUnit f;
    protected
      Real Re;
    algorithm
      Re := w * D_A / mu;
      Re := if Re > 2100 then Re else 2100;
      f := 0.332 / log(e / 3.7 + 5.47 / Re ^ 0.9) ^ 2;
    end f_colebrook;

    package BaseClasses
      extends Modelica.Icons.BasesPackage;

      partial model Flow1DBase  "Basic interface for 1-dimensional water/steam fluid flow models"
        extends Icons.Gas.Tube;
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium annotation(choicesAllMatching = true);
        parameter Integer N(min = 2) = 2 "Number of nodes for thermal variables";
        parameter Integer Nw = N - 1 "Number of volumes on the wall interface";
        parameter Integer Nt = 1 "Number of tubes in parallel";
        parameter .Modelica.SIunits.Distance L "Tube length";
        parameter .Modelica.SIunits.Position H = 0 "Elevation of outlet over inlet";
        parameter .Modelica.SIunits.Area A "Cross-sectional area (single tube)";
        parameter .Modelica.SIunits.Length omega "Perimeter of heat transfer surface (single tube)";
        parameter .Modelica.SIunits.Length Dhyd "Hydraulic Diameter (single tube)";
        parameter Medium.MassFlowRate wnom "Nominal mass flowrate (total)";
        parameter ThermoPower.Choices.Flow1D.FFtypes FFtype = ThermoPower.Choices.Flow1D.FFtypes.NoFriction "Friction Factor Type" annotation(Evaluate = true);
        parameter .Modelica.SIunits.PressureDifference dpnom = 0 "Nominal pressure drop";
        parameter Real Kfnom = 0 "Nominal hydraulic resistance coefficient";
        parameter Medium.Density rhonom = 0 "Nominal inlet density";
        parameter .Modelica.SIunits.PerUnit Cfnom = 0 "Nominal Fanning friction factor";
        parameter .Modelica.SIunits.PerUnit e = 0 "Relative roughness (ratio roughness/diameter)";
        parameter Real Kfc = 1 "Friction factor correction coefficient";
        parameter Boolean DynamicMomentum = false "Inertial phenomena accounted for" annotation(Evaluate = true);
        parameter Boolean UniformComposition = true "Uniform gas composition is assumed" annotation(Evaluate = true);
        parameter Boolean QuasiStatic = false "Quasi-static model (mass, energy and momentum static balances" annotation(Evaluate = true);
        parameter .ThermoPower.Choices.Flow1D.HCtypes HydraulicCapacitance = .ThermoPower.Choices.Flow1D.HCtypes.Downstream "1: Upstream, 2: Downstream";
        parameter Boolean avoidInletEnthalpyDerivative = true "Avoid inlet enthalpy derivative";
        parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
        outer ThermoPower.System system "System wide properties";
        parameter Medium.AbsolutePressure pstart = 1e5 "Pressure start value";
        parameter Medium.Temperature Tstartbar = 300 "Avarage temperature start value";
        parameter Medium.Temperature Tstartin = Tstartbar "Inlet temperature start value";
        parameter Medium.Temperature Tstartout = Tstartbar "Outlet temperature start value";
        parameter Medium.Temperature[N] Tstart = linspace(Tstartin, Tstartout, N) "Start value of temperature vector (initialized by default)";
        final parameter .Modelica.SIunits.Velocity unom = 10 "Nominal velocity for simplified equation";
        parameter Real wnf = 0.01 "Fraction of nominal flow rate at which linear friction equals turbulent friction";
        parameter Medium.MassFraction[nX] Xstart = Medium.reference_X "Start gas composition";
        parameter Choices.Init.Options initOpt = system.initOpt "Initialisation option";
        parameter Boolean noInitialPressure = false "Remove initial equation on pressure";
        function squareReg = ThermoPower.Functions.squareReg;
      protected
        parameter Integer nXi = Medium.nXi "number of independent mass fractions";
        parameter Integer nX = Medium.nX "total number of mass fractions";
      public
        FlangeA infl(redeclare package Medium = Medium, m_flow(start = wnom, min = if allowFlowReversal then -Modelica.Constants.inf else 0));
        FlangeB outfl(redeclare package Medium = Medium, m_flow(start = -wnom, max = if allowFlowReversal then +Modelica.Constants.inf else 0));
      initial equation
        assert(wnom > 0, "Please set a positive value for wnom");
        assert(FFtype == .ThermoPower.Choices.Flow1D.FFtypes.NoFriction or dpnom > 0, "dpnom=0 not valid, it is also used in the homotopy trasformation during the inizialization");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Kfnom and not Kfnom > 0), "Kfnom = 0 not valid, please set a positive value");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.OpPoint and not rhonom > 0), "rhonom = 0 not valid, please set a positive value");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Cfnom and not Cfnom > 0), "Cfnom = 0 not valid, please set a positive value");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Colebrook and not Dhyd > 0), "Dhyd = 0 not valid, please set a positive value");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Colebrook and not e > 0), "e = 0 not valid, please set a positive value");
      end Flow1DBase;
    end BaseClasses;
  end Gas;

  package Water  "Models of components with water/steam as working fluid"
    connector Flange  "Flange connector for water/steam flows"
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
      flow Medium.MassFlowRate m_flow "Mass flow rate from the connection point into the component";
      Medium.AbsolutePressure p "Thermodynamic pressure in the connection point";
      stream Medium.SpecificEnthalpy h_outflow "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
      stream Medium.MassFraction[Medium.nXi] Xi_outflow "Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0";
      stream Medium.ExtraProperty[Medium.nC] C_outflow "Properties c_i/m close to the connection point if m_flow < 0";
    end Flange;

    connector FlangeA  "A-type flange connector for water/steam flows"
      extends ThermoPower.Water.Flange;
    end FlangeA;

    connector FlangeB  "B-type flange connector for water/steam flows"
      extends ThermoPower.Water.Flange;
    end FlangeB;

    extends Modelica.Icons.Package;
    package StandardWater = Modelica.Media.Water.StandardWater;

    model Flow1DFV  "1-dimensional fluid flow model for water/steam (finite volumes)"
      extends BaseClasses.Flow1DBase;
      parameter .Modelica.SIunits.PerUnit wnm = 1e-3 "Maximum fraction of the nominal flow rate allowed as reverse flow";
      parameter Boolean fixedMassFlowSimplified = false "Fix flow rate = wnom for simplified homotopy model";
      Medium.ThermodynamicState[N] fluidState "Thermodynamic state of the fluid at the nodes";
      .Modelica.SIunits.Length omega_hyd "Wet perimeter (single tube)";
      .Modelica.SIunits.Pressure Dpfric "Pressure drop due to friction (total)";
      .Modelica.SIunits.Pressure Dpfric1 "Pressure drop due to friction (from inlet to capacitance)";
      .Modelica.SIunits.Pressure Dpfric2 "Pressure drop due to friction (from capacitance to outlet)";
      .Modelica.SIunits.Pressure Dpstat "Pressure drop due to static head";
      Medium.MassFlowRate win "Flow rate at the inlet (single tube)";
      Medium.MassFlowRate wout "Flow rate at the outlet (single tube)";
      Real Kf "Hydraulic friction coefficient";
      Real dwdt "Dynamic momentum term";
      .Modelica.SIunits.PerUnit Cf "Fanning friction factor";
      Medium.AbsolutePressure p(start = pstart, stateSelect = StateSelect.prefer) "Fluid pressure for property calculations";
      Medium.MassFlowRate w(start = wnom / Nt) "Mass flow rate (single tube)";
      Medium.MassFlowRate[N - 1] wbar(each start = wnom / Nt) "Average flow rate through volumes (single tube)";
      .Modelica.SIunits.Power[N - 1] Q_single = heatTransfer.Qvol / Nt "Heat flows entering the volumes from the lateral boundary (single tube)";
      .Modelica.SIunits.Velocity[N] u "Fluid velocity";
      Medium.Temperature[N] T "Fluid temperature";
      Medium.SpecificEnthalpy[N] h(start = hstart) "Fluid specific enthalpy at the nodes";
      Medium.SpecificEnthalpy[N - 1] htilde(start = hstart[2:N], each stateSelect = StateSelect.prefer) "Enthalpy state variables";
      Medium.Density[N] rho "Fluid nodal density";
      .Modelica.SIunits.Mass M "Fluid mass (single tube)";
      .Modelica.SIunits.Mass Mtot "Fluid mass (total)";
      .Modelica.SIunits.MassFlowRate[N - 1] dMdt "Time derivative of mass in each cell between two nodes";
      replaceable model HeatTransfer = Thermal.HeatTransferFV.IdealHeatTransfer constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFV;
      HeatTransfer heatTransfer(redeclare package Medium = Medium, final Nf = N, final Nw = Nw, final Nt = Nt, final L = L, final A = A, final Dhyd = Dhyd, final omega = omega, final wnom = wnom / Nt, final w = w * ones(N), final fluidState = fluidState) "Instantiated heat transfer model";
      ThermoPower.Thermal.DHTVolumes wall(final N = Nw);
    protected
      Medium.Density[N - 1] rhobar "Fluid average density";
      .Modelica.SIunits.SpecificVolume[N - 1] vbar "Fluid average specific volume";
      .Modelica.SIunits.DerDensityByEnthalpy[N] drdh "Derivative of density by enthalpy";
      .Modelica.SIunits.DerDensityByEnthalpy[N - 1] drbdh "Derivative of average density by enthalpy";
      .Modelica.SIunits.DerDensityByPressure[N] drdp "Derivative of density by pressure";
      .Modelica.SIunits.DerDensityByPressure[N - 1] drbdp "Derivative of average density by pressure";
    initial equation
      if initOpt == Choices.Init.Options.noInit then
      elseif initOpt == Choices.Init.Options.fixedState then
        if not noInitialPressure then
          p = pstart;
        end if;
        htilde = hstart[2:N];
      elseif initOpt == Choices.Init.Options.steadyState then
        der(htilde) = zeros(N - 1);
        if not Medium.singleState and not noInitialPressure then
          der(p) = 0;
        end if;
      elseif initOpt == Choices.Init.Options.steadyStateNoP then
        der(htilde) = zeros(N - 1);
        assert(false, "initOpt = steadyStateNoP deprecated, use steadyState and noInitialPressure", AssertionLevel.warning);
      elseif initOpt == Choices.Init.Options.steadyStateNoT and not Medium.singleState then
        der(p) = 0;
      else
        assert(false, "Unsupported initialisation option");
      end if;
    equation
      omega_hyd = 4 * A / Dhyd;
      if FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Kfnom then
        Kf = Kfnom * Kfc;
      elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.OpPoint then
        Kf = dpnom * rhonom / (wnom / Nt) ^ 2 * Kfc;
      elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Cfnom then
        Cf = Cfnom * Kfc;
      elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Colebrook then
        Cf = f_colebrook(w, Dhyd / A, e, Medium.dynamicViscosity(fluidState[integer(N / 2)])) * Kfc;
      else
        Cf = 0;
      end if;
      Kf = Cf * omega_hyd * L / (2 * A ^ 3) "Relationship between friction coefficient and Fanning friction factor";
      assert(Kf >= 0, "Negative friction coefficient");
      if DynamicMomentum then
        dwdt = der(w);
      else
        dwdt = 0;
      end if;
      sum(dMdt) = (infl.m_flow + outfl.m_flow) / Nt "Mass balance";
      L / A * dwdt + outfl.p - infl.p + Dpstat + Dpfric = 0 "Momentum balance";
      Dpfric = Dpfric1 + Dpfric2 "Total pressure drop due to friction";
      if FFtype == .ThermoPower.Choices.Flow1D.FFtypes.NoFriction then
        Dpfric1 = 0;
        Dpfric2 = 0;
      elseif HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Middle then
        Dpfric1 = homotopy(Kf * squareReg(win, wnom / Nt * wnf) * sum(vbar[1:integer((N - 1) / 2)]) / (N - 1), dpnom / 2 / (wnom / Nt) * win) "Pressure drop from inlet to capacitance";
        Dpfric2 = homotopy(Kf * squareReg(wout, wnom / Nt * wnf) * sum(vbar[1 + integer((N - 1) / 2):N - 1]) / (N - 1), dpnom / 2 / (wnom / Nt) * wout) "Pressure drop from capacitance to outlet";
      elseif HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Upstream then
        Dpfric1 = 0 "Pressure drop from inlet to capacitance";
        Dpfric2 = homotopy(Kf * squareReg(wout, wnom / Nt * wnf) * sum(vbar) / (N - 1), dpnom / (wnom / Nt) * wout) "Pressure drop from capacitance to outlet";
      else
        Dpfric1 = homotopy(Kf * squareReg(win, wnom / Nt * wnf) * sum(vbar) / (N - 1), dpnom / (wnom / Nt) * win) "Pressure drop from inlet to capacitance";
        Dpfric2 = 0 "Pressure drop from capacitance to outlet";
      end if;
      Dpstat = if abs(dzdx) < 1e-6 then 0 else g * l * dzdx * sum(rhobar) "Pressure drop due to static head";
      for j in 1:N - 1 loop
        if Medium.singleState then
          A * l * rhobar[j] * der(htilde[j]) + wbar[j] * (h[j + 1] - h[j]) = Q_single[j] "Energy balance (pressure effects neglected)";
        else
          A * l * rhobar[j] * der(htilde[j]) + wbar[j] * (h[j + 1] - h[j]) - A * l * der(p) = Q_single[j] "Energy balance";
        end if;
        dMdt[j] = A * l * (drbdh[j] * der(htilde[j]) + drbdp[j] * der(p)) "Mass derivative for each volume";
        rhobar[j] = (rho[j] + rho[j + 1]) / 2;
        drbdp[j] = (drdp[j] + drdp[j + 1]) / 2;
        drbdh[j] = (drdh[j] + drdh[j + 1]) / 2;
        vbar[j] = 1 / rhobar[j];
        if fixedMassFlowSimplified then
          wbar[j] = homotopy(infl.m_flow / Nt - sum(dMdt[1:j - 1]) - dMdt[j] / 2, wnom / Nt);
        else
          wbar[j] = infl.m_flow / Nt - sum(dMdt[1:j - 1]) - dMdt[j] / 2;
        end if;
      end for;
      for j in 1:N loop
        fluidState[j] = Medium.setState_ph(p, h[j]);
        T[j] = Medium.temperature(fluidState[j]);
        rho[j] = Medium.density(fluidState[j]);
        drdp[j] = if Medium.singleState then 0 else Medium.density_derp_h(fluidState[j]);
        drdh[j] = Medium.density_derh_p(fluidState[j]);
        u[j] = w / (rho[j] * A);
      end for;
      win = infl.m_flow / Nt;
      wout = -outfl.m_flow / Nt;
      assert(HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Upstream or HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Middle or HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Downstream, "Unsupported HydraulicCapacitance option");
      if HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Middle then
        p = infl.p - Dpfric1 - Dpstat / 2;
        w = win;
      elseif HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Upstream then
        p = infl.p;
        w = -outfl.m_flow / Nt;
      else
        p = outfl.p;
        w = win;
      end if;
      infl.h_outflow = htilde[1];
      outfl.h_outflow = htilde[N - 1];
      h[1] = inStream(infl.h_outflow);
      h[2:N] = htilde;
      connect(wall, heatTransfer.wall);
      Q = heatTransfer.Q "Total heat flow through lateral boundary";
      M = sum(rhobar) * A * l "Fluid mass (single tube)";
      Mtot = M * Nt "Fluid mass (total)";
      Tr = noEvent(M / max(win, Modelica.Constants.eps)) "Residence time";
      assert(w > (-wnom * wnm), "Reverse flow not allowed, maybe you connected the component with wrong orientation");
    end Flow1DFV;

    model DrumEquilibrium
      extends Icons.Water.Drum;
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium;
      parameter .Modelica.SIunits.Volume Vd "Drum internal volume";
      parameter .Modelica.SIunits.Mass Mm "Drum metal mass";
      parameter Medium.SpecificHeatCapacity cm "Specific heat capacity of the metal";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
      outer ThermoPower.System system "System wide properties";
      parameter .Modelica.SIunits.Pressure pstart "Pressure start value";
      parameter .Modelica.SIunits.Volume Vlstart "Start value of drum water volume";
      parameter Choices.Init.Options initOpt = system.initOpt "Initialisation option";
      parameter Boolean noInitialPressure = false "Remove initial equation on pressure";
      Medium.SaturationProperties sat "Saturation conditions";
      FlangeA feed(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      FlangeB steam(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
      Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a wall "Metal wall thermal port";
      .Modelica.SIunits.Mass Ml "Liquid water mass";
      .Modelica.SIunits.Mass Mv "Steam mass";
      .Modelica.SIunits.Mass M "Total liquid+steam mass";
      .Modelica.SIunits.Energy E "Total energy";
      .Modelica.SIunits.Volume Vv(start = Vd - Vlstart) "Steam volume";
      .Modelica.SIunits.Volume Vl(start = Vlstart, stateSelect = StateSelect.prefer) "Liquid water total volume";
      Medium.AbsolutePressure p(start = pstart, stateSelect = StateSelect.prefer) "Drum pressure";
      Medium.MassFlowRate qf "Feedwater mass flowrate";
      Medium.MassFlowRate qs "Steam mass flowrate";
      .Modelica.SIunits.HeatFlowRate Q "Heat flow to the risers";
      Medium.SpecificEnthalpy hf "Feedwater specific enthalpy";
      Medium.SpecificEnthalpy hl "Specific enthalpy of saturated liquid";
      Medium.SpecificEnthalpy hv "Specific enthalpy of saturated steam";
      Medium.Temperature Ts "Saturation temperature";
      Units.LiquidDensity rhol "Density of saturated liquid";
      Units.GasDensity rhov "Density of saturated steam";
    initial equation
      if initOpt == Choices.Init.Options.noInit then
      elseif initOpt == Choices.Init.Options.fixedState then
        if not noInitialPressure then
          p = pstart;
        end if;
        Vl = Vlstart;
      elseif initOpt == Choices.Init.Options.steadyState then
        if not noInitialPressure then
          der(p) = 0;
        end if;
        der(Vl) = 0;
      else
        assert(false, "Unsupported initialisation option");
      end if;
    equation
      Ml = Vl * rhol "Mass of liquid";
      Mv = Vv * rhov "Mass of vapour";
      M = Ml + Mv "Total mass";
      E = Ml * hl + Mv * hv - p * Vd + Mm * cm * Ts "Total energy";
      Ts = sat.Tsat "Saturation temperature";
      der(M) = qf - qs "Mass balance";
      der(E) = Q + qf * hf - qs * hv "Energy balance";
      Vl + Vv = Vd "Total volume";
      p = feed.p;
      p = steam.p;
      if not allowFlowReversal then
        hf = inStream(feed.h_outflow);
      else
        hf = homotopy(actualStream(feed.h_outflow), inStream(feed.h_outflow));
      end if;
      feed.m_flow = qf;
      -steam.m_flow = qs;
      feed.h_outflow = hl;
      steam.h_outflow = hv;
      Q = wall.Q_flow;
      wall.T = Ts;
      sat.psat = p;
      sat.Tsat = Medium.saturationTemperature(p);
      rhol = Medium.bubbleDensity(sat);
      rhov = Medium.dewDensity(sat);
      hl = Medium.bubbleEnthalpy(sat);
      hv = Medium.dewEnthalpy(sat);
    end DrumEquilibrium;

    model Pump  "Centrifugal pump with ideally controlled speed"
      extends BaseClasses.PumpBase;
      parameter .Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm n_const = n0 "Constant rotational speed";
      Modelica.Blocks.Interfaces.RealInput in_n if use_in_n "RPM";
      parameter Boolean use_in_n = false "Use connector input for the rotational speed";
    protected
      Modelica.Blocks.Interfaces.RealInput in_n_int "Internal connector for rotational speed";
    equation
      connect(in_n, in_n_int);
      if not use_in_n then
        in_n_int = n_const "Rotational speed provided by parameter";
      end if;
      n = in_n_int "Rotational speed";
    end Pump;

    function f_colebrook  "Fanning friction factor for water/steam flows"
      input .Modelica.SIunits.MassFlowRate w;
      input Real D_A;
      input Real e;
      input .Modelica.SIunits.DynamicViscosity mu;
      output .Modelica.SIunits.PerUnit f;
    protected
      .Modelica.SIunits.PerUnit Re;
    algorithm
      Re := abs(w) * D_A / mu;
      Re := if Re > 2100 then Re else 2100;
      f := 0.332 / log(e / 3.7 + 5.47 / Re ^ 0.9) ^ 2;
    end f_colebrook;

    model SteamTurbineStodola  "Steam turbine: Stodola's ellipse law and constant isentropic efficiency"
      extends BaseClasses.SteamTurbineBase;
      parameter .Modelica.SIunits.PerUnit eta_iso_nom = 0.92 "Nominal isentropic efficiency";
      parameter .Modelica.SIunits.Area Kt "Kt coefficient of Stodola's law";
      Medium.Density rho "Inlet density";
    equation
      rho = Medium.density(steamState_in);
      w = homotopy(Kt * theta * sqrt(pin * rho) * Functions.sqrtReg(1 - (1 / PR) ^ 2), theta * wnom / pnom * pin) "Stodola's law";
      eta_iso = eta_iso_nom "Constant efficiency";
    end SteamTurbineStodola;

    package BaseClasses  "Contains partial models"
      extends Modelica.Icons.BasesPackage;

      partial model Flow1DBase  "Basic interface for 1-dimensional water/steam fluid flow models"
        replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
        extends Icons.Water.Tube;
        constant Real pi = Modelica.Constants.pi;
        parameter Integer N(min = 2) = 2 "Number of nodes for thermal variables";
        parameter Integer Nw = N - 1 "Number of volumes on the wall interface";
        parameter Integer Nt = 1 "Number of tubes in parallel";
        parameter .Modelica.SIunits.Distance L "Tube length" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Position H = 0 "Elevation of outlet over inlet";
        parameter .Modelica.SIunits.Area A "Cross-sectional area (single tube)";
        parameter .Modelica.SIunits.Length omega "Perimeter of heat transfer surface (single tube)";
        parameter .Modelica.SIunits.Length Dhyd = omega / pi "Hydraulic Diameter (single tube)";
        parameter Medium.MassFlowRate wnom "Nominal mass flowrate (total)";
        parameter ThermoPower.Choices.Flow1D.FFtypes FFtype = ThermoPower.Choices.Flow1D.FFtypes.NoFriction "Friction Factor Type" annotation(Evaluate = true);
        parameter .Modelica.SIunits.PressureDifference dpnom = 0 "Nominal pressure drop (friction term only!)";
        parameter Real Kfnom = 0 "Nominal hydraulic resistance coefficient (DP = Kfnom*w^2/rho)";
        parameter Medium.Density rhonom = 0 "Nominal inlet density";
        parameter .Modelica.SIunits.PerUnit Cfnom = 0 "Nominal Fanning friction factor";
        parameter .Modelica.SIunits.PerUnit e = 0 "Relative roughness (ratio roughness/diameter)";
        parameter .Modelica.SIunits.PerUnit Kfc = 1 "Friction factor correction coefficient";
        parameter Boolean DynamicMomentum = false "Inertial phenomena accounted for" annotation(Evaluate = true);
        parameter ThermoPower.Choices.Flow1D.HCtypes HydraulicCapacitance = ThermoPower.Choices.Flow1D.HCtypes.Downstream "Location of the hydraulic capacitance";
        parameter Boolean avoidInletEnthalpyDerivative = true "Avoid inlet enthalpy derivative";
        parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
        outer ThermoPower.System system "System wide properties";
        parameter Choices.FluidPhase.FluidPhases FluidPhaseStart = Choices.FluidPhase.FluidPhases.Liquid "Fluid phase (only for initialization!)";
        parameter Medium.AbsolutePressure pstart = 1e5 "Pressure start value";
        parameter Medium.SpecificEnthalpy hstartin = if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Liquid then 1e5 else if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Steam then 3e6 else 1e6 "Inlet enthalpy start value";
        parameter Medium.SpecificEnthalpy hstartout = if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Liquid then 1e5 else if FluidPhaseStart == Choices.FluidPhase.FluidPhases.Steam then 3e6 else 1e6 "Outlet enthalpy start value";
        parameter Medium.SpecificEnthalpy[N] hstart = linspace(hstartin, hstartout, N) "Start value of enthalpy vector (initialized by default)";
        parameter .Modelica.SIunits.PerUnit wnf = 0.02 "Fraction of nominal flow rate at which linear friction equals turbulent friction";
        parameter Choices.Init.Options initOpt = system.initOpt "Initialisation option";
        parameter Boolean noInitialPressure = false "Remove initial equation on pressure";
        constant .Modelica.SIunits.Acceleration g = Modelica.Constants.g_n;
        function squareReg = ThermoPower.Functions.squareReg;
        FlangeA infl(h_outflow(start = hstartin), redeclare package Medium = Medium, m_flow(start = wnom, min = if allowFlowReversal then -Modelica.Constants.inf else 0));
        FlangeB outfl(h_outflow(start = hstartout), redeclare package Medium = Medium, m_flow(start = -wnom, max = if allowFlowReversal then +Modelica.Constants.inf else 0));
        .Modelica.SIunits.Power Q "Total heat flow through the lateral boundary (all Nt tubes)";
        .Modelica.SIunits.Time Tr "Residence time";
        final parameter .Modelica.SIunits.PerUnit dzdx = H / L "Slope" annotation(Evaluate = true);
        final parameter .Modelica.SIunits.Length l = L / (N - 1) "Length of a single volume";
        final parameter .Modelica.SIunits.Volume V = Nt * A * L "Total volume (all Nt tubes)";
      initial equation
        assert(wnom > 0, "Please set a positive value for wnom");
        assert(FFtype == .ThermoPower.Choices.Flow1D.FFtypes.NoFriction or dpnom > 0, "dpnom=0 not valid, it is also used in the homotopy trasformation during the inizialization");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Kfnom and not Kfnom > 0), "Kfnom = 0 not valid, please set a positive value");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.OpPoint and not rhonom > 0), "rhonom = 0 not valid, please set a positive value");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Cfnom and not Cfnom > 0), "Cfnom = 0 not valid, please set a positive value");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Colebrook and not Dhyd > 0), "Dhyd = 0 not valid, please set a positive value");
        assert(not (FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Colebrook and not e > 0), "e = 0 not valid, please set a positive value");
        annotation(Evaluate = true);
      end Flow1DBase;

      partial model PumpBase  "Base model for centrifugal pumps"
        extends Icons.Water.Pump;
        replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
        Medium.ThermodynamicState inletFluidState "Thermodynamic state of the fluid at the inlet";
        replaceable function flowCharacteristic = ThermoPower.Functions.PumpCharacteristics.baseFlow "Head vs. q_flow characteristic at nominal speed and density" annotation(choicesAllMatching = true);
        parameter Boolean usePowerCharacteristic = false "Use powerCharacteristic (vs. efficiencyCharacteristic)";
        replaceable function powerCharacteristic = Functions.PumpCharacteristics.constantPower constrainedby ThermoPower.Functions.PumpCharacteristics.basePower;
        replaceable function efficiencyCharacteristic = Functions.PumpCharacteristics.constantEfficiency(eta_nom = 0.8) constrainedby ThermoPower.Functions.PumpCharacteristics.baseEfficiency;
        parameter Integer Np0(min = 1) = 1 "Nominal number of pumps in parallel";
        parameter Boolean use_in_Np = false "Use connector input for the pressure";
        parameter Units.LiquidDensity rho0 = 1000 "Nominal Liquid Density";
        parameter .Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm n0 "Nominal rotational speed";
        parameter .Modelica.SIunits.Volume V = 0 "Pump Internal Volume" annotation(Evaluate = true);
        parameter Boolean CheckValve = false "Reverse flow stopped";
        parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
        outer ThermoPower.System system "System wide properties";
        parameter Medium.MassFlowRate wstart = w0 "Mass Flow Rate Start Value";
        parameter Medium.SpecificEnthalpy hstart = 1e5 "Specific Enthalpy Start Value";
        parameter Choices.Init.Options initOpt = system.initOpt "Initialisation option";
        parameter Boolean noInitialPressure = false "Remove initial equation on pressure";
        constant .Modelica.SIunits.Acceleration g = Modelica.Constants.g_n;
        parameter Medium.MassFlowRate w0 "Nominal mass flow rate";
        parameter .Modelica.SIunits.Pressure dp0 "Nominal pressure increase";
        final parameter .Modelica.SIunits.VolumeFlowRate q_single0 = w0 / (Np0 * rho0) "Nominal volume flow rate (single pump)" annotation(Evaluate = true);
        final parameter .Modelica.SIunits.Height head0 = dp0 / (rho0 * g) "Nominal pump head" annotation(Evaluate = true);
        final parameter Real d_head_dq_0 = (flowCharacteristic(q_single0 * 1.05) - flowCharacteristic(q_single0 * 0.95)) / (q_single0 * 0.1) "Approximate derivative of flow characteristic w.r.t. volume flow" annotation(Evaluate = true);
        final parameter Real d_head_dn_0 = 2 / n0 * head0 - q_single0 / n0 * d_head_dq_0 "Approximate derivative of the flow characteristic w.r.t. rotational speed" annotation(Evaluate = true);
        Medium.MassFlowRate w_single(start = wstart / Np0) "Mass flow rate (single pump)";
        Medium.MassFlowRate w = Np * w_single "Mass flow rate (total)";
        .Modelica.SIunits.VolumeFlowRate q_single(start = wstart / (Np0 * rho0)) "Volume flow rate (single pump)";
        .Modelica.SIunits.VolumeFlowRate q = Np * q_single "Volume flow rate (total)";
        .Modelica.SIunits.PressureDifference dp "Outlet pressure minus inlet pressure";
        .Modelica.SIunits.Height head "Pump head";
        Medium.SpecificEnthalpy h(start = hstart) "Fluid specific enthalpy";
        Medium.SpecificEnthalpy hin "Enthalpy of entering fluid";
        Medium.SpecificEnthalpy hout "Enthalpy of outgoing fluid";
        Units.LiquidDensity rho "Liquid density";
        Medium.Temperature Tin "Liquid inlet temperature";
        .Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm n "Shaft r.p.m.";
        Integer Np(min = 1) "Number of pumps in parallel";
        .Modelica.SIunits.Power W_single "Power Consumption (single pump)";
        .Modelica.SIunits.Power W = Np * W_single "Power Consumption (total)";
        .Modelica.SIunits.Power Qloss = 0 "Heat loss (single pump)";
        constant .Modelica.SIunits.Power W_eps = 1e-8 "Small coefficient to avoid numerical singularities";
        constant .Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm n_eps = 1e-6;
        .Modelica.SIunits.PerUnit eta "Pump efficiency";
        .Modelica.SIunits.PerUnit s(start = 1) "Auxiliary non-dimensional variable";
        FlangeA infl(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
        FlangeB outfl(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
        Modelica.Blocks.Interfaces.IntegerInput in_Np if use_in_Np "Number of  parallel pumps";
      protected
        Modelica.Blocks.Interfaces.IntegerInput int_Np "Internal connector with number of parallel pumps";
      initial equation
        if initOpt == Choices.Init.Options.noInit then
        elseif initOpt == Choices.Init.Options.fixedState then
          if V > 0 then
            h = hstart;
          end if;
        elseif initOpt == Choices.Init.Options.steadyState then
          if V > 0 then
            der(h) = 0;
          end if;
        else
          assert(false, "Unsupported initialisation option");
        end if;
      equation
        q_single = w_single / homotopy(rho, rho0);
        head = dp / (homotopy(rho, rho0) * g);
        if noEvent(s > 0 or not CheckValve) then
          q_single = s * q_single0;
          head = homotopy((n / n0) ^ 2 * flowCharacteristic(q_single * n0 / (n + n_eps)), head0 + d_head_dq_0 * (q_single - q_single0) + d_head_dn_0 * (n - n0));
        else
          head = homotopy((n / n0) ^ 2 * flowCharacteristic(0) - s * head0, head0 + d_head_dq_0 * (q_single - q_single0) + d_head_dn_0 * (n - n0));
          q_single = 0;
        end if;
        if usePowerCharacteristic then
          W_single = (n / n0) ^ 3 * (rho / rho0) * powerCharacteristic(q_single * n0 / (n + n_eps)) "Power consumption (single pump)";
          eta = dp * q_single / (W_single + W_eps) "Hydraulic efficiency";
        else
          eta = efficiencyCharacteristic(q_single * n0 / (n + n_eps));
          W_single = dp * q_single / eta;
        end if;
        inletFluidState = Medium.setState_ph(infl.p, hin);
        rho = Medium.density(inletFluidState);
        Tin = Medium.temperature(inletFluidState);
        dp = outfl.p - infl.p;
        w = infl.m_flow "Pump total flow rate";
        hin = homotopy(if not allowFlowReversal then inStream(infl.h_outflow) else if w >= 0 then inStream(infl.h_outflow) else inStream(outfl.h_outflow), inStream(infl.h_outflow));
        infl.h_outflow = hout;
        outfl.h_outflow = hout;
        h = hout;
        infl.m_flow + outfl.m_flow = 0 "Mass balance";
        if V > 0 then
          rho * V * der(h) = outfl.m_flow / Np * hout + infl.m_flow / Np * hin + W_single - Qloss "Energy balance";
        else
          0 = outfl.m_flow / Np * hout + infl.m_flow / Np * hin + W_single - Qloss "Energy balance";
        end if;
        connect(in_Np, int_Np);
        if not use_in_Np then
          int_Np = Np0;
        end if;
        Np = int_Np;
      end PumpBase;

      partial model SteamTurbineBase  "Steam turbine"
        replaceable package Medium = ThermoPower.Water.StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
        parameter Boolean explicitIsentropicEnthalpy = true "Outlet enthalpy computed by isentropicEnthalpy function";
        parameter Medium.MassFlowRate wstart = wnom "Mass flow rate start value";
        parameter .Modelica.SIunits.PerUnit PRstart "Pressure ratio start value";
        parameter Medium.MassFlowRate wnom "Inlet nominal flowrate";
        parameter Medium.AbsolutePressure pnom "Nominal inlet pressure";
        parameter Real eta_mech = 0.98 "Mechanical efficiency";
        parameter Boolean usePartialArcInput = false "Use the input connector for the partial arc opening";
        outer ThermoPower.System system "System wide properties";
        Medium.ThermodynamicState steamState_in;
        Medium.ThermodynamicState steamState_iso;
        .Modelica.SIunits.Angle phi "shaft rotation angle";
        .Modelica.SIunits.Torque tau "net torque acting on the turbine";
        .Modelica.SIunits.AngularVelocity omega "shaft angular velocity";
        Medium.MassFlowRate w(start = wstart) "Mass flow rate";
        Medium.SpecificEnthalpy hin "Inlet enthalpy";
        Medium.SpecificEnthalpy hout "Outlet enthalpy";
        Medium.SpecificEnthalpy hiso "Isentropic outlet enthalpy";
        Medium.SpecificEntropy sin "Inlet entropy";
        Medium.AbsolutePressure pin(start = pnom) "Outlet pressure";
        Medium.AbsolutePressure pout(start = pnom / PRstart) "Outlet pressure";
        .Modelica.SIunits.PerUnit PR "pressure ratio";
        .Modelica.SIunits.Power Pm "Mechanical power input";
        .Modelica.SIunits.PerUnit eta_iso "Isentropic efficiency";
        .Modelica.SIunits.PerUnit theta "Partial arc opening in p.u.";
        Modelica.Blocks.Interfaces.RealInput partialArc if usePartialArcInput "Partial arc opening in p.u.";
        Modelica.Mechanics.Rotational.Interfaces.Flange_a shaft_a;
        Modelica.Mechanics.Rotational.Interfaces.Flange_b shaft_b;
        FlangeA inlet(redeclare package Medium = Medium, m_flow(min = 0));
        FlangeB outlet(redeclare package Medium = Medium, m_flow(max = 0));
      protected
        Modelica.Blocks.Interfaces.RealInput partialArc_int "Internal connector for partial arc input";
      equation
        PR = pin / pout "Pressure ratio";
        theta = partialArc_int;
        if not usePartialArcInput then
          partialArc_int = 1 "Default value if not connector input is disabled";
        end if;
        if explicitIsentropicEnthalpy then
          hiso = Medium.isentropicEnthalpy(pout, steamState_in) "Isentropic enthalpy";
          sin = 0;
          steamState_iso = Medium.setState_ph(1e5, 1e5);
        else
          sin = Medium.specificEntropy(steamState_in);
          steamState_iso = Medium.setState_ps(pout, sin);
          hiso = Medium.specificEnthalpy(steamState_iso);
        end if;
        hin - hout = eta_iso * (hin - hiso) "Computation of outlet enthalpy";
        Pm = eta_mech * w * (hin - hout) "Mechanical power from the steam";
        Pm = -tau * omega "Mechanical power balance";
        inlet.m_flow + outlet.m_flow = 0 "Mass balance";
        assert(w >= (-wnom / 100), "The turbine model does not support flow reversal");
        shaft_a.phi = phi;
        shaft_b.phi = phi;
        shaft_a.tau + shaft_b.tau = tau;
        der(phi) = omega;
        steamState_in = Medium.setState_ph(pin, inStream(inlet.h_outflow));
        hin = inStream(inlet.h_outflow);
        hout = outlet.h_outflow;
        pin = inlet.p;
        pout = outlet.p;
        w = inlet.m_flow;
        inlet.h_outflow = outlet.h_outflow;
      end SteamTurbineBase;
    end BaseClasses;
  end Water;

  package Thermal  "Thermal models of heat transfer"
    extends Modelica.Icons.Package;
    connector HT = Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a "Thermal port for lumped parameter heat transfer";

    connector DHTVolumes  "Distributed Heat Terminal"
      parameter Integer N "Number of volumes";
      .Modelica.SIunits.Temperature[N] T "Temperature at the volumes";
      flow .Modelica.SIunits.Power[N] Q "Heat flow at the volumes";
    end DHTVolumes;

    model HT_DHTVolumes  "HT to DHT adaptor"
      parameter Integer N = 1 "Number of volumes on the connectors";
      HT HT_port;
      DHTVolumes DHT_port(N = N);
    equation
      for i in 1:N loop
        DHT_port.T[i] = HT_port.T "Uniform temperature distribution on DHT side";
      end for;
      sum(DHT_port.Q) + HT_port.Q_flow = 0 "Energy balance";
    end HT_DHTVolumes;

    model MetalTubeFV  "Cylindrical metal tube model with Nw finite volumes"
      extends Icons.MetalWall;
      parameter Integer Nw = 1 "Number of volumes on the wall ports";
      parameter Integer Nt = 1 "Number of tubes in parallel";
      parameter .Modelica.SIunits.Length L "Tube length";
      parameter .Modelica.SIunits.Length rint "Internal radius (single tube)";
      parameter .Modelica.SIunits.Length rext "External radius (single tube)";
      parameter Real rhomcm "Metal heat capacity per unit volume [J/m^3.K]";
      parameter .Modelica.SIunits.ThermalConductivity lambda "Thermal conductivity";
      parameter Boolean WallRes = true "Wall thermal resistance accounted for";
      parameter .Modelica.SIunits.Temperature Tstartbar = 300 "Avarage temperature";
      parameter .Modelica.SIunits.Temperature Tstart1 = Tstartbar "Temperature start value - first volume";
      parameter .Modelica.SIunits.Temperature TstartN = Tstartbar "Temperature start value - last volume";
      parameter .Modelica.SIunits.Temperature[Nw] Tvolstart = Functions.linspaceExt(Tstart1, TstartN, Nw);
      parameter Choices.Init.Options initOpt = system.initOpt "Initialisation option";
      constant Real pi = Modelica.Constants.pi;
      final parameter .Modelica.SIunits.Area Am = (rext ^ 2 - rint ^ 2) * pi "Area of the metal tube cross-section";
      final parameter .Modelica.SIunits.HeatCapacity Cm = Nt * L * Am * rhomcm "Total heat capacity";
      outer ThermoPower.System system "System wide properties";
      .Modelica.SIunits.Temperature[Nw] Tvol(start = Tvolstart) "Volume temperatures";
      ThermoPower.Thermal.DHTVolumes int(final N = Nw, T(start = Tvolstart)) "Internal surface";
      ThermoPower.Thermal.DHTVolumes ext(final N = Nw, T(start = Tvolstart)) "External surface";
    initial equation
      if initOpt == Choices.Init.Options.noInit then
      elseif initOpt == Choices.Init.Options.fixedState then
        Tvol = Tvolstart;
      elseif initOpt == Choices.Init.Options.steadyState then
        der(Tvol) = zeros(Nw);
      elseif initOpt == Choices.Init.Options.steadyStateNoT then
      else
        assert(false, "Unsupported initialisation option");
      end if;
    equation
      assert(rext > rint, "External radius must be greater than internal radius");
      L / Nw * Nt * rhomcm * Am * der(Tvol) = int.Q + ext.Q "Energy balance";
      if WallRes then
        int.Q = lambda * (2 * pi * L / Nw) * (int.T - Tvol) / log((rint + rext) / (2 * rint)) * Nt "Heat conduction through the internal half-thickness";
        ext.Q = lambda * (2 * pi * L / Nw) * (ext.T - Tvol) / log(2 * rext / (rint + rext)) * Nt "Heat conduction through the external half-thickness";
      else
        ext.T = Tvol;
        int.T = Tvol;
      end if;
    end MetalTubeFV;

    model HeatExchangerTopologyFV  "Connects two DHTVolumes ports according to a selected heat exchanger topology"
      extends Icons.HeatFlow;
      parameter Integer Nw "Number of volumes";
      replaceable model HeatExchangerTopology = HeatExchangerTopologies.CoCurrentFlow constrainedby ThermoPower.Thermal.BaseClasses.HeatExchangerTopologyData;
      HeatExchangerTopology HET(final Nw = Nw);
      Thermal.DHTVolumes side1(final N = Nw);
      Thermal.DHTVolumes side2(final N = Nw);
    equation
      for j in 1:Nw loop
        side2.T[HET.correspondingVolumes[j]] = side1.T[j];
        side2.Q[HET.correspondingVolumes[j]] + side1.Q[j] = 0;
      end for;
    end HeatExchangerTopologyFV;

    model CounterCurrentFV  "Connects two DHTVolume ports according to a counter-current flow configuration"
      extends ThermoPower.Thermal.HeatExchangerTopologyFV(redeclare model HeatExchangerTopology = HeatExchangerTopologies.CounterCurrentFlow);
    end CounterCurrentFV;

    package HeatTransferFV  "Heat transfer models for FV components"
      model IdealHeatTransfer  "Delta T across the boundary layer is zero (infinite h.t.c.)"
        extends BaseClasses.DistributedHeatTransferFV(final useAverageTemperature = false);
      equation
        assert(Nw == Nf - 1, "Number of volumes Nw on wall side should be equal to number of volumes fluid side Nf - 1");
        for j in 1:Nw loop
          wall.T[j] = T[j + 1] "Ideal infinite heat transfer";
        end for;
      end IdealHeatTransfer;

      model ConstantHeatTransferCoefficient  "Constant heat transfer coefficient"
        extends BaseClasses.DistributedHeatTransferFV;
        parameter .Modelica.SIunits.CoefficientOfHeatTransfer gamma "Constant heat transfer coefficient";
        parameter Boolean adaptiveAverageTemperature = true "Adapt the average temperature at low flow rates";
        parameter Modelica.SIunits.PerUnit sigma = 0.1 "Fraction of nominal flow rate below which the heat transfer is computed on outlet volume temperatures";
        .Modelica.SIunits.PerUnit w_wnom "Ratio between actual and nominal flow rate";
        Medium.Temperature[Nw] Tvol "Fluid temperature in the volumes";
      equation
        assert(Nw == Nf - 1, "The number of volumes Nw on wall side should be equal to number of volumes fluid side Nf - 1");
        w_wnom = abs(w[1]) / wnom;
        for j in 1:Nw loop
          Tvol[j] = if not useAverageTemperature then T[j + 1] else if not adaptiveAverageTemperature then (T[j] + T[j + 1]) / 2 else (T[j] + T[j + 1]) / 2 + (T[j + 1] - T[j]) / 2 * exp(-w_wnom / sigma);
          Qw[j] = (Tw[j] - Tvol[j]) * omega * l * gamma * Nt;
        end for;
      end ConstantHeatTransferCoefficient;
    end HeatTransferFV;

    package HeatExchangerTopologies
      model CoCurrentFlow  "Co-current flow"
        extends BaseClasses.HeatExchangerTopologyData(final correspondingVolumes = 1:Nw);
      end CoCurrentFlow;

      model CounterCurrentFlow  "Counter-current flow"
        extends BaseClasses.HeatExchangerTopologyData(final correspondingVolumes = Nw:(-1):1);
      end CounterCurrentFlow;
    end HeatExchangerTopologies;

    package BaseClasses
      partial model DistributedHeatTransferFV  "Base class for distributed heat transfer models - finite volumes"
        extends ThermoPower.Icons.HeatFlow;
        input Medium.ThermodynamicState[Nf] fluidState;
        input Medium.MassFlowRate[Nf] w;
        parameter Boolean useAverageTemperature = true "= true to use average temperature for heat transfer";
        ThermoPower.Thermal.DHTVolumes wall(final N = Nw);
        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium model";
        parameter Integer Nf(min = 2) = 2 "Number of nodes on the fluid side";
        parameter Integer Nw = Nf - 1 "Number of volumes on the wall side";
        parameter Integer Nt(min = 1) "Number of tubes in parallel";
        parameter .Modelica.SIunits.Distance L "Tube length";
        parameter .Modelica.SIunits.Area A "Cross-sectional area (single tube)";
        parameter .Modelica.SIunits.Length omega "Wet perimeter of heat transfer surface (single tube)";
        parameter .Modelica.SIunits.Length Dhyd "Hydraulic Diameter (single tube)";
        parameter .Modelica.SIunits.MassFlowRate wnom "Nominal mass flow rate (single tube)";
        final parameter .Modelica.SIunits.Length l = L / Nw "Length of a single volume";
        Medium.Temperature[Nf] T "Temperatures at the fluid side nodes";
        Medium.Temperature[Nw] Tw "Temperatures of the wall volumes";
        .Modelica.SIunits.Power[Nw] Qw "Heat flows entering from the wall volumes";
        .Modelica.SIunits.Power[Nf - 1] Qvol = Qw "Heat flows going to the fluid volumes";
        .Modelica.SIunits.Power Q "Total heat flow through lateral boundary";
      equation
        for j in 1:Nf loop
          T[j] = Medium.temperature(fluidState[j]);
        end for;
        Tw = wall.T;
        Qw = wall.Q;
        Q = sum(wall.Q);
      end DistributedHeatTransferFV;

      partial model HeatExchangerTopologyData  "Base class for heat exchanger topology data"
        parameter Integer Nw "Number of volumes on both sides";
        parameter Integer[Nw] correspondingVolumes "Indeces of corresponding volumes";
      end HeatExchangerTopologyData;
    end BaseClasses;
  end Thermal;

  package Electrical  "Simplified models of electric power components"
    extends Modelica.Icons.Package;

    connector PowerConnection  "Electrical power connector"
      flow .Modelica.SIunits.Power W "Active power";
      .Modelica.SIunits.Frequency f "Frequency";
    end PowerConnection;

    model Generator  "Active power generator"
      parameter .Modelica.SIunits.PerUnit eta = 1 "Conversion efficiency";
      parameter .Modelica.SIunits.MomentOfInertia J = 0 "Moment of inertia";
      parameter Integer Np = 2 "Number of electrical poles";
      parameter .Modelica.SIunits.Frequency fstart = 50 "Start value of the electrical frequency";
      parameter ThermoPower.Choices.Init.Options initOpt = system.initOpt "Initialization option";
      System system "System object";
      .Modelica.SIunits.Power Pm "Mechanical power";
      .Modelica.SIunits.Power Pe "Electrical Power";
      .Modelica.SIunits.Power Ploss "Inertial power Loss";
      .Modelica.SIunits.Torque tau "Torque at shaft";
      .Modelica.SIunits.AngularVelocity omega_m(start = 2 * Modelica.Constants.pi * fstart / Np) "Angular velocity of the shaft";
      .Modelica.SIunits.AngularVelocity omega_e "Angular velocity of the e.m.f. rotating frame";
      .Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm n "Rotational speed";
      .Modelica.SIunits.Frequency f "Electrical frequency";
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
      omega_m = der(shaft.phi) "Mechanical boundary condition";
      omega_e = omega_m * Np;
      f = omega_e / (2 * Modelica.Constants.pi) "Electrical frequency";
      n = Modelica.SIunits.Conversions.to_rpm(omega_m) "Rotational speed in rpm";
      Pm = omega_m * tau;
      if J > 0 then
        Ploss = J * der(omega_m) * omega_m;
      else
        Ploss = 0;
      end if;
      Pm = Pe / eta + Ploss "Energy balance";
      f = powerConnection.f;
      Pe = -powerConnection.W;
      tau = shaft.tau;
    end Generator;

    partial model Network1portBase  "Base class for one-port network"
      parameter Boolean hasBreaker = false "Model includes a breaker controlled by external input";
      parameter Modelica.SIunits.Angle deltaStart = 0 "Start value of the load angle";
      parameter ThermoPower.Choices.Init.Options initOpt = ThermoPower.Choices.Init.Options.noInit "Initialization option";
      parameter Modelica.SIunits.Power C "Max. power transfer";
      .Modelica.SIunits.Power Pe "Net electrical power";
      .Modelica.SIunits.Power Ploss "Electrical power loss";
      .Modelica.SIunits.AngularVelocity omega "Angular velocity";
      .Modelica.SIunits.AngularVelocity omegaRef "Angular velocity reference";
      .Modelica.SIunits.Angle delta(stateSelect = StateSelect.prefer, start = deltaStart) "Load angle";
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
      parameter .Modelica.SIunits.Power Pmax "Maximum power transfer";
      parameter .Modelica.SIunits.Frequency fnom = 50 "Nominal frequency of network";
      parameter .Modelica.SIunits.MomentOfInertia J = 0 "Moment of inertia of the generator/shaft system (for damping term calculation)";
      parameter .Modelica.SIunits.PerUnit r = 0.2 "Electrical damping of generator/shaft system" annotation(dialog(enable = if J > 0 then true else false, group = "Generator"));
      parameter Integer Np = 2 "Number of electrical poles" annotation(dialog(enable = if J > 0 then true else false, group = "Generator"));
      Real D "Electrical damping coefficient";
    equation
      omegaRef = 2 * Modelica.Constants.pi * fnom;
      if J > 0 then
        D = 2 * r * sqrt(C * J * (2 * Modelica.Constants.pi * fnom * Np) / Np ^ 2);
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

  package Icons  "Icons for ThermoPower library"
    extends Modelica.Icons.IconsPackage;

    package Water  "Icons for component using water/steam as working fluid"
      extends Modelica.Icons.Package;

      partial model Tube  end Tube;

      model Drum  end Drum;

      partial model Pump  end Pump;
    end Water;

    partial model HeatFlow  end HeatFlow;

    partial model MetalWall  end MetalWall;

    package Gas  "Icons for component using water/steam as working fluid"
      extends Modelica.Icons.Package;

      partial model SourceP  end SourceP;

      partial model SourceW  end SourceW;

      partial model Tube  end Tube;
    end Gas;
  end Icons;

  package Choices  "Choice enumerations for ThermoPower models"
    extends Modelica.Icons.TypesPackage;

    package Flow1D
      type FFtypes = enumeration(Kfnom "Kfnom friction factor", OpPoint "Friction factor defined by operating point", Cfnom "Cfnom friction factor", Colebrook "Colebrook's equation", NoFriction "No friction") "Type, constants and menu choices to select the friction factor";
      type HCtypes = enumeration(Middle "Middle of the pipe", Upstream "At the inlet", Downstream "At the outlet") "Type, constants and menu choices to select the location of the hydraulic capacitance";
    end Flow1D;

    package Init  "Options for initialisation"
      type Options = enumeration(noInit "No initial equations", fixedState "Fixed initial state variables", steadyState "Steady-state initialization", steadyStateNoP "Steady-state initialization except pressures (deprecated)", steadyStateNoT "Steady-state initialization except temperatures (deprecated)", steadyStateNoPT "Steady-state initialization except pressures and temperatures (deprecated)") "Type, constants and menu choices to select the initialisation options";
    end Init;

    package FluidPhase
      type FluidPhases = enumeration(Liquid "Liquid", Steam "Steam", TwoPhases "Two Phases") "Type, constants and menu choices to select the fluid phase";
    end FluidPhase;
  end Choices;

  package Functions  "Miscellaneous functions"
    extends Modelica.Icons.Package;

    function sqrtReg  "Symmetric square root approximation with finite derivative in zero"
      extends Modelica.Icons.Function;
      input Real x;
      input Real delta = 0.01 "Range of significant deviation from sqrt(x)";
      output Real y;
    algorithm
      y := x / sqrt(sqrt(x * x + delta * delta));
      annotation(derivative(zeroDerivative = delta) = ThermoPower.Functions.sqrtReg_der);
    end sqrtReg;

    function sqrtReg_der  "Derivative of sqrtReg"
      extends Modelica.Icons.Function;
      input Real x;
      input Real delta = 0.01 "Range of significant deviation from sqrt(x)";
      input Real dx "Derivative of x";
      output Real dy;
    algorithm
      dy := dx * 0.5 * (x * x + 2 * delta * delta) / (x * x + delta * delta) ^ 1.25;
    end sqrtReg_der;

    function squareReg  "Anti-symmetric square approximation with non-zero derivative in the origin"
      extends Modelica.Icons.Function;
      input Real x;
      input Real delta = 0.01 "Range of significant deviation from x^2*sgn(x)";
      output Real y;
    algorithm
      y := x * sqrt(x * x + delta * delta);
    end squareReg;

    function linspaceExt  "Extended linspace function handling also the N=1 case"
      input Real x1;
      input Real x2;
      input Integer N;
      output Real[N] vec;
    algorithm
      vec := if N == 1 then {x1} else linspace(x1, x2, N);
    end linspaceExt;

    package PumpCharacteristics  "Functions for pump characteristics"
      partial function baseFlow  "Base class for pump flow characteristics"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.VolumeFlowRate q_flow "Volumetric flow rate";
        output .Modelica.SIunits.Height head "Pump head";
      end baseFlow;

      partial function basePower  "Base class for pump power consumption characteristics"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.VolumeFlowRate q_flow "Volumetric flow rate";
        output .Modelica.SIunits.Power consumption "Power consumption at nominal density";
      end basePower;

      partial function baseEfficiency  "Base class for efficiency characteristics"
        extends Modelica.Icons.Function;
        input .Modelica.SIunits.VolumeFlowRate q_flow "Volumetric flow rate";
        output .Modelica.SIunits.PerUnit eta "Efficiency";
      end baseEfficiency;

      function quadraticFlow  "Quadratic flow characteristic"
        extends baseFlow;
        input .Modelica.SIunits.VolumeFlowRate[3] q_nom "Volume flow rate for three operating points (single pump)";
        input .Modelica.SIunits.Height[3] head_nom "Pump head for three operating points";
      protected
        parameter Real[3] q_nom2 = {q_nom[1] ^ 2, q_nom[2] ^ 2, q_nom[3] ^ 2} "Squared nominal flow rates";
        parameter Real[3] c = Modelica.Math.Matrices.solve([ones(3), q_nom, q_nom2], head_nom) "Coefficients of quadratic head curve";
      algorithm
        head := c[1] + q_flow * c[2] + q_flow ^ 2 * c[3];
      end quadraticFlow;

      function constantPower  "Constant power consumption characteristic"
        extends basePower;
        input .Modelica.SIunits.Power power = 0 "Constant power consumption";
      algorithm
        consumption := power;
      end constantPower;

      function constantEfficiency  "Constant efficiency characteristic"
        extends baseEfficiency;
        input .Modelica.SIunits.PerUnit eta_nom "Nominal efficiency";
      algorithm
        eta := eta_nom;
      end constantEfficiency;
    end PumpCharacteristics;
  end Functions;

  package Media  "Medium models for the ThermoPower library"
    extends Modelica.Icons.Package;

    package FlueGas  "flue gas"
      extends Modelica.Media.IdealGases.Common.MixtureGasNasa(mediumName = "FlueGas", data = {Modelica.Media.IdealGases.Common.SingleGasesData.O2, Modelica.Media.IdealGases.Common.SingleGasesData.Ar, Modelica.Media.IdealGases.Common.SingleGasesData.H2O, Modelica.Media.IdealGases.Common.SingleGasesData.CO2, Modelica.Media.IdealGases.Common.SingleGasesData.N2}, fluidConstants = {Modelica.Media.IdealGases.Common.FluidData.O2, Modelica.Media.IdealGases.Common.FluidData.Ar, Modelica.Media.IdealGases.Common.FluidData.H2O, Modelica.Media.IdealGases.Common.FluidData.CO2, Modelica.Media.IdealGases.Common.FluidData.N2}, substanceNames = {"Oxygen", "Argon", "Water", "Carbondioxide", "Nitrogen"}, reference_X = {0.23, 0.02, 0.01, 0.04, 0.7}, referenceChoice = Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt25C);
    end FlueGas;
  end Media;

  package Units  "Types with custom units"
    extends Modelica.Icons.Package;
    type HydraulicConductance = Real(final quantity = "HydraulicConductance", final unit = "(kg/s)/Pa");
    type HydraulicResistance = Real(final quantity = "HydraulicResistance", final unit = "Pa/(kg/s)");
    type LiquidDensity = .Modelica.SIunits.Density(start = 1000, nominal = 1000) "start value for liquids";
    type GasDensity = .Modelica.SIunits.Density(start = 5, nominal = 5) "start value for gases/vapours";
  end Units;
  annotation(version = "3.1");
end ThermoPower;
