class C Real x; end C;
record B String name; Integer age; end B;
block Mul input Real x; output Real result; equation result = x; end Mul;
type vector3D = Real[3](each start = 5, nominal = {1, 2, 3, 4, 5});
function div input Real x; output Real result; algorithm result := x; end div;
type size = enumeration(Small, Medium, Large);
model M "A class comment" parameter Integer i = 1; Real r = 4 if i > 0 "A component comment"; end M;
model ReplaceableClass replaceable model M1 end M1; end ReplaceableClass;
connector RealSignal replaceable type SignalType = Real; extends SignalType; end RealSignal;
model ProtectedClass protected model M1 end M1; end ProtectedClass;
type Resistance = Real(final quantity="Resistance",final unit="Ohm");

connector RealInput = input Real;
connector RealInput3 = flow constant input Real[3];
connector RealConnect = stream Real;

package TestPack
 function Ext
   input Real x;
   input Real y;
   input Real z;
   output Real u;
   external "C" u = externFunc(x,y,z);
 end Ext;

 function NoExt
   input Real x;
   output Real y;
 algorithm
   y := x;
 end NoExt;

model MyModel
  Modelica.Electrical.Analog.Basic.Resistor r1;
  Modelica.Electrical.Analog.Basic.Capacitor c1;
end MyModel;

end TestPack;

model M1
  Modelica.Electrical.Analog.Basic.Resistor resistor1(phi(start = 1));
end M1;

model state1
  annotation(__Dymola_state=true);
end state1;


