/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#include "PlotWindow.h"
#include "OMPlot.h"
#include "PlotZoomer.h"
#include "util/read_csv.h"
#include "util/read_matlab4.h"
#include "PlotCurve.h"
#include "PlotPicker.h"
#include "Legend.h"
#include "PlotPanner.h"
#include "PlotGrid.h"
#include "LogScaleEngine.h"
#include "LinearScaleEngine.h"

#include "qwt_plot_layout.h"
#include "qwt_text.h"
#if QWT_VERSION >= 0x060000
#include "qwt_plot_renderer.h"
#endif
#include "qwt_text_label.h"
#include "qwt_scale_widget.h"

#include <QtSvg/QSvgGenerator>
#include <QToolBar>
#include <QFileInfo>
#include <QLayout>
#include <QCloseEvent>
#include <QDir>
#include <QMessageBox>
#include <QFileDialog>
#include <QPainter>
#include <QPrinter>
#include <QPrintDialog>
#include <QRegExp>
#include <QStack>
#include <QLineEdit>
#include <QColorDialog>

using namespace OMPlot;

PlotWindow::PlotWindow(QStringList arguments, QWidget *parent, bool isInteractiveSimulation, int toolbarIconSize)
  : QMainWindow(parent), mIsInteractiveSimulation(isInteractiveSimulation)
{
  /* set the widget background white. so that the plot is more useable in books and publications. */
  QPalette p(palette());
  p.setColor(QPalette::Window, Qt::white);
  setAutoFillBackground(true);
  setPalette(p);
  // setup the main window widget
  setUpWidget(toolbarIconSize);
  // Keep default legend font since greek-mu for micro is not displayed correctly with monospaced font.
  setLegendFont(mpPlot->legend()->font());
  // initialize plot by reading all parameters passed to it
  if (arguments.size() > 1) {
    initializePlot(arguments);
    mpPlot->getPlotZoomer()->setZoomBase(false);
  }
  // set qwtplot the central widget
  setCentralWidget(getPlot());
}

PlotWindow::~PlotWindow()
{

}

void PlotWindow::setUpWidget(int toolbarIconSize)
{
  // create an instance of qwt plot
  mpPlot = new Plot(this);
  // set up the toolbar
  setupToolbar(toolbarIconSize);
  // set the default values
  // set the plot title
  setTitle(tr("Plot by OpenModelica"));
  // set the plot grid
  setGrid("simple");
}

void PlotWindow::initializePlot(QStringList arguments)
{
  // open the file
  initializeFile(QString(arguments[1]));
  //Set up arguments
  setTitle(QString(arguments[2]));
  setGrid(QString(arguments[3]));
  QString plotType = arguments[4];
  if (QString(arguments[5]) == "true") {
    setLogX(true);
  } else if (QString(arguments[5]) == "false") {
    setLogX(false);
  } else {
    throw PlotException("Invalid input" + arguments[5]);
  }
  if (QString(arguments[6]) == "true") {
    setLogY(true);
  } else if (QString(arguments[6]) == "false") {
    setLogY(false);
  } else {
    throw PlotException("Invalid input" + arguments[6]);
  }
  setXLabel(QString(arguments[7]));
  setYLabel(QString(arguments[8]));
  setXCustomLabel(getXLabel());
  setYCustomLabel(getYLabel());
  setXUnit("");
  setXDisplayUnit("");
  setYUnit("");
  setYDisplayUnit("");
  setXRange(QString(arguments[9]).toDouble(), QString(arguments[10]).toDouble());
  setYRange(QString(arguments[11]).toDouble(), QString(arguments[12]).toDouble());
  setCurveWidth(QString(arguments[13]).toDouble());
  setCurveStyle(QString(arguments[14]).toInt());
  setLegendPosition(QString(arguments[15]));
  setFooter(QString(arguments[16]));
  if (QString(arguments[17]) == "true") {
    setAutoScale(true);
  } else if (QString(arguments[17]) == "false") {
    setAutoScale(false);
  } else {
    throw PlotException("Invalid input" + arguments[17]);
  }
  setTimeUnit("");
  setPrefixUnits(true);
  /* read variables */
  QStringList variablesToRead;
  for(int i = 18; i < arguments.length(); i++)
    variablesToRead.append(QString(arguments[i]));

  setVariablesList(variablesToRead);
  //Plot
  if(plotType.toLower().compare("plot") == 0)
  {
    setPlotType(PlotWindow::PLOT);
    plot();
  }
  else if(plotType.toLower().compare("plotall") == 0)
  {
    setPlotType(PlotWindow::PLOTALL);
    plot();
  }
  else if(plotType.toLower().compare("plotparametric") == 0)
  {
    setPlotType(PlotWindow::PLOTPARAMETRIC);
    plotParametric();
  }
  else if (plotType.toLower().compare("plotinteractive") == 0)
  {
    setPlotType(PlotWindow::PLOTINTERACTIVE);
    plotInteractive();
  }
}

void PlotWindow::setVariablesList(QStringList variables)
{
  mVariablesList = variables;
}

void PlotWindow::setPlotType(PlotType type)
{
  mPlotType = type;
}

void PlotWindow::initializeFile(QString file)
{
  mFile.setFileName(file);
  if (!mFile.exists()) {
    throw NoFileException(QString("File not found : ").append(file).toStdString().c_str());
  }
}

void PlotWindow::getStartStopTime(double &start, double &stop){
  //PLOT PLT
  if (mFile.fileName().endsWith("plt"))
  {
    QString currentLine;
    // open the file
    mFile.open(QIODevice::ReadOnly);
    mpTextStream = new QTextStream(&mFile);
    // read the interval size from the file
    int intervalSize = 0;
    while (!mpTextStream->atEnd())
    {
      currentLine = mpTextStream->readLine();
      if (currentLine.startsWith("#IntervalSize"))
      {
        intervalSize = static_cast<QString>(currentLine.split("=").last()).toInt();
        break;
      }
    }
    // Read start and stop time
    while (!mpTextStream->atEnd())
    {
      currentLine = mpTextStream->readLine();
      QString currentVariable;
      if (currentLine.contains("DataSet:"))
      {
        currentVariable = currentLine.remove("DataSet: ");
        if (currentVariable == "time")
        {
          // read the variable values now
          currentLine = mpTextStream->readLine();
          QStringList values = currentLine.split(",");
          start = QString(values[0]).toDouble();
          for(int j = 0; j < intervalSize-1; j++)
          {
            currentLine = mpTextStream->readLine();
          }
          values = currentLine.split(",");
          stop = QString(values[0]).toDouble();
          break;
        }
      }
    }
    if(mpTextStream->atEnd()) throw NoVariableException("Variable doesnt exist: time");
    // close the file
    mFile.close();
  }
  //PLOT CSV
  else if (mFile.fileName().endsWith("csv"))
  {
    /* open the file */
    struct csv_data *csvReader;
    csvReader = read_csv(mFile.fileName().toStdString().c_str());
    if (csvReader == NULL) {
      throw NoVariableException("Variable doesnt exist: time");
    }
    //Read in timevector
    double *timeVals = read_csv_dataset(csvReader, "time");
    if (timeVals == NULL) {
      omc_free_csv_reader(csvReader);
      throw NoVariableException("Variable doesnt exist: time");
    }
    start = timeVals[0];
    stop = timeVals[csvReader->numsteps-1];

    // close the file
    omc_free_csv_reader(csvReader);
  }
  //PLOT MAT
  else if(mFile.fileName().endsWith("mat"))
  {
    ModelicaMatReader reader;
    const char *msg = "";
    //Read in mat file
    if(0 != (msg = omc_new_matlab4_reader(mFile.fileName().toStdString().c_str(), &reader))) {
      throw PlotException(msg);
    }

    //Read in timevector
    start = omc_matlab4_startTime(&reader);
    stop =  omc_matlab4_stopTime(&reader);

    // close the file
    omc_free_matlab4_reader(&reader);
  } else {throw PlotException(tr("Failed to open simulation result file %1").arg(mFile.fileName()));}
}

void PlotWindow::setupToolbar(int toolbarIconSize)
{
  QToolBar *toolBar = new QToolBar(this);
  setContextMenuPolicy(Qt::NoContextMenu);
  // if toolbarIconSize is not defined then its 0. In that case don't set the icon size.
  if (toolbarIconSize > 0) {
    setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  }
  // Interactive Simulation
  if (mIsInteractiveSimulation) {
    //start tool button
    mpStartSimulationToolButton = new QToolButton;
    mpStartSimulationToolButton->setText(tr("Start"));
    mpStartSimulationToolButton->setIcon(QIcon(":/Resources/icons/play_animation.svg"));
    mpStartSimulationToolButton->setToolTip(tr("Start"));
    mpStartSimulationToolButton->setAutoRaise(true);
    connect(mpStartSimulationToolButton, SIGNAL(clicked(bool)), SLOT(interactiveSimulationStarted()));
    // pause tool button
    mpPauseSimulationToolButton = new QToolButton;
    mpPauseSimulationToolButton->setEnabled(false);
    mpPauseSimulationToolButton->setText(tr("Pause"));
    mpPauseSimulationToolButton->setIcon(QIcon(":/Resources/icons/pause.svg"));
    mpPauseSimulationToolButton->setToolTip(tr("Pause"));
    mpPauseSimulationToolButton->setAutoRaise(true);
    connect(mpPauseSimulationToolButton, SIGNAL(clicked(bool)), SLOT(interactiveSimulationPaused()));
    // speed label and combo box
    mpSimulationSpeedLabel = new QLabel(tr("Speed:"));
    QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
    pDoubleValidator->setBottom(0.01);
    pDoubleValidator->setTop(100);
    mpSimulationSpeedComboBox = new QComboBox;
    mpSimulationSpeedComboBox->setEditable(true);
    mpSimulationSpeedComboBox->addItems(QStringList() << "10" << "5" << "2" << "1" << "0.5" << "0.2" << "0.1");
    mpSimulationSpeedComboBox->setCurrentIndex(3);
    mpSimulationSpeedComboBox->setCompleter(0);
    mpSimulationSpeedComboBox->setValidator(pDoubleValidator);
    // add the interactive controls
    toolBar->addWidget(mpStartSimulationToolButton);
    toolBar->addSeparator();
    toolBar->addWidget(mpPauseSimulationToolButton);
    toolBar->addSeparator();
    toolBar->addWidget(mpSimulationSpeedLabel);
    toolBar->addWidget(mpSimulationSpeedComboBox);
    toolBar->addSeparator();
  }
  // Auto scale
  mpAutoScaleButton = new QToolButton(toolBar);
  QString autoScale(tr("Auto Scale"));
  mpAutoScaleButton->setText(autoScale);
  mpAutoScaleButton->setToolTip(autoScale);
  mpAutoScaleButton->setStatusTip(autoScale);
  mpAutoScaleButton->setIcon(QIcon(":/Resources/icons/auto_scale.svg"));
  mpAutoScaleButton->setCheckable(true);
  connect(mpAutoScaleButton, SIGNAL(toggled(bool)), SLOT(setAutoScale(bool)));
  toolBar->addWidget(mpAutoScaleButton);
  toolBar->addSeparator();
  //Fit in View
  QToolButton *fitInViewButton = new QToolButton(toolBar);
  QString fitInView(tr("Fit in View"));
  fitInViewButton->setText(fitInView);
  fitInViewButton->setToolTip(fitInView);
  fitInViewButton->setStatusTip(fitInView);
  fitInViewButton->setIcon(QIcon(":/Resources/icons/fit-to-diagram.svg"));
  connect(fitInViewButton, SIGNAL(clicked()), SLOT(fitInView()));
  toolBar->addWidget(fitInViewButton);
  toolBar->addSeparator();
  //GRID
  mpGridComboBox = new QComboBox;
  mpGridComboBox->addItems(QStringList() << tr("Grid") << tr("Detailed Grid") << tr("No Grid"));
  connect(mpGridComboBox, SIGNAL(currentIndexChanged(int)), SLOT(setGrid(int)));
  toolBar->addWidget(mpGridComboBox);
  toolBar->addSeparator();
  //LOG x LOG y
  mpLogXCheckBox = new QCheckBox(tr("Log X"), this);
  connect(mpLogXCheckBox, SIGNAL(toggled(bool)), SLOT(setLogX(bool)));
  toolBar->addWidget(mpLogXCheckBox);
  toolBar->addSeparator();
  mpLogYCheckBox = new QCheckBox(tr("Log Y"), this);
  connect(mpLogYCheckBox, SIGNAL(toggled(bool)), SLOT(setLogY(bool)));
  toolBar->addWidget(mpLogYCheckBox);
  toolBar->addSeparator();
  // setup
  mpSetupButton = new QToolButton(toolBar);
  QString setup(tr("Setup"));
  mpSetupButton->setText(setup);
  mpSetupButton->setToolTip(setup);
  mpSetupButton->setStatusTip(setup);
  mpSetupButton->setIcon(QIcon(":/Resources/icons/options.svg"));
  connect(mpSetupButton, SIGNAL(clicked()), SLOT(showSetupDialog()));
  toolBar->addWidget(mpSetupButton);
  toolBar->addSeparator();
  //EXPORT
  QToolButton *btnExport = new QToolButton(toolBar);
  QString save(tr("Save"));
  btnExport->setText(save);
  btnExport->setToolTip(save);
  btnExport->setStatusTip(save);
  btnExport->setIcon(QIcon(":/Resources/icons/save.svg"));
  connect(btnExport, SIGNAL(clicked()), SLOT(exportDocument()));
  toolBar->addWidget(btnExport);
  toolBar->addSeparator();
  //PRINT
  QToolButton *btnPrint = new QToolButton(toolBar);
  QString print(tr("Print"));
  btnPrint->setText(print);
  btnPrint->setToolTip(print);
  btnPrint->setStatusTip(print);
  btnPrint->setIcon(QIcon(":/Resources/icons/print.svg"));
  connect(btnPrint, SIGNAL(clicked()), SLOT(printPlot()));
  toolBar->addWidget(btnPrint);
  // finally add the tool bar to the mainwindow
  addToolBar(toolBar);
}

