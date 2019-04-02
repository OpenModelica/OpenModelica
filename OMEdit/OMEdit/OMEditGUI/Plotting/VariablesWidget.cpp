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
#include "Simulation/SimulationProcessThread.h"

#include <QObject>

using namespace OMPlot;

/*!
 * \class VariablesTreeItem
 * \brief Contains the information about the result variable.
 */
/*!
 * \param variableItemData - a list of items.\n
 * 0 -> filePath\n
 * 1 -> fileName\n
 * 2 -> name\n
 * 3 -> displayName\n
 * 4 -> value\n
 * 5 -> unit\n
 * 6 -> displayUnit\n
 * 7 -> displayUnits (QStringList)\n
 * 8 -> description\n
 * 9 -> tooltip\n
 * 10 -> isMainArray
 */
VariablesTreeItem::VariablesTreeItem(const QVector<QVariant> &variableItemData, VariablesTreeItem *pParent, bool isRootItem)
{
  mpParentVariablesTreeItem = pParent;
  mIsRootItem = isRootItem;
  mFilePath = variableItemData[0].toString();
  mFileName = variableItemData[1].toString();
  mVariableName = variableItemData[2].toString();
  mDisplayVariableName = variableItemData[3].toString();
  mValue = variableItemData[4].toString();
  mValueChanged = false;
  mUnit = variableItemData[5].toString();
  mDisplayUnit = variableItemData[6].toString();
  mPreviousUnit = variableItemData[6].toString();
  mDisplayUnits = variableItemData[7].toStringList();
  mDescription = variableItemData[8].toString();
  mToolTip = variableItemData[9].toString();
  mChecked = false;
  mEditable = false;
  mVariability = "";
  mIsMainArray = variableItemData[10].toBool();
  mActive = false;
}

VariablesTreeItem::~VariablesTreeItem()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

QString VariablesTreeItem::getPlotVariable()
{
  return QString(mVariableName).remove(0, mFileName.length() + 1);
}

/*!
 * \brief VariablesTreeItem::setActive
 * Sets all the VariablesTreeItems inactive except this one.
 */
void VariablesTreeItem::setActive()
{
  VariablesTreeItem *pRootVariablesTreeItem;
  pRootVariablesTreeItem = MainWindow::instance()->getVariablesWidget()->getVariablesTreeModel()->getRootVariablesTreeItem();
  for (int i = 0 ; i < pRootVariablesTreeItem->getChildren().size() ; i++) {
    VariablesTreeItem *pVariablesTreeItem = pRootVariablesTreeItem->child(i);
    if (pVariablesTreeItem) {
      if (pVariablesTreeItem != this) {
        pVariablesTreeItem->mActive = false;
      }
    }
  }
  // set VariablesTreeView to active.
  mActive = true;
  MainWindow::instance()->getVariablesWidget()->initializeVisualization(mSimulationOptions);
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
    if (mDisplayUnit.compare(value.toString()) != 0) {
      mPreviousUnit = mDisplayUnit;
      mDisplayUnit = value.toString();
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
          return isActive() ? "(Active) " + mDisplayVariableName : mDisplayVariableName;
        case Qt::DecorationRole:
          return mIsRootItem ? getVariableTreeItemIcon(mVariableName) : QIcon();
        case Qt::ToolTipRole:
          return mToolTip;
        case Qt::CheckStateRole:
          if ((mChildren.size() == 0 && parent()->parent()) || mIsMainArray) {  // do not show checkbox for top level items without children.
            return isChecked() ? Qt::Checked : Qt::Unchecked;
           } else {
            return QVariant();
          }
        case Qt::FontRole:
          if (isActive()) {
            QFont font;
            font.setBold(true);
            return font;
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
          return mUnit;
        default:
          return QVariant();
      }
    case 3:
      switch (role) {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return mDisplayUnit;
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
        value = QString::number(realValue);
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
  headers << "" << "" << Helper::variables << Helper::variables << tr("Value") << tr("Unit") << tr("Display Unit") <<
             QStringList() << Helper::description << "" << false;
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
  return pParentVariablesTreeItem->getChildren().size();
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
      emit itemChecked(index, pPlottingPage->getCurveThickness(), pPlottingPage->getCurvePattern());
    }
  } else if (index.column() == 1) { // value
    if (!signalsBlocked()) {
      VariablesTreeItem *pVariablesRootTreeItem = pVariablesTreeItem->rootParent();
      if (pVariablesRootTreeItem->getSimulationOptions().isInteractiveSimulation()) {
        emit valueEntered(index);
      }
    }
  } else if (index.column() == 3) { // display unit
    if (!signalsBlocked() && displayUnit.compare(value.toString()) != 0) {
      emit unitChanged(index);
    }
  }
  emit dataChanged(index, index);
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
    return 0;
  }

  Qt::ItemFlags flags = Qt::ItemIsEnabled | Qt::ItemIsSelectable;
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (((index.column() == 0 && pVariablesTreeItem && pVariablesTreeItem->getChildren().size() == 0) || pVariablesTreeItem->isMainArray())
          && pVariablesTreeItem->parent() != mpRootVariablesTreeItem) {
    flags |= Qt::ItemIsUserCheckable;
  } else if (index.column() == 1 && pVariablesTreeItem && pVariablesTreeItem->getChildren().size() == 0 && pVariablesTreeItem->isEditable()) {
    flags |= Qt::ItemIsEditable;
  } else if (index.column() == 3) {
    flags |= Qt::ItemIsEditable;
  }

  return flags;
}

VariablesTreeItem* VariablesTreeModel::findVariablesTreeItem(const QString &name, VariablesTreeItem *root) const
{
  if (root->getVariableName() == name)
    return root;
  for (int i = root->getChildren().size(); --i >= 0; )
    if (VariablesTreeItem *item = findVariablesTreeItem(name, root->getChildren().at(i)))
      return item;
  return 0;
}

QModelIndex VariablesTreeModel::variablesTreeItemIndex(const VariablesTreeItem *pVariablesTreeItem) const
{
  return variablesTreeItemIndexHelper(pVariablesTreeItem, mpRootVariablesTreeItem, QModelIndex());
}

QModelIndex VariablesTreeModel::variablesTreeItemIndexHelper(const VariablesTreeItem *pVariablesTreeItem,
                                                             const VariablesTreeItem *pParentVariablesTreeItem,
                                                             const QModelIndex &parentIndex) const
{
  if (pVariablesTreeItem == pParentVariablesTreeItem)
    return parentIndex;
  for (int i = pParentVariablesTreeItem->getChildren().size(); --i >= 0; ) {
    const VariablesTreeItem *childItem = pParentVariablesTreeItem->getChildren().at(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = variablesTreeItemIndexHelper(pVariablesTreeItem, childItem, childIndex);
    if (index.isValid())
      return index;
  }
  return QModelIndex();
}

/*!
 * \brief VariablesTreeModel::parseInitXml
 * Parses the model_init.xml file and returns the scalar variables information.
 * \param xmlReader
 * \return
 */
void VariablesTreeModel::parseInitXml(QXmlStreamReader &xmlReader)
{
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
      if (xmlReader.name() == "ScalarVariable") {
        QHash<QString, QString> scalarVariable = parseScalarVariable(xmlReader);
        mScalarVariablesHash.insert(scalarVariable.value("name"),scalarVariable);
      }
    }
  }
  xmlReader.clear();
}

/*!
 * \brief VariablesTreeModel::insertVariablesItems
 * Inserts the variables in the Variables Browser.
 * \param fileName
 * \param filePath
 * \param variablesList
 * \param simulationOptions
 */
