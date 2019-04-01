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
  mText = "";
  mpComponent = pComponent;
  mTLMType = "";
  mTLMTypeDescription = "";
  mpParentConnectorItem = pParent;
  mChecked = false;
}

Qt::CheckState ConnectorItem::checkState() const
{
  if (mpComponent) {
    return isChecked() ? Qt::Checked : Qt::Unchecked;
  } else {
    if (mChildren.isEmpty()) {
      return Qt::Unchecked;
    }
    Qt::CheckState state = mChildren.first()->checkState();
    foreach (ConnectorItem *pConnectorItem, mChildren) {
      Qt::CheckState connectorState = pConnectorItem->checkState();
      if (connectorState != state) {
        return Qt::PartiallyChecked;
      }
    }
    return state;
  }
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
  mColumnCount = 1;
  mTLMTypes.clear();
  mTLMTypesDescriptions.clear();
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
  return mColumnCount;
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
 * \brief ConnectorsModel::index
 * Returns the index of the item in the model specified by the given row, column and parent index.
 * \param row
 * \param column
 * \param parent
 * \return
 */
QModelIndex ConnectorsModel::index(int row, int column, const QModelIndex &parent) const
{
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

  if (index.column() == 0 && role == Qt::CheckStateRole) {
    if (pConnectorItem->getComponent()) {
      if (value.toInt() == Qt::Checked) {
        pConnectorItem->setChecked(true);
      } else if (value.toInt() == Qt::Unchecked) {
        pConnectorItem->setChecked(false);
      }
      emit dataChanged(index, index);
      const QModelIndex parentIndex = createIndex(pConnectorItem->parent()->row(), 0, pConnectorItem->parent());
      emit dataChanged(parentIndex, parentIndex);
    } else {
      for (int i = 0 ; i < pConnectorItem->childrenSize() ; i++) {
        ConnectorItem *pChildConnectorItem = pConnectorItem->childAt(i);
        QModelIndex childIndex = createIndex(pChildConnectorItem->row(), 0, pChildConnectorItem);
        setData(childIndex, value, role);
      }
    }
    return true;
  } else if (index.column() == 1 && role == Qt::EditRole) {
    pConnectorItem->setTLMType(value.toString());
    emit dataChanged(index, index);
    return true;
  }
  return QAbstractItemModel::setData(index, value, role);
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

  switch (index.column()) {
    case 0:
      switch (role) {
        case Qt::DisplayRole:
          if (pConnectorItem->getComponent()) {
            if (pConnectorItem->getComponent()->getLibraryTreeItem()) {
              return pConnectorItem->getComponent()->getLibraryTreeItem()->getName();
            } else {
              return "";
            }
          } else {
            return pConnectorItem->getText();
          }
        case Qt::ToolTipRole:
          if (pConnectorItem->getComponent()) {
            if (pConnectorItem->getComponent()->getLibraryTreeItem()) {
              return pConnectorItem->getComponent()->getLibraryTreeItem()->getNameStructure();
            } else {
              return "";
            }
          } else {
            return pConnectorItem->getText();
          }
        case Qt::CheckStateRole:
          return pConnectorItem->checkState();
        default:
          return QVariant();
      }
    case 1:
      switch (role) {
        case Qt::DisplayRole:
          if (pConnectorItem->getComponent()) {
            return pConnectorItem->getTLMType();
          } else {
            return QVariant();
          }
        case Qt::ToolTipRole:
          if (pConnectorItem->getComponent()) {
            return pConnectorItem->getTLMTypeDescription();
          } else {
            return QVariant();
          }
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
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
    return 0;
  } else {
    Qt::ItemFlags flags = Qt::ItemIsEnabled | Qt::ItemIsSelectable;
    ConnectorItem *pConnectorItem = static_cast<ConnectorItem*>(index.internalPointer());
    if (index.column() == 0) {
      if (!pConnectorItem->getComponent() && pConnectorItem->childrenSize() == 0) {
        return flags;
      } else {
        return flags | Qt::ItemIsUserCheckable;
      }
    } else if (index.column() == 1 && pConnectorItem->getComponent()) {
      return flags | Qt::ItemIsEditable;
    } else {
      return flags;
    }
  }
}

/*!
 * \brief ConnectorsModel::connectorItemIndex
 * Finds the QModelIndex attached to ConnectorItem.
 * \param pConnectorItem
 * \return
 */
QModelIndex ConnectorsModel::connectorItemIndex(const ConnectorItem *pConnectorItem, const int column) const
{
  return connectorItemIndexHelper(pConnectorItem, column, mpRootConnectorItem, QModelIndex());
}

/*!
 * \brief ConnectorsModel::createConnectorItem
 * Creates the ConnectorItem and returns it.
 * \param pComponent
 * \param pParent
 * \return
 */
ConnectorItem* ConnectorsModel::createConnectorItem(Component *pComponent, ConnectorItem *pParent)
{
  int row = pParent->childrenSize();
  beginInsertRows(connectorItemIndex(pParent), row, row);
  ConnectorItem *pConnectorItem = new ConnectorItem(pComponent, pParent);
  pParent->insertChild(row, pConnectorItem);
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
QModelIndex ConnectorsModel::connectorItemIndexHelper(const ConnectorItem *pConnectorItem, const int column,
                                                      const ConnectorItem *pParentConnectorItem, const QModelIndex &parentIndex) const
{
  if (pConnectorItem == pParentConnectorItem) {
    return parentIndex;
  }
  for (int i = pParentConnectorItem->childrenSize(); --i >= 0; ) {
    const ConnectorItem *childItem = pParentConnectorItem->childAt(i);
    QModelIndex childIndex = index(i, column, parentIndex);
    QModelIndex index = connectorItemIndexHelper(pConnectorItem, column, childItem, childIndex);
    if (index.isValid()) {
      return index;
    }
  }
  return QModelIndex();
}

/*!
 * \class ConnectorsTreeView
 * \brief A treeview for connectors.
  */
/*!
 * \brief ConnectorsTreeView::ConnectorsTreeView
 * \param pParent
 */
ConnectorsTreeView::ConnectorsTreeView(QWidget *pParent)
  : QTreeView(pParent)
{
  setItemDelegate(new ItemDelegate(this));
  setHeaderHidden(true);
  setIndentation(Helper::treeIndentation);
  setTextElideMode(Qt::ElideMiddle);
  setUniformRowHeights(true);
}

/*!
 * \class AddBusDialog
 * \brief A dialog for creating a bus.
 */
/*!
 * \brief AddBusDialog::AddBusDialog
 * \param components
 * \param pLibraryTreeItem
 * \param pGraphicsView
 */
AddBusDialog::AddBusDialog(QList<Component *> components, LibraryTreeItem *pLibraryTreeItem, GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(pLibraryTreeItem ? Helper::editBus : Helper::addBus));
  setMinimumWidth(400);
  mpLibraryTreeItem = pLibraryTreeItem;
  mpGraphicsView = pGraphicsView;
  // set heading
  mpHeading = mpLibraryTreeItem ? Utilities::getHeadingLabel(Helper::editBus) : Utilities::getHeadingLabel(Helper::addBus);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(mpLibraryTreeItem ? mpLibraryTreeItem->getName() : "");
  // input connectors
  mpInputConnectorsTreeModel = new ConnectorsModel(this);
  mpInputConnectorsTreeView = new ConnectorsTreeView;
  mpInputConnectorsTreeView->setModel(mpInputConnectorsTreeModel);
  // inputs item
  ConnectorItem *pInputsConnectorItem = mpInputConnectorsTreeModel->createConnectorItem(0, mpInputConnectorsTreeModel->getRootConnectorItem());
  pInputsConnectorItem->setText("Input Connectors");
  // output connectors
  mpOutputConnectorsTreeModel = new ConnectorsModel(this);
  mpOutputConnectorsTreeView = new ConnectorsTreeView;
  mpOutputConnectorsTreeView->setModel(mpOutputConnectorsTreeModel);
  // outputs item
  ConnectorItem *pOutputsConnectorItem = mpInputConnectorsTreeModel->createConnectorItem(0, mpOutputConnectorsTreeModel->getRootConnectorItem());
  pOutputsConnectorItem->setText("Output Connectors");
  // add the connectors to input and output connectors tree views
  foreach (Component* pComponent, mpGraphicsView->getComponentsList()) {
    if (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getOMSConnector()
        && (!pComponent->isInBus() || pComponent->getBusComponent()->getLibraryTreeItem() == mpLibraryTreeItem)) {
      ConnectorItem *pConnectorItem = 0;
      if (pComponent->getLibraryTreeItem()->getOMSConnector()->causality == oms_causality_input) {
        pConnectorItem = mpInputConnectorsTreeModel->createConnectorItem(pComponent, pInputsConnectorItem);
      } else if (pComponent->getLibraryTreeItem()->getOMSConnector()->causality == oms_causality_output) {
        pConnectorItem = mpOutputConnectorsTreeModel->createConnectorItem(pComponent, pOutputsConnectorItem);
      } else {
        qDebug() << "AddBusDialog::AddBusDialog() unknown causality" << pComponent->getLibraryTreeItem()->getOMSConnector()->causality;
        Q_UNUSED(pConnectorItem);
      }
    }
  }
  // check which input connectors are already part of the bus
  markExistingBusConnectors(pInputsConnectorItem, components);
  // check which input connectors are already part of the bus
  markExistingBusConnectors(pOutputsConnectorItem, components);
  mpInputConnectorsTreeView->expandAll();
  mpOutputConnectorsTreeView->expandAll();
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
  pMainLayout->addWidget(mpInputConnectorsTreeView, 3, 0, 1, 2);
  pMainLayout->addWidget(mpOutputConnectorsTreeView, 4, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 5, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief AddBusDialog::markExistingBusConnectors
 * Mark the existing bus connectors checked.
 * \param pParentConnectorItem
 * \param components
 */
void AddBusDialog::markExistingBusConnectors(ConnectorItem *pParentConnectorItem, QList<Component *> components)
{
  for (int i = 0 ; i < pParentConnectorItem->childrenSize() ; i++) {
    ConnectorItem *pConnectorItem = pParentConnectorItem->childAt(i);
    if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSBusConnector() && mpLibraryTreeItem->getOMSBusConnector()->connectors) {
      for (int j = 0 ; mpLibraryTreeItem->getOMSBusConnector()->connectors[j] ; j++) {
        if (pConnectorItem->getComponent()->getName().compare(QString(mpLibraryTreeItem->getOMSBusConnector()->connectors[j])) == 0) {
          pConnectorItem->setChecked(true);
          break;
        }
      }
    } else if (pConnectorItem && components.contains(pConnectorItem->getComponent())) {
      pConnectorItem->setChecked(true);
      components.removeOne(pConnectorItem->getComponent());
    }
  }
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

  QStringList connectors;
  ConnectorItem *pInputConnectorsItem = mpInputConnectorsTreeModel->getRootConnectorItem()->childAt(0);
  if (pInputConnectorsItem) {
    for (int i = 0 ; i < pInputConnectorsItem->childrenSize() ; i++) {
      ConnectorItem *pConnectorItem = pInputConnectorsItem->childAt(i);
      if (pConnectorItem && pConnectorItem->isChecked()) {
        connectors.append(pConnectorItem->getComponent()->getLibraryTreeItem()->getNameStructure());
      }
    }
  }

  ConnectorItem *pOutputConnectorsItem = mpOutputConnectorsTreeModel->getRootConnectorItem()->childAt(0);
  if (pOutputConnectorsItem) {
    for (int i = 0 ; i < pOutputConnectorsItem->childrenSize() ; i++) {
      ConnectorItem *pConnectorItem = pOutputConnectorsItem->childAt(i);
      if (pConnectorItem && pConnectorItem->isChecked()) {
        connectors.append(pConnectorItem->getComponent()->getLibraryTreeItem()->getNameStructure());
      }
    }
  }

  LibraryTreeItem *pParentLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  QString bus = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mpNameTextBox->text());

  if (mpLibraryTreeItem) {  // edit case
    mpGraphicsView->getModelWidget()->beginMacro("Edit bus");

    /*! @todo Rename the bus here.
     */

    QStringList existingConnectors;
    if (mpLibraryTreeItem->getOMSBusConnector() && mpLibraryTreeItem->getOMSBusConnector()->connectors) {
      for (int i = 0 ; mpLibraryTreeItem->getOMSBusConnector()->connectors[i] ; i++) {
        existingConnectors.append(QString("%1.%2").arg(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure())
                                  .arg(QString(mpLibraryTreeItem->getOMSBusConnector()->connectors[i])));
      }
    }

    // add connectors to the bus
    QSet<QString> addConnectors = connectors.toSet().subtract(existingConnectors.toSet());
    foreach (QString connector, addConnectors) {
      AddConnectorToBusCommand *pAddConnectorToBusCommand = new AddConnectorToBusCommand(bus, connector, mpGraphicsView);
      mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddConnectorToBusCommand);
    }
    // delete connectors from the bus
    QSet<QString> deleteConnectors = existingConnectors.toSet().subtract(connectors.toSet());
    foreach (QString connector, deleteConnectors) {
      DeleteConnectorFromBusCommand *pDeleteConnectorFromBusCommand = new DeleteConnectorFromBusCommand(bus, connector, mpGraphicsView);
      mpGraphicsView->getModelWidget()->getUndoStack()->push(pDeleteConnectorFromBusCommand);
    }
    mpGraphicsView->getModelWidget()->updateModelText();
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
    accept();
    mpGraphicsView->getModelWidget()->endMacro();
  } else {  // add case
    mpGraphicsView->getModelWidget()->beginMacro("Add bus");
    QString annotation = QString("Placement(true,%1,%2,-10.0,-10.0,10.0,10.0,0,%1,%2,-10.0,-10.0,10.0,10.0,)")
                         .arg(Utilities::mapToCoOrdinateSystem(0.5, 0, 1, -100, 100))
                         .arg(Utilities::mapToCoOrdinateSystem(0.5, 0, 1, -100, 100));
    AddBusCommand *pAddBusCommand = new AddBusCommand(mpNameTextBox->text(), 0, annotation, mpGraphicsView, false);
    mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddBusCommand);
    if (!pAddBusCommand->isFailed()) {
      // add connectors to the bus
      foreach (QString connector, connectors) {
        AddConnectorToBusCommand *pAddConnectorToBusCommand = new AddConnectorToBusCommand(bus, connector, mpGraphicsView);
        mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddConnectorToBusCommand);
      }
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitComponentAddedForComponent();
      mpGraphicsView->getModelWidget()->updateModelText();
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
      accept();
    }
    mpGraphicsView->getModelWidget()->endMacro();
  }
}

