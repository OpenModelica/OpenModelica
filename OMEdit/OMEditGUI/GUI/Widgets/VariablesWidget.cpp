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
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "VariablesWidget.h"
#include "../../SimulationRuntime/c/util/read_matlab4.h"

using namespace OMPlot;

/*!
  \class VariablesTreeItem
  \brief Contains the information about the result variable.
  */
/*!
  \param variableItemData - a list of items.\n
  0 -> filePath\n
  1 -> fileName\n
  2 -> name\n
  3 -> displayName\n
  4 -> value\n
  5 -> displayUnit\n
  6 -> description\n
  7 -> tooltip
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
  mDisplayUnit = variableItemData[5].toString();
  mDescription = variableItemData[6].toString();
  mToolTip = variableItemData[7].toString();
  mChecked = false;
  mEditable = false;
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

QIcon VariablesTreeItem::getVariableTreeItemIcon(QString name) const
{
  if (name.endsWith(".mat"))
    return QIcon(":/Resources/icons/mat.svg");
  else if (name.endsWith(".plt"))
    return QIcon(":/Resources/icons/plt.svg");
  else if (name.endsWith(".csv"))
    return QIcon(":/Resources/icons/csv.svg");
  else
    return QIcon(":/Resources/icons/mat.svg");
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
  return 4;
}

bool VariablesTreeItem::setData(int column, const QVariant &value, int role)
{
  if (column == 0 && role == Qt::CheckStateRole)
  {
    if (value.toInt() == Qt::Checked)
      setChecked(true);
    else if (value.toInt() == Qt::Unchecked)
      setChecked(false);
    return true;
  }
  else if (column == 1 && role == Qt::EditRole)
  {
    if (mValue.compare(value.toString()) != 0)
    {
      mValueChanged = true;
      mValue = value.toString();
    }
    return true;
  }
  return false;
}

QVariant VariablesTreeItem::data(int column, int role) const
{
  switch (column)
  {
    case 0:
      switch (role)
      {
        case Qt::DisplayRole:
          return mDisplayVariableName;
        case Qt::DecorationRole:
          return mIsRootItem ? getVariableTreeItemIcon(mVariableName) : QIcon();
        case Qt::ToolTipRole:
          return mToolTip;
        case Qt::CheckStateRole:
          if (mChildren.size() > 0)
            return QVariant();
          else
            return isChecked() ? Qt::Checked : Qt::Unchecked;
        default:
          return QVariant();
      }
    case 1:
      switch (role)
      {
        case Qt::DisplayRole:
          return mValue;
        case Qt::EditRole:
          return mValue;
        default:
          return QVariant();
      }
    case 2:
      switch (role)
      {
        case Qt::DisplayRole:
          return mDisplayUnit;
        default:
          return QVariant();
      }
    case 3:
      switch (role)
      {
        case Qt::DisplayRole:
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

VariablesTreeItem* VariablesTreeItem::parent()
{
  return mpParentVariablesTreeItem;
}

VariablesTreeModel::VariablesTreeModel(VariablesTreeView *pVariablesTreeView)
  : QAbstractItemModel(pVariablesTreeView)
{
  mpVariablesTreeView = pVariablesTreeView;
  QVector<QVariant> headers;
  headers << "" << "" << "Variables" << Helper::variables << tr("Value") << tr("Unit") << Helper::description << "";
  mpRootVariablesTreeItem = new VariablesTreeItem(headers, 0, true);
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

bool VariablesTreeModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (!pVariablesTreeItem)
    return false;
  bool result = pVariablesTreeItem->setData(index.column(), value, role);
  if (index.column() == 0 && role == Qt::CheckStateRole)
  {
    if (!signalsBlocked())
    {
      CurveStylePage *pCurveStylePage = mpVariablesTreeView->getVariablesWidget()->getMainWindow()->getOptionsDialog()->getCurveStylePage();
      emit itemChecked(index, pCurveStylePage->getCurveThickness(), pCurveStylePage->getCurvePattern());
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
  if (!index.isValid())
      return 0;

  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  Qt::ItemFlags flags = Qt::ItemIsEnabled | Qt::ItemIsSelectable;
  if (index.column() == 0 && pVariablesTreeItem && pVariablesTreeItem->getChildren().size() == 0)
    flags |= Qt::ItemIsUserCheckable;
  else if (index.column() == 1 && pVariablesTreeItem && pVariablesTreeItem->getChildren().size() == 0 && pVariablesTreeItem->isEditable())
    flags |= Qt::ItemIsEditable;

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

void VariablesTreeModel::parseInitXml(QXmlStreamReader &xmlReader)
{
  mScalarVariablesList.clear();
  /* We'll parse the XML until we reach end of it.*/
  while(!xmlReader.atEnd() && !xmlReader.hasError())
  {
    /* Read next element.*/
    QXmlStreamReader::TokenType token = xmlReader.readNext();
    /* If token is just StartDocument, we'll go to next.*/
    if(token == QXmlStreamReader::StartDocument)
      continue;
    /* If token is StartElement, we'll see if we can read it.*/
    if(token == QXmlStreamReader::StartElement)
    {
      /* If it's named ScalarVariable, we'll dig the information from there.*/
      if(xmlReader.name() == "ScalarVariable")
      {
        QHash<QString, QString> scalarVariable = parseScalarVariable(xmlReader);
        mScalarVariablesList.insert(scalarVariable.value("name"),scalarVariable);
      }
    }
  }
  xmlReader.clear();
}

