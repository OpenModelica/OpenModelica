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
#include <QTimer>

#include "SplashScreen.h"
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    // adding style sheet
    argc += 1;
    argv[1] = "-stylesheet=../OMEditGUI/Resources/css/stylesheet.qss";

    QApplication a(argc, argv);
    QPixmap pixmap("../OMEditGUI/Resources/icons/omeditor_splash.png");
    SplashScreen splashScreen(pixmap);
    splashScreen.setMessage();
    splashScreen.show();

    MainWindow mainwindow;
    mainwindow.showMaximized();
    splashScreen.finish(&mainwindow);
    if (mainwindow.mExitApplication)        // if there is some issue in running the application.
        return 1;
    else
        return a.exec();
}
