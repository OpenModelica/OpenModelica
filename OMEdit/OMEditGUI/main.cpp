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
#include <QSplashScreen>

#include "SplashScreen.h"
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    Q_INIT_RESOURCE(resource_omedit);
    // read the second argument if specified by user.
    QString fileName = QString();
    // adding style sheet
    argc++;
    argv[(argc - 1)] = "-stylesheet=:/Resources/css/stylesheet.qss";

    QApplication a(argc, argv);
    QPixmap pixmap(":/Resources/icons/omeditor_splash.png");
    SplashScreen splashScreen(pixmap);
    splashScreen.setMessage();
    splashScreen.show();

    MainWindow mainwindow(&splashScreen);
    // if user has requested to open the file by passing it in argument then,
    if (a.arguments().size() > 1)
    {
        for (int i = 1; i < a.arguments().size(); i++)
        {
            fileName = a.arguments().at(i);
            if (!fileName.isEmpty())
            {
                // if path is relative make it absolute
                QFileInfo file (fileName);
                if (file.isRelative())
                {
                    fileName.prepend(QString(QDir::currentPath()).append("/"));
                }
                mainwindow.mpProjectTabs->openFile(fileName);
            }
        }
    }
    // finally show the main window
    mainwindow.showMaximized();
    // hide the splash screen
    splashScreen.finish(&mainwindow);
    if (mainwindow.mExitApplication)        // if there is some issue in running the application.
        return 1;
    else
        return a.exec();
}