QHash<QString, QString> VariablesTreeModel::parseScalarVariable(QXmlStreamReader &xmlReader)
{
  QHash<QString, QString> scalarVariable;
  /* Let's check that we're really getting a ScalarVariable. */
  if(xmlReader.tokenType() != QXmlStreamReader::StartElement && xmlReader.name() == "ScalarVariable")
    return scalarVariable;
  /* Let's get the attributes for ScalarVariable */
  QXmlStreamAttributes attributes = xmlReader.attributes();
  /* Read the ScalarVariable attributes. */
  scalarVariable["name"] = attributes.value("name").toString();
  scalarVariable["description"] = attributes.value("description").toString();
  scalarVariable["isValueChangeable"] = attributes.value("isValueChangeable").toString();
  /* Read the next element i.e Real, Integer, Boolean etc. */
  xmlReader.readNext();
  while(!(xmlReader.tokenType() == QXmlStreamReader::EndElement && xmlReader.name() == "ScalarVariable"))
  {
    if(xmlReader.tokenType() == QXmlStreamReader::StartElement)
    {
      QXmlStreamAttributes attributes = xmlReader.attributes();
      scalarVariable["start"] = attributes.value("start").toString();
      scalarVariable["displayUnit"] = attributes.value("displayUnit").toString();
    }
    xmlReader.readNext();
  }
  return scalarVariable;
}

void VariablesTreeModel::insertVariablesItems(QString fileName, QString filePath, QStringList variablesList,
                                              SimulationOptions simulationOptions)
{
  QString toolTip = tr("Simulation Result File: %1\n%2: %3/%4").arg(fileName).arg(Helper::fileLocation).arg(filePath).arg(fileName);
  QRegExp resultTypeRegExp("(_res.mat|_res.plt|_res.csv)");
  QString text = QString(fileName).remove(resultTypeRegExp);
  QModelIndex index = variablesTreeItemIndex(mpRootVariablesTreeItem);
  QVector<QVariant> Variabledata;
  Variabledata << filePath << fileName << fileName << text << "" << "" << "" << toolTip;
  VariablesTreeItem *pTopVariablesTreeItem = new VariablesTreeItem(Variabledata, mpRootVariablesTreeItem, true);
  pTopVariablesTreeItem->setSimulationOptions(simulationOptions);
  int row = rowCount();
  beginInsertRows(index, row, row);
  mpRootVariablesTreeItem->insertChild(row, pTopVariablesTreeItem);
  endInsertRows();
  /* open the model_init.xml file for reading */
  QString initFileName = QString(fileName).replace(resultTypeRegExp, "_init.xml");
  QFile initFile(QString(filePath).append(QDir::separator()).append(initFileName));
  if (initFile.open(QIODevice::ReadOnly))
  {
    QXmlStreamReader initXmlReader(&initFile);
    parseInitXml(initXmlReader);
    initFile.close();
  }
  else
  {
    MessagesWidget *pMessagesWidget = mpVariablesTreeView->getVariablesWidget()->getMainWindow()->getMessagesWidget();
    pMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0,
                                                        GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(initFile.fileName()),
                                                        Helper::scriptingKind, Helper::errorLevel, 0, pMessagesWidget->getMessagesTreeWidget()));
  }
  /* open the .mat file */
  ModelicaMatReader matReader;
  matReader.fileName = "";
  const char *msg[] = {""};
  if (fileName.endsWith(".mat"))
  {
    //Read in mat file
    if (0 != (msg[0] = omc_new_matlab4_reader(QString(filePath + "/" + fileName).toStdString().c_str(), &matReader)))
    {
      MessagesWidget *pMessagesWidget = mpVariablesTreeView->getVariablesWidget()->getMainWindow()->getMessagesWidget();
      pMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(fileName)
                                                          .arg(QString(msg[0])), Helper::scriptingKind, Helper::errorLevel, 0,
                                                          pMessagesWidget->getMessagesTreeWidget()));
    }
  }
  QStringList variables;
  foreach (QString plotVariable, variablesList)
  {
    QString parentVariable;
    if (plotVariable.startsWith("der("))
    {
      QString str = plotVariable;
      str.chop((str.lastIndexOf("der(")/4)+1);
      variables = makeVariableParts(str.mid(str.lastIndexOf("der(") + 4));
    }
    else
    {
      variables = makeVariableParts(plotVariable);
    }
    int count = 1;
    foreach (QString variable, variables)
    {
      QString findVariable = parentVariable.isEmpty() ? fileName + "." + variable : fileName + "." + parentVariable + "." + variable;
      if (findVariablesTreeItem(findVariable, mpRootVariablesTreeItem))
      {
        if (count == 1)
          parentVariable = variable;
        else
          parentVariable += "." + variable;
        count++;
        continue;
      }
      VariablesTreeItem *pParentVariablesTreeItem = findVariablesTreeItem(fileName + "." + parentVariable, mpRootVariablesTreeItem);
      if (!pParentVariablesTreeItem)
      {
        pParentVariablesTreeItem = pTopVariablesTreeItem;
      }
      QModelIndex index = variablesTreeItemIndex(pParentVariablesTreeItem);
      QVector<QVariant> variableData;
      /* if last item */
      if (variables.size() == count && plotVariable.startsWith("der("))
        variableData << filePath << fileName << fileName + "." + plotVariable << "der(" + variable + ")";
      else
        variableData << filePath << fileName << pParentVariablesTreeItem->getVariableName() + "." + variable << variable;
      /* find the variable in the xml file */
      QString variableToFind = variableData[2].toString();
      variableToFind.remove(QRegExp(pTopVariablesTreeItem->getVariableName() + "."));
      /* get the variable information i.e value, displayunit, description */
      QString value, displayUnit, description;
      bool changeAble = false;
      getVariableInformation(&matReader, variableToFind, &value, &changeAble, &displayUnit, &description);
      variableData << StringHandler::unparse(QString("\"").append(value).append("\""));
      /* set the variable displayUnit */
      variableData << StringHandler::unparse(QString("\"").append(displayUnit).append("\""));
      /* set the variable description */
      variableData << StringHandler::unparse(QString("\"").append(description).append("\""));
      /* construct tooltip text */
      variableData << tr("File: %1/%2\nVariable: %3").arg(filePath).arg(fileName).arg(variableToFind);
      VariablesTreeItem *pVariablesTreeItem = new VariablesTreeItem(variableData, pParentVariablesTreeItem);
      pVariablesTreeItem->setEditable(changeAble);
      int row = rowCount(index);
      beginInsertRows(index, row, row);
      pParentVariablesTreeItem->insertChild(row, pVariablesTreeItem);
      endInsertRows();
      if (count == 1)
        parentVariable = variable;
      else
        parentVariable += "." + variable;
      count++;
    }
  }
  /* close the .mat file */
  if (fileName.endsWith(".mat"))
  {
    if (matReader.file)
      omc_free_matlab4_reader(&matReader);
  }
  mpVariablesTreeView->collapseAll();
  QModelIndex idx = variablesTreeItemIndex(pTopVariablesTreeItem);
  idx = mpVariablesTreeView->getVariablesWidget()->getVariableTreeProxyModel()->mapFromSource(idx);
  mpVariablesTreeView->expand(idx);
}

