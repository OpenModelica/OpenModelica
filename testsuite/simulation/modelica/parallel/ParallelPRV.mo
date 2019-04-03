package TLM

connector Connector_Q
  output Real p;
  output Real q;
  input Real c;
  input Real Zc;
end Connector_Q;

connector Connector_C
  input Real p;
  input Real q;
  output Real c;
  output Real Zc;
end Connector_C;

model FlowSource
  Connector_Q source;
  parameter Real flowVal;
equation
  source.q = flowVal;
  source.p = source.c + source.q*source.Zc;
end FlowSource;

model PressureSource
  Connector_C pressure;
  parameter Real P;
equation
  pressure.c = P;
  pressure.Zc = 0;
end PressureSource;

model HydraulicAlternativePRV
  Connector_Q left;
  Connector_Q right;

  parameter Real Pref = 20e6 "Reference Opening Pressure";
  parameter Real cq = 0.67 "Flow Coefficient";
  parameter Real spooldiameter = 0.01 "Spool Diameter";
  parameter Real frac = 1.0 "Fraction of Spool Circumference that is Opening";
  parameter Real W = spooldiameter*frac;
  parameter Real pilotarea = 0.001 "Working Area of Pilot Pressure";
  parameter Real k = 1e6 "Steady State Characteristics of Spring";
  parameter Real c = 1000 "Steady State Damping Coefficient";
  parameter Real m = 0.01 "Mass";
  parameter Real xhyst = 0.0 "Hysteresis of Spool Position";
  constant Real xmax = 0.001 "Maximum Spool Position";
  constant Real xmin = 0 "Minimum Spool Position";

  parameter Real T;
  parameter Real Fs = pilotarea*Pref;

  Real Ftot = left.p*pilotarea - Fs;
  Real Ks = cq*W*x;
  Real x(start = xmin, min = xmin, max = xmax);

  Real xfrac = x*Pref/xmax;
  Real v = (x-delay(x,T))/T "better than der(xtmp) and der(x) does not have a good derivative";
  Real a = (v-delay(v,T))/T "der(a)";
  Real v2 = c*v;
  Real x2 = k*x;
  Real xtmp;
equation
  left.p = left.c + left.Zc*left.q;
  right.p = right.c + right.Zc*right.q;

  left.q  = -right.q;
  right.q = sign(left.c-right.c) * Ks * (noEvent(sqrt(abs(left.c-right.c)+((left.Zc+right.Zc)*Ks)^2/4)) - Ks*(left.Zc+right.Zc)/2);

  xtmp = (Ftot - c*v - m*a)/k;
  x = if noEvent(xtmp < xmin) then xmin else if noEvent(xtmp > xmax) then xmax else xtmp;
end HydraulicAlternativePRV;

replaceable model Volume
  parameter Real V;
  parameter Real Be;
  final parameter Real Zc = Be*T/V;
  parameter Real T;

  Connector_C left;
  Connector_C right;
equation
  left.Zc = Zc;
  right.Zc = Zc;
  left.c = if initial() then 0 else delay(right.c+2*Zc*right.q,T);
  right.c = if initial() then 0 else delay(left.c+2*Zc*left.q,T);
end Volume;

model VolumeDer
  parameter Real V;
  parameter Real Be;
  parameter Real Zc = Be*T/V;
  parameter Real T;
  parameter Real C =V/Be;

  Connector_C left(Zc = Zc);
  Connector_C right(Zc = Zc);
protected
  Real derleftp;
equation
  derleftp = (left.q+right.q)/C;
  derleftp = der(left.p);
  derleftp = der(right.p);
end VolumeDer;

model VolumeSample
  parameter Real V;
  parameter Real Be;
  parameter Real Zc = Be*T/V;
  parameter Real T = 0.01;

  Connector_C left(Zc = Zc);
  Connector_C right(Zc = Zc);
equation
  when sample(-T,T) then
    left.c = pre(right.c)+2*Zc*pre(right.q);
    right.c = pre(left.c)+2*Zc*pre(left.q);
  end when;
end VolumeSample;

model Orifice
  parameter Real K;

  Connector_Q left;
  Connector_Q right;
equation
  left.q = (right.p - left.p)*K;
  right.q = -left.q;
  left.p = left.c + left.Zc*left.q;
  right.p = right.c + right.Zc*right.q;
end Orifice;

end TLM;

model PRVSystem
  extends TLM;
  parameter Real T = 1e-4;
  // Chain of volumes + orifices to scale up the problem size
  parameter Integer problemSize = 24;
  Volume volumes[problemSize](each final V=1e-3 / problemSize, each final Be=1e9, each final T=T/problemSize);
  Orifice orifices[problemSize-1](each final K=1);
  FlowSource flowSource(flowVal = 1e-5);
  PressureSource pressureSource(P = 1e5);
  HydraulicAlternativePRV hydr(Pref=1e7,cq=0.67,spooldiameter=0.0025,frac=1.0,pilotarea=5e-5,xmax=0.015,m=0.12,c=400,k=150000,T=T);
equation
  connect(flowSource.source,volumes[1].left);
  for i in 1:(problemSize-1) loop
    connect(volumes[i].right,orifices[i].left);
    connect(orifices[i].right,volumes[i+1].left);
  end for;
  connect(volumes[problemSize].right, hydr.left);
  connect(hydr.right,pressureSource.pressure);
end PRVSystem;

model PRVSystemDer "Using der() instead of delay()"
  extends PRVSystem(redeclare model Volume = TLM.VolumeDer);
end PRVSystemDer;

model PRVSystemSample "Using sample instead of delay()"
  extends PRVSystem(redeclare model Volume = TLM.VolumeSample);
end PRVSystemSample;
