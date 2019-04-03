//This code is generated from a ModelicaML model.

within TwoTanksSystemExample.Simulations;

model TankSystemSimulation
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="TankSystemSimulation", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  TwoTanksSystemExample.Design.Two_Tanks_System.TanksConnectedPI dm "Desing model to be simulated. ";
  TwoTanksSystemExample.Requirements.Max_level_of_liquid_in_a_tank r001_tank1(tank_height = dm.tank1.tank_height, level = dm.tank1.h) "Requirement to be evaluated during system sumulation. ";
  TwoTanksSystemExample.Requirements.Max_level_of_liquid_in_a_tank r001_tank2(tank_height = dm.tank2.tank_height, level = dm.tank2.h) "Requirement to be evaluated during system sumulation. ";
  TwoTanksSystemExample.Requirements.Volume_of_the_tank1 r002_tank1(tank_volume = dm.tank1.volumeCal.volume) "Requirement to be evaluated during system sumulation. ";
  Boolean test_failed;
  record TankSystemSimulation_StateMachine_test_scenario__1__steps
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-6.722,3.6841}, lineColor={0,85,127}, fillColor={85,170,255}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-75.0,-50.0},{75.0,50.0}}, radius=40),Rectangle(visible=true, origin={70.0,2.6556}, lineColor={85,170,255}, fillColor={0,85,127}, fillPattern=FillPattern.Solid, lineThickness=4, extent={{-26.8908,-25.0},{26.8908,25.0}})}));
    // lib properties STATE MACHINE
      Boolean active; // indicates if the state is active.
      Real timeAtActivation; // time when the state is entered.
      Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
      Boolean selfTransitionActivated;
    Boolean startBehaviour;
    // REGIONS instantiation
    test_scenario__1__steps_Region_0 Region_0;

    // REGIONS classes
    record test_scenario__1__steps_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState no_flow;
      SimpleState step1__set_flow_level_to_0_02;
      SimpleState step2__set_flow_level_to_0_06;
      InitialState Initial_0;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end test_scenario__1__steps_Region_0;

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
  end TankSystemSimulation_StateMachine_test_scenario__1__steps;



  // STATE MACHNE instantiation
    TankSystemSimulation_StateMachine_test_scenario__1__steps test_scenario__1__steps;

  algorithm
    when {r001_tank1.violated, r001_tank2.violated, r002_tank1.violated} then
      test_failed := true;
    end when;
  algorithm
  algorithm

  /*** start behaviour code of state machine "test_scenario__1__steps" ***/
  algorithm





    /* initial state machine "test_scenario__1__steps" activation */
    test_scenario__1__steps.startBehaviour:=true;
    when test_scenario__1__steps.startBehaviour then
    test_scenario__1__steps.active:=true;
      test_scenario__1__steps.Region_0.Initial_0.active:=true;
    end when;
    when {test_scenario__1__steps.active, test_scenario__1__steps.selfTransitionActivated} then
        test_scenario__1__steps.timeAtActivation := time;
        test_scenario__1__steps.selfTransitionActivated := false;
      end when;
      if test_scenario__1__steps.active then
        test_scenario__1__steps.stime := time - test_scenario__1__steps.timeAtActivation;
      end if;
      if not test_scenario__1__steps.active then
        test_scenario__1__steps.stime := 0;
      end if;
    /*** start behaviour code of region "test_scenario__1__steps" ***/
  when {test_scenario__1__steps.Region_0.Initial_0.active, test_scenario__1__steps.Region_0.Initial_0.selfTransitionActivated} then
      test_scenario__1__steps.Region_0.Initial_0.timeAtActivation := time;
      test_scenario__1__steps.Region_0.Initial_0.selfTransitionActivated := false;
    end when;
    if test_scenario__1__steps.Region_0.Initial_0.active then
      test_scenario__1__steps.Region_0.Initial_0.stime := time - test_scenario__1__steps.Region_0.Initial_0.timeAtActivation;
    end if;
    if not test_scenario__1__steps.Region_0.Initial_0.active then
      test_scenario__1__steps.Region_0.Initial_0.stime := 0;
    end if;
  when {test_scenario__1__steps.Region_0.no_flow.active, test_scenario__1__steps.Region_0.no_flow.selfTransitionActivated} then
      test_scenario__1__steps.Region_0.no_flow.timeAtActivation := time;
      test_scenario__1__steps.Region_0.no_flow.selfTransitionActivated := false;
    end when;
  when {test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active, test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.selfTransitionActivated} then
      test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.timeAtActivation := time;
      test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.selfTransitionActivated := false;
    end when;
  when {test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active, test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.selfTransitionActivated} then
      test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.timeAtActivation := time;
      test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.selfTransitionActivated := false;
    end when;
    if test_scenario__1__steps.Region_0.no_flow.active then
      test_scenario__1__steps.Region_0.no_flow.stime := time - test_scenario__1__steps.Region_0.no_flow.timeAtActivation;
    end if;
    if not test_scenario__1__steps.Region_0.no_flow.active then
      test_scenario__1__steps.Region_0.no_flow.stime := 0;
    end if;
    if test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active then
      test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.stime := time - test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.timeAtActivation;
    end if;
    if not test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active then
      test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.stime := 0;
    end if;
    if test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active then
      test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.stime := time - test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.timeAtActivation;
    end if;
    if not test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active then
      test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.stime := 0;
    end if;

  /*start transition code uml.StateMachine (name: test scenario #1: steps, visibility: <unset>) (isLeaf: false, isAbstract: false) (isActive: false) (isReentrant: false)*/

  if /*pre*/(test_scenario__1__steps.Region_0.Initial_0.active) then
    test_scenario__1__steps.Region_0.Initial_0.active := false;
    test_scenario__1__steps.Region_0.no_flow.active := true;

  end if;
  /*test the composite state is still active*/
  /*1*/if(test_scenario__1__steps.active  ) then
    /*2*/ if pre(test_scenario__1__steps.Region_0.no_flow.active) then
      if     (test_scenario__1__steps.Region_0.no_flow.stime > (10)) then
      test_scenario__1__steps.Region_0.no_flow.active := false;
        test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active := true;

      end if; //test2
  elseif pre(test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active) then
      if     (test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.stime > (140)) then
      test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active := false;
        test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active := true;

      end if; //test2
  elseif pre(test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active) then
      if     (test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.stime > (20)) then
      test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active := false;
        test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active := true;

      end if; //test2
  /*2*/end if;
  /*1*/ end if; //test5
  /*end transition code*/
  /*start do Code*/
  if test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active then
    //state "test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02": do behavior
    dm.source.flowLevel := 0.02;
  end if;
  if test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active then
    //state "test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06": do behavior
    dm.source.flowLevel := 0.06;
  end if;
  /*end do Code*/



  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "test_scenario__1__steps"*/
    if (not test_scenario__1__steps.active) then
    /* M@ start terminate code of region "test_scenario__1__steps" ***/
    test_scenario__1__steps.Region_0.Initial_0.active := false;
    test_scenario__1__steps.Region_0.no_flow.active := false;
    test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active := false;
    test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    end if;
    /*end terminate code for state machine "test_scenario__1__steps"*/
  /*** end behaviour code of state machine "test_scenario__1__steps" ***/
  /* M@ reset debug variabels */
  test_scenario__1__steps.Region_0.numberOfActiveStates := 0;

  /* M@ start debug code of region "----test_scenario__1__steps" ***/
  if test_scenario__1__steps.Region_0.no_flow.active then
    test_scenario__1__steps.Region_0.numberOfActiveStates := test_scenario__1__steps.Region_0.numberOfActiveStates + 1;
  end if;
  if test_scenario__1__steps.Region_0.step1__set_flow_level_to_0_02.active then
    test_scenario__1__steps.Region_0.numberOfActiveStates := test_scenario__1__steps.Region_0.numberOfActiveStates + 1;
  end if;
  if test_scenario__1__steps.Region_0.step2__set_flow_level_to_0_06.active then
    test_scenario__1__steps.Region_0.numberOfActiveStates := test_scenario__1__steps.Region_0.numberOfActiveStates + 1;
  end if;
  if test_scenario__1__steps.Region_0.Initial_0.active then
    test_scenario__1__steps.Region_0.numberOfActiveStates := test_scenario__1__steps.Region_0.numberOfActiveStates + 1;
  end if;

  /* M@ validation code start*/

  if test_scenario__1__steps.active then
    assert(not (test_scenario__1__steps.Region_0.numberOfActiveStates < 1), "test_scenario__1__steps.Region_0 has no active states although the parent state is active!");
    assert(not (test_scenario__1__steps.Region_0.numberOfActiveStates > 1), "test_scenario__1__steps.Region_0 has multiple active states which are mutually exclusive!");
  end if;

  if not test_scenario__1__steps.active then
    assert(test_scenario__1__steps.Region_0.numberOfActiveStates == 0, "test_scenario__1__steps.Region_0 has active states although the parent state is not active!");
  end if;

  /* M@ validation code start*/



  /* M@ end debug code of region "Region_0" ***/
end TankSystemSimulation;