void VariablesTreeModel::insertVariablesItems(QString fileName, QString filePath, QStringList variablesList,
                                              SimulationOptions simulationOptions)
{
  QString toolTip;
  if (simulationOptions.isInteractiveSimulation()) {
    toolTip = tr("Interactive Simulation\nPort: %1").arg(simulationOptions.getInteractiveSimulationPortNumber());
  } else {
    toolTip = tr("Simulation Result File: %1\n%2: %3/%4").arg(fileName).arg(Helper::fileLocation).arg(filePath).arg(fileName);
  }
  QRegExp resultTypeRegExp("(\\.mat|\\.plt|\\.csv|_res.mat|_res.plt|_res.csv)");
  QString text = QString(fileName).remove(resultTypeRegExp);
  QModelIndex index = variablesTreeItemIndex(mpRootVariablesTreeItem);
  QVector<QVariant> Variabledata;
  Variabledata << filePath << fileName << fileName << text << "" << "" << "" << QStringList() << "" << toolTip << false;

  VariablesTreeItem *pTopVariablesTreeItem = new VariablesTreeItem(Variabledata, mpRootVariablesTreeItem, true);
  pTopVariablesTreeItem->setSimulationOptions(simulationOptions);
  int row = rowCount();
  beginInsertRows(index, row, row);
  mpRootVariablesTreeItem->insertChild(row, pTopVariablesTreeItem);
  endInsertRows();
  // set the newly inserted VariablesTreeItem active
  mpActiveVariablesTreeItem = pTopVariablesTreeItem;
  if (simulationOptions.isValid() && !simulationOptions.isInteractiveSimulation()) {
    pTopVariablesTreeItem->setActive();
  }
  /* open the model_init.xml file for reading */
  mScalarVariablesHash.clear();
  QString initFileName;
  if (simulationOptions.isValid()) {
    initFileName = QString(simulationOptions.getOutputFileName()).append("_init.xml");
  } else {
    initFileName = QString(text).append("_init.xml");
  }
  QFile initFile(QString(filePath).append(QDir::separator()).append(initFileName));
  if (initFile.exists()) {
    if (initFile.open(QIODevice::ReadOnly)) {
      QXmlStreamReader initXmlReader(&initFile);
      parseInitXml(initXmlReader);
      initFile.close();
    } else {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(initFile.fileName())
                                                            .arg(initFile.errorString()), Helper::scriptingKind, Helper::errorLevel));
    }
  }
  /* open the .mat file */
  ModelicaMatReader matReader;
  matReader.file = 0;
  const char *msg[] = {""};
  if (fileName.endsWith(".mat")) {
    //Read in mat file
    if (0 != (msg[0] = omc_new_matlab4_reader(QString(filePath + "/" + fileName).toStdString().c_str(), &matReader))) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(fileName)
                                                            .arg(QString(msg[0])), Helper::scriptingKind, Helper::errorLevel));
    }
  }

  // remove time from variables list
  variablesList.removeOne("time");
  QStringList variables;
  foreach (QString plotVariable, variablesList) {
    QString parentVariable;
    if (plotVariable.startsWith("der(")) {
      QString str = plotVariable;
      str.chop((str.lastIndexOf("der(")/4)+1);
      variables = StringHandler::makeVariablePartsWithInd(str.mid(str.lastIndexOf("der(") + 4));
    } else if (plotVariable.startsWith("previous(")) { //TODO: edit in same way as for der(
      QString str = plotVariable;
      str.chop((str.lastIndexOf("previous(")/9)+1);
      variables = StringHandler::makeVariablePartsWithInd(str.mid(str.lastIndexOf("previous(") + 9));
    } else {
      variables = StringHandler::makeVariablePartsWithInd(plotVariable);
    }
    int count = 1;
    VariablesTreeItem *pParentVariablesTreeItem = 0;
    foreach (QString variable, variables) {
      if (count == 1) { /* first loop iteration */
        pParentVariablesTreeItem = pTopVariablesTreeItem;
      }
      QString findVariable;
      /* if last item of non-array or second to last of array*/
      if (((variables.size() == count && !QRegExp("\\[\\d+\\]").exactMatch(variable)) ||
              (variables.size() == count+1 && QRegExp("\\[\\d+\\]").exactMatch(variables.last())))
              && plotVariable.startsWith("der(")) {
        if (parentVariable.isEmpty()) {
          findVariable = QString("%1.%2").arg(fileName , StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der("));
        } else {
          findVariable = QString("%1.%2.%3").arg(fileName, parentVariable, StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der("));
        }
      } else if (variables.size() == count && plotVariable.startsWith("previous(")) { //TODO: edit in same way as for der(
        if (parentVariable.isEmpty()) {
          findVariable = QString("%1.%2").arg(fileName , StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "previous("));
        } else {
          findVariable = QString("%1.%2.%3").arg(fileName, parentVariable, StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "previous("));
        }
      } else {
        if (parentVariable.isEmpty()) {
          findVariable = QString("%1.%2").arg(fileName, variable);
        } else {
          findVariable = QString("%1.%2.%3").arg(fileName, parentVariable, variable);
        }
      }
      if ((pParentVariablesTreeItem = findVariablesTreeItem(findVariable, pParentVariablesTreeItem)) != NULL) {
        QString addVar;
        //if second to last of array, add der(
        if ((variables.size() == count+1 && QRegExp("\\[\\d+\\]").exactMatch(variables.last())) && plotVariable.startsWith("der("))
          addVar = StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der(");
        else
          addVar = variable;
        if (count == 1) {
          parentVariable = addVar;
        } else {
          parentVariable += "." + addVar;
        }
        count++;
        continue;
      }
      /* If pParentVariablesTreeItem is 0 and it is first loop iteration then use pTopVariablesTreeItem as parent.
       * If loop iteration is not first and pParentVariablesTreeItem is 0 then find the parent item.
       */
      if (!pParentVariablesTreeItem && count > 1) {
        pParentVariablesTreeItem = findVariablesTreeItem(fileName + "." + parentVariable, pTopVariablesTreeItem);
      } else {
        pParentVariablesTreeItem = pTopVariablesTreeItem;
      }
      QModelIndex index = variablesTreeItemIndex(pParentVariablesTreeItem);
      QVector<QVariant> variableData;
      /*if last but one of array derivative*/
      if (variables.size() == count+1 && QRegExp("\\[\\d+\\]").exactMatch(variables.last()) && plotVariable.startsWith("der(")) {
        variableData << filePath << fileName << pParentVariablesTreeItem->getVariableName() + "." + StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der(") << StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der(");
      }
      /* if last item of non-array derivative*/
      else if (variables.size() == count && !QRegExp("\\[\\d+\\]").exactMatch(variable) && plotVariable.startsWith("der(")) {
        variableData << filePath << fileName << fileName + "." + plotVariable << StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der(");
      }
      /*if last but one of array previous*/
      else if (variables.size() == count+1 && QRegExp("\\[\\d+\\]").exactMatch(variables.last()) && plotVariable.startsWith("previous(")) {
        variableData << filePath << fileName << pParentVariablesTreeItem->getVariableName() + "." + StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "previous(") << StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "previous(");
      }
      /* if last item of non-array previous*/
      else if (variables.size() == count && !QRegExp("\\[\\d+\\]").exactMatch(variable) && plotVariable.startsWith("previous(")) {
        variableData << filePath << fileName << fileName + "." + plotVariable << StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "previous(");
      }
      /* if last item of array derivative*/
      else if (variables.size() == count && QRegExp("\\[\\d+\\]").exactMatch(variable)) {
        variableData << filePath << fileName << fileName + "." + plotVariable << variable;
      } else {
        variableData << filePath << fileName << pParentVariablesTreeItem->getVariableName() + "." + variable << variable;
      }
      /* find the variable in the xml file */
      QString variableToFind = variableData[2].toString();
      variableToFind.remove(QRegExp(pTopVariablesTreeItem->getVariableName() + "."));
      /* get the variable information i.e value, unit, displayunit, description */
      QString value, variability, unit, displayUnit, description;
      bool changeAble = false;
      getVariableInformation(&matReader, variableToFind, &value, &changeAble, &variability, &unit, &displayUnit, &description);
      variableData << StringHandler::unparse(QString("\"").append(value).append("\""));
      /* set the variable unit */
      variableData << StringHandler::unparse(QString("\"").append(unit).append("\""));
      /* set the variable displayUnit */
      variableData << StringHandler::unparse(QString("\"").append(displayUnit).append("\""));
      /* set the variable displayUnits */
      if (!variableData[5].toString().isEmpty()) {
        QStringList displayUnits, displayUnitOptions;
        displayUnits << variableData[5].toString();
        if (!variableData[6].toString().isEmpty()) {
          displayUnitOptions << variableData[6].toString();
          /* convert value to displayUnit */
          OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(variableData[5].toString(), variableData[6].toString());
          if (convertUnit.unitsCompatible) {
            bool ok = true;
            qreal realValue = variableData[4].toDouble(&ok);
            if (ok) {
              realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
              variableData[4] = QString::number(realValue);
            }
          }
        } else { /* use unit as displayUnit */
          variableData[6] = variableData[5];
        }
        displayUnits << displayUnitOptions;
        variableData << displayUnits;
      } else {
        variableData << QStringList();
      }
      /* set the variable description */
      variableData << StringHandler::unparse(QString("\"").append(description).append("\""));
      /* construct tooltip text */
      if (simulationOptions.isInteractiveSimulation()) {
        variableData << tr("Variable: %1\nVariability: %2").arg(variableToFind).arg(variability);
      } else {
        variableData << tr("File: %1/%2\nVariable: %3\nVariability: %4").arg(filePath).arg(fileName).arg(variableToFind).arg(variability);
      }
      /*is main array*/
      if (variables.size() == count+1 && QRegExp("\\[\\d+\\]").exactMatch(variables.last())) {
        variableData << true;
      } else {
        variableData << false;
      }
      VariablesTreeItem *pVariablesTreeItem = new VariablesTreeItem(variableData, pParentVariablesTreeItem);
      pVariablesTreeItem->setEditable(changeAble);
      pVariablesTreeItem->setVariability(variability);
      int row = rowCount(index);
      beginInsertRows(index, row, row);
      pParentVariablesTreeItem->insertChild(row, pVariablesTreeItem);
      endInsertRows();
      QString addVar;
      //if second to last of array, add der(
      if ((variables.size() == count+1 && QRegExp("\\[\\d+\\]").exactMatch(variables.last())) && plotVariable.startsWith("der("))
        addVar = StringHandler::joinDerivativeAndPreviousVariable(plotVariable, variable, "der(");
      else
        addVar = variable;
      if (count == 1) {
        parentVariable = addVar;
      } else {
        parentVariable += "." + addVar;
      }
      count++;
    }
  }
  /* close the .mat file */
  if (fileName.endsWith(".mat")) {
    if (matReader.file) {
      omc_free_matlab4_reader(&matReader);
    }
  }
  mpVariablesTreeView->collapseAll();
  QModelIndex idx = variablesTreeItemIndex(pTopVariablesTreeItem);
  idx = mpVariablesTreeView->getVariablesWidget()->getVariableTreeProxyModel()->mapFromSource(idx);
  mpVariablesTreeView->expand(idx);
  /* Ticket #3016.
   * If you only have one model the message "You must select a class to re-simulate" is annoying.
   * A default behavior of selecting the (single) model would be good.
   * The following line selects the result tree top level item.
   */
  mpVariablesTreeView->setCurrentIndex(idx);
  MainWindow::instance()->enableReSimulationToolbar(MainWindow::instance()->getVariablesDockWidget()->isVisible());
}

