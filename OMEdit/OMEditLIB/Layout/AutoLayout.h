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

/*
 * @author John Tinnerholm
 */

#ifndef AUTOLAYOUT_H
#define AUTOLAYOUT_H

#include <QString>
#include <QStringList>

/*!
 * \brief The AutoLayout class
 * Gives the components of a Modelica class a Placement and its connections a Line with
 * mocoal (https://github.com/OpenModelica/mocoal-rs), run as a child process: a crash or a hang of mocoal leaves
 * OMEdit running.
 */
class AutoLayout
{
public:
  struct Options {
    QString layout = "layered";       // layered, spring, grid
    QString route = "orthogonal";     // orthogonal, straight, bezier, none
    QString direction = "right";      // right, down
    double dx = 30.0;                 // space between components
    double dy = 20.0;
    double scale = 1.0;               // factor on the default component size
    bool keep = false;                // keep existing placements and lines, add what is missing
    bool rotate = true;               // turn two-pin components
    QString graphics = "move";        // shapes of the Diagram layer: move, keep, drop
    int stackMB = 256;                // stack of the layout in MB; a level of nesting in the model takes about 3 KB
    QString className;                // the class to lay out (with the classes in it)
    QStringList libraries;            // directories with libraries, searched before the default ones
    bool showProgress = true;         // after a second a dialog with Cancel; false: wait without an event loop (MCP)
  };
  static bool isRunning();
  static QString program();
  static QString savedProgram();
  static void setProgram(const QString &path);
  static QString findProgram();
  static QStringList arguments(const Options &options);
  static bool layout(const QString &text, const QString &fileName, const Options &options, QString *pResult, QString *pMessage);
  static bool layoutClass(const QString &before, const QString &classText, const QString &after, const QString &fileName,
                          const Options &options, QString *pNewClassText, QString *pMessage);
};

#endif // AUTOLAYOUT_H