/*!
 * \class AddTLMBusDialog
 * \brief A dialog for creating a tlm bus.
 */
/*!
 * \brief AddTLMBusDialog::AddTLMBusDialog
 * \param components
 * \param pLibraryTreeItem
 * \param pGraphicsView
 */
AddTLMBusDialog::AddTLMBusDialog(QList<Component *> components, LibraryTreeItem *pLibraryTreeItem, GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(pLibraryTreeItem ? Helper::editTLMBus : Helper::addTLMBus));
  setMinimumWidth(400);
  mpLibraryTreeItem = pLibraryTreeItem;
  mpGraphicsView = pGraphicsView;
  // set heading
  mpHeading = mpLibraryTreeItem ? Utilities::getHeadingLabel(Helper::editTLMBus) : Utilities::getHeadingLabel(Helper::addTLMBus);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit(mpLibraryTreeItem ? mpLibraryTreeItem->getName() : "");
  // domain
  mpDomainLabel = new Label(tr("Domain:"));
  mpDomainComboBox = new QComboBox;
  mpDomainComboBox->addItem("Input", oms_tlm_domain_input);
  mpDomainComboBox->addItem("Output", oms_tlm_domain_output);
  mpDomainComboBox->addItem("Mechanical", oms_tlm_domain_mechanical);
  mpDomainComboBox->addItem("Rotational", oms_tlm_domain_rotational);
  mpDomainComboBox->addItem("Hydraulic", oms_tlm_domain_hydraulic);
  mpDomainComboBox->addItem("Electric", oms_tlm_domain_electric);
  if (mpLibraryTreeItem) {
    int currentIndex = mpDomainComboBox->findData(mpLibraryTreeItem->getOMSTLMBusConnector()->domain);
    if (currentIndex > -1) {
      mpDomainComboBox->setCurrentIndex(currentIndex);
    }
  }
  connect(mpDomainComboBox, SIGNAL(currentIndexChanged(int)), SLOT(fetchTLMTypes()));
  // dimension
  mpDimensionLabel = new Label(tr("Dimension:"));
  mpDimensionSpinBox = new QSpinBox;
  mpDimensionSpinBox->setRange(1, 3);
  if (mpLibraryTreeItem) {
    mpDimensionSpinBox->setValue(mpLibraryTreeItem->getOMSTLMBusConnector()->dimensions);
  }
  connect(mpDimensionSpinBox, SIGNAL(valueChanged(int)), SLOT(fetchTLMTypes()));
  // interpolation
  mpInterpolationLabel = new Label(tr("Interpolation:"));
  mpInterpolationComboBox = new QComboBox;
  mpInterpolationComboBox->addItem("No interpolation", oms_tlm_no_interpolation);
  mpInterpolationComboBox->addItem("Coarse grained", oms_tlm_coarse_grained);
  mpInterpolationComboBox->addItem("Fine grained", oms_tlm_fine_grained);
  if (mpLibraryTreeItem) {
    int currentIndex = mpInterpolationComboBox->findData(mpLibraryTreeItem->getOMSTLMBusConnector()->interpolation);
    if (currentIndex > -1) {
      mpInterpolationComboBox->setCurrentIndex(currentIndex);
    }
  }
  connect(mpInterpolationComboBox, SIGNAL(currentIndexChanged(int)), SLOT(fetchTLMTypes()));
  // input connectors
  mpInputConnectorsTreeModel = new ConnectorsModel(this);
  mpInputConnectorsTreeModel->setColumnCount(2);
  mpInputConnectorsTreeView = new ConnectorsTreeView;
  mpInputConnectorsTreeView->setModel(mpInputConnectorsTreeModel);
  // inputs item
  ConnectorItem *pInputsConnectorItem = mpInputConnectorsTreeModel->createConnectorItem(0, mpInputConnectorsTreeModel->getRootConnectorItem());
  pInputsConnectorItem->setText("Input Connectors");
  // output connectors
  mpOutputConnectorsTreeModel = new ConnectorsModel(this);
  mpOutputConnectorsTreeModel->setColumnCount(2);
  mpOutputConnectorsTreeView = new ConnectorsTreeView;
  mpOutputConnectorsTreeView->setModel(mpOutputConnectorsTreeModel);
  // outputs item
  ConnectorItem *pOutputsConnectorItem = mpInputConnectorsTreeModel->createConnectorItem(0, mpOutputConnectorsTreeModel->getRootConnectorItem());
  pOutputsConnectorItem->setText("Output Connectors");
  // add the connectors to input and output connectors tree views
  foreach (Component* pComponent, mpGraphicsView->getComponentsList()) {
    if (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->getOMSConnector()
        && (!pComponent->isInBus() || pComponent->getBusComponent()->getLibraryTreeItem() == mpLibraryTreeItem)) {
      ConnectorItem *pConnectorItem = 0;
      if (pComponent->getLibraryTreeItem()->getOMSConnector()->causality == oms_causality_input) {
        pConnectorItem = mpInputConnectorsTreeModel->createConnectorItem(pComponent, pInputsConnectorItem);
      } else if (pComponent->getLibraryTreeItem()->getOMSConnector()->causality == oms_causality_output) {
        pConnectorItem = mpOutputConnectorsTreeModel->createConnectorItem(pComponent, pOutputsConnectorItem);
      } else {
        qDebug() << "AddTLMBusDialog::AddTLMBusDialog() unknown causality" << pComponent->getLibraryTreeItem()->getOMSConnector()->causality;
        Q_UNUSED(pConnectorItem);
      }
    }
  }
  fetchTLMTypes();
  // check which input connectors are already part of the tlm bus
  markExistingTLMBusConnectors(pInputsConnectorItem, components);
  // check which input connectors are already part of the tlm bus
  markExistingTLMBusConnectors(pOutputsConnectorItem, components);
  mpInputConnectorsTreeView->expandAll();
  mpInputConnectorsTreeView->resizeColumnToContents(0);
  mpOutputConnectorsTreeView->expandAll();
  mpOutputConnectorsTreeView->resizeColumnToContents(0);
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
  pMainLayout->addWidget(mpDomainComboBox, 3, 1);
  pMainLayout->addWidget(mpDimensionLabel, 4, 0);
  pMainLayout->addWidget(mpDimensionSpinBox, 4, 1);
  pMainLayout->addWidget(mpInterpolationLabel, 5, 0);
  pMainLayout->addWidget(mpInterpolationComboBox, 5, 1);
  pMainLayout->addWidget(mpInputConnectorsTreeView, 6, 0, 1, 2);
  pMainLayout->addWidget(mpOutputConnectorsTreeView, 7, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 8, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief AddTLMBusDialog::markExistingTLMBusConnectors
 * Mark the existing tlm bus connectors checked.
 * \param pParentConnectorItem
 * \param components
 */
void AddTLMBusDialog::markExistingTLMBusConnectors(ConnectorItem *pParentConnectorItem, QList<Component *> components)
{
  for (int i = 0 ; i < pParentConnectorItem->childrenSize() ; i++) {
    ConnectorItem *pConnectorItem = pParentConnectorItem->childAt(i);
    if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSTLMBusConnector() && mpLibraryTreeItem->getOMSTLMBusConnector()->connectornames) {
      for (int j = 0 ; mpLibraryTreeItem->getOMSTLMBusConnector()->connectornames[j] ; j++) {
        if (pConnectorItem->getComponent()->getName().compare(QString(mpLibraryTreeItem->getOMSTLMBusConnector()->connectornames[j])) == 0) {
          pConnectorItem->setChecked(true);
          pConnectorItem->setTLMType(mpLibraryTreeItem->getOMSTLMBusConnector()->connectortypes[j]);
          break;
        }
      }
    } else if (pConnectorItem && components.contains(pConnectorItem->getComponent())) {
      pConnectorItem->setChecked(true);
      components.removeOne(pConnectorItem->getComponent());
    }
  }
}

