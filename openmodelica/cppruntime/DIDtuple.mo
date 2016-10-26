within ;
model DIDtuple

  function update
    input Real pre_y1;
    input Real pre_y2;
    input Real u;
    input Real samplePeriod;
    output Real y1;
    output Real y2;
  algorithm
    y1 := pre_y1 + u * samplePeriod;
    y2 := pre_y2 + pre_y1 * samplePeriod + 0.5 * u * samplePeriod^2;
  end update;

  input Real u(start = -2);
  Real y1(start = 1), y2(start = 0);
  parameter Real samplePeriod = 0.1;
equation
  when sample(0, samplePeriod) then
    (y1, y2) = update(pre(y1), pre(y2), u, samplePeriod);
  end when;
  annotation(experiment(StopTime=1), uses(Modelica(version="3.2.1")));
end DIDtuple;
