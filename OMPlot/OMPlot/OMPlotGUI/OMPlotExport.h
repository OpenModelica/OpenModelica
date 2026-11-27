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

#ifndef OMPLOTEXPORT_H
#define OMPLOTEXPORT_H

// MSVC needs the class explicitly exported so its Qt staticMetaObject (a data
// symbol) is visible across the OMPlotLib DLL boundary; WINDOWS_EXPORT_ALL_SYMBOLS
// only covers functions. MinGW exports everything itself, but the users of the
// DLL need dllimport there too: without it &PlotWindow::closingDown is the address
// of an import thunk and a function pointer connect() finds no such signal.
#if defined(_WIN32)
#  ifdef OMPLOTLIB_LIBRARY
#    ifdef _MSC_VER
#      define OMPLOT_EXPORT __declspec(dllexport)
#    else
#      define OMPLOT_EXPORT
#    endif
#  else
#    define OMPLOT_EXPORT __declspec(dllimport)
#  endif
#else
#  define OMPLOT_EXPORT
#endif

#endif // OMPLOTEXPORT_H
