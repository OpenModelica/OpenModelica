within ;
package SMGraphicalTestCases
  "Some graphical test cases for Modelica State Machines"
  model SimpleSMwithAnnotations "Simple state machine"
    inner Integer i(start = 0);
    Integer j;

    block State1
      outer output Integer i;
      output Integer j(start = 10);
    equation
      i = previous(i) + 2;
      j = previous(j) - 1
      annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
    end State1;

    State1 state1 annotation(Placement(transformation(extent={{-62,40},{-26,76}})));

    block State2
      outer output Integer i;
    equation
      i = previous(i) - 1;
      annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
    end State2;

    State2 state2 annotation(Placement(transformation(extent={{-64,-8},{-26,30}})));
  equation
    j = 2*state1.j;
    transition(state1, state2, i > 10, immediate = false, reset = true, synchronize = false, priority = 1) annotation(Line(points={{-24,58},
            {-16,50},{-24,11}},                                                                                                  color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(string = "%condition", extent={{12,-2},
            {12,-8}},                                                                                                                                                                                                        lineColor = {95, 95, 95}, fontSize = 10, textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Left));
    transition(state2, state1, i < 1, immediate = false, reset = true, synchronize = false, priority = 1) annotation(Line(points={{-66,11},
            {-76,42},{-64,58}},                                                                                                    color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(string = "%condition", extent = {{-6, 4}, {-6, 10}}, lineColor = {95, 95, 95}, fontSize = 10, textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Right));
    initialState(state1) annotation(Line(points={{-45.2004,78},{-46,86}},      color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier, arrow = {Arrow.Filled, Arrow.None}));
    annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics={  Text(extent={{
                -72,96},{-22,86}},                                                                                                    lineColor = {0, 0, 0}, fontSize = 10,
              horizontalAlignment =                                                                                                   TextAlignment.Left, textString = "%declarations"),
                                                                                                    Text(extent={{
                -58,-12},{-8,-22}},                                                                                                   lineColor=
                {0,0,0},                                                                                                    fontSize=
                10,
              horizontalAlignment=TextAlignment.Left,
            textString="%equations")}),                                                                                                    experiment(StopTime = 30), __Dymola_experimentSetupOutput);
  end SimpleSMwithAnnotations;

  model InnerOuter "Hierarchical State Machine with inner outer variables"
    inner Integer i(start = 0);
    State1 state1 annotation(Placement(transformation(extent = {{-58, 22}, {18, 78}})));
    State2 state2 annotation(Placement(transformation(extent = {{-58, -58}, {18, -2}})));

    model State1
      inner outer output Integer i;
      A1 a1 annotation(Placement(transformation(extent = {{-68, -12}, {68, 44}})));
      A2 a2 annotation(Placement(transformation(extent = {{-68, -90}, {68, -30}})));

      model A1
        outer output Integer i;
      equation
        i = previous(i) + 2;
        annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
      end A1;

      model A2
        outer output Integer i;
      equation
        i = previous(i) - 1;
        annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
      end A2;
    equation
      initialState(a1) annotation(Line(points={{-8,46},{-8,68}},      color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier, arrow = {Arrow.Filled, Arrow.None}));
      transition(a1, a2, i < 1, immediate = false) annotation(Line(points={{-70,18},
              {-96,-28},{-70,-66}},                                                                              color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(string = "%condition", extent = {{-4, -4}, {-4, -10}}, lineColor = {95, 95, 95}, fontSize = 10, textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Right));
      transition(a2, a1, i > 10, immediate = false) annotation(Line(points={{70,-68},
              {92,-30},{70,18}},                                                                               color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(string = "%condition", extent = {{4, 4}, {4, 10}}, lineColor = {95, 95, 95}, fontSize = 10, textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Left));
      annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics={  Text(extent = {{-100, 102}, {100, -98}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
    end State1;

    model State2
      outer output Integer i;
    equation
      i = 42;
      annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
    end State2;
  equation

    initialState(state1) annotation(Line(points={{-26,80},{-26,92}},      color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier, arrow = {Arrow.Filled, Arrow.None}));
    transition(state2, state1, true, immediate = false) annotation(Line(points={{-60,-32},
            {-86,22},{-60,58}},                                                                                      color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(string = "%condition", extent = {{-4, 4}, {-4, 10}}, lineColor = {95, 95, 95}, fontSize = 10, textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Right));
    transition(state1, state2, i > 8, immediate = false) annotation(Line(points={{20,50},
            {42,2},{20,-30}},                                                                                     color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(string = "%condition", extent = {{4, -4}, {4, -10}}, lineColor = {95, 95, 95}, fontSize = 10, textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Left));
    annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics={  Text(extent = {{-94, 96}, {-34, 86}}, lineColor = {0, 0, 0}, fontSize = 10,
              horizontalAlignment =                                                                                                   TextAlignment.Left, textString = "%declarations")}), experiment(StopTime = 30), __Dymola_experimentSetupOutput);
  end InnerOuter;

  model Maraninchi2003_2 "Figure 2 from Maraninchi 2003"
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

model MLSWA "Example from the MLS 3.3, Section 17.3.7 with annotations"
      inner Integer v(start=0);
      model State1
        inner Integer count(start=0);
        inner outer output Integer v;
        StateA stateA
          annotation (Placement(transformation(extent={{-78,42},{-12,64}})));
        StateB stateB
          annotation (Placement(transformation(extent={{-78,2},{-12,26}})));
        StateC stateC
          annotation (Placement(transformation(extent={{-78,-46},{-12,-20}})));
        StateD stateD
          annotation (Placement(transformation(extent={{-78,-84},{-12,-68}})));
        StateX stateX
          annotation (Placement(transformation(extent={{10,2},{86,58}})));
        StateY stateY
          annotation (Placement(transformation(extent={{10,-78},{86,-24}})));
        model StateA
          outer output Integer v;
        equation
          v = previous(v) + 2;
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
        end StateA;

        model StateB
          outer output Integer v;
        equation
          v = previous(v) - 1;
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
        end StateB;

        model StateC
          outer output Integer count;
        equation
          count = previous(count) + 1;
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
        end StateC;

        model StateD
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
        end StateD;
      equation
        transition(
            stateA,
            stateB,
            v >= 6,
            immediate=false) annotation (Line(
            points={{-45,40},{-45,28}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier), Text(
            string="%condition",
            extent={{-4,-4},{-4,-10}},
            lineColor={95,95,95},
            fontSize=10,
            textStyle={TextStyle.Bold},
            horizontalAlignment=TextAlignment.Right));
        transition(
            stateB,
            stateC,
            v == 0,
            immediate=false) annotation (Line(
            points={{-45,0},{-45,-18}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier), Text(
            string="%condition",
            extent={{-4,-4},{-4,-10}},
            lineColor={95,95,95},
            fontSize=10,
            textStyle={TextStyle.Bold},
            horizontalAlignment=TextAlignment.Right));
        transition(
            stateC,
            stateD,
            count >= 2,
            immediate=false) annotation (Line(
            points={{-21.4285,-48},{-21.4285,-66}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier), Text(
            string="%condition",
            extent={{-4,-4},{-4,-10}},
            lineColor={95,95,95},
            fontSize=10,
            textStyle={TextStyle.Bold},
            horizontalAlignment=TextAlignment.Right));
        transition(
            stateC,
            stateA,
            true,
            immediate=false,
            priority=2) annotation (Line(
            points={{-63.857,-48},{-66,-48},{-90,-48},{-90,76},{-79,65}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier), Text(
            string="%condition",
            extent={{-4,-4},{-4,-10}},
            lineColor={95,95,95},
            fontSize=10,
            textStyle={TextStyle.Bold},
            horizontalAlignment=TextAlignment.Right));
        initialState(stateA) annotation (Line(
            points={{-45,66},{-50,72}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier,
            arrow={Arrow.Filled,Arrow.None}));
    public
        model StateX
          outer input Integer v;
          Integer i(start=0);
          Integer w;
        equation
          i = previous(i) + 1;
          w = v;
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
        end StateX;

        model StateY
          Integer j(start=0);
        equation
          j = previous(j) + 1;
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
        end StateY;
      equation
        transition(
            stateX,
            stateY,
            stateX.i > 20,
            immediate=false) annotation (Line(
            points={{48,0},{48,-22}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier), Text(
            string="%condition",
            extent={{-4,-4},{-4,-10}},
            lineColor={95,95,95},
            fontSize=10,
            textStyle={TextStyle.Bold},
            horizontalAlignment=TextAlignment.Right));
        initialState(stateX) annotation (Line(
            points={{48,60},{48,72}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier,
            arrow={Arrow.Filled,Arrow.None}));
        annotation (
          Icon(graphics={Text(
                extent={{-100,100},{100,-100}},
                lineColor={0,0,0},
                textString="%name")}),
          Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
                  100}}),
                  graphics={Text(
                extent={{-100,98},{100,-102}},
                lineColor={0,0,0},
                textString="%stateText",
                fontSize=10)}),
          __Dymola_state=true,
          showDiagram=true,
          singleInstance=true);
      end State1;
      State1 state1
        annotation (Placement(transformation(extent={{-80,-58},{78,78}})));
      model State2
        outer output Integer v;
      equation
        v = previous(v) + 5;
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
      end State2;
      State2 state2
        annotation (Placement(transformation(extent={{-78,-92},{78,-76}})));
equation
      transition(
        state1,
        state2,
        activeState(state1.stateD) and activeState(state1.stateY),
        immediate=false) annotation (Line(
          points={{-69.8718,-60},{-36,-74}},
          color={175,175,175},
          thickness=0.25,
          smooth=Smooth.Bezier), Text(
          string="%condition",
          extent={{76,-4},{76,-10}},
          lineColor={95,95,95},
          fontSize=10,
          textStyle={TextStyle.Bold},
          horizontalAlignment=TextAlignment.Right));
      transition(
        state2,
        state1,
        v >= 20,
        immediate=false) annotation (Line(
          points={{20,-74},{59.7692,-60}},
          color={175,175,175},
          thickness=0.25,
          smooth=Smooth.Bezier), Text(
          string="%condition",
          extent={{4,4},{4,10}},
          lineColor={95,95,95},
          fontSize=10,
          textStyle={TextStyle.Bold},
          horizontalAlignment=TextAlignment.Left));
      initialState(state1) annotation (Line(
          points={{-1,80},{0,94}},
          color={175,175,175},
          thickness=0.25,
          smooth=Smooth.Bezier,
          arrow={Arrow.Filled,Arrow.None}));
      annotation (Diagram(coordinateSystem(preserveAspectRatio=false,
        extent={{-100,-100},{100,100}}), graphics={Text(
              extent={{-96,94},{-58,90}},
              lineColor={0,0,0},
              textString="%declarations")}));
end MLSWA;

  model CDF "Example from \\cite{Elmqvist2012}"
    Components.Increment state1(increment=1)
      annotation (Placement(transformation(extent={{-26,28},{-14,40}})));
    Components.Increment state2(increment=-1)
      annotation (Placement(transformation(extent={{-26,-8},{-14,4}})));
  protected
    Components.IntegerOutput i
      annotation (Placement(transformation(extent={{6,6},{26,26}})));
  public
    Components.Prev prev
      annotation (Placement(transformation(extent={{30,10},{42,22}})));
  equation
    initialState(state1) annotation (Line(
        points={{-20,42},{-20,50}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier,
        arrow={Arrow.Filled,Arrow.None}));
    transition(
        state1,
        state2,
        i > 10,
        immediate=false) annotation (Line(
        points={{-20,26},{-20,6}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier), Text(
        string="%condition",
        extent={{-4,-4},{-4,-10}},
        lineColor={95,95,95},
        fontSize=10,
        textStyle={TextStyle.Bold},
        horizontalAlignment=TextAlignment.Right));
    transition(
        state2,
        state1,
        i < 1,
        immediate=false) annotation (Line(
        points={{-20,-10},{-20,-16},{-42,-16},{-42,46},{-28,46},{-27,41}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier), Text(
        string="%condition",
        extent={{-4,-4},{-4,-10}},
        lineColor={95,95,95},
        fontSize=10,
        textStyle={TextStyle.Bold},
        horizontalAlignment=TextAlignment.Right));
    connect(prev.u, i) annotation (Line(
        points={{27.6,16},{16,16}},
        color={255,127,0},
        smooth=Smooth.None));
    connect(i, state1.y) annotation (Line(
        points={{16,16},{-4,16},{-4,34},{-12.8,34}},
        color={255,127,0},
        smooth=Smooth.None));
    connect(i, state2.y) annotation (Line(
        points={{16,16},{-4,16},{-4,-2},{-12.8,-2}},
        color={255,127,0},
        smooth=Smooth.None));
    connect(prev.y, state1.u) annotation (Line(
        points={{43.2,16},{48,16},{48,-24},{-52,-24},{-52,34},{-28.4,34}},
        color={255,127,0},
        smooth=Smooth.None));
    connect(state2.u, prev.y) annotation (Line(
        points={{-28.4,-2},{-52,-2},{-52,-24},{48,-24},{48,16},{43.2,16}},
        color={255,127,0},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}),      graphics));
  end CDF;

  package Components
    partial block PartialIntegerSISO
      "Partial block with a IntegerInput and an IntegerOutput signal"

      IntegerInput u "Integer input signal"
        annotation (Placement(transformation(extent={{-180,-40},{-100,40}})));
      IntegerOutput y "Integer output signal"
        annotation (Placement(transformation(extent={{100,-20},{140,20}})));
      annotation (Icon(coordinateSystem(
            preserveAspectRatio=false,
            extent={{-100,-100},{100,100}},
            initialScale=0.06), graphics={
            Text(
              extent={{110,-50},{250,-70}},
              lineColor={0,0,0},
              textString=DynamicSelect(" ", String(
                    y,
                    minimumLength=1,
                    significantDigits=0))),
            Text(
              extent={{-250,170},{250,110}},
              textString="%name",
              lineColor={0,0,255}),
            Rectangle(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              lineThickness=5.0,
              fillColor={255,213,170},
              fillPattern=FillPattern.Solid,
              borderPattern=BorderPattern.Raised)}));
    end PartialIntegerSISO;

    connector IntegerInput = input Integer "'input Integer' as connector"
      annotation (
      defaultComponentName="u",
      Icon(graphics={Polygon(
            points={{-100,100},{100,0},{-100,-100},{-100,100}},
            lineColor={255,127,0},
            fillColor={255,127,0},
            fillPattern=FillPattern.Solid)}, coordinateSystem(
          extent={{-100,-100},{100,100}},
          preserveAspectRatio=true,
          initialScale=0.2)),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          initialScale=0.2,
          extent={{-100,-100},{100,100}}), graphics={Polygon(
            points={{0,50},{100,0},{0,-50},{0,50}},
            lineColor={255,127,0},
            fillColor={255,127,0},
            fillPattern=FillPattern.Solid), Text(
            extent={{-10,85},{-10,60}},
            lineColor={255,127,0},
            textString="%name")}),
      Documentation(info="<html>
<p>
Connector with one input signal of type Integer.
</p>
</html>"));
    connector IntegerOutput = output Integer "'output Integer' as connector"
      annotation (
      defaultComponentName="y",
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={Polygon(
            points={{-100,100},{100,0},{-100,-100},{-100,100}},
            lineColor={255,127,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid)}),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={Polygon(
            points={{-100,50},{0,0},{-100,-50},{-100,50}},
            lineColor={255,127,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid), Text(
            extent={{30,110},{30,60}},
            lineColor={255,127,0},
            textString="%name")}),
      Documentation(info="<html>
<p>
Connector with one output signal of type Integer.
</p>
</html>"));
    block Increment
      extends PartialIntegerSISO;
      parameter Integer increment;
    equation
      y = u + increment;
    end Increment;

    block Prev
      extends PartialIntegerSISO;
    equation
      y = previous(u);
    end Prev;
  end Components;

  model DeepHierarchy "SM Example with a slightly deeper hierarchy"
    block L1Start
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
    end L1Start;
    L1Start l1Start
      annotation (Placement(transformation(extent={{-18,22},{18,58}})));
    block L1Composite
      Integer count(start=0);
      block L2Start

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
      end L2Start;
      L2Start l2Start
        annotation (Placement(transformation(extent={{-58,2},{-22,38}})));
      block L2Composite
        block L3Start

          annotation (
            Icon(graphics={Text(
                  extent={{-100,100},{100,-100}},
                  lineColor={0,0,0},
                  textString="%name")}),
            Diagram(graphics={Text(
                  extent={{-100,100},{100,-100}},
                  lineColor={0,0,0},
                  textString="%stateName",
                  fontSize=10)}),
            __Dymola_state=true,
            showDiagram=true,
            singleInstance=true);
        end L3Start;
        L3Start l3Start
          annotation (Placement(transformation(extent={{-38,2},{38,78}})));
        block L3Final

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
        end L3Final;
        L3Final l3Final
          annotation (Placement(transformation(extent={{-38,-98},{38,-22}})));
      equation
        transition(
            l3Start,
            l3Final,
            true,
            immediate=false) annotation (Line(
            points={{0,0},{0,-20}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier), Text(
            string="%condition",
            extent={{-4,-4},{-4,-10}},
            fontSize=10,
            textStyle={TextStyle.Bold},
            horizontalAlignment=TextAlignment.Right));
        initialState(l3Start) annotation (Line(
            points={{-40,40},{-72,40}},
            color={175,175,175},
            thickness=0.25,
            smooth=Smooth.Bezier,
            arrow={Arrow.Filled,Arrow.None}));
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
      end L2Composite;
      L2Composite l2Composite
        annotation (Placement(transformation(extent={{-78,-98},{-2,-22}})));
      L2Final l2Final
        annotation (Placement(transformation(extent={{60,2},{96,38}})));
    equation
      transition(
        l2Start,
        l2Composite,
        true,
        immediate=false,
        reset=true,
        synchronize=false,
        priority=2) annotation (Line(
          points={{-20,10},{92,-34},{0,-60}},
          color={175,175,175},
          thickness=0.25,
          smooth=Smooth.Bezier), Text(
          string="%condition",
          extent={{40,0},{40,-6}},
          fontSize=10,
          textStyle={TextStyle.Bold},
          horizontalAlignment=TextAlignment.Right));
      transition(
        l2Composite,
        l2Start,
        activeState(l2Composite.l3Final),
        immediate=false,
        reset=true,
        synchronize=false,
        priority=1) annotation (Line(
          points={{-79,-21},{-59,1}},
          color={175,175,175},
          thickness=0.25,
          smooth=Smooth.Bezier), Text(
          string="%condition",
          extent={{4,4},{4,10}},
          fontSize=10,
          textStyle={TextStyle.Bold},
          horizontalAlignment=TextAlignment.Left));
      initialState(l2Start) annotation (Line(
          points={{-60,20},{-80,20}},
          color={175,175,175},
          thickness=0.25,
          smooth=Smooth.Bezier,
          arrow={Arrow.Filled,Arrow.None}));
    public
      block L2Final

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
      end L2Final;
    equation
      count = previous(count) + 1;
      transition(
        l2Start,
        l2Final,count >= 2,
        immediate=false,
        priority=1,
        reset=true,
        synchronize=false) annotation (Line(
          points={{-20,22},{58,22}},
          color={175,175,175},
          thickness=0.25,
          smooth=Smooth.Bezier), Text(
          string="%condition",
          extent={{4,4},{4,10}},
          fontSize=10,
          textStyle={TextStyle.Bold},
          horizontalAlignment=TextAlignment.Left));
      annotation (
        Icon(graphics={Text(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,0},
              textString="%name")}),
        Diagram(graphics={Text(
              extent={{-100,98},{100,-102}},
              lineColor={0,0,0},
              textString="%stateText",
              fontSize=10)}),
        __Dymola_state=true,
        showDiagram=true,
        singleInstance=true);
    end L1Composite;
    L1Composite l1Composite
      annotation (Placement(transformation(extent={{-38,-78},{38,-2}})));
  equation
    initialState(l1Start) annotation (Line(
        points={{-3.6,60},{-4,82}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier,
        arrow={Arrow.Filled,Arrow.None}));
    transition(
        l1Start,
        l1Composite,
        timeInState() > 1.9,
        immediate=false,
        reset=true,
        synchronize=false,
        priority=1) annotation (Line(
        points={{20,40},{34,0}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier), Text(
        string="%condition",
        extent={{36,-6},{36,-12}},
        fontSize=10,
        textStyle={TextStyle.Bold},
        horizontalAlignment=TextAlignment.Right));
    transition(
        l1Composite,
        l1Start,
        activeState(l1Composite.l2Final),
        immediate=false,
        reset=true,
        synchronize=false,
        priority=1) annotation (Line(
        points={{-39,-1},{-20,40}},
        color={175,175,175},
        thickness=0.25,
        smooth=Smooth.Bezier), Text(
        string="%condition",
        extent={{4,4},{4,10}},
        fontSize=10,
        textStyle={TextStyle.Bold},
        horizontalAlignment=TextAlignment.Left));
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end DeepHierarchy;
end SMGraphicalTestCases;