void PlotWindow::plot(PlotCurve *pPlotCurve)
{
  QString currentLine;
  if (mVariablesList.isEmpty() && isPlot())
    throw NoVariableException(QString("No variables specified!").toStdString().c_str());

  bool editCase = pPlotCurve ? true : false;
  //PLOT PLT
  if (mFile.fileName().endsWith("plt"))
  {
    // open the file
    mFile.open(QIODevice::ReadOnly);
    mpTextStream = new QTextStream(&mFile);
    // read the interval size from the file
    int intervalSize = 0;
    while (!mpTextStream->atEnd())
    {
      currentLine = mpTextStream->readLine();
      if (currentLine.startsWith("#IntervalSize"))
      {
        intervalSize = static_cast<QString>(currentLine.split("=").last()).toInt();
        break;
      }
    }

    QStringList variablesPlotted;
    // Read variable values and plot them
    while (!mpTextStream->atEnd())
    {
      currentLine = mpTextStream->readLine();
      QString currentVariable;
      if (currentLine.contains("DataSet:"))
      {
        currentVariable = currentLine.remove("DataSet: ");
        if (mVariablesList.contains(currentVariable) || isPlotAll())
        {
          variablesPlotted.append(currentVariable);
          if (!editCase) {
            QFileInfo fileInfo(mFile);
            pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), "time", getXUnit(), getXDisplayUnit(), currentVariable, getYUnit(), getYDisplayUnit(), mpPlot);
            mpPlot->addPlotCurve(pPlotCurve);
          }
          // clear previous curve data
          pPlotCurve->clearXAxisVector();
          pPlotCurve->clearYAxisVector();
          // read the variable values now
          currentLine = mpTextStream->readLine();
          for(int j = 0; j < intervalSize; j++)
          {
            QStringList values = currentLine.split(",");
            pPlotCurve->addXAxisValue(QString(values[0]).toDouble());
            pPlotCurve->addYAxisValue(QString(values[1]).toDouble());
            currentLine = mpTextStream->readLine();
          }
          pPlotCurve->plotData();
          pPlotCurve->attach(mpPlot);
          mpPlot->replot();
        }
        // if plottype is PLOT and we have read all the variable we need to plot then simply break the loop
        if (isPlot() && mVariablesList.size() == variablesPlotted.size()) {
          break;
        }
      }
    }
    // if plottype is PLOT then check which requested variables are not found in the file
    if (isPlot())
      checkForErrors(mVariablesList, variablesPlotted);
    // close the file
    mFile.close();
  }
  //PLOT CSV
  else if (mFile.fileName().endsWith("csv"))
  {
    /* open the file */
    QStringList variablesPlotted;
    struct csv_data *csvReader;
    csvReader = read_csv(mFile.fileName().toStdString().c_str());
    if (csvReader == NULL)
      throw PlotException(tr("Failed to open simulation result file %1").arg(mFile.fileName()));

    //Read in timevector
    double *timeVals = read_csv_dataset(csvReader, "time");
    if (timeVals == NULL)
    {
      timeVals = read_csv_dataset(csvReader, "lambda");
      if (timeVals == NULL)
      {
        omc_free_csv_reader(csvReader);
        throw NoVariableException(tr("Variable doesnt exist: %1").arg("time or lambda").toStdString().c_str());
      }
      setXLabel("lambda");
    }

    // read in all values
    for (int i = 0; i < csvReader->numvars; i++)
    {
      if (mVariablesList.contains(csvReader->variables[i]) || isPlotAll())
      {
        variablesPlotted.append(csvReader->variables[i]);
        double *vals = read_csv_dataset(csvReader, csvReader->variables[i]);
        if (vals == NULL)
        {
          omc_free_csv_reader(csvReader);
          throw NoVariableException(tr("Variable doesnt exist: %1").arg(csvReader->variables[i]).toStdString().c_str());
        }

        if (!editCase) {
          QFileInfo fileInfo(mFile);
          pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), "time", getXUnit(), getXDisplayUnit(), csvReader->variables[i], getYUnit(), getYDisplayUnit(), mpPlot);
          mpPlot->addPlotCurve(pPlotCurve);
        }
        // clear previous curve data
        pPlotCurve->clearXAxisVector();
        pPlotCurve->clearYAxisVector();
        for (int i = 0 ; i < csvReader->numsteps ; i++)
        {
          pPlotCurve->addXAxisValue(timeVals[i]);
          pPlotCurve->addYAxisValue(vals[i]);
        }
        pPlotCurve->plotData();
        pPlotCurve->attach(mpPlot);
        mpPlot->replot();
      }
    }
    // if plottype is PLOT then check which requested variables are not found in the file
    if (isPlot())
      checkForErrors(mVariablesList, variablesPlotted);
    // close the file
    omc_free_csv_reader(csvReader);
  }
  //PLOT MAT
  else if(mFile.fileName().endsWith("mat"))
  {
    ModelicaMatReader reader;
    ModelicaMatVariable_t *var;
    const char *msg = "";
    QStringList variablesPlotted;

    //Read in mat file
    if(0 != (msg = omc_new_matlab4_reader(mFile.fileName().toStdString().c_str(), &reader))) {
      throw PlotException(msg);
    }

    if (reader.nvar < 1) {
      omc_free_matlab4_reader(&reader);
      throw NoVariableException("Variable doesnt exist: time");
    }

    double startTime = omc_matlab4_startTime(&reader);
    double stopTime =  omc_matlab4_stopTime(&reader);
    //Read in timevector
    double *timeVals = omc_matlab4_read_vals(&reader,1);
    if (!timeVals) {
      omc_free_matlab4_reader(&reader);
      throw NoVariableException(QString("Corrupt file. nvar %1").arg(reader.nvar).toStdString().c_str());
    }
    // read in all values
    for (uint32_t i = 0; i < reader.nall; i++) {
      if (mVariablesList.contains(reader.allInfo[i].name) || isPlotAll()) {
        variablesPlotted.append(reader.allInfo[i].name);
        // create the plot curve for variable
        if (!editCase) {
          QFileInfo fileInfo(mFile);
          pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), "time", getXUnit(), getXDisplayUnit(), reader.allInfo[i].name, getYUnit(), getYDisplayUnit(), mpPlot);
          mpPlot->addPlotCurve(pPlotCurve);
        }
        // read the variable values
        var = omc_matlab4_find_var(&reader, reader.allInfo[i].name);
        if (!var) {
          omc_free_matlab4_reader(&reader);
          throw NoVariableException(QString("Variable doesn't exist : ").append(reader.allInfo[i].name).toStdString().c_str());
        }
        // clear previous curve data
        pPlotCurve->clearXAxisVector();
        pPlotCurve->clearYAxisVector();
        // if variable is not a parameter then
        if (!var->isParam) {
          double *vals = omc_matlab4_read_vals(&reader,var->index);
          if (!vals) {
            omc_free_matlab4_reader(&reader);
            throw NoVariableException(QString("Corrupt file. nvar %1").arg(reader.nvar).toStdString().c_str());
          }
          // set plot curve data and attach it to plot
          for (uint32_t i = 0 ; i < reader.nrows ; i++) {
            pPlotCurve->addXAxisValue(timeVals[i]);
            pPlotCurve->addYAxisValue(vals[i]);
          }
          pPlotCurve->plotData();
          pPlotCurve->attach(mpPlot);
          mpPlot->replot();
        } else { // if variable is a parameter then
          double val;
          if (omc_matlab4_val(&val,&reader,var,0.0)) {
            omc_free_matlab4_reader(&reader);
            throw NoVariableException(QString("Parameter doesn't have a value : ").append(reader.allInfo[i].name).toStdString().c_str());
          }

          pPlotCurve->addXAxisValue(startTime);
          pPlotCurve->addYAxisValue(val);
          pPlotCurve->addXAxisValue(stopTime);
          pPlotCurve->addYAxisValue(val);
          pPlotCurve->plotData();
          pPlotCurve->attach(mpPlot);
          mpPlot->replot();
        }
      }
    }
    // if plottype is PLOT then check which requested variables are not found in the file
    if (isPlot())
      checkForErrors(mVariablesList, variablesPlotted);
    // close the file
    omc_free_matlab4_reader(&reader);
  }
}

