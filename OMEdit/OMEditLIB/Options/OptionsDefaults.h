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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */
#ifndef OPTIONSDEFAULTS_H
#define OPTIONSDEFAULTS_H

#include <QString>
#include <QColor>

namespace OptionsDefaults
{
  namespace GeneralSettings {
    QString workingDirectory; // this value is set in GeneralSettingsPage constructor.
    int toolBarIconSize = 24;
    bool preserveUserCustomizations = true;
  #ifdef Q_OS_WIN32
    QString terminalCommand = "cmd.exe";
  #elif defined(Q_OS_MAC)
    QString terminalCommand =  "";
  #else
    QString terminalCommand = "x-terminal-emulator";
  #endif
    QString terminalCommandArguments = "";
    bool hideVariablesBrowser = true;
    int activateAccessAnnotationsIndex = 1;
    bool createBackupFile = true;
    bool displayNFAPIErrorsWarnings = false;
    bool enableCRMLSupport = false;
    int libraryIconSize = 24;
    int libraryIconMaximumTextLength = 3;
    bool showProtectedClasses = false;
    bool showHiddenClasses = false;
    bool synchronizeWithModelWidget = true;
    bool enableAutoSave = true;
    int autoSaveInterval = 300;
    int welcomePageView = 1;
    bool showLatestNews = true;
    int recentFilesAndLatestNewsSize = 15;
  }

  namespace Libraries {
    bool loadLatestModelica = true;
  }

  namespace TextEditor {
#ifdef WIN32
    int lineEnding = 0;
#else
    int lineEnding = 1;
#endif
    int bom = 1;
    int tabPolicy = 0;
    int tabSize = 4;
    int indentSize = 2;
    bool syntaxHighlighting = true;
    bool codeFolding = true;
    bool matchParenthesesCommentsQuotes = false;
    bool lineWrapping = true;
    bool autocomplete = true;
  }

  namespace ModelicaEditor {
    bool preserveTextIndentation = true;
    QColor textRuleColor = QColor(0, 0, 0);
    QColor numberRuleColor = QColor(139, 0, 139);
    QColor keywordRuleColor = QColor(139, 0, 0);
    QColor typeRuleColor = QColor(255, 10, 10);
    QColor functionRuleColor = QColor(0, 0, 255);
    QColor quotesRuleColor = QColor(0, 139, 0);
    QColor commentRuleColor = QColor(0, 150, 0);
  }

  namespace MetaModelicaEditor {
    QColor numberRuleColor = QColor(139, 0, 139);
    QColor keywordRuleColor = QColor(139, 0, 0);
    QColor typeRuleColor = QColor(255, 10, 10);
    QColor quotesRuleColor = QColor(0, 139, 0);
    QColor commentRuleColor = QColor(0, 150, 0);
  }

  namespace CRMLEditor {
    QColor numberRuleColor = QColor(139, 0, 139);
    QColor keywordRuleColor = QColor(139, 0, 0);
    QColor typeRuleColor = QColor(255, 10, 10);
    QColor quotesRuleColor = QColor(0, 139, 0);
    QColor commentRuleColor = QColor(0, 150, 0);
  }

  namespace MOSEditor {
    QColor numberRuleColor = QColor(139, 0, 139);
    QColor keywordRuleColor = QColor(139, 0, 0);
    QColor typeRuleColor = QColor(255, 10, 10);
    QColor quotesRuleColor = QColor(0, 139, 0);
    QColor commentRuleColor = QColor(0, 150, 0);
  }

  namespace OMSimulatorEditor {
    QColor tagRuleColor = QColor(0, 0, 255);
    QColor elementRuleColor = QColor(0, 0, 255);
    QColor quotesRuleColor = QColor(139, 0, 0);
    QColor commentRuleColor = QColor(0, 150, 0);
  }

  namespace CEditor {
    QColor numberRuleColor = QColor(139, 0, 139);
    QColor keywordRuleColor = QColor(139, 0, 0);
    QColor typeRuleColor = QColor(255, 10, 10);
    QColor quotesRuleColor = QColor(0, 139, 0);
    QColor commentRuleColor = QColor(0, 150, 0);
  }

