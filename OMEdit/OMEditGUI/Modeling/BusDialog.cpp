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

#include "BusDialog.h"
#include "Util/Helper.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Component/Component.h"
#include "Modeling/ItemDelegate.h"
#include "Modeling/Commands.h"

#include <QMessageBox>

/*!
 * \class ConnectorItem
 * \brief Contains the information about the Connector component.
 */
/*!
 * \brief ConnectorItem::ConnectorItem
 * \param pComponent
 * \param pParent
 */
ConnectorItem::ConnectorItem(Component *pComponent, ConnectorItem *pParent)
{
  mpComponent = pComponent;
  mpParentConnectorItem = pParent;
  mChecked = false;
}

/*!
 * \brief ConnectorItem::row
 * Returns the row number corresponding to ConnectorItem.
 * \return
 */
int ConnectorItem::row() const
{
  if (mpParentConnectorItem) {
    return mpParentConnectorItem->mChildren.indexOf(const_cast<ConnectorItem*>(this));
  }

  return 0;
}

/*!
 * \brief ConnectorItem::setData
 * Updates the item data.
 * \param column
 * \param value
 * \param role
 * \return
 */
bool ConnectorItem::setData(int column, const QVariant &value, int role)
{
  if (column == 0 && role == Qt::CheckStateRole) {
    if (value.toInt() == Qt::Checked) {
      setChecked(true);
    } else if (value.toInt() == Qt::Unchecked) {
      setChecked(false);
    }
    return true;
  }
  return false;
}

/*!
 * \brief ConnectorItem::data
 * Returns the data stored under the given role for the item referred to by the column.
 * \param column
 * \param role
 * \return
 */
QVariant ConnectorItem::data(int column, int role) const
{
  switch (column) {
    case 0:
      switch (role) {
        case Qt::DisplayRole:
          return mpComponent->getLibraryTreeItem() ? mpComponent->getLibraryTreeItem()->getNameStructure() : "";
        case Qt::ToolTipRole:
          return mpComponent->getLibraryTreeItem() ? mpComponent->getLibraryTreeItem()->getNameStructure() : "";
        case Qt::CheckStateRole:
          return isChecked() ? Qt::Checked : Qt::Unchecked;
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

/*!
 * \class ConnectorsModel
 * \brief A model for Connector components.
 */
/*!
 * \brief ConnectorsModel::ConnectorsModel
 * \param parent
 */
ConnectorsModel::ConnectorsModel(QObject *parent)
  : QAbstractItemModel(parent)
{
  mpRootConnectorItem = new ConnectorItem(0, 0);
}

/*!
 * \brief ConnectorsModel::columnCount
 * Returns the number of columns for the children of the given parent.
 * \param parent
 * \return
 */
int ConnectorsModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 1;
}

/*!
 * \brief ConnectorsModel::rowCount
 * Returns the number of rows under the given parent.
 * When the parent is valid it means that rowCount is returning the number of children of parent.
 * \param parent
 * \return
 */
int ConnectorsModel::rowCount(const QModelIndex &parent) const
{
  ConnectorItem *pParentConnectorItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentConnectorItem = mpRootConnectorItem;
  } else {
    pParentConnectorItem = static_cast<ConnectorItem*>(parent.internalPointer());
  }
  return pParentConnectorItem->childrenSize();
}

/*!
 * \brief ConnectorsModel::headerData
 * Returns the data for the given role and section in the header with the specified orientation.
 * \param section
 * \param orientation
 * \param role
 * \return
 */
QVariant ConnectorsModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  Q_UNUSED(section);
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
    return Helper::libraries;
  }
  return QVariant();
}

/*!
 * \brief ConnectorsModel::index
 * Returns the index of the item in the model specified by the given row, column and parent index.
 * \param row
 * \param column
 * \param parent
 * \return
 */
