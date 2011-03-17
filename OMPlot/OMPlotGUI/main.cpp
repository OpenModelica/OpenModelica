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
#include "PlotWindow.h"

using namespace OMPlot;

int main(int argc, char *argv[])
{
    if (argc < 14) {
      printf("Usage: %s filename title legend grid plottype logx logy xlabel ylabel xrange1 xrange2 yrange1 yrange2 variables\n", *argv);
      return 1;
    }
    QApplication a(argc, argv);    

    try {
        QStringList arguments;
        for(int i = 0; i < argc; i++)
            arguments.append(argv[i]);

        PlotWindow w(arguments);
        w.show();
        return a.exec();
    } catch (PlotException &e)
    {
        QMessageBox *msgBox = new QMessageBox();
        msgBox->setWindowTitle(QString("PlotWidgetGUI"));
        msgBox->setIcon(QMessageBox::Warning);
        msgBox->setText(QString(e.what()));
        msgBox->setStandardButtons(QMessageBox::Ok);
        msgBox->setDefaultButton(QMessageBox::Ok);
        msgBox->exec();

        return 1;
    }    
}