/*!
 * \brief AddTLMBusDialog::fetchTLMTypes
 * Fetches the TLM Types based on the domain, dimension and interpolation.
 */
void AddTLMBusDialog::fetchTLMTypes()
{
  char **types = NULL;
  char **descriptions = NULL;
  if (OMSProxy::instance()->getTLMVariableTypes((oms_tlm_domain_t)mpDomainComboBox->itemData(mpDomainComboBox->currentIndex()).toInt(),
                                                mpDimensionSpinBox->value(),
                                                (oms_tlm_interpolation_t)mpInterpolationComboBox->itemData(mpInterpolationComboBox->currentIndex()).toInt(),
                                                &types, &descriptions)) {
    // convert types and descriptions list to QStringList
    QStringList tlmTypes, tlmTypesDescriptions;
    for (int i = 0 ; types[i] ; i++) {
      tlmTypes.append(QString(types[i]));
      tlmTypesDescriptions.append(QString(descriptions[i]));
    }
    // Insert TLM types in Input Connectors treeview
    mpInputConnectorsTreeModel->setTLMTypes(tlmTypes);
    mpInputConnectorsTreeModel->setTLMTypesDescriptions(tlmTypesDescriptions);
    ConnectorItem *pInputConnectorsItem = mpInputConnectorsTreeModel->getRootConnectorItem()->childAt(0);
    if (pInputConnectorsItem) {
      for (int i = 0 ; i < pInputConnectorsItem->childrenSize() ; i++) {
        ConnectorItem *pConnectorItem = pInputConnectorsItem->childAt(i);
        if (pConnectorItem && !tlmTypes.isEmpty()) {
          QModelIndex index = mpInputConnectorsTreeModel->connectorItemIndex(pConnectorItem, 1);
          if (index.isValid()) {
            pConnectorItem->setTLMTypeDescription(tlmTypesDescriptions.first());
            mpInputConnectorsTreeModel->setData(index, tlmTypes.first());
          }
        }
      }
    }
    // Insert TLM types in Output Connectors treeview
    mpOutputConnectorsTreeModel->setTLMTypes(tlmTypes);
    mpOutputConnectorsTreeModel->setTLMTypesDescriptions(tlmTypesDescriptions);
    ConnectorItem *pOutputConnectorsItem = mpOutputConnectorsTreeModel->getRootConnectorItem()->childAt(0);
    if (pOutputConnectorsItem) {
      for (int i = 0 ; i < pOutputConnectorsItem->childrenSize() ; i++) {
        ConnectorItem *pConnectorItem = pOutputConnectorsItem->childAt(i);
        if (pConnectorItem && !tlmTypes.isEmpty()) {
          QModelIndex index = mpOutputConnectorsTreeModel->connectorItemIndex(pConnectorItem, 1);
          if (index.isValid()) {
            pConnectorItem->setTLMTypeDescription(tlmTypesDescriptions.first());
            mpOutputConnectorsTreeModel->setData(index, tlmTypes.first());
          }
        }
      }
    }
  }
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

  QSet<QPair<QString, QString> > connectors;
  ConnectorItem *pInputConnectorsItem = mpInputConnectorsTreeModel->getRootConnectorItem()->childAt(0);
  if (pInputConnectorsItem) {
    for (int i = 0 ; i < pInputConnectorsItem->childrenSize() ; i++) {
      ConnectorItem *pConnectorItem = pInputConnectorsItem->childAt(i);
      if (pConnectorItem && pConnectorItem->isChecked()) {
        connectors.insert(qMakePair(pConnectorItem->getComponent()->getLibraryTreeItem()->getNameStructure(), pConnectorItem->getTLMType()));
      }
    }
  }

  ConnectorItem *pOutputConnectorsItem = mpOutputConnectorsTreeModel->getRootConnectorItem()->childAt(0);
  if (pOutputConnectorsItem) {
    for (int i = 0 ; i < pOutputConnectorsItem->childrenSize() ; i++) {
      ConnectorItem *pConnectorItem = pOutputConnectorsItem->childAt(i);
      if (pConnectorItem && pConnectorItem->isChecked()) {
        connectors.insert(qMakePair(pConnectorItem->getComponent()->getLibraryTreeItem()->getNameStructure(), pConnectorItem->getTLMType()));
      }
    }
  }

  LibraryTreeItem *pParentLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  QString tlmBus = QString("%1.%2").arg(pParentLibraryTreeItem->getNameStructure()).arg(mpNameTextBox->text());

  if (mpLibraryTreeItem) {  // edit case
    mpGraphicsView->getModelWidget()->beginMacro("Edit TLM bus");

    /*! @todo Rename the tlm bus here.
     */

    QSet<QPair<QString, QString> > existingConnectors;
    if (mpLibraryTreeItem->getOMSTLMBusConnector() && mpLibraryTreeItem->getOMSTLMBusConnector()->connectornames) {
      for (int i = 0 ; mpLibraryTreeItem->getOMSTLMBusConnector()->connectornames[i] ; i++) {
        existingConnectors.insert(qMakePair(QString("%1.%2").arg(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure())
                                            .arg(QString(mpLibraryTreeItem->getOMSTLMBusConnector()->connectornames[i])),
                                            QString(mpLibraryTreeItem->getOMSTLMBusConnector()->connectortypes[i])));
      }
    }
    // delete connectors from the bus
    QSet<QPair<QString, QString> > deleteConnectors = existingConnectors;
    deleteConnectors.subtract(connectors);
    QPair<QString, QString> connector;
    foreach (connector, deleteConnectors) {
      DeleteConnectorFromTLMBusCommand *pDeleteConnectorFromTLMBusCommand;
      pDeleteConnectorFromTLMBusCommand = new DeleteConnectorFromTLMBusCommand(tlmBus, connector.first, connector.second, mpGraphicsView);
      mpGraphicsView->getModelWidget()->getUndoStack()->push(pDeleteConnectorFromTLMBusCommand);
    }
    // add connectors to the bus
    QSet<QPair<QString, QString> > addConnectors = connectors;
    addConnectors.subtract(existingConnectors);
    foreach (connector, addConnectors) {
      AddConnectorToTLMBusCommand *pAddConnectorToBusCommand = new AddConnectorToTLMBusCommand(tlmBus, connector.first,
                                                                                               connector.second, mpGraphicsView);
      mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddConnectorToBusCommand);
    }

    mpGraphicsView->getModelWidget()->updateModelText();
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
    accept();
    mpGraphicsView->getModelWidget()->endMacro();
  } else {  // add case
    mpGraphicsView->getModelWidget()->beginMacro("Add TLM bus");
    QString annotation = QString("Placement(true,%1,%2,-10.0,-10.0,10.0,10.0,0,%1,%2,-10.0,-10.0,10.0,10.0,)")
                         .arg(Utilities::mapToCoOrdinateSystem(0.5, 0, 1, -100, 100))
                         .arg(Utilities::mapToCoOrdinateSystem(0.5, 0, 1, -100, 100));
    AddTLMBusCommand *pAddTLMBusCommand = new AddTLMBusCommand(mpNameTextBox->text(), 0, annotation, mpGraphicsView, false,
                                                               (oms_tlm_domain_t)mpDomainComboBox->itemData(mpDomainComboBox->currentIndex()).toInt(),
                                                               mpDimensionSpinBox->value(),
                                                               (oms_tlm_interpolation_t)mpInterpolationComboBox->itemData(mpInterpolationComboBox->currentIndex()).toInt());
    mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddTLMBusCommand);
    if (!pAddTLMBusCommand->isFailed()) {
      // add connectors to the bus
      QPair<QString, QString> connector;
      foreach (connector, connectors) {
        AddConnectorToTLMBusCommand *pAddConnectorToTLMBusCommand = new AddConnectorToTLMBusCommand(tlmBus, connector.first,
                                                                                                    connector.second, mpGraphicsView);
        mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddConnectorToTLMBusCommand);
      }
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitComponentAddedForComponent();
      mpGraphicsView->getModelWidget()->updateModelText();
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
      accept();
    }
    mpGraphicsView->getModelWidget()->endMacro();
  }
}

