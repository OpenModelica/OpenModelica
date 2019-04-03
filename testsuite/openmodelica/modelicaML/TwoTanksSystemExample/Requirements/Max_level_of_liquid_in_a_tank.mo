//This code is generated from a ModelicaML model.

within TwoTanksSystemExample.Requirements;

model Max_level_of_liquid_in_a_tank
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="Max level of liquid in a tank", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«requirement»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="Rq", fontName="Arial")}));
  constant Real maxLevel= 0.8;
  parameter Real tank_height;
  input Real level;
  Boolean violated;
  record Max_level_of_liquid_in_a_tank_StateMachine_sm__evaluating_the_requirement
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-6.722,3.6841}, lineColor={0,85,127}, fillColor={85,170,255}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-75.0,-50.0},{75.0,50.0}}, radius=40),Rectangle(visible=true, origin={70.0,2.6556}, lineColor={85,170,255}, fillColor={0,85,127}, fillPattern=FillPattern.Solid, lineThickness=4, extent={{-26.8908,-25.0},{26.8908,25.0}})}));
    // lib properties STATE MACHINE
      Boolean active; // indicates if the state is active.
      Real timeAtActivation; // time when the state is entered.
      Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
      Boolean selfTransitionActivated;
    Boolean startBehaviour;
    // REGIONS instantiation
    sm__evaluating_the_requirement_Region_0 Region_0;

    // REGIONS classes
    record sm__evaluating_the_requirement_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState monitoring_the_level__no_violation;
      SimpleState violated;
      SimpleState violated_ones_or_several_times__continue_monitoring;
      InitialState Initial_0;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end sm__evaluating_the_requirement_Region_0;

    // library: SIMPLE STATE
    record SimpleState
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-0.0,-0.1675}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-64.6031,-34.6638},{64.6031,34.6638}}, radius=40)}));
      // lib properties SIMPLE STATE
        Boolean active; // indicates if the state is active.
        Real timeAtActivation; // time when the state is entered.
        Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
        Boolean selfTransitionActivated;
    end SimpleState;

      // library: INITIAL STATE
    record InitialState
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-0.0,0.0}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-34.8134,-34.6638},{34.8134,34.6638}}, radius=40)}));
      // lib properties INITIAL STATE
        Boolean active; // indicates if the state is active.
        Real timeAtActivation; // time when the state is entered.
        Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
        Boolean selfTransitionActivated;
    end InitialState;

        // library: FINAL STATE
    record FinalState
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,0.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-34.8134,-34.6638},{34.8134,34.6638}}, radius=40),Rectangle(visible=true, origin={0.0,0.0}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-17.2767,-17.2024},{17.2767,17.2024}}, radius=40)}));
      // lib properties FINAL STATE
        Boolean active; // indicates if the state is active.
        Real timeAtActivation; // time when the state is entered.
        Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
        Boolean selfTransitionActivated;
    end FinalState;
  end Max_level_of_liquid_in_a_tank_StateMachine_sm__evaluating_the_requirement;



  // STATE MACHNE instantiation
    Max_level_of_liquid_in_a_tank_StateMachine_sm__evaluating_the_requirement sm__evaluating_the_requirement;
  algorithm
  algorithm

  /*** start behaviour code of state machine "sm__evaluating_the_requirement" ***/
  algorithm





    /* initial state machine "sm__evaluating_the_requirement" activation */
    sm__evaluating_the_requirement.startBehaviour:=true;
    when sm__evaluating_the_requirement.startBehaviour then
    sm__evaluating_the_requirement.active:=true;
      sm__evaluating_the_requirement.Region_0.Initial_0.active:=true;
    end when;
    when {sm__evaluating_the_requirement.active, sm__evaluating_the_requirement.selfTransitionActivated} then
        sm__evaluating_the_requirement.timeAtActivation := time;
        sm__evaluating_the_requirement.selfTransitionActivated := false;
      end when;
      if sm__evaluating_the_requirement.active then
        sm__evaluating_the_requirement.stime := time - sm__evaluating_the_requirement.timeAtActivation;
      end if;
      if not sm__evaluating_the_requirement.active then
        sm__evaluating_the_requirement.stime := 0;
      end if;
    /*** start behaviour code of region "sm__evaluating_the_requirement" ***/
  when {sm__evaluating_the_requirement.Region_0.Initial_0.active, sm__evaluating_the_requirement.Region_0.Initial_0.selfTransitionActivated} then
      sm__evaluating_the_requirement.Region_0.Initial_0.timeAtActivation := time;
      sm__evaluating_the_requirement.Region_0.Initial_0.selfTransitionActivated := false;
    end when;
    if sm__evaluating_the_requirement.Region_0.Initial_0.active then
      sm__evaluating_the_requirement.Region_0.Initial_0.stime := time - sm__evaluating_the_requirement.Region_0.Initial_0.timeAtActivation;
    end if;
    if not sm__evaluating_the_requirement.Region_0.Initial_0.active then
      sm__evaluating_the_requirement.Region_0.Initial_0.stime := 0;
    end if;
  when {sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active, sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.selfTransitionActivated} then
      sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.timeAtActivation := time;
      sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.selfTransitionActivated := false;
    end when;
  when {sm__evaluating_the_requirement.Region_0.violated.active, sm__evaluating_the_requirement.Region_0.violated.selfTransitionActivated} then
      sm__evaluating_the_requirement.Region_0.violated.timeAtActivation := time;
      sm__evaluating_the_requirement.Region_0.violated.selfTransitionActivated := false;
    end when;
  when {sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active, sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.selfTransitionActivated} then
      sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.timeAtActivation := time;
      sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.selfTransitionActivated := false;
    end when;
    if sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active then
      sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.stime := time - sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.timeAtActivation;
    end if;
    if not sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active then
      sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.stime := 0;
    end if;
    if sm__evaluating_the_requirement.Region_0.violated.active then
      sm__evaluating_the_requirement.Region_0.violated.stime := time - sm__evaluating_the_requirement.Region_0.violated.timeAtActivation;
    end if;
    if not sm__evaluating_the_requirement.Region_0.violated.active then
      sm__evaluating_the_requirement.Region_0.violated.stime := 0;
    end if;
    if sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active then
      sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.stime := time - sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.timeAtActivation;
    end if;
    if not sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active then
      sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.stime := 0;
    end if;

  /*start transition code uml.StateMachine (name: sm: evaluating the requirement, visibility: <unset>) (isLeaf: false, isAbstract: false) (isActive: false) (isReentrant: false)*/

  if /*pre*/(sm__evaluating_the_requirement.Region_0.Initial_0.active) then
    sm__evaluating_the_requirement.Region_0.Initial_0.active := false;
    sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active := true;

  end if;
  /*test the composite state is still active*/
  /*1*/if(sm__evaluating_the_requirement.active  ) then
    /*2*/ if pre(sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active) then
      if     level > maxLevel * tank_height then
      sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active := false;
        sm__evaluating_the_requirement.Region_0.violated.active := true;

      end if; //test2
  elseif pre(sm__evaluating_the_requirement.Region_0.violated.active) then
      if     level < maxLevel * tank_height then
      sm__evaluating_the_requirement.Region_0.violated.active := false;
        sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active := true;

      end if; //test2
  elseif pre(sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active) then
      if     level > maxLevel * tank_height then
      sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active := false;
        sm__evaluating_the_requirement.Region_0.violated.active := true;

      end if; //test2
  /*2*/end if;
  /*1*/ end if; //test5
  /*end transition code*/
  /*start do Code*/
  if sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active then
    //state "sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation": do behavior
    violated := false;
  end if;
  if sm__evaluating_the_requirement.Region_0.violated.active then
    //state "sm__evaluating_the_requirement.Region_0.violated": do behavior
    violated := true;
  end if;
  if sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active then
    //state "sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring": do behavior
    violated := false;
  end if;
  /*end do Code*/



  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "sm__evaluating_the_requirement"*/
    if (not sm__evaluating_the_requirement.active) then
    /* M@ start terminate code of region "sm__evaluating_the_requirement" ***/
    sm__evaluating_the_requirement.Region_0.Initial_0.active := false;
    sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active := false;
    sm__evaluating_the_requirement.Region_0.violated.active := false;
    sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    end if;
    /*end terminate code for state machine "sm__evaluating_the_requirement"*/
  /*** end behaviour code of state machine "sm__evaluating_the_requirement" ***/
  /* M@ reset debug variabels */
  sm__evaluating_the_requirement.Region_0.numberOfActiveStates := 0;

  /* M@ start debug code of region "----sm__evaluating_the_requirement" ***/
  if sm__evaluating_the_requirement.Region_0.monitoring_the_level__no_violation.active then
    sm__evaluating_the_requirement.Region_0.numberOfActiveStates := sm__evaluating_the_requirement.Region_0.numberOfActiveStates + 1;
  end if;
  if sm__evaluating_the_requirement.Region_0.violated.active then
    sm__evaluating_the_requirement.Region_0.numberOfActiveStates := sm__evaluating_the_requirement.Region_0.numberOfActiveStates + 1;
  end if;
  if sm__evaluating_the_requirement.Region_0.violated_ones_or_several_times__continue_monitoring.active then
    sm__evaluating_the_requirement.Region_0.numberOfActiveStates := sm__evaluating_the_requirement.Region_0.numberOfActiveStates + 1;
  end if;
  if sm__evaluating_the_requirement.Region_0.Initial_0.active then
    sm__evaluating_the_requirement.Region_0.numberOfActiveStates := sm__evaluating_the_requirement.Region_0.numberOfActiveStates + 1;
  end if;

  /* M@ validation code start*/

  if sm__evaluating_the_requirement.active then
    assert(not (sm__evaluating_the_requirement.Region_0.numberOfActiveStates < 1), "sm__evaluating_the_requirement.Region_0 has no active states although the parent state is active!");
    assert(not (sm__evaluating_the_requirement.Region_0.numberOfActiveStates > 1), "sm__evaluating_the_requirement.Region_0 has multiple active states which are mutually exclusive!");
  end if;

  if not sm__evaluating_the_requirement.active then
    assert(sm__evaluating_the_requirement.Region_0.numberOfActiveStates == 0, "sm__evaluating_the_requirement.Region_0 has active states although the parent state is not active!");
  end if;

  /* M@ validation code start*/



  /* M@ end debug code of region "Region_0" ***/
end Max_level_of_liquid_in_a_tank;

