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

#ifndef ADDBUSDIALOG_H
#define ADDBUSDIALOG_H

#include <QDialog>
#include <QFrame>
#include <QLineEdit>
#include <QListWidget>
#include <QDialogButtonBox>

class Component;
class ConnectorItem : public QObject
{
  Q_OBJECT
public:
  ConnectorItem(Component *pComponent, ConnectorItem *pParent);
  Component* getComponent() {return mpComponent;}
  ConnectorItem* parent() const {return mpParentConnectorItem;}
  int childrenSize() const {return mChildren.size();}
  void insertChild(int row, ConnectorItem *pConnectorItem) {mChildren.insert(row, pConnectorItem);}
  ConnectorItem* child(int row) {return mChildren.value(row);}
  ConnectorItem* childAt(int index) const {return mChildren.at(index);}
  bool isChecked() const {return mChecked;}
  void setChecked(bool checked) {mChecked = checked;}
  int row() const;
  bool setData(int column, const QVariant &value, int role = Qt::EditRole);
  QVariant data(int column, int role = Qt::DisplayRole) const;
private:
  Component *mpComponent;
  ConnectorItem *mpParentConnectorItem;
  QList<ConnectorItem*> mChildren;
  bool mChecked;
};

class ConnectorsModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  ConnectorsModel(QObject *parent = 0);
  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  Qt::ItemFlags flags(const QModelIndex &index) const;
  QModelIndex connectorItemIndex(const ConnectorItem *pConnectorItem) const;
  ConnectorItem* getRootConnectorItem() {return mpRootConnectorItem;}
  ConnectorItem* createConnectorItem(Component *pComponent);
private:
  ConnectorItem *mpRootConnectorItem;
  QModelIndex connectorItemIndexHelper(const ConnectorItem *pConnectorItem, const ConnectorItem *pParentConnectorItem,
                                       const QModelIndex &parentIndex) const;
};

class GraphicsView;
class Label;
class AddBusDialog : public QDialog
{
  Q_OBJECT
public:
  AddBusDialog(QList<Component*> components, GraphicsView *pGraphicsView);
private:
  GraphicsView *mpGraphicsView;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpInputConnectorsLabel;
  ConnectorsModel *mpInputConnectorsTreeModel;
  QListView *mpInputConnectorsListView;
  Label *mpOutputConnectorsLabel;
  ConnectorsModel *mpOutputConnectorsTreeModel;
  QListView *mpOutputConnectorsListView;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void addBus();
};

#endif // ADDBUSDIALOG_H
