within ;
model DIDtuple

  function update
    input Real pre_y1;
    input Real[1,1] pre_y2;
    input Real u;
    input Real samplePeriod;
    output Real y1;
    output Real[1,1] y2;
  algorithm
    y1 := pre_y1 + u * samplePeriod;
    y2[1,1] := pre_y2[1,1] + pre_y1 * samplePeriod + 0.5 * u * samplePeriod^2;
  end update;

  input Real u(start = -2);
  Real[1] y1;
  Real[1,1] y2;
  parameter Real samplePeriod = 0.1;
initial equation
  pre(y1) = {1};
  pre(y2) = {{1}};
equation
  when sample(0, samplePeriod) then
    (y1[1], y2) = update(pre(y1[1]), pre(y2), u, samplePeriod);
  end when;
  annotation(experiment(StopTime=1));
end DIDtuple;
