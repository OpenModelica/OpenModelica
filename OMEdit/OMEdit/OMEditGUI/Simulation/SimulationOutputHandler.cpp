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

#include "SimulationOutputHandler.h"

/*!
  \class SimulationMessageModel
  \brief Data model for Simulation output messages.
  */
/*!
  \param pSimulationOutputWidget - a pointer to SimulationOutputWidget.
  \param pParent - a pointer to QObject.
  */
SimulationMessageModel::SimulationMessageModel(SimulationOutputWidget *pSimulationOutputWidget, QObject *pParent)
  : QAbstractItemModel(pParent)
{
  mpSimulationOutputWidget = pSimulationOutputWidget;
  mpRootSimulationMessage = new SimulationMessage;
}

/*!
  Returns the index of the item in the model specified by the given row, column and parent index.
  */
QModelIndex SimulationMessageModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  SimulationMessage *pParentSimulationMessage = 0;
  if (!parent.isValid()) {
    pParentSimulationMessage = mpRootSimulationMessage;
  } else {
    pParentSimulationMessage = static_cast<SimulationMessage*>(parent.internalPointer());
  }
  SimulationMessage *pChildSimulationMessage = pParentSimulationMessage->child(row);
  if (pChildSimulationMessage) {
    return createIndex(row, column, pChildSimulationMessage);
  } else {
    return QModelIndex();
  }
}

/*!
  Returns the parent of the model item with the given index. If the item has no parent, an invalid QModelIndex is returned.
  */
QModelIndex SimulationMessageModel::parent(const QModelIndex &child) const
{
  if (!child.isValid()) {
    return QModelIndex();
  }

  SimulationMessage *pChildSimulationMessage = static_cast<SimulationMessage*>(child.internalPointer());
  SimulationMessage *pParentSimulationMessage = pChildSimulationMessage->parent();
  if (pParentSimulationMessage == mpRootSimulationMessage) {
    return QModelIndex();
  } else {
  return createIndex(pParentSimulationMessage->row(), 0, pParentSimulationMessage);
  }
}

/*!
  Returns the number of rows under the given parent.\n
  When the parent is valid it means that rowCount is returning the number of children of parent.
  */
int SimulationMessageModel::rowCount(const QModelIndex &parent) const
{
  SimulationMessage *pParentSimulationMessage;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentSimulationMessage = mpRootSimulationMessage;
  } else {
    pParentSimulationMessage = static_cast<SimulationMessage*>(parent.internalPointer());
  }
  return pParentSimulationMessage->children().size();
}

/*!
  Returns the number of columns of the model.
  */
int SimulationMessageModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 1;
}

/*!
  Returns the data stored under the given role for the item referred to by the index.
  */
QVariant SimulationMessageModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }

  SimulationMessage *pSimulationMessage = static_cast<SimulationMessage*>(index.internalPointer());
  QString debugLink;
  QString text;
  QString toolTip;
  QVariant variant = QVariant();
  if (pSimulationMessage) {
    // create debuglink
    SimulationOptions simulationOptions = mpSimulationOutputWidget->getSimulationOptions();
    debugLink = QString("&nbsp;<a href=\"omedittransformationsbrowser://%1?index=%2\">Debug more</a>")
        .arg(QUrl::fromLocalFile(simulationOptions.getWorkingDirectory() + "/" + simulationOptions.getOutputFileName() + "_info.json").path())
        .arg(pSimulationMessage->mIndex);
    // create display text
    text = pSimulationMessage->mText + (pSimulationMessage->mIndex.isEmpty() ? "" : debugLink);
    // create tooltip
    toolTip = QString("%1 | %2 | %3")
        .arg(pSimulationMessage->mStream)
        .arg(StringHandler::getSimulationMessageTypeString(pSimulationMessage->mType))
        .arg(pSimulationMessage->mText);
    switch (role)
    {
      case Qt::DisplayRole:
        variant = text;
        break;
      case Qt::ToolTipRole:
        variant = toolTip;
        break;
      case Qt::ForegroundRole:
        variant = StringHandler::getSimulationMessageTypeColor(pSimulationMessage->mType);
        break;
      case Qt::TextAlignmentRole:
        variant = QVariant(Qt::AlignLeft | Qt::AlignTop);
      default:
        break;
    }
  }
  return variant;
}

/*!
  Returns the depth/level of the QModelIndex.\n
  Needed by ItemDelegate to properly word wrap the top level and child items.
  */