QStringList VariablesTreeModel::makeVariableParts(QString variable)
{
  QStringList variables = variable.split(QRegExp("\\.(?![^\\[\\]]*\\])"), QString::SkipEmptyParts);
  return variables;
}

bool VariablesTreeModel::removeVariableTreeItem(QString variable)
{
  VariablesTreeItem *pVariablesTreeItem = findVariablesTreeItem(variable, mpRootVariablesTreeItem);
  if (pVariablesTreeItem)
  {
    beginRemoveRows(variablesTreeItemIndex(pVariablesTreeItem), 0, pVariablesTreeItem->getChildren().size());
    pVariablesTreeItem->removeChildren();
    VariablesTreeItem *pParentVariablesTreeItem = pVariablesTreeItem->parent();
    pParentVariablesTreeItem->removeChild(pVariablesTreeItem);
    delete pVariablesTreeItem;
    endRemoveRows();
    return true;
  }
  return false;
}

void VariablesTreeModel::unCheckVariables(VariablesTreeItem *pVariablesTreeItem)
{
  QList<VariablesTreeItem*> items = pVariablesTreeItem->getChildren();
  for (int i = 0 ; i < items.size() ; i++)
  {
    items[i]->setData(0, Qt::Unchecked, Qt::CheckStateRole);
    unCheckVariables(items[i]);
  }
}

void VariablesTreeModel::getVariableInformation(ModelicaMatReader *pMatReader, QString variableToFind, QString *value, bool *changeAble,
                                                QString *displayUnit, QString *description)
{
  QHash<QString, QString> hash = mScalarVariablesList.value(variableToFind);
  if (hash["name"].compare(variableToFind) == 0)
  {
    *changeAble = (hash["isValueChangeable"].compare("true") == 0) ? true : false;
    if (*changeAble)
    {
      *value = hash["start"];
    }
    /* if the variable is not a tunable parameter then read the final value of the variable. Only mat result files are supported. */
    else
    {
      if (pMatReader->file && pMatReader->fileName != "")
      {
        *value = "";
        if (variableToFind.compare("time") == 0)
        {
          *value = QString::number(omc_matlab4_stopTime(pMatReader));
        }
        else
        {
          ModelicaMatVariable_t *var;
          if (0 == (var = omc_matlab4_find_var(pMatReader, variableToFind.toStdString().c_str())))
          {
            qDebug() << QString("%1 not found in %2").arg(variableToFind).arg(pMatReader->fileName);
          }
          double res;
          if (var && !omc_matlab4_val(&res, pMatReader, var, omc_matlab4_stopTime(pMatReader)))
          {
            *value = QString::number(res);
          }
        }
      }
    }
    *displayUnit = hash["displayUnit"];
    *description = hash["description"];
  }
  else if ((variableToFind.compare("time") == 0) && pMatReader->file && pMatReader->fileName != "")
  {
    *value = QString::number(omc_matlab4_stopTime(pMatReader));
  }
}

