model BouncingBall_me_FMU
  constant String fmuWorkingDir = "/home/marcus/workspace/openmodelica/openmodelica/OpenModelica-testsuite/openmodelica/cppruntime";
  parameter Integer logLevel = 3 "log level used during the loading of FMU" annotation (Dialog(tab="FMI", group="Enable logging"));
  parameter Boolean debugLogging = false "enables the FMU simulation logging" annotation (Dialog(tab="FMI", group="Enable logging"));
  Real h "height of ball";
  Real v "velocity of ball";
  Real der_h_ "height of ball";
  Real der_v_ "velocity of ball";
  Real v_new;
  parameter Real e = 0.7 "coefficient of restitution";
  parameter Real g = 9.81 "gravity acceleration";
  Integer n_bounce;
  Boolean _D_whenCondition1;
  Boolean _D_whenCondition2;
  Boolean _D_whenCondition3;
  Boolean flying "true, if ball is flying";
  Boolean impact;
protected
  FMI1ModelExchange fmi1me = FMI1ModelExchange(logLevel, fmuWorkingDir, "BouncingBall", debugLogging);
  constant Integer numberOfContinuousStates = 2;
  Real fmi_x[numberOfContinuousStates] "States";
  Real fmi_x_new[numberOfContinuousStates](each fixed = true) "New States";
  constant Integer numberOfEventIndicators = 2;
  Real fmi_z[numberOfEventIndicators] "Events Indicators";
  Boolean fmi_z_positive[numberOfEventIndicators](each fixed = true);
  parameter Real flowStartTime(fixed=false);
  Real flowTime;
  parameter Real flowInitialized(fixed=false);
  parameter Real flowParamsStart(fixed=false);
  parameter Real flowInitInputs(fixed=false);
  Real flowStatesInputs;
  Boolean callEventUpdate;
  constant Boolean intermediateResults = false;
  Boolean newStatesAvailable(fixed = true);
  Real triggerDSSEvent;
  Real nextEventTime;
initial equation
  flowStartTime = fmi1Functions.fmi1SetTime(fmi1me, time, 1);
  flowInitialized = fmi1Functions.fmi1Initialize(fmi1me, flowParamsStart+flowInitInputs+flowStartTime);
  fmi_x = fmi1Functions.fmi1GetContinuousStates(fmi1me, numberOfContinuousStates, flowParamsStart+flowInitialized);
initial algorithm
  flowParamsStart := 1;
  flowParamsStart := fmi1Functions.fmi1SetRealParameter(fmi1me, {5.0, 6.0}, {e, g});
  flowInitInputs := 1;
initial equation
equation
  flowTime = fmi1Functions.fmi1SetTime(fmi1me, time, flowInitialized);
  flowStatesInputs = fmi1Functions.fmi1SetContinuousStates(fmi1me, fmi_x, flowParamsStart + flowTime);
  der(fmi_x) = fmi1Functions.fmi1GetDerivatives(fmi1me, numberOfContinuousStates, flowStatesInputs);
  fmi_z  = fmi1Functions.fmi1GetEventIndicators(fmi1me, numberOfEventIndicators, flowStatesInputs);
  for i in 1:size(fmi_z,1) loop
    fmi_z_positive[i] = if not terminal() then fmi_z[i] > 0 else pre(fmi_z_positive[i]);
  end for;
  callEventUpdate = fmi1Functions.fmi1CompletedIntegratorStep(fmi1me, flowStatesInputs);
  triggerDSSEvent = noEvent(if callEventUpdate then flowStatesInputs+1.0 else flowStatesInputs-1.0);
  nextEventTime = fmi1Functions.fmi1nextEventTime(fmi1me, flowStatesInputs);
  {h, v, der_h_, der_v_, v_new} = fmi1Functions.fmi1GetReal(fmi1me, {0.0, 1.0, 2.0, 3.0, 4.0}, flowStatesInputs);
  {n_bounce} = fmi1Functions.fmi1GetInteger(fmi1me, {0.0}, flowStatesInputs);
  {_D_whenCondition1, _D_whenCondition2, _D_whenCondition3, flying, impact} = fmi1Functions.fmi1GetBoolean(fmi1me, {0.0, 1.0, 2.0, 3.0, 4.0}, flowStatesInputs);
