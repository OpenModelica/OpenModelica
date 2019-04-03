// name: ConnectComplexFlow1
// keywords:
// status: correct
// cflags: -d=newInst
//

operator record Complex
  replaceable Real re;
  replaceable Real im;
end Complex;

package Modelica
  package SIunits
    type Current = Real;
    type Voltage = Real;

    operator record ComplexCurrent = Complex(
      redeclare Modelica.SIunits.Current re,
      redeclare Modelica.SIunits.Current im
    );

    operator record ComplexVoltage = Complex(
      redeclare Modelica.SIunits.Voltage re,
      redeclare Modelica.SIunits.Voltage im
    );
  end SIunits;
end Modelica;

package Internals  
  operator record ComplexVoltage =
    Modelica.SIunits.ComplexVoltage(re(nominal = 1e3), im(nominal = 1e3));
  operator record ComplexCurrent =
    Modelica.SIunits.ComplexCurrent(re(nominal = 1e3), im(nominal = 1e3));

  connector Pin 
    ComplexVoltage v;
    flow ComplexCurrent i;
  end Pin;
end Internals;

model ConnectComplexFlow1
  Internals.Pin pin;
end ConnectComplexFlow1;

// Result:
// class ConnectComplexFlow1
//   Real pin.v.re(nominal = 1000.0);
//   Real pin.v.im(nominal = 1000.0);
//   Real pin.i.re(nominal = 1000.0);
//   Real pin.i.im(nominal = 1000.0);
// equation
//   pin.i.re = 0.0;
//   pin.i.im = 0.0;
// end ConnectComplexFlow1;
// endResult