void PlotWindow::plotParametric(PlotCurve *pPlotCurve)
{
  QString xVariable, yVariable, xTitle, yTitle;
  int pair = 0;

  if (mVariablesList.isEmpty())
    throw NoVariableException(QString("No variables specified!").toStdString().c_str());
  else if (mVariablesList.size()%2 != 0)
    throw NoVariableException(QString("Please specify variable pairs for plotParametric.").toStdString().c_str());

  bool editCase = pPlotCurve ? true : false;

  for (pair = 0; pair < mVariablesList.size(); pair += 2)
  {
    xVariable = mVariablesList.at(pair);
    yVariable = mVariablesList.at(pair+1);

    if (pair==0) {
      xTitle = xVariable;
      yTitle = yVariable;
    } else {
      xTitle += ", "+xVariable;
      yTitle += ", "+yVariable;
    }
    setXLabel(xTitle);
    setYLabel(yTitle);

    //PLOT PLT
    if (mFile.fileName().endsWith("plt"))
    {
      QString currentLine;
      // open the file
      mFile.open(QIODevice::ReadOnly);
      mpTextStream = new QTextStream(&mFile);
      // read the interval size from the file
      int intervalSize = 0;
      while (!mpTextStream->atEnd())
      {
        currentLine = mpTextStream->readLine();
        if (currentLine.startsWith("#IntervalSize"))
        {
          intervalSize = static_cast<QString>(currentLine.split("=").last()).toInt();
          break;
        }
      }

      QStringList variablesPlotted;
      // Read variable values and plot them
      while (!mpTextStream->atEnd())
      {
        currentLine = mpTextStream->readLine();
        QString currentVariable;
        if (currentLine.contains("DataSet:"))
        {
          currentVariable = currentLine.remove("DataSet: ");
          if (mVariablesList.contains(currentVariable))
          {
            variablesPlotted.append(currentVariable);
            if (variablesPlotted.size() == 1)
            {
              if (!editCase) {
                QFileInfo fileInfo(mFile);
                pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), xVariable, getXUnit(), getXDisplayUnit(), yVariable, getYUnit(), getYDisplayUnit(), mpPlot);
                mpPlot->addPlotCurve(pPlotCurve);
              }
              // clear previous curve data
              pPlotCurve->clearXAxisVector();
              pPlotCurve->clearYAxisVector();
            }
            // read the variable values now
            currentLine = mpTextStream->readLine();
            for(int j = 0; j < intervalSize; j++)
            {
              // add first variable to the xaxis vector and 2nd to yaxis vector
              QStringList values = currentLine.split(",");
              if (variablesPlotted.size() == 1)
                pPlotCurve->addXAxisValue(QString(values[1]).toDouble());
              else if (variablesPlotted.size() == 2)
                pPlotCurve->addYAxisValue(QString(values[1]).toDouble());
              currentLine = mpTextStream->readLine();
            }
            // when two variables are found plot then plot them
            if (variablesPlotted.size() == 2)
            {
              pPlotCurve->plotData();
              pPlotCurve->attach(mpPlot);
              mpPlot->replot();
            }
          }
          // if we have read all the variable we need to plot then simply break the loop
          if (mVariablesList.size() == variablesPlotted.size())
            break;
        }
      }
      // check which requested variables are not found in the file
      checkForErrors(mVariablesList, variablesPlotted);
      // close the file
      mFile.close();
    }
    //PLOT CSV
    else if (mFile.fileName().endsWith("csv"))
    {
      /* open the file */
      QStringList variablesPlotted;
      struct csv_data *csvReader;
      csvReader = read_csv(mFile.fileName().toStdString().c_str());
      if (csvReader == NULL)
        throw PlotException(tr("Failed to open simulation result file %1").arg(mFile.fileName()));

      double *xVals = NULL, *yVals = NULL;
      // read in all values
      for (int i = 0; i < csvReader->numvars; i++)
      {
        if ((xVariable.compare(csvReader->variables[i]) == 0))
        {
          variablesPlotted.append(csvReader->variables[i]);
          xVals = read_csv_dataset(csvReader, csvReader->variables[i]);
          if (xVals == NULL) {
            omc_free_csv_reader(csvReader);
            throw NoVariableException(tr("Variable doesnt exist: %1").arg(csvReader->variables[i]).toStdString().c_str());
          }
        }
        if ((yVariable.compare(csvReader->variables[i]) == 0))
        {
          variablesPlotted.append(csvReader->variables[i]);
          yVals = read_csv_dataset(csvReader, csvReader->variables[i]);
          if (yVals == NULL) {
            omc_free_csv_reader(csvReader);
            throw NoVariableException(tr("Variable doesnt exist: %1").arg(csvReader->variables[i]).toStdString().c_str());
          }
        }
      }

      if (!editCase) {
        QFileInfo fileInfo(mFile);
        pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), xVariable, getXUnit(), getXDisplayUnit(), yVariable, getYUnit(), getYDisplayUnit(), mpPlot);
        mpPlot->addPlotCurve(pPlotCurve);
      }
      // clear previous curve data
      pPlotCurve->clearXAxisVector();
      pPlotCurve->clearYAxisVector();
      for (int i = 0 ; i < csvReader->numsteps ; i++)
      {
        pPlotCurve->addXAxisValue(xVals[i]);
        pPlotCurve->addYAxisValue(yVals[i]);
      }
      pPlotCurve->plotData();
      pPlotCurve->attach(mpPlot);
      mpPlot->replot();
      // check which requested variables are not found in the file
      checkForErrors(mVariablesList, variablesPlotted);
      // close the file
      omc_free_csv_reader(csvReader);
    }
    //PLOT MAT
    else if(mFile.fileName().endsWith("mat"))
    {
      //Declare variables
      ModelicaMatReader reader;
      ModelicaMatVariable_t *var;
      const char *msg = "";

      //Read the .mat file
      if(0 != (msg = omc_new_matlab4_reader(mFile.fileName().toStdString().c_str(), &reader)))
        throw PlotException(msg);

      if (!editCase) {
        QFileInfo fileInfo(mFile);
        pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), xVariable, getXUnit(), getXDisplayUnit(), yVariable, getYUnit(), getYDisplayUnit(), mpPlot);
        mpPlot->addPlotCurve(pPlotCurve);
      }
      //Fill variable x with data
      var = omc_matlab4_find_var(&reader, xVariable.toStdString().c_str());
      if (!var) {
        omc_free_matlab4_reader(&reader);
        throw NoVariableException(QString("Variable doesn't exist : ").append(xVariable).toStdString().c_str());
      }
      // clear previous curve data
      pPlotCurve->clearXAxisVector();
      pPlotCurve->clearYAxisVector();
      // if variable is not a parameter then
      if (!var->isParam)
      {
        double *xVals = omc_matlab4_read_vals(&reader,var->index);
        if (!xVals) {
          omc_free_matlab4_reader(&reader);
          throw NoVariableException(QString("Corrupt file. nvar %1").arg(reader.nvar).toStdString().c_str());
        }
        for (uint32_t i = 0 ; i < reader.nrows ; i++)
          pPlotCurve->addXAxisValue(xVals[i]);
      }
      // if variable is a parameter then
      else
      {
        double xVal;
        if (omc_matlab4_val(&xVal,&reader,var,0.0)) {
          omc_free_matlab4_reader(&reader);
          throw NoVariableException(QString("Parameter doesn't have a value : ").append(xVariable).toStdString().c_str());
        }
        for (uint32_t i = 0 ; i < reader.nrows ; i++)
          pPlotCurve->addXAxisValue(xVal);
      }
      //Fill variable y with data
      var = omc_matlab4_find_var(&reader, yVariable.toStdString().c_str());
      if (!var) {
        omc_free_matlab4_reader(&reader);
        throw NoVariableException(QString("Variable doesn't exist : ").append(yVariable).toStdString().c_str());
      }
      // if variable is not a parameter then
      if (!var->isParam)
      {
        double *yVals = omc_matlab4_read_vals(&reader,var->index);
        if (!yVals) {
          omc_free_matlab4_reader(&reader);
          throw NoVariableException(QString("Corrupt file. nvar %1").arg(reader.nvar).toStdString().c_str());
        }
        for (uint32_t i = 0 ; i < reader.nrows ; i++)
          pPlotCurve->addYAxisValue(yVals[i]);
      }
      // if variable is a parameter then
      else
      {
        double yVal;
        if (omc_matlab4_val(&yVal,&reader,var,0.0)) {
          omc_free_matlab4_reader(&reader);
          throw NoVariableException(QString("Parameter doesn't have a value : ").append(yVariable).toStdString().c_str());
        }
        for (uint32_t i = 0 ; i < reader.nrows ; i++)
          pPlotCurve->addYAxisValue(yVal);
      }
      pPlotCurve->plotData();
      pPlotCurve->attach(mpPlot);
      mpPlot->replot();
      omc_free_matlab4_reader(&reader);
    }
  }
}

int setupInterp(double *vals, double val, int N, double &alpha){
  //given sorted values array of length N and val, returns pointer to i-th element so that
  //vals[i-1] < val <=  vals[i] and sets an interpolation coefficient alpha
  //if val is out of the array range, returns NULL
  double *p;
  if (val < vals[0] || vals[N-1] < val) return -1;
  p = std::lower_bound(vals, vals+N, val);
  if (p == vals) //first element
    alpha = 0;
  else
    alpha = (val - *(p-1))/(*p-*(p-1));
  return p-vals;
}

int readPLTDataset(QTextStream *mpTextStream, QString variable, int N, double* valsOut){
  bool resetDone = false;
  QString currentLine;
  do { //find start of dataset of the varible
    currentLine = mpTextStream->readLine();
    if (currentLine.contains("DataSet:"))
    {
      currentLine.remove("DataSet: ");
      if (currentLine == variable) break;
    }
    if (mpTextStream->atEnd() && !resetDone){
      mpTextStream->seek(0);
      resetDone = true;
      //Reset is done for each last index+1, so that the file is searched once again.
      //May be optimized.
    }
  } while (!mpTextStream->atEnd());
  if (mpTextStream->atEnd())
    return -1;
  for (int i = 0; i < N; i++ ){
    currentLine = mpTextStream->readLine();
    QStringList values = currentLine.split(",");
    if (values.count()!=2) throw PlotException("Faild to load the " + variable + "variable.");
    valsOut[i] = QString(values[1]).toDouble();
  }
  return 0;
}

void readPLTArray(QTextStream *mpTextStream, QString variable, double alpha, int intervalSize, int it, QList<double> &arrLstOut){
  int index = 1;
  auto vals = std::make_unique<double[]>(intervalSize);
  do  //loop over all indexes
  {
    //read the values
    QString variableWithInd = variable;
    if (QRegExp("der\\(\\D(\\w)*\\)").exactMatch(variableWithInd)){
      variableWithInd.chop(1);
      variableWithInd.append("["+QString::number(index)+"])");
    } else {
      variableWithInd.append("["+QString::number(index)+"]");
    }
    if (readPLTDataset(mpTextStream, variableWithInd, intervalSize, vals.get())){
      if (index == 1)
        throw NoVariableException(QObject::tr("Array variable doesnt exist: %1").arg(variable).toStdString().c_str());
      else
        break;
    }
    if (it == 0)
      arrLstOut.push_back(vals[0]);
    else
      arrLstOut.push_back(alpha*vals[it-1] + (1-alpha)*vals[it]);
    index++;
  } while(true);
  return;
}

double getTimeUnitFactor(QString timeUnit)
{
  if (timeUnit == "ms") return 1000.0;
  else if (timeUnit == "s") return 1.0;
  else if (timeUnit == "min") return 1.0/6.0;
  else if (timeUnit == "h") return 1.0/3600.0;
  else if (timeUnit == "d") return 1.0/86400.0;
  else throw PlotException(QObject::tr("Unknown unit in plotArray(Parametric)."));
}

void PlotWindow::updateTimeText()
{
  QString unit = getTimeUnit();
  double timeUnitFactor = getTimeUnitFactor(unit);
  mpPlot->setFooter(QString("t = %1 " + unit).arg(getTime()*timeUnitFactor,0,'g',3));
  mpPlot->replot();
}

