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

#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#include <QApplication>
#else
#include <QtGui/QApplication>
#endif


#include "PlotMainWindow.h"
#include "PlotApplication.h"

using namespace OMPlot;

#define CONSUME_BOOL_ARG(i,n,var) { \
  if (0 == strcmp("true",argv[i]+n)) var = true; \
  else if (0 == strcmp("false",argv[i]+n)) var = false; \
  else {fprintf(stderr, "%s does not describe a boolean value\n", argv[i]);} \
}

void printUsage()
{
    printf("Usage: OMPlot [OPTIONS] [--filename=NAME] [variable names]\n");
    printf("OPTIONS\n");
    printf("    --title=TITLE              Sets the TITLE of the plot window\n");
    printf("    --filename=NAME            Sets the NAME of the file to plot\n");
    printf("    --grid=GRID                Sets the GRID of the plot i.e simple, detailed, none\n");
    printf("    --logx=[true|false]        Use log scale for the x-axis\n");
    printf("    --logy=[true|false]        Use log scale for the y-axis\n");
    printf("    --xlabel=LABEL             Use LABEL as the label of the x-axis\n");
    printf("    --ylabel=LABEL             Use LABEL as the label of the y-axis\n");
    printf("    --plot                     Create a normal plot\n");
    printf("    --plotAll                  Create a normal plot containing every variable in the result-file\n");
    printf("    --plotParametric           Create a parametric plot (plot variables as functions of each other)\n");
    printf("    --xrange=LEFT:RIGHT        Sets the initial range of the x-axis to LEFT:RIGHT\n");
    printf("    --yrange=LEFT:RIGHT        Sets the initial range of the y-axis to LEFT:RIGHT\n");
    printf("    --new-window=[true|false]  Create a MDI dialog in the plot-window\n");
    printf("    --curve-width=WIDTH        Sets the WIDTH of the curve\n");
    printf("    --curve-style=STYLE        Sets the STYLE of the curve. SolidLine=1, DashLine=2, DotLine=3, DashDotLine=4, DashDotDotLine=5, Sticks=6, Steps=7\n");
    printf("    --legend-position=POSITION Sets the POSITION of the legend i.e left, right, top, bottom, none\n");
    printf("    --footer=FOOTER            Sets the FOOTER of the plot window\n");
    printf("    --auto-scale=[true|false]  Use auto scale while plotting.\n");
}

void printShortUsage()
{
  printf("Usage: OMPlot [OPTIONS] [--filename=NAME] [variable names]\n");
  printf("       For detailed usage information, use 'OMPlot --help'.\n");
}

