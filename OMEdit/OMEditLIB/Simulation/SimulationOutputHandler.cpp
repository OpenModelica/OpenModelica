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
#include "Options/OptionsDialog.h"

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
  mpRootSimulationMessage->mDeweyId = "1";
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
    if (pSimulationMessage->mText.compare(Helper::displayLimit) == 0) {
      QString simulationLogFilePath = QString("%1/%2.log").arg(mpSimulationOutputWidget->getSimulationOptions().getWorkingDirectory())
                                      .arg(mpSimulationOutputWidget->getSimulationOptions().getOutputFileName());
      text = Helper::displayLimitMsg.arg(simulationLogFilePath);
    } else {
      text = pSimulationMessage->mText + (pSimulationMessage->mIndex.isEmpty() ? "" : debugLink);
    }
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
        variant = OptionsDialog::instance()->getMessagesPage()->getColor(pSimulationMessage->mType);
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
    // check scroll position before adding the message
    auto pVerticalScrollBar = mpSimulationOutputWidget->getSimulationOutputTree()->verticalScrollBar();
    const bool atBottom = pVerticalScrollBar->value() == pVerticalScrollBar->maximum();
    int row = mpRootSimulationMessage->children().size();
    beginInsertRows(QModelIndex(), row, row);
    mpRootSimulationMessage->insertChild(row, pSimulationMessage);
    endInsertRows();
    // scroll to bottom
    if (atBottom) {
      mpSimulationOutputWidget->getSimulationOutputTree()->scrollToBottom();
    }
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
  Helper function to find the QModelIndex.
  \sa simulationMessageIndex()
  */
QModelIndex SimulationMessageModel::simulationMessageIndexHelper(const SimulationMessage *pSimulationMessage, const SimulationMessage *pParentSimulationMessage,
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
  <message stream="LOG_STDOUT" type="info" text="output text">
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
  mNumberOfBytes = 0;
  mShownDisplayLimitReachedMessage = false;
  mpSimulationMessage = 0;
  QString simulationLogFilePath = QString("%1/%2.log").arg(mpSimulationOutputWidget->getSimulationOptions().getWorkingDirectory())
                                  .arg(mpSimulationOutputWidget->getSimulationOptions().getOutputFileName());
#ifdef Q_OS_WIN
  mpSimulationLogFile = _wfopen((wchar_t*)simulationLogFilePath.utf16(), L"w");
#else
  mpSimulationLogFile = fopen(simulationLogFilePath.toUtf8().constData(), "w");
#endif
  if (mpSimulationOutputWidget->isOutputStructured()) {
    mpSimulationMessageModel = new SimulationMessageModel(mpSimulationOutputWidget);
  } else {
    mpSimulationMessageModel = 0;
  }
  parseSimulationOutput(simulationOutput.prepend("<root>"));
}

SimulationOutputHandler::~SimulationOutputHandler()
{
  simulationProcessFinished();
}

/*!
 * \brief SimulationOutputHandler::parseSimulationOutput
 * Sets the new simulation output data and continues the parsing.
 * \param output
 */