void PlotWindow::plotArray(double time, PlotCurve *pPlotCurve)
{
  double *res;
  QString currentLine;
  setTime(time);
  if (mVariablesList.isEmpty() && isPlotArray())
    throw NoVariableException(QString("No variables specified!").toStdString().c_str());
  bool editCase = pPlotCurve ? true : false;
  //PLOT PLT
  //we presume time is the first dataset and array elements datasets are consequent
  if (mFile.fileName().endsWith("plt"))
  {
    /* open the file */
    if (!mFile.open(QIODevice::ReadOnly))
      throw PlotException(tr("Failed to open simulation result file %1").arg(mFile.fileName()));
    mpTextStream = new QTextStream(&mFile);
    // read the interval size from the file
    int intervalSize = -1;
    while (!mpTextStream->atEnd())
    {
      currentLine = mpTextStream->readLine();
      if (currentLine.startsWith("#IntervalSize"))
      {
        intervalSize = static_cast<QString>(currentLine.split("=").last()).toInt();
        break;
      }
    }
    if (intervalSize == -1) {
      mFile.close();
      throw PlotException(tr("Interval size not specified.").toStdString().c_str());
    }
    //    double vals[intervalSize];
    //Read in timevector
    auto timeVals = std::make_unique<double[]>(intervalSize);
    readPLTDataset(mpTextStream, "time", intervalSize, timeVals.get());
    //Find indexes and alpha to interpolate data in particular time
    double alpha;
    int it = setupInterp(timeVals.get(), time, intervalSize, alpha);
    if (it < 0) {
      mFile.close();
      throw PlotException("Time out of bounds.");
    }
    QString currentVariable;  //without index part
    // Read variable values and plot them
    for (QStringList::Iterator itVarList = mVariablesList.begin(); itVarList != mVariablesList.end(); itVarList++){ //loop over all variables to be plotted
      currentVariable = *(itVarList);
      if (editCase)
      {
        // clear previous curve data
        pPlotCurve->clearXAxisVector();
        pPlotCurve->clearYAxisVector();
      } else {
        QFileInfo fileInfo(mFile);
        pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), "array index", getXUnit(), getXDisplayUnit(), currentVariable, getYUnit(), getYDisplayUnit(), mpPlot);
        mpPlot->addPlotCurve(pPlotCurve);
      }
      QList<double> arrLst;
      readPLTArray(mpTextStream, currentVariable, alpha, intervalSize, it, arrLst);
      for (int i = 0; i < arrLst.length(); i++)
      {
        pPlotCurve->addXAxisValue(i+1);
        pPlotCurve->addYAxisValue(arrLst[i]);
      }
      pPlotCurve->plotData();
      pPlotCurve->attach(mpPlot);
      updateTimeText();
    }
    mFile.close();
  }
  //PLOT CSV
  else if (mFile.fileName().endsWith("csv"))
  {
    /* open the file */
    struct csv_data *csvReader;
    csvReader = read_csv(mFile.fileName().toStdString().c_str());
    if (csvReader == NULL)
      throw PlotException(tr("Failed to open simulation result file %1").arg(mFile.fileName()));
    //Read in timevector
    double *timeVals = read_csv_dataset(csvReader, "time");
    if (timeVals == NULL)
    {
      omc_free_csv_reader(csvReader);
      throw NoVariableException(tr("Variable doesnt exist: %1").arg("time").toStdString().c_str());
    }
    double alpha;
    int it = setupInterp(timeVals, time, csvReader->numsteps, alpha);
    if (it < 0) {
      omc_free_csv_reader(csvReader);
      throw PlotException("Time out of bounds.");
    }
    QStringList::Iterator itVarList;
    for (itVarList = mVariablesList.begin(); itVarList != mVariablesList.end(); itVarList++){
      if (!editCase) {
        QFileInfo fileInfo(mFile);
        pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), "array index", getXUnit(), getXDisplayUnit(), *itVarList, getYUnit(), getYDisplayUnit(), mpPlot);
        mpPlot->addPlotCurve(pPlotCurve);
      }
      QList<double> res;
      double *arrElement;
      int i = 1;
      do {
        QString varNameQS = (*itVarList);
        if (QRegExp("der\\(\\D(\\w)*\\)").exactMatch(varNameQS)){
          varNameQS.chop(1);
          varNameQS.append("["+QString::number(i)+"])");
        } else {
          varNameQS.append("["+QString::number(i)+"]");
        }
        if (!(arrElement = read_csv_dataset(csvReader, varNameQS.toStdString().c_str()))) break;
        i++;

        if (it == 0)
          res.push_back(arrElement[0]);
        else
          res.push_back(alpha*arrElement[it-1] + (1-alpha)*arrElement[it]);
      } while (true);
      pPlotCurve->clearXAxisVector();
      pPlotCurve->clearYAxisVector();
      for (int j = 0; j < res.count(); j++){
        pPlotCurve->addXAxisValue(j+1);
        pPlotCurve->addYAxisValue(res[j]);
      }
      pPlotCurve->plotData();
      pPlotCurve->attach(mpPlot);
      updateTimeText();
    }
    omc_free_csv_reader(csvReader);
  }
  //PLOT MAT
  else
    if(mFile.fileName().endsWith("mat"))
    {
      ModelicaMatReader reader;
      ModelicaMatVariable_t *var;
      QList<ModelicaMatVariable_t*> vars;
      const char *msg = "";
      QStringList variablesPlotted;

      //Read in mat file
      if(0 != (msg = omc_new_matlab4_reader(mFile.fileName().toStdString().c_str(), &reader)))
        throw PlotException(msg);
      //calculate time
      double startTime = omc_matlab4_startTime(&reader);
      double stopTime =  omc_matlab4_stopTime(&reader);
      if (reader.nvar < 1) {
        omc_free_matlab4_reader(&reader);
        throw NoVariableException("Variable doesnt exist: time");
      }
      if (time<startTime || stopTime<time) {
        omc_free_matlab4_reader(&reader);
        throw PlotException("Time out of bounds.");
      }
      QStringList::Iterator itVarList;
      for (itVarList = mVariablesList.begin(); itVarList != mVariablesList.end(); itVarList++){
        if (!editCase) {
          QFileInfo fileInfo(mFile);
          pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), "array index", getXUnit(), getXDisplayUnit(), *itVarList, getYUnit(), getYDisplayUnit(), mpPlot);
          mpPlot->addPlotCurve(pPlotCurve);
        }
        int i = 1;
        do {
          QString varNameQS = (*itVarList);
          if (QRegExp("der\\(\\D(\\w)*\\)").exactMatch(varNameQS)){
            varNameQS.chop(1);
            varNameQS.append("["+QString::number(i)+"])");
          } else {
            varNameQS.append("["+QString::number(i)+"]");
          }
          if(!(var = omc_matlab4_find_var(&reader, varNameQS.toStdString().c_str()))) break;
          i++;
          vars.push_back(var);
        } while (true);
        QVector<ModelicaMatVariable_t*> varVec = vars.toVector();
        res = new double [vars.count()];
        omc_matlab4_read_vars_val(res, &reader, varVec.data(), vars.count(), time);
        pPlotCurve->clearXAxisVector();
        pPlotCurve->clearYAxisVector();
        for (int i = 0; i < vars.count(); i++){
          pPlotCurve->addXAxisValue(i+1);
          pPlotCurve->addYAxisValue(res[i]);
        }
        pPlotCurve->plotData();
        pPlotCurve->attach(mpPlot);
        updateTimeText();
        delete[] res;
      }
      // if plottype is PLOT then check which requested variables are not found in the file
      if (isPlot())
        checkForErrors(mVariablesList, variablesPlotted);
      // close the file
      omc_free_matlab4_reader(&reader);
    }
}

void PlotWindow::plotArrayParametric(double time, PlotCurve *pPlotCurve)
{
  QString xVariable, yVariable, xTitle, yTitle;
  int pair = 0;
  setTime(time);
  if (mVariablesList.isEmpty())
    throw NoVariableException(QString("No variables specified!").toStdString().c_str());
  else if (mVariablesList.size()%2 != 0)
    throw NoVariableException(QString("Please specify variable pairs for plotParametric.").toStdString().c_str());

  bool editCase = pPlotCurve ? true : false;

  for (pair = 0; pair < mVariablesList.size(); pair += 2)
  {
    xVariable = mVariablesList.at(pair);
    yVariable = mVariablesList.at(pair+1);

    if (pair==0) {
      xTitle = xVariable;
      yTitle = yVariable;
    } else {
      xTitle += ", "+xVariable;
      yTitle += ", "+yVariable;
    }
    setXLabel(xTitle);
    setYLabel(yTitle);

    //PLOT PLT
    //we presume time is the first dataset and array elements datasets are consequent
    if (mFile.fileName().endsWith("plt"))
    {
      /* open the file */
      if (!mFile.open(QIODevice::ReadOnly))
        throw PlotException(tr("Failed to open simulation result file %1").arg(mFile.fileName()));
      mpTextStream = new QTextStream(&mFile);
      // read the interval size from the file
      QString currentLine;
      int intervalSize = -1;
      while (!mpTextStream->atEnd())
      {
        currentLine = mpTextStream->readLine();
        if (currentLine.startsWith("#IntervalSize"))
        {
          intervalSize = static_cast<QString>(currentLine.split("=").last()).toInt();
          break;
        }
      }
      if (intervalSize == -1) {
        mFile.close();
        throw PlotException(tr("Interval size not specified.").toStdString().c_str());
      }
      //Read in timevector
      auto timeVals = std::make_unique<double[]>(intervalSize);
      readPLTDataset(mpTextStream, "time", intervalSize, timeVals.get());
      //Find indexes and alpha to interpolate data in particular time
      double alpha;
      int it = setupInterp(timeVals.get(), time, intervalSize, alpha);
      if (it < 0) {
        mFile.close();
        throw PlotException("Time out of bounds.");
      }
      if (editCase) {
        pPlotCurve->clearXAxisVector();
        pPlotCurve->clearYAxisVector();
      } else {
        QFileInfo fileInfo(mFile);
        pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), xVariable, getXUnit(), getXDisplayUnit(), yVariable, getYUnit(), getYDisplayUnit(), mpPlot);
        mpPlot->addPlotCurve(pPlotCurve);
      }
      //Read the values
      QList<double> xValsLst;
      readPLTArray(mpTextStream, xVariable, alpha, intervalSize, it, xValsLst);
      QList<double> yValsLst;
      readPLTArray(mpTextStream, yVariable, alpha, intervalSize, it, yValsLst);
      if (xValsLst.length() != yValsLst.length()) {
        mFile.close();
        throw PlotException(tr("Arrays must be of the same length in array parametric plot."));
      }
      for (int i = 0; i < xValsLst.length(); i++){
        pPlotCurve->addXAxisValue(xValsLst[i]);
        pPlotCurve->addYAxisValue(yValsLst[i]);
      }
      pPlotCurve->plotData();
      pPlotCurve->attach(mpPlot);
      updateTimeText();
      mFile.close();
    }
    //    //PLOT CSV
    else if (mFile.fileName().endsWith("csv"))
    {
      /* open the file */
      struct csv_data *csvReader;
      csvReader = read_csv(mFile.fileName().toStdString().c_str());
      if (csvReader == NULL)
        throw PlotException(tr("Failed to open simulation result file %1").arg(mFile.fileName()));
      //Read in timevector
      double *timeVals = read_csv_dataset(csvReader, "time");
      if (timeVals == NULL)
      {
        omc_free_csv_reader(csvReader);
        throw NoVariableException(tr("Variable doesnt exist: %1").arg("time").toStdString().c_str());
      }
      double alpha;
      int it = setupInterp(timeVals, time, csvReader->numsteps, alpha);
      if (it < 0) {
        omc_free_csv_reader(csvReader);
        throw PlotException("Time out of bounds.");
      }
      if (!editCase) {
        QFileInfo fileInfo(mFile);
        pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), xVariable, getXUnit(), getXDisplayUnit(), yVariable, getYUnit(), getYDisplayUnit(), mpPlot);
        mpPlot->addPlotCurve(pPlotCurve);
      }
      pPlotCurve->clearXAxisVector();
      pPlotCurve->clearYAxisVector();
      QStringList varPair;
      varPair << xVariable << yVariable;
      QList<double> res;
      for (int j = 0; j<2; j++){
        res.clear();
        double *arrElement;
        for (int i = 1; ;i++){
          QString varNameQS = varPair[j];
          if (QRegExp("der\\(\\D(\\w)*\\)").exactMatch(varNameQS)){
            varNameQS.chop(1);
            varNameQS.append("["+QString::number(i)+"])");
          } else {
            varNameQS.append("["+QString::number(i)+"]");
          }
          if (!(arrElement = read_csv_dataset(csvReader, varNameQS.toStdString().c_str()))) break;

          if (it == 0)
            res.push_back(arrElement[0]);
          else
            res.push_back(alpha*arrElement[it-1] + (1-alpha)*arrElement[it]);
        }
        if (j == 0) { //xVar
          for (int i = 0; i < res.count(); i++)
            pPlotCurve->addXAxisValue(res[i]);
        }
        else { //yVar
          if (pPlotCurve->getXAxisSize()!=res.count()) {
            omc_free_csv_reader(csvReader);
            throw PlotException(tr("Arrays must be of the same length in array parametric plot."));
          }
          for (int i = 0; i < res.count(); i++)
            pPlotCurve->addYAxisValue(res[i]);
        }
      }
      pPlotCurve->plotData();
      pPlotCurve->attach(mpPlot);
      updateTimeText();
      omc_free_csv_reader(csvReader);
    }
    //PLOT MAT
    else if(mFile.fileName().endsWith("mat"))
    {
      //Declare variables
      ModelicaMatReader reader;
      ModelicaMatVariable_t *var;
      double *res;
      const char *msg = "";

      //Read the .mat file
      if(0 != (msg = omc_new_matlab4_reader(mFile.fileName().toStdString().c_str(), &reader)))
        throw PlotException(msg);

      if (!editCase) {
        QFileInfo fileInfo(mFile);
        pPlotCurve = new PlotCurve(fileInfo.fileName(), fileInfo.absoluteFilePath(), xVariable, getXUnit(), getXDisplayUnit(), yVariable, getYUnit(), getYDisplayUnit(), mpPlot);
        mpPlot->addPlotCurve(pPlotCurve);
      }
      //calculate time
      double startTime = omc_matlab4_startTime(&reader);
      double stopTime =  omc_matlab4_stopTime(&reader);
      if (reader.nvar < 1) {
        omc_free_matlab4_reader(&reader);
        throw NoVariableException("Variable doesnt exist: time");
      }
      if (time<startTime || stopTime<time) {
        omc_free_matlab4_reader(&reader);
        throw PlotException("Time out of bounds.");
      }
      pPlotCurve->clearXAxisVector();
      pPlotCurve->clearYAxisVector();
      QList<ModelicaMatVariable_t*> vars;
      QStringList varPair;
      varPair.push_back(xVariable);
      varPair.push_back(yVariable);
      //read x and y vals:
      for (int j = 0; j < 2; j++){
        vars.clear();
        int i = 1;
        do {
          QString varNameQS = varPair[j];
          if (QRegExp("der\\(\\D(\\w)*\\)").exactMatch(varNameQS)){
            varNameQS.chop(1);
            varNameQS.append("["+QString::number(i)+"])");
          } else {
            varNameQS.append("["+QString::number(i)+"]");
          }
          if(!(var = omc_matlab4_find_var(&reader, varNameQS.toStdString().c_str()))) break;
          i++;
          vars.push_back(var);
        } while (true);
        QVector<ModelicaMatVariable_t*> varVec = vars.toVector();
        res = new double [vars.count()];
        omc_matlab4_read_vars_val(res, &reader, varVec.data(), vars.count(), time);
        if (j == 0)
          for (int i = 0; i < vars.count(); i++)
            pPlotCurve->addXAxisValue(res[i]);
        else{
          if (pPlotCurve->getXAxisSize()!=vars.count()) {
            omc_free_matlab4_reader(&reader);
            throw PlotException("Arrays must be of the same length in array parametric plot.");
          }
          for (int i = 0; i < vars.count(); i++)
            pPlotCurve->addYAxisValue(res[i]);
        }
        delete[] res;
      }
      pPlotCurve->plotData();
      pPlotCurve->attach(mpPlot);
      updateTimeText();
      omc_free_matlab4_reader(&reader);
    }
  }
}