int main(int argc, char *argv[])
{
    // read the arguments
    QStringList arguments;
    bool newApplication = false;
    QString title("");
    QString grid = "detailed";
    QString plottype("plot");
    bool logx = false;
    bool logy = false;
    QString xlabel("time");
    QString ylabel("");
    double xrange1 = 0.0;
    double xrange2 = 0.0;
    double yrange1 = 0.0;
    double yrange2 = 0.0;
    double curveWidth = 1.0;
    int curveStyle = 1;
    QString legendPosition = "top";
    QString footer("");
    bool autoScale = true;
    QStringList vars;
    QString filename;
    for(int i = 1; i < argc; i++)
    {
        if (strncmp(argv[i], "--filename=", 11) == 0) {
          filename = argv[i]+11;
        } else if (strcmp(argv[i], "--help") == 0) {
          printUsage();
          return 1;
        } else if (strncmp(argv[i], "--title=", 8) == 0) {
          title = argv[i]+8;
        } else if (strncmp(argv[i], "--grid=",7) == 0) {
          grid = argv[i]+7;
        } else if (strncmp(argv[i], "--logx=",7) == 0) {
          CONSUME_BOOL_ARG(i,7,logx);
        } else if (strncmp(argv[i], "--logy=",7) == 0) {
          CONSUME_BOOL_ARG(i,7,logy);
        } else if (strcmp(argv[i], "--plot") == 0) {
          plottype = "plot";
        } else if (strcmp(argv[i], "--plotAll") == 0) {
          plottype = "plotAll";
        } else if (strcmp(argv[i], "--plotParametric") == 0) {
          plottype = "plotParametric";
        } else if (strncmp(argv[i], "--xlabel=",9) == 0) {
          xlabel = argv[i]+9;
        } else if (strncmp(argv[i], "--ylabel=",9) == 0) {
          ylabel = argv[i]+9;
        } else if (strncmp(argv[i], "--xrange=",9) == 0) {
          if (2 != sscanf(argv[i]+9, "%lf:%lf", &xrange1, &xrange2)) {
            fprintf(stderr, "Error: Expected format double:double, but got %s\n", argv[i]);
            return 1;
          }
        } else if (strncmp(argv[i], "--yrange=",9) == 0) {
          if (2 != sscanf(argv[i]+9, "%lf:%lf", &yrange1, &yrange2)) {
            fprintf(stderr, "Error: Expected format double:double, but got %s\n", argv[i]);
            return 1;
          }
        } else if (strncmp(argv[i], "--new-window=",13) == 0) {
          CONSUME_BOOL_ARG(i,13,newApplication);
        } else if (strncmp(argv[i], "--curve-width=",14) == 0) {
          if (1 != sscanf(argv[i]+14, "%lf", &curveWidth)) {
            fprintf(stderr, "Error: Expected format double, but got %s\n", argv[i]);
            return 1;
          }
        } else if (strncmp(argv[i], "--curve-style=",14) == 0) {
          if (1 != sscanf(argv[i]+14, "%d", &curveStyle)) {
            fprintf(stderr, "Error: Expected format int, but got %s\n", argv[i]);
            return 1;
          }
        } else if (strncmp(argv[i], "--legend-position=",18) == 0) {
          legendPosition = argv[i]+18;
        } else if (strncmp(argv[i], "--footer=", 9) == 0) {
          footer = argv[i]+9;
        } else if (strncmp(argv[i], "--auto-scale=",13) == 0) {
          CONSUME_BOOL_ARG(i,13,autoScale);
        } else if (strncmp(argv[i], "--", 2) == 0) {
          fprintf(stderr, "Error: Unknown option: %s\n", argv[i]);
          return 1;
        } else {
          vars.append(argv[i]);
        }
    }

    if (filename.length() == 0) {
      QStringList nameFilter = (QStringList() << "*.mat" << "*.csv");

      QDir directory(".");
      QStringList resultFiles = directory.entryList(nameFilter);
      int count = resultFiles.count();

      if(count == 0)
      {
        fprintf(stderr, "Error: No filename specified.\n");
        printShortUsage();
        return 1;
      }
      else if(count == 1)
      {
        filename = resultFiles.at(0);
        fprintf(stdout, "WARN:  No filename specified, so the following filename is assumed:\n       '%s'\n", filename.toUtf8().constData());
      }
      else
      {
        fprintf(stdout, "Info:  This directory contains following result files:\n");
        for(int i=0;i<count;i++)
          fprintf(stderr, "       * '%s'\n", resultFiles.at(i).toUtf8().constData());

        fprintf(stderr, "Error: No filename specified.\n");
        printShortUsage();
        return 1;
      }
    }

    if (vars.count() == 0) {
      fprintf(stderr, "Error: No variables specified.\n");
      printShortUsage();
      return 1;
    }

    // Hack to get the expected format of PlotApplication. Yes, this is totally crazy :)
    arguments.append(argv[0]);
    arguments.append(filename);
    arguments.append(title);
    arguments.append(grid);
    arguments.append(plottype);
    arguments.append(logx ? "true" : "false");
    arguments.append(logy ? "true" : "false");
    arguments.append(xlabel);
    arguments.append(ylabel);
    arguments.append(QString::number(xrange1));
    arguments.append(QString::number(xrange2));
    arguments.append(QString::number(yrange1));
    arguments.append(QString::number(yrange2));
    arguments.append(QString::number(curveWidth));
    arguments.append(QString::number(curveStyle));
    arguments.append(legendPosition);
    arguments.append(footer);
    arguments.append(autoScale ? "true" : "false");
    arguments.append(vars);
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
