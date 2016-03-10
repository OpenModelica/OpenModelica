model extendOverride
  parameter Real pr1 = 1.1*2/4+4;
  final parameter Real p_finalPrefix5 = 1.123456;
end extendOverride;

package p1
 package p2
  model AfunctionExtend
    extends extendOverride(pr1 = 100,p_finalPrefix5=10);
  end AfunctionExtend;
 end p2;
end p1;

package p3
 model m3
 extends p1.p2.AfunctionExtend;
 end m3;
end p3;

model test1
extends p3.m3;
end test1;

model test2
  type Angle = Real(final quantity="Angle", final unit ="rad",displayUnit="deg");
  Angle a2(displayUnit="rad"); // fine
  Angle a1(unit="deg"); // error, since unit declared as final!
equation
end test2;

model TransferFunction
parameter Real b[:] = {1} "numerator coefficient vector";
parameter Real a[:] = {1,1} "denominator coefficient vector";
end TransferFunction;

model PI "PI controller"
parameter Real k=1 "gain";
parameter Real T=1 "time constant";
TransferFunction tf(final b=k*{T,1}, final a={T,0});
end PI;

model test3
PI c1(k=2, T=3); // fine
PI c2(tf.b={33}); // error, b is declared as final
end test3;

model test4
   type Distance = Real(final unit="m");
   parameter Distance di(unit="mm")=0.125;
end test4;