void SimulationOutputHandler::parseSimulationOutput(const QString &output)
{
  mXmlStreamReader.addData(output);
  // parse
  while (!mXmlStreamReader.atEnd()) {
    QXmlStreamReader::TokenType token = mXmlStreamReader.readNext();
    if (token == QXmlStreamReader::StartElement) {
      QXmlStreamAttributes attributes = mXmlStreamReader.attributes();
      if (mXmlStreamReader.name() == QString("message")) {
        QString text = attributes.value("text").toString() + "\n";
        mNumberOfBytes += text.toUtf8().size();

        if (isMaximumDisplayLimitReached()) {
          // Only generate the reached display limit message once.
          if (!mShownDisplayLimitReachedMessage) {
            mShownDisplayLimitReachedMessage = true;
            // if display limit is reached then close and display the so far text
            int currentLevel = mLevel;
            while (mLevel > 0) {
              mLevel--;
            }
            addSimulationMessage(mSimulationMessagesLevelMap.value(0, 0));
            // restore the level
            mLevel = currentLevel;
            // Display a message showing that the limit is reached.
            SimulationMessage *pSimulationMessage;
            if (mpSimulationOutputWidget->isOutputStructured()) {
              pSimulationMessage = new SimulationMessage(mpSimulationMessageModel->getRootSimulationMessage());
            } else {
              pSimulationMessage = new SimulationMessage;
            }
            pSimulationMessage->mStream = "LOG_STDOUT";
            pSimulationMessage->mType = StringHandler::OMEditInfo;
            pSimulationMessage->mText = Helper::displayLimit;
            pSimulationMessage->mLevel = 0;
            addSimulationMessage(pSimulationMessage);
          }
        }

        if (mpSimulationOutputWidget->isOutputStructured()) {
          mpSimulationMessage = new SimulationMessage(mpSimulationMessageModel->getRootSimulationMessage());
        } else {
          mpSimulationMessage = new SimulationMessage;
        }
        mpSimulationMessage->mStream = attributes.value("stream").toString();
        mpSimulationMessage->mType = StringHandler::getSimulationMessageType(attributes.value("type").toString());
        // check if we get the message about embedded opc-ua server initialized.
        if (attributes.value("text") == QString("The embedded server is initialized.") ){
          mpSimulationOutputWidget->embeddedServerInitialized();
        }
        if (mpSimulationOutputWidget->isOutputStructured()) {
          mpSimulationMessage->mText = Qt::convertFromPlainText(attributes.value("text").toString(), Qt::WhiteSpaceNormal);
        } else {
          mpSimulationMessage->mText = attributes.value("text").toString();
        }
        mpSimulationMessage->mLevel = mLevel;
        mSimulationMessagesLevelMap.insert(mLevel, mpSimulationMessage);
        if (mLevel > 0) {
          SimulationMessage *pSimulationMessage = mSimulationMessagesLevelMap.value(mLevel - 1, 0);
          if (pSimulationMessage) {
            mpSimulationMessage->setParent(pSimulationMessage);
            if (mpSimulationOutputWidget->isOutputStructured()) {
              mpSimulationMessage->mDeweyId = pSimulationMessage->mDeweyId + "." + QString::number(pSimulationMessage->children().size() + 1);
              mpSimulationMessage->mDeweyId = QString("%1.%2").arg(pSimulationMessage->mDeweyId)
                                              .arg(QString::number(pSimulationMessage->children().size() + 1));
            }
            pSimulationMessage->mChildren.append(mpSimulationMessage);
          }
        } else {
          if (mpSimulationOutputWidget->isOutputStructured()) {
            mpSimulationMessage->mDeweyId = QString("%1.%2").arg(mpSimulationMessageModel->getRootSimulationMessage()->mDeweyId)
                                            .arg(QString::number(mpSimulationMessageModel->getRootSimulationMessage()->children().size() + 1));
          }
        }
        mLevel++;
      } else if (mXmlStreamReader.name() == QString("used")) {
        if (mpSimulationMessage) {
          mpSimulationMessage->mIndex = attributes.value("index").toString();
        }
      } else if (mXmlStreamReader.name() == QString("status")) {
        int progress = attributes.value("progress").toInt();
        mpSimulationOutputWidget->getProgressBar()->setValue(progress/100);
        mpSimulationOutputWidget->updateMessageTabProgress();
      }
    } else if (token == QXmlStreamReader::EndElement) {
      if (mXmlStreamReader.name() == QString("message")) {
        endElement();
      }
    }
  }

  // error handling
  if (mXmlStreamReader.hasError()) {
    // read the error message
    if (mXmlStreamReader.error() != QXmlStreamReader::PrematureEndOfDocumentError) {
      QString errorText = QString("Fatal error on line %1, column %2: %3")
                          .arg(mXmlStreamReader.lineNumber())
                          .arg(mXmlStreamReader.columnNumber())
                          .arg(mXmlStreamReader.errorString());
      // construct the SimulationMessage object with error
      SimulationMessage *pSimulationMessage;
      if (mpSimulationOutputWidget->isOutputStructured()) {
        pSimulationMessage = new SimulationMessage(mpSimulationMessageModel->getRootSimulationMessage());
      } else {
        pSimulationMessage = new SimulationMessage;
      }
      pSimulationMessage->mStream = "stderr";
      pSimulationMessage->mType = StringHandler::getSimulationMessageType("error");
      pSimulationMessage->mText = errorText;
      pSimulationMessage->mLevel = 0;
      addSimulationMessage(pSimulationMessage);
    }
  }
}

