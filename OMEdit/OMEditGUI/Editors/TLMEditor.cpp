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

#include "TLMEditor.h"
#include "ComponentProperties.h"

XMLDocument::XMLDocument()
  : QDomDocument()
{

}

XMLDocument::XMLDocument(TLMEditor *pTLMEditor)
  : QDomDocument()
{
  mpTLMEditor = pTLMEditor;
}

QString XMLDocument::toString() const
{
  TabSettings tabSettings = mpTLMEditor->getMainWindow()->getOptionsDialog()->getTLMTabSettings();
  return QDomDocument::toString(tabSettings.getIndentSize());
}


TLMEditor::TLMEditor(ModelWidget *pModelWidget)
  : BaseEditor(pModelWidget), mLastValidText(""), mTextChanged(false), mForceSetPlainText(false)
{
  mXmlDocument = XMLDocument(this);
}

/*!
 * \brief TLMEditor::validateText
 * When user make some changes in the TLMEditor text then this method validates the text.
 * \return
 */
bool TLMEditor::validateText()
{
  if (mTextChanged) {
    // if the user makes few mistakes in the text then dont let him change the perspective
    if (!mpModelWidget->TLMEditorTextChanged()) {
      QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::ERROR_IN_TEXT).arg("MetaModel")
                           .append(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER))
                           .append(GUIMessages::getMessage(GUIMessages::REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY)));
      pMessageBox->addButton(tr("Fix error(s) manually"), QMessageBox::AcceptRole);
      pMessageBox->addButton(tr("Revert to last correct version"), QMessageBox::RejectRole);
      int answer = pMessageBox->exec();
      switch (answer) {
        case QMessageBox::RejectRole:
          mTextChanged = false;
          // revert back to last correct version
          setPlainText(mLastValidText);
          return true;
        case QMessageBox::AcceptRole:
        default:
          mTextChanged = true;
          return false;
      }
    } else {
      mTextChanged = false;
      mLastValidText = mpPlainTextEdit->toPlainText();
    }
  }
  return true;
}

/*!
 * \brief TLMEditor::getSubModelsElement
 * Returns the SubModels element tag.
 * \return
 */
QDomElement TLMEditor::getSubModelsElement()
{
  QDomNodeList subModels = mXmlDocument.elementsByTagName("SubModels");
  if (subModels.size() > 0) {
    return subModels.at(0).toElement();
  }
  return QDomElement();
}

/*!
 * \brief TLMEditor::getConnectionsElement
 * Returns the Connections element tag.
 * \return
 */
QDomElement TLMEditor::getConnectionsElement()
{
  QDomNodeList connections = mXmlDocument.elementsByTagName("Connections");
  if (connections.size() > 0) {
    return connections.at(0).toElement();
  }
  return QDomElement();
}

/*!
 * \brief TLMEditor::getSubModels
 * Returns the list of SubModel tags.
 * \return
 */
QDomNodeList TLMEditor::getSubModels()
{
  return mXmlDocument.elementsByTagName("SubModel");
}

/*!
 * \brief TLMEditor::getConnections
 * Returns the list of Connection tags.
 * \return
 */
QDomNodeList TLMEditor::getConnections()
{
  return mXmlDocument.elementsByTagName("Connection");
}

/*!
 * \brief TLMEditor::getSimulationToolStartCommand
 * Returns the simulation tool start command.
 * \return
 */
QString TLMEditor::getSimulationToolStartCommand(QString name)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(name) == 0) {
      return subModel.attribute("StartCommand");
    }
  }
  return "";
}

/*!
 * \brief TLMEditor::addSubModel
 * Adds a SubModel tag with Annotation tag as child of it.
 * \param name
 * \param exactStep
 * \param modelFile
 * \param startCommand
 * \param visible
 * \param origin
 * \param extent
 * \param rotation
 * \return
 */
