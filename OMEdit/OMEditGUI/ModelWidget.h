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
/*
class NewProject : public QDialog
{
    Q_OBJECT
public:
    NewProject(MainWindow *parent = 0);
    ~NewProject();

    MainWindow *mpParentMainWindow;
private:
    QLabel *mpProjectNameLabel;
    QLabel *mpProjectPathLabel;
    QLineEdit *mpNameTextBox;
    QLineEdit *mpPathTextBox;
    QPushButton *mpBrowseButton;
    QPushButton *mpCancelButton;
    QPushButton *mpOkButton;
    QDialogButtonBox *mpButtonBox;
public slots:
    void createProject();
    void openFileDialog();
};
*/

class NewPackage : public QDialog
{
    Q_OBJECT
public:
    NewPackage(MainWindow *parent = 0);
    ~NewPackage();
    void show();

    MainWindow *mpParentMainWindow;
private:
    QLabel *mpPackageNameLabel;
    QLabel *mpParentPackageLabel;
    QLineEdit *mpPackageNameTextBox;
    QComboBox *mpParentPackageCombo;
    QPushButton *mpCancelButton;
    QPushButton *mpOkButton;
    QDialogButtonBox *mpButtonBox;
public slots:
    void createPackage();
};

class NewModel : public QDialog
{
    Q_OBJECT
public:
    NewModel(MainWindow *parent = 0);
    ~NewModel();
    void show();

    MainWindow *mpParentMainWindow;
private:
    QLabel *mpModelNameLabel;
    QLabel *mpParentPackageLabel;
    QLineEdit *mpModelNameTextBox;
    QComboBox *mpParentPackageCombo;
    QPushButton *mpCancelButton;
    QPushButton *mpOkButton;
    QDialogButtonBox *mpButtonBox;
public slots:
    void createModel();
};

class RenameClassWidget : public QDialog
{
    Q_OBJECT
public:
    RenameClassWidget(QString name, QString nameStructure, MainWindow *parent = 0);
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

#endif // MODELWIDGET_H
