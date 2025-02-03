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
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef OMCPROXY_H
#define OMCPROXY_H

#include "OpenModelicaScriptingAPIQt.h"
#include "Util/StringHandler.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"

class CustomExpressionBox;
class OutputPlainTextEdit;
class ElementInfo;
class StringHandler;
class OMCInterface;
class LibraryTreeItem;
class QNetworkReply;

typedef struct {
  QString mFromUnit;
  QString mToUnit;
  OMCInterface::convertUnits_res mConvertUnits;
} UnitConverion;

class OMCProxy : public QObject
{
  Q_OBJECT
private:
  bool mHasInitialized;
  QString mResult;
  QWidget *mpOMCLoggerWidget;
  CustomExpressionBox *mpExpressionTextBox;
  QPushButton *mpOMCLoggerSendButton;
  OutputPlainTextEdit *mpOMCLoggerTextBox;
  QWidget *mpOMCDiffWidget;
  Label *mpOMCDiffBeforeLabel;
  QPlainTextEdit *mpOMCDiffBeforeTextBox;
  Label *mpOMCDiffAfterLabel;
  QPlainTextEdit *mpOMCDiffAfterTextBox;
  Label *mpOMCDiffMergedLabel;
  QPlainTextEdit *mpOMCDiffMergedTextBox;
  QString mObjectRefFile;
  QList<QString> mCommandsList;
  int mCurrentCommandIndex;
  FILE *mpCommunicationLogFile;
  FILE *mpCommandsLogFile;
  double mTotalOMCCallsTime;
  QList<UnitConverion> mUnitConversionList;
  QMap<QString, QList<QString> > mDerivedUnitsMap;
  OMCInterface *mpOMCInterface;
  bool mIsLoggingEnabled;
  QStringList mLibrariesBrowserAdditionCommandsList;
  QStringList mLibrariesBrowserDeletionCommandsList;
  bool mLoadModelError;
public:
  OMCProxy(threadData_t *threadData, QWidget *pParent = 0);
  ~OMCProxy();
  bool eventFilter(QObject *pObject, QEvent *pEvent);
  void getPreviousCommand();
  void getNextCommand();
  bool initializeOMC(threadData_t *threadData);
  void quitOMC();
  void sendCommand(const QString expression, bool saveToHistory = false);
  void setResult(QString value);
  QString getResult();
  void exitApplication();
  void removeObjectRefFile();
  void setLoggingEnabled(bool enable) {mIsLoggingEnabled = enable;}
  bool isLoggingEnabled() {return mIsLoggingEnabled;}
  bool isLoadModelError() const {return mLoadModelError;}
  QString getErrorString(bool warningsAsErrors = false);
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
  QString getVersion(QString className = QString("OpenModelica"));
  void loadSystemLibraries(const QVector<QPair<QString, QString> > libraries);
  void loadUserLibraries();
  QStringList getClassNames(QString className = QString("AllLoadedClasses"), bool recursive = false, bool qualified = false,
                            bool sort = false, bool builtin = false, bool showProtected = true, bool includeConstants = false);
  QStringList searchClassNames(QString searchText, bool findInText = false);
  OMCInterface::getClassInformation_res getClassInformation(QString className);
  bool isPackage(QString className);
  bool isBuiltinType(QString typeName);
  QString getBuiltinType(QString typeName);
  bool isWhat(StringHandler::ModelicaClasses type, QString className);
  bool isProtectedClass(QString className, QString nestedClassName);
  bool isPartial(QString className);
  bool isReplaceable(QString elementName);
  bool isRedeclare(QString elementName);
  StringHandler::ModelicaClasses getClassRestriction(QString className);
  bool setParameterValue(const QString &className, const QString &parameter, const QString &value);
  QString getParameterValue(const QString &className, const QString &parameter);
  QStringList getElementModifierNames(QString className, QString name);
  QString getElementModifierValue(QString className, QString name);
  bool setElementModifierValueOld(QString className, QString modifierName, QString modifierValue);
  bool setElementModifierValue(QString className, QString modifierName, QString modifierValue);
  bool removeElementModifiers(QString className, QString name);
  QString getElementModifierValues(QString className, QString name);
  QStringList getExtendsModifierNames(QString className, QString extendsClassName);
  QString getExtendsModifierValue(QString className, QString extendsClassName, QString modifierName);
  bool setExtendsModifierValueOld(QString className, QString extendsClassName, QString modifierName, QString modifierValue);
  bool setExtendsModifierValue(QString className, QString extendsClassName, QString modifierName, QString modifierValue);
  bool isExtendsModifierFinal(QString className, QString extendsClassName, QString modifierName);
  bool removeExtendsModifiers(QString className, QString extendsClassName);
  QString qualifyPath(const QString &classPath, const QString &path);
  QString getIconAnnotation(QString className);
  QString getDiagramAnnotation(QString className);
  int getConnectionCount(QString className);
  QList<QString> getNthConnection(QString className, int index);
  QString getNthConnectionAnnotation(QString className, int num);
  QList<QList<QString> > getTransitions(QString className);
  QList<QList<QString> > getInitialStates(QString className);
  int getInheritanceCount(QString className);
  QString getNthInheritedClass(QString className, int num);
  QList<QString> getInheritedClasses(QString className);
  QString getNthInheritedClassIconMapAnnotation(QString className, int num);
  QString getNthInheritedClassDiagramMapAnnotation(QString className, int num);
  QList<ElementInfo> getElements(QString className);
  QStringList getElementAnnotations(QString className);
  QString getDocumentationAnnotationInfoHeader(LibraryTreeItem *pLibraryTreeItem, QString infoHeader);
  QString getDocumentationAnnotation(LibraryTreeItem *pLibraryTreeItem);
  QList<QString> getDocumentationAnnotationInClass(LibraryTreeItem *pLibraryTreeItem);
  QString getClassComment(QString className);
  QString changeDirectory(QString directory = QString(""));
  bool loadModel(QString className, QString priorityVersion = QString("default"), bool notify = true, QString languageStandard = QString(""), bool requireExactVersion = false);
  bool loadFile(QString fileName, QString encoding = Helper::utf8, bool uses = true, bool notify = true, bool requireExactVersion = false, bool allowWithin = false);
  bool loadString(QString value, QString fileName, QString encoding = Helper::utf8, bool merge = false, bool checkError = true);
  bool loadClassContentString(const QString &data, const QString &className, int offsetX = 0, int offsetY = 0);
  QList<QString> parseFile(QString fileName, QString encoding = Helper::utf8);
  QList<QString> parseString(QString value, QString fileName, bool printErrors = true);
  bool createClass(QString type, QString className, LibraryTreeItem *pExtendsLibraryTreeItem);
  bool createSubClass(QString type, QString className, LibraryTreeItem *pParentLibraryTreeItem, LibraryTreeItem *pExtendsLibraryTreeItem);
  bool existClass(QString className);
  bool renameClass(QString oldName, QString newName);
  bool deleteClass(QString className);
  QString getSourceFile(QString className);
  bool setSourceFile(QString className, QString path);
  bool save(QString className);
  bool saveModifiedModel(QString modelText);
  bool saveTotalModel(QString fileName, QString className, bool stripAnnotations, bool stripComments, bool obfuscate, bool simplified);
  QString list(QString className);
  QString listFile(QString className, bool nestedClasses = true);
  QString diffModelicaFileListings(const QString &before, const QString &after);
  QString instantiateModel(QString className);
  QString runScript(QString fileName);
  bool addClassAnnotation(QString className, QString annotation);
  QString getDefaultComponentName(QString className);
  QString getDefaultComponentPrefixes(QString className);
  bool addComponent(QString name, QString componentName, QString className, QString placementAnnotation);
  bool deleteComponent(QString name, QString componentName);
  bool renameComponent(QString className, QString oldName, QString newName);
  bool updateComponent(QString name, QString className, QString componentName, QString placementAnnotation);
  bool setElementAnnotation(const QString &elementName, QString annotation);
  bool renameComponentInClass(QString className, QString oldName, QString newName);
  bool updateConnection(QString className, QString from, QString to, QString annotation);
  bool updateConnectionNames(QString className, QString from, QString to, QString fromNew, QString toNew);
  bool setComponentProperties(QString className, QString componentName, QString isFinal, QString isFlow, QString isProtected,
                              QString isReplaceAble, QString variability, QString isInner, QString isOuter, QString causality);
  bool setComponentComment(QString className, QString componentName, QString comment);
  bool setComponentDimensions(QString className, QString componentName, QString dimensions);
  void addConnection(QString from, QString to, QString className, QString annotation);
  bool deleteConnection(QString from, QString to, QString className);
  bool addTransition(QString className, QString from, QString to, QString condition, bool immediate, bool reset, bool synchronize, int priority, QString annotation);
  bool deleteTransition(QString className, QString from, QString to, QString condition, bool immediate, bool reset, bool synchronize, int priority);
  bool updateTransition(QString className, QString from, QString to, QString oldCondition, bool oldImmediate, bool oldReset, bool oldSynchronize, int oldPriority,
                        QString condition, bool immediate, bool reset, bool synchronize, int priority, QString annotation);
  bool addInitialState(QString className, QString state, QString annotation);
  bool deleteInitialState(QString className, QString state);
  bool updateInitialState(QString className, QString state, QString annotation);
  bool simulate(QString className, QString simualtionParameters);
  bool buildModel(QString className, QString simualtionParameters);
  bool translateModel(QString className, QString simualtionParameters);
  int readSimulationResultSize(QString fileName);
  QStringList readSimulationResultVars(QString fileName);
  bool closeSimulationResultFile();
  QString checkModel(QString className);
  bool ngspicetoModelica(QString fileName);
  QString checkAllModelsRecursive(QString className);
  bool isExperiment(QString className);
  OMCInterface::getSimulationOptions_res getSimulationOptions(QString className, double defaultTolerance = 1e-6);
  QString buildModelFMU(QString className, QString version, QString type, QString fileNamePrefix, QList<QString> platforms, bool includeResources);
  bool translateModelFMU(QString className, QString version, QString type, QString fileNamePrefix, QList<QString> platforms, bool includeResources);
  QString translateModelXML(QString className);
  QString importFMU(QString fmuName, QString outputDirectory, int logLevel, bool debugLogging, bool generateInputConnectors, bool generateOutputConnectors, QString modelName);
  QString importFMUModelDescription(QString fmuModelDescriptionName, QString outputDirectory, int logLevel, bool debugLogging, bool generateInputConnectors, bool generateOutputConnectors);
  QString getMatchingAlgorithm();
  OMCInterface::getAvailableMatchingAlgorithms_res getAvailableMatchingAlgorithms();
  bool setMatchingAlgorithm(QString matchingAlgorithm);
  QString getIndexReductionMethod();
  OMCInterface::getAvailableIndexReductionMethods_res getAvailableIndexReductionMethods();
  bool setIndexReductionMethod(QString method);
  QList<QString> getCommandLineOptions();
  bool setCommandLineOptions(QString options);
  bool clearCommandLineOptions();
  bool enableNewInstantiation();
  bool disableNewInstantiation();
  QString makeDocumentationUriToFileName(QString documentation);
  QString uriToFilename(QString uri);
  bool setModelicaPath(const QString &path);
  QString getModelicaPath();
  QString getHomeDirectoryPath();
  QStringList getAvailableLibraries();
  QStringList getAvailableLibraryVersions(QString libraryName);
  OMCInterface::convertUnits_res convertUnits(QString from, QString to);
  QList<QString> getDerivedUnits(QString baseUnit);
  QString getNamedAnnotation(const QString &className, const QString &annotation, StringHandler::ResultType type = StringHandler::String);
  QString getCommandLineOptionsAnnotation(QString className);
  QList<QString> getAnnotationNamedModifiers(QString className, QString annotation);
  QString getAnnotationModifierValue(QString className, QString annotation, QString modifier);
  QString getSimulationFlagsAnnotation(QString className);
  int numProcessors();
  QStringList getAllSubtypeOf(QString className, QString parentClassName = QString("AllLoadedClasses"), bool qualified = false, bool includePartial = false, bool sort = false);
  QString help(QString topic);
  OMCInterface::getConfigFlagValidOptions_res getConfigFlagValidOptions(QString topic);
  QString getCompiler();
  bool setCompiler(QString compiler);
  QString getCXXCompiler();
  bool setCXXCompiler(QString compiler);
  bool setDebugFlags(QString flags);
  bool exportToFigaro(QString className, QString directory, QString database, QString mode, QString options, QString processor);
  bool copyClass(QString className, QString newClassName, QString withIn);
  QStringList getEnumerationLiterals(QString className);
  void getSolverMethods(QStringList *methods, QStringList *descriptions);
  void getJacobianMethods(QStringList *methods, QStringList *descriptions);
  QString getJacobianFlagDetailedDescription();
  void getInitializationMethods(QStringList *methods, QStringList *descriptions);
  void getLinearSolvers(QStringList *methods, QStringList *descriptions);
  void getNonLinearSolvers(QStringList *methods, QStringList *descriptions);
  void getLogStreams(QStringList *names, QStringList *descriptions);
  bool moveClass(QString className, int offset);
  bool moveClassToTop(QString className);
  bool moveClassToBottom(QString className);
  bool inferBindings(QString className);
  bool generateVerificationScenarios(QString className);
  QList<QList<QString > > getUses(QString className);
  bool buildEncryptedPackage(QString className, bool encrypt = true);
  QList<QString> parseEncryptedPackage(QString fileName, QString workingDirectory);
  bool loadEncryptedPackage(QString fileName, QString workingDirectory, bool skipUnzip, bool uses = true, bool notify = true, bool requireExactVersion = false);
  bool installPackage(const QString &library, const QString &version, bool exactMatch);
  bool updatePackageIndex();
  bool upgradeInstalledPackages(bool installNewestVersions);
  QStringList getAvailablePackageVersions(QString pkg, QString version);
  bool convertPackageToLibrary(const QString &packageToConvert, const QString &library, const QString &libraryVersion);
  QList<QString> getAvailablePackageConversionsFrom(const QString &pkg, const QString &version);
  QJsonObject getModelInstance(const QString &className, const QString &modifier = QString(""), bool prettyPrint = false, bool icon = false);
  QJsonObject modifierToJSON(const QString &modifier, bool prettyPrint = false);
  int storeAST();
  bool restoreAST(int id);
  bool clear();
signals:
  void commandFinished();
public slots:
  void logCommand(QString command) { logCommand(command, false); }
  void logCommand(QString command, bool saveToHistory);
  void logResponse(QString command, QString response, double elapsed, bool customCommand = false);
  void showException(QString exception);
  void openOMCLoggerWidget();
  void sendCustomExpression();
  void openOMCDiffWidget();
};

class CustomExpressionBox : public QLineEdit
{
public:
  CustomExpressionBox(OMCProxy *pOMCProxy);
  OMCProxy *mpOMCProxy;
protected:
  virtual void keyPressEvent(QKeyEvent *event) override;
};

#endif // OMCPROXY_H
