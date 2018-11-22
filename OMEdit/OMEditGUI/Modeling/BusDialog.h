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

#include "OMSimulator.h"

#include <QDialog>
#include <QFrame>
#include <QLineEdit>
#include <QTreeView>
#include <QDialogButtonBox>
#include <QSpinBox>
#include <QComboBox>
#include <QTableView>

class Component;
class ConnectorItem : public QObject
{
  Q_OBJECT
public:
  ConnectorItem(Component *pComponent, ConnectorItem *pParent);
  QString getText() const {return mText;}
  void setText(const QString &text) {mText = text;}
  Component* getComponent() {return mpComponent;}
  QString getTLMType() const {return mTLMType;}
  void setTLMType(const QString &tlmType) {mTLMType = tlmType;}
  QString getTLMTypeDescription() const {return mTLMTypeDescription;}
  void setTLMTypeDescription(const QString &tlmTypeDescription) {mTLMTypeDescription = tlmTypeDescription;}
  ConnectorItem* parent() const {return mpParentConnectorItem;}
  int childrenSize() const {return mChildren.size();}
  void insertChild(int row, ConnectorItem *pConnectorItem) {mChildren.insert(row, pConnectorItem);}
  ConnectorItem* child(int row) {return mChildren.value(row);}
  ConnectorItem* childAt(int index) const {return mChildren.at(index);}
  Qt::CheckState checkState() const;
  bool isChecked() const {return mChecked;}
  void setChecked(bool checked) {mChecked = checked;}
  int row() const;
private:
  QString mText;
  Component *mpComponent;
  QString mTLMType;
  QString mTLMTypeDescription;
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
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  Qt::ItemFlags flags(const QModelIndex &index) const;
  QModelIndex connectorItemIndex(const ConnectorItem *pConnectorItem, const int column = 0) const;
  ConnectorItem* createConnectorItem(Component *pComponent, ConnectorItem *pParent);

  ConnectorItem* getRootConnectorItem() {return mpRootConnectorItem;}
  void setColumnCount(int columnCount) {mColumnCount = columnCount;}
  QStringList getTLMTypes() const {return mTLMTypes;}
  void setTLMTypes(const QStringList &tlmTypes) {mTLMTypes = tlmTypes;}
  QStringList getTLMTypesDescriptions() const {return mTLMTypesDescriptions;}
  void setTLMTypesDescriptions(const QStringList &tlmTypesDescriptions) {mTLMTypesDescriptions = tlmTypesDescriptions;}

private:
  ConnectorItem *mpRootConnectorItem;
  int mColumnCount;
  QStringList mTLMTypes;
  QStringList mTLMTypesDescriptions;
  QModelIndex connectorItemIndexHelper(const ConnectorItem *pConnectorItem, const int column, const ConnectorItem *pParentConnectorItem,
                                       const QModelIndex &parentIndex) const;
};

class ConnectorsTreeView : public QTreeView
{
  Q_OBJECT
public:
  ConnectorsTreeView(QWidget *pParent = 0);
};

class LibraryTreeItem;
class GraphicsView;
class Label;
class AddBusDialog : public QDialog
{
  Q_OBJECT
public:
  AddBusDialog(QList<Component*> components, LibraryTreeItem *pLibraryTreeItem, GraphicsView *pGraphicsView);
private:
  LibraryTreeItem *mpLibraryTreeItem;
  GraphicsView *mpGraphicsView;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  ConnectorsModel *mpInputConnectorsTreeModel;
  ConnectorsTreeView *mpInputConnectorsTreeView;
  ConnectorsModel *mpOutputConnectorsTreeModel;
  ConnectorsTreeView *mpOutputConnectorsTreeView;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  void markExistingBusConnectors(ConnectorItem *pParentConnectorItem, QList<Component*> components);
private slots:
  void addBus();
};

class AddTLMBusDialog : public QDialog
{
  Q_OBJECT
public:
  AddTLMBusDialog(QList<Component*> components, LibraryTreeItem *pLibraryTreeItem, GraphicsView *pGraphicsView);
private:
  LibraryTreeItem *mpLibraryTreeItem;
  GraphicsView *mpGraphicsView;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpDomainLabel;
  QComboBox *mpDomainComboBox;
  Label *mpDimensionLabel;
  QSpinBox *mpDimensionSpinBox;
  Label *mpInterpolationLabel;
  QComboBox *mpInterpolationComboBox;
  ConnectorsModel *mpInputConnectorsTreeModel;
  ConnectorsTreeView *mpInputConnectorsTreeView;
  ConnectorsModel *mpOutputConnectorsTreeModel;
  ConnectorsTreeView *mpOutputConnectorsTreeView;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  void markExistingTLMBusConnectors(ConnectorItem *pParentConnectorItem, QList<Component*> components);
private slots:
  void fetchTLMTypes();
  void addTLMBus();
};