algorithm
  when {(change(fmi_z_positive[2]) or change(fmi_z_positive[1])) and not initial(),triggerDSSEvent > flowStatesInputs, nextEventTime < time, terminal()} then
    newStatesAvailable := fmi1Functions.fmi1EventUpdate(fmi1me, intermediateResults);
    if newStatesAvailable then
      fmi_x_new := fmi1Functions.fmi1GetContinuousStates(fmi1me, numberOfContinuousStates, flowStatesInputs);
      reinit(fmi_x[2], fmi_x_new[2]);
      reinit(fmi_x[1], fmi_x_new[1]);
    end if;
  end when;
  annotation(experiment(StartTime=0.0, StopTime=1.0, Tolerance=1e-06));
  annotation (Icon(graphics={
      Rectangle(
        extent={{-100,100},{100,-100}},
        lineColor={0,0,0},
        fillColor={240,240,240},
        fillPattern=FillPattern.Solid,
        lineThickness=0.5),
      Text(
        extent={{-100,40},{100,0}},
        lineColor={0,0,0},
        textString="%name"),
      Text(
        extent={{-100,-50},{100,-90}},
        lineColor={0,0,0},
        textString="V1.0")}));
protected
  class FMI1ModelExchange
    extends ExternalObject;
      function constructor
        input Integer logLevel;
        input String workingDirectory;
        input String instanceName;
        input Boolean debugLogging;
        output FMI1ModelExchange fmi1me;
        external "C" fmi1me = FMI1ModelExchangeConstructor_OMC(logLevel, workingDirectory, instanceName, debugLogging) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end constructor;

      function destructor
        input FMI1ModelExchange fmi1me;
        external "C" FMI1ModelExchangeDestructor_OMC(fmi1me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
      end destructor;
  end FMI1ModelExchange;


  
  package fmi1Functions
    function fmi1Initialize
      input FMI1ModelExchange fmi1me;
      input Real preInitialized;
      output Real postInitialized=preInitialized;
      external "C" fmi1Initialize_OMC(fmi1me) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1Initialize;
  
    function fmi1SetTime
      input FMI1ModelExchange fmi1me;
      input Real inTime;
      input Real inFlow;
      output Real outFlow = inFlow;
      external "C" fmi1SetTime_OMC(fmi1me, inTime) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetTime;
  
    function fmi1GetContinuousStates
      input FMI1ModelExchange fmi1me;
      input Integer numberOfContinuousStates;
      input Real inFlowParams;
      output Real fmi_x[numberOfContinuousStates];
      external "C" fmi1GetContinuousStates_OMC(fmi1me, numberOfContinuousStates, inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1GetContinuousStates;
  
    function fmi1SetContinuousStates
      input FMI1ModelExchange fmi1me;
      input Real fmi_x[:];
      input Real inFlowParams;
      output Real outFlowStates;
      external "C" outFlowStates = fmi1SetContinuousStates_OMC(fmi1me, size(fmi_x, 1), inFlowParams, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetContinuousStates;
  
    function fmi1GetDerivatives
      input FMI1ModelExchange fmi1me;
      input Integer numberOfContinuousStates;
      input Real inFlowStates;
      output Real fmi_x[numberOfContinuousStates];
      external "C" fmi1GetDerivatives_OMC(fmi1me, numberOfContinuousStates, inFlowStates, fmi_x) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1GetDerivatives;
  
    function fmi1GetEventIndicators
      input FMI1ModelExchange fmi1me;
      input Integer numberOfEventIndicators;
      input Real inFlowStates;
      output Real fmi_z[numberOfEventIndicators];
      external "C" fmi1GetEventIndicators_OMC(fmi1me, numberOfEventIndicators, inFlowStates, fmi_z) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1GetEventIndicators;
  
    function fmi1GetReal
      input FMI1ModelExchange fmi1me;
      input Real realValuesReferences[:];
      input Real inFlowStatesInput;
      output Real realValues[size(realValuesReferences, 1)];
      external "C" fmi1GetReal_OMC(fmi1me, size(realValuesReferences, 1), realValuesReferences, inFlowStatesInput, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1GetReal;
  
    function fmi1SetReal
      input FMI1ModelExchange fmi1me;
      input Real realValueReferences[:];
      input Real realValues[size(realValueReferences, 1)];
      output Real outValues[size(realValueReferences, 1)] = realValues;
      external "C" fmi1SetReal_OMC(fmi1me, size(realValueReferences, 1), realValueReferences, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetReal;
  
    function fmi1SetRealParameter
      input FMI1ModelExchange fmi1me;
      input Real realValueReferences[:];
      input Real realValues[size(realValueReferences, 1)];
      output Real out_Value = 1;
      external "C" fmi1SetReal_OMC(fmi1me, size(realValueReferences, 1), realValueReferences, realValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetRealParameter;
  
    function fmi1GetInteger
      input FMI1ModelExchange fmi1me;
      input Real integerValueReferences[:];
      input Real inFlowStatesInput;
      output Integer integerValues[size(integerValueReferences, 1)];
      external "C" fmi1GetInteger_OMC(fmi1me, size(integerValueReferences, 1), integerValueReferences, inFlowStatesInput, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1GetInteger;
  
    function fmi1SetInteger
      input FMI1ModelExchange fmi1me;
      input Real integerValuesReferences[:];
      input Integer integerValues[size(integerValuesReferences, 1)];
      output Integer outValues[size(integerValuesReferences, 1)] = integerValues;
      external "C" fmi1SetInteger_OMC(fmi1me, size(integerValuesReferences, 1), integerValuesReferences, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetInteger;
  
    function fmi1SetIntegerParameter
      input FMI1ModelExchange fmi1me;
      input Real integerValuesReferences[:];
      input Integer integerValues[size(integerValuesReferences, 1)];
      output Real out_Value = 1;
      external "C" fmi1SetInteger_OMC(fmi1me, size(integerValuesReferences, 1), integerValuesReferences, integerValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetIntegerParameter;
  
    function fmi1GetBoolean
      input FMI1ModelExchange fmi1me;
      input Real booleanValuesReferences[:];
      input Real inFlowStatesInput;
      output Boolean booleanValues[size(booleanValuesReferences, 1)];
      external "C" fmi1GetBoolean_OMC(fmi1me, size(booleanValuesReferences, 1), booleanValuesReferences, inFlowStatesInput, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1GetBoolean;
  
    function fmi1SetBoolean
      input FMI1ModelExchange fmi1me;
      input Real booleanValueReferences[:];
      input Boolean booleanValues[size(booleanValueReferences, 1)];
      output Boolean outValues[size(booleanValueReferences, 1)] = booleanValues;
      external "C" fmi1SetBoolean_OMC(fmi1me, size(booleanValueReferences, 1), booleanValueReferences, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetBoolean;
  
    function fmi1SetBooleanParameter
      input FMI1ModelExchange fmi1me;
      input Real booleanValueReferences[:];
      input Boolean booleanValues[size(booleanValueReferences, 1)];
      output Real out_Value = 1;
      external "C" fmi1SetBoolean_OMC(fmi1me, size(booleanValueReferences, 1), booleanValueReferences, booleanValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetBooleanParameter;
  
    function fmi1GetString
      input FMI1ModelExchange fmi1me;
      input Real stringValuesReferences[:];
      input Real inFlowStatesInput;
      output String stringValues[size(stringValuesReferences, 1)];
      external "C" fmi1GetString_OMC(fmi1me, size(stringValuesReferences, 1), stringValuesReferences, inFlowStatesInput, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1GetString;
  
    function fmi1SetString
      input FMI1ModelExchange fmi1me;
      input Real stringValueReferences[:];
      input String stringValues[size(stringValueReferences, 1)];
      output String outValues[size(stringValueReferences, 1)] = stringValues;
      external "C" fmi1SetString_OMC(fmi1me, size(stringValueReferences, 1), stringValueReferences, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetString;
  
    function fmi1SetStringParameter
      input FMI1ModelExchange fmi1me;
      input Real stringValueReferences[:];
      input String stringValues[size(stringValueReferences, 1)];
      output Real out_Value = 1;
      external "C" fmi1SetString_OMC(fmi1me, size(stringValueReferences, 1), stringValueReferences, stringValues, 1) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1SetStringParameter;
  
    function fmi1EventUpdate
      input FMI1ModelExchange fmi1me;
      input Boolean intermediateResults;
      output Boolean outNewStatesAvailable;
      external "C" outNewStatesAvailable = fmi1EventUpdate_OMC(fmi1me, intermediateResults) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1EventUpdate;
  
    function fmi1nextEventTime
      input FMI1ModelExchange fmi1me;
      input Real inFlowStates;
      output Real outNewnextTime;
      external "C" outNewnextTime = fmi1nextEventTime_OMC(fmi1me, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1nextEventTime;
  
    function fmi1CompletedIntegratorStep
      input FMI1ModelExchange fmi1me;
      input Real inFlowStates;
      output Boolean outCallEventUpdate;
      external "C" outCallEventUpdate = fmi1CompletedIntegratorStep_OMC(fmi1me, inFlowStates) annotation(Library = {"OpenModelicaFMIRuntimeC", "fmilib"});
    end fmi1CompletedIntegratorStep;
  end fmi1Functions;
end BouncingBall_me_FMU;