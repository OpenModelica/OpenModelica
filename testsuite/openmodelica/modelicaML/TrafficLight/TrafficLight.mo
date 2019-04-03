//This code is generated from a ModelicaML model.


within myUMLModel;

model TrafficLight
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="TrafficLight", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  Boolean on;
  Real batteryLevel(start = 1);
  record TrafficLight_StateMachine_Operation_Modes
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-6.722,3.6841}, lineColor={0,85,127}, fillColor={85,170,255}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-75.0,-50.0},{75.0,50.0}}, radius=40),Rectangle(visible=true, origin={70.0,2.6556}, lineColor={85,170,255}, fillColor={0,85,127}, fillPattern=FillPattern.Solid, lineThickness=4, extent={{-26.8908,-25.0},{26.8908,25.0}})}));
    // lib properties STATE MACHINE
      Boolean active; // indicates if the state is active.
      Real timeAtActivation; // time when the state is entered.
      Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
      Boolean selfTransitionActivated;
    Boolean startBehaviour;
    // REGIONS instantiation
    Operation_Modes_Region_0 Region_0;

    // REGIONS classes
    record Operation_Modes_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState Off;
      InitialState Initial_0;
      // COMPOSITE STATES instantiation
      Region_0_On On;
      // COMPOSITE STATES classes
      record Region_0_On
        annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-0.0,-0.1675}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-64.6031,-34.6638},{64.6031,34.6638}}, radius=40)}));
        // lib properties COMPOSITE STATE
          Boolean active; // indicates if the state is active.
          Real timeAtActivation; // time when the state is entered.
          Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
          Boolean selfTransitionActivated;
        // REGIONS instantiation
        On_Region_0 Region_0;
        record On_Region_0
      annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
      // SIMPLE STATES instantiation
      SimpleState red;
      SimpleState _1__yellow;
      SimpleState green;
      SimpleState _2__yellow;
      InitialState Initial_0;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end On_Region_0;
  end Region_0_On;

      /* M@ debug variables */
      Integer numberOfActiveStates;

    end Operation_Modes_Region_0;

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
  end TrafficLight_StateMachine_Operation_Modes;



  // STATE MACHNE instantiation
    TrafficLight_StateMachine_Operation_Modes Operation_Modes;

    /* M@ start composite On */

    /* M@ end composite On */

  algorithm
    when time > 10 then
      on := true;
    end when;
  algorithm
  algorithm

  /*** start behaviour code of state machine "Operation_Modes" ***/
  algorithm



    /* M@ start composite On */

    /* M@ end composite On */

    /* initial state machine "Operation_Modes" activation */
    Operation_Modes.startBehaviour:=true;
    when Operation_Modes.startBehaviour then
    Operation_Modes.active:=true;
      Operation_Modes.Region_0.Initial_0.active:=true;
    end when;
    when {Operation_Modes.active, Operation_Modes.selfTransitionActivated} then
        Operation_Modes.timeAtActivation := time;
        Operation_Modes.selfTransitionActivated := false;
      end when;
      if Operation_Modes.active then
        Operation_Modes.stime := time - Operation_Modes.timeAtActivation;
      end if;
      if not Operation_Modes.active then
        Operation_Modes.stime := 0;
      end if;
    /*** start behaviour code of region "Operation_Modes" ***/
  when {Operation_Modes.Region_0.Initial_0.active, Operation_Modes.Region_0.Initial_0.selfTransitionActivated} then
      Operation_Modes.Region_0.Initial_0.timeAtActivation := time;
      Operation_Modes.Region_0.Initial_0.selfTransitionActivated := false;
    end when;
    if Operation_Modes.Region_0.Initial_0.active then
      Operation_Modes.Region_0.Initial_0.stime := time - Operation_Modes.Region_0.Initial_0.timeAtActivation;
    end if;
    if not Operation_Modes.Region_0.Initial_0.active then
      Operation_Modes.Region_0.Initial_0.stime := 0;
    end if;
  when {Operation_Modes.Region_0.Off.active, Operation_Modes.Region_0.Off.selfTransitionActivated} then
      Operation_Modes.Region_0.Off.timeAtActivation := time;
      Operation_Modes.Region_0.Off.selfTransitionActivated := false;
    end when;
  when {Operation_Modes.Region_0.On.active, Operation_Modes.Region_0.On.selfTransitionActivated} then
      Operation_Modes.Region_0.On.timeAtActivation := time;
      Operation_Modes.Region_0.On.selfTransitionActivated := false;
    end when;
    if Operation_Modes.Region_0.Off.active then
      Operation_Modes.Region_0.Off.stime := time - Operation_Modes.Region_0.Off.timeAtActivation;
    end if;
    if not Operation_Modes.Region_0.Off.active then
      Operation_Modes.Region_0.Off.stime := 0;
    end if;
    if Operation_Modes.Region_0.On.active then
      Operation_Modes.Region_0.On.stime := time - Operation_Modes.Region_0.On.timeAtActivation;
    end if;
    if not Operation_Modes.Region_0.On.active then
      Operation_Modes.Region_0.On.stime := 0;
    end if;

  /*start transition code*/

  if (Operation_Modes.Region_0.Initial_0.active) then
    Operation_Modes.Region_0.Initial_0.active := false;
    Operation_Modes.Region_0.Off.active := true;

  end if;
  /*test the composite state is still active*/
  if(Operation_Modes.active  ) then
     if pre(Operation_Modes.Region_0.Off.active) then
      if     on then
      Operation_Modes.Region_0.Off.active := false;
        Operation_Modes.Region_0.On.active := true;
      Operation_Modes.Region_0.On.Region_0.Initial_0.active := true;

      end if;
  elseif pre(Operation_Modes.Region_0.On.active) then
      if     not on then
      /*start composite highlevel transition deactivate active substate*/
      if (Operation_Modes.Region_0.On.Region_0.red.active) then
        Operation_Modes.Region_0.On.Region_0.red.active:=false;
      end if;
      if (Operation_Modes.Region_0.On.Region_0._1__yellow.active) then
        Operation_Modes.Region_0.On.Region_0._1__yellow.active:=false;
      end if;
      if (Operation_Modes.Region_0.On.Region_0.green.active) then
        Operation_Modes.Region_0.On.Region_0.green.active:=false;
      end if;
      if (Operation_Modes.Region_0.On.Region_0._2__yellow.active) then
        Operation_Modes.Region_0.On.Region_0._2__yellow.active:=false;
      end if;
      /*end composite highlevel transition deactivate active substate*/
      Operation_Modes.Region_0.On.active := false;
        Operation_Modes.Region_0.Off.active := true;

      end if;
  end if;
   end if;
  /*end transition code*/
  /*start do Code*/


  /*end do Code*/


  /*start composite On */
      /*** start behaviour code of region "Operation_Modes.Region_0.On" ***/
    when {Operation_Modes.Region_0.On.Region_0.Initial_0.active, Operation_Modes.Region_0.On.Region_0.Initial_0.selfTransitionActivated} then
        Operation_Modes.Region_0.On.Region_0.Initial_0.timeAtActivation := time;
        Operation_Modes.Region_0.On.Region_0.Initial_0.selfTransitionActivated := false;
      end when;
      if Operation_Modes.Region_0.On.Region_0.Initial_0.active then
        Operation_Modes.Region_0.On.Region_0.Initial_0.stime := time - Operation_Modes.Region_0.On.Region_0.Initial_0.timeAtActivation;
      end if;
      if not Operation_Modes.Region_0.On.Region_0.Initial_0.active then
        Operation_Modes.Region_0.On.Region_0.Initial_0.stime := 0;
      end if;
    when {Operation_Modes.Region_0.On.Region_0.red.active, Operation_Modes.Region_0.On.Region_0.red.selfTransitionActivated} then
        Operation_Modes.Region_0.On.Region_0.red.timeAtActivation := time;
        Operation_Modes.Region_0.On.Region_0.red.selfTransitionActivated := false;
      end when;
    when {Operation_Modes.Region_0.On.Region_0._1__yellow.active, Operation_Modes.Region_0.On.Region_0._1__yellow.selfTransitionActivated} then
        Operation_Modes.Region_0.On.Region_0._1__yellow.timeAtActivation := time;
        Operation_Modes.Region_0.On.Region_0._1__yellow.selfTransitionActivated := false;
      end when;
    when {Operation_Modes.Region_0.On.Region_0.green.active, Operation_Modes.Region_0.On.Region_0.green.selfTransitionActivated} then
        Operation_Modes.Region_0.On.Region_0.green.timeAtActivation := time;
        Operation_Modes.Region_0.On.Region_0.green.selfTransitionActivated := false;
      end when;
    when {Operation_Modes.Region_0.On.Region_0._2__yellow.active, Operation_Modes.Region_0.On.Region_0._2__yellow.selfTransitionActivated} then
        Operation_Modes.Region_0.On.Region_0._2__yellow.timeAtActivation := time;
        Operation_Modes.Region_0.On.Region_0._2__yellow.selfTransitionActivated := false;
      end when;
      if Operation_Modes.Region_0.On.Region_0.red.active then
        Operation_Modes.Region_0.On.Region_0.red.stime := time - Operation_Modes.Region_0.On.Region_0.red.timeAtActivation;
      end if;
      if not Operation_Modes.Region_0.On.Region_0.red.active then
        Operation_Modes.Region_0.On.Region_0.red.stime := 0;
      end if;
      if Operation_Modes.Region_0.On.Region_0._1__yellow.active then
        Operation_Modes.Region_0.On.Region_0._1__yellow.stime := time - Operation_Modes.Region_0.On.Region_0._1__yellow.timeAtActivation;
      end if;
      if not Operation_Modes.Region_0.On.Region_0._1__yellow.active then
        Operation_Modes.Region_0.On.Region_0._1__yellow.stime := 0;
      end if;
      if Operation_Modes.Region_0.On.Region_0.green.active then
        Operation_Modes.Region_0.On.Region_0.green.stime := time - Operation_Modes.Region_0.On.Region_0.green.timeAtActivation;
      end if;
      if not Operation_Modes.Region_0.On.Region_0.green.active then
        Operation_Modes.Region_0.On.Region_0.green.stime := 0;
      end if;
      if Operation_Modes.Region_0.On.Region_0._2__yellow.active then
        Operation_Modes.Region_0.On.Region_0._2__yellow.stime := time - Operation_Modes.Region_0.On.Region_0._2__yellow.timeAtActivation;
      end if;
      if not Operation_Modes.Region_0.On.Region_0._2__yellow.active then
        Operation_Modes.Region_0.On.Region_0._2__yellow.stime := 0;
      end if;

    /*start transition code*/

    if (Operation_Modes.Region_0.On.Region_0.Initial_0.active) then
      Operation_Modes.Region_0.On.Region_0.Initial_0.active := false;
      Operation_Modes.Region_0.On.Region_0.red.active := true;

    end if;
    /*test the composite state is still active*/
    if(Operation_Modes.Region_0.On.active  ) then
       if pre(Operation_Modes.Region_0.On.Region_0.red.active) then
        if     (Operation_Modes.Region_0.On.Region_0.red.stime > (30)) then
        Operation_Modes.Region_0.On.Region_0.red.active := false;
          Operation_Modes.Region_0.On.Region_0._1__yellow.active := true;

        end if;
    elseif pre(Operation_Modes.Region_0.On.Region_0._1__yellow.active) then
        if     (Operation_Modes.Region_0.On.Region_0._1__yellow.stime > (3)) then
        Operation_Modes.Region_0.On.Region_0._1__yellow.active := false;
          Operation_Modes.Region_0.On.Region_0.green.active := true;

        end if;
    elseif pre(Operation_Modes.Region_0.On.Region_0.green.active) then
        if     (Operation_Modes.Region_0.On.Region_0.green.stime > (30)) then
        Operation_Modes.Region_0.On.Region_0.green.active := false;
          Operation_Modes.Region_0.On.Region_0._2__yellow.active := true;

        end if;
    elseif pre(Operation_Modes.Region_0.On.Region_0._2__yellow.active) then
        if     (Operation_Modes.Region_0.On.Region_0._2__yellow.stime > (3)) then
        Operation_Modes.Region_0.On.Region_0._2__yellow.active := false;
          Operation_Modes.Region_0.On.Region_0.red.active := true;

        end if;
    end if;
     end if;
    /*end transition code*/
    /*start do Code*/




    /*end do Code*/



    /*** end behaviour code of region "Region_0" ***/
  /*end composite On */

  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "Operation_Modes"*/
    if (not Operation_Modes.active) then
    /* M@ start terminate code of region "Operation_Modes" ***/
    Operation_Modes.Region_0.Initial_0.active := false;
    Operation_Modes.Region_0.Off.active := false;
    Operation_Modes.Region_0.On.active := false;
    /* M@ start composite On */
    /* M@ start terminate code of region "Operation_Modes.Region_0.On" ***/
    Operation_Modes.Region_0.On.Region_0.Initial_0.active := false;
    Operation_Modes.Region_0.On.Region_0.red.active := false;
    Operation_Modes.Region_0.On.Region_0._1__yellow.active := false;
    Operation_Modes.Region_0.On.Region_0.green.active := false;
    Operation_Modes.Region_0.On.Region_0._2__yellow.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    /* M@ end composite On */
    /* M@ end terminate code of region "Region_0" ***/
    end if;
    /*end terminate code for state machine "Operation_Modes"*/
  /*** end behaviour code of state machine "Operation_Modes" ***/
  /* M@ reset debug variabels */
  Operation_Modes.Region_0.numberOfActiveStates := 0;

  /* M@ start debug code of region "----Operation_Modes" ***/
  if Operation_Modes.Region_0.Off.active then
    Operation_Modes.Region_0.numberOfActiveStates := Operation_Modes.Region_0.numberOfActiveStates + 1;
  end if;
  if Operation_Modes.Region_0.On.active then
    Operation_Modes.Region_0.numberOfActiveStates := Operation_Modes.Region_0.numberOfActiveStates + 1;
  end if;
  if Operation_Modes.Region_0.Initial_0.active then
    Operation_Modes.Region_0.numberOfActiveStates := Operation_Modes.Region_0.numberOfActiveStates + 1;
  end if;

  /* M@ validation code start*/

  if Operation_Modes.active then
    assert(not (Operation_Modes.Region_0.numberOfActiveStates < 1), "Operation_Modes.Region_0 has no active states although the parent state is active!");
    assert(not (Operation_Modes.Region_0.numberOfActiveStates > 1), "Operation_Modes.Region_0 has multiple active states which are mutually exclusive!");
  end if;

  if not Operation_Modes.active then
    assert(Operation_Modes.Region_0.numberOfActiveStates == 0, "Operation_Modes.Region_0 has active states although the parent state is not active!");
  end if;

  /* M@ validation code start*/

  /* M@ start composite On */
      /* M@ reset debug variabels */
    Operation_Modes.Region_0.On.Region_0.numberOfActiveStates := 0;

    /* M@ start debug code of region "----Operation_Modes.Region_0.On" ***/
    if Operation_Modes.Region_0.On.Region_0.red.active then
      Operation_Modes.Region_0.On.Region_0.numberOfActiveStates := Operation_Modes.Region_0.On.Region_0.numberOfActiveStates + 1;
    end if;
    if Operation_Modes.Region_0.On.Region_0._1__yellow.active then
      Operation_Modes.Region_0.On.Region_0.numberOfActiveStates := Operation_Modes.Region_0.On.Region_0.numberOfActiveStates + 1;
    end if;
    if Operation_Modes.Region_0.On.Region_0.green.active then
      Operation_Modes.Region_0.On.Region_0.numberOfActiveStates := Operation_Modes.Region_0.On.Region_0.numberOfActiveStates + 1;
    end if;
    if Operation_Modes.Region_0.On.Region_0._2__yellow.active then
      Operation_Modes.Region_0.On.Region_0.numberOfActiveStates := Operation_Modes.Region_0.On.Region_0.numberOfActiveStates + 1;
    end if;
    if Operation_Modes.Region_0.On.Region_0.Initial_0.active then
      Operation_Modes.Region_0.On.Region_0.numberOfActiveStates := Operation_Modes.Region_0.On.Region_0.numberOfActiveStates + 1;
    end if;

    /* M@ validation code start*/

    if Operation_Modes.Region_0.On.active then
      assert(not (Operation_Modes.Region_0.On.Region_0.numberOfActiveStates < 1), "Operation_Modes.Region_0.On.Region_0 has no active states although the parent state is active!");
      assert(not (Operation_Modes.Region_0.On.Region_0.numberOfActiveStates > 1), "Operation_Modes.Region_0.On.Region_0 has multiple active states which are mutually exclusive!");
    end if;

    if not Operation_Modes.Region_0.On.active then
      assert(Operation_Modes.Region_0.On.Region_0.numberOfActiveStates == 0, "Operation_Modes.Region_0.On.Region_0 has active states although the parent state is not active!");
    end if;

    /* M@ validation code start*/



    /* M@ end debug code of region "Region_0" ***/
  /* M@ end composite On */


  /* M@ end debug code of region "Region_0" ***/
  equation

  // code generated from the Activity "Battery Consumption" (ConditionalEquations(Diagram))

  // if/when-else code
  if batteryLevel < 0 then
      // OpaqueAction: "Battery Consumption.Not using battery"
      der(batteryLevel) = 0;
    else
      // if/when-else code
      if Operation_Modes.Region_0.On.active then
          // OpaqueAction: "Battery Consumption.Using battery"
          der(batteryLevel) = -0.001;
        else
          // OpaqueAction: "Battery Consumption.Not using battery"
          der(batteryLevel) = 0;
      end if;
  end if;
end TrafficLight;