/*!
 * \brief SimulationOutputHandler::writeSimulationMessage
 * Writes the simulation message.\n
 * The same function is used to write the message in the log file and in the SimulationOutputWidget.\n
 * If pSimulationOutputWidget is NULL then the message is written to the log file otherwise to the SimulationOutputWidget.
 * \param pSimulationMessage
 * \param pSimulationOutputWidget
 */
void SimulationOutputHandler::writeSimulationMessage(SimulationMessage *pSimulationMessage, SimulationOutputWidget *pSimulationOutputWidget)
{
  static QString lastStream;
  static QString lastType;
  /* format the error message */
  QString type = StringHandler::getSimulationMessageTypeString(pSimulationMessage->mType);
  QString text;
  if (pSimulationMessage->mType != StringHandler::OMEditInfo) {
    text = ((lastStream == pSimulationMessage->mStream && pSimulationMessage->mLevel > 0) ? "|" : pSimulationMessage->mStream) + "\t\t| ";
    text += ((lastStream == pSimulationMessage->mStream && lastType == type && pSimulationMessage->mLevel > 0) ? "|" : type) + "\t | ";
    for (int i = 0 ; i < pSimulationMessage->mLevel ; ++i)
      text += "| ";
  }
  text += pSimulationMessage->mText;

  if (pSimulationOutputWidget) {
    pSimulationOutputWidget->writeSimulationMessage(pSimulationMessage->mType, text, pSimulationMessage->mIndex);
  } else if (mpSimulationLogFile) {
    fputs(QString(text + "\n").toUtf8().constData(), mpSimulationLogFile);
  }

  /* save the current stream & type as last */
  lastStream = pSimulationMessage->mStream;
  lastType = type;
  /* write the child messages */
  foreach (SimulationMessage* pSimulationMessage, pSimulationMessage->mChildren) {
    writeSimulationMessage(pSimulationMessage);
  }
}

/*!
 * \brief SimulationOutputHandler::addSimulationMessage
 * \param pSimulationMessage
 */
void SimulationOutputHandler::addSimulationMessage(SimulationMessage *pSimulationMessage)
{
  if (mpSimulationOutputWidget->isOutputStructured()) {
    mpSimulationMessageModel->insertSimulationMessage(pSimulationMessage);
  } else {
    writeSimulationMessage(pSimulationMessage, mpSimulationOutputWidget);
  }
}

/*!
 * \brief SimulationOutputHandler::simulationProcessFinished
 * Closes the simulation log file.
 */
void SimulationOutputHandler::simulationProcessFinished()
{
  if (mpSimulationLogFile) {
    fclose(mpSimulationLogFile);
    mpSimulationLogFile = 0;
  }
}

/*!
 * \brief SimulationOutputHandler::isMaximumDisplayLimitReached
 * Returns true if maximum display limit is reached.
 * \return
 */
bool SimulationOutputHandler::isMaximumDisplayLimitReached() const
{
  return mNumberOfBytes > OptionsDialog::instance()->getSimulationPage()->getDisplayLimitSpinBox()->value() * 1000;
}

/*!
 * \brief SimulationOutputHandler::endElement
 */
void SimulationOutputHandler::endElement()
{
  mLevel--;
  // if mLevel is 0 then we have finished the one complete top level message tag. Add it to SimulationMessageModel now.
  if (mLevel == 0) {
    if (!isMaximumDisplayLimitReached()) {
      addSimulationMessage(mSimulationMessagesLevelMap.value(0, 0));
    }
    // write simulation log file
    writeSimulationMessage(mSimulationMessagesLevelMap.value(0, 0));
  }
}