QModelIndex ConnectorsModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  ConnectorItem *pParentConnectorItem;
  if (!parent.isValid()) {
    pParentConnectorItem = mpRootConnectorItem;
  } else {
    pParentConnectorItem = static_cast<ConnectorItem*>(parent.internalPointer());
  }

  ConnectorItem *pChildConnectorItem = pParentConnectorItem->child(row);
  if (pChildConnectorItem) {
    return createIndex(row, column, pChildConnectorItem);
  } else {
    return QModelIndex();
  }
}

/*!
 * \brief ConnectorsModel::parent
 * Finds the parent for QModelIndex
 * \param index
 * \return
 */
QModelIndex ConnectorsModel::parent(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return QModelIndex();
  }

  ConnectorItem *pChildConnectorItem = static_cast<ConnectorItem*>(index.internalPointer());
  ConnectorItem *pParentConnectorItem = pChildConnectorItem->parent();
  if (pParentConnectorItem == mpRootConnectorItem)
    return QModelIndex();

  return createIndex(pParentConnectorItem->row(), 0, pParentConnectorItem);
}

/*!
 * \brief ConnectorsModel::setData
 * Updates the model data.
 * \param index
 * \param value
 * \param role
 * \return
 */
bool ConnectorsModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
  ConnectorItem *pConnectorItem = static_cast<ConnectorItem*>(index.internalPointer());
  if (!pConnectorItem) {
    return false;
  }
  bool result = pConnectorItem->setData(index.column(), value, role);
  emit dataChanged(index, index);
  return result;
}

/*!
 * \brief ConnectorsModel::data
 * Returns the ConnectorItem data.
 * \param index
 * \param role
 * \return
 */
QVariant ConnectorsModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }

  ConnectorItem *pConnectorItem = static_cast<ConnectorItem*>(index.internalPointer());
  return pConnectorItem->data(index.column(), role);
}

/*!
 * \brief ConnectorsModel::flags
 * Returns the ConnectorItem flags.
 * \param index
 * \return
 */
Qt::ItemFlags ConnectorsModel::flags(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return Qt::ItemIsEnabled;
  } else {
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsUserCheckable;
  }
}

/*!
 * \brief ConnectorsModel::connectorItemIndex
 * Finds the QModelIndex attached to ConnectorItem.
 * \param pConnectorItem
 * \return
 */
QModelIndex ConnectorsModel::connectorItemIndex(const ConnectorItem *pConnectorItem) const
{
  return connectorItemIndexHelper(pConnectorItem, mpRootConnectorItem, QModelIndex());
}

/*!
 * \brief ConnectorsModel::createConnectorItem
 * Creates the ConnectorItem and returns it.
 * \param pComponent
 * \return
 */
ConnectorItem* ConnectorsModel::createConnectorItem(Component *pComponent)
{
  int row = mpRootConnectorItem->childrenSize();
  beginInsertRows(connectorItemIndex(mpRootConnectorItem), row, row);
  ConnectorItem *pConnectorItem = new ConnectorItem(pComponent, mpRootConnectorItem);
  mpRootConnectorItem->insertChild(row, pConnectorItem);
  endInsertRows();
  return pConnectorItem;
}

/*!
 * \brief ConnectorsModel::connectorItemIndexHelper
 * Helper function for ConnectorsModel::connectorItemIndex()
 * \param pConnectorItem
 * \param pParentConnectorItem
 * \param parentIndex
 * \return
 */
