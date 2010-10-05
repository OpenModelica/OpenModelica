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

class MainWindow;

class OMCProxy : public QObject
{
    Q_OBJECT
private:
    static OMCProxy *mpInstance;
    OmcCommunication_var mOMC;
    bool mHasInitialized;
    bool mIsStandardLibraryLoaded;
    QString mName;
    QString mResult;
    QDialog *mpOMCLogger;
    QTextEdit *mpTextEdit;
    QString mObjectRefFile;
public:
    OMCProxy(MainWindow *pParent = 0);
    ~OMCProxy();
    MainWindow *mpParentMainWindow;
    bool startServer();
    void stopServer();
    void sendCommand(const QString expression);
    QString evalCommand(const QString expression);
    void setResult(QString value);
    QString getResult();
    QStringList createPackagesList();
    void addPackage(QStringList *list, QString package, QString parentPackage = QString());
    void restartApplication();
    void removeObjectRefFile();
    QString getErrorString();
    void loadStandardLibrary();
    bool isStandardLibraryLoaded();
    QStringList getClassNames(QString className);
    QStringList getPackages(QString packageName);
    bool isPackage(QString className);
    bool isWhat(int type, QString className);
    QString getIconAnnotation(QString className);
    QString getDiagramAnnotation(QString className);
    int getInheritanceCount(QString className);
    QString getNthInheritedClass(QString className, int num);
    QList<ComponentsProperties*> getComponents(QString className);
    QStringList getComponentAnnotations(QString className);
    QString changeDirectory(QString directory);
    QString loadFile(QString fileName);
    bool createClass(QString type, QString className);
    bool createSubClass(QString type, QString className, QString parentClassName);
    bool createModel(QString modelName);
    bool newModel(QString modelName, QString parentModelName);
    bool existClass(QString className);
    QString getSourceFile(QString modelName);
    QString list(QString className);
    bool addComponent(QString name, QString className, QString modelName);
    bool deleteComponent(QString name, QString modelName);
    void renameComponent(QString oldName, QString className, QString newName);
    bool addConnection(QString from, QString to, QString className);
public slots:
    void openOMCLogger();
    void catchException();
};

#endif // OMCPROXY_H
