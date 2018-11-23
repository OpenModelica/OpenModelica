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

#ifndef MODELDIALOG_H
#define MODELDIALOG_H

#include <QWidget>
#include <QLineEdit>
#include <QComboBox>
#include <QDialog>
#include <QGroupBox>
#include <QDialogButtonBox>
#include <QScrollArea>

class LibraryTreeItem;
class Label;
class SystemWidget : public QWidget
{
  Q_OBJECT
public:
  SystemWidget(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
  QLineEdit* getNameTextBox() {return mpNameTextBox;}
  QComboBox* getTypeComboBox() {return mpTypeComboBox;}
private:
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpTypeLabel;
  QComboBox *mpTypeComboBox;
};

class CreateModelDialog : public QDialog
{
  Q_OBJECT
public:
  CreateModelDialog(QWidget *pParent = 0);
private:
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  QGroupBox *mpRootSystemGroupBox;
  SystemWidget *mpSystemWidget;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void createNewModel();
};

class GraphicsView;
class AddSystemDialog : public QDialog
{
  Q_OBJECT
public:
  AddSystemDialog(GraphicsView *pGraphicsView);
private:
  GraphicsView *mpGraphicsView;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  SystemWidget *mpSystemWidget;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void addSystem();
};

class AddSubModelDialog : public QDialog
{
  Q_OBJECT
public:
  AddSubModelDialog(GraphicsView *pGraphicsView);
private:
  GraphicsView *mpGraphicsView;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpPathLabel;
  QLineEdit *mpPathTextBox;
  QPushButton *mpBrowsePathButton;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void browseSubModelPath();
  void addSubModel();
};

class ShapeAnnotation;
class AddOrEditIconDialog : public QDialog
{
  Q_OBJECT
public:
  AddOrEditIconDialog(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView, QWidget *pParent = 0);
private:
  ShapeAnnotation *mpShapeAnnotation;
  GraphicsView *mpGraphicsView;
  Label *mpFileLabel;
  QLineEdit *mpFileTextBox;
  QPushButton *mpBrowseFileButton;
  QScrollArea *mpPreviewImageScrollArea;
  Label *mpPreviewImageLabel;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void browseImageFile();
  void addOrEditIcon();
};

class AddConnectorDialog : public QDialog
{
  Q_OBJECT
public:
  AddConnectorDialog(GraphicsView *pGraphicsView);
private:
  GraphicsView *mpGraphicsView;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpCausalityLabel;
  QComboBox *mpCausalityComboBox;
  Label *mpTypeLabel;
  QComboBox *mpTypeComboBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void addConnector();
};

#endif // MODELDIALOG_H
