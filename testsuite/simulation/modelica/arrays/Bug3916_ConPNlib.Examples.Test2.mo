package ConPNlib
  model PC  "Continuous Place"
    Real t = if t_ < minMarks then minMarks else t_ "marking";
    parameter Integer nIn = 0 "number of input transitions";
    parameter Integer nOut = 0 "number of output transitions";
    parameter Real startMarks = 0 "start marks";
    parameter Real minMarks(min = 0) = 0 "minimum capacity";
    parameter Real maxMarks(min = minMarks) = Constants.inf "maximum capacity";
    parameter Boolean showTokenFlow = settings.showTokenFlow;
    Blocks.tokenFlowCon tokenFlow(nIn = nIn, nOut = nOut, conFiringSumIn = firingSumIn, conFiringSumOut = firingSumOut, fireIn = fireIn, fireOut = fireOut, arcWeightIn = arcWeightIn, arcWeightOut = arcWeightOut, instSpeedIn = instSpeedIn, instSpeedOut = instSpeedOut) if showTokenFlow;
  protected
    outer ConPNlib.Settings settings "global settings for animation and display";
    Real t_(start = startMarks, fixed = true) "marking";
    Real[nIn] arcWeightIn "weights of input arcs";
    Real[nOut] arcWeightOut "weights of output arcs";
    Real[nIn] instSpeedIn "instantaneous speed of input transitions";
    Real[nOut] instSpeedOut "instantaneous speed of output transitions";
    Real[nIn] maxSpeedIn "maximum speed of input transitions";
    Real[nOut] maxSpeedOut "maximum speed of output transitions";
    Real[nIn] prelimSpeedIn "preliminary speed of input transitions";
    Real[nOut] prelimSpeedOut "preliminary speed of output transitions";
    Boolean[nIn] fireIn(each start = false, each fixed = true) "Does any input transition fire?";
    Boolean[nOut] fireOut(each start = false, each fixed = true) "Does any output transition fire?";
    Boolean[nIn] activeIn "Are the input transitions active?";
    Boolean[nOut] activeOut "Are the output transitions active?";
    Boolean[nIn] enabledByInPlaces "Are the input transitions enabled by all their input places?";
    Boolean feeding = Functions.anyTrue(pre(fireIn)) "Is the place fed by input transitions?";
    Boolean emptying = Functions.anyTrue(pre(fireOut)) "Is the place emptied by output transitions?";
    Real firingSumIn = Functions.firingSumCon(fire = fireIn, arcWeight = arcWeightIn, instSpeed = instSpeedIn) "firing sum calculation";
    Real firingSumOut = Functions.firingSumCon(fire = fireOut, arcWeight = arcWeightOut, instSpeed = instSpeedOut) "firing sum calculation";
    Real[nIn] decFactorIn = Functions.decreasingFactorIn(nIn = nIn, t = t_, maxMarks = maxMarks, speedOut = firingSumOut, maxSpeedIn = maxSpeedIn, prelimSpeedIn = prelimSpeedIn, arcWeightIn = arcWeightIn, firingIn = fireIn, firingOut = fireOut) "decreasing factors for input transitions";
    Real[nOut] decFactorOut = Functions.decreasingFactorOut(nOut = nOut, t = t_, minMarks = minMarks, speedIn = firingSumIn, maxSpeedOut = maxSpeedOut, prelimSpeedOut = prelimSpeedOut, arcWeightOut = arcWeightOut, firingIn = fireIn, firingOut = fireOut) "decreasing factors for output transitions";
  public
    Interfaces.PlaceIn[nIn] inTransition(each t = t_, each maxTokens = maxMarks, enable = activeIn, each emptied = emptying, decreasingFactor = decFactorIn, each speedSum = firingSumOut, fire = fireIn, active = activeIn, arcWeight = arcWeightIn, instSpeed = instSpeedIn, maxSpeed = maxSpeedIn, prelimSpeed = prelimSpeedIn, enabledByInPlaces = enabledByInPlaces) "connector for input transitions";
    Interfaces.PlaceOut[nOut] outTransition(each t = t_, each minTokens = minMarks, enable = activeOut, each arcType = Types.ArcType.normal_arc, each testValue = -1.0, each fed = feeding, decreasingFactor = decFactorOut, each speedSum = firingSumIn, fire = fireOut, active = activeOut, arcWeight = arcWeightOut, instSpeed = instSpeedOut, maxSpeed = maxSpeedOut, prelimSpeed = prelimSpeedOut) "connector for output transitions";
  equation
    der(t_) = firingSumIn - firingSumOut "calculation of continuous mark change";
    assert(startMarks >= minMarks and startMarks <= maxMarks, "minMarks <= startMarks <= maxMarks");
  end PC;

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
    connector PlaceIn  "part of place model to connect places to input transitions"
      output Real t "Marking of the place" annotation(HideResult = true);
      output Real maxTokens "Maximum capacity of the place" annotation(HideResult = true);
      output Boolean enable "Which of the input transitions are enabled by the place?" annotation(HideResult = true);
      output Real decreasingFactor "Factor for decreasing the speed of continuous input transitions" annotation(HideResult = true);
      output Boolean emptied "Is the continuous place emptied by output transitions?" annotation(HideResult = true);
      output Real speedSum "Output speed of a continuous place" annotation(HideResult = true);
      input Boolean active "Are the input transitions active?" annotation(HideResult = true);
      input Boolean fire "Do the input transitions fire?" annotation(HideResult = true);
      input Real arcWeight "Arc weights of input transitions" annotation(HideResult = true);
      input Boolean enabledByInPlaces "Are the input transitions enabled by all theier input places?" annotation(HideResult = true);
      input Real instSpeed "Instantaneous speeds of continuous input transitions" annotation(HideResult = true);
      input Real prelimSpeed "Preliminary speeds of continuous input transitions" annotation(HideResult = true);
      input Real maxSpeed "Maximum speeds of continuous input transitions" annotation(HideResult = true);
    end PlaceIn;

    connector PlaceOut  "part of place model to connect places to output transitions"
      output Real t "Marking of the place" annotation(HideResult = true);
      output Real minTokens "Minimum capacity of the place" annotation(HideResult = true);
      output Boolean enable "Which of the output transitions are enabled by the place?" annotation(HideResult = true);
      output Real decreasingFactor "Factor for decreasing the speed of continuous input transitions" annotation(HideResult = true);
      output ConPNlib.Types.ArcType arcType "Type of output arcs ([1]normal, [2]test, [3]inhibition, or [4]read)" annotation(HideResult = true);
      output Real testValue "Test value of a test or inhibitor arc" annotation(HideResult = true);
      output Boolean fed "Is the continuous place fed by input transitions?" annotation(HideResult = true);
      output Real speedSum "Input speed of a continuous place" annotation(HideResult = true);
      input Boolean active "Are the output transitions active?" annotation(HideResult = true);
      input Boolean fire "Do the output transitions fire?" annotation(HideResult = true);
      input Real arcWeight "Arc weights of output transitions" annotation(HideResult = true);
      input Real instSpeed "Instantaneous speeds of continuous output transitions" annotation(HideResult = true);
      input Real prelimSpeed "Preliminary speeds of continuous output transitions" annotation(HideResult = true);
      input Real maxSpeed "Maximum speeds of continuous output transitions" annotation(HideResult = true);
    end PlaceOut;

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

    block tokenFlowCon  "Calculates the token flow for a continuous place."
      parameter input Integer nIn "number of input transitions";
      parameter input Integer nOut "number of output transitions";
      input Real conFiringSumIn;
      input Real conFiringSumOut;
      input Boolean[nIn] fireIn;
      input Boolean[nOut] fireOut;
      input Real[nIn] arcWeightIn;
      input Real[nOut] arcWeightOut;
      input Real[nIn] instSpeedIn;
      input Real[nOut] instSpeedOut;
      output Real inflowSum(start = 0.0, fixed = true);
      output Real[nIn] inflow(each start = 0.0, each fixed = true);
      output Real outflowSum(start = 0.0, fixed = true);
      output Real[nOut] outflow(each start = 0.0, each fixed = true);
    equation
      der(inflowSum) = conFiringSumIn;
      for i in 1:nIn loop
        der(inflow[i]) = if pre(fireIn[i]) then arcWeightIn[i] * instSpeedIn[i] else 0.0;
      end for;
      der(outflowSum) = conFiringSumOut;
      for i in 1:nOut loop
        der(outflow[i]) = if pre(fireOut[i]) then arcWeightOut[i] * instSpeedOut[i] else 0.0;
      end for;
    end tokenFlowCon;
  end Blocks;

  package Functions
    function anyTrue  "Is any entry of a Boolean vector true?"
      input Boolean[:] vec;
      output Boolean anytrue;
    algorithm
      anytrue := false;
      for i in 1:size(vec, 1) loop
        if vec[i] then
          anytrue := true;
        else
        end if;
      end for;
    end anyTrue;

    function firingSumCon  "calculates the firing sum of continuous places"
      input Boolean[:] fire "firability of transitions";
      input Real[:] arcWeight "arc weights";
      input Real[:] instSpeed "istantaneous speed of transitions";
      output Real conFiringSum "continuous firing sum";
    algorithm
      conFiringSum := 0.0;
      for i in 1:size(fire, 1) loop
        if fire[i] then
          conFiringSum := conFiringSum + arcWeight[i] * instSpeed[i];
        else
        end if;
      end for;
    end firingSumCon;

    function numTrue  "Is any entry of a Boolean vector true?"
      input Boolean[:] vec;
      output Integer numtrue;
    algorithm
      numtrue := 0;
      for i in 1:size(vec, 1) loop
        if vec[i] then
          numtrue := numtrue + 1;
        else
        end if;
      end for;
    end numTrue;

    function conditionalSum  "calculates the conditional sum of real vector entries"
      input Real[:] vec;
      input Boolean[:] con;
      output Real conSum;
    algorithm
      conSum := 0;
      for i in 1:size(vec, 1) loop
        if con[i] then
          conSum := conSum + vec[i];
        else
        end if;
      end for;
    end conditionalSum;

    function decreasingFactorIn  "calculation of decreasing factors"
      parameter input Integer nIn "number of input transitions";
      input Real t "marking";
      input Real maxMarks "maximum capacity";
      input Real speedOut "output speed";
      input Real[:] maxSpeedIn "maximum speeds of input transitions";
      input Real[:] prelimSpeedIn "preliminary speeds of input transitions";
      input Real[:] arcWeightIn "arc weights of input transitions";
      input Boolean[:] firingIn "firability of input transitions";
      input Boolean[:] firingOut "firability of input transitions";
      output Real[nIn] decFactorIn "decreasing factors for input transitions";
    protected
      Real maxSpeedSumIn;
      Real prelimSpeedSumIn;
      Real prelimDecFactorIn;
      Real modSpeedOut;
      Boolean anyFireIn = Functions.anyTrue(firingIn);
      Integer numFireIn = Functions.numTrue(firingIn);
      Integer numFireOut = Functions.numTrue(firingOut);
      Boolean stop;
    algorithm
      decFactorIn := fill(-1, nIn);
      modSpeedOut := speedOut;
      stop := false;
      maxSpeedSumIn := 0;
      prelimSpeedSumIn := 0;
      prelimDecFactorIn := 0;
      if numFireOut > 0 and numFireIn > 1 then
        prelimSpeedSumIn := Functions.conditionalSum(arcWeightIn .* prelimSpeedIn, firingIn);
        maxSpeedSumIn := Functions.conditionalSum(arcWeightIn .* maxSpeedIn, firingIn);
        if maxSpeedSumIn > 0 then
          if not t < maxMarks and speedOut < prelimSpeedSumIn then
            prelimDecFactorIn := speedOut / maxSpeedSumIn;
            while not stop loop
              stop := true;
              for i in 1:nIn loop
                if firingIn[i] and prelimDecFactorIn * maxSpeedIn[i] > prelimSpeedIn[i] and decFactorIn[i] < 0 and prelimDecFactorIn < 1 then
                  decFactorIn[i] := prelimSpeedIn[i] / maxSpeedIn[i];
                  modSpeedOut := modSpeedOut - arcWeightIn[i] * prelimSpeedIn[i];
                  maxSpeedSumIn := maxSpeedSumIn - arcWeightIn[i] * maxSpeedIn[i];
                  stop := false;
                else
                end if;
              end for;
              if maxSpeedSumIn > 0 then
                prelimDecFactorIn := modSpeedOut / maxSpeedSumIn;
              else
                prelimDecFactorIn := 1;
              end if;
            end while;
            for i in 1:nIn loop
              if decFactorIn[i] < 0 then
                decFactorIn[i] := prelimDecFactorIn;
              else
              end if;
            end for;
          else
            decFactorIn := fill(1, nIn);
          end if;
        else
          decFactorIn := fill(1, nIn);
        end if;
      else
        decFactorIn := fill(1, nIn);
      end if;
    end decreasingFactorIn;

    function decreasingFactorOut  "calculation of decreasing factors"
      parameter input Integer nOut "number of output transitions";
      input Real t "marking";
      input Real minMarks "minimum capacity";
      input Real speedIn "input speed";
      input Real[:] maxSpeedOut "maximum speeds of output transitions";
      input Real[:] prelimSpeedOut "preliminary speeds of output transitions";
      input Real[:] arcWeightOut "arc weights of output transitions";
      input Boolean[:] firingIn "firability of input transitions";
      input Boolean[:] firingOut "firability of output transitions";
      output Real[nOut] decFactorOut "decreasing factors for output transitions";
    protected
      Real maxSpeedSumOut;
      Real prelimSpeedSumOut;
      Real prelimDecFactorOut;
      Real modSpeedIn;
      Boolean anyFireIn = Functions.anyTrue(firingIn);
      Integer numFireOut = Functions.numTrue(firingOut);
      Integer numFireIn = Functions.numTrue(firingIn);
      Boolean stop;
    algorithm
      decFactorOut := fill(-1, nOut);
      modSpeedIn := speedIn;
      stop := false;
      maxSpeedSumOut := 0;
      prelimSpeedSumOut := 0;
      prelimDecFactorOut := 0;
      stop := false;
      if numFireOut > 1 and numFireIn > 0 then
        prelimSpeedSumOut := Functions.conditionalSum(arcWeightOut .* prelimSpeedOut, firingOut);
        maxSpeedSumOut := Functions.conditionalSum(arcWeightOut .* maxSpeedOut, firingOut);
        if maxSpeedSumOut > 0 then
          if not t > minMarks and speedIn < prelimSpeedSumOut then
            prelimDecFactorOut := speedIn / maxSpeedSumOut;
            while not stop loop
              stop := true;
              for i in 1:nOut loop
                if firingOut[i] and prelimDecFactorOut * maxSpeedOut[i] > prelimSpeedOut[i] and decFactorOut[i] < 0 and prelimDecFactorOut < 1 then
                  decFactorOut[i] := prelimSpeedOut[i] / maxSpeedOut[i];
                  modSpeedIn := modSpeedIn - arcWeightOut[i] * prelimSpeedOut[i];
                  maxSpeedSumOut := maxSpeedSumOut - arcWeightOut[i] * maxSpeedOut[i];
                  stop := false;
                else
                end if;
              end for;
              if maxSpeedSumOut > 0 then
                prelimDecFactorOut := modSpeedIn / maxSpeedSumOut;
              else
              end if;
            end while;
            for i in 1:nOut loop
              if decFactorOut[i] < 0 then
                decFactorOut[i] := prelimDecFactorOut;
              else
              end if;
            end for;
          else
            decFactorOut := fill(1, nOut);
          end if;
        else
          decFactorOut := fill(1, nOut);
        end if;
      else
        decFactorOut := fill(1, nOut);
      end if;
    end decreasingFactorOut;

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

  package Constants  "contains constants which are used in the Petri net component models"
    final constant Real inf = 3.40282e+038 "Biggest Real number such that inf and -inf are representable on the machine";
  end Constants;

  package Types
    type ArcType = enumeration(normal_arc, inhibitor_arc);
  end Types;

  package Examples
    model Test2
      inner Settings settings;
      ConPNlib.TC T1(nIn = 1, nOut = 0, maximumSpeed = 2 * P1.t);
      ConPNlib.PC P1(nOut = 1, startMarks = 1);
    equation
      connect(P1.outTransition[1], T1.inPlaces[1]);
      annotation(experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006));
    end Test2;
  end Examples;
end ConPNlib;

model Test2_total
  extends ConPNlib.Examples.Test2;
 annotation(experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006));
end Test2_total;