void VariablesTreeModel::removeVariableTreeItem()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction)
  {
    removeVariableTreeItem(pAction->data().toString());
    emit variableTreeItemRemoved(pAction->data().toString());
  }
}

VariableTreeProxyModel::VariableTreeProxyModel(QObject *parent)
  : QSortFilterProxyModel(parent)
{
}

bool VariableTreeProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
  if (!filterRegExp().isEmpty())
  {
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    if (index.isValid())
    {
      // if any of children matches the filter, then current index matches the filter as well
      int rows = sourceModel()->rowCount(index);
      for (int i = 0 ; i < rows ; ++i)
      {
        if (filterAcceptsRow(i, index))
        {
          return true;
        }
      }
      // check current index itself
      VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
      if (pVariablesTreeItem)
      {
        QString variableName = pVariablesTreeItem->getVariableName();
        variableName.remove(QRegExp("(_res.mat|_res.plt|_res.csv)"));
        return variableName.contains(filterRegExp());
      }
      else
      {
        return sourceModel()->data(index).toString().contains(filterRegExp());
      }
      QString key = sourceModel()->data(index, filterRole()).toString();
      return key.contains(filterRegExp());
    }
  }
  return QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
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
}

/*!
  Reimplementation of QTreeView::mouseReleaseEvent\n
  Checks if user clicks on the first column then check/uncheck the corresponsing checkbox of the column.\n
  Otherwise calls the QTreeView::mouseReleaseEvent
  */
void VariablesTreeView::mouseReleaseEvent(QMouseEvent *event)
{
  QModelIndex index = indexAt(event->pos());
  if (index.isValid() &&
      index.column() == 0 &&
      index.parent().isValid() &&
      index.flags() & Qt::ItemIsUserCheckable &&
      event->button() == Qt::LeftButton)
  {
    if (visualRect(index).contains(event->pos()))
    {
      index = mpVariablesWidget->getVariableTreeProxyModel()->mapToSource(index);
      VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
      if (pVariablesTreeItem && pVariablesTreeItem)
      {
        if (pVariablesTreeItem->isChecked())
          mpVariablesWidget->getVariablesTreeModel()->setData(index, Qt::Unchecked, Qt::CheckStateRole);
        else
          mpVariablesWidget->getVariablesTreeModel()->setData(index, Qt::Checked, Qt::CheckStateRole);
      }
      return;
    }
  }
  QTreeView::mouseReleaseEvent(event);
}

