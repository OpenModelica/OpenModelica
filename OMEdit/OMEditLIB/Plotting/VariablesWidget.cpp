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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "VariablesWidget.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "util/read_matlab4.h"
#include "Plotting/PlotWindowContainer.h"
#include "Plotting/DiagramWindow.h"
#include "Simulation/SimulationDialog.h"
#include "Simulation/SimulationOutputWidget.h"
#include "TransformationalDebugger/TransformationsWidget.h"

#include <QObject>
#include <QDockWidget>
#include <QMessageBox>
#include <QMenu>
#include <QToolBar>

using namespace OMPlot;

namespace VariableItemData {
  enum VariableItemData {
    FILEPATH=0,
    FILENAME,
    NAME,
    DISPLAYNAME,
    TYPE,
    VALUE,
    UNIT,
    DISPLAYUNIT,
    DISPLAYUNITS,
    DESCRIPTION,
    TOOLTIP,
    ISMAINARRAY,
    USES,
    INITIAL_USES,
    DEFINED_IN,
    INFOFILE,
    EXISTINRESULTFILE
  };
}

/*!
 * \class VariablesTreeItem
 * \brief Contains the information about the result variable.
 */
/*!
 * \brief VariablesTreeItem::VariablesTreeItem
 * \param variableItemData see VariableItemData::VariableItemData
 * \param pParent
 * \param isRootItem
 */
VariablesTreeItem::VariablesTreeItem(const QVector<QVariant> &variableItemData, VariablesTreeItem *pParent, bool isRootItem)
{
  mpParentVariablesTreeItem = pParent;
  mIsRootItem = isRootItem;
  setVariableItemData(variableItemData);
  mValueChanged = false;
  mChecked = false;
  mEditable = false;
  mVariability = "";
}

VariablesTreeItem::~VariablesTreeItem()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
 * \brief VariablesTreeItem::setVariableItemData
 * Sets the values using the variable item data vector.
 * \param variableItemData
 */
void VariablesTreeItem::setVariableItemData(const QVector<QVariant> &variableItemData)
{
  mFilePath = variableItemData[VariableItemData::FILEPATH].toString();
  mFileName = variableItemData[VariableItemData::FILENAME].toString();
  mVariableName = variableItemData[VariableItemData::NAME].toString();
  mDisplayVariableName = variableItemData[VariableItemData::DISPLAYNAME].toString();
  mType = variableItemData[VariableItemData::TYPE].toString();
  mValue = variableItemData[VariableItemData::VALUE].toString();
  mUnit = variableItemData[VariableItemData::UNIT].toString();
  mDisplayUnit = variableItemData[VariableItemData::DISPLAYUNIT].toString();
  mPreviousUnit = variableItemData[VariableItemData::DISPLAYUNIT].toString();
  mDisplayUnits = variableItemData[VariableItemData::DISPLAYUNITS].toStringList();
  mDescription = variableItemData[VariableItemData::DESCRIPTION].toString();
  mToolTip = variableItemData[VariableItemData::TOOLTIP].toString();
  mIsMainArray = variableItemData[VariableItemData::ISMAINARRAY].toBool();
  mUses = variableItemData[VariableItemData::USES].toStringList();
  mInitialUses = variableItemData[VariableItemData::INITIAL_USES].toStringList();
  foreach(QVariant var, variableItemData[VariableItemData::DEFINED_IN].toList()) {
     mDefinedIn << var.value<IntStringPair>();
  }
  mInfoFileName = variableItemData[VariableItemData::INFOFILE].toString();
  mExistInResultFile = variableItemData[VariableItemData::EXISTINRESULTFILE].toBool();
}

/*!
 * \brief VariablesTreeItem::getPlotVariable
 * Returns the plot variable name.
 * \return
 */
QString VariablesTreeItem::getPlotVariable()
{
  return QString(mVariableName).remove(0, mFileName.length() + 1);
}

/*!
 * \brief VariablesTreeItem::isString
 * Returns true if variable type is String.
 * \return
 */
bool VariablesTreeItem::isString() const
{
  return mType.compare(QStringLiteral("String")) == 0;
}

/*!
 * \brief VariablesTreeItem::isMainArrayProtected
 * Checks if the array variable is protected.\n
 * For protected arrays we need to check the first index to see if it is protected or not.
 * \return
 */
bool VariablesTreeItem::isMainArrayProtected() const
{
  if (mChildren.size() > 0) {
    return mChildren.at(0)->getExistInResultFile();
  } else {
    return false;
  }
}

QIcon VariablesTreeItem::getVariableTreeItemIcon(QString name) const
{
  if (name.endsWith(".mat"))
    return QIcon(":/Resources/icons/mat.svg");
  else if (name.endsWith(".plt"))
    return QIcon(":/Resources/icons/plt.svg");
  else if (name.endsWith(".csv"))
    return QIcon(":/Resources/icons/csv.svg");
  else
    return QIcon(":/Resources/icons/interaction.svg");
}

void VariablesTreeItem::insertChild(int position, VariablesTreeItem *pVariablesTreeItem)
{
  mChildren.insert(position, pVariablesTreeItem);
}

VariablesTreeItem* VariablesTreeItem::child(int row)
{
  return mChildren.value(row);
}

void VariablesTreeItem::removeChildren()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

void VariablesTreeItem::removeChild(VariablesTreeItem *pVariablesTreeItem)
{
  mChildren.removeOne(pVariablesTreeItem);
}

int VariablesTreeItem::columnCount() const
{
  return 5;
}

/*!
 * \brief VariablesTreeItem::setData
 * Updates the item data.
 * \param column
 * \param value
 * \param role
 * \return
 */
bool VariablesTreeItem::setData(int column, const QVariant &value, int role)
{
  if (column == 0 && role == Qt::CheckStateRole) {
    if (value.toInt() == Qt::Checked) {
      setChecked(true);
    } else if (value.toInt() == Qt::Unchecked) {
      setChecked(false);
    }
    return true;
  } else if (column == 1 && role == Qt::EditRole) {
    if (mValue.compare(value.toString()) != 0) {
      mValueChanged = true;
      mValue = value.toString();
    }
    return true;
  } else if (column == 3 && role == Qt::EditRole) {
    if (mDisplayUnit.compare(Utilities::convertSymbolToUnit(value.toString())) != 0) {
      mPreviousUnit = mDisplayUnit;
      mDisplayUnit = Utilities::convertSymbolToUnit(value.toString());
    }
    return true;
  }
  return false;
}

QVariant VariablesTreeItem::data(int column, int role) const
{
  switch (column) {
    case 0:
      switch (role) {
        case Qt::DisplayRole:
          return mDisplayVariableName;
        case Qt::DecorationRole:
          return mIsRootItem ? getVariableTreeItemIcon(mVariableName) : QIcon();
        case Qt::ToolTipRole:
          return mToolTip;
        case Qt::CheckStateRole:
          /* Show checkbox for,
           * nodes without children i.e., leaf nodes and exist in the result file
           * nodes that are array
           */
          if (parent()->parent() && ((mChildren.size() == 0 && mExistInResultFile) || (mIsMainArray && isMainArrayProtected()))) {
            return isChecked() ? Qt::Checked : Qt::Unchecked;
           } else {
            return QVariant();
          }
        default:
          return QVariant();
      }
    case 1:
      switch (role) {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
        case Qt::EditRole:
          return mValue;
        case Qt::FontRole:
          if (isParameter()) {
            QFont font;
            font.setItalic(true);
            return font;
          } else {
            return QVariant();
          }
        default:
          return QVariant();
      }
    case 2:
      switch (role) {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return Utilities::convertUnitToSymbol(mUnit);
        default:
          return QVariant();
      }
    case 3:
      switch (role) {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return Utilities::convertUnitToSymbol(mDisplayUnit);
        default:
          return QVariant();
      }
    case 4:
      switch (role) {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return mDescription;
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

int VariablesTreeItem::row() const
{
  if (mpParentVariablesTreeItem)
    return mpParentVariablesTreeItem->mChildren.indexOf(const_cast<VariablesTreeItem*>(this));

  return 0;
}

VariablesTreeItem* VariablesTreeItem::rootParent()
{
  // since we have global mpRootVariablesTreeItem so we return one level down from this function in order to get the top level item.
  VariablesTreeItem *pVariablesTreeItem, *pVariablesTreeItem1;
  pVariablesTreeItem = this;
  pVariablesTreeItem1 = this;
  while (pVariablesTreeItem->mpParentVariablesTreeItem) {
    pVariablesTreeItem1 = pVariablesTreeItem;
    pVariablesTreeItem = pVariablesTreeItem->mpParentVariablesTreeItem;
  }
  return pVariablesTreeItem1;
}

/*!
 * \brief VariablesTreeItem::getValue
 * Returns the value in the desired unit or
 * an empty value in case of conversion error.
 * \param fromUnit
 * \param toUnit
 * \return
 */
QVariant VariablesTreeItem::getValue(QString fromUnit, QString toUnit)
{
  QString value = "";
  if (fromUnit.compare(toUnit) == 0) {
    value = mValue;
  } else {
    OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(fromUnit, toUnit);
    if (convertUnit.unitsCompatible) {
      bool ok = false;
      qreal realValue = mValue.toDouble(&ok);
      if (ok) {
        realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
        value = StringHandler::number(realValue);
      }
    }
  }
  return value;
}

VariablesTreeModel::VariablesTreeModel(VariablesTreeView *pVariablesTreeView)
  : QAbstractItemModel(pVariablesTreeView)
{
  mpVariablesTreeView = pVariablesTreeView;
  QVector<QVariant> headers;
  headers << "" << "" << Helper::variables << Helper::variables << "" << tr("Value") << tr("Unit") << tr("Display Unit")
          << QStringList() << Helper::description << "" << false << QStringList() << QStringList() << QStringList() << "dummy.json" << false;
  mpRootVariablesTreeItem = new VariablesTreeItem(headers, 0, true);
  mpActiveVariablesTreeItem = 0;
}

int VariablesTreeModel::columnCount(const QModelIndex &parent) const
{
  if (parent.isValid())
    return static_cast<VariablesTreeItem*>(parent.internalPointer())->columnCount();
  else
    return mpRootVariablesTreeItem->columnCount();
}

int VariablesTreeModel::rowCount(const QModelIndex &parent) const
{
  VariablesTreeItem *pParentVariablesTreeItem;
  if (parent.column() > 0)
    return 0;

  if (!parent.isValid())
    pParentVariablesTreeItem = mpRootVariablesTreeItem;
  else
    pParentVariablesTreeItem = static_cast<VariablesTreeItem*>(parent.internalPointer());
  return pParentVariablesTreeItem->mChildren.size();
}

QVariant VariablesTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole)
    return mpRootVariablesTreeItem->data(section);
  return QVariant();
}

QModelIndex VariablesTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent))
    return QModelIndex();

  VariablesTreeItem *pParentVariablesTreeItem;

  if (!parent.isValid())
    pParentVariablesTreeItem = mpRootVariablesTreeItem;
  else
    pParentVariablesTreeItem = static_cast<VariablesTreeItem*>(parent.internalPointer());

  VariablesTreeItem *pChildVariablesTreeItem = pParentVariablesTreeItem->child(row);
  if (pChildVariablesTreeItem)
    return createIndex(row, column, pChildVariablesTreeItem);
  else
    return QModelIndex();
}

QModelIndex VariablesTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid())
    return QModelIndex();

  VariablesTreeItem *pChildVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  VariablesTreeItem *pParentVariablesTreeItem = pChildVariablesTreeItem->parent();
  if (pParentVariablesTreeItem == mpRootVariablesTreeItem)
    return QModelIndex();

  return createIndex(pParentVariablesTreeItem->row(), 0, pParentVariablesTreeItem);
}

/*!
 * \brief VariablesTreeModel::setData
 * Updates the model data.
 * \param index
 * \param value
 * \param role
 * \return
 */
bool VariablesTreeModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (!pVariablesTreeItem) {
    return false;
  }
  QString displayUnit = pVariablesTreeItem->getDisplayUnit();
  bool result = pVariablesTreeItem->setData(index.column(), value, role);
  if (index.column() == 0 && role == Qt::CheckStateRole) {
    if (!signalsBlocked()) {
      PlottingPage *pPlottingPage = OptionsDialog::instance()->getPlottingPage();
      emit itemChecked(index, pPlottingPage->getCurveThickness(), pPlottingPage->getCurvePattern(), QApplication::keyboardModifiers().testFlag(Qt::ShiftModifier));
    }
  } else if (index.column() == 1) { // value
    if (!signalsBlocked()) {
      VariablesTreeItem *pVariablesRootTreeItem = pVariablesTreeItem->rootParent();
      if (pVariablesRootTreeItem->getSimulationOptions().isInteractiveSimulation()) {
        emit valueEntered(index);
      }
    }
  } else if (index.column() == 3) { // display unit
    if (!signalsBlocked() && displayUnit.compare(Utilities::convertSymbolToUnit(value.toString())) != 0) {
      emit unitChanged(index);
    }
  }
  updateVariablesTreeItem(pVariablesTreeItem);
  return result;
}

QVariant VariablesTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return QVariant();

  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  return pVariablesTreeItem->data(index.column(), role);
}

Qt::ItemFlags VariablesTreeModel::flags(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return Qt::ItemFlags();
  }

  Qt::ItemFlags flags = Qt::ItemIsEnabled | Qt::ItemIsSelectable;
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if ((index.column() == 0 && pVariablesTreeItem && pVariablesTreeItem->parent() != mpRootVariablesTreeItem)
      && ((pVariablesTreeItem->mChildren.size() == 0 && pVariablesTreeItem->getExistInResultFile())
          || (pVariablesTreeItem->isMainArray() && pVariablesTreeItem->isMainArrayProtected()))) {
    flags |= Qt::ItemIsUserCheckable;
    // Disable string type since is not stored in the result file and we can't plot them
    if (pVariablesTreeItem->isString()) {
      flags &= ~Qt::ItemIsEnabled;
    }
  } else if (index.column() == 1 && pVariablesTreeItem && pVariablesTreeItem->mChildren.size() == 0 && pVariablesTreeItem->isEditable()) {
    flags |= Qt::ItemIsEditable;
  } else if (index.column() == 3) {
    flags |= Qt::ItemIsEditable;
  }

  return flags;
}

VariablesTreeItem* VariablesTreeModel::findVariablesTreeItem(const QString &name, VariablesTreeItem *pVariablesTreeItem, Qt::CaseSensitivity caseSensitivity) const
{
  if (pVariablesTreeItem->getVariableName().compare(name, caseSensitivity) == 0) {
    return pVariablesTreeItem;
  }
  for (int i = pVariablesTreeItem->mChildren.size(); --i >= 0; ) {
    if (VariablesTreeItem *item = findVariablesTreeItem(name, pVariablesTreeItem->mChildren.at(i), caseSensitivity)) {
      return item;
    }
  }
  return 0;
}

/*!
 * \brief VariablesTreeModel::findVariablesTreeItemOneLevel
 * Finds the VariablesTreeItem based on the name and case sensitivity only in the children of pVariablesTreeItem
 * \param name
 * \param pVariablesTreeItem
 * \param caseSensitivity
 * \return
 */
VariablesTreeItem* VariablesTreeModel::findVariablesTreeItemOneLevel(const QString &name, VariablesTreeItem *pVariablesTreeItem, Qt::CaseSensitivity caseSensitivity) const
{
  if (!pVariablesTreeItem) {
    pVariablesTreeItem = mpRootVariablesTreeItem;
  }
  for (int i = pVariablesTreeItem->mChildren.size(); --i >= 0; ) {
    if (pVariablesTreeItem->mChildren.at(i)->getVariableName().compare(name, caseSensitivity) == 0) {
      return pVariablesTreeItem->mChildren.at(i);
    }
  }
  return 0;
}

/*!
 * \brief VariablesTreeModel::findVariablesTreeItemFromClassNameTopLevel
 * Finds the VariablesTreeItem based on the className and case sensitivity only in the top level
 * \param className
 * \return
 */