bool TLMEditor::addSubModel(QString name, QString exactStep, QString modelFile, QString startCommand, QString visible, QString origin,
                            QString extent, QString rotation)
{
  QDomElement subModels = getSubModelsElement();
  if (!subModels.isNull()) {
    QDomElement subModel = mXmlDocument.createElement("SubModel");
    subModel.setAttribute("Name", name);
    subModel.setAttribute("ExactStep", exactStep);
    subModel.setAttribute("ModelFile", modelFile);
    subModel.setAttribute("StartCommand", startCommand);
    // create Annotation Element
    QDomElement annotation = mXmlDocument.createElement("Annotation");
    annotation.setAttribute("Visible", visible);
    annotation.setAttribute("Origin", origin);
    annotation.setAttribute("Extent", extent);
    annotation.setAttribute("Rotation", rotation);
    subModel.appendChild(annotation);
    subModels.appendChild(subModel);
    setPlainText(mXmlDocument.toString());
    return true;
  }
  return false;
}

/*!
 * \brief TLMEditor::createAnnotationElement
 * Creates an Annotation tag for SubModel.
 * \param subModel
 * \param visible
 * \param origin
 * \param extent
 * \param rotation
 */
void TLMEditor::createAnnotationElement(QDomElement subModel, QString visible, QString origin, QString extent, QString rotation)
{
  QDomElement annotation = mXmlDocument.createElement("Annotation");
  annotation.setAttribute("Visible", visible);
  annotation.setAttribute("Origin", origin);
  annotation.setAttribute("Extent", extent);
  annotation.setAttribute("Rotation", rotation);
  subModel.insertBefore(annotation, QDomNode());
  setPlainText(mXmlDocument.toString());
}

/*!
 * \brief TLMEditor::updateSubModelPlacementAnnotation
 * Updates the SubModel annotation.
 * \param name
 * \param visible
 * \param origin
 * \param extent
 * \param rotation
 */
void TLMEditor::updateSubModelPlacementAnnotation(QString name, QString visible, QString origin, QString extent, QString rotation)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(name) == 0) {
      QDomNodeList subModelChildren = subModel.childNodes();
      for (int j = 0 ; j < subModelChildren.size() ; j++) {
        QDomElement annotationElement = subModelChildren.at(j).toElement();
        if (annotationElement.tagName().compare("Annotation") == 0) {
          annotationElement.setAttribute("Visible", visible);
          annotationElement.setAttribute("Origin", origin);
          annotationElement.setAttribute("Extent", extent);
          annotationElement.setAttribute("Rotation", rotation);
          setPlainText(mXmlDocument.toString());
          return;
        }
      }
      // create annotation element
      createAnnotationElement(subModel, visible, origin, extent, rotation);
      break;
    }
  }
}

/*!
 * \brief TLMEditor::updateSubModelParameters
 * Updates the SubModel parameters.
 * \param name
 * \param startCommand
 * \param ExactStepflag
 */
void TLMEditor::updateSubModelParameters(QString name, QString startCommand, QString exactStepFlag)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(name) == 0) {
      subModel.setAttribute("StartCommand", startCommand);
      subModel.setAttribute("ExactStep", exactStepFlag);
      setPlainText(mXmlDocument.toString());
      return;
     }
   }
}

/*!
  Checks whether the exact step flag is set to 1 or not.
  \param subModelName - the name for the submodel to check.
  \return true on success.
  */
bool TLMEditor::isExactStepFlagSet(QString subModelName)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(subModelName) == 0) {
        if (subModel.attribute("ExactStep").compare("1") == 0 ) {
           return true;
        }
      }
      break;
    }
  return false;
}

/*!
 * \brief TLMEditor::createConnection
 * Adds a a connection tag with Annotation tag as child of it.
 * \param from
 * \param to
 * \param delay
 * \param alpha
 * \param zf
 * \param zfr
 * \param points
 * \return
 */
