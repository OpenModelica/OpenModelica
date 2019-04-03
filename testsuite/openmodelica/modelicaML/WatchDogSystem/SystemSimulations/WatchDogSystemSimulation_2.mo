//This code is generated from a ModelicaML model.

within WatchDogSystem.SystemSimulations;

model WatchDogSystemSimulation_2
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="WatchDogSystemSimulation-2", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  WatchDogSystem.SystemDesign.AlarmSystem dm;
  WatchDogSystem.Requirements.Reset_of_alarm_signal req_001(alarm_is_activated = dm.watch_dog.alarm);
  WatchDogSystem.Requirements.Low_battery_indication req_002(battery_level = dm.watch_dog.battery_level, indication_is_on = dm.watch_dog.low_battery_indication);
  Boolean test_failed;
  record WatchDogSystemSimulation_2_StateMachine_test_scenario
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-6.722,3.6841}, lineColor={0,85,127}, fillColor={85,170,255}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-75.0,-50.0},{75.0,50.0}}, radius=40),Rectangle(visible=true, origin={70.0,2.6556}, lineColor={85,170,255}, fillColor={0,85,127}, fillPattern=FillPattern.Solid, lineThickness=4, extent={{-26.8908,-25.0},{26.8908,25.0}})}));
    // lib properties STATE MACHINE
      Boolean active; // indicates if the state is active.
      Real timeAtActivation; // time when the state is entered.
      Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
      Boolean selfTransitionActivated;
    Boolean startBehaviour;
    // REGIONS instantiation
    test_scenario_Region_0 Region_0;

    // REGIONS classes
    record test_scenario_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState init;
      SimpleState turn_on_the_system;
      SimpleState generate_alarm_signal;
      InitialState Initial_0;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end test_scenario_Region_0;

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
  end WatchDogSystemSimulation_2_StateMachine_test_scenario;



  // STATE MACHNE instantiation
    WatchDogSystemSimulation_2_StateMachine_test_scenario test_scenario;

  algorithm
    when {req_001.violated, req_002.violated}  then
      test_failed := true;
    end when;
  algorithm
  algorithm

  /*** start behaviour code of state machine "test_scenario" ***/
  algorithm





    /* initial state machine "test_scenario" activation */
    test_scenario.startBehaviour:=true;
    when test_scenario.startBehaviour then
    test_scenario.active:=true;
      test_scenario.Region_0.Initial_0.active:=true;
    end when;
    when {test_scenario.active, test_scenario.selfTransitionActivated} then
        test_scenario.timeAtActivation := time;
        test_scenario.selfTransitionActivated := false;
      end when;
      if test_scenario.active then
        test_scenario.stime := time - test_scenario.timeAtActivation;
      end if;
      if not test_scenario.active then
        test_scenario.stime := 0;
      end if;
    /*** start behaviour code of region "test_scenario" ***/
  when {test_scenario.Region_0.Initial_0.active, test_scenario.Region_0.Initial_0.selfTransitionActivated} then
      test_scenario.Region_0.Initial_0.timeAtActivation := time;
      test_scenario.Region_0.Initial_0.selfTransitionActivated := false;
    end when;
    if test_scenario.Region_0.Initial_0.active then
      test_scenario.Region_0.Initial_0.stime := time - test_scenario.Region_0.Initial_0.timeAtActivation;
    end if;
    if not test_scenario.Region_0.Initial_0.active then
      test_scenario.Region_0.Initial_0.stime := 0;
    end if;
  when {test_scenario.Region_0.init.active, test_scenario.Region_0.init.selfTransitionActivated} then
      test_scenario.Region_0.init.timeAtActivation := time;
      test_scenario.Region_0.init.selfTransitionActivated := false;
    end when;
  when {test_scenario.Region_0.turn_on_the_system.active, test_scenario.Region_0.turn_on_the_system.selfTransitionActivated} then
      test_scenario.Region_0.turn_on_the_system.timeAtActivation := time;
      test_scenario.Region_0.turn_on_the_system.selfTransitionActivated := false;
    end when;
  when {test_scenario.Region_0.generate_alarm_signal.active, test_scenario.Region_0.generate_alarm_signal.selfTransitionActivated} then
      test_scenario.Region_0.generate_alarm_signal.timeAtActivation := time;
      test_scenario.Region_0.generate_alarm_signal.selfTransitionActivated := false;
    end when;
    if test_scenario.Region_0.init.active then
      test_scenario.Region_0.init.stime := time - test_scenario.Region_0.init.timeAtActivation;
    end if;
    if not test_scenario.Region_0.init.active then
      test_scenario.Region_0.init.stime := 0;
    end if;
    if test_scenario.Region_0.turn_on_the_system.active then
      test_scenario.Region_0.turn_on_the_system.stime := time - test_scenario.Region_0.turn_on_the_system.timeAtActivation;
    end if;
    if not test_scenario.Region_0.turn_on_the_system.active then
      test_scenario.Region_0.turn_on_the_system.stime := 0;
    end if;
    if test_scenario.Region_0.generate_alarm_signal.active then
      test_scenario.Region_0.generate_alarm_signal.stime := time - test_scenario.Region_0.generate_alarm_signal.timeAtActivation;
    end if;
    if not test_scenario.Region_0.generate_alarm_signal.active then
      test_scenario.Region_0.generate_alarm_signal.stime := 0;
    end if;

  /*start transition code*/

  if (test_scenario.Region_0.Initial_0.active) then
    test_scenario.Region_0.Initial_0.active := false;
    test_scenario.Region_0.init.active := true;

  end if;
  /*test the composite state is still active*/
  if(test_scenario.active  ) then
     if pre(test_scenario.Region_0.init.active) then
      if     (test_scenario.Region_0.init.stime > (5)) then
      test_scenario.Region_0.init.active := false;
        test_scenario.Region_0.turn_on_the_system.active := true;
        //state "test_scenario.Region_0.turn_on_the_system": entry behavior
        dm.watch_dog.on := true;

      end if;
  elseif pre(test_scenario.Region_0.turn_on_the_system.active) then
      if     (test_scenario.Region_0.turn_on_the_system.stime > (10)) then
      test_scenario.Region_0.turn_on_the_system.active := false;
        test_scenario.Region_0.generate_alarm_signal.active := true;
        //state "test_scenario.Region_0.generate_alarm_signal": entry behavior
        dm.sensor.alarm_detected := not dm.sensor.alarm_detected;

      end if;
  end if;
   end if;
  /*end transition code*/
  /*start do Code*/



  /*end do Code*/



  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "test_scenario"*/
    if (not test_scenario.active) then
    /* M@ start terminate code of region "test_scenario" ***/
    test_scenario.Region_0.Initial_0.active := false;
    test_scenario.Region_0.init.active := false;
    test_scenario.Region_0.turn_on_the_system.active := false;
    test_scenario.Region_0.generate_alarm_signal.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    end if;
    /*end terminate code for state machine "test_scenario"*/
  /*** end behaviour code of state machine "test_scenario" ***/
  /* M@ reset debug variabels */
  test_scenario.Region_0.numberOfActiveStates := 0;

  /* M@ start debug code of region "----test_scenario" ***/
  if test_scenario.Region_0.init.active then
    test_scenario.Region_0.numberOfActiveStates := test_scenario.Region_0.numberOfActiveStates + 1;
  end if;
  if test_scenario.Region_0.turn_on_the_system.active then
    test_scenario.Region_0.numberOfActiveStates := test_scenario.Region_0.numberOfActiveStates + 1;
  end if;
  if test_scenario.Region_0.generate_alarm_signal.active then
    test_scenario.Region_0.numberOfActiveStates := test_scenario.Region_0.numberOfActiveStates + 1;
  end if;
  if test_scenario.Region_0.Initial_0.active then
    test_scenario.Region_0.numberOfActiveStates := test_scenario.Region_0.numberOfActiveStates + 1;
  end if;

  /* M@ validation code start*/

  if test_scenario.active then
    assert(not (test_scenario.Region_0.numberOfActiveStates < 1), "test_scenario.Region_0 has no active states although the parent state is active!");
    assert(not (test_scenario.Region_0.numberOfActiveStates > 1), "test_scenario.Region_0 has multiple active states which are mutually exclusive!");
  end if;

  if not test_scenario.active then
    assert(test_scenario.Region_0.numberOfActiveStates == 0, "test_scenario.Region_0 has active states although the parent state is not active!");
  end if;

  /* M@ validation code start*/



  /* M@ end debug code of region "Region_0" ***/
end WatchDogSystemSimulation_2;