QPair<QVector<double>*, QVector<double>*> PlotWindow::plotInteractive(PlotCurve *pPlotCurve)
{
  if (mVariablesList.isEmpty() && isPlotInteractive()) {
    throw NoVariableException(QString(tr("No variables specified!")).toStdString().c_str());
  } else if (mVariablesList.size() != 1) {
    throw NoVariableException(QString(tr("Could not determine the variable name!")).toStdString().c_str());
  }
  QString variableName = mVariablesList.at(0);
  pPlotCurve = new PlotCurve(mInteractiveModelName, "", "time", getXUnit(), getXDisplayUnit(), variableName, getYUnit(), getYDisplayUnit(), mpPlot);
  // clear previous curve data
  pPlotCurve->clearXAxisVector();
  pPlotCurve->clearYAxisVector();
  pPlotCurve->setSamples(mpInteractiveData);
  mpPlot->addPlotCurve(pPlotCurve);
  pPlotCurve->attach(mpPlot);
  mpPlot->replot();
  return pPlotCurve->getAxisVectors();
}

void PlotWindow::setInteractiveOwner(const QString &interactiveTreeItemOwner)
{
  mInteractiveTreeItemOwner = interactiveTreeItemOwner;
}

void PlotWindow::setInteractivePort(const int port)
{
  mInteractivePort = port;
}

void PlotWindow::setInteractivePlotData(QwtSeriesData<QPointF>* pInteractiveData)
{
  mpInteractiveData = pInteractiveData;
}

void PlotWindow::setInteractiveModelName(const QString &modelName)
{
  mInteractiveModelName = modelName;
}

void PlotWindow::setTitle(QString title)
{
  mpPlot->setTitle(title);
}

/*!
 * \brief PlotWindow::updatePlot
 * Updates the plot.
 * If auto scale is enabled then calls PlotWindow::fitInView()
 */
void PlotWindow::updatePlot()
{
  if (mpAutoScaleButton->isChecked()) {
    fitInView();
  } else {
    mpPlot->updateLayout();
    mpPlot->replot();
    if (mpPlot->getPlotZoomer()->zoomStack().size() == 1) {
      mpPlot->getPlotZoomer()->setZoomBase(false);
    }
  }
}

void PlotWindow::emitPrefixUnitsChanged()
{
  emit prefixUnitsChanged();
}

void PlotWindow::setInteractiveControls(bool enabled)
{
  // control buttons
  mpStartSimulationToolButton->setEnabled(enabled);
  mpPauseSimulationToolButton->setEnabled(!enabled);
  //plotpicker
  mpPlot->getPlotPicker()->setEnabled(enabled);
}

void PlotWindow::setGrid(QString grid)
{
  if (grid.toLower().compare("detailed") == 0) {
    mpGridComboBox->setCurrentIndex(1);
  } else if (grid.toLower().compare("none") == 0) {
    mpGridComboBox->setCurrentIndex(2);
  } else {
    mpGridComboBox->setCurrentIndex(0);
  }
}

QString PlotWindow::getGrid()
{
  return mGridType;
}

QCheckBox* PlotWindow::getLogXCheckBox()
{
  return mpLogXCheckBox;
}

QCheckBox* PlotWindow::getLogYCheckBox()
{
  return mpLogYCheckBox;
}

void PlotWindow::setXRange(double min, double max)
{
  if (!(max == 0 && min == 0)) {
    mpPlot->setAxisScale(QwtPlot::xBottom, min, max);
  }
  mXRangeMin = QString::number(min);
  mXRangeMax = QString::number(max);
}

QString PlotWindow::getXRangeMin()
{
  return mXRangeMin;
}

QString PlotWindow::getXRangeMax()
{
  return mXRangeMax;
}

void PlotWindow::setYRange(double min, double max)
{
  if (!(max == 0 && min == 0)) {
    mpPlot->setAxisScale(QwtPlot::yLeft, min, max);
  }
  mYRangeMin = QString::number(min);
  mYRangeMax = QString::number(max);
}

QString PlotWindow::getYRangeMin()
{
  return mYRangeMin;
}

QString PlotWindow::getYRangeMax()
{
  return mYRangeMax;
}

void PlotWindow::setCurveWidth(double width)
{
  mCurveWidth = width;
}

double PlotWindow::getCurveWidth()
{
  return mCurveWidth;
}

void PlotWindow::setCurveStyle(int style)
{
  mCurveStyle = style;
}

int PlotWindow::getCurveStyle()
{
  return mCurveStyle;
}

void PlotWindow::setLegendFont(QFont font)
{
  mLegendFont = font;
}

QFont PlotWindow::getLegendFont()
{
  return mLegendFont;
}

void PlotWindow::setLegendPosition(QString position)
{
  if (position.toLower().compare("left") == 0)
  {
    mpPlot->insertLegend(0);
    mpPlot->setLegend(new Legend(mpPlot));
    mpPlot->insertLegend(mpPlot->getLegend(), QwtPlot::LeftLegend);
  }
  else if (position.toLower().compare("right") == 0)
  {
    mpPlot->insertLegend(0);
    mpPlot->setLegend(new Legend(mpPlot));
    mpPlot->insertLegend(mpPlot->getLegend(), QwtPlot::RightLegend);
  }
  else if (position.toLower().compare("top") == 0)
  {
    mpPlot->insertLegend(0);
    mpPlot->setLegend(new Legend(mpPlot));
    mpPlot->insertLegend(mpPlot->getLegend(), QwtPlot::TopLegend);
#if QWT_VERSION > 0x060000
    /* we also want to align the legend to left. Qwt align it HCenter by default. */
    QwtLegend *pQwtLegend = qobject_cast<QwtLegend*>(mpPlot->legend());
    pQwtLegend->contentsWidget()->layout()->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    mpPlot->updateLegend();
#endif
  }
  else if (position.toLower().compare("bottom") == 0)
  {
    mpPlot->insertLegend(0);
    mpPlot->setLegend(new Legend(mpPlot));
    mpPlot->insertLegend(mpPlot->getLegend(), QwtPlot::BottomLegend);
#if QWT_VERSION > 0x060000
    /* we also want to align the legend to left. Qwt align it HCenter by default. */
    QwtLegend *pQwtLegend = qobject_cast<QwtLegend*>(mpPlot->legend());
    pQwtLegend->contentsWidget()->layout()->setAlignment(Qt::AlignBottom | Qt::AlignLeft);
    mpPlot->updateLegend();
#endif
  }
  else if (position.toLower().compare("none") == 0)
  {
    mpPlot->insertLegend(0);
  }
}

QString PlotWindow::getLegendPosition()
{
  if (!mpPlot->legend())
    return "none";
  switch (mpPlot->plotLayout()->legendPosition())
  {
    case QwtPlot::LeftLegend:
      return "left";
    case QwtPlot::RightLegend:
      return "right";
    case QwtPlot::TopLegend:
      return "top";
    case QwtPlot::BottomLegend:
      return "bottom";
    default:
      return "top";
  }
}

void PlotWindow::setFooter(QString footer)
{
#if QWT_VERSION > 0x060000
  mpPlot->setFooter(footer);
#endif
}

QString PlotWindow::getFooter()
{
#if QWT_VERSION > 0x060000
  return mpPlot->footer().text();
#else
  return "";
#endif
}

bool PlotWindow::getPrefixUnits() const
{
  return mPrefixUnits;
}

void PlotWindow::setPrefixUnits(bool prefixUnits)
{
  mPrefixUnits = prefixUnits;
}

