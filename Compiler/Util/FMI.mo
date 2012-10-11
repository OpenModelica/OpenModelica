/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
 
 encapsulated package FMI
" file:         FMI.mo
  package:     FMI
  description: This file contains FMI's import specific function, which are implemented in C."

public uniontype Info
  record INFO
    String fmiVersion;
    Integer fmiType;
    String fmiModelName;
    String fmiModelIdentifier;
    String fmiGuid;
    String fmiDescription;
    String fmiGenerationTool;
    String fmiGenerationDateAndTime;
    String fmiVariableNamingConvention;
    list<Integer> fmiNumberOfContinuousStates;
    list<Integer> fmiNumberOfEventIndicators;
  end INFO;
end Info;

public uniontype ExperimentAnnotation
  record EXPERIMENTANNOTATION
    Real fmiExperimentStartTime;
    Real fmiExperimentStopTime;
    Real fmiExperimentTolerance;
  end EXPERIMENTANNOTATION;
end ExperimentAnnotation;

public uniontype ModelVariables
  record REALVARIABLE
    Integer instance;
    String name;
    String description;
    String baseType;
    String variability;
    String causality;
    Boolean hasStartValue;
    Real startValue;
    Boolean isFixed;
    Integer valueReference;
  end REALVARIABLE;
  
  record INTEGERVARIABLE
    Integer instance;
    String name;
    String description;
    String baseType;
    String variability;
    String causality;
    Boolean hasStartValue;
    Integer startValue;
    Boolean isFixed;
    Integer valueReference;
  end INTEGERVARIABLE;
  
  record BOOLEANVARIABLE
    Integer instance;
    String name;
    String description;
    String baseType;
    String variability;
    String causality;
    Boolean hasStartValue;
    Boolean startValue;
    Boolean isFixed;
    Integer valueReference;
  end BOOLEANVARIABLE;
  
  record STRINGVARIABLE
    Integer instance;
    String name;
    String description;
    String baseType;
    String variability;
    String causality;
    Boolean hasStartValue;
    String startValue;
    Boolean isFixed;
    Integer valueReference;
  end STRINGVARIABLE;
  
  record ENUMERATIONVARIABLE
    Integer instance;
    String name;
    String description;
    String baseType;
    String variability;
    String causality;
    Boolean hasStartValue;
    Integer startValue;
    Boolean isFixed;
    Integer valueReference;
  end ENUMERATIONVARIABLE;
end ModelVariables;

public uniontype FmiImport
  record FMIIMPORT
    String platform;
    String fmuFileName;
    String fmuWorkingDirectory;
    Integer fmiLogLevel;
    Integer fmiContext;
    Integer fmiInstance;
    Info fmiInfo;
    ExperimentAnnotation fmiExperimentAnnotation;
    Integer fmiModelVariablesInstance;
    list<ModelVariables> fmiModelVariablesList;
  end FMIIMPORT;
end FmiImport;

public function countRealVariables
  input list<ModelVariables> inVariables;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue(inVariables)
    local
      Integer res;
      String v;
      list<ModelVariables> vars;
    /* Don't count the parameters */
    case (REALVARIABLE(variability = v) :: vars)
      equation
        true = stringEq(v,"");
        res = countRealVariables(vars);
      then
        res + 1;
    case (_ :: vars)
      equation
        res = countRealVariables(vars);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countRealVariables;

public function countRealStartVariables
  input list<ModelVariables> inVariables;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue(inVariables)
    local
      Integer res;
      list<ModelVariables> vars;
    case (REALVARIABLE(hasStartValue = true) :: vars)
      equation
        res = countRealStartVariables(vars);
      then
        res + 1;
    case (_ :: vars)
      equation
        res = countRealStartVariables(vars);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countRealStartVariables;

public function countIntegerVariables
  input list<ModelVariables> inVariables;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue(inVariables)
    local
      Integer res;
      String v;
      list<ModelVariables> vars;
    /* Don't count the parameters */
    case (INTEGERVARIABLE(variability = v) :: vars)
      equation
        true = stringEq(v,"");
        res = countIntegerVariables(vars);
      then
        res + 1;
    case (_ :: vars)
      equation
        res = countIntegerVariables(vars);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countIntegerVariables;

public function countIntegerStartVariables
  input list<ModelVariables> inVariables;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue(inVariables)
    local
      Integer res;
      list<ModelVariables> vars;
    case (INTEGERVARIABLE(hasStartValue = true) :: vars)
      equation
        res = countIntegerStartVariables(vars);
      then
        res + 1;
    case (_ :: vars)
      equation
        res = countIntegerStartVariables(vars);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countIntegerStartVariables;

public function countBooleanVariables
  input list<ModelVariables> inVariables;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue(inVariables)
    local
      Integer res;
      String v;
      list<ModelVariables> vars;
    /* Don't count the parameters */
    case (BOOLEANVARIABLE(variability = v) :: vars)
      equation
        true = stringEq(v,"");
        res = countBooleanVariables(vars);
      then
        res + 1;
    case (_ :: vars)
      equation
        res = countBooleanVariables(vars);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countBooleanVariables;

public function countBooleanStartVariables
  input list<ModelVariables> inVariables;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue(inVariables)
    local
      Integer res;
      list<ModelVariables> vars;
    case (BOOLEANVARIABLE(hasStartValue = true) :: vars)
      equation
        res = countBooleanStartVariables(vars);
      then
        res + 1;
    case (_ :: vars)
      equation
        res = countBooleanStartVariables(vars);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countBooleanStartVariables;

public function countStringVariables
  input list<ModelVariables> inVariables;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue(inVariables)
    local
      Integer res;
      String v;
      list<ModelVariables> vars;
    /* Don't count the parameters */
    case (STRINGVARIABLE(variability = v) :: vars)
      equation
        true = stringEq(v,"");
        res = countStringVariables(vars);
      then
        res + 1;
    case (_ :: vars)
      equation
        res = countStringVariables(vars);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countStringVariables;

public function countStringStartVariables
  input list<ModelVariables> inVariables;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue(inVariables)
    local
      Integer res;
      list<ModelVariables> vars;
    case (STRINGVARIABLE(hasStartValue = true) :: vars)
      equation
        res = countStringStartVariables(vars);
      then
        res + 1;
    case (_ :: vars)
      equation
        res = countStringStartVariables(vars);
      then
        res;
    case ({}) then 0;
  end matchcontinue;
end countStringStartVariables;

public function getFMIModelIdentifier
  input Info inFMIInfo;
  output String fmiModelIdentifier;
algorithm
  fmiModelIdentifier := match(inFMIInfo)
    local
      String modelIdentifier;
    case (INFO(fmiModelIdentifier = modelIdentifier)) then modelIdentifier;
  end match;
end getFMIModelIdentifier;

public function getFMIType
  input Info inFMIInfo;
  output String fmiType;
algorithm
  fmiType := match(inFMIInfo)
    case (INFO(fmiType = 0)) then "me";
    case (INFO(fmiType = 1)) then "cs_st";
    case (INFO(fmiType = 2)) then "cs_tool";
  end match;
end getFMIType;

end FMI;
