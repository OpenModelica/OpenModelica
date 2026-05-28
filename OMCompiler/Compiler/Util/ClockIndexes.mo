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
    case _                          then "NON";
    case _              then "STO";
    case _         then "SSI";
    case _                 then "BLD";
    case _                    then "EXS";
    case _                    then "FRT";
    case _                     then "BCK";
    case _                     then "SCD";
    case _                   then "LIN";
    case _                   then "TMP";
    case _               then "UNC";
    case _                         then "PR0";
    case _                         then "PR1";
    case _                         then "PR2";
    case _          then "JAC";
    case _               then "RES";
    case _      then "HPC";
    case _              then "STM";
    case _                       then "FIN";
    case _          then "SIM";
    case _  then "INI";
    else "ERR";
  end match;
end toString;

annotation(__OpenModelica_Interface="util");
end ClockIndexes;
