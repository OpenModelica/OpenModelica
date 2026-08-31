// name:     Ticket5821.mo
// keywords: tests Connections.branch/Connections.uniqueRoot/Connections.uniqueRootIndices
// status:   correct
//
//


package Modelica_StateGraph2  "Modelica_StateGraph2 (Version 2.0.3) - Modeling of continuous-time state machines"
  model Step  "Step (optionally with initial step and/or activePort)"
    parameter Integer nIn(min = 0) = 0 "Number of input connections" annotation(Dialog(__Dymola_connectorSizing = true), HideResult = true);
    parameter Integer nOut(min = 0) = 0 "Number of output connections" annotation(Dialog(__Dymola_connectorSizing = true), HideResult = true);
    parameter Boolean initialStep = false "=true, if initial step (graph starts at this step)" annotation(Evaluate = true, HideResult = true, choices(__Dymola_checkBox = true));
    parameter Boolean use_activePort = false "=true, if activePort enabled" annotation(Evaluate = true, HideResult = true, choices(__Dymola_checkBox = true));
    Modelica_StateGraph2.Internal.Interfaces.Step_in[nIn] inPort "Port for zero, one, or more input transitions" annotation(Placement(transformation(extent = {{-50, 85}, {50, 115}})));
    Modelica_StateGraph2.Internal.Interfaces.Step_out[nOut] outPort "Port for zero, one, or more output transitions" annotation(Placement(transformation(extent = {{-50, -130}, {50, -100}})));
    Modelica.Blocks.Interfaces.BooleanOutput activePort = active if use_activePort "= true if step is active, otherwise the step is not active" annotation(Placement(transformation(extent = {{100, -18}, {136, 18}})));
    output Boolean active "= true if step is active, otherwise the step is not active";
  protected
    Boolean newActive(start = initialStep, fixed = true) "Value of active in the next iteration";
    Boolean oldActive(start = initialStep, fixed = true) "Value of active when CompositeStep was aborted";
    Modelica_StateGraph2.Internal.Interfaces.Node node "Handles rootID as well as suspend and resume transitions from a Modelica_StateGraph2";
    Boolean inport_fire;
    Boolean outport_fire;
  equation
    inport_fire = Blocks.BooleanFunctions.anyTrue(inPort.fire);
    outport_fire = Blocks.BooleanFunctions.anyTrue(outPort.fire);
    newActive = if node.resume then oldActive else inport_fire or active and not outport_fire and not node.suspend;
    active = pre(newActive);
    when node.suspend then
      oldActive = active;
    end when;
    for i in 1:nOut loop
      outPort[i].available = if i == 1 then active and not node.suspend else outPort[i - 1].available and not outPort[i - 1].fire and not node.suspend;
    end for;
    inPort.checkUnaryConnection = fill(true, nIn);
    outPort.checkOneDelayedTransitionPerLoop = fill(Internal.Utilities.propagateLoopCheck(inPort.checkOneDelayedTransitionPerLoop), nOut);
    for i in 1:nIn loop
      Connections.branch(inPort[i].node, node);
      inPort[i].node = node;
    end for;
    if initialStep then
      Connections.uniqueRoot(node, "
  The StateGraph has a wrong connection structure. Reasons:
  (1) The StateGraph is initialized at two different locations (initial steps or entry ports).
  (2) A transition is made wrongly out of a Parallel component.
  (3) A transition is made between two branches of a Parallel component.
  All these cases are not allowed.
      ");
      node.suspend = false;
      node.resume = false;
    else
      assert(nIn > 0, "Step is not reachable since it has no input transition");
      if nIn == 0 then
        node.suspend = false;
        node.resume = false;
      end if;
    end if;
    for i in 1:nOut loop
      Connections.branch(node, outPort[i].node);
      outPort[i].node = node;
    end for;
    for i in 1:size(inPort, 1) loop
      if cardinality(inPort[i]) == 0 then
        inPort[i].fire = true;
        inPort[i].checkOneDelayedTransitionPerLoop = true;
        assert(false, "
  An element of the inPort connector of this step is not connected. Most likely, the Modelica tool
  has a bug and does not correctly handle the connectorSizing annotation in a particular case.
  You can fix this by removing all input connections to this step and by manually removing
  the line 'nIn=...' in the text layer where this step is declared.
        ");
      end if;
    end for;
    for i in 1:size(outPort, 1) loop
      if cardinality(outPort[i]) == 0 then
        outPort[i].fire = true;
        assert(false, "
  An element of the outPort connector of this step is not connected. Most likely, the Modelica tool
  has a bug and does not correctly handle the connectorSizing annotation in a particular case.
  You can fix this by removing all output connections to this step and by manually removing
  the line 'nOut=...' in the text layer where this step is declared.
        ");
      end if;
    end for;
    annotation(defaultComponentName = "step1", Documentation(info = "<html>
  <p>
  A Step is the graphical representation of a state and is said to be either
  active or not active. A StateGraph2 model is comprised of one or more
  steps that may or may not change their states during execution.
  The input port of a Step (inPort) can only be connected to the output port
  of a Transition, and the output port of a Step (outPort) can only be connected
  to the input of a Transition. An arbitrary number of input and/or output
  Transitions can be connected to these ports.
  </p>

  <p>
  The state of a step is available via the output variable <b>active</b> that can
  be used in action blocks (e.g. \"step.active\"). Alternatively, via parameter
  \"use_activePort\" the Boolean output port \"activePort\" can be enabled.
  When the step is active, activePort = <b>true</b>, otherwise it is <b>false</b>. This port can
  be connected to Boolean action blocks, e.g., from
  <a href=\"modelica://Modelica_StateGraph2.Blocks.MathBoolean\">Modelica_StateGraph2.Blocks.MathBoolean</a>.
  </p>

  <p>
  Every StateGraph2 graph
  must have exactly one initial step. An initial step is defined by setting parameter initialStep
  at one Step or one Parallel component to true. The initial step is visualized by a
  small arrow pointing to this step.
  </p>

  <p>
  In the following table different configurations of a Step are shown:
  </p>

  <blockquote>
  <table cellspacing=\"0\" cellpadding=\"4\" border=\"1\" width=\"600\">
  <tr><th>Parameter setting</th>
      <th>Icon</th>
      <th>Description</th>
      </tr>

  <tr><td> Default step</td>
      <td><img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/Step-default.png\"></td>
      <td> If the step is active, the public Step variable &quot;active&quot; is <b>true</b>
           otherwise, it is <b>false</b>. An active Step is visualized by a green
           fill color in diagram animation.</td>
      </tr>

  <tr><td> use_activePort = <b>true</b></td>
      <td><img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/Step-use_activePort.png\"></td>
      <td>If the step is active, the connector &quot;activePort&quot; is <b>true</b>
          otherwise, it is <b>false</b> (the activePort is the small, violet, triangle
          at the rigth side of the Step icon). Actions may be triggered, e.g., by connecting block
          <a href=\"modelica://Modelica_StateGraph2.Blocks.MathBoolean.MultiSwitch\">MultiSwitch</a>
          to the activePort.</td></tr>

  <tr><td> initialStep = <b>true</b></td>
      <td><img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/Step-initial.png\"></td>
      <td> Exactly <u>one</u> Step or Parallel component in a StateGraph2 graph
           must have &quot;initialStep = <b>true</b>&quot;. At the first model evaluation
           during initialization, &quot;active&quot; is set to <b>true</b> for
           the initial Step or the initial Parallel component, i.e.,
           the respective component is activated.</td>
      </tr>
  </table>
  </blockquote>

  <p>
  The inPort and the outPort connectors of a Step are &quot;vectors of connectors&quot;.
  How connections to these ports are automatically handled in a convenient way is sketched
  <a href=\"modelica://Modelica_StateGraph2.UsersGuide.Tutorial.VectorsOfConnectors\">here</a>
  in the tutorial.
  </p>

  </html>"), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.04, grid = {1, 1}), graphics = {Text(extent = {{15, 118}, {470, 193}}, textString = "%name", lineColor = {0, 0, 255}), Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = DynamicSelect({255, 255, 255}, if active > 0.5 then {0, 255, 0} else {255, 255, 255}), fillPattern = FillPattern.Solid, radius = 60), Line(visible = initialStep, points = {{-235, 181}, {-137, 181}, {-90, 90}}, color = {0, 0, 0}, smooth = Smooth.Bezier), Ellipse(visible = initialStep, extent = {{-255, 199}, {-219, 163}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Polygon(visible = initialStep, points = {{-95, 140}, {-90, 90}, {-126, 124}, {-95, 140}}, lineColor = {0, 0, 0}, smooth = Smooth.None, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.04, grid = {1, 1})));
  end Step;

  model Transition  "Transition between steps (optionally with delayed transition and/or condition input port)"
    parameter Boolean use_conditionPort = false "= true, if conditionPort enabled" annotation(Evaluate = true, HideResult = true, choices(__Dymola_checkBox = true));
    input Boolean condition = true "Fire condition (time varying Boolean expression)" annotation(Dialog(enable = not use_conditionPort));
    parameter Boolean delayedTransition = false "= true, if transition fires after waitTime" annotation(Evaluate = true, HideResult = true, choices(__Dymola_checkBox = true));
    parameter Modelica.SIunits.Time waitTime = 0 "Wait time before transition fires (> 0 required)" annotation(Dialog(enable = delayedTransition));
    parameter Boolean use_firePort = false "= true, if firePort enabled" annotation(Evaluate = true, HideResult = true, choices(__Dymola_checkBox = true));
    parameter Boolean loopCheck = true "= true, if one delayed transition per loop required" annotation(Evaluate = true, HideResult = true, Dialog(tab = "Advanced"), choices(__Dymola_checkBox = true));
    Modelica_StateGraph2.Internal.Interfaces.Transition_in inPort "Input port of transition (exactly one connection to this port is required)" annotation(Placement(transformation(extent = {{-17, 83}, {17, 117}})));
    Modelica_StateGraph2.Internal.Interfaces.Transition_out outPort "Output port of transition (exactly one connection from this port is required)" annotation(Placement(transformation(extent = {{-25, -150}, {25, -100}})));
    Modelica.Blocks.Interfaces.BooleanInput conditionPort if use_conditionPort "Fire condition as Boolean input." annotation(Placement(transformation(extent = {{-150, -25}, {-100, 25}})));
    Modelica.Blocks.Interfaces.BooleanOutput firePort = fire if use_firePort "= true, if transition fires" annotation(Placement(transformation(extent = {{90, -15}, {120, 15}})));
    output Boolean fire "= true, if transition fires";
    output Boolean enableFire "= true, if firing condition is true";
  protected
    constant Modelica.SIunits.Time minimumWaitTime = 100 * Modelica.Constants.eps;
    Modelica.SIunits.Time t_start "Time instant at which the transition would fire, if waitTime would be zero";
    Modelica.Blocks.Interfaces.BooleanInput localCondition;
  initial equation
    pre(enableFire) = false;
    if delayedTransition then
      pre(t_start) = 0;
    end if;
  equation
    connect(conditionPort, localCondition);
    if not use_conditionPort then
      localCondition = condition;
    end if;
    enableFire = localCondition and inPort.available;
    if delayedTransition then
      when enableFire then
        t_start = time;
      end when;
      fire = enableFire and time >= t_start + waitTime;
      outPort.checkOneDelayedTransitionPerLoop = true;
    else
      t_start = 0;
      fire = enableFire;
      if loopCheck then
        outPort.checkOneDelayedTransitionPerLoop = inPort.checkOneDelayedTransitionPerLoop;
      else
        outPort.checkOneDelayedTransitionPerLoop = true;
      end if;
    end if;
    inPort.fire = fire;
    outPort.fire = fire;
    Connections.branch(inPort.node, outPort.node);
    outPort.node = inPort.node;
    assert(not delayedTransition or delayedTransition and waitTime > minimumWaitTime, "Either set delayTransition = false, or set waitTime (= " + String(waitTime) + ") > " + String(minimumWaitTime));
    annotation(defaultComponentName = "T1", Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, initialScale = 0.04, preserveAspectRatio = true, grid = {1, 1}), graphics = {Text(visible = delayedTransition, extent = {{-200, 10}, {200, -10}}, lineColor = {255, 0, 0}, textString = "%waitTime", origin = {210, -70}, rotation = 0), Line(visible = delayedTransition, points = {{0, -12.5}, {0, -30}}, color = {255, 0, 0}), Line(visible = delayedTransition, points = {{0, -86}, {0, -100}}, color = {255, 0, 0}), Line(visible = delayedTransition, points = {{0, -47}, {0, -63}}, color = {255, 0, 0}), Line(visible = not delayedTransition, points = {{0, 0}, {0, -100}}, color = {0, 0, 0}), Text(extent = {{-150, -15}, {150, 15}}, textString = "%name", lineColor = {0, 0, 255}, origin = {160, 75}, rotation = 0), Rectangle(extent = {{-100, -15}, {100, 15}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid, radius = 10), Line(points = {{0, 90}, {0, 12}}, color = {0, 0, 0}), Text(visible = not use_conditionPort, extent = {{-300, -15}, {300, 15}}, lineColor = DynamicSelect({128, 128, 128}, if condition > 0.5 then {0, 255, 0} else {128, 128, 128}), textString = "%condition", origin = {-155, -3}, rotation = 90), Text(visible = not loopCheck, extent = {{10, -60}, {400, -80}}, lineColor = {255, 0, 0}, fillColor = {170, 255, 213}, fillPattern = FillPattern.Solid, textString = "no check"), Line(visible = not loopCheck, points = {{0, -15}, {0, -100}}, color = {255, 0, 0}, smooth = Smooth.None)}), Documentation(info = "<html>
  <p>
  <img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/SimpleStateGraph.png\" align=\"right\">
  To define a possible change of states, a Transition is connected to the output of the preceding Step and to the input of the succeeding Step, see figure to the right, where Transition t1 defines the transition from Step s1 to Step s2. Note: A Transition has exactly one preceding and one succeeding Step. A Transition is said to be enabled if the preceding step is active. An enabled transition is said to be fireable when the Boolean condition defined in the parameter menu of the transition is evaluated to <b>true</b>. This condition is also called <u>Transition condition</u> and is displayed in the icon of the Transition (e.g., &quot;time &gt; 1&quot; is the condition of Transition t1). When parameter <u>use_conditionPort</u> is set, the Transition condition is alternatively defined by a Boolean signal that is connected to the enabled <u>conditionPort</u>.
  </p>

  <p>
  A fireable transition will fire immediately. In the figure to the right, t1 fires when s1 is active and time is greater than one, i.e., s1 becomes inactive and s2 becomes active.
  The firing of a transition can optionally also be delayed for a certain period of time defined by parameter &quot;waitTime&quot;. See, e.g., t2 in the figure to right, that is delayed for one second before it may fire, given that the condition remains true and the preceding Step remains active during the entire delay time.
  </p>

  <p>
  In the following table different configurations of a Transition are shown:
  </p>

  <blockquote>
  <table cellspacing=\"0\" cellpadding=\"4\" border=\"1\" width=\"600\">
  <tr><th>Parameter setting</th>
      <th>Icon</th>
      <th>Description</th></tr>

  <tr><td>Default transition</td>
      <td><img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/Transition-default.png\"></td>
      <td>The transition fires when the preceding step is active
          and the expression &quot;condition&quot; in the parameter menu is <b>true</b>.</td>
      </tr>

  <tr><td>use_conditionPort = <b>true</b></td>
      <td><img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/Transition-use_conditionPort.png\"></td>
      <td>The transition fires when the preceding step is active
          and connector &quot;conditionPort&quot; is <b>true</b>.</td>
      </tr>

  <tr><td>delayedTransition = <b>true</b></td>
      <td><img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/Transition-delayedTransition.png\"></td>
      <td>The transition fires after the delay time &quot;waitTime&quot; (here: 1.23 s),
          if the preceding step was active, and &quot;condition = <b>true</b>&quot;
          during the entire delay time.</td>
      </tr>

  <tr><td>use_firePort = <b>true</b></td>
      <td><img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/Transition-use_firePort.png\"></td>
      <td>Connector &quot;firePort&quot; is <b>true</b> when the transition fires.
          Actions may be triggered, e.g., by connecting block
          <a href=\"modelica://Modelica_StateGraph2.Blocks.MathBoolean.MultiSwitch\">MultiSwitch</a>
          to the firePort.</td>
      </tr>

  <tr><td>loopCheck = <b>false</b><br>
          (in &quot;Advanced&quot; tab)</td>
      <td><img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/Transition-noLoopCheck.png\"></td>
      <td>It is <u>not</u> checked whether the loop in which this Transition
          is used, has at least one delayed transition.
          Use this option only, if you are completley sure that
          infinite event looping is not possible in this loop.
          Consider to use
          <a href=\"modelica://Modelica_StateGraph2.LoopBreakingTransition\">LoopBreakingTransition</a>
          instead!</td>
      </tr>

  </table>
  </blockquote>

  <p>
  <img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/SimpleInfiniteLoop.png\" align=\"right\">
  At an event instant, an iteration occurs, due to the Modelica semantics (= whenever a new event occurs, the model is re-evaluated). This means that Transitions keep firing along a connected graph, as long as the firing conditions are true. In principal, it is therefore possible that infinite event looping occurs.
  A simple example of this kind is shown in the figure to the right. Here, all Transition conditions are true and therefore all Transitions would fire forever at the initial time. This is, however, no valid StateGraph2 model and will result in a translation error, since it is required that a StateGraph2 model has at least one delayed Transition per loop.
  This means that one of T1, T2, or T3, must have parameter delayedTransition=<b>true</b>. Since event iteration stops at a delayed Transition, infinite event looping cannot occur. This also means that at one time instant every Transition can fire at most once and therefore the number of model evaluations at an event instant is bounded by the number of Transition components.
  </p>

  <p>
  If you have to artifically introduce a delay time in order to fulfill the requirement above, it is recommended to use the special
  <a href=\"modelica://Modelica_StateGraph2.LoopBreakingTransition\">LoopBreakingTransition</a>
  that is designed for this case.
  </p>

  <p>
  Note, it is still possible that infinite event looping occurs due to <u>model errors</u> in other parts of the model. For example, if a user introduces an equation of the form &quot;J = <b>pre</b>(J) + 1&quot; outside of a when-clause, event iteration does not stop.
  </p>

  <p>
  There are rare situations, where infinite event looping cannot occur even if there is no delayed transition in a loop. When you do not want to introduce an artifical time delay in a loop in this case, you can switch off the loop check by setting parameter &quot;loopCheck = <b>false</b>&quot; in the &quot;Advanced&quot; tab of the parameter menu of one Transition in this loop.
  </p>

  </html>"), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, grid = {1, 1})));
  end Transition;

  package Blocks  "Input/output blocks that are designed for StateGraph2 but shall be included in the Modelica Standard Library"
    package BooleanFunctions  "Functions with Boolean inputs (shall be included in Modelica Standard Library)"
      function anyTrue  "Returns true, if at least on element of the Boolean input vector is true ('or')"
        extends Modelica.Icons.Function;
        input Boolean[:] b;
        output Boolean result;
      algorithm
        result := false;
        for i in 1:size(b, 1) loop
          result := result or b[i];
        end for;
      end anyTrue;
    end BooleanFunctions;
    annotation(Documentation(info = "<html>
  <p>
  An important practical aspect of state machines is the ability to assign values and expressions to variables depending on the state of the machine. In StateGraph2, a number of graphical components have been added in this package (= Modelica_StateGraph2.Blocks)
  to facilitate usage in a safe and intuitive way. Since these are just input/output blocks and will also be useful in another context, it is planned to add them to the Modelica Standard Library.
  Some usage examples are given
  <a href=\"modelica://Modelica_StateGraph2.UsersGuide.Tutorial.Actions\">here</a>
  in the tutorial, e.g., the example shown in the Figure below.
  </p>

  <blockquote>
  <img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/Elements/MultiSwitch.png\">
  </blockquote>

  </html>"));
  end Blocks;

  package Internal  "Internal utility models (should usually not be used by user)"
    package Interfaces  "Connectors and partial models"
      record Node  "Node of a state machine to communicate information between steps (for suspend/resume actions and to guarantee a valid graph)"
        Boolean suspend "= true, if the composite step is terminated via a suspend port";
        Boolean resume "= true, if the composite step is entered via a resume port";

        function equalityConstraint
          input Node node1;
          input Node node2;
          output Real[0] residue;
        algorithm
          assert(node1.suspend == node2.suspend and node1.resume == node2.resume, "Internal error");
        end equalityConstraint;
      end Node;

      connector Step_in_base  "Input port of a step without icon"
        input Boolean fire "true, if transition fires and step is activated" annotation(HideResult = true);
        Node node "Communicates suspend/resume flags and is used to check the correct connection structure." annotation(HideResult = true);
        output Boolean checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible" annotation(HideResult = true);
        input Boolean checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition" annotation(__Dymola_BooleanLoopMessage = "
      Every loop of a StateGraph must have at least one delayed transition
      (an instance of Components.Transition with parameter delayedTransition = true)
      in order that infinite event looping cannot occur. Alternatively you can set
      checkLoop=false in the Advanced tab of the Transition, provided you are
      absolutely sure that this cannot happen.
        ", HideResult = true);
      end Step_in_base;

      connector Step_out_base  "Output port of a step without icon"
        output Boolean available "= true, if step is active and firing is possible" annotation(HideResult = true);
        input Boolean fire "= true, if transition fires and step is deactivated" annotation(HideResult = true);
        Node node "Communicates suspend/resume flags and is used to check the correct connection structure." annotation(HideResult = true);
        output Boolean checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition" annotation(__Dymola_BooleanLoopMessage = "
      Every loop of a StateGraph must have at least one delayed transition
      (an instance of Components.Transition with parameter delayedTransition = true)
      in order that infinite event looping cannot occur. Alternatively you can set
      checkLoop=false in the Advanced tab of the Transition, provided you are
      absolutely sure that this cannot happen.
        ", HideResult = true);
      end Step_out_base;

      connector Step_in  "Input port of a step"
        extends Step_in_base;
        annotation(defaultComponentName = "inPort", Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics = {Rectangle(extent = {{0, 0}, {0, 0}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 0, 0}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid), Text(extent = {{47, 58}, {112, 20}}, lineColor = {0, 0, 0}, textString = "%name")}));
      end Step_in;

      connector Step_out  "Output port of a step"
        extends Step_out_base;
        annotation(defaultComponentName = "outPort", Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics = {Polygon(points = {{-100, 100}, {0, -100}, {100, 100}, {-100, 100}}, lineColor = {0, 0, 0}, smooth = Smooth.None, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics = {Rectangle(extent = {{0, 0}, {0, 0}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-40, 100}, {0, 20}, {40, 100}, {-40, 100}}, lineColor = {0, 0, 0}, smooth = Smooth.None, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid), Text(extent = {{40, 66}, {116, 30}}, lineColor = {0, 0, 0}, textString = "%name")}));
      end Step_out;

      connector Transition_in_base  "Input port of a transition without an icon"
        input Boolean available "= true, if step connected to the transition input is active and firing is possible" annotation(HideResult = true);
        output Boolean fire "= true, if transition fires and the step connected to the transition input is deactivated" annotation(HideResult = true);
        Node node "Communicates suspend/resume flags and is used to check the correct connection structure." annotation(HideResult = true);
        input Boolean checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition" annotation(__Dymola_BooleanLoopMessage = "
      Every loop of a StateGraph must have at least one delayed transition
      (an instance of Components.Transition with parameter delayedTransition = true)
      in order that infinite event looping cannot occur. Alternatively you can set
      checkLoop=false in the Advanced tab of the Transition, provided you are
      absolutely sure that this cannot happen.
        ", HideResult = true);
      end Transition_in_base;

      connector Transition_out_base  "Output port of a transition without icon"
        output Boolean fire "true, if transition fires and step connected to the transition output becomes active" annotation(HideResult = true);
        Node node "Communicates suspend/resume flags and is used to check the correct connection structure." annotation(HideResult = true);
        input Boolean checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible" annotation(HideResult = true);
        output Boolean checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition" annotation(__Dymola_BooleanLoopMessage = "
      Every loop of a StateGraph must have at least one delayed transition
      (an instance of Components.Transition with parameter delayedTransition = true)
      in order that infinite event looping cannot occur. Alternatively you can set
      checkLoop=false in the Advanced tab of the Transition, provided you are
      absolutely sure that this cannot happen.
        ", HideResult = true);
      end Transition_out_base;

      connector Transition_in  "Input port of a transition"
        extends Transition_in_base;
        annotation(defaultComponentName = "inPort", Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics = {Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 0, 0}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid), Text(extent = {{51, 22}, {134, -16}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html>

      </html>"));
      end Transition_in;

      connector Transition_out  "Output port of a transition"
        extends Transition_out_base;
        annotation(defaultComponentName = "outPort", Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics = {Polygon(points = {{-100, 100}, {0, -100}, {100, 100}, {-100, 100}}, lineColor = {0, 0, 0}, smooth = Smooth.None, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics = {Polygon(points = {{-40, 100}, {0, 20}, {40, 100}, {-40, 100}}, lineColor = {0, 0, 0}, smooth = Smooth.None, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid), Text(extent = {{44, 100}, {138, 68}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html>

      </html>"));
      end Transition_out;
    end Interfaces;

    package Utilities  "Utility functions used to implement a Modelica_StateGraph2"
      function propagateLoopCheck  "Propagate flag to check loop"
        extends Modelica.Icons.Function;
        input Boolean[:] b;
        output Boolean result;
      protected
        Integer dummy;
      algorithm
        dummy := 0;
        result := true;
      end propagateLoopCheck;
    end Utilities;
  end Internal;
  annotation(uses(Modelica(version = "3.2.3")), Dymola(checkSum = "90067705:1029089882"), preferredView = "info", version = "2.0.3", versionBuild = 0, versionDate = "2016-03-11", dateModified = "2016-03-11 15:20:00Z", revisionId = "$Id:: package.mo 9594 2016-12-19 07:05:33Z #$", Documentation(info = "<html>
<p>
<img src=\"modelica://Modelica_StateGraph2/Resources/Images/StateGraph/UsersGuide/StateGraphElements.png\" align=\"right\">
Library <b>Modelica_StateGraph2</b> is a <b>free</b> Modelica package providing
components to model <b>discrete event</b>, <b>reactive</b> and
<b>hybrid</b> systems in a convenient way with <b>deterministic hierarchical state diagrams</b>.
For convenience, the abbreviation \"StateGraph2\" will be
often used for this library. An example model constructed with this
library is shown in the figure to the right.
</p>

<p>
This library is inspired by Grafcet/Sequential Function Charts (SFC), Statecharts,
Safe State Machines (SSM) and Mode Automata, and utilizes Modelica as action language.
It has a similar modeling power as
these formalisms, e.g. synchronization of parallel executing branches
as in SFC (not easy in Statecharts), or suspending a hierarchical subgraph with one
transition and resuming at the same states afterwards when entering it again, as in Statechart (not possible in SFC). A StateGraph2 model is always deterministic due to
Modelicas \"single assignment rule\". Via special blocks in subpackage \"Blocks\",
actions can be defined in a graphical way depending on the active step.
</p>

<p>
In order to construct a new state machine, exactly one instance of either \"Step\"
or of \"Parallel\" must have parameter \"initialStep = <b>true</b>\".
The \"Parallel\" component is both used as \"composite step\" (so only one branch),
as well as \"parallel step\" (so several execution branches). The branches can be
synchronized (if parameter use_outPort = <b>true</b>) or can run unsynchronized
to each other (if parameter use_outPort = <b>false</b>).
</p>

<p>
For an introduction, have especially a look at:
</p>

<ul>
<li><a href=\"modelica://Modelica_StateGraph2.UsersGuide.Tutorial\">Tutorial</a>
     provides an overview of the library inside the User's Guide.</li>
<li><a href=\"modelica://Modelica_StateGraph2.Examples\">Examples</a>
     provides simple introductory examples as well as involved application examples.</li>
<li> <a href=\"modelica://Modelica_StateGraph2.UsersGuide.ComparisonWithStateGraph1\">ComparisonWithStateGraph1</a>
     summarizes the enhancements with respect to the previous version of
     Modelica.StateGraph.</li>
</ul>

<p>
This library is implemented with Modelica 3.1 and utilizes non-standard extensions to Modelica 3.1 as summarized
<a href=\"modelica://Modelica_StateGraph2.UsersGuide.UsedModelicaExtensions\">here</a>.
</p>

<p>
<b>Licensed by DLR and Dynasim under the Modelica License 2</b><br>
Copyright &copy; 2003-2013, DLR and 2007-2009, Dynasim AB
</p>

<p>
<i>This Modelica package is <u>free</u> software and
the use is completely at <u>your own risk</u>;
it can be redistributed and/or modified under the terms of the
Modelica license 2, see the license conditions (including the
disclaimer of warranty)
<a href=\"modelica://Modelica_StateGraph2.UsersGuide.ModelicaLicense2\">here</a></u>
or at
<a href=\"http://www.Modelica.org/licenses/ModelicaLicense2\">
http://www.Modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

</html>"));
end Modelica_StateGraph2;

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine  "Machine dependent constants"
    extends Modelica.Icons.Package;
    final constant Real eps = 1e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1e60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    annotation(Documentation(info = "<html>
  <p>
  Package in which processor specific constants are defined that are needed
  by numerical algorithms. Typically these constants are not directly used,
  but indirectly via the alias definition in
  <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
  </p>
  </html>"));
  end Machine;
  annotation(preferredView = "info", version = "3.2.3", versionBuild = 3, versionDate = "2019-01-23", dateModified = "2019-09-21 12:00:00Z", revisionId = "$Format:%h %ci$", uses(Modelica(version = "3.2.3")), conversion(noneFromVersion = "1.0", noneFromVersion = "1.1", noneFromVersion = "1.2", noneFromVersion = "3.2.1", noneFromVersion = "3.2.2"), Documentation(info = "<html>
<p>
This package contains a set of functions and models to be used in the
Modelica Standard Library that requires a tool specific implementation.
These are:
</p>

<ul>
<li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Animation.Shape</a>
     provides a 3-dim. visualization of elementary
     mechanical objects. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Animation.Surface</a>
     provides a 3-dim. visualization of
     moveable parameterized surface. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">ExternalReferences.loadResource</a>
     provides a function to return the absolute path name of an URI or a local file name. It is used in
<a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Machine\">Machine</a>
     provides a package of machine constants. It is used in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

<li> <a href=\"modelica://ModelicaServices.System.exit\">System.exit</a> provides a function to terminate the execution of the Modelica environment. It is used in <a href=\"modelica://Modelica.Utilities.System.exit\">Modelica.Utilities.System.exit</a> via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
     provides a string defining the integration method to solve differential equations in
     a clocked discretized continuous-time partition (see Modelica 3.3 language specification).
     It is not yet used in the Modelica Standard Library, but in the Modelica_Synchronous library
     that provides convenience blocks for the clock operators of Modelica version &ge; 3.3.</li>
</ul>

<p>
This is the default implementation, if no tool-specific implementation is available.
This ModelicaServices package provides only \"dummy\" models that do nothing.
</p>

<p>
<strong>Licensed by the Modelica Association under the 3-Clause BSD License</strong><br>
Copyright &copy; 2009-2019, Modelica Association and contributors
</p>

<p>
<em>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the 3-Clause BSD license. For license conditions (including the disclaimer of warranty) visit <a href=\"https://modelica.org/licenses/modelica-3-clause-bsd\">https://modelica.org/licenses/modelica-3-clause-bsd</a>.</em>
</p>

</html>"));
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.3"
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector" annotation(defaultComponentName = "u", Icon(graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}, coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}, preserveAspectRatio = true, initialScale = 0.2)), Diagram(coordinateSystem(preserveAspectRatio = true, initialScale = 0.2, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid, points = {{0.0, 50.0}, {100.0, 0.0}, {0.0, -50.0}, {0.0, 50.0}}), Text(lineColor = {0, 0, 127}, extent = {{-10.0, 60.0}, {-10.0, 85.0}}, textString = "%name")}), Documentation(info = "<html>
      <p>
      Connector with one input signal of type Real.
      </p>
      </html>"));
      connector RealOutput = output Real "'output Real' as connector" annotation(defaultComponentName = "y", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 50.0}, {0.0, 0.0}, {-100.0, -50.0}}), Text(lineColor = {0, 0, 127}, extent = {{30.0, 60.0}, {30.0, 110.0}}, textString = "%name")}), Documentation(info = "<html>
      <p>
      Connector with one output signal of type Real.
      </p>
      </html>"));
      connector BooleanInput = input Boolean "'input Boolean' as connector" annotation(defaultComponentName = "u", Icon(graphics = {Polygon(points = {{-100, 100}, {100, 0}, {-100, -100}, {-100, 100}}, lineColor = {255, 0, 255}, fillColor = {255, 0, 255}, fillPattern = FillPattern.Solid)}, coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.2)), Diagram(coordinateSystem(preserveAspectRatio = true, initialScale = 0.2, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{0, 50}, {100, 0}, {0, -50}, {0, 50}}, lineColor = {255, 0, 255}, fillColor = {255, 0, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-10, 85}, {-10, 60}}, lineColor = {255, 0, 255}, textString = "%name")}), Documentation(info = "<html>
      <p>
      Connector with one input signal of type Boolean.
      </p>
      </html>"));
      connector BooleanOutput = output Boolean "'output Boolean' as connector" annotation(defaultComponentName = "y", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-100, 100}, {100, 0}, {-100, -100}, {-100, 100}}, lineColor = {255, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-100, 50}, {0, 0}, {-100, -50}, {-100, 50}}, lineColor = {255, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{30, 110}, {30, 60}}, lineColor = {255, 0, 255}, textString = "%name")}), Documentation(info = "<html>
      <p>
      Connector with one output signal of type Boolean.
      </p>
      </html>"));

      partial block MO  "Multiple Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        parameter Integer nout(min = 1) = 1 "Number of outputs";
        RealOutput[nout] y "Connector of Real output signals" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
        annotation(Documentation(info = "<html>
      <p>
      Block has one continuous Real output signal vector.
      </p>
      </html>"));
      end MO;

      partial block partialBooleanSISO  "Partial block with 1 input and 1 output Boolean signal"
        extends Modelica.Blocks.Icons.PartialBooleanBlock;
        Blocks.Interfaces.BooleanInput u "Connector of Boolean input signal" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
        Blocks.Interfaces.BooleanOutput y "Connector of Boolean output signal" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-71, 7}, {-85, -7}}, lineColor = DynamicSelect({235, 235, 235}, if u then {0, 255, 0} else {235, 235, 235}), fillColor = DynamicSelect({235, 235, 235}, if u then {0, 255, 0} else {235, 235, 235}), fillPattern = FillPattern.Solid), Ellipse(extent = {{71, 7}, {85, -7}}, lineColor = DynamicSelect({235, 235, 235}, if y then {0, 255, 0} else {235, 235, 235}), fillColor = DynamicSelect({235, 235, 235}, if y then {0, 255, 0} else {235, 235, 235}), fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
      <p>
      Block has one continuous Boolean input and one continuous Boolean output signal
      with a 3D icon (e.g., used in Blocks.Logical library).
      </p>
      </html>"));
      end partialBooleanSISO;

      partial block partialBooleanSO  "Partial block with 1 output Boolean signal"
        Blocks.Interfaces.BooleanOutput y "Connector of Boolean output signal" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
        extends Modelica.Blocks.Icons.PartialBooleanBlock;
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{71, 7}, {85, -7}}, lineColor = DynamicSelect({235, 235, 235}, if y then {0, 255, 0} else {235, 235, 235}), fillColor = DynamicSelect({235, 235, 235}, if y then {0, 255, 0} else {235, 235, 235}), fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
      <p>
      Block has one continuous Boolean output signal
      with a 3D icon (e.g., used in Blocks.Logical library).
      </p>
      </html>"));
      end partialBooleanSO;
      annotation(Documentation(info = "<html>
    <p>
    This package contains interface definitions for
    <strong>continuous</strong> input/output blocks with Real,
    Integer and Boolean signals. Furthermore, it contains
    partial models for continuous and discrete blocks.
    </p>

    </html>", revisions = "<html>
    <ul>
    <li><em>Oct. 21, 2002</em>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
           and Christian Schweiger:<br>
           Added several new interfaces.</li>
    <li><em>Oct. 24, 1999</em>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           RealInputSignal renamed to RealInput. RealOutputSignal renamed to
           output RealOutput. GraphBlock renamed to BlockIcon. SISOreal renamed to
           SISO. SOreal renamed to SO. I2SOreal renamed to M2SO.
           SignalGenerator renamed to SignalSource. Introduced the following
           new models: MIMO, MIMOs, SVcontrol, MVcontrol, DiscreteBlockIcon,
           DiscreteBlock, DiscreteSISO, DiscreteMIMO, DiscreteMIMOs,
           BooleanBlockIcon, BooleanSISO, BooleanSignalSource, MI2BooleanMOs.</li>
    <li><em>June 30, 1999</em>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           Realized a first version, based on an existing Dymola library
           of Dieter Moormann and Hilding Elmqvist.</li>
    </ul>
    </html>"));
    end Interfaces;

    package Logical  "Library of components with Boolean input and output signals"
      extends Modelica.Icons.Package;

      block Not  "Logical 'not': y = not u"
        extends Blocks.Interfaces.partialBooleanSISO;
      equation
        y = not u;
        annotation(defaultComponentName = "not1", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-90, 40}, {90, -40}}, textString = "not")}), Documentation(info = "<html>
      <p>
      The output is <strong>true</strong> if the input is <strong>false</strong>, otherwise
      the output is <strong>false</strong>.
      </p>
      </html>"));
      end Not;
      annotation(Documentation(info = "<html>
    <p>
    This package provides blocks with Boolean input and output signals
    to describe logical networks. A typical example for a logical
    network built with package Logical is shown in the next figure:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Blocks/LogicalNetwork1.png\"
         alt=\"LogicalNetwork1.png\">
    </p>

    <p>
    The actual value of Boolean input and/or output signals is displayed
    in the respective block icon as \"circle\", where \"white\" color means
    value <strong>false</strong> and \"green\" color means value <strong>true</strong>. These
    values are visualized in a diagram animation.
    </p>
    </html>"), Icon(graphics = {Line(points = {{-86, -22}, {-50, -22}, {-50, 22}, {48, 22}, {48, -22}, {88, -24}}, color = {255, 0, 255})}));
    end Logical;

    package Math  "Library of Real mathematical functions as input/output blocks"
      extends Modelica.Icons.Package;

      block RealToBoolean  "Convert Real to Boolean signal"
        Blocks.Interfaces.RealInput u "Connector of Real input signal" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
        extends .Modelica.Blocks.Interfaces.partialBooleanSO;
        parameter Real threshold = 0.5 "Output signal y is true, if input u >= threshold";
      equation
        y = u >= threshold;
        annotation(Documentation(info = "<html>
      <p>
      This block computes the Boolean output <strong>y</strong>
      from the Real input <strong>u</strong> by the equation:
      </p>

      <pre>    y = u &ge; threshold;
      </pre>

      <p>
      where <strong>threshold</strong> is a parameter.
      </p>
      </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-86, 92}, {-6, 10}}, lineColor = {0, 0, 127}, textString = "R"), Polygon(points = {{-12, -46}, {-32, -26}, {-32, -36}, {-64, -36}, {-64, -56}, {-32, -56}, {-32, -66}, {-12, -46}}, lineColor = {255, 0, 255}, fillColor = {255, 0, 255}, fillPattern = FillPattern.Solid), Text(extent = {{8, -4}, {92, -94}}, lineColor = {255, 0, 255}, textString = "B")}));
      end RealToBoolean;
      annotation(Documentation(info = "<html>
    <p>
    This package contains basic <strong>mathematical operations</strong>,
    such as summation and multiplication, and basic <strong>mathematical
    functions</strong>, such as <strong>sqrt</strong> and <strong>sin</strong>, as
    input/output blocks. All blocks of this library can be either
    connected with continuous blocks or with sampled-data blocks.
    </p>
    </html>", revisions = "<html>
    <ul>
    <li><em>August 24, 2016</em>
           by Christian Kral: added WrapAngle</li>
    <li><em>October 21, 2002</em>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
           and Christian Schweiger:<br>
           New blocks added: RealToInteger, IntegerToReal, Max, Min, Edge, BooleanChange, IntegerChange.</li>
    <li><em>August 7, 1999</em>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           Realized (partly based on an existing Dymola library
           of Dieter Moormann and Hilding Elmqvist).
    </li>
    </ul>
    </html>"), Icon(graphics = {Line(points = {{-80, -2}, {-68.7, 32.2}, {-61.5, 51.1}, {-55.1, 64.4}, {-49.4, 72.6}, {-43.8, 77.1}, {-38.2, 77.8}, {-32.6, 74.6}, {-26.9, 67.7}, {-21.3, 57.4}, {-14.9, 42.1}, {-6.83, 19.2}, {10.1, -32.8}, {17.3, -52.2}, {23.7, -66.2}, {29.3, -75.1}, {35, -80.4}, {40.6, -82}, {46.2, -79.6}, {51.9, -73.5}, {57.5, -63.9}, {63.9, -49.2}, {72, -26.8}, {80, -2}}, color = {95, 95, 95}, smooth = Smooth.Bezier)}));
    end Math;

    package Sources  "Library of signal source blocks generating Real, Integer and Boolean signals"
      extends Modelica.Icons.SourcesPackage;

      block CombiTimeTable  "Table look-up with respect to time and linear/periodic extrapolation methods (data from matrix/file)"
        extends Modelica.Blocks.Interfaces.MO(final nout = max([size(columns, 1); size(offset, 1)]));
        parameter Boolean tableOnFile = false "= true, if table is defined on file or in function usertab" annotation(Dialog(group = "Table data definition"));
        parameter Real[:, :] table = fill(0.0, 0, 2) "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])" annotation(Dialog(group = "Table data definition", enable = not tableOnFile));
        parameter String tableName = "NoName" "Table name on file or in function usertab (see docu)" annotation(Dialog(group = "Table data definition", enable = tableOnFile));
        parameter String fileName = "NoName" "File where matrix is stored" annotation(Dialog(group = "Table data definition", enable = tableOnFile, loadSelector(filter = "Text files (*.txt);;MATLAB MAT-files (*.mat)", caption = "Open file in which table is present")));
        parameter Boolean verboseRead = true "= true, if info message that file is loading is to be printed" annotation(Dialog(group = "Table data definition", enable = tableOnFile));
        parameter Integer[:] columns = 2:size(table, 2) "Columns of table to be interpolated" annotation(Dialog(group = "Table data interpretation", groupImage = "modelica://Modelica/Resources/Images/Blocks/Sources/CombiTimeTable.png"));
        parameter Modelica.Blocks.Types.Smoothness smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments "Smoothness of table interpolation" annotation(Dialog(group = "Table data interpretation"));
        parameter Modelica.Blocks.Types.Extrapolation extrapolation = Modelica.Blocks.Types.Extrapolation.LastTwoPoints "Extrapolation of data outside the definition range" annotation(Dialog(group = "Table data interpretation"));
        parameter Modelica.SIunits.Time timeScale(min = Modelica.Constants.eps) = 1 "Time scale of first table column" annotation(Dialog(group = "Table data interpretation"), Evaluate = true);
        parameter Real[:] offset = {0} "Offsets of output signals" annotation(Dialog(group = "Table data interpretation"));
        parameter Modelica.SIunits.Time startTime = 0 "Output = offset for time < startTime" annotation(Dialog(group = "Table data interpretation"));
        parameter Modelica.SIunits.Time shiftTime = startTime "Shift time of first table column" annotation(Dialog(group = "Table data interpretation"));
        parameter Modelica.Blocks.Types.TimeEvents timeEvents = Modelica.Blocks.Types.TimeEvents.Always "Time event handling of table interpolation" annotation(Dialog(group = "Table data interpretation", enable = smoothness == Modelica.Blocks.Types.Smoothness.LinearSegments));
        parameter Boolean verboseExtrapolation = false "= true, if warning messages are to be printed if time is outside the table definition range" annotation(Dialog(group = "Table data interpretation", enable = extrapolation == Modelica.Blocks.Types.Extrapolation.LastTwoPoints or extrapolation == Modelica.Blocks.Types.Extrapolation.HoldLastPoint));
        final parameter Modelica.SIunits.Time t_min = t_minScaled * timeScale "Minimum abscissa value defined in table";
        final parameter Modelica.SIunits.Time t_max = t_maxScaled * timeScale "Maximum abscissa value defined in table";
        final parameter Real t_minScaled = .Modelica.Blocks.Tables.Internal.getTimeTableTmin(tableID) "Minimum (scaled) abscissa value defined in table";
        final parameter Real t_maxScaled = .Modelica.Blocks.Tables.Internal.getTimeTableTmax(tableID) "Maximum (scaled) abscissa value defined in table";
      protected
        final parameter Real[nout] p_offset = if size(offset, 1) == 1 then ones(nout) * offset[1] else offset "Offsets of output signals";
        parameter Modelica.Blocks.Types.ExternalCombiTimeTable tableID = Modelica.Blocks.Types.ExternalCombiTimeTable(if tableOnFile then tableName else "NoName", if tableOnFile and fileName <> "NoName" and not Modelica.Utilities.Strings.isEmpty(fileName) then fileName else "NoName", table, startTime / timeScale, columns, smoothness, extrapolation, shiftTime / timeScale, if smoothness == Modelica.Blocks.Types.Smoothness.LinearSegments then timeEvents elseif smoothness == Modelica.Blocks.Types.Smoothness.ConstantSegments then Modelica.Blocks.Types.TimeEvents.Always else Modelica.Blocks.Types.TimeEvents.NoTimeEvents, if tableOnFile then verboseRead else false) "External table object";
        discrete Modelica.SIunits.Time nextTimeEvent(start = 0, fixed = true) "Next time event instant";
        discrete Real nextTimeEventScaled(start = 0, fixed = true) "Next scaled time event instant";
        Real timeScaled "Scaled time";
      equation
        if tableOnFile then
          assert(tableName <> "NoName", "tableOnFile = true and no table name given");
        else
          assert(size(table, 1) > 0 and size(table, 2) > 0, "tableOnFile = false and parameter table is an empty matrix");
        end if;
        if verboseExtrapolation and (extrapolation == Modelica.Blocks.Types.Extrapolation.LastTwoPoints or extrapolation == Modelica.Blocks.Types.Extrapolation.HoldLastPoint) then
          assert(noEvent(time >= t_min), "
      Extrapolation warning: Time (=" + String(time) + ") must be greater or equal
      than the minimum abscissa value t_min (=" + String(t_min) + ") defined in the table.
          ", AssertionLevel.warning);
          assert(noEvent(time <= t_max), "
      Extrapolation warning: Time (=" + String(time) + ") must be less or equal
      than the maximum abscissa value t_max (=" + String(t_max) + ") defined in the table.
          ", AssertionLevel.warning);
        end if;
        timeScaled = time / timeScale;
        when {time >= pre(nextTimeEvent), initial()} then
          nextTimeEventScaled = .Modelica.Blocks.Tables.Internal.getNextTimeEvent(tableID, timeScaled);
          nextTimeEvent = if nextTimeEventScaled < Modelica.Constants.inf then nextTimeEventScaled * timeScale else Modelica.Constants.inf;
        end when;
        if smoothness == Modelica.Blocks.Types.Smoothness.ConstantSegments then
          for i in 1:nout loop
            y[i] = p_offset[i] + .Modelica.Blocks.Tables.Internal.getTimeTableValueNoDer(tableID, i, timeScaled, nextTimeEventScaled, pre(nextTimeEventScaled));
          end for;
        else
          for i in 1:nout loop
            y[i] = p_offset[i] + .Modelica.Blocks.Tables.Internal.getTimeTableValue(tableID, i, timeScaled, nextTimeEventScaled, pre(nextTimeEventScaled));
          end for;
        end if;
        annotation(Documentation(info = "<html>
      <p>
      This block generates an output signal y[:] by <strong>constant</strong>,
      <strong>linear</strong> or <strong>cubic Hermite spline interpolation</strong>
      in a table. The time points and function values are stored in a matrix
      <strong>table[i,j]</strong>, where the first column table[:,1] contains the
      time points and the other columns contain the data to be interpolated.
      </p>

      <p>
      <img src=\"modelica://Modelica/Resources/Images/Blocks/Sources/CombiTimeTable.png\"
           alt=\"CombiTimeTable.png\">
      </p>

      <p>
      Via parameter <strong>columns</strong> it can be defined which columns of the
      table are interpolated. If, e.g., columns={2,4}, it is assumed that
      2 output signals are present and that the first output is computed
      by interpolation of column 2 and the second output is computed
      by interpolation of column 4 of the table matrix.
      The table interpolation has the following properties:
      </p>
      <ul>
      <li>The interpolation interval is found by a binary search where the interval used in the
          last call is used as start interval.</li>
      <li>The time points need to be <strong>strictly increasing</strong> for cubic Hermite
          spline interpolation, otherwise <strong>monotonically increasing</strong>.</li>
      <li><strong>Discontinuities</strong> are allowed for (constant or) linear interpolation,
          by providing the same time point twice in the table.</li>
      <li>Via parameter <strong>smoothness</strong> it is defined how the data is interpolated:
      <pre>
        smoothness = 1: Linear interpolation
                   = 2: Akima interpolation: Smooth interpolation by cubic Hermite
                        splines such that der(y) is continuous, also if extrapolated.
                   = 3: Constant segments
                   = 4: Fritsch-Butland interpolation: Smooth interpolation by cubic
                        Hermite splines such that y preserves the monotonicity and
                        der(y) is continuous, also if extrapolated.
                   = 5: Steffen interpolation: Smooth interpolation by cubic Hermite
                        splines such that y preserves the monotonicity and der(y)
                        is continuous, also if extrapolated.
      </pre></li>
      <li>Values <strong>outside</strong> of the table range, are computed by
          extrapolation according to the setting of parameter <strong>extrapolation</strong>:
      <pre>
        extrapolation = 1: Hold the first or last value of the table,
                           if outside of the table scope.
                      = 2: Extrapolate by using the derivative at the first/last table
                           points if outside of the table scope.
                           (If smoothness is LinearSegments or ConstantSegments
                           this means to extrapolate linearly through the first/last
                           two table points.).
                      = 3: Periodically repeat the table data (periodical function).
                      = 4: No extrapolation, i.e. extrapolation triggers an error
      </pre></li>
      <li>If the table has only <strong>one row</strong>, no interpolation is performed and
          the table values of this row are just returned.</li>
      <li>Via parameters <strong>shiftTime</strong> and <strong>offset</strong> the curve defined
          by the table can be shifted both in time and in the ordinate value.
          The time instants stored in the table are therefore <strong>relative</strong>
          to <strong>shiftTime</strong>.</li>
      <li>If time &lt; startTime, no interpolation is performed and the offset
          is used as ordinate value for all outputs.</li>
      <li>The table is implemented in a numerically sound way by
          generating <strong>time events</strong> at interval boundaries, in case of
          interpolation by linear segments.
          This generates continuously differentiable values for the integrator.
          Via parameter <strong>timeEvents</strong> it is defined how the time events are generated:
      <pre>
        timeEvents = 1: Always generate time events at interval boundaries
                   = 2: Generate time events at discontinuities (defined by duplicated sample points)
                   = 3: No time events at interval boundaries
      </pre>
          For interpolation by constant segments time events are always generated at interval boundaries.
          For smooth interpolation by cubic Hermite splines no time events are generated at interval boundaries.</li>
      <li>Via parameter <strong>timeScale</strong> the first column of the table array can
          be scaled, e.g., if the table array is given in hours (instead of seconds)
          <strong>timeScale</strong> shall be set to 3600.</li>
      <li>For special applications it is sometimes needed to know the minimum
          and maximum time instant defined in the table as a parameter. For this
          reason parameters <strong>t_min</strong>/<strong>t_minScaled</strong> and
          <strong>t_max</strong>/<strong>t_maxScaled</strong> are provided and can be
          accessed from the outside of the table object. Whereas <strong>t_min</strong> and
          <strong>t_max</strong> define the scaled abscissa values (using parameter
          <strong>timeScale</strong>) in SIunits.Time, <strong>t_minScaled</strong> and
          <strong>t_maxScaled</strong> define the unitless original abscissa values of
          the table.</li>
      </ul>
      <p>
      Example:
      </p>
      <pre>
         table = [0, 0;
                  1, 0;
                  1, 1;
                  2, 4;
                  3, 9;
                  4, 16];
         extrapolation = 2 (default), timeEvents = 2
      If, e.g., time = 1.0, the output y =  0.0 (before event), 1.0 (after event)
          e.g., time = 1.5, the output y =  2.5,
          e.g., time = 2.0, the output y =  4.0,
          e.g., time = 5.0, the output y = 23.0 (i.e., extrapolation via last 2 points).
      </pre>
      <p>
      The table matrix can be defined in the following ways:
      </p>
      <ol>
      <li>Explicitly supplied as <strong>parameter matrix</strong> \"table\",
          and the other parameters have the following values:
      <pre>
         tableName is \"NoName\" or has only blanks,
         fileName  is \"NoName\" or has only blanks.
      </pre></li>
      <li><strong>Read</strong> from a <strong>file</strong> \"fileName\" where the matrix is stored as
          \"tableName\". Both text and MATLAB MAT-file format is possible.
          (The text format is described below).
          The MAT-file format comes in four different versions: v4, v6, v7 and v7.3.
          The library supports at least v4, v6 and v7 whereas v7.3 is optional.
          It is most convenient to generate the MAT-file from FreeMat or MATLAB&reg;
          by command
      <pre>
         save tables.mat tab1 tab2 tab3
      </pre>
          or Scilab by command
      <pre>
         savematfile tables.mat tab1 tab2 tab3
      </pre>
          when the three tables tab1, tab2, tab3 should be used from the model.<br>
          Note, a fileName can be defined as URI by using the helper function
          <a href=\"modelica://Modelica.Utilities.Files.loadResource\">loadResource</a>.</li>
      <li>Statically stored in function \"usertab\" in file \"usertab.c\".
          The matrix is identified by \"tableName\". Parameter
          fileName = \"NoName\" or has only blanks. Row-wise storage is always to be
          preferred as otherwise the table is reallocated and transposed.</li>
      </ol>
      <p>
      When the constant \"NO_FILE_SYSTEM\" is defined, all file I/O related parts of the
      source code are removed by the C-preprocessor, such that no access to files takes place.
      </p>
      <p>
      If tables are read from a text file, the file needs to have the
      following structure (\"-----\" is not part of the file content):
      </p>
      <pre>
      -----------------------------------------------------
      #1
      double tab1(6,2)   # comment line
        0   0
        1   0
        1   1
        2   4
        3   9
        4  16
      double tab2(6,2)   # another comment line
        0   0
        2   0
        2   2
        4   8
        6  18
        8  32
      -----------------------------------------------------
      </pre>
      <p>
      Note, that the first two characters in the file need to be
      \"#1\" (a line comment defining the version number of the file format).
      Afterwards, the corresponding matrix has to be declared
      with type (= \"double\" or \"float\"), name and actual dimensions.
      Finally, in successive rows of the file, the elements of the matrix
      have to be given. The elements have to be provided as a sequence of
      numbers in row-wise order (therefore a matrix row can span several
      lines in the file and need not start at the beginning of a line).
      Numbers have to be given according to C syntax (such as 2.3, -2, +2.e4).
      Number separators are spaces, tab (\\t), comma (,), or semicolon (;).
      Several matrices may be defined one after another. Line comments start
      with the hash symbol (#) and can appear everywhere.
      Text files should either be ASCII or UTF-8 encoded, where UTF-8 encoded strings are only allowed in line comments and an optional UTF-8 BOM at the start of the text file is ignored.
      Other characters, like trailing non comments, are not allowed in the file.
      </p>
      <p>
      MATLAB is a registered trademark of The MathWorks, Inc.
      </p>
      </html>", revisions = "<html>
      <p><strong>Release Notes:</strong></p>
      <ul>
      <li><em>April 09, 2013</em>
             by Thomas Beutlich:<br>
             Implemented as external object.</li>
      <li><em>March 31, 2001</em>
             by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
             Used CombiTableTime as a basis and added the
             arguments <strong>extrapolation, columns, startTime</strong>.
             This allows periodic function definitions.</li>
      </ul>
      </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{-80.0, 90.0}, {-88.0, 68.0}, {-72.0, 68.0}, {-80.0, 90.0}}), Line(points = {{-80.0, 68.0}, {-80.0, -80.0}}, color = {192, 192, 192}), Line(points = {{-90.0, -70.0}, {82.0, -70.0}}, color = {192, 192, 192}), Polygon(lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{90.0, -70.0}, {68.0, -62.0}, {68.0, -78.0}, {90.0, -70.0}}), Rectangle(lineColor = {255, 255, 255}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-48.0, -50.0}, {2.0, 70.0}}), Line(points = {{-48.0, -50.0}, {-48.0, 70.0}, {52.0, 70.0}, {52.0, -50.0}, {-48.0, -50.0}, {-48.0, -20.0}, {52.0, -20.0}, {52.0, 10.0}, {-48.0, 10.0}, {-48.0, 40.0}, {52.0, 40.0}, {52.0, 70.0}, {2.0, 70.0}, {2.0, -51.0}})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 68}, {-80, -80}}, color = {95, 95, 95}), Line(points = {{-90, -70}, {82, -70}}, color = {95, 95, 95}), Polygon(points = {{90, -70}, {68, -62}, {68, -78}, {90, -70}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-20, 90}, {20, -30}}, lineColor = {255, 255, 255}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-20, -30}, {-20, 90}, {80, 90}, {80, -30}, {-20, -30}, {-20, 0}, {80, 0}, {80, 30}, {-20, 30}, {-20, 60}, {80, 60}, {80, 90}, {20, 90}, {20, -30}}), Text(extent = {{-71, -42}, {-32, -54}}, textString = "offset"), Polygon(points = {{-31, -30}, {-33, -40}, {-28, -40}, {-31, -30}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Polygon(points = {{-31, -70}, {-34, -60}, {-29, -60}, {-31, -70}, {-31, -70}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-31, -31}, {-31, -70}}, color = {95, 95, 95}), Line(points = {{-20, -30}, {-20, -70}}, color = {95, 95, 95}), Text(extent = {{-42, -74}, {6, -84}}, textString = "startTime"), Line(points = {{-20, -30}, {-80, -30}}, color = {95, 95, 95}), Text(extent = {{-73, 93}, {-44, 74}}, textString = "y"), Text(extent = {{66, -81}, {92, -92}}, textString = "time"), Text(extent = {{-19, 83}, {20, 68}}, textString = "time"), Text(extent = {{21, 82}, {50, 68}}, textString = "y[1]"), Line(points = {{50, 90}, {50, -30}}), Line(points = {{80, 0}, {100, 0}}, color = {0, 0, 255}), Text(extent = {{34, -30}, {71, -42}}, textString = "columns", lineColor = {0, 0, 255}), Text(extent = {{51, 82}, {80, 68}}, textString = "y[2]")}));
      end CombiTimeTable;

      block BooleanTable  "Generate a Boolean output signal based on a vector of time instants"
        parameter Modelica.SIunits.Time[:] table = {0, 1} "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})" annotation(Dialog(group = "Table data definition"));
        parameter Boolean startValue = false "Start value of y. At time = table[1], y changes to 'not startValue'" annotation(Dialog(group = "Table data interpretation", groupImage = "modelica://Modelica/Resources/Images/Blocks/Sources/BooleanTable.png"));
        parameter Modelica.Blocks.Types.Extrapolation extrapolation = Modelica.Blocks.Types.Extrapolation.HoldLastPoint "Extrapolation of data outside the definition range" annotation(Dialog(group = "Table data interpretation"));
        parameter Modelica.SIunits.Time startTime = -Modelica.Constants.inf "Output = false for time < startTime" annotation(Dialog(group = "Table data interpretation"));
        parameter Modelica.SIunits.Time shiftTime = 0 "Shift time of table" annotation(Dialog(group = "Table data interpretation"));
        extends .Modelica.Blocks.Interfaces.partialBooleanSO;
        CombiTimeTable combiTimeTable(final table = if n > 0 then if startValue then [table[1], 1.0; table, {mod(i + 1, 2.0) for i in 1:n}] else [table[1], 0.0; table, {mod(i, 2.0) for i in 1:n}] else if startValue then [0.0, 1.0] else [0.0, 0.0], final smoothness = Modelica.Blocks.Types.Smoothness.ConstantSegments, final columns = {2}, final extrapolation = extrapolation, final startTime = startTime, final shiftTime = shiftTime) annotation(Placement(transformation(extent = {{-30, -10}, {-10, 10}})));
        Modelica.Blocks.Math.RealToBoolean realToBoolean annotation(Placement(transformation(extent = {{10, -10}, {30, 10}})));

      protected
        function isValidTable  "Check if table is valid"
          extends Modelica.Icons.Function;
          input Real[:] table "Vector of time instants";
        protected
          Integer n = size(table, 1) "Number of table points";
        algorithm
          if n > 0 then
            for i in 2:n loop
              assert(table[i] > table[i - 1], "Time values of table not strict monotonically increasing: table[" + String(i - 1) + "] = " + String(table[i - 1]) + ", table[" + String(i) + "] = " + String(table[i]));
            end for;
          else
          end if;
        end isValidTable;

        parameter Integer n = size(table, 1) "Number of table points";
      initial algorithm
        isValidTable(table);
      equation
        assert(extrapolation <> Modelica.Blocks.Types.Extrapolation.LastTwoPoints, "Unsuitable extrapolation setting.");
        connect(combiTimeTable.y[1], realToBoolean.u) annotation(Line(points = {{-9, 0}, {8, 0}}, color = {0, 0, 127}));
        connect(realToBoolean.y, y) annotation(Line(points = {{31, 0}, {110, 0}, {110, 0}}, color = {255, 127, 0}));
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-80, 88}, {-88, 66}, {-72, 66}, {-80, 88}}, lineColor = {255, 0, 255}, fillColor = {255, 0, 255}, fillPattern = FillPattern.Solid), Line(points = {{-80, 66}, {-80, -82}}, color = {255, 0, 255}), Line(points = {{-90, -70}, {72, -70}}, color = {255, 0, 255}), Polygon(points = {{90, -70}, {68, -62}, {68, -78}, {90, -70}}, lineColor = {255, 0, 255}, fillColor = {255, 0, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-18, 70}, {32, -50}}, lineColor = {255, 255, 255}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-18, -50}, {-18, 70}, {32, 70}, {32, -50}, {-18, -50}, {-18, -20}, {32, -20}, {32, 10}, {-18, 10}, {-18, 40}, {32, 40}, {32, 70}, {32, 70}, {32, -51}})}), Documentation(info = "<html>
      <p>
      The Boolean output y is a signal defined by parameter vector <strong>table</strong>.
      In the vector time points are stored.
      The table interpolation has the following properties:
      </p>

      <ul>
      <li>At every time point, the output y
          changes its value to the negated value of the previous one.</li>
      <li>Values <strong>outside</strong> of the table range, are computed by
          extrapolation according to the setting of parameter <strong>extrapolation</strong>:
      <pre>
        extrapolation = 1: Hold the <strong>startValue</strong> or last value of the table,
                           if outside of the table scope.
                      = 2: Extrapolate by using the derivative at the first/last table
                           points if outside of the table scope.
                           (This setting is not suitable and triggers an assert.)
                      = 3: Periodically repeat the table data (periodical function).
                      = 4: No extrapolation, i.e. extrapolation triggers an error
      </pre></li>
      <li>Via parameter <strong>shiftTime</strong> the curve defined by the table can be shifted
          in time.
          The time instants stored in the table are therefore <strong>relative</strong>
          to <strong>shiftTime</strong>.</li>
      <li>If time &lt; startTime, no interpolation is performed and <strong>false</strong>
          is used as ordinate value for the output.</li>
      </ul>

      <p>
      <img src=\"modelica://Modelica/Resources/Images/Blocks/Sources/BooleanTable.png\"
           alt=\"BooleanTable.png\">
      </p>

      <p>
      The precise semantics is:
      </p>

      <pre>
        <strong>if</strong> size(table,1) == 0 <strong>then</strong>
           y = startValue;
        <strong>else</strong>
           //            time &lt; table[1]: y = startValue
           // table[1] &le; time &lt; table[2]: y = not startValue
           // table[2] &le; time &lt; table[3]: y = startValue
           // table[3] &le; time &lt; table[4]: y = not startValue
           // ...
        <strong>end if</strong>;
      </pre>
      </html>"));
      end BooleanTable;
      annotation(Documentation(info = "<html>
    <p>
    This package contains <strong>source</strong> components, i.e., blocks which
    have only output signals. These blocks are used as signal generators
    for Real, Integer and Boolean signals.
    </p>

    <p>
    All Real source signals (with the exception of the Constant source)
    have at least the following two parameters:
    </p>

    <table border=1 cellspacing=0 cellpadding=2>
      <tr><td><strong>offset</strong></td>
          <td>Value which is added to the signal</td>
      </tr>
      <tr><td><strong>startTime</strong></td>
          <td>Start time of signal. For time &lt; startTime,
                    the output y is set to offset.</td>
      </tr>
    </table>

    <p>
    The <strong>offset</strong> parameter is especially useful in order to shift
    the corresponding source, such that at initial time the system
    is stationary. To determine the corresponding value of offset,
    usually requires a trimming calculation.
    </p>
    </html>", revisions = "<html>
    <ul>
    <li><em>October 21, 2002</em>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
           and Christian Schweiger:<br>
           Integer sources added. Step, TimeTable and BooleanStep slightly changed.</li>
    <li><em>Nov. 8, 1999</em>
           by <a href=\"mailto:christoph@clauss-it.com\">Christoph Clau&szlig;</a>,
           <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
           <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
           (nperiod=-1 is an infinite number of periods).</li>
    <li><em>Oct. 31, 1999</em>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           <a href=\"mailto:christoph@clauss-it.com\">Christoph Clau&szlig;</a>,
           <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
           All sources vectorized. New sources: ExpSine, Trapezoid,
           BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
           Improved documentation, especially detailed description of
           signals in diagram layer.</li>
    <li><em>June 29, 1999</em>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           Realized a first version, based on an existing Dymola library
           of Dieter Moormann and Hilding Elmqvist.</li>
    </ul>
    </html>"));
    end Sources;

    package Tables  "Library of blocks to interpolate in one and two-dimensional tables"
      extends Modelica.Icons.Package;

      package Internal  "Internal external object definitions for table functions that should not be directly utilized by the user"
        extends Modelica.Icons.InternalPackage;

        function getTimeTableValue  "Interpolate 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Integer icol;
          input Real timeIn;
          discrete input Real nextTimeEvent;
          discrete input Real pre_nextTimeEvent;
          output Real y;
          external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent) annotation(Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"}, derivative(noDerivative = nextTimeEvent, noDerivative = pre_nextTimeEvent) = getDerTimeTableValue);
          annotation(derivative(noDerivative = nextTimeEvent, noDerivative = pre_nextTimeEvent) = getDerTimeTableValue);
        end getTimeTableValue;

        function getTimeTableValueNoDer  "Interpolate 1-dim. table where first column is time (but do not provide a derivative function)"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Integer icol;
          input Real timeIn;
          discrete input Real nextTimeEvent;
          discrete input Real pre_nextTimeEvent;
          output Real y;
          external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent) annotation(Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getTimeTableValueNoDer;

        function getDerTimeTableValue  "Derivative of interpolated 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Integer icol;
          input Real timeIn;
          discrete input Real nextTimeEvent;
          discrete input Real pre_nextTimeEvent;
          input Real der_timeIn;
          output Real der_y;
          external "C" der_y = ModelicaStandardTables_CombiTimeTable_getDerValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent, der_timeIn) annotation(Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getDerTimeTableValue;

        function getTimeTableTmin  "Return minimum abscissa value of 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          output Real timeMin "Minimum abscissa value in table";
          external "C" timeMin = ModelicaStandardTables_CombiTimeTable_minimumTime(tableID) annotation(Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getTimeTableTmin;

        function getTimeTableTmax  "Return maximum abscissa value of 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          output Real timeMax "Maximum abscissa value in table";
          external "C" timeMax = ModelicaStandardTables_CombiTimeTable_maximumTime(tableID) annotation(Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getTimeTableTmax;

        function getNextTimeEvent  "Return next time event value of 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
          input Real timeIn;
          output Real nextTimeEvent "Next time event in table";
          external "C" nextTimeEvent = ModelicaStandardTables_CombiTimeTable_nextTimeEvent(tableID, timeIn) annotation(Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end getNextTimeEvent;
      end Internal;
      annotation(Documentation(info = "<html>
    <p>This package contains blocks for one- and two-dimensional interpolation in tables.</p>
    <h4>Special interest topic: Statically stored tables for real-time simulation targets</h4>
    <p>Especially for use on real-time platform targets (e.g., HIL-simulators) with <strong>no file system</strong>, it is possible to statically
    store tables using a function &quot;usertab&quot; in a file conventionally named &quot;usertab.c&quot;. This can be more efficient than providing the tables as Modelica parameter arrays.</p>
    <p>This is achieved by providing the tables in a specific structure as C-code and compiling that C-code together with the rest of the simulation model into a binary
    that can be executed on the target platform. The &quot;Resources/Data/Tables/&quot; subdirectory of the MSL installation directory contains the files
    <a href=\"modelica://Modelica/Resources/Data/Tables/usertab.c\">&quot;usertab.c&quot;</a> and <a href=\"modelica://Modelica/Resources/Data/Tables/usertab.h\">&quot;usertab.h&quot;</a>
    that can be used as a template for own developments. While &quot;usertab.c&quot; would be typically used unmodified, the
    &quot;usertab.h&quot; needs to adapted for the own needs.</p>
    <p>In order to work it is necessary that the compiler pulls in the &quot;usertab.c&quot; file. Different Modelica tools might provide different mechanisms to do so.
    Please consult the respective documentation/support for your Modelica tool.</p>
    <p>A possible (though a bit &quot;hackish&quot;) Modelica standard conformant approach is to pull in the required files by utilizing a &quot;dummy&quot;-function that uses the Modelica external function
    interface to pull in the required &quot;usertab.c&quot;. An example how this can be done is given below.</p>
    <pre>
    model Test25_usertab \"Test utilizing the usertab.c interface\"
      extends Modelica.Icons.Example;
    public
      Modelica.Blocks.Sources.RealExpression realExpression(y=getUsertab(t_new.y))
        annotation (Placement(transformation(extent={{-40,-34},{-10,-14}})));
      Modelica.Blocks.Tables.CombiTable1D t_new(tableOnFile=true, tableName=\"TestTable_1D_a\")
        annotation (Placement(transformation(extent={{-40,0},{-20,20}})));
      Modelica.Blocks.Sources.Clock clock
        annotation (Placement(transformation(extent={{-80,0},{-60,20}})));
    protected
      encapsulated function getUsertab
        input Real dummy_u[:];
        output Real dummy_y;
        external \"C\" dummy_y=  mydummyfunc(dummy_u);
        annotation(IncludeDirectory=\"modelica://Modelica/Resources/Data/Tables\",
               Include = \"#include \"usertab.c\"
    double mydummyfunc(double* dummy_in) {
       return 0;
    }
    \");
      end getUsertab;
    equation
      connect(clock.y,t_new. u[1]) annotation (Line(
          points={{-59,10},{-42,10}}, color={0,0,127}));
      annotation (experiment(StartTime=0, StopTime=5), uses(Modelica(version=\"3.2.3\")));
    end Test25_usertab;
    </pre>
    </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-76, -26}, {80, -76}}, lineColor = {95, 95, 95}, fillColor = {235, 235, 235}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-76, 24}, {80, -26}}, lineColor = {95, 95, 95}, fillColor = {235, 235, 235}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-76, 74}, {80, 24}}, lineColor = {95, 95, 95}, fillColor = {235, 235, 235}, fillPattern = FillPattern.Solid), Line(points = {{-28, 74}, {-28, -76}}, color = {95, 95, 95}), Line(points = {{24, 74}, {24, -76}}, color = {95, 95, 95})}));
    end Tables;

    package Types  "Library of constants, external objects and types with choices, especially to build menus"
      extends Modelica.Icons.TypesPackage;
      type Smoothness = enumeration(LinearSegments "Table points are linearly interpolated", ContinuousDerivative "Table points are interpolated (by Akima splines) such that the first derivative is continuous", ConstantSegments "Table points are not interpolated, but the value from the previous abscissa point is returned", MonotoneContinuousDerivative1 "Table points are interpolated (by Fritsch-Butland splines) such that the monotonicity is preserved and the first derivative is continuous", MonotoneContinuousDerivative2 "Table points are interpolated (by Steffen splines) such that the monotonicity is preserved and the first derivative is continuous") "Enumeration defining the smoothness of table interpolation";
      type Extrapolation = enumeration(HoldLastPoint "Hold the first/last table point outside of the table scope", LastTwoPoints "Extrapolate by using the derivative at the first/last table points outside of the table scope", Periodic "Repeat the table scope periodically", NoExtrapolation "Extrapolation triggers an error") "Enumeration defining the extrapolation of table interpolation";
      type TimeEvents = enumeration(Always "Always generate time events at interval boundaries", AtDiscontinuities "Generate time events at discontinuities (defined by duplicated sample points)", NoTimeEvents "No time events at interval boundaries") "Enumeration defining the time event handling of time table interpolation";

      class ExternalCombiTimeTable  "External object of 1-dim. table where first column is time"
        extends ExternalObject;

        function constructor  "Initialize 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input String tableName "Table name";
          input String fileName "File name";
          input Real[:, :] table;
          input Modelica.SIunits.Time startTime;
          input Integer[:] columns;
          input Modelica.Blocks.Types.Smoothness smoothness;
          input Modelica.Blocks.Types.Extrapolation extrapolation;
          input Modelica.SIunits.Time shiftTime = 0.0;
          input Modelica.Blocks.Types.TimeEvents timeEvents = Modelica.Blocks.Types.TimeEvents.Always;
          input Boolean verboseRead = true "= true: Print info message; = false: No info message";
          output ExternalCombiTimeTable externalCombiTimeTable;
          external "C" externalCombiTimeTable = ModelicaStandardTables_CombiTimeTable_init2(fileName, tableName, table, size(table, 1), size(table, 2), startTime, columns, size(columns, 1), smoothness, extrapolation, shiftTime, timeEvents, verboseRead) annotation(Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end constructor;

        function destructor  "Terminate 1-dim. table where first column is time"
          extends Modelica.Icons.Function;
          input ExternalCombiTimeTable externalCombiTimeTable;
          external "C" ModelicaStandardTables_CombiTimeTable_close(externalCombiTimeTable) annotation(Library = {"ModelicaStandardTables", "ModelicaIO", "ModelicaMatIO", "zlib"});
        end destructor;
      end ExternalCombiTimeTable;
      annotation(Documentation(info = "<html>
    <p>
    In this package <strong>types</strong>, <strong>constants</strong> and <strong>external objects</strong> are defined that are used
    in library Modelica.Blocks. The types have additional annotation choices
    definitions that define the menus to be built up in the graphical
    user interface when the type is used as parameter in a declaration.
    </p>
    </html>"));
    end Types;

    package Icons  "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block  "Basic graphical layout of input/output block"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, -100}, {100, 100}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>
      <p>
      Block that has only the basic icon for an input/output
      block (no declarations, no equations). Most blocks
      of package Modelica.Blocks inherit directly or indirectly
      from this block.
      </p>
      </html>")); end Block;

      partial block PartialBooleanBlock  "Basic graphical layout of logical block"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, fillColor = {210, 210, 210}, fillPattern = FillPattern.Solid, borderPattern = BorderPattern.Raised), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>
      <p>
      Block that has only the basic icon for an input/output,
      Boolean block (no declarations, no equations) used especially
      in the Blocks.Logical library.
      </p>
      </html>")); end PartialBooleanBlock;
    end Icons;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Rectangle(origin = {0.0, 35.1488}, fillColor = {255, 255, 255}, extent = {{-30.0, -20.1488}, {30.0, 20.1488}}), Rectangle(origin = {0.0, -34.8512}, fillColor = {255, 255, 255}, extent = {{-30.0, -20.1488}, {30.0, 20.1488}}), Line(origin = {-51.25, 0.0}, points = {{21.25, -35.0}, {-13.75, -35.0}, {-13.75, 35.0}, {6.25, 35.0}}), Polygon(origin = {-40.0, 35.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{10.0, 0.0}, {-5.0, 5.0}, {-5.0, -5.0}}), Line(origin = {51.25, 0.0}, points = {{-21.25, 35.0}, {13.75, 35.0}, {13.75, -35.0}, {-6.25, -35.0}}), Polygon(origin = {40.0, -35.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.0, 0.0}, {5.0, 5.0}, {5.0, -5.0}})}), Documentation(info = "<html>
  <p>
  This library contains input/output blocks to build up block diagrams.
  </p>

  <dl>
  <dt><strong>Main Author:</strong></dt>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
      Oberpfaffenhofen<br>
      Postfach 1116<br>
      D-82230 Wessling<br>
      email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a><br></dd>
  </dl>
  <p>
  Copyright &copy; 1998-2019, Modelica Association and contributors
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><em>June 23, 2004</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Introduced new block connectors and adapted all blocks to the new connectors.
         Included subpackages Continuous, Discrete, Logical, Nonlinear from
         package ModelicaAdditions.Blocks.
         Included subpackage ModelicaAdditions.Table in Modelica.Blocks.Sources
         and in the new package Modelica.Blocks.Tables.
         Added new blocks to Blocks.Sources and Blocks.Logical.
         </li>
  <li><em>October 21, 2002</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
         and Christian Schweiger:<br>
         New subpackage Examples, additional components.
         </li>
  <li><em>June 20, 2000</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
         Michael Tiller:<br>
         Introduced a replaceable signal type into
         Blocks.Interfaces.RealInput/RealOutput:
  <pre>
     replaceable type SignalType = Real
  </pre>
         in order that the type of the signal of an input/output block
         can be changed to a physical type, for example:
  <pre>
     Sine sin1(outPort(redeclare type SignalType=Modelica.SIunits.Torque))
  </pre>
        </li>
  <li><em>Sept. 18, 1999</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Renamed to Blocks. New subpackages Math, Nonlinear.
         Additional components in subpackages Interfaces, Continuous
         and Sources.</li>
  <li><em>June 30, 1999</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized a first version, based on an existing Dymola library
         of Dieter Moormann and Hilding Elmqvist.</li>
  </ul>
  </html>"));
  end Blocks;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {0, 68}}, color = {192, 192, 192}), Polygon(points = {{0, 90}, {-8, 68}, {8, 68}, {0, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(graphics = {Line(points = {{0, 80}, {-8, 80}}, color = {95, 95, 95}), Line(points = {{0, -80}, {-8, -80}}, color = {95, 95, 95}), Line(points = {{0, -90}, {0, 84}}, color = {95, 95, 95}), Text(extent = {{5, 104}, {25, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{0, 98}, {-6, 82}, {6, 82}, {0, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
      <p>
      Icon for a mathematical function, consisting of an y-axis in the middle.
      It is expected, that an x-axis is added and a plot of the function.
      </p>
      </html>")); end AxisCenter;
    end Icons;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = asin(u), with -1 &le; u &le; +1:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = asin(u), with -1 &le; u &le; +1:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
    </p>
    </html>"));
    end asin;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175})}), Documentation(info = "<html>
    <p>
    This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
    </p>
    </html>"));
    end exp;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.4}, {-49.4, 74.6}, {-43.8, 79.1}, {-38.2, 79.8}, {-32.6, 76.6}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.1}, {35, -78.4}, {40.6, -80}, {46.2, -77.6}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}), Documentation(info = "<html>
  <p>
  This package contains <strong>basic mathematical functions</strong> (such as sin(..)),
  as well as functions operating on
  <a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
  <a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
  <a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
  <a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
  </p>

  <h4>Main Authors</h4>
  <p><a href=\"http://www.robotic.dlr.de/Martin.Otter/\"><strong>Martin Otter</strong></a>
  and <strong>Marcus Baur</strong><br>
  Deutsches Zentrum f&uuml;r Luft- und Raumfahrt e.V. (DLR)<br>
  Institut f&uuml;r Systemdynamik und Regelungstechnik (DLR-SR)<br>
  Forschungszentrum Oberpfaffenhofen<br>
  D-82234 Wessling<br>
  Germany<br>
  email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a>
  </p>

  <p>
  Copyright &copy; 1998-2019, Modelica Association and contributors
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><em>August 24, 2016</em>
         by Christian Kral: added wrapAngle</li>
  <li><em>October 21, 2002</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
         and Christian Schweiger:<br>
         Function tempInterpol2 added.</li>
  <li><em>Oct. 24, 1999</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Icons for icon and diagram level introduced.</li>
  <li><em>June 30, 1999</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized.</li>
  </ul>

  </html>"));
  end Math;

  package Utilities  "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)"
    extends Modelica.Icons.UtilitiesPackage;

    package Strings  "Operations on strings"
      extends Modelica.Icons.FunctionsPackage;

      function length  "Return length of string"
        extends Modelica.Icons.Function;
        input String string;
        output Integer result "Number of characters of string";
        external "C" result = ModelicaStrings_length(string) annotation(Library = "ModelicaExternalC", Documentation(info = "<html>
      <h4>Syntax</h4>
      <blockquote><pre>
      Strings.<strong>length</strong>(string);
      </pre></blockquote>
      <h4>Description</h4>
      <p>
      Returns the number of characters of \"string\".
      </p>
      </html>"));
        annotation(Documentation(info = "<html>
      <h4>Syntax</h4>
      <blockquote><pre>
      Strings.<strong>length</strong>(string);
      </pre></blockquote>
      <h4>Description</h4>
      <p>
      Returns the number of characters of \"string\".
      </p>
      </html>"));
      end length;

      function isEmpty  "Return true if a string is empty (has only white space characters)"
        extends Modelica.Icons.Function;
        input String string;
        output Boolean result "True, if string is empty";
      protected
        Integer nextIndex;
        Integer len;
      algorithm
        nextIndex := Strings.Advanced.skipWhiteSpace(string);
        len := Strings.length(string);
        if len < 1 or nextIndex > len then
          result := true;
        else
          result := false;
        end if;
        annotation(Documentation(info = "<html>
      <h4>Syntax</h4>
      <blockquote><pre>
      Strings.<strong>isEmpty</strong>(string);
      </pre></blockquote>
      <h4>Description</h4>
      <p>
      Returns true if the string has no characters or if the string consists
      only of white space characters. Otherwise, false is returned.
      </p>

      <h4>Example</h4>
      <blockquote><pre>
        isEmpty(\"\");       // returns true
        isEmpty(\"   \");    // returns true
        isEmpty(\"  abc\");  // returns false
        isEmpty(\"a\");      // returns false
      </pre></blockquote>
      </html>"));
      end isEmpty;

      package Advanced  "Advanced scanning functions"
        extends Modelica.Icons.FunctionsPackage;

        function skipWhiteSpace  "Scan white space"
          extends Modelica.Icons.Function;
          input String string;
          input Integer startIndex(min = 1) = 1;
          output Integer nextIndex;
          external "C" nextIndex = ModelicaStrings_skipWhiteSpace(string, startIndex) annotation(Library = "ModelicaExternalC", Documentation(info = "<html>
        <h4>Syntax</h4>
        <blockquote><pre>
        nextIndex = <strong>skipWhiteSpace</strong>(string, startIndex);
        </pre></blockquote>
        <h4>Description</h4>
        <p>
        Starts scanning of \"string\" at position \"startIndex\" and
        skips white space. The function returns nextIndex = index of character
        of the first non white space character.
        </p>
        <h4>See also</h4>
        <a href=\"modelica://Modelica.Utilities.Strings.Advanced\">Strings.Advanced</a>.
        </html>"));
          annotation(Documentation(info = "<html>
        <h4>Syntax</h4>
        <blockquote><pre>
        nextIndex = <strong>skipWhiteSpace</strong>(string, startIndex);
        </pre></blockquote>
        <h4>Description</h4>
        <p>
        Starts scanning of \"string\" at position \"startIndex\" and
        skips white space. The function returns nextIndex = index of character
        of the first non white space character.
        </p>
        <h4>See also</h4>
        <a href=\"modelica://Modelica.Utilities.Strings.Advanced\">Strings.Advanced</a>.
        </html>"));
        end skipWhiteSpace;
        annotation(Documentation(info = "<html>
      <h4>Library content</h4>
      <p>
      Package <strong>Strings.Advanced</strong> contains basic scanning
      functions. These functions should be <strong>not called</strong> directly, because
      it is much simpler to utilize the higher level functions \"Strings.scanXXX\".
      The functions of the \"Strings.Advanced\" library provide
      the basic interface in order to implement the higher level
      functions in package \"Strings\".
      </p>
      <p>
      Library \"Advanced\" provides the following functions:
      </p>
      <pre>
        (nextIndex, realNumber)    = <a href=\"modelica://Modelica.Utilities.Strings.Advanced.scanReal\">scanReal</a>        (string, startIndex, unsigned=false);
        (nextIndex, integerNumber) = <a href=\"modelica://Modelica.Utilities.Strings.Advanced.scanInteger\">scanInteger</a>     (string, startIndex, unsigned=false);
        (nextIndex, string2)       = <a href=\"modelica://Modelica.Utilities.Strings.Advanced.scanString\">scanString</a>      (string, startIndex);
        (nextIndex, identifier)    = <a href=\"modelica://Modelica.Utilities.Strings.Advanced.scanIdentifier\">scanIdentifier</a>  (string, startIndex);
         nextIndex                 = <a href=\"modelica://Modelica.Utilities.Strings.Advanced.skipWhiteSpace\">skipWhiteSpace</a>  (string, startIndex);
         nextIndex                 = <a href=\"modelica://Modelica.Utilities.Strings.Advanced.skipLineComments\">skipLineComments</a>(string, startIndex);
      </pre>
      <p>
      All functions perform the following actions:
      </p>
      <ol>
      <li> Scanning starts at character position \"startIndex\" of
           \"string\" (startIndex has a default of 1).</li>
      <li> First, white space is skipped, such as blanks (\" \"), tabs (\"\\t\"), or newline (\"\\n\")</li>
      <li> Afterwards, the required token is scanned.</li>
      <li> If successful, on return nextIndex = index of character
           directly after the found token and the token value is returned
           as second output argument.<br>
           If not successful, on return nextIndex = startIndex.
           </li>
      </ol>
      <p>
      The following additional rules apply for the scanning:
      </p>
      <ul>
      <li> Function <a href=\"modelica://Modelica.Utilities.Strings.Advanced.scanReal\">scanReal</a>:<br>
           Scans a full number including one optional leading \"+\" or \"-\" (if unsigned=false)
           according to the Modelica grammar. For example, \"+1.23e-5\", \"0.123\" are
           Real numbers, but \".1\" is not.
           Note, an Integer number, such as \"123\" is also treated as a Real number.<br>&nbsp;</li>
      <li> Function <a href=\"modelica://Modelica.Utilities.Strings.Advanced.scanInteger\">scanInteger</a>:<br>
           Scans an Integer number including one optional leading \"+\"
           or \"-\" (if unsigned=false) according to the Modelica (and C/C++) grammar.
           For example, \"+123\", \"20\" are Integer numbers.
           Note, a Real number, such as \"123.4\" is not an Integer and
           scanInteger returns nextIndex = startIndex.<br>&nbsp;</li>
      <li> Function <a href=\"modelica://Modelica.Utilities.Strings.Advanced.scanString\">scanString</a>:<br>
           Scans a String according to the Modelica (and C/C++) grammar, e.g.,
           \"This is a \"string\"\" is a valid string token.<br>&nbsp;</li>
      <li> Function <a href=\"modelica://Modelica.Utilities.Strings.Advanced.scanIdentifier\">scanIdentifier</a>:<br>
           Scans a Modelica identifier, i.e., the identifier starts either
           with a letter, followed by letters, digits or \"_\".
           For example, \"w_rel\", \"T12\".<br>&nbsp;</li>
      <li> Function <a href=\"modelica://Modelica.Utilities.Strings.Advanced.skipLineComments\">skipLineComments</a><br>
           Skips white space and Modelica (C/C++) line comments iteratively.
           A line comment starts with \"//\" and ends either with an
           end-of-line (\"\\n\") or the end of the \"string\".</li>
      </ul>
      </html>"));
      end Advanced;
      annotation(Documentation(info = "<html>
    <h4>Library content</h4>
    <p>
    Package <strong>Strings</strong> contains functions to manipulate strings.
    </p>
    <p>
    In the table below an example
    call to every function is given using the <strong>default</strong> options.
    </p>
    <table border=1 cellspacing=0 cellpadding=2>
      <tr><th><strong><em>Function</em></strong></th><th><strong><em>Description</em></strong></th></tr>
      <tr><td>len = <a href=\"modelica://Modelica.Utilities.Strings.length\">length</a>(string)</td>
          <td>Returns length of string</td></tr>
      <tr><td>string2 = <a href=\"modelica://Modelica.Utilities.Strings.substring\">substring</a>(string1,startIndex,endIndex)
           </td>
          <td>Returns a substring defined by start and end index</td></tr>
      <tr><td>result = <a href=\"modelica://Modelica.Utilities.Strings.repeat\">repeat</a>(n)<br>
     result = <a href=\"modelica://Modelica.Utilities.Strings.repeat\">repeat</a>(n,string)</td>
          <td>Repeat a blank or a string n times.</td></tr>
      <tr><td>result = <a href=\"modelica://Modelica.Utilities.Strings.compare\">compare</a>(string1, string2)</td>
          <td>Compares two substrings with regards to alphabetical order</td></tr>
      <tr><td>identical =
    <a href=\"modelica://Modelica.Utilities.Strings.isEqual\">isEqual</a>(string1,string2)</td>
          <td>Determine whether two strings are identical</td></tr>
      <tr><td>result = <a href=\"modelica://Modelica.Utilities.Strings.count\">count</a>(string,searchString)</td>
          <td>Count the number of occurrences of a string</td></tr>
      <tr>
    <td>index = <a href=\"modelica://Modelica.Utilities.Strings.find\">find</a>(string,searchString)</td>
          <td>Find first occurrence of a string in another string</td></tr>
    <tr>
    <td>index = <a href=\"modelica://Modelica.Utilities.Strings.findLast\">findLast</a>(string,searchString)</td>
          <td>Find last occurrence of a string in another string</td></tr>
      <tr><td>string2 = <a href=\"modelica://Modelica.Utilities.Strings.replace\">replace</a>(string,searchString,replaceString)</td>
          <td>Replace one or all occurrences of a string</td></tr>
      <tr><td>stringVector2 = <a href=\"modelica://Modelica.Utilities.Strings.sort\">sort</a>(stringVector1)</td>
          <td>Sort vector of strings in alphabetic order</td></tr>
      <tr><td>hash = <a href=\"modelica://Modelica.Utilities.Strings.hashString\">hashString</a>(string)</td>
          <td>Create a hash value of a string</td></tr>
      <tr><td>(token, index) = <a href=\"modelica://Modelica.Utilities.Strings.scanToken\">scanToken</a>(string,startIndex)</td>
          <td>Scan for a token (Real/Integer/Boolean/String/Identifier/Delimiter/NoToken)</td></tr>
      <tr><td>(number, index) = <a href=\"modelica://Modelica.Utilities.Strings.scanReal\">scanReal</a>(string,startIndex)</td>
          <td>Scan for a Real constant</td></tr>
      <tr><td>(number, index) = <a href=\"modelica://Modelica.Utilities.Strings.scanInteger\">scanInteger</a>(string,startIndex)</td>
          <td>Scan for an Integer constant</td></tr>
      <tr><td>(boolean, index) = <a href=\"modelica://Modelica.Utilities.Strings.scanBoolean\">scanBoolean</a>(string,startIndex)</td>
          <td>Scan for a Boolean constant</td></tr>
      <tr><td>(string2, index) = <a href=\"modelica://Modelica.Utilities.Strings.scanString\">scanString</a>(string,startIndex)</td>
          <td>Scan for a String constant</td></tr>
      <tr><td>(identifier, index) = <a href=\"modelica://Modelica.Utilities.Strings.scanIdentifier\">scanIdentifier</a>(string,startIndex)</td>
          <td>Scan for an identifier</td></tr>
      <tr><td>(delimiter, index) = <a href=\"modelica://Modelica.Utilities.Strings.scanDelimiter\">scanDelimiter</a>(string,startIndex)</td>
          <td>Scan for delimiters</td></tr>
      <tr><td><a href=\"modelica://Modelica.Utilities.Strings.scanNoToken\">scanNoToken</a>(string,startIndex)</td>
          <td>Check that remaining part of string consists solely of<br>
              white space or line comments (\"// ...\\n\").</td></tr>
      <tr><td><a href=\"modelica://Modelica.Utilities.Strings.syntaxError\">syntaxError</a>(string,index,message)</td>
          <td> Print a \"syntax error message\" as well as a string and the<br>
               index at which scanning detected an error</td></tr>
    </table>
    <p>
    The functions \"compare\", \"isEqual\", \"count\", \"find\", \"findLast\", \"replace\", \"sort\"
    have the optional
    input argument <strong>caseSensitive</strong> with default <strong>true</strong>.
    If <strong>false</strong>, the operation is carried out without taking
    into account whether a character is upper or lower case.
    </p>
    </html>"));
    end Strings;
    annotation(Documentation(info = "<html>
  <p>
  This package contains Modelica <strong>functions</strong> that are
  especially suited for <strong>scripting</strong>. The functions might
  be used to work with strings, read data from file, write data
  to file or copy, move and remove files.
  </p>
  <p>
  For an introduction, have especially a look at:
  </p>
  <ul>
  <li> <a href=\"modelica://Modelica.Utilities.UsersGuide\">Modelica.Utilities.User's Guide</a>
       discusses the most important aspects of this library.</li>
  <li> <a href=\"modelica://Modelica.Utilities.Examples\">Modelica.Utilities.Examples</a>
       contains examples that demonstrate the usage of this library.</li>
  </ul>
  <p>
  The following main sublibraries are available:
  </p>
  <ul>
  <li> <a href=\"modelica://Modelica.Utilities.Files\">Files</a>
       provides functions to operate on files and directories, e.g.,
       to copy, move, remove files.</li>
  <li> <a href=\"modelica://Modelica.Utilities.Streams\">Streams</a>
       provides functions to read from files and write to files.</li>
  <li> <a href=\"modelica://Modelica.Utilities.Strings\">Strings</a>
       provides functions to operate on strings. E.g.
       substring, find, replace, sort, scanToken.</li>
  <li> <a href=\"modelica://Modelica.Utilities.System\">System</a>
       provides functions to interact with the environment.
       E.g., get or set the working directory or environment
       variables and to send a command to the default shell.</li>
  </ul>

  <p>
  Copyright &copy; 1998-2019, Modelica Association and contributors
  </p>
  </html>"));
  end Utilities;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant Real inf = ModelicaServices.Machine.inf "Biggest Real number such that inf and -inf are representable on the machine";
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant .Modelica.SIunits.FaradayConstant F = 9.648533289e4 "Faraday constant, C/mol (previous value: 9.64853399e4)";
    final constant Real N_A(final unit = "1/mol") = 6.022140857e23 "Avogadro constant (previous value: 6.0221415e23)";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
    annotation(Documentation(info = "<html>
  <p>
  This package provides often needed constants from mathematics, machine
  dependent constants and constants from nature. The latter constants
  (name, value, description) are from the following source:
  </p>

  <dl>
  <dt>Peter J. Mohr, David B. Newell, and Barry N. Taylor:</dt>
  <dd><strong>CODATA Recommended Values of the Fundamental Physical Constants: 2014</strong>.
  <a href= \"http://dx.doi.org/10.5281/zenodo.22826\">http://dx.doi.org/10.5281/zenodo.22826</a>, 2015. See also <a href=
  \"http://physics.nist.gov/cuu/Constants/index.html\">http://physics.nist.gov/cuu/Constants/index.html</a></dd>
  </dl>

  <p>CODATA is the Committee on Data for Science and Technology.</p>

  <dl>
  <dt><strong>Main Author:</strong></dt>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
      Oberpfaffenhofen<br>
      Postfach 1116<br>
      D-82230 We&szlig;ling<br>
      email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  </dl>

  <p>
  Copyright &copy; 1998-2019, Modelica Association and contributors
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><em>Nov 4, 2015</em>
         by Thomas Beutlich:<br>
         Constants updated according to 2014 CODATA values.</li>
  <li><em>Nov 8, 2004</em>
         by Christian Schweiger:<br>
         Constants updated according to 2002 CODATA values.</li>
  <li><em>Dec 9, 1999</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Constants updated according to 1998 CODATA values. Using names, values
         and description text from this source. Included magnetic and
         electric constant.</li>
  <li><em>Sep 18, 1999</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Constants eps, inf, small introduced.</li>
  <li><em>Nov 15, 1997</em>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized.</li>
  </ul>
  </html>"), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-9.2597, 25.6673}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{48.017, 11.336}, {48.017, 11.336}, {10.766, 11.336}, {-25.684, 10.95}, {-34.944, -15.111}, {-34.944, -15.111}, {-32.298, -15.244}, {-32.298, -15.244}, {-22.112, 0.168}, {11.292, 0.234}, {48.267, -0.097}, {48.267, -0.097}}, smooth = Smooth.Bezier), Polygon(origin = {-19.9923, -8.3993}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{3.239, 37.343}, {3.305, 37.343}, {-0.399, 2.683}, {-16.936, -20.071}, {-7.808, -28.604}, {6.811, -22.519}, {9.986, 37.145}, {9.986, 37.145}}, smooth = Smooth.Bezier), Polygon(origin = {23.753, -11.5422}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.873, 41.478}, {-10.873, 41.478}, {-14.048, -4.162}, {-9.352, -24.8}, {7.912, -24.469}, {16.247, 0.27}, {16.247, 0.27}, {13.336, 0.071}, {13.336, 0.071}, {7.515, -9.983}, {-3.134, -7.271}, {-2.671, 41.214}, {-2.671, 41.214}}, smooth = Smooth.Bezier)}));
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial model Example  "Icon for runnable examples"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {75, 138, 73}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Polygon(lineColor = {0, 0, 255}, fillColor = {75, 138, 73}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-36, 60}, {64, 0}, {-36, -60}, {-36, 60}})}), Documentation(info = "<html>
    <p>This icon indicates an example. The play button suggests that the example can be executed.</p>
    </html>")); end Example;

    partial package Package  "Icon for standard packages"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {248, 248, 248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Rectangle(lineColor = {128, 128, 128}, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0)}), Documentation(info = "<html>
    <p>Standard package icon.</p>
    </html>")); end Package;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {20.0, 0.0}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-10.0, 70.0}, {10.0, 70.0}, {40.0, 20.0}, {80.0, 20.0}, {80.0, -20.0}, {40.0, -20.0}, {10.0, -70.0}, {-10.0, -70.0}}), Polygon(fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-100.0, 20.0}, {-60.0, 20.0}, {-30.0, 70.0}, {-10.0, 70.0}, {-10.0, -70.0}, {-30.0, -70.0}, {-60.0, -20.0}, {-100.0, -20.0}})}), Documentation(info = "<html>
    <p>This icon indicates packages containing interfaces.</p>
    </html>"));
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {23.3333, 0.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-23.333, 30.0}, {46.667, 0.0}, {-23.333, -30.0}}), Rectangle(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-70, -4.5}, {0, 4.5}})}), Documentation(info = "<html>
    <p>This icon indicates a package which contains sources.</p>
    </html>"));
    end SourcesPackage;

    partial package UtilitiesPackage  "Icon for utility packages"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {1.3835, -4.1418}, rotation = 45.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.0, 93.333}, {-15.0, 68.333}, {0.0, 58.333}, {15.0, 68.333}, {15.0, 93.333}, {20.0, 93.333}, {25.0, 83.333}, {25.0, 58.333}, {10.0, 43.333}, {10.0, -41.667}, {25.0, -56.667}, {25.0, -76.667}, {10.0, -91.667}, {0.0, -91.667}, {0.0, -81.667}, {5.0, -81.667}, {15.0, -71.667}, {15.0, -61.667}, {5.0, -51.667}, {-5.0, -51.667}, {-15.0, -61.667}, {-15.0, -71.667}, {-5.0, -81.667}, {0.0, -81.667}, {0.0, -91.667}, {-10.0, -91.667}, {-25.0, -76.667}, {-25.0, -56.667}, {-10.0, -41.667}, {-10.0, 43.333}, {-25.0, 58.333}, {-25.0, 83.333}, {-20.0, 93.333}}), Polygon(origin = {10.1018, 5.218}, rotation = -45.0, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-15.0, 87.273}, {15.0, 87.273}, {20.0, 82.273}, {20.0, 27.273}, {10.0, 17.273}, {10.0, 7.273}, {20.0, 2.273}, {20.0, -2.727}, {5.0, -2.727}, {5.0, -77.727}, {10.0, -87.727}, {5.0, -112.727}, {-5.0, -112.727}, {-10.0, -87.727}, {-5.0, -77.727}, {-5.0, -2.727}, {-20.0, -2.727}, {-20.0, 2.273}, {-10.0, 7.273}, {-10.0, 17.273}, {-20.0, 27.273}, {-20.0, 82.273}})}), Documentation(info = "<html>
    <p>This icon indicates a package containing utility classes.</p>
    </html>"));
    end UtilitiesPackage;

    partial package TypesPackage  "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-12.167, -23}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{12.167, 65}, {14.167, 93}, {36.167, 89}, {24.167, 20}, {4.167, -30}, {14.167, -30}, {24.167, -30}, {24.167, -40}, {-5.833, -50}, {-15.833, -30}, {4.167, 20}, {12.167, 65}}, smooth = Smooth.Bezier), Polygon(origin = {2.7403, 1.6673}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{49.2597, 22.3327}, {31.2597, 24.3327}, {7.2597, 18.3327}, {-26.7403, 10.3327}, {-46.7403, 14.3327}, {-48.7403, 6.3327}, {-32.7403, 0.3327}, {-6.7403, 4.3327}, {33.2597, 14.3327}, {49.2597, 14.3327}, {49.2597, 22.3327}}, smooth = Smooth.Bezier)}));
    end TypesPackage;

    partial package FunctionsPackage  "Icon for packages containing functions"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {128, 128, 128}, extent = {{-90, -90}, {90, 90}}, textString = "f")}));
    end FunctionsPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}})}));
    end IconsPackage;

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {215, 215, 215}, fillColor = {255, 255, 255}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100, -100}, {100, 100}}, radius = 25), Rectangle(lineColor = {215, 215, 215}, extent = {{-100, -100}, {100, 100}}, radius = 25), Ellipse(extent = {{-80, 80}, {80, -80}}, lineColor = {215, 215, 215}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-55, 55}, {55, -55}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-60, 14}, {60, -14}}, lineColor = {215, 215, 215}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid, rotation = 45)}), Documentation(info = "<html>

    <p>
    This icon shall be used for a package that contains internal classes not to be
    directly utilized by a user.
    </p>
    </html>")); end InternalPackage;

    partial function Function  "Icon for functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 105}, {150, 145}}, textString = "%name"), Ellipse(lineColor = {108, 88, 49}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Text(lineColor = {108, 88, 49}, extent = {{-90.0, -90.0}, {90.0, 90.0}}, textString = "f")}), Documentation(info = "<html>
    <p>This icon indicates Modelica functions.</p>
    </html>")); end Function;
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}})}), Documentation(info = "<html>
  <p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer.</p>

  <h4>Main Authors:</h4>

  <dl>
  <dt><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dt>
      <dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd>
      <dd>Oberpfaffenhofen</dd>
      <dd>Postfach 1116</dd>
      <dd>D-82230 Wessling</dd>
      <dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  <dt>Christian Kral</dt>

      <dd>  <a href=\"https://christiankral.net/\">Electric Machines, Drives and Systems</a><br>
  </dd>
      <dd>1060 Vienna, Austria</dd>
      <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
  <dt>Johan Andreasson</dt>
      <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>
      <dd>Ideon Science Park</dd>
      <dd>22370 Lund, Sweden</dd>
      <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
  </dl>

  <p>
  Copyright &copy; 1998-2019, Modelica Association and contributors
  </p>
  </html>"));
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
        annotation(Documentation(info = "<html>
      <p>
      This package provides predefined types, such as <strong>Angle_deg</strong> (angle in
      degree), <strong>AngularVelocity_rpm</strong> (angular velocity in revolutions per
      minute) or <strong>Temperature_degF</strong> (temperature in degree Fahrenheit),
      which are in common use but are not part of the international standard on
      units according to ISO 31-1992 \"General principles concerning quantities,
      units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
      the use of their multiples and of certain other units\".</p>
      <p>If possible, the types in this package should not be used. Use instead
      types of package Modelica.SIunits. For more information on units, see also
      the book of Francois Cardarelli <strong>Scientific Unit Conversion - A
      Practical Guide to Metrication</strong> (Springer 1997).</p>
      <p>Some units, such as <strong>Temperature_degC/Temp_C</strong> are both defined in
      Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
      definitions have been placed erroneously in Modelica.SIunits although they
      are not SIunits. For backward compatibility, these type definitions are
      still kept in Modelica.SIunits.</p>
      </html>"), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Text(origin = {15.0, 51.8518}, extent = {{-105.0, -86.8518}, {75.0, -16.8518}}, textString = "[km/h]")}));
      end NonSIunits;
      annotation(Documentation(info = "<html>
    <p>This package provides conversion functions from the non SI Units
    defined in package Modelica.SIunits.Conversions.NonSIunits to the
    corresponding SI Units defined in package Modelica.SIunits and vice
    versa. It is recommended to use these functions in the following
    way (note, that all functions have one Real input and one Real output
    argument):</p>
    <pre>
      <strong>import</strong> SI = Modelica.SIunits;
      <strong>import</strong> Modelica.SIunits.Conversions.*;
         ...
      <strong>parameter</strong> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
      <strong>parameter</strong> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
      <strong>parameter</strong> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                          // to radian per seconds
    </pre>

    </html>"));
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Time = Real(final quantity = "Time", final unit = "s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type ElectricCharge = Real(final quantity = "ElectricCharge", final unit = "C");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-80, -40}, {-80, -40}, {-55, 50}, {-52.5, 62.5}, {-65, 60}, {-65, 65}, {-35, 77.5}, {-32.5, 60}, {-50, 0}, {-50, 0}, {-30, 15}, {-20, 27.5}, {-32.5, 27.5}, {-32.5, 27.5}, {-32.5, 32.5}, {-32.5, 32.5}, {2.5, 32.5}, {2.5, 32.5}, {2.5, 27.5}, {2.5, 27.5}, {-7.5, 27.5}, {-30, 7.5}, {-30, 7.5}, {-25, -25}, {-17.5, -28.75}, {-10, -25}, {-5, -26.25}, {-5, -32.5}, {-16.25, -41.25}, {-31.25, -43.75}, {-40, -33.75}, {-45, -5}, {-45, -5}, {-52.5, -10}, {-52.5, -10}, {-60, -40}, {-60, -40}}, smooth = Smooth.Bezier), Polygon(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{87.5, 30}, {62.5, 30}, {62.5, 30}, {55, 33.75}, {36.25, 35}, {16.25, 25}, {7.5, 6.25}, {11.25, -7.5}, {22.5, -12.5}, {22.5, -12.5}, {6.25, -22.5}, {6.25, -35}, {16.25, -38.75}, {16.25, -38.75}, {21.25, -41.25}, {21.25, -41.25}, {45, -48.75}, {47.5, -61.25}, {32.5, -70}, {12.5, -65}, {7.5, -51.25}, {21.25, -41.25}, {21.25, -41.25}, {16.25, -38.75}, {16.25, -38.75}, {6.25, -41.25}, {-6.25, -50}, {-3.75, -68.75}, {30, -76.25}, {65, -62.5}, {63.75, -35}, {27.5, -26.25}, {22.5, -20}, {27.5, -15}, {27.5, -15}, {30, -7.5}, {30, -7.5}, {27.5, -2.5}, {28.75, 11.25}, {36.25, 27.5}, {47.5, 30}, {53.75, 22.5}, {51.25, 8.75}, {45, -6.25}, {35, -11.25}, {30, -7.5}, {30, -7.5}, {27.5, -15}, {27.5, -15}, {43.75, -16.25}, {65, -6.25}, {72.5, 10}, {70, 20}, {70, 20}, {80, 20}}, smooth = Smooth.Bezier)}), Documentation(info = "<html>
  <p>This package provides predefined types, such as <em>Mass</em>,
  <em>Angle</em>, <em>Time</em>, based on the international standard
  on units, e.g.,
  </p>

  <pre>   <strong>type</strong> Angle = Real(<strong>final</strong> quantity = \"Angle\",
                       <strong>final</strong> unit     = \"rad\",
                       displayUnit    = \"deg\");
  </pre>

  <p>
  Some of the types are derived SI units that are utilized in package Modelica
  (such as ComplexCurrent, which is a complex number where both the real and imaginary
  part have the SI unit Ampere).
  </p>

  <p>
  Furthermore, conversion functions from non SI-units to SI-units and vice versa
  are provided in subpackage
  <a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
  </p>

  <p>
  For an introduction how units are used in the Modelica standard library
  with package SIunits, have a look at:
  <a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
  </p>

  <p>
  Copyright &copy; 1998-2019, Modelica Association and contributors
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><em>May 25, 2011</em> by Stefan Wischhusen:<br/>Added molar units for energy and enthalpy.</li>
  <li><em>Jan. 27, 2010</em> by Christian Kral:<br/>Added complex units.</li>
  <li><em>Dec. 14, 2005</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
  <li><em>October 21, 2002</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Christian Schweiger:<br/>Added new package <strong>Conversions</strong>. Corrected typo <em>Wavelenght</em>.</li>
  <li><em>June 6, 2000</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
  <li><em>Oct. 27, 1999</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
  <li><em>Sept. 18, 1999</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
  <li><em>Aug 12, 1999</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
  <li><em>June 29, 1999</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
  <li><em>April 8, 1998</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
  <li><em>Nov. 15, 1997</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Hubertus Tummescheit:<br/>Some chapters realized.</li>
  </ul>
  </html>"));
  end SIunits;
  annotation(preferredView = "info", version = "3.2.3", versionBuild = 3, versionDate = "2019-01-23", dateModified = "2019-09-21 12:00:00Z", revisionId = "$Format:%h %ci$", uses(ModelicaServices(version = "3.2.3")), conversion(noneFromVersion = "3.2.2", noneFromVersion = "3.2.1", noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-6.9888, 20.048}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112, 10.3188}, {-93.0112, 10.3188}, {-73.011, 24.6}, {-63.011, 31.221}, {-51.219, 36.777}, {-39.842, 38.629}, {-31.376, 36.248}, {-25.819, 29.369}, {-24.232, 22.49}, {-23.703, 17.463}, {-15.501, 25.135}, {-6.24, 32.015}, {3.02, 36.777}, {15.191, 39.423}, {27.097, 37.306}, {32.653, 29.633}, {35.035, 20.108}, {43.501, 28.046}, {54.085, 35.19}, {65.991, 39.952}, {77.897, 39.688}, {87.422, 33.338}, {91.126, 21.696}, {90.068, 9.525}, {86.099, -1.058}, {79.749, -10.054}, {71.283, -21.431}, {62.816, -33.337}, {60.964, -32.808}, {70.489, -16.14}, {77.368, -2.381}, {81.072, 10.054}, {79.749, 19.05}, {72.605, 24.342}, {61.758, 23.019}, {49.587, 14.817}, {39.003, 4.763}, {29.214, -6.085}, {21.012, -16.669}, {13.339, -26.458}, {5.401, -36.777}, {-1.213, -46.037}, {-6.24, -53.446}, {-8.092, -52.387}, {-0.684, -40.746}, {5.401, -30.692}, {12.81, -17.198}, {19.424, -3.969}, {23.658, 7.938}, {22.335, 18.785}, {16.514, 23.283}, {8.047, 23.019}, {-1.478, 19.05}, {-11.267, 11.113}, {-19.734, 2.381}, {-29.259, -8.202}, {-38.519, -19.579}, {-48.044, -31.221}, {-56.511, -43.392}, {-64.449, -55.298}, {-72.386, -66.939}, {-77.678, -74.612}, {-79.53, -74.083}, {-71.857, -61.383}, {-62.861, -46.037}, {-52.278, -28.046}, {-44.869, -15.346}, {-38.784, -2.117}, {-35.344, 8.731}, {-36.403, 19.844}, {-42.488, 23.813}, {-52.013, 22.49}, {-60.744, 16.933}, {-68.947, 10.054}, {-76.884, 2.646}, {-93.0112, -12.1707}, {-93.0112, -12.1707}}, smooth = Smooth.Bezier), Ellipse(origin = {40.8208, -37.7602}, fillColor = {161, 0, 4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562, -17.8563}, {17.8563, 17.8562}})}), Documentation(info = "<html>
<p>
Package <strong>Modelica&reg;</strong> is a <strong>standardized</strong> and <strong>free</strong> package
that is developed together with the Modelica&reg; language from the
Modelica Association, see
<a href=\"https://www.Modelica.org\">https://www.Modelica.org</a>.
It is also called <strong>Modelica Standard Library</strong>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/UsersGuide/ModelicaLibraries.png\">
</p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"modelica://Modelica.UsersGuide.Overview\">Overview</a>
  provides an overview of the Modelica Standard Library
  inside the <a href=\"modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
<li><a href=\"modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
 summarizes the changes of new versions of this package.</li>
<li> <a href=\"modelica://Modelica.UsersGuide.Contact\">Contact</a>
  lists the contributors of the Modelica Standard Library.</li>
<li> The <strong>Examples</strong> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li><strong>1288</strong> component models and blocks,</li>
<li><strong>404</strong> example models, and</li>
<li><strong>1227</strong> functions</li>
</ul>
<p>
that are directly usable (= number of public, non-partial, non-internal and non-obsolete classes). It is fully compliant
to <a href=\"https://www.modelica.org/documents/ModelicaSpec32Revision2.pdf\">Modelica Specification Version 3.2 Revision 2</a>
and it has been tested with Modelica tools from different vendors.
</p>

<p>
<strong>Licensed by the Modelica Association under the 3-Clause BSD License</strong><br>
Copyright &copy; 1998-2019, Modelica Association and <a href=\"modelica://Modelica.UsersGuide.Contact\">contributors</a>.
</p>

<p>
<em>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the 3-Clause BSD license. For license conditions (including the disclaimer of warranty) visit <a href=\"https://modelica.org/licenses/modelica-3-clause-bsd\">https://modelica.org/licenses/modelica-3-clause-bsd</a>.</em>
</p>

<p>
<strong>Modelica&reg;</strong> is a registered trademark of the Modelica Association.
</p>
</html>"));
end Modelica;

package YD
  model Test
    extends Modelica.Icons.Example;
    Modelica.Blocks.Sources.BooleanTable booleanTable(table = {0.5, 1, 1.5, 1.55, 1.6, 2, 2.05, 2.1}, startTime = 0.1) annotation(Placement(transformation(extent = {{-80, -10}, {-60, 10}})));
    LogicalDelayEquations logicalDelayEquations(delayTime = 0.1) annotation(Placement(transformation(extent = {{-20, 20}, {0, 40}})));
    LogicalDelayStateGraph logicalDelayStateGraph(delayTime = 0.1) annotation(Placement(transformation(extent = {{-20, -40}, {0, -20}})));
  equation
    connect(booleanTable.y, logicalDelayEquations.u) annotation(Line(points = {{-59, 0}, {-40, 0}, {-40, 30}, {-22, 30}}, color = {255, 0, 255}));
    connect(booleanTable.y, logicalDelayStateGraph.u) annotation(Line(points = {{-59, 0}, {-40, 0}, {-40, -30}, {-22, -30}}, color = {255, 0, 255}));
    annotation(experiment(StopTime = 2.5));
  end Test;

  partial block PartialLogicalDelay  "Delay boolean signal"
    extends Modelica.Blocks.Icons.PartialBooleanBlock;
    parameter Modelica.SIunits.Time delayTime(final min = 0) = 0 "Time delay";
    Modelica.Blocks.Interfaces.BooleanInput u annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
    Modelica.Blocks.Interfaces.BooleanOutput y1 annotation(Placement(transformation(extent = {{100, 50}, {120, 70}})));
    Modelica.Blocks.Interfaces.BooleanOutput y2 annotation(Placement(transformation(extent = {{100, -70}, {120, -50}})));
    annotation(Documentation(info = "<html>
  <p>
  When input <code>u</code> gets true, output <code>y1</code> gets immediately true, whereas output <code>y2</code> gets true after <code>delayTime</code>.
  </p>
  <p>
  When input <code>u</code> gets false, output <code>y1</code> gets false after <code>delayTime</code>, whereas output <code>y2</code> gets immediately false.
  </p>
  </html>"), Icon(graphics = {Polygon(lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}), Line(points = {{-80, 68}, {-80, -80}}, color = {192, 192, 192}), Line(points = {{-90, -70}, {82, -70}}, color = {192, 192, 192}), Polygon(lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{90, -70}, {68, -62}, {68, -78}, {90, -70}}), Line(points = {{-80, -10}, {-60, -10}, {-60, 10}, {40, 10}, {40, -10}, {80, -10}}, color = {255, 0, 255}), Line(points = {{-80, 50}, {-60, 50}, {-60, 70}, {50, 70}, {50, 50}, {80, 50}}, color = {255, 0, 255}), Line(points = {{-80, -70}, {-50, -70}, {-50, -50}, {40, -50}, {40, -70}, {80, -70}}, color = {255, 0, 255}), Line(points = {{-60, 70}, {-60, -70}}, color = {192, 192, 192}, pattern = LinePattern.Dot), Line(points = {{40, 70}, {40, -70}}, color = {192, 192, 192}, pattern = LinePattern.Dot)}));
  end PartialLogicalDelay;

  block LogicalDelayEquations  "Delay boolean signal"
    extends YD.PartialLogicalDelay;
  protected
    discrete Modelica.SIunits.Time tSwitch;
  initial equation
    tSwitch = time - 2 * delayTime;
  equation
    when {u, not u} then
      tSwitch = time;
    end when;
    y1 = if u then true else not time >= tSwitch + delayTime;
    y2 = if not u then false else time >= tSwitch + delayTime;
  end LogicalDelayEquations;

  block LogicalDelayStateGraph  "Delay boolean signal"
    extends YD.PartialLogicalDelay;
    Modelica.Blocks.Logical.Not not1 annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {-60, -30})));
    Modelica.Blocks.Logical.Not not2 annotation(Placement(transformation(extent = {{40, 50}, {60, 70}})));
    Modelica_StateGraph2.Step Y1D0(initialStep = true, use_activePort = true, nOut = 1, nIn = 1) annotation(Placement(transformation(extent = {{16, 56}, {24, 64}})));
    Modelica_StateGraph2.Transition T1(use_conditionPort = true) annotation(Placement(transformation(extent = {{24, 26}, {16, 34}})));
    Modelica_StateGraph2.Step Y0D0(nIn = 2, nOut = 2) annotation(Placement(transformation(extent = {{-4, -4}, {4, 4}})));
    Modelica_StateGraph2.Transition T2(use_conditionPort = true, delayedTransition = true, waitTime = delayTime) annotation(Placement(transformation(extent = {{24, -34}, {16, -26}})));
    Modelica_StateGraph2.Step Y0D1(use_activePort = true, nIn = 1, nOut = 1) annotation(Placement(transformation(extent = {{16, -64}, {24, -56}})));
    Modelica_StateGraph2.Transition T3(use_conditionPort = true, delayedTransition = false) annotation(Placement(transformation(extent = {{4, -4}, {-4, 4}}, rotation = 180, origin = {-10, -30})));
    Modelica_StateGraph2.Transition T4(use_conditionPort = true, delayedTransition = true, waitTime = delayTime) annotation(Placement(transformation(extent = {{4, -4}, {-4, 4}}, rotation = 180, origin = {-20, 30})));
  equation
    connect(u, not1.u) annotation(Line(points = {{-120, 0}, {-90, 0}, {-90, -30}, {-72, -30}}, color = {255, 0, 255}));
    connect(not2.y, y1) annotation(Line(points = {{61, 60}, {110, 60}}, color = {255, 0, 255}));
    connect(Y1D0.activePort, not2.u) annotation(Line(points = {{24.72, 60}, {38, 60}}, color = {255, 0, 255}));
    connect(Y1D0.outPort[1], T1.inPort) annotation(Line(points = {{20, 55.4}, {20, 34}}, color = {0, 0, 0}));
    connect(Y0D1.activePort, y2) annotation(Line(points = {{24.72, -60}, {110, -60}}, color = {255, 0, 255}));
    connect(T2.outPort, Y0D1.inPort[1]) annotation(Line(points = {{20, -35}, {20, -56}}, color = {0, 0, 0}));
    connect(Y0D1.outPort[1], T3.inPort) annotation(Line(points = {{20, -64.6}, {20, -80}, {-10, -80}, {-10, -34}}, color = {0, 0, 0}));
    connect(not1.y, T3.conditionPort) annotation(Line(points = {{-49, -30}, {-15, -30}}, color = {255, 0, 255}));
    connect(T4.outPort, Y1D0.inPort[1]) annotation(Line(points = {{-20, 35}, {-20, 80}, {20, 80}, {20, 64}}, color = {0, 0, 0}));
    connect(not1.y, T4.conditionPort) annotation(Line(points = {{-49, -30}, {-40, -30}, {-40, 30}, {-25, 30}}, color = {255, 0, 255}));
    connect(u, T1.conditionPort) annotation(Line(points = {{-120, 0}, {-90, 0}, {-90, 40}, {40, 40}, {40, 30}, {25, 30}}, color = {255, 0, 255}));
    connect(u, T2.conditionPort) annotation(Line(points = {{-120, 0}, {-90, 0}, {-90, 40}, {40, 40}, {40, -30}, {25, -30}}, color = {255, 0, 255}));
    connect(T3.outPort, Y0D0.inPort[1]) annotation(Line(points = {{-10, -25}, {-10, 20}, {-1, 20}, {-1, 4}}, color = {0, 0, 0}));
    connect(Y0D0.inPort[2], T1.outPort) annotation(Line(points = {{1, 4}, {1, 20}, {20, 20}, {20, 25}}, color = {0, 0, 0}));
    connect(Y0D0.outPort[1], T4.inPort) annotation(Line(points = {{-1, -4.6}, {-1, -20}, {-20, -20}, {-20, 26}}, color = {0, 0, 0}));
    connect(Y0D0.outPort[2], T2.inPort) annotation(Line(points = {{1, -4.6}, {1, -20}, {20, -20}, {20, -26}}, color = {0, 0, 0}));
  end LogicalDelayStateGraph;
end YD;

model Test_total
  extends YD.Test;
 annotation(experiment(StopTime = 2.5));
  annotation(__OpenModelica_commandLineOptions="--std=3.2");
end Test_total;


// Result:
// function Modelica.Blocks.Tables.Internal.getNextTimeEvent "Return next time event value of 1-dim. table where first column is time"
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   input Real timeIn;
//   output Real nextTimeEvent "Next time event in table";
//
//   external "C" nextTimeEvent = ModelicaStandardTables_CombiTimeTable_nextTimeEvent(tableID, timeIn);
// end Modelica.Blocks.Tables.Internal.getNextTimeEvent;
//
// function Modelica.Blocks.Tables.Internal.getTimeTableTmax "Return maximum abscissa value of 1-dim. table where first column is time"
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   output Real timeMax "Maximum abscissa value in table";
//
//   external "C" timeMax = ModelicaStandardTables_CombiTimeTable_maximumTime(tableID);
// end Modelica.Blocks.Tables.Internal.getTimeTableTmax;
//
// function Modelica.Blocks.Tables.Internal.getTimeTableTmin "Return minimum abscissa value of 1-dim. table where first column is time"
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   output Real timeMin "Minimum abscissa value in table";
//
//   external "C" timeMin = ModelicaStandardTables_CombiTimeTable_minimumTime(tableID);
// end Modelica.Blocks.Tables.Internal.getTimeTableTmin;
//
// function Modelica.Blocks.Tables.Internal.getTimeTableValueNoDer "Interpolate 1-dim. table where first column is time (but do not provide a derivative function)"
//   input Modelica.Blocks.Types.ExternalCombiTimeTable tableID;
//   input Integer icol;
//   input Real timeIn;
//   input Real nextTimeEvent;
//   input Real pre_nextTimeEvent;
//   output Real y;
//
//   external "C" y = ModelicaStandardTables_CombiTimeTable_getValue(tableID, icol, timeIn, nextTimeEvent, pre_nextTimeEvent);
// end Modelica.Blocks.Tables.Internal.getTimeTableValueNoDer;
//
// function Modelica.Blocks.Types.ExternalCombiTimeTable.constructor "Initialize 1-dim. table where first column is time"
//   input String tableName "Table name";
//   input String fileName "File name";
//   input Real[:, :] table;
//   input Real startTime(quantity = "Time", unit = "s");
//   input Integer[:] columns;
//   input enumeration(LinearSegments, ContinuousDerivative, ConstantSegments, MonotoneContinuousDerivative1, MonotoneContinuousDerivative2) smoothness;
//   input enumeration(HoldLastPoint, LastTwoPoints, Periodic, NoExtrapolation) extrapolation;
//   input Real shiftTime(quantity = "Time", unit = "s") = 0.0;
//   input enumeration(Always, AtDiscontinuities, NoTimeEvents) timeEvents = Modelica.Blocks.Types.TimeEvents.Always;
//   input Boolean verboseRead = true "= true: Print info message; = false: No info message";
//   output Modelica.Blocks.Types.ExternalCombiTimeTable externalCombiTimeTable;
//
//   external "C" externalCombiTimeTable = ModelicaStandardTables_CombiTimeTable_init2(fileName, tableName, table, size(table, 1), size(table, 2), startTime, columns, size(columns, 1), smoothness, extrapolation, shiftTime, timeEvents, verboseRead);
// end Modelica.Blocks.Types.ExternalCombiTimeTable.constructor;
//
// function Modelica.Blocks.Types.ExternalCombiTimeTable.destructor "Terminate 1-dim. table where first column is time"
//   input Modelica.Blocks.Types.ExternalCombiTimeTable externalCombiTimeTable;
//
//   external "C" ModelicaStandardTables_CombiTimeTable_close(externalCombiTimeTable);
// end Modelica.Blocks.Types.ExternalCombiTimeTable.destructor;
//
// function Modelica_StateGraph2.Blocks.BooleanFunctions.anyTrue "Returns true, if at least on element of the Boolean input vector is true ('or')"
//   input Boolean[:] b;
//   output Boolean result;
// algorithm
//   result := false;
//   for i in 1:size(b, 1) loop
//     result := result or b[i];
//   end for;
// end Modelica_StateGraph2.Blocks.BooleanFunctions.anyTrue;
//
// function Modelica_StateGraph2.Internal.Interfaces.Node "Automatically generated record constructor for Modelica_StateGraph2.Internal.Interfaces.Node"
//   input Boolean suspend;
//   input Boolean resume;
//   output Node res;
// end Modelica_StateGraph2.Internal.Interfaces.Node;
//
// function Modelica_StateGraph2.Internal.Utilities.propagateLoopCheck "Propagate flag to check loop"
//   input Boolean[:] b;
//   output Boolean result;
//   protected Integer dummy;
// algorithm
//   dummy := 0;
//   result := true;
// end Modelica_StateGraph2.Internal.Utilities.propagateLoopCheck;
//
// function Test_total.booleanTable.isValidTable "Check if table is valid"
//   input Real[:] table "Vector of time instants";
//   protected Integer n = size(table, 1) "Number of table points";
// algorithm
//   if n > 0 then
//     for i in 2:n loop
//       assert(table[i] > table[i - 1], "Time values of table not strict monotonically increasing: table[" + String(i - 1, 0, true) + "] = " + String(table[i - 1], 6, 0, true) + ", table[" + String(i, 0, true) + "] = " + String(table[i], 6, 0, true));
//     end for;
//   end if;
// end Test_total.booleanTable.isValidTable;
//
// class Test_total
//   parameter Real booleanTable.table[1](quantity = "Time", unit = "s") = 0.5 "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})";
//   parameter Real booleanTable.table[2](quantity = "Time", unit = "s") = 1.0 "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})";
//   parameter Real booleanTable.table[3](quantity = "Time", unit = "s") = 1.5 "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})";
//   parameter Real booleanTable.table[4](quantity = "Time", unit = "s") = 1.55 "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})";
//   parameter Real booleanTable.table[5](quantity = "Time", unit = "s") = 1.6 "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})";
//   parameter Real booleanTable.table[6](quantity = "Time", unit = "s") = 2.0 "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})";
//   parameter Real booleanTable.table[7](quantity = "Time", unit = "s") = 2.05 "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})";
//   parameter Real booleanTable.table[8](quantity = "Time", unit = "s") = 2.1 "Vector of time points. At every time point, the output y gets its opposite value (e.g., table={0,1})";
//   parameter Boolean booleanTable.startValue = false "Start value of y. At time = table[1], y changes to 'not startValue'";
//   final parameter enumeration(HoldLastPoint, LastTwoPoints, Periodic, NoExtrapolation) booleanTable.extrapolation = Modelica.Blocks.Types.Extrapolation.HoldLastPoint "Extrapolation of data outside the definition range";
//   parameter Real booleanTable.startTime(quantity = "Time", unit = "s") = 0.1 "Output = false for time < startTime";
//   parameter Real booleanTable.shiftTime(quantity = "Time", unit = "s") = 0.0 "Shift time of table";
//   Boolean booleanTable.y "Connector of Boolean output signal";
//   final parameter Integer booleanTable.combiTimeTable.nout(min = 1) = 1 "Number of outputs";
//   Real booleanTable.combiTimeTable.y[1] "Connector of Real output signals";
//   final parameter Boolean booleanTable.combiTimeTable.tableOnFile = false "= true, if table is defined on file or in function usertab";
//   final parameter Real booleanTable.combiTimeTable.table[1,1] = if booleanTable.startValue then booleanTable.table[1] else booleanTable.table[1] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[1,2] = if booleanTable.startValue then 1.0 else 0.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[2,1] = if booleanTable.startValue then booleanTable.table[1] else booleanTable.table[1] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[2,2] = if booleanTable.startValue then 0.0 else 1.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[3,1] = if booleanTable.startValue then booleanTable.table[2] else booleanTable.table[2] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[3,2] = if booleanTable.startValue then 1.0 else 0.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[4,1] = if booleanTable.startValue then booleanTable.table[3] else booleanTable.table[3] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[4,2] = if booleanTable.startValue then 0.0 else 1.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[5,1] = if booleanTable.startValue then booleanTable.table[4] else booleanTable.table[4] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[5,2] = if booleanTable.startValue then 1.0 else 0.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[6,1] = if booleanTable.startValue then booleanTable.table[5] else booleanTable.table[5] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[6,2] = if booleanTable.startValue then 0.0 else 1.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[7,1] = if booleanTable.startValue then booleanTable.table[6] else booleanTable.table[6] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[7,2] = if booleanTable.startValue then 1.0 else 0.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[8,1] = if booleanTable.startValue then booleanTable.table[7] else booleanTable.table[7] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[8,2] = if booleanTable.startValue then 0.0 else 1.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[9,1] = if booleanTable.startValue then booleanTable.table[8] else booleanTable.table[8] "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   final parameter Real booleanTable.combiTimeTable.table[9,2] = if booleanTable.startValue then 1.0 else 0.0 "Table matrix (time = first column; e.g., table=[0, 0; 1, 1; 2, 4])";
//   parameter String booleanTable.combiTimeTable.tableName = "NoName" "Table name on file or in function usertab (see docu)";
//   parameter String booleanTable.combiTimeTable.fileName = "NoName" "File where matrix is stored";
//   parameter Boolean booleanTable.combiTimeTable.verboseRead = true "= true, if info message that file is loading is to be printed";
//   final parameter Integer booleanTable.combiTimeTable.columns[1] = 2 "Columns of table to be interpolated";
//   final parameter enumeration(LinearSegments, ContinuousDerivative, ConstantSegments, MonotoneContinuousDerivative1, MonotoneContinuousDerivative2) booleanTable.combiTimeTable.smoothness = Modelica.Blocks.Types.Smoothness.ConstantSegments "Smoothness of table interpolation";
//   final parameter enumeration(HoldLastPoint, LastTwoPoints, Periodic, NoExtrapolation) booleanTable.combiTimeTable.extrapolation = Modelica.Blocks.Types.Extrapolation.HoldLastPoint "Extrapolation of data outside the definition range";
//   final parameter Real booleanTable.combiTimeTable.timeScale(quantity = "Time", unit = "s", min = 1e-15) = 1.0 "Time scale of first table column";
//   parameter Real booleanTable.combiTimeTable.offset[1] = 0.0 "Offsets of output signals";
//   final parameter Real booleanTable.combiTimeTable.startTime(quantity = "Time", unit = "s") = booleanTable.startTime "Output = offset for time < startTime";
//   final parameter Real booleanTable.combiTimeTable.shiftTime(quantity = "Time", unit = "s") = booleanTable.shiftTime "Shift time of first table column";
//   parameter enumeration(Always, AtDiscontinuities, NoTimeEvents) booleanTable.combiTimeTable.timeEvents = Modelica.Blocks.Types.TimeEvents.Always "Time event handling of table interpolation";
//   final parameter Boolean booleanTable.combiTimeTable.verboseExtrapolation = false "= true, if warning messages are to be printed if time is outside the table definition range";
//   final parameter Real booleanTable.combiTimeTable.t_min(quantity = "Time", unit = "s") = booleanTable.combiTimeTable.t_minScaled "Minimum abscissa value defined in table";
//   final parameter Real booleanTable.combiTimeTable.t_max(quantity = "Time", unit = "s") = booleanTable.combiTimeTable.t_maxScaled "Maximum abscissa value defined in table";
//   final parameter Real booleanTable.combiTimeTable.t_minScaled = Modelica.Blocks.Tables.Internal.getTimeTableTmin(booleanTable.combiTimeTable.tableID) "Minimum (scaled) abscissa value defined in table";
//   final parameter Real booleanTable.combiTimeTable.t_maxScaled = Modelica.Blocks.Tables.Internal.getTimeTableTmax(booleanTable.combiTimeTable.tableID) "Maximum (scaled) abscissa value defined in table";
//   protected final parameter Real booleanTable.combiTimeTable.p_offset[1] = booleanTable.combiTimeTable.offset[1] "Offsets of output signals";
//   protected parameter Modelica.Blocks.Types.ExternalCombiTimeTable booleanTable.combiTimeTable.tableID = Modelica.Blocks.Types.ExternalCombiTimeTable.constructor("NoName", "NoName", booleanTable.combiTimeTable.table, booleanTable.combiTimeTable.startTime, booleanTable.combiTimeTable.columns, Modelica.Blocks.Types.Smoothness.ConstantSegments, Modelica.Blocks.Types.Extrapolation.HoldLastPoint, booleanTable.combiTimeTable.shiftTime, Modelica.Blocks.Types.TimeEvents.Always, false) "External table object";
//   protected discrete Real booleanTable.combiTimeTable.nextTimeEvent(quantity = "Time", unit = "s", start = 0.0, fixed = true) "Next time event instant";
//   protected discrete Real booleanTable.combiTimeTable.nextTimeEventScaled(start = 0.0, fixed = true) "Next scaled time event instant";
//   protected Real booleanTable.combiTimeTable.timeScaled "Scaled time";
//   Real booleanTable.realToBoolean.u "Connector of Real input signal";
//   Boolean booleanTable.realToBoolean.y "Connector of Boolean output signal";
//   parameter Real booleanTable.realToBoolean.threshold = 0.5 "Output signal y is true, if input u >= threshold";
//   protected final parameter Integer booleanTable.n = 8 "Number of table points";
//   parameter Real logicalDelayEquations.delayTime(quantity = "Time", unit = "s", min = 0.0) = 0.1 "Time delay";
//   Boolean logicalDelayEquations.u;
//   Boolean logicalDelayEquations.y1;
//   Boolean logicalDelayEquations.y2;
//   protected discrete Real logicalDelayEquations.tSwitch(quantity = "Time", unit = "s");
//   parameter Real logicalDelayStateGraph.delayTime(quantity = "Time", unit = "s", min = 0.0) = 0.1 "Time delay";
//   Boolean logicalDelayStateGraph.u;
//   Boolean logicalDelayStateGraph.y1;
//   Boolean logicalDelayStateGraph.y2;
//   Boolean logicalDelayStateGraph.not1.u "Connector of Boolean input signal";
//   Boolean logicalDelayStateGraph.not1.y "Connector of Boolean output signal";
//   Boolean logicalDelayStateGraph.not2.u "Connector of Boolean input signal";
//   Boolean logicalDelayStateGraph.not2.y "Connector of Boolean output signal";
//   final parameter Integer logicalDelayStateGraph.Y1D0.nIn(min = 0) = 1 "Number of input connections";
//   final parameter Integer logicalDelayStateGraph.Y1D0.nOut(min = 0) = 1 "Number of output connections";
//   final parameter Boolean logicalDelayStateGraph.Y1D0.initialStep = true "=true, if initial step (graph starts at this step)";
//   final parameter Boolean logicalDelayStateGraph.Y1D0.use_activePort = true "=true, if activePort enabled";
//   Boolean logicalDelayStateGraph.Y1D0.inPort[1].fire "true, if transition fires and step is activated";
//   Boolean logicalDelayStateGraph.Y1D0.inPort[1].node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.Y1D0.inPort[1].node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.Y1D0.inPort[1].checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible";
//   Boolean logicalDelayStateGraph.Y1D0.inPort[1].checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.Y1D0.outPort[1].available "= true, if step is active and firing is possible";
//   Boolean logicalDelayStateGraph.Y1D0.outPort[1].fire "= true, if transition fires and step is deactivated";
//   Boolean logicalDelayStateGraph.Y1D0.outPort[1].node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.Y1D0.outPort[1].node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.Y1D0.outPort[1].checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.Y1D0.activePort = logicalDelayStateGraph.Y1D0.active "= true if step is active, otherwise the step is not active";
//   Boolean logicalDelayStateGraph.Y1D0.active "= true if step is active, otherwise the step is not active";
//   protected Boolean logicalDelayStateGraph.Y1D0.newActive(start = true, fixed = true) "Value of active in the next iteration";
//   protected Boolean logicalDelayStateGraph.Y1D0.oldActive(start = true, fixed = true) "Value of active when CompositeStep was aborted";
//   protected Boolean logicalDelayStateGraph.Y1D0.node.suspend "= true, if the composite step is terminated via a suspend port";
//   protected Boolean logicalDelayStateGraph.Y1D0.node.resume "= true, if the composite step is entered via a resume port";
//   protected Boolean logicalDelayStateGraph.Y1D0.inport_fire;
//   protected Boolean logicalDelayStateGraph.Y1D0.outport_fire;
//   final parameter Boolean logicalDelayStateGraph.T1.use_conditionPort = true "= true, if conditionPort enabled";
//   Boolean logicalDelayStateGraph.T1.condition = true "Fire condition (time varying Boolean expression)";
//   final parameter Boolean logicalDelayStateGraph.T1.delayedTransition = false "= true, if transition fires after waitTime";
//   parameter Real logicalDelayStateGraph.T1.waitTime(quantity = "Time", unit = "s") = 0.0 "Wait time before transition fires (> 0 required)";
//   final parameter Boolean logicalDelayStateGraph.T1.use_firePort = false "= true, if firePort enabled";
//   final parameter Boolean logicalDelayStateGraph.T1.loopCheck = true "= true, if one delayed transition per loop required";
//   Boolean logicalDelayStateGraph.T1.inPort.available "= true, if step connected to the transition input is active and firing is possible";
//   Boolean logicalDelayStateGraph.T1.inPort.fire "= true, if transition fires and the step connected to the transition input is deactivated";
//   Boolean logicalDelayStateGraph.T1.inPort.node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.T1.inPort.node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.T1.inPort.checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.T1.outPort.fire "true, if transition fires and step connected to the transition output becomes active";
//   Boolean logicalDelayStateGraph.T1.outPort.node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.T1.outPort.node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.T1.outPort.checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible";
//   Boolean logicalDelayStateGraph.T1.outPort.checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.T1.conditionPort "Fire condition as Boolean input.";
//   Boolean logicalDelayStateGraph.T1.fire "= true, if transition fires";
//   Boolean logicalDelayStateGraph.T1.enableFire "= true, if firing condition is true";
//   protected constant Real logicalDelayStateGraph.T1.minimumWaitTime(quantity = "Time", unit = "s") = 1e-13;
//   protected Real logicalDelayStateGraph.T1.t_start(quantity = "Time", unit = "s") "Time instant at which the transition would fire, if waitTime would be zero";
//   protected Boolean logicalDelayStateGraph.T1.localCondition;
//   final parameter Integer logicalDelayStateGraph.Y0D0.nIn(min = 0) = 2 "Number of input connections";
//   final parameter Integer logicalDelayStateGraph.Y0D0.nOut(min = 0) = 2 "Number of output connections";
//   final parameter Boolean logicalDelayStateGraph.Y0D0.initialStep = false "=true, if initial step (graph starts at this step)";
//   final parameter Boolean logicalDelayStateGraph.Y0D0.use_activePort = false "=true, if activePort enabled";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[1].fire "true, if transition fires and step is activated";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[1].node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[1].node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[1].checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[1].checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[2].fire "true, if transition fires and step is activated";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[2].node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[2].node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[2].checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible";
//   Boolean logicalDelayStateGraph.Y0D0.inPort[2].checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[1].available "= true, if step is active and firing is possible";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[1].fire "= true, if transition fires and step is deactivated";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[1].node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[1].node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[1].checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[2].available "= true, if step is active and firing is possible";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[2].fire "= true, if transition fires and step is deactivated";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[2].node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[2].node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.Y0D0.outPort[2].checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.Y0D0.active "= true if step is active, otherwise the step is not active";
//   protected Boolean logicalDelayStateGraph.Y0D0.newActive(start = false, fixed = true) "Value of active in the next iteration";
//   protected Boolean logicalDelayStateGraph.Y0D0.oldActive(start = false, fixed = true) "Value of active when CompositeStep was aborted";
//   protected Boolean logicalDelayStateGraph.Y0D0.node.suspend "= true, if the composite step is terminated via a suspend port";
//   protected Boolean logicalDelayStateGraph.Y0D0.node.resume "= true, if the composite step is entered via a resume port";
//   protected Boolean logicalDelayStateGraph.Y0D0.inport_fire;
//   protected Boolean logicalDelayStateGraph.Y0D0.outport_fire;
//   final parameter Boolean logicalDelayStateGraph.T2.use_conditionPort = true "= true, if conditionPort enabled";
//   Boolean logicalDelayStateGraph.T2.condition = true "Fire condition (time varying Boolean expression)";
//   final parameter Boolean logicalDelayStateGraph.T2.delayedTransition = true "= true, if transition fires after waitTime";
//   parameter Real logicalDelayStateGraph.T2.waitTime(quantity = "Time", unit = "s") = logicalDelayStateGraph.delayTime "Wait time before transition fires (> 0 required)";
//   final parameter Boolean logicalDelayStateGraph.T2.use_firePort = false "= true, if firePort enabled";
//   final parameter Boolean logicalDelayStateGraph.T2.loopCheck = true "= true, if one delayed transition per loop required";
//   Boolean logicalDelayStateGraph.T2.inPort.available "= true, if step connected to the transition input is active and firing is possible";
//   Boolean logicalDelayStateGraph.T2.inPort.fire "= true, if transition fires and the step connected to the transition input is deactivated";
//   Boolean logicalDelayStateGraph.T2.inPort.node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.T2.inPort.node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.T2.inPort.checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.T2.outPort.fire "true, if transition fires and step connected to the transition output becomes active";
//   Boolean logicalDelayStateGraph.T2.outPort.node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.T2.outPort.node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.T2.outPort.checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible";
//   Boolean logicalDelayStateGraph.T2.outPort.checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.T2.conditionPort "Fire condition as Boolean input.";
//   Boolean logicalDelayStateGraph.T2.fire "= true, if transition fires";
//   Boolean logicalDelayStateGraph.T2.enableFire "= true, if firing condition is true";
//   protected constant Real logicalDelayStateGraph.T2.minimumWaitTime(quantity = "Time", unit = "s") = 1e-13;
//   protected Real logicalDelayStateGraph.T2.t_start(quantity = "Time", unit = "s") "Time instant at which the transition would fire, if waitTime would be zero";
//   protected Boolean logicalDelayStateGraph.T2.localCondition;
//   final parameter Integer logicalDelayStateGraph.Y0D1.nIn(min = 0) = 1 "Number of input connections";
//   final parameter Integer logicalDelayStateGraph.Y0D1.nOut(min = 0) = 1 "Number of output connections";
//   final parameter Boolean logicalDelayStateGraph.Y0D1.initialStep = false "=true, if initial step (graph starts at this step)";
//   final parameter Boolean logicalDelayStateGraph.Y0D1.use_activePort = true "=true, if activePort enabled";
//   Boolean logicalDelayStateGraph.Y0D1.inPort[1].fire "true, if transition fires and step is activated";
//   Boolean logicalDelayStateGraph.Y0D1.inPort[1].node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.Y0D1.inPort[1].node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.Y0D1.inPort[1].checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible";
//   Boolean logicalDelayStateGraph.Y0D1.inPort[1].checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.Y0D1.outPort[1].available "= true, if step is active and firing is possible";
//   Boolean logicalDelayStateGraph.Y0D1.outPort[1].fire "= true, if transition fires and step is deactivated";
//   Boolean logicalDelayStateGraph.Y0D1.outPort[1].node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.Y0D1.outPort[1].node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.Y0D1.outPort[1].checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.Y0D1.activePort = logicalDelayStateGraph.Y0D1.active "= true if step is active, otherwise the step is not active";
//   Boolean logicalDelayStateGraph.Y0D1.active "= true if step is active, otherwise the step is not active";
//   protected Boolean logicalDelayStateGraph.Y0D1.newActive(start = false, fixed = true) "Value of active in the next iteration";
//   protected Boolean logicalDelayStateGraph.Y0D1.oldActive(start = false, fixed = true) "Value of active when CompositeStep was aborted";
//   protected Boolean logicalDelayStateGraph.Y0D1.node.suspend "= true, if the composite step is terminated via a suspend port";
//   protected Boolean logicalDelayStateGraph.Y0D1.node.resume "= true, if the composite step is entered via a resume port";
//   protected Boolean logicalDelayStateGraph.Y0D1.inport_fire;
//   protected Boolean logicalDelayStateGraph.Y0D1.outport_fire;
//   final parameter Boolean logicalDelayStateGraph.T3.use_conditionPort = true "= true, if conditionPort enabled";
//   Boolean logicalDelayStateGraph.T3.condition = true "Fire condition (time varying Boolean expression)";
//   final parameter Boolean logicalDelayStateGraph.T3.delayedTransition = false "= true, if transition fires after waitTime";
//   parameter Real logicalDelayStateGraph.T3.waitTime(quantity = "Time", unit = "s") = 0.0 "Wait time before transition fires (> 0 required)";
//   final parameter Boolean logicalDelayStateGraph.T3.use_firePort = false "= true, if firePort enabled";
//   final parameter Boolean logicalDelayStateGraph.T3.loopCheck = true "= true, if one delayed transition per loop required";
//   Boolean logicalDelayStateGraph.T3.inPort.available "= true, if step connected to the transition input is active and firing is possible";
//   Boolean logicalDelayStateGraph.T3.inPort.fire "= true, if transition fires and the step connected to the transition input is deactivated";
//   Boolean logicalDelayStateGraph.T3.inPort.node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.T3.inPort.node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.T3.inPort.checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.T3.outPort.fire "true, if transition fires and step connected to the transition output becomes active";
//   Boolean logicalDelayStateGraph.T3.outPort.node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.T3.outPort.node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.T3.outPort.checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible";
//   Boolean logicalDelayStateGraph.T3.outPort.checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.T3.conditionPort "Fire condition as Boolean input.";
//   Boolean logicalDelayStateGraph.T3.fire "= true, if transition fires";
//   Boolean logicalDelayStateGraph.T3.enableFire "= true, if firing condition is true";
//   protected constant Real logicalDelayStateGraph.T3.minimumWaitTime(quantity = "Time", unit = "s") = 1e-13;
//   protected Real logicalDelayStateGraph.T3.t_start(quantity = "Time", unit = "s") "Time instant at which the transition would fire, if waitTime would be zero";
//   protected Boolean logicalDelayStateGraph.T3.localCondition;
//   final parameter Boolean logicalDelayStateGraph.T4.use_conditionPort = true "= true, if conditionPort enabled";
//   Boolean logicalDelayStateGraph.T4.condition = true "Fire condition (time varying Boolean expression)";
//   final parameter Boolean logicalDelayStateGraph.T4.delayedTransition = true "= true, if transition fires after waitTime";
//   parameter Real logicalDelayStateGraph.T4.waitTime(quantity = "Time", unit = "s") = logicalDelayStateGraph.delayTime "Wait time before transition fires (> 0 required)";
//   final parameter Boolean logicalDelayStateGraph.T4.use_firePort = false "= true, if firePort enabled";
//   final parameter Boolean logicalDelayStateGraph.T4.loopCheck = true "= true, if one delayed transition per loop required";
//   Boolean logicalDelayStateGraph.T4.inPort.available "= true, if step connected to the transition input is active and firing is possible";
//   Boolean logicalDelayStateGraph.T4.inPort.fire "= true, if transition fires and the step connected to the transition input is deactivated";
//   Boolean logicalDelayStateGraph.T4.inPort.node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.T4.inPort.node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.T4.inPort.checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.T4.outPort.fire "true, if transition fires and step connected to the transition output becomes active";
//   Boolean logicalDelayStateGraph.T4.outPort.node.suspend "= true, if the composite step is terminated via a suspend port";
//   Boolean logicalDelayStateGraph.T4.outPort.node.resume "= true, if the composite step is entered via a resume port";
//   Boolean logicalDelayStateGraph.T4.outPort.checkUnaryConnection "Is used to guarantee that only 1:1 connections are possible";
//   Boolean logicalDelayStateGraph.T4.outPort.checkOneDelayedTransitionPerLoop "Is used to check that every connection loop has at least one delayed transition";
//   Boolean logicalDelayStateGraph.T4.conditionPort "Fire condition as Boolean input.";
//   Boolean logicalDelayStateGraph.T4.fire "= true, if transition fires";
//   Boolean logicalDelayStateGraph.T4.enableFire "= true, if firing condition is true";
//   protected constant Real logicalDelayStateGraph.T4.minimumWaitTime(quantity = "Time", unit = "s") = 1e-13;
//   protected Real logicalDelayStateGraph.T4.t_start(quantity = "Time", unit = "s") "Time instant at which the transition would fire, if waitTime would be zero";
//   protected Boolean logicalDelayStateGraph.T4.localCondition;
// initial equation
//   logicalDelayEquations.tSwitch = time - 2.0 * logicalDelayEquations.delayTime;
//   pre(logicalDelayStateGraph.T1.enableFire) = false;
//   pre(logicalDelayStateGraph.T2.enableFire) = false;
//   pre(logicalDelayStateGraph.T2.t_start) = 0.0;
//   pre(logicalDelayStateGraph.T3.enableFire) = false;
//   pre(logicalDelayStateGraph.T4.enableFire) = false;
//   pre(logicalDelayStateGraph.T4.t_start) = 0.0;
// initial algorithm
//   Test_total.booleanTable.isValidTable(booleanTable.table);
// equation
//   booleanTable.combiTimeTable.y[1] = booleanTable.realToBoolean.u;
//   booleanTable.realToBoolean.y = booleanTable.y;
//   logicalDelayStateGraph.T1.conditionPort = logicalDelayStateGraph.T1.localCondition;
//   logicalDelayStateGraph.T2.conditionPort = logicalDelayStateGraph.T2.localCondition;
//   logicalDelayStateGraph.T3.conditionPort = logicalDelayStateGraph.T3.localCondition;
//   logicalDelayStateGraph.T4.conditionPort = logicalDelayStateGraph.T4.localCondition;
//   logicalDelayStateGraph.not2.y = logicalDelayStateGraph.y1;
//   logicalDelayStateGraph.Y1D0.activePort = logicalDelayStateGraph.not2.u;
//   logicalDelayStateGraph.Y1D0.outPort[1].available = logicalDelayStateGraph.T1.inPort.available;
//   logicalDelayStateGraph.Y1D0.outPort[1].checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.T1.inPort.checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.Y1D0.outPort[1].fire = logicalDelayStateGraph.T1.inPort.fire;
//   logicalDelayStateGraph.Y0D1.activePort = logicalDelayStateGraph.y2;
//   logicalDelayStateGraph.T2.outPort.checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.Y0D1.inPort[1].checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.T2.outPort.checkUnaryConnection = logicalDelayStateGraph.Y0D1.inPort[1].checkUnaryConnection;
//   logicalDelayStateGraph.T2.outPort.fire = logicalDelayStateGraph.Y0D1.inPort[1].fire;
//   logicalDelayStateGraph.Y0D1.outPort[1].available = logicalDelayStateGraph.T3.inPort.available;
//   logicalDelayStateGraph.Y0D1.outPort[1].checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.T3.inPort.checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.Y0D1.outPort[1].fire = logicalDelayStateGraph.T3.inPort.fire;
//   logicalDelayStateGraph.Y0D1.outPort[1].node.suspend = logicalDelayStateGraph.T3.inPort.node.suspend;
//   logicalDelayStateGraph.Y0D1.outPort[1].node.resume = logicalDelayStateGraph.T3.inPort.node.resume;
//   logicalDelayStateGraph.not1.y = logicalDelayStateGraph.T4.conditionPort;
//   logicalDelayStateGraph.not1.y = logicalDelayStateGraph.T3.conditionPort;
//   logicalDelayStateGraph.T4.outPort.checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.Y1D0.inPort[1].checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.T4.outPort.checkUnaryConnection = logicalDelayStateGraph.Y1D0.inPort[1].checkUnaryConnection;
//   logicalDelayStateGraph.T4.outPort.fire = logicalDelayStateGraph.Y1D0.inPort[1].fire;
//   logicalDelayStateGraph.T4.outPort.node.suspend = logicalDelayStateGraph.Y1D0.inPort[1].node.suspend;
//   logicalDelayStateGraph.T4.outPort.node.resume = logicalDelayStateGraph.Y1D0.inPort[1].node.resume;
//   logicalDelayStateGraph.u = logicalDelayStateGraph.T2.conditionPort;
//   logicalDelayStateGraph.u = logicalDelayStateGraph.T1.conditionPort;
//   logicalDelayStateGraph.u = logicalDelayStateGraph.not1.u;
//   logicalDelayStateGraph.T3.outPort.checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.Y0D0.inPort[1].checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.T3.outPort.checkUnaryConnection = logicalDelayStateGraph.Y0D0.inPort[1].checkUnaryConnection;
//   logicalDelayStateGraph.T3.outPort.fire = logicalDelayStateGraph.Y0D0.inPort[1].fire;
//   logicalDelayStateGraph.T3.outPort.node.suspend = logicalDelayStateGraph.Y0D0.inPort[1].node.suspend;
//   logicalDelayStateGraph.T3.outPort.node.resume = logicalDelayStateGraph.Y0D0.inPort[1].node.resume;
//   logicalDelayStateGraph.Y0D0.inPort[2].checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.T1.outPort.checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.Y0D0.inPort[2].checkUnaryConnection = logicalDelayStateGraph.T1.outPort.checkUnaryConnection;
//   logicalDelayStateGraph.Y0D0.inPort[2].fire = logicalDelayStateGraph.T1.outPort.fire;
//   logicalDelayStateGraph.Y0D0.inPort[2].node.suspend = logicalDelayStateGraph.T1.outPort.node.suspend;
//   logicalDelayStateGraph.Y0D0.inPort[2].node.resume = logicalDelayStateGraph.T1.outPort.node.resume;
//   logicalDelayStateGraph.Y0D0.outPort[1].available = logicalDelayStateGraph.T4.inPort.available;
//   logicalDelayStateGraph.Y0D0.outPort[1].checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.T4.inPort.checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.Y0D0.outPort[1].fire = logicalDelayStateGraph.T4.inPort.fire;
//   logicalDelayStateGraph.Y0D0.outPort[1].node.suspend = logicalDelayStateGraph.T4.inPort.node.suspend;
//   logicalDelayStateGraph.Y0D0.outPort[1].node.resume = logicalDelayStateGraph.T4.inPort.node.resume;
//   logicalDelayStateGraph.Y0D0.outPort[2].available = logicalDelayStateGraph.T2.inPort.available;
//   logicalDelayStateGraph.Y0D0.outPort[2].checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.T2.inPort.checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.Y0D0.outPort[2].fire = logicalDelayStateGraph.T2.inPort.fire;
//   logicalDelayStateGraph.Y0D0.outPort[2].node.suspend = logicalDelayStateGraph.T2.inPort.node.suspend;
//   logicalDelayStateGraph.Y0D0.outPort[2].node.resume = logicalDelayStateGraph.T2.inPort.node.resume;
//   booleanTable.y = logicalDelayStateGraph.u;
//   booleanTable.y = logicalDelayEquations.u;
//   booleanTable.combiTimeTable.timeScaled = time;
//   when {time >= pre(booleanTable.combiTimeTable.nextTimeEvent), initial()} then
//     booleanTable.combiTimeTable.nextTimeEventScaled = Modelica.Blocks.Tables.Internal.getNextTimeEvent(booleanTable.combiTimeTable.tableID, booleanTable.combiTimeTable.timeScaled);
//     booleanTable.combiTimeTable.nextTimeEvent = if booleanTable.combiTimeTable.nextTimeEventScaled < 1e60 then booleanTable.combiTimeTable.nextTimeEventScaled else 1e60;
//   end when;
//   booleanTable.combiTimeTable.y[1] = booleanTable.combiTimeTable.p_offset[1] + Modelica.Blocks.Tables.Internal.getTimeTableValueNoDer(booleanTable.combiTimeTable.tableID, 1, booleanTable.combiTimeTable.timeScaled, booleanTable.combiTimeTable.nextTimeEventScaled, pre(booleanTable.combiTimeTable.nextTimeEventScaled));
//   booleanTable.realToBoolean.y = booleanTable.realToBoolean.u >= booleanTable.realToBoolean.threshold;
//   when {logicalDelayEquations.u, not logicalDelayEquations.u} then
//     logicalDelayEquations.tSwitch = time;
//   end when;
//   logicalDelayEquations.y1 = if logicalDelayEquations.u then true else not time >= logicalDelayEquations.tSwitch + logicalDelayEquations.delayTime;
//   logicalDelayEquations.y2 = if not logicalDelayEquations.u then false else time >= logicalDelayEquations.tSwitch + logicalDelayEquations.delayTime;
//   logicalDelayStateGraph.not1.y = not logicalDelayStateGraph.not1.u;
//   logicalDelayStateGraph.not2.y = not logicalDelayStateGraph.not2.u;
//   logicalDelayStateGraph.Y1D0.inport_fire = Modelica_StateGraph2.Blocks.BooleanFunctions.anyTrue({logicalDelayStateGraph.Y1D0.inPort[1].fire});
//   logicalDelayStateGraph.Y1D0.outport_fire = Modelica_StateGraph2.Blocks.BooleanFunctions.anyTrue({logicalDelayStateGraph.Y1D0.outPort[1].fire});
//   logicalDelayStateGraph.Y1D0.newActive = if logicalDelayStateGraph.Y1D0.node.resume then logicalDelayStateGraph.Y1D0.oldActive else logicalDelayStateGraph.Y1D0.inport_fire or logicalDelayStateGraph.Y1D0.active and not logicalDelayStateGraph.Y1D0.outport_fire and not logicalDelayStateGraph.Y1D0.node.suspend;
//   logicalDelayStateGraph.Y1D0.active = pre(logicalDelayStateGraph.Y1D0.newActive);
//   when logicalDelayStateGraph.Y1D0.node.suspend then
//     logicalDelayStateGraph.Y1D0.oldActive = logicalDelayStateGraph.Y1D0.active;
//   end when;
//   logicalDelayStateGraph.Y1D0.outPort[1].available = logicalDelayStateGraph.Y1D0.active and not logicalDelayStateGraph.Y1D0.node.suspend;
//   logicalDelayStateGraph.Y1D0.inPort[1].checkUnaryConnection = true;
//   logicalDelayStateGraph.Y1D0.outPort[1].checkOneDelayedTransitionPerLoop = Modelica_StateGraph2.Internal.Utilities.propagateLoopCheck({logicalDelayStateGraph.Y1D0.inPort[1].checkOneDelayedTransitionPerLoop});
//   logicalDelayStateGraph.Y1D0.inPort[1].node = logicalDelayStateGraph.Y1D0.node;
//   logicalDelayStateGraph.Y1D0.node.suspend = false;
//   logicalDelayStateGraph.Y1D0.node.resume = false;
//   logicalDelayStateGraph.Y1D0.outPort[1].node = logicalDelayStateGraph.Y1D0.node;
//   logicalDelayStateGraph.T1.enableFire = logicalDelayStateGraph.T1.localCondition and logicalDelayStateGraph.T1.inPort.available;
//   logicalDelayStateGraph.T1.t_start = 0.0;
//   logicalDelayStateGraph.T1.fire = logicalDelayStateGraph.T1.enableFire;
//   logicalDelayStateGraph.T1.outPort.checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.T1.inPort.checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.T1.inPort.fire = logicalDelayStateGraph.T1.fire;
//   logicalDelayStateGraph.T1.outPort.fire = logicalDelayStateGraph.T1.fire;
//   logicalDelayStateGraph.T1.outPort.node = logicalDelayStateGraph.T1.inPort.node;
//   logicalDelayStateGraph.Y0D0.inport_fire = Modelica_StateGraph2.Blocks.BooleanFunctions.anyTrue({logicalDelayStateGraph.Y0D0.inPort[1].fire, logicalDelayStateGraph.Y0D0.inPort[2].fire});
//   logicalDelayStateGraph.Y0D0.outport_fire = Modelica_StateGraph2.Blocks.BooleanFunctions.anyTrue({logicalDelayStateGraph.Y0D0.outPort[1].fire, logicalDelayStateGraph.Y0D0.outPort[2].fire});
//   logicalDelayStateGraph.Y0D0.newActive = if logicalDelayStateGraph.Y0D0.node.resume then logicalDelayStateGraph.Y0D0.oldActive else logicalDelayStateGraph.Y0D0.inport_fire or logicalDelayStateGraph.Y0D0.active and not logicalDelayStateGraph.Y0D0.outport_fire and not logicalDelayStateGraph.Y0D0.node.suspend;
//   logicalDelayStateGraph.Y0D0.active = pre(logicalDelayStateGraph.Y0D0.newActive);
//   when logicalDelayStateGraph.Y0D0.node.suspend then
//     logicalDelayStateGraph.Y0D0.oldActive = logicalDelayStateGraph.Y0D0.active;
//   end when;
//   logicalDelayStateGraph.Y0D0.outPort[1].available = logicalDelayStateGraph.Y0D0.active and not logicalDelayStateGraph.Y0D0.node.suspend;
//   logicalDelayStateGraph.Y0D0.outPort[2].available = logicalDelayStateGraph.Y0D0.outPort[1].available and not logicalDelayStateGraph.Y0D0.outPort[1].fire and not logicalDelayStateGraph.Y0D0.node.suspend;
//   logicalDelayStateGraph.Y0D0.inPort[1].checkUnaryConnection = true;
//   logicalDelayStateGraph.Y0D0.inPort[2].checkUnaryConnection = true;
//   logicalDelayStateGraph.Y0D0.outPort[1].checkOneDelayedTransitionPerLoop = Modelica_StateGraph2.Internal.Utilities.propagateLoopCheck({logicalDelayStateGraph.Y0D0.inPort[1].checkOneDelayedTransitionPerLoop, logicalDelayStateGraph.Y0D0.inPort[2].checkOneDelayedTransitionPerLoop});
//   logicalDelayStateGraph.Y0D0.outPort[2].checkOneDelayedTransitionPerLoop = Modelica_StateGraph2.Internal.Utilities.propagateLoopCheck({logicalDelayStateGraph.Y0D0.inPort[1].checkOneDelayedTransitionPerLoop, logicalDelayStateGraph.Y0D0.inPort[2].checkOneDelayedTransitionPerLoop});
//   logicalDelayStateGraph.Y0D0.inPort[1].node = logicalDelayStateGraph.Y0D0.node;
//   logicalDelayStateGraph.Y0D0.inPort[2].node = logicalDelayStateGraph.Y0D0.node;
//   logicalDelayStateGraph.Y0D0.outPort[1].node = logicalDelayStateGraph.Y0D0.node;
//   logicalDelayStateGraph.Y0D0.outPort[2].node = logicalDelayStateGraph.Y0D0.node;
//   logicalDelayStateGraph.T2.enableFire = logicalDelayStateGraph.T2.localCondition and logicalDelayStateGraph.T2.inPort.available;
//   when logicalDelayStateGraph.T2.enableFire then
//     logicalDelayStateGraph.T2.t_start = time;
//   end when;
//   logicalDelayStateGraph.T2.fire = logicalDelayStateGraph.T2.enableFire and time >= logicalDelayStateGraph.T2.t_start + logicalDelayStateGraph.T2.waitTime;
//   logicalDelayStateGraph.T2.outPort.checkOneDelayedTransitionPerLoop = true;
//   logicalDelayStateGraph.T2.inPort.fire = logicalDelayStateGraph.T2.fire;
//   logicalDelayStateGraph.T2.outPort.fire = logicalDelayStateGraph.T2.fire;
//   logicalDelayStateGraph.T2.outPort.node = logicalDelayStateGraph.T2.inPort.node;
//   assert(logicalDelayStateGraph.T2.waitTime > 1e-13, "Either set delayTransition = false, or set waitTime (= " + String(logicalDelayStateGraph.T2.waitTime, 6, 0, true) + ") > " + String(1e-13, 6, 0, true));
//   logicalDelayStateGraph.Y0D1.inport_fire = Modelica_StateGraph2.Blocks.BooleanFunctions.anyTrue({logicalDelayStateGraph.Y0D1.inPort[1].fire});
//   logicalDelayStateGraph.Y0D1.outport_fire = Modelica_StateGraph2.Blocks.BooleanFunctions.anyTrue({logicalDelayStateGraph.Y0D1.outPort[1].fire});
//   logicalDelayStateGraph.Y0D1.newActive = if logicalDelayStateGraph.Y0D1.node.resume then logicalDelayStateGraph.Y0D1.oldActive else logicalDelayStateGraph.Y0D1.inport_fire or logicalDelayStateGraph.Y0D1.active and not logicalDelayStateGraph.Y0D1.outport_fire and not logicalDelayStateGraph.Y0D1.node.suspend;
//   logicalDelayStateGraph.Y0D1.active = pre(logicalDelayStateGraph.Y0D1.newActive);
//   when logicalDelayStateGraph.Y0D1.node.suspend then
//     logicalDelayStateGraph.Y0D1.oldActive = logicalDelayStateGraph.Y0D1.active;
//   end when;
//   logicalDelayStateGraph.Y0D1.outPort[1].available = logicalDelayStateGraph.Y0D1.active and not logicalDelayStateGraph.Y0D1.node.suspend;
//   logicalDelayStateGraph.Y0D1.inPort[1].checkUnaryConnection = true;
//   logicalDelayStateGraph.Y0D1.outPort[1].checkOneDelayedTransitionPerLoop = Modelica_StateGraph2.Internal.Utilities.propagateLoopCheck({logicalDelayStateGraph.Y0D1.inPort[1].checkOneDelayedTransitionPerLoop});
//   logicalDelayStateGraph.Y0D1.inPort[1].node = logicalDelayStateGraph.Y0D1.node;
//   logicalDelayStateGraph.Y0D1.outPort[1].node = logicalDelayStateGraph.Y0D1.node;
//   logicalDelayStateGraph.T3.enableFire = logicalDelayStateGraph.T3.localCondition and logicalDelayStateGraph.T3.inPort.available;
//   logicalDelayStateGraph.T3.t_start = 0.0;
//   logicalDelayStateGraph.T3.fire = logicalDelayStateGraph.T3.enableFire;
//   logicalDelayStateGraph.T3.outPort.checkOneDelayedTransitionPerLoop = logicalDelayStateGraph.T3.inPort.checkOneDelayedTransitionPerLoop;
//   logicalDelayStateGraph.T3.inPort.fire = logicalDelayStateGraph.T3.fire;
//   logicalDelayStateGraph.T3.outPort.fire = logicalDelayStateGraph.T3.fire;
//   logicalDelayStateGraph.T3.outPort.node = logicalDelayStateGraph.T3.inPort.node;
//   logicalDelayStateGraph.T4.enableFire = logicalDelayStateGraph.T4.localCondition and logicalDelayStateGraph.T4.inPort.available;
//   when logicalDelayStateGraph.T4.enableFire then
//     logicalDelayStateGraph.T4.t_start = time;
//   end when;
//   logicalDelayStateGraph.T4.fire = logicalDelayStateGraph.T4.enableFire and time >= logicalDelayStateGraph.T4.t_start + logicalDelayStateGraph.T4.waitTime;
//   logicalDelayStateGraph.T4.outPort.checkOneDelayedTransitionPerLoop = true;
//   logicalDelayStateGraph.T4.inPort.fire = logicalDelayStateGraph.T4.fire;
//   logicalDelayStateGraph.T4.outPort.fire = logicalDelayStateGraph.T4.fire;
//   logicalDelayStateGraph.T4.outPort.node = logicalDelayStateGraph.T4.inPort.node;
//   assert(logicalDelayStateGraph.T4.waitTime > 1e-13, "Either set delayTransition = false, or set waitTime (= " + String(logicalDelayStateGraph.T4.waitTime, 6, 0, true) + ") > " + String(1e-13, 6, 0, true));
// end Test_total;
// [flattening/modelica/scodeinst/Ticket5821.mo:38:7-38:47:writable] Warning: The second argument 'logicalDelayStateGraph.Y1D0.node' of Connections.branch must have the form A.R, where A is a connector and R an over-determined type/record.
// [flattening/modelica/scodeinst/Ticket5821.mo:42:7-48:9:writable] Warning: Usage of non-standard operator (not specified in the Modelica specification): Connections.uniqueRoot. Functionality might be partially supported but is not guaranteed.
// [flattening/modelica/scodeinst/Ticket5821.mo:42:7-48:9:writable] Warning: The first argument 'logicalDelayStateGraph.Y1D0.node' of Connections.uniqueRoot must have the form A.R, where A is a connector and R an over-determined type/record.
// [flattening/modelica/scodeinst/Ticket5821.mo:59:7-59:48:writable] Warning: The first argument 'logicalDelayStateGraph.Y1D0.node' of Connections.branch must have the form A.R, where A is a connector and R an over-determined type/record.
// [flattening/modelica/scodeinst/Ticket5821.mo:38:7-38:47:writable] Warning: The second argument 'logicalDelayStateGraph.Y0D0.node' of Connections.branch must have the form A.R, where A is a connector and R an over-determined type/record.
// [flattening/modelica/scodeinst/Ticket5821.mo:42:7-48:9:writable] Warning: Usage of non-standard operator (not specified in the Modelica specification): Connections.uniqueRoot. Functionality might be partially supported but is not guaranteed.
// [flattening/modelica/scodeinst/Ticket5821.mo:42:7-48:9:writable] Warning: The first argument 'logicalDelayStateGraph.Y0D0.node' of Connections.uniqueRoot must have the form A.R, where A is a connector and R an over-determined type/record.
// [flattening/modelica/scodeinst/Ticket5821.mo:59:7-59:48:writable] Warning: The first argument 'logicalDelayStateGraph.Y0D0.node' of Connections.branch must have the form A.R, where A is a connector and R an over-determined type/record.
// [flattening/modelica/scodeinst/Ticket5821.mo:38:7-38:47:writable] Warning: The second argument 'logicalDelayStateGraph.Y0D1.node' of Connections.branch must have the form A.R, where A is a connector and R an over-determined type/record.
// [flattening/modelica/scodeinst/Ticket5821.mo:42:7-48:9:writable] Warning: Usage of non-standard operator (not specified in the Modelica specification): Connections.uniqueRoot. Functionality might be partially supported but is not guaranteed.
// [flattening/modelica/scodeinst/Ticket5821.mo:42:7-48:9:writable] Warning: The first argument 'logicalDelayStateGraph.Y0D1.node' of Connections.uniqueRoot must have the form A.R, where A is a connector and R an over-determined type/record.
// [flattening/modelica/scodeinst/Ticket5821.mo:59:7-59:48:writable] Warning: The first argument 'logicalDelayStateGraph.Y0D1.node' of Connections.branch must have the form A.R, where A is a connector and R an over-determined type/record.
//
// endResult