VariablesTreeItem *VariablesTreeModel::findVariablesTreeItemFromClassNameTopLevel(const QString &className) const
{
  for (int i = mpRootVariablesTreeItem->mChildren.size(); --i >= 0; ) {
    if (mpRootVariablesTreeItem->mChildren.at(i)->getSimulationOptions().getClassName().compare(className) == 0) {
      return mpRootVariablesTreeItem->mChildren.at(i);
    }
  }
  return 0;
}

/*!
 * \brief VariablesTreeModel::updateVariablesTreeItem
 * Triggers a view update for the VariablesTreeItem in the Variable Browser.
 * \param pVariablesTreeItem
 */
void VariablesTreeModel::updateVariablesTreeItem(VariablesTreeItem *pVariablesTreeItem)
{
  QModelIndex index = variablesTreeItemIndex(pVariablesTreeItem);
  emit dataChanged(index, index);
}

QModelIndex VariablesTreeModel::variablesTreeItemIndex(const VariablesTreeItem *pVariablesTreeItem) const
{
  return variablesTreeItemIndexHelper(pVariablesTreeItem, mpRootVariablesTreeItem, QModelIndex());
}

/*!
 * \brief VariablesTreeModel::parseInitXml
 * Parses the model_init.xml file and returns the scalar variables information.
 * \param xmlReader
 * \param simulationOptions
 * \param variablesList
 */
void VariablesTreeModel::parseInitXml(QXmlStreamReader &xmlReader, SimulationOptions simulationOptions, QStringList* variablesList)
{
  // if the variables list is empty then add the xml scalar variables to the list
  bool addVariablesToList = variablesList->isEmpty();
  bool protectedVariables = simulationOptions.getProtectedVariables();
  bool ignoreHideResult = simulationOptions.getIgnoreHideResult();
  /* We'll parse the XML until we reach end of it.*/
  while (!xmlReader.atEnd() && !xmlReader.hasError()) {
    /* Read next element.*/
    QXmlStreamReader::TokenType token = xmlReader.readNext();
    /* If token is just StartDocument, we'll go to next.*/
    if (token == QXmlStreamReader::StartDocument) {
      continue;
    }
    /* If token is StartElement, we'll see if we can read it.*/
    if (token == QXmlStreamReader::StartElement) {
      /* If it's named ScalarVariable, we'll dig the information from there.*/
      if (xmlReader.name() == QString("ScalarVariable")) {
        QHash<QString, QString> scalarVariable = parseScalarVariable(xmlReader);
        bool hideResultIsTrue = scalarVariable.value("hideResult").compare(QStringLiteral("true")) == 0;
        // we need the following flag becasuse hideResult value can be empty.
        bool hideResultIsFalse = scalarVariable.value("hideResult").compare(QStringLiteral("false")) == 0;
        bool isProtected = scalarVariable.value("isProtected").compare(QStringLiteral("true")) == 0;
        bool isEncrypted = scalarVariable.value("isEncrypted").compare(QStringLiteral("true")) == 0;
        /* Skip variables,
         *   1. If ignoreHideResult is not set and hideResult is true.
         *   2. If emit protected flag is false and variable is protected OR if variable belongs to an encrytped model.
         *      If hideResult is false for protected variable then we show it.
         */
        if ((ignoreHideResult || !hideResultIsTrue)
            && ((protectedVariables && !isEncrypted) || (!isProtected || (!ignoreHideResult && hideResultIsFalse)))) {
          mScalarVariablesHash.insert(scalarVariable.value("name"),scalarVariable);
          if (addVariablesToList) {
            variablesList->append(scalarVariable.value("name"));
          }
        }
      }
    }
  }
  xmlReader.clear();
}

/*!
 * \brief VariablesTreeModel::removeVariableTreeItem
 * Removes the VariablesTreeItem.
 * \param variable
 * \param closeInteractivePlotWindow
 * \return
 */
bool VariablesTreeModel::removeVariableTreeItem(QString variable, bool closeInteractivePlotWindow)
{
  VariablesTreeItem *pVariablesTreeItem = findVariablesTreeItem(variable, mpRootVariablesTreeItem);
  if (pVariablesTreeItem) {
    int row = pVariablesTreeItem->row();
    beginRemoveRows(variablesTreeItemIndex(pVariablesTreeItem->parent()), row, row);
    pVariablesTreeItem->removeChildren();
    VariablesTreeItem *pParentVariablesTreeItem = pVariablesTreeItem->parent();
    pParentVariablesTreeItem->removeChild(pVariablesTreeItem);
    MainWindow::instance()->getSimulationDialog()->removeInteractiveSimulation(pVariablesTreeItem->getSimulationOptions().isInteractiveSimulation(),
                                                                               pVariablesTreeItem->getFileName(), closeInteractivePlotWindow);
    /* Reset the active VariablesTreeItem so the contorls are disabled when initializeVisualization is called.
     * The can controls can be enabled if diagramWindow is active and we have a corresponding VariablesTreeItem for it.
     */
    if (pVariablesTreeItem == mpActiveVariablesTreeItem) {
      mpActiveVariablesTreeItem = 0;
    }
    delete pVariablesTreeItem;
    mpVariablesTreeView->getVariablesWidget()->initializeVisualization();
    endRemoveRows();
    mpVariablesTreeView->getVariablesWidget()->findVariables();
    return true;
  }
  return false;
}

/*!
 * \brief VariablesTreeModel::insertVariablesItems
 * Inserts the variables in the Variable Browser.
 * \param fileName
 * \param filePath
 * \param variablesList
 * \param simulationOptions
 * \return
 */
bool VariablesTreeModel::insertVariablesItems(QString fileName, QString filePath, QStringList variablesList, SimulationOptions simulationOptions)
{
  QString toolTip;
  if (simulationOptions.isInteractiveSimulation()) {
    toolTip = tr("Interactive Simulation\nPort: %1").arg(simulationOptions.getInteractiveSimulationPortNumber());
  } else {
    toolTip = tr("Simulation Result File: %1\n%2: %3/%4").arg(fileName).arg(Helper::fileLocation).arg(filePath).arg(fileName);
  }
  QRegularExpression resultTypeRegExp("(\\.mat|\\.plt|\\.csv|_res.mat|_res.plt|_res.csv)");
  QString text(QString(fileName).remove(resultTypeRegExp));
  QVector<QVariant> variabledata;
  variabledata << filePath << fileName << fileName << text << "" << "" << "" << "" << QStringList() << "" << toolTip << false << QStringList() << QStringList() << QStringList() << "dummy.json" << false;

  bool existingTopVariableTreeItem;
  VariablesTreeItem *pTopVariablesTreeItem = findVariablesTreeItemOneLevel(variabledata.at(VariableItemData::NAME).toString(), mpRootVariablesTreeItem);
  if (pTopVariablesTreeItem) {
    pTopVariablesTreeItem->setVariableItemData(variabledata);
    pTopVariablesTreeItem->setSimulationOptions(simulationOptions);
    existingTopVariableTreeItem = true;
  } else {
    pTopVariablesTreeItem = new VariablesTreeItem(variabledata, mpRootVariablesTreeItem, true);
    pTopVariablesTreeItem->setSimulationOptions(simulationOptions);
    int row = rowCount();
    QModelIndex index = variablesTreeItemIndex(mpRootVariablesTreeItem);
    beginInsertRows(index, row, row);
    mpRootVariablesTreeItem->insertChild(row, pTopVariablesTreeItem);
    endInsertRows();
    existingTopVariableTreeItem = false;
  }
  // set the newly inserted VariablesTreeItem active
  PlotWindowContainer *pPlotWindowContainer = MainWindow::instance()->getPlotWindowContainer();
  if (!(pPlotWindowContainer->currentSubWindow() && pPlotWindowContainer->isDiagramWindow(pPlotWindowContainer->currentSubWindow()->widget()))) {
    mpActiveVariablesTreeItem = pTopVariablesTreeItem;
    mpVariablesTreeView->getVariablesWidget()->initializeVisualization();
  }
  /* open the model_init.xml file for reading */
  mScalarVariablesHash.clear();
  QString initFileName, infoFileName;
  if (simulationOptions.isValid()) {
    initFileName = QString("%1_init.xml").arg(simulationOptions.getOutputFileName());
    infoFileName = QString("%1_info.json").arg(simulationOptions.getOutputFileName());
  } else {
    initFileName = QString("%1_init.xml").arg(text);
    infoFileName = QString("%1_info.json").arg(text);
  }
  bool readingVariablesFromInitFile = false;
  QFile initFile(QString("%1%2%3").arg(filePath, QDir::separator(), initFileName));
  if (initFile.exists()) {
    if (initFile.open(QIODevice::ReadOnly)) {
      QXmlStreamReader initXmlReader(&initFile);
      readingVariablesFromInitFile = variablesList.isEmpty();
      parseInitXml(initXmlReader, simulationOptions, &variablesList);
      initFile.close();
    } else {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(initFile.fileName())
                                                            .arg(initFile.errorString()), Helper::scriptingKind, Helper::errorLevel));
    }
  }

  QMap<QString,QSet<QString>> usedInitialVars;
  QMap<QString,QSet<QString>> usedVars;
  QMap<QString,QList<IntStringPair>> definedIn;

  JsonDocument jsonDocument;
  if (jsonDocument.parse(QString("%1%2%3").arg(filePath, QDir::separator(), infoFileName))) {
    QVariantMap result = jsonDocument.result.toMap();
    QVariantList eqs = result["equations"].toList();
    for (int i=0; i<eqs.size(); i++) {
      QVariantMap veq = eqs[i].toMap();
      bool isInitial = (veq.find("section") != veq.end() && veq["section"] == QString("initial"));

      if (veq.find("defines") != veq.end()) {
        QStringList defines = Utilities::variantListToStringList(veq["defines"].toList());
        foreach (QString v1, defines) {
          if (!definedIn.contains(v1)) {
            definedIn[v1] = QList<IntStringPair>();
          }
          definedIn[v1] << IntStringPair(veq["eqIndex"].toInt(), veq.find("section") != veq.end() ? veq["section"].toString() : QString("unknown"));
          if (veq.find("uses") != veq.end()) {
            QStringList uses = Utilities::variantListToStringList(veq["uses"].toList());
            foreach (QString v2, uses) {
              if (isInitial) {
                usedInitialVars[v1].insert(v2);
              } else {
                usedVars[v1].insert(v2);
              }
            }
          }
        }
      }
    }
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, jsonDocument.errorString, Helper::scriptingKind, Helper::errorLevel));
    MainWindow::instance()->printStandardOutAndErrorFilesMessages();
  }
  /* open the .mat file */
  ModelicaMatReader matReader;
  matReader.file = 0;
  const char *msg[] = {""};
  if (fileName.endsWith(".mat")) {
    //Read in mat file
    if (0 != (msg[0] = omc_new_matlab4_reader(QString(filePath + "/" + fileName).toUtf8().constData(), &matReader))) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(filePath + "/" + fileName)
                                                            .arg(QString(msg[0])), Helper::scriptingKind, Helper::errorLevel));
    }
  }
  // create hash based VariableNode
  VariableNode *pTopVariableNode = new VariableNode(variabledata);
  // remove time from variables list
  variablesList.removeOne("time");
  /* Fixes issue #7551
   * Add the $cpuTime variable to the list if cpu time flag is set.
   * We read the variables from model_init.xml file that doesn't contain $cpuTime variable but is present in model_res.mat file.
   */
  if (simulationOptions.isValid() && simulationOptions.getCPUTime()) {
    variablesList.append("$cpuTime");
  }
  /* Issue #7632 Variable Browser show non-existing variable
   * Show the non-existing variables as we want to use them for resimulation e.g., string variables.
   * But don't make them checkable so user can't plot them.
   */
  QStringList variableListFromResultFile;
  if (readingVariablesFromInitFile && !simulationOptions.isInteractiveSimulation()) {
    variableListFromResultFile = MainWindow::instance()->getOMCProxy()->readSimulationResultVars(QString("%1%2%3").arg(filePath, QDir::separator(), fileName));
  }
  QStringList variables;
  foreach (QString plotVariable, variablesList) {
    QString parentVariable = "";
    if (plotVariable.startsWith("der(")) {
      QString str = plotVariable;
      str.chop((str.lastIndexOf("der(")/4)+1);
      variables = StringHandler::makeVariablePartsWithInd(str.mid(str.lastIndexOf("der(") + 4));
    } else if (plotVariable.startsWith("previous(")) {
      QString str = plotVariable;
      str.chop((str.lastIndexOf("previous(")/9)+1);
      variables = StringHandler::makeVariablePartsWithInd(str.mid(str.lastIndexOf("previous(") + 9));
    } else {
      variables = StringHandler::makeVariablePartsWithInd(plotVariable);
    }
    int count = 1;
    VariableNode *pParentVariableNode = 0;
    foreach (QString variable, variables) {
      if (count == 1) { /* first loop iteration */
        pParentVariableNode = pTopVariableNode;
      }
      QString findVariable;
      // if last item of derivative or 2nd last item of derivative array
      if ((plotVariable.startsWith("der(")) && ((variables.size() == count) || ((variables.size() - 1 == count) && (variables.at(variables.size() - 1).startsWith("["))))) {
        if (parentVariable.isEmpty()) {
          findVariable = QString("%1.%2").arg(fileName ,StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der("));
        } else {
          findVariable = QString("%1.%2").arg(fileName ,StringHandler::joinDerivativeAndPreviousVariable(plotVariable, parentVariable + "." + variable, "der("));
        }
      }
      // if last item of previous or 2nd last item of previous array
      else if ((plotVariable.startsWith("previous(")) && ((variables.size() == count) || ((variables.size() - 1 == count) && (variables.at(variables.size() - 1).startsWith("["))))) {
        if (parentVariable.isEmpty()) {
          findVariable = QString("%1.%2").arg(fileName ,StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "previous("));
        } else {
          findVariable = QString("%1.%2").arg(fileName ,StringHandler::joinDerivativeAndPreviousVariable(plotVariable, parentVariable + "." + variable, "previous("));
        }
      } else {
        if (parentVariable.isEmpty()) {
          findVariable = QString("%1.%2").arg(fileName, variable);
        } else {
          findVariable = QString("%1.%2.%3").arg(fileName, parentVariable, variable);
        }
      }
      // if its the last item then don't try to find the item as we will always fail to find it
      if (variables.size() != count) {
        pParentVariableNode = VariableNode::findVariableNode(findVariable, pParentVariableNode);
        if (pParentVariableNode) {
          QString addVar = variable;
          if (count == 1) {
            parentVariable = addVar;
          } else {
            parentVariable += "." + addVar;
          }
          count++;
          continue;
        }
      }
      /* If pParentVariablesTreeItem is 0 and it is first loop iteration then use pTopVariablesTreeItem as parent.
       * If loop iteration is not first and pParentVariablesTreeItem is 0 then find the parent item.
       */
      if (!pParentVariableNode && count > 1) {
        pParentVariableNode = VariableNode::findVariableNode(fileName + "." + parentVariable, pTopVariableNode);
      }
      // Just make sure parent is not NULL
      if (!pParentVariableNode) {
        pParentVariableNode = pTopVariableNode;
      }
      // data
      QVector<QVariant> variableData;
      // if last item of array
      if (variables.size() == count && QRegularExpression(QRegularExpression::anchoredPattern(Helper::arrayIndexRegularExpression)).match(variable).hasMatch()) {
        variableData << filePath << fileName << fileName + "." + plotVariable << variable;
      }
      // if 2nd last item of derivative array
      else if ((plotVariable.startsWith("der(")) && ((variables.size() - 1 == count) && (variables.at(variables.size() - 1).startsWith("[")))) {
        QString derivatieArrayVar = variable;
        if (!parentVariable.isEmpty()) {
          derivatieArrayVar = parentVariable + "." + variable;
        }
        derivatieArrayVar = QString("%1.%2").arg(fileName ,StringHandler::joinDerivativeAndPreviousVariable(plotVariable, derivatieArrayVar, "der("));
        variableData << filePath << fileName << derivatieArrayVar << StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der(");
      }
      // if last item of derivative
      else if ((plotVariable.startsWith("der(")) && (variables.size() == count)) {
        variableData << filePath << fileName << fileName + "." + plotVariable << StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der(");
      }
      // if 2nd last item of previous array
      else if ((plotVariable.startsWith("previous(")) && ((variables.size() == count) || ((variables.size() - 1 == count) && (variables.at(variables.size() - 1).startsWith("["))))) {
        QString previousArrayVar = variable;
        if (!parentVariable.isEmpty()) {
          previousArrayVar = parentVariable + "." + variable;
        }
        previousArrayVar = QString("%1.%2").arg(fileName ,StringHandler::joinDerivativeAndPreviousVariable(plotVariable, previousArrayVar, "previous("));
        variableData << filePath << fileName << previousArrayVar << StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "previous(");
      }
      // if last item of previous
      else if ((plotVariable.startsWith("previous(")) && ((variables.size() == count) || ((variables.size() - 1 == count) && (variables.at(variables.size() - 1).startsWith("["))))) {
        variableData << filePath << fileName << fileName + "." + plotVariable << StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "previous(");
      } else {
        variableData << filePath << fileName << pParentVariableNode->mVariableNodeData.at(VariableItemData::NAME).toString() + "." + variable << variable;
      }

      /* find the variable in the xml file */
      QString variableToFind = variableData.at(VariableItemData::NAME).toString();
      variableToFind.remove(QRegularExpression(pTopVariablesTreeItem->getVariableName() + "."));
      /* get the variable information i.e value, unit, displayunit, description */
      QString type, value, variability, unit, displayUnit, description;
      bool changeAble = false;
      getVariableInformation(&matReader, variableToFind, &type, &value, &changeAble, &variability, &unit, &displayUnit, &description);
      /* set the variable type and value */
      variableData << type << value;
      /* set the variable unit */
      variableData << unit;
      unit = variableData.at(VariableItemData::UNIT).toString();
      /* set the variable displayUnit */
      variableData << displayUnit;
      /* set the variable displayUnits */
      if ((variableData.at(VariableItemData::TYPE).toString().compare(QStringLiteral("String")) != 0) && !unit.isEmpty()) {
        QStringList displayUnits, displayUnitOptions;
        displayUnits << unit;
        if (!variableData.at(VariableItemData::DISPLAYUNIT).toString().isEmpty()) {
          displayUnitOptions << variableData.at(VariableItemData::DISPLAYUNIT).toString();
          /* convert value to displayUnit */
          OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(unit, variableData.at(VariableItemData::DISPLAYUNIT).toString());
          if (convertUnit.unitsCompatible) {
            bool ok = true;
            qreal realValue = variableData.at(VariableItemData::VALUE).toDouble(&ok);
            if (ok) {
              realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
              variableData[VariableItemData::VALUE] = StringHandler::number(realValue);
            }
          }
        } else { /* use unit as displayUnit */
          variableData[VariableItemData::DISPLAYUNIT] = unit;
        }
        Utilities::addDefaultDisplayUnit(unit, displayUnitOptions);
        displayUnitOptions.removeDuplicates();
        displayUnits << displayUnitOptions;
        variableData << displayUnits;
      } else {
        variableData << QStringList();
      }
      /* set the variable description */
      variableData << description;
      /* construct tooltip text */
      if (simulationOptions.isInteractiveSimulation()) {
        variableData << tr("Variable: %1\nVariability: %2").arg(variableToFind).arg(variability);
      } else {
        variableData << tr("File: %1/%2\nVariable: %3\nVariability: %4").arg(filePath).arg(fileName).arg(variableToFind).arg(variability);
      }
      /*is main array*/
      if (variables.size() == count+1 && QRegularExpression(QRegularExpression::anchoredPattern(Helper::arrayIndexRegularExpression)).match(variables.last()).hasMatch()) {
        variableData << true;
      } else {
        variableData << false;
      }
      QString findVariableNoFileName = findVariable.right(findVariable.size()-fileName.size()-1);

      if (usedVars.find(findVariableNoFileName) != usedVars.end()) {
        QStringList lst = QStringList(usedVars[findVariableNoFileName].values());
        lst << findVariableNoFileName;
        variableData << lst;
      } else {
        variableData << QStringList(findVariableNoFileName);
      }
      if (usedInitialVars.find(findVariableNoFileName) != usedInitialVars.end()) {
        QStringList lst = QStringList(usedInitialVars[findVariableNoFileName].values());
        lst << findVariableNoFileName;
        variableData << lst;
      } else {
        variableData << QStringList(findVariableNoFileName);
      }
      QVariantList variantDefinedIn;
      if (definedIn.find(findVariableNoFileName) != definedIn.end()) {
        foreach (IntStringPair pair, definedIn[findVariableNoFileName]) {
          variantDefinedIn << QVariant::fromValue(pair);
        }
      } else {
        variantDefinedIn << QVariant::fromValue(IntStringPair(0,QString("")));
      }
      variableData << variantDefinedIn;
      variableData << infoFileName;
      bool variableExistsInResultFile = true;
      if (readingVariablesFromInitFile && !variableListFromResultFile.contains(variableToFind)) {
        variableExistsInResultFile = false;
      }
      variableData << variableExistsInResultFile;

      VariableNode *pVariableNode = new VariableNode(variableData);
      pVariableNode->mEditable = changeAble;
      pVariableNode->mVariability = variability;
      pParentVariableNode->mChildren.insert(variableData.at(VariableItemData::NAME).toString(), pVariableNode);
      pParentVariableNode = pVariableNode;

      if (count == 1) {
        parentVariable = variable;
      } else {
        parentVariable += "." + variable;
      }
      count++;
    }
  }
  // remove VariablesTreeItems only when result already exists
  if (existingTopVariableTreeItem) {
    filterVariableTreeItem(pTopVariableNode, pTopVariablesTreeItem);
  }
  // insert variables to VariablesTreeModel
  insertVariablesItems(pTopVariableNode, pTopVariablesTreeItem);
  // Delete VariableNode
  delete pTopVariableNode;
  /* close the .mat file */
  if (fileName.endsWith(".mat") && matReader.file) {
    omc_free_matlab4_reader(&matReader);
  }
  /* Ticket #3016.
   * If you only have one model the message "You must select a class to re-simulate" is annoying.
   * A default behavior of selecting the (single) model would be good.
   * The following line selects the result tree top level item.
   */
  QModelIndex idx = variablesTreeItemIndex(pTopVariablesTreeItem);
  idx = mpVariablesTreeView->getVariablesWidget()->getVariableTreeProxyModel()->mapFromSource(idx);
  mpVariablesTreeView->expand(idx);
  mpVariablesTreeView->setCurrentIndex(idx);
  mpVariablesTreeView->setFocus(Qt::ActiveWindowFocusReason);
  MainWindow::instance()->enableReSimulationToolbar(MainWindow::instance()->getVariablesDockWidget()->isVisible());

  return existingTopVariableTreeItem;
}