VariablesWidget::VariablesWidget(MainWindow *pMainWindow)
  : QWidget(pMainWindow)
{
  setMinimumWidth(175);
  mpMainWindow = pMainWindow;
  // create the find text box
  mpFindVariablesTextBox = new QLineEdit(Helper::findVariables);
  mpFindVariablesTextBox->installEventFilter(this);
  connect(mpFindVariablesTextBox, SIGNAL(returnPressed()), SLOT(findVariables()));
  connect(mpFindVariablesTextBox, SIGNAL(textEdited(QString)), SLOT(findVariables()));
  // create the case sensitivity checkbox
  mpFindCaseSensitiveCheckBox = new QCheckBox(tr("Case Sensitive"));
  connect(mpFindCaseSensitiveCheckBox, SIGNAL(toggled(bool)), SLOT(findVariables()));
  // create the find syntax combobox
  mpFindSyntaxComboBox = new QComboBox;
  mpFindSyntaxComboBox->addItem(tr("Regular Expression"), QRegExp::RegExp);
  mpFindSyntaxComboBox->setItemData(0, tr("A rich Perl-like pattern matching syntax."), Qt::ToolTipRole);
  mpFindSyntaxComboBox->addItem(tr("Wildcard"), QRegExp::Wildcard);
  mpFindSyntaxComboBox->setItemData(1, tr("A simple pattern matching syntax similar to that used by shells (command interpreters) for \"file globbing\"."), Qt::ToolTipRole);
  mpFindSyntaxComboBox->addItem(tr("Fixed String"), QRegExp::FixedString);
  mpFindSyntaxComboBox->setItemData(2, tr("Fixed string matching."), Qt::ToolTipRole);
  connect(mpFindSyntaxComboBox, SIGNAL(currentIndexChanged(int)), SLOT(findVariables()));
  // expand all button
  mpExpandAllButton = new QPushButton(tr("Expand All"));
  // collapse all button
  mpCollapseAllButton = new QPushButton(tr("Collapse All"));
  // create variables tree widget
  mpVariablesTreeView = new VariablesTreeView(this);
  mpVariablesTreeModel = new VariablesTreeModel(mpVariablesTreeView);
  mpVariableTreeProxyModel = new VariableTreeProxyModel;
  mpVariableTreeProxyModel->setDynamicSortFilter(true);
  mpVariableTreeProxyModel->setSourceModel(mpVariablesTreeModel);
  mpVariablesTreeView->setModel(mpVariableTreeProxyModel);
  mpVariablesTreeView->setColumnWidth(0, 150);
  mpVariablesTreeView->setColumnWidth(2, 50);
  mpLastActiveSubWindow = 0;
  // create the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpFindVariablesTextBox, 0, 0, 1, 2);
  pMainLayout->addWidget(mpFindCaseSensitiveCheckBox, 1, 0);
  pMainLayout->addWidget(mpFindSyntaxComboBox, 1, 1);
  pMainLayout->addWidget(mpExpandAllButton, 2, 0);
  pMainLayout->addWidget(mpCollapseAllButton, 2, 1);
  pMainLayout->addWidget(mpVariablesTreeView, 3, 0, 1, 2);
  setLayout(pMainLayout);
  connect(mpExpandAllButton, SIGNAL(clicked()), mpVariablesTreeView, SLOT(expandAll()));
  connect(mpCollapseAllButton, SIGNAL(clicked()), mpVariablesTreeView, SLOT(collapseAll()));
  connect(mpVariablesTreeModel, SIGNAL(rowsInserted(QModelIndex,int,int)), mpVariableTreeProxyModel, SLOT(invalidate()));
  connect(mpVariablesTreeModel, SIGNAL(rowsRemoved(QModelIndex,int,int)), mpVariableTreeProxyModel, SLOT(invalidate()));
  connect(mpVariablesTreeModel, SIGNAL(itemChecked(QModelIndex,qreal,int)), SLOT(plotVariables(QModelIndex,qreal,int)));
  connect(mpVariablesTreeView, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  connect(pMainWindow->getPlotWindowContainer(), SIGNAL(subWindowActivated(QMdiSubWindow*)), this, SLOT(updateVariablesTree(QMdiSubWindow*)));
  connect(mpVariablesTreeModel, SIGNAL(variableTreeItemRemoved(QString)), pMainWindow->getPlotWindowContainer(), SLOT(updatePlotWindows(QString)));
}

void VariablesWidget::insertVariablesItemsToTree(QString fileName, QString filePath, QStringList variablesList,
                                                 SimulationOptions simulationOptions)
{
  mpVariablesTreeView->setSortingEnabled(false);
  /* Remove the simulation result if we already had it in tree */
  bool variableItemDeleted = mpVariablesTreeModel->removeVariableTreeItem(fileName);
  /* add the plot variables */
  mpVariablesTreeModel->insertVariablesItems(fileName, filePath, variablesList, simulationOptions);
  /* update the plot variables tree */
  if (variableItemDeleted)
    variablesUpdated();
  mpVariablesTreeView->setSortingEnabled(true);
  mpVariablesTreeView->sortByColumn(0, Qt::AscendingOrder);
}

void VariablesWidget::variablesUpdated()
{
  foreach (QMdiSubWindow *pSubWindow, mpMainWindow->getPlotWindowContainer()->subWindowList(QMdiArea::StackingOrder))
  {
    PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
    foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
    {
      if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
      {
        QString curveNameStructure = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text());
        VariablesTreeItem *pVariableTreeItem;
        pVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(curveNameStructure, mpVariablesTreeModel->getRootVariablesTreeItem());
        pPlotWindow->getPlot()->removeCurve(pPlotCurve);
        pPlotCurve->detach();
        pPlotWindow->fitInView();
        pPlotWindow->getPlot()->updateLayout();
        if (pVariableTreeItem)
        {
          bool state = mpVariablesTreeModel->blockSignals(true);
          QModelIndex index = mpVariablesTreeModel->variablesTreeItemIndex(pVariableTreeItem);
          mpVariablesTreeModel->setData(index, Qt::Checked, Qt::CheckStateRole);
          plotVariables(index, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), pPlotWindow);
          mpVariablesTreeModel->blockSignals(state);
        }
      }
      else if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC)
      {
        QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
        VariablesTreeItem *pXVariableTreeItem;
        pXVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(xVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
        QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
        VariablesTreeItem *pYVariableTreeItem;
        pYVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(yVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
        if (pXVariableTreeItem && pYVariableTreeItem)
        {
          bool state = mpVariablesTreeModel->blockSignals(true);
          QModelIndex xIndex = mpVariablesTreeModel->variablesTreeItemIndex(pXVariableTreeItem);
          mpVariablesTreeModel->setData(xIndex, Qt::Checked, Qt::CheckStateRole);
          plotVariables(xIndex, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), pPlotWindow);
          QModelIndex yIndex = mpVariablesTreeModel->variablesTreeItemIndex(pYVariableTreeItem);
          mpVariablesTreeModel->setData(yIndex, Qt::Checked, Qt::CheckStateRole);
          plotVariables(yIndex, pPlotCurve->getCurveWidth(), pPlotCurve->getCurveStyle(), pPlotWindow);
          mpVariablesTreeModel->blockSignals(state);
        }
        else
        {
          pPlotWindow->getPlot()->removeCurve(pPlotCurve);
          pPlotCurve->detach();
          pPlotWindow->fitInView();
          pPlotWindow->getPlot()->updateLayout();
        }
      }
    }
  }
  updateVariablesTreeHelper(mpMainWindow->getPlotWindowContainer()->currentSubWindow());
}

