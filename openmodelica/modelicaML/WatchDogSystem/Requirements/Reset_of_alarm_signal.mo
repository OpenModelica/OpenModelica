//This code is generated from a ModelicaML model.

within WatchDogSystem.Requirements;

model Reset_of_alarm_signal
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="Reset of alarm signal", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«requirement»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="Rq", fontName="Arial")}));
  input Boolean alarm_is_activated;
  Boolean violated;
  record Reset_of_alarm_signal_StateMachine_requirement_violation_monitor
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-6.722,3.6841}, lineColor={0,85,127}, fillColor={85,170,255}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-75.0,-50.0},{75.0,50.0}}, radius=40),Rectangle(visible=true, origin={70.0,2.6556}, lineColor={85,170,255}, fillColor={0,85,127}, fillPattern=FillPattern.Solid, lineThickness=4, extent={{-26.8908,-25.0},{26.8908,25.0}})}));
    // lib properties STATE MACHINE
      Boolean active; // indicates if the state is active.
      Real timeAtActivation; // time when the state is entered.
      Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
      Boolean selfTransitionActivated;
    Boolean startBehaviour;
    // REGIONS instantiation
    requirement_violation_monitor_Region_0 Region_0;

    // REGIONS classes
    record requirement_violation_monitor_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState waiting_for_alarm_activation;
      InitialState Initial_0;
      // COMPOSITE STATES instantiation
      Region_0_alarm_is_activated alarm_is_activated;
      // COMPOSITE STATES classes
      record Region_0_alarm_is_activated
        annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-0.0,-0.1675}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-64.6031,-34.6638},{64.6031,34.6638}}, radius=40)}));
        // lib properties COMPOSITE STATE
          Boolean active; // indicates if the state is active.
          Real timeAtActivation; // time when the state is entered.
          Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
          Boolean selfTransitionActivated;
        // REGIONS instantiation
        alarm_is_activated_Region_0 Region_0;
        record alarm_is_activated_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState wait_20_sec;
      SimpleState requirement_is_violated;
      InitialState Initial_0;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end alarm_is_activated_Region_0;
      end Region_0_alarm_is_activated;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end requirement_violation_monitor_Region_0;

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
  end Reset_of_alarm_signal_StateMachine_requirement_violation_monitor;



  // STATE MACHNE instantiation
    Reset_of_alarm_signal_StateMachine_requirement_violation_monitor requirement_violation_monitor;

    /* M@ start composite alarm is activated */

    /* M@ end composite alarm is activated */
  algorithm
  algorithm

  /*** start behaviour code of state machine "requirement_violation_monitor" ***/
  algorithm



    /* M@ start composite alarm is activated */

    /* M@ end composite alarm is activated */

    /* initial state machine "requirement_violation_monitor" activation */
    requirement_violation_monitor.startBehaviour:=true;
    when requirement_violation_monitor.startBehaviour then
    requirement_violation_monitor.active:=true;
      requirement_violation_monitor.Region_0.Initial_0.active:=true;
    end when;
    when {requirement_violation_monitor.active, requirement_violation_monitor.selfTransitionActivated} then
        requirement_violation_monitor.timeAtActivation := time;
        requirement_violation_monitor.selfTransitionActivated := false;
      end when;
      if requirement_violation_monitor.active then
        requirement_violation_monitor.stime := time - requirement_violation_monitor.timeAtActivation;
      end if;
      if not requirement_violation_monitor.active then
        requirement_violation_monitor.stime := 0;
      end if;
    /*** start behaviour code of region "requirement_violation_monitor" ***/
  when {requirement_violation_monitor.Region_0.Initial_0.active, requirement_violation_monitor.Region_0.Initial_0.selfTransitionActivated} then
      requirement_violation_monitor.Region_0.Initial_0.timeAtActivation := time;
      requirement_violation_monitor.Region_0.Initial_0.selfTransitionActivated := false;
    end when;
    if requirement_violation_monitor.Region_0.Initial_0.active then
      requirement_violation_monitor.Region_0.Initial_0.stime := time - requirement_violation_monitor.Region_0.Initial_0.timeAtActivation;
    end if;
    if not requirement_violation_monitor.Region_0.Initial_0.active then
      requirement_violation_monitor.Region_0.Initial_0.stime := 0;
    end if;
  when {requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active, requirement_violation_monitor.Region_0.waiting_for_alarm_activation.selfTransitionActivated} then
      requirement_violation_monitor.Region_0.waiting_for_alarm_activation.timeAtActivation := time;
      requirement_violation_monitor.Region_0.waiting_for_alarm_activation.selfTransitionActivated := false;
    end when;
  when {requirement_violation_monitor.Region_0.alarm_is_activated.active, requirement_violation_monitor.Region_0.alarm_is_activated.selfTransitionActivated} then
      requirement_violation_monitor.Region_0.alarm_is_activated.timeAtActivation := time;
      requirement_violation_monitor.Region_0.alarm_is_activated.selfTransitionActivated := false;
    end when;
    if requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active then
      requirement_violation_monitor.Region_0.waiting_for_alarm_activation.stime := time - requirement_violation_monitor.Region_0.waiting_for_alarm_activation.timeAtActivation;
    end if;
    if not requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active then
      requirement_violation_monitor.Region_0.waiting_for_alarm_activation.stime := 0;
    end if;
    if requirement_violation_monitor.Region_0.alarm_is_activated.active then
      requirement_violation_monitor.Region_0.alarm_is_activated.stime := time - requirement_violation_monitor.Region_0.alarm_is_activated.timeAtActivation;
    end if;
    if not requirement_violation_monitor.Region_0.alarm_is_activated.active then
      requirement_violation_monitor.Region_0.alarm_is_activated.stime := 0;
    end if;

  /*start transition code*/

  if (requirement_violation_monitor.Region_0.Initial_0.active) then
    requirement_violation_monitor.Region_0.Initial_0.active := false;
    requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active := true;

  end if;
  /*test the composite state is still active*/
  if(requirement_violation_monitor.active  ) then
     if pre(requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active) then
      if     alarm_is_activated then
      requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active := false;
        requirement_violation_monitor.Region_0.alarm_is_activated.active := true;
      requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.active := true;

      end if;
  elseif pre(requirement_violation_monitor.Region_0.alarm_is_activated.active) then
      if     not alarm_is_activated then
      /*start composite highlevel transition deactivate active substate*/
      if (requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active) then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active:=false;
      end if;
      if (requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active) then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active:=false;
      end if;
      /*end composite highlevel transition deactivate active substate*/
      requirement_violation_monitor.Region_0.alarm_is_activated.active := false;
        requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active := true;

      end if;
  end if;
   end if;
  /*end transition code*/
  /*start do Code*/


  /*end do Code*/


  /*start composite alarm is activated */
      /*** start behaviour code of region "requirement_violation_monitor.Region_0.alarm_is_activated" ***/
    when {requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.active, requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.selfTransitionActivated} then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.timeAtActivation := time;
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.selfTransitionActivated := false;
      end when;
      if requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.active then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.stime := time - requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.timeAtActivation;
      end if;
      if not requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.active then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.stime := 0;
      end if;
    when {requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active, requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.selfTransitionActivated} then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.timeAtActivation := time;
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.selfTransitionActivated := false;
      end when;
    when {requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active, requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.selfTransitionActivated} then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.timeAtActivation := time;
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.selfTransitionActivated := false;
      end when;
      if requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.stime := time - requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.timeAtActivation;
      end if;
      if not requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.stime := 0;
      end if;
      if requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.stime := time - requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.timeAtActivation;
      end if;
      if not requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.stime := 0;
      end if;

    /*start transition code*/

    if (requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.active) then
      requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.active := false;
      requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active := true;

    end if;
    /*test the composite state is still active*/
    if(requirement_violation_monitor.Region_0.alarm_is_activated.active  ) then
       if pre(requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active) then
        if     (requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.stime > (20)) then
        requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active := false;
          requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active := true;

        end if;
    end if;
     end if;
    /*end transition code*/
    /*start do Code*/

    if requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active then
      //state "requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated": do behavior
      violated := true;
    end if;

    /*end do Code*/



    /*** end behaviour code of region "Region_0" ***/
  /*end composite alarm is activated */

  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "requirement_violation_monitor"*/
    if (not requirement_violation_monitor.active) then
    /* M@ start terminate code of region "requirement_violation_monitor" ***/
    requirement_violation_monitor.Region_0.Initial_0.active := false;
    requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active := false;
    requirement_violation_monitor.Region_0.alarm_is_activated.active := false;
    /* M@ start composite alarm is activated */
    /* M@ start terminate code of region "requirement_violation_monitor.Region_0.alarm_is_activated" ***/
    requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.active := false;
    requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active := false;
    requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    /* M@ end composite alarm is activated */
    /* M@ end terminate code of region "Region_0" ***/
    end if;
    /*end terminate code for state machine "requirement_violation_monitor"*/
  /*** end behaviour code of state machine "requirement_violation_monitor" ***/
  /* M@ reset debug variabels */
  requirement_violation_monitor.Region_0.numberOfActiveStates := 0;

  /* M@ start debug code of region "----requirement_violation_monitor" ***/
  if requirement_violation_monitor.Region_0.waiting_for_alarm_activation.active then
    requirement_violation_monitor.Region_0.numberOfActiveStates := requirement_violation_monitor.Region_0.numberOfActiveStates + 1;
  end if;
  if requirement_violation_monitor.Region_0.alarm_is_activated.active then
    requirement_violation_monitor.Region_0.numberOfActiveStates := requirement_violation_monitor.Region_0.numberOfActiveStates + 1;
  end if;
  if requirement_violation_monitor.Region_0.Initial_0.active then
    requirement_violation_monitor.Region_0.numberOfActiveStates := requirement_violation_monitor.Region_0.numberOfActiveStates + 1;
  end if;

  /* M@ validation code start*/

  if requirement_violation_monitor.active then
    assert(not (requirement_violation_monitor.Region_0.numberOfActiveStates < 1), "requirement_violation_monitor.Region_0 has no active states although the parent state is active!");
    assert(not (requirement_violation_monitor.Region_0.numberOfActiveStates > 1), "requirement_violation_monitor.Region_0 has multiple active states which are mutually exclusive!");
  end if;

  if not requirement_violation_monitor.active then
    assert(requirement_violation_monitor.Region_0.numberOfActiveStates == 0, "requirement_violation_monitor.Region_0 has active states although the parent state is not active!");
  end if;

  /* M@ validation code start*/

  /* M@ start composite alarm is activated */
      /* M@ reset debug variabels */
    requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates := 0;

    /* M@ start debug code of region "----requirement_violation_monitor.Region_0.alarm_is_activated" ***/
    if requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.wait_20_sec.active then
      requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates := requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates + 1;
    end if;
    if requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.requirement_is_violated.active then
      requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates := requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates + 1;
    end if;
    if requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.Initial_0.active then
      requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates := requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates + 1;
    end if;

    /* M@ validation code start*/

    if requirement_violation_monitor.Region_0.alarm_is_activated.active then
      assert(not (requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates < 1), "requirement_violation_monitor.Region_0.alarm_is_activated.Region_0 has no active states although the parent state is active!");
      assert(not (requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates > 1), "requirement_violation_monitor.Region_0.alarm_is_activated.Region_0 has multiple active states which are mutually exclusive!");
    end if;

    if not requirement_violation_monitor.Region_0.alarm_is_activated.active then
      assert(requirement_violation_monitor.Region_0.alarm_is_activated.Region_0.numberOfActiveStates == 0, "requirement_violation_monitor.Region_0.alarm_is_activated.Region_0 has active states although the parent state is not active!");
    end if;

    /* M@ validation code start*/



    /* M@ end debug code of region "Region_0" ***/
  /* M@ end composite alarm is activated */


  /* M@ end debug code of region "Region_0" ***/
end Reset_of_alarm_signal;