void VariablesTreeModel::unCheckVariables(VariablesTreeItem *pVariablesTreeItem)
{
  QList<VariablesTreeItem*> items = pVariablesTreeItem->mChildren;
  for (int i = 0 ; i < items.size() ; i++) {
    items[i]->setData(0, Qt::Unchecked, Qt::CheckStateRole);
    unCheckVariables(items[i]);
  }
}

void VariablesTreeModel::plotAllVariables(VariablesTreeItem *pVariablesTreeItem, PlotWindow *pPlotWindow)
{
  QList<VariablesTreeItem*> variablesTreeItems = pVariablesTreeItem->mChildren;
  if (variablesTreeItems.size() == 0) {
    QModelIndex index = variablesTreeItemIndex(pVariablesTreeItem);
    OMPlot::PlotCurve *pPlotCurve = 0;
    foreach (OMPlot::PlotCurve *curve, pPlotWindow->getPlot()->getPlotCurvesList()) {
      if (curve->getNameStructure().compare(pVariablesTreeItem->getVariableName()) == 0) {
        pPlotCurve = curve;
        break;
      }
    }
    setData(index, Qt::Checked, Qt::CheckStateRole);
    mpVariablesTreeView->getVariablesWidget()->plotVariables(index, pPlotWindow->getCurveWidth(), pPlotWindow->getCurveStyle(), false, pPlotCurve);
  } else {
    for (int i = 0 ; i < variablesTreeItems.size() ; i++) {
      plotAllVariables(variablesTreeItems[i], pPlotWindow);
    }
  }
}

/*!
 * \brief VariablesTreeModel::variablesTreeItemIndexHelper
 * Helper function for VariablesTreeModel::variablesTreeItem()
 * \param pVariablesTreeItem
 * \param pParentVariablesTreeItem
 * \param parentIndex
 * \return
 */
QModelIndex VariablesTreeModel::variablesTreeItemIndexHelper(const VariablesTreeItem *pVariablesTreeItem, const VariablesTreeItem *pParentVariablesTreeItem,
                                                             const QModelIndex &parentIndex) const
{
  if (pVariablesTreeItem == pParentVariablesTreeItem) {
    return parentIndex;
  }
  for (int i = pParentVariablesTreeItem->mChildren.size(); --i >= 0; ) {
    const VariablesTreeItem *childItem = pParentVariablesTreeItem->mChildren.at(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = variablesTreeItemIndexHelper(pVariablesTreeItem, childItem, childIndex);
    if (index.isValid()) {
      return index;
    }
  }
  return QModelIndex();
}

void VariablesTreeModel::filterVariableTreeItem(VariableNode *pParentVariableNode, VariablesTreeItem *pParentVariablesTreeItem)
{
  foreach (VariablesTreeItem *pVariablesTreeItem, pParentVariablesTreeItem->mChildren) {
    VariableNode *pVariableNode = pParentVariableNode->mChildren.value(pVariablesTreeItem->getVariableName(), 0);
    // if we fail to find the variable node then remove that pVariablesTreeItem
    if (!pVariableNode) {
      QModelIndex index = variablesTreeItemIndex(pParentVariablesTreeItem);
      int row = pVariablesTreeItem->row();
      beginRemoveRows(index, row, row);
      pParentVariablesTreeItem->removeChild(pVariablesTreeItem);
      delete pVariablesTreeItem;
      endRemoveRows();
    } else {
      filterVariableTreeItem(pVariableNode, pVariablesTreeItem);
    }
  }
}

/*!
 * \brief VariablesTreeModel::insertVariablesItems
 * Creates VariablesTreeItem using VariableNode and adds them to the VariablesTreeView.
 * \param pParentVariableNode
 * \param pParentVariablesTreeItem
 */
void VariablesTreeModel::insertVariablesItems(VariableNode *pParentVariableNode, VariablesTreeItem *pParentVariablesTreeItem)
{
  if (pParentVariableNode && !pParentVariableNode->mChildren.isEmpty()) {
    QHash<QString, VariableNode*>::const_iterator iterator = pParentVariableNode->mChildren.constBegin();
    QVector<VariableNode*> variableNodes;
    while (iterator != pParentVariableNode->mChildren.constEnd()) {
      VariableNode *pVariableNode = iterator.value();
      VariablesTreeItem *pVariablesTreeItem = findVariablesTreeItemOneLevel(pVariableNode->mVariableNodeData.at(VariableItemData::NAME).toString(), pParentVariablesTreeItem);
      // if we find the exisitng VariablesTreeItem then we update it otherwise we add it to variableNodes vector
      if (pVariablesTreeItem) {
        pVariablesTreeItem->setVariableItemData(pVariableNode->mVariableNodeData);
        pVariablesTreeItem->setEditable(pVariableNode->mEditable);
        pVariablesTreeItem->setVariability(pVariableNode->mVariability);
      } else {
        variableNodes.append(pVariableNode);
      }
      ++iterator;
    }
    // Insert the new variableNodes.
    if (!variableNodes.isEmpty()) {
      QModelIndex index = variablesTreeItemIndex(pParentVariablesTreeItem);
      int row = rowCount(index);
      beginInsertRows(index, row, row + variableNodes.size() - 1);
      foreach (VariableNode *pVariableNode, variableNodes) {
        VariablesTreeItem *pVariablesTreeItem = new VariablesTreeItem(pVariableNode->mVariableNodeData, pParentVariablesTreeItem);
        pVariablesTreeItem->setEditable(pVariableNode->mEditable);
        pVariablesTreeItem->setVariability(pVariableNode->mVariability);
        pParentVariablesTreeItem->insertChild(row++, pVariablesTreeItem);
      }
      endInsertRows();
    }

    foreach (VariablesTreeItem *pVariablesTreeItem, pParentVariablesTreeItem->mChildren) {
      VariableNode *pVariableNode = pParentVariableNode->mChildren.value(pVariablesTreeItem->getVariableName());
      insertVariablesItems(pVariableNode, pVariablesTreeItem);
    }
  }
}

/*!
 * \brief VariablesTreeModel::parseScalarVariable
 * Parses the scalar variable.
 * Helper function for VariablesTreeModel::parseInitXml
 * \param xmlReader
 * \return
 */
QHash<QString, QString> VariablesTreeModel::parseScalarVariable(QXmlStreamReader &xmlReader)
{
  QHash<QString, QString> scalarVariable;
  /* Let's check that we're really getting a ScalarVariable. */
  if (xmlReader.tokenType() != QXmlStreamReader::StartElement && xmlReader.name() == QString("ScalarVariable")) {
    return scalarVariable;
  }
  /* Let's get the attributes for ScalarVariable */
  QXmlStreamAttributes attributes = xmlReader.attributes();
  /* Read the ScalarVariable attributes. */
  scalarVariable["name"] = attributes.value("name").toString();
  scalarVariable["description"] = attributes.value("description").toString();
  scalarVariable["isValueChangeable"] = attributes.value("isValueChangeable").toString();
  scalarVariable["variability"] = attributes.value("variability").toString();
  scalarVariable["hideResult"] = attributes.value("hideResult").toString();
  scalarVariable["isProtected"] = attributes.value("isProtected").toString();
  scalarVariable["isEncrypted"] = attributes.value("isEncrypted").toString();
  /* Read the next element i.e Real, Integer, Boolean etc. */
  xmlReader.readNext();
  while (!(xmlReader.tokenType() == QXmlStreamReader::EndElement && xmlReader.name() == QString("ScalarVariable"))) {
    if (xmlReader.tokenType() == QXmlStreamReader::StartElement) {
      scalarVariable["type"] = xmlReader.name().toString();
      QXmlStreamAttributes attributes = xmlReader.attributes();
      scalarVariable["start"] = attributes.value("start").toString();
      scalarVariable["unit"] = attributes.value("unit").toString();
      scalarVariable["displayUnit"] = attributes.value("displayUnit").toString();
    }
    xmlReader.readNext();
  }
  return scalarVariable;
}

/*!
 * \brief VariablesTreeModel::getVariableInformation
 * Returns the variable information like value, unit, displayunit and description.
 * \param pMatReader
 * \param variableToFind
 * \param type
 * \param value
 * \param changeAble
 * \param variability
 * \param unit
 * \param displayUnit
 * \param description
 */
void VariablesTreeModel::getVariableInformation(ModelicaMatReader *pMatReader, QString variableToFind, QString *type, QString *value, bool *changeAble,
                                                QString *variability, QString *unit, QString *displayUnit, QString *description)
{
  QHash<QString, QString> hash = mScalarVariablesHash.value(variableToFind);
  if (hash.value("name").compare(variableToFind) == 0) {
    *type = hash.value("type");
    *changeAble = hash.value("isValueChangeable").compare(QStringLiteral("true")) == 0;
    *variability = hash.value("variability");
    if (*changeAble) {
      *value = hash.value("start");
    } else { /* Read the final value of the variable. Only mat result files are supported. */
      if ((pMatReader->file != NULL) && strcmp(pMatReader->fileName, "")) {
        *value = "";
        ModelicaMatVariable_t *var = omc_matlab4_find_var(pMatReader, variableToFind.toUtf8().constData());
        double res = 0.0;
        if (var && !omc_matlab4_val(&res, pMatReader, var, omc_matlab4_stopTime(pMatReader))) {
          *value = StringHandler::number(res);
        }
      }
    }
    *unit = hash.value("unit");
    *displayUnit = hash.value("displayUnit");
    *description = hash.value("description");
  }
}

/*!
 * \brief VariablesTreeModel::removeVariableTreeItem
 * Slot activated when pDeleteResultAction triggered SIGNAL is raised.
 * Removes a VariablesTreeItem
 */
void VariablesTreeModel::removeVariableTreeItem()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    removeVariableTreeItem(pAction->data().toString(), true);
    emit variableTreeItemRemoved(pAction->data().toString());
  }
}

