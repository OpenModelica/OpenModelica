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

      partial block SignalSource
        extends SO;
        parameter Real offset = 0;
        parameter .Modelica.SIunits.Time startTime = 0;
      end SignalSource;
    end Interfaces;

    package Sources
      extends Modelica.Icons.SourcesPackage;

      block Step
        parameter Real height = 1;
        extends .Modelica.Blocks.Interfaces.SignalSource;
      equation
        y = offset + (if time < startTime then 0 else height);
      end Step;
    end Sources;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial block Block  end Block;
    end Icons;
  end Blocks;

  package Fluid
    extends Modelica.Icons.Package;

    package Utilities
      extends Modelica.Icons.UtilitiesPackage;

      function cubicHermite
        extends Modelica.Icons.Function;
        input Real x;
        input Real x1;
        input Real x2;
        input Real y1;
        input Real y2;
        input Real y1d;
        input Real y2d;
        output Real y;
      protected
        Real h;
        Real t;
        Real h00;
        Real h10;
        Real h01;
        Real h11;
        Real aux3;
        Real aux2;
      algorithm
        h := x2 - x1;
        if abs(h) > 0 then
          t := (x - x1) / h;
          aux3 := t ^ 3;
          aux2 := t ^ 2;
          h00 := 2 * aux3 - 3 * aux2 + 1;
          h10 := aux3 - 2 * aux2 + t;
          h01 := (-2 * aux3) + 3 * aux2;
          h11 := aux3 - aux2;
          y := y1 * h00 + h * y1d * h10 + y2 * h01 + h * y2d * h11;
        else
          y := (y1 + y2) / 2;
        end if;
      end cubicHermite;
    end Utilities;
  end Fluid;

  package Thermal
    extends Modelica.Icons.Package;

    package HeatTransfer
      extends Modelica.Icons.Package;

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

    function sin
      extends Modelica.Math.Icons.AxisLeft;
      input Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = sin(u);
    end sin;

    function cos
      extends Modelica.Math.Icons.AxisLeft;
      input .Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = cos(u);
    end cos;

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
  end Math;

  package Constants
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real small = ModelicaServices.Machine.small;
    final constant .Modelica.SIunits.Velocity c = 299792458;
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7;
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

    partial package UtilitiesPackage
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

    partial package IconsPackage
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package MaterialPropertiesPackage
      extends Modelica.Icons.Package;
    end MaterialPropertiesPackage;

    partial function Function  end Function;

    partial record Record  end Record;
  end Icons;

  package SIunits
    extends Modelica.Icons.Package;

    package Conversions
      extends Modelica.Icons.Package;

      package NonSIunits
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC");
      end NonSIunits;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Length = Real(final quantity = "Length", final unit = "m");
    type Area = Real(final quantity = "Area", final unit = "m2");
    type Time = Real(final quantity = "Time", final unit = "s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC");
    type Temperature = ThermodynamicTemperature;
    type TemperatureDifference = Real(final quantity = "ThermodynamicTemperature", final unit = "K");
    type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
    type HeatFlux = Real(final quantity = "HeatFlux", final unit = "W/m2");
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type CoefficientOfHeatTransfer = Real(final quantity = "CoefficientOfHeatTransfer", final unit = "W/(m2.K)");
    type ThermalResistance = Real(final quantity = "ThermalResistance", final unit = "K/W");
    type ThermalConductance = Real(final quantity = "ThermalConductance", final unit = "W/K");
    type HeatCapacity = Real(final quantity = "HeatCapacity", final unit = "J/K");
    type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
    type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
    type SpecificInternalEnergy = SpecificEnergy;
    type Emissivity = Real(final quantity = "Emissivity", final unit = "1");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
end Modelica;