class LineAnnotation;
class ConnectionItem : public QObject
{
  Q_OBJECT
public:
  ConnectionItem(QString start, QString end, bool checked, ConnectionItem *pParent);
  QString getStart() const {return mStart;}
  void setStart(const QString &start) {mStart = start;}
  QString getInitialStart() const {return mInitialStart;}
  QString getEnd() const {return mEnd;}
  void setEnd(const QString &end) {mEnd = end;}
  QString getInitialEnd() const {return mInitialEnd;}
  ConnectionItem* parent() const {return mpParentConnectionItem;}
  int childrenSize() const {return mChildren.size();}
  void insertChild(int row, ConnectionItem *pConnectionItem) {mChildren.insert(row, pConnectionItem);}
  ConnectionItem* child(int row) {return mChildren.value(row);}
  ConnectionItem* childAt(int index) const {return mChildren.at(index);}
  bool isChecked() const {return mChecked;}
  void setChecked(bool checked) {mChecked = checked;}
  bool isExisting() const {return mExisting;}
  void setExisting(bool existing) {mExisting = existing;}
  int row() const;
private:
  QString mStart;
  QString mInitialStart;
  QString mEnd;
  QString mInitialEnd;
  ConnectionItem *mpParentConnectionItem;
  QList<ConnectionItem*> mChildren;
  bool mChecked;
  bool mExisting;
};

class ConnectionsModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  ConnectionsModel(LineAnnotation *pConnectionLineAnnotation, QObject *parent = 0);

  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  QStringList mimeTypes() const;
  QMimeData* mimeData(const QModelIndexList &indexes) const;
  bool canDropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent) const;
  bool dropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent);
  Qt::DropActions supportedDropActions() const;
  Qt::ItemFlags flags(const QModelIndex &index) const;
  QModelIndex connectionItemIndex(const ConnectionItem *pConnectionItem) const;

  ConnectionItem* getRootConnectionItem() {return mpRootConnectionItem;}
  void setHeaderLabels(const QStringList &headerLabels) {mHeaderLabels = headerLabels;}

  ConnectionItem* createConnectionItem(QString start, QString end, bool checked, ConnectionItem *pParent);
private:
  LineAnnotation *mpConnectionLineAnnotation;
  ConnectionItem *mpRootConnectionItem;
  QStringList mHeaderLabels;
  QModelIndex connectionItemIndexHelper(const ConnectionItem *pConnectionItem, const ConnectionItem *pParentConnectionItem,
                                        const QModelIndex &parentIndex) const;
};

class BusConnectionDialog : public QDialog
{
  Q_OBJECT
public:
  BusConnectionDialog(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, bool addCase = true);
private:
  GraphicsView *mpGraphicsView;
  LineAnnotation *mpConnectionLineAnnotation;
  bool mAddCase;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  ConnectionsModel *mpInputOutputConnectionsModel;
  QTableView *mpInputOutputConnectionsTableView;
  ConnectionsModel *mpOutputInputConnectionsModel;
  QTableView *mpOutputInputConnectionsTableView;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  void addOrDeleteAtomicConnections(ConnectionsModel *pConnectionsModel);
  void deleteAtomicConnection(QString startConnectorName, QString endConnectorName);
  void addAtomicConnection(QString startConnectorName, QString endConnectorName);

private slots:
  void addBusConnection();
};

class TLMConnectionDialog : public QDialog
{
  Q_OBJECT
public:
  TLMConnectionDialog(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, bool addCase = true);
private:
  GraphicsView *mpGraphicsView;
  LineAnnotation *mpConnectionLineAnnotation;
  bool mAddCase;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpDelayLabel;
  QLineEdit *mpDelayTextBox;
  Label *mpAlphaLabel;
  QLineEdit *mpAlphaTextBox;
  Label *mpLinearImpedanceLabel;
  QLineEdit *mpLinearImpedanceTextBox;
  Label *mpAngularImpedanceLabel;
  QLineEdit *mpAngularImpedanceTextBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void addTLMConnection();
};

#endif // ADDBUSDIALOG_H
