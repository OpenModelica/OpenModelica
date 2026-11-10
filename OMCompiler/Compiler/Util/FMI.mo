/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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

protected import Flags;
protected import List;

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

  /* The records above describe an FMI 1.0 or 2.0 ScalarVariable. FMI 3.0 has a
     different variable model and gets its own records, so that the import of the
     older versions keeps working exactly as it did:

       - there is no single Real and no single Integer any more. Float32 and
         Float64 are separate elements, and so are Int8/16/32/64 and their
         unsigned counterparts. Grouping them the way Modelica sees them keeps
         one record per Modelica type; fmiType carries the element the FMU
         actually used, which the wrapper needs to call the right setter.
       - any variable can be an array, described by Dimension elements. An empty
         dimensions list is a scalar.
       - Binary and Clock have no counterpart in FMI 1.0 or 2.0 at all.
       - value references are UInt32, so they are Integer here rather than the
         Real the older records use. */

  record FMI3REALVARIABLE "an FMI 3.0 Float32 or Float64 variable"
    Integer instance;
    String name;
    String description;
    String baseType;
    String fmiType "Float32 or Float64";
    String variability;
    String causality;
    Boolean hasStartValue;
    list<Real> startValue "one element for a scalar, one per element for an array";
    Boolean isFixed;
    Integer valueReference;
    list<Integer> dimensions "empty for a scalar";
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
  end FMI3REALVARIABLE;

  record FMI3INTEGERVARIABLE "an FMI 3.0 Int8/16/32/64 or UInt8/16/32/64 variable"
    Integer instance;
    String name;
    String description;
    String baseType;
    String fmiType "Int8, UInt8, Int16, ... Int64, UInt64";
    String variability;
    String causality;
    Boolean hasStartValue;
    list<Integer> startValue;
    Boolean isFixed;
    Integer valueReference;
    list<Integer> dimensions;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
  end FMI3INTEGERVARIABLE;

  record FMI3BOOLEANVARIABLE "an FMI 3.0 Boolean variable"
    Integer instance;
    String name;
    String description;
    String baseType;
    String fmiType;
    String variability;
    String causality;
    Boolean hasStartValue;
    list<Boolean> startValue;
    Boolean isFixed;
    Integer valueReference;
    list<Integer> dimensions;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
  end FMI3BOOLEANVARIABLE;

  record FMI3STRINGVARIABLE "an FMI 3.0 String variable"
    Integer instance;
    String name;
    String description;
    String baseType;
    String fmiType;
    String variability;
    String causality;
    Boolean hasStartValue;
    list<String> startValue;
    Boolean isFixed;
    Integer valueReference;
    list<Integer> dimensions;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
  end FMI3STRINGVARIABLE;

  record FMI3BINARYVARIABLE "an FMI 3.0 Binary variable, which Modelica has no type for"
    Integer instance;
    String name;
    String description;
    String baseType;
    String fmiType;
    String variability;
    String causality;
    Boolean hasStartValue;
    list<String> startValue "the start attribute, which FMI 3.0 writes as hex";
    Boolean isFixed;
    Integer valueReference;
    list<Integer> dimensions;
    String mimeType;
    Integer maxSize "0 when the FMU did not say";
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
  end FMI3BINARYVARIABLE;

  record FMI3CLOCKVARIABLE "an FMI 3.0 Clock variable"
    Integer instance;
    String name;
    String description;
    String baseType;
    String fmiType;
    String variability;
    String causality;
    Boolean hasStartValue;
    Boolean isFixed;
    Integer valueReference;
    list<Integer> dimensions;
    String intervalVariability;
    Real intervalDecimal "0.0 when the FMU did not say";
    Boolean hasIntervalDecimal;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
  end FMI3CLOCKVARIABLE;

  record FMI3ENUMERATIONVARIABLE "an FMI 3.0 Enumeration variable"
    Integer instance;
    String name;
    String description;
    String baseType;
    String fmiType;
    String variability;
    String causality;
    Boolean hasStartValue;
    list<Integer> startValue;
    Boolean isFixed;
    Integer valueReference;
    list<Integer> dimensions;
    String declaredType;
    Integer x1Placement;
    Integer x2Placement;
    Integer y1Placement;
    Integer y2Placement;
  end FMI3ENUMERATIONVARIABLE;
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
  fmiModelIdentifier := match inFMIInfo
    local
      String modelIdentifier;
    case INFO(fmiModelIdentifier = modelIdentifier) then modelIdentifier;
  end match;
end getFMIModelIdentifier;

public function getFMIType
  input Info inFMIInfo;
  output String fmiType;
algorithm
  fmiType := match inFMIInfo
    case INFO(fmiVersion = "1.0", fmiType = 0) then "me";
    case INFO(fmiVersion = "1.0", fmiType = 1) then "cs_st";
    case INFO(fmiVersion = "1.0", fmiType = 2) then "cs_tool";
    case INFO(fmiVersion = "2.0", fmiType = 1) then "me";
    case INFO(fmiVersion = "2.0", fmiType = 2) then "cs";
    case INFO(fmiVersion = "2.0", fmiType = 3) then "me_cs";
    /* FMI 3.0 numbers its interface types as flags, so 2, 4 and 8 rather than the
       1, 2, 3 of FMI 2.0; see fmi3_fmu_kind_enu_t. FMIImpl.c stores the one the
       import picked, not the set the FMU offers. */
    case INFO(fmiVersion = "3.0", fmiType = 2) then "me";
    case INFO(fmiVersion = "3.0", fmiType = 4) then "cs";
    case INFO(fmiVersion = "3.0", fmiType = 8) then "se";
    else "";
  end match;