bool TLMEditor::createConnection(QString from, QString to, QString delay, QString alpha, QString zf, QString zfr, QString points)
{
  QDomElement connections = getConnectionsElement();
  if (!connections.isNull()) {
    QDomElement connection = mXmlDocument.createElement("Connection");
    connection.setAttribute("From", from);
    connection.setAttribute("To", to);
    connection.setAttribute("Delay", delay);
    connection.setAttribute("alpha", alpha);
    connection.setAttribute("Zf", zf);
    connection.setAttribute("Zfr", zfr);
    // create Annotation Element
    QDomElement annotation = mXmlDocument.createElement("Annotation");
    annotation.setAttribute("Points", points);
    connection.appendChild(annotation);
    connections.appendChild(connection);
    setPlainText(mXmlDocument.toString());
    return true;
  }
  return false;
}

/*!
 * \brief TLMEditor::updateTLMConnectiontAnnotation
 * Updates the TLM connection annotation.
 * \param fromSubModel
 * \param toSubModel
 * \param points
 */
void TLMEditor::updateTLMConnectiontAnnotation(QString fromSubModel, QString toSubModel, QString points)
{
  QDomNodeList connectionList = mXmlDocument.elementsByTagName("Connection");
  for (int i = 0 ; i < connectionList.size() ; i++) {
    QDomElement connection = connectionList.at(i).toElement();
    if (StringHandler::getSubStringBeforeDots(connection.attribute("From")).compare(fromSubModel) == 0
        && StringHandler::getSubStringBeforeDots(connection.attribute("To")).compare(toSubModel) == 0) {
      QDomNodeList connectionChildren = connection.childNodes();
      for (int j = 0 ; j < connectionChildren.size() ; j++) {
        QDomElement annotationElement = connectionChildren.at(j).toElement();
        if (annotationElement.tagName().compare("Annotation") == 0) {
          annotationElement.setAttribute("Points", points);
          setPlainText(mXmlDocument.toString());
          return;
        }
      }
      break;
    }
  }
}

/*!
 * \brief TLMEditor::addInterfacesData
 * Adds the InterfacePoint tag to SubModel.
 * \param interfaces
 */
void TLMEditor::addInterfacesData(QDomElement interfaces)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    QDomElement interfaceDataElement = interfaces.firstChildElement();
    while (!interfaceDataElement.isNull()) {
      if (subModel.attribute("Name").compare(interfaceDataElement.attribute("model")) == 0
          && !existInterfaceData(subModel.attribute("Name"), interfaceDataElement.attribute("name"))) {
        QDomElement interfacePoint = mXmlDocument.createElement("InterfacePoint");
        interfacePoint.setAttribute("Name",interfaceDataElement.attribute("name"));
        interfacePoint.setAttribute("Position",interfaceDataElement.attribute("Position"));
        interfacePoint.setAttribute("Angle321",interfaceDataElement.attribute("Angle321"));
        subModel.appendChild(interfacePoint);
        setPlainText(mXmlDocument.toString());

        TLMInterfacePointInfo *pTLMInterfacePointInfo;
        pTLMInterfacePointInfo = new TLMInterfacePointInfo(subModel.attribute("Name"),"shaft3" , interfaceDataElement.attribute("name"));
        getModelWidget()->getDiagramGraphicsView()->getComponentObject(subModel.attribute("Name"))->addInterfacePoint(pTLMInterfacePointInfo);
      }
      interfaceDataElement = interfaceDataElement.nextSiblingElement();
    }
  }
}

/*!
  Checks whether the interface already exists in MetaModel or not.
  \param interfaceName - the name for the interface to check.
  \return true on success.
  */
bool TLMEditor::existInterfaceData(QString subModelName, QString interfaceName)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(subModelName) == 0) {
      QDomNodeList subModelChildren = subModel.childNodes();
      for (int j = 0 ; j < subModelChildren.size() ; j++) {
        QDomElement interfaceElement = subModelChildren.at(j).toElement();
        if (interfaceElement.tagName().compare("InterfacePoint") == 0 && interfaceElement.attribute("Name").compare(interfaceName)== 0) {
           return true;
        }
      }
      break;
    }
  }
  return false;
}

