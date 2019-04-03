// name:     TwoRateSampler
// keywords:  sample
// status:   correct
//
// <insert description here>
//
// Drmodelica: 13.2  Sampled Systems (p. 429)
//

model TwoRateSampler
  discrete Real x,y;
  Boolean fastSample;
  Boolean slowSample;
  Integer cyCounter(start=0);          // Cyclic count 0,1,2,3,4, 0,1,2,3,4,...
 equation
  fastSample = sample(0,1);          // Define the fast clock
  when fastSample then
    cyCounter  = if pre(cyCounter) < 5 then pre(cyCounter)+1 else 0;
    slowSample = pre(cyCounter) == 0;       // Define the slow clock

  end when;
 equation
  when fastSample then              // fast sampling
    x = sin(time);
  end when;
 equation
  when slowSample then                // slow sampling (5-times slower)
    y = log(time);
  end when;
end TwoRateSampler;


// Result:
// class TwoRateSampler
//   discrete Real x;
//   discrete Real y;
//   Boolean fastSample;
//   Boolean slowSample;
//   Integer cyCounter(start = 0);
// equation
//   when slowSample then
//   y = log(time);
//   end when;
//   when fastSample then
//   x = sin(time);
//   end when;
//   fastSample = sample(0.0, 1.0);
//   when fastSample then
//   cyCounter = if pre(cyCounter) < 5 then 1 + pre(cyCounter) else 0;
//   slowSample = pre(cyCounter) == 0;
//   end when;
// end TwoRateSampler;
// endResult