/*!
 * \class ConnectionItem
 * \brief Contains the information about the connection.
 */
/*!
 * \brief ConnectionItem::ConnectionItem
 * \param start
 * \param end
 * \param checked
 * \param pParent
 */
ConnectionItem::ConnectionItem(QString start, QString end, bool checked, ConnectionItem *pParent)
{
  mStart = start;
  mInitialStart = start;
  mEnd = end;
  mInitialEnd = end;
  mpParentConnectionItem = pParent;
  mChecked = checked;
  mExisting = false;
}

/*!
 * \brief ConnectionItem::row
 * Returns the row number corresponding to ConnectorItem.
 * \return
 */
int ConnectionItem::row() const
{
  if (mpParentConnectionItem) {
    return mpParentConnectionItem->mChildren.indexOf(const_cast<ConnectionItem*>(this));
  }

  return 0;
}

/*!
 * \class ConnectionsModel
 * \brief A model for connections.
 */
/*!
 * \brief ConnectionsModel::ConnectionsModel
 * \param pConnectionLineAnnotation
 * \param parent
 */
ConnectionsModel::ConnectionsModel(LineAnnotation *pConnectionLineAnnotation, QObject *parent)
  : QAbstractItemModel(parent)
{
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mpRootConnectionItem = new ConnectionItem("", "", false, 0);
}

/*!
 * \brief ConnectionsModel::columnCount
 * Returns the number of columns for the children of the given parent.
 * \param parent
 * \return
 */
int ConnectionsModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 3;
}

/*!
 * \brief ConnectionsModel::rowCount
 * Returns the number of rows under the given parent.
 * When the parent is valid it means that rowCount is returning the number of children of parent.
 * \param parent
 * \return
 */
int ConnectionsModel::rowCount(const QModelIndex &parent) const
{
  ConnectionItem *pParentConnectionItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentConnectionItem = mpRootConnectionItem;
  } else {
    pParentConnectionItem = static_cast<ConnectionItem*>(parent.internalPointer());
  }
  return pParentConnectionItem->childrenSize();
}

QVariant ConnectionsModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  Q_UNUSED(orientation);
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
    switch (section) {
      case 0:
        return mHeaderLabels.size() > 0 ? mHeaderLabels.at(0) : "";
      case 1:
        return mHeaderLabels.size() > 1 ? mHeaderLabels.at(1) : "";
      case 2:
        return "ssd:Connection";
      default:
        break;
    }
  }
  return QAbstractItemModel::headerData(section, orientation, role);
}