/*!
 * \brief VariablesTreeModel::enableTimeControls
 * Slots activated when pEnableTimeControls triggered SIGNAL is raised.
 * Enables the time controls.
 */
void VariablesTreeModel::enableTimeControls()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    VariablesTreeItem *pVariablesTreeItem = findVariablesTreeItem(pAction->data().toString(), mpRootVariablesTreeItem);
    if (pVariablesTreeItem) {
      mpActiveVariablesTreeItem = pVariablesTreeItem;
      mpVariablesTreeView->getVariablesWidget()->initializeVisualization();
    }
  }
}

void VariablesTreeModel::filterDependencies()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    QStringList uses = pAction->data().toStringList();
    QStringList escapedUses;
    foreach(QString s, uses) {
      escapedUses << s.replace("[","[[]").replace("]","[]]").replace("[[[]]","[[]").replace("(","[(]").replace(")","[)]").replace(".","[.]");
    }
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    QRegularExpression regexp("^" + escapedUses.join("|") + "$");
    mpVariablesTreeView->getVariablesWidget()->getVariableTreeProxyModel()->setFilterRegularExpression(regexp);
#else
    QRegExp regexp("^" + escapedUses.join("|") + "$");
    mpVariablesTreeView->getVariablesWidget()->getVariableTreeProxyModel()->setFilterRegExp(regexp);
#endif
  }
}

void VariablesTreeModel::openTransformationsBrowser()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    QVariantList list = pAction->data().toList();
    QString fileName = list[0].toString();
    int equationIndex = list[1].toInt();
    if (QFileInfo(fileName).exists()) {
      TransformationsWidget *pTransformationsWidget = MainWindow::instance()->showTransformationsWidget(fileName, false);
      QTreeWidgetItem *pTreeWidgetItem = pTransformationsWidget->findEquationTreeItem(equationIndex);
      if (pTreeWidgetItem) {
        pTransformationsWidget->getEquationsTreeWidget()->clearSelection();
        pTransformationsWidget->getEquationsTreeWidget()->setCurrentItem(pTreeWidgetItem);
      }
      pTransformationsWidget->fetchEquationData(equationIndex);
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(fileName), QMessageBox::Ok);
    }
  }
}

/*!
 * \class VariableTreeProxyModel
 * \brief A sort filter proxy model for Variable Browser.
 */
/*!
 * \brief VariableTreeProxyModel::VariableTreeProxyModel
 * \param parent
 */
VariableTreeProxyModel::VariableTreeProxyModel(QObject *parent)
  : QSortFilterProxyModel(parent)
{
}

/*!
 * \brief VariableTreeProxyModel::filterAcceptsRow
 * Filters the VariablesTreeItems based on the filter reguler expression.
 * \param sourceRow
 * \param sourceParent
 * \return
 */
bool VariableTreeProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  if (!filterRegularExpression().pattern().isEmpty()) {
#else
  if (!filterRegExp().isEmpty()) {
#endif
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    if (index.isValid()) {
      // if any of children matches the filter, then current index matches the filter as well
      int rows = sourceModel()->rowCount(index);
      for (int i = 0 ; i < rows ; ++i) {
        if (filterAcceptsRow(i, index)) {
          return true;
        }
      }
      // check current index itself
      VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
      if (pVariablesTreeItem) {
        QString variableName = pVariablesTreeItem->getVariableName();
        variableName.remove(QRegularExpression("(\\.mat|\\.plt|\\.csv|_res.mat|_res.plt|_res.csv)"));
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        return variableName.contains(filterRegularExpression());
#else
        return variableName.contains(filterRegExp());
#endif
      } else {
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        return sourceModel()->data(index).toString().contains(filterRegularExpression());
#else
        return sourceModel()->data(index).toString().contains(filterRegExp());
#endif
      }
      QString key = sourceModel()->data(index, filterRole()).toString();
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
      return key.contains(filterRegularExpression());
#else
      return key.contains(filterRegExp());
#endif
    }
  }
  return QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
}

/*!
 * \brief VariableTreeProxyModel::lessThan
 * Sorts the VariablesTreeItems using the natural sort.
 * \param left
 * \param right
 * \return
 */
bool VariableTreeProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
  QVariant l = (left.model() ? left.model()->data(left) : QVariant());
  QVariant r = (right.model() ? right.model()->data(right) : QVariant());
  return StringHandler::naturalSort(l.toString(), r.toString());
}

VariablesTreeView::VariablesTreeView(VariablesWidget *pVariablesWidget)
  : QTreeView(pVariablesWidget)
{
  mpVariablesWidget = pVariablesWidget;
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(Helper::treeIndentation);
  setIconSize(Helper::iconSize);
  setContextMenuPolicy(Qt::CustomContextMenu);
  setExpandsOnDoubleClick(false);
  setEditTriggers(QAbstractItemView::AllEditTriggers);
  setUniformRowHeights(true);
}

/*!
 * \brief VariablesTreeView::mouseReleaseEvent
 * Reimplementation of QTreeView::mouseReleaseEvent\n
 * Checks if user clicks on the first column then check/uncheck the corresponsing checkbox of the column.\n
 * Otherwise calls the QTreeView::mouseReleaseEvent
 * \param event
 */
void VariablesTreeView::mouseReleaseEvent(QMouseEvent *event)
{
  QModelIndex index = indexAt(event->pos());
  if (index.isValid() &&
      index.column() == 0 &&
      index.parent().isValid() &&
      index.flags() & Qt::ItemIsUserCheckable &&
      event->button() == Qt::LeftButton) {
    if (visualRect(index).contains(event->pos())) {
      index = mpVariablesWidget->getVariableTreeProxyModel()->mapToSource(index);
      VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
      if (pVariablesTreeItem && !pVariablesTreeItem->isString()) {
        if (pVariablesTreeItem->isChecked()) {
          mpVariablesWidget->getVariablesTreeModel()->setData(index, Qt::Unchecked, Qt::CheckStateRole);
        } else {
          mpVariablesWidget->getVariablesTreeModel()->setData(index, Qt::Checked, Qt::CheckStateRole);
        }
      }
      return;
    }
  }
  QTreeView::mouseReleaseEvent(event);
}

/*!
 * \brief VariablesTreeView::keyPressEvent
 * Reimplementation of keypressevent.
 * \param event
 */
void VariablesTreeView::keyPressEvent(QKeyEvent *event)
{
  QModelIndexList indexes = selectionModel()->selectedIndexes();
  if (!indexes.isEmpty()) {
    QModelIndex index = indexes.at(0);
    index = mpVariablesWidget->getVariableTreeProxyModel()->mapToSource(index);
    VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
    if (event->key() == Qt::Key_Delete && pVariablesTreeItem->isRootItem()) {
      mpVariablesWidget->getVariablesTreeModel()->removeVariableTreeItem(pVariablesTreeItem->getVariableName(), true);
      return;
    }
  }
  QTreeView::keyPressEvent(event);
}

VariablesWidget::VariablesWidget(QWidget *pParent)
  : QWidget(pParent)
{
  // tree search filters
  mpTreeSearchFilters = new TreeSearchFilters(this);
  mpTreeSearchFilters->getFilterTextBox()->setPlaceholderText(Helper::filterVariables);
  mpTreeSearchFilters->getFilterTimer()->setInterval(OptionsDialog::instance()->getPlottingPage()->getFilterIntervalSpinBox()->value() * 1000);
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(returnPressed()), SLOT(findVariables()));
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(textEdited(QString)), mpTreeSearchFilters->getFilterTimer(), SLOT(start()));
  connect(mpTreeSearchFilters->getFilterTimer(), SIGNAL(timeout()), SLOT(findVariables()));
  connect(mpTreeSearchFilters->getCaseSensitiveCheckBox(), SIGNAL(toggled(bool)), SLOT(findVariables()));
  connect(mpTreeSearchFilters->getSyntaxComboBox(), SIGNAL(currentIndexChanged(int)), SLOT(findVariables()));
  // simulation time label and combobox
  mpSimulationTimeLabel = new Label(tr("Simulation Time Unit"));
  mpSimulationTimeComboBox = new QComboBox;
  mpSimulationTimeComboBox->addItem("s");
  mpSimulationTimeComboBox->addItems(MainWindow::instance()->getOMCProxy()->getDerivedUnits("s"));
  connect(mpSimulationTimeComboBox, SIGNAL(currentIndexChanged(int)), SLOT(timeUnitChanged(int)));
  // simulation time slider
  mSliderRange = 1000;
  mpTimeControlsDescriptionLabel = new Label;
  mpTimeControlsDescriptionLabel->setElideMode(Qt::ElideMiddle);
  mpSimulationTimeSlider = new QSlider(Qt::Horizontal);
  mpSimulationTimeSlider->setRange(0, mSliderRange);
  mpSimulationTimeSlider->setSliderPosition(0);
  connect(mpSimulationTimeSlider, SIGNAL(valueChanged(int)), SLOT(simulationTimeChanged(int)));
  // toolbar
  mpToolBar = new QToolBar;
  int toolbarIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value();
  mpToolBar->setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  // rewind action
  mpRewindAction = new QAction(QIcon(":/Resources/icons/initialize.svg"), tr("Rewind"), this);
  mpRewindAction->setStatusTip(tr("Rewind the visualization to the start"));
  connect(mpRewindAction, SIGNAL(triggered()), SLOT(rewindVisualization()));
  // play action
  mpPlayAction = new QAction(QIcon(":/Resources/icons/play_animation.svg"), Helper::animationPlay, this);
  mpPlayAction->setStatusTip(tr("Play the visualization"));
  connect(mpPlayAction, SIGNAL(triggered()), SLOT(playVisualization()));
  // pause action
  mpPauseAction = new QAction(QIcon(":/Resources/icons/pause.svg"), Helper::animationPause, this);
  mpPauseAction->setStatusTip(tr("Pause the visualization"));
  connect(mpPauseAction, SIGNAL(triggered()), SLOT(pauseVisualization()));
  // time
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  pDoubleValidator->setBottom(0);
  mpTimeLabel = new Label;
  mpTimeLabel->setText(tr("Time:"));
  mpTimeTextBox = new QLineEdit("0.0");
  mpTimeTextBox->setMaximumHeight(toolbarIconSize);
  mpTimeTextBox->setValidator(pDoubleValidator);
  connect(mpTimeTextBox, SIGNAL(returnPressed()), SLOT(visualizationTimeChanged()));
  // speed
  mpSpeedLabel = new Label;
  mpSpeedLabel->setText(Helper::speed);
  mpSpeedComboBox = new QComboBox;
  mpSpeedComboBox->setEditable(true);
  mpSpeedComboBox->addItems(Helper::speedOptions.split(","));
  mpSpeedComboBox->setCurrentIndex(3);
  mpSpeedComboBox->setMaximumHeight(toolbarIconSize);
  mpSpeedComboBox->setValidator(pDoubleValidator);
  mpSpeedComboBox->setCompleter(0);
  connect(mpSpeedComboBox, SIGNAL(currentIndexChanged(int)), SLOT(visualizationSpeedChanged()));
  connect(mpSpeedComboBox->lineEdit(), SIGNAL(textChanged(QString)), SLOT(visualizationSpeedChanged()));
  // add actions to toolbar
  mpToolBar->addAction(mpRewindAction);
  mpToolBar->addSeparator();
  mpToolBar->addAction(mpPlayAction);
  mpToolBar->addAction(mpPauseAction);
  mpToolBar->addSeparator();
  mpToolBar->addWidget(mpTimeLabel);
  mpToolBar->addWidget(mpTimeTextBox);
  mpToolBar->addSeparator();
  mpToolBar->addWidget(mpSpeedLabel);
  mpToolBar->addWidget(mpSpeedComboBox);
  // time manager
  mpTimeManager = new TimeManager(0.0, 0.0, 0.0, 0.0, 0.1, 0.0, 1.0);
  mpTimeManager->setStartTime(0.0);
  mpTimeManager->setEndTime(1.0);
  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  mpTimeManager->setPause(true);
  connect(mpTimeManager->getUpdateSceneTimer(), SIGNAL(timeout()), SLOT(incrementVisualization()));
  // create variables tree widget
  mpVariablesTreeView = new VariablesTreeView(this);
  mpVariablesTreeModel = new VariablesTreeModel(mpVariablesTreeView);
  mpVariableTreeProxyModel = new VariableTreeProxyModel;
  mpVariableTreeProxyModel->setDynamicSortFilter(true);
  mpVariableTreeProxyModel->setSourceModel(mpVariablesTreeModel);
  mpVariablesTreeView->setModel(mpVariableTreeProxyModel);
  mpVariablesTreeView->setColumnWidth(0, 150);
  mpVariablesTreeView->setColumnWidth(1, 70);
  mpVariablesTreeView->setColumnWidth(2, 50);
  mpVariablesTreeView->setColumnWidth(3, 70);
  mpVariablesTreeView->setColumnHidden(2, true); // hide Unit column
  mpLastActiveSubWindow = 0;
  mModelicaMatReader.file = 0;
  mpCSVData = 0;
  // create the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpTreeSearchFilters, 0, 0, 1, 2);
  pMainLayout->addWidget(mpSimulationTimeLabel, 1, 0);
  pMainLayout->addWidget(mpSimulationTimeComboBox, 1, 1);
  pMainLayout->addWidget(mpTimeControlsDescriptionLabel, 2, 0, 1, 2);
  pMainLayout->addWidget(mpSimulationTimeSlider, 3, 0, 1, 2);
  pMainLayout->addWidget(mpToolBar, 4, 0, 1, 2);
  pMainLayout->addWidget(mpVariablesTreeView, 5, 0, 1, 2);
  setLayout(pMainLayout);
  connect(mpTreeSearchFilters->getExpandAllButton(), SIGNAL(clicked()), mpVariablesTreeView, SLOT(expandAll()));
  connect(mpTreeSearchFilters->getCollapseAllButton(), SIGNAL(clicked()), mpVariablesTreeView, SLOT(collapseAll()));
  connect(mpVariablesTreeModel, SIGNAL(rowsInserted(QModelIndex,int,int)), mpVariableTreeProxyModel, SLOT(invalidate()));
  connect(mpVariablesTreeModel, SIGNAL(rowsRemoved(QModelIndex,int,int)), mpVariableTreeProxyModel, SLOT(invalidate()));
  connect(mpVariablesTreeModel, SIGNAL(itemChecked(QModelIndex,qreal,int,bool)), SLOT(plotVariables(QModelIndex,qreal,int,bool)));
  connect(mpVariablesTreeModel, SIGNAL(unitChanged(QModelIndex)), SLOT(unitChanged(QModelIndex)));
  connect(mpVariablesTreeModel, SIGNAL(valueEntered(QModelIndex)), SLOT(valueEntered(QModelIndex)));
  connect(mpVariablesTreeView, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  connect(MainWindow::instance()->getPlotWindowContainer(), SIGNAL(subWindowActivated(QMdiSubWindow*)), this, SLOT(updateVariablesTree(QMdiSubWindow*)));
  connect(mpVariablesTreeModel, SIGNAL(variableTreeItemRemoved(QString)), MainWindow::instance()->getPlotWindowContainer(), SLOT(updatePlotWindows(QString)));
  //connect(mpVariablesTreeModel, SIGNAL(clicked(QModelIndex)), this, SLOT(selectInteractivePlotWindow(QModelIndex)));
  //connect(mpVariablesTreeModel, SIGNAL(itemChecked(QModelIndex)), SLOT(selectInteractivePlotWindow(QModelIndex)));
  enableVisualizationControls(false);
}