void VariablesWidget::updateVariablesTreeHelper(QMdiSubWindow *pSubWindow)
{
  if (!pSubWindow)
    return;
  // first clear all the check boxes in the tree
  bool state = mpVariablesTreeModel->blockSignals(true);
  mpVariablesTreeModel->unCheckVariables(mpVariablesTreeModel->getRootVariablesTreeItem());
  mpVariablesTreeModel->blockSignals(state);
  // all plotwindows are closed down then simply return
  if (mpMainWindow->getPlotWindowContainer()->subWindowList().size() == 0)
    return;

  PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
  // now loop through the curves and tick variables in the tree whose curves are on the plot
  state = mpVariablesTreeModel->blockSignals(true);
  foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
  {
    VariablesTreeItem *pVariablesTreeItem;
    if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
    {
      QString variable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text());
      pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(variable, mpVariablesTreeModel->getRootVariablesTreeItem());
      if (pVariablesTreeItem)
        mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Checked, Qt::CheckStateRole);
    }
    else if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC)
    {
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
    }
  }
  mpVariablesTreeModel->blockSignals(state);
  /* invalidate the view so that the items show the updated values. */
  mpVariableTreeProxyModel->invalidate();
}

bool VariablesWidget::eventFilter(QObject *pObject, QEvent *pEvent)
{
  if (pObject != mpFindVariablesTextBox)
    return false;
  if (pEvent->type() == QEvent::FocusIn)
  {
    if (mpFindVariablesTextBox->text().compare(Helper::findVariables) == 0)
      mpFindVariablesTextBox->setText("");
  }
  if (pEvent->type() == QEvent::FocusOut)
  {
    if (mpFindVariablesTextBox->text().isEmpty())
      mpFindVariablesTextBox->setText(Helper::findVariables);
  }
  return false;
}