/*!
 * \brief TLMEditor::deleteSubModel
 * Delets a SubModel.
 * \param name
 * \return
 */
bool TLMEditor::deleteSubModel(QString name)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(name) == 0) {
      QDomElement subModels = getSubModelsElement();
      if (!subModels.isNull()) {
        subModels.removeChild(subModel);
        setPlainText(mXmlDocument.toString());
        return true;
      }
      break;
    }
  }
  return false;
}

/*!
 * \brief TLMEditor::deleteConnection
 * Delets a connection.
 * \param name
 * \return
 */
bool TLMEditor::deleteConnection(QString startSubModelName, QString endSubModelName)
{
  QDomNodeList connectionList = mXmlDocument.elementsByTagName("Connection");
  for (int i = 0 ; i < connectionList.size() ; i++) {
    QDomElement connection = connectionList.at(i).toElement();
    QString startName = StringHandler::getSubStringBeforeDots(connection.attribute("From"));
    QString endName = StringHandler::getSubStringBeforeDots(connection.attribute("To"));
    if (startName.compare(startSubModelName) == 0 && endName.compare(endSubModelName) == 0 ) {
      QDomElement connections = getConnectionsElement();
      if (!connections.isNull()) {
        connections.removeChild(connection);
        setPlainText(mXmlDocument.toString());
        return true;
      }
      break;
    }
  }
  return false;
}

/*!
 * \brief TLMEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void TLMEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = createStandardContextMenu();
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

/*!
 * \brief TLMEditor::setPlainText
 * Reimplementation of QPlainTextEdit::setPlainText method.
 * Makes sure we dont update if the passed text is same.
 * \param text the string to set.
 */
void TLMEditor::setPlainText(const QString &text)
{
  if (text != mpPlainTextEdit->toPlainText()) {
    mForceSetPlainText = true;
    mXmlDocument.setContent(text);
    // use the text from mXmlDocument so that we can map error to line numbers. We don't care about users formatting in the file.
    mpPlainTextEdit->setPlainText(mXmlDocument.toString());
    mForceSetPlainText = false;
    mLastValidText = text;
  }
}

/*!
 * \brief TLMEditor::contentsHasChanged
 * Slot activated when TLMEdit's QTextDocument contentsChanged SIGNAL is raised.\n
 * Sets the model as modified so that user knows that his current TLM is not saved.
 * \param position
 * \param charsRemoved
 * \param charsAdded
 */
void TLMEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget->isVisible()) {
    if (charsRemoved == 0 && charsAdded == 0) {
      return;
    }
    /* if user is changing the read only file. */
    if (mpModelWidget->getLibraryTreeItem()->isReadOnly() && !mForceSetPlainText) {
      /* if user is changing the read-only class. */
      mpMainWindow->getInfoBar()->showMessage(tr("<b>Warning: </b>You are changing a read-only class."));
    } else {
      /* if user is changing, the normal file. */
      if (!mForceSetPlainText) {
        mpModelWidget->setWindowTitle(QString(mpModelWidget->getLibraryTreeItem()->getNameStructure()).append("*"));
        mpModelWidget->getLibraryTreeItem()->setIsSaved(false);
        mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(mpModelWidget->getLibraryTreeItem());
        mTextChanged = true;
      }
    }
  }
}

//! @class TLMHighlighter
//! @brief A syntax highlighter for TLMEditor.