void PlotWindow::checkForErrors(QStringList variables, QStringList variablesPlotted)
{
  QStringList nonExistingVariables;
  foreach (QString variable, variables)
  {
    if (!variablesPlotted.contains(variable))
      nonExistingVariables.append(variable);
  }
  if (!nonExistingVariables.isEmpty())
  {
    throw NoVariableException(QString("Following variable(s) are not found : ")
                              .append(nonExistingVariables.join(",")).toStdString().c_str());
  }
}

Plot* PlotWindow::getPlot()
{
  return mpPlot;
}

void PlotWindow::receiveMessage(QStringList arguments)
{
  foreach (PlotCurve *pCurve, mpPlot->getPlotCurvesList())
  {
    pCurve->detach();
    mpPlot->removeCurve(pCurve);
  }
  initializePlot(arguments);
}

void PlotWindow::closeEvent(QCloseEvent *event)
{
  emit closingDown();
  event->accept();
}

void PlotWindow::fitInView()
{
  mpPlot->getPlotZoomer()->zoom(0);
  mpPlot->setAxisAutoScale(QwtPlot::yLeft);
  mpPlot->setAxisAutoScale(QwtPlot::xBottom);
  mpPlot->replot();
  mpPlot->getPlotZoomer()->setZoomBase(false);
}

void PlotWindow::updateCurves()
{
  for (auto & p : mpPlot->getPlotCurvesList()) {
    // append the last point to the plotting curve
    p->getPlotDirectPainter()->drawSeries(p, p->getXAxisSize() - 2, -1);
  }
}

void PlotWindow::updateYAxis(QPair<double, double> minMaxValues)
{
  // replot if a value is out of bounds
  if (minMaxValues.first < mpPlot->axisScaleDiv(QwtPlot::yLeft).lowerBound() || minMaxValues.second > mpPlot->axisScaleDiv(QwtPlot::yLeft).upperBound()) {
    mpPlot->replot();
  }
}

void PlotWindow::enableZoomMode(bool on)
{
  mpPlot->getPlotZoomer()->setEnabled(on);
  if(on)
  {
    mpPlot->canvas()->setCursor(Qt::CrossCursor);
  }
}

void PlotWindow::enablePanMode(bool on)
{
  mpPlot->getPlotPanner()->setEnabled(on);
  if(on)
  {
    mpPlot->canvas()->setCursor(Qt::OpenHandCursor);
  }
}

void PlotWindow::exportDocument()
{
  static QString lastOpenDir;
  QString dir = lastOpenDir.isEmpty() ? QDir::homePath() : lastOpenDir;
  QString fileName = QFileDialog::getSaveFileName(this, tr("Save File As"), dir, tr("Image Files (*.png *.svg *.bmp)"));

  if (!fileName.isEmpty()) {
    lastOpenDir = QFileInfo(fileName).absoluteDir().absolutePath();
    // export svg
    if (fileName.endsWith(".svg")) {
#if QWT_VERSION < 0x060000
      QSvgGenerator generator;
      generator.setTitle(tr("OMPlot - OpenModelica Plot"));
      generator.setDescription(tr("Generated by OpenModelica Plot Tool"));
      generator.setFileName(fileName);
      generator.setSize(mpPlot->rect().size());
      mpPlot->print(generator);
#else
      QwtPlotRenderer plotRenderer;
      plotRenderer.setDiscardFlag(QwtPlotRenderer::DiscardBackground);  /* removes the gray widget background when OMPlot is used as library. */
      plotRenderer.renderDocument(mpPlot, fileName, QSizeF(mpPlot->widthMM(), mpPlot->heightMM()));
#endif
    }
    // export png, bmp
    else
    {
#if QWT_VERSION < 0x060000
      QPixmap pixmap(mpPlot->size());
      /* removes the gray widget background when OMPlot is used as library. */
      pixmap.fill(Qt::white);
      mpPlot->render(&pixmap, QPoint(), QRegion(), DrawChildren);
#else
      QwtPlotRenderer plotRenderer;
      plotRenderer.setDiscardFlag(QwtPlotRenderer::DiscardBackground);  /* removes the gray widget background when OMPlot is used as library. */
      QPixmap pixmap(mpPlot->size());
      pixmap.fill(Qt::white);
      QPainter painter(&pixmap);
      QRect rect = mpPlot->geometry();
      painter.setWindow(rect);
      plotRenderer.render(mpPlot, &painter, rect);
#endif
      if (!pixmap.save(fileName)) {
        QMessageBox::critical(this, "Error", "Failed to save image " + fileName);
      }
    }
  }
}

void PlotWindow::printPlot()
{
#if 1
  QPrinter printer;
#else
  QPrinter printer(QPrinter::HighResolution);
  printer.setOutputFileName("OMPlot.ps");
#endif

  printer.setDocName("OMPlot");
  printer.setCreator("Plot Window");
  printer.setPageOrientation(QPageLayout::Landscape);

  QPrintDialog dialog(&printer);
  if ( dialog.exec() )
  {
#if QWT_VERSION < 0x060000
    QwtPlotPrintFilter filter;
    if ( printer.colorMode() == QPrinter::GrayScale )
    {
      int options = QwtPlotPrintFilter::PrintAll;
      options &= ~QwtPlotPrintFilter::PrintBackground;
      options |= QwtPlotPrintFilter::PrintFrameWithScales;
      filter.setOptions(options);
    }
    mpPlot->print(printer, filter);
#else
    QwtPlotRenderer plotRenderer;
    plotRenderer.renderTo(mpPlot, printer);
#endif
  }
}

/*!
 * \brief PlotWindow::setGrid
 * Slot activated when grid combobox index is changed.
 * Sets the grid type.
 * \param index
 */
void PlotWindow::setGrid(int index)
{
  switch (index) {
    case 1:
      mGridType = "detailed";
      mpPlot->getPlotGrid()->setDetailedGrid();
      mpPlot->getPlotGrid()->attach(mpPlot);
      break;
    case 2:
      mGridType = "none";
      mpPlot->getPlotGrid()->detach();
      break;
    case 0:
    default:
      mGridType = "simple";
      mpPlot->getPlotGrid()->setGrid();
      mpPlot->getPlotGrid()->attach(mpPlot);
      break;
  }
  mpPlot->replot();
}

void PlotWindow::setLogX(bool on)
{
  if (on) {
#if QWT_VERSION >= 0x060100
    mpPlot->setAxisScaleEngine(QwtPlot::xBottom, new LogScaleEngine);
#else
    mpPlot->setAxisScaleEngine(QwtPlot::xBottom, new QwtLog10ScaleEngine);
#endif
  } else {
    mpPlot->setAxisScaleEngine(QwtPlot::xBottom, new LinearScaleEngine);
  }
  mpPlot->setAxisAutoScale(QwtPlot::xBottom);
  bool state = mpLogXCheckBox->blockSignals(true);
  mpLogXCheckBox->setChecked(on);
  mpLogXCheckBox->blockSignals(state);
  updatePlot();
}

void PlotWindow::setLogY(bool on)
{
  if (on) {
#if QWT_VERSION >= 0x060100
    mpPlot->setAxisScaleEngine(QwtPlot::yLeft, new LogScaleEngine);
#else
    mpPlot->setAxisScaleEngine(QwtPlot::yLeft, new QwtLog10ScaleEngine);
#endif
  } else {
    mpPlot->setAxisScaleEngine(QwtPlot::yLeft, new LinearScaleEngine);
  }
  mpPlot->setAxisAutoScale(QwtPlot::yLeft);
  bool state = mpLogYCheckBox->blockSignals(true);
  mpLogYCheckBox->setChecked(on);
  mpLogYCheckBox->blockSignals(state);
  updatePlot();
}

void PlotWindow::setAutoScale(bool on)
{
  bool state = mpAutoScaleButton->blockSignals(true);
  mpAutoScaleButton->setChecked(on);
  mpAutoScaleButton->blockSignals(state);
}

bool PlotWindow::toggleSign(PlotCurve *pPlotCurve, bool checked)
{
  bool toggleSign = false;
  bool previousToggle = pPlotCurve->getToggleSign();
  pPlotCurve->setToggleSign(checked);
  if ((!previousToggle && pPlotCurve->getToggleSign()) || (previousToggle && !pPlotCurve->getToggleSign())) {
    for (int i = 0 ; i < pPlotCurve->mYAxisVector.size() ; i++) {
      pPlotCurve->updateYAxisValue(i, -pPlotCurve->mYAxisVector.at(i));
    }
    pPlotCurve->plotData(true);
    toggleSign = true;
  }
  return toggleSign;
}

void PlotWindow::showSetupDialog()
{
  SetupDialog *pSetupDialog = new SetupDialog(this);
  pSetupDialog->exec();
}

void PlotWindow::showSetupDialog(QString variable)
{
  SetupDialog *pSetupDialog = new SetupDialog(this);
  pSetupDialog->selectVariable(variable);
  pSetupDialog->exec();
}

void PlotWindow::interactiveSimulationStarted()
{
  setInteractiveControls(false);
}

void PlotWindow::interactiveSimulationPaused()
{
  setInteractiveControls(true);
}

/*!
  \class VariablePageWidget
  \brief Represent the attribute of a plot variable.
  */