void VariablesWidget::readVariablesAndUpdateXML(VariablesTreeItem *pVariablesTreeItem, QString outputFileName,
                                                QHash<QString, QHash<QString, QString> > *variables)
{
  for (int i = 0 ; i < pVariablesTreeItem->getChildren().size() ; i++)
  {
    VariablesTreeItem *pChildVariablesTreeItem = pVariablesTreeItem->child(i);
    if (pChildVariablesTreeItem->isEditable() && pChildVariablesTreeItem->isValueChanged())
    {
      QString value = pChildVariablesTreeItem->data(1, Qt::DisplayRole).toString();
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

void VariablesWidget::findVariableAndUpdateValue(QDomDocument xmlDocument, QHash<QString, QHash<QString, QString> > variables)
{
  /* if no variables are changed. */
  if (variables.empty())
    return;
  /* update the variables */
  int count = 0;
  QDomNodeList scalarVariable = xmlDocument.elementsByTagName("ScalarVariable");
  for (int i = 0; i < scalarVariable.size(); i++)
  {
    if (count >= variables.size())
      break;
    QDomElement element = scalarVariable.at(i).toElement();
    if (!element.isNull())
    {
      QHash<QString, QString> hash = variables.value(element.attribute("name"));
      if (element.attribute("name").compare(hash["name"]) == 0)
      {
        count++;
        QDomElement el = scalarVariable.at(i).firstChild().toElement();
        if (!el.isNull())
        {
          el.setAttribute("start", hash["value"]);
        }
      }
    }
  }
}

void VariablesWidget::plotVariables(const QModelIndex &index, qreal curveThickness, int curveStyle, PlotWindow *pPlotWindow)
{
  if (index.column() > 0)
    return;
  VariablesTreeItem *pVariablesTreeItem = static_cast<VariablesTreeItem*>(index.internalPointer());
  if (!pVariablesTreeItem)
    return;
  try
  {
    // if pPlotWindow is 0 then get the current window.
    if (!pPlotWindow)
      pPlotWindow = mpMainWindow->getPlotWindowContainer()->getCurrentWindow();
    // if pPlotWindow is 0 then create a new plot window.
    if (!pPlotWindow)
    {
      bool state = mpMainWindow->getPlotWindowContainer()->blockSignals(true);
      mpMainWindow->getPlotWindowContainer()->addPlotWindow();
      mpMainWindow->getPlotWindowContainer()->blockSignals(state);
      pPlotWindow = mpMainWindow->getPlotWindowContainer()->getCurrentWindow();
    }
    // if still pPlotWindow is 0 then return.
    if (!pPlotWindow)
    {
      bool state = mpVariablesTreeModel->blockSignals(true);
      mpVariablesTreeModel->setData(index, Qt::Unchecked, Qt::CheckStateRole);
      mpVariablesTreeModel->blockSignals(state);
      QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               tr("No plot window is active for plotting. Please select a plot window or open a new."), Helper::ok);
      return;
    }
    // if plottype is PLOT then
    if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
    {
      // check the item checkstate
      if (pVariablesTreeItem->isChecked())
      {
        pPlotWindow->initializeFile(QString(pVariablesTreeItem->getFilePath()).append("/").append(pVariablesTreeItem->getFileName()));
        pPlotWindow->setCurveWidth(curveThickness);
        pPlotWindow->setCurveStyle(curveStyle);
        pPlotWindow->setVariablesList(QStringList(pVariablesTreeItem->getPlotVariable()));
        pPlotWindow->plot();
        pPlotWindow->fitInView();
        pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
        pPlotWindow->getPlot()->updateLayout();
      }
      // if user unchecks the variable then remove it from the plot
      else if (!pVariablesTreeItem->isChecked())
      {
        foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
        {
          QString curveTitle = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text());
          if (curveTitle.compare(pVariablesTreeItem->getVariableName()) == 0)
          {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
            pPlotWindow->fitInView();
            pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
            pPlotWindow->getPlot()->updateLayout();
          }
        }
      }
    }
    // if plottype is PLOTPARAMETRIC then
    else
    {
      // check the item checkstate
      if (pVariablesTreeItem->isChecked())
      {
        // if mPlotParametricVariables is empty just add one QStringlist with 1 varibale to it
        if (mPlotParametricVariables.isEmpty())
        {
          mPlotParametricVariables.append(QStringList(pVariablesTreeItem->getPlotVariable()));
          mFileName = pVariablesTreeItem->getFileName();
        }
        // if mPlotParametricVariables is not empty then add one string to its last element
        else
        {
          if (mPlotParametricVariables.last().size() < 2)
          {
            if (mFileName.compare(pVariablesTreeItem->getFileName()) != 0)
            {
              bool state = mpVariablesTreeModel->blockSignals(true);
              mpVariablesTreeModel->setData(index, Qt::Unchecked, Qt::CheckStateRole);
              QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                                    GUIMessages::getMessage(GUIMessages::PLOT_PARAMETRIC_DIFF_FILES), Helper::ok);
              mpVariablesTreeModel->blockSignals(state);
              return;
            }
            mPlotParametricVariables.last().append(QStringList(pVariablesTreeItem->getPlotVariable()));
            pPlotWindow->initializeFile(QString(pVariablesTreeItem->getFilePath()).append("/").append(pVariablesTreeItem->getFileName()));
            pPlotWindow->setCurveWidth(curveThickness);
            pPlotWindow->setCurveStyle(curveStyle);
            pPlotWindow->setVariablesList(mPlotParametricVariables.last());
            pPlotWindow->plotParametric();
            if (mPlotParametricVariables.size() > 1)
            {
              pPlotWindow->setXLabel("");
              pPlotWindow->setYLabel("");
            }
            pPlotWindow->fitInView();
            pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
            pPlotWindow->getPlot()->updateLayout();
          }
          else
          {
            mPlotParametricVariables.append(QStringList(pVariablesTreeItem->getPlotVariable()));
            mFileName = pVariablesTreeItem->getFileName();
          }
        }
      }
      // if user unchecks the variable then remove it from the plot
      else if (!pVariablesTreeItem->isChecked())
      {
        // remove the variable from mPlotParametricVariables list
        foreach (QStringList list, mPlotParametricVariables)
        {
          if (list.contains(pVariablesTreeItem->getPlotVariable()))
          {
            // if list has only one variable then clear the list and return;
            if (list.size() < 2)
            {
              mPlotParametricVariables.removeOne(list);
              break;
            }
            // if list has more than two variables then remove both and remove the curve
            else
            {
              QString itemTitle = QString(list.last()).append("(").append(list.first()).append(")");
              foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
              {
                QString curveTitle = pPlotCurve->title().text();
                if ((curveTitle.compare(itemTitle) == 0) && (pVariablesTreeItem->getFileName().compare(pPlotCurve->getFileName()) == 0))
                {
                  bool state = mpVariablesTreeModel->blockSignals(true);
                  // uncheck the x variable
                  QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
                  VariablesTreeItem *pVariablesTreeItem;
                  pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(xVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
                  if (pVariablesTreeItem)
                    mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Unchecked, Qt::CheckStateRole);
                  // uncheck the y variable
                  QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
                  pVariablesTreeItem = mpVariablesTreeModel->findVariablesTreeItem(yVariable, mpVariablesTreeModel->getRootVariablesTreeItem());
                  if (pVariablesTreeItem)
                    mpVariablesTreeModel->setData(mpVariablesTreeModel->variablesTreeItemIndex(pVariablesTreeItem), Qt::Unchecked, Qt::CheckStateRole);
                  mpVariablesTreeModel->blockSignals(state);
                  pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                  pPlotCurve->detach();
                  pPlotWindow->fitInView();
                  pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
                  pPlotWindow->getPlot()->updateLayout();
                }
              }
              mPlotParametricVariables.removeOne(list);
              if (mPlotParametricVariables.size() == 1)
              {
                if (mPlotParametricVariables.last().size() > 1)
                {
                  pPlotWindow->setXLabel(mPlotParametricVariables.last().at(0));
                  pPlotWindow->setYLabel(mPlotParametricVariables.last().at(1));
                }
                else
                {
                  pPlotWindow->setXLabel("");
                  pPlotWindow->setYLabel("");
                }
              }
              else
              {
                pPlotWindow->setXLabel("");
                pPlotWindow->setYLabel("");
              }
            }
          }
        }
      }
    }
  }
  catch (PlotException &e)
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), Helper::ok);
  }
}