/*!
 * \brief VariablesWidget::enableVisualizationControls
 * Enables/Disables the visualization controls.
 * \param enable
 */
void VariablesWidget::enableVisualizationControls(bool enable)
{
  mpSimulationTimeSlider->setEnabled(enable);
  mpToolBar->setEnabled(enable);
}

/*!
 * \brief VariablesWidget::insertVariablesItemsToTree
 * Inserts the result variables in the Variable Browser.
 * \param fileName
 * \param filePath
 * \param variablesList
 * \param simulationOptions
 */
void VariablesWidget::insertVariablesItemsToTree(QString fileName, QString filePath, QStringList variablesList, SimulationOptions simulationOptions)
{
  MainWindow::instance()->showProgressBar();
  MainWindow::instance()->getStatusBar()->showMessage(tr("Loading simulation result variables"));
  // In order to improve the response time of insertVariablesItems function we should disbale sorting and clear the filter.
  mpVariablesTreeView->setSortingEnabled(false);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  mpVariableTreeProxyModel->setFilterRegularExpression(QRegularExpression(""));
#else
  mpVariableTreeProxyModel->setFilterRegExp(QRegExp(""));
#endif
  // insert the plot variables
  bool updateVariables = mpVariablesTreeModel->insertVariablesItems(fileName, filePath, variablesList, simulationOptions);
  // update the plot variables tree
  if (updateVariables) {
    variablesUpdated();
  }
  initializeVisualization();
  mpVariablesTreeView->setSortingEnabled(true);
  mpVariablesTreeView->sortByColumn(0, Qt::AscendingOrder);
  // since we cleared the filter above so we need to apply it back.
  findVariables();
  MainWindow::instance()->getStatusBar()->clearMessage();
  MainWindow::instance()->hideProgressBar();
}

/*!
 * \brief VariablesWidget::variablesUpdated
 * Updates the already plotted variables after simulation with new values.
 */
void VariablesWidget::variablesUpdated()
{
  foreach (QMdiSubWindow *pSubWindow, MainWindow::instance()->getPlotWindowContainer()->subWindowList(QMdiArea::StackingOrder)) {
    PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
    if (pPlotWindow) { // we can have an AnimateWindow there as well so always check
      foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
        if (pPlotWindow->isPlot() || pPlotWindow->isPlotArray()) {
          QString curveNameStructure = pPlotCurve->getNameStructure();
          VariablesTreeItem *pVariableTreeItem;
          pVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(curveNameStructure, mpVariablesTreeModel->getRootVariablesTreeItem());
          if (pVariableTreeItem) {
            pPlotCurve->detach();
            bool state = mpVariablesTreeModel->blockSignals(true);
            QModelIndex index = mpVariablesTreeModel->variablesTreeItemIndex(pVariableTreeItem);
            mpVariablesTreeModel->setData(index, Qt::Checked, Qt::CheckStateRole);
            plotVariables(index, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), false, pPlotCurve, pPlotWindow);
            mpVariablesTreeModel->blockSignals(state);
          } else {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
          }
        } else if (pPlotWindow->isPlotParametric() || pPlotWindow->isPlotArrayParametric()) {
          QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
          VariablesTreeItem *pXVariableTreeItem;
          pXVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(xVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
          QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
          VariablesTreeItem *pYVariableTreeItem;
          pYVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(yVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
          if (pXVariableTreeItem && pYVariableTreeItem) {
            pPlotCurve->detach();
            bool state = mpVariablesTreeModel->blockSignals(true);
            QModelIndex xIndex = mpVariablesTreeModel->variablesTreeItemIndex(pXVariableTreeItem);
            mpVariablesTreeModel->setData(xIndex, Qt::Checked, Qt::CheckStateRole);
            plotVariables(xIndex, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), true, pPlotCurve, pPlotWindow);
            QModelIndex yIndex = mpVariablesTreeModel->variablesTreeItemIndex(pYVariableTreeItem);
            mpVariablesTreeModel->setData(yIndex, Qt::Checked, Qt::CheckStateRole);
            plotVariables(yIndex, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), false, pPlotCurve, pPlotWindow);
            mpVariablesTreeModel->blockSignals(state);
          } else {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
          }
        }
      }
      pPlotWindow->updatePlot();
    }
  }
  updateVariablesTreeHelper(MainWindow::instance()->getPlotWindowContainer()->currentSubWindow());
}

void VariablesWidget::updateVariablesTreeHelper(QMdiSubWindow *pSubWindow)
{
  /* We always pause the visualization if we reach this function
   * This function can be reached via following ways,
   * When active PlotWindow is changed.
   * When active PlotWindow variables are updated.
   * When clearing the PlotWindow curves
   */
  pauseVisualization();
  if (!pSubWindow) {
    return;
  }
  // first clear all the check boxes in the tree
  bool state = mpVariablesTreeModel->blockSignals(true);
  mpVariablesTreeModel->unCheckVariables(mpVariablesTreeModel->getRootVariablesTreeItem());
  mpVariablesTreeModel->blockSignals(state);
  // all plotwindows are closed down then simply return
  if (MainWindow::instance()->getPlotWindowContainer()->subWindowList().size() == 0) {
    return;
  }
  PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
  if (pPlotWindow) { // we can have an AnimateWindow there as well so always check
    // update the simulation time unit
    mpSimulationTimeComboBox->setCurrentIndex(mpSimulationTimeComboBox->findText(pPlotWindow->getTimeUnit(), Qt::MatchExactly));
    // now loop through the curves and tick variables in the tree whose curves are on the plot
    state = mpVariablesTreeModel->blockSignals(true);
    foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
      VariablesTreeItem *pVariablesTreeItem;
      if (pPlotWindow->isPlot() || pPlotWindow->isPlotArray()) {
        QString variable = pPlotCurve->getNameStructure();
        pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(variable, mpVariablesTreeModel->getRootVariablesTreeItem());
        if (pVariablesTreeItem) {
          mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Checked, Qt::CheckStateRole);
        }
      } else if (pPlotWindow->isPlotParametric() || pPlotWindow->isPlotArrayParametric()) {
        // check the xvariable
        QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
        pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(xVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
        if (pVariablesTreeItem)
          mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Checked, Qt::CheckStateRole);
        // check the y variable
        QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
        pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(yVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
        if (pVariablesTreeItem)
          mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Checked, Qt::CheckStateRole);
      } else if (pPlotWindow->isPlotInteractive()) {
        QString variable = pPlotCurve->getNameStructure();
        pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(variable, mpVariablesTreeModel->getRootVariablesTreeItem());
        if (pVariablesTreeItem) {
          mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Checked, Qt::CheckStateRole);
        }
        // if a simulation was left running, make a replot
        pPlotWindow->updatePlot();
      }
    }
    mpVariablesTreeModel->blockSignals(state);
  }
  /* invalidate the view so that the items show the updated values. */
  mpVariableTreeProxyModel->invalidate();
}

/*!
 * \brief VariablesWidget::readVariablesAndUpdateXML
 * Reads the updated values
 * \sa VariablesWidget::findVariableAndUpdateValue()
 * \param pVariablesTreeItem
 * \param outputFileName
 * \param variables
 */
void VariablesWidget::readVariablesAndUpdateXML(VariablesTreeItem *pVariablesTreeItem, QString outputFileName,
                                                QHash<QString, QHash<QString, QString> > *variables)
{
  for (int i = 0 ; i < pVariablesTreeItem->mChildren.size() ; i++) {
    VariablesTreeItem *pChildVariablesTreeItem = pVariablesTreeItem->child(i);
    if (pChildVariablesTreeItem->isEditable() && pChildVariablesTreeItem->isValueChanged()) {
      //QString value = pChildVariablesTreeItem->data(1, Qt::DisplayRole).toString();
      /* Ticket #2250, 4031
       * We need to convert the value to base unit since the values stored in init xml are always in base unit.
       */
      QString value = pChildVariablesTreeItem->getValue(pChildVariablesTreeItem->getDisplayUnit(),
                                                        pChildVariablesTreeItem->getUnit()).toString();
      QString variableToFind = pChildVariablesTreeItem->getVariableName();
      variableToFind.remove(QRegularExpression(outputFileName + "."));
      QHash<QString, QString> hash;
      hash["name"] = variableToFind;
      hash["value"] = value;
      variables->insert(variableToFind, hash);
    }
    readVariablesAndUpdateXML(pChildVariablesTreeItem, outputFileName, variables);
  }
}

/*!
 * \brief VariablesWidget::findVariableAndUpdateValue
 * Writes the updated values in the init xml dom
 * \param xmlDocument
 * \param variables
 */
void VariablesWidget::findVariableAndUpdateValue(QDomDocument xmlDocument, QHash<QString, QHash<QString, QString> > variables)
{
  /* if no variables are changed. */
  if (variables.empty()) {
    return;
  }
  /* update the variables */
  int count = 0;
  QDomNodeList scalarVariable = xmlDocument.elementsByTagName("ScalarVariable");
  for (int i = 0; i < scalarVariable.size(); i++) {
    if (count >= variables.size()) {
      break;
    }
    QDomElement element = scalarVariable.at(i).toElement();
    if (!element.isNull()) {
      QHash<QString, QString> hash = variables.value(element.attribute("name"));
      if (element.attribute("name").compare(hash["name"]) == 0) {
        count++;
        QDomElement el = scalarVariable.at(i).firstChild().toElement();
        if (!el.isNull()) {
          el.setAttribute("start", hash["value"]);
        }
      }
    }
  }
}

void VariablesWidget::reSimulate(bool showSetup)
{
  QModelIndexList indexes = mpVariablesTreeView->selectionModel()->selectedIndexes();
  if (indexes.isEmpty()) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             tr("You must select a class to re-simulate."), QMessageBox::Ok);
    return;
  }
  QModelIndex index = indexes.at(0);
  index = mpVariableTreeProxyModel->mapToSource(index);
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  pVariablesTreeItem = pVariablesTreeItem->rootParent();
  SimulationOptions simulationOptions = pVariablesTreeItem->getSimulationOptions();
  if (simulationOptions.isValid()) {
    MainWindow::instance()->getSimulationDialog()->removeInteractiveSimulation(simulationOptions.isInteractiveSimulation(), pVariablesTreeItem->getFileName(), false);
    simulationOptions.setReSimulate(true);
    updateInitXmlFile(pVariablesTreeItem, simulationOptions);
    if (showSetup) {
      MainWindow::instance()->getSimulationDialog()->show(0, true, simulationOptions);
    } else {
      MainWindow::instance()->getSimulationDialog()->reSimulate(simulationOptions);
    }
  } else {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             tr("You cannot re-simulate this class.<br />This is just a result file loaded via menu <b>File->Open Result File(s)</b>."), QMessageBox::Ok);
  }
}

/*!
 * \brief VariablesWidget::updateInitXmlFile
 * Updates the model_init.xml file
 * \param pVariablesTreeItem
 * \param simulationOptions
 */
void VariablesWidget::updateInitXmlFile(VariablesTreeItem *pVariablesTreeItem, SimulationOptions simulationOptions)
{
  /* Update the _init.xml file with new values. */
  /* open the model_init.xml file for writing */
  QString initFileName = QString(simulationOptions.getOutputFileName()).append("_init.xml");
  QFile initFile(QString(simulationOptions.getWorkingDirectory()).append(QDir::separator()).append(initFileName));
  QDomDocument initXmlDocument;
  if (initFile.open(QIODevice::ReadOnly)) {
    if (initXmlDocument.setContent(&initFile)) {
      if (pVariablesTreeItem) {
        QHash<QString, QHash<QString, QString> > variables;
        readVariablesAndUpdateXML(pVariablesTreeItem, simulationOptions.getFullResultFileName(), &variables);
        findVariableAndUpdateValue(initXmlDocument, variables);
      }
    } else {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Unable to set the content of QDomDocument from file %1")
                                                            .arg(initFile.fileName()), Helper::scriptingKind, Helper::errorLevel));
    }
    initFile.close();
    initFile.open(QIODevice::WriteOnly | QIODevice::Truncate);
    QTextStream textStream(&initFile);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    textStream.setEncoding(QStringConverter::Utf8);
#else
    textStream.setCodec(Helper::utf8.toUtf8().constData());
#endif
    textStream.setGenerateByteOrderMark(false);
    textStream << initXmlDocument.toString();
    initFile.close();
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(initFile.fileName())
                                                          .arg(initFile.errorString()), Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief VariablesWidget::initializeVisualization
 * Initializes the TimeManager for visualization.
 */
void VariablesWidget::initializeVisualization()
{
  VariablesTreeItem *pVariablesTreeItem = 0;
  PlotWindowContainer *pPlotWindowContainer = MainWindow::instance()->getPlotWindowContainer();
  bool isDiagramWindow = (pPlotWindowContainer->currentSubWindow() && pPlotWindowContainer->isDiagramWindow(pPlotWindowContainer->currentSubWindow()->widget())
                          && pPlotWindowContainer->getDiagramWindow() && pPlotWindowContainer->getDiagramWindow()->getModelWidget()
                          && pPlotWindowContainer->getDiagramWindow()->getModelWidget()->getLibraryTreeItem());
  if (mpVariablesTreeModel->getActiveVariablesTreeItem() || isDiagramWindow) {
    // if we came in due to diagram window then find the VariablesTreeItem
    if (isDiagramWindow) {
      const QString className = pPlotWindowContainer->getDiagramWindow()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItemFromClassNameTopLevel(className);
    } else {
      pVariablesTreeItem = mpVariablesTreeModel->getActiveVariablesTreeItem();
    }
    if (pVariablesTreeItem) {
      // close any result file before opening a new one
      closeResultFile();
      // Open the file for reading
      double startTime = 0.0;
      double stopTime = 0.0;
      openResultFile(pVariablesTreeItem, startTime, stopTime);
      // Initialize the time manager
      mpTimeManager->setStartTime(startTime);
      mpTimeManager->setEndTime(stopTime);
      mpTimeManager->setVisTime(mpTimeManager->getStartTime());
      mpTimeManager->setPause(true);
      // reset the visualization controls
      mpTimeControlsDescriptionLabel->setText(tr("Enabled for %1").arg(pVariablesTreeItem->getVariableName()));
      mpTimeTextBox->setText(QString::number(mpTimeManager->getVisTime()));
      mpSimulationTimeSlider->setValue(mpTimeManager->getTimeFraction());
      enableVisualizationControls(true);
      updateVisualization();
    }
  }

  if (!pVariablesTreeItem) {
    mpTimeControlsDescriptionLabel->setText("");
    rewindVisualization();
    enableVisualizationControls(false);
  }
}

/*!
 * \brief VariablesWidget::readVariableValue
 * Reads the variable value at specific time.
 * \param variable
 * \param time
 * \param reportError
 * \return variable value
 */