  namespace HTMLEditor {
    QColor tagRuleColor = QColor(0, 0, 255);
    QColor quotesRuleColor = QColor(139, 0, 0);
    QColor commentRuleColor = QColor(0, 150, 0);
  }

  namespace GraphicalViewsPage {
    bool moveConnectorsTogether = false;
  }

  namespace Simulation {
    QString targetBuild = "gcc";
    QString cCompiler; // this value is set in SimulationPage constructor.
    QString cxxCompiler; // this value is set in SimulationPage constructor.
    bool useStaticLinking = false;
    QString postCompilationCommand = "";
    bool ignoreCommandLineOptionsAnnotation = false;
    bool ignoreSimulationFlagsAnnotation = false;
    bool saveClassBeforeSimulation = true;
    bool switchToPlottingPerspective = true;
    bool closeSimulationOutputWidgetsBeforeSimulation = true;
    bool deleteIntermediateCompilationFiles = true;
    bool deleteEntireSimulationDirectory = false;
    int displayLimit = 500;
  }

  namespace Messages {
    int outputSize = 0;
    bool resetMessagesNumberBeforeSimulation = true;
    bool clearMessagesBrowserBeforeSimulation = false;
    bool enlargeMessageBrowserCheckBox = false;
    QColor notificationColor = Qt::black;
    QColor warningColor = QColor(255, 170, 0);
    QColor errorColor = Qt::red;
  }

  namespace Notification {
    bool quitApplication = false;
    bool itemDroppedOnItself = true;
    bool replaceableIfPartial = true;
    bool innerModelNameChanged = true;
    bool saveModelForBitmapInsertion = true;
    bool alwaysAskForDraggedComponentName = true;
    bool alwaysAskForTextEditorError = true;
  }

  namespace LineStyle {
    QColor color = Qt::black;
    QString pattern = "LinePattern.Solid";
    double thickness = 0.25;
    QString startArrow = "Arrow.None";
    QString endArrow = "Arrow.None";
    double arrowSize = 3;
    bool smooth = false;
  }

  namespace FillStyle {
    QColor color = Qt::black;
    QString pattern = "FillPattern.None";
  }

  namespace Plotting {
    bool autoScale = true;
    bool prefixUnits = true;
    int curvePattern = 1;
    double curveThickness = 1;
    int variableFilterInterval = 2;
    double titleFontSize = 14;
    double verticalAxisTitleFontSize = 11;
    double verticalAxisNumbersFontSize = 10;
    double horizontalAxisTitleFontSize = 11;
    double horizontalAxisNumbersFontSize = 10;
  }

  namespace Figaro {
    QString databaseFile = "";
    QString options = "";
    QString process; // this value is set in FigaroPage constructor.
  }

  namespace CRML {
    QString compilerJar = "crml-compiler-all.jar";
    QString process = "java";
  }

  namespace Debugger {
    int GDBCommandTimeout = 40;
    int GDBOutputLimit = 0;
    bool displayCFrames = true;
    bool displayUnknownFrames = true;
    bool clearOutputOnNewRun = true;
    bool clearLogOnNewRun = true;
    bool alwaysShowTransformationalDebugger = false;
    bool generateOperations = true;
  }

  namespace FMI {
    QString version = "2.0";
    QString type = "me_cs";
    QString FMUName = "";
    QString moveFMU = "";
    QString solver = "";
    QString modelDescriptionFilter = "protected";
    bool includeResources = false;
    bool includeSourceCode = true;
    bool generateDebugSymbols = false;
    bool deleteFMUDirectoyAndModel = false;
  }

  namespace OMSimulator {
    QString commandLineOptions = "--suppressPath=true";
    int loggingLevel = 0;
  }

  namespace SensitivityOptimization {
    QString python = "python";
  }

  namespace Traceability {
    bool traceability = false;
    QString username = "";
    QString email = "";
    QString gitRepository = "";
    QString ipAdress = "";
    QString port = "";
  }
}

#endif // OPTIONSDEFAULTS_H