void VariablesWidget::updateVariablesTree(QMdiSubWindow *pSubWindow)
{
  if (!pSubWindow && mpMainWindow->getPlotWindowContainer()->subWindowList().size() != 0)
    return;
  /* if the same sub window is activated again then just return */
  if (mpLastActiveSubWindow == pSubWindow)
  {
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
    QAction *pDeleteResultAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Delete Result"), this);
    pDeleteResultAction->setData(pVariablesTreeItem->getVariableName());
    pDeleteResultAction->setStatusTip(tr("Delete the result"));
    connect(pDeleteResultAction, SIGNAL(triggered()), mpVariablesTreeModel, SLOT(removeVariableTreeItem()));
    /* re-simulate action */
    QAction *pReSimulateAction = new QAction(QIcon(":/Resources/icons/simulate.png"), tr("Re-simulate"), this);
    pReSimulateAction->setData(pVariablesTreeItem->getSimulationOptions());
    pReSimulateAction->setStatusTip(Helper::simulateTip);
    pReSimulateAction->setEnabled(pVariablesTreeItem->getSimulationOptions().isValid());
    connect(pReSimulateAction, SIGNAL(triggered()), this, SLOT(reSimulate()));
    QMenu menu(this);
    menu.addAction(pDeleteResultAction);
    menu.addAction(pReSimulateAction);
    point.setY(point.y() + adjust);
    menu.exec(mpVariablesTreeView->mapToGlobal(point));
  }
}

void VariablesWidget::findVariables()
{
  QString findText = mpFindVariablesTextBox->text();
  if (mpFindVariablesTextBox->text().isEmpty() || (mpFindVariablesTextBox->text().compare(Helper::findVariables) == 0))
  {
    findText = "";
  }
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpFindSyntaxComboBox->itemData(mpFindSyntaxComboBox->currentIndex()).toInt());
  Qt::CaseSensitivity caseSensitivity = mpFindCaseSensitiveCheckBox->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
  QRegExp regExp(findText, caseSensitivity, syntax);
  mpVariableTreeProxyModel->setFilterRegExp(regExp);
  /* expand all so that the filtered items can be seen. */
  if (!findText.isEmpty())
    mpVariablesTreeView->expandAll();
}

void VariablesWidget::reSimulate()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction)
  {
    SimulationOptions simulationOptions = pAction->data().value<SimulationOptions>();
    simulationOptions.setReSimuate(true);
    /* Update the _init.xml file with new values. */
    QRegExp resultTypeRegExp("(_res.mat|_res.plt|_res.csv)");
    /* open the model_init.xml file for writing */
    QString initFileName = QString(simulationOptions.getOutputFileName()).replace(resultTypeRegExp, "_init.xml");
    QFile initFile(QString(simulationOptions.getWorkingDirectory()).append(QDir::separator()).append(initFileName));
    QDomDocument initXmlDocument;
    if (initFile.open(QIODevice::ReadOnly))
    {
      if (initXmlDocument.setContent(&initFile))
      {
        VariablesTreeItem *pTopVariableTreeItem;
        pTopVariableTreeItem = mpVariablesTreeModel->findVariablesTreeItem(simulationOptions.getOutputFileName(),
                                                                           mpVariablesTreeModel->getRootVariablesTreeItem());
        if (pTopVariableTreeItem)
        {
          QHash<QString, QHash<QString, QString> > variables;
          readVariablesAndUpdateXML(pTopVariableTreeItem, simulationOptions.getOutputFileName(), &variables);
          findVariableAndUpdateValue(initXmlDocument, variables);
        }
      }
      else
      {
        MessagesWidget *pMessagesWidget = mpVariablesTreeView->getVariablesWidget()->getMainWindow()->getMessagesWidget();
        pMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0,
                                                            tr("Unable to set the content of QDomDocument from file %1")
                                                            .arg(initFile.fileName()), Helper::scriptingKind, Helper::errorLevel, 0,
                                                            pMessagesWidget->getMessagesTreeWidget()));
      }
      initFile.close();
      initFile.open(QIODevice::WriteOnly | QIODevice::Truncate);
      QTextStream textStream(&initFile);
      textStream << initXmlDocument.toString();
      initFile.close();
    }
    else
    {
      MessagesWidget *pMessagesWidget = mpVariablesTreeView->getVariablesWidget()->getMainWindow()->getMessagesWidget();
      pMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0,
                                                          GUIMessages::getMessage(GUIMessages::ERROR_OPENING_FILE).arg(initFile.fileName()),
                                                          Helper::scriptingKind, Helper::errorLevel, 0, pMessagesWidget->getMessagesTreeWidget()));
    }
    mpMainWindow->getSimulationDialog()->runSimulationExecutable(simulationOptions);
  }
}
