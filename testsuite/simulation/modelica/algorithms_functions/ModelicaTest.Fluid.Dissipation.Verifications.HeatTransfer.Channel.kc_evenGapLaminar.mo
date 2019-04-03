package ModelicaTest
  extends Modelica.Icons.Package;

  package Fluid
    extends Modelica.Icons.ExamplesPackage;

    package Dissipation
      extends Modelica.Icons.ExamplesPackage;

      package Verifications
        extends Modelica.Icons.ExamplesPackage;

        package HeatTransfer
          extends Modelica.Icons.ExamplesPackage;

          package Channel
            extends Modelica.Icons.ExamplesPackage;

            model kc_evenGapLaminar
              extends Modelica.Icons.Example;
              parameter Integer n = size(cp, 1);
              parameter Modelica.SIunits.Diameter d_hyd = 2 * s;
              Real[n] abscissa = array((length / d_hyd / (max(Re[i], 0.001) * Pr[i])) ^ 0.5 for i in 1:n);
              Modelica.SIunits.Length length = L;
              Modelica.SIunits.Length dimlesslength(start = 0.01);
              Modelica.SIunits.PrandtlNumber[n] Pr = array(eta[i] * cp[i] / lambda[i] for i in 1:n);
              Modelica.SIunits.ReynoldsNumber[n] Re = array(rho[i] * velocity[i] * d_hyd / eta[i] for i in 1:n);
              Modelica.SIunits.Velocity[n] velocity = array(m_flow[i] / (rho[i] * h * s) for i in 1:n);
              parameter Modelica.SIunits.Length h = 0.1;
              parameter Modelica.SIunits.Length s = 0.05;
              parameter Modelica.SIunits.Length L = 1;
              parameter Modelica.SIunits.SpecificHeatCapacityAtConstantPressure[:] cp = {1007, 4189, 3384.55};
              parameter Modelica.SIunits.DynamicViscosity[:] eta = {0.00001824, 0.0010016, 0.114};
              parameter Modelica.SIunits.ThermalConductivity[:] lambda = {0.02569, 0.5985, 0.387};
              parameter Modelica.SIunits.Density[:] rho = {1.188, 998.21, 1037.799};
              Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_con[n] m_flow_IN_con_1(each h = h, each s = s, each L = L, each final target = Modelica.Fluid.Dissipation.Utilities.Types.kc_evenGap.DevOne);
              Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_var[n] m_flow_IN_var_1(m_flow = m_flow, cp = cp, eta = eta, lambda = lambda, rho = rho);
              Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_con[n] m_flow_IN_con_2(each h = h, each s = s, each L = L, each final target = Modelica.Fluid.Dissipation.Utilities.Types.kc_evenGap.DevBoth);
              Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_var[n] m_flow_IN_var_2(m_flow = m_flow, cp = cp, eta = eta, lambda = lambda, rho = rho);
              Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_con[n] m_flow_IN_con_3(each h = h, each s = s, each L = L, each final target = Modelica.Fluid.Dissipation.Utilities.Types.kc_evenGap.UndevOne);
              Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_var[n] m_flow_IN_var_3(m_flow = m_flow, cp = cp, eta = eta, lambda = lambda, rho = rho);
              Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_con[n] m_flow_IN_con_4(each h = h, each s = s, each L = L, each final target = Modelica.Fluid.Dissipation.Utilities.Types.kc_evenGap.UndevBoth);
              Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_var[n] m_flow_IN_var_4(m_flow = m_flow, cp = cp, eta = eta, lambda = lambda, rho = rho);
              Modelica.SIunits.NusseltNumber[n] Nu_1;
              Modelica.SIunits.NusseltNumber[n] Nu_2;
              Modelica.SIunits.NusseltNumber[n] Nu_3;
              Modelica.SIunits.NusseltNumber[n] Nu_4;
            protected
              Modelica.SIunits.MassFlowRate[n] m_flow = array(0.5 * h * lambda[i] * length / (cp[i] * d_hyd * dimlesslength ^ 2) for i in 1:n);
            equation
              der(dimlesslength) = 1 - 0.01;
              for i in 1:n loop
                (, , , Nu_1[i], ) = Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar(m_flow_IN_con_1[i], m_flow_IN_var_1[i]);
              end for;
              for i in 1:n loop
                (, , , Nu_2[i], ) = Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar(m_flow_IN_con_2[i], m_flow_IN_var_2[i]);
              end for;
              for i in 1:n loop
                (, , , Nu_3[i], ) = Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar(m_flow_IN_con_3[i], m_flow_IN_var_3[i]);
              end for;
              for i in 1:n loop
                (, , , Nu_4[i], ) = Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar(m_flow_IN_con_4[i], m_flow_IN_var_4[i]);
              end for;
            end kc_evenGapLaminar;
          end Channel;
        end HeatTransfer;
      end Verifications;
    end Dissipation;
  end Fluid;