/*!
 * \brief VariablesTreeModel::removeVariableTreeItem
 * Removes the VariablesTreeItem.
 * \param variable
 * \return
 */
bool VariablesTreeModel::removeVariableTreeItem(QString variable)
{
  VariablesTreeItem *pVariablesTreeItem = findVariablesTreeItem(variable, mpRootVariablesTreeItem);
  if (pVariablesTreeItem) {
    beginRemoveRows(variablesTreeItemIndex(pVariablesTreeItem), 0, pVariablesTreeItem->getChildren().size());
    pVariablesTreeItem->removeChildren();
    VariablesTreeItem *pParentVariablesTreeItem = pVariablesTreeItem->parent();
    pParentVariablesTreeItem->removeChild(pVariablesTreeItem);

    if (pVariablesTreeItem->getSimulationOptions().isInteractiveSimulation()) {
      for (const auto& p : MainWindow::instance()->getSimulationDialog()->getSimulationOutputWidgetsList()) {
        // remove the right interactive output widget
        if (p->getSimulationOptions().getClassName() == pVariablesTreeItem->getFileName()) {
          MainWindow::instance()->getSimulationDialog()->removeSimulationOutputWidget(p);
          break;
        }
      }
    }
    if (pVariablesTreeItem) {
      delete pVariablesTreeItem;
    }
    endRemoveRows();
    mpVariablesTreeView->getVariablesWidget()->findVariables();
    return true;
  }
  return false;
}

void VariablesTreeModel::unCheckVariables(VariablesTreeItem *pVariablesTreeItem)
{
  QList<VariablesTreeItem*> items = pVariablesTreeItem->getChildren();
  for (int i = 0 ; i < items.size() ; i++) {
    items[i]->setData(0, Qt::Unchecked, Qt::CheckStateRole);
    unCheckVariables(items[i]);
  }
}