QModelIndex ConnectorsModel::connectorItemIndexHelper(const ConnectorItem *pConnectorItem,
                                                      const ConnectorItem *pParentConnectorItem, const QModelIndex &parentIndex) const
{
  if (pConnectorItem == pParentConnectorItem) {
    return parentIndex;
  }
  for (int i = pParentConnectorItem->childrenSize(); --i >= 0; ) {
    const ConnectorItem *childItem = pParentConnectorItem->childAt(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = connectorItemIndexHelper(pConnectorItem, childItem, childIndex);
    if (index.isValid()) {
      return index;
    }
  }
  return QModelIndex();
}

/*!
 * \class AddBusDialog
 * \brief A dialog for creating a bus.
 */
/*!
 * \brief AddBusDialog::AddBusDialog
 * \param components
 * \param pGraphicsView
 */
AddBusDialog::AddBusDialog(QList<Component *> components, GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::addBus));
  setMinimumWidth(400);
  mpGraphicsView = pGraphicsView;
  // set heading
  mpHeading = Utilities::getHeadingLabel(Helper::addBus);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // input connectors
  mpInputConnectorsLabel = new Label(tr("Input Connectors"));
  mpInputConnectorsTreeModel = new ConnectorsModel(this);
  mpInputConnectorsListView = new QListView;
  mpInputConnectorsListView->setModel(mpInputConnectorsTreeModel);
  mpInputConnectorsListView->setItemDelegate(new ItemDelegate(mpInputConnectorsListView));
  mpInputConnectorsListView->setTextElideMode(Qt::ElideMiddle);
  // output connectors
  mpOutputConnectorsLabel = new Label(tr("Output Connectors"));
  mpOutputConnectorsTreeModel = new ConnectorsModel(this);
  mpOutputConnectorsListView = new QListView;
  mpOutputConnectorsListView->setModel(mpOutputConnectorsTreeModel);
  mpOutputConnectorsListView->setItemDelegate(new ItemDelegate(mpOutputConnectorsListView));
  mpOutputConnectorsListView->setTextElideMode(Qt::ElideMiddle);
  // add the connectors to input and output connectors list views
  foreach (Component* pComponent, mpGraphicsView->getComponentsList()) {
    if (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getOMSConnector()) {
      ConnectorItem *pConnectorItem = 0;
      if (pComponent->getLibraryTreeItem()->getOMSConnector()->causality == oms_causality_input) {
        pConnectorItem = mpInputConnectorsTreeModel->createConnectorItem(pComponent);
      } else if (pComponent->getLibraryTreeItem()->getOMSConnector()->causality == oms_causality_output) {
        pConnectorItem = mpOutputConnectorsTreeModel->createConnectorItem(pComponent);
      }
      if (pConnectorItem && components.contains(pConnectorItem->getComponent())) {
        pConnectorItem->setChecked(true);
        components.removeOne(pComponent);
      }
    }
  }
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addBus()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpNameLabel, 2, 0);
  pMainLayout->addWidget(mpNameTextBox, 2, 1);
  pMainLayout->addWidget(mpInputConnectorsLabel, 3, 0, 1, 2);
  pMainLayout->addWidget(mpInputConnectorsListView, 4, 0, 1, 2);
  pMainLayout->addWidget(mpOutputConnectorsLabel, 5, 0, 1, 2);
  pMainLayout->addWidget(mpOutputConnectorsListView, 6, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 7, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief AddBusDialog::addBus
 * Adds the bus by calling AddBusCommand
 */
void AddBusDialog::addBus()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("Bus")), Helper::ok);
    return;
  }

  QList<Component*> components;
  bool inputConnectorChecked = false;
  for (int i = 0 ; i < mpInputConnectorsTreeModel->getRootConnectorItem()->childrenSize() ; i++) {
    ConnectorItem *pConnectorItem = mpInputConnectorsTreeModel->getRootConnectorItem()->child(i);
    if (pConnectorItem && pConnectorItem->isChecked()) {
      inputConnectorChecked = true;
      components.append(pConnectorItem->getComponent());
    }
  }

  bool outputConnectorChecked = false;
  for (int i = 0 ; i < mpOutputConnectorsTreeModel->getRootConnectorItem()->childrenSize() ; i++) {
    ConnectorItem *pConnectorItem = mpOutputConnectorsTreeModel->getRootConnectorItem()->child(i);
    if (pConnectorItem && pConnectorItem->isChecked()) {
      outputConnectorChecked = true;
      components.append(pConnectorItem->getComponent());
    }
  }

  if (inputConnectorChecked && outputConnectorChecked) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("You can't select both input and output connectors for the bus."), Helper::ok);
    return;
  }

  mpGraphicsView->getModelWidget()->beginMacro("Add Bus");
  QString annotation = QString("Placement(true,%1,%2,-10.0,-10.0,10.0,10.0,0,%1,%2,-10.0,-10.0,10.0,10.0,)")
                       .arg(Utilities::mapToCoOrdinateSystem(0.5, 0, 1, -100, 100))
                       .arg(Utilities::mapToCoOrdinateSystem(0.5, 0, 1, -100, 100));
  AddBusCommand *pAddBusCommand = new AddBusCommand(mpNameTextBox->text(), 0, annotation, mpGraphicsView, false);
  mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddBusCommand);
  // add connectors to the bus
  LibraryTreeItem *pParentLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  QString bus = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mpNameTextBox->text());
  foreach (Component *pComponent, components) {
    if (pComponent->getLibraryTreeItem()) {
      AddConnectorToBusCommand *pAddConnectorToBusCommand = new AddConnectorToBusCommand(bus, pComponent->getLibraryTreeItem()->getNameStructure());
      mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddConnectorToBusCommand);
    }
  }
  mpGraphicsView->getModelWidget()->updateModelText();
  mpGraphicsView->getModelWidget()->endMacro();
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  accept();
}

