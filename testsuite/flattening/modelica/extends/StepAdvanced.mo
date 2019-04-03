// name:     StepAdvanced
// keywords:
// status:   correct
//



connector InPort            "Connector with input signals of type Real"
  parameter Integer n = 1        "Dimension of signal vector";
  input Real     signal[n]      "Real input signals";
end InPort;
connector OutPort            "Connector with output signals of type Real"
  parameter Integer n = 1        "Dimension of signal vector";
  output Real     signal[n]      "Real output signals";
end OutPort;              // From Modelica.Blocks.Interfaces
type Time=Real(quantity="Time",unit="s");
partial block MO             "Multiple Output continuous control block"
  parameter Integer nout = 1      "Number of outputs";
  OutPort       outPort(n = nout)  "Connector of Real output signals";
protected
  Real n[nout] = outPort.signal;
end MO;                  // From Modelica.Blocks.Interfaces

block Step                   "Generate step signals of type Real"
  parameter Real   height[:] = {1}      "Heights of steps";
  parameter Real   offset[:] = {0}      "Offset of output signals";
  parameter Time startTime[:] = {0}     "Output = offset for time < startTime";

  extends MO(final nout =   max([size(height, 1);
                size(offset, 1);
                size(startTime, 1)]) );
protected
  parameter Real p_height[nout] =
          (if size(height, 1) == 1 then
            ones(nout)*height[1]
          else
            height);
  parameter Real p_offset[nout] =
          (if size(offset, 1) == 1 then
            ones(nout)*offset[1]
          else
            offset);
  parameter Time p_startTime[nout] =
          (if size(startTime, 1) == 1 then
            ones(nout)*startTime[1]
          else
            startTime);

equation
  for i in 1:nout loop                  // A regular equation structure
    outPort.signal[i] = p_offset[i] +
              (if time < p_startTime[i] then 0 else p_height[i]);
  end for;
end Step;                        // From Modelica.Blocks.Sources


// Result:
// class Step "Generate step signals of type Real"
//   parameter Integer nout = 1 "Number of outputs";
//   parameter Integer outPort.n = nout "Dimension of signal vector";
//   output Real outPort.signal[1] "Real output signals";
//   protected Real n[1];
//   parameter Real height[1] = 1.0 "Heights of steps";
//   parameter Real offset[1] = 0.0 "Offset of output signals";
//   parameter Real startTime[1](quantity = "Time", unit = "s") = 0.0 "Output = offset for time < startTime";
//   protected parameter Real p_height[1] = height[1];
//   protected parameter Real p_offset[1] = offset[1];
//   protected parameter Real p_startTime[1](quantity = "Time", unit = "s") = startTime[1];
// equation
//   n = {outPort.signal[1]};
//   outPort.signal[1] = p_offset[1] + (if time < p_startTime[1] then 0.0 else p_height[1]);
// end Step;
// endResult