QPair<double, bool> VariablesWidget::readVariableValue(QString variable, double time, bool reportError)
{
  double value = 0.0;
  bool found = false;

  if (mModelicaMatReader.file) {
    ModelicaMatVariable_t* var = omc_matlab4_find_var(&mModelicaMatReader, variable.toUtf8().constData());
    if (var) {
      omc_matlab4_val(&value, &mModelicaMatReader, var, time);
      found = true;
    } else {
    }
  } else if (mpCSVData) {
    double *timeDataSet = read_csv_dataset(mpCSVData, "time");
    if (timeDataSet) {
      for (int i = 0 ; i < mpCSVData->numsteps ; i++) {
        if (QString::number(timeDataSet[i]).compare(QString::number(time)) == 0) {
          double *varDataSet = read_csv_dataset(mpCSVData, variable.toUtf8().constData());
          if (varDataSet) {
            value = varDataSet[i];
            found = true;
            break;
          }
        }
      }
    }
  } else if (mPlotFileReader.isOpen()) {
    QTextStream textStream(&mPlotFileReader);
    QString currentLine;
    bool variableFound = false;
    while (!textStream.atEnd()) {
      currentLine = textStream.readLine();
      if (currentLine.compare(QString("DataSet: %1").arg(variable)) == 0) {
        variableFound = true;
      } else if (variableFound) {
        if (currentLine.startsWith("DataSet:")) { // new dataset started. Unable to find the value.
          break;
        }
        QStringList values = currentLine.split(",");
        if (QString::number(time).compare(values[0]) == 0) {
          value = values[1].toDouble();
          found = true;
          break;
        }
      }
    }
    textStream.seek(0);
  }

  if (reportError && !found) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "No result for variable " + variable + " in result file.",
                                                          Helper::simulationKind, Helper::warningLevel));
  }

  return qMakePair(value, found);
}

/*!
 * \brief VariablesWidget::plotVariables
 * Plot/unplot the checked/unchecked index.
 * \param index
 * \param curveThickness
 * \param curveStyle
 * \param shiftKey
 * \param pPlotCurve
 * \param pPlotWindow
 */
void VariablesWidget::plotVariables(const QModelIndex &index, qreal curveThickness, int curveStyle, bool shiftKey, PlotCurve *pPlotCurve, PlotWindow *pPlotWindow)
{
  if (index.column() > 0) {
    return;
  }
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (!pVariablesTreeItem) {
    return;
  }
  try {
    // if pPlotWindow is 0 then get the current window.
    if (!pPlotWindow) {
      QMdiSubWindow *pSubWindow = MainWindow::instance()->getPlotWindowContainer()->getPlotSubWindowFromMdi();
      if (pSubWindow) {
        pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
        /* Since we change the active subwindow so the variable check state might change after call to setActiveSubWindow
         * So we store the check state and apply it back after setActiveSubWindow.
         * This is done to fix issue #12911.
         * We plot on the previous plot window, if there is any and make it active. If there is no previous plot window then open a new plot window.
         * See also VariablesWidget::updateVariablesTree
         */
        bool checkState = pVariablesTreeItem->isChecked();
        MainWindow::instance()->getPlotWindowContainer()->setActiveSubWindow(pSubWindow);
        pVariablesTreeItem->setChecked(checkState);
      }
    }
    // if the variable is not an array and
    // pPlotWindow is 0 or the plot's type is PLOTARRAY or PLOTARRAYPARAMETRIC
    // then create a new plot window.
    if (!pVariablesTreeItem->isMainArray() && (!pPlotWindow || pPlotWindow->isPlotArray() || pPlotWindow->isPlotArrayParametric())) {
      bool checkedState = pVariablesTreeItem->isChecked();
      MainWindow::instance()->getPlotWindowContainer()->addPlotWindow();
      pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
      checkVariable(index, checkedState);
    }
    // if the variable is an array and
    // pPlotWindow is 0 or the plot's type is PLOT or PLOTPARAMETRIC
    // then create a new plot window.
    else if (pVariablesTreeItem->isMainArray() && (!pPlotWindow || pPlotWindow->isPlot() || pPlotWindow->isPlotParametric())) {
      bool checkedState = pVariablesTreeItem->isChecked();
      MainWindow::instance()->getPlotWindowContainer()->addArrayPlotWindow();
      pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
      checkVariable(index, checkedState);
    }
    // if still pPlotWindow is 0 then return.
    if (!pPlotWindow) {
      unCheckVariableAndErrorMessage(index, tr("No plot window is active for plotting. Please select a plot window or open a new."));
      return;
    }
    // if plottype is PLOT or PLOTARRAY then
    if (pPlotWindow->isPlot() || pPlotWindow->isPlotArray()) {
      // check the item checkstate
      if (pVariablesTreeItem->isChecked()) {
        VariablesTreeItem *pVariablesTreeRootItem = pVariablesTreeItem;
        if (!pVariablesTreeItem->isRootItem()) {
          pVariablesTreeRootItem = pVariablesTreeItem->rootParent();
        }
        if (pVariablesTreeRootItem->getSimulationOptions().isInteractiveSimulation()) {
          QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information), tr("Cannot be attached to a plot window."), QMessageBox::Ok);
          pVariablesTreeItem->setChecked(false);
          return;
        }
        pPlotWindow->initializeFile(QString("%1/%2").arg(pVariablesTreeItem->getFilePath(), pVariablesTreeItem->getFileName()));
        pPlotWindow->setCurveWidth(curveThickness);
        pPlotWindow->setCurveStyle(curveStyle);
        pPlotWindow->setVariablesList(QStringList(pVariablesTreeItem->getPlotVariable()));
        pPlotWindow->setYUnit(Utilities::convertUnitToSymbol(pVariablesTreeItem->getUnit()));
        pPlotWindow->setYDisplayUnit(Utilities::convertUnitToSymbol(pVariablesTreeItem->getDisplayUnit()));
        if (pPlotWindow->isPlot()) {
          pPlotWindow->plot(pPlotCurve);
          /* Ticket:5839
           * Check the toggle sign of the curve and apply it in case of update.
           */
          if (pPlotCurve && pPlotCurve->getToggleSign()) {
            pPlotCurve->setToggleSign(false);
            pPlotWindow->toggleSign(pPlotCurve, true);
          }
        } else {/* i.e., pPlotWindow->isPlotArray() */
          double timePercent = mpTimeTextBox->text().toDouble();
          pPlotWindow->plotArray(timePercent, pPlotCurve);
        }
        /* Ticket:4231
         * Only update the variable browser value and unit when updating some curve not when checking/unchecking variable.
         */
        if (pPlotCurve) {
          /* Ticket:2250
           * Update the value of Variable Browser display unit according to the display unit of already plotted curve.
           */
          pVariablesTreeItem->setData(3, pPlotCurve->getYDisplayUnit(), Qt::EditRole);
          QString value = pVariablesTreeItem->getValue(pVariablesTreeItem->getPreviousUnit(), pVariablesTreeItem->getDisplayUnit()).toString();
          pVariablesTreeItem->setData(1, value, Qt::EditRole);
        }
        if (!pPlotCurve) {
          pPlotCurve = pPlotWindow->getPlot()->getPlotCurvesList().last();
        }
        bool requiresUpdate = false;
        if (pPlotCurve && !pVariablesTreeItem->isString() && pVariablesTreeItem->getUnit().compare(pVariablesTreeItem->getDisplayUnit()) != 0) {
          OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(pVariablesTreeItem->getUnit(), pVariablesTreeItem->getDisplayUnit());
          if (convertUnit.unitsCompatible) {
            pPlotCurve->resetPrefixUnit();
            requiresUpdate = true;
            for (int i = 0 ; i < pPlotCurve->mYAxisVector.size() ; i++) {
              pPlotCurve->updateYAxisValue(i, Utilities::convertUnit(pPlotCurve->mYAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
            }
          } else {
            pPlotCurve->setYDisplayUnit(Utilities::convertUnitToSymbol(pVariablesTreeItem->getDisplayUnit()));
          }
        }
        // update the time values if time unit is different then s
        if (pPlotCurve && pPlotWindow->getTimeUnit().compare("s") != 0) {
          OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits("s", pPlotWindow->getTimeUnit());
          /* if requiresUpdate = false then call pPlotCurve->resetPrefixUnit() and set it to true.
           * otherwise avoid calling pPlotCurve->resetPrefixUnit() since it is already called above.
           */
          if (!requiresUpdate) {
            pPlotCurve->resetPrefixUnit();
            requiresUpdate = true;
          }
          if (convertUnit.unitsCompatible) {
            for (int i = 0 ; i < pPlotCurve->mXAxisVector.size() ; i++) {
              pPlotCurve->updateXAxisValue(i, Utilities::convertUnit(pPlotCurve->mXAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
            }
          }
        }
        if (requiresUpdate) {
          pPlotCurve->plotData();
        }
        pPlotWindow->updatePlot();
      } else if (!pVariablesTreeItem->isChecked()) {  // if user unchecks the variable then remove it from the plot
        foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
          QString curveTitle = pPlotCurve->getNameStructure();
          if (curveTitle.compare(pVariablesTreeItem->getVariableName()) == 0) {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
            pPlotWindow->updatePlot();
            break;
          }
        }
      }
    } else if (pPlotWindow->isPlotParametric() || pPlotWindow->isPlotArrayParametric()) { // if plottype is PLOTPARAMETRIC or PLOTARRAYPARAMETRIC then
      // check the item checkstate
      if (pVariablesTreeItem->isChecked()) {
        VariablesTreeItem *pVariablesTreeRootItem = pVariablesTreeItem;
        if (!pVariablesTreeItem->isRootItem()) {
          pVariablesTreeRootItem = pVariablesTreeItem->rootParent();
        }
        if (pVariablesTreeRootItem->getSimulationOptions().isInteractiveSimulation()) {
          QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information), tr("Cannot be attached to a parametric plot window."), QMessageBox::Ok);
          pVariablesTreeItem->setChecked(false);
          return;
        }

        if (shiftKey) {
          if (!mPlotParametricCurves.isEmpty()) {
            PlotParametricCurve plotParametricCurve = mPlotParametricCurves.last();
            if (plotParametricCurve.yVariables.isEmpty()) {
              unCheckVariableAndErrorMessage(index, tr("Cannot select two consecutive x-axis variables. <b>%1</b> is already selected as x-axis variable.")
                                             .arg(plotParametricCurve.xVariable.variableName));
              return;
            }
          }
          PlotParametricCurve plotParametricCurve;
          plotParametricCurve.xVariable.fileName = pVariablesTreeItem->getFileName();
          plotParametricCurve.xVariable.variableName = pVariablesTreeItem->getPlotVariable();
          plotParametricCurve.xVariable.unit = pVariablesTreeItem->getUnit();
          plotParametricCurve.xVariable.displayUnit = pVariablesTreeItem->getDisplayUnit();
          plotParametricCurve.xVariable.isString = pVariablesTreeItem->isString();
          mPlotParametricCurves.append(plotParametricCurve);
        } else {
          if (mPlotParametricCurves.isEmpty()) {
            unCheckVariableAndErrorMessage(index, tr("Select the x-axis variable first. Press and hold the shift key and then check the variable."));
            return;
          } else {
            if (mPlotParametricCurves.last().xVariable.fileName.compare(pVariablesTreeItem->getFileName()) != 0) {
              unCheckVariableAndErrorMessage(index, GUIMessages::getMessage(GUIMessages::PLOT_PARAMETRIC_DIFF_FILES));
              return;
            }
            PlotParametricCurve plotParametricCurve = mPlotParametricCurves.takeLast();
            PlotParametricVariable plotParametricVariable;
            plotParametricVariable.fileName = pVariablesTreeItem->getFileName();
            plotParametricVariable.variableName = pVariablesTreeItem->getPlotVariable();
            plotParametricVariable.unit = pVariablesTreeItem->getUnit();
            plotParametricVariable.displayUnit = pVariablesTreeItem->getDisplayUnit();
            plotParametricVariable.isString = pVariablesTreeItem->isString();
            plotParametricCurve.yVariables.append(plotParametricVariable);
            // Put the updated PlotParametricCurve to mPlotParametricCurves vector
            mPlotParametricCurves.append(plotParametricCurve);

            pPlotWindow->initializeFile(QString("%1/%2").arg(pVariablesTreeItem->getFilePath(), pVariablesTreeItem->getFileName()));
            pPlotWindow->setCurveWidth(curveThickness);
            pPlotWindow->setCurveStyle(curveStyle);
            pPlotWindow->setVariablesList(QStringList() << plotParametricCurve.xVariable.variableName << plotParametricVariable.variableName);
            pPlotWindow->setXUnit(Utilities::convertUnitToSymbol(plotParametricCurve.xVariable.unit));
            pPlotWindow->setXDisplayUnit(Utilities::convertUnitToSymbol(plotParametricCurve.xVariable.displayUnit));
            pPlotWindow->setYUnit(Utilities::convertUnitToSymbol(plotParametricVariable.unit));
            pPlotWindow->setYDisplayUnit(Utilities::convertUnitToSymbol(plotParametricVariable.displayUnit));
            if (pPlotWindow->isPlotParametric()) {
              pPlotWindow->plotParametric(pPlotCurve);
              /* Ticket:5839
               * Check the toggle sign of the curve and apply it in case of update.
               */
              if (pPlotCurve && pPlotCurve->getToggleSign()) {
                pPlotCurve->setToggleSign(false);
                pPlotWindow->toggleSign(pPlotCurve, true);
              }
            } else { /* i.e., pPlotWindow->isPlotArrayParametric() */
              double timePercent = mpTimeTextBox->text().toDouble();
              pPlotWindow->plotArrayParametric(timePercent, pPlotCurve);
            }
            if (!pPlotCurve) {
              pPlotCurve = pPlotWindow->getPlot()->getPlotCurvesList().last();
            }
            // convert x value
            bool requiresUpdate = false;
            if (pPlotCurve && !plotParametricCurve.xVariable.isString && plotParametricCurve.xVariable.unit.compare(plotParametricCurve.xVariable.displayUnit) != 0) {
              OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(plotParametricCurve.xVariable.unit, plotParametricCurve.xVariable.displayUnit);
              if (convertUnit.unitsCompatible) {
                pPlotCurve->resetPrefixUnit();
                requiresUpdate = true;
                for (int i = 0 ; i < pPlotCurve->mXAxisVector.size() ; i++) {
                  pPlotCurve->updateXAxisValue(i, Utilities::convertUnit(pPlotCurve->mXAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
                }
              } else {
                pPlotCurve->setXDisplayUnit(Utilities::convertUnitToSymbol(plotParametricCurve.xVariable.displayUnit));
              }
            }
            // convert y value
            if (pPlotCurve && !plotParametricVariable.isString && plotParametricVariable.unit.compare(plotParametricVariable.displayUnit) != 0) {
              OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(plotParametricVariable.unit, plotParametricVariable.displayUnit);
              if (convertUnit.unitsCompatible) {
                /* if requiresUpdate = false then call pPlotCurve->resetPrefixUnit() and set it to true.
                 * otherwise avoid calling pPlotCurve->resetPrefixUnit() since it is already called above.
                 */
                if (!requiresUpdate) {
                  pPlotCurve->resetPrefixUnit();
                  requiresUpdate = true;
                }
                for (int i = 0 ; i < pPlotCurve->mYAxisVector.size() ; i++) {
                  pPlotCurve->updateYAxisValue(i, Utilities::convertUnit(pPlotCurve->mYAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
                }
              } else {
                pPlotCurve->setYDisplayUnit(Utilities::convertUnitToSymbol(plotParametricVariable.displayUnit));
              }
            }
            if (requiresUpdate) {
              pPlotCurve->plotData();
            }
            pPlotWindow->updatePlot();
          }
        }
      } else if (!pVariablesTreeItem->isChecked()) {  // if user unchecks the variable then remove it from the plot
        bool curveRemoved = false;
        int i = 0;
        while (i < mPlotParametricCurves.size()) {
          PlotParametricCurve plotParametricCurve = mPlotParametricCurves.at(i);
          if (plotParametricCurve.xVariable.variableName.compare(pVariablesTreeItem->getPlotVariable()) == 0) {
            foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
              if (pPlotCurve->getXVariable().compare(plotParametricCurve.xVariable.variableName) == 0) {
                // uncheck x variable
                unCheckCurveVariable(QString("%1.%2").arg(pPlotCurve->getFileName(), pPlotCurve->getXVariable()));
                // uncheck y variable
                unCheckCurveVariable(QString("%1.%2").arg(pPlotCurve->getFileName(), pPlotCurve->getYVariable()));
                // remove the curve
                pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                pPlotCurve->detach();
                curveRemoved = true;
              }
            }
            mPlotParametricCurves.remove(i);
            i = 0;  //Restart iteration on mPlotParametricCurves.size()
            continue;
          } else {
            int j = 0;
            int canRemovePlotParametricCurve = false;
            while (j < plotParametricCurve.yVariables.size()) {
              PlotParametricVariable plotParametricVariable = plotParametricCurve.yVariables.at(j);
              if (plotParametricVariable.variableName.compare(pVariablesTreeItem->getPlotVariable()) == 0) {
                foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
                  if (pPlotCurve->getYVariable().compare(plotParametricVariable.variableName) == 0) {
                    // uncheck x variable if size of y variables is 1.
                    if (plotParametricCurve.yVariables.size() == 1) {
                      unCheckCurveVariable(QString("%1.%2").arg(pPlotCurve->getFileName(), pPlotCurve->getXVariable()));
                      canRemovePlotParametricCurve = true;
                    }
                    // uncheck y variable
                    unCheckCurveVariable(QString("%1.%2").arg(pPlotCurve->getFileName(), pPlotCurve->getYVariable()));
                    // remove the curve
                    pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                    pPlotCurve->detach();
                    curveRemoved = true;
                    plotParametricCurve.yVariables.remove(j);
                    mPlotParametricCurves.replace(i, plotParametricCurve);
                    break;
                  }
                }
              }
              j++;
            }
            if (canRemovePlotParametricCurve) {
              mPlotParametricCurves.remove(i);
              i = 0;  //Restart iteration on mPlotParametricCurves
              continue;
            }
          }
          i++;
        }
        if (curveRemoved) {
          pPlotWindow->updatePlot();
        }
      }
    } else { // if plottype is INTERACTIVE then
      VariablesTreeItem *pVariablesTreeRootItem = pVariablesTreeItem;
      if (!pVariablesTreeItem->isRootItem()) {
        pVariablesTreeRootItem = pVariablesTreeItem->rootParent();
      }
      int port = pVariablesTreeRootItem->getSimulationOptions().getInteractiveSimulationPortNumber();

      if (pVariablesTreeItem->isChecked()) { // if user checks the variable
        if (!pVariablesTreeRootItem->getSimulationOptions().isInteractiveSimulation()) {
          QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information), tr("Cannot be attached to an interactive plot window."), QMessageBox::Ok);
          pVariablesTreeItem->setChecked(false);
        } else {
          // if user checks a variable belonging to an inactive plot window, switch to it.
          if (pPlotWindow->getInteractiveOwner() != pVariablesTreeRootItem->getFileName()) {
            pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getInteractiveWindow(pVariablesTreeRootItem->getFileName());
            MainWindow::instance()->getPlotWindowContainer()->setActiveSubWindow(pPlotWindow->getSubWindow());
          } else {
            pPlotWindow->setCurveWidth(curveThickness);
            pPlotWindow->setCurveStyle(curveStyle);
            QString plotVariable = pVariablesTreeItem->getPlotVariable();
            pPlotWindow->setVariablesList(QStringList(plotVariable));
            pPlotWindow->setYUnit(Utilities::convertUnitToSymbol(pVariablesTreeItem->getUnit()));
            pPlotWindow->setYDisplayUnit(Utilities::convertUnitToSymbol(pVariablesTreeItem->getDisplayUnit()));
            pPlotWindow->setInteractiveModelName(pVariablesTreeItem->getFileName());
            OpcUaClient *pOpcUaClient = MainWindow::instance()->getSimulationDialog()->getOpcUaClient(port);
            if (pOpcUaClient) {
              Variable *pCurveData = *pOpcUaClient->getVariables()->find(plotVariable);
              QwtSeriesData<QPointF>* pData = dynamic_cast<QwtSeriesData<QPointF>*>(pCurveData);
              pPlotWindow->setInteractivePlotData(pData);
              QPair<QVector<double>*, QVector<double>*> memory = pPlotWindow->plotInteractive(pPlotCurve);
              // use the same vectors as a normal plot
              pCurveData->setAxisVectors(memory);
              pOpcUaClient->checkVariable(pCurveData->getNodeId(), pVariablesTreeItem);
            }
          }
        }
      }
      else if (!pVariablesTreeItem->isChecked()) { // if user unchecks the variable
        // remove the variable from the data fetch list
        OpcUaClient *pOpcUaClient = MainWindow::instance()->getSimulationDialog()->getOpcUaClient(port);
        if (pOpcUaClient) {
          Variable *pCurveData = *pOpcUaClient->getVariables()->find(pVariablesTreeItem->getPlotVariable());
          pOpcUaClient->unCheckVariable(pCurveData->getNodeId(), pVariablesTreeItem->getPlotVariable());
        }
        foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
          /* FIX: Make sure to remove the right curve when implementing several interactive simulations at the same time */
          if (pVariablesTreeItem->getVariableName().endsWith("." + pPlotCurve->getYVariable())) {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
            pPlotWindow->updatePlot();
            break;
          }
        }
      }
    }
  } catch (PlotException &e) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), QMessageBox::Ok);
  }
}