end ModelicaTest;

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

  package Fluid
    extends Modelica.Icons.Package;

    package Dissipation
      extends Modelica.Icons.BasesPackage;

      package HeatTransfer
        extends Modelica.Icons.VariantsPackage;

        package Channel
          extends Modelica.Icons.VariantsPackage;

          function kc_evenGapLaminar
            extends Modelica.Icons.Function;
            input Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_con IN_con;
            input Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_var IN_var;
            output .Modelica.SIunits.CoefficientOfHeatTransfer kc;
            output .Modelica.SIunits.PrandtlNumber Pr;
            output .Modelica.SIunits.ReynoldsNumber Re;
            output .Modelica.SIunits.NusseltNumber Nu;
            output Real failureStatus;
          protected
            type TYP = Modelica.Fluid.Dissipation.Utilities.Types.kc_evenGap;
            Real MIN = Modelica.Constants.eps;
            Real laminar = 2200;
            .Modelica.SIunits.Area A_cross = IN_con.s * IN_con.h;
            .Modelica.SIunits.Diameter d_hyd = 2 * IN_con.s;
            Real prandtlMax = if IN_con.target == TYP.UndevOne then 10 else if IN_con.target == TYP.UndevBoth then 1000 else 0;
            Real prandtlMin = if IN_con.target == TYP.UndevOne or IN_con.target == TYP.UndevBoth then 0.1 else 0;
            .Modelica.SIunits.Velocity velocity = abs(IN_var.m_flow) / max(MIN, IN_var.rho * A_cross);
            Real[2] fstatus;
          algorithm
            Pr := abs(IN_var.eta * IN_var.cp / max(MIN, IN_var.lambda));
            Re := max(1, abs(IN_var.rho * velocity * d_hyd / max(MIN, IN_var.eta)));
            kc := Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_KC(IN_con, IN_var);
            Nu := kc * d_hyd / max(MIN, IN_var.lambda);
            fstatus[1] := if Re > laminar then 1 else 0;
            fstatus[2] := if IN_con.target == TYP.UndevOne or IN_con.target == TYP.UndevBoth then if Pr > prandtlMax or Pr < prandtlMin then 1 else 0 else 0;
            failureStatus := 0;
            for i in 1:size(fstatus, 1) loop
              if fstatus[i] == 1 then
                failureStatus := 1;
              else
              end if;
            end for;
          end kc_evenGapLaminar;

          function kc_evenGapLaminar_KC
            extends Modelica.Icons.Function;
            input Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_con IN_con;
            input Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapLaminar_IN_var IN_var;
            output .Modelica.SIunits.CoefficientOfHeatTransfer kc;
          protected
            type TYP = Modelica.Fluid.Dissipation.Utilities.Types.kc_evenGap;
            Real MIN = Modelica.Constants.eps;
            .Modelica.SIunits.Area A_cross = max(MIN, IN_con.s * IN_con.h);
            .Modelica.SIunits.Diameter d_hyd = 2 * IN_con.s;
            .Modelica.SIunits.Velocity velocity = abs(IN_var.m_flow) / max(MIN, IN_var.rho * A_cross);
            .Modelica.SIunits.ReynoldsNumber Re = max(1, IN_var.rho * velocity * d_hyd / max(MIN, IN_var.eta));
            .Modelica.SIunits.PrandtlNumber Pr = abs(IN_var.eta * IN_var.cp / max(MIN, IN_var.lambda));
            .Modelica.SIunits.NusseltNumber Nu_1 = if IN_con.target == TYP.DevOne or IN_con.target == TYP.UndevOne then 4.861 else if IN_con.target == TYP.DevBoth or IN_con.target == TYP.UndevBoth then 7.541 else 0;
            .Modelica.SIunits.NusseltNumber Nu_2 = 1.841 * (Re * Pr * d_hyd / max(IN_con.L, MIN)) ^ (1 / 3);
            .Modelica.SIunits.NusseltNumber Nu_3 = if IN_con.target == TYP.UndevOne or IN_con.target == TYP.UndevBoth then (2 / (1 + 22 * Pr)) ^ (1 / 6) * (Re * Pr * d_hyd / max(IN_con.L, MIN)) ^ 0.5 else 0;
            .Modelica.SIunits.NusseltNumber Nu = (Nu_1 ^ 3 + Nu_2 ^ 3 + Nu_3 ^ 3) ^ (1 / 3);
          algorithm
            kc := Nu * IN_var.lambda / max(MIN, d_hyd);
          end kc_evenGapLaminar_KC;

          record kc_evenGapLaminar_IN_con
            extends Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapOverall_IN_con;
          end kc_evenGapLaminar_IN_con;

          record kc_evenGapLaminar_IN_var
            extends Modelica.Fluid.Dissipation.HeatTransfer.Channel.kc_evenGapOverall_IN_var;
          end kc_evenGapLaminar_IN_var;

          record kc_evenGapOverall_IN_con
            extends Modelica.Fluid.Dissipation.Utilities.Records.HeatTransfer.EvenGap;
          end kc_evenGapOverall_IN_con;

          record kc_evenGapOverall_IN_var
            extends Modelica.Fluid.Dissipation.Utilities.Records.General.FluidProperties;
            .Modelica.SIunits.MassFlowRate m_flow;
          end kc_evenGapOverall_IN_var;
        end Channel;
      end HeatTransfer;

      package Utilities
        extends Modelica.Icons.UtilitiesPackage;

        package Records
          extends Modelica.Icons.Package;

          package General
            extends Modelica.Icons.Package;

            record FluidProperties
              extends Modelica.Icons.Record;
              .Modelica.SIunits.SpecificHeatCapacityAtConstantPressure cp;
              .Modelica.SIunits.DynamicViscosity eta;
              .Modelica.SIunits.ThermalConductivity lambda;
              .Modelica.SIunits.Density rho;
            end FluidProperties;
          end General;

          package HeatTransfer
            extends Modelica.Icons.Package;

            record EvenGap
              extends Modelica.Icons.Record;
              Modelica.Fluid.Dissipation.Utilities.Types.kc_evenGap target = Dissipation.Utilities.Types.kc_evenGap.DevBoth;
              .Modelica.SIunits.Length h = 0.1;
              .Modelica.SIunits.Length s = 0.05;
              .Modelica.SIunits.Length L = 1;
            end EvenGap;
          end HeatTransfer;
        end Records;

        package Types
          extends Modelica.Icons.TypesPackage;
          type kc_evenGap = enumeration(DevOne, DevBoth, UndevOne, UndevBoth);
        end Types;
      end Utilities;
    end Dissipation;
  end Fluid;

  package Math
    extends Modelica.Icons.Package;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter  end AxisCenter;
    end Icons;

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
    final constant Real eps = ModelicaServices.Machine.eps;
    final constant .Modelica.SIunits.Velocity c = 299792458;
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 0.0000001;
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

    partial package UtilitiesPackage
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

    partial package TypesPackage
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package IconsPackage
      extends Modelica.Icons.Package;
    end IconsPackage;

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
    type Diameter = Length(min = 0);
    type Area = Real(final quantity = "Area", final unit = "m2");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
    type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type CoefficientOfHeatTransfer = Real(final quantity = "CoefficientOfHeatTransfer", final unit = "W/(m2.K)");
    type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
    type SpecificHeatCapacityAtConstantPressure = SpecificHeatCapacity;
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    type ReynoldsNumber = Real(final quantity = "ReynoldsNumber", final unit = "1");
    type NusseltNumber = Real(final quantity = "NusseltNumber", final unit = "1");
    type PrandtlNumber = Real(final quantity = "PrandtlNumber", final unit = "1");
  end SIunits;
end Modelica;