void VariablesTreeModel::plotAllVariables(VariablesTreeItem *pVariablesTreeItem, PlotWindow *pPlotWindow)
{
  QList<VariablesTreeItem*> variablesTreeItems = pVariablesTreeItem->getChildren();
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
    mpVariablesTreeView->getVariablesWidget()->plotVariables(index, pPlotWindow->getCurveWidth(), pPlotWindow->getCurveStyle(), pPlotCurve);
  } else {
    for (int i = 0 ; i < variablesTreeItems.size() ; i++) {
      plotAllVariables(variablesTreeItems[i], pPlotWindow);
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
  if (xmlReader.tokenType() != QXmlStreamReader::StartElement && xmlReader.name() == "ScalarVariable") {
    return scalarVariable;
  }
  /* Let's get the attributes for ScalarVariable */
  QXmlStreamAttributes attributes = xmlReader.attributes();
  /* Read the ScalarVariable attributes. */
  scalarVariable["name"] = attributes.value("name").toString();
  scalarVariable["description"] = attributes.value("description").toString();
  scalarVariable["isValueChangeable"] = attributes.value("isValueChangeable").toString();
  scalarVariable["variability"] = attributes.value("variability").toString();
  /* Read the next element i.e Real, Integer, Boolean etc. */
  xmlReader.readNext();
  while (!(xmlReader.tokenType() == QXmlStreamReader::EndElement && xmlReader.name() == "ScalarVariable")) {
    if (xmlReader.tokenType() == QXmlStreamReader::StartElement) {
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
 * \param value
 * \param changeAble
 * \param variability
 * \param unit
 * \param displayUnit
 * \param description
 */
void VariablesTreeModel::getVariableInformation(ModelicaMatReader *pMatReader, QString variableToFind, QString *value, bool *changeAble,
                                                QString *variability, QString *unit, QString *displayUnit, QString *description)
{
  QHash<QString, QString> hash = mScalarVariablesHash.value(variableToFind);
  if (hash["name"].compare(variableToFind) == 0) {
    *changeAble = (hash["isValueChangeable"].compare("true") == 0) ? true : false;
    *variability = hash["variability"];
    if (*changeAble) {
      *value = hash["start"];
    } else { /* if the variable is not a tunable parameter then read the final value of the variable. Only mat result files are supported. */
      if ((pMatReader->file != NULL) && strcmp(pMatReader->fileName, "")) {
        *value = "";
        ModelicaMatVariable_t *var;
        if (0 == (var = omc_matlab4_find_var(pMatReader, variableToFind.toStdString().c_str()))) {
          qDebug() << QString("%1 not found in %2").arg(variableToFind).arg(pMatReader->fileName);
        }
        double res;
        if (var && !omc_matlab4_val(&res, pMatReader, var, omc_matlab4_stopTime(pMatReader))) {
          *value = QString::number(res);
        }
      }
    }
    *unit = hash["unit"];
    *displayUnit = hash["displayUnit"];
    *description = hash["description"];
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
    removeVariableTreeItem(pAction->data().toString());
    emit variableTreeItemRemoved(pAction->data().toString());
  }
}

/*!
 * \brief VariablesTreeModel::setVariableTreeItemActive
 * Slots activated when mpSetResultActiveAction triggered SIGNAL is raised.
 * Sets a VariablesTreeItem active.
 */
void VariablesTreeModel::setVariableTreeItemActive()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction) {
    VariablesTreeItem *pVariablesTreeItem = findVariablesTreeItem(pAction->data().toString(), mpRootVariablesTreeItem);
    if (pVariablesTreeItem) {
      mpActiveVariablesTreeItem = pVariablesTreeItem;
      pVariablesTreeItem->setActive();
    }
  }
}

/*!
 * \class VariableTreeProxyModel
 * \brief A sort filter proxy model for Variables Browser.
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
  if (!filterRegExp().isEmpty()) {
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
        variableName.remove(QRegExp("(\\.mat|\\.plt|\\.csv|_res.mat|_res.plt|_res.csv)"));
        return variableName.contains(filterRegExp());
      } else {
        return sourceModel()->data(index).toString().contains(filterRegExp());
      }
      QString key = sourceModel()->data(index, filterRole()).toString();
      return key.contains(filterRegExp());
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
      if (pVariablesTreeItem && pVariablesTreeItem) {
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
      mpVariablesWidget->getVariablesTreeModel()->removeVariableTreeItem(pVariablesTreeItem->getVariableName());
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
  connect(mpSimulationTimeComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(timeUnitChanged(QString)));
  // simulation time slider
  mpSimulationTimeSlider = new QSlider(Qt::Horizontal);
  mpSimulationTimeSlider->setMinimum(0);
  mpSimulationTimeSlider->setMaximum(100);
  connect(mpSimulationTimeSlider, SIGNAL(valueChanged(int)), SLOT(simulationTimeChanged(int)));
  // toolbar
  mpToolBar = new QToolBar;
  int toolbarIconSize = OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value();
  mpToolBar->setIconSize(QSize(toolbarIconSize, toolbarIconSize));
  // rewind action
  mpRewindAction = new QAction(QIcon(":/Resources/icons/initialize.svg"), tr("Rewind"), this);
  mpRewindAction->setStatusTip(tr("Rewinds the visualization to the start"));
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
  mpTimeTextBox->setMaximumSize(QSize(toolbarIconSize*2, toolbarIconSize));
  mpTimeTextBox->setValidator(pDoubleValidator);
  connect(mpTimeTextBox, SIGNAL(returnPressed()), SLOT(visulizationTimeChanged()));
  // speed
  mpSpeedLabel = new Label;
  mpSpeedLabel->setText(Helper::speed);
  mpSpeedComboBox = new QComboBox;
  mpSpeedComboBox->setEditable(true);
  mpSpeedComboBox->addItems(Helper::speedOptions.split(","));
  mpSpeedComboBox->setCurrentIndex(3);
  mpSpeedComboBox->setMaximumSize(QSize(toolbarIconSize*2, toolbarIconSize));
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
  pMainLayout->addWidget(mpSimulationTimeSlider, 2, 0, 1, 2);
  pMainLayout->addWidget(mpToolBar, 3, 0, 1, 2);
  pMainLayout->addWidget(mpVariablesTreeView, 4, 0, 1, 2);
  setLayout(pMainLayout);
  connect(mpTreeSearchFilters->getExpandAllButton(), SIGNAL(clicked()), mpVariablesTreeView, SLOT(expandAll()));
  connect(mpTreeSearchFilters->getCollapseAllButton(), SIGNAL(clicked()), mpVariablesTreeView, SLOT(collapseAll()));
  connect(mpVariablesTreeModel, SIGNAL(rowsInserted(QModelIndex,int,int)), mpVariableTreeProxyModel, SLOT(invalidate()));
  connect(mpVariablesTreeModel, SIGNAL(rowsRemoved(QModelIndex,int,int)), mpVariableTreeProxyModel, SLOT(invalidate()));
  connect(mpVariablesTreeModel, SIGNAL(itemChecked(QModelIndex,qreal,int)), SLOT(plotVariables(QModelIndex,qreal,int)));
  connect(mpVariablesTreeModel, SIGNAL(unitChanged(QModelIndex)), SLOT(unitChanged(QModelIndex)));
  connect(mpVariablesTreeModel, SIGNAL(valueEntered(QModelIndex)), SLOT(valueEntered(QModelIndex)));
  connect(mpVariablesTreeView, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  connect(MainWindow::instance()->getPlotWindowContainer(), SIGNAL(subWindowActivated(QMdiSubWindow*)), this, SLOT(updateVariablesTree(QMdiSubWindow*)));
  connect(mpVariablesTreeModel, SIGNAL(variableTreeItemRemoved(QString)), MainWindow::instance()->getPlotWindowContainer(), SLOT(updatePlotWindows(QString)));
  //connect(mpVariablesTreeModel, SIGNAL(clicked(QModelIndex)), this, SLOT(selectInteractivePlotWindow(QModelIndex)));
  //connect(mpVariablesTreeModel, SIGNAL(itemChecked(QModelIndex)), SLOT(selectInteractivePlotWindow(QModelIndex)));
}

/*!
 * \brief VariablesWidget::insertVariablesItemsToTree
 * Inserts the result variables in the Variables Browser.
 * \param fileName
 * \param filePath
 * \param variablesList
 * \param simulationOptions
 */
void VariablesWidget::insertVariablesItemsToTree(QString fileName, QString filePath, QStringList variablesList,
                                                 SimulationOptions simulationOptions)
{
  /* Show results in model diagram if it is present in ModelWidgetContainer
   * and if switch to plotting perspective is disabled
   */
  ModelWidget *pModelWidget = NULL;
  if (!OptionsDialog::instance()->getSimulationPage()->getSwitchToPlottingPerspectiveCheckBox()->isChecked()) {
    pModelWidget = MainWindow::instance()->getModelWidgetContainer()->getModelWidget(simulationOptions.getClassName());
  }
  if (pModelWidget != NULL) {
    if (simulationOptions.isReSimulate() && pModelWidget->getResultFileName().isEmpty()) {
      /* skip update of model view if the model has changed */
      pModelWidget = NULL;
    }
    else {
      /* prevent update during removeVariableTreeItem
         because the model will be updated below anyway */
      pModelWidget->updateDynamicResults("");
    }
  }
  /* Remove the simulation result if we already had it in tree */
  bool variableItemDeleted = false;
  variableItemDeleted = mpVariablesTreeModel->removeVariableTreeItem(fileName);

  mpVariablesTreeView->setSortingEnabled(false);
  /* In order to improve the response time of insertVariablesItems function we should clear the filter and collapse all the items. */
  mpVariableTreeProxyModel->setFilterRegExp(QRegExp(""));
  mpVariablesTreeView->collapseAll();
  /* add the plot variables */
  mpVariablesTreeModel->insertVariablesItems(fileName, filePath, variablesList, simulationOptions);

  /* re-check previously checked variables */
  if (simulationOptions.isInteractiveSimulation() && simulationOptions.isReSimulate()) {
    interactiveReSimulation(simulationOptions.getClassName());
  }

  /* update the plot variables tree */
  if (variableItemDeleted) {
    variablesUpdated();
  }
  /* update the model widget */
  if (pModelWidget != NULL) {
    pModelWidget->updateDynamicResults(fileName);
  }
  mpVariablesTreeView->setSortingEnabled(true);
  mpVariablesTreeView->sortByColumn(0, Qt::AscendingOrder);
  /* since we cleared the filter above so we need to apply it back. */
  findVariables();
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
        if (pPlotWindow->getPlotType() == PlotWindow::PLOT) {
          QString curveNameStructure = pPlotCurve->getNameStructure();
          VariablesTreeItem *pVariableTreeItem;
          pVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(curveNameStructure, mpVariablesTreeModel->getRootVariablesTreeItem());
          pPlotCurve->detach();
          if (pVariableTreeItem) {
            bool state = mpVariablesTreeModel->blockSignals(true);
            QModelIndex index = mpVariablesTreeModel->variablesTreeItemIndex(pVariableTreeItem);
            mpVariablesTreeModel->setData(index, Qt::Checked, Qt::CheckStateRole);
            plotVariables(index, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), pPlotCurve, pPlotWindow);
            mpVariablesTreeModel->blockSignals(state);
          } else {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
          }
        } else if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC) {
          QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
          VariablesTreeItem *pXVariableTreeItem;
          pXVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(xVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
          QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
          VariablesTreeItem *pYVariableTreeItem;
          pYVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(yVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
          pPlotCurve->detach();
          if (pXVariableTreeItem && pYVariableTreeItem) {
            bool state = mpVariablesTreeModel->blockSignals(true);
            QModelIndex xIndex = mpVariablesTreeModel->variablesTreeItemIndex(pXVariableTreeItem);
            mpVariablesTreeModel->setData(xIndex, Qt::Checked, Qt::CheckStateRole);
            plotVariables(xIndex, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), pPlotCurve, pPlotWindow);
            QModelIndex yIndex = mpVariablesTreeModel->variablesTreeItemIndex(pYVariableTreeItem);
            mpVariablesTreeModel->setData(yIndex, Qt::Checked, Qt::CheckStateRole);
            plotVariables(yIndex, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), pPlotCurve, pPlotWindow);
            mpVariablesTreeModel->blockSignals(state);
          } else {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
          }
        }
      }
      if (pPlotWindow->getAutoScaleButton()->isChecked()) {
        pPlotWindow->fitInView();
      } else {
        pPlotWindow->getPlot()->replot();
      }
    }
  }
  updateVariablesTreeHelper(MainWindow::instance()->getPlotWindowContainer()->currentSubWindow());
}

void VariablesWidget::updateVariablesTreeHelper(QMdiSubWindow *pSubWindow)
{
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
      if (pPlotWindow->getPlotType() == PlotWindow::PLOT || pPlotWindow->getPlotType() == PlotWindow::PLOTARRAY) {
        QString variable = pPlotCurve->getNameStructure();
        pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(variable, mpVariablesTreeModel->getRootVariablesTreeItem());
        if (pVariablesTreeItem) {
          mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Checked, Qt::CheckStateRole);
        }
      } else if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC || pPlotWindow->getPlotType() == PlotWindow::PLOTARRAYPARAMETRIC) {
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
      } else if (pPlotWindow->getPlotType() == PlotWindow::PLOTINTERACTIVE) {
        QString variable = pPlotCurve->getNameStructure();
        pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(variable, mpVariablesTreeModel->getRootVariablesTreeItem());
        if (pVariablesTreeItem) {
          mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Checked, Qt::CheckStateRole);
        }
        // if a simulation was left running, make a replot
        pPlotWindow->getPlot()->replot();
      }
    }
    mpVariablesTreeModel->blockSignals(state);
  }
  /* invalidate the view so that the items show the updated values. */
  mpVariableTreeProxyModel->invalidate();
}

