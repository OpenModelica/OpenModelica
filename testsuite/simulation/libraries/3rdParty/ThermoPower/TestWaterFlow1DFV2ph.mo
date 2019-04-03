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

    model SinkPressure  "Pressure sink for water/steam flows"
      extends Icons.Water.SourceP;
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
      parameter Medium.AbsolutePressure p0 = 1.01325e5 "Nominal pressure";
      parameter Units.HydraulicResistance R = 0 "Hydraulic resistance" annotation(Evaluate = true);
      parameter Boolean use_T = false "Use the temperature if true, otherwise use specific enthalpy";
      parameter Medium.Temperature T = 298.15 "Nominal temperature";
      parameter Medium.SpecificEnthalpy h = 1e5 "Nominal specific enthalpy";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
      parameter Boolean use_in_p0 = false "Use connector input for the pressure";
      parameter Boolean use_in_T = false "Use connector input for the temperature";
      parameter Boolean use_in_h = false "Use connector input for the specific enthalpy";
      outer ThermoPower.System system "System wide properties";
      Medium.AbsolutePressure p "Actual pressure";
      FlangeA flange(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      Modelica.Blocks.Interfaces.RealInput in_p0 if use_in_p0;
      Modelica.Blocks.Interfaces.RealInput in_T if use_in_T "Externally supplied temperature";
      Modelica.Blocks.Interfaces.RealInput in_h if use_in_h;
    protected
      Modelica.Blocks.Interfaces.RealInput in_p0_internal;
      Modelica.Blocks.Interfaces.RealInput in_T_internal;
      Modelica.Blocks.Interfaces.RealInput in_h_internal;
    equation
      if R > 0 then
        flange.p = p + flange.m_flow * R;
      else
        flange.p = p;
      end if;
      p = in_p0_internal;
      if not use_in_p0 then
        in_p0_internal = p0 "Pressure set by parameter";
      end if;
      if use_T then
        flange.h_outflow = Medium.specificEnthalpy_pT(p = flange.p, T = in_T_internal);
      else
        flange.h_outflow = in_h_internal "Enthalpy set by connector";
      end if;
      if not use_in_T then
        in_T_internal = T "Temperature set by parameter";
      end if;
      if not use_in_h then
        in_h_internal = h "Enthalpy set by parameter";
      end if;
      connect(in_p0, in_p0_internal);
      connect(in_T, in_T_internal);
      connect(in_h, in_h_internal);
      assert(not (use_in_T and use_in_h), "Either temperature or specific enthalpy input");
      assert(not (use_T and use_in_h), "use_in_h required use_T = false");
      assert(not (not use_T and use_in_T), "use_in_T required use_T = true");
    end SinkPressure;

    model SourceMassFlow  "Flowrate source for water/steam flows"
      extends Icons.Water.SourceW;
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
      parameter Medium.MassFlowRate w0 = 0 "Nominal mass flowrate";
      parameter Medium.AbsolutePressure p0 = 1e5 "Nominal pressure";
      parameter Units.HydraulicConductance G = 0 "Hydraulic conductance";
      parameter Boolean use_T = false "Use the temperature if true, otherwise use specific enthalpy";
      parameter Medium.Temperature T = 298.15 "Nominal temperature";
      parameter Medium.SpecificEnthalpy h = 1e5 "Nominal specific enthalpy";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
      parameter Boolean use_in_w0 = false "Use connector input for the mass flow";
      parameter Boolean use_in_T = false "Use connector input for the temperature";
      parameter Boolean use_in_h = false "Use connector input for the specific enthalpy";
      outer ThermoPower.System system "System wide properties";
      Medium.MassFlowRate w "Mass flow rate";
      FlangeB flange(redeclare package Medium = Medium);
      Modelica.Blocks.Interfaces.RealInput in_w0 if use_in_w0 "Externally supplied mass flow rate";
      Modelica.Blocks.Interfaces.RealInput in_T if use_in_T "Externally supplied temperature";
      Modelica.Blocks.Interfaces.RealInput in_h if use_in_h "Externally supplied specific enthalpy";
    protected
      Modelica.Blocks.Interfaces.RealInput in_w0_internal;
      Modelica.Blocks.Interfaces.RealInput in_T_internal;
      Modelica.Blocks.Interfaces.RealInput in_h_internal;
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
      if use_T then
        flange.h_outflow = Medium.specificEnthalpy_pT(p = flange.p, T = in_T_internal);
      else
        flange.h_outflow = in_h_internal "Enthalpy set by connector";
      end if;
      if not use_in_T then
        in_T_internal = T "Temperature set by parameter";
      end if;
      if not use_in_h then
        in_h_internal = h "Enthalpy set by parameter";
      end if;
      connect(in_w0, in_w0_internal);
      connect(in_h, in_h_internal);
      connect(in_T, in_T_internal);
      assert(not (use_in_T and use_in_h), "Either temperature or specific enthalpy input");
      assert(not (use_T and use_in_h), "use_in_h required use_T = false");
      assert(not (not use_T and use_in_T), "use_in_T required use_T = true");
    end SourceMassFlow;

    model Flow1DFV2ph  "1-dimensional fluid flow model for water/steam (finite volumes, 2-phase)"
      extends BaseClasses.Flow1DBase(redeclare replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialTwoPhaseMedium, FluidPhaseStart = Choices.FluidPhase.FluidPhases.TwoPhases);
      replaceable model HeatTransfer = Thermal.HeatTransferFV.IdealHeatTransfer constrainedby ThermoPower.Thermal.BaseClasses.DistributedHeatTransferFV;
      HeatTransfer heatTransfer(redeclare package Medium = Medium, final Nf = N, final Nw = Nw, final Nt = Nt, final L = L, final A = A, final Dhyd = Dhyd, final omega = omega, final wnom = wnom / Nt, final w = w * ones(N), final fluidState = fluidState) "Instantiated heat transfer model";
      ThermoPower.Thermal.DHTVolumes wall(final N = Nw);
      constant .Modelica.SIunits.Pressure pzero = 10 "Small deltap for calculations";
      constant Medium.AbsolutePressure pc = Medium.fluidConstants[1].criticalPressure;
      constant .Modelica.SIunits.SpecificEnthalpy hzero = 1e-3 "Small value for deltah";
      parameter .Modelica.SIunits.PerUnit wnm = 1e-3 "Maximum fraction of the nominal flow rate allowed as reverse flow";
      Medium.ThermodynamicState[N] fluidState "Thermodynamic state of the fluid at the nodes";
      Medium.SaturationProperties sat "Properties of saturated fluid";
      .Modelica.SIunits.Length omega_hyd "Wet perimeter (single tube)";
      .Modelica.SIunits.Pressure Dpfric "Pressure drop due to friction";
      .Modelica.SIunits.Pressure Dpstat "Pressure drop due to static head";
      Real[N - 1] Kf "Friction coefficient";
      Real[N - 1] Kfl "Linear friction coefficient";
      Real[N - 1] Cf "Fanning friction factor";
      Real dwdt "Dynamic momentum term";
      Medium.AbsolutePressure p(start = pstart) "Fluid pressure for property calculations";
      .Modelica.SIunits.Pressure[N - 1] dpf "Pressure drop due to friction between two nodes";
      Medium.MassFlowRate w(start = wnom / Nt) "Mass flowrate (single tube)";
      Medium.MassFlowRate[N - 1] wbar(each start = wnom / Nt) "Average mass flow rates (single tube)";
      .Modelica.SIunits.Power[N - 1] Q_single = heatTransfer.Qvol / Nt "Heat flows entering the volumes from the lateral boundary (single tube)";
      .Modelica.SIunits.Velocity[N] u "Fluid velocity";
      Medium.Temperature[N] T "Fluid temperature";
      Medium.Temperature Ts "Saturated water temperature";
      Medium.SpecificEnthalpy[N] h(start = hstart) "Fluid specific enthalpy";
      Medium.SpecificEnthalpy[N - 1] htilde(start = hstart[2:N]) "Enthalpy state variables";
      Medium.SpecificEnthalpy hl "Saturated liquid temperature";
      Medium.SpecificEnthalpy hv "Saturated vapour temperature";
      .Modelica.SIunits.PerUnit[N] x "Steam quality";
      Medium.Density[N] rho "Fluid density";
      Units.LiquidDensity rhol "Saturated liquid density";
      Units.GasDensity rhov "Saturated vapour density";
      .Modelica.SIunits.Mass M "Fluid mass";
    protected
      .Modelica.SIunits.DerEnthalpyByPressure dhldp "Derivative of saturated liquid enthalpy by pressure";
      .Modelica.SIunits.DerEnthalpyByPressure dhvdp "Derivative of saturated vapour enthalpy by pressure";
      Medium.Density[N - 1] rhobar "Fluid average density";
      .Modelica.SIunits.DerDensityByPressure[N] drdp "Derivative of density by pressure";
      .Modelica.SIunits.DerDensityByPressure[N - 1] drbdp "Derivative of average density by pressure";
      .Modelica.SIunits.DerDensityByPressure drldp "Derivative of saturated liquid density by pressure";
      .Modelica.SIunits.DerDensityByPressure drvdp "Derivative of saturated vapour density by pressure";
      .Modelica.SIunits.SpecificVolume[N - 1] vbar "Average specific volume";
      .Modelica.SIunits.DerDensityByEnthalpy[N] drdh "Derivative of density by enthalpy";
      .Modelica.SIunits.DerDensityByEnthalpy[N - 1] drbdh1 "Derivative of average density by left enthalpy";
      .Modelica.SIunits.DerDensityByEnthalpy[N - 1] drbdh2 "Derivative of average density by right enthalpy";
      Real AA;
      Real AA1;
      .Modelica.SIunits.MassFlowRate[N - 1] dMdt "Derivative of fluid mass in each volume";
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
      for j in 1:N - 1 loop
        if FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Kfnom then
          Kf[j] = Kfnom * Kfc / (N - 1);
          Cf[j] = 2 * Kf[j] * A ^ 3 / (omega_hyd * l);
        elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.OpPoint then
          Kf[j] = dpnom * rhonom / (wnom / Nt) ^ 2 / (N - 1) * Kfc;
          Cf[j] = 2 * Kf[j] * A ^ 3 / (omega_hyd * l);
        elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Cfnom then
          Kf[j] = Cfnom * omega_hyd * l / (2 * A ^ 3) * Kfc;
          Cf[j] = 2 * Kf[j] * A ^ 3 / (omega_hyd * l);
        elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.Colebrook then
          Cf[j] = if noEvent(htilde[j] < hl or htilde[j] > hv) then f_colebrook(w, Dhyd / A, e, Medium.dynamicViscosity(fluidState[j])) * Kfc else f_colebrook_2ph(w, Dhyd / A, e, Medium.dynamicViscosity(Medium.setBubbleState(sat, 1)), Medium.dynamicViscosity(Medium.setDewState(sat, 1)), x[j]) * Kfc;
          Kf[j] = Cf[j] * omega_hyd * l / (2 * A ^ 3);
        elseif FFtype == .ThermoPower.Choices.Flow1D.FFtypes.NoFriction then
          Cf[j] = 0;
          Kf[j] = 0;
        else
          assert(FFtype <> .ThermoPower.Choices.Flow1D.FFtypes.NoFriction, "Unsupported FFtype");
          Cf[j] = 0;
          Kf[j] = 0;
        end if;
        assert(Kf[j] >= 0, "Negative friction coefficient");
        Kfl[j] = wnom / Nt * wnf * Kf[j];
      end for;
      if DynamicMomentum then
        dwdt = der(w);
      else
        dwdt = 0;
      end if;
      sum(dMdt) = infl.m_flow / Nt + outfl.m_flow / Nt "Mass balance";
      sum(dpf) = Dpfric "Total pressure drop due to friction";
      Dpstat = if abs(dzdx) < 1e-6 then 0 else g * l * dzdx * sum(rhobar) "Pressure drop due to static head";
      L / A * dwdt + outfl.p - infl.p + Dpstat + Dpfric = 0 "Momentum balance";
      for j in 1:N - 1 loop
        A * l * rhobar[j] * der(htilde[j]) + wbar[j] * (h[j + 1] - h[j]) - A * l * der(p) = Q_single[j] "Energy balance";
        dMdt[j] = A * l * (drbdh1[j] * der(h[j]) + drbdh2[j] * der(h[j + 1]) + drbdp[j] * der(p)) "Mass balance for each volume";
        vbar[j] = 1 / rhobar[j] "Average specific volume";
        wbar[j] = homotopy(infl.m_flow / Nt - sum(dMdt[1:j - 1]) - dMdt[j] / 2, wnom / Nt);
        dpf[j] = if FFtype == .ThermoPower.Choices.Flow1D.FFtypes.NoFriction then 0 else homotopy(smooth(1, Kf[j] * squareReg(w, wnom / Nt * wnf)) * vbar[j], dpnom / (N - 1) / (wnom / Nt) * w);
        if avoidInletEnthalpyDerivative and j == 1 then
          rhobar[j] = rho[j + 1];
          drbdp[j] = drdp[j + 1];
          drbdh1[j] = 0;
          drbdh2[j] = drdh[j + 1];
        elseif noEvent(h[j] < hl and h[j + 1] < hl or h[j] > hv and h[j + 1] > hv or p >= pc - pzero or abs(h[j + 1] - h[j]) < hzero) then
          rhobar[j] = (rho[j] + rho[j + 1]) / 2;
          drbdp[j] = (drdp[j] + drdp[j + 1]) / 2;
          drbdh1[j] = drdh[j] / 2;
          drbdh2[j] = drdh[j + 1] / 2;
        elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] >= hl and h[j + 1] <= hv) then
          rhobar[j] = AA * log(rho[j] / rho[j + 1]) / (h[j + 1] - h[j]);
          drbdp[j] = (AA1 * log(rho[j] / rho[j + 1]) + AA * (1 / rho[j] * drdp[j] - 1 / rho[j + 1] * drdp[j + 1])) / (h[j + 1] - h[j]);
          drbdh1[j] = (rhobar[j] - rho[j]) / (h[j + 1] - h[j]);
          drbdh2[j] = (rho[j + 1] - rhobar[j]) / (h[j + 1] - h[j]);
        elseif noEvent(h[j] < hl and h[j + 1] >= hl and h[j + 1] <= hv) then
          rhobar[j] = ((rho[j] + rhol) * (hl - h[j]) / 2 + AA * log(rhol / rho[j + 1])) / (h[j + 1] - h[j]);
          drbdp[j] = ((drdp[j] + drldp) * (hl - h[j]) / 2 + (rho[j] + rhol) / 2 * dhldp + AA1 * log(rhol / rho[j + 1]) + AA * (1 / rhol * drldp - 1 / rho[j + 1] * drdp[j + 1])) / (h[j + 1] - h[j]);
          drbdh1[j] = (rhobar[j] - (rho[j] + rhol) / 2 + drdh[j] * (hl - h[j]) / 2) / (h[j + 1] - h[j]);
          drbdh2[j] = (rho[j + 1] - rhobar[j]) / (h[j + 1] - h[j]);
        elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] > hv) then
          rhobar[j] = (AA * log(rho[j] / rhov) + (rhov + rho[j + 1]) * (h[j + 1] - hv) / 2) / (h[j + 1] - h[j]);
          drbdp[j] = (AA1 * log(rho[j] / rhov) + AA * (1 / rho[j] * drdp[j] - 1 / rhov * drvdp) + (drvdp + drdp[j + 1]) * (h[j + 1] - hv) / 2 - (rhov + rho[j + 1]) / 2 * dhvdp) / (h[j + 1] - h[j]);
          drbdh1[j] = (rhobar[j] - rho[j]) / (h[j + 1] - h[j]);
          drbdh2[j] = ((rhov + rho[j + 1]) / 2 - rhobar[j] + drdh[j + 1] * (h[j + 1] - hv) / 2) / (h[j + 1] - h[j]);
        elseif noEvent(h[j] < hl and h[j + 1] > hv) then
          rhobar[j] = ((rho[j] + rhol) * (hl - h[j]) / 2 + AA * log(rhol / rhov) + (rhov + rho[j + 1]) * (h[j + 1] - hv) / 2) / (h[j + 1] - h[j]);
          drbdp[j] = ((drdp[j] + drldp) * (hl - h[j]) / 2 + (rho[j] + rhol) / 2 * dhldp + AA1 * log(rhol / rhov) + AA * (1 / rhol * drldp - 1 / rhov * drvdp) + (drvdp + drdp[j + 1]) * (h[j + 1] - hv) / 2 - (rhov + rho[j + 1]) / 2 * dhvdp) / (h[j + 1] - h[j]);
          drbdh1[j] = (rhobar[j] - (rho[j] + rhol) / 2 + drdh[j] * (hl - h[j]) / 2) / (h[j + 1] - h[j]);
          drbdh2[j] = ((rhov + rho[j + 1]) / 2 - rhobar[j] + drdh[j + 1] * (h[j + 1] - hv) / 2) / (h[j + 1] - h[j]);
        elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] < hl) then
          rhobar[j] = (AA * log(rho[j] / rhol) + (rhol + rho[j + 1]) * (h[j + 1] - hl) / 2) / (h[j + 1] - h[j]);
          drbdp[j] = (AA1 * log(rho[j] / rhol) + AA * (1 / rho[j] * drdp[j] - 1 / rhol * drldp) + (drldp + drdp[j + 1]) * (h[j + 1] - hl) / 2 - (rhol + rho[j + 1]) / 2 * dhldp) / (h[j + 1] - h[j]);
          drbdh1[j] = (rhobar[j] - rho[j]) / (h[j + 1] - h[j]);
          drbdh2[j] = ((rhol + rho[j + 1]) / 2 - rhobar[j] + drdh[j + 1] * (h[j + 1] - hl) / 2) / (h[j + 1] - h[j]);
        elseif noEvent(h[j] > hv and h[j + 1] < hl) then
          rhobar[j] = ((rho[j] + rhov) * (hv - h[j]) / 2 + AA * log(rhov / rhol) + (rhol + rho[j + 1]) * (h[j + 1] - hl) / 2) / (h[j + 1] - h[j]);
          drbdp[j] = ((drdp[j] + drvdp) * (hv - h[j]) / 2 + (rho[j] + rhov) / 2 * dhvdp + AA1 * log(rhov / rhol) + AA * (1 / rhov * drvdp - 1 / rhol * drldp) + (drldp + drdp[j + 1]) * (h[j + 1] - hl) / 2 - (rhol + rho[j + 1]) / 2 * dhldp) / (h[j + 1] - h[j]);
          drbdh1[j] = (rhobar[j] - (rho[j] + rhov) / 2 + drdh[j] * (hv - h[j]) / 2) / (h[j + 1] - h[j]);
          drbdh2[j] = ((rhol + rho[j + 1]) / 2 - rhobar[j] + drdh[j + 1] * (h[j + 1] - hl) / 2) / (h[j + 1] - h[j]);
        else
          rhobar[j] = ((rho[j] + rhov) * (hv - h[j]) / 2 + AA * log(rhov / rho[j + 1])) / (h[j + 1] - h[j]);
          drbdp[j] = ((drdp[j] + drvdp) * (hv - h[j]) / 2 + (rho[j] + rhov) / 2 * dhvdp + AA1 * log(rhov / rho[j + 1]) + AA * (1 / rhov * drvdp - 1 / rho[j + 1] * drdp[j + 1])) / (h[j + 1] - h[j]);
          drbdh1[j] = (rhobar[j] - (rho[j] + rhov) / 2 + drdh[j] * (hv - h[j]) / 2) / (h[j + 1] - h[j]);
          drbdh2[j] = (rho[j + 1] - rhobar[j]) / (h[j + 1] - h[j]);
        end if;
      end for;
      sat = Medium.setSat_p(p);
      Ts = sat.Tsat;
      rhol = Medium.bubbleDensity(sat);
      rhov = Medium.dewDensity(sat);
      hl = Medium.bubbleEnthalpy(sat);
      hv = Medium.dewEnthalpy(sat);
      drldp = Medium.dBubbleDensity_dPressure(sat);
      drvdp = Medium.dDewDensity_dPressure(sat);
      dhldp = Medium.dBubbleEnthalpy_dPressure(sat);
      dhvdp = Medium.dDewEnthalpy_dPressure(sat);
      AA = (hv - hl) / (1 / rhov - 1 / rhol);
      AA1 = ((dhvdp - dhldp) * (rhol - rhov) * rhol * rhov - (hv - hl) * (rhov ^ 2 * drldp - rhol ^ 2 * drvdp)) / (rhol - rhov) ^ 2;
      for j in 1:N loop
        fluidState[j] = Medium.setState_ph(p, h[j]);
        T[j] = Medium.temperature(fluidState[j]);
        rho[j] = Medium.density(fluidState[j]);
        drdp[j] = Medium.density_derp_h(fluidState[j]);
        drdh[j] = Medium.density_derh_p(fluidState[j]);
        u[j] = w / (rho[j] * A);
        x[j] = noEvent(if h[j] <= hl then 0 else if h[j] >= hv then 1 else (h[j] - hl) / (hv - hl));
      end for;
      if HydraulicCapacitance == .ThermoPower.Choices.Flow1D.HCtypes.Upstream then
        p = infl.p;
        w = -outfl.m_flow / Nt;
      else
        p = outfl.p;
        w = infl.m_flow / Nt;
      end if;
      infl.h_outflow = htilde[1];
      outfl.h_outflow = htilde[N - 1];
      h[1] = inStream(infl.h_outflow);
      h[2:N] = htilde;
      connect(wall, heatTransfer.wall);
      Q = heatTransfer.Q "Total heat flow through lateral boundary";
      M = sum(rhobar) * A * l "Fluid mass (single tube)";
      Tr = noEvent(M / max(infl.m_flow / Nt, Modelica.Constants.eps)) "Residence time";
      assert(infl.m_flow > (-wnom * wnm), "Reverse flow not allowed, maybe you connected the component with wrong orientation");
    end Flow1DFV2ph;

    model ValveLin  "Valve for water/steam flows with linear pressure drop"
      extends Icons.Water.Valve;
      replaceable package Medium = StandardWater constrainedby Modelica.Media.Interfaces.PartialMedium;
      parameter Units.HydraulicConductance Kv "Nominal hydraulic conductance";
      parameter Boolean allowFlowReversal = system.allowFlowReversal "= true to allow flow reversal, false restricts to design direction" annotation(Evaluate = true);
      outer ThermoPower.System system "System wide properties";
      Medium.MassFlowRate w "Mass flowrate";
      FlangeA inlet(redeclare package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0));
      FlangeB outlet(redeclare package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0));
      Modelica.Blocks.Interfaces.RealInput cmd;
    equation
      inlet.m_flow + outlet.m_flow = 0 "Mass balance";
      w = Kv * cmd * (inlet.p - outlet.p) "Valve characteristics";
      w = inlet.m_flow;
      inlet.h_outflow = inStream(outlet.h_outflow);
      inStream(inlet.h_outflow) = outlet.h_outflow;
    end ValveLin;

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

    function f_colebrook_2ph  "Fanning friction factor for a two phase water/steam flow"
      input .Modelica.SIunits.MassFlowRate w;
      input Real D_A;
      input Real e;
      input .Modelica.SIunits.DynamicViscosity mul;
      input .Modelica.SIunits.DynamicViscosity muv;
      input .Modelica.SIunits.PerUnit x;
      output .Modelica.SIunits.PerUnit f;
    protected
      .Modelica.SIunits.PerUnit Re;
      .Modelica.SIunits.DynamicViscosity mu;
    algorithm
      mu := 1 / (x / muv + (1 - x) / mul);
      Re := w * D_A / mu;
      Re := if Re > 2100 then Re else 2100;
      f := 0.332 / log(e / 3.7 + 5.47 / Re ^ 0.9) ^ 2;
    end f_colebrook_2ph;

    function f_dittus_boelter  "Dittus-Boelter correlation for one-phase flow in a tube"
      input .Modelica.SIunits.MassFlowRate w;
      input .Modelica.SIunits.Length D;
      input .Modelica.SIunits.Area A;
      input .Modelica.SIunits.DynamicViscosity mu;
      input .Modelica.SIunits.ThermalConductivity k;
      input .Modelica.SIunits.SpecificHeatCapacity cp;
      output .Modelica.SIunits.CoefficientOfHeatTransfer hTC;
    protected
      .Modelica.SIunits.PerUnit Re;
      .Modelica.SIunits.PerUnit Pr;
    algorithm
      Re := abs(w) * D / A / mu;
      Pr := cp * mu / k;
      hTC := 0.023 * k / D * Re ^ 0.8 * Pr ^ 0.4;
    end f_dittus_boelter;

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
    end BaseClasses;
  end Water;

  package Thermal  "Thermal models of heat transfer"
    extends Modelica.Icons.Package;

    connector DHTVolumes  "Distributed Heat Terminal"
      parameter Integer N "Number of volumes";
      .Modelica.SIunits.Temperature[N] T "Temperature at the volumes";
      flow .Modelica.SIunits.Power[N] Q "Heat flow at the volumes";
    end DHTVolumes;

    model TempSource1DlinFV  "Linearly Distributed Temperature Source for Finite Volume models"
      extends Icons.HeatFlow;
      parameter Integer Nw = 1 "Number of volumes on the wall port";
      Thermal.DHTVolumes wall(final N = Nw);
      Modelica.Blocks.Interfaces.RealInput temperature_1;
      Modelica.Blocks.Interfaces.RealInput temperature_Nw;
    equation
      wall.T = Functions.linspaceExt(temperature_1, temperature_Nw, Nw);
    end TempSource1DlinFV;

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

    package HeatTransferFV  "Heat transfer models for FV components"
      model IdealHeatTransfer  "Delta T across the boundary layer is zero (infinite h.t.c.)"
        extends BaseClasses.DistributedHeatTransferFV(final useAverageTemperature = false);
      equation
        assert(Nw == Nf - 1, "Number of volumes Nw on wall side should be equal to number of volumes fluid side Nf - 1");
        for j in 1:Nw loop
          wall.T[j] = T[j + 1] "Ideal infinite heat transfer";
        end for;
      end IdealHeatTransfer;

      model HeatTransfer2phDB  "Dittus-Boelter 1-phase, constant h.t.c. 2-phase"
        extends BaseClasses.DistributedHeatTransferFV(final useAverageTemperature, redeclare replaceable package Medium = Modelica.Media.Interfaces.PartialTwoPhaseMedium);
        parameter .Modelica.SIunits.CoefficientOfHeatTransfer gamma_b = 20000 "Coefficient of heat transfer in the 2-phase region";
        Real[Nw] state "Indicator of phase configuration";
        .Modelica.SIunits.PerUnit[Nw] alpha_l(each unit = "1") "Normalized position of liquid phase boundary";
        .Modelica.SIunits.PerUnit[Nw] alpha_v(each unit = "1") "Normalized position of vapour phase boundary";
        .Modelica.SIunits.CoefficientOfHeatTransfer[Nf] gamma1ph "Heat transfer coefficient for 1-phase fluid";
        .Modelica.SIunits.CoefficientOfHeatTransfer gamma_bubble "Heat transfer coefficient for 1-phase fluid at liquid phase boundary";
        .Modelica.SIunits.CoefficientOfHeatTransfer gamma_dew "Heat transfer coefficient for 1-phase fluid at vapour phase boundary";
        .Modelica.SIunits.CoefficientOfHeatTransfer gamma2ph = gamma_b "Heat transfer coefficient for 2-phase mixture";
        Medium.SpecificEnthalpy[Nf] h "Fluid specific enthalpy";
        Medium.SpecificEnthalpy hl "Saturated liquid enthalpy";
        Medium.SpecificEnthalpy hv "Saturated vapour enthalpy";
        Medium.Temperature[Nw] Tvol "Fluid average temperature in the volumes";
        Medium.Temperature Ts "Saturated water temperature";
        Medium.SaturationProperties sat "Properties of saturated fluid";
        Medium.ThermodynamicState bubble "Bubble point, one-phase side";
        Medium.ThermodynamicState dew "Dew point, one-phase side";
        Medium.AbsolutePressure p "Fluid pressure for property calculations";
        Medium.DynamicViscosity[Nf] mu "Dynamic viscosity";
        Medium.ThermalConductivity[Nf] k "Thermal conductivity";
        Medium.SpecificHeatCapacity[Nf] cp "Heat capacity at constant pressure";
        Medium.DynamicViscosity mu_bubble "Dynamic viscosity at bubble point";
        Medium.ThermalConductivity k_bubble "Thermal conductivity at bubble point";
        Medium.SpecificHeatCapacity cp_bubble "Heat capacity at constant pressure at bubble point";
        Medium.DynamicViscosity mu_dew "Dynamic viscosity at dew point";
        Medium.ThermalConductivity k_dew "Thermal conductivity at dew point";
        Medium.SpecificHeatCapacity cp_dew "Heat capacity at constant pressure at dew point";
        .Modelica.SIunits.Power Q "Total heat flow through lateral boundary";
      equation
        assert(Nw == Nf - 1, "The number of volumes Nw on wall side should be equal to number of volumes fluid side Nf - 1");
        p = Medium.pressure(fluidState[1]);
        sat = Medium.setSat_p(p);
        Ts = sat.Tsat;
        hl = Medium.bubbleEnthalpy(sat);
        hv = Medium.dewEnthalpy(sat);
        bubble = Medium.setBubbleState(sat, 1);
        dew = Medium.setDewState(sat, 1);
        mu_bubble = Medium.dynamicViscosity(bubble);
        k_bubble = Medium.thermalConductivity(bubble);
        cp_bubble = Medium.heatCapacity_cp(bubble);
        mu_dew = Medium.dynamicViscosity(dew);
        k_dew = Medium.thermalConductivity(dew);
        cp_dew = Medium.heatCapacity_cp(dew);
        gamma_bubble = Water.f_dittus_boelter(w[1], Dhyd, A, mu_bubble, k_bubble, cp_bubble);
        gamma_dew = Water.f_dittus_boelter(w[1], Dhyd, A, mu_dew, k_dew, cp_dew);
        for j in 1:Nf loop
          h[j] = Medium.specificEnthalpy(fluidState[j]);
          mu[j] = Medium.dynamicViscosity(fluidState[j]);
          k[j] = Medium.thermalConductivity(fluidState[j]);
          cp[j] = Medium.heatCapacity_cp(fluidState[j]);
          gamma1ph[j] = Water.f_dittus_boelter(w[j], Dhyd, A, mu[j], k[j], cp[j]);
        end for;
        for j in 1:Nw loop
          if noEvent(h[j] < hl and h[j + 1] < hl or h[j] > hv and h[j + 1] > hv) then
            Qw[j] = (Tw[j] - Tvol[j]) * omega * l * Nt * ((gamma1ph[j] + gamma1ph[j + 1]) / 2);
            state[j] = 1;
            alpha_l[j] = 0;
            alpha_v[j] = 0;
          elseif noEvent(h[j] < hl and h[j + 1] >= hl and h[j + 1] <= hv) then
            Qw[j] = alpha_l[j] * (Tw[j] - (T[j] + Ts) / 2) * omega * l * Nt * ((gamma1ph[j] + gamma_bubble) / 2) + (1 - alpha_l[j]) * (Tw[j] - Ts) * omega * l * Nt * gamma2ph;
            state[j] = 2;
            alpha_l[j] = (hl - h[j]) / (h[j + 1] - h[j]);
            alpha_v[j] = 0;
          elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] >= hl and h[j + 1] <= hv) then
            Qw[j] = (Tw[j] - Ts) * omega * l * Nt * gamma2ph;
            state[j] = 3;
            alpha_l[j] = 0;
            alpha_v[j] = 0;
          elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] > hv) then
            Qw[j] = alpha_v[j] * (Tw[j] - (T[j + 1] + Ts) / 2) * omega * l * Nt * (gamma_dew + gamma1ph[j + 1]) / 2 + (1 - alpha_v[j]) * (Tw[j] - Ts) * omega * l * Nt * gamma2ph;
            state[j] = 4;
            alpha_l[j] = 0;
            alpha_v[j] = (h[j + 1] - hv) / (h[j + 1] - h[j]);
          elseif noEvent(h[j] >= hl and h[j] <= hv and h[j + 1] < hl) then
            Qw[j] = alpha_l[j] * (Tw[j] - (T[j + 1] + Ts) / 2) * omega * l * Nt * (gamma_bubble + gamma1ph[j + 1]) / 2 + (1 - alpha_l[j]) * (Tw[j] - Ts) * omega * l * Nt * gamma2ph;
            state[j] = 5;
            alpha_l[j] = (hl - h[j + 1]) / (h[j] - h[j + 1]);
            alpha_v[j] = 0;
          else
            Qw[j] = alpha_v[j] * (Tw[j] - (T[j] + Ts) / 2) * omega * l * Nt * (gamma1ph[j] + gamma_dew) / 2 + (1 - alpha_v[j]) * (Tw[j] - Ts) * omega * l * Nt * gamma2ph;
            state[j] = 6;
            alpha_l[j] = 0;
            alpha_v[j] = (h[j] - hv) / (h[j] - h[j + 1]);
          end if;
          if useAverageTemperature then
            Tvol[j] = (T[j] + T[j + 1]) / 2;
          else
            Tvol[j] = T[j + 1];
          end if;
        end for;
      end HeatTransfer2phDB;
    end HeatTransferFV;

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
    end BaseClasses;
  end Thermal;

  package Icons  "Icons for ThermoPower library"
    extends Modelica.Icons.IconsPackage;

    package Water  "Icons for component using water/steam as working fluid"
      extends Modelica.Icons.Package;

      partial model SourceP  end SourceP;

      partial model SourceW  end SourceW;

      partial model Tube  end Tube;

      partial model Valve  end Valve;
    end Water;

    partial model HeatFlow  end HeatFlow;

    partial model MetalWall  end MetalWall;
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
  end Functions;

  package Units  "Types with custom units"
    extends Modelica.Icons.Package;
    type HydraulicConductance = Real(final quantity = "HydraulicConductance", final unit = "(kg/s)/Pa");
    type HydraulicResistance = Real(final quantity = "HydraulicResistance", final unit = "Pa/(kg/s)");
    type LiquidDensity = .Modelica.SIunits.Density(start = 1000, nominal = 1000) "start value for liquids";
    type GasDensity = .Modelica.SIunits.Density(start = 5, nominal = 5) "start value for gases/vapours";
  end Units;

  package Test  "Test cases for the ThermoPower models"
    extends Modelica.Icons.ExamplesPackage;

    package DistributedParameterComponents  "Tests for thermo-hydraulic distributed parameter components"
      extends Modelica.Icons.ExamplesPackage;

      model TestWaterFlow1DFV2ph
        extends Modelica.Icons.Example;
        package Medium = Modelica.Media.Water.WaterIF97_ph;
        constant Real pi = Modelica.Constants.pi;
        parameter Integer Nnodes = 15;
        parameter .Modelica.SIunits.Length Lhex = 20;
        parameter .Modelica.SIunits.Diameter Dhex = 0.01;
        parameter .Modelica.SIunits.Thickness thhex = 0.002;
        parameter .Modelica.SIunits.Radius rhex = Dhex / 2;
        parameter .Modelica.SIunits.Length omegahex = pi * Dhex;
        parameter .Modelica.SIunits.Area Ahex = pi * rhex ^ 2;
        parameter .Modelica.SIunits.PerUnit Cfhex = 0.005;
        Water.ValveLin valve(Kv = 0.05 / 60e5);
        Water.SinkPressure Sink(p0 = 10000);
        Modelica.Blocks.Sources.Step hIn(height = 0, startTime = 30, offset = 1e6);
        Water.SourceMassFlow Source(w0 = 0.05, G = 0.05 / 600e5, use_in_h = true, p0 = 6000000);
        Modelica.Blocks.Sources.Ramp xValve(height = 0, offset = 1, duration = 1);
        inner System system;
        Water.Flow1DFV2ph hexFV(N = Nnodes, L = Lhex, omega = omegahex, A = Ahex, Cfnom = 0.005, DynamicMomentum = false, hstartin = 1e6, hstartout = 1e6, Dhyd = 2 * rhex, wnom = 0.05, redeclare package Medium = Medium, FFtype = ThermoPower.Choices.Flow1D.FFtypes.Cfnom, initOpt = ThermoPower.Choices.Init.Options.steadyState, redeclare model HeatTransfer = ThermoPower.Thermal.HeatTransferFV.HeatTransfer2phDB(gamma_b = 30000), dpnom = 1000);
        Thermal.MetalTubeFV metalTubeFV(L = Lhex, rint = rhex, rhomcm = 7000 * 680, lambda = 20, rext = rhex + 2 * thhex, initOpt = ThermoPower.Choices.Init.Options.steadyState, Nw = Nnodes - 1, Tstart1 = 510, TstartN = 510);
        Thermal.TempSource1DlinFV tempSource1DlinFV(Nw = Nnodes - 1);
        Modelica.Blocks.Sources.Ramp extTemp1(duration = 100, height = 50, offset = 540, startTime = 100);
        Modelica.Blocks.Sources.Ramp extTemp2(duration = 100, height = -50, startTime = 500);
        Modelica.Blocks.Math.Add Add1;
        Modelica.Blocks.Math.Add Add2;
        Modelica.Blocks.Sources.Constant DT(k = 5);
      equation
        connect(valve.outlet, Sink.flange);
        connect(hIn.y, Source.in_h);
        connect(xValve.y, valve.cmd);
        connect(hexFV.infl, Source.flange);
        connect(hexFV.outfl, valve.inlet);
        connect(Add2.u2, DT.y);
        connect(Add2.u1, Add1.y);
        connect(extTemp1.y, Add1.u2);
        connect(extTemp2.y, Add1.u1);
        connect(tempSource1DlinFV.temperature_1, Add1.y);
        connect(tempSource1DlinFV.temperature_Nw, Add2.y);
        connect(tempSource1DlinFV.wall, metalTubeFV.int);
        connect(metalTubeFV.ext, hexFV.wall);
        annotation(experiment(StopTime = 1000, __Dymola_NumberOfIntervals = 5000, Tolerance = 1e-008));
      end TestWaterFlow1DFV2ph;
    end DistributedParameterComponents;
  end Test;
  annotation(version = "3.1");
end ThermoPower;
