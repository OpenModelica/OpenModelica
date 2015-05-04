//This code is generated from a ModelicaML model.

within WatchDogSystem.SystemDesign.AlarmSystem_Components;

model EWatchDog
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="EWatchDog", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  Boolean on;
  Boolean alarm;
  input WatchDogSystem.SystemDesign.AlarmSystem_Components.Interfaces.ISensor p_sensor;
  Real battery_level(start = 100);
  Boolean low_battery_indication= if battery_level < 20 then true else false;
  Boolean alarm_detected;
  record EWatchDog_StateMachine_Operation_Modes
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
      SimpleState Active;
      InitialState Initial_0;
      // Submachine STATES instantiation
      Region_0_Alarmed Alarmed;
      // Submachine STATES classes
      record Region_0_Alarmed
        annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-0.0,-0.1675}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.HorizontalCylinder, lineThickness=10, extent={{-64.6031,-34.6638},{64.6031,34.6638}}, radius=40)}));
        // lib properties SUBMACHINE STATE
          Boolean active; // indicates if the state is active.
          Real timeAtActivation; // time when the state is entered.
          Real stime; // stime means "state time". It is is a local timer. It starts when the state is entered and is equal to zero if the state is not active.
          Boolean selfTransitionActivated;
        // Submachine REGIONS instantiation
            Alarmed_Region_0 Region_0;

        record Alarmed_Region_0
          annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.3349,3.6841}, lineColor={0,85,127}, fillColor={104,182,221}, fillPattern=FillPattern.Solid, lineThickness=10, extent={{-84.7336,-50.0},{84.7336,50.0}}, radius=40),Rectangle(visible=true, origin={2.0095,40.0}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,4.4251}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={2.0095,-31.5559}, fillPattern=FillPattern.Solid, extent={{-2.0095,-8.4441},{2.0095,8.4441}}),Rectangle(visible=true, origin={-30.0,70.0}, lineColor={0,85,127}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=2, extent={{-25.0,-10.0},{25.0,10.0}})}));
          // SIMPLE STATES instantiation
          SimpleState alarm_is_activated;
          SimpleState deactivate_alarm;
          InitialState Initial_0;

          /* M@ debug variables */
          Integer numberOfActiveStates;

        end Alarmed_Region_0; //test
      end Region_0_Alarmed;

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
  end EWatchDog_StateMachine_Operation_Modes;



  // STATE MACHNE instantiation
    EWatchDog_StateMachine_Operation_Modes Operation_Modes;

    /* M@ start submachine composite Alarmed */


    /* M@ end submachine composite Alarmed */

  algorithm
    alarm_detected := pre(p_sensor.signal);
  algorithm
  algorithm

  /*** start behaviour code of state machine "Operation_Modes" ***/
  algorithm



    /* M@ start submachine composite Alarmed */


    /* M@ end submachine composite Alarmed */

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
  when {Operation_Modes.Region_0.Active.active, Operation_Modes.Region_0.Active.selfTransitionActivated} then
      Operation_Modes.Region_0.Active.timeAtActivation := time;
      Operation_Modes.Region_0.Active.selfTransitionActivated := false;
    end when;
  when {Operation_Modes.Region_0.Alarmed.active, Operation_Modes.Region_0.Alarmed.selfTransitionActivated} then
      Operation_Modes.Region_0.Alarmed.timeAtActivation := time;
      Operation_Modes.Region_0.Alarmed.selfTransitionActivated := false;
    end when;
    if Operation_Modes.Region_0.Off.active then
      Operation_Modes.Region_0.Off.stime := time - Operation_Modes.Region_0.Off.timeAtActivation;
    end if;
    if not Operation_Modes.Region_0.Off.active then
      Operation_Modes.Region_0.Off.stime := 0;
    end if;
    if Operation_Modes.Region_0.Active.active then
      Operation_Modes.Region_0.Active.stime := time - Operation_Modes.Region_0.Active.timeAtActivation;
    end if;
    if not Operation_Modes.Region_0.Active.active then
      Operation_Modes.Region_0.Active.stime := 0;
    end if;
    if Operation_Modes.Region_0.Alarmed.active then
      Operation_Modes.Region_0.Alarmed.stime := time - Operation_Modes.Region_0.Alarmed.timeAtActivation;
    end if;
    if not Operation_Modes.Region_0.Alarmed.active then
      Operation_Modes.Region_0.Alarmed.stime := 0;
    end if;

  /*start transition code*/

  if (Operation_Modes.Region_0.Initial_0.active) then
    Operation_Modes.Region_0.Initial_0.active := false;
    Operation_Modes.Region_0.Off.active := true;

  end if;
  /*test the composite state is still active*/
  if(Operation_Modes.active  ) then
     if pre(Operation_Modes.Region_0.Off.active) then
      if     on and battery_level > 1 then
      Operation_Modes.Region_0.Off.active := false;
        Operation_Modes.Region_0.Active.active := true;

      end if;
  elseif pre(Operation_Modes.Region_0.Active.active) then
      if     not on  or battery_level < 1 then
      Operation_Modes.Region_0.Active.active := false;
        Operation_Modes.Region_0.Off.active := true;

        elseif            alarm_detected <> pre(alarm_detected) then
      Operation_Modes.Region_0.Active.active := false;
        Operation_Modes.Region_0.Alarmed.active := true;
        //state "Operation_Modes.Region_0.Alarmed": entry behavior
        alarm := true;
      Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.active := true;

      end if;
  elseif pre(Operation_Modes.Region_0.Alarmed.active) then
      if     not alarm then
      /*start submachine highlevel transition deactivate active substate*/
      //HIGHLEVEL
      if (Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active) then
        Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active:=false;
      end if;
      if (Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active) then
        Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active:=false;
      end if;
      /*end submachine highlevel transition deactivate active substate*/
      //state "Operation_Modes.Region_0.Alarmed": exit behavior
        alarm := false;
      Operation_Modes.Region_0.Alarmed.active := false;
        Operation_Modes.Region_0.Active.active := true;

        elseif            not on  or  battery_level < 1 then
      /*start submachine highlevel transition deactivate active substate*/
      //HIGHLEVEL
      if (Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active) then
        Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active:=false;
      end if;
      if (Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active) then
        Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active:=false;
      end if;
      /*end submachine highlevel transition deactivate active substate*/
      //state "Operation_Modes.Region_0.Alarmed": exit behavior
        alarm := false;
      Operation_Modes.Region_0.Alarmed.active := false;
        Operation_Modes.Region_0.Off.active := true;

      end if;
  end if;
   end if;
  /*end transition code*/
  /*start do Code*/



  /*end do Code*/


  /*start submachine composite Alarmed */
        /*** start behaviour code of region "Operation_Modes.Region_0.Alarmed" ***/
      when {Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.active, Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.selfTransitionActivated} then
          Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.timeAtActivation := time;
          Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.selfTransitionActivated := false;
        end when;
        if Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.active then
          Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.stime := time - Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.timeAtActivation;
        end if;
        if not Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.active then
          Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.stime := 0;
        end if;
      when {Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active, Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.selfTransitionActivated} then
          Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.timeAtActivation := time;
          Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.selfTransitionActivated := false;
        end when;
      when {Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active, Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.selfTransitionActivated} then
          Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.timeAtActivation := time;
          Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.selfTransitionActivated := false;
        end when;
        if Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active then
          Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.stime := time - Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.timeAtActivation;
        end if;
        if not Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active then
          Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.stime := 0;
        end if;
        if Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active then
          Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.stime := time - Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.timeAtActivation;
        end if;
        if not Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active then
          Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.stime := 0;
        end if;

      /*start transition code*/

      if (Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.active) then
        Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.active := false;
        Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active := true;

      end if;
      /*test the composite state is still active*/
      if(Operation_Modes.Region_0.Alarmed.active  ) then
         if pre(Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active) then
          if     (Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.stime > (20)) then
          Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active := false;
            Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active := true;
            //state "Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm": entry behavior
            alarm := false;

          end if;
      end if;
       end if;
      /*end transition code*/
      /*start do Code*/


      /*end do Code*/



      /*** end behaviour code of region "Region_0" ***/

  /*end submachine composite Alarmed */

  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "Operation_Modes"*/
    if (not Operation_Modes.active) then
    /* M@ start terminate code of region "Operation_Modes" ***/
    Operation_Modes.Region_0.Initial_0.active := false;
    Operation_Modes.Region_0.Off.active := false;
    Operation_Modes.Region_0.Active.active := false;
    Operation_Modes.Region_0.Alarmed.active := false;
    /* M@ start submachine composite Alarmed */
    /* M@ start terminate code of region "Operation_Modes.Region_0.Alarmed" ***/
    Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.active := false;
    Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active := false;
    Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    /* M@ end submachine composite Alarmed */
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
  if Operation_Modes.Region_0.Active.active then
    Operation_Modes.Region_0.numberOfActiveStates := Operation_Modes.Region_0.numberOfActiveStates + 1;
  end if;
  if Operation_Modes.Region_0.Alarmed.active then
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


  /* M@ start submachine composite Alarmed */
      /* M@ reset debug variabels */
      Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates := 0;

      /* M@ start debug code of region "----Operation_Modes.Region_0.Alarmed" ***/
      if Operation_Modes.Region_0.Alarmed.Region_0.alarm_is_activated.active then
        Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates := Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates + 1;
      end if;
      if Operation_Modes.Region_0.Alarmed.Region_0.deactivate_alarm.active then
        Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates := Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates + 1;
      end if;
      if Operation_Modes.Region_0.Alarmed.Region_0.Initial_0.active then
        Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates := Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates + 1;
      end if;

      /* M@ validation code start*/

      if Operation_Modes.Region_0.Alarmed.active then
        assert(not (Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates < 1), "Operation_Modes.Region_0.Alarmed.Region_0 has no active states although the parent state is active!");
        assert(not (Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates > 1), "Operation_Modes.Region_0.Alarmed.Region_0 has multiple active states which are mutually exclusive!");
      end if;

      if not Operation_Modes.Region_0.Alarmed.active then
        assert(Operation_Modes.Region_0.Alarmed.Region_0.numberOfActiveStates == 0, "Operation_Modes.Region_0.Alarmed.Region_0 has active states although the parent state is not active!");
      end if;

      /* M@ validation code start*/



      /* M@ end debug code of region "Region_0" ***/


  /* M@ end submachine composite Alarmed */

  /* M@ end debug code of region "Region_0" ***/
  equation

  // code generated from the Activity "Battery level calculation" (ConditionalEquations(Diagram))

  // if/when-else code
  if battery_level > 0 then
      // if/when-else code
      if Operation_Modes.Region_0.Active.active or Operation_Modes.Region_0.Alarmed.active then
          // OpaqueAction: "Battery level calculation.battery is used"
          der(battery_level) = - 1;
        else
          // OpaqueAction: "Battery level calculation.battery is not used"
          der(battery_level) = 0;
      end if;
    else
      // OpaqueAction: "Battery level calculation.battery is empty"
      der(battery_level) = 0;
  end if;
end EWatchDog;

