model TestExtFFT "external C with a protected work array, array outputs and several outputs"
  parameter Real u[6] = {0.0, 0.1, 0.2, 0.4, 0.5, 0.6};
  Integer info;
  Real amplitudes[4];
  Real phases[4];
  Real x(start = 0, fixed = true);
equation
  (info, amplitudes, phases) = Modelica.Math.FastFourierTransform.Internal.rawRealFFT(u);
  der(x) = amplitudes[2];
end TestExtFFT;
