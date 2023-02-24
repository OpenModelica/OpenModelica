package P
  connector C
    Real e;
    flow Real f;
  end C;

  model A
    C c1, c2;
  equation
    connect(c1, c2);
  end A;

  model M
    extends A;

    C c3;
  equation
    connect(c1, c3) annotation(Line(points = {{-25, 30}, {10, 30}, {10, -20}, {40, -20}}));

  annotation (
    Icon(graphics={Rectangle(extent={{-66,78},{70,-56}}, lineColor={28,108,200})}),
    Diagram(graphics={Ellipse(extent={{-62,68},{56,-60}}, lineColor={28,108,200})}));
  end M;
end P;