/*!
 * \brief ConnectionsModel::index
 * Returns the index of the item in the model specified by the given row, column and parent index.
 * \param row
 * \param column
 * \param parent
 * \return
 */
QModelIndex ConnectionsModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  ConnectionItem *pParentConnectionItem;
  if (!parent.isValid()) {
    pParentConnectionItem = mpRootConnectionItem;
  } else {
    pParentConnectionItem = static_cast<ConnectionItem*>(parent.internalPointer());
  }

  ConnectionItem *pChildConnectionItem = pParentConnectionItem->child(row);
  if (pChildConnectionItem) {
    return createIndex(row, column, pChildConnectionItem);
  } else {
    return QModelIndex();
  }
}

/*!
 * \brief ConnectionsModel::parent
 * Finds the parent for QModelIndex
 * \param index
 * \return
 */
QModelIndex ConnectionsModel::parent(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return QModelIndex();
  }

  ConnectionItem *pChildConnectionItem = static_cast<ConnectionItem*>(index.internalPointer());
  ConnectionItem *pParentConnectionItem = pChildConnectionItem->parent();
  if (pParentConnectionItem == mpRootConnectionItem)
    return QModelIndex();

  return createIndex(pParentConnectionItem->row(), 0, pParentConnectionItem);
}

/*!
 * \brief ConnectionsModel::setData
 * Updates the model data.
 * \param index
 * \param value
 * \param role
 * \return
 */
bool ConnectionsModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
  ConnectionItem *pConnectionItem = static_cast<ConnectionItem*>(index.internalPointer());
  if (!pConnectionItem) {
    return false;
  }

  if (index.column() == 0 && role == Qt::CheckStateRole) {
    if (value.toInt() == Qt::Checked) {
      pConnectionItem->setChecked(true);
    } else if (value.toInt() == Qt::Unchecked) {
      pConnectionItem->setChecked(false);
    }
    emit dataChanged(index, index);
    return true;
  }

  return QAbstractItemModel::setData(index, value, role);
}

/*!
 * \brief ConnectionsModel::data
 * Returns the ConnectionItem data.
 * \param index
 * \param role
 * \return
 */
QVariant ConnectionsModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }

  ConnectionItem *pConnectionItem = static_cast<ConnectionItem*>(index.internalPointer());

  switch (index.column()) {
    case 0:
      switch (role) {
        case Qt::CheckStateRole:
          if (pConnectionItem->getStart().isEmpty() || pConnectionItem->getEnd().isEmpty()) {
            return Qt::Unchecked;
          }
          return pConnectionItem->isChecked() ? Qt::Checked : Qt::Unchecked;;
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return pConnectionItem->getStart();
        case Qt::BackgroundRole:
          return pConnectionItem->isExisting() ? QColor(Qt::yellow) : QVariant();
        default:
          return QVariant();
      }
    case 1:
      switch (role) {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return pConnectionItem->getEnd();
        case Qt::BackgroundRole:
          return pConnectionItem->isExisting() ? QColor(Qt::yellow) : QVariant();
        default:
          return QVariant();
      }
    case 2:
      switch (role) {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
        {
          LibraryTreeItem *pStartElement = mpConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()->parent();
          LibraryTreeItem *pEndElement = mpConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()->parent();
          if (pStartElement && pEndElement && !pConnectionItem->getStart().isEmpty() && !pConnectionItem->getEnd().isEmpty()) {
            return QString("<ssd:Connection startElement=\"%1\" startConnector=\"%2\" endElement=\"%3\" endConnector=\"%4\" />")
                .arg(pStartElement->getName(), pConnectionItem->getStart(), pEndElement->getName(), pConnectionItem->getEnd());
          } else {
            return QVariant();
          }
        }
        case Qt::BackgroundRole:
          return pConnectionItem->isExisting() ? QColor(Qt::yellow) : QVariant();
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

/*!
 * \brief ConnectionsModel::mimeTypes
 * \return
 */
QStringList ConnectionsModel::mimeTypes() const
{
  QStringList types;
  types << Helper::busConnectorFormat;
  return types;
}

/*!
 * \brief ConnectionsModel::mimeData
 * \param indexes
 * \return
 */
QMimeData* ConnectionsModel::mimeData(const QModelIndexList &indexes) const
{
  QMimeData *mimeData = new QMimeData();
  QByteArray encodedData;
  QDataStream stream(&encodedData, QIODevice::WriteOnly);

  if (!indexes.isEmpty()) {
    const QModelIndex &index = indexes.at(0); // single selection model
    if (index.isValid()) {
      stream << index.row();
      stream << index.column();
      stream << data(index, Qt::DisplayRole).toString();
    }
  }

  mimeData->setData(Helper::busConnectorFormat, encodedData);
  return mimeData;
}

bool ConnectionsModel::canDropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent) const
{
  Q_UNUSED(action);
  Q_UNUSED(row);
  Q_UNUSED(parent);

  if (!data->hasFormat(Helper::busConnectorFormat)) {
    return false;
  }

  int sourceRow, sourceColumn;
  QByteArray encodedData = data->data(Helper::busConnectorFormat);
  QDataStream stream(&encodedData, QIODevice::ReadOnly);

  stream >> sourceRow;
  stream >> sourceColumn;

  // move is only allowed in the same column
  if (sourceColumn != parent.column()) {
    return false;
  }

  return true;
}

bool ConnectionsModel::dropMimeData(const QMimeData *data, Qt::DropAction action, int row, int column, const QModelIndex &parent)
{
  int sourceRow, sourceColumn;
  QByteArray encodedData = data->data(Helper::busConnectorFormat);
  QDataStream stream(&encodedData, QIODevice::ReadOnly);

  stream >> sourceRow;
  stream >> sourceColumn;

  QModelIndex sourceIndex = index(sourceRow, sourceColumn);
  ConnectionItem *pSourceConnectionItem = static_cast<ConnectionItem*>(sourceIndex.internalPointer());

  ConnectionItem *pDestinationConnectionItem = static_cast<ConnectionItem*>(parent.internalPointer());

  QString sourceValue = "";
  QString destinationValue = "";
  if (sourceColumn == 0) {
    sourceValue = pSourceConnectionItem->getStart();
    destinationValue = pDestinationConnectionItem->getStart();
    pSourceConnectionItem->setStart(destinationValue);
    pDestinationConnectionItem->setStart(sourceValue);
  } else if (sourceColumn == 1) {
    sourceValue = pSourceConnectionItem->getEnd();
    destinationValue = pDestinationConnectionItem->getEnd();
    pSourceConnectionItem->setEnd(destinationValue);
    pDestinationConnectionItem->setEnd(sourceValue);
  }

  pSourceConnectionItem->setChecked(!pSourceConnectionItem->getStart().isEmpty() && !pSourceConnectionItem->getEnd().isEmpty());
  pDestinationConnectionItem->setChecked(!pDestinationConnectionItem->getStart().isEmpty() && !pDestinationConnectionItem->getEnd().isEmpty());

  return true;
}

/*!
 * \brief ConnectionsModel::supportedDropActions
 * \return
 */
Qt::DropActions ConnectionsModel::supportedDropActions() const
{
  return Qt::MoveAction;
}

/*!
 * \brief ConnectionsModel::flags
 * Returns the ConnectionItem flags.
 * \param index
 * \return
 */
Qt::ItemFlags ConnectionsModel::flags(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return Qt::ItemIsEnabled;
  } else {
    switch (index.column()) {
      case 0:
        return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsDragEnabled | Qt::ItemIsDropEnabled | Qt::ItemIsUserCheckable;
      case 1:
        return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsDragEnabled | Qt::ItemIsDropEnabled;
      case 2:
      default:
        return Qt::ItemIsEnabled | Qt::ItemIsSelectable;

    }
  }
}

/*!
 * \brief ConnectionsModel::connectionItemIndex
 * Finds the QModelIndex attached to ConnectionItem.
 * \param pConnectionItem
 * \return
 */
QModelIndex ConnectionsModel::connectionItemIndex(const ConnectionItem *pConnectionItem) const
{
  return connectionItemIndexHelper(pConnectionItem, mpRootConnectionItem, QModelIndex());
}

