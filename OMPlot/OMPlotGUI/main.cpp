/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

#include <QtGui/QApplication>
#include "PlotMainWindow.h"
#include "PlotApplication.h"

using namespace OMPlot;

int main(int argc, char *argv[])
{
    if (argc < 14) {
      printf("Usage: %s filename title legend grid plottype logx logy xlabel ylabel xrange1 xrange2 yrange1 yrange2 variables -ew true/false\n", *argv);
      return 1;
    }
    // read the arguments
    QStringList arguments;
    bool newApplication = false;
    bool skiparguments = false;         // just used to skip 2 arguments(-ew, true/false)
    for(int i = 0; i < argc; i++)
    {
        if (strcmp(argv[i], "-ew") == 0)
        {
            skiparguments = true;
            if (strcmp(argv[i + 1], "true") == 0)
                newApplication = true;
            continue;
        }
        if (!skiparguments)
            arguments.append(argv[i]);
        else
            skiparguments = false;
    }
    // create the plot application object that is used to check that only one instance of application is running
    PlotApplication app(argc, argv, "OMPlot");
    // create the plot main window
    PlotMainWindow w;
    QObject::connect(&app, SIGNAL(messageAvailable(QStringList)),
                     w.getPlotWindowContainer(), SLOT(updateCurrentWindow(QStringList)));
    QObject::connect(&app, SIGNAL(newApplicationLaunched(QStringList)),
                     w.getPlotWindowContainer(), SLOT(addPlotWindow(QStringList)));
    try {
        if (!app.isRunning())
            w.addPlotWindow(arguments);
        // if there is no exception with plot window then continue
        if (app.isRunning())
        {
            if (newApplication)
                app.launchNewApplication(arguments);
            else
                app.sendMessage(arguments);
            return 0;
        }
        w.show();
        return app.exec();
    } catch (PlotException &e)
    {
        QMessageBox *msgBox = new QMessageBox();
        msgBox->setWindowTitle(QString("OMPlot - Error"));
        msgBox->setIcon(QMessageBox::Warning);
        msgBox->setText(QString(e.what()));
        msgBox->setStandardButtons(QMessageBox::Ok);
        msgBox->setDefaultButton(QMessageBox::Ok);
        msgBox->exec();
        return 1;
    }
}
