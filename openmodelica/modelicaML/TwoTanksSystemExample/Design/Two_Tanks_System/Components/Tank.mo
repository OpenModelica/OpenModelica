//This code is generated from a ModelicaML model.

within TwoTanksSystemExample.Design.Two_Tanks_System.Components;

model Tank
  annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={0.0,65.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-35.0},{100.0,35.0}}),Rectangle(visible=true, origin={0.0,-35.0}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, lineThickness=1, extent={{-100.0,-65.0},{100.0,65.0}}),Text(visible=true, origin={0.0,52.0578}, fillPattern=FillPattern.Solid, extent={{-96.311,-15.0969},{96.311,15.0969}}, textString="Tank", fontName="Arial"),Text(visible=true, origin={0.0,83.1521}, fillPattern=FillPattern.Solid, extent={{-90.0,-11.3192},{90.0,11.3192}}, textString="«model»", fontName="Arial"),Text(visible=true, origin={0.3349,-37.1756}, fillPattern=FillPattern.Solid, extent={{-97.7954,-59.2801},{97.7954,59.2801}}, textString="M", fontName="Arial")}));
  TwoTanksSystemExample.Design.Two_Tanks_System.Interfaces.ReadSignal tSensor "Connector, sensor reading tank level (m) ";
  TwoTanksSystemExample.Design.Two_Tanks_System.Interfaces.ActSignal tActuator "Connector, actuator controlling input flow ";
  TwoTanksSystemExample.Design.Two_Tanks_System.Interfaces.LiquidFlow qIn "Connector, flow (m3/s) through input valve ";
  TwoTanksSystemExample.Design.Two_Tanks_System.Interfaces.LiquidFlow qOut "Connector, flow (m3/s) through output valve ";
  parameter Real flowGain(unit = "m2/s")= 0.05;
  parameter Real minV= 0 "Limits for output valve flow ";
  parameter Real maxV=10 "Limits for output valve flow ";
  Real h(unit = "m") "Tank level ";
  parameter Real tank_height= 0.6;
  parameter Real tank_width= 1;
  parameter Real tank_length= 1.3;
  TwoTanksSystemExample.Design.Library.CalculationModels.AreaCalculation areaCal(width = tank_width, length = tank_length);
  TwoTanksSystemExample.Design.Library.CalculationModels.VolumeCalculation volumeCal(area = areaCal.area, height = tank_height);
  Real volume_of_liquid_lost;
  record Tank_StateMachine_sm
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
      SimpleState empty;
      SimpleState partially_filled;
      SimpleState overflow;
      InitialState Initial_0;

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
  end Tank_StateMachine_sm;



  // STATE MACHNE instantiation
    Tank_StateMachine_sm sm;
  equation
    der(h)        = (qIn.lflow - qOut.lflow)/areaCal.area;    // Mass balance equation
    qOut.lflow   = TwoTanksSystemExample.Design.Library.limitValue(minV, maxV, -flowGain*tActuator.act);
    tSensor.val   = h;
  algorithm
  algorithm

  /*** start behaviour code of state machine "sm" ***/
  algorithm





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
  when {sm.Region_0.empty.active, sm.Region_0.empty.selfTransitionActivated} then
      sm.Region_0.empty.timeAtActivation := time;
      sm.Region_0.empty.selfTransitionActivated := false;
    end when;
  when {sm.Region_0.partially_filled.active, sm.Region_0.partially_filled.selfTransitionActivated} then
      sm.Region_0.partially_filled.timeAtActivation := time;
      sm.Region_0.partially_filled.selfTransitionActivated := false;
    end when;
  when {sm.Region_0.overflow.active, sm.Region_0.overflow.selfTransitionActivated} then
      sm.Region_0.overflow.timeAtActivation := time;
      sm.Region_0.overflow.selfTransitionActivated := false;
    end when;
    if sm.Region_0.empty.active then
      sm.Region_0.empty.stime := time - sm.Region_0.empty.timeAtActivation;
    end if;
    if not sm.Region_0.empty.active then
      sm.Region_0.empty.stime := 0;
    end if;
    if sm.Region_0.partially_filled.active then
      sm.Region_0.partially_filled.stime := time - sm.Region_0.partially_filled.timeAtActivation;
    end if;
    if not sm.Region_0.partially_filled.active then
      sm.Region_0.partially_filled.stime := 0;
    end if;
    if sm.Region_0.overflow.active then
      sm.Region_0.overflow.stime := time - sm.Region_0.overflow.timeAtActivation;
    end if;
    if not sm.Region_0.overflow.active then
      sm.Region_0.overflow.stime := 0;
    end if;

  /*start transition code uml.StateMachine (name: sm, visibility: <unset>) (isLeaf: false, isAbstract: false) (isActive: false) (isReentrant: false)*/

  if /*pre*/(sm.Region_0.Initial_0.active) then
    sm.Region_0.Initial_0.active := false;
    sm.Region_0.empty.active := true;

  end if;
  /*test the composite state is still active*/
  /*1*/if(sm.active  ) then
    /*2*/ if pre(sm.Region_0.empty.active) then
      if     h > 0.001 then
      sm.Region_0.empty.active := false;
        sm.Region_0.partially_filled.active := true;

      end if; //test2
  elseif pre(sm.Region_0.partially_filled.active) then
      if     h > tank_height then
      sm.Region_0.partially_filled.active := false;
        sm.Region_0.overflow.active := true;

        elseif            h < 0.001 then
      sm.Region_0.partially_filled.active := false;
        sm.Region_0.empty.active := true;

      end if; //test2
  elseif pre(sm.Region_0.overflow.active) then
      if     h < tank_height then
      sm.Region_0.overflow.active := false;
        sm.Region_0.partially_filled.active := true;

      end if; //test2
  /*2*/end if;
  /*1*/ end if; //test5
  /*end transition code*/
  /*start do Code*/
  /*end do Code*/



  /*** end behaviour code of region "Region_0" ***/

    /*start terminate code for state machine "sm"*/
    if (not sm.active) then
    /* M@ start terminate code of region "sm" ***/
    sm.Region_0.Initial_0.active := false;
    sm.Region_0.empty.active := false;
    sm.Region_0.partially_filled.active := false;
    sm.Region_0.overflow.active := false;
    /* M@ end terminate code of region "Region_0" ***/
    end if;
    /*end terminate code for state machine "sm"*/
  /*** end behaviour code of state machine "sm" ***/
  /* M@ reset debug variabels */
  sm.Region_0.numberOfActiveStates := 0;

  /* M@ start debug code of region "----sm" ***/
  if sm.Region_0.empty.active then
    sm.Region_0.numberOfActiveStates := sm.Region_0.numberOfActiveStates + 1;
  end if;
  if sm.Region_0.partially_filled.active then
    sm.Region_0.numberOfActiveStates := sm.Region_0.numberOfActiveStates + 1;
  end if;
  if sm.Region_0.overflow.active then
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



  /* M@ end debug code of region "Region_0" ***/
  equation

  // code generated from the Activity "monitoring the volume of liquid that is lost when overflow" (ConditionalEquations(Diagram))

  // if/when-else code
  if sm.Region_0.overflow.active then
      // OpaqueAction: "monitoring the volume of liquid that is lost when overflow.calculate the volume of the liquid that is lost"
      volume_of_liquid_lost = (h - tank_height) * areaCal.area;
    else
      // OpaqueAction: "monitoring the volume of liquid that is lost when overflow.NOT loosing liquid"
      volume_of_liquid_lost = 0;
  end if;
end Tank;

