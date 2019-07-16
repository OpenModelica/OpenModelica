  module ClockIndexes


    using MetaModelica

         #= /*
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
         * from the URLs: http:www.ida.liu.se/projects/OpenModelica or
         * http:www.openmodelica.org, and in the OpenModelica distribution.
         * GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
         *
         * This program is distributed WITHOUT ANY WARRANTY; without
         * even the implied warranty of  MERCHANTABILITY or FITNESS
         * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
         * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
         *
         * See the full OSMC Public License conditions for more details.
         *
         */ =#

         RT_CLOCK_SIMULATE_TOTAL = 8::ModelicaInteger

         RT_CLOCK_SIMULATE_SIMULATION = 9::ModelicaInteger

         RT_CLOCK_BUILD_MODEL = 10::ModelicaInteger

         RT_CLOCK_EXECSTAT = 11::ModelicaInteger

         RT_CLOCK_EXECSTAT_CUMULATIVE = 12::ModelicaInteger

         RT_CLOCK_FRONTEND = 13::ModelicaInteger

         RT_CLOCK_BACKEND = 14::ModelicaInteger

         RT_CLOCK_SIMCODE = 15::ModelicaInteger

         RT_CLOCK_LINEARIZE = 16::ModelicaInteger

         RT_CLOCK_TEMPLATES = 17::ModelicaInteger

         RT_CLOCK_UNCERTAINTIES = 18::ModelicaInteger

         RT_PROFILER0 = 19::ModelicaInteger

         RT_PROFILER1 = 20::ModelicaInteger

         RT_PROFILER2 = 21::ModelicaInteger

         RT_CLOCK_EXECSTAT_JACOBIANS = 22::ModelicaInteger

         RT_CLOCK_USER_RESERVED = 23::ModelicaInteger

         RT_CLOCK_EXECSTAT_HPCOM_MODULES = 24::ModelicaInteger

         RT_CLOCK_SHOW_STATEMENT = 25::ModelicaInteger

         RT_CLOCK_FINST = 26::ModelicaInteger

         buildModelClocks = list(RT_CLOCK_BUILD_MODEL, RT_CLOCK_SIMULATE_TOTAL, RT_CLOCK_TEMPLATES, RT_CLOCK_LINEARIZE, RT_CLOCK_SIMCODE, RT_CLOCK_BACKEND, RT_CLOCK_FRONTEND)::List

  end