/*!
 * \brief ConnectionsModel::createConnectionItem
 * Creates the ConnectionItem and returns it.
 * \param start
 * \param end
 * \param checked
 * \param pParent
 * \return
 */
ConnectionItem* ConnectionsModel::createConnectionItem(QString start, QString end, bool checked, ConnectionItem *pParent)
{
  int row = pParent->childrenSize();
  beginInsertRows(connectionItemIndex(pParent), row, row);
  ConnectionItem *pConnectionItem = new ConnectionItem(start, end, checked, pParent);
  pParent->insertChild(row, pConnectionItem);
  endInsertRows();
  return pConnectionItem;
}

/*!
 * \brief ConnectionsModel::connectionItemIndexHelper
 * Helper function for ConnectionsModel::connectionItemIndex()
 * \param pConnectionItem
 * \param pParentConnectionItem
 * \param parentIndex
 * \return
 */
QModelIndex ConnectionsModel::connectionItemIndexHelper(const ConnectionItem *pConnectionItem,
                                                        const ConnectionItem *pParentConnectionItem, const QModelIndex &parentIndex) const
{
  if (pConnectionItem == pParentConnectionItem) {
    return parentIndex;
  }
  for (int i = pParentConnectionItem->childrenSize(); --i >= 0; ) {
    const ConnectionItem *childItem = pParentConnectionItem->childAt(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = connectionItemIndexHelper(pConnectionItem, childItem, childIndex);
    if (index.isValid()) {
      return index;
    }
  }
  return QModelIndex();
}

/*!
 * \class BusConnectionDialog
 * \brief A dialog for creating a bus connection.
 */
/*!
 * \brief BusConnectionDialog::BusConnectionDialog
 * \param pGraphicsView
 * \param pConnectionLineAnnotation
 */
BusConnectionDialog::BusConnectionDialog(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, bool addCase)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(addCase ? Helper::addBusConnection : Helper::editBusConnection));
  resize(800, 600);
  mpGraphicsView = pGraphicsView;
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mAddCase = addCase;
  // set heading
  mpHeading = Utilities::getHeadingLabel(addCase ? Helper::addBusConnection : Helper::editBusConnection);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // input output label
  LibraryTreeItem *pStartLibraryTreeItem = mpConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem();
  LibraryTreeItem *pEndLibraryTreeItem = mpConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem();
  Label *pInputOutputLabel = new Label(QString("Connect <b>%1</b> input connectors to <b>%2</b> output connectors")
                                       .arg(pStartLibraryTreeItem->getName())
                                       .arg(pEndLibraryTreeItem->getName()));
  // input output connections
  mpInputOutputConnectionsModel = new ConnectionsModel(mpConnectionLineAnnotation, this);
  QStringList headerLabels;
  headerLabels << QString("%1 inputs").arg(pStartLibraryTreeItem->getName())
               << QString("%1 outputs").arg(pEndLibraryTreeItem->getName());
  mpInputOutputConnectionsModel->setHeaderLabels(headerLabels);
  mpInputOutputConnectionsTableView = new QTableView;
  mpInputOutputConnectionsTableView->setModel(mpInputOutputConnectionsModel);
  mpInputOutputConnectionsTableView->setTextElideMode(Qt::ElideMiddle);
  mpInputOutputConnectionsTableView->setDragDropMode(QAbstractItemView::InternalMove);
  mpInputOutputConnectionsTableView->setDropIndicatorShown(true);
  mpInputOutputConnectionsTableView->setSelectionBehavior(QAbstractItemView::SelectItems);
  mpInputOutputConnectionsTableView->setSelectionMode(QAbstractItemView::SingleSelection);
  // output input label
  Label *pOutputInputLabel = new Label(QString("Connect <b>%1</b> output connectors to <b>%2</b> input connectors")
                                       .arg(pStartLibraryTreeItem->getName())
                                       .arg(pEndLibraryTreeItem->getName()));
  // output input connections
  mpOutputInputConnectionsModel = new ConnectionsModel(mpConnectionLineAnnotation, this);
  headerLabels.clear();
  headerLabels << QString("%1 outputs").arg(pStartLibraryTreeItem->getName())
               << QString("%1 inputs").arg(pEndLibraryTreeItem->getName());
  mpOutputInputConnectionsModel->setHeaderLabels(headerLabels);
  mpOutputInputConnectionsTableView = new QTableView;
  mpOutputInputConnectionsTableView->setModel(mpOutputInputConnectionsModel);
  mpOutputInputConnectionsTableView->setTextElideMode(Qt::ElideMiddle);
  mpOutputInputConnectionsTableView->setDragDropMode(QAbstractItemView::InternalMove);
  mpOutputInputConnectionsTableView->setDropIndicatorShown(true);
  mpOutputInputConnectionsTableView->setSelectionBehavior(QAbstractItemView::SelectItems);
  mpOutputInputConnectionsTableView->setSelectionMode(QAbstractItemView::SingleSelection);
  // start bus input output connectors
  oms_busconnector_t *pStartBus = pStartLibraryTreeItem->getOMSBusConnector();
  QStringList startBusInputConnectors, startBusOutputConnectors;
  if (pStartBus && pStartBus->connectors) {
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pParentLibraryTreeItem = pStartLibraryTreeItem->parent();
    for (int i = 0; pStartBus->connectors[i] ; ++i) {
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(QString("%1.%2")
                                                                                 .arg(pParentLibraryTreeItem->getNameStructure())
                                                                                 .arg(pStartBus->connectors[i]), pParentLibraryTreeItem);
      if (pLibraryTreeItem && pLibraryTreeItem->getOMSConnector()) {
        if (pLibraryTreeItem->getOMSConnector()->causality == oms_causality_input) {
          startBusInputConnectors.append(QString(pStartBus->connectors[i]));
        } else if (pLibraryTreeItem->getOMSConnector()->causality == oms_causality_output) {
          startBusOutputConnectors.append(QString(pStartBus->connectors[i]));
        }
      }
    }
  } else if (pStartLibraryTreeItem->getOMSConnector()) {
    if (pStartLibraryTreeItem->getOMSConnector()->causality == oms_causality_input) {
      startBusInputConnectors.append(pStartLibraryTreeItem->getName());
    } else if (pStartLibraryTreeItem->getOMSConnector()->causality == oms_causality_output) {
      startBusOutputConnectors.append(pStartLibraryTreeItem->getName());
    }
  }
  startBusInputConnectors.sort();
  startBusOutputConnectors.sort();
  // end bus input output connectors
  oms_busconnector_t *pEndBus = pEndLibraryTreeItem->getOMSBusConnector();
  QStringList endBusInputConnectors, endBusOutputConnectors;
  if (pEndBus && pEndBus->connectors) {
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pParentLibraryTreeItem = pEndLibraryTreeItem->parent();
    for (int i = 0; pEndBus->connectors[i] ; ++i) {
      LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(QString("%1.%2")
                                                                                 .arg(pParentLibraryTreeItem->getNameStructure())
                                                                                 .arg(pEndBus->connectors[i]), pParentLibraryTreeItem);
      if (pLibraryTreeItem && pLibraryTreeItem->getOMSConnector()) {
        if (pLibraryTreeItem->getOMSConnector()->causality == oms_causality_input) {
          endBusInputConnectors.append(QString(pEndBus->connectors[i]));
        } else if (pLibraryTreeItem->getOMSConnector()->causality == oms_causality_output) {
          endBusOutputConnectors.append(QString(pEndBus->connectors[i]));
        }
      }
    }
  } else if (pEndLibraryTreeItem->getOMSConnector()) {
    if (pEndLibraryTreeItem->getOMSConnector()->causality == oms_causality_input) {
      startBusInputConnectors.append(pEndLibraryTreeItem->getName());
    } else if (pEndLibraryTreeItem->getOMSConnector()->causality == oms_causality_output) {
      startBusOutputConnectors.append(pEndLibraryTreeItem->getName());
    }
  }
  endBusInputConnectors.sort();
  endBusOutputConnectors.sort();

  if (!addCase) {
    for (int i = 0 ; i < mpGraphicsView->getConnectionsList().size() ; ++i) {
      LineAnnotation *pAtomicConnectionLineAnnotation = mpGraphicsView->getConnectionsList().at(i);
      if (pAtomicConnectionLineAnnotation && pAtomicConnectionLineAnnotation->getOMSConnectionType() == oms_connection_single) {
        QString startConnectorName = StringHandler::getLastWordAfterDot(pAtomicConnectionLineAnnotation->getStartComponentName());
        QString endConnectorName = StringHandler::getLastWordAfterDot(pAtomicConnectionLineAnnotation->getEndComponentName());
        if (startBusInputConnectors.contains(startConnectorName) && endBusOutputConnectors.contains(endConnectorName)) {
          ConnectionItem *pConnectionItem;
          pConnectionItem = mpInputOutputConnectionsModel->createConnectionItem(startConnectorName, endConnectorName, true,
                                                                                mpInputOutputConnectionsModel->getRootConnectionItem());
          pConnectionItem->setExisting(true);
          startBusInputConnectors.removeOne(startConnectorName);
          endBusOutputConnectors.removeOne(endConnectorName);
        } else if (startBusInputConnectors.contains(endConnectorName) && endBusOutputConnectors.contains(startConnectorName)) {
          ConnectionItem *pConnectionItem;
          pConnectionItem = mpInputOutputConnectionsModel->createConnectionItem(endConnectorName, startConnectorName, true,
                                                                                mpInputOutputConnectionsModel->getRootConnectionItem());
          pConnectionItem->setExisting(true);
          startBusInputConnectors.removeOne(endConnectorName);
          endBusOutputConnectors.removeOne(startConnectorName);
        } else if (startBusOutputConnectors.contains(startConnectorName) && endBusInputConnectors.contains(endConnectorName)) {
          ConnectionItem *pConnectionItem;
          pConnectionItem = mpOutputInputConnectionsModel->createConnectionItem(startConnectorName, endConnectorName, true,
                                                                                mpOutputInputConnectionsModel->getRootConnectionItem());
          pConnectionItem->setExisting(true);
          startBusOutputConnectors.removeOne(startConnectorName);
          endBusInputConnectors.removeOne(endConnectorName);
        } else if (startBusOutputConnectors.contains(endConnectorName) && endBusInputConnectors.contains(startConnectorName)) {
          ConnectionItem *pConnectionItem;
          pConnectionItem = mpOutputInputConnectionsModel->createConnectionItem(endConnectorName, startConnectorName, true,
                                                                                mpOutputInputConnectionsModel->getRootConnectionItem());
          pConnectionItem->setExisting(true);
          startBusOutputConnectors.removeOne(endConnectorName);
          endBusInputConnectors.removeOne(startConnectorName);
        }
      }
    }
  }

  int size = qMax(startBusInputConnectors.size(), endBusOutputConnectors.size());

  for (int i = 0; i < size ; ++i) {
    QString start = i < startBusInputConnectors.size() ? startBusInputConnectors.at(i) : "";
    QString end = i < endBusOutputConnectors.size() ? endBusOutputConnectors.at(i) : "";
    mpInputOutputConnectionsModel->createConnectionItem(start, end, addCase, mpInputOutputConnectionsModel->getRootConnectionItem());
  }
  mpInputOutputConnectionsTableView->resizeColumnToContents(2);

  size = qMax(startBusOutputConnectors.size(), endBusInputConnectors.size());

  for (int i = 0; i < size ; ++i) {
    QString start = i < startBusOutputConnectors.size() ? startBusOutputConnectors.at(i) : "";
    QString end = i < endBusInputConnectors.size() ? endBusInputConnectors.at(i) : "";
    mpOutputInputConnectionsModel->createConnectionItem(start, end, addCase, mpOutputInputConnectionsModel->getRootConnectionItem());
  }
  mpOutputInputConnectionsTableView->resizeColumnToContents(2);

  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addBusConnection()));
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
  pMainLayout->addWidget(mpHeading, 0, 0);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainLayout->addWidget(pInputOutputLabel, 2, 0);
  pMainLayout->addWidget(mpInputOutputConnectionsTableView, 3, 0);
  pMainLayout->addWidget(pOutputInputLabel, 4, 0);
  pMainLayout->addWidget(mpOutputInputConnectionsTableView, 5, 0);
  int i = 6;
  if (!addCase) {
    pMainLayout->addWidget(new Label(tr("Note: Yellow marked rows are existing connections.")), i++, 0);
  }
  pMainLayout->addWidget(mpButtonBox, i, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief BusConnectionDialog::addOrDeleteAtomicConnections
 * Adds or Deletes the atomic connections based on the connections set on each ConnectionsModel.
 * \param pConnectionsModel
 */
void BusConnectionDialog::addOrDeleteAtomicConnections(ConnectionsModel *pConnectionsModel)
{
  for (int i = 0; i < pConnectionsModel->getRootConnectionItem()->childrenSize() ; ++i) {
    ConnectionItem *pConnectionItem = pConnectionsModel->getRootConnectionItem()->childAt(i);
    if (pConnectionItem->isExisting()) { // delete atomic connection
      /* 1. Unchecked and start and end are unchanged.
       * 2. Unchecked and start or end are empty.
       * 3. Checked/Unchecked and start or end are changed.
       */
      if ((!pConnectionItem->isChecked() && (pConnectionItem->getStart().compare(pConnectionItem->getInitialStart()) == 0)
           && (pConnectionItem->getEnd().compare(pConnectionItem->getInitialEnd()) == 0))
          || (!pConnectionItem->isChecked() && (pConnectionItem->getStart().isEmpty() || pConnectionItem->getEnd().isEmpty()))
          || ((pConnectionItem->getStart().compare(pConnectionItem->getInitialStart()) != 0)
              || (pConnectionItem->getEnd().compare(pConnectionItem->getInitialEnd()) != 0))) {
        deleteAtomicConnection(pConnectionItem->getInitialStart(), pConnectionItem->getInitialEnd());
        /* When we have case 3. Checked/Unchecked and start or end are changed.
         * Then we also need to add a new atomic connection if checked.
         */
        if (pConnectionItem->isChecked() && ((pConnectionItem->getStart().compare(pConnectionItem->getInitialStart()) != 0)
                                             || (pConnectionItem->getEnd().compare(pConnectionItem->getInitialEnd()) != 0))) {
          addAtomicConnection(pConnectionItem->getStart(), pConnectionItem->getEnd());
        }
      }
    } else if (pConnectionItem->isChecked()) { // add atomic connection
      addAtomicConnection(pConnectionItem->getStart(), pConnectionItem->getEnd());
    }
  }
}

/*!
 * \brief BusConnectionDialog::deleteAtomicConnection
 * Deletes an atomic connection
 * \param startConnectorName
 * \param endConnectorName
 */
void BusConnectionDialog::deleteAtomicConnection(QString startConnectorName, QString endConnectorName)
{
  LibraryTreeItem *pStartLibraryTreeItem = mpConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem();
  LibraryTreeItem *pStartParentLibraryTreeItem = pStartLibraryTreeItem->parent();
  LibraryTreeItem *pEndLibraryTreeItem = mpConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem();
  LibraryTreeItem *pEndParentLibraryTreeItem = pEndLibraryTreeItem->parent();

  Component *pStartComponent = pStartParentLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getComponentObject(startConnectorName);
  Component *pEndComponent = pEndParentLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getComponentObject(endConnectorName);

  if (pStartComponent && pEndComponent) {
    foreach (LineAnnotation *pConnectionLineAnnotation, mpGraphicsView->getConnectionsList()) {
      if ((pConnectionLineAnnotation->getStartComponentName().compare(pStartComponent->getLibraryTreeItem()->getNameStructure()) == 0)
          && (pConnectionLineAnnotation->getEndComponentName().compare(pEndComponent->getLibraryTreeItem()->getNameStructure()) == 0)) {
        DeleteConnectionCommand *pDeleteConnectionCommand = new DeleteConnectionCommand(pConnectionLineAnnotation);
        mpGraphicsView->getModelWidget()->getUndoStack()->push(pDeleteConnectionCommand);
      }
    }
  }
}

/*!
 * \brief BusConnectionDialog::addAtomicConnection
 * Adds an atomic connection.
 * \param startConnectorName
 * \param endConnectorName
 */
void BusConnectionDialog::addAtomicConnection(QString startConnectorName, QString endConnectorName)
{
  LibraryTreeItem *pStartLibraryTreeItem = mpConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem();
  LibraryTreeItem *pStartParentLibraryTreeItem = pStartLibraryTreeItem->parent();
  LibraryTreeItem *pEndLibraryTreeItem = mpConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem();
  LibraryTreeItem *pEndParentLibraryTreeItem = pEndLibraryTreeItem->parent();

  Component *pStartComponent = pStartParentLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getComponentObject(startConnectorName);
  Component *pEndComponent = pEndParentLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getComponentObject(endConnectorName);

  if (pStartComponent && pEndComponent) {
    LineAnnotation *pNewConnectionLineAnnotation = new LineAnnotation("", 0, 0, mpGraphicsView);
    pNewConnectionLineAnnotation->updateShape(mpConnectionLineAnnotation);
    pNewConnectionLineAnnotation->setOMSConnectionType(oms_connection_single);
    pNewConnectionLineAnnotation->setStartComponentName(pStartComponent->getLibraryTreeItem()->getNameStructure());
    pNewConnectionLineAnnotation->setEndComponentName(pEndComponent->getLibraryTreeItem()->getNameStructure());
    AddConnectionCommand *pAddConnectionCommand = new AddConnectionCommand(pNewConnectionLineAnnotation, true);
    mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddConnectionCommand);
    if (pNewConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()->getOMSBusConnector()
        && pNewConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()->getOMSBusConnector()) {
      pNewConnectionLineAnnotation->setVisible(false);
    }
  }
}