/*!
 * \brief VariablesWidget::unitChanged
 * Handles the case when display unit is changed in VariablesTreeView.\n
 * Updates the values according to the new display unit.
 * \param index
 */
void VariablesWidget::unitChanged(const QModelIndex &index)
{
  if (index.column() != 3) {
    return;
  }
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (!pVariablesTreeItem) {
    return;
  }
  try {
    OMPlot::PlotWindow *pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    // if still pPlotWindow is 0 then return.
    if (!pPlotWindow) {
      return;
    }
    OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(pVariablesTreeItem->getPreviousUnit(), pVariablesTreeItem->getDisplayUnit());
    if (convertUnit.unitsCompatible) {
      /* update value */
      QVariant stringValue = pVariablesTreeItem->data(1, Qt::EditRole);
      bool ok = true;
      qreal realValue = stringValue.toDouble(&ok);
      if (ok) {
        realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
        pVariablesTreeItem->setData(1, StringHandler::number(realValue), Qt::EditRole);
      }
      /* update plots */
      foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
        bool requiresUpdate = false;
        const QString yVariableName = QString("%1.%2").arg(pPlotCurve->getFileName(), pPlotCurve->getYVariable());
        if (yVariableName.compare(pVariablesTreeItem->getVariableName()) == 0) {
          // reset prefix unit
          pPlotCurve->resetPrefixUnit();
          requiresUpdate = true;
          for (int i = 0 ; i < pPlotCurve->mYAxisVector.size() ; i++) {
            pPlotCurve->updateYAxisValue(i, Utilities::convertUnit(pPlotCurve->mYAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
          }
          pPlotCurve->setYDisplayUnit(Utilities::convertUnitToSymbol(pVariablesTreeItem->getDisplayUnit()));
        }
        if (pPlotWindow->isPlotParametric() || pPlotWindow->isPlotArrayParametric()) {
          const QString xVariableName = QString("%1.%2").arg(pPlotCurve->getFileName(), pPlotCurve->getXVariable());
          if (xVariableName.compare(pVariablesTreeItem->getVariableName()) == 0) {
            /* if requiresUpdate = false then call pPlotCurve->resetPrefixUnit() and set it to true.
             * otherwise avoid calling pPlotCurve->resetPrefixUnit() since it is already called above.
             */
            if (!requiresUpdate) {
              pPlotCurve->resetPrefixUnit();
              requiresUpdate = true;
            }
            for (int i = 0 ; i < pPlotCurve->mXAxisVector.size() ; i++) {
              pPlotCurve->updateXAxisValue(i, Utilities::convertUnit(pPlotCurve->mXAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
            }
            pPlotCurve->setXDisplayUnit(Utilities::convertUnitToSymbol(pVariablesTreeItem->getDisplayUnit()));
          }
        }
        if (requiresUpdate) {
          // update plot data and do not break the loop as the variable can be used in multiple curves in the case of parametric plot.
          pPlotCurve->plotData();
        }
      }
      pPlotWindow->updatePlot();
    }
  } catch (PlotException &e) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), QMessageBox::Ok);
  }
}

/*!
 * \brief VariablesWidget::simulationTimeChanged
 * SLOT activated when mpSimulationTimeSlider valueChanged SIGNAL is raised.
 * \param value
 */
void VariablesWidget::simulationTimeChanged(int value)
{
  if (value >= 0) {
    double start = mpTimeManager->getStartTime();
    double end = mpTimeManager->getEndTime();
    double time = (end - start) * (value / (double)mSliderRange) + start;
    updateBrowserTime(time);
  } else {
    bool state = mpSimulationTimeSlider->blockSignals(true);
    mpSimulationTimeSlider->setValue(mpTimeManager->getTimeFraction());
    mpSimulationTimeSlider->blockSignals(state);
  }
}

/*!
 * \brief VariablesWidget::updateBrowserTime
 * Updates the browser to the provided point of time
 * \param time The new point of time
 */
void VariablesWidget::updateBrowserTime(double time)
{
  double start = mpTimeManager->getStartTime();
  double end = mpTimeManager->getEndTime();
  if (time < start) {
    time = start;
  } else if (time > end) {
    time = end;
  }
  mpTimeManager->setVisTime(time);
  mpTimeTextBox->setText(QString::number(mpTimeManager->getVisTime()));
  bool state = mpSimulationTimeSlider->blockSignals(true);
  mpSimulationTimeSlider->setValue(mpTimeManager->getTimeFraction());
  mpSimulationTimeSlider->blockSignals(state);
  updateVisualization();
  updatePlotWindows();
}

/*!
 * \brief VariablesWidget::updatePlotWindows
 * Updates the plot windows.
 */
void VariablesWidget::updatePlotWindows()
{
  double time = mpTimeManager->getVisTime();
  foreach (QMdiSubWindow *pSubWindow, MainWindow::instance()->getPlotWindowContainer()->subWindowList(QMdiArea::StackingOrder)) {
    try {
      if (MainWindow::instance()->getPlotWindowContainer()->isPlotWindow(pSubWindow->widget())) {
        PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
        if (pPlotWindow->isPlotArray() || pPlotWindow->isPlotArrayParametric()) {
          QList<PlotCurve*> curves = pPlotWindow->getPlot()->getPlotCurvesList();
          if (curves.isEmpty()) {
            if (!pPlotWindow->getFooter().isEmpty()) {
              pPlotWindow->setTime(time);
              pPlotWindow->updateTimeText();
            }
          } else if (pPlotWindow->isPlotArray()) {
            foreach (PlotCurve* curve, curves) {
              QString varName = curve->getYVariable();
              pPlotWindow->setVariablesList(QStringList(varName));
              pPlotWindow->plotArray(time, curve);
            }
          } else {
            foreach (PlotCurve* curve, curves) {
              QString xVarName = curve->getXVariable();
              QString yVarName = curve->getYVariable();
              pPlotWindow->setVariablesList({xVarName, yVarName});
              pPlotWindow->plotArrayParametric(time, curve);
            }
          }
        }
      }
    } catch (PlotException &e) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, e.what(), Helper::scriptingKind, Helper::errorLevel));
    }
  }
}

/*!
 * \brief VariablesWidget::valueEntered
 * Handles the case when a new value is entered in VariablesTreeView.\n
 * \param index
 */
void VariablesWidget::valueEntered(const QModelIndex &index)
{
  if (index.column() != 1) {
    return;
  }
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (!pVariablesTreeItem) {
    return;
  }
  try {
    OMPlot::PlotWindow *pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    // if still pPlotWindow is 0 then return.
    if (!pPlotWindow) {
      return;
    }
    QVariant variableValue = pVariablesTreeItem->getValue(pVariablesTreeItem->getDisplayUnit(), pVariablesTreeItem->getUnit()).toDouble();
    QString variableName = pVariablesTreeItem->getPlotVariable();
    // make sure the write goes to the right server
    VariablesTreeItem *pVariablesTreeRootItem = pVariablesTreeItem;
    if (!pVariablesTreeItem->isRootItem()) {
      pVariablesTreeRootItem = pVariablesTreeItem->rootParent();
    }
    int port = pVariablesTreeRootItem->getSimulationOptions().getInteractiveSimulationPortNumber();
    OpcUaClient *pOpcUaClient = MainWindow::instance()->getSimulationDialog()->getOpcUaClient(port);
    if (pOpcUaClient) {
      pOpcUaClient->writeValue(variableValue, variableName);
    }

  } catch (PlotException &e) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), QMessageBox::Ok);
  }
}

void VariablesWidget::selectInteractivePlotWindow(VariablesTreeItem *pVariablesTreeItem)
{
  // look at the root parent
  if (!pVariablesTreeItem->isRootItem()) {
    pVariablesTreeItem = pVariablesTreeItem->rootParent();
  }
  // change to the corresponding subwindow
  if (pVariablesTreeItem->getSimulationOptions().isInteractiveSimulation()) {
    foreach (QMdiSubWindow *pSubWindow, MainWindow::instance()->getPlotWindowContainer()->subWindowList(QMdiArea::StackingOrder)) {
      PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
      if (pPlotWindow->getInteractiveOwner() == pVariablesTreeItem->getFileName()) {
        MainWindow::instance()->getPlotWindowContainer()->setActiveSubWindow(pSubWindow);
      }
    }
  }
}

/*!
 * \brief VariablesWidget::closeResultFile
 * Closes the result file.
 */
void VariablesWidget::closeResultFile()
{
  if (mModelicaMatReader.file) {
    omc_free_matlab4_reader(&mModelicaMatReader);
    mModelicaMatReader.file = 0;
  }
  if (mpCSVData) {
    omc_free_csv_reader(mpCSVData);
    mpCSVData = 0;
  }
  if (mPlotFileReader.isOpen()) {
    mPlotFileReader.close();
  }
}

/*!
 * \brief VariablesWidget::openResultFile
 * Opens the result file.
 * \param pVariablesTreeItem
 * \param startTime
 * \param stopTime
 */
void VariablesWidget::openResultFile(VariablesTreeItem *pVariablesTreeItem, double &startTime, double &stopTime)
{
  if (pVariablesTreeItem) {
    // read filename
    QString fileName = QString("%1/%2").arg(pVariablesTreeItem->getFilePath(), pVariablesTreeItem->getFileName());
    bool errorOpeningFile = false;
    QString errorString = "";
    if (pVariablesTreeItem->getFileName().endsWith(".mat")) {
      const char *msg[] = {""};
      if (0 == (msg[0] = omc_new_matlab4_reader(fileName.toUtf8().constData(), &mModelicaMatReader))) {
        startTime = omc_matlab4_startTime(&mModelicaMatReader);
        stopTime = omc_matlab4_stopTime(&mModelicaMatReader);
      } else {
        errorOpeningFile = true;
        errorString = msg[0];
      }
    } else if (pVariablesTreeItem->getFileName().endsWith(".csv")) {
      mpCSVData = read_csv(fileName.toUtf8().constData());
      if (mpCSVData) {
        //Read in timevector
        double *timeVals = read_csv_dataset(mpCSVData, "time");
        if (timeVals == NULL) {
          errorOpeningFile = true;
          errorString = "Error reading time from CSV file.";
        } else {
          startTime = timeVals[0];
          stopTime = timeVals[mpCSVData->numsteps-1];
        }
      } else {
        errorOpeningFile = true;
        errorString = "Error reading CSV file.";
      }
    } else if (pVariablesTreeItem->getFileName().endsWith(".plt")) {
      mPlotFileReader.setFileName(fileName);
      if (mPlotFileReader.open(QIODevice::ReadOnly)) {
        QTextStream textStream(&mPlotFileReader);
        // read the interval size from the file
        int intervalSize = 0;
        QString currentLine;
        while (!textStream.atEnd()) {
          currentLine = textStream.readLine();
          if (currentLine.startsWith("#IntervalSize")) {
            intervalSize = static_cast<QString>(currentLine.split("=").last()).toInt();
            break;
          }
        }
        // Read start and stop time
        while (!textStream.atEnd()) {
          currentLine = textStream.readLine();
          QString currentVariable;
          if (currentLine.contains("DataSet:")) {
            currentVariable = currentLine.remove("DataSet: ");
            if (currentVariable == "time") {
              // read the variable values now
              currentLine = textStream.readLine();
              QStringList values = currentLine.split(",");
              startTime = QString(values[0]).toDouble();
              for(int j = 0; j < intervalSize-1; j++) {
                currentLine = textStream.readLine();
              }
              values = currentLine.split(",");
              stopTime = QString(values[0]).toDouble();
              break;
            }
          }
        }
      } else {
        errorOpeningFile = true;
        errorString = mPlotFileReader.errorString();
      }
    }
    // check file opening error
    if (errorOpeningFile) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                            GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE)
                                                            .arg(fileName, errorString), Helper::scriptingKind, Helper::errorLevel));
    }
  }
}

