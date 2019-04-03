within ;
model Maraninchi2003_2 "Example motivated by Figure 2 of 'Maraninchi, F. & Rémond, Y. Mode-Automata: a new domain-specific construct for the development of safe critical systems, Science of Computer Programming, 2003, 46, 219-254'"
  inner Integer x(start=0);
  inner Integer z(start=0);
  inner Integer y(start=0);
  constant Boolean i = true;
  constant Boolean j = false;
  model A
    outer output Integer x;
    inner outer output Integer y;
    inner outer output Integer z;
    C c annotation (Placement(transformation(extent={{-78,12},{-8,42}})));
    D d annotation (Placement(transformation(extent={{8,10},{80,42}})));
    E e annotation (Placement(transformation(extent={{-68,-78},{-8,-44}})));
    F f annotation (Placement(transformation(extent={{16,-78},{78,-44}})));
    model C
      outer output Integer y;
    equation
      y = previous(y)+1;
      annotation (
        Icon(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%name")}),
        Diagram(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%stateText",
              fontSize=10)}),
        __Dymola_state=true,
        showDiagram=true,
        singleInstance=true);
    end C;
  equation
    initialState(c) annotation (Line(
        points={{-80,30},{-96,30}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier,
        arrow={Arrow.Filled,Arrow.None}));
  public
    model D
      outer output Integer y;
    equation
      y = previous(y) - 1;
      annotation (
        Icon(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%name")}),
        Diagram(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%stateText",
              fontSize=10)}),
        __Dymola_state=true,
        showDiagram=true,
        singleInstance=true);
    end D;
  equation
    transition(
        c,
        d,y == 10,
        immediate=false,reset=true,synchronize=false,priority=1)
                         annotation (Line(
        points={{-22,44},{-6,48},{22.4,44}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier), Text(
        string="%condition",
        extent={{4,4},{4,10}},
        lineColor={95,95,95},
        fontSize=10,
        textStyle={TextStyle.Bold},
        horizontalAlignment=TextAlignment.Left));
    transition(
      d,
      c,y == 0,
      immediate=false,reset=true,synchronize=false,priority=1)
                       annotation (Line(
        points={{36.8,8},{-4,0},{-36,10}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier), Text(
        string="%condition",
        extent={{-8,-12},{-8,-6}},
        lineColor={95,95,95},
        fontSize=10,
        textStyle={TextStyle.Bold},
        horizontalAlignment=TextAlignment.Left));
    x = previous(x) + 1;
  public
    model E
      outer output Integer z;
      outer input Integer y;
    equation
      z = previous(z) + y;
      annotation (
        Icon(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%name")}),
        Diagram(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%stateText",
              fontSize=10)}),
        __Dymola_state=true,
        showDiagram=true,
        singleInstance=true);
    end E;

    model F
      outer output Integer z;
      outer input Integer y;
    equation
      z = previous(z) - y;
      annotation (
        Icon(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%name")}),
        Diagram(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%stateText",
              fontSize=10)}),
        __Dymola_state=true,
        showDiagram=true,
        singleInstance=true);
    end F;
  equation
    initialState(e) annotation (Line(
        points={{-70,-64},{-90,-64}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier,
        arrow={Arrow.Filled,Arrow.None}));
    transition(
      e,
      f,
      z > 100,
      immediate=false) annotation (Line(
        points={{-40,-42},{0,-30},{38,-42}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier), Text(
        string="%condition",
        extent={{4,4},{4,10}},
        lineColor={95,95,95},
        fontSize=10,
        textStyle={TextStyle.Bold},
        horizontalAlignment=TextAlignment.Left));
    transition(
      f,
      e,
      z < 50,
      immediate=false,
      reset=true,
      synchronize=false,
      priority=1) annotation (Line(
        points={{44,-80},{0,-92},{-38,-80}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier), Text(
        string="%condition",
        extent={{-12,-14},{-12,-8}},
        lineColor={95,95,95},
        fontSize=10,
        textStyle={TextStyle.Bold},
        horizontalAlignment=TextAlignment.Left));
    annotation (
      Icon(graphics={Text(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,0},
            textString="%name")}),
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
              100}}), graphics={Text(
            extent={{-100,98},{100,-102}},
            lineColor={0,0,0},
            textString="%stateText",
            fontSize=10)}),
      __Dymola_state=true,
      showDiagram=true,
      singleInstance=true);
  end A;
  A a annotation (Placement(transformation(extent={{-74,-52},{26,28}})));
  B b annotation (Placement(transformation(extent={{48,-26},{76,-6}})));
equation
  initialState(a) annotation (Line(
      points={{-36,30},{-38,38}},
      color={175,175,175},
      thickness=0.25,
      smooth=Smooth.Bezier,
      arrow={Arrow.Filled,Arrow.None}));
public
  model B
    outer output Integer x;
  equation
    x = previous(x) - 1
    annotation (
      Icon(graphics={Text(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,0},
            textString="%name")}),
      Diagram(graphics={Text(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,0},
            textString="%stateText",
            fontSize=10)}),
      __Dymola_state=true,
      showDiagram=true,
      singleInstance=true);
  end B;
equation
  transition(
    a,
    b,(z > 100 and i) or j,
    immediate=false,
    reset=true,
    synchronize=false,
    priority=1) annotation (Line(
      points={{28,6},{40,6},{52,-4}},
      color={175,175,175},
      thickness=0.25,
      smooth=Smooth.Bezier), Text(
      string="%condition",
      extent={{4,4},{4,10}},
      lineColor={95,95,95},
      fontSize=10,
      textStyle={TextStyle.Bold},
      horizontalAlignment=TextAlignment.Left));
  transition(
    b,
    a,x == 0,
    immediate=false,
    reset=true,synchronize=false,priority=1)
                 annotation (Line(
      points={{52,-28},{44,-38},{28,-30}},
      color={175,175,175},
      thickness=0.25,
      smooth=Smooth.Bezier), Text(
      string="%condition",
      extent={{-6,-14},{-6,-8}},
      lineColor={95,95,95},
      fontSize=10,
      textStyle={TextStyle.Bold},
      horizontalAlignment=TextAlignment.Left));
  annotation (Diagram(coordinateSystem(extent={{-80,-60},{80,60}},
          preserveAspectRatio=false),
                      graphics={
        Text(
          extent={{-68,56},{-8,46}},
          lineColor={0,0,0},
          fontSize=10,
          horizontalAlignment=TextAlignment.Left,
          textString="%declarations"),                        Rectangle(extent={{
              -80,60},{80,-60}},     lineColor={95,95,95}),
        Text(
          extent={{-90,36},{-80,26}},
          lineColor={255,0,255},
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          textString="i"),
        Text(
          extent={{-90,-46},{-80,-56}},
          lineColor={255,0,255},
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid,
          textString="j")}),             Icon(coordinateSystem(extent={{-80,-60},
            {80,60}},   preserveAspectRatio=false), graphics={Rectangle(extent={
              {-100,100},{100,-80}}, lineColor={95,95,95})}),
    showDiagram=true);
end Maraninchi2003_2;