/*!
 * \brief BusConnectionDialog::addBusConnection
 * Adds the bus connection and its corresponding atomic connections.
 */
void BusConnectionDialog::addBusConnection()
{
  if (mAddCase) {
    mpGraphicsView->getModelWidget()->beginMacro(Helper::addBusConnection);
  } else {
    mpGraphicsView->getModelWidget()->beginMacro(Helper::editBusConnection);
  }

  addOrDeleteAtomicConnections(mpInputOutputConnectionsModel);
  addOrDeleteAtomicConnections(mpOutputInputConnectionsModel);

  if (mAddCase
      && mpConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()->getOMSBusConnector()
      && mpConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()->getOMSBusConnector()) {
    LibraryTreeItem *pStartLibraryTreeItem = mpConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem();
    mpConnectionLineAnnotation->setStartComponentName(pStartLibraryTreeItem->getNameStructure());

    LibraryTreeItem *pEndLibraryTreeItem = mpConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem();
    mpConnectionLineAnnotation->setEndComponentName(pEndLibraryTreeItem->getNameStructure());

    mpConnectionLineAnnotation->setOMSConnectionType(oms_connection_bus);
    mpConnectionLineAnnotation->setLineThickness(0.5);

    AddConnectionCommand *pAddConnectionCommand = new AddConnectionCommand(mpConnectionLineAnnotation, true);
    mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddConnectionCommand);
  } else if (mAddCase) {
    /* When connecting a connector to a bus connector
     * We don't want a bus connection in that case so we have to delete it since the atomic connection
     * already created above.
     */
    mpGraphicsView->removeCurrentConnection();
  }

  mpGraphicsView->getModelWidget()->updateModelText();
  mpGraphicsView->getModelWidget()->endMacro();
  accept();
}