VariablePageWidget::VariablePageWidget(PlotCurve *pPlotCurve, SetupDialog *pSetupDialog)
  : QWidget(pSetupDialog)
{
  mpPlotCurve = pPlotCurve;
  // general group box
  mpGeneralGroupBox = new QGroupBox(tr("General"));
  mpLegendLabel = new QLabel(tr("Legend"));
  mpLegendTextBox = new QLineEdit(mpPlotCurve->getCustomTitle().isEmpty() ? mpPlotCurve->title().text() : mpPlotCurve->getCustomTitle());
  mpResetLabelButton = new QPushButton(tr("Reset"));
  mpResetLabelButton->setAutoDefault(false);
  connect(mpResetLabelButton, SIGNAL(clicked()), SLOT(resetLabel()));
  mpFileLabel = new QLabel(tr("File"));
  mpFileTextBox = new QLabel(mpPlotCurve->getFileName());
  // appearance layout
  QGridLayout *pGeneralGroupBoxGridLayout = new QGridLayout;
  pGeneralGroupBoxGridLayout->addWidget(mpLegendLabel, 0, 0);
  pGeneralGroupBoxGridLayout->addWidget(mpLegendTextBox, 0, 1);
  pGeneralGroupBoxGridLayout->addWidget(mpResetLabelButton, 0, 2);
  pGeneralGroupBoxGridLayout->addWidget(mpFileLabel, 1, 0);
  pGeneralGroupBoxGridLayout->addWidget(mpFileTextBox, 1, 1, 1, 2);
  mpGeneralGroupBox->setLayout(pGeneralGroupBoxGridLayout);
  // Appearance group box
  mpAppearanceGroupBox = new QGroupBox(tr("Appearance"));
  mpColorLabel = new QLabel(tr("Color"));
  mpPickColorButton = new QPushButton(tr("Pick Color"));
  mpPickColorButton->setAutoDefault(false);
  //mpPickColorButton->setAutoDefault(false);
  connect(mpPickColorButton, SIGNAL(clicked()), SLOT(pickColor()));
  mCurveColor = mpPlotCurve->pen().color();
  setCurvePickColorButtonIcon();
  mpAutomaticColorCheckBox = new QCheckBox(tr("Automatic Color"));
  mpAutomaticColorCheckBox->setChecked(!mpPlotCurve->hasCustomColor());
  // pattern
  mpPatternLabel = new QLabel(tr("Pattern"));
  mpPatternComboBox = new QComboBox;
  mpPatternComboBox->addItem("SolidLine", 1);
  mpPatternComboBox->addItem("DashLine", 2);
  mpPatternComboBox->addItem("DotLine", 3);
  mpPatternComboBox->addItem("DashDotLine", 4);
  mpPatternComboBox->addItem("DashDotDotLine", 5);
  mpPatternComboBox->addItem("Sticks", 6);
  mpPatternComboBox->addItem("Steps", 7);
  int index = mpPatternComboBox->findData(mpPlotCurve->getCurveStyle());
  if (index != -1) mpPatternComboBox->setCurrentIndex(index);
  // thickness
  mpThicknessLabel = new QLabel(tr("Thickness"));
  mpThicknessSpinBox = new QDoubleSpinBox;
  mpThicknessSpinBox->setValue(1);
  mpThicknessSpinBox->setSingleStep(1);
  mpThicknessSpinBox->setValue(mpPlotCurve->getCurveWidth());
  // hide
  mpHideCheckBox = new QCheckBox(tr("Hide"));
  mpHideCheckBox->setChecked(!mpPlotCurve->isVisible());
  // toggle sign
  mpToggleSignCheckBox = new QCheckBox(tr("Toggle Sign"));
  mpToggleSignCheckBox->setChecked(mpPlotCurve->getToggleSign());
  // appearance layout
  QGridLayout *pAppearanceGroupBoxGridLayout = new QGridLayout;
  pAppearanceGroupBoxGridLayout->addWidget(mpColorLabel, 0, 0);
  pAppearanceGroupBoxGridLayout->addWidget(mpPickColorButton, 0, 1);
  pAppearanceGroupBoxGridLayout->addWidget(mpAutomaticColorCheckBox, 0, 2);
  pAppearanceGroupBoxGridLayout->addWidget(mpPatternLabel, 1, 0);
  pAppearanceGroupBoxGridLayout->addWidget(mpPatternComboBox, 1, 1, 1, 2);
  pAppearanceGroupBoxGridLayout->addWidget(mpThicknessLabel, 2, 0);
  pAppearanceGroupBoxGridLayout->addWidget(mpThicknessSpinBox, 2, 1, 1, 2);
  pAppearanceGroupBoxGridLayout->addWidget(mpHideCheckBox, 3, 0, 1, 3);
  pAppearanceGroupBoxGridLayout->addWidget(mpToggleSignCheckBox, 4, 0, 1, 3);
  mpAppearanceGroupBox->setLayout(pAppearanceGroupBoxGridLayout);
  // set layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpGeneralGroupBox, 0, 0);
  pMainLayout->addWidget(mpAppearanceGroupBox, 1, 0);
  setLayout(pMainLayout);
}

void VariablePageWidget::setCurvePickColorButtonIcon()
{
  QPixmap pixmap(QSize(10, 10));
  pixmap.fill(getCurveColor());
  mpPickColorButton->setIcon(pixmap);
}

void VariablePageWidget::resetLabel()
{
  mpPlotCurve->setCustomTitle("");
  mpPlotCurve->setTitleLocal();
  mpLegendTextBox->setText(mpPlotCurve->title().text());
}

void VariablePageWidget::pickColor()
{
  QColor color = QColorDialog::getColor(getCurveColor());
  if (!color.isValid())
    return;

  setCurveColor(color);
  setCurvePickColorButtonIcon();
  mpAutomaticColorCheckBox->setChecked(false);
}

/*!
  \class SetupDialog
  \brief Contains a list of plot variables. Allows user to select the variable and then edit its attributes.
  */
/*!
  \param pPlotWindow - pointer to PlotWindow
  */
SetupDialog::SetupDialog(PlotWindow *pPlotWindow)
  : QDialog(pPlotWindow)
{
  setWindowTitle(tr("Plot Setup"));
  setAttribute(Qt::WA_DeleteOnClose);

  mpPlotWindow = pPlotWindow;
  mpSetupTabWidget = new QTabWidget;
  // Variables Tab
  mpVariablesTab = new QWidget;
  mpVariableLabel = new QLabel(tr("Select a variable, then edit its properties below:"));
  // variables list
  mpVariablesListWidget = new QListWidget;
  mpVariablePagesStackedWidget = new QStackedWidget;
  QList<PlotCurve*> plotCurves = mpPlotWindow->getPlot()->getPlotCurvesList();
  foreach (PlotCurve *pPlotCurve, plotCurves) {
    mpVariablePagesStackedWidget->addWidget(new VariablePageWidget(pPlotCurve, this));
    QListWidgetItem *pListItem = new QListWidgetItem(mpVariablesListWidget);
    pListItem->setText(pPlotCurve->getYVariable());
    pListItem->setData(Qt::UserRole, pPlotCurve->getNameStructure());
  }
  connect(mpVariablesListWidget, SIGNAL(currentItemChanged(QListWidgetItem*,QListWidgetItem*)), SLOT(variableSelected(QListWidgetItem*,QListWidgetItem*)));
  // Variables Tab Layout
  QGridLayout *pVariablesTabGridLayout = new QGridLayout;
  pVariablesTabGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pVariablesTabGridLayout->addWidget(mpVariableLabel, 0, 0);
  pVariablesTabGridLayout->addWidget(mpVariablesListWidget, 1, 0);
  pVariablesTabGridLayout->addWidget(mpVariablePagesStackedWidget, 2, 0);
  mpVariablesTab->setLayout(pVariablesTabGridLayout);
  // title tab
  mpTitlesTab = new QWidget;
  mpPlotTitleLabel = new QLabel(tr("Plot Title"));
  mpPlotTitleTextBox = new QLineEdit(mpPlotWindow->getPlot()->title().text());
  mpTitleFontSizeLabel = new QLabel("Title Font Size");
  mpTitleFontSizeSpinBox = new QDoubleSpinBox;
  mpTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpTitleFontSizeSpinBox->setValue(mpPlotWindow->getPlot()->titleLabel()->font().pointSizeF());
  mpTitleFontSizeSpinBox->setSingleStep(1);
  mpVerticalAxisLabel = new QLabel(tr("Vertical Axis Title"));
  mpVerticalAxisTextBox = new QLineEdit(mpPlotWindow->getYCustomLabel());
  mpVerticalAxisTitleFontSizeLabel = new QLabel("Vertical Axis Title Font Size");
  mpVerticalAxisTitleFontSizeSpinBox = new QDoubleSpinBox;
  mpVerticalAxisTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpVerticalAxisTitleFontSizeSpinBox->setValue(mpPlotWindow->getPlot()->axisWidget(QwtPlot::yLeft)->title().font().pointSizeF());
  mpVerticalAxisTitleFontSizeSpinBox->setSingleStep(1);
  mpVerticalAxisNumbersFontSizeLabel = new QLabel("Vertical Axis Numbers Font Size");
  mpVerticalAxisNumbersFontSizeSpinBox = new QDoubleSpinBox;
  mpVerticalAxisNumbersFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpVerticalAxisNumbersFontSizeSpinBox->setValue(mpPlotWindow->getPlot()->axisWidget(QwtPlot::yLeft)->font().pointSizeF());
  mpVerticalAxisNumbersFontSizeSpinBox->setSingleStep(1);
  mpHorizontalAxisLabel = new QLabel(tr("Horizontal Axis Title"));
  mpHorizontalAxisTextBox = new QLineEdit(mpPlotWindow->getXCustomLabel());
  mpHorizontalAxisTitleFontSizeLabel = new QLabel("Horizontal Axis Title Font Size");
  mpHorizontalAxisTitleFontSizeSpinBox = new QDoubleSpinBox;
  mpHorizontalAxisTitleFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpHorizontalAxisTitleFontSizeSpinBox->setValue(mpPlotWindow->getPlot()->axisWidget(QwtPlot::xBottom)->title().font().pointSizeF());
  mpHorizontalAxisTitleFontSizeSpinBox->setSingleStep(1);
  mpHorizontalAxisNumbersFontSizeLabel = new QLabel("Horizontal Axis Numbers Font Size");
  mpHorizontalAxisNumbersFontSizeSpinBox = new QDoubleSpinBox;
  mpHorizontalAxisNumbersFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpHorizontalAxisNumbersFontSizeSpinBox->setValue(mpPlotWindow->getPlot()->axisWidget(QwtPlot::xBottom)->font().pointSizeF());
  mpHorizontalAxisNumbersFontSizeSpinBox->setSingleStep(1);
  mpPlotFooterLabel = new QLabel(tr("Plot Footer"));
  mpPlotFooterTextBox = new QLineEdit(mpPlotWindow->getFooter());
  mpFooterFontSizeLabel = new QLabel("Footer Font Size");
  mpFooterFontSizeSpinBox = new QDoubleSpinBox;
  mpFooterFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpFooterFontSizeSpinBox->setValue(mpPlotWindow->getPlot()->footerLabel()->font().pointSizeF());
  mpFooterFontSizeSpinBox->setSingleStep(1);
  // title tab layout
  QGridLayout *pTitlesTabGridLayout = new QGridLayout;
  pTitlesTabGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pTitlesTabGridLayout->addWidget(mpPlotTitleLabel, 0, 0);
  pTitlesTabGridLayout->addWidget(mpPlotTitleTextBox, 0, 1);
  pTitlesTabGridLayout->addWidget(mpTitleFontSizeLabel, 1, 0);
  pTitlesTabGridLayout->addWidget(mpTitleFontSizeSpinBox, 1, 1);
  pTitlesTabGridLayout->addWidget(mpVerticalAxisLabel, 2, 0);
  pTitlesTabGridLayout->addWidget(mpVerticalAxisTextBox, 2, 1);
  pTitlesTabGridLayout->addWidget(mpVerticalAxisTitleFontSizeLabel, 3, 0);
  pTitlesTabGridLayout->addWidget(mpVerticalAxisTitleFontSizeSpinBox, 3, 1);
  pTitlesTabGridLayout->addWidget(mpVerticalAxisNumbersFontSizeLabel, 4, 0);
  pTitlesTabGridLayout->addWidget(mpVerticalAxisNumbersFontSizeSpinBox, 4, 1);
  pTitlesTabGridLayout->addWidget(mpHorizontalAxisLabel, 5, 0);
  pTitlesTabGridLayout->addWidget(mpHorizontalAxisTextBox, 5, 1);
  pTitlesTabGridLayout->addWidget(mpHorizontalAxisTitleFontSizeLabel, 6, 0);
  pTitlesTabGridLayout->addWidget(mpHorizontalAxisTitleFontSizeSpinBox, 6, 1);
  pTitlesTabGridLayout->addWidget(mpHorizontalAxisNumbersFontSizeLabel, 7, 0);
  pTitlesTabGridLayout->addWidget(mpHorizontalAxisNumbersFontSizeSpinBox, 7, 1);
#if QWT_VERSION > 0x060000
  pTitlesTabGridLayout->addWidget(mpPlotFooterLabel, 8, 0);
  pTitlesTabGridLayout->addWidget(mpPlotFooterTextBox, 8, 1);
  pTitlesTabGridLayout->addWidget(mpFooterFontSizeLabel, 9, 0);
  pTitlesTabGridLayout->addWidget(mpFooterFontSizeSpinBox, 9, 1);
#endif
  mpTitlesTab->setLayout(pTitlesTabGridLayout);
  // legend tab
  mpLegendTab = new QWidget;
  mpLegendPositionLabel = new QLabel(tr("Legend Position"));
  mpLegendPositionComboBox = new QComboBox;
  mpLegendPositionComboBox->addItem(tr("Top"), "top");
  mpLegendPositionComboBox->addItem(tr("Right"), "right");
  mpLegendPositionComboBox->addItem(tr("Bottom"), "bottom");
  mpLegendPositionComboBox->addItem(tr("Left"), "left");
  int index = mpLegendPositionComboBox->findData(mpPlotWindow->getLegendPosition());
  if (index > -1) {
    mpLegendPositionComboBox->setCurrentIndex(index);
  }
  mpLegendFontSizeLabel = new QLabel(tr("Legend Font Size"));
  mpLegendFontSizeSpinBox = new QDoubleSpinBox;
  mpLegendFontSizeSpinBox->setRange(6, std::numeric_limits<double>::max());
  mpLegendFontSizeSpinBox->setValue(mpPlotWindow->getLegendFont().pointSizeF());
  mpLegendFontSizeSpinBox->setSingleStep(1);
  // legend tab layout
  QGridLayout *pLegendTabGridLayout = new QGridLayout;
  pLegendTabGridLayout->setAlignment(Qt::AlignTop);
  pLegendTabGridLayout->addWidget(mpLegendPositionLabel, 0, 0);
  pLegendTabGridLayout->addWidget(mpLegendPositionComboBox, 0, 1);
  pLegendTabGridLayout->addWidget(mpLegendFontSizeLabel, 1, 0);
  pLegendTabGridLayout->addWidget(mpLegendFontSizeSpinBox, 1, 1);
  mpLegendTab->setLayout(pLegendTabGridLayout);
  // range tab
  mpRangeTab = new QWidget;
  mpAutoScaleCheckbox = new QCheckBox(tr("Auto Scale"));
  mpAutoScaleCheckbox->setChecked(mpPlotWindow->getAutoScaleButton()->isChecked());
  connect(mpAutoScaleCheckbox, SIGNAL(toggled(bool)), SLOT(autoScaleChecked(bool)));
  // x-axis
  mpXAxisGroupBox = new QGroupBox(tr("X-Axis"));
  mpXMinimumLabel = new QLabel(tr("Minimum"));
  mpXMinimumTextBox = new QLineEdit(QString::number(mpPlotWindow->getPlot()->axisScaleDiv(QwtPlot::xBottom).lowerBound()));
  mpXMaximumLabel = new QLabel(tr("Maximum"));
  mpXMaximumTextBox = new QLineEdit(QString::number(mpPlotWindow->getPlot()->axisScaleDiv(QwtPlot::xBottom).upperBound()));
  QGridLayout *pXGridLayout = new QGridLayout;
  pXGridLayout->addWidget(mpXMinimumLabel, 0, 0);
  pXGridLayout->addWidget(mpXMinimumTextBox, 0, 1);
  pXGridLayout->addWidget(mpXMaximumLabel, 1, 0);
  pXGridLayout->addWidget(mpXMaximumTextBox, 1, 1);
  mpXAxisGroupBox->setLayout(pXGridLayout);
  mpXAxisGroupBox->setEnabled(!mpAutoScaleCheckbox->isChecked());
  // y-axis
  mpYAxisGroupBox = new QGroupBox(tr("Y-Axis"));
  mpYMinimumLabel = new QLabel(tr("Minimum"));
  mpYMinimumTextBox = new QLineEdit(QString::number(mpPlotWindow->getPlot()->axisScaleDiv(QwtPlot::yLeft).lowerBound()));
  mpYMaximumLabel = new QLabel(tr("Maximum"));
  mpYMaximumTextBox = new QLineEdit(QString::number(mpPlotWindow->getPlot()->axisScaleDiv(QwtPlot::yLeft).upperBound()));
  QGridLayout *pYGridLayout = new QGridLayout;
  pYGridLayout->addWidget(mpYMinimumLabel, 0, 0);
  pYGridLayout->addWidget(mpYMinimumTextBox, 0, 1);
  pYGridLayout->addWidget(mpYMaximumLabel, 1, 0);
  pYGridLayout->addWidget(mpYMaximumTextBox, 1, 1);
  mpYAxisGroupBox->setLayout(pYGridLayout);
  mpYAxisGroupBox->setEnabled(!mpAutoScaleCheckbox->isChecked());
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpXMinimumTextBox->setValidator(pDoubleValidator);
  mpXMaximumTextBox->setValidator(pDoubleValidator);
  mpYMinimumTextBox->setValidator(pDoubleValidator);
  mpXMaximumTextBox->setValidator(pDoubleValidator);
  mpPrefixUnitsCheckbox = new QCheckBox(tr("Prefix Units"));
  mpPrefixUnitsCheckbox->setChecked(mpPlotWindow->getPrefixUnits());
  // range tab layout
  QVBoxLayout *pRangeTabVerticalLayout = new QVBoxLayout;
  pRangeTabVerticalLayout->setAlignment(Qt::AlignTop);
  pRangeTabVerticalLayout->addWidget(mpAutoScaleCheckbox);
  pRangeTabVerticalLayout->addWidget(mpXAxisGroupBox);
  pRangeTabVerticalLayout->addWidget(mpYAxisGroupBox);
  pRangeTabVerticalLayout->addWidget(mpPrefixUnitsCheckbox);
  mpRangeTab->setLayout(pRangeTabVerticalLayout);
  // add tabs
  mpSetupTabWidget->addTab(mpVariablesTab, tr("Variables"));
  mpSetupTabWidget->addTab(mpTitlesTab, tr("Titles"));
  mpSetupTabWidget->addTab(mpLegendTab, tr("Legend"));
  mpSetupTabWidget->addTab(mpRangeTab, tr("Range"));
  // Create the buttons
  mpOkButton = new QPushButton(tr("OK"));
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(saveSetup()));
  mpApplyButton = new QPushButton(tr("Apply"));
  mpApplyButton->setAutoDefault(false);
  connect(mpApplyButton, SIGNAL(clicked()), this, SLOT(applySetup()));
  mpCancelButton = new QPushButton(tr("Cancel"));
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpApplyButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the main layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->addWidget(mpSetupTabWidget, 0, 0);
  pMainLayout->addWidget(mpButtonBox, 1, 0, 1, 1, Qt::AlignRight);
  setLayout(pMainLayout);
  // select the first variable if its available.
  if (mpVariablesListWidget->count() > 0) {
    mpVariablesListWidget->setCurrentRow(0, QItemSelectionModel::Select);
  }
}