void VariablesWidget::interactiveReSimulation(QString modelName)
{
  QList<QString> selectedVariables = mSelectedInteractiveVariables.value(modelName);

  foreach (QString variable, selectedVariables) {
    QString curveNameStructure = modelName + "." + variable;
    VariablesTreeItem *pVariableTreeItem;
    pVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(curveNameStructure, mpVariablesTreeModel->getRootVariablesTreeItem());
    if (pVariableTreeItem) {
      bool state = mpVariablesTreeModel->blockSignals(true);
      QModelIndex index = mpVariablesTreeModel->variablesTreeItemIndex(pVariableTreeItem);
      mpVariablesTreeModel->setData(index, Qt::Checked, Qt::CheckStateRole);
      plotVariables(index, 1, 1);
      mpVariablesTreeModel->blockSignals(state);
    }
  }
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
  for (int i = 0 ; i < pVariablesTreeItem->getChildren().size() ; i++) {
    VariablesTreeItem *pChildVariablesTreeItem = pVariablesTreeItem->child(i);
    if (pChildVariablesTreeItem->isEditable() && pChildVariablesTreeItem->isValueChanged()) {
      //QString value = pChildVariablesTreeItem->data(1, Qt::DisplayRole).toString();
      /* Ticket #2250, 4031
       * We need to convert the value to base unit since the values stored in init xml are always in base unit.
       */
      QString value = pChildVariablesTreeItem->getValue(pChildVariablesTreeItem->getDisplayUnit(),
                                                        pChildVariablesTreeItem->getUnit()).toString();
      QString variableToFind = pChildVariablesTreeItem->getVariableName();
      variableToFind.remove(QRegExp(outputFileName + "."));
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
                             tr("You must select a class to re-simulate."), Helper::ok);
    return;
  }
  QModelIndex index = indexes.at(0);
  index = mpVariableTreeProxyModel->mapToSource(index);
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  pVariablesTreeItem = pVariablesTreeItem->rootParent();
  SimulationOptions simulationOptions = pVariablesTreeItem->getSimulationOptions();
  if (simulationOptions.isValid()) {
    if (simulationOptions.isInteractiveSimulation()) {
      QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                               tr("You cannot re-simulate an interactive simulation."), Helper::ok);
    } else {
      simulationOptions.setReSimulate(true);
      updateInitXmlFile(simulationOptions);
      if (showSetup) {
        MainWindow::instance()->getSimulationDialog()->show(0, true, simulationOptions);
      } else {
        MainWindow::instance()->getSimulationDialog()->reSimulate(simulationOptions);
      }
    }
  } else {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             tr("You cannot re-simulate this class.<br />This is just a result file loaded via menu <b>File->Open Result File(s)</b>."), Helper::ok);
  }
}

void VariablesWidget::updateInitXmlFile(SimulationOptions simulationOptions)
{
  /* Update the _init.xml file with new values. */
  /* open the model_init.xml file for writing */
  QString initFileName = QString(simulationOptions.getOutputFileName()).append("_init.xml");
  QFile initFile(QString(simulationOptions.getWorkingDirectory()).append(QDir::separator()).append(initFileName));
  QDomDocument initXmlDocument;
  if (initFile.open(QIODevice::ReadOnly)) {
    if (initXmlDocument.setContent(&initFile)) {
      VariablesTreeItem *pTopVariableTreeItem;
      pTopVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(simulationOptions.getFullResultFileName(),
                                                                         mpVariablesTreeModel->getRootVariablesTreeItem());
      if (pTopVariableTreeItem) {
        QHash<QString, QHash<QString, QString> > variables;
        readVariablesAndUpdateXML(pTopVariableTreeItem, simulationOptions.getFullResultFileName(), &variables);
        findVariableAndUpdateValue(initXmlDocument, variables);
      }
    } else {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                            tr("Unable to set the content of QDomDocument from file %1")
                                                            .arg(initFile.fileName()), Helper::scriptingKind, Helper::errorLevel));
    }
    initFile.close();
    initFile.open(QIODevice::WriteOnly | QIODevice::Truncate);
    QTextStream textStream(&initFile);
    textStream.setCodec(Helper::utf8.toStdString().data());
    textStream.setGenerateByteOrderMark(false);
    textStream << initXmlDocument.toString();
    initFile.close();
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(initFile.fileName())
                                                          .arg(initFile.errorString()), Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief VariablesWidget::initializeVisualization
 * Initializes the TimeManager with SimulationOptions for Visualization.
 * \param simulationOptions
 */
void VariablesWidget::initializeVisualization(SimulationOptions simulationOptions)
{
  // close any result file before opening a new one
  closeResultFile();
  // Open the file for reading
  openResultFile();
  // Initialize the time manager
  mpTimeManager->setStartTime(simulationOptions.getStartTime().toDouble());
  mpTimeManager->setEndTime(simulationOptions.getStopTime().toDouble());
  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  mpTimeManager->setPause(true);
  // reset the visualization controls
  mpTimeTextBox->setText("0.0");
  mpSimulationTimeSlider->setValue(0);
}

/*!
 * \brief VariablesWidget::readVariableValue
 * Reads the variable value at specific time.
 * \param variable
 * \param time
 * \return
 */