//! Constructor
TLMHighlighter::TLMHighlighter(TLMEditorPage *pTLMEditorPage, QPlainTextEdit *pPlainTextEdit)
    : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpTLMEditorPage = pTLMEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void TLMHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpTLMEditorPage->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpTLMEditorPage->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(mpTLMEditorPage->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpTLMEditorPage->getTextRuleColor());
  mTagFormat.setForeground(mpTLMEditorPage->getTagRuleColor());
  mElementFormat.setForeground(mpTLMEditorPage->getElementRuleColor());
  mCommentFormat.setForeground(mpTLMEditorPage->getCommentRuleColor());
  mQuotationFormat.setForeground(QColor(mpTLMEditorPage->getQuotesRuleColor()));

  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);

 // TLM Tags
  QStringList TLMTags;
  TLMTags << "<\\?"
          << "<"
          << "</"
          << "\\?>"
          << ">"
          << "/>";
  foreach (const QString &TLMTag, TLMTags)
  {
    rule.mPattern = QRegExp(TLMTag);
    rule.mFormat = mTagFormat;
    mHighlightingRules.append(rule);
  }

 // TLM Elements
  QStringList elementPatterns;
  elementPatterns << "\\bxml\\b"
                  << "\\bModel\\b"
                  << "\\bAnnotations\\b"
                  << "\\bAnnotation\\b"
                  << "\\bSubModels\\b"
                  << "\\bSubModel\\b"
                  << "\\bInterfacePoint\\b"
                  << "\\bConnections\\b"
                  << "\\bConnection\\b"
                  << "\\bLines\\b"
                  << "\\bLine\\b"
                  << "\\bSimulationParams\\b";
  foreach (const QString &elementPattern, elementPatterns)
  {
    rule.mPattern = QRegExp(elementPattern);
    rule.mFormat = mElementFormat;
    mHighlightingRules.append(rule);
  }

  // TLM Comments
  mCommentStartExpression = QRegExp("<!--");
  mCommentEndExpression = QRegExp("-->");
}

/*!
  Highlights the multilines text.\n
  Quoted text.
  */
void TLMHighlighter::highlightMultiLine(const QString &text)
{
  int index = 0, startIndex = 0;
  int blockState = previousBlockState();
  // fprintf(stderr, "%s with blockState %d\n", text.toStdString().c_str(), blockState);

  while (index < text.length())
  {
    switch (blockState) {
      case 2:
        if (text[index] == '-' &&
            index+1<text.length() && text[index+1] == '-' &&
            index+2<text.length() && text[index+2] == '>') {
          index = index+2;
          setFormat(startIndex, index-startIndex+1, mCommentFormat);
          blockState = 0;
        }
        break;
      case 3:
        if (text[index] == '\\') {
          index++;
        } else if (text[index] == '"') {
          setFormat(startIndex, index-startIndex+1, mQuotationFormat);
          blockState = 0;
        }
        break;
      default:
        if (text[index] == '<' &&
            index+1<text.length() && text[index+1] == '!' &&
            index+2<text.length() && text[index+2] == '-' &&
            index+3<text.length() && text[index+3] == '-') {
          startIndex = index;
          blockState = 2;
        } else if (text[index] == '"') {
          startIndex = index;
          blockState = 3;
        }
    }
    index++;
  }
  switch (blockState) {
    case 2:
      setFormat(startIndex, text.length()-startIndex, mCommentFormat);
      setCurrentBlockState(2);
      break;
    case 3:
      setFormat(startIndex, text.length()-startIndex, mQuotationFormat);
      setCurrentBlockState(3);
      break;
  }
}

//! Reimplementation of QSyntaxHighlighter::highlightBlock
void TLMHighlighter::highlightBlock(const QString &text)
{
  /* Only highlight the text if user has enabled the syntax highlighting */
  if (!mpTLMEditorPage->getSyntaxHighlightingCheckbox()->isChecked()) {
    return;
  }
  setCurrentBlockState(0);
  setFormat(0, text.length(), mpTLMEditorPage->getTextRuleColor());
  foreach (const HighlightingRule &rule, mHighlightingRules)
  {
    QRegExp expression(rule.mPattern);
    int index = expression.indexIn(text);
    while (index >= 0)
    {
      int length = expression.matchedLength();
      setFormat(index, length, rule.mFormat);
      index = expression.indexIn(text, index + length);
    }
  }
  highlightMultiLine(text);
}

//! Slot activated whenever ModelicaEditor text settings changes.
void TLMHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}

