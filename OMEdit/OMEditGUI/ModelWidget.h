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

#ifndef MODELWIDGET_H
#define MODELWIDGET_H

#include <QLineEdit>
#include <QLabel>
#include <QComboBox>

#include "mainwindow.h"

class MainWindow;

class ModelCreator : public QDialog
{
    Q_OBJECT
public:
    ModelCreator(MainWindow *parent);
    ~ModelCreator();
    void show(int type);

    MainWindow *mpParentMainWindow;
private:
    int mType;
    QLabel *mpNameLabel;
    QLineEdit *mpNameTextBox;
    QLabel *mpParentPackageLabel;
    QComboBox *mpParentPackageCombo;
    QPushButton *mpCancelButton;
    QPushButton *mpOkButton;
    QDialogButtonBox *mpButtonBox;
public slots:
    void create();
};

class RenameClassWidget : public QDialog
{
    Q_OBJECT
public:
    RenameClassWidget(QString name, QString nameStructure, MainWindow *parent);
    ~RenameClassWidget();

    MainWindow *mpParentMainWindow;
private:
    QString mName;
    QString mNameStructure;
    QLabel *mpModelNameLabel;
    QLineEdit *mpModelNameTextBox;
    QPushButton *mpCancelButton;
    QPushButton *mpOkButton;
    QDialogButtonBox *mpButtonBox;
public slots:
    void renameClass();
};

class CheckModelWidget : public QDialog
{
    Q_OBJECT
public:
    CheckModelWidget(QString name, QString nameStructure, MainWindow *pParent);

    MainWindow *mpParentMainWindow;
private:
    QString mName;
    QString mNameStructure;
    QTextEdit *mpCheckResultLabel;
    QPushButton *mpOkButton;
};


class FlatModelWidget : public QDialog
{
    Q_OBJECT
public:
    FlatModelWidget(QString name, QString nameStructure, MainWindow *pParent);

    MainWindow *mpParentMainWindow;
private:
    QString mName;
    QString mNameStructure;
    QTextEdit *mpText;
    QPushButton *mpOkButton;
};

#endif // MODELWIDGET_H