double VariablesWidget::readVariableValue(QString variable, double time)
{
  double value = 0.0;
  if (mModelicaMatReader.file) {
    ModelicaMatVariable_t* var = omc_matlab4_find_var(&mModelicaMatReader, variable.toStdString().c_str());
    if (var) {
      omc_matlab4_val(&value, &mModelicaMatReader, var, time);
    }
  } else if (mpCSVData) {
    double *timeDataSet = read_csv_dataset(mpCSVData, "time");
    if (timeDataSet) {
      for (int i = 0 ; i < mpCSVData->numsteps ; i++) {
        if (QString::number(timeDataSet[i]).compare(QString::number(time)) == 0) {
          double *varDataSet = read_csv_dataset(mpCSVData, variable.toStdString().c_str());
          if (varDataSet) {
            value = varDataSet[i];
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
          break;
        }
      }
    }
    textStream.seek(0);
  }
  return value;
}

void VariablesWidget::plotVariables(const QModelIndex &index, qreal curveThickness, int curveStyle, PlotCurve *pPlotCurve,
                                    PlotWindow *pPlotWindow)
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
      pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    }
    // if the variable is not an array and
    // pPlotWindow is 0 or the plot's type is PLOTARRAY or PLOTARRAYPARAMETRIC
    // then create a new plot window.
    if (!pVariablesTreeItem->isMainArray() &&
            (!pPlotWindow || pPlotWindow->getPlotType()==PlotWindow::PLOTARRAY
             || pPlotWindow->getPlotType()== PlotWindow::PLOTARRAYPARAMETRIC))
    {
        MainWindow::instance()->getPlotWindowContainer()->addPlotWindow();
        bool state = MainWindow::instance()->getPlotWindowContainer()->blockSignals(true);
        bool state2 = mpVariablesTreeModel->blockSignals(true);
        mpVariablesTreeModel->setData(index, Qt::Checked, Qt::CheckStateRole);
        mpVariablesTreeModel->blockSignals(state2);
        MainWindow::instance()->getPlotWindowContainer()->blockSignals(state);
        pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    }
    // if the variable is an array and
    // pPlotWindow is 0 or the plot's type is PLOT or PLOTPARAMETRIC
    // then create a new plot window.
    else if (pVariablesTreeItem->isMainArray() &&
               (!pPlotWindow || pPlotWindow->getPlotType()==PlotWindow::PLOT ||
                pPlotWindow->getPlotType()==PlotWindow::PLOTPARAMETRIC))
    {
        MainWindow::instance()->getPlotWindowContainer()->addArrayPlotWindow();
        bool state = MainWindow::instance()->getPlotWindowContainer()->blockSignals(true);
        bool state2 = mpVariablesTreeModel->blockSignals(true);
        mpVariablesTreeModel->setData(index, Qt::Checked, Qt::CheckStateRole);
        mpVariablesTreeModel->blockSignals(state2);
        MainWindow::instance()->getPlotWindowContainer()->blockSignals(state);
        pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    }



    // if still pPlotWindow is 0 then return.
    if (!pPlotWindow) {
      bool state = mpVariablesTreeModel->blockSignals(true);
      mpVariablesTreeModel->setData(index, Qt::Unchecked, Qt::CheckStateRole);
      mpVariablesTreeModel->blockSignals(state);
      QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               tr("No plot window is active for plotting. Please select a plot window or open a new."), Helper::ok);
      return;
    }
    // if plottype is PLOT or PLOTARRAY then
    if (pPlotWindow->getPlotType() == PlotWindow::PLOT || pPlotWindow->getPlotType() == PlotWindow::PLOTARRAY) {
      // check the item checkstate
      if (pVariablesTreeItem->isChecked()) {
        VariablesTreeItem *pVariablesTreeRootItem = pVariablesTreeItem;
        if (!pVariablesTreeItem->isRootItem()) {
          pVariablesTreeRootItem = pVariablesTreeItem->rootParent();
        }
        if (pVariablesTreeRootItem->getSimulationOptions().isInteractiveSimulation()) {
          QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                   tr("Can not be attached to a plot window."), Helper::ok);
          pVariablesTreeItem->setChecked(false);
          return;
        }
        pPlotWindow->initializeFile(QString(pVariablesTreeItem->getFilePath()).append("/").append(pVariablesTreeItem->getFileName()));
        pPlotWindow->setCurveWidth(curveThickness);
        pPlotWindow->setCurveStyle(curveStyle);
        pPlotWindow->setVariablesList(QStringList(pVariablesTreeItem->getPlotVariable()));
        pPlotWindow->setUnit(pVariablesTreeItem->getUnit());
        pPlotWindow->setDisplayUnit(pVariablesTreeItem->getDisplayUnit());
        if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
            pPlotWindow->plot(pPlotCurve);
        else/* ie. (pPlotWindow->getPlotType() == PlotWindow::PLOTARRAY)*/{
          double timePercent = (double) mpSimulationTimeSlider->value();
          pPlotWindow->plotArray(timePercent,pPlotCurve);
        }
        /* Ticket:4231
         * Only update the variables browser value and unit when updating some curve not when checking/unchecking variable.
         */
        if (pPlotCurve) {
          /* Ticket:2250
           * Update the value of Variables Browser display unit according to the display unit of already plotted curve.
           */
          pVariablesTreeItem->setData(3, pPlotCurve->getDisplayUnit(), Qt::EditRole);
          QString value = pVariablesTreeItem->getValue(pVariablesTreeItem->getPreviousUnit(), pVariablesTreeItem->getDisplayUnit()).toString();
          pVariablesTreeItem->setData(1, value, Qt::EditRole);
        }
        if (!pPlotCurve) {
          pPlotCurve = pPlotWindow->getPlot()->getPlotCurvesList().last();
        }
        if (pPlotCurve && pVariablesTreeItem->getUnit().compare(pVariablesTreeItem->getDisplayUnit()) != 0) {
          OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(pVariablesTreeItem->getUnit(),
                                                                                                 pVariablesTreeItem->getDisplayUnit());
          if (convertUnit.unitsCompatible) {
            for (int i = 0 ; i < pPlotCurve->mYAxisVector.size() ; i++) {
              pPlotCurve->updateYAxisValue(i, Utilities::convertUnit(pPlotCurve->mYAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
            }
            pPlotCurve->setData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(), pPlotCurve->getSize());
            pPlotWindow->getPlot()->replot();
          } else {
            pPlotCurve->setDisplayUnit(pVariablesTreeItem->getUnit());
          }
          pPlotCurve->setTitleLocal();
        }
        // update the time values if time unit is different then s
        if (pPlotWindow->getTimeUnit().compare("s") != 0) {
          OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits("s", pPlotWindow->getTimeUnit());
          if (convertUnit.unitsCompatible) {
            for (int i = 0 ; i < pPlotCurve->mXAxisVector.size() ; i++) {
              pPlotCurve->updateXAxisValue(i, Utilities::convertUnit(pPlotCurve->mXAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
            }
            pPlotCurve->setData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(), pPlotCurve->getSize());
            pPlotWindow->getPlot()->replot();
          }
        }
        if (pPlotWindow->getAutoScaleButton()->isChecked()) {
          pPlotWindow->fitInView();
        } else {
          pPlotWindow->getPlot()->replot();
          if (pPlotWindow->getPlot()->getPlotZoomer()->zoomStack().size() == 1) {
            pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
          }
        }
      } else if (!pVariablesTreeItem->isChecked()) {  // if user unchecks the variable then remove it from the plot
        foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
          QString curveTitle = pPlotCurve->getNameStructure();
          if (curveTitle.compare(pVariablesTreeItem->getVariableName()) == 0) {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
            if (pPlotWindow->getAutoScaleButton()->isChecked()) {
              pPlotWindow->fitInView();
            } else {
              pPlotWindow->getPlot()->replot();
            }
            break;
          }
        }
      }
    } else if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC || pPlotWindow->getPlotType() == PlotWindow::PLOTARRAYPARAMETRIC) {  // if plottype is PLOTPARAMETRIC or PLOTARRAYPARAMETRIC then
      // check the item checkstate
      if (pVariablesTreeItem->isChecked()) {
        VariablesTreeItem *pVariablesTreeRootItem = pVariablesTreeItem;
        if (!pVariablesTreeItem->isRootItem()) {
          pVariablesTreeRootItem = pVariablesTreeItem->rootParent();
        }
        if (pVariablesTreeRootItem->getSimulationOptions().isInteractiveSimulation()) {
          QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                   tr("Can not be attached to a parametric plot window."), Helper::ok);
          pVariablesTreeItem->setChecked(false);
          return;
        }
        // if mPlotParametricVariables is empty just add one QStringlist with 1 varibale to it
        if (mPlotParametricVariables.isEmpty()) {
          mPlotParametricVariables.append(QStringList() << pVariablesTreeItem->getPlotVariable() << pVariablesTreeItem->getUnit());
          mFileName = pVariablesTreeItem->getFileName();
        } else {  // if mPlotParametricVariables is not empty then add one string to its last element
          if (mPlotParametricVariables.last().size() < 4) {
            if (mFileName.compare(pVariablesTreeItem->getFileName()) != 0) {
              bool state = mpVariablesTreeModel->blockSignals(true);
              mpVariablesTreeModel->setData(index, Qt::Unchecked, Qt::CheckStateRole);
              QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                                    GUIMessages::getMessage(GUIMessages::PLOT_PARAMETRIC_DIFF_FILES), Helper::ok);
              mpVariablesTreeModel->blockSignals(state);
              return;
            }
            mPlotParametricVariables.last().append(QStringList() << pVariablesTreeItem->getPlotVariable() << pVariablesTreeItem->getUnit());
            pPlotWindow->initializeFile(QString(pVariablesTreeItem->getFilePath()).append("/").append(pVariablesTreeItem->getFileName()));
            pPlotWindow->setCurveWidth(curveThickness);
            pPlotWindow->setCurveStyle(curveStyle);
            pPlotWindow->setVariablesList(QStringList() << mPlotParametricVariables.last().at(0) << mPlotParametricVariables.last().at(2));
            if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC)
                pPlotWindow->plotParametric(pPlotCurve);
            else /* ie. (pPlotWindow->getPlotType() == PlotWindow::PLOTARRAYPARAMETRIC)*/{
              double timePercent = mpSimulationTimeSlider->value();
              pPlotWindow->plotArrayParametric(timePercent,pPlotCurve);
            }

            if (pPlotWindow->getPlot()->getPlotCurvesList().size() > 1) {
              pPlotWindow->setXLabel("");
              pPlotWindow->setYLabel("");
            } else {
              QString xVariable = mPlotParametricVariables.last().at(0);
              QString xUnit = mPlotParametricVariables.last().at(1);
              QString yVariable = mPlotParametricVariables.last().at(2);
              QString yUnit = mPlotParametricVariables.last().at(3);
              if (xUnit.isEmpty()) {
                pPlotWindow->setXLabel(xVariable);
              } else {
                pPlotWindow->setXLabel(xVariable + " (" + xUnit + ")");
              }

              if (yUnit.isEmpty()) {
                pPlotWindow->setYLabel(yVariable);
              } else {
                pPlotWindow->setYLabel(yVariable + " (" + yUnit + ")");
              }
            }
            if (pPlotWindow->getAutoScaleButton()->isChecked()) {
              pPlotWindow->fitInView();
            } else {
              pPlotWindow->getPlot()->replot();
              if (pPlotWindow->getPlot()->getPlotZoomer()->zoomStack().size() == 1) {
                pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
              }
            }
          } else {
            mPlotParametricVariables.append(QStringList() << pVariablesTreeItem->getPlotVariable() << pVariablesTreeItem->getUnit());
            mFileName = pVariablesTreeItem->getFileName();
          }
        }
      } else if (!pVariablesTreeItem->isChecked()) {  // if user unchecks the variable then remove it from the plot
        // remove the variable from mPlotParametricVariables list
        foreach (QStringList list, mPlotParametricVariables) {
          if (list.contains(pVariablesTreeItem->getPlotVariable())) {
            // if list has only one variable then clear the list and return;
            if (list.size() < 4) {
              mPlotParametricVariables.removeOne(list);
              break;
            } else {  // if list has more than two variables then remove both and remove the curve
              QString itemTitle = QString(pVariablesTreeItem->getFileName()).append(".").append(list.at(2)).append(" vs ").append(list.at(0));
              foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
                QString curveTitle = pPlotCurve->getNameStructure();
                if ((curveTitle.compare(itemTitle) == 0) && (pVariablesTreeItem->getFileName().compare(pPlotCurve->getFileName()) == 0)) {
                  bool state = mpVariablesTreeModel->blockSignals(true);
                  // uncheck the x variable
                  QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
                  VariablesTreeItem *pVariablesTreeItem;
                  pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(xVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
                  if (pVariablesTreeItem) {
                    mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Unchecked, Qt::CheckStateRole);
                  }
                  // uncheck the y variable
                  QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
                  pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(yVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
                  if (pVariablesTreeItem) {
                    mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Unchecked, Qt::CheckStateRole);
                  }
                  mpVariablesTreeModel->blockSignals(state);
                  pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                  pPlotCurve->detach();
                  if (pPlotWindow->getAutoScaleButton()->isChecked()) {
                    pPlotWindow->fitInView();
                  } else {
                    pPlotWindow->getPlot()->replot();
                  }
                }
              }
              mPlotParametricVariables.removeOne(list);
              if (pPlotWindow->getPlot()->getPlotCurvesList().size() == 1) {
                if (mPlotParametricVariables.last().size() > 3) {
                  QString xVariable = mPlotParametricVariables.last().at(0);
                  QString xUnit = mPlotParametricVariables.last().at(1);
                  QString yVariable = mPlotParametricVariables.last().at(2);
                  QString yUnit = mPlotParametricVariables.last().at(3);
                  if (xUnit.isEmpty()) {
                    pPlotWindow->setXLabel(xVariable);
                  } else {
                    pPlotWindow->setXLabel(xVariable + " (" + xUnit + ")");
                  }

                  if (yUnit.isEmpty()) {
                    pPlotWindow->setYLabel(yVariable);
                  } else {
                    pPlotWindow->setYLabel(yVariable + " (" + yUnit + ")");
                  }
                } else {
                  pPlotWindow->setXLabel("");
                  pPlotWindow->setYLabel("");
                }
              } else {
                pPlotWindow->setXLabel("");
                pPlotWindow->setYLabel("");
              }
            }
          }
        }
      }
    }
    else { // if plottype is INTERACTIVE then
      VariablesTreeItem *pVariablesTreeRootItem = pVariablesTreeItem;
      if (!pVariablesTreeItem->isRootItem()) {
        pVariablesTreeRootItem = pVariablesTreeItem->rootParent();
      }
      int port = pVariablesTreeRootItem->getSimulationOptions().getInteractiveSimulationPortNumber();

      if (pVariablesTreeItem->isChecked()) { // if user checks the variable
        if (!pVariablesTreeRootItem->getSimulationOptions().isInteractiveSimulation()) {
          QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                                   tr("Can not be attached to an interactive plot window."), Helper::ok);
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
            pPlotWindow->setUnit(pVariablesTreeItem->getUnit());
            pPlotWindow->setDisplayUnit(pVariablesTreeItem->getDisplayUnit());
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
          if (pVariablesTreeItem->getVariableName().endsWith("." + pPlotCurve->getName())) {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
            if (pPlotWindow->getAutoScaleButton()->isChecked()) {
              pPlotWindow->fitInView();
            } else {
              pPlotWindow->getPlot()->replot();
            }
            break;
          }
        }
      }
    }
  } catch (PlotException &e) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), Helper::ok);
  }
}

