//This code is generated from a ModelicaML model.

within TwoTanksSystemExample.Design.Two_Tanks_System.Components;

model PIcontinuousController
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="PIcontinuousController", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  extends TwoTanksSystemExample.Design.Library.BaseController(K = 2, T = 10) ;

  Real x "State variable of continuous PI controller ";
  Boolean powered;
  record PIcontinuousController_StateMachine_sm
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-6.722,3.6841}, lineColor={0,85,127}, fillColor={85,170,255}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-75.0,-50.0},{75.0,50.0}}, radius=40),Rectangle(visible=true, origin={70.0,2.6556}, lineColor={85,170,255}, fillColor={0,85,127}, fillPattern=FillPattern.Solid, lineThickness=4, extent={{-26.8908,-25.0},{26.8908,25.0}})}));
    // lib properties STATE MACHINE
      Boolean active; // indicates if the state is active.
      Real timeAtActivation; // time when the state is entered.
      Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
      Boolean selfTransitionActivated;
    Boolean startBehaviour;
    // REGIONS instantiation
    sm_Region_0 Region_0;

    // REGIONS classes
    record sm_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState off;
      InitialState Initial_0;
      // COMPOSITE STATES instantiation
      Region_0_on on;
      // COMPOSITE STATES classes
      record Region_0_on
        annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-0.0,-0.1675}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-64.6031,-34.6638},{64.6031,34.6638}}, radius=40)}));
        // lib properties COMPOSITE STATE
          Boolean active; // indicates if the state is active.
          Real timeAtActivation; // time when the state is entered.
          Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
          Boolean selfTransitionActivated;
        // REGIONS instantiation
        on_Region_0 Region_0;
        record on_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState monitoring_the_level;
      SimpleState controlling_the_level;
      InitialState Initial_0;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end on_Region_0;
      end Region_0_on;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end sm_Region_0;

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
  end PIcontinuousController_StateMachine_sm;



  // STATE MACHNE instantiation
    PIcontinuousController_StateMachine_sm sm;

    /* M@ start composite on */

    /* M@ end composite on */
  equation
    der(x) = error/T;
    outCtr = K*(error + x);
  algorithm
    when time > 0 then
      powered := true;
    end when;
  algorithm
  algorithm

  /*** start behaviour code of state machine "sm" ***/
  algorithm



    /* M@ start composite on */

    /* M@ end composite on */

    /* initial state machine "sm" activation */
    sm.startBehaviour:=true;
    when sm.startBehaviour then
    sm.active:=true;
      sm.Region_0.Initial_0.active:=true;
    end when;
    when {sm.active, sm.selfTransitionActivated} then
        sm.timeAtActivation := time;
        sm.selfTransitionActivated := false;
      end when;
      if sm.active then
        sm.stime := time - sm.timeAtActivation;
      end if;
      if not sm.active then
        sm.stime := 0;
      end if;
    /*** start behaviour code of region "sm" ***/
  when {sm.Region_0.Initial_0.active, sm.Region_0.Initial_0.selfTransitionActivated} then
      sm.Region_0.Initial_0.timeAtActivation := time;
      sm.Region_0.Initial_0.selfTransitionActivated := false;
    end when;
    if sm.Region_0.Initial_0.active then
      sm.Region_0.Initial_0.stime := time - sm.Region_0.Initial_0.timeAtActivation;
    end if;
    if not sm.Region_0.Initial_0.active then
      sm.Region_0.Initial_0.stime := 0;
    end if;
  when {sm.Region_0.off.active, sm.Region_0.off.selfTransitionActivated} then
      sm.Region_0.off.timeAtActivation := time;
      sm.Region_0.off.selfTransitionActivated := false;
    end when;
  when {sm.Region_0.on.active, sm.Region_0.on.selfTransitionActivated} then
      sm.Region_0.on.timeAtActivation := time;
      sm.Region_0.on.selfTransitionActivated := false;
    end when;
    if sm.Region_0.off.active then
      sm.Region_0.off.stime := time - sm.Region_0.off.timeAtActivation;
    end if;
    if not sm.Region_0.off.active then
      sm.Region_0.off.stime := 0;
    end if;
    if sm.Region_0.on.active then
      sm.Region_0.on.stime := time - sm.Region_0.on.timeAtActivation;
    end if;
    if not sm.Region_0.on.active then
      sm.Region_0.on.stime := 0;
    end if;

  /*start transition code uml.StateMachine (name: sm, visibility: <unset>) (isLeaf: false, isAbstract: false) (isActive: false) (isReentrant: false)*/

  if /*pre*/(sm.Region_0.Initial_0.active) then
    sm.Region_0.Initial_0.active := false;
    sm.Region_0.off.active := true;

  end if;
  /*test the composite state is still active*/
  /*1*/if(sm.active  ) then
    /*2*/ if pre(sm.Region_0.off.active) then
      if     powered then
      sm.Region_0.off.active := false;
        sm.Region_0.on.active := true;
      sm.Region_0.on.Region_0.Initial_0.active := true;

      end if; //test2
  elseif pre(sm.Region_0.on.active) then
      if     not powered then
      /*start composite highlevel transition deactivate active substate*/
      if (sm.Region_0.on.Region_0.monitoring_the_level.active) then
        sm.Region_0.on.Region_0.monitoring_the_level.active:=false;
      end if;
      if (sm.Region_0.on.Region_0.controlling_the_level.active) then
        sm.Region_0.on.Region_0.controlling_the_level.active:=false;
      end if;
      /*end composite highlevel transition deactivate active substate*/
      sm.Region_0.on.active := false;
        sm.Region_0.off.active := true;

      end if; //test2
  /*2*/end if;
  /*1*/ end if; //test5
  /*end transition code*/
  /*start do Code*/
  /*end do Code*/


  /*start composite on */
      /*** start behaviour code of region "sm.Region_0.on" ***/
    when {sm.Region_0.on.Region_0.Initial_0.active, sm.Region_0.on.Region_0.Initial_0.selfTransitionActivated} then
        sm.Region_0.on.Region_0.Initial_0.timeAtActivation := time;
        sm.Region_0.on.Region_0.Initial_0.selfTransitionActivated := false;
      end when;
      if sm.Region_0.on.Region_0.Initial_0.active then
        sm.Region_0.on.Region_0.Initial_0.stime := time - sm.Region_0.on.Region_0.Initial_0.timeAtActivation;
      end if;
      if not sm.Region_0.on.Region_0.Initial_0.active then
        sm.Region_0.on.Region_0.Initial_0.stime := 0;
      end if;
    when {sm.Region_0.on.Region_0.monitoring_the_level.active, sm.Region_0.on.Region_0.monitoring_the_level.selfTransitionActivated} then
        sm.Region_0.on.Region_0.monitoring_the_level.timeAtActivation := time;
        sm.Region_0.on.Region_0.monitoring_the_level.selfTransitionActivated := false;
      end when;
    when {sm.Region_0.on.Region_0.controlling_the_level.active, sm.Region_0.on.Region_0.controlling_the_level.selfTransitionActivated} then
        sm.Region_0.on.Region_0.controlling_the_level.timeAtActivation := time;
        sm.Region_0.on.Region_0.controlling_the_level.selfTransitionActivated := false;
      end when;
      if sm.Region_0.on.Region_0.monitoring_the_level.active then
        sm.Region_0.on.Region_0.monitoring_the_level.stime := time - sm.Region_0.on.Region_0.monitoring_the_level.timeAtActivation;
      end if;
      if not sm.Region_0.on.Region_0.monitoring_the_level.active then
        sm.Region_0.on.Region_0.monitoring_the_level.stime := 0;
      end if;
      if sm.Region_0.on.Region_0.controlling_the_level.active then
        sm.Region_0.on.Region_0.controlling_the_level.stime := time - sm.Region_0.on.Region_0.controlling_the_level.timeAtActivation;
      end if;
      if not sm.Region_0.on.Region_0.controlling_the_level.active then
        sm.Region_0.on.Region_0.controlling_the_level.stime := 0;
      end if;

    /*start transition code uml.StateMachine (name: sm, visibility: <unset>) (isLeaf: false, isAbstract: false) (isActive: false) (isReentrant: false)*/

    if /*pre*/(sm.Region_0.on.Region_0.Initial_0.active) then
      sm.Region_0.on.Region_0.Initial_0.active := false;
      sm.Region_0.on.Region_0.monitoring_the_level.active := true;

    end if;
    /*test the composite state is still active*/
    /*1*/if(sm.Region_0.on.active  ) then
      /*2*/ if pre(sm.Region_0.on.Region_0.monitoring_the_level.active) then
        if     cIn.val > 0.2 then
        sm.Region_0.on.Region_0.monitoring_the_level.active := false;
          sm.Region_0.on.Region_0.controlling_the_level.active := true;

        end if; //test2
    elseif pre(sm.Region_0.on.Region_0.controlling_the_level.active) then
        if     cIn.val < 0.08 then
        sm.Region_0.on.Region_0.controlling_the_level.active := false;
          sm.Region_0.on.Region_0.monitoring_the_level.active := true;

        end if; //test2
    /*2*/end if;
    /*1*/ end if; //test5
    /*end transition code*/
    /*start do Code*/
    /*end do Code*/



    /*** end behaviour code of region "Region_0" ***/
  /*end composite on */

  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "sm"*/
    if (not sm.active) then
    /* M@ start terminate code of region "sm" ***/
    sm.Region_0.Initial_0.active := false;
    sm.Region_0.off.active := false;
    sm.Region_0.on.active := false;
    /* M@ start composite on */
    /* M@ start terminate code of region "sm.Region_0.on" ***/
    sm.Region_0.on.Region_0.Initial_0.active := false;
    sm.Region_0.on.Region_0.monitoring_the_level.active := false;
    sm.Region_0.on.Region_0.controlling_the_level.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    /* M@ end composite on */
    /* M@ end terminate code of region "Region_0" ***/
    end if;
    /*end terminate code for state machine "sm"*/
  /*** end behaviour code of state machine "sm" ***/
  /* M@ reset debug variabels */
  sm.Region_0.numberOfActiveStates := 0;

  /* M@ start debug code of region "----sm" ***/
  if sm.Region_0.off.active then
    sm.Region_0.numberOfActiveStates := sm.Region_0.numberOfActiveStates + 1;
  end if;
  if sm.Region_0.on.active then
    sm.Region_0.numberOfActiveStates := sm.Region_0.numberOfActiveStates + 1;
  end if;
  if sm.Region_0.Initial_0.active then
    sm.Region_0.numberOfActiveStates := sm.Region_0.numberOfActiveStates + 1;
  end if;

  /* M@ validation code start*/

  if sm.active then
    assert(not (sm.Region_0.numberOfActiveStates < 1), "sm.Region_0 has no active states although the parent state is active!");
    assert(not (sm.Region_0.numberOfActiveStates > 1), "sm.Region_0 has multiple active states which are mutually exclusive!");
  end if;

  if not sm.active then
    assert(sm.Region_0.numberOfActiveStates == 0, "sm.Region_0 has active states although the parent state is not active!");
  end if;

  /* M@ validation code start*/

  /* M@ start composite on */
      /* M@ reset debug variabels */
    sm.Region_0.on.Region_0.numberOfActiveStates := 0;

    /* M@ start debug code of region "----sm.Region_0.on" ***/
    if sm.Region_0.on.Region_0.monitoring_the_level.active then
      sm.Region_0.on.Region_0.numberOfActiveStates := sm.Region_0.on.Region_0.numberOfActiveStates + 1;
    end if;
    if sm.Region_0.on.Region_0.controlling_the_level.active then
      sm.Region_0.on.Region_0.numberOfActiveStates := sm.Region_0.on.Region_0.numberOfActiveStates + 1;
    end if;
    if sm.Region_0.on.Region_0.Initial_0.active then
      sm.Region_0.on.Region_0.numberOfActiveStates := sm.Region_0.on.Region_0.numberOfActiveStates + 1;
    end if;

    /* M@ validation code start*/

    if sm.Region_0.on.active then
      assert(not (sm.Region_0.on.Region_0.numberOfActiveStates < 1), "sm.Region_0.on.Region_0 has no active states although the parent state is active!");
      assert(not (sm.Region_0.on.Region_0.numberOfActiveStates > 1), "sm.Region_0.on.Region_0 has multiple active states which are mutually exclusive!");
    end if;

    if not sm.Region_0.on.active then
      assert(sm.Region_0.on.Region_0.numberOfActiveStates == 0, "sm.Region_0.on.Region_0 has active states although the parent state is not active!");
    end if;

    /* M@ validation code start*/



    /* M@ end debug code of region "Region_0" ***/
  /* M@ end composite on */


  /* M@ end debug code of region "Region_0" ***/
  equation

  // code generated from the Activity "signal activation" (ConditionalEquations(Diagram))

  // if/when-else code
  if sm.Region_0.on.Region_0.controlling_the_level.active then
      // OpaqueAction: "signal activation.Ouput signal active"
      cOut.act = outCtr;
    else
      // OpaqueAction: "signal activation.Ouput signal NOT active"
      cOut.act = 0;
  end if;
end PIcontinuousController;

