// name: BindingArray7
// keywords:
// status: correct
// cflags: -d=newInst
//

operator record Complex
  replaceable Real re = 1;
  replaceable Real im = 2;
end Complex;

type Resistance = Real(final quantity = "Resistance");

operator record ComplexImpedance = Complex(
  redeclare Resistance re,
  redeclare Resistance im
);

model Impedance
  parameter ComplexImpedance Z;
end Impedance;

model BindingArray7  
  Impedance[3] i;
end BindingArray7;

// Result:
// class BindingArray7
//   parameter Real i[1].Z.re(quantity = "Resistance") = 1.0;
//   parameter Real i[1].Z.im(quantity = "Resistance") = 2.0;
//   parameter Real i[2].Z.re(quantity = "Resistance") = 1.0;
//   parameter Real i[2].Z.im(quantity = "Resistance") = 2.0;
//   parameter Real i[3].Z.re(quantity = "Resistance") = 1.0;
//   parameter Real i[3].Z.im(quantity = "Resistance") = 2.0;
// end BindingArray7;
// endResult