/*!
 * \class TLMBusConnectionDialog
 * \brief A dialog for creating a tlm bus connection.
 */
/*!
 * \brief TLMBusConnectionDialog::TLMBusConnectionDialog
 * \param pGraphicsView
 * \param pConnectionLineAnnotation
 */
TLMConnectionDialog::TLMConnectionDialog(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, bool addCase)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(addCase ? Helper::addTLMConnection : Helper::editTLMConnection));
  mpGraphicsView = pGraphicsView;
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mAddCase = addCase;
  // set heading
  mpHeading = Utilities::getHeadingLabel(addCase ? Helper::addTLMConnection : Helper::editTLMConnection);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // delay
  mpDelayLabel = new Label(tr("Delay:"));
  mpDelayTextBox = new QLineEdit(addCase ? "" : pConnectionLineAnnotation->getDelay());
  // alpha
  mpAlphaLabel = new Label(tr("Alpha:"));
  mpAlphaTextBox = new QLineEdit(addCase ? "" : pConnectionLineAnnotation->getAlpha());
  // Linear Impedance
  mpLinearImpedanceLabel = new Label(tr("Linear Impedance:"));
  mpLinearImpedanceTextBox = new QLineEdit(addCase ? "" : pConnectionLineAnnotation->getZf());
  // Angular Impedance
  mpAngularImpedanceLabel = new Label(tr("Angular Impedance:"));
  mpAngularImpedanceTextBox = new QLineEdit(addCase ? "" : pConnectionLineAnnotation->getZfr());
  // Add the validator
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpDelayTextBox->setValidator(pDoubleValidator);
  mpAlphaTextBox->setValidator(pDoubleValidator);
  mpLinearImpedanceTextBox->setValidator(pDoubleValidator);
  mpAngularImpedanceTextBox->setValidator(pDoubleValidator);
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addTLMConnection()));
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
  pMainLayout->addWidget(mpDelayLabel, 2, 0);
  pMainLayout->addWidget(mpDelayTextBox, 2, 1);
  pMainLayout->addWidget(mpAlphaLabel, 3, 0);
  pMainLayout->addWidget(mpAlphaTextBox, 3, 1);
  pMainLayout->addWidget(mpLinearImpedanceLabel, 4, 0);
  pMainLayout->addWidget(mpLinearImpedanceTextBox, 4, 1);
  pMainLayout->addWidget(mpAngularImpedanceLabel, 5, 0);
  pMainLayout->addWidget(mpAngularImpedanceTextBox, 5, 1);
  pMainLayout->addWidget(mpButtonBox, 6, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

void TLMConnectionDialog::addTLMConnection()
{
  if (mpDelayTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg(tr("Delay")), Helper::ok);
    return;
  }

  if (mpAlphaTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg(tr("Alpha")), Helper::ok);
    return;
  }

  if (mpLinearImpedanceTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg(tr("Linear Impedance")), Helper::ok);
    return;
  }

  if (mpAngularImpedanceTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALUE).arg(tr("Angular Impedance")), Helper::ok);
    return;
  }

  if (mAddCase) {
    mpConnectionLineAnnotation->setStartComponentName(mpConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()->getNameStructure());
    mpConnectionLineAnnotation->setEndComponentName(mpConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()->getNameStructure());
    mpConnectionLineAnnotation->setDelay(mpDelayTextBox->text());
    mpConnectionLineAnnotation->setAlpha(mpAlphaTextBox->text());
    mpConnectionLineAnnotation->setZf(mpLinearImpedanceTextBox->text());
    mpConnectionLineAnnotation->setZfr(mpAngularImpedanceTextBox->text());
    mpConnectionLineAnnotation->setOMSConnectionType(oms_connection_tlm);

    AddConnectionCommand *pAddConnectionCommand = new AddConnectionCommand(mpConnectionLineAnnotation, true);
    mpGraphicsView->getModelWidget()->getUndoStack()->push(pAddConnectionCommand);
  } else {
    oms_tlm_connection_parameters_t oldTLMParameters;
    oldTLMParameters.delay = mpConnectionLineAnnotation->getDelay().toDouble();
    oldTLMParameters.alpha = mpConnectionLineAnnotation->getAlpha().toDouble();
    oldTLMParameters.linearimpedance = mpConnectionLineAnnotation->getZf().toDouble();
    oldTLMParameters.angularimpedance = mpConnectionLineAnnotation->getZfr().toDouble();

    oms_tlm_connection_parameters_t newTLMParameters;
    newTLMParameters.delay = mpDelayTextBox->text().toDouble();
    newTLMParameters.alpha = mpAlphaTextBox->text().toDouble();
    newTLMParameters.linearimpedance = mpLinearImpedanceTextBox->text().toDouble();
    newTLMParameters.angularimpedance = mpAngularImpedanceTextBox->text().toDouble();

    UpdateTLMParametersCommand *pUpdateTLMParametersCommand = new UpdateTLMParametersCommand(mpConnectionLineAnnotation, oldTLMParameters,
                                                                                             newTLMParameters);
    mpGraphicsView->getModelWidget()->getUndoStack()->push(pUpdateTLMParametersCommand);
  }
  mpGraphicsView->getModelWidget()->updateModelText();
  accept();
}
