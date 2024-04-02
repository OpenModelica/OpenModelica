// name: CevalBinding9
// status: correct
// cflags: -d=newInst
//
//

pure function ext_fun
  input Real u1;
  output Real y;
  external "C";
end ext_fun;

model Pump
  parameter Real m_flow_nominal;
  parameter Integer nOri = 2;
  parameter Real V_flow = 2.0*m_flow_nominal;
  final parameter power pow = if V_flow < 0 then power(V_flow=1) else power(V_flow=2);
end Pump;

record power
  parameter Real V_flow = 0;
end power;

model CevalBinding9
  Pump pumHeaPum(m_flow_nominal = Q);
  parameter Real T = 0;
  parameter Real Q = ext_fun(T);
end CevalBinding9;

// Result:
// function ext_fun
//   input Real u1;
//   output Real y;
//
//   external "C" y = ext_fun(u1);
// end ext_fun;
//
// function power "Automatically generated record constructor for power"
//   input Real V_flow = 0.0;
//   output power res;
// end power;
//
// class CevalBinding9
//   parameter Real pumHeaPum.m_flow_nominal = Q;
//   parameter Integer pumHeaPum.nOri = 2;
//   parameter Real pumHeaPum.V_flow = 2.0 * pumHeaPum.m_flow_nominal;
//   final parameter Real pumHeaPum.pow.V_flow(fixed = false);
//   parameter Real T = 0.0;
//   parameter Real Q = ext_fun(T);
// initial equation
//   pumHeaPum.pow = if pumHeaPum.V_flow < 0.0 then power(1.0) else power(2.0);
// end CevalBinding9;
// endResult