end getFMIType;

public function getFMIVersion
  input Info inFMIInfo;
  output String fmiVersion;
algorithm
  fmiVersion := match inFMIInfo
    local
      String version;
    case INFO(fmiVersion = version) then version;
  end match;
end getFMIVersion;

public function checkFMIVersion "Checks if the FMU version is supported."
  input String inFMIVersion;
  output Boolean success;
algorithm
  success := match inFMIVersion
    case "1.0" then true;
    case "2.0" then true;
    case "3.0" then true;
    else false;
  end match;
end checkFMIVersion;

public function isFMIVersion10 "Checks if the FMI version is 1.0."
  input String inFMUVersion;
  output Boolean success;
algorithm
  success := match inFMUVersion
    case "1.0" then true;
    else false;
  end match;
end isFMIVersion10;

public function isFMIVersion20 "Checks if the FMI version is 2.0."
  input String inFMUVersion = getFMIVersionString();
  output Boolean success;
algorithm
  success := match inFMUVersion
    case "2.0" then true;
    else false;
  end match;
end isFMIVersion20;

public function isFMIVersion30 "Checks if the FMI version is 3.0."
  input String inFMUVersion = getFMIVersionString();
  output Boolean success;
algorithm
  success := match inFMUVersion
    case "3.0" then true;
    else false;
  end match;
end isFMIVersion30;

public function getFMIVersionString "Returns the FMI version string."
  output String version = Flags.getConfigString(Flags.FMI_VERSION);
end getFMIVersionString;

public function checkFMIType "Checks if the FMU type is supported."
  input String inFMIType;
  output Boolean success;
algorithm
  success := match inFMIType
    case "me" then true;
    case "cs" then true;
    case "me_cs" then true;
    case "se" then true;
    else false;
  end match;
end checkFMIType;

public function canExportFMU
  input String inFMUVersion;
  input String inFMIType;
  output Boolean success;
algorithm
  success := match (inFMUVersion, inFMIType)
    case ("1.0", "me") then true;
    case ("2.0", "me") then true;
    case ("2.0", "cs") then true;
    case ("2.0", "me_cs") then true;
    case ("3.0", "me") then true;
    case ("3.0", "cs") then true;
    case ("3.0", "me_cs") then true;
    case ("3.0", "se") then true;
    else false;
  end match;
end canExportFMU;

public function isFMIMEType "Checks if FMU type is model exchange"
  input String inFMIType;
  output Boolean success;
algorithm
  success := match inFMIType
    case "me" then true;
    case "me_cs" then true;
    else false;
  end match;
end isFMIMEType;

public function isFMICSType "Checks if FMU type is co-simulation"
  input String inFMIType;
  output Boolean success;
algorithm
  success := match inFMIType
    case "cs" then true;
    case "me_cs" then true;
    else false;
  end match;
end isFMICSType;

public function isFMISEType "Checks if FMU type is scheduled execution (FMI 3.0 only)"
  input String inFMIType;
  output Boolean success;
algorithm
  success := match inFMIType
    case "se" then true;
    else false;
  end match;
end isFMISEType;

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
      algorithm
        name_ := getEnumerationTypeFromTypes(xs, baseType);
      then
        name_;
    case ({}, _) then "";
  end match;
end getEnumerationTypeFromTypes;

public function filterModelVariables
  input list<ModelVariables> inModelVariables;
  input String tipe;
  input String variableCausality;
  output list<ModelVariables> outModelVariables;
algorithm
  outModelVariables := List.filter2OnTrue(inModelVariables, filterModelVariable, tipe, variableCausality);
end filterModelVariables;

protected function filterModelVariable
  input ModelVariables modelVar;
  input String tipe;
  input String variableCausality;
  output Boolean result;
algorithm
  result := match modelVar
    local
      String causality;
    case REALVARIABLE(causality=causality)
      guard tipe == "real" and causality == variableCausality
        then true;
    case INTEGERVARIABLE(causality=causality)
      guard tipe == "integer" and causality == variableCausality
        then true;
    case BOOLEANVARIABLE(causality=causality)
      guard tipe == "boolean" and causality == variableCausality
        then true;
    case STRINGVARIABLE(causality=causality)
      guard tipe == "string" and causality == variableCausality
        then true;
    /* The FMI 3.0 records answer to the same type names, so that a caller asking
       for the real inputs of an FMU does not have to know which FMI version it
       came from. Binary and Clock have no Modelica type and no name here; they
       are filtered out until the wrapper knows what to do with them. */
    case FMI3REALVARIABLE(causality=causality)
      guard tipe == "real" and causality == variableCausality
        then true;
    case FMI3INTEGERVARIABLE(causality=causality)
      guard tipe == "integer" and causality == variableCausality
        then true;
    case FMI3BOOLEANVARIABLE(causality=causality)
      guard tipe == "boolean" and causality == variableCausality
        then true;
    case FMI3STRINGVARIABLE(causality=causality)
      guard tipe == "string" and causality == variableCausality
        then true;
    else then false;
  end match;
end filterModelVariable;

annotation(__OpenModelica_Interface="util");
end FMI;
