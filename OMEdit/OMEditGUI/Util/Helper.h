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
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef HELPER_H
#define HELPER_H

#include <stdlib.h>
#include <QString>
#include <QSize>
#include <QObject>
#include <QMdiArea>
#include <QThread>
#include <QLabel>
#include <QPlainTextEdit>
#include <QMessageBox>
#include <QCheckBox>

class Helper : public QObject
{
  Q_OBJECT
public:
  static void initHelperVariables();
  /* Global non-translated variables */
  static QString applicationName;
  static QString applicationIntroText;
  static QString organization;
  static QString application;
  static QString OpenModelicaHome;
  static QString OpenModelicaLibrary;
  static QString omcServerName;
  static QString omFileTypes;
  static QString omnotebookFileTypes;
  static QString imageFileTypes;
  static QString fmuFileTypes;
  static QString xmlFileTypes;
  static QString matFileTypes;
  static QString omResultFileTypes;
  static int treeIndentation;
  static QSize iconSize;
  static QSize buttonIconSize;
  static int tabWidth;
  static QString modelicaComponentFormat;
  static QString modelicaFileFormat;
  static qreal globalDiagramXScale;
  static qreal globalDiagramYScale;
  static qreal globalIconXScale;
  static qreal globalIconYScale;
  static qreal shapesStrokeWidth;
  static int headingFontSize;
  static QString ModelicaSimulationMethods;
  static QString ModelicaInitializationMethods;
  static QString ModelicaOptimizationMethods;
  static QString ModelicaSimulationOutputFormats;
  static QString clockOptions;
  static QString linearSolvers;
  static QString nonLinearSolvers;
  static QString fontSizes;
  static QString notificationLevel;
  static QString warningLevel;
  static QString errorLevel;
  static QString syntaxKind;
  static QString grammarKind;
  static QString translationKind;
  static QString symbolicKind;
  static QString simulationKind;
  static QString scriptingKind;
  static QString tabbed;
  static QString subWindow;
  static QString utf8;
  static QFontInfo systemFontInfo;
  static QFontInfo monospacedFontInfo;
  static QString defaultComponentAnnotationString;
  static QString errorComponentAnnotationString;
  /* Global translated variables */
  static QString newModelicaClass;
  static QString createNewModelicaClass;
  static QString openModelicaFile;
  static QString clearRecentFiles;
  static QString encoding;
  static QString file;
  static QString browse;
  static QString ok;
  static QString cancel;
  static QString close;
  static QString error;
  static QString chooseFile;
  static QString chooseFiles;
  static QString attributes;
  static QString properties;
  static QString connection;
  static QString edit;
  static QString save;
  static QString chooseDirectory;
  static QString general;
  static QString parameters;
  static QString name;
  static QString comment;
  static QString path;
  static QString type;
  static QString information;
  static QString rename;
  static QString checkModel;
  static QString checkModelTip;
  static QString instantiateModel;
  static QString instantiateModelTip;
  static QString exportFMU;
  static QString exportFMUTip;
  static QString importFMU;
  static QString importFMUTip;
  static QString exportXML;
  static QString exportXMLTip;
  static QString exportToOMNotebook;
  static QString exportToOMNotebookTip;
  static QString importFromOMNotebook;
  static QString importFromOMNotebookTip;
  static QString exportAsImage;
  static QString exportAsImageTip;
  static QString deleteStr;
  static QString copy;
  static QString paste;
  static QString loading;
  static QString question;
  static QString search;
  static QString model;
  static QString Class;
  static QString connector;
  static QString record;
  static QString block;
  static QString function;
  static QString optimization;
  static QString functionTip;
  static QString unloadClass;
  static QString unloadClassTip;
  static QString simulate;
  static QString simulateTip;
  static QString simulation;
  static QString interactiveSimulation;
  static QString options;
  static QString extent;
  static QString bottom;
  static QString top;
  static QString grid;
  static QString horizontal;
  static QString vertical;
  static QString component;
  static QString scaleFactor;
  static QString preserveAspectRatio;
  static QString originX;
  static QString originY;
  static QString rotation;
  static QString thickness;
  static QString smooth;
  static QString bezier;
  static QString startArrow;
  static QString endArrow;
  static QString arrowSize;
  static QString size;
  static QString lineStyle;
  static QString color;
  static QString pickColor;
  static QString pattern;
  static QString fillStyle;
  static QString extent1X;
  static QString extent1Y;
  static QString extent2X;
  static QString extent2Y;
  static QString radius;
  static QString startAngle;
  static QString endAngle;
  static QString remove;
  static QString errorLocation;
  static QString fileLocation;
  static QString readOnly;
  static QString writable;
  static QString iconView;
  static QString diagramView;
  static QString modelicaTextView;
  static QString documentationView;
  static QString searchModelicaClass;
  static QString findReplaceModelicaText;
  static QString left;
  static QString center;
  static QString right;
  static QString connectArray;
  static QString findVariables;
  static QString viewClass;
  static QString viewClassTip;
  static QString viewDocumentation;
  static QString viewDocumentationTip;
  static QString dontShowThisMessageAgain;
};