int SimulationMessageModel::getDepth(const QModelIndex &index) const
{
  QModelIndex index1 = index;
  int depth = 1;
  while (index1.parent().isValid()) {
    index1 = index1.parent();
    SimulationMessage *pSimulationMessage = static_cast<SimulationMessage*>(index.internalPointer());
    if (pSimulationMessage == mpRootSimulationMessage) {
      break;
    }
    depth++;
  }
  return depth;
}

/*!
  Inserts the simulation message in the data.
  \param pSimulationMessage - the simulation message to insert.
  */
void SimulationMessageModel::insertSimulationMessage(SimulationMessage *pSimulationMessage)
{
  if (pSimulationMessage) {
    int row = mpRootSimulationMessage->children().size();
    beginInsertRows(QModelIndex(), row, row);
    mpRootSimulationMessage->insertChild(row, pSimulationMessage);
    endInsertRows();
  }
}

/*!
  Emits the QAbstractItemModel::layoutChanged which calls the ItemDelegate::sizeHint.\n
  This is needed for views which shows rich text using QTextDocument.\n
  The ItemDelegate then automatically word wraps the text and finds the optimal height for multiline items.
  */
void SimulationMessageModel::callLayoutChanged()
{
  emit layoutAboutToBeChanged();
  emit layoutChanged();
}

/*!
  Retuns the list of selected rows of the model.\n
  The rows are returned as they are displayed in the view without any ordering/sorting.\n
  Beats the QTreeView::selectionModel()::selectedRows() which returns the nested item rows first.
  */
QModelIndexList SimulationMessageModel::selectedRows()
{
  mSelectedRowsList.clear();
  selectedRowsHelper(mpRootSimulationMessage);
  return mSelectedRowsList;
}

/*!
  Finds the QModelIndex represented by the specified SimulationMessage.
  */
QModelIndex SimulationMessageModel::simulationMessageIndex(const SimulationMessage *pSimulationMessage) const
{
  return simulationMessageIndexHelper(pSimulationMessage, mpRootSimulationMessage, QModelIndex());
}

/*!
  Helper function for selectedRows.
  \param pParentSimulationMessage - a pointer to SimulationMessage.
  \sa selectedRows()
  */
void SimulationMessageModel::selectedRowsHelper(SimulationMessage *pParentSimulationMessage)
{
  foreach (SimulationMessage *pSimulationMessage, pParentSimulationMessage->children()) {
    QModelIndex index = simulationMessageIndex(pSimulationMessage);
    if (index.isValid()) {
      if (mpSimulationOutputWidget->getSimulationOutputTree()->selectionModel()->isSelected(index)) {
        mSelectedRowsList.append(index);
      }
      if (pSimulationMessage->children().size() > 0) {
        selectedRowsHelper(pSimulationMessage);
      }
    }
  }
}

/*!
  Helper function to find the QModelIndex.
  \sa simulationMessageIndex()
  */
