// name:     ComparePSD.mo [BUG: #2739]
// keywords: redeclare function
// status:   correct
//
// Checks that it's possible to uniquely modify packages in different components having the same type
// Reduced from the Noise library: each PRNG redeclares PSD with its own
// modifier, and PSD0 derived from it must use that component's defaults.
//

package Noise
  partial function PDFInterface
    input Real t;
    output Real y;
  end PDFInterface;

  function Uniform
    extends PDFInterface;
    input Real interval[2] = {0, 1};
  algorithm
    y := interval[1] + t * (interval[2] - interval[1]);
  end Uniform;

  partial function PSDInterface
    input Real t;
    output Real y;
    replaceable function PDF = Uniform constrainedby PDFInterface;
  end PSDInterface;

  function WhiteNoise
    extends PSDInterface;
  algorithm
    y := PDF(t);
  end WhiteNoise;

  function Interpolation
    extends PSDInterface;
    input Integer n = 5;
    input Integer max_n = n;
  algorithm
    y := 0;
    for i in -max_n:n loop
      y := y + PDF(t + i);
    end for;
  end Interpolation;

  function LinearInterpolation
    extends Interpolation(n = 1);
  end LinearInterpolation;

  block PRNG
    output Real y;
    replaceable function PDF = Uniform constrainedby PDFInterface;
    replaceable function PSD = WhiteNoise constrainedby PSDInterface;
  protected
    function PDF0 = PDF;
    function PSD0 = PSD(redeclare function PDF = PDF0);
  equation
    y = PSD0(time);
  end PRNG;
end Noise;

model ComparePSD
  Noise.PRNG WhiteNoise(redeclare function PSD = Noise.WhiteNoise, redeclare function PDF = Noise.Uniform(interval = {-1, 1}));
  Noise.PRNG IdealLowPass(redeclare function PSD = Noise.Interpolation(n = 10), redeclare function PDF = Noise.Uniform(interval = {-1, 1}));
  Noise.PRNG Linear(redeclare function PSD = Noise.LinearInterpolation(n = 5), redeclare function PDF = Noise.Uniform(interval = {-1, 1}));
  annotation(__OpenModelica_commandLineOptions="-d=nogen");
end ComparePSD;

// Result:
// function ComparePSD.IdealLowPass.PSD0
//   input Real t;
//   input Integer n = 10;
//   input Integer max_n = n;
//   output Real y;
// algorithm
//   y := 0.0;
//   for i in (-max_n):n loop
//     y := y + ComparePSD.IdealLowPass.PSD0.PDF(t + /*Real*/(i), {-1.0, 1.0});
//   end for;
// end ComparePSD.IdealLowPass.PSD0;
//
// function ComparePSD.IdealLowPass.PSD0.PDF
//   input Real t;
//   input Real[2] interval = {-1.0, 1.0};
//   output Real y;
// algorithm
//   y := interval[1] + t * (interval[2] - interval[1]);
// end ComparePSD.IdealLowPass.PSD0.PDF;
//
// function ComparePSD.Linear.PSD0
//   input Real t;
//   input Integer n = 5;
//   input Integer max_n = n;
//   output Real y;
// algorithm
//   y := 0.0;
//   for i in (-max_n):n loop
//     y := y + ComparePSD.Linear.PSD0.PDF(t + /*Real*/(i), {-1.0, 1.0});
//   end for;
// end ComparePSD.Linear.PSD0;
//
// function ComparePSD.Linear.PSD0.PDF
//   input Real t;
//   input Real[2] interval = {-1.0, 1.0};
//   output Real y;
// algorithm
//   y := interval[1] + t * (interval[2] - interval[1]);
// end ComparePSD.Linear.PSD0.PDF;
//
// function ComparePSD.WhiteNoise.PSD0
//   input Real t;
//   output Real y;
// algorithm
//   y := ComparePSD.WhiteNoise.PSD0.PDF(t, {-1.0, 1.0});
// end ComparePSD.WhiteNoise.PSD0;
//
// function ComparePSD.WhiteNoise.PSD0.PDF
//   input Real t;
//   input Real[2] interval = {-1.0, 1.0};
//   output Real y;
// algorithm
//   y := interval[1] + t * (interval[2] - interval[1]);
// end ComparePSD.WhiteNoise.PSD0.PDF;
//
// class ComparePSD
//   Real WhiteNoise.y;
//   Real IdealLowPass.y;
//   Real Linear.y;
// equation
//   WhiteNoise.y = ComparePSD.WhiteNoise.PSD0(time);
//   IdealLowPass.y = ComparePSD.IdealLowPass.PSD0(time, 10, 10);
//   Linear.y = ComparePSD.Linear.PSD0(time, 5, 5);
// end ComparePSD;
// endResult
