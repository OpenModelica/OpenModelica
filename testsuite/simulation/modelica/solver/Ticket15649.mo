
package Ticket15649

  model LotkaVolterra
    Real y1(start=2, fixed=true);
    Real y2(start=3, fixed=true);
    parameter Real p1=0.05;
    parameter Real p2=1.4;
  equation
    der(y1) = p1 * y1 - y2;
    der(y2) = -p2 * y2;
  end LotkaVolterra;

end Ticket15649;