QModelIndex SimulationMessageModel::simulationMessageIndexHelper(const SimulationMessage *pSimulationMessage,
                                                             const SimulationMessage *pParentSimulationMessage,
                                                             const QModelIndex &parentIndex) const
{
  if (pSimulationMessage == pParentSimulationMessage)
    return parentIndex;
  for (int i = pParentSimulationMessage->children().size(); --i >= 0; ) {
    const SimulationMessage *pChildSimulationMessage = pParentSimulationMessage->children().at(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = simulationMessageIndexHelper(pSimulationMessage, pChildSimulationMessage, childIndex);
    if (index.isValid())
      return index;
  }
  return QModelIndex();
}

/*!
  \class SimulationOutputHandler
  \brief Parses the xml output of simulation executable.
  */
/*
  <message stream="LOG_STATS" type="info" text="events">
    <message stream="LOG_STATS" type="info" text="    0 state events" />
    <message stream="LOG_STATS" type="info" text="    0 time events" />
  </message>
  <message stream="stdout" type="info" text="output text">
    <used index="2" />
  </message>
  */
/*!
  \param pSimulationOutputWidget - a pointer to SimulationOutputWidget.
  \param simulationOutput - the simulation output
  */
SimulationOutputHandler::SimulationOutputHandler(SimulationOutputWidget *pSimulationOutputWidget, QString simulationOutput)
{
  mpSimulationOutputWidget = pSimulationOutputWidget;
  mLevel = 0;
  mpSimulationMessage = 0;
  if (mpSimulationOutputWidget->isOutputStructured()) {
    mpSimulationMessageModel = new SimulationMessageModel(mpSimulationOutputWidget);
  } else {
    mpSimulationMessageModel = 0;
  }
  mXmlSimpleReader.setContentHandler(this);
  mXmlSimpleReader.setErrorHandler(this);
  mpXmlInputSource = new QXmlInputSource;
  mpXmlInputSource->setData(simulationOutput.prepend("<root>"));
  mXmlSimpleReader.parse(mpXmlInputSource, true);
}

SimulationOutputHandler::~SimulationOutputHandler()
{
  delete mpXmlInputSource;
}

/*!
  Sets the new simulation output data and continues the parsing.
  */
void SimulationOutputHandler::parseSimulationOutput(QString output)
{
  mpXmlInputSource->setData(output);
  mXmlSimpleReader.parseContinue();
}

/*!
  The reader calls this function when it has parsed a start element tag.
  */
bool SimulationOutputHandler::startElement(const QString &namespaceURI, const QString &localName, const QString &qName,
                                           const QXmlAttributes &atts)
{
  Q_UNUSED(namespaceURI);
  Q_UNUSED(localName);
  if (qName == "message") {
    if (mpSimulationOutputWidget->isOutputStructured()) {
      mpSimulationMessage = new SimulationMessage(mpSimulationMessageModel->getRootSimulationMessage());
    } else {
      mpSimulationMessage = new SimulationMessage;
    }
    mpSimulationMessage->mStream = atts.value("stream");
    mpSimulationMessage->mType = StringHandler::getSimulationMessageType(atts.value("type"));
    // check if we get the message about embedded opc-ua server initialized.
    if (atts.value("text").compare("The embedded server is initialized.") == 0) {
      mpSimulationOutputWidget->embeddedServerInitialized();
    }
    if (mpSimulationOutputWidget->isOutputStructured()) {
      mpSimulationMessage->mText = Qt::convertFromPlainText(atts.value("text"));
    } else {
      mpSimulationMessage->mText = atts.value("text");
    }
    mpSimulationMessage->mLevel = mLevel;
    mSimulationMessagesLevelMap.insert(mLevel, mpSimulationMessage);
    if (mLevel > 0) {
      SimulationMessage *pSimulationMessage = mSimulationMessagesLevelMap.value(mLevel - 1, 0);
      if (pSimulationMessage) {
        mpSimulationMessage->setParent(pSimulationMessage);
        pSimulationMessage->mChildren.append(mpSimulationMessage);
      }
    }
    mLevel++;
  } else if (qName == "used") {
    if (mpSimulationMessage) {
      mpSimulationMessage->mIndex = atts.value("index");
    }
  } else if (qName == "status") {
    int progress = atts.value("progress").toInt();
    mpSimulationOutputWidget->getProgressBar()->setValue(progress/100);
  }
  return true;
}

/*!
  The reader calls this function when it has parsed a end element tag.
  */
bool SimulationOutputHandler::endElement(const QString &namespaceURI, const QString &localName, const QString &qName)
{
  Q_UNUSED(namespaceURI);
  Q_UNUSED(localName);
  if (qName == "message") {
    mLevel--;
    // if mLevel is 0 then we have finished the one complete top level message tag. Add it to SimulationMessageModel now.
    if (mLevel == 0) {
      if (mpSimulationOutputWidget->isOutputStructured()) {
        mpSimulationMessageModel->insertSimulationMessage(mSimulationMessagesLevelMap.value(0, 0));
      } else {
        mpSimulationOutputWidget->writeSimulationMessage(mSimulationMessagesLevelMap.value(0, 0));
      }
    }
  }
  return true;
}

/*!
  Reports a non-recoverable error. Details of the error are stored in exception.
  */
bool SimulationOutputHandler::fatalError(const QXmlParseException &exception)
{
  // read the error message
  QString error = QString("Fatal error on line %1, column %2: %3")
      .arg(exception.lineNumber())
      .arg(exception.columnNumber())
      .arg(exception.message());
  // construct the SimulationMessage object with error
  SimulationMessage *pSimulationMessage;
  if (mpSimulationOutputWidget->isOutputStructured()) {
    pSimulationMessage = new SimulationMessage(mpSimulationMessageModel->getRootSimulationMessage());
  } else {
    pSimulationMessage = new SimulationMessage;
  }
  pSimulationMessage->mStream = "stderr";
  pSimulationMessage->mType = StringHandler::getSimulationMessageType("error");
  pSimulationMessage->mText = error;
  pSimulationMessage->mLevel = 0;
  if (mpSimulationOutputWidget->isOutputStructured()) {
    mpSimulationMessageModel->insertSimulationMessage(pSimulationMessage);
  } else {
    mpSimulationOutputWidget->writeSimulationMessage(pSimulationMessage);
  }
  return false;
}
