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

encapsulated package ClockIndexes
" file:        ClockIndexes.mo
  package:     ClockIndexes
  description: Clock indexes used by the real-time clocks in a separate
    package to ease customisation (different indexes depending on
    back-end). Compiled as a utility package since Susan uses timers.

"

public constant Integer RT_NO_CLOCK = -1;

public constant Integer RT_CLOCK_SIMULATE_TOTAL = 8;
public constant Integer RT_CLOCK_SIMULATE_SIMULATION = 9;
public constant Integer RT_CLOCK_BUILD_MODEL = 10;
public constant Integer RT_CLOCK_EXECSTAT = 11;
public constant Integer RT_CLOCK_EXECSTAT_CUMULATIVE = 12;
public constant Integer RT_CLOCK_FRONTEND = 13;
public constant Integer RT_CLOCK_BACKEND = 14;
public constant Integer RT_CLOCK_SIMCODE = 15;
public constant Integer RT_CLOCK_LINEARIZE = 16;
public constant Integer RT_CLOCK_TEMPLATES = 17;
public constant Integer RT_CLOCK_UNCERTAINTIES = 18;
public constant Integer RT_PROFILER0=19;
public constant Integer RT_PROFILER1=20;
public constant Integer RT_PROFILER2=21;
public constant Integer RT_CLOCK_EXECSTAT_JACOBIANS=22;
public constant Integer RT_CLOCK_USER_RESERVED = 23;
public constant Integer RT_CLOCK_EXECSTAT_HPCOM_MODULES = 24;
public constant Integer RT_CLOCK_SHOW_STATEMENT = 25;
public constant Integer RT_CLOCK_FINST = 26;

public constant Integer RT_CLOCK_NEW_BACKEND_MODULE = 29;
public constant Integer RT_CLOCK_NEW_BACKEND_INITIALIZATION = 30;

public constant list<Integer> buildModelClocks = {RT_CLOCK_BUILD_MODEL,RT_CLOCK_SIMULATE_TOTAL,RT_CLOCK_TEMPLATES,RT_CLOCK_LINEARIZE,RT_CLOCK_SIMCODE,RT_CLOCK_BACKEND,RT_CLOCK_FRONTEND};

function toString
  input Integer clockIndex;
  output String str;
algorithm
  str := match clockIndex
    case RT_NO_CLOCK                          then "NON";
    case RT_CLOCK_SIMULATE_TOTAL              then "STO";
    case RT_CLOCK_SIMULATE_SIMULATION         then "SSI";
    case RT_CLOCK_BUILD_MODEL                 then "BLD";
    case RT_CLOCK_EXECSTAT                    then "EXS";
    case RT_CLOCK_EXECSTAT_CUMULATIVE         then "EXC";
    case RT_CLOCK_FRONTEND                    then "FRT";
    case RT_CLOCK_BACKEND                     then "BCK";
    case RT_CLOCK_SIMCODE                     then "SCD";
    case RT_CLOCK_LINEARIZE                   then "LIN";
    case RT_CLOCK_TEMPLATES                   then "TMP";
    case RT_CLOCK_UNCERTAINTIES               then "UNC";
    case RT_PROFILER0                         then "PR0";
    case RT_PROFILER1                         then "PR1";
    case RT_PROFILER2                         then "PR2";
    case RT_CLOCK_EXECSTAT_JACOBIANS          then "JAC";
    case RT_CLOCK_USER_RESERVED               then "RES";
    case RT_CLOCK_EXECSTAT_HPCOM_MODULES      then "HPC";
    case RT_CLOCK_SHOW_STATEMENT              then "STM";
    case RT_CLOCK_FINST                       then "FIN";
    case RT_CLOCK_NEW_BACKEND_MODULE          then "SIM";
    case RT_CLOCK_NEW_BACKEND_INITIALIZATION  then "INI";
    else "ERR";
  end match;
end toString;

annotation(__OpenModelica_Interface="util");
end ClockIndexes;
