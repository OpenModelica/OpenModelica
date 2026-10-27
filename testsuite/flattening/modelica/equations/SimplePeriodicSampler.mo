// name:     SimplePeriodicSampler
// keywords: sample
// status:   correct
//
// <insert description here>
//
// Drmodelica: 13.2  Sampled Systems (p. 429)
//
model Sampler
  parameter Real sample_interval = 0.1        "Sample period";
  Real x(start=5);
  Real y;
equation
  der(x) = -x;
  when sample(0, sample_interval) then
    y = x;
  end when;
end Sampler;


// Result:
// class Sampler
//   parameter Real sample_interval = 0.1 "Sample period";
//   Real x(start = 5.0);
//   Real y;
// equation
//   der(x) = -x;
//   when sample(0.0, sample_interval) then
//   y = x;
//   end when;
// end Sampler;
// endResult
