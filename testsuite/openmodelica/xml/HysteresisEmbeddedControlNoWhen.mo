model HysteresisEmbeddedControlNoWhen "A control strategy that uses embedded C code"

  function computeHeat "Modelica wrapper for an embedded C controller"
    input Real T;
    input Real Tbar;
    input Real Q;
    output Real heat;

    external "C"  annotation(Include = "
#ifndef _COMPUTE_HEAT_C_
#define _COMPUTE_HEAT_C_

#define UNINITIALIZED -1
#define ON 1
#define OFF 0

double
computeHeat(double T, double Tbar, double Q) {
  static int state = UNINITIALIZED;
  if (state == UNINITIALIZED) {
    if (T>Tbar) state = OFF;
    else state = ON;
  }
  if (state == OFF && T<Tbar - 2) state = ON;
  if (state == ON && T>Tbar + 2) state = OFF;

  if (state == ON) return Q;
  else return 0;
}

#endif
");
  end computeHeat;

  type HeatCapacitance = Real(unit = "J/K");
  type Temperature = Real(unit = "K");
  type Heat = Real(unit = "W");
  type Mass = Real(unit = "kg");
  type HeatTransferCoefficient = Real(unit = "W/K");
  parameter HeatCapacitance C = 1.0;
  parameter HeatTransferCoefficient h = 2.0;
  parameter Heat Qcapacity = 25.0;
  parameter Temperature Tamb = 285;
  parameter Temperature Tbar = 295;
  Temperature T (start = 390);
  Heat Q;
equation
  Q = computeHeat(T, Tbar, Qcapacity);
  C * der(T) = Q - h * (T - Tamb);
end HysteresisEmbeddedControlNoWhen;