void VariablesWidget::addSelectedInteractiveVariables(const QString &modelName, const QList<QString> &selectedVariables)
{
  mSelectedInteractiveVariables.insert(modelName, selectedVariables);
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
    OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(pVariablesTreeItem->getPreviousUnit(),
                                                                                           pVariablesTreeItem->getDisplayUnit());
    if (convertUnit.unitsCompatible) {
      /* update value */
      QVariant stringValue = pVariablesTreeItem->data(1, Qt::EditRole);
      bool ok = true;
      qreal realValue = stringValue.toDouble(&ok);
      if (ok) {
        realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
        pVariablesTreeItem->setData(1, QString::number(realValue), Qt::EditRole);
      }
      /* update plots */
      foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
        QString curveTitle = pPlotCurve->getNameStructure();
        if (curveTitle.compare(pVariablesTreeItem->getVariableName()) == 0) {
          for (int i = 0 ; i < pPlotCurve->mYAxisVector.size() ; i++) {
            pPlotCurve->updateYAxisValue(i, Utilities::convertUnit(pPlotCurve->mYAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
          }
          pPlotCurve->setData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(), pPlotCurve->getSize());
          pPlotCurve->setDisplayUnit(pVariablesTreeItem->getDisplayUnit());
          pPlotCurve->setTitleLocal();
          pPlotWindow->getPlot()->replot();
          break;
        }
      }
    }
  } catch (PlotException &e) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), Helper::ok);
  }
}

/*!
 * \brief VariablesWidget::simulationTimeChanged
 * SLOT activated when mpSimulationTimeSlider valueChanged SIGNAL is raised.
 * \param time
 */
void VariablesWidget::simulationTimeChanged(int timePercent)
{
  PlotWindow *pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
  if (pPlotWindow) {
    PlotWindow::PlotType plotType = pPlotWindow->getPlotType();
    if (plotType == PlotWindow::PLOTARRAY) {
      QList<PlotCurve*> curves = pPlotWindow->getPlot()->getPlotCurvesList();
      foreach (PlotCurve* curve, curves) {
        QString varName = curve->getYVariable();
        pPlotWindow->setVariablesList(QStringList(varName));
        pPlotWindow->plotArray(timePercent, curve);
      }
    } else if (plotType == PlotWindow::PLOTARRAYPARAMETRIC) {
      QList<PlotCurve*> curves = pPlotWindow->getPlot()->getPlotCurvesList();
      foreach (PlotCurve* curve, curves) {
        QString xVarName = curve->getXVariable();
        QString yVarName = curve->getYVariable();
        pPlotWindow->setVariablesList({xVarName,yVarName});
        pPlotWindow->plotArrayParametric(timePercent, curve);
      }
    } else {
      return;
    }
  } else { // if no plot window then try to update the DiagramWindow
    float time = (mpTimeManager->getEndTime() - mpTimeManager->getStartTime()) * (float) (timePercent / 100.0);
    mpTimeManager->setVisTime(time);
    mpTimeTextBox->setText(QString::number(mpTimeManager->getVisTime()));
    updateVisualization();
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
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), Helper::ok);
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
 */
