model IdealSwitchStiff
  extends Modelica.Electrical.Analog.Interfaces.OnePort;
  Boolean off(start=false);
  parameter Real t0=5;
  Real sign_i(start=0);
  parameter Real Roff(final min=0) = 1.0e-5;
  parameter Real Gon(final min=0) = 1.0e-5;
protected
  Real s;
equation
  when (time>t0) then
    sign_i = if (i>0) then 1 else -1;
  end when;
  when (time>t0 and sign_i*i<0) then
    off = true;
  end when;
  v = s*(if off then 1 else Roff);
  i = s*(if off then Gon else 1);
end IdealSwitchStiff;
