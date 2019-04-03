//This code is generated from a ModelicaML model.

within BouncingBallExample;

model Ball
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="Ball", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  parameter Real g=9.81;
  parameter Real c= 0.90;
  Real height(start=0, fixed=true);
  Real v(start=10, fixed=true);
  record Ball_StateMachine_StateMachine_0
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-6.722,3.6841}, lineColor={0,85,127}, fillColor={85,170,255}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-75.0,-50.0},{75.0,50.0}}, radius=40),Rectangle(visible=true, origin={70.0,2.6556}, lineColor={85,170,255}, fillColor={0,85,127}, fillPattern=FillPattern.Solid, lineThickness=4, extent={{-26.8908,-25.0},{26.8908,25.0}})}));
    // lib properties STATE MACHINE
      Boolean active(fixed=true); // indicates if the state is active.
      Real timeAtActivation(fixed=true); // time when the state is entered.
      Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
      Boolean selfTransitionActivated(fixed=true);
    Boolean startBehaviour;
    // REGIONS instantiation
    StateMachine_0_Region_0 Region_0;

    // REGIONS classes
    record StateMachine_0_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState Falling;
      SimpleState Touching_the_ground;
      SimpleState Going_up;
      InitialState Initial_0;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end StateMachine_0_Region_0;

    // library: SIMPLE STATE
    record SimpleState
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-0.0,-0.1675}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-64.6031,-34.6638},{64.6031,34.6638}}, radius=40)}));
      // lib properties SIMPLE STATE
        Boolean active(fixed=true); // indicates if the state is active.
        Real timeAtActivation(fixed=true); // time when the state is entered.
        Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
        Boolean selfTransitionActivated(fixed=true);
    end SimpleState;

      // library: INITIAL STATE
    record InitialState
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-0.0,0.0}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-34.8134,-34.6638},{34.8134,34.6638}}, radius=40)}));
      // lib properties INITIAL STATE
        Boolean active; // indicates if the state is active.
        Real timeAtActivation(fixed=true); // time when the state is entered.
        Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
        Boolean selfTransitionActivated(fixed=true);
    end InitialState;

        // library: FINAL STATE
    record FinalState
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,0.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-34.8134,-34.6638},{34.8134,34.6638}}, radius=40),Rectangle(visible=true, origin={0.0,0.0}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-17.2767,-17.2024},{17.2767,17.2024}}, radius=40)}));
      // lib properties FINAL STATE
        Boolean active(fixed=true); // indicates if the state is active.
        Real timeAtActivation(fixed=true); // time when the state is entered.
        Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
        Boolean selfTransitionActivated;
    end FinalState;
  end Ball_StateMachine_StateMachine_0;



  // STATE MACHNE instantiation
    Ball_StateMachine_StateMachine_0 StateMachine_0;
  equation
    der(height) = v;
    der(v) = -g;

    when height<0 then
      reinit(v, -c*v);
    end when;
  algorithm
  algorithm

  /*** start behaviour code of state machine "StateMachine_0" ***/
  algorithm





    /* initial state machine "StateMachine_0" activation */
    StateMachine_0.startBehaviour:=true;
    when StateMachine_0.startBehaviour then
    StateMachine_0.active:=true;
      StateMachine_0.Region_0.Initial_0.active:=true;
    end when;
    when {StateMachine_0.active, StateMachine_0.selfTransitionActivated} then
        StateMachine_0.timeAtActivation := time;
        StateMachine_0.selfTransitionActivated := false;
      end when;
      if StateMachine_0.active then
        StateMachine_0.stime := time - StateMachine_0.timeAtActivation;
      end if;
      if not StateMachine_0.active then
        StateMachine_0.stime := 0;
      end if;
    /*** start behaviour code of region "StateMachine_0" ***/
  when {StateMachine_0.Region_0.Initial_0.active, StateMachine_0.Region_0.Initial_0.selfTransitionActivated} then
      StateMachine_0.Region_0.Initial_0.timeAtActivation := time;
      StateMachine_0.Region_0.Initial_0.selfTransitionActivated := false;
    end when;
    if StateMachine_0.Region_0.Initial_0.active then
      StateMachine_0.Region_0.Initial_0.stime := time - StateMachine_0.Region_0.Initial_0.timeAtActivation;
    end if;
    if not StateMachine_0.Region_0.Initial_0.active then
      StateMachine_0.Region_0.Initial_0.stime := 0;
    end if;
  when {StateMachine_0.Region_0.Falling.active, StateMachine_0.Region_0.Falling.selfTransitionActivated} then
      StateMachine_0.Region_0.Falling.timeAtActivation := time;
      StateMachine_0.Region_0.Falling.selfTransitionActivated := false;
    end when;
  when {StateMachine_0.Region_0.Touching_the_ground.active, StateMachine_0.Region_0.Touching_the_ground.selfTransitionActivated} then
      StateMachine_0.Region_0.Touching_the_ground.timeAtActivation := time;
      StateMachine_0.Region_0.Touching_the_ground.selfTransitionActivated := false;
    end when;
  when {StateMachine_0.Region_0.Going_up.active, StateMachine_0.Region_0.Going_up.selfTransitionActivated} then
      StateMachine_0.Region_0.Going_up.timeAtActivation := time;
      StateMachine_0.Region_0.Going_up.selfTransitionActivated := false;
    end when;
    if StateMachine_0.Region_0.Falling.active then
      StateMachine_0.Region_0.Falling.stime := time - StateMachine_0.Region_0.Falling.timeAtActivation;
    end if;
    if not StateMachine_0.Region_0.Falling.active then
      StateMachine_0.Region_0.Falling.stime := 0;
    end if;
    if StateMachine_0.Region_0.Touching_the_ground.active then
      StateMachine_0.Region_0.Touching_the_ground.stime := time - StateMachine_0.Region_0.Touching_the_ground.timeAtActivation;
    end if;
    if not StateMachine_0.Region_0.Touching_the_ground.active then
      StateMachine_0.Region_0.Touching_the_ground.stime := 0;
    end if;
    if StateMachine_0.Region_0.Going_up.active then
      StateMachine_0.Region_0.Going_up.stime := time - StateMachine_0.Region_0.Going_up.timeAtActivation;
    end if;
    if not StateMachine_0.Region_0.Going_up.active then
      StateMachine_0.Region_0.Going_up.stime := 0;
    end if;

  /*start transition code*/

  if(StateMachine_0.Region_0.Initial_0.active) then
     if true then
  StateMachine_0.Region_0.Initial_0.active := false;
  if v > 0 then
  StateMachine_0.Region_0.Going_up.active := true;
  else
  StateMachine_0.Region_0.Falling.active := true;
  end if;
    end if;
  end if;
  /*test the composite state is still active*/
  if(StateMachine_0.active  ) then
     if pre(StateMachine_0.Region_0.Falling.active) then
      if     height < 0 then
      StateMachine_0.Region_0.Falling.active := false;
        StateMachine_0.Region_0.Touching_the_ground.active := true;

      end if;
  elseif pre(StateMachine_0.Region_0.Touching_the_ground.active) then
      if     v > 0 then
      StateMachine_0.Region_0.Touching_the_ground.active := false;
        StateMachine_0.Region_0.Going_up.active := true;

      end if;
  elseif pre(StateMachine_0.Region_0.Going_up.active) then
      if     v < 0 then
      StateMachine_0.Region_0.Going_up.active := false;
        StateMachine_0.Region_0.Falling.active := true;

      end if;
  end if;
   end if;
  /*end transition code*/
  /*start do Code*/



  /*end do Code*/



  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "StateMachine_0"*/
    if (not StateMachine_0.active) then
    /* M@ start terminate code of region "StateMachine_0" ***/
    StateMachine_0.Region_0.Initial_0.active := false;
    StateMachine_0.Region_0.Falling.active := false;
    StateMachine_0.Region_0.Touching_the_ground.active := false;
    StateMachine_0.Region_0.Going_up.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    end if;
    /*end terminate code for state machine "StateMachine_0"*/
  /*** end behaviour code of state machine "StateMachine_0" ***/
  /* M@ reset debug variabels */
  StateMachine_0.Region_0.numberOfActiveStates := 0;

  /* M@ start debug code of region "----StateMachine_0" ***/
  if StateMachine_0.Region_0.Falling.active then
    StateMachine_0.Region_0.numberOfActiveStates := StateMachine_0.Region_0.numberOfActiveStates + 1;
  end if;
  if StateMachine_0.Region_0.Touching_the_ground.active then
    StateMachine_0.Region_0.numberOfActiveStates := StateMachine_0.Region_0.numberOfActiveStates + 1;
  end if;
  if StateMachine_0.Region_0.Going_up.active then
    StateMachine_0.Region_0.numberOfActiveStates := StateMachine_0.Region_0.numberOfActiveStates + 1;
  end if;
  if StateMachine_0.Region_0.Initial_0.active then
    StateMachine_0.Region_0.numberOfActiveStates := StateMachine_0.Region_0.numberOfActiveStates + 1;
  end if;

  /* M@ validation code start*/

  if StateMachine_0.active then
    assert(not (StateMachine_0.Region_0.numberOfActiveStates < 1), "StateMachine_0.Region_0 has no active states although the parent state is active!");
    assert(not (StateMachine_0.Region_0.numberOfActiveStates > 1), "StateMachine_0.Region_0 has multiple active states which are mutually exclusive!");
  end if;

  if not StateMachine_0.active then
    assert(StateMachine_0.Region_0.numberOfActiveStates == 0, "StateMachine_0.Region_0 has active states although the parent state is not active!");
  end if;

  /* M@ validation code start*/



  /* M@ end debug code of region "Region_0" ***/
end Ball;

