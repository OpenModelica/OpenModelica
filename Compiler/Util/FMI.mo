/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

public uniontype TypeDefinitions
  record ENUMERATIONTYPE
    String name;
    String description;
    String quantity;
    Integer min;
    Integer max;
    list<EnumerationItem> items;
  end ENUMERATIONTYPE;
end TypeDefinitions;

public uniontype EnumerationItem
  record ENUMERATIONITEM
    String name;
    String description;
  end ENUMERATIONITEM;
end EnumerationItem;

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
    Real valueReference;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
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
    Real valueReference;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
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
    Real valueReference;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
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
    Real valueReference;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
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
    Real valueReference;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
  end ENUMERATIONVARIABLE;
end ModelVariables;

public uniontype FmiImport
  record FMIIMPORT
    String platform;
    String fmuFileName;
    String fmuWorkingDirectory;
    Integer fmiLogLevel;
    Boolean fmiDebugOutput;
    Option<Integer> fmiContext;
    Option<Integer> fmiInstance;
    Info fmiInfo;
    list<TypeDefinitions> fmiTypeDefinitionsList;
    ExperimentAnnotation fmiExperimentAnnotation;
    Option<Integer> fmiModelVariablesInstance;
    list<ModelVariables> fmiModelVariablesList;
    Boolean generateInputConnectors;
    Boolean generateOutputConnectors;
  end FMIIMPORT;
end FmiImport;

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
    case (INFO(fmiVersion = "1.0", fmiType = 0)) then "me";
    case (INFO(fmiVersion = "1.0", fmiType = 1)) then "cs_st";
    case (INFO(fmiVersion = "1.0", fmiType = 2)) then "cs_tool";
    case (INFO(fmiVersion = "2.0", fmiType = 1)) then "me";
    case (INFO(fmiVersion = "2.0", fmiType = 2)) then "cs";
    case (INFO(fmiVersion = "2.0", fmiType = 3)) then "me_cs";
  end match;
end getFMIType;

public function getFMIVersion
  input Info inFMIInfo;
  output String fmiVersion;
algorithm
  fmiVersion := match(inFMIInfo)
    local
      String version;
    case (INFO(fmiVersion = version)) then version;
  end match;
end getFMIVersion;

public function checkFMIVersion "Checks if the FMU version is supported."
  input String inFMIVersion;
  output Boolean success;
algorithm
  success := match (inFMIVersion)
    case ("1") then true;
    case ("1.0") then true;
    case ("2") then true;
    case ("2.0") then true;
    else false;
  end match;
end checkFMIVersion;

public function isFMIVersion10 "Checks if the FMI version is 1.0."
  input String inFMUVersion;
  output Boolean success;
algorithm
  success := match (inFMUVersion)
    case ("1") then true;
    case ("1.0") then true;
    else false;
  end match;
end isFMIVersion10;

public function isFMIVersion20 "Checks if the FMI version is 2.0."
  input String inFMUVersion;
  output Boolean success;
algorithm
  success := match (inFMUVersion)
    case ("2") then true;
    case ("2.0") then true;
    else false;
  end match;
end isFMIVersion20;

public function checkFMIType "Checks if the FMU type is supported."
  input String inFMIType;
  output Boolean success;
algorithm
  success := match (inFMIType)
    case ("me") then true;
    case ("cs") then true;
    case ("me_cs") then true;
    else false;
  end match;
end checkFMIType;

public function isFMIMEType "Checks if FMU type is model exchange"
  input String inFMIType;
  output Boolean success;
algorithm
  success := match (inFMIType)
    case ("me") then true;
    case ("me_cs") then true;
    else false;
  end match;
end isFMIMEType;

public function isFMICSType "Checks if FMU type is co-simulation"
  input String inFMIType;
  output Boolean success;
algorithm
  success := match (inFMIType)
    case ("cs") then true;
    case ("me_cs") then true;
    else false;
  end match;
end isFMICSType;

public function getEnumerationTypeFromTypes
  input list<TypeDefinitions> inTypeDefinitionsList;
  input String inBaseType;
  output String outEnumerationType;
algorithm
  outEnumerationType := match (inTypeDefinitionsList, inBaseType)
    local
      list<TypeDefinitions> xs;
      String name_;
      String baseType;
    case ((ENUMERATIONTYPE(name = name_) :: _), baseType) guard stringEqual(name_, baseType)
      then
        name_;
    case ((_ :: xs), baseType)
      equation
        name_ = getEnumerationTypeFromTypes(xs, baseType);
      then
        name_;
    case ({}, _) then "";
  end match;
end getEnumerationTypeFromTypes;

annotation(__OpenModelica_Interface="util");
end FMI;
