// status: correct
// Bug #2761

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

    package Continuous
      extends Modelica.Icons.Package;

      block Filter
        extends Modelica.Blocks.Interfaces.SISO;
        parameter Modelica.Blocks.Types.AnalogFilter analogFilter = Modelica.Blocks.Types.AnalogFilter.CriticalDamping;
        parameter Modelica.Blocks.Types.FilterType filterType = Modelica.Blocks.Types.FilterType.LowPass;
        parameter Integer order(min = 1) = 2;
        parameter Modelica.SIunits.Frequency f_cut;
        parameter Real gain = 1.0;
        parameter Real A_ripple(unit = "dB") = 0.5;
        parameter Modelica.SIunits.Frequency f_min = 0;
        parameter Boolean normalized = true;
        parameter Modelica.Blocks.Types.Init init = Modelica.Blocks.Types.Init.SteadyState annotation(Evaluate = true);
        final parameter Integer nx = if filterType == Modelica.Blocks.Types.FilterType.LowPass or filterType == Modelica.Blocks.Types.FilterType.HighPass then order else 2 * order;
        parameter Real[nx] x_start = zeros(nx);
        parameter Real y_start = 0;
        parameter Real u_nominal = 1.0;
        Modelica.Blocks.Interfaces.RealOutput[nx] x;
      protected
        parameter Integer ncr = if analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then order else mod(order, 2);
        parameter Integer nc0 = if analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then 0 else integer(order / 2);
        parameter Integer na = if filterType == Modelica.Blocks.Types.FilterType.BandPass or filterType == Modelica.Blocks.Types.FilterType.BandStop then order else if analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then 0 else integer(order / 2);
        parameter Integer nr = if filterType == Modelica.Blocks.Types.FilterType.BandPass or filterType == Modelica.Blocks.Types.FilterType.BandStop then 0 else if analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then order else mod(order, 2);
        parameter Real[ncr] cr(each fixed = false);
        parameter Real[nc0] c0(each fixed = false);
        parameter Real[nc0] c1(each fixed = false);
        parameter Real[nr] r(each fixed = false);
        parameter Real[na] a(each fixed = false);
        parameter Real[na] b(each fixed = false);
        parameter Real[na] ku(each fixed = false);
        parameter Real[if filterType == Modelica.Blocks.Types.FilterType.LowPass then 0 else na] k1(each fixed = false);
        parameter Real[if filterType == Modelica.Blocks.Types.FilterType.LowPass then 0 else na] k2(each fixed = false);
        Real[na + nr + 1] uu;
      initial equation
        if analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then
          cr = Internal.Filter.base.CriticalDamping(order, normalized);
        elseif analogFilter == Modelica.Blocks.Types.AnalogFilter.Bessel then
          (cr, c0, c1) = Internal.Filter.base.Bessel(order, normalized);
        elseif analogFilter == Modelica.Blocks.Types.AnalogFilter.Butterworth then
          (cr, c0, c1) = Internal.Filter.base.Butterworth(order, normalized);
        elseif analogFilter == Modelica.Blocks.Types.AnalogFilter.ChebyshevI then
          (cr, c0, c1) = Internal.Filter.base.ChebyshevI(order, A_ripple, normalized);
        end if;
        if filterType == Modelica.Blocks.Types.FilterType.LowPass then
          (r, a, b, ku) = Internal.Filter.roots.lowPass(cr, c0, c1, f_cut);
        elseif filterType == Modelica.Blocks.Types.FilterType.HighPass then
          (r, a, b, ku, k1, k2) = Internal.Filter.roots.highPass(cr, c0, c1, f_cut);
        elseif filterType == Modelica.Blocks.Types.FilterType.BandPass then
          (a, b, ku, k1, k2) = Internal.Filter.roots.bandPass(cr, c0, c1, f_min, f_cut);
        elseif filterType == Modelica.Blocks.Types.FilterType.BandStop then
          (a, b, ku, k1, k2) = Internal.Filter.roots.bandStop(cr, c0, c1, f_min, f_cut);
        end if;
        if init == Modelica.Blocks.Types.Init.InitialState then
          x = x_start;
        elseif init == Modelica.Blocks.Types.Init.SteadyState then
          der(x) = zeros(nx);
        elseif init == Modelica.Blocks.Types.Init.InitialOutput then
          y = y_start;
          if nx > 1 then
            der(x[1:nx - 1]) = zeros(nx - 1);
          end if;
        end if;
      equation
        assert(u_nominal > 0, "u_nominal > 0 required");
        assert(filterType == Modelica.Blocks.Types.FilterType.LowPass or filterType == Modelica.Blocks.Types.FilterType.HighPass or f_min > 0, "f_min > 0 required for band pass and band stop filter");
        assert(A_ripple > 0, "A_ripple > 0 required");
        assert(f_cut > 0, "f_cut > 0 required");
        uu[1] = u / u_nominal;
        for i in 1:nr loop
          der(x[i]) = r[i] * (x[i] - uu[i]);
        end for;
        for i in 1:na loop
          der(x[nr + 2 * i - 1]) = a[i] * x[nr + 2 * i - 1] - b[i] * x[nr + 2 * i] + ku[i] * uu[nr + i];
          der(x[nr + 2 * i]) = b[i] * x[nr + 2 * i - 1] + a[i] * x[nr + 2 * i];
        end for;
        if filterType == Modelica.Blocks.Types.FilterType.LowPass then
          for i in 1:nr loop
            uu[i + 1] = x[i];
          end for;
          for i in 1:na loop
            uu[nr + i + 1] = x[nr + 2 * i];
          end for;
        elseif filterType == Modelica.Blocks.Types.FilterType.HighPass then
          for i in 1:nr loop
            uu[i + 1] = (-x[i]) + uu[i];
          end for;
          for i in 1:na loop
            uu[nr + i + 1] = k1[i] * x[nr + 2 * i - 1] + k2[i] * x[nr + 2 * i] + uu[nr + i];
          end for;
        elseif filterType == Modelica.Blocks.Types.FilterType.BandPass then
          for i in 1:na loop
            uu[nr + i + 1] = k1[i] * x[nr + 2 * i - 1] + k2[i] * x[nr + 2 * i];
          end for;
        elseif filterType == Modelica.Blocks.Types.FilterType.BandStop then
          for i in 1:na loop
            uu[nr + i + 1] = k1[i] * x[nr + 2 * i - 1] + k2[i] * x[nr + 2 * i] + uu[nr + i];
          end for;
        else
          assert(false, "filterType (= " + String(filterType) + ") is unknown");
          uu = zeros(na + nr + 1);
        end if;
        y = gain * u_nominal * uu[nr + na + 1];
      end Filter;

      package Internal
        extends Modelica.Icons.InternalPackage;

        package Filter
          extends Modelica.Icons.InternalPackage;

          package base
            extends Modelica.Icons.InternalPackage;

            function CriticalDamping
              extends Modelica.Icons.Function;
              input Integer order(min = 1);
              input Boolean normalized = true;
              output Real[order] cr;
            protected
              Real alpha = 1.0;
              Real alpha2;
              Real[order] den1;
              Real[0, 2] den2;
              Real[0] c0;
              Real[0] c1;
            algorithm
              if normalized then
                alpha := sqrt(10 ^ (3 / 10 / order) - 1);
              else
                alpha := 1.0;
              end if;
              for i in 1:order loop
                den1[i] := alpha;
              end for;
              (cr, c0, c1) := Modelica.Blocks.Continuous.Internal.Filter.Utilities.toHighestPowerOne(den1, den2);
            end CriticalDamping;

            function Bessel
              extends Modelica.Icons.Function;
              input Integer order(min = 1);
              input Boolean normalized = true;
              output Real[mod(order, 2)] cr;
              output Real[integer(order / 2)] c0;
              output Real[integer(order / 2)] c1;
            protected
              Real alpha = 1.0;
              Real alpha2;
              Real[size(cr, 1)] den1;
              Real[size(c0, 1), 2] den2;
            algorithm
              (den1, den2, alpha) := Modelica.Blocks.Continuous.Internal.Filter.Utilities.BesselBaseCoefficients(order);
              if not normalized then
                alpha2 := alpha * alpha;
                for i in 1:size(c0, 1) loop
                  den2[i, 1] := den2[i, 1] * alpha2;
                  den2[i, 2] := den2[i, 2] * alpha;
                end for;
                if size(cr, 1) == 1 then
                  den1[1] := den1[1] * alpha;
                else
                end if;
              else
              end if;
              (cr, c0, c1) := Modelica.Blocks.Continuous.Internal.Filter.Utilities.toHighestPowerOne(den1, den2);
            end Bessel;

            function Butterworth
              extends Modelica.Icons.Function;
              input Integer order(min = 1);
              input Boolean normalized = true;
              output Real[mod(order, 2)] cr;
              output Real[integer(order / 2)] c0;
              output Real[integer(order / 2)] c1;
            protected
              Real alpha = 1.0;
              Real alpha2;
              Real[size(cr, 1)] den1;
              Real[size(c0, 1), 2] den2;
              constant Real pi = Modelica.Constants.pi;
            algorithm
              for i in 1:size(c0, 1) loop
                den2[i, 1] := 1.0;
                den2[i, 2] := -2 * Modelica.Math.cos(pi * (0.5 + (i - 0.5) / order));
              end for;
              if size(cr, 1) == 1 then
                den1[1] := 1.0;
              else
              end if;
              (cr, c0, c1) := Modelica.Blocks.Continuous.Internal.Filter.Utilities.toHighestPowerOne(den1, den2);
            end Butterworth;

            function ChebyshevI
              extends Modelica.Icons.Function;
              input Integer order(min = 1);
              input Real A_ripple = 0.5;
              input Boolean normalized = true;
              output Real[mod(order, 2)] cr;
              output Real[integer(order / 2)] c0;
              output Real[integer(order / 2)] c1;
            protected
              Real epsilon;
              Real fac;
              Real alpha = 1.0;
              Real alpha2;
              Real[size(cr, 1)] den1;
              Real[size(c0, 1), 2] den2;
              constant Real pi = Modelica.Constants.pi;
            algorithm
              epsilon := sqrt(10 ^ (A_ripple / 10) - 1);
              fac := .Modelica.Math.asinh(1 / epsilon) / order;
              den1 := fill(1 / sinh(fac), size(den1, 1));
              if size(cr, 1) == 0 then
                for i in 1:size(c0, 1) loop
                  den2[i, 1] := 1 / (cosh(fac) ^ 2 - cos((2 * i - 1) * pi / (2 * order)) ^ 2);
                  den2[i, 2] := 2 * den2[i, 1] * sinh(fac) * cos((2 * i - 1) * pi / (2 * order));
                end for;
              else
                for i in 1:size(c0, 1) loop
                  den2[i, 1] := 1 / (cosh(fac) ^ 2 - cos(i * pi / order) ^ 2);
                  den2[i, 2] := 2 * den2[i, 1] * sinh(fac) * cos(i * pi / order);
                end for;
              end if;
              if normalized then
                alpha := Modelica.Blocks.Continuous.Internal.Filter.Utilities.normalizationFactor(den1, den2);
                alpha2 := alpha * alpha;
                for i in 1:size(c0, 1) loop
                  den2[i, 1] := den2[i, 1] * alpha2;
                  den2[i, 2] := den2[i, 2] * alpha;
                end for;
                den1 := den1 * alpha;
              else
              end if;
              (cr, c0, c1) := Modelica.Blocks.Continuous.Internal.Filter.Utilities.toHighestPowerOne(den1, den2);
            end ChebyshevI;
          end base;

          package coefficients
            extends Modelica.Icons.InternalPackage;

            function lowPass
              extends Modelica.Icons.Function;
              input Real[:] cr_in;
              input Real[:] c0_in;
              input Real[size(c0_in, 1)] c1_in;
              input Modelica.SIunits.Frequency f_cut;
              output Real[size(cr_in, 1)] cr;
              output Real[size(c0_in, 1)] c0;
              output Real[size(c0_in, 1)] c1;
            protected
              constant Real pi = Modelica.Constants.pi;
              Modelica.SIunits.AngularVelocity w_cut = 2 * pi * f_cut;
              Real w_cut2 = w_cut * w_cut;
            algorithm
              assert(f_cut > 0, "Cut-off frequency f_cut must be positive");
              cr := w_cut * cr_in;
              c1 := w_cut * c1_in;
              c0 := w_cut2 * c0_in;
            end lowPass;

            function highPass
              extends Modelica.Icons.Function;
              input Real[:] cr_in;
              input Real[:] c0_in;
              input Real[size(c0_in, 1)] c1_in;
              input Modelica.SIunits.Frequency f_cut;
              output Real[size(cr_in, 1)] cr;
              output Real[size(c0_in, 1)] c0;
              output Real[size(c0_in, 1)] c1;
            protected
              constant Real pi = Modelica.Constants.pi;
              Modelica.SIunits.AngularVelocity w_cut = 2 * pi * f_cut;
              Real w_cut2 = w_cut * w_cut;
            algorithm
              assert(f_cut > 0, "Cut-off frequency f_cut must be positive");
              for i in 1:size(cr_in, 1) loop
                cr[i] := w_cut / cr_in[i];
              end for;
              for i in 1:size(c0_in, 1) loop
                c0[i] := w_cut2 / c0_in[i];
                c1[i] := w_cut * c1_in[i] / c0_in[i];
              end for;
            end highPass;

            function bandPass
              extends Modelica.Icons.Function;
              input Real[:] cr_in;
              input Real[:] c0_in;
              input Real[size(c0_in, 1)] c1_in;
              input Modelica.SIunits.Frequency f_min;
              input Modelica.SIunits.Frequency f_max;
              output Real[0] cr;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] c0;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] c1;
              output Real cn;
            protected
              constant Real pi = Modelica.Constants.pi;
              Modelica.SIunits.Frequency f0 = sqrt(f_min * f_max);
              Modelica.SIunits.AngularVelocity w_cut = 2 * pi * f0;
              Real w_band = (f_max - f_min) / f0;
              Real w_cut2 = w_cut * w_cut;
              Real c;
              Real alpha;
              Integer j;
            algorithm
              assert(f_min > 0 and f_min < f_max, "Band frequencies f_min and f_max are wrong");
              for i in 1:size(cr_in, 1) loop
                c1[i] := w_cut * cr_in[i] * w_band;
                c0[i] := w_cut2;
              end for;
              for i in 1:size(c1_in, 1) loop
                alpha := Modelica.Blocks.Continuous.Internal.Filter.Utilities.bandPassAlpha(c1_in[i], c0_in[i], w_band);
                c := c1_in[i] * w_band / (alpha + 1 / alpha);
                j := size(cr_in, 1) + 2 * i - 1;
                c1[j] := w_cut * c / alpha;
                c1[j + 1] := w_cut * c * alpha;
                c0[j] := w_cut2 / alpha ^ 2;
                c0[j + 1] := w_cut2 * alpha ^ 2;
              end for;
              cn := w_band * w_cut;
            end bandPass;

            function bandStop
              extends Modelica.Icons.Function;
              input Real[:] cr_in;
              input Real[:] c0_in;
              input Real[size(c0_in, 1)] c1_in;
              input Modelica.SIunits.Frequency f_min;
              input Modelica.SIunits.Frequency f_max;
              output Real[0] cr;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] c0;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] c1;
            protected
              constant Real pi = Modelica.Constants.pi;
              Modelica.SIunits.Frequency f0 = sqrt(f_min * f_max);
              Modelica.SIunits.AngularVelocity w_cut = 2 * pi * f0;
              Real w_band = (f_max - f_min) / f0;
              Real w_cut2 = w_cut * w_cut;
              Real c;
              Real ww;
              Real alpha;
              Integer j;
            algorithm
              assert(f_min > 0 and f_min < f_max, "Band frequencies f_min and f_max are wrong");
              for i in 1:size(cr_in, 1) loop
                c1[i] := w_cut * w_band / cr_in[i];
                c0[i] := w_cut2;
              end for;
              for i in 1:size(c1_in, 1) loop
                ww := w_band / c0_in[i];
                alpha := Modelica.Blocks.Continuous.Internal.Filter.Utilities.bandPassAlpha(c1_in[i], c0_in[i], ww);
                c := c1_in[i] * ww / (alpha + 1 / alpha);
                j := size(cr_in, 1) + 2 * i - 1;
                c1[j] := w_cut * c / alpha;
                c1[j + 1] := w_cut * c * alpha;
                c0[j] := w_cut2 / alpha ^ 2;
                c0[j + 1] := w_cut2 * alpha ^ 2;
              end for;
            end bandStop;
          end coefficients;

          package roots
            extends Modelica.Icons.InternalPackage;

            function lowPass
              extends Modelica.Icons.Function;
              input Real[:] cr_in;
              input Real[:] c0_in;
              input Real[size(c0_in, 1)] c1_in;
              input Modelica.SIunits.Frequency f_cut;
              output Real[size(cr_in, 1)] r;
              output Real[size(c0_in, 1)] a;
              output Real[size(c0_in, 1)] b;
              output Real[size(c0_in, 1)] ku;
            protected
              Real[size(c0_in, 1)] c0;
              Real[size(c0_in, 1)] c1;
              Real[size(cr_in, 1)] cr;
            algorithm
              (cr, c0, c1) := coefficients.lowPass(cr_in, c0_in, c1_in, f_cut);
              for i in 1:size(cr_in, 1) loop
                r[i] := -cr[i];
              end for;
              for i in 1:size(c0_in, 1) loop
                a[i] := -c1[i] / 2;
                b[i] := sqrt(c0[i] - a[i] * a[i]);
                ku[i] := c0[i] / b[i];
              end for;
            end lowPass;

            function highPass
              extends Modelica.Icons.Function;
              input Real[:] cr_in;
              input Real[:] c0_in;
              input Real[size(c0_in, 1)] c1_in;
              input Modelica.SIunits.Frequency f_cut;
              output Real[size(cr_in, 1)] r;
              output Real[size(c0_in, 1)] a;
              output Real[size(c0_in, 1)] b;
              output Real[size(c0_in, 1)] ku;
              output Real[size(c0_in, 1)] k1;
              output Real[size(c0_in, 1)] k2;
            protected
              Real[size(c0_in, 1)] c0;
              Real[size(c0_in, 1)] c1;
              Real[size(cr_in, 1)] cr;
              Real ba2;
            algorithm
              (cr, c0, c1) := coefficients.highPass(cr_in, c0_in, c1_in, f_cut);
              for i in 1:size(cr_in, 1) loop
                r[i] := -cr[i];
              end for;
              for i in 1:size(c0_in, 1) loop
                a[i] := -c1[i] / 2;
                b[i] := sqrt(c0[i] - a[i] * a[i]);
                ku[i] := c0[i] / b[i];
                k1[i] := 2 * a[i] / ku[i];
                ba2 := (b[i] / a[i]) ^ 2;
                k2[i] := (1 - ba2) / (1 + ba2);
              end for;
            end highPass;

            function bandPass
              extends Modelica.Icons.Function;
              input Real[:] cr_in;
              input Real[:] c0_in;
              input Real[size(c0_in, 1)] c1_in;
              input Modelica.SIunits.Frequency f_min;
              input Modelica.SIunits.Frequency f_max;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] a;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] b;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] ku;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] k1;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] k2;
            protected
              Real[0] cr;
              Real[size(a, 1)] c0;
              Real[size(a, 1)] c1;
              Real cn;
              Real bb;
            algorithm
              (cr, c0, c1, cn) := coefficients.bandPass(cr_in, c0_in, c1_in, f_min, f_max);
              for i in 1:size(a, 1) loop
                a[i] := -c1[i] / 2;
                bb := c0[i] - a[i] * a[i];
                assert(bb >= 0, "\nNot possible to use band pass filter, since transformation results in\n" + "system that does not have conjugate complex poles.\n" + "Try to use another analog filter for the band pass.\n");
                b[i] := sqrt(bb);
                ku[i] := c0[i] / b[i];
                k1[i] := cn / ku[i];
                k2[i] := cn * a[i] / (b[i] * ku[i]);
              end for;
            end bandPass;

            function bandStop
              extends Modelica.Icons.Function;
              input Real[:] cr_in;
              input Real[:] c0_in;
              input Real[size(c0_in, 1)] c1_in;
              input Modelica.SIunits.Frequency f_min;
              input Modelica.SIunits.Frequency f_max;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] a;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] b;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] ku;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] k1;
              output Real[size(cr_in, 1) + 2 * size(c0_in, 1)] k2;
            protected
              Real[0] cr;
              Real[size(a, 1)] c0;
              Real[size(a, 1)] c1;
              Real cn;
              Real bb;
            algorithm
              (cr, c0, c1) := coefficients.bandStop(cr_in, c0_in, c1_in, f_min, f_max);
              for i in 1:size(a, 1) loop
                a[i] := -c1[i] / 2;
                bb := c0[i] - a[i] * a[i];
                assert(bb >= 0, "\nNot possible to use band stop filter, since transformation results in\n" + "system that does not have conjugate complex poles.\n" + "Try to use another analog filter for the band stop filter.\n");
                b[i] := sqrt(bb);
                ku[i] := c0[i] / b[i];
                k1[i] := 2 * a[i] / ku[i];
                k2[i] := (c0[i] + a[i] ^ 2 - b[i] ^ 2) / (b[i] * ku[i]);
              end for;
            end bandStop;
          end roots;

          package Utilities
            extends Modelica.Icons.InternalPackage;

            function BesselBaseCoefficients
              extends Modelica.Icons.Function;
              input Integer order;
              output Real[mod(order, 2)] c1;
              output Real[integer(order / 2), 2] c2;
              output Real alpha;
            algorithm
              if order == 1 then
                alpha := 1.002377293007601;
                c1[1] := 0.9976283451109835;
              elseif order == 2 then
                alpha := 0.7356641785819585;
                c2[1, 1] := 0.6159132201783791;
                c2[1, 2] := 1.359315879600889;
              elseif order == 3 then
                alpha := 0.5704770156982642;
                c1[1] := 0.7548574865985343;
                c2[1, 1] := 0.4756958028827457;
                c2[1, 2] := 0.9980615136104388;
              elseif order == 4 then
                alpha := 0.4737978580281427;
                c2[1, 1] := 0.4873729247240677;
                c2[1, 2] := 1.337564170455762;
                c2[2, 1] := 0.3877724315741958;
                c2[2, 2] := 0.7730405590839861;
              elseif order == 5 then
                alpha := 0.4126226974763408;
                c1[1] := 0.6645723262620757;
                c2[1, 1] := 0.4115231900614016;
                c2[1, 2] := 1.138349926728708;
                c2[2, 1] := 0.3234938702877912;
                c2[2, 2] := 0.6205992985771313;
              elseif order == 6 then
                alpha := 0.3705098000736233;
                c2[1, 1] := 0.3874508649098960;
                c2[1, 2] := 1.219740879520741;
                c2[2, 1] := 0.3493298843155746;
                c2[2, 2] := 0.9670265529381365;
                c2[3, 1] := 0.2747419229514599;
                c2[3, 2] := 0.5122165075105700;
              elseif order == 7 then
                alpha := 0.3393452623586350;
                c1[1] := 0.5927147125821412;
                c2[1, 1] := 0.3383379423919174;
                c2[1, 2] := 1.092630816438030;
                c2[2, 1] := 0.3001025788696046;
                c2[2, 2] := 0.8289928256598656;
                c2[3, 1] := 0.2372867471539579;
                c2[3, 2] := 0.4325128641920154;
              elseif order == 8 then
                alpha := 0.3150267393795002;
                c2[1, 1] := 0.3151115975207653;
                c2[1, 2] := 1.109403015460190;
                c2[2, 1] := 0.2969344839572762;
                c2[2, 2] := 0.9737455812222699;
                c2[3, 1] := 0.2612545921889538;
                c2[3, 2] := 0.7190394712068573;
                c2[4, 1] := 0.2080523342974281;
                c2[4, 2] := 0.3721456473047434;
              elseif order == 9 then
                alpha := 0.2953310177184124;
                c1[1] := 0.5377196679501422;
                c2[1, 1] := 0.2824689124281034;
                c2[1, 2] := 1.022646191567475;
                c2[2, 1] := 0.2626824161383468;
                c2[2, 2] := 0.8695626454762596;
                c2[3, 1] := 0.2302781917677917;
                c2[3, 2] := 0.6309047553448520;
                c2[4, 1] := 0.1847991729757028;
                c2[4, 2] := 0.3251978031287202;
              elseif order == 10 then
                alpha := 0.2789426890619463;
                c2[1, 1] := 0.2640769908255582;
                c2[1, 2] := 1.019788132875305;
                c2[2, 1] := 0.2540802639216947;
                c2[2, 2] := 0.9377020417760623;
                c2[3, 1] := 0.2343577229427963;
                c2[3, 2] := 0.7802229808216112;
                c2[4, 1] := 0.2052193139338624;
                c2[4, 2] := 0.5594176813008133;
                c2[5, 1] := 0.1659546953748916;
                c2[5, 2] := 0.2878349616233292;
              elseif order == 11 then
                alpha := 0.2650227766037203;
                c1[1] := 0.4950265498954191;
                c2[1, 1] := 0.2411858478546218;
                c2[1, 2] := 0.9567800996387417;
                c2[2, 1] := 0.2296849355380925;
                c2[2, 2] := 0.8592523717113126;
                c2[3, 1] := 0.2107851705677406;
                c2[3, 2] := 0.7040216048898129;
                c2[4, 1] := 0.1846461385164021;
                c2[4, 2] := 0.5006729207276717;
                c2[5, 1] := 0.1504217970817433;
                c2[5, 2] := 0.2575070491320295;
              elseif order == 12 then
                alpha := 0.2530051198547209;
                c2[1, 1] := 0.2268294941204543;
                c2[1, 2] := 0.9473116570034053;
                c2[2, 1] := 0.2207657387793729;
                c2[2, 2] := 0.8933728946287606;
                c2[3, 1] := 0.2087600700376653;
                c2[3, 2] := 0.7886236252756229;
                c2[4, 1] := 0.1909959101492760;
                c2[4, 2] := 0.6389263649257017;
                c2[5, 1] := 0.1675208146048472;
                c2[5, 2] := 0.4517847275162215;
                c2[6, 1] := 0.1374257286372761;
                c2[6, 2] := 0.2324699157474680;
              elseif order == 13 then
                alpha := 0.2424910397561007;
                c1[1] := 0.4608848369928040;
                c2[1, 1] := 0.2099813050274780;
                c2[1, 2] := 0.8992478823790660;
                c2[2, 1] := 0.2027250423101359;
                c2[2, 2] := 0.8328117484224146;
                c2[3, 1] := 0.1907635894058731;
                c2[3, 2] := 0.7257379204691213;
                c2[4, 1] := 0.1742280397887686;
                c2[4, 2] := 0.5830640944868014;
                c2[5, 1] := 0.1530858190490478;
                c2[5, 2] := 0.4106192089751885;
                c2[6, 1] := 0.1264090712880446;
                c2[6, 2] := 0.2114980230156001;
              elseif order == 14 then
                alpha := 0.2331902368695848;
                c2[1, 1] := 0.1986162311411235;
                c2[1, 2] := 0.8876961808055535;
                c2[2, 1] := 0.1946683341271615;
                c2[2, 2] := 0.8500754229171967;
                c2[3, 1] := 0.1868331332895056;
                c2[3, 2] := 0.7764629313723603;
                c2[4, 1] := 0.1752118757862992;
                c2[4, 2] := 0.6699720402924552;
                c2[5, 1] := 0.1598906457908402;
                c2[5, 2] := 0.5348446712848934;
                c2[6, 1] := 0.1407810153019944;
                c2[6, 2] := 0.3755841316563539;
                c2[7, 1] := 0.1169627966707339;
                c2[7, 2] := 0.1937088226304455;
              elseif order == 15 then
                alpha := 0.2248854870552422;
                c1[1] := 0.4328492272335646;
                c2[1, 1] := 0.1857292591004588;
                c2[1, 2] := 0.8496337061962563;
                c2[2, 1] := 0.1808644178280136;
                c2[2, 2] := 0.8020517898136011;
                c2[3, 1] := 0.1728264404199081;
                c2[3, 2] := 0.7247449729331105;
                c2[4, 1] := 0.1616970125901954;
                c2[4, 2] := 0.6205369315943097;
                c2[5, 1] := 0.1475257264578426;
                c2[5, 2] := 0.4929612162355906;
                c2[6, 1] := 0.1301861023357119;
                c2[6, 2] := 0.3454770708040735;
                c2[7, 1] := 0.1087810777120188;
                c2[7, 2] := 0.1784526655428406;
              elseif order == 16 then
                alpha := 0.2174105053474761;
                c2[1, 1] := 0.1765637967473151;
                c2[1, 2] := 0.8377453068635511;
                c2[2, 1] := 0.1738525357503125;
                c2[2, 2] := 0.8102988957433199;
                c2[3, 1] := 0.1684627004613343;
                c2[3, 2] := 0.7563265923413258;
                c2[4, 1] := 0.1604519074815815;
                c2[4, 2] := 0.6776082294687619;
                c2[5, 1] := 0.1498828607802206;
                c2[5, 2] := 0.5766417034027680;
                c2[6, 1] := 0.1367764717792823;
                c2[6, 2] := 0.4563528264410489;
                c2[7, 1] := 0.1209810465419295;
                c2[7, 2] := 0.3193782657322374;
                c2[8, 1] := 0.1016312648007554;
                c2[8, 2] := 0.1652419227369036;
              elseif order == 17 then
                alpha := 0.2106355148193306;
                c1[1] := 0.4093223608497299;
                c2[1, 1] := 0.1664014345826274;
                c2[1, 2] := 0.8067173752345952;
                c2[2, 1] := 0.1629839591538256;
                c2[2, 2] := 0.7712924931447541;
                c2[3, 1] := 0.1573277802512491;
                c2[3, 2] := 0.7134213666303411;
                c2[4, 1] := 0.1494828185148637;
                c2[4, 2] := 0.6347841731714884;
                c2[5, 1] := 0.1394948812681826;
                c2[5, 2] := 0.5375594414619047;
                c2[6, 1] := 0.1273627583380806;
                c2[6, 2] := 0.4241608926375478;
                c2[7, 1] := 0.1129187258461290;
                c2[7, 2] := 0.2965752009703245;
                c2[8, 1] := 0.9533357359908857e-1;
                c2[8, 2] := 0.1537041700889585;
              elseif order == 18 then
                alpha := 0.2044575288651841;
                c2[1, 1] := 0.1588768571976356;
                c2[1, 2] := 0.7951914263212913;
                c2[2, 1] := 0.1569357024981854;
                c2[2, 2] := 0.7744529690772538;
                c2[3, 1] := 0.1530722206358810;
                c2[3, 2] := 0.7335304425992080;
                c2[4, 1] := 0.1473206710524167;
                c2[4, 2] := 0.6735038935387268;
                c2[5, 1] := 0.1397225420331520;
                c2[5, 2] := 0.5959151542621590;
                c2[6, 1] := 0.1303092459809849;
                c2[6, 2] := 0.5026483447894845;
                c2[7, 1] := 0.1190627367060072;
                c2[7, 2] := 0.3956893824587150;
                c2[8, 1] := 0.1058058030798994;
                c2[8, 2] := 0.2765091830730650;
                c2[9, 1] := 0.8974708108800873e-1;
                c2[9, 2] := 0.1435505288284833;
              elseif order == 19 then
                alpha := 0.1987936248083529;
                c1[1] := 0.3892259966869526;
                c2[1, 1] := 0.1506640012172225;
                c2[1, 2] := 0.7693121733774260;
                c2[2, 1] := 0.1481728062796673;
                c2[2, 2] := 0.7421133586741549;
                c2[3, 1] := 0.1440444668388838;
                c2[3, 2] := 0.6975075386214800;
                c2[4, 1] := 0.1383101628540374;
                c2[4, 2] := 0.6365464378910025;
                c2[5, 1] := 0.1310032283190998;
                c2[5, 2] := 0.5606211948462122;
                c2[6, 1] := 0.1221431166405330;
                c2[6, 2] := 0.4713530424221445;
                c2[7, 1] := 0.1116991161103884;
                c2[7, 2] := 0.3703717538617073;
                c2[8, 1] := 0.9948917351196349e-1;
                c2[8, 2] := 0.2587371155559744;
                c2[9, 1] := 0.8475989238107367e-1;
                c2[9, 2] := 0.1345537894555993;
              elseif order == 20 then
                alpha := 0.1935761760416219;
                c2[1, 1] := 0.1443871348337404;
                c2[1, 2] := 0.7584165598446141;
                c2[2, 1] := 0.1429501891353184;
                c2[2, 2] := 0.7423000962318863;
                c2[3, 1] := 0.1400877384920004;
                c2[3, 2] := 0.7104185332215555;
                c2[4, 1] := 0.1358210369491446;
                c2[4, 2] := 0.6634599783272630;
                c2[5, 1] := 0.1301773703034290;
                c2[5, 2] := 0.6024175491895959;
                c2[6, 1] := 0.1231826501439148;
                c2[6, 2] := 0.5285332736326852;
                c2[7, 1] := 0.1148465498575254;
                c2[7, 2] := 0.4431977385498628;
                c2[8, 1] := 0.1051289462376788;
                c2[8, 2] := 0.3477444062821162;
                c2[9, 1] := 0.9384622797485121e-1;
                c2[9, 2] := 0.2429038300327729;
                c2[10, 1] := 0.8028211612831444e-1;
                c2[10, 2] := 0.1265329974009533;
              elseif order == 21 then
                alpha := 0.1887494014766075;
                c1[1] := 0.3718070668941645;
                c2[1, 1] := 0.1376151928386445;
                c2[1, 2] := 0.7364290859445481;
                c2[2, 1] := 0.1357438914390695;
                c2[2, 2] := 0.7150167318935022;
                c2[3, 1] := 0.1326398453462415;
                c2[3, 2] := 0.6798001808470175;
                c2[4, 1] := 0.1283231214897678;
                c2[4, 2] := 0.6314663440439816;
                c2[5, 1] := 0.1228169159777534;
                c2[5, 2] := 0.5709353626166905;
                c2[6, 1] := 0.1161406100773184;
                c2[6, 2] := 0.4993087153571335;
                c2[7, 1] := 0.1082959649233524;
                c2[7, 2] := 0.4177766148584385;
                c2[8, 1] := 0.9923596957485723e-1;
                c2[8, 2] := 0.3274257287232124;
                c2[9, 1] := 0.8877776108724853e-1;
                c2[9, 2] := 0.2287218166767916;
                c2[10, 1] := 0.7624076527736326e-1;
                c2[10, 2] := 0.1193423971506988;
              elseif order == 22 then
                alpha := 0.1842668221199706;
                c2[1, 1] := 0.1323053462701543;
                c2[1, 2] := 0.7262446126765204;
                c2[2, 1] := 0.1312121721769772;
                c2[2, 2] := 0.7134286088450949;
                c2[3, 1] := 0.1290330911166814;
                c2[3, 2] := 0.6880287870435514;
                c2[4, 1] := 0.1257817990372067;
                c2[4, 2] := 0.6505015800059301;
                c2[5, 1] := 0.1214765261983008;
                c2[5, 2] := 0.6015107185211451;
                c2[6, 1] := 0.1161365140967959;
                c2[6, 2] := 0.5418983553698413;
                c2[7, 1] := 0.1097755171533100;
                c2[7, 2] := 0.4726370779831614;
                c2[8, 1] := 0.1023889478519956;
                c2[8, 2] := 0.3947439506537486;
                c2[9, 1] := 0.9392485861253800e-1;
                c2[9, 2] := 0.3090996703083202;
                c2[10, 1] := 0.8420273775456455e-1;
                c2[10, 2] := 0.2159561978556017;
                c2[11, 1] := 0.7257600023938262e-1;
                c2[11, 2] := 0.1128633732721116;
              elseif order == 23 then
                alpha := 0.1800893554453722;
                c1[1] := 0.3565232673929280;
                c2[1, 1] := 0.1266275171652706;
                c2[1, 2] := 0.7072778066734162;
                c2[2, 1] := 0.1251865227648538;
                c2[2, 2] := 0.6900676345785905;
                c2[3, 1] := 0.1227944815236645;
                c2[3, 2] := 0.6617011100576023;
                c2[4, 1] := 0.1194647013077667;
                c2[4, 2] := 0.6226432315773119;
                c2[5, 1] := 0.1152132989252356;
                c2[5, 2] := 0.5735222810625359;
                c2[6, 1] := 0.1100558598478487;
                c2[6, 2] := 0.5151027978024605;
                c2[7, 1] := 0.1040013558214886;
                c2[7, 2] := 0.4482410942032739;
                c2[8, 1] := 0.9704014176512626e-1;
                c2[8, 2] := 0.3738049984631116;
                c2[9, 1] := 0.8911683905758054e-1;
                c2[9, 2] := 0.2925028692588410;
                c2[10, 1] := 0.8005438265072295e-1;
                c2[10, 2] := 0.2044134600278901;
                c2[11, 1] := 0.6923832296800832e-1;
                c2[11, 2] := 0.1069984887283394;
              elseif order == 24 then
                alpha := 0.1761838665838427;
                c2[1, 1] := 0.1220804912720132;
                c2[1, 2] := 0.6978026874156063;
                c2[2, 1] := 0.1212296762358897;
                c2[2, 2] := 0.6874139794926736;
                c2[3, 1] := 0.1195328372961027;
                c2[3, 2] := 0.6667954259551859;
                c2[4, 1] := 0.1169990987333593;
                c2[4, 2] := 0.6362602049901176;
                c2[5, 1] := 0.1136409040480130;
                c2[5, 2] := 0.5962662188435553;
                c2[6, 1] := 0.1094722001757955;
                c2[6, 2] := 0.5474001634109253;
                c2[7, 1] := 0.1045052832229087;
                c2[7, 2] := 0.4903523180249535;
                c2[8, 1] := 0.9874509806025907e-1;
                c2[8, 2] := 0.4258751523524645;
                c2[9, 1] := 0.9217799943472177e-1;
                c2[9, 2] := 0.3547079765396403;
                c2[10, 1] := 0.8474633796250476e-1;
                c2[10, 2] := 0.2774145482392767;
                c2[11, 1] := 0.7627722381240495e-1;
                c2[11, 2] := 0.1939329108084139;
                c2[12, 1] := 0.6618645465422745e-1;
                c2[12, 2] := 0.1016670147947242;
              elseif order == 25 then
                alpha := 0.1725220521949266;
                c1[1] := 0.3429735385896000;
                c2[1, 1] := 0.1172525033170618;
                c2[1, 2] := 0.6812327932576614;
                c2[2, 1] := 0.1161194585333535;
                c2[2, 2] := 0.6671566071153211;
                c2[3, 1] := 0.1142375145794466;
                c2[3, 2] := 0.6439167855053158;
                c2[4, 1] := 0.1116157454252308;
                c2[4, 2] := 0.6118378416180135;
                c2[5, 1] := 0.1082654809459177;
                c2[5, 2] := 0.5713609763370088;
                c2[6, 1] := 0.1041985674230918;
                c2[6, 2] := 0.5230289949762722;
                c2[7, 1] := 0.9942439308123559e-1;
                c2[7, 2] := 0.4674627926041906;
                c2[8, 1] := 0.9394453593830893e-1;
                c2[8, 2] := 0.4053226688298811;
                c2[9, 1] := 0.8774221237222533e-1;
                c2[9, 2] := 0.3372372276379071;
                c2[10, 1] := 0.8075839512216483e-1;
                c2[10, 2] := 0.2636485508005428;
                c2[11, 1] := 0.7282483286646764e-1;
                c2[11, 2] := 0.1843801345273085;
                c2[12, 1] := 0.6338571166846652e-1;
                c2[12, 2] := 0.9680153764737715e-1;
              elseif order == 26 then
                alpha := 0.1690795702796737;
                c2[1, 1] := 0.1133168695796030;
                c2[1, 2] := 0.6724297955493932;
                c2[2, 1] := 0.1126417845769961;
                c2[2, 2] := 0.6638709519790540;
                c2[3, 1] := 0.1112948749545606;
                c2[3, 2] := 0.6468652038763624;
                c2[4, 1] := 0.1092823986944244;
                c2[4, 2] := 0.6216337070799265;
                c2[5, 1] := 0.1066130386697976;
                c2[5, 2] := 0.5885011413992190;
                c2[6, 1] := 0.1032969057045413;
                c2[6, 2] := 0.5478864278297548;
                c2[7, 1] := 0.9934388184210715e-1;
                c2[7, 2] := 0.5002885306054287;
                c2[8, 1] := 0.9476081523436283e-1;
                c2[8, 2] := 0.4462644847551711;
                c2[9, 1] := 0.8954648464575577e-1;
                c2[9, 2] := 0.3863930785049522;
                c2[10, 1] := 0.8368166847159917e-1;
                c2[10, 2] := 0.3212074592527143;
                c2[11, 1] := 0.7710664731701103e-1;
                c2[11, 2] := 0.2510470347119383;
                c2[12, 1] := 0.6965807988411425e-1;
                c2[12, 2] := 0.1756419294111342;
                c2[13, 1] := 0.6080674930548766e-1;
                c2[13, 2] := 0.9234535279274277e-1;
              elseif order == 27 then
                alpha := 0.1658353543067995;
                c1[1] := 0.3308543720638957;
                c2[1, 1] := 0.1091618578712746;
                c2[1, 2] := 0.6577977071169651;
                c2[2, 1] := 0.1082549561495043;
                c2[2, 2] := 0.6461121666520275;
                c2[3, 1] := 0.1067479247890451;
                c2[3, 2] := 0.6267937760991321;
                c2[4, 1] := 0.1046471079537577;
                c2[4, 2] := 0.6000750116745808;
                c2[5, 1] := 0.1019605976654259;
                c2[5, 2] := 0.5662734183049320;
                c2[6, 1] := 0.9869726954433709e-1;
                c2[6, 2] := 0.5257827234948534;
                c2[7, 1] := 0.9486520934132483e-1;
                c2[7, 2] := 0.4790595019077763;
                c2[8, 1] := 0.9046906518775348e-1;
                c2[8, 2] := 0.4266025862147336;
                c2[9, 1] := 0.8550529998276152e-1;
                c2[9, 2] := 0.3689188223512328;
                c2[10, 1] := 0.7995282239306020e-1;
                c2[10, 2] := 0.3064589322702932;
                c2[11, 1] := 0.7375174596252882e-1;
                c2[11, 2] := 0.2394754504667310;
                c2[12, 1] := 0.6674377263329041e-1;
                c2[12, 2] := 0.1676223546666024;
                c2[13, 1] := 0.5842458027529246e-1;
                c2[13, 2] := 0.8825044329219431e-1;
              elseif order == 28 then
                alpha := 0.1627710671942929;
                c2[1, 1] := 0.1057232656113488;
                c2[1, 2] := 0.6496161226860832;
                c2[2, 1] := 0.1051786825724864;
                c2[2, 2] := 0.6424661279909941;
                c2[3, 1] := 0.1040917964935006;
                c2[3, 2] := 0.6282470268918791;
                c2[4, 1] := 0.1024670101953951;
                c2[4, 2] := 0.6071189030701136;
                c2[5, 1] := 0.1003105109519892;
                c2[5, 2] := 0.5793175191747016;
                c2[6, 1] := 0.9762969425430802e-1;
                c2[6, 2] := 0.5451486608855443;
                c2[7, 1] := 0.9443223803058400e-1;
                c2[7, 2] := 0.5049796971628137;
                c2[8, 1] := 0.9072460982036488e-1;
                c2[8, 2] := 0.4592270546572523;
                c2[9, 1] := 0.8650956423253280e-1;
                c2[9, 2] := 0.4083368605952977;
                c2[10, 1] := 0.8178165740374893e-1;
                c2[10, 2] := 0.3527525188880655;
                c2[11, 1] := 0.7651838885868020e-1;
                c2[11, 2] := 0.2928534570013572;
                c2[12, 1] := 0.7066010532447490e-1;
                c2[12, 2] := 0.2288185204390681;
                c2[13, 1] := 0.6405358596145789e-1;
                c2[13, 2] := 0.1602396172588190;
                c2[14, 1] := 0.5621780070227172e-1;
                c2[14, 2] := 0.8447589564915071e-1;
              elseif order == 29 then
                alpha := 0.1598706626277596;
                c1[1] := 0.3199314513011623;
                c2[1, 1] := 0.1021101032532951;
                c2[1, 2] := 0.6365758882240111;
                c2[2, 1] := 0.1013729819392774;
                c2[2, 2] := 0.6267495975736321;
                c2[3, 1] := 0.1001476175660628;
                c2[3, 2] := 0.6104876178266819;
                c2[4, 1] := 0.9843854640428316e-1;
                c2[4, 2] := 0.5879603139195113;
                c2[5, 1] := 0.9625164534591696e-1;
                c2[5, 2] := 0.5594012291050210;
                c2[6, 1] := 0.9359356960417668e-1;
                c2[6, 2] := 0.5251016150410664;
                c2[7, 1] := 0.9047086748649986e-1;
                c2[7, 2] := 0.4854024475590397;
                c2[8, 1] := 0.8688856407189167e-1;
                c2[8, 2] := 0.4406826457109709;
                c2[9, 1] := 0.8284779224069856e-1;
                c2[9, 2] := 0.3913408089298914;
                c2[10, 1] := 0.7834154620997181e-1;
                c2[10, 2] := 0.3377643999400627;
                c2[11, 1] := 0.7334628941928766e-1;
                c2[11, 2] := 0.2802710651919946;
                c2[12, 1] := 0.6780290487362146e-1;
                c2[12, 2] := 0.2189770008083379;
                c2[13, 1] := 0.6156321231528423e-1;
                c2[13, 2] := 0.1534235999306070;
                c2[14, 1] := 0.5416797446761512e-1;
                c2[14, 2] := 0.8098664736760292e-1;
              elseif order == 30 then
                alpha := 0.1571200296252450;
                c2[1, 1] := 0.9908074847842124e-1;
                c2[1, 2] := 0.6289618807831557;
                c2[2, 1] := 0.9863509708328196e-1;
                c2[2, 2] := 0.6229164525571278;
                c2[3, 1] := 0.9774542692037148e-1;
                c2[3, 2] := 0.6108853364240036;
                c2[4, 1] := 0.9641490581986484e-1;
                c2[4, 2] := 0.5929869253412513;
                c2[5, 1] := 0.9464802912225441e-1;
                c2[5, 2] := 0.5693960175547550;
                c2[6, 1] := 0.9245027206218041e-1;
                c2[6, 2] := 0.5403402396359503;
                c2[7, 1] := 0.8982754584112941e-1;
                c2[7, 2] := 0.5060948065875106;
                c2[8, 1] := 0.8678535291732599e-1;
                c2[8, 2] := 0.4669749797983789;
                c2[9, 1] := 0.8332744242052199e-1;
                c2[9, 2] := 0.4233249626334694;
                c2[10, 1] := 0.7945356393775309e-1;
                c2[10, 2] := 0.3755006094498054;
                c2[11, 1] := 0.7515543969833788e-1;
                c2[11, 2] := 0.3238400339292700;
                c2[12, 1] := 0.7040879901685638e-1;
                c2[12, 2] := 0.2686072427439079;
                c2[13, 1] := 0.6515528854010540e-1;
                c2[13, 2] := 0.2098650589782619;
                c2[14, 1] := 0.5925168237177876e-1;
                c2[14, 2] := 0.1471138832654873;
                c2[15, 1] := 0.5225913954211672e-1;
                c2[15, 2] := 0.7775248839507864e-1;
              elseif order == 31 then
                alpha := 0.1545067022920929;
                c1[1] := 0.3100206996451866;
                c2[1, 1] := 0.9591020358831668e-1;
                c2[1, 2] := 0.6172474793293396;
                c2[2, 1] := 0.9530301275601203e-1;
                c2[2, 2] := 0.6088916323460413;
                c2[3, 1] := 0.9429332655402368e-1;
                c2[3, 2] := 0.5950511595503025;
                c2[4, 1] := 0.9288445429894548e-1;
                c2[4, 2] := 0.5758534119053522;
                c2[5, 1] := 0.9108073420087422e-1;
                c2[5, 2] := 0.5514734636081183;
                c2[6, 1] := 0.8888719137536870e-1;
                c2[6, 2] := 0.5221306199481831;
                c2[7, 1] := 0.8630901440239650e-1;
                c2[7, 2] := 0.4880834248148061;
                c2[8, 1] := 0.8335074993373294e-1;
                c2[8, 2] := 0.4496225358496770;
                c2[9, 1] := 0.8001502494376102e-1;
                c2[9, 2] := 0.4070602306679052;
                c2[10, 1] := 0.7630041338037624e-1;
                c2[10, 2] := 0.3607139804818122;
                c2[11, 1] := 0.7219760885744920e-1;
                c2[11, 2] := 0.3108783301229550;
                c2[12, 1] := 0.6768185077153345e-1;
                c2[12, 2] := 0.2577706252514497;
                c2[13, 1] := 0.6269571766328638e-1;
                c2[13, 2] := 0.2014081375889921;
                c2[14, 1] := 0.5710081766945065e-1;
                c2[14, 2] := 0.1412581515841926;
                c2[15, 1] := 0.5047740914807019e-1;
                c2[15, 2] := 0.7474725873250158e-1;
              elseif order == 32 then
                alpha := 0.1520196210848210;
                c2[1, 1] := 0.9322163554339406e-1;
                c2[1, 2] := 0.6101488690506050;
                c2[2, 1] := 0.9285233997694042e-1;
                c2[2, 2] := 0.6049832320721264;
                c2[3, 1] := 0.9211494244473163e-1;
                c2[3, 2] := 0.5946969295569034;
                c2[4, 1] := 0.9101176786042449e-1;
                c2[4, 2] := 0.5793791854364477;
                c2[5, 1] := 0.8954614071360517e-1;
                c2[5, 2] := 0.5591619969234026;
                c2[6, 1] := 0.8772216763680164e-1;
                c2[6, 2] := 0.5342177994699602;
                c2[7, 1] := 0.8554440426912734e-1;
                c2[7, 2] := 0.5047560942986598;
                c2[8, 1] := 0.8301735302045588e-1;
                c2[8, 2] := 0.4710187048140929;
                c2[9, 1] := 0.8014469519188161e-1;
                c2[9, 2] := 0.4332730387207936;
                c2[10, 1] := 0.7692807528893225e-1;
                c2[10, 2] := 0.3918021436411035;
                c2[11, 1] := 0.7336507157284898e-1;
                c2[11, 2] := 0.3468890521471250;
                c2[12, 1] := 0.6944555312763458e-1;
                c2[12, 2] := 0.2987898029050460;
                c2[13, 1] := 0.6514446669420571e-1;
                c2[13, 2] := 0.2476810747407199;
                c2[14, 1] := 0.6040544477732702e-1;
                c2[14, 2] := 0.1935412053397663;
                c2[15, 1] := 0.5509478650672775e-1;
                c2[15, 2] := 0.1358108994174911;
                c2[16, 1] := 0.4881064725720192e-1;
                c2[16, 2] := 0.7194819894416505e-1;
              elseif order == 33 then
                alpha := 0.1496489351138032;
                c1[1] := 0.3009752799176432;
                c2[1, 1] := 0.9041725460994505e-1;
                c2[1, 2] := 0.5995521047364046;
                c2[2, 1] := 0.8991117804113002e-1;
                c2[2, 2] := 0.5923764112099496;
                c2[3, 1] := 0.8906941547422532e-1;
                c2[3, 2] := 0.5804822013853129;
                c2[4, 1] := 0.8789442491445575e-1;
                c2[4, 2] := 0.5639663528946501;
                c2[5, 1] := 0.8638945831033775e-1;
                c2[5, 2] := 0.5429623519607796;
                c2[6, 1] := 0.8455834602616358e-1;
                c2[6, 2] := 0.5176379938389326;
                c2[7, 1] := 0.8240517431382334e-1;
                c2[7, 2] := 0.4881921474066189;
                c2[8, 1] := 0.7993380417355076e-1;
                c2[8, 2] := 0.4548502528082586;
                c2[9, 1] := 0.7714713890732801e-1;
                c2[9, 2] := 0.4178579388038483;
                c2[10, 1] := 0.7404596598181127e-1;
                c2[10, 2] := 0.3774715722484659;
                c2[11, 1] := 0.7062702339160462e-1;
                c2[11, 2] := 0.3339432938810453;
                c2[12, 1] := 0.6687952672391507e-1;
                c2[12, 2] := 0.2874950693388235;
                c2[13, 1] := 0.6277828912909767e-1;
                c2[13, 2] := 0.2382680702894708;
                c2[14, 1] := 0.5826808305383988e-1;
                c2[14, 2] := 0.1862073169968455;
                c2[15, 1] := 0.5321974125363517e-1;
                c2[15, 2] := 0.1307323751236313;
                c2[16, 1] := 0.4724820282032780e-1;
                c2[16, 2] := 0.6933542082177094e-1;
              elseif order == 34 then
                alpha := 0.1473858373968463;
                c2[1, 1] := 0.8801537152275983e-1;
                c2[1, 2] := 0.5929204288972172;
                c2[2, 1] := 0.8770594341007476e-1;
                c2[2, 2] := 0.5884653382247518;
                c2[3, 1] := 0.8708797598072095e-1;
                c2[3, 2] := 0.5795895850253119;
                c2[4, 1] := 0.8616320590689187e-1;
                c2[4, 2] := 0.5663615383647170;
                c2[5, 1] := 0.8493413175570858e-1;
                c2[5, 2] := 0.5488825092350877;
                c2[6, 1] := 0.8340387368687513e-1;
                c2[6, 2] := 0.5272851839324592;
                c2[7, 1] := 0.8157596213131521e-1;
                c2[7, 2] := 0.5017313864372913;
                c2[8, 1] := 0.7945402670834270e-1;
                c2[8, 2] := 0.4724089864574216;
                c2[9, 1] := 0.7704133559556429e-1;
                c2[9, 2] := 0.4395276256463053;
                c2[10, 1] := 0.7434009635219704e-1;
                c2[10, 2] := 0.4033126590648964;
                c2[11, 1] := 0.7135035113853376e-1;
                c2[11, 2] := 0.3639961488919042;
                c2[12, 1] := 0.6806813160738834e-1;
                c2[12, 2] := 0.3218025212900124;
                c2[13, 1] := 0.6448214312000864e-1;
                c2[13, 2] := 0.2769235521088158;
                c2[14, 1] := 0.6056719318430530e-1;
                c2[14, 2] := 0.2294693573271038;
                c2[15, 1] := 0.5626925196925040e-1;
                c2[15, 2] := 0.1793564218840015;
                c2[16, 1] := 0.5146352031547277e-1;
                c2[16, 2] := 0.1259877129326412;
                c2[17, 1] := 0.4578069074410591e-1;
                c2[17, 2] := 0.6689147319568768e-1;
              elseif order == 35 then
                alpha := 0.1452224267615486;
                c1[1] := 0.2926764667564367;
                c2[1, 1] := 0.8551731299267280e-1;
                c2[1, 2] := 0.5832758214629523;
                c2[2, 1] := 0.8509109732853060e-1;
                c2[2, 2] := 0.5770596582643844;
                c2[3, 1] := 0.8438201446671953e-1;
                c2[3, 2] := 0.5667497616665494;
                c2[4, 1] := 0.8339191981579831e-1;
                c2[4, 2] := 0.5524209816238369;
                c2[5, 1] := 0.8212328610083385e-1;
                c2[5, 2] := 0.5341766459916322;
                c2[6, 1] := 0.8057906332198853e-1;
                c2[6, 2] := 0.5121470053512750;
                c2[7, 1] := 0.7876247299954955e-1;
                c2[7, 2] := 0.4864870722254752;
                c2[8, 1] := 0.7667670879950268e-1;
                c2[8, 2] := 0.4573736721705665;
                c2[9, 1] := 0.7432449556218945e-1;
                c2[9, 2] := 0.4250013835198991;
                c2[10, 1] := 0.7170742126011575e-1;
                c2[10, 2] := 0.3895767735915445;
                c2[11, 1] := 0.6882488171701314e-1;
                c2[11, 2] := 0.3513097926737368;
                c2[12, 1] := 0.6567231746957568e-1;
                c2[12, 2] := 0.3103999917596611;
                c2[13, 1] := 0.6223804362223595e-1;
                c2[13, 2] := 0.2670123611280899;
                c2[14, 1] := 0.5849696460782910e-1;
                c2[14, 2] := 0.2212298104867592;
                c2[15, 1] := 0.5439628409499822e-1;
                c2[15, 2] := 0.1729443731341637;
                c2[16, 1] := 0.4981540179136920e-1;
                c2[16, 2] := 0.1215462157134930;
                c2[17, 1] := 0.4439981033536435e-1;
                c2[17, 2] := 0.6460098363520967e-1;
              elseif order == 36 then
                alpha := 0.1431515914458580;
                c2[1, 1] := 0.8335881847130301e-1;
                c2[1, 2] := 0.5770670512160201;
                c2[2, 1] := 0.8309698922852212e-1;
                c2[2, 2] := 0.5731929100172432;
                c2[3, 1] := 0.8257400347039723e-1;
                c2[3, 2] := 0.5654713811993058;
                c2[4, 1] := 0.8179117911600136e-1;
                c2[4, 2] := 0.5539556343603020;
                c2[5, 1] := 0.8075042173126963e-1;
                c2[5, 2] := 0.5387245649546684;
                c2[6, 1] := 0.7945413151258206e-1;
                c2[6, 2] := 0.5198817177723069;
                c2[7, 1] := 0.7790506514288866e-1;
                c2[7, 2] := 0.4975537629595409;
                c2[8, 1] := 0.7610613635339480e-1;
                c2[8, 2] := 0.4718884193866789;
                c2[9, 1] := 0.7406012816626425e-1;
                c2[9, 2] := 0.4430516443136726;
                c2[10, 1] := 0.7176927060205631e-1;
                c2[10, 2] := 0.4112237708115829;
                c2[11, 1] := 0.6923460172504251e-1;
                c2[11, 2] := 0.3765940116389730;
                c2[12, 1] := 0.6645495833489556e-1;
                c2[12, 2] := 0.3393522147815403;
                c2[13, 1] := 0.6342528888937094e-1;
                c2[13, 2] := 0.2996755899575573;
                c2[14, 1] := 0.6013361864949449e-1;
                c2[14, 2] := 0.2577053294053830;
                c2[15, 1] := 0.5655503081322404e-1;
                c2[15, 2] := 0.2135004731531631;
                c2[16, 1] := 0.5263798119559069e-1;
                c2[16, 2] := 0.1669320999865636;
                c2[17, 1] := 0.4826589873626196e-1;
                c2[17, 2] := 0.1173807590715484;
                c2[18, 1] := 0.4309819397289806e-1;
                c2[18, 2] := 0.6245036108880222e-1;
              elseif order == 37 then
                alpha := 0.1411669104782917;
                c1[1] := 0.2850271036215707;
                c2[1, 1] := 0.8111958235023328e-1;
                c2[1, 2] := 0.5682412610563970;
                c2[2, 1] := 0.8075727567979578e-1;
                c2[2, 2] := 0.5628142923227016;
                c2[3, 1] := 0.8015440554413301e-1;
                c2[3, 2] := 0.5538087696879930;
                c2[4, 1] := 0.7931239302677386e-1;
                c2[4, 2] := 0.5412833323304460;
                c2[5, 1] := 0.7823314328639347e-1;
                c2[5, 2] := 0.5253190555393968;
                c2[6, 1] := 0.7691895211595101e-1;
                c2[6, 2] := 0.5060183741977191;
                c2[7, 1] := 0.7537237072011853e-1;
                c2[7, 2] := 0.4835036020049034;
                c2[8, 1] := 0.7359601294804538e-1;
                c2[8, 2] := 0.4579149413954837;
                c2[9, 1] := 0.7159227884849299e-1;
                c2[9, 2] := 0.4294078049978829;
                c2[10, 1] := 0.6936295002846032e-1;
                c2[10, 2] := 0.3981491350382047;
                c2[11, 1] := 0.6690857785828917e-1;
                c2[11, 2] := 0.3643121502867948;
                c2[12, 1] := 0.6422751692085542e-1;
                c2[12, 2] := 0.3280684291406284;
                c2[13, 1] := 0.6131430866206096e-1;
                c2[13, 2] := 0.2895750997170303;
                c2[14, 1] := 0.5815677249570920e-1;
                c2[14, 2] := 0.2489521814805720;
                c2[15, 1] := 0.5473023527947980e-1;
                c2[15, 2] := 0.2062377435955363;
                c2[16, 1] := 0.5098441033167034e-1;
                c2[16, 2] := 0.1612849131645336;
                c2[17, 1] := 0.4680658811093562e-1;
                c2[17, 2] := 0.1134672937045305;
                c2[18, 1] := 0.4186928031694695e-1;
                c2[18, 2] := 0.6042754777339966e-1;
              elseif order == 38 then
                alpha := 0.1392625697140030;
                c2[1, 1] := 0.7916943373658329e-1;
                c2[1, 2] := 0.5624158631591745;
                c2[2, 1] := 0.7894592250257840e-1;
                c2[2, 2] := 0.5590219398777304;
                c2[3, 1] := 0.7849941672384930e-1;
                c2[3, 2] := 0.5522551628416841;
                c2[4, 1] := 0.7783093084875645e-1;
                c2[4, 2] := 0.5421574325808380;
                c2[5, 1] := 0.7694193770482690e-1;
                c2[5, 2] := 0.5287909941093643;
                c2[6, 1] := 0.7583430534712885e-1;
                c2[6, 2] := 0.5122376814029880;
                c2[7, 1] := 0.7451020436122948e-1;
                c2[7, 2] := 0.4925978555548549;
                c2[8, 1] := 0.7297197617673508e-1;
                c2[8, 2] := 0.4699889739625235;
                c2[9, 1] := 0.7122194706992953e-1;
                c2[9, 2] := 0.4445436860615774;
                c2[10, 1] := 0.6926216260386816e-1;
                c2[10, 2] := 0.4164072786327193;
                c2[11, 1] := 0.6709399961255503e-1;
                c2[11, 2] := 0.3857341621868851;
                c2[12, 1] := 0.6471757977022456e-1;
                c2[12, 2] := 0.3526828388476838;
                c2[13, 1] := 0.6213084287116965e-1;
                c2[13, 2] := 0.3174082831364342;
                c2[14, 1] := 0.5932799638550641e-1;
                c2[14, 2] := 0.2800495563550299;
                c2[15, 1] := 0.5629672408524944e-1;
                c2[15, 2] := 0.2407078154782509;
                c2[16, 1] := 0.5301264751544952e-1;
                c2[16, 2] := 0.1994026830553859;
                c2[17, 1] := 0.4942673259817896e-1;
                c2[17, 2] := 0.1559719194038917;
                c2[18, 1] := 0.4542996716979947e-1;
                c2[18, 2] := 0.1097844277878470;
                c2[19, 1] := 0.4070720755433961e-1;
                c2[19, 2] := 0.5852181110523043e-1;
              elseif order == 39 then
                alpha := 0.1374332900196804;
                c1[1] := 0.2779468246419593;
                c2[1, 1] := 0.7715084161825772e-1;
                c2[1, 2] := 0.5543001331300056;
                c2[2, 1] := 0.7684028301163326e-1;
                c2[2, 2] := 0.5495289890712267;
                c2[3, 1] := 0.7632343924866024e-1;
                c2[3, 2] := 0.5416083298429741;
                c2[4, 1] := 0.7560141319808483e-1;
                c2[4, 2] := 0.5305846713929198;
                c2[5, 1] := 0.7467569064745969e-1;
                c2[5, 2] := 0.5165224112570647;
                c2[6, 1] := 0.7354807648551346e-1;
                c2[6, 2] := 0.4995030679271456;
                c2[7, 1] := 0.7222060351121389e-1;
                c2[7, 2] := 0.4796242430956156;
                c2[8, 1] := 0.7069540462458585e-1;
                c2[8, 2] := 0.4569982440368368;
                c2[9, 1] := 0.6897453353492381e-1;
                c2[9, 2] := 0.4317502624832354;
                c2[10, 1] := 0.6705970959388781e-1;
                c2[10, 2] := 0.4040159353969854;
                c2[11, 1] := 0.6495194541066725e-1;
                c2[11, 2] := 0.3739379843169939;
                c2[12, 1] := 0.6265098412417610e-1;
                c2[12, 2] := 0.3416613843816217;
                c2[13, 1] := 0.6015440984955930e-1;
                c2[13, 2] := 0.3073260166338746;
                c2[14, 1] := 0.5745615876877304e-1;
                c2[14, 2] := 0.2710546723961181;
                c2[15, 1] := 0.5454383762391338e-1;
                c2[15, 2] := 0.2329316824061170;
                c2[16, 1] := 0.5139340231935751e-1;
                c2[16, 2] := 0.1929604256043231;
                c2[17, 1] := 0.4795705862458131e-1;
                c2[17, 2] := 0.1509655259246037;
                c2[18, 1] := 0.4412933231935506e-1;
                c2[18, 2] := 0.1063130748962878;
                c2[19, 1] := 0.3960672309405603e-1;
                c2[19, 2] := 0.5672356837211527e-1;
              elseif order == 40 then
                alpha := 0.1356742655825434;
                c2[1, 1] := 0.7538038374294594e-1;
                c2[1, 2] := 0.5488228264329617;
                c2[2, 1] := 0.7518806529402738e-1;
                c2[2, 2] := 0.5458297722483311;
                c2[3, 1] := 0.7480383050347119e-1;
                c2[3, 2] := 0.5398604576730540;
                c2[4, 1] := 0.7422847031965465e-1;
                c2[4, 2] := 0.5309482987446206;
                c2[5, 1] := 0.7346313704205006e-1;
                c2[5, 2] := 0.5191429845322307;
                c2[6, 1] := 0.7250930053201402e-1;
                c2[6, 2] := 0.5045099368431007;
                c2[7, 1] := 0.7136868456879621e-1;
                c2[7, 2] := 0.4871295553902607;
                c2[8, 1] := 0.7004317764946634e-1;
                c2[8, 2] := 0.4670962098860498;
                c2[9, 1] := 0.6853470921527828e-1;
                c2[9, 2] := 0.4445169164956202;
                c2[10, 1] := 0.6684507689945471e-1;
                c2[10, 2] := 0.4195095960479698;
                c2[11, 1] := 0.6497570123412630e-1;
                c2[11, 2] := 0.3922007419030645;
                c2[12, 1] := 0.6292726794917847e-1;
                c2[12, 2] := 0.3627221993494397;
                c2[13, 1] := 0.6069918741663154e-1;
                c2[13, 2] := 0.3312065181294388;
                c2[14, 1] := 0.5828873983769410e-1;
                c2[14, 2] := 0.2977798532686911;
                c2[15, 1] := 0.5568964389813015e-1;
                c2[15, 2] := 0.2625503293999835;
                c2[16, 1] := 0.5288947816690705e-1;
                c2[16, 2] := 0.2255872486520188;
                c2[17, 1] := 0.4986456327645859e-1;
                c2[17, 2] := 0.1868796731919594;
                c2[18, 1] := 0.4656832613054458e-1;
                c2[18, 2] := 0.1462410193532463;
                c2[19, 1] := 0.4289867647614935e-1;
                c2[19, 2] := 0.1030361558710747;
                c2[20, 1] := 0.3856310684054106e-1;
                c2[20, 2] := 0.5502423832293889e-1;
              elseif order == 41 then
                alpha := 0.1339811106984253;
                c1[1] := 0.2713685065531391;
                c2[1, 1] := 0.7355140275160984e-1;
                c2[1, 2] := 0.5413274778282860;
                c2[2, 1] := 0.7328319082267173e-1;
                c2[2, 2] := 0.5371064088294270;
                c2[3, 1] := 0.7283676160772547e-1;
                c2[3, 2] := 0.5300963437270770;
                c2[4, 1] := 0.7221298133014343e-1;
                c2[4, 2] := 0.5203345998371490;
                c2[5, 1] := 0.7141302173623395e-1;
                c2[5, 2] := 0.5078728971879841;
                c2[6, 1] := 0.7043831559982149e-1;
                c2[6, 2] := 0.4927768111819803;
                c2[7, 1] := 0.6929049381827268e-1;
                c2[7, 2] := 0.4751250308594139;
                c2[8, 1] := 0.6797129849758392e-1;
                c2[8, 2] := 0.4550083840638406;
                c2[9, 1] := 0.6648246325101609e-1;
                c2[9, 2] := 0.4325285673076087;
                c2[10, 1] := 0.6482554675958526e-1;
                c2[10, 2] := 0.4077964789091151;
                c2[11, 1] := 0.6300169683004558e-1;
                c2[11, 2] := 0.3809299858742483;
                c2[12, 1] := 0.6101130648543355e-1;
                c2[12, 2] := 0.3520508315700898;
                c2[13, 1] := 0.5885349417435808e-1;
                c2[13, 2] := 0.3212801560701271;
                c2[14, 1] := 0.5652528148656809e-1;
                c2[14, 2] := 0.2887316252774887;
                c2[15, 1] := 0.5402021575818373e-1;
                c2[15, 2] := 0.2545001287790888;
                c2[16, 1] := 0.5132588802608274e-1;
                c2[16, 2] := 0.2186415296842951;
                c2[17, 1] := 0.4841900639702602e-1;
                c2[17, 2] := 0.1811322622296060;
                c2[18, 1] := 0.4525419574485134e-1;
                c2[18, 2] := 0.1417762065404688;
                c2[19, 1] := 0.4173260173087802e-1;
                c2[19, 2] := 0.9993834530966510e-1;
                c2[20, 1] := 0.3757210572966463e-1;
                c2[20, 2] := 0.5341611499960143e-1;
              else
                .Modelica.Utilities.Streams.error("Input argument order (= " + String(order) + ") of Bessel filter is not in the range 1..41");
              end if;
            end BesselBaseCoefficients;

            function toHighestPowerOne
              extends Modelica.Icons.Function;
              input Real[:] den1;
              input Real[:, 2] den2;
              output Real[size(den1, 1)] cr;
              output Real[size(den2, 1)] c0;
              output Real[size(den2, 1)] c1;
            algorithm
              for i in 1:size(den1, 1) loop
                cr[i] := 1 / den1[i];
              end for;
              for i in 1:size(den2, 1) loop
                c1[i] := den2[i, 2] / den2[i, 1];
                c0[i] := 1 / den2[i, 1];
              end for;
            end toHighestPowerOne;

            function normalizationFactor
              extends .Modelica.Icons.Function;
              input Real[:] c1;
              input Real[:, 2] c2;
              output Real alpha;
            protected
              Real alpha_min;
              Real alpha_max;

              function normalizationResidue
                extends .Modelica.Icons.Function;
                input Real[:] c1;
                input Real[:, 2] c2;
                input Real alpha;
                output Real residue;
              protected
                constant Real beta = 10 ^ (-3 / 20);
                Real cc1;
                Real cc2;
                Real p;
                Real alpha2 = alpha * alpha;
                Real alpha4 = alpha2 * alpha2;
                Real A2 = 1.0;
              algorithm
                assert(size(c1, 1) <= 1, "Internal error 2 (should not occur)");
                if size(c1, 1) == 1 then
                  cc1 := c1[1] * c1[1];
                  p := 1 + cc1 * alpha2;
                  A2 := A2 * p;
                else
                end if;
                for i in 1:size(c2, 1) loop
                  cc1 := c2[i, 2] * c2[i, 2] - 2 * c2[i, 1];
                  cc2 := c2[i, 1] * c2[i, 1];
                  p := 1 + cc1 * alpha2 + cc2 * alpha4;
                  A2 := A2 * p;
                end for;
                residue := 1 / sqrt(A2) - beta;
              end normalizationResidue;

              function findInterval
                extends .Modelica.Icons.Function;
                input Real[:] c1;
                input Real[:, 2] c2;
                output Real alpha_min;
                output Real alpha_max;
              protected
                Real alpha = 1.0;
                Real residue;
              algorithm
                alpha_min := 0;
                residue := normalizationResidue(c1, c2, alpha);
                if residue < 0 then
                  alpha_max := alpha;
                else
                  while residue >= 0 loop
                    alpha := 1.1 * alpha;
                    residue := normalizationResidue(c1, c2, alpha);
                  end while;
                  alpha_max := alpha;
                end if;
              end findInterval;

              function solveOneNonlinearEquation
                extends .Modelica.Icons.Function;
                input Real[:] c1;
                input Real[:, 2] c2;
                input Real u_min;
                input Real u_max;
                input Real tolerance = 100 * .Modelica.Constants.eps;
                output Real u;
              protected
                constant Real eps = .Modelica.Constants.eps;
                Real a = u_min;
                Real b = u_max;
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
                fa := normalizationResidue(c1, c2, u_min);
                fb := normalizationResidue(c1, c2, u_max);
                fc := fb;
                if fa > 0.0 and fb > 0.0 or fa < 0.0 and fb < 0.0 then
                  .Modelica.Utilities.Streams.error("The arguments u_min and u_max to solveOneNonlinearEquation(..)\n" + "do not bracket the root of the single non-linear equation:\n" + "  u_min  = " + String(u_min) + "\n" + "  u_max  = " + String(u_max) + "\n" + "  fa = f(u_min) = " + String(fa) + "\n" + "  fb = f(u_max) = " + String(fb) + "\n" + "fa and fb must have opposite sign which is not the case");
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
                  tol := 2 * eps * abs(b) + tolerance;
                  m := (c - b) / 2;
                  if abs(m) <= tol or fb == 0.0 then
                    found := true;
                    u := b;
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
                    fb := normalizationResidue(c1, c2, b);
                    if fb > 0 and fc > 0 or fb < 0 and fc < 0 then
                      c := a;
                      fc := fa;
                      e := b - a;
                      d := e;
                    else
                    end if;
                  end if;
                end while;
              end solveOneNonlinearEquation;
            algorithm
              (alpha_min, alpha_max) := findInterval(c1, c2);
              alpha := solveOneNonlinearEquation(c1, c2, alpha_min, alpha_max);
            end normalizationFactor;

            encapsulated function bandPassAlpha
              extends .Modelica.Icons.Function;
              input Real a;
              input Real b;
              input .Modelica.SIunits.AngularVelocity w;
              output Real alpha;
            protected
              Real alpha_min;
              Real alpha_max;
              Real z_min;
              Real z_max;
              Real z;

              function residue
                extends .Modelica.Icons.Function;
                input Real a;
                input Real b;
                input Real w;
                input Real z;
                output Real res;
              algorithm
                res := z ^ 2 + (a * w * z / (1 + z)) ^ 2 - (2 + b * w ^ 2) * z + 1;
              end residue;

              function solveOneNonlinearEquation
                extends .Modelica.Icons.Function;
                input Real aa;
                input Real bb;
                input Real ww;
                input Real u_min;
                input Real u_max;
                input Real tolerance = 100 * .Modelica.Constants.eps;
                output Real u;
              protected
                constant Real eps = .Modelica.Constants.eps;
                Real a = u_min;
                Real b = u_max;
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
                fa := residue(aa, bb, ww, u_min);
                fb := residue(aa, bb, ww, u_max);
                fc := fb;
                if fa > 0.0 and fb > 0.0 or fa < 0.0 and fb < 0.0 then
                  .Modelica.Utilities.Streams.error("The arguments u_min and u_max to solveOneNonlinearEquation(..)\n" + "do not bracket the root of the single non-linear equation:\n" + "  u_min  = " + String(u_min) + "\n" + "  u_max  = " + String(u_max) + "\n" + "  fa = f(u_min) = " + String(fa) + "\n" + "  fb = f(u_max) = " + String(fb) + "\n" + "fa and fb must have opposite sign which is not the case");
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
                  tol := 2 * eps * abs(b) + tolerance;
                  m := (c - b) / 2;
                  if abs(m) <= tol or fb == 0.0 then
                    found := true;
                    u := b;
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
                    fb := residue(aa, bb, ww, b);
                    if fb > 0 and fc > 0 or fb < 0 and fc < 0 then
                      c := a;
                      fc := fa;
                      e := b - a;
                      d := e;
                    else
                    end if;
                  end if;
                end while;
              end solveOneNonlinearEquation;
            algorithm
              assert(a ^ 2 / 4 - b <= 0, "Band pass transformation cannot be computed");
              z := solveOneNonlinearEquation(a, b, w, 0, 1);
              alpha := sqrt(z);
            end bandPassAlpha;
          end Utilities;
        end Filter;
      end Internal;
    end Continuous;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real;
      connector RealOutput = output Real;
      connector BooleanInput = input Boolean;
      connector BooleanOutput = output Boolean;

      partial block SO
        extends Modelica.Blocks.Icons.Block;
        RealOutput y;
      end SO;

      partial block MO
        extends Modelica.Blocks.Icons.Block;
        parameter Integer nout(min = 1) = 1;
        RealOutput[nout] y;
      end MO;

      partial block SISO
        extends Modelica.Blocks.Icons.Block;
        RealInput u;
        RealOutput y;
      end SISO;

      partial block partialBooleanSISO
        extends Modelica.Blocks.Icons.PartialBooleanBlock;
        Blocks.Interfaces.BooleanInput u;
        Blocks.Interfaces.BooleanOutput y;
      end partialBooleanSISO;

      partial block partialBooleanSI
        extends Modelica.Blocks.Icons.PartialBooleanBlock;
        Blocks.Interfaces.BooleanInput u;
      end partialBooleanSI;
    end Interfaces;

    package Logical
      extends Modelica.Icons.Package;

      block Not
        extends Blocks.Interfaces.partialBooleanSISO;
      equation
        y = not u;
      end Not;

      block Hysteresis
        extends Modelica.Blocks.Icons.PartialBooleanBlock;
        parameter Real uLow(start = 0);
        parameter Real uHigh(start = 1);
        parameter Boolean pre_y_start = false;
        Blocks.Interfaces.RealInput u;
        Blocks.Interfaces.BooleanOutput y;
      initial equation
        pre(y) = pre_y_start;
      equation
        y = u > uHigh or pre(y) and u >= uLow;
      end Hysteresis;
    end Logical;

    package Math
      extends Modelica.Icons.Package;

      block BooleanToReal
        extends .Modelica.Blocks.Interfaces.partialBooleanSI;
        parameter Real realTrue = 1.0;
        parameter Real realFalse = 0.0;
        Blocks.Interfaces.RealOutput y;
      equation
        y = if u then realTrue else realFalse;
      end BooleanToReal;
    end Math;

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

      block CombiTimeTable
        extends Modelica.Blocks.Interfaces.MO(final nout = max([size(columns, 1); size(offset, 1)]));
        parameter Boolean tableOnFile = false;
        parameter Real[:, :] table = fill(0.0, 0, 2);
        parameter String tableName = "NoName";
        parameter String fileName = "NoName";
        parameter Boolean verboseRead = true;
        parameter Integer[:] columns = 2:size(table, 2);
        parameter Modelica.Blocks.Types.Smoothness smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments;
        parameter Modelica.Blocks.Types.Extrapolation extrapolation = Modelica.Blocks.Types.Extrapolation.LastTwoPoints;
        parameter Real[:] offset = {0};
        parameter Modelica.SIunits.Time startTime = 0;
        final parameter Modelica.SIunits.Time t_min(fixed = false);
        final parameter Modelica.SIunits.Time t_max(fixed = false);
      protected
        final parameter Real[nout] p_offset = if size(offset, 1) == 1 then ones(nout) * offset[1] else offset;
        Modelica.Blocks.Types.ExternalCombiTimeTable tableID = Modelica.Blocks.Types.ExternalCombiTimeTable(if tableOnFile then tableName else "NoName", if tableOnFile and fileName <> "NoName" and not Modelica.Utilities.Strings.isEmpty(fileName) then fileName else "NoName", table, startTime, columns, smoothness, extrapolation);
        discrete Modelica.SIunits.Time nextTimeEvent(start = 0, fixed = true);
        parameter Real tableOnFileRead(fixed = false);

        function readTableData
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Boolean forceRead = false;
          output Real readSuccess;
          input Boolean verboseRead;
          external "C" readSuccess = ModelicaStandardTables_CombiTimeTable_read(tableID, forceRead, verboseRead) annotation(Library = {"ModelicaStandardTables"});
        end readTableData;

        function getTableValue
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Integer icol;
          input Modelica.SIunits.Time timeIn;
          discrete input Modelica.SIunits.Time nextTimeEvent;
          discrete input Modelica.SIunits.Time pre_nextTimeEvent;
          input Real tableAvailable annotation(__OpenModelica_UnusedVariable = true);
          output Real y;
          external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent) annotation(Library = {"ModelicaStandardTables"}, derivative(noDerivative = nextTimeEvent, noDerivative = pre_nextTimeEvent, noDerivative = tableAvailable) = getDerTableValue);
        end getTableValue;

        function getTableValueNoDer
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Integer icol;
          input Modelica.SIunits.Time timeIn;
          discrete input Modelica.SIunits.Time nextTimeEvent;
          discrete input Modelica.SIunits.Time pre_nextTimeEvent;
          input Real tableAvailable annotation(__OpenModelica_UnusedVariable = true);
          output Real y;
          external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent) annotation(Library = {"ModelicaStandardTables"});
        end getTableValueNoDer;

        function getDerTableValue
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Integer icol;
          input Modelica.SIunits.Time timeIn;
          discrete input Modelica.SIunits.Time nextTimeEvent;
          discrete input Modelica.SIunits.Time pre_nextTimeEvent;
          input Real tableAvailable annotation(__OpenModelica_UnusedVariable = true);
          input Real der_timeIn;
          output Real der_y;
          external "C" der_y = ModelicaStandardTables_CombiTimeTable_getDerValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent, der_timeIn) annotation(Library = {"ModelicaStandardTables"});
        end getDerTableValue;

        function getTableTimeTmin
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Real tableAvailable annotation(__OpenModelica_UnusedVariable = true);
          output Modelica.SIunits.Time timeMin;
          external "C" timeMin = ModelicaStandardTables_CombiTimeTable_minimumTime(tableID) annotation(Library = {"ModelicaStandardTables"});
        end getTableTimeTmin;

        function getTableTimeTmax
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Real tableAvailable annotation(__OpenModelica_UnusedVariable = true);
          output Modelica.SIunits.Time timeMax;
          external "C" timeMax = ModelicaStandardTables_CombiTimeTable_maximumTime(tableID) annotation(Library = {"ModelicaStandardTables"});
        end getTableTimeTmax;

        function getNextTimeEvent
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Modelica.SIunits.Time timeIn;
          input Real tableAvailable annotation(__OpenModelica_UnusedVariable = true);
          output Modelica.SIunits.Time nextTimeEvent;
          external "C" nextTimeEvent = ModelicaStandardTables_CombiTimeTable_nextTimeEvent(tableID, timeIn) annotation(Library = {"ModelicaStandardTables"});
        end getNextTimeEvent;
      initial algorithm
        if tableOnFile then
          tableOnFileRead := readTableData(tableID, false, verboseRead);
        else
          tableOnFileRead := 1.;
        end if;
        t_min := getTableTimeTmin(tableID, tableOnFileRead);
        t_max := getTableTimeTmax(tableID, tableOnFileRead);
      equation
        if tableOnFile then
          assert(tableName <> "NoName", "tableOnFile = true and no table name given");
        else
          assert(size(table, 1) > 0 and size(table, 2) > 0, "tableOnFile = false and parameter table is an empty matrix");
        end if;
        when {time >= pre(nextTimeEvent), initial()} then
          nextTimeEvent = getNextTimeEvent(tableID, time, tableOnFileRead);
        end when;
        if smoothness == Modelica.Blocks.Types.Smoothness.ConstantSegments then
          for i in 1:nout loop
            y[i] = p_offset[i] + getTableValueNoDer(tableID, i, time, nextTimeEvent, pre(nextTimeEvent), tableOnFileRead);
          end for;
        else
          for i in 1:nout loop
            y[i] = p_offset[i] + getTableValue(tableID, i, time, nextTimeEvent, pre(nextTimeEvent), tableOnFileRead);
          end for;
        end if;
      end CombiTimeTable;
    end Sources;

    package Types
      extends Modelica.Icons.TypesPackage;
      type Smoothness = enumeration(LinearSegments, ContinuousDerivative, ConstantSegments);
      type Extrapolation = enumeration(HoldLastPoint, LastTwoPoints, Periodic, NoExtrapolation);
      type Init = enumeration(NoInit, SteadyState, InitialState, InitialOutput);
      type AnalogFilter = enumeration(CriticalDamping, Bessel, Butterworth, ChebyshevI);
      type FilterType = enumeration(LowPass, HighPass, BandPass, BandStop);

      class ExternalCombiTimeTable
        extends ExternalObject;

        function constructor
          extends Modelica.Icons.Function;
          input String tableName;
          input String fileName;
          input Real[:, :] table;
          input Modelica.SIunits.Time startTime;
          input Integer[:] columns;
          input Modelica.Blocks.Types.Smoothness smoothness;
          input Modelica.Blocks.Types.Extrapolation extrapolation;
          output ExternalCombiTimeTable externalCombiTimeTable;
          external "C" externalCombiTimeTable = ModelicaStandardTables_CombiTimeTable_init(tableName, fileName, table, size(table, 1), size(table, 2), startTime, columns, size(columns, 1), smoothness, extrapolation) annotation(Library = {"ModelicaStandardTables"});
        end constructor;

        function destructor
          extends Modelica.Icons.Function;
          input ExternalCombiTimeTable externalCombiTimeTable;
          external "C" ModelicaStandardTables_CombiTimeTable_close(externalCombiTimeTable) annotation(Library = {"ModelicaStandardTables"});
        end destructor;
      end ExternalCombiTimeTable;
    end Types;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial block Block  end Block;

      partial block PartialBooleanBlock  end PartialBooleanBlock;
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

      partial model PartialTwoPortTransport
        extends PartialTwoPort(final port_a_exposesState = false, final port_b_exposesState = false);
        parameter Medium.AbsolutePressure dp_start = 0.01 * system.p_start;
        parameter Medium.MassFlowRate m_flow_start = system.m_flow_start;
        parameter Medium.MassFlowRate m_flow_small = if system.use_eps_Re then system.eps_m_flow * system.m_flow_nominal else system.m_flow_small;
        parameter Boolean show_T = true;
        parameter Boolean show_V_flow = true;
        Medium.MassFlowRate m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0, start = m_flow_start);
        Modelica.SIunits.Pressure dp(start = dp_start);
        Modelica.SIunits.VolumeFlowRate V_flow = m_flow / Modelica.Fluid.Utilities.regStep(m_flow, Medium.density(state_a), Medium.density(state_b), m_flow_small) if show_V_flow;
        Medium.Temperature port_a_T = Modelica.Fluid.Utilities.regStep(port_a.m_flow, Medium.temperature(state_a), Medium.temperature(Medium.setState_phX(port_a.p, port_a.h_outflow, port_a.Xi_outflow)), m_flow_small) if show_T;
        Medium.Temperature port_b_T = Modelica.Fluid.Utilities.regStep(port_b.m_flow, Medium.temperature(state_b), Medium.temperature(Medium.setState_phX(port_b.p, port_b.h_outflow, port_b.Xi_outflow)), m_flow_small) if show_T;
      protected
        Medium.ThermodynamicState state_a;
        Medium.ThermodynamicState state_b;
      equation
        state_a = Medium.setState_phX(port_a.p, inStream(port_a.h_outflow), inStream(port_a.Xi_outflow));
        state_b = Medium.setState_phX(port_b.p, inStream(port_b.h_outflow), inStream(port_b.Xi_outflow));
        dp = port_a.p - port_b.p;
        m_flow = port_a.m_flow;
        assert(m_flow > (-m_flow_small) or allowFlowReversal, "Reverting flow occurs even though allowFlowReversal is false");
        port_a.m_flow + port_b.m_flow = 0;
        port_a.Xi_outflow = inStream(port_b.Xi_outflow);
        port_b.Xi_outflow = inStream(port_a.Xi_outflow);
        port_a.C_outflow = inStream(port_b.C_outflow);
        port_b.C_outflow = inStream(port_a.C_outflow);
      end PartialTwoPortTransport;
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

        replaceable function density_pTX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input Temperature T;
          input MassFraction[:] X;
          output Density d;
        algorithm
          d := density(setState_pTX(p, T, X));
        end density_pTX;

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
        type EnthalpyFlowRate = .Modelica.SIunits.EnthalpyFlowRate(nominal = 1000.0, min = -1.0e8, max = 1.e8);
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
        type ExtraPropertyFlowRate = Real(unit = "kg/s");
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

        model ThermalConductor
          extends Interfaces.Element1D;
          parameter Modelica.SIunits.ThermalConductance G;
        equation
          Q_flow = G * dT;
        end ThermalConductor;
      end Components;

      package Sensors
        extends Modelica.Icons.SensorsPackage;

        model TemperatureSensor
          Modelica.Blocks.Interfaces.RealOutput T(unit = "K");
          Interfaces.HeatPort_a port;
        equation
          T = port.T;
          port.Q_flow = 0;
        end TemperatureSensor;
      end Sensors;

      package Sources
        extends Modelica.Icons.SourcesPackage;

        model FixedTemperature
          parameter Modelica.SIunits.Temperature T;
          Interfaces.HeatPort_b port;
        equation
          port.T = T;
        end FixedTemperature;

        model PrescribedHeatFlow
          parameter Modelica.SIunits.Temperature T_ref = 293.15;
          parameter Modelica.SIunits.LinearTemperatureCoefficient alpha = 0;
          Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W");
          Interfaces.HeatPort_b port;
        equation
          port.Q_flow = -Q_flow * (1 + alpha * (port.T - T_ref));
        end PrescribedHeatFlow;
      end Sources;

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

    function asinh
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
    algorithm
      y := Modelica.Math.log(u + sqrt(u * u + 1));
    end asinh;

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
        external "C" ModelicaError(string) annotation(Library = "ModelicaExternalC");
      end error;
    end Streams;

    package Strings
      extends Modelica.Icons.Package;

      function length
        extends Modelica.Icons.Function;
        input String string;
        output Integer result;
        external "C" result = ModelicaStrings_length(string) annotation(Library = "ModelicaExternalC");
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
          external "C" nextIndex = ModelicaStrings_skipWhiteSpace(string, startIndex) annotation(Library = "ModelicaExternalC");
        end skipWhiteSpace;
      end Advanced;
    end Strings;
  end Utilities;

  package Constants
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps;
    final constant Real small = ModelicaServices.Machine.small;
    final constant Real inf = ModelicaServices.Machine.inf;
    final constant .Modelica.SIunits.Velocity c = 299792458;
    final constant .Modelica.SIunits.Acceleration g_n = 9.80665;
    final constant Real R(final unit = "J/(mol.K)") = 8.314472;
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7;
    final constant .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_zero = -273.15;
  end Constants;

  package Icons
    partial class Information  end Information;

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

    partial package InternalPackage  end InternalPackage;

    partial package MaterialPropertiesPackage
      extends Modelica.Icons.Package;
    end MaterialPropertiesPackage;

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
    type Area = Real(final quantity = "Area", final unit = "m2");
    type Volume = Real(final quantity = "Volume", final unit = "m3");
    type Time = Real(final quantity = "Time", final unit = "s");
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type AbsolutePressure = Pressure(min = 0.0, nominal = 1e5);
    type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
    type Energy = Real(final quantity = "Energy", final unit = "J");
    type Power = Real(final quantity = "Power", final unit = "W");
    type EnthalpyFlowRate = Real(final quantity = "EnthalpyFlowRate", final unit = "W");
    type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
    type VolumeFlowRate = Real(final quantity = "VolumeFlowRate", final unit = "m3/s");
    type MomentumFlux = Real(final quantity = "MomentumFlux", final unit = "N");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC");
    type Temperature = ThermodynamicTemperature;
    type TemperatureDifference = Real(final quantity = "ThermodynamicTemperature", final unit = "K");
    type TemperatureSlope = Real(final quantity = "TemperatureSlope", final unit = "K/s");
    type LinearTemperatureCoefficient = Real(final quantity = "LinearTemperatureCoefficient", final unit = "1/K");
    type Compressibility = Real(final quantity = "Compressibility", final unit = "1/Pa");
    type IsothermalCompressibility = Compressibility;
    type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type ThermalConductance = Real(final quantity = "ThermalConductance", final unit = "W/K");
    type HeatCapacity = Real(final quantity = "HeatCapacity", final unit = "J/K");
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

