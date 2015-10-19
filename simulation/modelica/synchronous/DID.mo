model DID "Double Integrator Discrete-time"
  parameter Real p = 1 "gain for input";
  parameter Real y1_start = 1 "start value for first state";
  parameter Real y2_start = 0 "start value for second state";
  parameter Real dt = 0.1 "sample time";
  input Real u(start = -2);
  output Real y1, y2;
  Boolean first(start=true) "Used to identify the first clock tick";
equation
  when Clock(dt) then
    first = false;
    y1 = if previous(first) then y1_start else previous(y1) + p * u * dt;
    y2 = if previous(first) then y2_start else previous(y2) + previous(y1)*dt + 0.5 * u * dt*dt;
  end when;
end DID;
