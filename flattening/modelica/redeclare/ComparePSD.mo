// name:     ComparePSD.mo [BUG: #2739]
// keywords: redeclare function
// cflags: -d=nogen
// status:   correct
//
// Checks that it's possible to uniquely modify packages in different components having the same type
//
//

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
      connector RealOutput = output Real;

      partial block SO
        extends Modelica.Blocks.Icons.Block;
        RealOutput y;
      end SO;
    end Interfaces;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial block Block  end Block;
    end Icons;
  end Blocks;

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

    partial package InterfacesPackage
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package UtilitiesPackage
      extends Modelica.Icons.Package;
    end UtilitiesPackage;

    partial package IconsPackage
      extends Modelica.Icons.Package;
    end IconsPackage;
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
    type Time = Real(final quantity = "Time", final unit = "s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Period = Real(final quantity = "Time", final unit = "s");
    type Frequency = Real(final quantity = "Frequency", final unit = "Hz");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
  end SIunits;
end Modelica;

package Noise
  extends Modelica.Icons.Package;

  model GlobalSeed
    parameter Integer userSeed = 1;
    final parameter Integer seed = userSeed;
  end GlobalSeed;

  block PRNG
    extends Modelica.Blocks.Interfaces.SO;
    outer GlobalSeed globalSeed;
    parameter Boolean useSampleBasedMethods = false;
    replaceable function SampleBasedRNG = Noise.RNG.SampleBased.RNG_LCG constrainedby Noise.Utilities.Interfaces.SampleBasedRNG;
    replaceable function SampleFreeRNG = Noise.RNG.SampleFree.RNG_DIRCS constrainedby Noise.Utilities.Interfaces.SampleFreeRNG;
  protected
    function SampleBasedRNG0 = SampleBasedRNG;
    function SampleFreeRNG0 = SampleFreeRNG;
  public
    replaceable function PDF = Noise.PDF.PDF_Uniform constrainedby Noise.Utilities.Interfaces.PDF;
  protected
    function SampleBasedPDF0 = PDF(redeclare function RNG = SampleBasedRNG0);
    function SampleFreePDF0 = PDF(redeclare function RNG = SampleFreeRNG0);
  public
    parameter Boolean infiniteFreq = false;
  protected
    parameter Modelica.SIunits.Frequency freq = 0.5 * 1 / samplePeriod;
  public
    replaceable function PSD = Noise.PSD.PSD_WhiteNoise constrainedby Noise.Utilities.Interfaces.PSD;
  protected
    function SampleBasedPSD0 = PSD(redeclare function PDF = SampleBasedPDF0);
    function SampleFreePSD0 = PSD(redeclare function PDF = SampleFreePDF0);
    function InfiniteFreqPSD0 = Noise.PSD.PSD_WhiteNoise(redeclare function PDF = SampleFreePDF0);
  public
    parameter Modelica.SIunits.Time startTime = 0;
    parameter Modelica.SIunits.Time samplePeriod = 0.01;
    parameter Boolean enable = true;
    parameter Real y_off = 0;
    replaceable function Seed = Noise.Seed.Seed_MRG(real_seed = 0.0) constrainedby Noise.Utilities.Interfaces.Seed;
  protected
    parameter Integer state_size = 33;
    Integer[state_size] state;
    Real t_last;
  public
    parameter Integer localSeed = 123456789;
    parameter Boolean useGlobalSeed = true;
    final parameter Integer seed = if useGlobalSeed then Utilities.Auxiliary.combineSeedLCG(localSeed, globalSeed.seed) else localSeed;
    final parameter Real DT = 1 / (2 * freq);
    output Real y_hold;
  protected
    discrete Real dummy1;
    discrete Real dummy2;
  initial equation
    if useSampleBasedMethods then
      pre(state) = Seed(local_seed = localSeed, global_seed = if useGlobalSeed then globalSeed.seed else 0, n = state_size, real_seed = 0.0);
      pre(t_last) = floor(time / DT) * DT;
    end if;
  equation
    if not enable then
      y = y_off;
      y_hold = y_off;
      t_last = 0;
      dummy1 = 0;
      dummy2 = 0;
      state = zeros(state_size);
    else
      if useSampleBasedMethods then
        when sample(0, DT) then
          t_last = time;
          (dummy1, dummy2, state) = SampleBasedPSD0(t = time, dt = DT, t_last = pre(t_last), states_in = pre(state));
        end when;
        (y_hold, y) = SampleBasedPSD0(t = time, dt = DT, t_last = t_last, states_in = state);
      else
        when initial() then
          dummy1 = 0;
          dummy2 = 0;
        end when;
        state = Seed(local_seed = localSeed, global_seed = if useGlobalSeed then globalSeed.seed else 0, n = state_size, real_seed = 0.0);
        t_last = noEvent(2 * abs(time) + 1);
        if infiniteFreq then
          (y_hold, y) = InfiniteFreqPSD0(t = time, dt = 0, t_last = t_last, states_in = state);
        else
          (y_hold, y) = SampleFreePSD0(t = time, dt = DT, t_last = t_last, states_in = state);
        end if;
      end if;
    end if;
  end PRNG;

  package RNG
    extends Modelica.Icons.Package;

    package SampleBased
      extends Modelica.Icons.Package;

      function RNG_MRG
        extends Noise.Utilities.Interfaces.SampleBasedRNG;
        input Integer[:] a = {1071064, 0, 0, 0, 0, 0, 2113664};
        input Integer c = 0;
        input Integer m = 1073741823;
      algorithm
        assert(size(states_in, 1) >= size(a, 1), "State must have at least as many elements as a!");
        states_out := states_in;
        states_out[1] := 0;
        for i in 1:size(a, 1) loop
          states_out[1] := states_out[1] + a[i] * states_in[i];
        end for;
        states_out[1] := integer(mod(states_out[1] + c, m));
        for i in 1:size(a, 1) - 1 loop
          states_out[i + 1] := states_in[i];
        end for;
        rand := abs(states_out[1] / (m - 1));
      end RNG_MRG;

      function RNG_LCG
        extends Noise.Utilities.Interfaces.SampleBasedRNG;
        input Integer a = 69069;
        input Integer c = 1;
        input Integer m = 1073741823;
      algorithm
        (rand, states_out) := RNG_MRG(instance, states_in, a = {a}, c = c, m = m);
      end RNG_LCG;
    end SampleBased;

    package SampleFree
      extends Modelica.Icons.Package;

      function RNG_DIRCS
        extends Noise.Utilities.Interfaces.SampleFreeRNG;
        replaceable function Seed = Noise.Seed.Seed_Real constrainedby Noise.Utilities.Interfaces.Seed;
        replaceable function RNG = Noise.RNG.SampleBased.RNG_MRG(a = {134775813, 134775813}, c = 1) constrainedby Noise.Utilities.Interfaces.RNG;
        input Integer k = 1;
      protected
        Integer[2] states_internal;
      algorithm
        states_internal := Seed(real_seed = instance, local_seed = states_in[1], global_seed = 0, n = 2);
        for i in 1:k loop
          (rand, states_internal) := RNG(instance = instance, states_in = states_internal);
        end for;
        states_out := states_in;
      end RNG_DIRCS;
    end SampleFree;
  end RNG;

  package PDF
    extends Noise.Utilities.Icons.PDFPackage;

    function PDF_Uniform
      extends Noise.Utilities.Interfaces.PDF;
      input Real[2] interval = {0, 1};
    algorithm
      (rand, states_out) := RNG(instance = instance, states_in = states_in);
      rand := rand * (interval[2] - interval[1]) + interval[1];
    end PDF_Uniform;
  end PDF;

  package PSD
    extends Noise.Utilities.Icons.PSDPackage;

    function PSD_WhiteNoise
      extends Noise.Utilities.Interfaces.PSD;
    algorithm
      if dt > 0 then
        (rand, states_out) := PDF(instance = floor(t / dt) * dt, states_in = states_in);
      else
        (rand, states_out) := PDF(instance = t, states_in = states_in);
      end if;
      rand_hold := rand;
    end PSD_WhiteNoise;

    function PSD_IdealLowPass
      extends PSD_Interpolation(redeclare function Kernel = Kernels.IdealLowPass);
    end PSD_IdealLowPass;

    function PSD_LinearInterpolation
      extends PSD_Interpolation(redeclare function Kernel = Kernels.Linear, n = 1);
    end PSD_LinearInterpolation;

    function PSD_Interpolation
      extends Noise.Utilities.Interfaces.PSD;
      replaceable function Kernel = Noise.PSD.Kernels.IdealLowPass constrainedby Utilities.Interfaces.Kernel;
      input Integer n = 5;
      input Integer max_n = n;
    protected
      Real raw;
      Real coefficient;
      Real scaling;
      Integer[size(states_in, 1)] states_temp;
    algorithm
      rand := 0;
      scaling := 0;
      states_temp := states_in;
      for i in (-max_n):(-n) loop
        (raw, states_temp) := PDF(instance = (floor(t / dt) + i) * dt, states_in = states_temp);
      end for;
      for i in (-n) + 1:n loop
        (raw, states_temp) := PDF(states_in = states_temp, instance = floor(t / dt + i) * dt);
        coefficient := if t_last <= t then Kernel(t = t - (t_last + i * dt), dt = dt) else Kernel(t = t - floor(t / dt + i) * dt, dt = dt);
        rand := rand + raw * coefficient;
        scaling := scaling + coefficient;
        if i == 0 then
          rand_hold := raw;
        else
        end if;
      end for;
      rand := rand / scaling;
      (raw, states_out) := PDF(states_in = states_in, instance = floor(t / dt) * dt);
    end PSD_Interpolation;

    package Kernels
      extends Modelica.Icons.Package;

      function IdealLowPass
        extends Noise.Utilities.Interfaces.Kernel;
        input Modelica.SIunits.Frequency B = 1 / 2 / dt;
      algorithm
        h := 2 * B * .Noise.Utilities.Math.sinc(2 * .Modelica.Constants.pi * B * t);
      end IdealLowPass;

      function Linear
        extends Noise.Utilities.Interfaces.Kernel;
      algorithm
        h := if t < (-dt) then 0 else if t < 0 then 1 + t / dt else if t < dt then 1 - t / dt else 0;
      end Linear;
    end Kernels;
  end PSD;

  package Seed
    extends Noise.Utilities.Icons.SeedPackage;

    function Seed_MRG
      extends Utilities.Interfaces.Seed;
      input Integer[:] a = fill(134775813, n);
      input Integer c = 1;
      input Integer m = 1073741823;
      input Integer k = n;
    protected
      Real dummy;
      Integer[max(n, 2)] internal_states;
    algorithm
      assert(n > 0, "You are seeding a state vector of size 0!");
      internal_states := cat(1, {local_seed, global_seed}, fill(0, max(n, 2) - 2));
      for i in 1:k loop
        (dummy, internal_states) := RNG.SampleBased.RNG_MRG(instance = real_seed, states_in = internal_states, a = a, c = c, m = m);
      end for;
      for i in 1:n loop
        states[i] := internal_states[i];
      end for;
    end Seed_MRG;

    function Seed_Real
      extends Utilities.Interfaces.Seed;
    algorithm
      states := Noise.Utilities.Auxiliary.SeedReal(local_seed = local_seed, global_seed = global_seed, real_seed = real_seed, n = n);
    end Seed_Real;
  end Seed;

  package Utilities
    extends Modelica.Icons.Package;
    extends Modelica.Icons.UtilitiesPackage;

    package Icons
      extends Modelica.Icons.IconsPackage;

      partial function PDF  end PDF;

      partial package PDFPackage
        extends Modelica.Icons.Package;
      end PDFPackage;

      partial function PSD  end PSD;

      partial package PSDPackage
        extends Modelica.Icons.Package;
      end PSDPackage;

      partial function Seed  end Seed;

      partial package SeedPackage
        extends Modelica.Icons.Package;
      end SeedPackage;
    end Icons;

    package Interfaces
      extends Modelica.Icons.InterfacesPackage;

      partial function InputOutput
        input Modelica.SIunits.Time instance;
        input Integer[:] states_in;
        output Real rand;
        output Integer[size(states_in, 1)] states_out;
      end InputOutput;

      partial function RNG
        extends Interfaces.InputOutput;
      end RNG;

      partial function SampleBasedRNG
        extends Interfaces.RNG;
      end SampleBasedRNG;

      partial function SampleFreeRNG
        extends Interfaces.RNG;
      end SampleFreeRNG;

      partial function PDF
        extends Icons.PDF;
        extends Interfaces.InputOutput;
        replaceable function RNG = Noise.RNG.SampleBased.RNG_LCG constrainedby Interfaces.RNG;
      end PDF;

      partial function PSD
        extends Icons.PSD;
        output Real rand_hold;
        extends Interfaces.InputOutput(instance = t);
        input Modelica.SIunits.Time t;
        input Modelica.SIunits.Period dt;
        input Modelica.SIunits.Time t_last;
        replaceable function PDF = Noise.PDF.PDF_Uniform constrainedby Interfaces.PDF;
      end PSD;

      partial function Kernel
        input Real t;
        input Real dt;
        output Real h;
      end Kernel;

      partial function Seed
        extends Icons.Seed;
        input Integer local_seed = 12345;
        input Integer global_seed = 67890;
        input Real real_seed = 1.234;
        input Integer n = 33;
        output Integer[n] states;
      end Seed;

      partial function combineSeed
        input Integer seed1;
        input Integer seed2;
        output Integer newSeed;
      end combineSeed;
    end Interfaces;

    package Auxiliary
      extends Modelica.Icons.Package;

      function SeedReal
        input Integer local_seed;
        input Integer global_seed;
        input Real real_seed;
        input Integer n;
        output Integer[n] states;
        external "C" NOISE_SeedReal(local_seed, global_seed, real_seed, n, states);
      end SeedReal;

      function combineSeedLCG
        extends Interfaces.combineSeed;
        external "C" newSeed = NOISE_combineSeedLCG(seed1, seed2);
      end combineSeedLCG;
    end Auxiliary;

    package Math
      extends Modelica.Icons.Package;

      function sinc
        input Real x;
        output Real y;
      algorithm
        y := if abs(x) > 0.5e-4 then sin(x) / x else 1 - x ^ 2 / 6 + x ^ 4 / 120;
      end sinc;
    end Math;
  end Utilities;
end Noise;

model ComparePSD
  extends Modelica.Icons.Example;
  .Noise.PRNG WhiteNoise(redeclare function PSD = .Noise.PSD.PSD_WhiteNoise, useSampleBasedMethods = false, redeclare function PDF = .Noise.PDF.PDF_Uniform(interval = {-1, 1}));
  .Noise.PRNG IdealLowPass(redeclare function PSD = .Noise.PSD.PSD_IdealLowPass(n = 10), useSampleBasedMethods = false, redeclare function PDF = .Noise.PDF.PDF_Uniform(interval = {-1, 1}));
  .Noise.PRNG Linear(redeclare function PSD = .Noise.PSD.PSD_LinearInterpolation(n = 5), useSampleBasedMethods = false, redeclare function PDF = .Noise.PDF.PDF_Uniform(interval = {-1, 1}));
  inner .Noise.GlobalSeed globalSeed;
end ComparePSD;

// Result:
// function Noise.PRNG$IdealLowPass.PSD.Kernel
//   input Real t;
//   input Real dt;
//   output Real h;
//   input Real B(quantity = "Frequency", unit = "Hz") = 0.5 / dt;
// algorithm
//   h := 2.0 * B * Noise.Utilities.Math.sinc(6.283185307179586 * B * t);
// end Noise.PRNG$IdealLowPass.PSD.Kernel;
//
// function Noise.PRNG$IdealLowPass.PSD.PDF
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Real[2] interval = {-1.0, 1.0};
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   (rand, states_out) := Noise.PRNG$IdealLowPass.RNG(instance, states_in, 1);
//   rand := rand * (interval[2] - interval[1]) + interval[1];
// end Noise.PRNG$IdealLowPass.PSD.PDF;
//
// function Noise.PRNG$IdealLowPass.RNG
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Integer k = 1;
//   protected Integer[2] states_internal;
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   states_internal := Noise.RNG.SampleFree.Seed(states_in[1], 0, instance, 2);
//   for i in 1:k loop
//     (rand, states_internal) := Noise.RNG.SampleFree.RNG(instance, {states_internal[1], states_internal[2]}, {134775813, 134775813}, 1, 1073741823);
//   end for;
//   states_out := states_in;
// end Noise.PRNG$IdealLowPass.RNG;
//
// function Noise.PRNG$IdealLowPass.SampleFreePDF0.RNG
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Integer k = 1;
//   protected Integer[2] states_internal;
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   states_internal := Noise.RNG.SampleFree.Seed(states_in[1], 0, instance, 2);
//   for i in 1:k loop
//     (rand, states_internal) := Noise.RNG.SampleFree.RNG(instance, {states_internal[1], states_internal[2]}, {134775813, 134775813}, 1, 1073741823);
//   end for;
//   states_out := states_in;
// end Noise.PRNG$IdealLowPass.SampleFreePDF0.RNG;
//
// function Noise.PRNG$IdealLowPass.SampleFreePSD0
//   output Real rand_hold;
//   input Real instance(quantity = "Time", unit = "s") = t;
//   input Integer[:] states_in;
//   output Real rand;
//   output Integer[size(states_in, 1)] states_out;
//   input Real t(quantity = "Time", unit = "s");
//   input Real dt(quantity = "Time", unit = "s");
//   input Real t_last(quantity = "Time", unit = "s");
//   input Integer n = 10;
//   input Integer max_n = n;
//   protected Real raw;
//   protected Real coefficient;
//   protected Real scaling;
//   protected Integer[size(states_in, 1)] states_temp;
// algorithm
//   rand := 0.0;
//   scaling := 0.0;
//   states_temp := states_in;
//   for i in (-max_n):(-n) loop
//     (raw, states_temp) := Noise.PRNG$IdealLowPass.SampleFreePSD0.PDF((floor(t / dt) + /*Real*/(i)) * dt, states_temp, {-1.0, 1.0});
//   end for;
//   for i in 1 - n:n loop
//     (raw, states_temp) := Noise.PRNG$IdealLowPass.SampleFreePSD0.PDF(floor(t / dt + /*Real*/(i)) * dt, states_temp, {-1.0, 1.0});
//     coefficient := if t_last <= t then Noise.PRNG$IdealLowPass.SampleFreePSD0.Kernel(t + (-t_last) - /*Real*/(i) * dt, dt, 0.5 / dt) else Noise.PRNG$IdealLowPass.SampleFreePSD0.Kernel(t - floor(t / dt + /*Real*/(i)) * dt, dt, 0.5 / dt);
//     rand := rand + raw * coefficient;
//     scaling := scaling + coefficient;
//     if i == 0 then
//       rand_hold := raw;
//     end if;
//   end for;
//   rand := rand / scaling;
//   (raw, states_out) := Noise.PRNG$IdealLowPass.SampleFreePSD0.PDF(floor(t / dt) * dt, states_in, {-1.0, 1.0});
// end Noise.PRNG$IdealLowPass.SampleFreePSD0;
//
// function Noise.PRNG$IdealLowPass.SampleFreePSD0.Kernel
//   input Real t;
//   input Real dt;
//   output Real h;
//   input Real B(quantity = "Frequency", unit = "Hz") = 0.5 / dt;
// algorithm
//   h := 2.0 * B * Noise.Utilities.Math.sinc(6.283185307179586 * B * t);
// end Noise.PRNG$IdealLowPass.SampleFreePSD0.Kernel;
//
// function Noise.PRNG$IdealLowPass.SampleFreePSD0.PDF
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Real[2] interval = {-1.0, 1.0};
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   (rand, states_out) := Noise.PRNG$IdealLowPass.RNG(instance, states_in, 1);
//   rand := rand * (interval[2] - interval[1]) + interval[1];
// end Noise.PRNG$IdealLowPass.SampleFreePSD0.PDF;
//
// function Noise.PRNG$IdealLowPass.Seed
//   input Integer local_seed = 12345;
//   input Integer global_seed = 67890;
//   input Real real_seed = 0.0;
//   input Integer n = 33;
//   output Integer[n] states;
//   input Integer[:] a = fill(134775813, n);
//   input Integer c = 1;
//   input Integer m = 1073741823;
//   input Integer k = n;
//   protected Real dummy;
//   protected Integer[max(n, 2)] internal_states;
// algorithm
//   assert(n > 0, "You are seeding a state vector of size 0!");
//   internal_states := cat(1, {local_seed, global_seed}, fill(0, -2 + max(n, 2)));
//   for i in 1:k loop
//     (dummy, internal_states) := Noise.RNG.SampleBased.RNG_MRG(real_seed, internal_states, a, c, m);
//   end for;
//   for i in 1:n loop
//     states[i] := internal_states[i];
//   end for;
// end Noise.PRNG$IdealLowPass.Seed;
//
// function Noise.PRNG$Linear.PSD.Kernel
//   input Real t;
//   input Real dt;
//   output Real h;
// algorithm
//   h := if t < (-dt) then 0.0 else if t < 0.0 then 1.0 + t / dt else if t < dt then 1.0 - t / dt else 0.0;
// end Noise.PRNG$Linear.PSD.Kernel;
//
// function Noise.PRNG$Linear.PSD.PDF
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Real[2] interval = {-1.0, 1.0};
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   (rand, states_out) := Noise.PRNG$Linear.RNG(instance, states_in, 1);
//   rand := rand * (interval[2] - interval[1]) + interval[1];
// end Noise.PRNG$Linear.PSD.PDF;
//
// function Noise.PRNG$Linear.RNG
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Integer k = 1;
//   protected Integer[2] states_internal;
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   states_internal := Noise.RNG.SampleFree.Seed(states_in[1], 0, instance, 2);
//   for i in 1:k loop
//     (rand, states_internal) := Noise.RNG.SampleFree.RNG(instance, {states_internal[1], states_internal[2]}, {134775813, 134775813}, 1, 1073741823);
//   end for;
//   states_out := states_in;
// end Noise.PRNG$Linear.RNG;
//
// function Noise.PRNG$Linear.SampleFreePDF0.RNG
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Integer k = 1;
//   protected Integer[2] states_internal;
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   states_internal := Noise.RNG.SampleFree.Seed(states_in[1], 0, instance, 2);
//   for i in 1:k loop
//     (rand, states_internal) := Noise.RNG.SampleFree.RNG(instance, {states_internal[1], states_internal[2]}, {134775813, 134775813}, 1, 1073741823);
//   end for;
//   states_out := states_in;
// end Noise.PRNG$Linear.SampleFreePDF0.RNG;
//
// function Noise.PRNG$Linear.SampleFreePSD0
//   output Real rand_hold;
//   input Real instance(quantity = "Time", unit = "s") = t;
//   input Integer[:] states_in;
//   output Real rand;
//   output Integer[size(states_in, 1)] states_out;
//   input Real t(quantity = "Time", unit = "s");
//   input Real dt(quantity = "Time", unit = "s");
//   input Real t_last(quantity = "Time", unit = "s");
//   input Integer n = 5;
//   input Integer max_n = n;
//   protected Real raw;
//   protected Real coefficient;
//   protected Real scaling;
//   protected Integer[size(states_in, 1)] states_temp;
// algorithm
//   rand := 0.0;
//   scaling := 0.0;
//   states_temp := states_in;
//   for i in (-max_n):(-n) loop
//     (raw, states_temp) := Noise.PRNG$Linear.SampleFreePSD0.PDF((floor(t / dt) + /*Real*/(i)) * dt, states_temp, {-1.0, 1.0});
//   end for;
//   for i in 1 - n:n loop
//     (raw, states_temp) := Noise.PRNG$Linear.SampleFreePSD0.PDF(floor(t / dt + /*Real*/(i)) * dt, states_temp, {-1.0, 1.0});
//     coefficient := if t_last <= t then Noise.PRNG$Linear.SampleFreePSD0.Kernel(t + (-t_last) - /*Real*/(i) * dt, dt) else Noise.PRNG$Linear.SampleFreePSD0.Kernel(t - floor(t / dt + /*Real*/(i)) * dt, dt);
//     rand := rand + raw * coefficient;
//     scaling := scaling + coefficient;
//     if i == 0 then
//       rand_hold := raw;
//     end if;
//   end for;
//   rand := rand / scaling;
//   (raw, states_out) := Noise.PRNG$Linear.SampleFreePSD0.PDF(floor(t / dt) * dt, states_in, {-1.0, 1.0});
// end Noise.PRNG$Linear.SampleFreePSD0;
//
// function Noise.PRNG$Linear.SampleFreePSD0.Kernel
//   input Real t;
//   input Real dt;
//   output Real h;
// algorithm
//   h := if t < (-dt) then 0.0 else if t < 0.0 then 1.0 + t / dt else if t < dt then 1.0 - t / dt else 0.0;
// end Noise.PRNG$Linear.SampleFreePSD0.Kernel;
//
// function Noise.PRNG$Linear.SampleFreePSD0.PDF
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Real[2] interval = {-1.0, 1.0};
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   (rand, states_out) := Noise.PRNG$Linear.RNG(instance, states_in, 1);
//   rand := rand * (interval[2] - interval[1]) + interval[1];
// end Noise.PRNG$Linear.SampleFreePSD0.PDF;
//
// function Noise.PRNG$Linear.Seed
//   input Integer local_seed = 12345;
//   input Integer global_seed = 67890;
//   input Real real_seed = 0.0;
//   input Integer n = 33;
//   output Integer[n] states;
//   input Integer[:] a = fill(134775813, n);
//   input Integer c = 1;
//   input Integer m = 1073741823;
//   input Integer k = n;
//   protected Real dummy;
//   protected Integer[max(n, 2)] internal_states;
// algorithm
//   assert(n > 0, "You are seeding a state vector of size 0!");
//   internal_states := cat(1, {local_seed, global_seed}, fill(0, -2 + max(n, 2)));
//   for i in 1:k loop
//     (dummy, internal_states) := Noise.RNG.SampleBased.RNG_MRG(real_seed, internal_states, a, c, m);
//   end for;
//   for i in 1:n loop
//     states[i] := internal_states[i];
//   end for;
// end Noise.PRNG$Linear.Seed;
//
// function Noise.PRNG$WhiteNoise.PSD.PDF
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Real[2] interval = {-1.0, 1.0};
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   (rand, states_out) := Noise.PRNG$WhiteNoise.RNG(instance, states_in, 1);
//   rand := rand * (interval[2] - interval[1]) + interval[1];
// end Noise.PRNG$WhiteNoise.PSD.PDF;
//
// function Noise.PRNG$WhiteNoise.RNG
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Integer k = 1;
//   protected Integer[2] states_internal;
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   states_internal := Noise.RNG.SampleFree.Seed(states_in[1], 0, instance, 2);
//   for i in 1:k loop
//     (rand, states_internal) := Noise.RNG.SampleFree.RNG(instance, {states_internal[1], states_internal[2]}, {134775813, 134775813}, 1, 1073741823);
//   end for;
//   states_out := states_in;
// end Noise.PRNG$WhiteNoise.RNG;
//
// function Noise.PRNG$WhiteNoise.SampleFreePDF0.RNG
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Integer k = 1;
//   protected Integer[2] states_internal;
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   states_internal := Noise.RNG.SampleFree.Seed(states_in[1], 0, instance, 2);
//   for i in 1:k loop
//     (rand, states_internal) := Noise.RNG.SampleFree.RNG(instance, {states_internal[1], states_internal[2]}, {134775813, 134775813}, 1, 1073741823);
//   end for;
//   states_out := states_in;
// end Noise.PRNG$WhiteNoise.SampleFreePDF0.RNG;
//
// function Noise.PRNG$WhiteNoise.SampleFreePSD0
//   output Real rand_hold;
//   input Real instance(quantity = "Time", unit = "s") = t;
//   input Integer[:] states_in;
//   output Real rand;
//   output Integer[size(states_in, 1)] states_out;
//   input Real t(quantity = "Time", unit = "s");
//   input Real dt(quantity = "Time", unit = "s");
//   input Real t_last(quantity = "Time", unit = "s");
// algorithm
//   if dt > 0.0 then
//     (rand, states_out) := Noise.PRNG$WhiteNoise.SampleFreePSD0.PDF(floor(t / dt) * dt, states_in, {-1.0, 1.0});
//   else
//     (rand, states_out) := Noise.PRNG$WhiteNoise.SampleFreePSD0.PDF(t, states_in, {-1.0, 1.0});
//   end if;
//   rand_hold := rand;
// end Noise.PRNG$WhiteNoise.SampleFreePSD0;
//
// function Noise.PRNG$WhiteNoise.SampleFreePSD0.PDF
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   input Real[2] interval = {-1.0, 1.0};
//   output Integer[size(states_in, 1)] states_out;
// algorithm
//   (rand, states_out) := Noise.PRNG$WhiteNoise.RNG(instance, states_in, 1);
//   rand := rand * (interval[2] - interval[1]) + interval[1];
// end Noise.PRNG$WhiteNoise.SampleFreePSD0.PDF;
//
// function Noise.PRNG$WhiteNoise.Seed
//   input Integer local_seed = 12345;
//   input Integer global_seed = 67890;
//   input Real real_seed = 0.0;
//   input Integer n = 33;
//   output Integer[n] states;
//   input Integer[:] a = fill(134775813, n);
//   input Integer c = 1;
//   input Integer m = 1073741823;
//   input Integer k = n;
//   protected Real dummy;
//   protected Integer[max(n, 2)] internal_states;
// algorithm
//   assert(n > 0, "You are seeding a state vector of size 0!");
//   internal_states := cat(1, {local_seed, global_seed}, fill(0, -2 + max(n, 2)));
//   for i in 1:k loop
//     (dummy, internal_states) := Noise.RNG.SampleBased.RNG_MRG(real_seed, internal_states, a, c, m);
//   end for;
//   for i in 1:n loop
//     states[i] := internal_states[i];
//   end for;
// end Noise.PRNG$WhiteNoise.Seed;
//
// function Noise.RNG.SampleBased.RNG_MRG
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   output Integer[size(states_in, 1)] states_out;
//   input Integer[:] a = {1071064, 0, 0, 0, 0, 0, 2113664};
//   input Integer c = 0;
//   input Integer m = 1073741823;
// algorithm
//   assert(size(states_in, 1) >= size(a, 1), "State must have at least as many elements as a!");
//   states_out := states_in;
//   states_out[1] := 0;
//   for i in 1:size(a, 1) loop
//     states_out[1] := states_out[1] + a[i] * states_in[i];
//   end for;
//   states_out[1] := integer(/*Real*/(mod(states_out[1] + c, m)));
//   for i in 1:-1 + size(a, 1) loop
//     states_out[1 + i] := states_in[i];
//   end for;
//   rand := abs(/*Real*/(states_out[1]) / /*Real*/(-1 + m));
// end Noise.RNG.SampleBased.RNG_MRG;
//
// function Noise.RNG.SampleFree.RNG
//   input Real instance(quantity = "Time", unit = "s");
//   input Integer[:] states_in;
//   output Real rand;
//   output Integer[size(states_in, 1)] states_out;
//   input Integer[:] a = {134775813, 134775813};
//   input Integer c = 1;
//   input Integer m = 1073741823;
// algorithm
//   assert(size(states_in, 1) >= size(a, 1), "State must have at least as many elements as a!");
//   states_out := states_in;
//   states_out[1] := 0;
//   for i in 1:size(a, 1) loop
//     states_out[1] := states_out[1] + a[i] * states_in[i];
//   end for;
//   states_out[1] := integer(/*Real*/(mod(states_out[1] + c, m)));
//   for i in 1:-1 + size(a, 1) loop
//     states_out[1 + i] := states_in[i];
//   end for;
//   rand := abs(/*Real*/(states_out[1]) / /*Real*/(-1 + m));
// end Noise.RNG.SampleFree.RNG;
//
// function Noise.RNG.SampleFree.Seed
//   input Integer local_seed = 12345;
//   input Integer global_seed = 67890;
//   input Real real_seed = 1.234;
//   input Integer n = 33;
//   output Integer[n] states;
// algorithm
//   states := Noise.Utilities.Auxiliary.SeedReal(local_seed, global_seed, real_seed, n);
// end Noise.RNG.SampleFree.Seed;
//
// function Noise.Utilities.Auxiliary.SeedReal
//   input Integer local_seed;
//   input Integer global_seed;
//   input Real real_seed;
//   input Integer n;
//   output Integer[n] states;
//
//   external "C" NOISE_SeedReal(local_seed, global_seed, real_seed, n, states);
// end Noise.Utilities.Auxiliary.SeedReal;
//
// function Noise.Utilities.Auxiliary.combineSeedLCG
//   input Integer seed1;
//   input Integer seed2;
//   output Integer newSeed;
//
//   external "C" newSeed = NOISE_combineSeedLCG(seed1, seed2);
// end Noise.Utilities.Auxiliary.combineSeedLCG;
//
// function Noise.Utilities.Math.sinc
//   input Real x;
//   output Real y;
// algorithm
//   y := if abs(x) > 5e-05 then sin(x) / x else 1.0 + (-0.1666666666666667) * x ^ 2.0 + 0.008333333333333333 * x ^ 4.0;
// end Noise.Utilities.Math.sinc;
//
// class ComparePSD
//   Real WhiteNoise.y;
//   parameter Boolean WhiteNoise.useSampleBasedMethods = false;
//   parameter Boolean WhiteNoise.infiniteFreq = false;
//   protected parameter Real WhiteNoise.freq(quantity = "Frequency", unit = "Hz") = 0.5 / WhiteNoise.samplePeriod;
//   parameter Real WhiteNoise.startTime(quantity = "Time", unit = "s") = 0.0;
//   parameter Real WhiteNoise.samplePeriod(quantity = "Time", unit = "s") = 0.01;
//   parameter Boolean WhiteNoise.enable = true;
//   parameter Real WhiteNoise.y_off = 0.0;
//   protected parameter Integer WhiteNoise.state_size = 33;
//   protected Integer WhiteNoise.state[1];
//   protected Integer WhiteNoise.state[2];
//   protected Integer WhiteNoise.state[3];
//   protected Integer WhiteNoise.state[4];
//   protected Integer WhiteNoise.state[5];
//   protected Integer WhiteNoise.state[6];
//   protected Integer WhiteNoise.state[7];
//   protected Integer WhiteNoise.state[8];
//   protected Integer WhiteNoise.state[9];
//   protected Integer WhiteNoise.state[10];
//   protected Integer WhiteNoise.state[11];
//   protected Integer WhiteNoise.state[12];
//   protected Integer WhiteNoise.state[13];
//   protected Integer WhiteNoise.state[14];
//   protected Integer WhiteNoise.state[15];
//   protected Integer WhiteNoise.state[16];
//   protected Integer WhiteNoise.state[17];
//   protected Integer WhiteNoise.state[18];
//   protected Integer WhiteNoise.state[19];
//   protected Integer WhiteNoise.state[20];
//   protected Integer WhiteNoise.state[21];
//   protected Integer WhiteNoise.state[22];
//   protected Integer WhiteNoise.state[23];
//   protected Integer WhiteNoise.state[24];
//   protected Integer WhiteNoise.state[25];
//   protected Integer WhiteNoise.state[26];
//   protected Integer WhiteNoise.state[27];
//   protected Integer WhiteNoise.state[28];
//   protected Integer WhiteNoise.state[29];
//   protected Integer WhiteNoise.state[30];
//   protected Integer WhiteNoise.state[31];
//   protected Integer WhiteNoise.state[32];
//   protected Integer WhiteNoise.state[33];
//   protected Real WhiteNoise.t_last;
//   parameter Integer WhiteNoise.localSeed = 123456789;
//   parameter Boolean WhiteNoise.useGlobalSeed = true;
//   final parameter Integer WhiteNoise.seed = if WhiteNoise.useGlobalSeed then Noise.Utilities.Auxiliary.combineSeedLCG(WhiteNoise.localSeed, globalSeed.seed) else WhiteNoise.localSeed;
//   final parameter Real WhiteNoise.DT = 0.5 / WhiteNoise.freq;
//   Real WhiteNoise.y_hold;
//   protected discrete Real WhiteNoise.dummy1;
//   protected discrete Real WhiteNoise.dummy2;
//   Real IdealLowPass.y;
//   parameter Boolean IdealLowPass.useSampleBasedMethods = false;
//   parameter Boolean IdealLowPass.infiniteFreq = false;
//   protected parameter Real IdealLowPass.freq(quantity = "Frequency", unit = "Hz") = 0.5 / IdealLowPass.samplePeriod;
//   parameter Real IdealLowPass.startTime(quantity = "Time", unit = "s") = 0.0;
//   parameter Real IdealLowPass.samplePeriod(quantity = "Time", unit = "s") = 0.01;
//   parameter Boolean IdealLowPass.enable = true;
//   parameter Real IdealLowPass.y_off = 0.0;
//   protected parameter Integer IdealLowPass.state_size = 33;
//   protected Integer IdealLowPass.state[1];
//   protected Integer IdealLowPass.state[2];
//   protected Integer IdealLowPass.state[3];
//   protected Integer IdealLowPass.state[4];
//   protected Integer IdealLowPass.state[5];
//   protected Integer IdealLowPass.state[6];
//   protected Integer IdealLowPass.state[7];
//   protected Integer IdealLowPass.state[8];
//   protected Integer IdealLowPass.state[9];
//   protected Integer IdealLowPass.state[10];
//   protected Integer IdealLowPass.state[11];
//   protected Integer IdealLowPass.state[12];
//   protected Integer IdealLowPass.state[13];
//   protected Integer IdealLowPass.state[14];
//   protected Integer IdealLowPass.state[15];
//   protected Integer IdealLowPass.state[16];
//   protected Integer IdealLowPass.state[17];
//   protected Integer IdealLowPass.state[18];
//   protected Integer IdealLowPass.state[19];
//   protected Integer IdealLowPass.state[20];
//   protected Integer IdealLowPass.state[21];
//   protected Integer IdealLowPass.state[22];
//   protected Integer IdealLowPass.state[23];
//   protected Integer IdealLowPass.state[24];
//   protected Integer IdealLowPass.state[25];
//   protected Integer IdealLowPass.state[26];
//   protected Integer IdealLowPass.state[27];
//   protected Integer IdealLowPass.state[28];
//   protected Integer IdealLowPass.state[29];
//   protected Integer IdealLowPass.state[30];
//   protected Integer IdealLowPass.state[31];
//   protected Integer IdealLowPass.state[32];
//   protected Integer IdealLowPass.state[33];
//   protected Real IdealLowPass.t_last;
//   parameter Integer IdealLowPass.localSeed = 123456789;
//   parameter Boolean IdealLowPass.useGlobalSeed = true;
//   final parameter Integer IdealLowPass.seed = if IdealLowPass.useGlobalSeed then Noise.Utilities.Auxiliary.combineSeedLCG(IdealLowPass.localSeed, globalSeed.seed) else IdealLowPass.localSeed;
//   final parameter Real IdealLowPass.DT = 0.5 / IdealLowPass.freq;
//   Real IdealLowPass.y_hold;
//   protected discrete Real IdealLowPass.dummy1;
//   protected discrete Real IdealLowPass.dummy2;
//   Real Linear.y;
//   parameter Boolean Linear.useSampleBasedMethods = false;
//   parameter Boolean Linear.infiniteFreq = false;
//   protected parameter Real Linear.freq(quantity = "Frequency", unit = "Hz") = 0.5 / Linear.samplePeriod;
//   parameter Real Linear.startTime(quantity = "Time", unit = "s") = 0.0;
//   parameter Real Linear.samplePeriod(quantity = "Time", unit = "s") = 0.01;
//   parameter Boolean Linear.enable = true;
//   parameter Real Linear.y_off = 0.0;
//   protected parameter Integer Linear.state_size = 33;
//   protected Integer Linear.state[1];
//   protected Integer Linear.state[2];
//   protected Integer Linear.state[3];
//   protected Integer Linear.state[4];
//   protected Integer Linear.state[5];
//   protected Integer Linear.state[6];
//   protected Integer Linear.state[7];
//   protected Integer Linear.state[8];
//   protected Integer Linear.state[9];
//   protected Integer Linear.state[10];
//   protected Integer Linear.state[11];
//   protected Integer Linear.state[12];
//   protected Integer Linear.state[13];
//   protected Integer Linear.state[14];
//   protected Integer Linear.state[15];
//   protected Integer Linear.state[16];
//   protected Integer Linear.state[17];
//   protected Integer Linear.state[18];
//   protected Integer Linear.state[19];
//   protected Integer Linear.state[20];
//   protected Integer Linear.state[21];
//   protected Integer Linear.state[22];
//   protected Integer Linear.state[23];
//   protected Integer Linear.state[24];
//   protected Integer Linear.state[25];
//   protected Integer Linear.state[26];
//   protected Integer Linear.state[27];
//   protected Integer Linear.state[28];
//   protected Integer Linear.state[29];
//   protected Integer Linear.state[30];
//   protected Integer Linear.state[31];
//   protected Integer Linear.state[32];
//   protected Integer Linear.state[33];
//   protected Real Linear.t_last;
//   parameter Integer Linear.localSeed = 123456789;
//   parameter Boolean Linear.useGlobalSeed = true;
//   final parameter Integer Linear.seed = if Linear.useGlobalSeed then Noise.Utilities.Auxiliary.combineSeedLCG(Linear.localSeed, globalSeed.seed) else Linear.localSeed;
//   final parameter Real Linear.DT = 0.5 / Linear.freq;
//   Real Linear.y_hold;
//   protected discrete Real Linear.dummy1;
//   protected discrete Real Linear.dummy2;
//   parameter Integer globalSeed.userSeed = 1;
//   final parameter Integer globalSeed.seed = globalSeed.userSeed;
// equation
//   when initial() then
//     WhiteNoise.dummy1 = 0.0;
//     WhiteNoise.dummy2 = 0.0;
//   end when;
//   WhiteNoise.state = Noise.PRNG$WhiteNoise.Seed(WhiteNoise.localSeed, if WhiteNoise.useGlobalSeed then globalSeed.seed else 0, 0.0, 33, {134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813}, 1, 1073741823, 33);
//   WhiteNoise.t_last = 1.0 + 2.0 * abs(time);
//   (WhiteNoise.y_hold, WhiteNoise.y, _) = Noise.PRNG$WhiteNoise.SampleFreePSD0(time, {WhiteNoise.state[1], WhiteNoise.state[2], WhiteNoise.state[3], WhiteNoise.state[4], WhiteNoise.state[5], WhiteNoise.state[6], WhiteNoise.state[7], WhiteNoise.state[8], WhiteNoise.state[9], WhiteNoise.state[10], WhiteNoise.state[11], WhiteNoise.state[12], WhiteNoise.state[13], WhiteNoise.state[14], WhiteNoise.state[15], WhiteNoise.state[16], WhiteNoise.state[17], WhiteNoise.state[18], WhiteNoise.state[19], WhiteNoise.state[20], WhiteNoise.state[21], WhiteNoise.state[22], WhiteNoise.state[23], WhiteNoise.state[24], WhiteNoise.state[25], WhiteNoise.state[26], WhiteNoise.state[27], WhiteNoise.state[28], WhiteNoise.state[29], WhiteNoise.state[30], WhiteNoise.state[31], WhiteNoise.state[32], WhiteNoise.state[33]}, time, WhiteNoise.DT, WhiteNoise.t_last);
//   when initial() then
//     IdealLowPass.dummy1 = 0.0;
//     IdealLowPass.dummy2 = 0.0;
//   end when;
//   IdealLowPass.state = Noise.PRNG$IdealLowPass.Seed(IdealLowPass.localSeed, if IdealLowPass.useGlobalSeed then globalSeed.seed else 0, 0.0, 33, {134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813}, 1, 1073741823, 33);
//   IdealLowPass.t_last = 1.0 + 2.0 * abs(time);
//   (IdealLowPass.y_hold, IdealLowPass.y, _) = Noise.PRNG$IdealLowPass.SampleFreePSD0(time, {IdealLowPass.state[1], IdealLowPass.state[2], IdealLowPass.state[3], IdealLowPass.state[4], IdealLowPass.state[5], IdealLowPass.state[6], IdealLowPass.state[7], IdealLowPass.state[8], IdealLowPass.state[9], IdealLowPass.state[10], IdealLowPass.state[11], IdealLowPass.state[12], IdealLowPass.state[13], IdealLowPass.state[14], IdealLowPass.state[15], IdealLowPass.state[16], IdealLowPass.state[17], IdealLowPass.state[18], IdealLowPass.state[19], IdealLowPass.state[20], IdealLowPass.state[21], IdealLowPass.state[22], IdealLowPass.state[23], IdealLowPass.state[24], IdealLowPass.state[25], IdealLowPass.state[26], IdealLowPass.state[27], IdealLowPass.state[28], IdealLowPass.state[29], IdealLowPass.state[30], IdealLowPass.state[31], IdealLowPass.state[32], IdealLowPass.state[33]}, time, IdealLowPass.DT, IdealLowPass.t_last, 10, 10);
//   when initial() then
//     Linear.dummy1 = 0.0;
//     Linear.dummy2 = 0.0;
//   end when;
//   Linear.state = Noise.PRNG$Linear.Seed(Linear.localSeed, if Linear.useGlobalSeed then globalSeed.seed else 0, 0.0, 33, {134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813, 134775813}, 1, 1073741823, 33);
//   Linear.t_last = 1.0 + 2.0 * abs(time);
//   (Linear.y_hold, Linear.y, _) = Noise.PRNG$Linear.SampleFreePSD0(time, {Linear.state[1], Linear.state[2], Linear.state[3], Linear.state[4], Linear.state[5], Linear.state[6], Linear.state[7], Linear.state[8], Linear.state[9], Linear.state[10], Linear.state[11], Linear.state[12], Linear.state[13], Linear.state[14], Linear.state[15], Linear.state[16], Linear.state[17], Linear.state[18], Linear.state[19], Linear.state[20], Linear.state[21], Linear.state[22], Linear.state[23], Linear.state[24], Linear.state[25], Linear.state[26], Linear.state[27], Linear.state[28], Linear.state[29], Linear.state[30], Linear.state[31], Linear.state[32], Linear.state[33]}, time, Linear.DT, Linear.t_last, 5, 5);
// end ComparePSD;
// endResult
