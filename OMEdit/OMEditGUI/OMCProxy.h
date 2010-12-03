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

#ifndef OMCPROXY_H
#define OMCPROXY_H

#include <QtCore>
#include <QtGui>

#include "mainwindow.h"
#include "omc_communication.h"
#include "ComponentsProperties.h"
#include "IconParameters.h"

class MainWindow;
class CustomExpressionBox;

class OMCProxy : public QObject
{
    Q_OBJECT
private:
    OmcCommunication_var mOMC;
    bool mHasInitialized;
    bool mIsStandardLibraryLoaded;
    QString mName;
    QString mResult;
    bool mDisplayErrors;
    QDialog *mpOMCLogger;
    CustomExpressionBox *mpExpressionTextBox;
    QPushButton *mpSendButton;
    QTextEdit *mpTextEdit;
    QString mObjectRefFile;
    QList<QString> mCommandsList;
    QMap<QString, QString> mCommandsMap;
public:
    OMCProxy(MainWindow *pParent = 0, bool displayErrors = true);
    ~OMCProxy();
    void getPreviousCommand();
    void getNextCommand();
    void addCommandMap(QString expression, QString result);
    QString getCommandMap(QString expression);

    MainWindow *mpParentMainWindow;
    enum mModelicaAnnotationVersion {ANNOTATION_VERSION2X, ANNOTATION_VERSION3X};
    int mAnnotationVersion;

    bool startServer();
    void stopServer();
    void sendCommand(const QString expression);
    void setResult(QString value);
    QString getResult();
    void logOMCMessages(QString expression);
    QStringList createPackagesList();
    void addPackage(QStringList *list, QString package, QString parentPackage = QString());
    void restartApplication();
    void removeObjectRefFile();
    QString getErrorString();
    QString getVersion();
    bool setAnnotationVersion(int version);
    QString getAnnotationVersion();
    bool setEnvironmentVar(QString name, QString value);
    QString getEnvironmentVar(QString name);
    void loadStandardLibrary();
    bool isStandardLibraryLoaded();
    QStringList getClassNames(QString className = QString());
    QStringList getPackages(QString packageName);
    bool isPackage(QString className);
    bool isWhat(int type, QString className);
    int getClassRestriction(QString modelName);
    QList<IconParameters*> getParameters(QString className);
    QStringList getParameterNames(QString className);
    QString getParameterValue(QString className, QString parameter);
    bool setParameterValue(QString className, QString parameter, QString value);
    QString getIconAnnotation(QString className);
    QString getDiagramAnnotation(QString className);
    int getConnectionCount(QString className);
    QString getNthConnection(QString className, int num);
    QString getNthConnectionAnnotation(QString className, int num);
    int getInheritanceCount(QString className);
    QString getNthInheritedClass(QString className, int num);
    QList<ComponentsProperties*> getComponents(QString className);
    QStringList getComponentAnnotations(QString className);
    QString getDocumentationAnnotation(QString className);
    QString changeDirectory(QString directory);
    bool loadFile(QString fileName);
    bool createClass(QString type, QString className);
    bool createSubClass(QString type, QString className, QString parentClassName);
    bool updateSubClass(QString parentClassName, QString modelText);
    bool createModel(QString modelName);
    bool newModel(QString modelName, QString parentModelName);
    bool existClass(QString className);
    bool renameClass(QString oldName, QString newName);
    bool deleteClass(QString className);
    QString getSourceFile(QString modelName);
    bool setSourceFile(QString modelName, QString path);
    bool save(QString modelName);
    bool saveModifiedModel(QString modelText);
    QString list(QString className);
    bool addClassAnnotation(QString className, QString annotation);
    bool addComponent(QString name, QString className, QString modelName);
    bool deleteComponent(QString name, QString modelName);
    bool renameComponent(QString modelName, QString oldName, QString newName);
    bool updateComponent(QString name, QString className, QString modelName, QString annotation);
    bool renameComponentInClass(QString modelName, QString oldName, QString newName);
    bool updateConnection(QString from, QString to, QString modelName, QString annotation);
    bool setComponentProperties(QString modelName, QString componentName, QString isFinal, QString isFlow,
                                QString isProtected, QString isReplaceAble, QString variability, QString isInner,
                                QString isOuter, QString causality);
    bool setComponentComment(QString modelName, QString componentName, QString comment);
    bool addConnection(QString from, QString to, QString className);
    bool deleteConnection(QString from, QString to, QString className);
    bool instantiateModel(QString modelName);
    bool simulate(QString modelName, QString simualtionParameters);
    bool plot(QString modelName, QString plotVariables);
    bool plotParametric(QString modelName, QString plotVariables);
    bool visualize(QString modelName);
    QString checkModel(QString modelName);
public slots:
    void openOMCLogger();
    void catchException();
    void sendCustomExpression();
};

class CustomExpressionBox : public QLineEdit
{
public:
    CustomExpressionBox(OMCProxy *pParent);

    OMCProxy *mpParentOMCProxy;
protected:
    virtual void keyPressEvent(QKeyEvent *event);
};

#endif // OMCPROXY_H
