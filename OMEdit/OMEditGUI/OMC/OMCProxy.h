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

#ifndef OMCPROXY_H
#define OMCPROXY_H

#include "MainWindow.h"
#include "omc_communication.h"
#include "Component.h"
#include "StringHandler.h"

class MainWindow;
class CustomExpressionBox;
class ComponentInfo;
class StringHandler;

struct cachedOMCCommand
{
  QString mOMCCommand;
  QString mOMCCommandResult;
};

class OMCProxy : public QObject
{
  Q_OBJECT
private:
  OmcCommunication_var mOMC;
  bool mHasInitialized;
  QString mResult;
  QString mExpression;
  QWidget *mpOMCLoggerWidget;
  CustomExpressionBox *mpExpressionTextBox;
  QPushButton *mpOMCLoggerSendButton;
  QPlainTextEdit *mpOMCLoggerTextBox;
  QString mObjectRefFile;
  QList<QString> mCommandsList;
  int mCurrentCommandIndex;
  QFile mCommandsLogFile;
  QTextStream mCommandsLogFileTextStream;
  MainWindow *mpMainWindow;
  int mAnnotationVersion;
  QMap<QString, QList<cachedOMCCommand> > mCachedOMCCommandsMap;
public:
  OMCProxy(MainWindow *pMainWindow);
  ~OMCProxy();
  void enableCustomExpression(bool enable);
  void getPreviousCommand();
  void getNextCommand();
  void setExpression(QString expression);
  QString getExpression();
  void writeCommandLog(QString expression, QTime* commandTime);
  void writeCommandResponseLog(QTime* commandTime);
  cachedOMCCommand getcachedOMCCommand(QString className, QString command);
  void cacheOMCCommand(QString className, QString command, QString commandResult);
  void removeCachedOMCCommand(QString className);
  bool startServer();
  void stopServer();
  void sendCommand(const QString expression, bool cacheCommand = false, QString className = QString(), bool dontUseCachedCommand = false);
  void setResult(QString value);
  QString getResult();
  void logOMCMessages(QString expression);
  void exitApplication();
  void removeObjectRefFile();
  QString getErrorString();
  bool printMessagesStringInternal();
  int getMessagesStringInternal();
  void setCurrentError(int errorIndex);
  QString getErrorFileName();
  bool getErrorReadOnly();
  int getErrorLineStart();
  int getErrorColumnStart();
  int getErrorLineEnd();
  int getErrorColumnEnd();
  QString getErrorMessage();
  QString getErrorKind();
  QString getErrorLevel();
  int getErrorId();
  QString getVersion();
  QString getAnnotationVersion();
  bool setEnvironmentVar(QString name, QString value);
  QString getEnvironmentVar(QString name);
  void loadSystemLibraries(QSplashScreen *pSplashScreen);
  void loadUserLibraries(QSplashScreen *pSplashScreen);
  QStringList getClassNames(QString className = QString(), QString recursive = QString("false"), QString qualified = QString("false"),
                            QString showProtected = QString("true"));
  QStringList searchClassNames(QString searchText, QString findInText = QString("false"));
  QStringList getClassInformation(QString className);
  bool isPackage(QString className);
  bool isBuiltinType(QString typeName);
  bool isWhat(int type, QString className);
  bool isProtected(QString parameter, QString className);
  bool isProtectedClass(QString className, QString nestedClassName);
  bool isPartial(QString className);
  StringHandler::ModelicaClasses getClassRestriction(QString className);
  QStringList getParameterNames(QString className);
  QString getParameterValue(QString className, QString parameter);
  bool setParameterValue(QString className, QString parameter, QString value);
  QStringList getComponentModifierNames(QString className, QString name);
  QString getComponentModifierValue(QString className, QString name);
  bool setComponentModifierValue(QString className, QString name, QString modifierValue);
  QStringList getExtendsModifierNames(QString className, QString extendsClassName);
  QString getExtendsModifierValue(QString className, QString extendsClassName, QString modifierName);
  bool setExtendsModifierValue(QString className, QString extendsClassName, QString modifierName, QString modifierValue);
  QString getIconAnnotation(QString className);
  QString getDiagramAnnotation(QString className);
  int getConnectionCount(QString className);
  QString getNthConnection(QString className, int num);
  QString getNthConnectionAnnotation(QString className, int num);
  int getInheritanceCount(QString className);
  QString getNthInheritedClass(QString className, int num);
  QList<ComponentInfo*> getComponents(QString className);
  QStringList getComponentAnnotations(QString className);
  QString getDocumentationAnnotation(QString className);
  QString getClassComment(QString className);
  QString changeDirectory(QString directory = QString());
  bool loadModel(QString library, QString version = QString("default"));
  bool loadFile(QString fileName, QString encoding = Helper::utf8);
  bool loadString(QString value);
  bool parseFile(QString fileName, QString encoding = Helper::utf8);
  QStringList parseString(QString value);
  bool createClass(QString type, QString className, QString extendsClass);
  bool createSubClass(QString type, QString className, QString parentClassName, QString extendsClass);
  bool existClass(QString className);
  bool renameClass(QString oldName, QString newName);
  bool deleteClass(QString className);
  QString getSourceFile(QString className);
  bool setSourceFile(QString className, QString path);
  bool save(QString className);
  bool saveModifiedModel(QString modelText);
  QString list(QString className);
  QString instantiateModel(QString className);
  bool addClassAnnotation(QString className, QString annotation);
  QString getDefaultComponentName(QString className);
  QString getDefaultComponentPrefixes(QString className);
  bool addComponent(QString name, QString className, QString componentName, QString placementAnnotation);
  bool deleteComponent(QString name, QString componentName);
  bool renameComponent(QString className, QString oldName, QString newName);
  bool updateComponent(QString name, QString className, QString componentName, QString placementAnnotation);
  bool renameComponentInClass(QString className, QString oldName, QString newName);
  bool updateConnection(QString from, QString to, QString className, QString annotation);
  bool setComponentProperties(QString className, QString componentName, QString isFinal, QString isFlow, QString isProtected,
                              QString isReplaceAble, QString variability, QString isInner, QString isOuter, QString causality);
  bool setComponentComment(QString className, QString componentName, QString comment);
  bool addConnection(QString from, QString to, QString className, QString annotation);
  bool deleteConnection(QString from, QString to, QString className);
  bool instantiateModelSucceeds(QString className);
  bool simulate(QString className, QString simualtionParameters);
  bool buildModel(QString className, QString simualtionParameters);
  bool translateModel(QString className, QString simualtionParameters);
  QStringList readSimulationResultVars(QString fileName);
  bool closeSimulationResultFile();
  QString checkModel(QString className);
  bool isExperiment(QString className);
  QStringList getSimulationOptions(QString className, double defaultTolerance = 1e-4);
  bool translateModelFMU(QString className);
  bool translateModelXML(QString className);
  QString importFMU(QString fmuName, QString outputDirectory, int logLevel, bool debugLogging, bool generateInputConnectors, bool generateOutputConnectors);
  QString getMatchingAlgorithm();
  void getAvailableMatchingAlgorithms(QStringList *choices, QStringList *comments);
  bool setMatchingAlgorithm(QString matchingAlgorithm);
  QString getIndexReductionMethod();
  void getAvailableIndexReductionMethods(QStringList *choices, QStringList *comments);
  bool setIndexReductionMethod(QString method);
  bool setCommandLineOptions(QString options);
  bool clearCommandLineOptions();
  QString makeDocumentationImagesUriToFileName(QString documentation);
  QString uriToFilename(QString uri);
  QString getModelicaPath();
  QStringList getAvailableLibraries();
  QString getDerivedClassModifierValue(QString className, QString modifierName);
  bool getDocumentationClassAnnotation(QString className);
  QString numProcessors();
signals:
  void commandFinished();
public slots:
  void sendCommand();
  void openOMCLoggerWidget();
  void sendCustomExpression();
};

class CustomExpressionBox : public QLineEdit
{
public:
  CustomExpressionBox(OMCProxy *pOMCProxy);
  OMCProxy *mpOMCProxy;
protected:
  virtual void keyPressEvent(QKeyEvent *event);
};

#endif // OMCPROXY_H
