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
" file:   FMI.mo
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
    Integer fmiContext;
    Integer fmiInstance;
    Info fmiInfo;
    ExperimentAnnotation fmiExperimentAnnotation;
    Integer fmiModelVariablesInstance;
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
    case (INFO(fmiType = 0)) then "me";
    case (INFO(fmiType = 1)) then "cs_st";
    case (INFO(fmiType = 2)) then "cs_tool";
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

end FMI;