void SetupDialog::selectVariable(QString variable)
{
  for (int i = 0 ; i < mpVariablesListWidget->count() ; i++)
  {
    if (mpVariablesListWidget->item(i)->data(Qt::UserRole).toString().compare(variable) == 0)
    {
      mpVariablesListWidget->setCurrentRow(i, QItemSelectionModel::ClearAndSelect);
      break;
    }
  }
}

void SetupDialog::setupPlotCurve(VariablePageWidget *pVariablePageWidget, bool prefixUnitsChanged)
{
  if (pVariablePageWidget) {
    PlotCurve *pPlotCurve = pVariablePageWidget->getPlotCurve();
    /* set the legend title */
    if (pPlotCurve->getCustomTitle().isEmpty() && pPlotCurve->title().text().compare(pVariablePageWidget->getLegendTextBox()->text()) == 0) {
      pPlotCurve->setCustomTitle("");
    } else {
      pPlotCurve->setCustomTitle(pVariablePageWidget->getLegendTextBox()->text());
    }
    /* set the curve color title */
    pPlotCurve->setCustomColor(!pVariablePageWidget->getAutomaticColorCheckBox()->isChecked());
    if (pVariablePageWidget->getAutomaticColorCheckBox()->isChecked()) {
      pVariablePageWidget->setCurveColor(pPlotCurve->pen().color());
      pVariablePageWidget->setCurvePickColorButtonIcon();
    } else {
      QPen pen = pPlotCurve->pen();
      pen.setColor(pVariablePageWidget->getCurveColor());
      pPlotCurve->setPen(pen);
    }
    /* set the curve style */
    QComboBox *pPatternComboBox = pVariablePageWidget->getPatternComboBox();
    pPlotCurve->setCurveStyle(pPatternComboBox->itemData(pPatternComboBox->currentIndex()).toInt());
    /* set the curve width */
    pPlotCurve->setCurveWidth(pVariablePageWidget->getThicknessSpinBox()->value());
    /* set the curve visibility */
    pPlotCurve->toggleVisibility(!pVariablePageWidget->getHideCheckBox()->isChecked());
    /* set the curve toggle sign */
    mpPlotWindow->toggleSign(pPlotCurve, pVariablePageWidget->getToggleSignCheckBox()->isChecked());
    // if prefixunits value is changed
    if (prefixUnitsChanged) {
      pPlotCurve->plotData();
    }
  }
}

void SetupDialog::variableSelected(QListWidgetItem *current, QListWidgetItem *previous)
{
  if (!current) {
    current = previous;
  }

  mpVariablePagesStackedWidget->setCurrentIndex(mpVariablesListWidget->row(current));
}

/*!
 * \brief SetupDialog::autoScaleChecked
 * SLOT activated when mpAutoScaleCheckbox toggled SIGNAL is raised.\n
 * Enabled/disables the range controls.
 * \param checked
 */
void SetupDialog::autoScaleChecked(bool checked)
{
  mpXAxisGroupBox->setEnabled(!checked);
  mpYAxisGroupBox->setEnabled(!checked);
}

void SetupDialog::saveSetup()
{
  applySetup();
  accept();
}

void SetupDialog::applySetup()
{
  // set the prefix units. Always set prefixUnits before setting plot data.
  const bool prefixUnitsChanged = mpPrefixUnitsCheckbox->isChecked() != mpPlotWindow->getPrefixUnits();
  mpPlotWindow->setPrefixUnits(mpPrefixUnitsCheckbox->isChecked());
  // set the variables attributes
  for (int i = 0 ; i < mpVariablePagesStackedWidget->count() ; i++) {
    setupPlotCurve(qobject_cast<VariablePageWidget*>(mpVariablePagesStackedWidget->widget(i)), prefixUnitsChanged);
  }
  // set the font sizes. Don't move this line. We should set the font sizes before calling setLegendPosition
  mpPlotWindow->getPlot()->setFontSizes(mpTitleFontSizeSpinBox->value(), mpVerticalAxisTitleFontSizeSpinBox->value(), mpVerticalAxisNumbersFontSizeSpinBox->value(),
                                        mpHorizontalAxisTitleFontSizeSpinBox->value(), mpHorizontalAxisNumbersFontSizeSpinBox->value(), mpFooterFontSizeSpinBox->value(),
                                        mpLegendFontSizeSpinBox->value());
  // set the titles
  mpPlotWindow->getPlot()->setTitle(mpPlotTitleTextBox->text());
  mpPlotWindow->setYCustomLabel(mpVerticalAxisTextBox->text());
  mpPlotWindow->setXCustomLabel(mpHorizontalAxisTextBox->text());
  mpPlotWindow->setFooter(mpPlotFooterTextBox->text());
  // set the legend
  mpPlotWindow->setLegendPosition(mpLegendPositionComboBox->itemData(mpLegendPositionComboBox->currentIndex()).toString());
  // set the auto scale
  mpPlotWindow->setAutoScale(mpAutoScaleCheckbox->isChecked());
  // set the range
  if (mpAutoScaleCheckbox->isChecked()) {
    mpPlotWindow->getPlot()->setAxisAutoScale(QwtPlot::xBottom);
    mpPlotWindow->getPlot()->setAxisAutoScale(QwtPlot::yLeft);
  } else {
    mpPlotWindow->setXRange(mpXMinimumTextBox->text().toDouble(), mpXMaximumTextBox->text().toDouble());
    mpPlotWindow->setYRange(mpYMinimumTextBox->text().toDouble(), mpYMaximumTextBox->text().toDouble());
  }
  // update plot
  mpPlotWindow->updatePlot();
  if (prefixUnitsChanged) {
    mpPlotWindow->emitPrefixUnitsChanged();
  }
}