class GUIMessages : public QObject
{
  Q_OBJECT
public:
  enum MessagesTypes
  {
    CHECK_MESSAGES_BROWSER,
    SAME_COMPONENT_NAME,
    SAME_COMPONENT_CONNECT,
    NO_MODELICA_CLASS_OPEN,
    NO_SIMULATION_STARTTIME,
    NO_SIMULATION_STOPTIME,
    SIMULATION_STARTTIME_LESSTHAN_STOPTIME,
    ENTER_NAME,
    MODEL_ALREADY_EXISTS,
    ITEM_ALREADY_EXISTS,
    OPENMODELICAHOME_NOT_FOUND,
    ERROR_OCCURRED,
    ERROR_IN_MODELICA_TEXT,
    REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY,
    NO_OPENMODELICA_KEYWORDS,
    INCOMPATIBLE_CONNECTORS,
    UNABLE_TO_LOAD_FILE,
    FILE_NOT_FOUND,
    UNABLE_TO_LOAD_MODEL,
    DELETE_AND_LOAD,
    REDEFINING_EXISTING_CLASSES,
    SEARCH_STRING_NOT_FOUND,
    CLOSE_INTERACTIVE_SIMULATION_TAB,
    INFO_CLOSE_INTERACTIVE_SIMULATION_TAB,
    INTERACTIVE_SIMULATION_RUNNIG,
    SELECT_VARIABLE_FOR_OMI,
    DIAGRAM_VIEW_DROP_MSG,
    ICON_VIEW_DROP_MSG,
    PLOT_PARAMETRIC_DIFF_FILES,
    FILE_FORMAT_NOT_SUPPORTED,
    ENTER_VALID_INTEGER,
    ENTER_VALID_NUMBER,
    ITEM_DROPPED_ON_ITSELF,
    MAKE_REPLACEABLE_IF_PARTIAL,
    INNER_MODEL_NAME_CHANGED,
    FMU_GENERATED,
    XML_GENERATED,
    DELETE_CLASS_MSG,
    WRONG_MODIFIER
  };

  static QString getMessage(int type);
};

class MainWindow;
class MdiArea : public QMdiArea
{
  Q_OBJECT
public:
  MdiArea(QWidget *pParent = 0);
  MainWindow* getMainWindow();
protected:
  MainWindow *mpMainWindow;
};

//! @brief Used to create platform independent sleep for the application.
class Sleep : public QThread
{
  Q_OBJECT
public:
  Sleep() {}
  ~Sleep() {}
  static void sleep(unsigned long secs) {QThread::sleep(secs);}
protected:
  void run() {}
};

class Label : public QLabel
{
public:
  Label(QWidget *parent = 0, Qt::WindowFlags f = 0) : QLabel(parent, f) {init();}
  Label(const QString &text, QWidget *parent = 0, Qt::WindowFlags f = 0) : QLabel(text, parent, f) {init();}
private:
  void init() {setTextInteractionFlags(Qt::TextSelectableByMouse);}
};

//! @struct RecentFile
/*! \brief It contains the recently opened file name and its encoding.
 * We must register this struct as a meta type since we need to use it as a QVariant.
 * This is used to store the recent files information in omedit.ini file.
 * The QDataStream also needed to be defined for this struct.
 */
struct RecentFile
{
  QString fileName;
  QString encoding;
  operator QVariant() const
  {
    return QVariant::fromValue(*this);
  }
};
Q_DECLARE_METATYPE(RecentFile)

inline QDataStream& operator<<(QDataStream& out, const RecentFile& recentFile)
{
  out << recentFile.fileName;
  out << recentFile.encoding;
  return out;
}

inline QDataStream& operator>>(QDataStream& in, RecentFile& recentFile)
{
  in >> recentFile.fileName;
  in >> recentFile.encoding;
  return in;
}

//! @struct FindText
/*! \brief It contains the recently searched text from find/replace dialog .
 * We must register this struct as a meta type since we need to use it as a QVariant.
 * This is used to store the recent texts information in omedit.ini file.
 * The QDataStream also needed to be defined for this struct.
 */
struct FindText
{
  QString text;
  operator QVariant() const
  {
    return QVariant::fromValue(*this);
  }
};
Q_DECLARE_METATYPE(FindText)

inline QDataStream& operator<<(QDataStream& out, const FindText& findText)
{
  out << findText.text;
  return out;
}

inline QDataStream& operator>>(QDataStream& in, FindText& findText)
{
  in >> findText.text;
  return in;
}

#endif // HELPER_H