package Buildings
  extends Modelica.Icons.Package;

  package HeatTransfer
    extends Modelica.Icons.Package;

    package Conduction
      extends Modelica.Icons.VariantsPackage;

      model SingleLayer
        extends Buildings.HeatTransfer.Conduction.BaseClasses.PartialConductor(final R = if material.R == 0 then material.x / material.k / A else material.R / A);
        Modelica.SIunits.Temperature[nSta] T(start = array(T_a_start + (T_b_start - T_a_start) * UA * sum(1 / (if k == 1 or k == nSta + 1 then UAnSta2 else UAnSta) for k in 1:i) for i in 1:nSta), each nominal = 300);
        Modelica.SIunits.HeatFlowRate[nSta + 1] Q_flow;
        Modelica.SIunits.SpecificInternalEnergy[nSta] u(start = material.c * array(T_a_start + (T_b_start - T_a_start) * UA * sum(1 / (if k == 1 or k == nSta + 1 then UAnSta2 else UAnSta) for k in 1:i) for i in 1:nSta), each nominal = 270000);
        replaceable parameter Data.BaseClasses.Material material annotation(choicesAllMatching = true);
        parameter Boolean steadyStateInitial = false annotation(Evaluate = true);
        parameter Modelica.SIunits.Temperature T_a_start = 293.15;
        parameter Modelica.SIunits.Temperature T_b_start = 293.15;
      protected
        final parameter Integer nSta(min = 1) = material.nSta;
        final parameter Modelica.SIunits.ThermalConductance UAnSta = UA * nSta;
        final parameter Modelica.SIunits.ThermalConductance UAnSta2 = 2 * UAnSta;
        parameter Modelica.SIunits.Mass m = A * material.x * material.d / material.nSta;
        parameter Modelica.SIunits.HeatCapacity C = m * material.c;
        parameter Modelica.SIunits.SpecificInternalEnergy[Buildings.HeatTransfer.Conduction.nSupPCM] ud(each fixed = false);
        parameter Modelica.SIunits.Temperature[Buildings.HeatTransfer.Conduction.nSupPCM] Td(each fixed = false);
        parameter Real[Buildings.HeatTransfer.Conduction.nSupPCM] dT_du(each fixed = false, each unit = "kg.K2/J");
      initial equation
        if not material.steadyState then
          if steadyStateInitial then
            if material.phasechange then
              der(u) = zeros(nSta);
            else
              der(T) = zeros(nSta);
            end if;
          else
            for i in 1:nSta loop
              T[i] = T_a_start + (T_b_start - T_a_start) * UA * sum(1 / (if k == 1 or k == nSta + 1 then UAnSta2 else UAnSta) for k in 1:i);
            end for;
          end if;
        end if;
        if material.phasechange then
          (ud, Td, dT_du) = BaseClasses.der_temperature_u(material = material);
        else
          ud = zeros(Buildings.HeatTransfer.Conduction.nSupPCM);
          Td = zeros(Buildings.HeatTransfer.Conduction.nSupPCM);
          dT_du = zeros(Buildings.HeatTransfer.Conduction.nSupPCM);
        end if;
      equation
        port_a.Q_flow = +Q_flow[1];
        port_b.Q_flow = -Q_flow[nSta + 1];
        port_a.T - T[1] = Q_flow[1] / UAnSta2;
        T[nSta] - port_b.T = Q_flow[nSta + 1] / UAnSta2;
        for i in 2:nSta loop
          T[i - 1] - T[i] = Q_flow[i] / UAnSta;
        end for;
        if material.steadyState then
          for i in 2:nSta + 1 loop
            Q_flow[i] = Q_flow[1];
            if material.phasechange then
              T[i - 1] = BaseClasses.temperature_u(ud = ud, Td = Td, dT_du = dT_du, u = u[i - 1]);
            else
              u[i - 1] = material.c * T[i - 1];
            end if;
          end for;
        else
          if material.phasechange then
            for i in 1:nSta loop
              der(u[i]) = (Q_flow[i] - Q_flow[i + 1]) / m;
              T[i] = BaseClasses.temperature_u(ud = ud, Td = Td, dT_du = dT_du, u = u[i]);
            end for;
          else
            for i in 1:nSta loop
              der(T[i]) = (Q_flow[i] - Q_flow[i + 1]) / C;
              u[i] = material.c * T[i];
            end for;
          end if;
        end if;
      end SingleLayer;

      model MultiLayer
        extends Buildings.HeatTransfer.Conduction.BaseClasses.PartialConductor(final R = sum(lay[i].R for i in 1:nLay));
        Modelica.SIunits.Temperature[sum(nSta)] T(each nominal = 300);
        Modelica.SIunits.HeatFlowRate[sum(nSta) + nLay] Q_flow;
        extends Buildings.HeatTransfer.Conduction.BaseClasses.PartialConstruction;
      protected
        Buildings.HeatTransfer.Conduction.SingleLayer[nLay] lay(each final A = A, material = layers.material, T_a_start = _T_a_start, T_b_start = _T_b_start, each steadyStateInitial = steadyStateInitial);
        parameter Modelica.SIunits.Temperature[nLay] _T_a_start = array(T_b_start + (T_a_start - T_b_start) * 1 / R * sum(lay[k].R for k in i:nLay) for i in 1:nLay);
        parameter Modelica.SIunits.Temperature[nLay] _T_b_start = array(T_a_start + (T_b_start - T_a_start) * 1 / R * sum(lay[k].R for k in 1:i) for i in 1:nLay);
      equation
        for i in 1:nLay loop
          for j in 1:nSta[i] loop
            T[sum(nSta[k] for k in 1:i - 1) + j] = lay[i].T[j];
          end for;
          for j in 1:nSta[i] + 1 loop
            Q_flow[sum(nSta[k] for k in 1:i - 1) + i - 1 + j] = lay[i].Q_flow[j];
          end for;
        end for;
        connect(port_a, lay[1].port_a);
        for i in 1:nLay - 1 loop
          connect(lay[i].port_b, lay[i + 1].port_a);
        end for;
        connect(lay[nLay].port_b, port_b);
      end MultiLayer;

      constant Integer nSupPCM = 6;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        partial model PartialConductor
          extends Buildings.BaseClasses.BaseIcon;
          parameter Modelica.SIunits.Area A;
          final parameter Modelica.SIunits.CoefficientOfHeatTransfer U = UA / A;
          final parameter Modelica.SIunits.ThermalConductance UA = 1 / R;
          parameter Modelica.SIunits.ThermalResistance R;
          Modelica.SIunits.TemperatureDifference dT;
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a;
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b;
        equation
          dT = port_a.T - port_b.T;
        end PartialConductor;

        model PartialConstruction
          extends Buildings.BaseClasses.BaseIcon;
          parameter Modelica.SIunits.Area A;
          replaceable parameter Buildings.HeatTransfer.Data.OpaqueConstructions.Generic layers annotation(choicesAllMatching = true);
          final parameter Integer nLay(min = 1, fixed = true) = layers.nLay;
          final parameter Integer[nLay] nSta(each min = 1) = array(layers.material[i].nSta for i in 1:nLay) annotation(Evaluate = true);
          parameter Boolean steadyStateInitial = false annotation(Evaluate = true);
          parameter Modelica.SIunits.Temperature T_a_start = 293.15;
          parameter Modelica.SIunits.Temperature T_b_start = 293.15;
        end PartialConstruction;

        function der_temperature_u
          input Buildings.HeatTransfer.Data.Solids.Generic material;
          output Modelica.SIunits.SpecificInternalEnergy[Buildings.HeatTransfer.Conduction.nSupPCM] ud;
          output Modelica.SIunits.Temperature[Buildings.HeatTransfer.Conduction.nSupPCM] Td;
          output Real[Buildings.HeatTransfer.Conduction.nSupPCM] dT_du(fixed = false, unit = "kg.K2/J");
        protected
          parameter Real scale = 0.999;
          parameter Modelica.SIunits.Temperature Tm1 = material.TSol + (1 - scale) * (material.TLiq - material.TSol);
          parameter Modelica.SIunits.Temperature Tm2 = material.TSol + scale * (material.TLiq - material.TSol);
        algorithm
          assert(Buildings.HeatTransfer.Conduction.nSupPCM == 6, "The material must have exactly 6 support points for the u(T) relation.");
          assert(material.TLiq > material.TSol, "TLiq has to be larger than TSol.");
          ud := {material.c * scale * material.TSol, material.c * material.TSol, material.c * Tm1 + material.LHea * (Tm1 - material.TSol) / (material.TLiq - material.TSol), material.c * Tm2 + material.LHea * (Tm2 - material.TSol) / (material.TLiq - material.TSol), material.c * material.TLiq + material.LHea, material.c * (material.TLiq + material.TSol * (1 - scale)) + material.LHea};
          Td := {scale * material.TSol, material.TSol, Tm1, Tm2, material.TLiq, material.TLiq + material.TSol * (1 - scale)};
          dT_du := Buildings.Utilities.Math.Functions.splineDerivatives(x = ud, y = Td, ensureMonotonicity = material.ensureMonotonicity);
        end der_temperature_u;

        function temperature_u
          input Modelica.SIunits.SpecificInternalEnergy[Buildings.HeatTransfer.Conduction.nSupPCM] ud;
          input Modelica.SIunits.Temperature[Buildings.HeatTransfer.Conduction.nSupPCM] Td;
          input Real[:] dT_du(each fixed = false, unit = "kg.K2/J");
          input Modelica.SIunits.SpecificInternalEnergy u;
          output Modelica.SIunits.Temperature T;
        protected
          Integer i;
        algorithm
          i := 1;
          for j in 1:size(ud, 1) - 1 loop
            if u > ud[j] then
              i := j;
            else
            end if;
          end for;
          T := Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = u, x1 = ud[i], x2 = ud[i + 1], y1 = Td[i], y2 = Td[i + 1], y1d = dT_du[i], y2d = dT_du[i + 1]);
        end temperature_u;
      end BaseClasses;
    end Conduction;

    package Convection
      extends Modelica.Icons.VariantsPackage;

      model Interior
        extends Buildings.HeatTransfer.Convection.BaseClasses.PartialConvection;
        parameter Buildings.HeatTransfer.Types.InteriorConvection conMod = Buildings.HeatTransfer.Types.InteriorConvection.Fixed annotation(Evaluate = true);
        parameter Boolean homotopyInitialization = true annotation(Evaluate = true);
      protected
        constant Modelica.SIunits.Temperature dT0 = 2;
      equation
        if conMod == Buildings.HeatTransfer.Types.InteriorConvection.Fixed then
          q_flow = hFixed * dT;
        else
          if homotopyInitialization then
            if isCeiling then
              q_flow = homotopy(actual = Functions.HeatFlux.ceiling(dT = dT), simplified = dT / dT0 * Functions.HeatFlux.ceiling(dT = dT0));
            elseif isFloor then
              q_flow = homotopy(actual = Functions.HeatFlux.floor(dT = dT), simplified = dT / dT0 * Functions.HeatFlux.floor(dT = dT0));
            else
              q_flow = homotopy(actual = Functions.HeatFlux.wall(dT = dT), simplified = dT / dT0 * Functions.HeatFlux.wall(dT = dT0));
            end if;
          else
            if isCeiling then
              q_flow = Functions.HeatFlux.ceiling(dT = dT);
            elseif isFloor then
              q_flow = Functions.HeatFlux.floor(dT = dT);
            else
              q_flow = Functions.HeatFlux.wall(dT = dT);
            end if;
          end if;
        end if;
      end Interior;

      package Functions
        package HeatFlux
          function wall
            extends Buildings.HeatTransfer.Convection.Functions.HeatFlux.BaseClasses.PartialHeatFlux;
          algorithm
            q_flow := noEvent(smooth(1, if dT > 0 then 1.3 * dT ^ 1.3333 else -1.3 * (-dT) ^ 1.3333));
          end wall;

          function floor
            extends Buildings.HeatTransfer.Convection.Functions.HeatFlux.BaseClasses.PartialHeatFlux;
          algorithm
            q_flow := noEvent(smooth(1, if dT > 0 then 1.51 * dT ^ 1.3333 else -0.76 * (-dT) ^ 1.3333));
          end floor;

          function ceiling
            extends Buildings.HeatTransfer.Convection.Functions.HeatFlux.BaseClasses.PartialHeatFlux;
          algorithm
            q_flow := noEvent(smooth(1, if dT > 0 then 0.76 * dT ^ 1.3333 else -1.51 * (-dT) ^ 1.3333));
          end ceiling;

          package BaseClasses
            extends Modelica.Icons.BasesPackage;

            partial function PartialHeatFlux
              input Modelica.SIunits.TemperatureDifference dT;
              output Modelica.SIunits.HeatFlux q_flow;
            end PartialHeatFlux;
          end BaseClasses;
        end HeatFlux;
      end Functions;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        partial model PartialConvection
          extends Buildings.BaseClasses.BaseIcon;
          parameter Modelica.SIunits.Area A;
          parameter Modelica.SIunits.CoefficientOfHeatTransfer hFixed = 3;
          Modelica.SIunits.HeatFlowRate Q_flow;
          Modelica.SIunits.HeatFlux q_flow;
          Modelica.SIunits.TemperatureDifference dT(start = 0);
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a solid;
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b fluid;
          parameter Modelica.SIunits.Angle til(displayUnit = "deg");
        protected
          final parameter Real cosTil = Modelica.Math.cos(til);
          final parameter Real sinTil = Modelica.Math.sin(til);
          final parameter Boolean isCeiling = abs(sinTil) < 10E-10 and cosTil > 0;
          final parameter Boolean isFloor = abs(sinTil) < 10E-10 and cosTil < 0;
        equation
          dT = solid.T - fluid.T;
          solid.Q_flow = Q_flow;
          fluid.Q_flow = -Q_flow;
          Q_flow = A * q_flow;
        end PartialConvection;
      end BaseClasses;
    end Convection;

    package Sources
      extends Modelica.Icons.SourcesPackage;

      model FixedTemperature
        parameter Modelica.SIunits.Temperature T;
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port;
      equation
        port.T = T;
      end FixedTemperature;

      model PrescribedTemperature
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port;
        Modelica.Blocks.Interfaces.RealInput T;
      equation
        port.T = T;
      end PrescribedTemperature;
    end Sources;

    package Data
      extends Modelica.Icons.MaterialPropertiesPackage;

      package Solids
        extends Modelica.Icons.MaterialPropertiesPackage;

        record Generic
          extends Buildings.HeatTransfer.Data.BaseClasses.Material(final R = x / k, final TSol = 293.15, final TLiq = 293.15, final LHea = 0, final phasechange = false);
        end Generic;

        record Concrete = Buildings.HeatTransfer.Data.Solids.Generic(k = 1.4, d = 2240, c = 840);
        record InsulationBoard = Buildings.HeatTransfer.Data.Solids.Generic(k = 0.03, d = 40, c = 1200);
      end Solids;

      package OpaqueConstructions
        extends Modelica.Icons.MaterialPropertiesPackage;

        record Generic
          parameter Integer nLay(min = 1, fixed = true);
          parameter Buildings.HeatTransfer.Data.BaseClasses.Material[nLay] material annotation(choicesAllMatching = true, Evaluate = false);
          final parameter Real R(unit = "m2.K/W") = sum(material[:].R);
          parameter Modelica.SIunits.Emissivity absIR_a = 0.9;
          parameter Modelica.SIunits.Emissivity absIR_b = 0.9;
          parameter Modelica.SIunits.Emissivity absSol_a = 0.5;
          parameter Modelica.SIunits.Emissivity absSol_b = 0.5;
          parameter Buildings.HeatTransfer.Types.SurfaceRoughness roughness_a = Buildings.HeatTransfer.Types.SurfaceRoughness.Medium;
        end Generic;

        record Insulation100Concrete200 = Buildings.HeatTransfer.Data.OpaqueConstructions.Generic(material = {Solids.InsulationBoard(x = 0.1), Solids.Concrete(x = 0.2)}, final nLay = 2);
      end OpaqueConstructions;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        record Material
          extends Modelica.Icons.Record;
          parameter Modelica.SIunits.Length x;
          parameter Modelica.SIunits.ThermalConductivity k;
          parameter Modelica.SIunits.SpecificHeatCapacity c;
          parameter Modelica.SIunits.Density d;
          parameter Real R(unit = "m2.K/W");
          parameter Integer nStaRef(min = 0) = 3;
          parameter Integer nSta(min = 1) = max(1, integer(ceil(nStaReal))) annotation(Evaluate = true);
          parameter Boolean steadyState = c == 0 or d == 0 annotation(Evaluate = true);
          parameter Real piRef = 331.4;
          parameter Real piMat = if steadyState then piRef else x * sqrt(c * d) / sqrt(k);
          parameter Real nStaReal(min = 0) = nStaRef * piMat / piRef;
          parameter Modelica.SIunits.Temperature TSol;
          parameter Modelica.SIunits.Temperature TLiq;
          parameter Modelica.SIunits.SpecificInternalEnergy LHea;
          constant Boolean ensureMonotonicity = false;
          constant Boolean phasechange = false;
        end Material;
      end BaseClasses;
    end Data;

    package Types
      type SurfaceRoughness = enumeration(VeryRough, Rough, Medium, MediumSmooth, Smooth, VerySmooth);
      type InteriorConvection = enumeration(Fixed, Temperature);

      package Tilt
        constant Modelica.SIunits.Angle Wall = Modelica.Constants.pi / 2;
      end Tilt;
    end Types;

    package Examples
      extends Modelica.Icons.ExamplesPackage;

      model ConductorMultiLayer
        extends Modelica.Icons.Example;
        Buildings.HeatTransfer.Sources.FixedTemperature TB(T = 293.15);
        Buildings.HeatTransfer.Sources.PrescribedTemperature TA;
        Modelica.Blocks.Sources.Step step(height = 10, offset = 293.15, startTime = 43200);
        Buildings.HeatTransfer.Conduction.MultiLayer con(steadyStateInitial = false, redeclare Buildings.HeatTransfer.Data.OpaqueConstructions.Insulation100Concrete200 layers, A = 0.1);
        Buildings.HeatTransfer.Convection.Interior conv(A = 0.1, til = Buildings.HeatTransfer.Types.Tilt.Wall);
      equation
        connect(step.y, TA.T);
        connect(con.port_b, TB.port);
        connect(conv.fluid, TA.port);
        connect(conv.solid, con.port_a);
      end ConductorMultiLayer;
    end Examples;
  end HeatTransfer;

  package Utilities
    extends Modelica.Icons.Package;

    package Math
      extends Modelica.Icons.Package;

      package Functions
        extends Modelica.Icons.VariantsPackage;

        function cubicHermiteLinearExtrapolation
          input Real x;
          input Real x1;
          input Real x2;
          input Real y1;
          input Real y2;
          input Real y1d;
          input Real y2d;
          output Real y;
        algorithm
          if x > x1 and x < x2 then
            y := Modelica.Fluid.Utilities.cubicHermite(x = x, x1 = x1, x2 = x2, y1 = y1, y2 = y2, y1d = y1d, y2d = y2d);
          elseif x <= x1 then
            y := y1 + (x - x1) * y1d;
          else
            y := y2 + (x - x2) * y2d;
          end if;
        end cubicHermiteLinearExtrapolation;

        function isMonotonic
          input Real[:] x;
          input Boolean strict = false;
          output Boolean monotonic;
        protected
          Integer n = size(x, 1);
        algorithm
          if n == 1 then
            monotonic := true;
          else
            monotonic := true;
            if strict then
              if x[1] >= x[n] then
                for i in 1:n - 1 loop
                  if not x[i] > x[i + 1] then
                    monotonic := false;
                  else
                  end if;
                end for;
              else
                for i in 1:n - 1 loop
                  if not x[i] < x[i + 1] then
                    monotonic := false;
                  else
                  end if;
                end for;
              end if;
            else
              if x[1] >= x[n] then
                for i in 1:n - 1 loop
                  if not x[i] >= x[i + 1] then
                    monotonic := false;
                  else
                  end if;
                end for;
              else
                for i in 1:n - 1 loop
                  if not x[i] <= x[i + 1] then
                    monotonic := false;
                  else
                  end if;
                end for;
              end if;
            end if;
          end if;
        end isMonotonic;

        function splineDerivatives
          input Real[:] x;
          input Real[size(x, 1)] y;
          input Boolean ensureMonotonicity = isMonotonic(y, strict = false);
          output Real[size(x, 1)] d;
        protected
          Integer n = size(x, 1);
          Real[n - 1] delta;
          Real alpha;
          Real beta;
          Real tau;
        algorithm
          if n > 1 then
            assert(x[1] < x[n], "x must be strictly increasing.
              Received x[1] = " + String(x[1]) + "
                       x[" + String(n) + "] = " + String(x[n]));
            assert(isMonotonic(x, strict = true), "x-values must be strictly monontone increasing or decreasing.");
            if ensureMonotonicity then
              assert(isMonotonic(y, strict = false), "If ensureMonotonicity=true, y-values must be monontone increasing or decreasing.");
            else
            end if;
          else
          end if;
          if n == 1 then
            d[1] := 0;
          elseif n == 2 then
            d[1] := (y[2] - y[1]) / (x[2] - x[1]);
            d[2] := d[1];
          else
            for i in 1:n - 1 loop
              delta[i] := (y[i + 1] - y[i]) / (x[i + 1] - x[i]);
            end for;
            d[1] := delta[1];
            d[n] := delta[n - 1];
            for i in 2:n - 1 loop
              d[i] := (delta[i - 1] + delta[i]) / 2;
            end for;
          end if;
          if n > 2 and ensureMonotonicity then
            for i in 1:n - 1 loop
              if abs(delta[i]) < Modelica.Constants.small then
                d[i] := 0;
                d[i + 1] := 0;
              else
                alpha := d[i] / delta[i];
                beta := d[i + 1] / delta[i];
                if alpha ^ 2 + beta ^ 2 > 9 then
                  tau := 3 / (alpha ^ 2 + beta ^ 2) ^ (1 / 2);
                  d[i] := delta[i] * alpha * tau;
                  d[i + 1] := delta[i] * beta * tau;
                else
                end if;
              end if;
            end for;
          else
          end if;
        end splineDerivatives;
      end Functions;
    end Math;
  end Utilities;

  package BaseClasses
    extends Modelica.Icons.BasesPackage;

    block BaseIcon  end BaseIcon;
  end BaseClasses;
end Buildings;

model ConductorMultiLayer
  extends Buildings.HeatTransfer.Examples.ConductorMultiLayer;
  annotation(experiment(StopTime = 86400), __Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/HeatTransfer/Examples/ConductorMultiLayer.mos"));
end ConductorMultiLayer;