package Buildings
  package Fluid
    extends Modelica.Icons.Package;

    package Delays
      extends Modelica.Icons.VariantsPackage;

      model DelayFirstOrder
        extends Buildings.Fluid.MixingVolumes.MixingVolume(final V = V0);
        parameter Modelica.SIunits.Time tau = 60;
      protected
        parameter Modelica.SIunits.Volume V0 = m_flow_nominal * tau / rho_nominal;
      end DelayFirstOrder;
    end Delays;

    package HeatExchangers
      extends Modelica.Icons.VariantsPackage;

      package Radiators
        extends Modelica.Icons.VariantsPackage;

        model RadiatorEN442_2
          extends Fluid.Interfaces.PartialTwoPortInterface(showDesignFlowDirection = false, show_T = true, m_flow_nominal = abs(Q_flow_nominal / cp_nominal / (T_a_nominal - T_b_nominal)));
          extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations(final X_start = Medium.X_default, final C_start = fill(0, Medium.nC), final C_nominal = fill(1E-2, Medium.nC));
          parameter Integer nEle(min = 1) = 5;
          parameter Real fraRad(min = 0, max = 1) = 0.35;
          parameter Modelica.SIunits.Power Q_flow_nominal;
          parameter Modelica.SIunits.Temperature T_a_nominal;
          parameter Modelica.SIunits.Temperature T_b_nominal;
          parameter Modelica.SIunits.Temperature TAir_nominal = 293.15;
          parameter Modelica.SIunits.Temperature TRad_nominal = TAir_nominal;
          parameter Real n = 1.24;
          parameter Modelica.SIunits.Volume VWat = 5.8E-6 * abs(Q_flow_nominal) annotation(Evaluate = true);
          parameter Modelica.SIunits.Mass mDry = 0.0263 * abs(Q_flow_nominal) if not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState annotation(Evaluate = true);
          parameter Boolean homotopyInitialization = true annotation(Evaluate = true);
          Modelica.SIunits.HeatFlowRate QCon_flow;
          Modelica.SIunits.HeatFlowRate QRad_flow;
          Modelica.SIunits.HeatFlowRate Q_flow;
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPortCon;
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPortRad;
          Modelica.Thermal.HeatTransfer.Components.HeatCapacitor[nEle] heaCap(each C = 500 * mDry / nEle, each T(start = T_start)) if not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
          Buildings.HeatTransfer.Sources.PrescribedHeatFlow[nEle] preHeaFloCon;
          Buildings.HeatTransfer.Sources.PrescribedHeatFlow[nEle] preHeaFloRad;
          Fluid.MixingVolumes.MixingVolume[nEle] vol(redeclare each package Medium = Medium, each nPorts = 2, each V = VWat / nEle, each final m_flow_nominal = m_flow_nominal, each final energyDynamics = energyDynamics, each final massDynamics = energyDynamics, each final p_start = p_start, each final T_start = T_start, each final X_start = X_start, each final C_start = C_start);
        protected
          parameter Modelica.SIunits.SpecificHeatCapacity cp_nominal = Medium.specificHeatCapacityCp(Medium.setState_pTX(Medium.p_default, T_a_nominal, Medium.X_default));
          parameter Modelica.SIunits.HeatFlowRate[nEle] QEle_flow_nominal(each fixed = false, each start = Q_flow_nominal / nEle);
          parameter Modelica.SIunits.Temperature[nEle] TWat_nominal(each fixed = false, start = array(T_a_nominal - i / nEle * (T_a_nominal - T_b_nominal) for i in 1:nEle));
          parameter Modelica.SIunits.TemperatureDifference[nEle] dTRad_nominal(each fixed = false, start = array(T_a_nominal - i / nEle * (T_a_nominal - T_b_nominal) - TRad_nominal for i in 1:nEle));
          parameter Modelica.SIunits.TemperatureDifference[nEle] dTCon_nominal(each fixed = false, start = array(T_a_nominal - i / nEle * (T_a_nominal - T_b_nominal) - TAir_nominal for i in 1:nEle));
          parameter Modelica.SIunits.ThermalConductance UAEle(fixed = false, min = 0, start = Q_flow_nominal / ((T_a_nominal + T_b_nominal) / 2 - ((1 - fraRad) * TAir_nominal + fraRad * TRad_nominal)) / nEle);
          final parameter Real k = if T_b_nominal > TAir_nominal then 1 else -1;
          Modelica.SIunits.TemperatureDifference[nEle] dTCon;
          Modelica.SIunits.TemperatureDifference[nEle] dTRad;
        initial equation
          if T_b_nominal > TAir_nominal then
            assert(T_a_nominal > T_b_nominal, "In RadiatorEN442_2, T_a_nominal must be higher than T_b_nominal");
            assert(Q_flow_nominal > 0, "In RadiatorEN442_2, nominal power must be bigger than zero if T_b_nominal > TAir_nominal");
          else
            assert(T_a_nominal < T_b_nominal, "In RadiatorEN442_2, T_a_nominal must be lower than T_b_nominal");
            assert(Q_flow_nominal < 0, "In RadiatorEN442_2, nominal power must be smaller than zero if T_b_nominal < TAir_nominal");
          end if;
          TWat_nominal[1] = T_a_nominal - QEle_flow_nominal[1] / m_flow_nominal / Medium.specificHeatCapacityCp(Medium.setState_pTX(Medium.p_default, T_a_nominal, Medium.X_default));
          for i in 2:nEle loop
            TWat_nominal[i] = TWat_nominal[i - 1] - QEle_flow_nominal[i] / m_flow_nominal / Medium.specificHeatCapacityCp(Medium.setState_pTX(Medium.p_default, TWat_nominal[i - 1], Medium.X_default));
          end for;
          dTRad_nominal = TWat_nominal .- TRad_nominal;
          dTCon_nominal = TWat_nominal .- TAir_nominal;
          Q_flow_nominal = sum(QEle_flow_nominal);
          for i in 1:nEle loop
            QEle_flow_nominal[i] = k * UAEle * ((1 - fraRad) * Buildings.Utilities.Math.Functions.powerLinearized(x = k * dTRad_nominal[i], n = n, x0 = 0.1 * k * (T_b_nominal - TRad_nominal)) + fraRad * Buildings.Utilities.Math.Functions.powerLinearized(x = k * dTCon_nominal[i], n = n, x0 = 0.1 * k * (T_b_nominal - TAir_nominal)));
          end for;
        equation
          dTCon = heatPortCon.T .- vol.T;
          dTRad = heatPortRad.T .- vol.T;
          if homotopyInitialization then
            preHeaFloCon.Q_flow = homotopy(actual = (1 - fraRad) .* UAEle .* dTCon .* Buildings.Utilities.Math.Functions.regNonZeroPower(x = dTCon, n = n - 1, delta = 0.05), simplified = (1 - fraRad) .* UAEle .* abs(dTCon_nominal) .^ (n - 1) .* dTCon);
            preHeaFloRad.Q_flow = homotopy(actual = fraRad .* UAEle .* dTRad .* Buildings.Utilities.Math.Functions.regNonZeroPower(x = dTRad, n = n - 1, delta = 0.05), simplified = fraRad .* UAEle .* abs(dTRad_nominal) .^ (n - 1) .* dTRad);
          else
            preHeaFloCon.Q_flow = (1 - fraRad) .* UAEle .* dTCon .* Buildings.Utilities.Math.Functions.regNonZeroPower(x = dTCon, n = n - 1, delta = 0.05);
            preHeaFloRad.Q_flow = fraRad .* UAEle .* dTRad .* Buildings.Utilities.Math.Functions.regNonZeroPower(x = dTRad, n = n - 1, delta = 0.05);
          end if;
          QCon_flow = sum(preHeaFloCon.Q_flow);
          QRad_flow = sum(preHeaFloRad.Q_flow);
          Q_flow = QCon_flow + QRad_flow;
          heatPortCon.Q_flow = QCon_flow;
          heatPortRad.Q_flow = QRad_flow;
          connect(preHeaFloCon.port, vol.heatPort);
          connect(preHeaFloRad.port, vol.heatPort);
          connect(heaCap.port, vol.heatPort);
          connect(port_a, vol[1].ports[1]);
          connect(vol[nEle].ports[2], port_b);
          for i in 1:nEle - 1 loop
            connect(vol[i].ports[2], vol[i + 1].ports[1]);
          end for;
        end RadiatorEN442_2;
      end Radiators;
    end HeatExchangers;

    package MixingVolumes
      extends Modelica.Icons.VariantsPackage;

      model MixingVolume
        extends Buildings.Fluid.MixingVolumes.BaseClasses.PartialMixingVolume;
      protected
        Modelica.Blocks.Sources.Constant[Medium.nXi] masExc(k = zeros(Medium.nXi)) if Medium.nXi > 0;
        Modelica.Blocks.Sources.RealExpression heaInp(y = heatPort.Q_flow);
      equation
        connect(heaInp.y, steBal.Q_flow);
        connect(heaInp.y, dynBal.Q_flow);
        connect(masExc.y, steBal.mXi_flow);
        connect(masExc.y, dynBal.mXi_flow);
      end MixingVolume;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        partial model PartialMixingVolume
          outer Modelica.Fluid.System system;
          extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
          parameter Modelica.SIunits.MassFlowRate m_flow_nominal(min = 0);
          parameter Integer nPorts = 0 annotation(Evaluate = true);
          parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * abs(m_flow_nominal);
          parameter Boolean homotopyInitialization = true annotation(Evaluate = true);
          parameter Boolean allowFlowReversal = system.allowFlowReversal annotation(Evaluate = true);
          parameter Modelica.SIunits.Volume V;
          parameter Boolean prescribedHeatFlowRate = false annotation(Evaluate = true);
          Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b[nPorts] ports(redeclare each package Medium = Medium);
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort;
          Modelica.SIunits.Temperature T;
          Modelica.SIunits.Pressure p;
          Modelica.SIunits.MassFraction[Medium.nXi] Xi;
          Medium.ExtraProperty[Medium.nC] C(nominal = C_nominal);
        protected
          Buildings.Fluid.Interfaces.StaticTwoPortConservationEquation steBal(sensibleOnly = true, redeclare final package Medium = Medium, final m_flow_nominal = m_flow_nominal, final allowFlowReversal = allowFlowReversal, final m_flow_small = m_flow_small, final homotopyInitialization = homotopyInitialization, final show_V_flow = false) if useSteadyStateTwoPort;
          Buildings.Fluid.Interfaces.ConservationEquation dynBal(redeclare final package Medium = Medium, final energyDynamics = energyDynamics, final massDynamics = massDynamics, final p_start = p_start, final T_start = T_start, final X_start = X_start, final C_start = C_start, final C_nominal = C_nominal, final fluidVolume = V, m(start = V * rho_nominal), U(start = V * rho_nominal * Medium.specificInternalEnergy(state_start)), nPorts = nPorts) if not useSteadyStateTwoPort;
          parameter Medium.ThermodynamicState state_start = Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi]);
          parameter Modelica.SIunits.Density rho_nominal = Medium.density(Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi])) annotation(Evaluate = true);
          final parameter Boolean useSteadyStateTwoPort = nPorts == 2 and prescribedHeatFlowRate and energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState annotation(Evaluate = true);
          Modelica.SIunits.HeatFlowRate Q_flow;
          Modelica.Blocks.Interfaces.RealOutput hOut_internal(unit = "J/kg");
          Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut_internal(each unit = "1");
          Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut_internal(each unit = "1");
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
          heatPort.Q_flow = Q_flow;
        end PartialMixingVolume;
      end BaseClasses;
    end MixingVolumes;

    package Movers
      extends Modelica.Icons.VariantsPackage;

      model FlowMachine_m_flow
        extends Buildings.Fluid.Movers.BaseClasses.ControlledFlowMachine(final control_m_flow = true, preSou(m_flow_start = m_flow_start, m_flow_small = m_flow_small));
        Modelica.Blocks.Interfaces.RealInput m_flow_in(final unit = "kg/s", nominal = m_flow_nominal);
        parameter Boolean filteredSpeed = true;
        parameter Modelica.SIunits.Time riseTime = 30;
        parameter Modelica.Blocks.Types.Init init = Modelica.Blocks.Types.Init.InitialOutput;
        parameter Modelica.SIunits.MassFlowRate m_flow_start(min = 0) = 0;
        Modelica.Blocks.Interfaces.RealOutput m_flow_actual(final unit = "kg/s", nominal = m_flow_nominal);
      protected
        Modelica.Blocks.Continuous.Filter filter(order = 2, f_cut = 5 / (2 * Modelica.Constants.pi * riseTime), final init = init, final y_start = m_flow_start, u_nominal = m_flow_nominal, x(each stateSelect = StateSelect.always), u(final unit = "kg/s"), y(final unit = "kg/s"), final analogFilter = Modelica.Blocks.Types.AnalogFilter.CriticalDamping, final filterType = Modelica.Blocks.Types.FilterType.LowPass) if filteredSpeed;
        Modelica.Blocks.Interfaces.RealOutput m_flow_filtered(final unit = "kg/s") if filteredSpeed;
      equation
        if filteredSpeed then
          connect(m_flow_in, filter.u);
          connect(filter.y, m_flow_actual);
        else
          connect(m_flow_in, m_flow_actual);
        end if;
        connect(filter.y, m_flow_filtered);
        connect(m_flow_actual, preSou.m_flow_in);
      end FlowMachine_m_flow;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        package Characteristics
          record efficiencyParameters
            extends Modelica.Icons.Record;
            parameter Real[:] r_V(each min = 0, each max = 1, each displayUnit = "1");
            parameter Real[size(r_V, 1)] eta(each min = 0, each max = 1, each displayUnit = "1");
          end efficiencyParameters;

          function efficiency
            extends Modelica.Icons.Function;
            input Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters data;
            input Real r_V(unit = "1");
            input Real[:] d;
            output Real eta(min = 0, unit = "1");
          protected
            Integer n = size(data.r_V, 1);
            Integer i;
          algorithm
            if n == 1 then
              eta := data.eta[1];
            else
              i := 1;
              for j in 1:n - 1 loop
                if r_V > data.r_V[j] then
                  i := j;
                else
                end if;
              end for;
              eta := Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = r_V, x1 = data.r_V[i], x2 = data.r_V[i + 1], y1 = data.eta[i], y2 = data.eta[i + 1], y1d = d[i], y2d = d[i + 1]);
            end if;
          end efficiency;
        end Characteristics;

        model ControlledFlowMachine
          extends Buildings.Fluid.Movers.BaseClasses.PartialFlowMachine(final show_V_flow = false, preSou(final control_m_flow = control_m_flow));
          extends Buildings.Fluid.Movers.BaseClasses.PowerInterface(final use_powerCharacteristic = false, final rho_default = Medium.density(sta_default));
          constant Boolean control_m_flow annotation(Evaluate = true);
          Real r_V(start = 1);
        protected
          final parameter Medium.AbsolutePressure p_a_default(displayUnit = "Pa") = Medium.p_default;
          parameter Medium.ThermodynamicState sta_default = Medium.setState_pTX(T = T_start, p = p_a_default, X = X_start[1:Medium.nXi]);
          Modelica.Blocks.Sources.RealExpression PToMedium_flow(y = Q_flow + WFlo) if addPowerToMedium;
        initial equation
          V_flow_max = m_flow_nominal / rho_default;
        equation
          r_V = VMachine_flow / V_flow_max;
          etaHyd = Characteristics.efficiency(data = hydraulicEfficiency, r_V = r_V, d = hydDer);
          etaMot = Characteristics.efficiency(data = motorEfficiency, r_V = r_V, d = motDer);
          dpMachine = -dp;
          VMachine_flow = -port_b.m_flow / rho_in;
          P = WFlo / Buildings.Utilities.Math.Functions.smoothMax(x1 = eta, x2 = 1E-5, deltaX = 1E-6);
          connect(PToMedium_flow.y, prePow.Q_flow);
        end ControlledFlowMachine;

        partial model PartialFlowMachine
          extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
          extends Buildings.Fluid.Interfaces.PartialTwoPortInterface(show_T = false, port_a(h_outflow(start = h_outflow_start), final m_flow(min = if allowFlowReversal then -.Modelica.Constants.inf else 0)), port_b(h_outflow(start = h_outflow_start), p(start = p_start), final m_flow(max = if allowFlowReversal then +.Modelica.Constants.inf else 0)), final showDesignFlowDirection = false);
          Delays.DelayFirstOrder vol(redeclare package Medium = Medium, tau = tau, energyDynamics = if dynamicBalance then energyDynamics else Modelica.Fluid.Types.Dynamics.SteadyState, massDynamics = if dynamicBalance then massDynamics else Modelica.Fluid.Types.Dynamics.SteadyState, T_start = T_start, X_start = X_start, C_start = C_start, m_flow_nominal = m_flow_nominal, p_start = p_start, prescribedHeatFlowRate = true, allowFlowReversal = allowFlowReversal, nPorts = 2);
          parameter Boolean dynamicBalance = true annotation(Evaluate = true);
          parameter Boolean addPowerToMedium = true;
          parameter Modelica.SIunits.Time tau = 1;
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort;
        protected
          Modelica.SIunits.Density rho_in;
          Buildings.Fluid.Movers.BaseClasses.IdealSource preSou(redeclare package Medium = Medium, allowFlowReversal = allowFlowReversal);
          Buildings.HeatTransfer.Sources.PrescribedHeatFlow prePow if addPowerToMedium;
          parameter Medium.ThermodynamicState sta_start = Medium.setState_pTX(T = T_start, p = p_start, X = X_start);
          parameter Modelica.SIunits.SpecificEnthalpy h_outflow_start = Medium.specificEnthalpy(sta_start);
        equation
          rho_in = Medium.density(Medium.setState_phX(port_a.p, inStream(port_a.h_outflow), inStream(port_a.Xi_outflow)));
          connect(prePow.port, vol.heatPort);
          connect(vol.heatPort, heatPort);
          connect(port_a, vol.ports[1]);
          connect(vol.ports[2], preSou.port_a);
          connect(preSou.port_b, port_b);
        end PartialFlowMachine;

        model IdealSource
          extends Modelica.Fluid.Interfaces.PartialTwoPortTransport(show_V_flow = false, show_T = false);
          parameter Boolean control_m_flow annotation(Evaluate = true);
          Modelica.Blocks.Interfaces.RealInput m_flow_in if control_m_flow;
          Modelica.Blocks.Interfaces.RealInput dp_in if not control_m_flow;
        protected
          Modelica.Blocks.Interfaces.RealInput m_flow_internal;
          Modelica.Blocks.Interfaces.RealInput dp_internal;
        equation
          if control_m_flow then
            m_flow = m_flow_internal;
            dp_internal = 0;
          else
            dp = dp_internal;
            m_flow_internal = 0;
          end if;
          connect(dp_internal, dp_in);
          connect(m_flow_internal, m_flow_in);
          port_a.h_outflow = inStream(port_b.h_outflow);
          port_b.h_outflow = inStream(port_a.h_outflow);
        end IdealSource;

        partial model PowerInterface
          parameter Boolean use_powerCharacteristic = false annotation(Evaluate = true);
          parameter Boolean motorCooledByFluid = true;
          parameter Boolean homotopyInitialization = true annotation(Evaluate = true);
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters motorEfficiency(r_V = {1}, eta = {0.7}) annotation(enable = not use_powerCharacteristic);
          parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters hydraulicEfficiency(r_V = {1}, eta = {0.7}) annotation(enable = not use_powerCharacteristic);
          parameter Modelica.SIunits.Density rho_default;
          Modelica.Blocks.Interfaces.RealOutput P(quantity = "Modelica.SIunits.Power", unit = "W");
          Modelica.SIunits.Power WHyd;
          Modelica.SIunits.Power WFlo;
          Modelica.SIunits.HeatFlowRate Q_flow;
          Real eta(min = 0, max = 1);
          Real etaHyd(min = 0, max = 1);
          Real etaMot(min = 0, max = 1);
          Modelica.SIunits.Pressure dpMachine(displayUnit = "Pa");
          Modelica.SIunits.VolumeFlowRate VMachine_flow;
        protected
          parameter Modelica.SIunits.VolumeFlowRate V_flow_max(fixed = false);
          parameter Modelica.SIunits.VolumeFlowRate delta_V_flow = 1E-3 * V_flow_max;
          final parameter Real[size(motorEfficiency.r_V, 1)] motDer(fixed = false) annotation(Evaluate = true);
          final parameter Real[size(hydraulicEfficiency.r_V, 1)] hydDer(fixed = false) annotation(Evaluate = true);
          Modelica.SIunits.HeatFlowRate QThe_flow;
        initial algorithm
          motDer := if use_powerCharacteristic then zeros(size(motorEfficiency.r_V, 1)) elseif size(motorEfficiency.r_V, 1) == 1 then {0} else Buildings.Utilities.Math.Functions.splineDerivatives(x = motorEfficiency.r_V, y = motorEfficiency.eta, ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(x = motorEfficiency.eta, strict = false));
          hydDer := if use_powerCharacteristic then zeros(size(hydraulicEfficiency.r_V, 1)) elseif size(hydraulicEfficiency.r_V, 1) == 1 then {0} else Buildings.Utilities.Math.Functions.splineDerivatives(x = hydraulicEfficiency.r_V, y = hydraulicEfficiency.eta);
        equation
          eta = etaHyd * etaMot;
          WFlo = dpMachine * VMachine_flow;
          etaHyd * WHyd = WFlo;
          QThe_flow + WFlo = if motorCooledByFluid then P else WHyd;
          if homotopyInitialization then
            Q_flow = homotopy(actual = Buildings.Utilities.Math.Functions.spliceFunction(pos = QThe_flow, neg = 0, x = noEvent(abs(VMachine_flow)) - 2 * delta_V_flow, deltax = delta_V_flow), simplified = 0);
          else
            Q_flow = Buildings.Utilities.Math.Functions.spliceFunction(pos = QThe_flow, neg = 0, x = noEvent(abs(VMachine_flow)) - 2 * delta_V_flow, deltax = delta_V_flow);
          end if;
        end PowerInterface;
      end BaseClasses;
    end Movers;

    package Sensors
      extends Modelica.Icons.SensorsPackage;

      model TemperatureTwoPort
        extends Buildings.Fluid.Sensors.BaseClasses.PartialDynamicFlowSensor;
        Modelica.Blocks.Interfaces.RealOutput T(final quantity = "Temperature", final unit = "K", displayUnit = "degC", min = 0, start = T_start);
        parameter Modelica.SIunits.Temperature T_start = Medium.T_default;
        Medium.Temperature TMed(start = T_start);
      protected
        Medium.Temperature T_a_inflow;
        Medium.Temperature T_b_inflow;
      initial equation
        if dynamic then
          if initType == Modelica.Blocks.Types.Init.SteadyState then
            der(T) = 0;
          elseif initType == Modelica.Blocks.Types.Init.InitialState or initType == Modelica.Blocks.Types.Init.InitialOutput then
            T = T_start;
          end if;
        end if;
      equation
        if allowFlowReversal then
          T_a_inflow = Medium.temperature(Medium.setState_phX(port_b.p, port_b.h_outflow, port_b.Xi_outflow));
          T_b_inflow = Medium.temperature(Medium.setState_phX(port_a.p, port_a.h_outflow, port_a.Xi_outflow));
          TMed = Modelica.Fluid.Utilities.regStep(port_a.m_flow, T_a_inflow, T_b_inflow, m_flow_small);
        else
          TMed = Medium.temperature(Medium.setState_phX(port_b.p, port_b.h_outflow, port_b.Xi_outflow));
          T_a_inflow = TMed;
          T_b_inflow = TMed;
        end if;
        if dynamic then
          der(T) = (TMed - T) * k / tau;
        else
          T = TMed;
        end if;
      end TemperatureTwoPort;

      package BaseClasses
        extends Modelica.Icons.BasesPackage;

        partial model PartialDynamicFlowSensor
          extends PartialFlowSensor;
          parameter Modelica.SIunits.Time tau(min = 0) = 1 annotation(Evaluate = true);
          parameter Modelica.Blocks.Types.Init initType = Modelica.Blocks.Types.Init.InitialState annotation(Evaluate = true);
        protected
          Real k(start = 1);
          final parameter Boolean dynamic = tau > 1E-10 or tau < (-1E-10);
          Real mNor_flow;
        equation
          if dynamic then
            mNor_flow = port_a.m_flow / m_flow_nominal;
            k = Modelica.Fluid.Utilities.regStep(x = port_a.m_flow, y1 = mNor_flow, y2 = -mNor_flow, x_small = m_flow_small);
          else
            mNor_flow = 1;
            k = 1;
          end if;
        end PartialDynamicFlowSensor;

        partial model PartialFlowSensor
          extends Modelica.Fluid.Interfaces.PartialTwoPort;
          parameter Modelica.SIunits.MassFlowRate m_flow_nominal(min = 0);
          parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * m_flow_nominal;
        equation
          0 = port_a.m_flow + port_b.m_flow;
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

      model FixedBoundary
        extends Modelica.Fluid.Sources.BaseClasses.PartialSource;
        parameter Boolean use_p = true annotation(Evaluate = true);
        parameter Medium.AbsolutePressure p = Medium.p_default;
        parameter Medium.Density d = Medium.density_pTX(Medium.p_default, Medium.T_default, Medium.X_default);
        parameter Boolean use_T = true annotation(Evaluate = true);
        parameter Medium.Temperature T = Medium.T_default;
        parameter Medium.SpecificEnthalpy h = Medium.h_default;
        parameter Medium.MassFraction[Medium.nX] X(quantity = Medium.substanceNames) = Medium.X_default;
        parameter Medium.ExtraProperty[Medium.nC] C(quantity = Medium.extraPropertiesNames) = fill(0, Medium.nC);
      equation
        Modelica.Fluid.Utilities.checkBoundary(Medium.mediumName, Medium.substanceNames, Medium.singleState, use_p, X, "FixedBoundary");
        if use_p or Medium.singleState then
          medium.p = p;
        else
          medium.d = d;
        end if;
        if use_T then
          medium.T = T;
        else
          medium.h = h;
        end if;
        medium.Xi = X[1:Medium.nXi];
        ports.C_outflow = fill(C, nPorts);
      end FixedBoundary;
    end Sources;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;

      partial model PartialTwoPortInterface
        extends Modelica.Fluid.Interfaces.PartialTwoPort(port_a(p(start = Medium.p_default, nominal = Medium.p_default)), port_b(p(start = Medium.p_default, nominal = Medium.p_default)));
        parameter Modelica.SIunits.MassFlowRate m_flow_nominal;
        parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * abs(m_flow_nominal);
        parameter Boolean homotopyInitialization = true annotation(Evaluate = true);
        parameter Boolean show_V_flow = false;
        parameter Boolean show_T = false;
        Modelica.SIunits.VolumeFlowRate V_flow = m_flow / Medium.density(sta_a) if show_V_flow;
        Modelica.SIunits.MassFlowRate m_flow(start = 0) = port_a.m_flow;
        Modelica.SIunits.Pressure dp(start = 0, displayUnit = "Pa");
        Medium.ThermodynamicState sta_a = if homotopyInitialization then Medium.setState_phX(port_a.p, homotopy(actual = actualStream(port_a.h_outflow), simplified = inStream(port_a.h_outflow)), homotopy(actual = actualStream(port_a.Xi_outflow), simplified = inStream(port_a.Xi_outflow))) else Medium.setState_phX(port_a.p, actualStream(port_a.h_outflow), actualStream(port_a.Xi_outflow)) if show_T or show_V_flow;
        Medium.ThermodynamicState sta_b = if homotopyInitialization then Medium.setState_phX(port_b.p, homotopy(actual = actualStream(port_b.h_outflow), simplified = port_b.h_outflow), homotopy(actual = actualStream(port_b.Xi_outflow), simplified = port_b.Xi_outflow)) else Medium.setState_phX(port_b.p, actualStream(port_b.h_outflow), actualStream(port_b.Xi_outflow)) if show_T;
      equation
        dp = port_a.p - port_b.p;
      end PartialTwoPortInterface;

      model ConservationEquation
        extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
        parameter Integer nPorts = 0 annotation(Evaluate = true);
        Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b[nPorts] ports(redeclare each package Medium = Medium);
        Medium.BaseProperties medium(preferredMediumStates = not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState, p(start = p_start, nominal = Medium.p_default, stateSelect = if not massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then StateSelect.prefer else StateSelect.default), h(start = Medium.specificEnthalpy_pTX(p_start, T_start, X_start)), T(start = T_start, nominal = Medium.T_default, stateSelect = if not energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then StateSelect.prefer else StateSelect.default), Xi(start = X_start[1:Medium.nXi], nominal = Medium.X_default[1:Medium.nXi], each stateSelect = if not substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then StateSelect.prefer else StateSelect.default), d(start = rho_nominal));
        Modelica.SIunits.Energy U;
        Modelica.SIunits.Mass m;
        Modelica.SIunits.Mass[Medium.nXi] mXi;
        Modelica.SIunits.Mass[Medium.nC] mC;
        Medium.ExtraProperty[Medium.nC] C(each nominal = C_nominal);
        Modelica.SIunits.MassFlowRate mb_flow;
        Modelica.SIunits.MassFlowRate[Medium.nXi] mbXi_flow;
        Medium.ExtraPropertyFlowRate[Medium.nC] mbC_flow;
        Modelica.SIunits.EnthalpyFlowRate Hb_flow;
        input Modelica.SIunits.Volume fluidVolume;
        Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W");
        Modelica.Blocks.Interfaces.RealInput[Medium.nXi] mXi_flow(each unit = "kg/s");
        Modelica.Blocks.Interfaces.RealOutput hOut(unit = "J/kg");
        Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut(each unit = "1", each min = 0, each max = 1);
        Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut(each min = 0);
      protected
        parameter Boolean initialize_p = not Medium.singleState;
        Medium.EnthalpyFlowRate[nPorts] ports_H_flow;
        Modelica.SIunits.MassFlowRate[nPorts, Medium.nXi] ports_mXi_flow;
        Medium.ExtraPropertyFlowRate[nPorts, Medium.nC] ports_mC_flow;
        parameter Modelica.SIunits.Density rho_nominal = Medium.density(Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi])) annotation(Evaluate = true);
      initial equation
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
          0 = mb_flow + sum(mXi_flow);
        else
          der(m) = mb_flow + sum(mXi_flow);
        end if;
        if substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
          zeros(Medium.nXi) = mbXi_flow + mXi_flow;
        else
          der(mXi) = mbXi_flow + mXi_flow;
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

      model StaticTwoPortConservationEquation
        extends Buildings.Fluid.Interfaces.PartialTwoPortInterface(showDesignFlowDirection = false);
        Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W");
        Modelica.Blocks.Interfaces.RealInput[Medium.nXi] mXi_flow(each unit = "kg/s");
        constant Boolean sensibleOnly;
        Modelica.Blocks.Interfaces.RealOutput hOut(unit = "J/kg");
        Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut(each unit = "1", each min = 0, each max = 1);
        Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut(each min = 0);
        constant Boolean use_safeDivision = true;
      protected
        Real m_flowInv(unit = "s/kg");
      equation
        if use_safeDivision then
          m_flowInv = Buildings.Utilities.Math.Functions.inverseXRegularized(x = port_a.m_flow, delta = m_flow_small / 1E3);
        else
          m_flowInv = 0;
        end if;
        if allowFlowReversal then
          if port_a.m_flow >= 0 then
            hOut = port_b.h_outflow;
            XiOut = port_b.Xi_outflow;
            COut = port_b.C_outflow;
          else
            hOut = port_a.h_outflow;
            XiOut = port_a.Xi_outflow;
            COut = port_a.C_outflow;
          end if;
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
            port_a.m_flow * (inStream(port_a.h_outflow) - port_b.h_outflow) = Q_flow;
            port_a.m_flow * (inStream(port_b.h_outflow) - port_a.h_outflow) = -Q_flow;
          end if;
          port_a.Xi_outflow = inStream(port_b.Xi_outflow);
          port_b.Xi_outflow = inStream(port_a.Xi_outflow);
          port_a.C_outflow = inStream(port_b.C_outflow);
          port_b.C_outflow = inStream(port_a.C_outflow);
        else
          port_a.m_flow + port_b.m_flow = -sum(mXi_flow);
          if use_safeDivision then
            port_b.h_outflow = inStream(port_a.h_outflow) + Q_flow * m_flowInv;
            port_a.h_outflow = inStream(port_b.h_outflow) - Q_flow * m_flowInv;
            port_b.Xi_outflow = inStream(port_a.Xi_outflow) + mXi_flow * m_flowInv;
            port_a.Xi_outflow = inStream(port_b.Xi_outflow) - mXi_flow * m_flowInv;
          else
            port_a.m_flow * (port_b.h_outflow - inStream(port_a.h_outflow)) = Q_flow;
            port_a.m_flow * (port_a.h_outflow - inStream(port_b.h_outflow)) = -Q_flow;
            port_a.m_flow * (port_b.Xi_outflow - inStream(port_a.Xi_outflow)) = mXi_flow;
            port_a.m_flow * (port_a.Xi_outflow - inStream(port_b.Xi_outflow)) = -mXi_flow;
          end if;
          port_a.m_flow * port_a.C_outflow = -port_b.m_flow * inStream(port_b.C_outflow);
          port_b.m_flow * port_b.C_outflow = -port_a.m_flow * inStream(port_a.C_outflow);
        end if;
        port_a.p = port_b.p;
      end StaticTwoPortConservationEquation;

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
    end Interfaces;
  end Fluid;

  package HeatTransfer
    extends Modelica.Icons.Package;

    package Sources
      extends Modelica.Icons.SourcesPackage;

      model PrescribedHeatFlow
        Modelica.Blocks.Interfaces.RealInput Q_flow;
        Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port;
      equation
        port.Q_flow = -Q_flow;
      end PrescribedHeatFlow;
    end Sources;
  end HeatTransfer;

  package Media
    extends Modelica.Icons.MaterialPropertiesPackage;

    package ConstantPropertyLiquidWater
      extends Buildings.Media.Interfaces.PartialSimpleMedium(mediumName = "SimpleLiquidWater", cp_const = 4184, cv_const = 4184, d_const = 995.586, eta_const = 1.e-3, lambda_const = 0.598, a_const = 1484, T_min = .Modelica.SIunits.Conversions.from_degC(-1), T_max = .Modelica.SIunits.Conversions.from_degC(130), T0 = 273.15, MM_const = 0.018015268, fluidConstants = Modelica.Media.Water.ConstantPropertyLiquidWater.simpleWaterConstants, ThermoStates = Interfaces.Choices.IndependentVariables.T);

      redeclare replaceable function extends specificInternalEnergy
        input ThermodynamicState state;
        output SpecificEnergy u;
      algorithm
        u := cv_const * (state.T - T0);
      end specificInternalEnergy;
    end ConstantPropertyLiquidWater;

    package GasesPTDecoupled
      extends Modelica.Icons.MaterialPropertiesPackage;

      package MoistAirUnsaturated
        extends Modelica.Media.Interfaces.PartialCondensingGases(final singleState = false, mediumName = "MoistAirPTDecoupledUnsaturated", substanceNames = {"water", "air"}, final reducedX = true, reference_X = {0.01, 0.99}, fluidConstants = {Modelica.Media.IdealGases.Common.FluidData.H2O, Modelica.Media.IdealGases.Common.FluidData.N2});
        constant Integer Water = 1;
        constant Integer Air = 2;
        constant Real k_mair = steam.MM / dryair.MM;
        constant Buildings.Media.PerfectGases.Common.DataRecord dryair = Buildings.Media.PerfectGases.Common.SingleGasData.Air;
        constant Buildings.Media.PerfectGases.Common.DataRecord steam = Buildings.Media.PerfectGases.Common.SingleGasData.H2O;
        constant AbsolutePressure pStp = 101325;
        constant Density dStp = 1.2;

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
          R = dryair.R * (1 - Xi[Water]) + steam.R * Xi[Water];
          u = h - pStp / dStp;
          d / dStp = p / pStp;
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
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T_phX(p, h, X), X = X) else ThermodynamicState(p = p, T = T_phX(p, h, cat(1, X, {1 - sum(X)})), X = cat(1, X, {1 - sum(X)}));
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
          extends Modelica.Icons.Function;
          input ThermodynamicState state;
          output Density d;
        algorithm
          d := state.p * dStp / pStp;
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
          h := (T - 273.15) * steam.cp + Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.enthalpyOfVaporization(T);
        end enthalpyOfCondensingGas;

        replaceable function der_enthalpyOfCondensingGas
          extends Modelica.Icons.Function;
          input Temperature T;
          input Real der_T(unit = "K/s");
          output Real der_h(unit = "J/(kg.s)");
        algorithm
          der_h := steam.cp * der_T;
        end der_enthalpyOfCondensingGas;

        redeclare replaceable function extends enthalpyOfGas
        algorithm
          h := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.enthalpyOfCondensingGas(T) * X[Water] + Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.enthalpyOfDryAir(T) * (1.0 - X[Water]);
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
          input Real der_T(unit = "K/s");
          output Real der_h(unit = "J/(kg.s)");
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
          lambda := .Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluate({-4.8737307422969E-008, 7.67803133753502E-005, 0.0241814385504202}, Modelica.SIunits.Conversions.to_degC(state.T));
        end thermalConductivity;

        redeclare function extends specificEnthalpy
        algorithm
          h := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, state.X);
        end specificEnthalpy;

        redeclare function extends specificInternalEnergy
          extends Modelica.Icons.Function;
        algorithm
          u := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, state.X) - pStp / dStp;
        end specificInternalEnergy;

        redeclare function extends specificGibbsEnergy
          extends Modelica.Icons.Function;
        algorithm
          g := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, state.X) - state.T * specificEntropy(state);
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy
          extends Modelica.Icons.Function;
        algorithm
          f := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, state.X) - gasConstant(state) * state.T - state.T * Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.specificEntropy(state);
        end specificHelmholtzEnergy;

        function h_pTX
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p;
          input .Modelica.SIunits.Temperature T;
          input .Modelica.SIunits.MassFraction[nX] X;
          output .Modelica.SIunits.SpecificEnthalpy h;
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction x_sat;
          .Modelica.SIunits.SpecificEnthalpy hDryAir;
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := k_mair * p_steam_sat / (p - p_steam_sat);
          h := (T - 273.15) * dryair.cp * (1 - X[Water]) + ((T - 273.15) * steam.cp + 2501014.5) * X[Water];
        end h_pTX;

        function T_phX
          extends Modelica.Icons.Function;
          input AbsolutePressure p;
          input SpecificEnthalpy h;
          input MassFraction[:] X;
          output Temperature T;
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat;
          .Modelica.SIunits.MassFraction x_sat;
        algorithm
          T := 273.15 + (h - 2501014.5 * X[Water]) / (dryair.cp * (1 - X[Water]) + steam.cp * X[Water]);
          p_steam_sat := saturationPressure(T);
          x_sat := k_mair * p_steam_sat / (p - p_steam_sat);
        end T_phX;

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
      end MoistAirUnsaturated;
    end GasesPTDecoupled;

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

      package Common
        extends Modelica.Icons.MaterialPropertiesPackage;

        record DataRecord
          extends Modelica.Icons.Record;
          String name;
          Modelica.SIunits.MolarMass MM;
          Modelica.SIunits.SpecificHeatCapacity R;
          Modelica.SIunits.SpecificHeatCapacity cp;
          Modelica.SIunits.SpecificHeatCapacity cv = cp - R;
        end DataRecord;

        package SingleGasData
          extends Modelica.Icons.MaterialPropertiesPackage;
          constant PerfectGases.Common.DataRecord Air(name = Modelica.Media.IdealGases.Common.SingleGasesData.Air.name, R = Modelica.Media.IdealGases.Common.SingleGasesData.Air.R, MM = Modelica.Media.IdealGases.Common.SingleGasesData.Air.MM, cp = 1006);
          constant PerfectGases.Common.DataRecord H2O(name = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.name, R = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.R, MM = Modelica.Media.IdealGases.Common.SingleGasesData.H2O.MM, cp = 1860);
        end SingleGasData;
      end Common;
    end PerfectGases;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;

      package Choices
        type IndependentVariables = enumeration(T, pT, ph, phX, pTX, dTX);
      end Choices;

      partial package PartialSimpleMedium
        extends Modelica.Media.Interfaces.PartialPureSubstance(ThermoStates = Choices.IndependentVariables.pT, final singleState = constantDensity, reference_p = p0, p_default = p0);
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

        constant Real kappa_const(unit = "1/Pa") = 0;
        constant Modelica.SIunits.AbsolutePressure p0 = 3E5;
      protected
        constant Boolean constantDensity = kappa_const <= 1E-20;

      public
        redeclare replaceable model extends BaseProperties
        equation
          assert(T >= T_min and T <= T_max, "
          Temperature T (= " + String(T) + " K) is not
          in the allowed range (" + String(T_min) + " K <= T <= " + String(T_max) + " K)
          required from medium model \"" + mediumName + "\".
          ");
          h = specificEnthalpy_pTX(p, T, X);
          u = cv_const * (T - T0);
          d = if constantDensity then d_const else d_const * (1 + kappa_const * (p - p0));
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
          d := if constantDensity then d_const else d_const * (1 + kappa_const * (state.p - p0));
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
      extends Modelica.Icons.VariantsPackage;

      package Functions
        extends Modelica.Icons.BasesPackage;

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

        function powerLinearized
          input Real x;
          input Real n;
          input Real x0;
          output Real y;
        algorithm
          if x > x0 then
            y := x ^ n;
          else
            y := x0 ^ n * (1 - n) + n * x0 ^ (n - 1) * x;
          end if;
        end powerLinearized;

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

        function smoothMax
          input Real x1;
          input Real x2;
          input Real deltaX;
          output Real y;
        algorithm
          y := Buildings.Utilities.Math.Functions.spliceFunction(pos = x1, neg = x2, x = x1 - x2, deltax = deltaX);
        end smoothMax;

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

  package Examples
    extends Modelica.Icons.ExamplesPackage;

    package Tutorial
      extends Modelica.Icons.Information;

      package Boiler
        extends Modelica.Icons.ExamplesPackage;

        model System2
          extends Modelica.Icons.Example;
          replaceable package MediumA = Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated;
          replaceable package MediumW = Buildings.Media.ConstantPropertyLiquidWater;
          parameter Modelica.SIunits.HeatFlowRate Q_flow_nominal = 20000;
          parameter Modelica.SIunits.Temperature TRadSup_nominal = 273.15 + 50;
          parameter Modelica.SIunits.Temperature TRadRet_nominal = 273.15 + 40;
          parameter Modelica.SIunits.MassFlowRate mRad_flow_nominal = Q_flow_nominal / 4200 / (TRadSup_nominal - TRadRet_nominal);
          inner Modelica.Fluid.System system;
          Fluid.MixingVolumes.MixingVolume vol(redeclare package Medium = MediumA, m_flow_nominal = mA_flow_nominal, V = V);
          Modelica.Thermal.HeatTransfer.Components.ThermalConductor theCon(G = 20000 / 30);
          parameter Modelica.SIunits.Volume V = 6 * 10 * 3;
          parameter Modelica.SIunits.MassFlowRate mA_flow_nominal = V * 6 / 3600;
          parameter Modelica.SIunits.HeatFlowRate QRooInt_flow = 4000;
          Modelica.Thermal.HeatTransfer.Sources.FixedTemperature TOut(T = 263.15);
          Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow preHea;
          Modelica.Thermal.HeatTransfer.Components.HeatCapacitor heaCap(C = 2 * V * 1.2 * 1006);
          Modelica.Blocks.Sources.CombiTimeTable timTab(extrapolation = Modelica.Blocks.Types.Extrapolation.Periodic, table = [0, 0; 8 * 3600, 0; 8 * 3600, QRooInt_flow; 18 * 3600, QRooInt_flow; 18 * 3600, 0; 24 * 3600, 0]);
          Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2 rad(redeclare package Medium = MediumW, Q_flow_nominal = Q_flow_nominal, T_a_nominal = TRadSup_nominal, T_b_nominal = TRadRet_nominal);
          Fluid.Sources.FixedBoundary sin(nPorts = 1, redeclare package Medium = MediumW);
          Fluid.Sensors.TemperatureTwoPort temSup(redeclare package Medium = MediumW, m_flow_nominal = mRad_flow_nominal);
          Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor temRoo;
          Buildings.Fluid.Movers.FlowMachine_m_flow pumRad(m_flow_nominal = mRad_flow_nominal, redeclare package Medium = MediumW);
          Fluid.Sources.FixedBoundary sou(nPorts = 1, redeclare package Medium = MediumW, T = TRadSup_nominal);
          Modelica.Blocks.Logical.Hysteresis hysPum(uLow = 273.15 + 19, uHigh = 273.15 + 21);
          Modelica.Blocks.Math.BooleanToReal booToReaRad(realTrue = mRad_flow_nominal);
          Modelica.Blocks.Logical.Not not1;
        equation
          connect(TOut.port, theCon.port_a);
          connect(theCon.port_b, vol.heatPort);
          connect(preHea.port, vol.heatPort);
          connect(heaCap.port, vol.heatPort);
          connect(timTab.y[1], preHea.Q_flow);
          connect(temSup.port_b, rad.port_a);
          connect(rad.port_b, sin.ports[1]);
          connect(temRoo.port, vol.heatPort);
          connect(rad.heatPortCon, vol.heatPort);
          connect(rad.heatPortRad, vol.heatPort);
          connect(sou.ports[1], pumRad.port_a);
          connect(pumRad.port_b, temSup.port_a);
          connect(temRoo.T, hysPum.u);
          connect(hysPum.y, not1.u);
          connect(not1.y, booToReaRad.u);
          connect(booToReaRad.y, pumRad.m_flow_in);
        end System2;
      end Boiler;
    end Tutorial;
  end Examples;
end Buildings;

model System2
  extends Buildings.Examples.Tutorial.Boiler.System2;
  annotation(__Dymola_Commands(file = "modelica://Buildings/Resources/Scripts/Dymola/Examples/Tutorial/Boiler/System2.mos"), experiment(StopTime = 172800));
end System2;

// Result:
// function Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.FluidConstants;
//
// function Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.density
//   input Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 995.586;
// end Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.density;
//
// function Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.setState_pTX;
//
// function Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.specificInternalEnergy
//   input Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.ThermodynamicState state;
//   output Real u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
// algorithm
//   u := 4184.0 * (-273.15 + state.T);
// end Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.specificInternalEnergy;
//
// function Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.temperature_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := 273.15 + 0.0002390057361376673 * h;
// end Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.temperature_phX;
//
// function Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.FluidConstants;
//
// function Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.ThermodynamicState;
//
// function Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_pTX;
//
// function Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.ThermodynamicState(p, Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.temperature_phX(p, h, X));
// end Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_phX;
//
// function Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificHeatCapacityCp
//   input Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.ThermodynamicState state;
//   output Real cp(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
// algorithm
//   cp := 4184.0;
// end Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificHeatCapacityCp;
//
// function Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.temperature_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := 273.15 + 0.0002390057361376673 * h;
// end Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.temperature_phX;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.FluidConstants;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.density
//   input Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 995.586;
// end Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.density;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.setState_pTX;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.FluidConstants;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.density
//   input Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 995.586;
// end Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.density;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.setState_pTX;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.FluidConstants"
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
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.FluidConstants;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.density
//   input Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 1.184307920059215e-05 * state.p;
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.density;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.saturationPressure
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
// algorithm
//   psat := Buildings.Utilities.Math.Functions.spliceFunction(Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.saturationPressureLiquid(Tsat), Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.sublimationPressureIce(Tsat), -273.16 + Tsat, 1.0);
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.saturationPressure;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.saturationPressureLiquid
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
// algorithm
//   psat := 611.657 * exp(17.2799 + (-4102.99) / (-35.719 + Tsat));
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.saturationPressureLiquid;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.setState_pTX;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.specificEnthalpy
//   input Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.specificEnthalpy;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.specificEnthalpy(/*.Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.ThermodynamicState*/(Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.setState_pTX(p, T, X)));
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.sublimationPressureIce
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real Ttriple(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 273.16;
//   protected Real ptriple(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 611.657;
//   protected Real[2] a = {-13.928169, 34.7078238};
//   protected Real[2] n = {-1.5, -1.25};
//   protected Real r1 = Tsat / Ttriple;
// algorithm
//   psat := exp(a[1] + a[2] + (-a[1]) * r1 ^ n[1] - a[2] * r1 ^ n[2]) * ptriple;
// end Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.sublimationPressureIce;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.FluidConstants;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.ThermodynamicState;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.density
//   input Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 995.586;
// end Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.density;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.setState_pTX;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificInternalEnergy
//   input Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.ThermodynamicState state;
//   output Real u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
// algorithm
//   u := 4184.0 * (-273.15 + state.T);
// end Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificInternalEnergy;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.temperature_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := 273.15 + 0.0002390057361376673 * h;
// end Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.temperature_phX;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.FluidConstants"
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
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.FluidConstants;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.T_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected Real p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real x_sat(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
// algorithm
//   T := 273.15 + (h + (-2501014.5) * X[1]) / (dryair.cp * (1.0 - X[1]) + steam.cp * X[1]);
//   p_steam_sat := Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.saturationPressure(T);
//   x_sat := steam.MM * p_steam_sat / ((p - p_steam_sat) * dryair.MM);
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.T_phX;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.density
//   input Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 1.184307920059215e-05 * state.p;
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.density;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.saturationPressure
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
// algorithm
//   psat := Buildings.Utilities.Math.Functions.spliceFunction(Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.saturationPressureLiquid(Tsat), Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.sublimationPressureIce(Tsat), -273.16 + Tsat, 1.0);
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.saturationPressure;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.saturationPressureLiquid
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
// algorithm
//   psat := 611.657 * exp(17.2799 + (-4102.99) / (-35.719 + Tsat));
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.saturationPressureLiquid;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.setState_pTX;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.setState_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState(p, Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.T_phX(p, h, X), X) else Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState(p, Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.T_phX(p, h, cat(1, X, {1.0 - sum(X)})), cat(1, X, {1.0 - sum(X)}));
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.setState_phX;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.specificEnthalpy
//   input Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.specificEnthalpy;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.specificEnthalpy(/*.Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState*/(Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.setState_pTX(p, T, X)));
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.specificInternalEnergy
//   input Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState state;
//   output Real u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
// algorithm
//   u := -84437.5 + Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.specificInternalEnergy;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.sublimationPressureIce
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real Ttriple(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 273.16;
//   protected Real ptriple(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 611.657;
//   protected Real[2] a = {-13.928169, 34.7078238};
//   protected Real[2] n = {-1.5, -1.25};
//   protected Real r1 = Tsat / Ttriple;
// algorithm
//   psat := exp(a[1] + a[2] + (-a[1]) * r1 ^ n[1] - a[2] * r1 ^ n[2]) * ptriple;
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.sublimationPressureIce;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.temperature
//   input Modelica.Media.Air.MoistAir.ThermodynamicState state;
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := state.T;
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.temperature;
//
// function Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.temperature_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.temperature(/*.Modelica.Media.Air.MoistAir.ThermodynamicState*/(Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.setState_phX(p, h, X)));
// end Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.temperature_phX;
//
// function Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency
//   input Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters data;
//   input Real r_V(unit = "1");
//   input Real[:] d;
//   output Real eta(unit = "1", min = 0.0);
//   protected Integer i;
//   protected Integer n = size(data.r_V, 1);
// algorithm
//   if n == 1 then
//     eta := data.eta[1];
//   else
//     i := 1;
//     for j in 1:-1 + n loop
//       if r_V > data.r_V[j] then
//         i := j;
//       end if;
//     end for;
//     eta := Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(r_V, data.r_V[i], data.r_V[1 + i], data.eta[i], data.eta[1 + i], d[i], d[1 + i]);
//   end if;
// end Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency;
//
// function Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters "Automatically generated record constructor for Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters"
//   input Real[:] r_V(min = 0.0, max = 1.0, displayUnit = "1");
//   input Real[size(r_V, 1)] eta(min = 0.0, max = 1.0, displayUnit = "1");
//   output efficiencyParameters res;
// end Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters;
//
// function Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters$pumRad$hydraulicEfficiency "Automatically generated record constructor for Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters$pumRad$hydraulicEfficiency"
//   input Real[:] r_V(min = 0.0, max = 1.0, displayUnit = "1");
//   input Real[size(r_V, 1)] eta(min = 0.0, max = 1.0, displayUnit = "1");
//   output efficiencyParameters$pumRad$hydraulicEfficiency res;
// end Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters$pumRad$hydraulicEfficiency;
//
// function Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters$pumRad$motorEfficiency "Automatically generated record constructor for Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters$pumRad$motorEfficiency"
//   input Real[:] r_V(min = 0.0, max = 1.0, displayUnit = "1");
//   input Real[size(r_V, 1)] eta(min = 0.0, max = 1.0, displayUnit = "1");
//   output efficiencyParameters$pumRad$motorEfficiency res;
// end Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters$pumRad$motorEfficiency;
//
// function Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.FluidConstants;
//
// function Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.setState_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.ThermodynamicState(p, Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.temperature_phX(p, h, X));
// end Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.setState_phX;
//
// function Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.temperature_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := 273.15 + 0.0002390057361376673 * h;
// end Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.temperature_phX;
//
// function Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.FluidConstants;
//
// function Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.density
//   input Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 995.586;
// end Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.density;
//
// function Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.setState_pTX;
//
// function Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.setState_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState(p, Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.temperature_phX(p, h, X));
// end Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.setState_phX;
//
// function Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.specificEnthalpy
//   input Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + state.T);
// end Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.specificEnthalpy;
//
// function Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.temperature_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := 273.15 + 0.0002390057361376673 * h;
// end Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.temperature_phX;
//
// function Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.FluidConstants;
//
// function Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.setState_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.ThermodynamicState(p, Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.temperature_phX(p, h, X));
// end Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.setState_phX;
//
// function Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.temperature
//   input Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.ThermodynamicState state;
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := state.T;
// end Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.temperature;
//
// function Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.temperature_phX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
// algorithm
//   T := 273.15 + 0.0002390057361376673 * h;
// end Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.temperature_phX;
//
// function Buildings.Fluid.Sources.FixedBoundary$sin.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Sources.FixedBoundary$sin.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Sources.FixedBoundary$sin.Medium.FluidConstants;
//
// function Buildings.Fluid.Sources.FixedBoundary$sin.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Sources.FixedBoundary$sin.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Sources.FixedBoundary$sin.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Sources.FixedBoundary$sin.Medium.density
//   input Buildings.Fluid.Sources.FixedBoundary$sin.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 995.586;
// end Buildings.Fluid.Sources.FixedBoundary$sin.Medium.density;
//
// function Buildings.Fluid.Sources.FixedBoundary$sin.Medium.density_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := Buildings.Fluid.Sources.FixedBoundary$sin.Medium.density(Buildings.Fluid.Sources.FixedBoundary$sin.Medium.setState_pTX(p, T, X));
// end Buildings.Fluid.Sources.FixedBoundary$sin.Medium.density_pTX;
//
// function Buildings.Fluid.Sources.FixedBoundary$sin.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Sources.FixedBoundary$sin.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Sources.FixedBoundary$sin.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.Sources.FixedBoundary$sin.Medium.setState_pTX;
//
// function Buildings.Fluid.Sources.FixedBoundary$sin.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Sources.FixedBoundary$sin.Medium.specificEnthalpy_pTX;
//
// function Buildings.Fluid.Sources.FixedBoundary$sou.Medium.FluidConstants "Automatically generated record constructor for Buildings.Fluid.Sources.FixedBoundary$sou.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Buildings.Fluid.Sources.FixedBoundary$sou.Medium.FluidConstants;
//
// function Buildings.Fluid.Sources.FixedBoundary$sou.Medium.ThermodynamicState "Automatically generated record constructor for Buildings.Fluid.Sources.FixedBoundary$sou.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   output ThermodynamicState res;
// end Buildings.Fluid.Sources.FixedBoundary$sou.Medium.ThermodynamicState;
//
// function Buildings.Fluid.Sources.FixedBoundary$sou.Medium.density
//   input Buildings.Fluid.Sources.FixedBoundary$sou.Medium.ThermodynamicState state;
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := 995.586;
// end Buildings.Fluid.Sources.FixedBoundary$sou.Medium.density;
//
// function Buildings.Fluid.Sources.FixedBoundary$sou.Medium.density_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
// algorithm
//   d := Buildings.Fluid.Sources.FixedBoundary$sou.Medium.density(Buildings.Fluid.Sources.FixedBoundary$sou.Medium.setState_pTX(p, T, X));
// end Buildings.Fluid.Sources.FixedBoundary$sou.Medium.density_pTX;
//
// function Buildings.Fluid.Sources.FixedBoundary$sou.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {1.0};
//   output Buildings.Fluid.Sources.FixedBoundary$sou.Medium.ThermodynamicState state;
// algorithm
//   state := Buildings.Fluid.Sources.FixedBoundary$sou.Medium.ThermodynamicState(p, T);
// end Buildings.Fluid.Sources.FixedBoundary$sou.Medium.setState_pTX;
//
// function Buildings.Fluid.Sources.FixedBoundary$sou.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Buildings.Fluid.Sources.FixedBoundary$sou.Medium.specificEnthalpy_pTX;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.FluidConstants "Automatically generated record constructor for Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.FluidConstants"
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
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.FluidConstants;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.ThermodynamicState "Automatically generated record constructor for Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.ThermodynamicState;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   input Real[2] X(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg");
//   protected Real p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real x_sat(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real hDryAir(quantity = "SpecificEnergy", unit = "J/kg");
// algorithm
//   p_steam_sat := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.saturationPressure(T);
//   x_sat := steam.MM * p_steam_sat / ((p - p_steam_sat) * dryair.MM);
//   h := (-273.15 + T) * dryair.cp * (1.0 - X[1]) + (2501014.5 + (-273.15 + T) * steam.cp) * X[1];
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.saturationPressure
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
// algorithm
//   psat := Buildings.Utilities.Math.Functions.spliceFunction(Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.saturationPressureLiquid(Tsat), Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.sublimationPressureIce(Tsat), -273.16 + Tsat, 1.0);
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.saturationPressure;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.saturationPressureLiquid
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
// algorithm
//   psat := 611.657 * exp(17.2799 + (-4102.99) / (-35.719 + Tsat));
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.saturationPressureLiquid;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.setState_pTX;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.specificEnthalpy
//   input Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.specificEnthalpy;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.specificEnthalpy(/*.Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.ThermodynamicState*/(Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.setState_pTX(p, T, X)));
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.specificEnthalpy_pTX;
//
// function Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.sublimationPressureIce
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real Ttriple(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 273.16;
//   protected Real ptriple(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 611.657;
//   protected Real[2] a = {-13.928169, 34.7078238};
//   protected Real[2] n = {-1.5, -1.25};
//   protected Real r1 = Tsat / Ttriple;
// algorithm
//   psat := exp(a[1] + a[2] + (-a[1]) * r1 ^ n[1] - a[2] * r1 ^ n[2]) * ptriple;
// end Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.sublimationPressureIce;
//
// function Buildings.Media.PerfectGases.Common.DataRecord "Automatically generated record constructor for Buildings.Media.PerfectGases.Common.DataRecord"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cp(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cv(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = cp - R;
//   output DataRecord res;
// end Buildings.Media.PerfectGases.Common.DataRecord;
//
// function Buildings.Media.PerfectGases.Common.DataRecord$Air "Automatically generated record constructor for Buildings.Media.PerfectGases.Common.DataRecord$Air"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cp(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cv(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = cp - R;
//   output DataRecord$Air res;
// end Buildings.Media.PerfectGases.Common.DataRecord$Air;
//
// function Buildings.Media.PerfectGases.Common.DataRecord$H2O "Automatically generated record constructor for Buildings.Media.PerfectGases.Common.DataRecord$H2O"
//   input String name;
//   input Real MM(quantity = "MolarMass", unit = "kg/mol", min = 0.0);
//   input Real R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cp(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)");
//   input Real cv(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = cp - R;
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
// function Buildings.Media.PerfectGases.MoistAir.ThermodynamicState "Automatically generated record constructor for Buildings.Media.PerfectGases.MoistAir.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Buildings.Media.PerfectGases.MoistAir.ThermodynamicState;
//
// function Buildings.Media.PerfectGases.MoistAir.h_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg");
//   protected Real p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real x_sat(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real X_liquid(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real X_steam(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real X_air(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real hDryAir(quantity = "SpecificEnergy", unit = "J/kg");
// algorithm
//   p_steam_sat := Buildings.Media.PerfectGases.MoistAir.saturationPressure(T);
//   x_sat := steam.MM * p_steam_sat / ((p - p_steam_sat) * dryair.MM);
//   X_liquid := max(X[1] - x_sat / (1.0 + x_sat), 0.0);
//   X_steam := X[1] - X_liquid;
//   X_air := 1.0 - X[1];
//   hDryAir := (-273.15 + T) * dryair.cp;
//   h := hDryAir * X_air + (2501014.5 + (-273.15 + T) * steam.cp) * X_steam + 4186.0 * (-273.15 + T) * X_liquid;
// end Buildings.Media.PerfectGases.MoistAir.h_pTX;
//
// function Buildings.Media.PerfectGases.MoistAir.saturationPressure
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
// algorithm
//   psat := Buildings.Utilities.Math.Functions.spliceFunction(Buildings.Media.PerfectGases.MoistAir.saturationPressureLiquid(Tsat), Buildings.Media.PerfectGases.MoistAir.sublimationPressureIce(Tsat), -273.16 + Tsat, 1.0);
// end Buildings.Media.PerfectGases.MoistAir.saturationPressure;
//
// function Buildings.Media.PerfectGases.MoistAir.saturationPressureLiquid
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
// algorithm
//   psat := 611.657 * exp(17.2799 + (-4102.99) / (-35.719 + Tsat));
// end Buildings.Media.PerfectGases.MoistAir.saturationPressureLiquid;
//
// function Buildings.Media.PerfectGases.MoistAir.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Buildings.Media.PerfectGases.MoistAir.setState_pTX;
//
// function Buildings.Media.PerfectGases.MoistAir.specificEnthalpy
//   input Buildings.Media.PerfectGases.MoistAir.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Media.PerfectGases.MoistAir.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Buildings.Media.PerfectGases.MoistAir.specificEnthalpy;
//
// function Buildings.Media.PerfectGases.MoistAir.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Media.PerfectGases.MoistAir.specificEnthalpy(/*.Buildings.Media.PerfectGases.MoistAir.ThermodynamicState*/(Buildings.Media.PerfectGases.MoistAir.setState_pTX(p, T, X)));
// end Buildings.Media.PerfectGases.MoistAir.specificEnthalpy_pTX;
//
// function Buildings.Media.PerfectGases.MoistAir.sublimationPressureIce
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real Ttriple(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 273.16;
//   protected Real ptriple(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 611.657;
//   protected Real[2] a = {-13.928169, 34.7078238};
//   protected Real[2] n = {-1.5, -1.25};
//   protected Real r1 = Tsat / Ttriple;
// algorithm
//   psat := exp(a[1] + a[2] + (-a[1]) * r1 ^ n[1] - a[2] * r1 ^ n[2]) * ptriple;
// end Buildings.Media.PerfectGases.MoistAir.sublimationPressureIce;
//
// function Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation
//   input Real x;
//   input Real x1;
//   input Real x2;
//   input Real y1;
//   input Real y2;
//   input Real y1d;
//   input Real y2d;
//   output Real y;
// algorithm
//   if x > x1 and x < x2 then
//     y := Modelica.Fluid.Utilities.cubicHermite(x, x1, x2, y1, y2, y1d, y2d);
//   elseif x <= x1 then
//     y := y1 + (x - x1) * y1d;
//   else
//     y := y2 + (x - x2) * y2d;
//   end if;
// end Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation;
//
// function Buildings.Utilities.Math.Functions.isMonotonic
//   input Real[:] x;
//   input Boolean strict = false;
//   output Boolean monotonic;
//   protected Integer n = size(x, 1);
// algorithm
//   if n == 1 then
//     monotonic := true;
//   else
//     monotonic := true;
//     if strict then
//       if x[1] >= x[n] then
//         for i in 1:-1 + n loop
//           if not x[i] > x[1 + i] then
//             monotonic := false;
//           end if;
//         end for;
//       else
//         for i in 1:-1 + n loop
//           if not x[i] < x[1 + i] then
//             monotonic := false;
//           end if;
//         end for;
//       end if;
//     else
//       if x[1] >= x[n] then
//         for i in 1:-1 + n loop
//           if not x[i] >= x[1 + i] then
//             monotonic := false;
//           end if;
//         end for;
//       else
//         for i in 1:-1 + n loop
//           if not x[i] <= x[1 + i] then
//             monotonic := false;
//           end if;
//         end for;
//       end if;
//     end if;
//   end if;
// end Buildings.Utilities.Math.Functions.isMonotonic;
//
// function Buildings.Utilities.Math.Functions.powerLinearized
//   input Real x;
//   input Real n;
//   input Real x0;
//   output Real y;
// algorithm
//   if x > x0 then
//     y := x ^ n;
//   else
//     y := x0 ^ n * (1.0 - n) + n * x0 ^ (-1.0 + n) * x;
//   end if;
// end Buildings.Utilities.Math.Functions.powerLinearized;
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
//     delta2 := delta ^ 2.0;
//     x2 := x ^ 2.0;
//     y_d := delta ^ n;
//     yP_d := n * delta ^ (-1.0 + n);
//     yPP_d := n * (-1.0 + n) * delta ^ (-2.0 + n);
//     a1 := (-0.125) * (yP_d / delta - yPP_d) / delta2;
//     a3 := 0.5 * yPP_d + (-6.0) * a1 * delta2;
//     a5 := y_d - delta2 * (a3 + delta2 * a1);
//     y := a5 + x2 * (a3 + x2 * a1);
//     assert(a5 > 0.0, "Delta is too small for this exponent.");
//   end if;
// end Buildings.Utilities.Math.Functions.regNonZeroPower;
//
// function Buildings.Utilities.Math.Functions.smoothMax
//   input Real x1;
//   input Real x2;
//   input Real deltaX;
//   output Real y;
// algorithm
//   y := Buildings.Utilities.Math.Functions.spliceFunction(x1, x2, x1 - x2, deltaX);
// end Buildings.Utilities.Math.Functions.smoothMax;
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
// function Buildings.Utilities.Math.Functions.splineDerivatives
//   input Real[:] x;
//   input Real[size(x, 1)] y;
//   input Boolean ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(y, false);
//   output Real[size(x, 1)] d;
//   protected Real alpha;
//   protected Real beta;
//   protected Real tau;
//   protected Integer n = size(x, 1);
//   protected Real[-1 + n] delta;
// algorithm
//   if n > 1 then
//     assert(x[1] < x[n], "x must be strictly increasing.
//                   Received x[1] = " + String(x[1], 6, 0, true) + "
//                            x[" + String(n, 0, true) + "] = " + String(x[n], 6, 0, true));
//     assert(Buildings.Utilities.Math.Functions.isMonotonic(x, true), "x-values must be strictly monontone increasing or decreasing.");
//     if ensureMonotonicity then
//       assert(Buildings.Utilities.Math.Functions.isMonotonic(y, false), "If ensureMonotonicity=true, y-values must be monontone increasing or decreasing.");
//     end if;
//   end if;
//   if n == 1 then
//     d[1] := 0.0;
//   elseif n == 2 then
//     d[1] := (y[2] - y[1]) / (x[2] - x[1]);
//     d[2] := d[1];
//   else
//     for i in 1:-1 + n loop
//       delta[i] := (y[1 + i] - y[i]) / (x[1 + i] - x[i]);
//     end for;
//     d[1] := delta[1];
//     d[n] := delta[-1 + n];
//     for i in 2:-1 + n loop
//       d[i] := 0.5 * (delta[-1 + i] + delta[i]);
//     end for;
//   end if;
//   if n > 2 and ensureMonotonicity then
//     for i in 1:-1 + n loop
//       if abs(delta[i]) < 1e-60 then
//         d[i] := 0.0;
//         d[1 + i] := 0.0;
//       else
//         alpha := d[i] / delta[i];
//         beta := d[1 + i] / delta[i];
//         if alpha ^ 2.0 + beta ^ 2.0 > 9.0 then
//           tau := 3.0 / (alpha ^ 2.0 + beta ^ 2.0) ^ 0.5;
//           d[i] := delta[i] * alpha * tau;
//           d[1 + i] := delta[i] * beta * tau;
//         end if;
//       end if;
//     end for;
//   end if;
// end Buildings.Utilities.Math.Functions.splineDerivatives;
//
// function Modelica.Blocks.Continuous.Internal.Filter.Utilities.toHighestPowerOne
//   input Real[:] den1;
//   input Real[:, 2] den2;
//   output Real[size(den1, 1)] cr;
//   output Real[size(den2, 1)] c0;
//   output Real[size(den2, 1)] c1;
// algorithm
//   for i in 1:size(den1, 1) loop
//     cr[i] := 1.0 / den1[i];
//   end for;
//   for i in 1:size(den2, 1) loop
//     c1[i] := den2[i,2] / den2[i,1];
//     c0[i] := 1.0 / den2[i,1];
//   end for;
// end Modelica.Blocks.Continuous.Internal.Filter.Utilities.toHighestPowerOne;
//
// function Modelica.Blocks.Continuous.Internal.Filter.base.CriticalDamping
//   input Integer order(min = 1);
//   input Boolean normalized = true;
//   output Real[order] cr;
//   protected Real alpha = 1.0;
//   protected Real alpha2;
//   protected Real[0, 2] den2;
//   protected Real[0] c0;
//   protected Real[0] c1;
//   protected Real[order] den1;
// algorithm
//   if normalized then
//     alpha := sqrt(-1.0 + 10.0 ^ (0.3 / /*Real*/(order)));
//   else
//     alpha := 1.0;
//   end if;
//   for i in 1:order loop
//     den1[i] := alpha;
//   end for;
//   (cr, c0, c1) := Modelica.Blocks.Continuous.Internal.Filter.Utilities.toHighestPowerOne(den1, {});
// end Modelica.Blocks.Continuous.Internal.Filter.base.CriticalDamping;
//
// function Modelica.Blocks.Continuous.Internal.Filter.coefficients.lowPass
//   input Real[:] cr_in;
//   input Real[:] c0_in;
//   input Real[size(c0_in, 1)] c1_in;
//   input Real f_cut(quantity = "Frequency", unit = "Hz");
//   output Real[size(cr_in, 1)] cr;
//   output Real[size(c0_in, 1)] c0;
//   output Real[size(c0_in, 1)] c1;
//   protected constant Real pi = 3.141592653589793;
//   protected Real w_cut(quantity = "AngularVelocity", unit = "rad/s") = 6.283185307179586 * f_cut;
//   protected Real w_cut2 = w_cut ^ 2.0;
// algorithm
//   assert(f_cut > 0.0, "Cut-off frequency f_cut must be positive");
//   cr := cr_in * w_cut;
//   c1 := c1_in * w_cut;
//   c0 := c0_in * w_cut2;
// end Modelica.Blocks.Continuous.Internal.Filter.coefficients.lowPass;
//
// function Modelica.Blocks.Continuous.Internal.Filter.roots.lowPass
//   input Real[:] cr_in;
//   input Real[:] c0_in;
//   input Real[size(c0_in, 1)] c1_in;
//   input Real f_cut(quantity = "Frequency", unit = "Hz");
//   output Real[size(cr_in, 1)] r;
//   output Real[size(c0_in, 1)] a;
//   output Real[size(c0_in, 1)] b;
//   output Real[size(c0_in, 1)] ku;
//   protected Real[size(cr_in, 1)] cr;
//   protected Real[size(c0_in, 1)] c0;
//   protected Real[size(c0_in, 1)] c1;
// algorithm
//   (cr, c0, c1) := Modelica.Blocks.Continuous.Internal.Filter.coefficients.lowPass(cr_in, c0_in, c1_in, f_cut);
//   for i in 1:size(cr_in, 1) loop
//     r[i] := -cr[i];
//   end for;
//   for i in 1:size(c0_in, 1) loop
//     a[i] := (-0.5) * c1[i];
//     b[i] := sqrt(c0[i] - a[i] ^ 2.0);
//     ku[i] := c0[i] / b[i];
//   end for;
// end Modelica.Blocks.Continuous.Internal.Filter.roots.lowPass;
//
// function Modelica.Blocks.Sources.CombiTimeTable$timTab.getDerTableValue
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   input Integer icol;
//   input Real timeIn(quantity = "Time", unit = "s");
//   discrete input Real nextTimeEvent(quantity = "Time", unit = "s");
//   discrete input Real pre_nextTimeEvent(quantity = "Time", unit = "s");
//   input Real tableAvailable;
//   input Real der_timeIn;
//   output Real der_y;
//
//   external "C" der_y = ModelicaStandardTables_CombiTimeTable_getDerValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent, der_timeIn);
// end Modelica.Blocks.Sources.CombiTimeTable$timTab.getDerTableValue;
//
// function Modelica.Blocks.Sources.CombiTimeTable$timTab.getNextTimeEvent
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   input Real timeIn(quantity = "Time", unit = "s");
//   input Real tableAvailable;
//   output Real nextTimeEvent(quantity = "Time", unit = "s");
//
//   external "C" nextTimeEvent = ModelicaStandardTables_CombiTimeTable_nextTimeEvent(tableID, timeIn);
// end Modelica.Blocks.Sources.CombiTimeTable$timTab.getNextTimeEvent;
//
// function Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableTimeTmax
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   input Real tableAvailable;
//   output Real timeMax(quantity = "Time", unit = "s");
//
//   external "C" timeMax = ModelicaStandardTables_CombiTimeTable_maximumTime(tableID);
// end Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableTimeTmax;
//
// function Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableTimeTmin
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   input Real tableAvailable;
//   output Real timeMin(quantity = "Time", unit = "s");
//
//   external "C" timeMin = ModelicaStandardTables_CombiTimeTable_minimumTime(tableID);
// end Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableTimeTmin;
//
// function Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableValue
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   input Integer icol;
//   input Real timeIn(quantity = "Time", unit = "s");
//   discrete input Real nextTimeEvent(quantity = "Time", unit = "s");
//   discrete input Real pre_nextTimeEvent(quantity = "Time", unit = "s");
//   input Real tableAvailable;
//   output Real y;
//
//   external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent);
// end Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableValue;
//
// function Modelica.Blocks.Sources.CombiTimeTable$timTab.readTableData
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   input Boolean forceRead = false;
//   output Real readSuccess;
//   input Boolean verboseRead;
//
//   external "C" readSuccess = ModelicaStandardTables_CombiTimeTable_read(tableID, forceRead, verboseRead);
// end Modelica.Blocks.Sources.CombiTimeTable$timTab.readTableData;
//
// function Modelica.Blocks.Types.ExternalCombiTimeTable.constructor
//   input String tableName;
//   input String fileName;
//   input Real[:, :] table;
//   input Real startTime(quantity = "Time", unit = "s");
//   input Integer[:] columns;
//   input enumeration(LinearSegments, ContinuousDerivative, ConstantSegments) smoothness;
//   input enumeration(HoldLastPoint, LastTwoPoints, Periodic, NoExtrapolation) extrapolation;
//   output Modelica.Blocks.Types.ExternalCombiTimeTable externalCombiTimeTable;
//
//   external "C" externalCombiTimeTable = ModelicaStandardTables_CombiTimeTable_init(tableName, fileName, table, size(table, 1), size(table, 2), startTime, columns, size(columns, 1), smoothness, extrapolation);
// end Modelica.Blocks.Types.ExternalCombiTimeTable.constructor;
//
// function Modelica.Blocks.Types.ExternalCombiTimeTable.destructor
//   input Modelica.Blocks.Types.ExternalCombiTimeTable externalCombiTimeTable;
//
//   external "C" ModelicaStandardTables_CombiTimeTable_close(externalCombiTimeTable);
// end Modelica.Blocks.Types.ExternalCombiTimeTable.destructor;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pumRad$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$pumRad$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$pumRad$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pumRad$port_a.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPort_a$pumRad$port_a.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pumRad$preSou$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$pumRad$preSou$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$pumRad$preSou$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$pumRad$preSou$port_a.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPort_a$pumRad$preSou$port_a.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$rad$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$rad$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$rad$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$rad$port_a.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPort_a$rad$port_a.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$temSup$port_a.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_a$temSup$port_a.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_a$temSup$port_a.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_a$temSup$port_a.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPort_a$temSup$port_a.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$pumRad$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$pumRad$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$pumRad$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$pumRad$port_b.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPort_b$pumRad$port_b.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$pumRad$preSou$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$pumRad$preSou$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$pumRad$preSou$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$pumRad$preSou$port_b.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPort_b$pumRad$preSou$port_b.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$rad$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$rad$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$rad$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$rad$port_b.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPort_b$rad$port_b.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$temSup$port_b.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPort_b$temSup$port_b.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPort_b$temSup$port_b.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPort_b$temSup$port_b.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPort_b$temSup$port_b.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$sin$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPorts_b$sin$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPorts_b$sin$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$sin$ports.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPorts_b$sin$ports.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$sou$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Interfaces.FluidPorts_b$sou$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Interfaces.FluidPorts_b$sou$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Interfaces.FluidPorts_b$sou$ports.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Interfaces.FluidPorts_b$sou$ports.Medium.specificEnthalpy_pTX;
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
// function Modelica.Fluid.Utilities.cubicHermite
//   input Real x;
//   input Real x1;
//   input Real x2;
//   input Real y1;
//   input Real y2;
//   input Real y1d;
//   input Real y2d;
//   output Real y;
//   protected Real h;
//   protected Real t;
//   protected Real h00;
//   protected Real h10;
//   protected Real h01;
//   protected Real h11;
//   protected Real aux3;
//   protected Real aux2;
// algorithm
//   h := x2 - x1;
//   if abs(h) > 0.0 then
//     t := (x - x1) / h;
//     aux3 := t ^ 3.0;
//     aux2 := t ^ 2.0;
//     h00 := 1.0 + 2.0 * aux3 + (-3.0) * aux2;
//     h10 := aux3 + (-2.0) * aux2 + t;
//     h01 := 3.0 * aux2 + (-2.0) * aux3;
//     h11 := aux3 - aux2;
//     y := y1 * h00 + h * y1d * h10 + y2 * h01 + h * y2d * h11;
//   else
//     y := 0.5 * (y1 + y2);
//   end if;
// end Modelica.Fluid.Utilities.cubicHermite;
//
// function Modelica.Fluid.Utilities.regStep
//   input Real x;
//   input Real y1;
//   input Real y2;
//   input Real x_small(min = 0.0) = 1e-05;
//   output Real y;
// algorithm
//   y := smooth(1, if x > x_small then y1 else if x < (-x_small) then y2 else if x_small > 0.0 then 0.25 * x * (-3.0 + (x / x_small) ^ 2.0) * (y2 - y1) / x_small + 0.5 * (y1 + y2) else 0.5 * (y1 + y2));
// end Modelica.Fluid.Utilities.regStep;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$dynBal$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$dynBal$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$dynBal$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$dynBal$ports.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$dynBal$ports.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$ports.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$pumRad$vol$ports.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$dynBal$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$dynBal$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$dynBal$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$dynBal$ports.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$dynBal$ports.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$ports.Medium.FluidConstants"
//   input String iupacName;
//   input String casRegistryNumber;
//   input String chemicalFormula;
//   input String structureFormula;
//   input Real molarMass(min = 0.001, max = 0.25, nominal = 0.032, quantity = "MolarMass", unit = "kg/mol");
//   output FluidConstants res;
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$ports.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$rad$vol$ports.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.FluidConstants"
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
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.ThermodynamicState "Automatically generated record constructor for Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.ThermodynamicState;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.setState_pTX;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.specificEnthalpy
//   input Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.specificEnthalpy;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.specificEnthalpy(/*.Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.ThermodynamicState*/(Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.setState_pTX(p, T, X)));
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$dynBal$ports.Medium.specificEnthalpy_pTX;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.FluidConstants "Automatically generated record constructor for Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.FluidConstants"
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
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.FluidConstants;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.ThermodynamicState "Automatically generated record constructor for Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.ThermodynamicState"
//   input Real p(min = 0.0, max = 100000000.0, nominal = 100000.0, start = 100000.0, quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(min = 1.0, max = 10000.0, nominal = 300.0, start = 300.0, quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC");
//   input Real[2] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output ThermodynamicState res;
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.ThermodynamicState;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.setState_pTX;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.specificEnthalpy
//   input Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Buildings.Media.GasesPTDecoupled.MoistAirUnsaturated.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.specificEnthalpy;
//
// function Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.specificEnthalpy(/*.Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.ThermodynamicState*/(Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.setState_pTX(p, T, X)));
// end Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b$vol$ports.Medium.specificEnthalpy_pTX;
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
// function Modelica.Media.Air.MoistAir.Utilities.spliceFunction
//   input Real pos;
//   input Real neg;
//   input Real x;
//   input Real deltax = 1.0;
//   output Real out;
//   protected Real scaledX;
//   protected Real scaledX1;
//   protected Real y;
// algorithm
//   scaledX1 := x / deltax;
//   scaledX := 1.570796326794897 * scaledX1;
//   if scaledX1 <= -0.999999999 then
//     y := 0.0;
//   elseif scaledX1 >= 0.999999999 then
//     y := 1.0;
//   else
//     y := 0.5 + 0.5 * tanh(tan(scaledX));
//   end if;
//   out := pos * y + (1.0 - y) * neg;
// end Modelica.Media.Air.MoistAir.Utilities.spliceFunction;
//
// function Modelica.Media.Air.MoistAir.enthalpyOfWater
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg");
// algorithm
//   h := Modelica.Media.Air.MoistAir.Utilities.spliceFunction(4200.0 * (-273.15 + T), -333000.0 + 2050.0 * (-273.15 + T), -273.16 + T, 0.1);
// end Modelica.Media.Air.MoistAir.enthalpyOfWater;
//
// function Modelica.Media.Air.MoistAir.h_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg");
//   protected Real p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real X_sat(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real X_liquid(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real X_steam(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected Real X_air(quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
// algorithm
//   p_steam_sat := Modelica.Media.Air.MoistAir.saturationPressure(T);
//   X_sat := min(0.6219647130774989 * p_steam_sat * (1.0 - X[1]) / max(1e-13, p - p_steam_sat), 1.0);
//   X_liquid := max(X[1] - X_sat, 0.0);
//   X_steam := X[1] - X_liquid;
//   X_air := 1.0 - X[1];
//   h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(Modelica.Media.IdealGases.Common.DataRecord("H2O", 0.01801528, -13423382.81725291, 549760.6476280135, 1000, {-39479.6083, 575.5731019999999, 0.931782653, 0.00722271286, -7.34255737e-06, 4.95504349e-09, -1.336933246e-12}, {-33039.7431, 17.24205775}, {1034972.096, -2412.698562, 4.64611078, 0.002291998307, -6.836830479999999e-07, 9.426468930000001e-11, -4.82238053e-15}, {-13842.86509, -7.97814851}, 461.5233290850878), T, true, Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, 2547494.319) * X_steam + Modelica.Media.IdealGases.Common.Functions.h_Tlow(Modelica.Media.IdealGases.Common.DataRecord("Air", 0.0289651159, -4333.833858403446, 298609.6803431054, 1000, {10099.5016, -196.827561, 5.00915511, -0.00576101373, 1.06685993e-05, -7.94029797e-09, 2.18523191e-12}, {-176.796731, -3.921504225}, {241521.443, -1257.8746, 5.14455867, -0.000213854179, 7.06522784e-08, -1.07148349e-11, 6.57780015e-16}, {6462.26319, -8.147411905}, 287.0512249529787), T, true, Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, 25104.684) * X_air + Modelica.Media.Air.MoistAir.enthalpyOfWater(T) * X_liquid;
// end Modelica.Media.Air.MoistAir.h_pTX;
//
// function Modelica.Media.Air.MoistAir.saturationPressure
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
// algorithm
//   psat := Modelica.Media.Air.MoistAir.Utilities.spliceFunction(Modelica.Media.Air.MoistAir.saturationPressureLiquid(Tsat), Modelica.Media.Air.MoistAir.sublimationPressureIce(Tsat), -273.16 + Tsat, 1.0);
// end Modelica.Media.Air.MoistAir.saturationPressure;
//
// function Modelica.Media.Air.MoistAir.saturationPressureLiquid
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real Tcritical(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 647.096;
//   protected Real pcritical(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 22064000.0;
//   protected Real[6] a = {-7.85951783, 1.84408259, -11.7866497, 22.6807411, -15.9618719, 1.80122502};
//   protected Real[6] n = {1.0, 1.5, 3.0, 3.5, 4.0, 7.5};
//   protected Real r1 = 1.0 - Tsat / Tcritical;
// algorithm
//   psat := exp((a[1] * r1 ^ n[1] + a[2] * r1 ^ n[2] + a[3] * r1 ^ n[3] + a[4] * r1 ^ n[4] + a[5] * r1 ^ n[5] + a[6] * r1 ^ n[6]) * Tcritical / Tsat) * pcritical;
// end Modelica.Media.Air.MoistAir.saturationPressureLiquid;
//
// function Modelica.Media.Air.MoistAir.setState_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Modelica.Media.Air.MoistAir.ThermodynamicState state;
// algorithm
//   state := if size(X, 1) == 2 then Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, X) else Modelica.Media.Air.MoistAir.ThermodynamicState(p, T, cat(1, X, {1.0 - sum(X)}));
// end Modelica.Media.Air.MoistAir.setState_pTX;
//
// function Modelica.Media.Air.MoistAir.specificEnthalpy
//   input Modelica.Media.Air.MoistAir.ThermodynamicState state;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Modelica.Media.Air.MoistAir.h_pTX(state.p, state.T, {state.X[1], state.X[2]});
// end Modelica.Media.Air.MoistAir.specificEnthalpy;
//
// function Modelica.Media.Air.MoistAir.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 190.0, max = 647.0, start = 300.0, nominal = 300.0);
//   input Real[:] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = {0.01, 0.99};
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := Modelica.Media.Air.MoistAir.specificEnthalpy(Modelica.Media.Air.MoistAir.setState_pTX(p, T, X));
// end Modelica.Media.Air.MoistAir.specificEnthalpy_pTX;
//
// function Modelica.Media.Air.MoistAir.sublimationPressureIce
//   input Real Tsat(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   output Real psat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   protected Real Ttriple(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 273.16;
//   protected Real ptriple(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 611.657;
//   protected Real[2] a = {-13.928169, 34.7078238};
//   protected Real[2] n = {-1.5, -1.25};
//   protected Real r1 = Tsat / Ttriple;
// algorithm
//   psat := exp(a[1] + a[2] + (-a[1]) * r1 ^ n[1] - a[2] * r1 ^ n[2]) * ptriple;
// end Modelica.Media.Air.MoistAir.sublimationPressureIce;
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
// function Modelica.Media.IdealGases.Common.Functions.h_Tlow
//   input Modelica.Media.IdealGases.Common.DataRecord data;
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   input Boolean exclEnthForm = true;
//   input enumeration(ZeroAt0K, ZeroAt25C, UserDefined) refChoice = Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K;
//   input Real h_off(quantity = "SpecificEnergy", unit = "J/kg") = 0.0;
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg");
// algorithm
//   h := data.R * (T * (data.blow[1] + data.alow[2] * log(T) + T * (data.alow[3] + T * (0.5 * data.alow[4] + T * (0.3333333333333333 * data.alow[5] + T * (0.25 * data.alow[6] + 0.2 * data.alow[7] * T))))) - data.alow[1]) / T + (if exclEnthForm then -data.Hf else 0.0) + (if refChoice == Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K then data.H0 else 0.0) + (if refChoice == Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined then h_off else 0.0);
// end Modelica.Media.IdealGases.Common.Functions.h_Tlow;
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
// function Modelica.Media.Water.ConstantPropertyLiquidWater.specificEnthalpy_pTX
//   input Real p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   input Real T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   input Real[1] X(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   output Real h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
// algorithm
//   h := 4184.0 * (-273.15 + T);
// end Modelica.Media.Water.ConstantPropertyLiquidWater.specificEnthalpy_pTX;
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
// function Modelica.Utilities.Strings.Advanced.skipWhiteSpace
//   input String string;
//   input Integer startIndex(min = 1) = 1;
//   output Integer nextIndex;
//
//   external "C" nextIndex = ModelicaStrings_skipWhiteSpace(string, startIndex);
// end Modelica.Utilities.Strings.Advanced.skipWhiteSpace;
//
// function Modelica.Utilities.Strings.isEmpty
//   input String string;
//   output Boolean result;
//   protected Integer nextIndex;
//   protected Integer len;
// algorithm
//   nextIndex := Modelica.Utilities.Strings.Advanced.skipWhiteSpace(string, 1);
//   len := Modelica.Utilities.Strings.length(string);
//   if len < 1 or nextIndex > len then
//     result := true;
//   else
//     result := false;
//   end if;
// end Modelica.Utilities.Strings.isEmpty;
//
// function Modelica.Utilities.Strings.length
//   input String string;
//   output Integer result;
//
//   external "C" result = ModelicaStrings_length(string);
// end Modelica.Utilities.Strings.length;
//
// class System2
//   parameter Real Q_flow_nominal(quantity = "Power", unit = "W") = 20000.0;
//   parameter Real TRadSup_nominal(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 323.15;
//   parameter Real TRadRet_nominal(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 313.15;
//   parameter Real mRad_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 0.0002380952380952381 * Q_flow_nominal / (TRadSup_nominal - TRadRet_nominal);
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
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) vol.energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) vol.massDynamics = vol.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) vol.substanceDynamics = vol.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) vol.traceDynamics = vol.energyDynamics;
//   parameter Real vol.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 101325.0;
//   parameter Real vol.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   parameter Real vol.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.01;
//   parameter Real vol.X_start[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.99;
//   parameter Real vol.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = mA_flow_nominal;
//   parameter Integer vol.nPorts = 0;
//   parameter Real vol.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(vol.m_flow_nominal);
//   parameter Boolean vol.homotopyInitialization = true;
//   parameter Boolean vol.allowFlowReversal = system.allowFlowReversal;
//   parameter Real vol.V(quantity = "Volume", unit = "m3") = V;
//   parameter Boolean vol.prescribedHeatFlowRate = false;
//   Real vol.heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real vol.heatPort.Q_flow(quantity = "Power", unit = "W");
//   Real vol.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real vol.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   Real vol.Xi[1](quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   protected parameter Real vol.state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 101325.0;
//   protected parameter Real vol.state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real vol.state_start.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.01;
//   protected parameter Real vol.state_start.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 0.99;
//   protected parameter Real vol.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.density(/*.Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.ThermodynamicState*/(Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.setState_pTX(vol.p_start, vol.T_start, {vol.X_start[1]})));
//   protected final parameter Boolean vol.useSteadyStateTwoPort = vol.nPorts == 2 and vol.prescribedHeatFlowRate and vol.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and vol.massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and vol.substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and vol.traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected Real vol.Q_flow(quantity = "Power", unit = "W");
//   protected Real vol.hOut_internal(unit = "J/kg");
//   protected Real vol.XiOut_internal[1](unit = "1");
//   protected Real vol.heaInp.y = vol.heatPort.Q_flow;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) vol.dynBal.energyDynamics = vol.energyDynamics;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) vol.dynBal.massDynamics = vol.massDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) vol.dynBal.substanceDynamics = vol.dynBal.energyDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) vol.dynBal.traceDynamics = vol.dynBal.energyDynamics;
//   protected parameter Real vol.dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = vol.p_start;
//   protected parameter Real vol.dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = vol.T_start;
//   protected parameter Real vol.dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = vol.X_start[1];
//   protected parameter Real vol.dynBal.X_start[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = vol.X_start[2];
//   protected parameter Integer vol.dynBal.nPorts = vol.nPorts;
//   protected Real vol.dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = vol.dynBal.p_start, nominal = 101325.0, stateSelect = StateSelect.prefer);
//   protected Real vol.dynBal.medium.Xi[1](quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0, start = vol.dynBal.X_start[1], nominal = 0.01, stateSelect = StateSelect.prefer);
//   protected Real vol.dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.specificEnthalpy_pTX(vol.dynBal.p_start, vol.dynBal.T_start, {vol.dynBal.X_start[1], vol.dynBal.X_start[2]}));
//   protected Real vol.dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = vol.dynBal.rho_nominal, nominal = 1.0);
//   protected Real vol.dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = vol.dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected Real vol.dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 0.01, nominal = 0.1);
//   protected Real vol.dynBal.medium.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 0.99, nominal = 0.1);
//   protected Real vol.dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   protected Real vol.dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   protected Real vol.dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected Real vol.dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real vol.dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected Real vol.dynBal.medium.state.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real vol.dynBal.medium.state.X[2](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected parameter Boolean vol.dynBal.medium.preferredMediumStates = not vol.dynBal.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected parameter Boolean vol.dynBal.medium.standardOrderComponents = true;
//   protected Real vol.dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(vol.dynBal.medium.T);
//   protected Real vol.dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(vol.dynBal.medium.p);
//   protected Real vol.dynBal.medium.x_water(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real vol.dynBal.medium.phi;
//   protected constant Real vol.dynBal.medium.MMX[1](quantity = "MolarMass", unit = "kg/mol", min = 0.0) = steam.MM;
//   protected constant Real vol.dynBal.medium.MMX[2](quantity = "MolarMass", unit = "kg/mol", min = 0.0) = dryair.MM;
//   protected Real vol.dynBal.medium.X_steam(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real vol.dynBal.medium.X_air(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real vol.dynBal.medium.X_sat(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real vol.dynBal.medium.x_sat(quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1);
//   protected Real vol.dynBal.medium.p_steam_sat(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real vol.dynBal.U(quantity = "Energy", unit = "J", start = vol.V * vol.rho_nominal * Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.specificInternalEnergy(vol.state_start));
//   protected Real vol.dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = vol.V * vol.rho_nominal);
//   protected Real vol.dynBal.mXi[1](quantity = "Mass", unit = "kg", min = 0.0);
//   protected Real vol.dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected Real vol.dynBal.mbXi_flow[1](quantity = "MassFlowRate", unit = "kg/s");
//   protected Real vol.dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected Real vol.dynBal.fluidVolume(quantity = "Volume", unit = "m3") = vol.V;
//   protected Real vol.dynBal.Q_flow(unit = "W");
//   protected Real vol.dynBal.mXi_flow[1](unit = "kg/s");
//   protected Real vol.dynBal.hOut(unit = "J/kg");
//   protected Real vol.dynBal.XiOut[1](unit = "1", min = 0.0, max = 1.0);
//   protected parameter Boolean vol.dynBal.initialize_p = true;
//   protected parameter Real vol.dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.density(/*.Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.ThermodynamicState*/(Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.setState_pTX(vol.dynBal.p_start, vol.dynBal.T_start, {vol.dynBal.X_start[1]})));
//   protected Real vol.masExc[1].y;
//   protected parameter Real vol.masExc[1].k(start = 1.0) = 0.0;
//   Real theCon.Q_flow(quantity = "Power", unit = "W");
//   Real theCon.dT(quantity = "ThermodynamicTemperature", unit = "K");
//   Real theCon.port_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real theCon.port_a.Q_flow(quantity = "Power", unit = "W");
//   Real theCon.port_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real theCon.port_b.Q_flow(quantity = "Power", unit = "W");
//   parameter Real theCon.G(quantity = "ThermalConductance", unit = "W/K") = 666.6666666666666;
//   parameter Real V(quantity = "Volume", unit = "m3") = 180.0;
//   parameter Real mA_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = 0.001666666666666667 * V;
//   parameter Real QRooInt_flow(quantity = "Power", unit = "W") = 4000.0;
//   parameter Real TOut.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 263.15;
//   Real TOut.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real TOut.port.Q_flow(quantity = "Power", unit = "W");
//   parameter Real preHea.T_ref(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 293.15;
//   parameter Real preHea.alpha(quantity = "LinearTemperatureCoefficient", unit = "1/K") = 0.0;
//   Real preHea.Q_flow(unit = "W");
//   Real preHea.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real preHea.port.Q_flow(quantity = "Power", unit = "W");
//   parameter Real heaCap.C(quantity = "HeatCapacity", unit = "J/K") = 2414.4 * V;
//   Real heaCap.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 293.15, nominal = 300.0);
//   Real heaCap.der_T(quantity = "TemperatureSlope", unit = "K/s", start = 0.0);
//   Real heaCap.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real heaCap.port.Q_flow(quantity = "Power", unit = "W");
//   parameter Integer timTab.nout(min = 1) = 1;
//   Real timTab.y[1];
//   parameter Boolean timTab.tableOnFile = false;
//   parameter Real timTab.table[1,1] = 0.0;
//   parameter Real timTab.table[1,2] = 0.0;
//   parameter Real timTab.table[2,1] = 28800.0;
//   parameter Real timTab.table[2,2] = 0.0;
//   parameter Real timTab.table[3,1] = 28800.0;
//   parameter Real timTab.table[3,2] = QRooInt_flow;
//   parameter Real timTab.table[4,1] = 64800.0;
//   parameter Real timTab.table[4,2] = QRooInt_flow;
//   parameter Real timTab.table[5,1] = 64800.0;
//   parameter Real timTab.table[5,2] = 0.0;
//   parameter Real timTab.table[6,1] = 86400.0;
//   parameter Real timTab.table[6,2] = 0.0;
//   parameter String timTab.tableName = "NoName";
//   parameter String timTab.fileName = "NoName";
//   parameter Boolean timTab.verboseRead = true;
//   parameter Integer timTab.columns[1] = 2;
//   parameter enumeration(LinearSegments, ContinuousDerivative, ConstantSegments) timTab.smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments;
//   parameter enumeration(HoldLastPoint, LastTwoPoints, Periodic, NoExtrapolation) timTab.extrapolation = Modelica.Blocks.Types.Extrapolation.Periodic;
//   parameter Real timTab.offset[1] = 0.0;
//   parameter Real timTab.startTime(quantity = "Time", unit = "s") = 0.0;
//   final parameter Real timTab.t_min(quantity = "Time", unit = "s", fixed = false);
//   final parameter Real timTab.t_max(quantity = "Time", unit = "s", fixed = false);
//   protected final parameter Real timTab.p_offset[1] = timTab.offset[1];
//   protected Modelica.Blocks.Types.ExternalCombiTimeTable timTab.tableID = Modelica.Blocks.Types.ExternalCombiTimeTable.constructor(if timTab.tableOnFile then timTab.tableName else "NoName", if timTab.tableOnFile and timTab.fileName <> "NoName" and not Modelica.Utilities.Strings.isEmpty(timTab.fileName) then timTab.fileName else "NoName", {{timTab.table[1,1], timTab.table[1,2]}, {timTab.table[2,1], timTab.table[2,2]}, {timTab.table[3,1], timTab.table[3,2]}, {timTab.table[4,1], timTab.table[4,2]}, {timTab.table[5,1], timTab.table[5,2]}, {timTab.table[6,1], timTab.table[6,2]}}, timTab.startTime, {timTab.columns[1]}, timTab.smoothness, timTab.extrapolation);
//   protected discrete Real timTab.nextTimeEvent(quantity = "Time", unit = "s", start = 0.0, fixed = true);
//   protected parameter Real timTab.tableOnFileRead(fixed = false);
//   parameter Boolean rad.allowFlowReversal = system.allowFlowReversal;
//   Real rad.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if rad.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real rad.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 300000.0);
//   Real rad.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if rad.allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real rad.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 300000.0);
//   Real rad.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter Boolean rad.port_a_exposesState = false;
//   protected parameter Boolean rad.port_b_exposesState = false;
//   protected parameter Boolean rad.showDesignFlowDirection = false;
//   parameter Real rad.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = abs(rad.Q_flow_nominal / ((rad.T_a_nominal - rad.T_b_nominal) * rad.cp_nominal));
//   parameter Real rad.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(rad.m_flow_nominal);
//   parameter Boolean rad.homotopyInitialization = true;
//   parameter Boolean rad.show_V_flow = false;
//   parameter Boolean rad.show_T = true;
//   Real rad.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = 0.0) = rad.port_a.m_flow;
//   Real rad.dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0);
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.massDynamics = rad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.substanceDynamics = rad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.traceDynamics = rad.energyDynamics;
//   parameter Real rad.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   parameter Real rad.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   parameter Real rad.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   parameter Integer rad.nEle(min = 1) = 5;
//   parameter Real rad.fraRad(min = 0.0, max = 1.0) = 0.35;
//   parameter Real rad.Q_flow_nominal(quantity = "Power", unit = "W") = Q_flow_nominal;
//   parameter Real rad.T_a_nominal(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = TRadSup_nominal;
//   parameter Real rad.T_b_nominal(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = TRadRet_nominal;
//   parameter Real rad.TAir_nominal(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 293.15;
//   parameter Real rad.TRad_nominal(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = rad.TAir_nominal;
//   parameter Real rad.n = 1.24;
//   parameter Real rad.VWat(quantity = "Volume", unit = "m3") = 5.8e-06 * abs(rad.Q_flow_nominal);
//   Real rad.QCon_flow(quantity = "Power", unit = "W");
//   Real rad.QRad_flow(quantity = "Power", unit = "W");
//   Real rad.Q_flow(quantity = "Power", unit = "W");
//   Real rad.heatPortCon.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.heatPortCon.Q_flow(quantity = "Power", unit = "W");
//   Real rad.heatPortRad.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.heatPortRad.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloCon[1].Q_flow;
//   Real rad.preHeaFloCon[1].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloCon[1].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloCon[2].Q_flow;
//   Real rad.preHeaFloCon[2].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloCon[2].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloCon[3].Q_flow;
//   Real rad.preHeaFloCon[3].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloCon[3].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloCon[4].Q_flow;
//   Real rad.preHeaFloCon[4].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloCon[4].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloCon[5].Q_flow;
//   Real rad.preHeaFloCon[5].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloCon[5].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloRad[1].Q_flow;
//   Real rad.preHeaFloRad[1].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloRad[1].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloRad[2].Q_flow;
//   Real rad.preHeaFloRad[2].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloRad[2].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloRad[3].Q_flow;
//   Real rad.preHeaFloRad[3].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloRad[3].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloRad[4].Q_flow;
//   Real rad.preHeaFloRad[4].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloRad[4].port.Q_flow(quantity = "Power", unit = "W");
//   Real rad.preHeaFloRad[5].Q_flow;
//   Real rad.preHeaFloRad[5].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.preHeaFloRad[5].port.Q_flow(quantity = "Power", unit = "W");
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[1].energyDynamics = rad.energyDynamics;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[1].massDynamics = rad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[1].substanceDynamics = rad.vol[1].energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[1].traceDynamics = rad.vol[1].energyDynamics;
//   parameter Real rad.vol[1].p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.p_start;
//   parameter Real rad.vol[1].T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.T_start;
//   parameter Real rad.vol[1].X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.X_start[1];
//   parameter Real rad.vol[1].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = rad.m_flow_nominal;
//   parameter Integer rad.vol[1].nPorts = 2;
//   parameter Real rad.vol[1].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(rad.vol[1].m_flow_nominal);
//   parameter Boolean rad.vol[1].homotopyInitialization = true;
//   parameter Boolean rad.vol[1].allowFlowReversal = system.allowFlowReversal;
//   parameter Real rad.vol[1].V(quantity = "Volume", unit = "m3") = rad.VWat / /*Real*/(rad.nEle);
//   parameter Boolean rad.vol[1].prescribedHeatFlowRate = false;
//   Real rad.vol[1].ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[1].ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[1].ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[1].ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[1].ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[1].ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[1].heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[1].heatPort.Q_flow(quantity = "Power", unit = "W");
//   Real rad.vol[1].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   protected parameter Real rad.vol[1].state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real rad.vol[1].state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real rad.vol[1].rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.density(Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.setState_pTX(rad.vol[1].p_start, rad.vol[1].T_start, {}));
//   protected final parameter Boolean rad.vol[1].useSteadyStateTwoPort = rad.vol[1].nPorts == 2 and rad.vol[1].prescribedHeatFlowRate and rad.vol[1].energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[1].massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[1].substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[1].traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected Real rad.vol[1].Q_flow(quantity = "Power", unit = "W");
//   protected Real rad.vol[1].hOut_internal(unit = "J/kg");
//   protected Real rad.vol[1].heaInp.y = rad.vol[1].heatPort.Q_flow;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[1].dynBal.energyDynamics = rad.vol[1].energyDynamics;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[1].dynBal.massDynamics = rad.vol[1].massDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[1].dynBal.substanceDynamics = rad.vol[1].dynBal.energyDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[1].dynBal.traceDynamics = rad.vol[1].dynBal.energyDynamics;
//   protected parameter Real rad.vol[1].dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.vol[1].p_start;
//   protected parameter Real rad.vol[1].dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.vol[1].T_start;
//   protected parameter Real rad.vol[1].dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.vol[1].X_start[1];
//   protected parameter Integer rad.vol[1].dynBal.nPorts = rad.vol[1].nPorts;
//   protected Real rad.vol[1].dynBal.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[1].dynBal.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[1].dynBal.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[1].dynBal.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[1].dynBal.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[1].dynBal.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[1].dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = rad.vol[1].dynBal.p_start, nominal = 300000.0, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[1].dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[1].dynBal.p_start, rad.vol[1].dynBal.T_start, {rad.vol[1].dynBal.X_start[1]}));
//   protected Real rad.vol[1].dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = rad.vol[1].dynBal.rho_nominal, nominal = 1.0);
//   protected Real rad.vol[1].dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = rad.vol[1].dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[1].dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   protected Real rad.vol[1].dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   protected Real rad.vol[1].dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   protected Real rad.vol[1].dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected Real rad.vol[1].dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[1].dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected parameter Boolean rad.vol[1].dynBal.medium.preferredMediumStates = not rad.vol[1].dynBal.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected parameter Boolean rad.vol[1].dynBal.medium.standardOrderComponents = true;
//   protected Real rad.vol[1].dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(rad.vol[1].dynBal.medium.T);
//   protected Real rad.vol[1].dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(rad.vol[1].dynBal.medium.p);
//   protected Real rad.vol[1].dynBal.U(quantity = "Energy", unit = "J", start = rad.vol[1].V * rad.vol[1].rho_nominal * Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificInternalEnergy(rad.vol[1].state_start));
//   protected Real rad.vol[1].dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = rad.vol[1].V * rad.vol[1].rho_nominal);
//   protected Real rad.vol[1].dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected Real rad.vol[1].dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected Real rad.vol[1].dynBal.fluidVolume(quantity = "Volume", unit = "m3") = rad.vol[1].V;
//   protected Real rad.vol[1].dynBal.Q_flow(unit = "W");
//   protected Real rad.vol[1].dynBal.hOut(unit = "J/kg");
//   protected parameter Boolean rad.vol[1].dynBal.initialize_p = false;
//   protected Real rad.vol[1].dynBal.ports_H_flow[1](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected Real rad.vol[1].dynBal.ports_H_flow[2](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected parameter Real rad.vol[1].dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.density(Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.setState_pTX(rad.vol[1].dynBal.p_start, rad.vol[1].dynBal.T_start, {}));
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[2].energyDynamics = rad.energyDynamics;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[2].massDynamics = rad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[2].substanceDynamics = rad.vol[2].energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[2].traceDynamics = rad.vol[2].energyDynamics;
//   parameter Real rad.vol[2].p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.p_start;
//   parameter Real rad.vol[2].T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.T_start;
//   parameter Real rad.vol[2].X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.X_start[1];
//   parameter Real rad.vol[2].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = rad.m_flow_nominal;
//   parameter Integer rad.vol[2].nPorts = 2;
//   parameter Real rad.vol[2].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(rad.vol[2].m_flow_nominal);
//   parameter Boolean rad.vol[2].homotopyInitialization = true;
//   parameter Boolean rad.vol[2].allowFlowReversal = system.allowFlowReversal;
//   parameter Real rad.vol[2].V(quantity = "Volume", unit = "m3") = rad.VWat / /*Real*/(rad.nEle);
//   parameter Boolean rad.vol[2].prescribedHeatFlowRate = false;
//   Real rad.vol[2].ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[2].ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[2].ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[2].ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[2].ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[2].ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[2].heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[2].heatPort.Q_flow(quantity = "Power", unit = "W");
//   Real rad.vol[2].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   protected parameter Real rad.vol[2].state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real rad.vol[2].state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real rad.vol[2].rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.density(Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.setState_pTX(rad.vol[2].p_start, rad.vol[2].T_start, {}));
//   protected final parameter Boolean rad.vol[2].useSteadyStateTwoPort = rad.vol[2].nPorts == 2 and rad.vol[2].prescribedHeatFlowRate and rad.vol[2].energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[2].massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[2].substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[2].traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected Real rad.vol[2].Q_flow(quantity = "Power", unit = "W");
//   protected Real rad.vol[2].hOut_internal(unit = "J/kg");
//   protected Real rad.vol[2].heaInp.y = rad.vol[2].heatPort.Q_flow;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[2].dynBal.energyDynamics = rad.vol[2].energyDynamics;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[2].dynBal.massDynamics = rad.vol[2].massDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[2].dynBal.substanceDynamics = rad.vol[2].dynBal.energyDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[2].dynBal.traceDynamics = rad.vol[2].dynBal.energyDynamics;
//   protected parameter Real rad.vol[2].dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.vol[2].p_start;
//   protected parameter Real rad.vol[2].dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.vol[2].T_start;
//   protected parameter Real rad.vol[2].dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.vol[2].X_start[1];
//   protected parameter Integer rad.vol[2].dynBal.nPorts = rad.vol[2].nPorts;
//   protected Real rad.vol[2].dynBal.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[2].dynBal.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[2].dynBal.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[2].dynBal.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[2].dynBal.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[2].dynBal.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[2].dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = rad.vol[2].dynBal.p_start, nominal = 300000.0, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[2].dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[2].dynBal.p_start, rad.vol[2].dynBal.T_start, {rad.vol[2].dynBal.X_start[1]}));
//   protected Real rad.vol[2].dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = rad.vol[2].dynBal.rho_nominal, nominal = 1.0);
//   protected Real rad.vol[2].dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = rad.vol[2].dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[2].dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   protected Real rad.vol[2].dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   protected Real rad.vol[2].dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   protected Real rad.vol[2].dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected Real rad.vol[2].dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[2].dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected parameter Boolean rad.vol[2].dynBal.medium.preferredMediumStates = not rad.vol[2].dynBal.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected parameter Boolean rad.vol[2].dynBal.medium.standardOrderComponents = true;
//   protected Real rad.vol[2].dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(rad.vol[2].dynBal.medium.T);
//   protected Real rad.vol[2].dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(rad.vol[2].dynBal.medium.p);
//   protected Real rad.vol[2].dynBal.U(quantity = "Energy", unit = "J", start = rad.vol[2].V * rad.vol[2].rho_nominal * Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificInternalEnergy(rad.vol[2].state_start));
//   protected Real rad.vol[2].dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = rad.vol[2].V * rad.vol[2].rho_nominal);
//   protected Real rad.vol[2].dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected Real rad.vol[2].dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected Real rad.vol[2].dynBal.fluidVolume(quantity = "Volume", unit = "m3") = rad.vol[2].V;
//   protected Real rad.vol[2].dynBal.Q_flow(unit = "W");
//   protected Real rad.vol[2].dynBal.hOut(unit = "J/kg");
//   protected parameter Boolean rad.vol[2].dynBal.initialize_p = false;
//   protected Real rad.vol[2].dynBal.ports_H_flow[1](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected Real rad.vol[2].dynBal.ports_H_flow[2](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected parameter Real rad.vol[2].dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.density(Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.setState_pTX(rad.vol[2].dynBal.p_start, rad.vol[2].dynBal.T_start, {}));
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[3].energyDynamics = rad.energyDynamics;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[3].massDynamics = rad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[3].substanceDynamics = rad.vol[3].energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[3].traceDynamics = rad.vol[3].energyDynamics;
//   parameter Real rad.vol[3].p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.p_start;
//   parameter Real rad.vol[3].T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.T_start;
//   parameter Real rad.vol[3].X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.X_start[1];
//   parameter Real rad.vol[3].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = rad.m_flow_nominal;
//   parameter Integer rad.vol[3].nPorts = 2;
//   parameter Real rad.vol[3].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(rad.vol[3].m_flow_nominal);
//   parameter Boolean rad.vol[3].homotopyInitialization = true;
//   parameter Boolean rad.vol[3].allowFlowReversal = system.allowFlowReversal;
//   parameter Real rad.vol[3].V(quantity = "Volume", unit = "m3") = rad.VWat / /*Real*/(rad.nEle);
//   parameter Boolean rad.vol[3].prescribedHeatFlowRate = false;
//   Real rad.vol[3].ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[3].ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[3].ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[3].ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[3].ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[3].ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[3].heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[3].heatPort.Q_flow(quantity = "Power", unit = "W");
//   Real rad.vol[3].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[3].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   protected parameter Real rad.vol[3].state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real rad.vol[3].state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real rad.vol[3].rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.density(Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.setState_pTX(rad.vol[3].p_start, rad.vol[3].T_start, {}));
//   protected final parameter Boolean rad.vol[3].useSteadyStateTwoPort = rad.vol[3].nPorts == 2 and rad.vol[3].prescribedHeatFlowRate and rad.vol[3].energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[3].massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[3].substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[3].traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected Real rad.vol[3].Q_flow(quantity = "Power", unit = "W");
//   protected Real rad.vol[3].hOut_internal(unit = "J/kg");
//   protected Real rad.vol[3].heaInp.y = rad.vol[3].heatPort.Q_flow;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[3].dynBal.energyDynamics = rad.vol[3].energyDynamics;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[3].dynBal.massDynamics = rad.vol[3].massDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[3].dynBal.substanceDynamics = rad.vol[3].dynBal.energyDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[3].dynBal.traceDynamics = rad.vol[3].dynBal.energyDynamics;
//   protected parameter Real rad.vol[3].dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.vol[3].p_start;
//   protected parameter Real rad.vol[3].dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.vol[3].T_start;
//   protected parameter Real rad.vol[3].dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.vol[3].X_start[1];
//   protected parameter Integer rad.vol[3].dynBal.nPorts = rad.vol[3].nPorts;
//   protected Real rad.vol[3].dynBal.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[3].dynBal.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[3].dynBal.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[3].dynBal.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[3].dynBal.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[3].dynBal.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[3].dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = rad.vol[3].dynBal.p_start, nominal = 300000.0, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[3].dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[3].dynBal.p_start, rad.vol[3].dynBal.T_start, {rad.vol[3].dynBal.X_start[1]}));
//   protected Real rad.vol[3].dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = rad.vol[3].dynBal.rho_nominal, nominal = 1.0);
//   protected Real rad.vol[3].dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = rad.vol[3].dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[3].dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   protected Real rad.vol[3].dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   protected Real rad.vol[3].dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   protected Real rad.vol[3].dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected Real rad.vol[3].dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[3].dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected parameter Boolean rad.vol[3].dynBal.medium.preferredMediumStates = not rad.vol[3].dynBal.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected parameter Boolean rad.vol[3].dynBal.medium.standardOrderComponents = true;
//   protected Real rad.vol[3].dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(rad.vol[3].dynBal.medium.T);
//   protected Real rad.vol[3].dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(rad.vol[3].dynBal.medium.p);
//   protected Real rad.vol[3].dynBal.U(quantity = "Energy", unit = "J", start = rad.vol[3].V * rad.vol[3].rho_nominal * Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificInternalEnergy(rad.vol[3].state_start));
//   protected Real rad.vol[3].dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = rad.vol[3].V * rad.vol[3].rho_nominal);
//   protected Real rad.vol[3].dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected Real rad.vol[3].dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected Real rad.vol[3].dynBal.fluidVolume(quantity = "Volume", unit = "m3") = rad.vol[3].V;
//   protected Real rad.vol[3].dynBal.Q_flow(unit = "W");
//   protected Real rad.vol[3].dynBal.hOut(unit = "J/kg");
//   protected parameter Boolean rad.vol[3].dynBal.initialize_p = false;
//   protected Real rad.vol[3].dynBal.ports_H_flow[1](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected Real rad.vol[3].dynBal.ports_H_flow[2](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected parameter Real rad.vol[3].dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.density(Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.setState_pTX(rad.vol[3].dynBal.p_start, rad.vol[3].dynBal.T_start, {}));
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[4].energyDynamics = rad.energyDynamics;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[4].massDynamics = rad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[4].substanceDynamics = rad.vol[4].energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[4].traceDynamics = rad.vol[4].energyDynamics;
//   parameter Real rad.vol[4].p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.p_start;
//   parameter Real rad.vol[4].T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.T_start;
//   parameter Real rad.vol[4].X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.X_start[1];
//   parameter Real rad.vol[4].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = rad.m_flow_nominal;
//   parameter Integer rad.vol[4].nPorts = 2;
//   parameter Real rad.vol[4].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(rad.vol[4].m_flow_nominal);
//   parameter Boolean rad.vol[4].homotopyInitialization = true;
//   parameter Boolean rad.vol[4].allowFlowReversal = system.allowFlowReversal;
//   parameter Real rad.vol[4].V(quantity = "Volume", unit = "m3") = rad.VWat / /*Real*/(rad.nEle);
//   parameter Boolean rad.vol[4].prescribedHeatFlowRate = false;
//   Real rad.vol[4].ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[4].ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[4].ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[4].ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[4].ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[4].ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[4].heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[4].heatPort.Q_flow(quantity = "Power", unit = "W");
//   Real rad.vol[4].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[4].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   protected parameter Real rad.vol[4].state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real rad.vol[4].state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real rad.vol[4].rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.density(Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.setState_pTX(rad.vol[4].p_start, rad.vol[4].T_start, {}));
//   protected final parameter Boolean rad.vol[4].useSteadyStateTwoPort = rad.vol[4].nPorts == 2 and rad.vol[4].prescribedHeatFlowRate and rad.vol[4].energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[4].massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[4].substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[4].traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected Real rad.vol[4].Q_flow(quantity = "Power", unit = "W");
//   protected Real rad.vol[4].hOut_internal(unit = "J/kg");
//   protected Real rad.vol[4].heaInp.y = rad.vol[4].heatPort.Q_flow;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[4].dynBal.energyDynamics = rad.vol[4].energyDynamics;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[4].dynBal.massDynamics = rad.vol[4].massDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[4].dynBal.substanceDynamics = rad.vol[4].dynBal.energyDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[4].dynBal.traceDynamics = rad.vol[4].dynBal.energyDynamics;
//   protected parameter Real rad.vol[4].dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.vol[4].p_start;
//   protected parameter Real rad.vol[4].dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.vol[4].T_start;
//   protected parameter Real rad.vol[4].dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.vol[4].X_start[1];
//   protected parameter Integer rad.vol[4].dynBal.nPorts = rad.vol[4].nPorts;
//   protected Real rad.vol[4].dynBal.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[4].dynBal.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[4].dynBal.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[4].dynBal.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[4].dynBal.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[4].dynBal.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[4].dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = rad.vol[4].dynBal.p_start, nominal = 300000.0, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[4].dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[4].dynBal.p_start, rad.vol[4].dynBal.T_start, {rad.vol[4].dynBal.X_start[1]}));
//   protected Real rad.vol[4].dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = rad.vol[4].dynBal.rho_nominal, nominal = 1.0);
//   protected Real rad.vol[4].dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = rad.vol[4].dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[4].dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   protected Real rad.vol[4].dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   protected Real rad.vol[4].dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   protected Real rad.vol[4].dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected Real rad.vol[4].dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[4].dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected parameter Boolean rad.vol[4].dynBal.medium.preferredMediumStates = not rad.vol[4].dynBal.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected parameter Boolean rad.vol[4].dynBal.medium.standardOrderComponents = true;
//   protected Real rad.vol[4].dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(rad.vol[4].dynBal.medium.T);
//   protected Real rad.vol[4].dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(rad.vol[4].dynBal.medium.p);
//   protected Real rad.vol[4].dynBal.U(quantity = "Energy", unit = "J", start = rad.vol[4].V * rad.vol[4].rho_nominal * Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificInternalEnergy(rad.vol[4].state_start));
//   protected Real rad.vol[4].dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = rad.vol[4].V * rad.vol[4].rho_nominal);
//   protected Real rad.vol[4].dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected Real rad.vol[4].dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected Real rad.vol[4].dynBal.fluidVolume(quantity = "Volume", unit = "m3") = rad.vol[4].V;
//   protected Real rad.vol[4].dynBal.Q_flow(unit = "W");
//   protected Real rad.vol[4].dynBal.hOut(unit = "J/kg");
//   protected parameter Boolean rad.vol[4].dynBal.initialize_p = false;
//   protected Real rad.vol[4].dynBal.ports_H_flow[1](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected Real rad.vol[4].dynBal.ports_H_flow[2](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected parameter Real rad.vol[4].dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.density(Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.setState_pTX(rad.vol[4].dynBal.p_start, rad.vol[4].dynBal.T_start, {}));
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[5].energyDynamics = rad.energyDynamics;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[5].massDynamics = rad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[5].substanceDynamics = rad.vol[5].energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[5].traceDynamics = rad.vol[5].energyDynamics;
//   parameter Real rad.vol[5].p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.p_start;
//   parameter Real rad.vol[5].T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.T_start;
//   parameter Real rad.vol[5].X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.X_start[1];
//   parameter Real rad.vol[5].m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = rad.m_flow_nominal;
//   parameter Integer rad.vol[5].nPorts = 2;
//   parameter Real rad.vol[5].m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(rad.vol[5].m_flow_nominal);
//   parameter Boolean rad.vol[5].homotopyInitialization = true;
//   parameter Boolean rad.vol[5].allowFlowReversal = system.allowFlowReversal;
//   parameter Real rad.vol[5].V(quantity = "Volume", unit = "m3") = rad.VWat / /*Real*/(rad.nEle);
//   parameter Boolean rad.vol[5].prescribedHeatFlowRate = false;
//   Real rad.vol[5].ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[5].ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[5].ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[5].ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real rad.vol[5].ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.vol[5].ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real rad.vol[5].heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[5].heatPort.Q_flow(quantity = "Power", unit = "W");
//   Real rad.vol[5].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.vol[5].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   protected parameter Real rad.vol[5].state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real rad.vol[5].state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real rad.vol[5].rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.density(Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.setState_pTX(rad.vol[5].p_start, rad.vol[5].T_start, {}));
//   protected final parameter Boolean rad.vol[5].useSteadyStateTwoPort = rad.vol[5].nPorts == 2 and rad.vol[5].prescribedHeatFlowRate and rad.vol[5].energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[5].massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[5].substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and rad.vol[5].traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected Real rad.vol[5].Q_flow(quantity = "Power", unit = "W");
//   protected Real rad.vol[5].hOut_internal(unit = "J/kg");
//   protected Real rad.vol[5].heaInp.y = rad.vol[5].heatPort.Q_flow;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[5].dynBal.energyDynamics = rad.vol[5].energyDynamics;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[5].dynBal.massDynamics = rad.vol[5].massDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[5].dynBal.substanceDynamics = rad.vol[5].dynBal.energyDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) rad.vol[5].dynBal.traceDynamics = rad.vol[5].dynBal.energyDynamics;
//   protected parameter Real rad.vol[5].dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = rad.vol[5].p_start;
//   protected parameter Real rad.vol[5].dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = rad.vol[5].T_start;
//   protected parameter Real rad.vol[5].dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = rad.vol[5].X_start[1];
//   protected parameter Integer rad.vol[5].dynBal.nPorts = rad.vol[5].nPorts;
//   protected Real rad.vol[5].dynBal.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[5].dynBal.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[5].dynBal.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[5].dynBal.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real rad.vol[5].dynBal.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[5].dynBal.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real rad.vol[5].dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = rad.vol[5].dynBal.p_start, nominal = 300000.0, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[5].dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[5].dynBal.p_start, rad.vol[5].dynBal.T_start, {rad.vol[5].dynBal.X_start[1]}));
//   protected Real rad.vol[5].dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = rad.vol[5].dynBal.rho_nominal, nominal = 1.0);
//   protected Real rad.vol[5].dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = rad.vol[5].dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected Real rad.vol[5].dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   protected Real rad.vol[5].dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   protected Real rad.vol[5].dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   protected Real rad.vol[5].dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected Real rad.vol[5].dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real rad.vol[5].dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected parameter Boolean rad.vol[5].dynBal.medium.preferredMediumStates = not rad.vol[5].dynBal.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected parameter Boolean rad.vol[5].dynBal.medium.standardOrderComponents = true;
//   protected Real rad.vol[5].dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(rad.vol[5].dynBal.medium.T);
//   protected Real rad.vol[5].dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(rad.vol[5].dynBal.medium.p);
//   protected Real rad.vol[5].dynBal.U(quantity = "Energy", unit = "J", start = rad.vol[5].V * rad.vol[5].rho_nominal * Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.specificInternalEnergy(rad.vol[5].state_start));
//   protected Real rad.vol[5].dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = rad.vol[5].V * rad.vol[5].rho_nominal);
//   protected Real rad.vol[5].dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected Real rad.vol[5].dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected Real rad.vol[5].dynBal.fluidVolume(quantity = "Volume", unit = "m3") = rad.vol[5].V;
//   protected Real rad.vol[5].dynBal.Q_flow(unit = "W");
//   protected Real rad.vol[5].dynBal.hOut(unit = "J/kg");
//   protected parameter Boolean rad.vol[5].dynBal.initialize_p = false;
//   protected Real rad.vol[5].dynBal.ports_H_flow[1](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected Real rad.vol[5].dynBal.ports_H_flow[2](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected parameter Real rad.vol[5].dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.density(Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.setState_pTX(rad.vol[5].dynBal.p_start, rad.vol[5].dynBal.T_start, {}));
//   protected parameter Real rad.cp_nominal(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)") = Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificHeatCapacityCp(Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_pTX(300000.0, rad.T_a_nominal, {1.0}));
//   protected parameter Real rad.QEle_flow_nominal[1](quantity = "Power", unit = "W", start = rad.Q_flow_nominal / /*Real*/(rad.nEle), fixed = false);
//   protected parameter Real rad.QEle_flow_nominal[2](quantity = "Power", unit = "W", start = rad.Q_flow_nominal / /*Real*/(rad.nEle), fixed = false);
//   protected parameter Real rad.QEle_flow_nominal[3](quantity = "Power", unit = "W", start = rad.Q_flow_nominal / /*Real*/(rad.nEle), fixed = false);
//   protected parameter Real rad.QEle_flow_nominal[4](quantity = "Power", unit = "W", start = rad.Q_flow_nominal / /*Real*/(rad.nEle), fixed = false);
//   protected parameter Real rad.QEle_flow_nominal[5](quantity = "Power", unit = "W", start = rad.Q_flow_nominal / /*Real*/(rad.nEle), fixed = false);
//   protected parameter Real rad.TWat_nominal[1](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_a_nominal + (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle), fixed = false, nominal = 300.0);
//   protected parameter Real rad.TWat_nominal[2](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_a_nominal + 2.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle), fixed = false, nominal = 300.0);
//   protected parameter Real rad.TWat_nominal[3](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_a_nominal + 3.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle), fixed = false, nominal = 300.0);
//   protected parameter Real rad.TWat_nominal[4](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_a_nominal + 4.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle), fixed = false, nominal = 300.0);
//   protected parameter Real rad.TWat_nominal[5](quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_a_nominal + 5.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle), fixed = false, nominal = 300.0);
//   protected parameter Real rad.dTRad_nominal[1](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TRad_nominal, fixed = false);
//   protected parameter Real rad.dTRad_nominal[2](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + 2.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TRad_nominal, fixed = false);
//   protected parameter Real rad.dTRad_nominal[3](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + 3.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TRad_nominal, fixed = false);
//   protected parameter Real rad.dTRad_nominal[4](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + 4.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TRad_nominal, fixed = false);
//   protected parameter Real rad.dTRad_nominal[5](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + 5.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TRad_nominal, fixed = false);
//   protected parameter Real rad.dTCon_nominal[1](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TAir_nominal, fixed = false);
//   protected parameter Real rad.dTCon_nominal[2](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + 2.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TAir_nominal, fixed = false);
//   protected parameter Real rad.dTCon_nominal[3](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + 3.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TAir_nominal, fixed = false);
//   protected parameter Real rad.dTCon_nominal[4](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + 4.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TAir_nominal, fixed = false);
//   protected parameter Real rad.dTCon_nominal[5](quantity = "ThermodynamicTemperature", unit = "K", start = rad.T_a_nominal + 5.0 * (rad.T_b_nominal - rad.T_a_nominal) / /*Real*/(rad.nEle) - rad.TAir_nominal, fixed = false);
//   protected parameter Real rad.UAEle(quantity = "ThermalConductance", unit = "W/K", min = 0.0, start = rad.Q_flow_nominal / (/*Real*/(rad.nEle) * (0.5 * (rad.T_a_nominal + rad.T_b_nominal) + (-1.0 + rad.fraRad) * rad.TAir_nominal - rad.fraRad * rad.TRad_nominal)), fixed = false);
//   protected final parameter Real rad.k = if rad.T_b_nominal > rad.TAir_nominal then 1.0 else -1.0;
//   protected Real rad.dTCon[1](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTCon[2](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTCon[3](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTCon[4](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTCon[5](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTRad[1](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTRad[2](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTRad[3](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTRad[4](quantity = "ThermodynamicTemperature", unit = "K");
//   protected Real rad.dTRad[5](quantity = "ThermodynamicTemperature", unit = "K");
//   Real rad.sta_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.sta_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real rad.sta_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real rad.sta_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   parameter Real rad.mDry(quantity = "Mass", unit = "kg", min = 0.0) = 0.0263 * abs(rad.Q_flow_nominal);
//   parameter Real rad.heaCap[1].C(quantity = "HeatCapacity", unit = "J/K") = 500.0 * rad.mDry / /*Real*/(rad.nEle);
//   Real rad.heaCap[1].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_start, nominal = 300.0);
//   Real rad.heaCap[1].der_T(quantity = "TemperatureSlope", unit = "K/s", start = 0.0);
//   Real rad.heaCap[1].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.heaCap[1].port.Q_flow(quantity = "Power", unit = "W");
//   parameter Real rad.heaCap[2].C(quantity = "HeatCapacity", unit = "J/K") = 500.0 * rad.mDry / /*Real*/(rad.nEle);
//   Real rad.heaCap[2].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_start, nominal = 300.0);
//   Real rad.heaCap[2].der_T(quantity = "TemperatureSlope", unit = "K/s", start = 0.0);
//   Real rad.heaCap[2].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.heaCap[2].port.Q_flow(quantity = "Power", unit = "W");
//   parameter Real rad.heaCap[3].C(quantity = "HeatCapacity", unit = "J/K") = 500.0 * rad.mDry / /*Real*/(rad.nEle);
//   Real rad.heaCap[3].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_start, nominal = 300.0);
//   Real rad.heaCap[3].der_T(quantity = "TemperatureSlope", unit = "K/s", start = 0.0);
//   Real rad.heaCap[3].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.heaCap[3].port.Q_flow(quantity = "Power", unit = "W");
//   parameter Real rad.heaCap[4].C(quantity = "HeatCapacity", unit = "J/K") = 500.0 * rad.mDry / /*Real*/(rad.nEle);
//   Real rad.heaCap[4].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_start, nominal = 300.0);
//   Real rad.heaCap[4].der_T(quantity = "TemperatureSlope", unit = "K/s", start = 0.0);
//   Real rad.heaCap[4].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.heaCap[4].port.Q_flow(quantity = "Power", unit = "W");
//   parameter Real rad.heaCap[5].C(quantity = "HeatCapacity", unit = "J/K") = 500.0 * rad.mDry / /*Real*/(rad.nEle);
//   Real rad.heaCap[5].T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = rad.T_start, nominal = 300.0);
//   Real rad.heaCap[5].der_T(quantity = "TemperatureSlope", unit = "K/s", start = 0.0);
//   Real rad.heaCap[5].port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real rad.heaCap[5].port.Q_flow(quantity = "Power", unit = "W");
//   parameter Integer sin.nPorts = 1;
//   Real sin.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   Real sin.medium.h(quantity = "SpecificEnergy", unit = "J/kg");
//   Real sin.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
//   Real sin.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real sin.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   Real sin.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   Real sin.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   Real sin.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   Real sin.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sin.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   parameter Boolean sin.medium.preferredMediumStates = false;
//   parameter Boolean sin.medium.standardOrderComponents = true;
//   Real sin.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(sin.medium.T);
//   Real sin.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(sin.medium.p);
//   Real sin.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if sin.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Entering then 0.0 else -9.999999999999999e+59, max = if sin.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Leaving then 0.0 else 9.999999999999999e+59);
//   Real sin.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sin.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter enumeration(Entering, Leaving, Bidirectional) sin.flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional;
//   parameter Boolean sin.use_p = true;
//   parameter Real sin.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   parameter Real sin.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0) = 995.586;
//   parameter Boolean sin.use_T = true;
//   parameter Real sin.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   parameter Real sin.h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0) = 83680.0;
//   parameter Real sin.X[1](quantity = "SimpleLiquidWater", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   parameter Boolean temSup.allowFlowReversal = system.allowFlowReversal;
//   Real temSup.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if temSup.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real temSup.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real temSup.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real temSup.port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if temSup.allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real temSup.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real temSup.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter Boolean temSup.port_a_exposesState = false;
//   protected parameter Boolean temSup.port_b_exposesState = false;
//   protected parameter Boolean temSup.showDesignFlowDirection = true;
//   parameter Real temSup.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = mRad_flow_nominal;
//   parameter Real temSup.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * temSup.m_flow_nominal;
//   parameter Real temSup.tau(quantity = "Time", unit = "s", min = 0.0) = 1.0;
//   parameter enumeration(NoInit, SteadyState, InitialState, InitialOutput) temSup.initType = Modelica.Blocks.Types.Init.InitialState;
//   protected Real temSup.k(start = 1.0);
//   protected final parameter Boolean temSup.dynamic = temSup.tau > 1e-10 or temSup.tau < -1e-10;
//   protected Real temSup.mNor_flow;
//   Real temSup.T(quantity = "Temperature", unit = "K", displayUnit = "degC", min = 0.0, start = temSup.T_start);
//   parameter Real temSup.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 293.15;
//   Real temSup.TMed(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = temSup.T_start, nominal = 300.0);
//   protected Real temSup.T_a_inflow(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected Real temSup.T_b_inflow(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real temRoo.T(unit = "K");
//   Real temRoo.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real temRoo.port.Q_flow(quantity = "Power", unit = "W");
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.massDynamics = pumRad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.substanceDynamics = pumRad.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.traceDynamics = pumRad.energyDynamics;
//   parameter Real pumRad.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   parameter Real pumRad.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   parameter Real pumRad.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   parameter Boolean pumRad.allowFlowReversal = system.allowFlowReversal;
//   Real pumRad.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if pumRad.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   Real pumRad.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 300000.0, nominal = 300000.0);
//   Real pumRad.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, start = pumRad.h_outflow_start, nominal = 1000000.0);
//   Real pumRad.port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pumRad.allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   Real pumRad.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = pumRad.p_start, nominal = 300000.0);
//   Real pumRad.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, start = pumRad.h_outflow_start, nominal = 1000000.0);
//   protected parameter Boolean pumRad.port_a_exposesState = false;
//   protected parameter Boolean pumRad.port_b_exposesState = false;
//   protected parameter Boolean pumRad.showDesignFlowDirection = false;
//   parameter Real pumRad.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s") = mRad_flow_nominal;
//   parameter Real pumRad.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(pumRad.m_flow_nominal);
//   parameter Boolean pumRad.homotopyInitialization = true;
//   parameter Boolean pumRad.show_V_flow = false;
//   parameter Boolean pumRad.show_T = false;
//   Real pumRad.m_flow(quantity = "MassFlowRate", unit = "kg/s", start = 0.0) = pumRad.port_a.m_flow;
//   Real pumRad.dp(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", start = 0.0);
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.vol.energyDynamics = if pumRad.dynamicBalance then pumRad.energyDynamics else Modelica.Fluid.Types.Dynamics.SteadyState;
//   parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.vol.massDynamics = if pumRad.dynamicBalance then pumRad.massDynamics else Modelica.Fluid.Types.Dynamics.SteadyState;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.vol.substanceDynamics = pumRad.vol.energyDynamics;
//   final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.vol.traceDynamics = pumRad.vol.energyDynamics;
//   parameter Real pumRad.vol.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = pumRad.p_start;
//   parameter Real pumRad.vol.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = pumRad.T_start;
//   parameter Real pumRad.vol.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = pumRad.X_start[1];
//   parameter Real pumRad.vol.m_flow_nominal(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = pumRad.m_flow_nominal;
//   parameter Integer pumRad.vol.nPorts = 2;
//   parameter Real pumRad.vol.m_flow_small(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0001 * abs(pumRad.vol.m_flow_nominal);
//   parameter Boolean pumRad.vol.homotopyInitialization = true;
//   parameter Boolean pumRad.vol.allowFlowReversal = pumRad.allowFlowReversal;
//   parameter Real pumRad.vol.V(quantity = "Volume", unit = "m3") = pumRad.vol.V0;
//   parameter Boolean pumRad.vol.prescribedHeatFlowRate = true;
//   Real pumRad.vol.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real pumRad.vol.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pumRad.vol.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pumRad.vol.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   Real pumRad.vol.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real pumRad.vol.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   Real pumRad.vol.heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real pumRad.vol.heatPort.Q_flow(quantity = "Power", unit = "W");
//   Real pumRad.vol.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real pumRad.vol.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar");
//   protected parameter Real pumRad.vol.state_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real pumRad.vol.state_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real pumRad.vol.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.density(Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.setState_pTX(pumRad.vol.p_start, pumRad.vol.T_start, {}));
//   protected final parameter Boolean pumRad.vol.useSteadyStateTwoPort = pumRad.vol.nPorts == 2 and pumRad.vol.prescribedHeatFlowRate and pumRad.vol.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and pumRad.vol.massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and pumRad.vol.substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and pumRad.vol.traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected Real pumRad.vol.Q_flow(quantity = "Power", unit = "W");
//   protected Real pumRad.vol.hOut_internal(unit = "J/kg");
//   protected Real pumRad.vol.heaInp.y = pumRad.vol.heatPort.Q_flow;
//   parameter Real pumRad.vol.tau(quantity = "Time", unit = "s") = pumRad.tau;
//   protected parameter Real pumRad.vol.V0(quantity = "Volume", unit = "m3") = pumRad.vol.m_flow_nominal * pumRad.vol.tau / pumRad.vol.rho_nominal;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.vol.dynBal.energyDynamics = pumRad.vol.energyDynamics;
//   protected parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.vol.dynBal.massDynamics = pumRad.vol.massDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.vol.dynBal.substanceDynamics = pumRad.vol.dynBal.energyDynamics;
//   protected final parameter enumeration(DynamicFreeInitial, FixedInitial, SteadyStateInitial, SteadyState) pumRad.vol.dynBal.traceDynamics = pumRad.vol.dynBal.energyDynamics;
//   protected parameter Real pumRad.vol.dynBal.p_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = pumRad.vol.p_start;
//   protected parameter Real pumRad.vol.dynBal.T_start(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = pumRad.vol.T_start;
//   protected parameter Real pumRad.vol.dynBal.X_start[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = pumRad.vol.X_start[1];
//   protected parameter Integer pumRad.vol.dynBal.nPorts = pumRad.vol.nPorts;
//   protected Real pumRad.vol.dynBal.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real pumRad.vol.dynBal.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pumRad.vol.dynBal.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real pumRad.vol.dynBal.ports[2].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0);
//   protected Real pumRad.vol.dynBal.ports[2].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pumRad.vol.dynBal.ports[2].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real pumRad.vol.dynBal.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, start = pumRad.vol.dynBal.p_start, nominal = 300000.0, stateSelect = StateSelect.prefer);
//   protected Real pumRad.vol.dynBal.medium.h(quantity = "SpecificEnergy", unit = "J/kg", start = Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.specificEnthalpy_pTX(pumRad.vol.dynBal.p_start, pumRad.vol.dynBal.T_start, {pumRad.vol.dynBal.X_start[1]}));
//   protected Real pumRad.vol.dynBal.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = pumRad.vol.dynBal.rho_nominal, nominal = 1.0);
//   protected Real pumRad.vol.dynBal.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = pumRad.vol.dynBal.T_start, nominal = 293.15, stateSelect = StateSelect.prefer);
//   protected Real pumRad.vol.dynBal.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   protected Real pumRad.vol.dynBal.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   protected Real pumRad.vol.dynBal.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   protected Real pumRad.vol.dynBal.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   protected Real pumRad.vol.dynBal.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pumRad.vol.dynBal.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected parameter Boolean pumRad.vol.dynBal.medium.preferredMediumStates = not pumRad.vol.dynBal.energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState;
//   protected parameter Boolean pumRad.vol.dynBal.medium.standardOrderComponents = true;
//   protected Real pumRad.vol.dynBal.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(pumRad.vol.dynBal.medium.T);
//   protected Real pumRad.vol.dynBal.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(pumRad.vol.dynBal.medium.p);
//   protected Real pumRad.vol.dynBal.U(quantity = "Energy", unit = "J", start = pumRad.vol.V * pumRad.vol.rho_nominal * Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.specificInternalEnergy(pumRad.vol.state_start));
//   protected Real pumRad.vol.dynBal.m(quantity = "Mass", unit = "kg", min = 0.0, start = pumRad.vol.V * pumRad.vol.rho_nominal);
//   protected Real pumRad.vol.dynBal.mb_flow(quantity = "MassFlowRate", unit = "kg/s");
//   protected Real pumRad.vol.dynBal.Hb_flow(quantity = "EnthalpyFlowRate", unit = "W");
//   protected Real pumRad.vol.dynBal.fluidVolume(quantity = "Volume", unit = "m3") = pumRad.vol.V;
//   protected Real pumRad.vol.dynBal.Q_flow(unit = "W");
//   protected Real pumRad.vol.dynBal.hOut(unit = "J/kg");
//   protected parameter Boolean pumRad.vol.dynBal.initialize_p = false;
//   protected Real pumRad.vol.dynBal.ports_H_flow[1](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected Real pumRad.vol.dynBal.ports_H_flow[2](quantity = "EnthalpyFlowRate", unit = "W", min = -100000000.0, max = 100000000.0, nominal = 1000.0);
//   protected parameter Real pumRad.vol.dynBal.rho_nominal(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.density(Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.setState_pTX(pumRad.vol.dynBal.p_start, pumRad.vol.dynBal.T_start, {}));
//   parameter Boolean pumRad.dynamicBalance = true;
//   parameter Boolean pumRad.addPowerToMedium = true;
//   parameter Real pumRad.tau(quantity = "Time", unit = "s") = 1.0;
//   Real pumRad.heatPort.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   Real pumRad.heatPort.Q_flow(quantity = "Power", unit = "W");
//   protected Real pumRad.rho_in(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
//   protected parameter Boolean pumRad.preSou.allowFlowReversal = pumRad.allowFlowReversal;
//   protected Real pumRad.preSou.port_a.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if pumRad.preSou.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0);
//   protected Real pumRad.preSou.port_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pumRad.preSou.port_a.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected Real pumRad.preSou.port_b.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = if pumRad.preSou.allowFlowReversal then 9.999999999999999e+59 else 0.0);
//   protected Real pumRad.preSou.port_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pumRad.preSou.port_b.h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter Boolean pumRad.preSou.port_a_exposesState = false;
//   protected parameter Boolean pumRad.preSou.port_b_exposesState = false;
//   protected parameter Boolean pumRad.preSou.showDesignFlowDirection = true;
//   protected parameter Real pumRad.preSou.dp_start(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 0.01 * system.p_start;
//   protected parameter Real pumRad.preSou.m_flow_start(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0) = pumRad.m_flow_start;
//   protected parameter Real pumRad.preSou.m_flow_small(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = -100000.0, max = 100000.0) = pumRad.m_flow_small;
//   protected parameter Boolean pumRad.preSou.show_T = false;
//   protected parameter Boolean pumRad.preSou.show_V_flow = false;
//   protected Real pumRad.preSou.m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if pumRad.preSou.allowFlowReversal then -9.999999999999999e+59 else 0.0, max = 100000.0, start = pumRad.preSou.m_flow_start);
//   protected Real pumRad.preSou.dp(quantity = "Pressure", unit = "Pa", displayUnit = "bar", start = pumRad.preSou.dp_start);
//   protected Real pumRad.preSou.state_a.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pumRad.preSou.state_a.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected Real pumRad.preSou.state_b.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   protected Real pumRad.preSou.state_b.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   protected parameter Boolean pumRad.preSou.control_m_flow = true;
//   protected Real pumRad.preSou.m_flow_internal;
//   protected Real pumRad.preSou.dp_internal;
//   protected Real pumRad.preSou.m_flow_in;
//   protected parameter Real pumRad.sta_start.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real pumRad.sta_start.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   protected parameter Real pumRad.h_outflow_start(quantity = "SpecificEnergy", unit = "J/kg") = Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.specificEnthalpy(pumRad.sta_start);
//   parameter Boolean pumRad.use_powerCharacteristic = false;
//   parameter Boolean pumRad.motorCooledByFluid = true;
//   parameter Real pumRad.motorEfficiency.r_V[1](displayUnit = "1", min = 0.0, max = 1.0) = 1.0;
//   parameter Real pumRad.motorEfficiency.eta[1](displayUnit = "1", min = 0.0, max = 1.0) = 0.7;
//   parameter Real pumRad.hydraulicEfficiency.r_V[1](displayUnit = "1", min = 0.0, max = 1.0) = 1.0;
//   parameter Real pumRad.hydraulicEfficiency.eta[1](displayUnit = "1", min = 0.0, max = 1.0) = 0.7;
//   parameter Real pumRad.rho_default(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.density(pumRad.sta_default);
//   Real pumRad.P(quantity = "Modelica.SIunits.Power", unit = "W");
//   Real pumRad.WHyd(quantity = "Power", unit = "W");
//   Real pumRad.WFlo(quantity = "Power", unit = "W");
//   Real pumRad.Q_flow(quantity = "Power", unit = "W");
//   Real pumRad.eta(min = 0.0, max = 1.0);
//   Real pumRad.etaHyd(min = 0.0, max = 1.0);
//   Real pumRad.etaMot(min = 0.0, max = 1.0);
//   Real pumRad.dpMachine(quantity = "Pressure", unit = "Pa", displayUnit = "Pa");
//   Real pumRad.VMachine_flow(quantity = "VolumeFlowRate", unit = "m3/s");
//   protected parameter Real pumRad.V_flow_max(quantity = "VolumeFlowRate", unit = "m3/s", fixed = false);
//   protected parameter Real pumRad.delta_V_flow(quantity = "VolumeFlowRate", unit = "m3/s") = 0.001 * pumRad.V_flow_max;
//   protected final parameter Real pumRad.motDer[1](fixed = false);
//   protected final parameter Real pumRad.hydDer[1](fixed = false);
//   protected Real pumRad.QThe_flow(quantity = "Power", unit = "W");
//   constant Boolean pumRad.control_m_flow = true;
//   Real pumRad.r_V(start = 1.0);
//   protected final parameter Real pumRad.p_a_default(quantity = "Pressure", unit = "Pa", displayUnit = "Pa", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real pumRad.sta_default.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   protected parameter Real pumRad.sta_default.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = 293.15;
//   Real pumRad.m_flow_in(unit = "kg/s", nominal = pumRad.m_flow_nominal);
//   parameter Boolean pumRad.filteredSpeed = true;
//   parameter Real pumRad.riseTime(quantity = "Time", unit = "s") = 30.0;
//   parameter enumeration(NoInit, SteadyState, InitialState, InitialOutput) pumRad.init = Modelica.Blocks.Types.Init.InitialOutput;
//   parameter Real pumRad.m_flow_start(quantity = "MassFlowRate", unit = "kg/s", min = 0.0) = 0.0;
//   Real pumRad.m_flow_actual(unit = "kg/s", nominal = pumRad.m_flow_nominal);
//   protected Real pumRad.prePow.Q_flow;
//   protected Real pumRad.prePow.port.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0);
//   protected Real pumRad.prePow.port.Q_flow(quantity = "Power", unit = "W");
//   protected Real pumRad.PToMedium_flow.y = pumRad.Q_flow + pumRad.WFlo;
//   protected Real pumRad.filter.u(unit = "kg/s");
//   protected Real pumRad.filter.y(unit = "kg/s");
//   protected parameter enumeration(CriticalDamping, Bessel, Butterworth, ChebyshevI) pumRad.filter.analogFilter = Modelica.Blocks.Types.AnalogFilter.CriticalDamping;
//   protected parameter enumeration(LowPass, HighPass, BandPass, BandStop) pumRad.filter.filterType = Modelica.Blocks.Types.FilterType.LowPass;
//   protected parameter Integer pumRad.filter.order(min = 1) = 2;
//   protected parameter Real pumRad.filter.f_cut(quantity = "Frequency", unit = "Hz") = 5.0 / (6.283185307179586 * pumRad.riseTime);
//   protected parameter Real pumRad.filter.gain = 1.0;
//   protected parameter Real pumRad.filter.A_ripple(unit = "dB") = 0.5;
//   protected parameter Real pumRad.filter.f_min(quantity = "Frequency", unit = "Hz") = 0.0;
//   protected parameter Boolean pumRad.filter.normalized = true;
//   protected parameter enumeration(NoInit, SteadyState, InitialState, InitialOutput) pumRad.filter.init = pumRad.init;
//   protected final parameter Integer pumRad.filter.nx = if pumRad.filter.filterType == Modelica.Blocks.Types.FilterType.LowPass or pumRad.filter.filterType == Modelica.Blocks.Types.FilterType.HighPass then pumRad.filter.order else 2 * pumRad.filter.order;
//   protected parameter Real pumRad.filter.x_start[1] = 0.0;
//   protected parameter Real pumRad.filter.x_start[2] = 0.0;
//   protected parameter Real pumRad.filter.y_start = pumRad.m_flow_start;
//   protected parameter Real pumRad.filter.u_nominal = pumRad.m_flow_nominal;
//   protected Real pumRad.filter.x[1](stateSelect = StateSelect.always);
//   protected Real pumRad.filter.x[2](stateSelect = StateSelect.always);
//   protected parameter Integer pumRad.filter.ncr = if pumRad.filter.analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then pumRad.filter.order else mod(pumRad.filter.order, 2);
//   protected parameter Integer pumRad.filter.nc0 = if pumRad.filter.analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then 0 else integer(0.5 * /*Real*/(pumRad.filter.order));
//   protected parameter Integer pumRad.filter.na = if pumRad.filter.filterType == Modelica.Blocks.Types.FilterType.BandPass or pumRad.filter.filterType == Modelica.Blocks.Types.FilterType.BandStop then pumRad.filter.order else if pumRad.filter.analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then 0 else integer(0.5 * /*Real*/(pumRad.filter.order));
//   protected parameter Integer pumRad.filter.nr = if pumRad.filter.filterType == Modelica.Blocks.Types.FilterType.BandPass or pumRad.filter.filterType == Modelica.Blocks.Types.FilterType.BandStop then 0 else if pumRad.filter.analogFilter == Modelica.Blocks.Types.AnalogFilter.CriticalDamping then pumRad.filter.order else mod(pumRad.filter.order, 2);
//   protected parameter Real pumRad.filter.cr[1](fixed = false);
//   protected parameter Real pumRad.filter.cr[2](fixed = false);
//   protected parameter Real pumRad.filter.r[1](fixed = false);
//   protected parameter Real pumRad.filter.r[2](fixed = false);
//   protected Real pumRad.filter.uu[1];
//   protected Real pumRad.filter.uu[2];
//   protected Real pumRad.filter.uu[3];
//   protected Real pumRad.m_flow_filtered(unit = "kg/s");
//   parameter Integer sou.nPorts = 1;
//   Real sou.medium.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0);
//   Real sou.medium.h(quantity = "SpecificEnergy", unit = "J/kg");
//   Real sou.medium.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0);
//   Real sou.medium.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   Real sou.medium.X[1](quantity = "MassFraction", unit = "kg/kg", min = 0.0, max = 1.0, start = 1.0, nominal = 0.1);
//   Real sou.medium.u(quantity = "SpecificEnergy", unit = "J/kg", min = -100000000.0, max = 100000000.0, nominal = 1000000.0);
//   Real sou.medium.R(quantity = "SpecificHeatCapacity", unit = "J/(kg.K)", min = 0.0, max = 10000000.0, start = 1000.0, nominal = 1000.0);
//   Real sou.medium.MM(quantity = "MolarMass", unit = "kg/mol", min = 0.001, max = 0.25, nominal = 0.032);
//   Real sou.medium.state.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sou.medium.state.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0);
//   parameter Boolean sou.medium.preferredMediumStates = false;
//   parameter Boolean sou.medium.standardOrderComponents = true;
//   Real sou.medium.T_degC(quantity = "ThermodynamicTemperature", unit = "degC") = Modelica.SIunits.Conversions.to_degC(sou.medium.T);
//   Real sou.medium.p_bar(quantity = "Pressure", unit = "bar") = Modelica.SIunits.Conversions.to_bar(sou.medium.p);
//   Real sou.ports[1].m_flow(quantity = "MassFlowRate.SimpleLiquidWater", unit = "kg/s", min = if sou.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Entering then 0.0 else -9.999999999999999e+59, max = if sou.flowDirection == Modelica.Fluid.Types.PortFlowDirection.Leaving then 0.0 else 9.999999999999999e+59);
//   Real sou.ports[1].p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0);
//   Real sou.ports[1].h_outflow(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0);
//   protected parameter enumeration(Entering, Leaving, Bidirectional) sou.flowDirection = Modelica.Fluid.Types.PortFlowDirection.Bidirectional;
//   parameter Boolean sou.use_p = true;
//   parameter Real sou.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, max = 100000000.0, start = 100000.0, nominal = 100000.0) = 300000.0;
//   parameter Real sou.d(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0, max = 100000.0, start = 1.0, nominal = 1.0) = 995.586;
//   parameter Boolean sou.use_T = true;
//   parameter Real sou.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 1.0, max = 10000.0, start = 300.0, nominal = 300.0) = TRadSup_nominal;
//   parameter Real sou.h(quantity = "SpecificEnergy", unit = "J/kg", min = -10000000000.0, max = 10000000000.0, nominal = 1000000.0) = 83680.0;
//   parameter Real sou.X[1](quantity = "SimpleLiquidWater", unit = "kg/kg", min = 0.0, max = 1.0, nominal = 0.1) = 1.0;
//   parameter Real hysPum.uLow(start = 0.0) = 292.15;
//   parameter Real hysPum.uHigh(start = 1.0) = 294.15;
//   parameter Boolean hysPum.pre_y_start = false;
//   Real hysPum.u;
//   Boolean hysPum.y;
//   Boolean booToReaRad.u;
//   parameter Real booToReaRad.realTrue = mRad_flow_nominal;
//   parameter Real booToReaRad.realFalse = 0.0;
//   Real booToReaRad.y;
//   Boolean not1.u;
//   Boolean not1.y;
// initial equation
//   assert(rad.T_a_nominal > rad.T_b_nominal, "In RadiatorEN442_2, T_a_nominal must be higher than T_b_nominal");
//   assert(rad.Q_flow_nominal > 0.0, "In RadiatorEN442_2, nominal power must be bigger than zero if T_b_nominal > TAir_nominal");
//   rad.TWat_nominal[1] = rad.T_a_nominal - rad.QEle_flow_nominal[1] / (Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificHeatCapacityCp(Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_pTX(300000.0, rad.T_a_nominal, {1.0})) * rad.m_flow_nominal);
//   rad.TWat_nominal[2] = rad.TWat_nominal[1] - rad.QEle_flow_nominal[2] / (Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificHeatCapacityCp(Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_pTX(300000.0, rad.TWat_nominal[1], {1.0})) * rad.m_flow_nominal);
//   rad.TWat_nominal[3] = rad.TWat_nominal[2] - rad.QEle_flow_nominal[3] / (Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificHeatCapacityCp(Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_pTX(300000.0, rad.TWat_nominal[2], {1.0})) * rad.m_flow_nominal);
//   rad.TWat_nominal[4] = rad.TWat_nominal[3] - rad.QEle_flow_nominal[4] / (Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificHeatCapacityCp(Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_pTX(300000.0, rad.TWat_nominal[3], {1.0})) * rad.m_flow_nominal);
//   rad.TWat_nominal[5] = rad.TWat_nominal[4] - rad.QEle_flow_nominal[5] / (Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.specificHeatCapacityCp(Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_pTX(300000.0, rad.TWat_nominal[4], {1.0})) * rad.m_flow_nominal);
//   rad.dTRad_nominal[1] = rad.TWat_nominal[1] - rad.TRad_nominal;
//   rad.dTRad_nominal[2] = rad.TWat_nominal[2] - rad.TRad_nominal;
//   rad.dTRad_nominal[3] = rad.TWat_nominal[3] - rad.TRad_nominal;
//   rad.dTRad_nominal[4] = rad.TWat_nominal[4] - rad.TRad_nominal;
//   rad.dTRad_nominal[5] = rad.TWat_nominal[5] - rad.TRad_nominal;
//   rad.dTCon_nominal[1] = rad.TWat_nominal[1] - rad.TAir_nominal;
//   rad.dTCon_nominal[2] = rad.TWat_nominal[2] - rad.TAir_nominal;
//   rad.dTCon_nominal[3] = rad.TWat_nominal[3] - rad.TAir_nominal;
//   rad.dTCon_nominal[4] = rad.TWat_nominal[4] - rad.TAir_nominal;
//   rad.dTCon_nominal[5] = rad.TWat_nominal[5] - rad.TAir_nominal;
//   rad.Q_flow_nominal = rad.QEle_flow_nominal[1] + rad.QEle_flow_nominal[2] + rad.QEle_flow_nominal[3] + rad.QEle_flow_nominal[4] + rad.QEle_flow_nominal[5];
//   rad.QEle_flow_nominal[1] = rad.k * rad.UAEle * ((1.0 - rad.fraRad) * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTRad_nominal[1], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TRad_nominal)) + rad.fraRad * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTCon_nominal[1], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TAir_nominal)));
//   rad.QEle_flow_nominal[2] = rad.k * rad.UAEle * ((1.0 - rad.fraRad) * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTRad_nominal[2], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TRad_nominal)) + rad.fraRad * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTCon_nominal[2], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TAir_nominal)));
//   rad.QEle_flow_nominal[3] = rad.k * rad.UAEle * ((1.0 - rad.fraRad) * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTRad_nominal[3], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TRad_nominal)) + rad.fraRad * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTCon_nominal[3], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TAir_nominal)));
//   rad.QEle_flow_nominal[4] = rad.k * rad.UAEle * ((1.0 - rad.fraRad) * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTRad_nominal[4], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TRad_nominal)) + rad.fraRad * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTCon_nominal[4], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TAir_nominal)));
//   rad.QEle_flow_nominal[5] = rad.k * rad.UAEle * ((1.0 - rad.fraRad) * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTRad_nominal[5], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TRad_nominal)) + rad.fraRad * Buildings.Utilities.Math.Functions.powerLinearized(rad.k * rad.dTCon_nominal[5], rad.n, 0.1 * rad.k * (rad.T_b_nominal - rad.TAir_nominal)));
//   temSup.T = temSup.T_start;
//   pumRad.filter.cr = Modelica.Blocks.Continuous.Internal.Filter.base.CriticalDamping(2, pumRad.filter.normalized);
//   (pumRad.filter.r, _, _, _) = Modelica.Blocks.Continuous.Internal.Filter.roots.lowPass({pumRad.filter.cr[1], pumRad.filter.cr[2]}, {}, {}, pumRad.filter.f_cut);
//   pumRad.filter.y = pumRad.filter.y_start;
//   der(pumRad.filter.x[1]) = 0.0;
//   pumRad.V_flow_max = pumRad.m_flow_nominal / pumRad.rho_default;
//   pre(hysPum.y) = hysPum.pre_y_start;
// initial algorithm
//   if timTab.tableOnFile then
//     timTab.tableOnFileRead := Modelica.Blocks.Sources.CombiTimeTable$timTab.readTableData(timTab.tableID, false, timTab.verboseRead);
//   else
//     timTab.tableOnFileRead := 1.0;
//   end if;
//   timTab.t_min := Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableTimeTmin(timTab.tableID, timTab.tableOnFileRead);
//   timTab.t_max := Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableTimeTmax(timTab.tableID, timTab.tableOnFileRead);
// initial algorithm
//   pumRad.motDer := {0.0};
//   pumRad.hydDer := {0.0};
// equation
//   assert(vol.dynBal.medium.T >= 200.0 and vol.dynBal.medium.T <= 423.15, "
//             Temperature T is not in the allowed range
//             200.0 K <= (T =" + String(vol.dynBal.medium.T, 6, 0, true) + " K) <= 423.15 K
//             required from medium model \"" + "MoistAirPTDecoupledUnsaturated" + "\".");
//   vol.dynBal.medium.MM = 1.0 / (vol.dynBal.medium.Xi[1] / <EMPTY(scope: Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.BaseProperties$vol$dynBal$medium, name: steam.MM, ty: Real(String quantity PARAM DAE.EQBOUND("MolarMass", SOME("MolarMass"), C_PARAM, [DEFAULT VALUE]), String unit PARAM DAE.EQBOUND("kg/mol", SOME("kg/mol"), C_PARAM, [DEFAULT VALUE]), Real min PARAM DAE.EQBOUND(0.0, SOME(0.0), C_PARAM, [DEFAULT VALUE])))> + (1.0 - vol.dynBal.medium.Xi[1]) / <EMPTY(scope: Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.BaseProperties$vol$dynBal$medium, name: dryair.MM, ty: Real(String quantity PARAM DAE.EQBOUND("MolarMass", SOME("MolarMass"), C_PARAM, [DEFAULT VALUE]), String unit PARAM DAE.EQBOUND("kg/mol", SOME("kg/mol"), C_PARAM, [DEFAULT VALUE]), Real min PARAM DAE.EQBOUND(0.0, SOME(0.0), C_PARAM, [DEFAULT VALUE])))>);
//   vol.dynBal.medium.p_steam_sat = min(Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.saturationPressure(vol.dynBal.medium.T), 0.999 * vol.dynBal.medium.p);
//   vol.dynBal.medium.X_sat = min(vol.dynBal.medium.p_steam_sat * steam.MM * (1.0 - vol.dynBal.medium.Xi[1]) / (dryair.MM * max(1e-13, vol.dynBal.medium.p - vol.dynBal.medium.p_steam_sat)), 1.0);
//   vol.dynBal.medium.X_steam = vol.dynBal.medium.Xi[1];
//   vol.dynBal.medium.X_air = 1.0 - vol.dynBal.medium.Xi[1];
//   vol.dynBal.medium.h = Buildings.Fluid.Interfaces.ConservationEquation$vol$dynBal.Medium.specificEnthalpy_pTX(vol.dynBal.medium.p, vol.dynBal.medium.T, {vol.dynBal.medium.Xi[1]});
//   vol.dynBal.medium.R = dryair.R * (1.0 - vol.dynBal.medium.Xi[1]) + steam.R * vol.dynBal.medium.Xi[1];
//   vol.dynBal.medium.u = -84437.5 + vol.dynBal.medium.h;
//   0.8333333333333334 * vol.dynBal.medium.d = 9.869232667160129e-06 * vol.dynBal.medium.p;
//   vol.dynBal.medium.state.p = vol.dynBal.medium.p;
//   vol.dynBal.medium.state.T = vol.dynBal.medium.T;
//   vol.dynBal.medium.state.X[1] = vol.dynBal.medium.X[1];
//   vol.dynBal.medium.state.X[2] = vol.dynBal.medium.X[2];
//   vol.dynBal.medium.x_sat = steam.MM * vol.dynBal.medium.p_steam_sat / (dryair.MM * max(1e-13, vol.dynBal.medium.p - vol.dynBal.medium.p_steam_sat));
//   vol.dynBal.medium.x_water = vol.dynBal.medium.Xi[1] / max(vol.dynBal.medium.X_air, 1e-13);
//   vol.dynBal.medium.phi = vol.dynBal.medium.p * vol.dynBal.medium.Xi[1] / (vol.dynBal.medium.p_steam_sat * (vol.dynBal.medium.Xi[1] + steam.MM * vol.dynBal.medium.X_air / dryair.MM));
//   vol.dynBal.medium.Xi[1] = vol.dynBal.medium.X[1];
//   vol.dynBal.medium.X[2] = 1.0 - vol.dynBal.medium.Xi[1];
//   assert(vol.dynBal.medium.X[1] >= -1e-05 and vol.dynBal.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(vol.dynBal.medium.X[1], 6, 0, true) + "of substance " + "water" + "
//   of medium " + "MoistAirPTDecoupledUnsaturated" + " is not in the range 0..1");
//   assert(vol.dynBal.medium.X[2] >= -1e-05 and vol.dynBal.medium.X[2] <= 1.00001, "Mass fraction X[2] = " + String(vol.dynBal.medium.X[2], 6, 0, true) + "of substance " + "air" + "
//   of medium " + "MoistAirPTDecoupledUnsaturated" + " is not in the range 0..1");
//   assert(vol.dynBal.medium.p >= 0.0, "Pressure (= " + String(vol.dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "MoistAirPTDecoupledUnsaturated" + "\" is negative
//   (Temperature = " + String(vol.dynBal.medium.T, 6, 0, true) + " K)");
//   vol.dynBal.m = vol.dynBal.fluidVolume * vol.dynBal.medium.d;
//   vol.dynBal.mXi[1] = vol.dynBal.medium.Xi[1] * vol.dynBal.m;
//   vol.dynBal.U = vol.dynBal.m * vol.dynBal.medium.u;
//   vol.dynBal.hOut = vol.dynBal.medium.h;
//   vol.dynBal.XiOut[1] = vol.dynBal.medium.Xi[1];
//   vol.dynBal.mbXi_flow[1] = 0.0;
//   vol.dynBal.mb_flow = 0.0;
//   vol.dynBal.Hb_flow = 0.0;
//   der(vol.dynBal.U) = vol.dynBal.Hb_flow + vol.dynBal.Q_flow;
//   der(vol.dynBal.m) = vol.dynBal.mb_flow + vol.dynBal.mXi_flow[1];
//   der(vol.dynBal.mXi[1]) = vol.dynBal.mbXi_flow[1] + vol.dynBal.mXi_flow[1];
//   vol.masExc[1].y = vol.masExc[1].k;
//   vol.p = if vol.nPorts > 0 then vol.ports[1].p else vol.p_start;
//   vol.T = Buildings.Fluid.MixingVolumes.MixingVolume$vol.Medium.temperature_phX(vol.p, vol.hOut_internal, {vol.Xi[1], 1.0 - vol.Xi[1]});
//   vol.Xi[1] = vol.XiOut_internal[1];
//   vol.heatPort.T = vol.T;
//   vol.heatPort.Q_flow = vol.Q_flow;
//   theCon.Q_flow = theCon.G * theCon.dT;
//   theCon.dT = theCon.port_a.T - theCon.port_b.T;
//   theCon.port_a.Q_flow = theCon.Q_flow;
//   theCon.port_b.Q_flow = -theCon.Q_flow;
//   TOut.port.T = TOut.T;
//   preHea.port.Q_flow = (-preHea.Q_flow) * (1.0 + preHea.alpha * (preHea.port.T - preHea.T_ref));
//   heaCap.T = heaCap.port.T;
//   heaCap.der_T = der(heaCap.T);
//   heaCap.C * der(heaCap.T) = heaCap.port.Q_flow;
//   when {time >= pre(timTab.nextTimeEvent), initial()} then
//     timTab.nextTimeEvent = Modelica.Blocks.Sources.CombiTimeTable$timTab.getNextTimeEvent(timTab.tableID, time, timTab.tableOnFileRead);
//   end when;
//   timTab.y[1] = timTab.p_offset[1] + Modelica.Blocks.Sources.CombiTimeTable$timTab.getTableValue(timTab.tableID, 1, time, timTab.nextTimeEvent, pre(timTab.nextTimeEvent), timTab.tableOnFileRead);
//   rad.preHeaFloCon[1].port.Q_flow = -rad.preHeaFloCon[1].Q_flow;
//   rad.preHeaFloCon[2].port.Q_flow = -rad.preHeaFloCon[2].Q_flow;
//   rad.preHeaFloCon[3].port.Q_flow = -rad.preHeaFloCon[3].Q_flow;
//   rad.preHeaFloCon[4].port.Q_flow = -rad.preHeaFloCon[4].Q_flow;
//   rad.preHeaFloCon[5].port.Q_flow = -rad.preHeaFloCon[5].Q_flow;
//   rad.preHeaFloRad[1].port.Q_flow = -rad.preHeaFloRad[1].Q_flow;
//   rad.preHeaFloRad[2].port.Q_flow = -rad.preHeaFloRad[2].Q_flow;
//   rad.preHeaFloRad[3].port.Q_flow = -rad.preHeaFloRad[3].Q_flow;
//   rad.preHeaFloRad[4].port.Q_flow = -rad.preHeaFloRad[4].Q_flow;
//   rad.preHeaFloRad[5].port.Q_flow = -rad.preHeaFloRad[5].Q_flow;
//   assert(rad.vol[1].dynBal.medium.T >= 272.15 and rad.vol[1].dynBal.medium.T <= 403.15, "
//             Temperature T (= " + String(rad.vol[1].dynBal.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   rad.vol[1].dynBal.medium.h = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[1].dynBal.medium.p, rad.vol[1].dynBal.medium.T, {rad.vol[1].dynBal.medium.X[1]});
//   rad.vol[1].dynBal.medium.u = 4184.0 * (-273.15 + rad.vol[1].dynBal.medium.T);
//   rad.vol[1].dynBal.medium.d = 995.586;
//   rad.vol[1].dynBal.medium.R = 0.0;
//   rad.vol[1].dynBal.medium.MM = 0.018015268;
//   rad.vol[1].dynBal.medium.state.T = rad.vol[1].dynBal.medium.T;
//   rad.vol[1].dynBal.medium.state.p = rad.vol[1].dynBal.medium.p;
//   rad.vol[1].dynBal.medium.X[1] = 1.0;
//   assert(rad.vol[1].dynBal.medium.X[1] >= -1e-05 and rad.vol[1].dynBal.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(rad.vol[1].dynBal.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(rad.vol[1].dynBal.medium.p >= 0.0, "Pressure (= " + String(rad.vol[1].dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(rad.vol[1].dynBal.medium.T, 6, 0, true) + " K)");
//   rad.vol[1].dynBal.m = rad.vol[1].dynBal.fluidVolume * rad.vol[1].dynBal.medium.d;
//   rad.vol[1].dynBal.U = rad.vol[1].dynBal.m * rad.vol[1].dynBal.medium.u;
//   rad.vol[1].dynBal.hOut = rad.vol[1].dynBal.medium.h;
//   rad.vol[1].dynBal.ports_H_flow[1] = rad.vol[1].dynBal.ports[1].m_flow * smooth(0, if rad.vol[1].dynBal.ports[1].m_flow > 0.0 then temSup.port_b.h_outflow else rad.vol[1].dynBal.ports[1].h_outflow);
//   rad.vol[1].dynBal.ports_H_flow[2] = rad.vol[1].dynBal.ports[2].m_flow * smooth(0, if rad.vol[1].dynBal.ports[2].m_flow > 0.0 then rad.vol[2].ports[1].h_outflow else rad.vol[1].dynBal.ports[2].h_outflow);
//   rad.vol[1].dynBal.mb_flow = rad.vol[1].dynBal.ports[1].m_flow + rad.vol[1].dynBal.ports[2].m_flow;
//   rad.vol[1].dynBal.Hb_flow = rad.vol[1].dynBal.ports_H_flow[1] + rad.vol[1].dynBal.ports_H_flow[2];
//   der(rad.vol[1].dynBal.U) = rad.vol[1].dynBal.Hb_flow + rad.vol[1].dynBal.Q_flow;
//   der(rad.vol[1].dynBal.m) = rad.vol[1].dynBal.mb_flow;
//   rad.vol[1].dynBal.ports[1].p = rad.vol[1].dynBal.medium.p;
//   rad.vol[1].dynBal.ports[1].h_outflow = rad.vol[1].dynBal.medium.h;
//   rad.vol[1].dynBal.ports[2].p = rad.vol[1].dynBal.medium.p;
//   rad.vol[1].dynBal.ports[2].h_outflow = rad.vol[1].dynBal.medium.h;
//   rad.vol[1].p = if rad.vol[1].nPorts > 0 then rad.vol[1].ports[1].p else rad.vol[1].p_start;
//   rad.vol[1].T = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.temperature_phX(rad.vol[1].p, rad.vol[1].hOut_internal, {1.0});
//   rad.vol[1].heatPort.T = rad.vol[1].T;
//   rad.vol[1].heatPort.Q_flow = rad.vol[1].Q_flow;
//   assert(rad.vol[2].dynBal.medium.T >= 272.15 and rad.vol[2].dynBal.medium.T <= 403.15, "
//             Temperature T (= " + String(rad.vol[2].dynBal.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   rad.vol[2].dynBal.medium.h = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[2].dynBal.medium.p, rad.vol[2].dynBal.medium.T, {rad.vol[2].dynBal.medium.X[1]});
//   rad.vol[2].dynBal.medium.u = 4184.0 * (-273.15 + rad.vol[2].dynBal.medium.T);
//   rad.vol[2].dynBal.medium.d = 995.586;
//   rad.vol[2].dynBal.medium.R = 0.0;
//   rad.vol[2].dynBal.medium.MM = 0.018015268;
//   rad.vol[2].dynBal.medium.state.T = rad.vol[2].dynBal.medium.T;
//   rad.vol[2].dynBal.medium.state.p = rad.vol[2].dynBal.medium.p;
//   rad.vol[2].dynBal.medium.X[1] = 1.0;
//   assert(rad.vol[2].dynBal.medium.X[1] >= -1e-05 and rad.vol[2].dynBal.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(rad.vol[2].dynBal.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(rad.vol[2].dynBal.medium.p >= 0.0, "Pressure (= " + String(rad.vol[2].dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(rad.vol[2].dynBal.medium.T, 6, 0, true) + " K)");
//   rad.vol[2].dynBal.m = rad.vol[2].dynBal.fluidVolume * rad.vol[2].dynBal.medium.d;
//   rad.vol[2].dynBal.U = rad.vol[2].dynBal.m * rad.vol[2].dynBal.medium.u;
//   rad.vol[2].dynBal.hOut = rad.vol[2].dynBal.medium.h;
//   rad.vol[2].dynBal.ports_H_flow[1] = rad.vol[2].dynBal.ports[1].m_flow * smooth(0, if rad.vol[2].dynBal.ports[1].m_flow > 0.0 then rad.vol[1].ports[2].h_outflow else rad.vol[2].dynBal.ports[1].h_outflow);
//   rad.vol[2].dynBal.ports_H_flow[2] = rad.vol[2].dynBal.ports[2].m_flow * smooth(0, if rad.vol[2].dynBal.ports[2].m_flow > 0.0 then rad.vol[3].ports[1].h_outflow else rad.vol[2].dynBal.ports[2].h_outflow);
//   rad.vol[2].dynBal.mb_flow = rad.vol[2].dynBal.ports[1].m_flow + rad.vol[2].dynBal.ports[2].m_flow;
//   rad.vol[2].dynBal.Hb_flow = rad.vol[2].dynBal.ports_H_flow[1] + rad.vol[2].dynBal.ports_H_flow[2];
//   der(rad.vol[2].dynBal.U) = rad.vol[2].dynBal.Hb_flow + rad.vol[2].dynBal.Q_flow;
//   der(rad.vol[2].dynBal.m) = rad.vol[2].dynBal.mb_flow;
//   rad.vol[2].dynBal.ports[1].p = rad.vol[2].dynBal.medium.p;
//   rad.vol[2].dynBal.ports[1].h_outflow = rad.vol[2].dynBal.medium.h;
//   rad.vol[2].dynBal.ports[2].p = rad.vol[2].dynBal.medium.p;
//   rad.vol[2].dynBal.ports[2].h_outflow = rad.vol[2].dynBal.medium.h;
//   rad.vol[2].p = if rad.vol[2].nPorts > 0 then rad.vol[2].ports[1].p else rad.vol[2].p_start;
//   rad.vol[2].T = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.temperature_phX(rad.vol[2].p, rad.vol[2].hOut_internal, {1.0});
//   rad.vol[2].heatPort.T = rad.vol[2].T;
//   rad.vol[2].heatPort.Q_flow = rad.vol[2].Q_flow;
//   assert(rad.vol[3].dynBal.medium.T >= 272.15 and rad.vol[3].dynBal.medium.T <= 403.15, "
//             Temperature T (= " + String(rad.vol[3].dynBal.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   rad.vol[3].dynBal.medium.h = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[3].dynBal.medium.p, rad.vol[3].dynBal.medium.T, {rad.vol[3].dynBal.medium.X[1]});
//   rad.vol[3].dynBal.medium.u = 4184.0 * (-273.15 + rad.vol[3].dynBal.medium.T);
//   rad.vol[3].dynBal.medium.d = 995.586;
//   rad.vol[3].dynBal.medium.R = 0.0;
//   rad.vol[3].dynBal.medium.MM = 0.018015268;
//   rad.vol[3].dynBal.medium.state.T = rad.vol[3].dynBal.medium.T;
//   rad.vol[3].dynBal.medium.state.p = rad.vol[3].dynBal.medium.p;
//   rad.vol[3].dynBal.medium.X[1] = 1.0;
//   assert(rad.vol[3].dynBal.medium.X[1] >= -1e-05 and rad.vol[3].dynBal.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(rad.vol[3].dynBal.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(rad.vol[3].dynBal.medium.p >= 0.0, "Pressure (= " + String(rad.vol[3].dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(rad.vol[3].dynBal.medium.T, 6, 0, true) + " K)");
//   rad.vol[3].dynBal.m = rad.vol[3].dynBal.fluidVolume * rad.vol[3].dynBal.medium.d;
//   rad.vol[3].dynBal.U = rad.vol[3].dynBal.m * rad.vol[3].dynBal.medium.u;
//   rad.vol[3].dynBal.hOut = rad.vol[3].dynBal.medium.h;
//   rad.vol[3].dynBal.ports_H_flow[1] = rad.vol[3].dynBal.ports[1].m_flow * smooth(0, if rad.vol[3].dynBal.ports[1].m_flow > 0.0 then rad.vol[2].ports[2].h_outflow else rad.vol[3].dynBal.ports[1].h_outflow);
//   rad.vol[3].dynBal.ports_H_flow[2] = rad.vol[3].dynBal.ports[2].m_flow * smooth(0, if rad.vol[3].dynBal.ports[2].m_flow > 0.0 then rad.vol[4].ports[1].h_outflow else rad.vol[3].dynBal.ports[2].h_outflow);
//   rad.vol[3].dynBal.mb_flow = rad.vol[3].dynBal.ports[1].m_flow + rad.vol[3].dynBal.ports[2].m_flow;
//   rad.vol[3].dynBal.Hb_flow = rad.vol[3].dynBal.ports_H_flow[1] + rad.vol[3].dynBal.ports_H_flow[2];
//   der(rad.vol[3].dynBal.U) = rad.vol[3].dynBal.Hb_flow + rad.vol[3].dynBal.Q_flow;
//   der(rad.vol[3].dynBal.m) = rad.vol[3].dynBal.mb_flow;
//   rad.vol[3].dynBal.ports[1].p = rad.vol[3].dynBal.medium.p;
//   rad.vol[3].dynBal.ports[1].h_outflow = rad.vol[3].dynBal.medium.h;
//   rad.vol[3].dynBal.ports[2].p = rad.vol[3].dynBal.medium.p;
//   rad.vol[3].dynBal.ports[2].h_outflow = rad.vol[3].dynBal.medium.h;
//   rad.vol[3].p = if rad.vol[3].nPorts > 0 then rad.vol[3].ports[1].p else rad.vol[3].p_start;
//   rad.vol[3].T = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.temperature_phX(rad.vol[3].p, rad.vol[3].hOut_internal, {1.0});
//   rad.vol[3].heatPort.T = rad.vol[3].T;
//   rad.vol[3].heatPort.Q_flow = rad.vol[3].Q_flow;
//   assert(rad.vol[4].dynBal.medium.T >= 272.15 and rad.vol[4].dynBal.medium.T <= 403.15, "
//             Temperature T (= " + String(rad.vol[4].dynBal.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   rad.vol[4].dynBal.medium.h = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[4].dynBal.medium.p, rad.vol[4].dynBal.medium.T, {rad.vol[4].dynBal.medium.X[1]});
//   rad.vol[4].dynBal.medium.u = 4184.0 * (-273.15 + rad.vol[4].dynBal.medium.T);
//   rad.vol[4].dynBal.medium.d = 995.586;
//   rad.vol[4].dynBal.medium.R = 0.0;
//   rad.vol[4].dynBal.medium.MM = 0.018015268;
//   rad.vol[4].dynBal.medium.state.T = rad.vol[4].dynBal.medium.T;
//   rad.vol[4].dynBal.medium.state.p = rad.vol[4].dynBal.medium.p;
//   rad.vol[4].dynBal.medium.X[1] = 1.0;
//   assert(rad.vol[4].dynBal.medium.X[1] >= -1e-05 and rad.vol[4].dynBal.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(rad.vol[4].dynBal.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(rad.vol[4].dynBal.medium.p >= 0.0, "Pressure (= " + String(rad.vol[4].dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(rad.vol[4].dynBal.medium.T, 6, 0, true) + " K)");
//   rad.vol[4].dynBal.m = rad.vol[4].dynBal.fluidVolume * rad.vol[4].dynBal.medium.d;
//   rad.vol[4].dynBal.U = rad.vol[4].dynBal.m * rad.vol[4].dynBal.medium.u;
//   rad.vol[4].dynBal.hOut = rad.vol[4].dynBal.medium.h;
//   rad.vol[4].dynBal.ports_H_flow[1] = rad.vol[4].dynBal.ports[1].m_flow * smooth(0, if rad.vol[4].dynBal.ports[1].m_flow > 0.0 then rad.vol[3].ports[2].h_outflow else rad.vol[4].dynBal.ports[1].h_outflow);
//   rad.vol[4].dynBal.ports_H_flow[2] = rad.vol[4].dynBal.ports[2].m_flow * smooth(0, if rad.vol[4].dynBal.ports[2].m_flow > 0.0 then rad.vol[5].ports[1].h_outflow else rad.vol[4].dynBal.ports[2].h_outflow);
//   rad.vol[4].dynBal.mb_flow = rad.vol[4].dynBal.ports[1].m_flow + rad.vol[4].dynBal.ports[2].m_flow;
//   rad.vol[4].dynBal.Hb_flow = rad.vol[4].dynBal.ports_H_flow[1] + rad.vol[4].dynBal.ports_H_flow[2];
//   der(rad.vol[4].dynBal.U) = rad.vol[4].dynBal.Hb_flow + rad.vol[4].dynBal.Q_flow;
//   der(rad.vol[4].dynBal.m) = rad.vol[4].dynBal.mb_flow;
//   rad.vol[4].dynBal.ports[1].p = rad.vol[4].dynBal.medium.p;
//   rad.vol[4].dynBal.ports[1].h_outflow = rad.vol[4].dynBal.medium.h;
//   rad.vol[4].dynBal.ports[2].p = rad.vol[4].dynBal.medium.p;
//   rad.vol[4].dynBal.ports[2].h_outflow = rad.vol[4].dynBal.medium.h;
//   rad.vol[4].p = if rad.vol[4].nPorts > 0 then rad.vol[4].ports[1].p else rad.vol[4].p_start;
//   rad.vol[4].T = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.temperature_phX(rad.vol[4].p, rad.vol[4].hOut_internal, {1.0});
//   rad.vol[4].heatPort.T = rad.vol[4].T;
//   rad.vol[4].heatPort.Q_flow = rad.vol[4].Q_flow;
//   assert(rad.vol[5].dynBal.medium.T >= 272.15 and rad.vol[5].dynBal.medium.T <= 403.15, "
//             Temperature T (= " + String(rad.vol[5].dynBal.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   rad.vol[5].dynBal.medium.h = Buildings.Fluid.Interfaces.ConservationEquation$rad$vol$dynBal.Medium.specificEnthalpy_pTX(rad.vol[5].dynBal.medium.p, rad.vol[5].dynBal.medium.T, {rad.vol[5].dynBal.medium.X[1]});
//   rad.vol[5].dynBal.medium.u = 4184.0 * (-273.15 + rad.vol[5].dynBal.medium.T);
//   rad.vol[5].dynBal.medium.d = 995.586;
//   rad.vol[5].dynBal.medium.R = 0.0;
//   rad.vol[5].dynBal.medium.MM = 0.018015268;
//   rad.vol[5].dynBal.medium.state.T = rad.vol[5].dynBal.medium.T;
//   rad.vol[5].dynBal.medium.state.p = rad.vol[5].dynBal.medium.p;
//   rad.vol[5].dynBal.medium.X[1] = 1.0;
//   assert(rad.vol[5].dynBal.medium.X[1] >= -1e-05 and rad.vol[5].dynBal.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(rad.vol[5].dynBal.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(rad.vol[5].dynBal.medium.p >= 0.0, "Pressure (= " + String(rad.vol[5].dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(rad.vol[5].dynBal.medium.T, 6, 0, true) + " K)");
//   rad.vol[5].dynBal.m = rad.vol[5].dynBal.fluidVolume * rad.vol[5].dynBal.medium.d;
//   rad.vol[5].dynBal.U = rad.vol[5].dynBal.m * rad.vol[5].dynBal.medium.u;
//   rad.vol[5].dynBal.hOut = rad.vol[5].dynBal.medium.h;
//   rad.vol[5].dynBal.ports_H_flow[1] = rad.vol[5].dynBal.ports[1].m_flow * smooth(0, if rad.vol[5].dynBal.ports[1].m_flow > 0.0 then rad.vol[4].ports[2].h_outflow else rad.vol[5].dynBal.ports[1].h_outflow);
//   rad.vol[5].dynBal.ports_H_flow[2] = rad.vol[5].dynBal.ports[2].m_flow * smooth(0, if rad.vol[5].dynBal.ports[2].m_flow > 0.0 then sin.ports[1].h_outflow else rad.vol[5].dynBal.ports[2].h_outflow);
//   rad.vol[5].dynBal.mb_flow = rad.vol[5].dynBal.ports[1].m_flow + rad.vol[5].dynBal.ports[2].m_flow;
//   rad.vol[5].dynBal.Hb_flow = rad.vol[5].dynBal.ports_H_flow[1] + rad.vol[5].dynBal.ports_H_flow[2];
//   der(rad.vol[5].dynBal.U) = rad.vol[5].dynBal.Hb_flow + rad.vol[5].dynBal.Q_flow;
//   der(rad.vol[5].dynBal.m) = rad.vol[5].dynBal.mb_flow;
//   rad.vol[5].dynBal.ports[1].p = rad.vol[5].dynBal.medium.p;
//   rad.vol[5].dynBal.ports[1].h_outflow = rad.vol[5].dynBal.medium.h;
//   rad.vol[5].dynBal.ports[2].p = rad.vol[5].dynBal.medium.p;
//   rad.vol[5].dynBal.ports[2].h_outflow = rad.vol[5].dynBal.medium.h;
//   rad.vol[5].p = if rad.vol[5].nPorts > 0 then rad.vol[5].ports[1].p else rad.vol[5].p_start;
//   rad.vol[5].T = Buildings.Fluid.MixingVolumes.MixingVolume$rad$vol.Medium.temperature_phX(rad.vol[5].p, rad.vol[5].hOut_internal, {1.0});
//   rad.vol[5].heatPort.T = rad.vol[5].T;
//   rad.vol[5].heatPort.Q_flow = rad.vol[5].Q_flow;
//   rad.sta_a = if rad.homotopyInitialization then Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_phX(rad.port_a.p, homotopy(smooth(0, if rad.port_a.m_flow > 0.0 then temSup.port_b.h_outflow else rad.port_a.h_outflow), temSup.port_b.h_outflow), {}) else Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_phX(rad.port_a.p, smooth(0, if rad.port_a.m_flow > 0.0 then temSup.port_b.h_outflow else rad.port_a.h_outflow), {});
//   rad.sta_b = if rad.homotopyInitialization then Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_phX(rad.port_b.p, homotopy(smooth(0, if rad.port_b.m_flow > 0.0 then sin.ports[1].h_outflow else rad.port_b.h_outflow), rad.port_b.h_outflow), {}) else Buildings.Fluid.HeatExchangers.Radiators.RadiatorEN442_2$rad.Medium.setState_phX(rad.port_b.p, smooth(0, if rad.port_b.m_flow > 0.0 then sin.ports[1].h_outflow else rad.port_b.h_outflow), {});
//   rad.heaCap[1].T = rad.heaCap[1].port.T;
//   rad.heaCap[1].der_T = der(rad.heaCap[1].T);
//   rad.heaCap[1].C * der(rad.heaCap[1].T) = rad.heaCap[1].port.Q_flow;
//   rad.heaCap[2].T = rad.heaCap[2].port.T;
//   rad.heaCap[2].der_T = der(rad.heaCap[2].T);
//   rad.heaCap[2].C * der(rad.heaCap[2].T) = rad.heaCap[2].port.Q_flow;
//   rad.heaCap[3].T = rad.heaCap[3].port.T;
//   rad.heaCap[3].der_T = der(rad.heaCap[3].T);
//   rad.heaCap[3].C * der(rad.heaCap[3].T) = rad.heaCap[3].port.Q_flow;
//   rad.heaCap[4].T = rad.heaCap[4].port.T;
//   rad.heaCap[4].der_T = der(rad.heaCap[4].T);
//   rad.heaCap[4].C * der(rad.heaCap[4].T) = rad.heaCap[4].port.Q_flow;
//   rad.heaCap[5].T = rad.heaCap[5].port.T;
//   rad.heaCap[5].der_T = der(rad.heaCap[5].T);
//   rad.heaCap[5].C * der(rad.heaCap[5].T) = rad.heaCap[5].port.Q_flow;
//   rad.dTCon[1] = rad.heatPortCon.T - rad.vol[1].T;
//   rad.dTCon[2] = rad.heatPortCon.T - rad.vol[2].T;
//   rad.dTCon[3] = rad.heatPortCon.T - rad.vol[3].T;
//   rad.dTCon[4] = rad.heatPortCon.T - rad.vol[4].T;
//   rad.dTCon[5] = rad.heatPortCon.T - rad.vol[5].T;
//   rad.dTRad[1] = rad.heatPortRad.T - rad.vol[1].T;
//   rad.dTRad[2] = rad.heatPortRad.T - rad.vol[2].T;
//   rad.dTRad[3] = rad.heatPortRad.T - rad.vol[3].T;
//   rad.dTRad[4] = rad.heatPortRad.T - rad.vol[4].T;
//   rad.dTRad[5] = rad.heatPortRad.T - rad.vol[5].T;
//   rad.preHeaFloCon[1].Q_flow = homotopy(rad.dTCon[1] * (1.0 - rad.fraRad) * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTCon[1], -1.0 + rad.n, 0.05), abs(rad.dTCon_nominal[1]) ^ (-1.0 + rad.n) * (1.0 - rad.fraRad) * rad.UAEle * rad.dTCon[1]);
//   rad.preHeaFloCon[2].Q_flow = homotopy(rad.dTCon[2] * (1.0 - rad.fraRad) * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTCon[2], -1.0 + rad.n, 0.05), abs(rad.dTCon_nominal[2]) ^ (-1.0 + rad.n) * (1.0 - rad.fraRad) * rad.UAEle * rad.dTCon[2]);
//   rad.preHeaFloCon[3].Q_flow = homotopy(rad.dTCon[3] * (1.0 - rad.fraRad) * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTCon[3], -1.0 + rad.n, 0.05), abs(rad.dTCon_nominal[3]) ^ (-1.0 + rad.n) * (1.0 - rad.fraRad) * rad.UAEle * rad.dTCon[3]);
//   rad.preHeaFloCon[4].Q_flow = homotopy(rad.dTCon[4] * (1.0 - rad.fraRad) * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTCon[4], -1.0 + rad.n, 0.05), abs(rad.dTCon_nominal[4]) ^ (-1.0 + rad.n) * (1.0 - rad.fraRad) * rad.UAEle * rad.dTCon[4]);
//   rad.preHeaFloCon[5].Q_flow = homotopy(rad.dTCon[5] * (1.0 - rad.fraRad) * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTCon[5], -1.0 + rad.n, 0.05), abs(rad.dTCon_nominal[5]) ^ (-1.0 + rad.n) * (1.0 - rad.fraRad) * rad.UAEle * rad.dTCon[5]);
//   rad.preHeaFloRad[1].Q_flow = homotopy(rad.dTRad[1] * rad.fraRad * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTRad[1], -1.0 + rad.n, 0.05), abs(rad.dTRad_nominal[1]) ^ (-1.0 + rad.n) * rad.fraRad * rad.UAEle * rad.dTRad[1]);
//   rad.preHeaFloRad[2].Q_flow = homotopy(rad.dTRad[2] * rad.fraRad * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTRad[2], -1.0 + rad.n, 0.05), abs(rad.dTRad_nominal[2]) ^ (-1.0 + rad.n) * rad.fraRad * rad.UAEle * rad.dTRad[2]);
//   rad.preHeaFloRad[3].Q_flow = homotopy(rad.dTRad[3] * rad.fraRad * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTRad[3], -1.0 + rad.n, 0.05), abs(rad.dTRad_nominal[3]) ^ (-1.0 + rad.n) * rad.fraRad * rad.UAEle * rad.dTRad[3]);
//   rad.preHeaFloRad[4].Q_flow = homotopy(rad.dTRad[4] * rad.fraRad * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTRad[4], -1.0 + rad.n, 0.05), abs(rad.dTRad_nominal[4]) ^ (-1.0 + rad.n) * rad.fraRad * rad.UAEle * rad.dTRad[4]);
//   rad.preHeaFloRad[5].Q_flow = homotopy(rad.dTRad[5] * rad.fraRad * rad.UAEle * Buildings.Utilities.Math.Functions.regNonZeroPower(rad.dTRad[5], -1.0 + rad.n, 0.05), abs(rad.dTRad_nominal[5]) ^ (-1.0 + rad.n) * rad.fraRad * rad.UAEle * rad.dTRad[5]);
//   rad.QCon_flow = rad.preHeaFloCon[1].Q_flow + rad.preHeaFloCon[2].Q_flow + rad.preHeaFloCon[3].Q_flow + rad.preHeaFloCon[4].Q_flow + rad.preHeaFloCon[5].Q_flow;
//   rad.QRad_flow = rad.preHeaFloRad[1].Q_flow + rad.preHeaFloRad[2].Q_flow + rad.preHeaFloRad[3].Q_flow + rad.preHeaFloRad[4].Q_flow + rad.preHeaFloRad[5].Q_flow;
//   rad.Q_flow = rad.QCon_flow + rad.QRad_flow;
//   rad.heatPortCon.Q_flow = rad.QCon_flow;
//   rad.heatPortRad.Q_flow = rad.QRad_flow;
//   rad.dp = rad.port_a.p - rad.port_b.p;
//   assert(sin.medium.T >= 272.15 and sin.medium.T <= 403.15, "
//             Temperature T (= " + String(sin.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   sin.medium.h = Buildings.Fluid.Sources.FixedBoundary$sin.Medium.specificEnthalpy_pTX(sin.medium.p, sin.medium.T, {sin.medium.X[1]});
//   sin.medium.u = 4184.0 * (-273.15 + sin.medium.T);
//   sin.medium.d = 995.586;
//   sin.medium.R = 0.0;
//   sin.medium.MM = 0.018015268;
//   sin.medium.state.T = sin.medium.T;
//   sin.medium.state.p = sin.medium.p;
//   sin.medium.X[1] = 1.0;
//   assert(sin.medium.X[1] >= -1e-05 and sin.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(sin.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(sin.medium.p >= 0.0, "Pressure (= " + String(sin.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(sin.medium.T, 6, 0, true) + " K)");
//   Modelica.Fluid.Utilities.checkBoundary("SimpleLiquidWater", {"SimpleLiquidWater"}, true, sin.use_p, {sin.X[1]}, "FixedBoundary");
//   sin.medium.p = sin.p;
//   sin.medium.T = sin.T;
//   sin.ports[1].p = sin.medium.p;
//   sin.ports[1].h_outflow = sin.medium.h;
//   temSup.T_a_inflow = Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.temperature(Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.setState_phX(temSup.port_b.p, temSup.port_b.h_outflow, {}));
//   temSup.T_b_inflow = Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.temperature(Buildings.Fluid.Sensors.TemperatureTwoPort$temSup.Medium.setState_phX(temSup.port_a.p, temSup.port_a.h_outflow, {}));
//   temSup.TMed = Modelica.Fluid.Utilities.regStep(temSup.port_a.m_flow, temSup.T_a_inflow, temSup.T_b_inflow, temSup.m_flow_small);
//   der(temSup.T) = (temSup.TMed - temSup.T) * temSup.k / temSup.tau;
//   temSup.mNor_flow = temSup.port_a.m_flow / temSup.m_flow_nominal;
//   temSup.k = Modelica.Fluid.Utilities.regStep(temSup.port_a.m_flow, temSup.mNor_flow, -temSup.mNor_flow, temSup.m_flow_small);
//   0.0 = temSup.port_a.m_flow + temSup.port_b.m_flow;
//   temSup.port_a.p = temSup.port_b.p;
//   temSup.port_a.h_outflow = rad.port_a.h_outflow;
//   temSup.port_b.h_outflow = pumRad.port_b.h_outflow;
//   temRoo.T = temRoo.port.T;
//   temRoo.port.Q_flow = 0.0;
//   assert(pumRad.vol.dynBal.medium.T >= 272.15 and pumRad.vol.dynBal.medium.T <= 403.15, "
//             Temperature T (= " + String(pumRad.vol.dynBal.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   pumRad.vol.dynBal.medium.h = Buildings.Fluid.Interfaces.ConservationEquation$pumRad$vol$dynBal.Medium.specificEnthalpy_pTX(pumRad.vol.dynBal.medium.p, pumRad.vol.dynBal.medium.T, {pumRad.vol.dynBal.medium.X[1]});
//   pumRad.vol.dynBal.medium.u = 4184.0 * (-273.15 + pumRad.vol.dynBal.medium.T);
//   pumRad.vol.dynBal.medium.d = 995.586;
//   pumRad.vol.dynBal.medium.R = 0.0;
//   pumRad.vol.dynBal.medium.MM = 0.018015268;
//   pumRad.vol.dynBal.medium.state.T = pumRad.vol.dynBal.medium.T;
//   pumRad.vol.dynBal.medium.state.p = pumRad.vol.dynBal.medium.p;
//   pumRad.vol.dynBal.medium.X[1] = 1.0;
//   assert(pumRad.vol.dynBal.medium.X[1] >= -1e-05 and pumRad.vol.dynBal.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(pumRad.vol.dynBal.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(pumRad.vol.dynBal.medium.p >= 0.0, "Pressure (= " + String(pumRad.vol.dynBal.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(pumRad.vol.dynBal.medium.T, 6, 0, true) + " K)");
//   pumRad.vol.dynBal.m = pumRad.vol.dynBal.fluidVolume * pumRad.vol.dynBal.medium.d;
//   pumRad.vol.dynBal.U = pumRad.vol.dynBal.m * pumRad.vol.dynBal.medium.u;
//   pumRad.vol.dynBal.hOut = pumRad.vol.dynBal.medium.h;
//   pumRad.vol.dynBal.ports_H_flow[1] = pumRad.vol.dynBal.ports[1].m_flow * smooth(0, if pumRad.vol.dynBal.ports[1].m_flow > 0.0 then sou.ports[1].h_outflow else pumRad.vol.dynBal.ports[1].h_outflow);
//   pumRad.vol.dynBal.ports_H_flow[2] = pumRad.vol.dynBal.ports[2].m_flow * smooth(0, if pumRad.vol.dynBal.ports[2].m_flow > 0.0 then pumRad.preSou.port_a.h_outflow else pumRad.vol.dynBal.ports[2].h_outflow);
//   pumRad.vol.dynBal.mb_flow = pumRad.vol.dynBal.ports[1].m_flow + pumRad.vol.dynBal.ports[2].m_flow;
//   pumRad.vol.dynBal.Hb_flow = pumRad.vol.dynBal.ports_H_flow[1] + pumRad.vol.dynBal.ports_H_flow[2];
//   der(pumRad.vol.dynBal.U) = pumRad.vol.dynBal.Hb_flow + pumRad.vol.dynBal.Q_flow;
//   der(pumRad.vol.dynBal.m) = pumRad.vol.dynBal.mb_flow;
//   pumRad.vol.dynBal.ports[1].p = pumRad.vol.dynBal.medium.p;
//   pumRad.vol.dynBal.ports[1].h_outflow = pumRad.vol.dynBal.medium.h;
//   pumRad.vol.dynBal.ports[2].p = pumRad.vol.dynBal.medium.p;
//   pumRad.vol.dynBal.ports[2].h_outflow = pumRad.vol.dynBal.medium.h;
//   pumRad.vol.p = if pumRad.vol.nPorts > 0 then pumRad.vol.ports[1].p else pumRad.vol.p_start;
//   pumRad.vol.T = Buildings.Fluid.Delays.DelayFirstOrder$pumRad$vol.Medium.temperature_phX(pumRad.vol.p, pumRad.vol.hOut_internal, {1.0});
//   pumRad.vol.heatPort.T = pumRad.vol.T;
//   pumRad.vol.heatPort.Q_flow = pumRad.vol.Q_flow;
//   pumRad.preSou.m_flow = pumRad.preSou.m_flow_internal;
//   pumRad.preSou.dp_internal = 0.0;
//   pumRad.preSou.port_a.h_outflow = temSup.port_a.h_outflow;
//   pumRad.preSou.port_b.h_outflow = pumRad.vol.ports[2].h_outflow;
//   pumRad.preSou.state_a = Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.setState_phX(pumRad.preSou.port_a.p, pumRad.vol.ports[2].h_outflow, {});
//   pumRad.preSou.state_b = Buildings.Fluid.Movers.BaseClasses.IdealSource$pumRad$preSou.Medium.setState_phX(pumRad.preSou.port_b.p, temSup.port_a.h_outflow, {});
//   pumRad.preSou.dp = pumRad.preSou.port_a.p - pumRad.preSou.port_b.p;
//   pumRad.preSou.m_flow = pumRad.preSou.port_a.m_flow;
//   assert(pumRad.preSou.m_flow > (-pumRad.preSou.m_flow_small) or pumRad.preSou.allowFlowReversal, "Reverting flow occurs even though allowFlowReversal is false");
//   pumRad.preSou.port_a.m_flow + pumRad.preSou.port_b.m_flow = 0.0;
//   pumRad.prePow.port.Q_flow = -pumRad.prePow.Q_flow;
//   assert(pumRad.filter.u_nominal > 0.0, "u_nominal > 0 required");
//   assert(pumRad.filter.filterType == Modelica.Blocks.Types.FilterType.LowPass or pumRad.filter.filterType == Modelica.Blocks.Types.FilterType.HighPass or pumRad.filter.f_min > 0.0, "f_min > 0 required for band pass and band stop filter");
//   assert(pumRad.filter.A_ripple > 0.0, "A_ripple > 0 required");
//   assert(pumRad.filter.f_cut > 0.0, "f_cut > 0 required");
//   pumRad.filter.uu[1] = pumRad.filter.u / pumRad.filter.u_nominal;
//   der(pumRad.filter.x[1]) = pumRad.filter.r[1] * (pumRad.filter.x[1] - pumRad.filter.uu[1]);
//   der(pumRad.filter.x[2]) = pumRad.filter.r[2] * (pumRad.filter.x[2] - pumRad.filter.uu[2]);
//   pumRad.filter.uu[2] = pumRad.filter.x[1];
//   pumRad.filter.uu[3] = pumRad.filter.x[2];
//   pumRad.filter.y = pumRad.filter.gain * pumRad.filter.u_nominal * pumRad.filter.uu[3];
//   pumRad.r_V = pumRad.VMachine_flow / pumRad.V_flow_max;
//   pumRad.etaHyd = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency(/*.Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters*/(pumRad.hydraulicEfficiency), pumRad.r_V, {pumRad.hydDer[1]});
//   pumRad.etaMot = Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiency(/*.Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters*/(pumRad.motorEfficiency), pumRad.r_V, {pumRad.motDer[1]});
//   pumRad.dpMachine = -pumRad.dp;
//   pumRad.VMachine_flow = (-pumRad.port_b.m_flow) / pumRad.rho_in;
//   pumRad.P = pumRad.WFlo / Buildings.Utilities.Math.Functions.smoothMax(pumRad.eta, 1e-05, 1e-06);
//   pumRad.rho_in = Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.density(Buildings.Fluid.Movers.FlowMachine_m_flow$pumRad.Medium.setState_phX(pumRad.port_a.p, sou.ports[1].h_outflow, {}));
//   pumRad.dp = pumRad.port_a.p - pumRad.port_b.p;
//   pumRad.eta = pumRad.etaHyd * pumRad.etaMot;
//   pumRad.WFlo = pumRad.dpMachine * pumRad.VMachine_flow;
//   pumRad.etaHyd * pumRad.WHyd = pumRad.WFlo;
//   pumRad.QThe_flow + pumRad.WFlo = if pumRad.motorCooledByFluid then pumRad.P else pumRad.WHyd;
//   pumRad.Q_flow = homotopy(Buildings.Utilities.Math.Functions.spliceFunction(pumRad.QThe_flow, 0.0, abs(pumRad.VMachine_flow) + (-2.0) * pumRad.delta_V_flow, pumRad.delta_V_flow), 0.0);
//   assert(sou.medium.T >= 272.15 and sou.medium.T <= 403.15, "
//             Temperature T (= " + String(sou.medium.T, 6, 0, true) + " K) is not
//             in the allowed range (" + String(272.15, 6, 0, true) + " K <= T <= " + String(403.15, 6, 0, true) + " K)
//             required from medium model \"" + "SimpleLiquidWater" + "\".
//             ");
//   sou.medium.h = Buildings.Fluid.Sources.FixedBoundary$sou.Medium.specificEnthalpy_pTX(sou.medium.p, sou.medium.T, {sou.medium.X[1]});
//   sou.medium.u = 4184.0 * (-273.15 + sou.medium.T);
//   sou.medium.d = 995.586;
//   sou.medium.R = 0.0;
//   sou.medium.MM = 0.018015268;
//   sou.medium.state.T = sou.medium.T;
//   sou.medium.state.p = sou.medium.p;
//   sou.medium.X[1] = 1.0;
//   assert(sou.medium.X[1] >= -1e-05 and sou.medium.X[1] <= 1.00001, "Mass fraction X[1] = " + String(sou.medium.X[1], 6, 0, true) + "of substance " + "SimpleLiquidWater" + "
//   of medium " + "SimpleLiquidWater" + " is not in the range 0..1");
//   assert(sou.medium.p >= 0.0, "Pressure (= " + String(sou.medium.p, 6, 0, true) + " Pa) of medium \"" + "SimpleLiquidWater" + "\" is negative
//   (Temperature = " + String(sou.medium.T, 6, 0, true) + " K)");
//   Modelica.Fluid.Utilities.checkBoundary("SimpleLiquidWater", {"SimpleLiquidWater"}, true, sou.use_p, {sou.X[1]}, "FixedBoundary");
//   sou.medium.p = sou.p;
//   sou.medium.T = sou.T;
//   sou.ports[1].p = sou.medium.p;
//   sou.ports[1].h_outflow = sou.medium.h;
//   hysPum.y = hysPum.u > hysPum.uHigh or pre(hysPum.y) and hysPum.u >= hysPum.uLow;
//   booToReaRad.y = if booToReaRad.u then booToReaRad.realTrue else booToReaRad.realFalse;
//   not1.y = not not1.u;
//   theCon.port_a.Q_flow + TOut.port.Q_flow = 0.0;
//   theCon.port_b.Q_flow + preHea.port.Q_flow + temRoo.port.Q_flow + rad.heatPortCon.Q_flow + rad.heatPortRad.Q_flow + heaCap.port.Q_flow + vol.heatPort.Q_flow = 0.0;
//   sin.ports[1].m_flow + rad.port_b.m_flow = 0.0;
//   sou.ports[1].m_flow + pumRad.port_a.m_flow = 0.0;
//   rad.preHeaFloCon[5].port.Q_flow + rad.preHeaFloRad[5].port.Q_flow + rad.heaCap[5].port.Q_flow + rad.vol[5].heatPort.Q_flow = 0.0;
//   rad.preHeaFloCon[4].port.Q_flow + rad.preHeaFloRad[4].port.Q_flow + rad.heaCap[4].port.Q_flow + rad.vol[4].heatPort.Q_flow = 0.0;
//   rad.preHeaFloCon[3].port.Q_flow + rad.preHeaFloRad[3].port.Q_flow + rad.heaCap[3].port.Q_flow + rad.vol[3].heatPort.Q_flow = 0.0;
//   rad.preHeaFloCon[2].port.Q_flow + rad.preHeaFloRad[2].port.Q_flow + rad.heaCap[2].port.Q_flow + rad.vol[2].heatPort.Q_flow = 0.0;
//   rad.preHeaFloCon[1].port.Q_flow + rad.preHeaFloRad[1].port.Q_flow + rad.heaCap[1].port.Q_flow + rad.vol[1].heatPort.Q_flow = 0.0;
//   rad.port_a.m_flow + temSup.port_b.m_flow = 0.0;
//   (-rad.port_b.m_flow) + rad.vol[5].ports[2].m_flow = 0.0;
//   rad.vol[5].ports[1].m_flow + rad.vol[4].ports[2].m_flow = 0.0;
//   (-rad.vol[5].ports[2].m_flow) + rad.vol[5].dynBal.ports[2].m_flow = 0.0;
//   (-rad.vol[5].ports[1].m_flow) + rad.vol[5].dynBal.ports[1].m_flow = 0.0;
//   rad.vol[5].dynBal.Q_flow = rad.vol[5].heaInp.y;
//   rad.vol[5].ports[1].h_outflow = rad.vol[5].dynBal.ports[1].h_outflow;
//   rad.vol[5].dynBal.ports[1].p = rad.vol[5].ports[1].p;
//   rad.vol[5].ports[2].h_outflow = rad.vol[5].dynBal.ports[2].h_outflow;
//   rad.vol[5].dynBal.ports[2].p = rad.vol[5].ports[2].p;
//   rad.vol[5].dynBal.hOut = rad.vol[5].hOut_internal;
//   rad.vol[4].ports[1].m_flow + rad.vol[3].ports[2].m_flow = 0.0;
//   (-rad.vol[4].ports[2].m_flow) + rad.vol[4].dynBal.ports[2].m_flow = 0.0;
//   (-rad.vol[4].ports[1].m_flow) + rad.vol[4].dynBal.ports[1].m_flow = 0.0;
//   rad.vol[4].dynBal.Q_flow = rad.vol[4].heaInp.y;
//   rad.vol[4].ports[1].h_outflow = rad.vol[4].dynBal.ports[1].h_outflow;
//   rad.vol[4].dynBal.ports[1].p = rad.vol[4].ports[1].p;
//   rad.vol[4].ports[2].h_outflow = rad.vol[4].dynBal.ports[2].h_outflow;
//   rad.vol[4].dynBal.ports[2].p = rad.vol[4].ports[2].p;
//   rad.vol[4].dynBal.hOut = rad.vol[4].hOut_internal;
//   rad.vol[3].ports[1].m_flow + rad.vol[2].ports[2].m_flow = 0.0;
//   (-rad.vol[3].ports[2].m_flow) + rad.vol[3].dynBal.ports[2].m_flow = 0.0;
//   (-rad.vol[3].ports[1].m_flow) + rad.vol[3].dynBal.ports[1].m_flow = 0.0;
//   rad.vol[3].dynBal.Q_flow = rad.vol[3].heaInp.y;
//   rad.vol[3].ports[1].h_outflow = rad.vol[3].dynBal.ports[1].h_outflow;
//   rad.vol[3].dynBal.ports[1].p = rad.vol[3].ports[1].p;
//   rad.vol[3].ports[2].h_outflow = rad.vol[3].dynBal.ports[2].h_outflow;
//   rad.vol[3].dynBal.ports[2].p = rad.vol[3].ports[2].p;
//   rad.vol[3].dynBal.hOut = rad.vol[3].hOut_internal;
//   rad.vol[2].ports[1].m_flow + rad.vol[1].ports[2].m_flow = 0.0;
//   (-rad.vol[2].ports[2].m_flow) + rad.vol[2].dynBal.ports[2].m_flow = 0.0;
//   (-rad.vol[2].ports[1].m_flow) + rad.vol[2].dynBal.ports[1].m_flow = 0.0;
//   rad.vol[2].dynBal.Q_flow = rad.vol[2].heaInp.y;
//   rad.vol[2].ports[1].h_outflow = rad.vol[2].dynBal.ports[1].h_outflow;
//   rad.vol[2].dynBal.ports[1].p = rad.vol[2].ports[1].p;
//   rad.vol[2].ports[2].h_outflow = rad.vol[2].dynBal.ports[2].h_outflow;
//   rad.vol[2].dynBal.ports[2].p = rad.vol[2].ports[2].p;
//   rad.vol[2].dynBal.hOut = rad.vol[2].hOut_internal;
//   (-rad.port_a.m_flow) + rad.vol[1].ports[1].m_flow = 0.0;
//   (-rad.vol[1].ports[2].m_flow) + rad.vol[1].dynBal.ports[2].m_flow = 0.0;
//   (-rad.vol[1].ports[1].m_flow) + rad.vol[1].dynBal.ports[1].m_flow = 0.0;
//   rad.vol[1].dynBal.Q_flow = rad.vol[1].heaInp.y;
//   rad.vol[1].ports[1].h_outflow = rad.vol[1].dynBal.ports[1].h_outflow;
//   rad.vol[1].dynBal.ports[1].p = rad.vol[1].ports[1].p;
//   rad.vol[1].ports[2].h_outflow = rad.vol[1].dynBal.ports[2].h_outflow;
//   rad.vol[1].dynBal.ports[2].p = rad.vol[1].ports[2].p;
//   rad.vol[1].dynBal.hOut = rad.vol[1].hOut_internal;
//   rad.heaCap[1].port.T = rad.preHeaFloCon[1].port.T;
//   rad.heaCap[1].port.T = rad.preHeaFloRad[1].port.T;
//   rad.heaCap[1].port.T = rad.vol[1].heatPort.T;
//   rad.heaCap[2].port.T = rad.preHeaFloCon[2].port.T;
//   rad.heaCap[2].port.T = rad.preHeaFloRad[2].port.T;
//   rad.heaCap[2].port.T = rad.vol[2].heatPort.T;
//   rad.heaCap[3].port.T = rad.preHeaFloCon[3].port.T;
//   rad.heaCap[3].port.T = rad.preHeaFloRad[3].port.T;
//   rad.heaCap[3].port.T = rad.vol[3].heatPort.T;
//   rad.heaCap[4].port.T = rad.preHeaFloCon[4].port.T;
//   rad.heaCap[4].port.T = rad.preHeaFloRad[4].port.T;
//   rad.heaCap[4].port.T = rad.vol[4].heatPort.T;
//   rad.heaCap[5].port.T = rad.preHeaFloCon[5].port.T;
//   rad.heaCap[5].port.T = rad.preHeaFloRad[5].port.T;
//   rad.heaCap[5].port.T = rad.vol[5].heatPort.T;
//   rad.port_a.h_outflow = rad.vol[1].ports[1].h_outflow;
//   rad.port_a.p = rad.vol[1].ports[1].p;
//   rad.port_b.h_outflow = rad.vol[5].ports[2].h_outflow;
//   rad.port_b.p = rad.vol[5].ports[2].p;
//   rad.vol[1].ports[2].p = rad.vol[2].ports[1].p;
//   rad.vol[2].ports[2].p = rad.vol[3].ports[1].p;
//   rad.vol[3].ports[2].p = rad.vol[4].ports[1].p;
//   rad.vol[4].ports[2].p = rad.vol[5].ports[1].p;
//   temSup.port_a.m_flow + pumRad.port_b.m_flow = 0.0;
//   pumRad.heatPort.Q_flow = 0.0;
//   (-pumRad.heatPort.Q_flow) + pumRad.prePow.port.Q_flow + pumRad.vol.heatPort.Q_flow = 0.0;
//   pumRad.vol.ports[2].m_flow + pumRad.preSou.port_a.m_flow = 0.0;
//   pumRad.vol.ports[1].m_flow + (-pumRad.port_a.m_flow) = 0.0;
//   (-pumRad.vol.ports[2].m_flow) + pumRad.vol.dynBal.ports[2].m_flow = 0.0;
//   (-pumRad.vol.ports[1].m_flow) + pumRad.vol.dynBal.ports[1].m_flow = 0.0;
//   pumRad.vol.dynBal.Q_flow = pumRad.vol.heaInp.y;
//   pumRad.vol.ports[1].h_outflow = pumRad.vol.dynBal.ports[1].h_outflow;
//   pumRad.vol.dynBal.ports[1].p = pumRad.vol.ports[1].p;
//   pumRad.vol.ports[2].h_outflow = pumRad.vol.dynBal.ports[2].h_outflow;
//   pumRad.vol.dynBal.ports[2].p = pumRad.vol.ports[2].p;
//   pumRad.vol.dynBal.hOut = pumRad.vol.hOut_internal;
//   pumRad.preSou.port_b.m_flow + (-pumRad.port_b.m_flow) = 0.0;
//   pumRad.preSou.m_flow_in = pumRad.preSou.m_flow_internal;
//   pumRad.filter.u = pumRad.m_flow_in;
//   pumRad.filter.y = pumRad.m_flow_actual;
//   pumRad.filter.y = pumRad.m_flow_filtered;
//   pumRad.filter.y = pumRad.preSou.m_flow_in;
//   pumRad.PToMedium_flow.y = pumRad.prePow.Q_flow;
//   pumRad.heatPort.T = pumRad.prePow.port.T;
//   pumRad.heatPort.T = pumRad.vol.heatPort.T;
//   pumRad.vol.ports[1].h_outflow = pumRad.port_a.h_outflow;
//   pumRad.port_a.p = pumRad.vol.ports[1].p;
//   pumRad.preSou.port_a.p = pumRad.vol.ports[2].p;
//   pumRad.preSou.port_b.h_outflow = pumRad.port_b.h_outflow;
//   pumRad.port_b.p = pumRad.preSou.port_b.p;
//   vol.dynBal.Q_flow = vol.heaInp.y;
//   vol.dynBal.mXi_flow[1] = vol.masExc[1].y;
//   vol.dynBal.hOut = vol.hOut_internal;
//   vol.XiOut_internal[1] = vol.dynBal.XiOut[1];
//   TOut.port.T = theCon.port_a.T;
//   heaCap.port.T = preHea.port.T;
//   heaCap.port.T = rad.heatPortCon.T;
//   heaCap.port.T = rad.heatPortRad.T;
//   heaCap.port.T = temRoo.port.T;
//   heaCap.port.T = theCon.port_b.T;
//   heaCap.port.T = vol.heatPort.T;
//   preHea.Q_flow = timTab.y[1];
//   rad.port_a.p = temSup.port_b.p;
//   rad.port_b.p = sin.ports[1].p;
//   pumRad.port_a.p = sou.ports[1].p;
//   pumRad.port_b.p = temSup.port_a.p;
//   hysPum.u = temRoo.T;
//   hysPum.y = not1.u;
//   booToReaRad.u = not1.y;
//   booToReaRad.y = pumRad.m_flow_in;
// end System2;
// [flattening/libraries/3rdParty/Buildings/System2.mo:4960:69-4960:82:writable] Warning: Non-array modification 'false' for array component, possibly due to missing 'each'.
// [flattening/libraries/3rdParty/Buildings/System2.mo:4961:73-4961:86:writable] Warning: Non-array modification 'false' for array component, possibly due to missing 'each'.
//
// endResult
