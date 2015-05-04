package Modelica
  extends Modelica.Icons.Package;

  package Fluid
    extends Modelica.Icons.Package;

    package Utilities
      extends Modelica.Icons.UtilitiesPackage;

      function regStep
        extends Modelica.Icons.Function;
        input Real x;
        input Real y1;
        input Real y2;
        input Real x_small(min = 0) = 1e-5;
        output Real y;
      algorithm
        y := smooth(1, if x > x_small then y1 else if x < (-x_small) then y2 else if x_small > 0 then x / x_small * ((x / x_small) ^ 2 - 3) * (y2 - y1) / 4 + (y1 + y2) / 2 else (y1 + y2) / 2);
      end regStep;

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

  package Icons
    extends Icons.Package;

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

    partial function Function  end Function;

    partial record Record  end Record;
  end Icons;

  package SIunits
    extends Modelica.Icons.Package;
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type VolumeFlowRate = Real(final quantity = "VolumeFlowRate", final unit = "m3/s");
  end SIunits;
end Modelica;

package Annex60
  extends Modelica.Icons.Package;

  package Fluid
    extends Modelica.Icons.Package;

    package Movers
      extends Modelica.Icons.VariantsPackage;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        package Characteristics
          record flowParametersInternal
            extends Modelica.Icons.Record;
            parameter Integer n;
            parameter Modelica.SIunits.VolumeFlowRate[n] V_flow(each min = 0);
            parameter Modelica.SIunits.Pressure[n] dp(each min = 0, each displayUnit = "Pa");
          end flowParametersInternal;

          function pressure
            extends Modelica.Icons.Function;
            input Annex60.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal data;
            input Modelica.SIunits.VolumeFlowRate V_flow;
            input Real r_N(unit = "1");
            input Modelica.SIunits.VolumeFlowRate VDelta_flow;
            input Modelica.SIunits.Pressure dpDelta;
            input Modelica.SIunits.VolumeFlowRate V_flow_max;
            input Modelica.SIunits.Pressure dpMax(min = 0);
            input Real[:] d;
            input Real delta;
            input Real[2] cBar;
            input Real kRes(unit = "kg/(s.m4)");
            output Modelica.SIunits.Pressure dp;
          protected
            Integer dimD(min = 2) = size(data.V_flow, 1);

            function performanceCurve
              input Modelica.SIunits.VolumeFlowRate V_flow;
              input Real r_N(unit = "1");
              input Real[dimD] d;
              input Annex60.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal data;
              input Integer dimD;
              output Modelica.SIunits.Pressure dp;
            protected
              Modelica.SIunits.VolumeFlowRate rat;
              Integer i;
            algorithm
              rat := V_flow / r_N;
              i := 1;
              for j in 1:dimD - 1 loop
                if rat > data.V_flow[j] then
                  i := j;
                else
                end if;
              end for;
              dp := r_N ^ 2 * Annex60.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = rat, x1 = data.V_flow[i], x2 = data.V_flow[i + 1], y1 = data.dp[i], y2 = data.dp[i + 1], y1d = d[i], y2d = d[i + 1]);
            end performanceCurve;
          algorithm
            if r_N >= delta then
              dp := performanceCurve(V_flow = V_flow, r_N = r_N, d = d, data = data, dimD = dimD);
            elseif r_N <= delta / 2 then
              dp := flowApproximationAtOrigin(r_N = r_N, V_flow = V_flow, VDelta_flow = VDelta_flow, dpDelta = dpDelta, delta = delta, cBar = cBar);
            else
              dp := Modelica.Fluid.Utilities.regStep(x = r_N - 0.75 * delta, y1 = performanceCurve(V_flow = V_flow, r_N = r_N, d = d, data = data, dimD = dimD), y2 = flowApproximationAtOrigin(r_N = r_N, V_flow = V_flow, VDelta_flow = VDelta_flow, dpDelta = dpDelta, delta = delta, cBar = cBar), x_small = delta / 4);
            end if;
            dp := dp - V_flow * kRes;
          end pressure;

          function flowApproximationAtOrigin
            extends Modelica.Icons.Function;
            input Modelica.SIunits.VolumeFlowRate V_flow;
            input Real r_N(unit = "1");
            input Modelica.SIunits.VolumeFlowRate VDelta_flow;
            input Modelica.SIunits.Pressure dpDelta;
            input Real delta;
            input Real[2] cBar;
            output Modelica.SIunits.Pressure dp;
          algorithm
            dp := r_N * dpDelta + r_N ^ 2 * (cBar[1] + cBar[2] * V_flow);
          end flowApproximationAtOrigin;
        end Characteristics;
      end BaseClasses;
    end Movers;
  end Fluid;

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
      end Functions;
    end Math;
  end Utilities;
end Annex60;
