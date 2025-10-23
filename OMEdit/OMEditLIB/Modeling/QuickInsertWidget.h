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
 * @author Quentin Huss <quentinhuss@hotmail.com>
 */

#pragma once

#include <QApplication>
#include <QPainter>
#include <QStyledItemDelegate>

class ModelItemDelegate : public QStyledItemDelegate
{
  Q_OBJECT
public:
  explicit ModelItemDelegate(QObject *parent = nullptr);

  //! Overrides the paint method to draw the item.
  void paint(QPainter *painter, const QStyleOptionViewItem &option,
             const QModelIndex &index) const override;

  //! Overrides the sizeHint method to provide the correct item size.
  QSize sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const override;
};

#include <QKeyEvent>
#include <QListView>
#include <QLineEdit>
#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QWidget>

class LibraryTreeModel;
class QCheckBox;

class ClassNameFilterProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  explicit ClassNameFilterProxyModel(QObject *parent = nullptr);
  void setFilterString(const QString &pattern);
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

public slots:
  void setHideExamples(bool hide);

protected:
  bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
  bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;
  Qt::ItemFlags flags(const QModelIndex &index) const override;

private:
  QString mFuzzyPattern;
  bool mHideExamples = true;
};

class QuickInsertWidget : public QWidget
{
  Q_OBJECT

public:
  explicit QuickInsertWidget(LibraryTreeModel *model, QWidget *parent = nullptr);
  void showAt(const QPoint &pos);
  QString getSelectedClass() const;

signals:
  void classSelected(const QString &className);

protected:
  void keyPressEvent(QKeyEvent *event) override;
  bool eventFilter(QObject *watched, QEvent *event) override;

private slots:
  void onSearchTextChanged(const QString &text);
  void onListItemActivated(const QModelIndex &index);
  void onHideExamplesToggled(bool checked);

private:
  void populateModel();

  QLineEdit *mpSearchLineEdit;
  QListView *mpResultsListView;
  QStandardItemModel *mpSourceModel;
  ClassNameFilterProxyModel *mpProxyModel;
  LibraryTreeModel *mpLibraryTreeModel;
  QString mSelectedClass;
  QCheckBox *mpHideExamplesCheckBox;
};