/*!
 * \class AddTLMBusDialog
 * \brief A dialog for creating a tlm bus.
 */
/*!
 * \brief AddTLMBusDialog::AddTLMBusDialog
 * \param pGraphicsView
 */
AddTLMBusDialog::AddTLMBusDialog(GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::addTLMBus));
  setMinimumWidth(400);
  mpGraphicsView = pGraphicsView;
  // set heading
  mpHeading = Utilities::getHeadingLabel(Helper::addTLMBus);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // domain
  mpDomainLabel = new Label(tr("Domain:"));
  mpDomainTextBox = new QLineEdit;
  // dimension
  mpDimensionLabel = new Label(tr("Dimension:"));
  mpDimensionSpinBox = new QSpinBox;
  mpDimensionSpinBox->setRange(1, 3);
  // interpolation
  mpInterpolationLabel = new Label(tr("Interpolation:"));
  mpInterpolationComboBox = new QComboBox;
  mpInterpolationComboBox->addItem("No interpolation", oms_tlm_no_interpolation);
  mpInterpolationComboBox->addItem("Coarse grained", oms_tlm_coarse_grained);
  mpInterpolationComboBox->addItem("Fine grained", oms_tlm_fine_grained);
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addTLMBus()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpNameLabel, 2, 0);
  pMainLayout->addWidget(mpNameTextBox, 2, 1);
  pMainLayout->addWidget(mpDomainLabel, 3, 0);
  pMainLayout->addWidget(mpDomainTextBox, 3, 1);
  pMainLayout->addWidget(mpDimensionLabel, 4, 0);
  pMainLayout->addWidget(mpDimensionSpinBox, 4, 1);
  pMainLayout->addWidget(mpInterpolationLabel, 5, 0);
  pMainLayout->addWidget(mpInterpolationComboBox, 5, 1);
  pMainLayout->addWidget(mpButtonBox, 6, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief AddTLMBusDialog::addTLMBus
 * Adds the tlm bus by calling AddTLMBusCommand
 */
void AddTLMBusDialog::addTLMBus()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("TLM Bus")), Helper::ok);
    return;
  }

  if (mpDomainTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("domain")), Helper::ok);
    return;
  }

  QString annotation = QString("Placement(true,%1,%2,-10.0,-10.0,10.0,10.0,0,%1,%2,-10.0,-10.0,10.0,10.0,)")
                       .arg(Utilities::mapToCoOrdinateSystem(0.5, 0, 1, -100, 100))
                       .arg(Utilities::mapToCoOrdinateSystem(0.5, 0, 1, -100, 100));
  AddTLMBusCommand *pAddBusCommand = new AddTLMBusCommand(mpNameTextBox->text(), 0, annotation, mpGraphicsView, false, mpDomainTextBox->text(),
                                                          mpDimensionSpinBox->value(),
                                                          (oms_tlm_interpolation_t)mpInterpolationComboBox->itemData(mpInterpolationComboBox->currentIndex()).toInt());
  mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddBusCommand);
  mpGraphicsView->getModelWidget()->updateModelText();
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  accept();
}