/*!
 * \brief VariablesWidget::updateVisualization
 * Updates the visualization.
 */
void VariablesWidget::updateVisualization()
{
  // check if visualization is enabled
  if (mpSimulationTimeSlider->isEnabled()) {
    mpTimeManager->updateTick();  //for real-time measurement
    double visTime = mpTimeManager->getRealTime();
    // Update the DiagramWindow by emitting updateDynamicSelect SIGNAL only if its DiagramWindow is active
    PlotWindowContainer *pPlotWindowContainer = MainWindow::instance()->getPlotWindowContainer();
    if (pPlotWindowContainer->currentSubWindow() && pPlotWindowContainer->isDiagramWindow(pPlotWindowContainer->currentSubWindow()->widget())) {
      emit updateDynamicSelect(mpTimeManager->getVisTime());
    }
    if (MainWindow::instance()->getPlotWindowContainer()->getDiagramWindow()
        && MainWindow::instance()->getPlotWindowContainer()->getDiagramWindow()->getModelWidget()) {
      MainWindow::instance()->getPlotWindowContainer()->getDiagramWindow()->getModelWidget()->getDiagramGraphicsView()->scene()->update();
    }
    mpTimeManager->updateTick();  //for real-time measurement
    visTime = mpTimeManager->getRealTime() - visTime;
    mpTimeManager->setRealTimeFactor(mpTimeManager->getHVisual() / visTime);
  }
}

/*!
 * \brief VariablesWidget::checkVariable
 * \param index
 */
void VariablesWidget::checkVariable(const QModelIndex &index, bool checkState)
{
  /* When we add a new plotwindow then the checked variables are cleared based on the new plotwindow.
   * So check the active variable again
   */
  bool state = mpVariablesTreeModel->blockSignals(true);
  mpVariablesTreeModel->setData(index, checkState ? Qt::Checked : Qt::Unchecked, Qt::CheckStateRole);
  mpVariablesTreeModel->blockSignals(state);
}

/*!
 * \brief VariablesWidget::unCheckVariableAndErrorMessage
 * Unchecks the variable in case of error and shows an error message if any.
 * \param index
 * \param errorMessage
 */
void VariablesWidget::unCheckVariableAndErrorMessage(const QModelIndex &index, const QString &errorMessage)
{
  bool state = mpVariablesTreeModel->blockSignals(true);
  mpVariablesTreeModel->setData(index, Qt::Unchecked, Qt::CheckStateRole);
  mpVariablesTreeModel->blockSignals(state);
  if (!errorMessage.isEmpty()) {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), errorMessage, QMessageBox::Ok);
  }
}

void VariablesWidget::unCheckCurveVariable(const QString &variable)
{
  bool state = mpVariablesTreeModel->blockSignals(true);
  VariablesTreeItem *pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(variable, mpVariablesTreeModel->getRootVariablesTreeItem());
  if (pVariablesTreeItem) {
    mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Unchecked, Qt::CheckStateRole);
  }
  mpVariablesTreeModel->blockSignals(state);
  if (pVariablesTreeItem) {
    mpVariablesTreeModel->updateVariablesTreeItem(pVariablesTreeItem);
  }
}

/*!
 * \brief VariablesWidget::timeUnitChanged
 * Handles the case when simulation time unit is changed.\n
 * Updates the x values of all the curves.
 * \param unit
 */
void VariablesWidget::timeUnitChanged(int index)
{
  const QString unit = mpSimulationTimeComboBox->itemText(index);
  if (unit.isEmpty()) {
    return;
  }
  try {
    OMPlot::PlotWindow *pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    // if still pPlotWindow is 0 then return.
    if (!pPlotWindow) {
      return;
    }
    if (pPlotWindow->isPlotArray() || pPlotWindow->isPlotArrayParametric()) {
      pPlotWindow->setTimeUnit(unit);
      pPlotWindow->updateTimeText();
    } else if (pPlotWindow->isPlot() || pPlotWindow->isPlotInteractive()) {
      OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(pPlotWindow->getTimeUnit(), unit);
      pPlotWindow->setTimeUnit(unit);
      if (convertUnit.unitsCompatible) {
        foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
          for (int i = 0 ; i < pPlotCurve->mXAxisVector.size() ; i++) {
            pPlotCurve->updateXAxisValue(i, Utilities::convertUnit(pPlotCurve->mXAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
          }
          pPlotCurve->plotData();
        }
        pPlotWindow->updatePlot();
      }
    }
  } catch (PlotException &e) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), QMessageBox::Ok);
  }
}

/*!
 * \brief VariablesWidget::updateVariablesTree
 * Updates the VariablesTreeView when the subwindow is changed in PlotWindowContainer
 * \param pSubWindow
 */
void VariablesWidget::updateVariablesTree(QMdiSubWindow *pSubWindow)
{
  MainWindow::instance()->getModelWidgetContainer()->currentModelWidgetChanged(0);
  if (!pSubWindow && MainWindow::instance()->getPlotWindowContainer()->subWindowList().size() != 0) {
    return;
  }
  /* if the same sub window is activated again then just return */
  if (mpLastActiveSubWindow == pSubWindow) {
    mpLastActiveSubWindow = pSubWindow;
    return;
  }
  mpLastActiveSubWindow = pSubWindow;
  /* update the tree variables to last active PlotWindow
   * This is done to fix issue #12911.
   * See also VariablesWidget::plotVariables
   */
  pSubWindow = MainWindow::instance()->getPlotWindowContainer()->getPlotSubWindowFromMdi();
  updateVariablesTreeHelper(pSubWindow);
  initializeVisualization();
}

void VariablesWidget::showContextMenu(QPoint point)
{
  int adjust = 24;
  QModelIndex index = mpVariablesTreeView->indexAt(point);
  index = mpVariableTreeProxyModel->mapToSource(index);
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (pVariablesTreeItem && pVariablesTreeItem->isRootItem()) {
    /* delete result action */
    QAction *pDeleteResultAction = new QAction(QIcon(":/Resources/icons/delete.svg"), tr("Delete Result"), this);
    pDeleteResultAction->setData(pVariablesTreeItem->getVariableName());
    pDeleteResultAction->setShortcut(QKeySequence::Delete);
    pDeleteResultAction->setStatusTip(tr("Delete the result"));
    connect(pDeleteResultAction, SIGNAL(triggered()), mpVariablesTreeModel, SLOT(removeVariableTreeItem()));
    /* set result active action */
    QAction *pEnableTimeControlsAction = new QAction(tr("Enable Time Controls"), this);
    pEnableTimeControlsAction->setData(pVariablesTreeItem->getVariableName());
    pEnableTimeControlsAction->setStatusTip(tr("Enables the time controls"));
    PlotWindowContainer *pPlotWindowContainer = MainWindow::instance()->getPlotWindowContainer();
    bool isDiagramWindow = pPlotWindowContainer->currentSubWindow() && pPlotWindowContainer->isDiagramWindow(pPlotWindowContainer->currentSubWindow()->widget());
    bool isActiveVariableTreeItem = pVariablesTreeItem == mpVariablesTreeModel->getActiveVariablesTreeItem();
    pEnableTimeControlsAction->setEnabled(!pVariablesTreeItem->getSimulationOptions().isInteractiveSimulation() && !isDiagramWindow && !isActiveVariableTreeItem);
    connect(pEnableTimeControlsAction, SIGNAL(triggered()), mpVariablesTreeModel, SLOT(enableTimeControls()));

    QMenu menu(this);
    menu.addAction(pDeleteResultAction);
    menu.addSeparator();
    menu.addAction(pEnableTimeControlsAction);
    menu.addSeparator();
    menu.addAction(MainWindow::instance()->getReSimulateModelAction());
    menu.addAction(MainWindow::instance()->getReSimulateSetupAction());
    point.setY(point.y() + adjust);
    menu.exec(mpVariablesTreeView->mapToGlobal(point));
  } else if (pVariablesTreeItem) {
    QAction *pGetDepends = new QAction(tr("Show only direct dependencies"), this);
    if (pVariablesTreeItem->getUses().size() <= 1 /* Self only */) {
      pGetDepends->setEnabled(false);
    }
    pGetDepends->setData(pVariablesTreeItem->getUses());
    pGetDepends->setStatusTip(tr("Show only variables that depend on this variable"));

    QAction *pGetInitDepends = new QAction(tr("Show only direct dependencies (initial)"), this);
    if (pVariablesTreeItem->getInitialUses().size() <= 1 /* Self only */) {
      pGetInitDepends->setEnabled(false);
    }
    pGetInitDepends->setData(pVariablesTreeItem->getInitialUses());
    pGetInitDepends->setStatusTip(tr("Show only variables that depend on this variable in the initial system of equations"));

    connect(pGetDepends, SIGNAL(triggered()), mpVariablesTreeModel, SLOT(filterDependencies()));
    connect(pGetInitDepends, SIGNAL(triggered()), mpVariablesTreeModel, SLOT(filterDependencies()));

    QMenu menu(this);
    menu.addAction(pGetDepends);
    menu.addAction(pGetInitDepends);

    foreach(IntStringPair pair, pVariablesTreeItem->getDefinedIn()) {
      if (pair.second == QString("")) {
        continue;
      }
      QAction *pGetDefines = new QAction(tr("Open debugger (equation %1 - %2)").arg(QString::number(pair.first), pair.second), this);
      QVariantList lst;
      lst << QString("%1/%2").arg(pVariablesTreeItem->getFilePath(), pVariablesTreeItem->getInfoFileName());
      lst << pair.first;
      pGetDefines->setData(lst);
      pGetDefines->setStatusTip(tr("Open debugger for the equation"));
      menu.addAction(pGetDefines);

      connect(pGetDefines, SIGNAL(triggered()), mpVariablesTreeModel, SLOT(openTransformationsBrowser()));
    }

    menu.exec(mpVariablesTreeView->viewport()->mapToGlobal(point));
  }
}

/*!
 * \brief VariablesWidget::findVariables
 * Finds the variables in the Variable Browser.
 */
void VariablesWidget::findVariables()
{
  QString findText = mpTreeSearchFilters->getFilterTextBox()->text();
  Qt::CaseSensitivity caseSensitivity = mpTreeSearchFilters->getCaseSensitiveCheckBox()->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  // TODO: handle PatternSyntax
  QRegularExpression regExp(QRegularExpression::fromWildcard(findText, caseSensitivity, QRegularExpression::UnanchoredWildcardConversion));
  mpVariableTreeProxyModel->setFilterRegularExpression(regExp);
#else
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpTreeSearchFilters->getSyntaxComboBox()->itemData(mpTreeSearchFilters->getSyntaxComboBox()->currentIndex()).toInt());
  QRegExp regExp(findText, caseSensitivity, syntax);
  mpVariableTreeProxyModel->setFilterRegExp(regExp);
#endif
  /* expand all so that the filtered items can be seen. */
  if (!findText.isEmpty()) {
    mpVariablesTreeView->expandAll();
  }
  if (mpVariablesTreeView->selectionModel()->selectedIndexes().isEmpty()) {
    QModelIndex proxyIndex = mpVariableTreeProxyModel->index(0, 0);
    if (proxyIndex.isValid()) {
      mpVariablesTreeView->selectionModel()->select(proxyIndex, QItemSelectionModel::Select | QItemSelectionModel::Rows);
    }
  }
  MainWindow::instance()->enableReSimulationToolbar(MainWindow::instance()->getVariablesDockWidget()->isVisible());
}

void VariablesWidget::directReSimulate()
{
  reSimulate(false);
}

void VariablesWidget::showReSimulateSetup()
{
  reSimulate(true);
}

/*!
 * \brief VariablesWidget::rewindVisualization
 * Slot activated when mpRewindAction triggered SIGNAL is raised.
 */
void VariablesWidget::rewindVisualization()
{
  mpTimeManager->setPause(true);
  mpTimeManager->setRealTimeFactor(0.0);
  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  updateVisualization();
  updatePlotWindows();
  bool state = mpSimulationTimeSlider->blockSignals(true);
  mpSimulationTimeSlider->setValue(mpTimeManager->getTimeFraction());
  mpSimulationTimeSlider->blockSignals(state);
  mpTimeTextBox->setText(QString::number(mpTimeManager->getVisTime()));
}

/*!
 * \brief VariablesWidget::playVisualization
 * Slot activated when mpPlayAction triggered SIGNAL is raised.
 */
void VariablesWidget::playVisualization()
{
  mpTimeManager->setPause(false);
}

/*!
 * \brief VariablesWidget::pauseVisualization
 * Slot activated when mpPauseAction triggered SIGNAL is raised.
 */
void VariablesWidget::pauseVisualization()
{
  mpTimeManager->setPause(true);
}

/*!
 * \brief VariablesWidget::visualizationTimeChanged
 * Slot activated when mpTimeTextBox returnPressed SIGNAL is raised.
 */
void VariablesWidget::visualizationTimeChanged()
{
  bool isDouble = false;
  double time = mpTimeTextBox->text().toDouble(&isDouble);
  if (isDouble && time >= 0.0) {
    updateBrowserTime(time);
  } else {
    mpTimeTextBox->setText(QString::number(mpTimeManager->getVisTime()));
  }
}

/*!
 * \brief VariablesWidget::visualizationSpeedChanged
 * Slot activated when mpSpeedComboBox currentIndexChanged SIGNAL is raised,
 * as well as when mpSpeedComboBox->lineEdit() textChanged SIGNAL is raised.
 */
void VariablesWidget::visualizationSpeedChanged()
{
  bool isDouble = false;
  double speed = mpSpeedComboBox->lineEdit()->text().toDouble(&isDouble);
  if (isDouble && speed > 0.0) {
    mpTimeManager->setSpeedUp(speed);
  } else {
    mpSpeedComboBox->lineEdit()->setText(QString::number(mpTimeManager->getSpeedUp()));
  }
}

/*!
 * \brief VariablesWidget::incrementVisualization
 * Slot activated when TimeManager timer emits timeout SIGNAL.
 */
void VariablesWidget::incrementVisualization()
{
  // measure real time
  mpTimeManager->updateTick();
  // set next time step
  if (!mpTimeManager->isPaused()) {
    // finish animation with pause when end time is reached
    if (mpTimeManager->getVisTime() >= mpTimeManager->getEndTime()) {
      pauseVisualization();
    } else {
      // set new visualization time
      double newTime = mpTimeManager->getVisTime() + (mpTimeManager->getHVisual() * mpTimeManager->getSpeedUp());
      if (newTime <= mpTimeManager->getEndTime()) {
        mpTimeManager->setVisTime(newTime);
      } else {
        mpTimeManager->setVisTime(mpTimeManager->getEndTime());
      }
    }
    // update browser
    updateVisualization();
    updatePlotWindows();
    if (!mpTimeManager->isPaused()) {
      // set time label
      mpTimeTextBox->setText(QString::number(mpTimeManager->getVisTime()));
      // set time slider
      bool state = mpSimulationTimeSlider->blockSignals(true);
      mpSimulationTimeSlider->setValue(mpTimeManager->getTimeFraction());
      mpSimulationTimeSlider->blockSignals(state);
    }
  }
}
