package ConPNlib
  model TC  "Continuous Transition"
    parameter Integer nIn = 0 "number of input places";
    parameter Integer nOut = 0 "number of output places";
    Real maximumSpeed = 1 "maximum speed";
    Real[nIn] arcWeightIn = fill(1, nIn) "arc weights of input places";
    Real[nOut] arcWeightOut = fill(1, nOut) "arc weights of output places";
    Boolean fire "Does the transition fire?";
    Real instantaneousSpeed "instantaneous speed";
    Real actualSpeed = if fire then instantaneousSpeed else 0.0;
    Interfaces.TransitionOut[nOut] outPlaces(each active = activation.active, each fire = fire, each enabledByInPlaces = true, arcWeight = arcWeightOut, each instSpeed = instantaneousSpeed, each prelimSpeed = preliminarySpeed, each maxSpeed = maximumSpeed, t = tOut, maxTokens = maxTokens, decreasingFactor = decreasingFactorOut, emptied = emptied, speedSum = speedSumOut) "connector for output places";
    Interfaces.TransitionIn[nIn] inPlaces(each active = activation.active, each fire = fire, arcWeight = arcWeightIn, each instSpeed = instantaneousSpeed, each prelimSpeed = preliminarySpeed, each maxSpeed = maximumSpeed, t = tIn, minTokens = minTokens, fed = fed, enable = enableIn, decreasingFactor = decreasingFactorIn, speedSum = speedSumIn) "connector for input places";
  protected
    Real[nIn] tIn "tokens of input places";
    Real[nOut] tOut "tokens of output places";
    Real[nIn] minTokens "minimum tokens of input places";
    Real[nOut] maxTokens "maximum tokens of output places";
    Real[nIn] speedSumIn "Input speeds of continuous input places";
    Real[nOut] speedSumOut "Output speeds of continuous output places";
    Real[nIn] decreasingFactorIn "decreasing factors of input places";
    Real[nOut] decreasingFactorOut "decreasing factors of output places";
    Boolean[nIn] fed "Are the input places fed by their input transitions?";
    Boolean[nOut] emptied "Are the output places emptied by their output transitions?";
    Boolean[nIn] enableIn "Is the transition enabled by all its discrete input transitions?";
    Blocks.activationCon activation(nIn = nIn, nOut = nOut, tIn = tIn, tOut = tOut, arcWeightIn = arcWeightIn, arcWeightOut = arcWeightOut, minTokens = minTokens, maxTokens = maxTokens, fed = fed, emptied = emptied, testValue = inPlaces.testValue, arcType = inPlaces.arcType) "activation process";
    Real preliminarySpeed = Functions.preliminarySpeed(nIn = nIn, nOut = nOut, arcWeightIn = arcWeightIn, arcWeightOut = arcWeightOut, speedSumIn = speedSumIn, speedSumOut = speedSumOut, maximumSpeed = maximumSpeed, weaklyInputActiveVec = activation.weaklyInputActiveVec, weaklyOutputActiveVec = activation.weaklyOutputActiveVec) "preliminary speed calculation";
  equation
    fire = activation.active and not maximumSpeed <= 0 "firing process";
    instantaneousSpeed = max(min(min(min(decreasingFactorIn), min(decreasingFactorOut)) * maximumSpeed, preliminarySpeed), 0.0) "instantaneous speed calculation";
  end TC;

  model Settings  "Global Settings for Animation and Display"
    parameter Boolean showTokenFlow = false;
    annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "The settings object is missing");
  end Settings;

  package Interfaces  "contains the connectors for the Petri net component models"
    connector TransitionIn  "part of transition model to connect transitions to input places"
      input Real t "Markings of input places" annotation(HideResult = true);
      input Real minTokens "Minimum capacites of input places" annotation(HideResult = true);
      input Boolean enable "Is the transition enabled by input places?" annotation(HideResult = true);
      input Real decreasingFactor "Factor of continuous input places for decreasing the speed" annotation(HideResult = true);
      input ConPNlib.Types.ArcType arcType "Type of output arcs ([1]normal, [2]test, [3]inhibition, or [4]read)" annotation(HideResult = true);
      input Real testValue "Test value of a test or inhibitor arc" annotation(HideResult = true);
      input Boolean fed "Are the continuous input places fed?" annotation(HideResult = true);
      input Real speedSum "Input speeds of continuous input places" annotation(HideResult = true);
      output Boolean active "Is the transition active?" annotation(HideResult = true);
      output Boolean fire "Does the transition fire?" annotation(HideResult = true);
      output Real arcWeight "Input arc weights of the transition" annotation(HideResult = true);
      output Real instSpeed "Instantaneous speed of a continuous transition" annotation(HideResult = true);
      output Real prelimSpeed "Preliminary speed of a continuous transition" annotation(HideResult = true);
      output Real maxSpeed "Maximum speed of a continuous transition" annotation(HideResult = true);
    end TransitionIn;

    connector TransitionOut  "part of transition model to connect transitions to output places"
      input Real t "Markings of output places" annotation(HideResult = true);
      input Real maxTokens "Maximum capacities of output places" annotation(HideResult = true);
      input Boolean enable "Is the transition enabled by output places?" annotation(HideResult = true);
      input Real decreasingFactor "Factor of continuous output places for decreasing the speed" annotation(HideResult = true);
      input Boolean emptied "Are the continuous output places emptied?" annotation(HideResult = true);
      input Real speedSum "Output speeds of continuous output places" annotation(HideResult = true);
      output Boolean active "Is the transition active?" annotation(HideResult = true);
      output Boolean fire "Does the transition fire?" annotation(HideResult = true);
      output Real arcWeight "Output arc weights of the transition" annotation(HideResult = true);
      output Boolean enabledByInPlaces "Is the transition enabled by all input places?" annotation(HideResult = true);
      output Real instSpeed "Instantaneous speed of a continuous transition" annotation(HideResult = true);
      output Real prelimSpeed "Preliminary speed of a continuous transition" annotation(HideResult = true);
      output Real maxSpeed "Maximum speed of a continuous transition" annotation(HideResult = true);
    end TransitionOut;
  end Interfaces;

  package Blocks  "contains blocks with specific procedures that are used in the Petri net component models"
    block activationCon  "activation process of continuous transitions"
      parameter input Integer nIn "number of input places";
      parameter input Integer nOut "number of output places";
      input Real[:] tIn "marking of input places";
      input Real[:] tOut "marking of output places";
      input Real[:] arcWeightIn "arc weights of input places";
      input Real[:] arcWeightOut "arc weights of output places";
      input Real[:] minTokens "minimum capacities of input places";
      input Real[:] maxTokens "maximum capacities of output places";
      input Boolean[:] fed "input places are fed?";
      input Boolean[:] emptied "output places are emptied?";
      input ConPNlib.Types.ArcType[:] arcType "arc type of input places";
      input Real[:] testValue "test values of test and inhibitor arcs";
      output Boolean active "activation of transition";
      output Boolean[nIn] weaklyInputActiveVec "places that causes weakly input activation";
      output Boolean[nOut] weaklyOutputActiveVec "places that causes weakly output activation";
    algorithm
      active := true;
      weaklyInputActiveVec := fill(false, nIn);
      weaklyOutputActiveVec := fill(false, nOut);
      for i in 1:nIn loop
        if arcType[i] == ConPNlib.Types.ArcType.normal_arc then
          if tIn[i] <= minTokens[i] then
            if fed[i] then
              weaklyInputActiveVec[i] := true;
            else
              active := false;
            end if;
          else
          end if;
        elseif arcType[i] == ConPNlib.Types.ArcType.inhibitor_arc then
          if not tIn[i] < testValue[i] then
            active := false;
          else
          end if;
        else
        end if;
      end for;
      for i in 1:nOut loop
        if tOut[i] >= maxTokens[i] and not emptied[i] then
          active := false;
        elseif tOut[i] >= maxTokens[i] and emptied[i] then
          weaklyOutputActiveVec[i] := true;
        else
        end if;
      end for;
    end activationCon;
  end Blocks;

  package Functions
    function preliminarySpeed  "calculates the preliminary speed of a continuous transition"
      input Integer nIn "number of input places";
      input Integer nOut "number of output places";
      input Real[:] arcWeightIn "input arc weights";
      input Real[:] arcWeightOut "output arc weights";
      input Real[:] speedSumIn "input speed";
      input Real[:] speedSumOut "output speed";
      input Real maximumSpeed "maximum speed";
      input Boolean[:] weaklyInputActiveVec "places that causes weakly input activation";
      input Boolean[:] weaklyOutputActiveVec "places that causes weakly output activation";
      output Real prelimSpeed "preliminary speed";
    algorithm
      prelimSpeed := maximumSpeed;
      for i in 1:nIn loop
        if weaklyInputActiveVec[i] and speedSumIn[i] < prelimSpeed * arcWeightIn[i] then
          prelimSpeed := speedSumIn[i] / arcWeightIn[i];
        else
        end if;
      end for;
      for i in 1:nOut loop
        if weaklyOutputActiveVec[i] and speedSumOut[i] < prelimSpeed * arcWeightOut[i] then
          prelimSpeed := speedSumOut[i] / arcWeightOut[i];
        else
        end if;
      end for;
    end preliminarySpeed;
  end Functions;

  package Types
    type ArcType = enumeration(normal_arc, inhibitor_arc);
  end Types;

  package Examples
    model Test1b
      inner Settings settings;
      ConPNlib.TC T1;
      annotation(experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-006));
    end Test1b;
  end Examples;
end ConPNlib;

model Test1b_total
  extends ConPNlib.Examples.Test1b;
 annotation(experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-006));
end Test1b_total;