void VariablesWidget::openResultFile()
{
  if (mpVariablesTreeModel->getActiveVariablesTreeItem()) {
    // read filename
    QString fileName = QString("%1/%2").arg(mpVariablesTreeModel->getActiveVariablesTreeItem()->getFilePath())
                       .arg(mpVariablesTreeModel->getActiveVariablesTreeItem()->getFileName());
    bool errorOpeningFile = false;
    QString errorString = "";
    if (mpVariablesTreeModel->getActiveVariablesTreeItem()->getFileName().endsWith(".mat")) {
      const char *msg[] = {""};
      if (0 != (msg[0] = omc_new_matlab4_reader(fileName.toStdString().c_str(), &mModelicaMatReader))) {
        errorOpeningFile = true;
        errorString = msg[0];
      }
    } else if (mpVariablesTreeModel->getActiveVariablesTreeItem()->getFileName().endsWith(".csv")) {
      mpCSVData = read_csv(fileName.toStdString().c_str());
      if (!mpCSVData) {
        errorOpeningFile = true;
      }
    } else if (mpVariablesTreeModel->getActiveVariablesTreeItem()->getFileName().endsWith(".plt")) {
      mPlotFileReader.setFileName(fileName);
      if (!mPlotFileReader.open(QIODevice::ReadOnly)) {
        errorOpeningFile = true;
        errorString = mPlotFileReader.errorString();
      }
    }
    // check file opening error
    if (errorOpeningFile) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
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
  mpTimeManager->updateTick();  //for real-time measurement
  double visTime = mpTimeManager->getRealTime();
  // Update the DiagramWindow
  emit updateDynamicSelect(mpTimeManager->getVisTime());
  if (MainWindow::instance()->getPlotWindowContainer()->getDiagramWindow()) {
    MainWindow::instance()->getPlotWindowContainer()->getDiagramWindow()->getGraphicsView()->scene()->update();
  }
  mpTimeManager->updateTick();  //for real-time measurement
  visTime = mpTimeManager->getRealTime() - visTime;
  mpTimeManager->setRealTimeFactor(mpTimeManager->getHVisual() / visTime);
}

/*!
 * \brief VariablesWidget::timeUnitChanged
 * Handles the case when simulation time unit is changed.\n
 * Updates the x values of all the curves.
 * \param unit
 */
void VariablesWidget::timeUnitChanged(QString unit)
{
  if (unit.isEmpty()) {
    return;
  }
  try {
    OMPlot::PlotWindow *pPlotWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentWindow();
    // if still pPlotWindow is 0 then return.
    if (!pPlotWindow) {
      return;
    }
    if (pPlotWindow->getPlotType() == PlotWindow::PLOTARRAY ||
        pPlotWindow->getPlotType() == PlotWindow::PLOTARRAYPARAMETRIC) {
      pPlotWindow->setTimeUnit(unit);
      pPlotWindow->updateTimeText(unit);
    } else if (pPlotWindow->getPlotType() == PlotWindow::PLOT ||
               pPlotWindow->getPlotType() == PlotWindow::PLOTINTERACTIVE) {
      OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(pPlotWindow->getTimeUnit(), unit);
      if (convertUnit.unitsCompatible) {
        foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
          for (int i = 0 ; i < pPlotCurve->mXAxisVector.size() ; i++) {
            pPlotCurve->updateXAxisValue(i, Utilities::convertUnit(pPlotCurve->mXAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
          }
          pPlotCurve->setData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(), pPlotCurve->getSize());
        }
        pPlotWindow->setXLabel(QString("time (%1)").arg(unit));
        pPlotWindow->setTimeUnit(unit);
        pPlotWindow->getPlot()->replot();
      }
    }
  } catch (PlotException &e) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), Helper::ok);
  }
}

/*!
 * \brief VariablesWidget::updateVariablesTree
 * Updates the VariablesTreeView when the subwindow is changed in PlotWindowContainer
 * \param pSubWindow
 */
void VariablesWidget::updateVariablesTree(QMdiSubWindow *pSubWindow)
{
  if (!pSubWindow && MainWindow::instance()->getPlotWindowContainer()->subWindowList().size() != 0) {
    return;
  }
  /* if the same sub window is activated again then just return */
  if (mpLastActiveSubWindow == pSubWindow) {
    mpLastActiveSubWindow = pSubWindow;
    return;
  }
  mpLastActiveSubWindow = pSubWindow;
  updateVariablesTreeHelper(pSubWindow);
}

void VariablesWidget::showContextMenu(QPoint point)
{
  int adjust = 24;
  QModelIndex index = mpVariablesTreeView->indexAt(point);
  index = mpVariableTreeProxyModel->mapToSource(index);
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (pVariablesTreeItem && pVariablesTreeItem->isRootItem())
  {
    /* delete result action */
    QAction *pDeleteResultAction = new QAction(QIcon(":/Resources/icons/delete.svg"), tr("Delete Result"), this);
    pDeleteResultAction->setData(pVariablesTreeItem->getVariableName());
    pDeleteResultAction->setShortcut(QKeySequence::Delete);
    pDeleteResultAction->setStatusTip(tr("Delete the result"));
    connect(pDeleteResultAction, SIGNAL(triggered()), mpVariablesTreeModel, SLOT(removeVariableTreeItem()));

    /* set result active action */
    QAction *pSetResultActiveAction = new QAction(tr("Set Active"), this);
    pSetResultActiveAction->setData(pVariablesTreeItem->getVariableName());
    pSetResultActiveAction->setStatusTip(tr("An active item is used for the visualization"));
    pSetResultActiveAction->setEnabled(pVariablesTreeItem->getSimulationOptions().isValid()
                                       && !pVariablesTreeItem->getSimulationOptions().isInteractiveSimulation()
                                       && !pVariablesTreeItem->isActive());
    connect(pSetResultActiveAction, SIGNAL(triggered()), mpVariablesTreeModel, SLOT(setVariableTreeItemActive()));

    QMenu menu(this);
    menu.addAction(pDeleteResultAction);
    menu.addSeparator();
    menu.addAction(pSetResultActiveAction);
    menu.addSeparator();
    menu.addAction(MainWindow::instance()->getReSimulateModelAction());
    menu.addAction(MainWindow::instance()->getReSimulateSetupAction());
    point.setY(point.y() + adjust);
    menu.exec(mpVariablesTreeView->mapToGlobal(point));
  }
}

/*!
 * \brief VariablesWidget::findVariables
 * Finds the variables in the Variables Browser.
 */
void VariablesWidget::findVariables()
{
  QString findText = mpTreeSearchFilters->getFilterTextBox()->text();
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpTreeSearchFilters->getSyntaxComboBox()->itemData(mpTreeSearchFilters->getSyntaxComboBox()->currentIndex()).toInt());
  Qt::CaseSensitivity caseSensitivity = mpTreeSearchFilters->getCaseSensitiveCheckBox()->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
  QRegExp regExp(findText, caseSensitivity, syntax);
  mpVariableTreeProxyModel->setFilterRegExp(regExp);
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
  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  mpTimeManager->setRealTimeFactor(0.0);
  mpTimeManager->setPause(true);
  bool state = mpSimulationTimeSlider->blockSignals(true);
  mpSimulationTimeSlider->setValue(0);
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
 * \brief VariablesWidget::visulizationTimeChanged
 * Slot activated when mpTimeTextBox returnPressed SIGNAL is raised.
 */
void VariablesWidget::visulizationTimeChanged()
{
  QString time = mpTimeTextBox->text();
  bool isFloat = true;
  double start = mpTimeManager->getStartTime();
  double end = mpTimeManager->getEndTime();
  double value = time.toFloat(&isFloat);
  if (isFloat && value >= 0.0) {
    if (value < start) {
      value = start;
    } else if (value > end) {
      value = end;
    }
    mpTimeManager->setVisTime(value);
    bool state = mpSimulationTimeSlider->blockSignals(true);
    mpSimulationTimeSlider->setValue(mpTimeManager->getTimeFraction());
    mpSimulationTimeSlider->blockSignals(state);
    updateVisualization();
  }
}

/*!
 * \brief VariablesWidget::visualizationSpeedChanged
 * Slot activated when mpSpeedComboBox currentIndexChanged SIGNAL is raised.
 */
void VariablesWidget::visualizationSpeedChanged()
{
  QString speed = mpSpeedComboBox->lineEdit()->text();
  bool isFloat = true;
  double value = speed.toFloat(&isFloat);
  if (isFloat && value > 0.0) {
    mpTimeManager->setSpeedUp(value);
  }
}

/*!
 * \brief VariablesWidget::incrementVisualization
 * Slot activated when TimeManager timer emits timeout SIGNAL.
 */
void VariablesWidget::incrementVisualization()
{
  if (!mpTimeManager->isPaused()) {
    mpTimeTextBox->setText(QString::number(mpTimeManager->getVisTime()));
    // set time slider
    int time = mpTimeManager->getTimeFraction();
    bool state = mpSimulationTimeSlider->blockSignals(true);
    mpSimulationTimeSlider->setValue(time);
    mpSimulationTimeSlider->blockSignals(state);
  }

  //measure realtime
  mpTimeManager->updateTick();
  //update scene and set next time step
  if (!mpTimeManager->isPaused()) {
    updateVisualization();
    //finish animation with pause when endtime is reached
    if (mpTimeManager->getVisTime() >= mpTimeManager->getEndTime()) {
      pauseVisualization();
    } else { // get the new visualization time
      double newTime = mpTimeManager->getVisTime() + (mpTimeManager->getHVisual()*mpTimeManager->getSpeedUp());
      if (newTime <= mpTimeManager->getEndTime()) {
        mpTimeManager->setVisTime(newTime);
      } else {
        mpTimeManager->setVisTime(mpTimeManager->getEndTime());
      }
    }
  }
}
