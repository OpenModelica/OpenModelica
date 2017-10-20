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

#include "CompositeModelEditor.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "Modeling/Commands.h"
#include "Options/NotificationsDialog.h"

#include <QMessageBox>
#include <QMenu>

XMLDocument::XMLDocument()
  : QDomDocument()
{

}

XMLDocument::XMLDocument(CompositeModelEditor *pCompositeModelEditor)
  : QDomDocument()
{
  mpCompositeModelEditor = pCompositeModelEditor;
}

QString XMLDocument::toString() const
{
  TabSettings tabSettings = OptionsDialog::instance()->getTabSettings();
  return QDomDocument::toString(tabSettings.getIndentSize());
}


CompositeModelEditor::CompositeModelEditor(QWidget *pParent)
  : BaseEditor(pParent), mLastValidText(""), mTextChanged(false)
{
  mXmlDocument = XMLDocument(this);
}

/*!
 * \brief CompositeModelEditor::popUpCompleter()
 * \we do not have completer for this
 */
void CompositeModelEditor::popUpCompleter()
{

}

/*!
 * \brief CompositeModelEditor::validateText
 * When user make some changes in the CompositeModelEditor text then this method validates the text.
 * \return
 */
bool CompositeModelEditor::validateText()
{
  if (mTextChanged) {
    // if the user makes few mistakes in the text then dont let him change the perspective
    if (!mpModelWidget->compositeModelEditorTextChanged()) {
      QSettings *pSettings = Utilities::getApplicationSettings();
      int answer = -1;
      if (pSettings->contains("textEditor/revertPreviousOrFixErrorsManually")) {
        answer = pSettings->value("textEditor/revertPreviousOrFixErrorsManually").toInt();
      }
      if (answer < 0 || OptionsDialog::instance()->getNotificationsPage()->getAlwaysAskForTextEditorErrorCheckBox()->isChecked()) {
        NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::RevertPreviousOrFixErrorsManually,
                                                                            NotificationsDialog::CriticalIcon,
                                                                            MainWindow::instance());
        pNotificationsDialog->setNotificationLabelString(GUIMessages::getMessage(GUIMessages::ERROR_IN_TEXT).arg("Composite Model")
                                                         .append(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER))
                                                         .append(GUIMessages::getMessage(GUIMessages::REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY)));
        pNotificationsDialog->getOkButton()->setText(Helper::revertToLastCorrectVersion);
        pNotificationsDialog->getOkButton()->setAutoDefault(false);
        pNotificationsDialog->getCancelButton()->setText(Helper::fixErrorsManually);
        pNotificationsDialog->getCancelButton()->setAutoDefault(true);
        pNotificationsDialog->getButtonBox()->removeButton(pNotificationsDialog->getOkButton());
        pNotificationsDialog->getButtonBox()->removeButton(pNotificationsDialog->getCancelButton());
        pNotificationsDialog->getButtonBox()->addButton(pNotificationsDialog->getCancelButton(), QDialogButtonBox::ActionRole);
        pNotificationsDialog->getButtonBox()->addButton(pNotificationsDialog->getOkButton(), QDialogButtonBox::ActionRole);
        // we set focus to this widget here so when the error dialog is closed Qt gives back the focus to this widget.
        mpPlainTextEdit->setFocus(Qt::ActiveWindowFocusReason);
        answer = pNotificationsDialog->exec();
      }
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
  updateAllOrientations();
  return true;
}


/*!
 * @\brief CompositeModelEditor::getSubModelElement
 * Returns SubModel element tag by model name
 * @param name Name of the sub model to search for
 * @return
 */
QDomElement CompositeModelEditor::getSubModelElement(QString name)
{
  QDomElement subModelsElement = getSubModelsElement();
  if(!subModelsElement.isNull()) {
    QDomElement subModelElement = subModelsElement.firstChildElement("SubModel");
    while(!subModelElement.isNull()) {
      if(subModelElement.attribute("Name").compare(name) == 0) {
        return subModelElement;
      }
      subModelElement = subModelElement.nextSiblingElement("SubModel");
    }
  }
  return QDomElement();
}

QStringList CompositeModelEditor::getParameterNames(QString subModelName)
{
  QStringList ret;
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModelElement = subModelList.at(i).toElement();
    if(subModelElement.attribute("Name").compare(subModelName) == 0) {
      QDomElement parameterElement = subModelElement.firstChildElement("Parameter");
      while(!parameterElement.isNull()) {
        ret << parameterElement.attribute("Name");
        parameterElement = parameterElement.nextSiblingElement("Parameter");
      }
    }
  }
  return ret;
}

QString CompositeModelEditor::getParameterValue(QString subModelName, QString parameterName)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModelElement = subModelList.at(i).toElement();
    if(subModelElement.attribute("Name").compare(subModelName) == 0) {
      QDomElement parameterElement = subModelElement.firstChildElement("Parameter");
      while(!parameterElement.isNull()) {
        if(parameterElement.attribute("Name").compare(parameterName) == 0) {
          return parameterElement.attribute("Value");
        }
        parameterElement = parameterElement.nextSiblingElement("Parameter");
      }
    }
  }
  return "";      //Should never happen
}

void CompositeModelEditor::setParameterValue(QString subModelName, QString parameterName, QString value)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModelElement = subModelList.at(i).toElement();
    if (subModelElement.attribute("Name").compare(subModelName) == 0) {
      QDomElement parameterElement = subModelElement.firstChildElement("Parameter");
      while(!parameterElement.isNull()) {
        if(parameterElement.attribute("Name").compare(parameterName) == 0) {
          parameterElement.setAttribute("Value",value);
          setPlainText(mXmlDocument.toString());
          return;
        }
        parameterElement = parameterElement.nextSiblingElement("Parameter");
      }
      //Parameter not found, insert it
      QDomElement parameterPoint = mXmlDocument.createElement("Parameter");
      parameterPoint.setAttribute("Name", parameterName);
      parameterPoint.setAttribute("Value", value);
      subModelElement.appendChild(parameterPoint);
      setPlainText(mXmlDocument.toString());
      return;
    }
  }
}

/*!
 * \brief CompositeModelEditor::getCompositeModelName
 * Gets the CompositeModel name.
 * \return
 */
QString CompositeModelEditor::getCompositeModelName()
{
  QDomNodeList nodes = mXmlDocument.elementsByTagName("Model");
  for (int i = 0; i < nodes.size(); i++) {
    QDomElement node = nodes.at(i).toElement();
    return node.attribute("Name");
  }
  return "";
}

/*!
 * \brief CompositeModelEditor::getSubModelsElement
 * Returns the SubModels element tag.
 * \return
 */
QDomElement CompositeModelEditor::getSubModelsElement()
{
  QDomNodeList subModels = mXmlDocument.elementsByTagName("SubModels");
  if (subModels.size() > 0) {
    return subModels.at(0).toElement();
  }
  return QDomElement();
}

/*!
 * \brief CompositeModelEditor::getSubModels
 * Returns the list of SubModel tags.
 * \return
 */
QDomNodeList CompositeModelEditor::getSubModels()
{
  return mXmlDocument.elementsByTagName("SubModel");
}

/*!
 * \brief CompositeModelEditor::getInterfacePoint
 * \param subModelName
 * \param interfaceName
 * \return
 */
QDomElement CompositeModelEditor::getInterfacePoint(QString subModelName, QString interfaceName)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(subModelName) == 0) {
      QDomNodeList subModelChildren = subModel.childNodes();
      for (int j = 0 ; j < subModelChildren.size() ; j++) {
        QDomElement interfaceElement = subModelChildren.at(j).toElement();
        if (interfaceElement.tagName().compare("InterfacePoint") == 0 && interfaceElement.attribute("Name").compare(interfaceName) == 0) {
          return interfaceElement;
        }
      }
    }
  }
  return QDomElement();
}

/*!
 * \brief CompositeModelEditor::getConnectionsElement
 * Returns the Connections element tag.
 * \return
 */
QDomElement CompositeModelEditor::getConnectionsElement()
{
  QDomNodeList connections = mXmlDocument.elementsByTagName("Connections");
  if (connections.size() > 0) {
    return connections.at(0).toElement();
  }
  return QDomElement();
}

/*!
 * \brief CompositeModelEditor::getConnections
 * Returns the list of Connection tags.
 * \return
 */
QDomNodeList CompositeModelEditor::getConnections()
{
  return mXmlDocument.elementsByTagName("Connection");
}

/*!
 * \brief CompositeModelEditor::setCompositeModelName
 * Sets the CompositeModel name.
 * \param name
 */
void CompositeModelEditor::setCompositeModelName(QString name)
{
  QDomNodeList nodes = mXmlDocument.elementsByTagName("Model");
  for (int i = 0; i < nodes.size(); i++) {
    QDomElement node = nodes.at(i).toElement();
    node.setAttribute("Name", name);
    setPlainText(mXmlDocument.toString());
    break;
  }
}

/*!
 * \brief CompositeModelEditor::addSubModel
 * Adds a SubModel tag with Annotation tag as child of it.
 * \param pComponent
 * \return
 */
bool CompositeModelEditor::addSubModel(Component *pComponent)
{
  pComponent->getComponentInfo()->setName(pComponent->getName().remove("."));
  QDomElement subModels = getSubModelsElement();
  if (!subModels.isNull()) {
    QDomElement subModel = mXmlDocument.createElement("SubModel");
    subModel.setAttribute("Name", pComponent->getName());
    subModel.setAttribute("ModelFile", pComponent->getComponentInfo()->getModelFile());
    subModel.setAttribute("StartCommand", pComponent->getComponentInfo()->getStartCommand());
    subModel.setAttribute("Position", pComponent->getComponentInfo()->getPosition());
    subModel.setAttribute("Angle321", pComponent->getComponentInfo()->getAngle321());
    if (pComponent->getComponentInfo()->getGeometryFile().isEmpty()) {
      subModel.removeAttribute("GeometryFile");
    } else {
      QFileInfo geometryFileInfo(pComponent->getComponentInfo()->getGeometryFile());
      subModel.setAttribute("GeometryFile", geometryFileInfo.fileName());
    }
    // create Annotation Element
    QDomElement annotation = mXmlDocument.createElement("Annotation");
    annotation.setAttribute("Visible", pComponent->mTransformation.getVisible() ? "true" : "false");
    annotation.setAttribute("Origin", pComponent->getTransformationOrigin());
    annotation.setAttribute("Extent", pComponent->getTransformationExtent());
    annotation.setAttribute("Rotation", QString::number(pComponent->mTransformation.getRotateAngle()));
    subModel.appendChild(annotation);
    subModels.appendChild(subModel);
    setPlainText(mXmlDocument.toString());
    return true;
  }
  return false;
}

/*!
 * \brief CompositeModelEditor::createAnnotationElement
 * Creates an Annotation tag for SubModel.
 * \param subModel
 * \param visible
 * \param origin
 * \param extent
 * \param rotation
 */
void CompositeModelEditor::createAnnotationElement(QDomElement subModel, QString visible, QString origin, QString extent, QString rotation)
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
 * \brief CompositeModelEditor::updateSubModelPlacementAnnotation
 * Updates the SubModel annotation.
 * \param name
 * \param visible
 * \param origin
 * \param extent
 * \param rotation
 */
void CompositeModelEditor::updateSubModelPlacementAnnotation(QString name, QString visible, QString origin, QString extent, QString rotation)
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
 * \brief CompositeModelEditor::updateSubModelParameters
 * Updates the SubModel parameters.
 * \param name
 * \param startCommand
 * \param exactStep
 * \param geometryFile
 */
void CompositeModelEditor::updateSubModelParameters(QString name, QString startCommand, QString exactStep, QString geometryFile)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(name) == 0) {
      subModel.setAttribute("StartCommand", startCommand);
      if (exactStep.compare("true") == 0) {
        subModel.setAttribute("ExactStep", exactStep);
      } else if (subModel.hasAttribute("ExactStep")) {
        subModel.removeAttribute("ExactStep");
      }
      if (geometryFile.isEmpty()) {
        subModel.removeAttribute("GeometryFile");
      } else {
        QFileInfo geometryFileInfo(geometryFile);
        subModel.setAttribute("GeometryFile", geometryFileInfo.fileName());
      }
      setPlainText(mXmlDocument.toString());
      return;
    }
  }
}

void CompositeModelEditor::updateSubModelOrientation(QString name, QGenericMatrix<3,1,double> pos, QGenericMatrix<3,1,double> rot)
{
  QString pos_str = QString("%1,%2,%3").arg(pos(0,0)).arg(pos(0,1)).arg(pos(0,2));
  getSubModelElement(name).setAttribute("Position", pos_str);
  QString rot_str = QString("%1,%2,%3").arg(rot(0,0)).arg(rot(0,1)).arg(rot(0,2));
  getSubModelElement(name).setAttribute("Angle321", rot_str);
  setPlainText(mXmlDocument.toString());

  Component *pComp = mpModelWidget->getDiagramGraphicsView()->getComponentObject(name);
  if(pComp) {
    pComp->getComponentInfo()->setPosition(pos_str);
    pComp->getComponentInfo()->setAngle321(rot_str);
  }
}

/*!
 * \brief CompositeModelEditor::createConnection
 * Adds a connection tag with Annotation tag as child of it.
 * \param pConnectionLineAnnotation
 * \return
 */
bool CompositeModelEditor::createConnection(LineAnnotation *pConnectionLineAnnotation)
{
  QDomElement connections = getConnectionsElement();
  if (!connections.isNull()) {
    QDomElement connection = mXmlDocument.createElement("Connection");
    connection.setAttribute("From", pConnectionLineAnnotation->getStartComponentName());
    connection.setAttribute("To", pConnectionLineAnnotation->getEndComponentName());
    connection.setAttribute("Delay", pConnectionLineAnnotation->getDelay());
    if(!pConnectionLineAnnotation->getAlpha().isEmpty()) {
      connection.setAttribute("alpha", pConnectionLineAnnotation->getAlpha());
    }
    if(!pConnectionLineAnnotation->getZf().isEmpty()) {
      connection.setAttribute("Zf", pConnectionLineAnnotation->getZf());
    }
    if(!pConnectionLineAnnotation->getZfr().isEmpty()) {
      connection.setAttribute("Zfr", pConnectionLineAnnotation->getZfr());
    }
    // create Annotation Element
    QDomElement annotation = mXmlDocument.createElement("Annotation");
    annotation.setAttribute("Points", pConnectionLineAnnotation->getCompositeModelShapeAnnotation());
    connection.appendChild(annotation);
    connections.appendChild(connection);
    setPlainText(mXmlDocument.toString());
    // check if interfaces are aligned
    bool aligned = interfacesAligned(pConnectionLineAnnotation->getStartComponentName(), pConnectionLineAnnotation->getEndComponentName());
    pConnectionLineAnnotation->setAligned(aligned);

    if (this->getInterfaceCausality(pConnectionLineAnnotation->getEndComponentName()) ==
        StringHandler::getTLMCausality(StringHandler::TLMInput)) {
      pConnectionLineAnnotation->setLinePattern(StringHandler::LineDash);
      pConnectionLineAnnotation->setEndArrow(StringHandler::ArrowFilled);
    } else if(this->getInterfaceCausality(pConnectionLineAnnotation->getEndComponentName()) ==
              StringHandler::getTLMCausality(StringHandler::TLMOutput)) {
      pConnectionLineAnnotation->setLinePattern(StringHandler::LineDash);
      pConnectionLineAnnotation->setStartArrow(StringHandler::ArrowFilled);
    }
    return true;
  }
  return false;
}

/*!
 * \brief CompositeModelEditor::okToConnect
 * Checks if a connection between two interfaces is legal
 * \param pConnectionLineAnnotation
 * \return
 */
bool CompositeModelEditor::okToConnect(LineAnnotation *pConnectionLineAnnotation)
{
  QString startComp = pConnectionLineAnnotation->getStartComponentName();
  QString endComp = pConnectionLineAnnotation->getEndComponentName();

  int dimensions1 = getInterfaceDimensions(startComp);
  int dimensions2 = getInterfaceDimensions(endComp);
  QString causality1 = getInterfaceCausality(startComp);
  QString causality2 = getInterfaceCausality(endComp);
  QString domain1 = getInterfaceDomain(startComp);
  QString domain2 = getInterfaceDomain(endComp);

  if (dimensions1 != dimensions2) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0,
                                                          tr("Cannot connect interface points of different dimensions (%1 to %2)")
                                                          .arg(QString::number(dimensions1), QString::number(dimensions2)),
                                                          Helper::scriptingKind, Helper::errorLevel));
    return false;
  }
  if (!(causality1 == StringHandler::getTLMCausality(StringHandler::TLMBidirectional) &&
        causality2 == StringHandler::getTLMCausality(StringHandler::TLMBidirectional)) &&
      !(causality1 == StringHandler::getTLMCausality(StringHandler::TLMInput) &&
        causality2  == StringHandler::getTLMCausality(StringHandler::TLMOutput)) &&
      !(causality1 == StringHandler::getTLMCausality(StringHandler::TLMOutput) &&
        causality2  == StringHandler::getTLMCausality(StringHandler::TLMInput))) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0,
                                                          tr("Cannot connect interface points of different causality (%1 to %2)")
                                                          .arg(causality1, causality2), Helper::scriptingKind, Helper::errorLevel));
    return false;
  }
  if (domain1 != domain2) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0,
                                                          tr("Cannot connect interface points of different domains (%1 to %2)")
                                                          .arg(domain1, domain2), Helper::scriptingKind, Helper::errorLevel));
    return false;
  }
  return true;
}

/*!
 * \brief CompositeModelEditor::updateConnection
 * Updates the CompositeModel connection annotation.
 * \param pConnectionLineAnnotation
 */
void CompositeModelEditor::updateConnection(LineAnnotation *pConnectionLineAnnotation)
{
  QDomNodeList connectionList = mXmlDocument.elementsByTagName("Connection");
  for (int i = 0 ; i < connectionList.size() ; i++) {
    QDomElement connection = connectionList.at(i).toElement();
    if (connection.attribute("From").compare(pConnectionLineAnnotation->getStartComponentName()) == 0 &&
        connection.attribute("To").compare(pConnectionLineAnnotation->getEndComponentName()) == 0) {
      connection.setAttribute("Delay", pConnectionLineAnnotation->getDelay());
      if(connection.hasAttribute("alpha")) {
        connection.setAttribute("alpha", pConnectionLineAnnotation->getAlpha());
      }
      if(connection.hasAttribute("Zf")) {
        connection.setAttribute("Zf", pConnectionLineAnnotation->getZf());
      }
      if(connection.hasAttribute("Zfr")) {
        connection.setAttribute("Zfr", pConnectionLineAnnotation->getZfr());
      }
      QDomNodeList connectionChildren = connection.childNodes();
      bool annotationFound = false;
      for (int j = 0 ; j < connectionChildren.size() ; j++) {
        QDomElement annotationElement = connectionChildren.at(j).toElement();
        if (annotationElement.tagName().compare("Annotation") == 0) {
          annotationFound = true;
          annotationElement.setAttribute("Points", pConnectionLineAnnotation->getCompositeModelShapeAnnotation());
          setPlainText(mXmlDocument.toString());
          return;
        }
      }
      // if we found the connection and there is no annotation with it then add the annotation element.
      if (!annotationFound) {
        QDomElement annotationElement = mXmlDocument.createElement("Annotation");
        annotationElement.setAttribute("Points", pConnectionLineAnnotation->getCompositeModelShapeAnnotation());
        connection.appendChild(annotationElement);
        setPlainText(mXmlDocument.toString());
      }
      break;
    }
  }
}

/*!
 * \brief CompositeModelEditor::updateSimulationParams
 * Updates the simulation parameters.
 * \param startTime
 * \param stopTime
 */
void CompositeModelEditor::updateSimulationParams(QString startTime, QString stopTime)
{
  QDomElement simulationParamsElement = mXmlDocument.documentElement().firstChildElement("SimulationParams");
  if (!simulationParamsElement.isNull()) {
    simulationParamsElement.setAttribute("StartTime", startTime);
    simulationParamsElement.setAttribute("StopTime", stopTime);
  }
  setPlainText(mXmlDocument.toString());
}

/*!
 * \brief CompositeModelEditor::isSimulationParams
 * Updates the simulation parameters.
 */
bool CompositeModelEditor::isSimulationParams()
{
  QDomElement simulationParamsElement = mXmlDocument.documentElement().firstChildElement("SimulationParams");
  if (!simulationParamsElement.isNull()) {
    return true;
  }
  return false;
}

/*!
 * \brief CompositeModelEditor::getSimulationStartTime
 * Gets the simulation start time.
 */
QString CompositeModelEditor::getSimulationStartTime()
{
  QDomElement simulationParamsElement = mXmlDocument.documentElement().firstChildElement("SimulationParams");
  return simulationParamsElement.attribute("StartTime");
}

/*!
 * \brief CompositeModelEditor::getSimulationStopTime
 * Gets the simulation stop time.
 */
QString CompositeModelEditor::getSimulationStopTime()
{
  QDomElement simulationParamsElement = mXmlDocument.documentElement().firstChildElement("SimulationParams");
  return simulationParamsElement.attribute("StopTime");
}
/*!
 * \brief CompositeModelEditor::addInterfacesData
 * Adds the InterfacePoint tag to SubModel.
 * \param interfaces
 */
void CompositeModelEditor::addInterfacesData(QDomElement interfaces, QDomElement parameters, QString singleModel)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    QDomElement interfaceDataElement = interfaces.firstChildElement();
    while (!interfaceDataElement.isNull()) {
      subModel = subModelList.at(i).toElement();
      if (subModel.attribute("Name").compare(interfaceDataElement.attribute("model")) == 0 &&
          (subModel.attribute("Name") == singleModel || singleModel.isEmpty())) {
        QDomElement interfacePoint;
        // update interface point
        if (existInterfacePoint(subModel.attribute("Name"), interfaceDataElement.attribute("Name"))) {
          interfacePoint = getInterfacePoint(subModel.attribute("Name"), interfaceDataElement.attribute("Name"));
          interfacePoint.setAttribute("Name", interfaceDataElement.attribute("Name"));
          interfacePoint.setAttribute("Position", interfaceDataElement.attribute("Position"));
          interfacePoint.setAttribute("Angle321", interfaceDataElement.attribute("Angle321"));
          interfacePoint.setAttribute("Dimensions", interfaceDataElement.attribute("Dimensions"));
          interfacePoint.setAttribute("Domain", interfaceDataElement.attribute("Domain"));
          interfacePoint.setAttribute("Causality", interfaceDataElement.attribute("Causality"));
          setPlainText(mXmlDocument.toString());
          // check if interface is aligned
          foreach (LineAnnotation* pConnectionLineAnnotation, mpModelWidget->getDiagramGraphicsView()->getConnectionsList()) {
            QString interfaceName = QString("%1.%2").arg(subModel.attribute("Name")).arg(interfaceDataElement.attribute("Name"));
            if (pConnectionLineAnnotation->getStartComponentName().compare(interfaceName) == 0 ||
                pConnectionLineAnnotation->getEndComponentName().compare(interfaceName) == 0) {
              bool aligned = interfacesAligned(pConnectionLineAnnotation->getStartComponentName(), pConnectionLineAnnotation->getEndComponentName());
              pConnectionLineAnnotation->setAligned(aligned);
            }
          }
        } else {  // insert interface point
          QDomElement interfacePoint = mXmlDocument.createElement("InterfacePoint");
          interfacePoint.setAttribute("Name", interfaceDataElement.attribute("Name"));
          interfacePoint.setAttribute("Position", interfaceDataElement.attribute("Position"));
          interfacePoint.setAttribute("Angle321", interfaceDataElement.attribute("Angle321"));
          interfacePoint.setAttribute("Dimensions", interfaceDataElement.attribute("Dimensions"));
          interfacePoint.setAttribute("Causality", interfaceDataElement.attribute("Causality"));
          interfacePoint.setAttribute("Domain", interfaceDataElement.attribute("Domain"));
          subModel.appendChild(interfacePoint);
          setPlainText(mXmlDocument.toString());
          Component *pComponent = mpModelWidget->getDiagramGraphicsView()->getComponentObject(subModel.attribute("Name"));
          if (pComponent) {
            pComponent->insertInterfacePoint(interfaceDataElement.attribute("Name"),
                                             interfaceDataElement.attribute("Position", "0,0,0"),
                                             interfaceDataElement.attribute("Angle321", "0,0,0"),
                                             interfaceDataElement.attribute("Dimensions", "3").toInt(),
                                             interfaceDataElement.attribute("Causality", StringHandler::getTLMCausality(StringHandler::TLMBidirectional)),
                                             interfaceDataElement.attribute("Domain", StringHandler::getTLMDomain(StringHandler::Mechanical)));
          }
        }
      }
      interfaceDataElement = interfaceDataElement.nextSiblingElement();
    }

    //Now remove all elements in sub model that does not exist in fetched interfaces (i.e. has been externally removed)
    subModel = subModelList.at(i).toElement();
    if(subModel.attribute("Name") != singleModel && !singleModel.isEmpty()){
        continue;   //Ignore other models if single model is specified
    }
    Component *pComponent = mpModelWidget->getDiagramGraphicsView()->getComponentObject(subModel.attribute("Name"));
    QDomElement subModelInterfaceDataElement = subModel.firstChildElement("InterfacePoint");
    while (!subModelInterfaceDataElement.isNull()) {
      bool interfaceExists = false;
      interfaceDataElement = interfaces.firstChildElement();
      while (!interfaceDataElement.isNull()) {
        if (subModelInterfaceDataElement.attribute("Name") == interfaceDataElement.attribute("Name") &&
            subModel.attribute("Name") == interfaceDataElement.attribute("model")) {
          interfaceExists = true;
        }
        interfaceDataElement = interfaceDataElement.nextSiblingElement();
      }
      if (!interfaceExists) {
        QDomElement elementToRemove = subModelInterfaceDataElement;
        subModelInterfaceDataElement = subModelInterfaceDataElement.nextSiblingElement("InterfacePoint");
        if (pComponent) {
          pComponent->removeInterfacePoint(elementToRemove.attribute("Name"));
        }
        subModel.removeChild(elementToRemove);
      }
      else {
        subModelInterfaceDataElement = subModelInterfaceDataElement.nextSiblingElement("InterfacePoint");
      }
    }

    //Add or update parameters
    QDomElement parameterDataElement = parameters.firstChildElement();
    while (!parameterDataElement.isNull()) {
      subModel = subModelList.at(i).toElement();
      if (subModel.attribute("Name").compare(parameterDataElement.attribute("model")) == 0 &&
          (subModel.attribute("Name") == singleModel || singleModel.isEmpty())) {
        QDomElement parameterPoint;
        // update parameter
        //Do nothing if parameter already exists (i.e. never overwrite values)
        if (!existParameter(subModel.attribute("Name"), parameterDataElement)) {  // insert parameter
          QDomElement parameterPoint = mXmlDocument.createElement("Parameter");
          parameterPoint.setAttribute("Name", parameterDataElement.attribute("Name"));
          parameterPoint.setAttribute("Value", parameterDataElement.attribute("DefaultValue"));
          subModel.appendChild(parameterPoint);
        }
      }
      parameterDataElement = parameterDataElement.nextSiblingElement();
    }

    //Remove all parameters in sub model that does not exist in fetched data (i.e. has been externally removed)
    subModel = subModelList.at(i).toElement();
    if(subModel.attribute("Name") != singleModel && !singleModel.isEmpty()){
      continue;   //Ignore other models if single model is specified
    }
    pComponent = mpModelWidget->getDiagramGraphicsView()->getComponentObject(subModel.attribute("Name"));
    QDomElement subModelParameterDataElement = subModel.firstChildElement("Parameter");
    while (!subModelParameterDataElement.isNull()) {
      bool parameterExists = false;
      parameterDataElement = parameters.firstChildElement();
      while (!parameterDataElement.isNull()) {
        if (subModelParameterDataElement.attribute("Name") == parameterDataElement.attribute("Name") &&
          subModel.attribute("Name") == parameterDataElement.attribute("model")) {
          parameterExists = true;
        }
        parameterDataElement = parameterDataElement.nextSiblingElement();
      }
      if (!parameterExists) {
        QDomElement elementToRemove = subModelParameterDataElement;
        subModelParameterDataElement = subModelParameterDataElement.nextSiblingElement("Parameter");
        subModel.removeChild(elementToRemove);
      }
      else {
        subModelParameterDataElement = subModelParameterDataElement.nextSiblingElement("Parameter");
      }
    }
  }

  //Remove connections between no longer existing elements
  QDomNodeList connectionsList = mXmlDocument.elementsByTagName("Connection");
  for (int i = 0 ; i < connectionsList.size() ; i++) {
    QDomElement connection = connectionsList.at(i).toElement();
    QString from = connection.attribute("From");
    QString to = connection.attribute("To");

    bool fromExists = false;
    bool toExists = false;
    for(int i = 0 ; i < subModelList.size() ; ++i) {
      QDomElement subModel = subModelList.at(i).toElement();
      QDomElement subModelInterfaceDataElement = subModel.firstChildElement("InterfacePoint");
      while (!subModelInterfaceDataElement.isNull()) {
        if (subModel.attribute("Name") == from.section(".",0,0) && subModelInterfaceDataElement.attribute("Name") == from.section(".",1,1)) {
          fromExists = true;
        }
        else if (subModel.attribute("Name") == to.section(".",0,0) && subModelInterfaceDataElement.attribute("Name") == to.section(".",1,1)) {
          toExists = true;
        }
        subModelInterfaceDataElement = subModelInterfaceDataElement.nextSiblingElement("InterfacePoint");
      }
    }
    if (!fromExists || !toExists) {
      foreach (LineAnnotation *pConnectionLineAnnotation, mpModelWidget->getDiagramGraphicsView()->getConnectionsList()) {
        if (pConnectionLineAnnotation->getStartComponentName().compare(from) == 0 ||
            pConnectionLineAnnotation->getEndComponentName().compare(to) == 0) {
          mpModelWidget->getDiagramGraphicsView()->deleteConnectionFromList(pConnectionLineAnnotation);
          mpModelWidget->getDiagramGraphicsView()->removeItem(pConnectionLineAnnotation);
          pConnectionLineAnnotation->deleteLater();
        }
      }
      connection.parentNode().removeChild(connection);
      --i;
    }
  }

  setPlainText(mXmlDocument.toString());
}

/*!
 * \brief CompositeModelEditor::addInterface
 * Adds the interface to submodel.
 * \param pInterfaceComponent
 * \param subModel
 */
void CompositeModelEditor::addInterface(Component *pInterfaceComponent, QString subModel)
{
  QDomElement subModelElement = getSubModelElement(subModel);
  QDomElement interfacePoint = mXmlDocument.createElement("InterfacePoint");
  interfacePoint.setAttribute("Name", pInterfaceComponent->getName());
  interfacePoint.setAttribute("Position", pInterfaceComponent->getComponentInfo()->getPosition());
  interfacePoint.setAttribute("Angle321", pInterfaceComponent->getComponentInfo()->getAngle321());
  interfacePoint.setAttribute("Dimensions", pInterfaceComponent->getComponentInfo()->getDimensions());
  interfacePoint.setAttribute("Causality", pInterfaceComponent->getComponentInfo()->getTLMCausality());
  interfacePoint.setAttribute("Domain", pInterfaceComponent->getComponentInfo()->getDomain());
  subModelElement.appendChild(interfacePoint);
  setPlainText(mXmlDocument.toString());
}

/*!
 * \brief CompositeModelEditor::interfacesAligned
 * Checkes whether specified TLM interfaces are aligned
 * \param interface1 First interface (submodel1.interface1)
 * \param interface2 Second interface (submodel2.interface2)
 * \return
 */
bool CompositeModelEditor::interfacesAligned(QString interface1, QString interface2)
{
  if(getInterfaceCausality(interface1) != StringHandler::getTLMCausality(StringHandler::TLMBidirectional)) {
    //Assume interface2 has same causality and dimensions, otherwise they could not be connected)
    return true;      //Alignment is not relevant for non-bidirectional connections
  }

  //Extract rotation and position vectors to Qt matrices
  QGenericMatrix<3,1,double> CG_X1_PHI_CG;  //Rotation of X1 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X1_C1_PHI_X1;  //Rotation of C1 relative to X1 expressed in X1
  QGenericMatrix<3,1,double> CG_X1_R_CG;      //Position of X1 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X1_C1_R_X1;      //Position of C1 relative to X1 expressed in X1
  if (!getPositionAndRotationVectors(interface1,CG_X1_PHI_CG, X1_C1_PHI_X1,CG_X1_R_CG,X1_C1_R_X1)) {
    return false;
  }

  QGenericMatrix<3,1,double> CG_X2_PHI_CG;  //Rotation of X2 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X2_C2_PHI_X2;  //Rotation of C2 relative to X2 expressed in X2
  QGenericMatrix<3,1,double> CG_X2_R_CG;      //Position of X2 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X2_C2_R_X2;      //Position of C2 relative to X2 expressed in X2

  if (!getPositionAndRotationVectors(interface2,CG_X2_PHI_CG, X2_C2_PHI_X2,CG_X2_R_CG,X2_C2_R_X2)) {
    return false;
  } else if(getInterfaceCausality(interface1) == StringHandler::getTLMCausality(StringHandler::TLMBidirectional) &&
            getInterfaceDimensions(interface1) == 1) {
    //Handle 1D- interfaces
    //Assume interface2 has same causality and dimensions, otherwise they could not be connected)
    //Only compare first element of interface position relative to external model,
    //the model orientation should not matter for 1D connections
    return fuzzyCompare(X1_C1_R_X1(0,0),X2_C2_R_X2(0,0));
  }

  QGenericMatrix<3,1,double> CG_C1_R_CG, CG_C1_PHI_CG, CG_C2_R_CG, CG_C2_PHI_CG;
  QGenericMatrix<3,3,double> R_X1_C1, R_CG_X1, R_CG_C1, R_X2_C2, R_CG_X2, R_CG_C2;

  //Compute rotation matrices for both interfaces relative to CG and make sure they are the same
  R_X1_C1 = Utilities::getRotationMatrix(X1_C1_PHI_X1);    //Rotation matrix between X1 and C1
  R_CG_X1 = Utilities::getRotationMatrix(CG_X1_PHI_CG);    //Rotation matrix between CG and X1
  R_CG_C1 = R_X1_C1*R_CG_X1;                       //Rotation matrix between CG and C1
  R_X2_C2 = Utilities::getRotationMatrix(X2_C2_PHI_X2);    //Rotation matrix between X2 and C2
  R_CG_X2 = Utilities::getRotationMatrix(CG_X2_PHI_CG);    //Rotation matrix between CG and X2
  R_CG_C2 = R_X2_C2*R_CG_X2;                       //Rotation matrix between CG and C2

  bool success=true;
  for (int i=0; i<3; ++i) {
    for (int j=0; j<3; ++j) {
      if (!fuzzyCompare(R_CG_C1(i,j),R_CG_C2(i,j))) {
        success=false;
      }
    }
  }

  //Compute positions for both interfaces relative to CG and make sure they are the same
  CG_C1_R_CG = CG_X1_R_CG + X1_C1_R_X1*R_CG_X1;   //Position of C1 relative to CG exressed in CG
  CG_C2_R_CG = CG_X2_R_CG + X2_C2_R_X2*R_CG_X2;   //Position of C2 relative to CG exressed in CG

  for (int i=0; i<3; ++i) {
    if (!fuzzyCompare(CG_C1_R_CG(0,i),CG_C2_R_CG(0,i))) {
      success=false;
    }
  }

  return success;
}

/*!
 * \brief CompositeModelEditor::deleteSubModel
 * Delets a SubModel.
 * \param name
 * \return
 */
bool CompositeModelEditor::deleteSubModel(QString name)
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
 * \brief CompositeModelEditor::deleteConnection
 * Delets a connection.
 * \param name
 * \return
 */
bool CompositeModelEditor::deleteConnection(QString startSubModelName, QString endSubModelName)
{
  QDomNodeList connectionList = mXmlDocument.elementsByTagName("Connection");
  for (int i = 0 ; i < connectionList.size() ; i++) {
    QDomElement connection = connectionList.at(i).toElement();
    QString startName = connection.attribute("From");
    QString endName = connection.attribute("To");
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
 * \brief CompositeModelEditor::existInterfacePoint
 * Checks whether the interface already exists in CompositeModel or not.
 * \param subModelName
 * \param interfaceName
 * \return
 */
bool CompositeModelEditor::existInterfacePoint(QString subModelName, QString interfaceName)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(subModelName) == 0) {
      QDomNodeList subModelChildren = subModel.childNodes();
      for (int j = 0 ; j < subModelChildren.size() ; j++) {
        QDomElement interfaceElement = subModelChildren.at(j).toElement();
        if (interfaceElement.tagName().compare("InterfacePoint") == 0 &&
            interfaceElement.attribute("Name").compare(interfaceName) == 0) {
          return true;
        }
      }
      break;
    }
  }
  return false;
}

bool CompositeModelEditor::existParameter(QString subModelName, QDomElement parameterDataElement)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(subModelName) == 0) {
      QDomNodeList subModelChildren = subModel.childNodes();
      for (int j = 0 ; j < subModelChildren.size() ; j++) {
        QDomElement parameterElement = subModelChildren.at(j).toElement();
        if (parameterElement.tagName().compare("Parameter") == 0 &&
            parameterElement.attribute("Name").compare(parameterDataElement.attribute("Name")) == 0) {
          return true;
        }
      }
      break;
    }
  }
  return false;
}

/*!
 * \brief CompositeModelEditor::getRotationVector
 * Computes a rotation vector (321) from a rotation matrix
 * \param R
 * \return
 */
QGenericMatrix<3,1,double> CompositeModelEditor::getRotationVector(QGenericMatrix<3,3,double> R)
{
  double a11 = R(0,0);
  double a12 = R(0,1);
  double a13 = R(0,2);
  double a23 = R(1,2);
  double a33 = R(2,2);

  double phi[3];
  phi[1] = (fabs(a13) < DBL_MIN)? 0.0 : asin((a13<-1.0) ? 1.0 : ((a13>1.0) ? -1.0 : -a13));
  double tmp = cos(phi[1]);
  double cosphi1 = tmp+sign(tmp)*1.0e-50;

  phi[0] = atan2(a23/cosphi1, a33/cosphi1);
  phi[2] = atan2(a12/cosphi1, a11/cosphi1);

  return QGenericMatrix<3,1,double>(phi);
}

void CompositeModelEditor::updateAllOrientations()
{
  QDomNodeList subModelList = getSubModels();
  for (int i=0; i<subModelList.size(); ++i) {
    QDomElement subModelElement = subModelList.at(i).toElement();
    GraphicsView *pView = mpModelWidget->getDiagramGraphicsView();
    QString modelName = subModelElement.attribute("Name");

    if(subModelElement.hasAttribute("Position") && subModelElement.hasAttribute("Angle321")) {
      Component *pComp = pView->getComponentObject(modelName);
      if(pComp) {
        pComp->getComponentInfo()->setPosition(subModelElement.attribute("Position"));
        pComp->getComponentInfo()->setAngle321(subModelElement.attribute("Angle321"));
      }
    }
  }
#if !defined(WITHOUT_OSG)
  mpModelWidget->getModelWidgetContainer()->updateThreeDViewer(mpModelWidget);
#endif
}

/*!
 * \brief CompositeModelEditor::getPositionAndRotationVectors
 * Extracts position and rotation vectors for specified TLM interface, both between CG and model X and between X and interface C
 * \param interfacePoint Interface on the form "submodel.interface"
 * \param CG_X_PHI_CG Rotation vector between CG abd X
 * \param X_C_PHI_X Rotation vector between X and C
 * \param CG_X_R_CG Position vector between CG and X
 * \param X_C_R_X Position vector between X and C
 * \return
 */
bool CompositeModelEditor::getPositionAndRotationVectors(QString interfacePoint, QGenericMatrix<3,1,double> &CG_X_PHI_CG,
                                                    QGenericMatrix<3,1,double> &X_C_PHI_X, QGenericMatrix<3,1,double> &CG_X_R_CG,
                                                    QGenericMatrix<3,1,double> &X_C_R_X)
{
  //Extract submodel and interface names
  QString modelName = interfacePoint.split(".").at(0);
  QString interfaceName = interfacePoint.split(".").at(1);
  //Read positions and rotations from XML
  QString x_c_r_x_str, x_c_phi_x_str;
  QString cg_x_phi_cg_str, cg_x_r_cg_str;
  QDomElement subModelElement = getSubModelElement(modelName);
  cg_x_r_cg_str = subModelElement.attribute("Position", "0,0,0");
  cg_x_phi_cg_str = subModelElement.attribute("Angle321", "0,0,0");
  QDomElement interfaceElement = subModelElement.firstChildElement("InterfacePoint");
  while (!interfaceElement.isNull()) {
    if (interfaceElement.attribute("Name").compare(interfaceName) == 0) {
      x_c_r_x_str = interfaceElement.attribute("Position");
      x_c_phi_x_str = interfaceElement.attribute("Angle321");
      break;
    }
    interfaceElement = interfaceElement.nextSiblingElement("InterfacePoint");
  }

  //Make sure that all vector strings are found in XML
  if (cg_x_phi_cg_str.isEmpty() || cg_x_r_cg_str.isEmpty() || x_c_r_x_str.isEmpty() || x_c_phi_x_str.isEmpty()) {
    QString msg = tr("Interface coordinates does not exist in xml");
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind,
                                                          Helper::errorLevel));
    return false;
  }

  //Convert from strings to arrays
  double cg_x_phi_cg[3],x_c_phi_x[3];
  double cg_x_r_cg[3],x_c_r_x[3];

  cg_x_phi_cg[0] = cg_x_phi_cg_str.split(",")[0].toDouble();
  cg_x_phi_cg[1] = cg_x_phi_cg_str.split(",")[1].toDouble();
  cg_x_phi_cg[2] = cg_x_phi_cg_str.split(",")[2].toDouble();

  x_c_phi_x[0] = x_c_phi_x_str.split(",")[0].toDouble();
  x_c_phi_x[1] = x_c_phi_x_str.split(",")[1].toDouble();
  x_c_phi_x[2] = x_c_phi_x_str.split(",")[2].toDouble();

  cg_x_r_cg[0] = cg_x_r_cg_str.split(",")[0].toDouble();
  cg_x_r_cg[1] = cg_x_r_cg_str.split(",")[1].toDouble();
  cg_x_r_cg[2] = cg_x_r_cg_str.split(",")[2].toDouble();

  x_c_r_x[0] = x_c_r_x_str.split(",")[0].toDouble();
  x_c_r_x[1] = x_c_r_x_str.split(",")[1].toDouble();
  x_c_r_x[2] = x_c_r_x_str.split(",")[2].toDouble();

  //Convert from arrays to Qt matrices
  CG_X_PHI_CG = QGenericMatrix<3,1,double>(cg_x_phi_cg);  //Rotation of X relative to CG expressed in CG
  X_C_PHI_X = QGenericMatrix<3,1,double>(x_c_phi_x);  //Rotation of C relative to X expressed in X
  CG_X_R_CG = QGenericMatrix<3,1,double>(cg_x_r_cg);      //Position of X1 relative to CG expressed in CG
  X_C_R_X = QGenericMatrix<3,1,double>(x_c_r_x);      //Position of C relative to X expressed in X

  return true;
}

/*!
 * \brief CompositeModelEditor::alignInterfaces
 * Aligns interface C1 in model X1 to interface C2 in model X2
 * \param fromSubModel Full name of first interfae (X1.C1)
 * \param toSubModel Full name of second interface (X2.C2)
 * \param showError
 */
void CompositeModelEditor::alignInterfaces(QString fromInterface, QString toInterface, bool showError)
{
  //Extract rotation and position vectors to Qt matrices
  QGenericMatrix<3,1,double> CG_X1_PHI_CG;  //Rotation of X1 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X1_C1_PHI_X1;  //Rotation of C1 relative to X1 expressed in X1
  QGenericMatrix<3,1,double> CG_X1_R_CG;      //Position of X1 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X1_C1_R_X1;      //Position of C1 relative to X1 expressed in X1
  if(!getPositionAndRotationVectors(fromInterface,CG_X1_PHI_CG, X1_C1_PHI_X1,CG_X1_R_CG,X1_C1_R_X1)) return;

  QGenericMatrix<3,1,double> CG_X2_PHI_CG;  //Rotation of X2 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X2_C2_PHI_X2;  //Rotation of C2 relative to X2 expressed in X2
  QGenericMatrix<3,1,double> CG_X2_R_CG;      //Position of X2 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X2_C2_R_X2;      //Position of C2 relative to X2 expressed in X2
  if(!getPositionAndRotationVectors(toInterface,CG_X2_PHI_CG, X2_C2_PHI_X2,CG_X2_R_CG,X2_C2_R_X2)) return;

  QGenericMatrix<3,3,double> R_X2_C2, R_CG_X1, R_CG_X2, R_CG_C2, R_X1_C1;

  //Equations from BEAST
  R_X2_C2 = Utilities::getRotationMatrix(X2_C2_PHI_X2);    //Rotation matrix between X2 and C2
  R_CG_X2 = Utilities::getRotationMatrix(CG_X2_PHI_CG);    //Rotation matrix between CG and X2
  R_CG_C2 = R_X2_C2*R_CG_X2;                       //Rotation matrix between CG and C2

  R_X1_C1 = Utilities::getRotationMatrix(X1_C1_PHI_X1);    //Rotation matrix between X1 and C1
  R_CG_X1 = R_X1_C1.transposed()*R_CG_C2;          //New rotation matrix between CG and X1

  //Extract angles from rotation matrix
  QGenericMatrix<3,1,double> CG_X1_PHI_CG_new = getRotationVector(R_CG_X1);
  //  CG_X1_PHI_CG(0,0) = atan2(R_CG_X1(2,1),R_CG_X1(2,2));
  //  CG_X1_PHI_CG(0,1) = atan2(-R_CG_X1(2,0),sqrt(R_CG_X1(2,1)*R_CG_X1(2,1) + R_CG_X1(2,2)*R_CG_X1(2,2)));
  //  CG_X1_PHI_CG(0,2) = atan2(R_CG_X1(1,0),R_CG_X1(0,0));

  //New position of X1 relative to CG
  QGenericMatrix<3,1,double> CG_X1_R_CG_new = CG_X2_R_CG + X2_C2_R_X2*R_CG_X2 - X1_C1_R_X1*R_CG_X1;

  // get the relevant connection
  LineAnnotation* pFoundConnectionLineAnnotation = 0;
  foreach (LineAnnotation* pConnectionLineAnnotation, mpModelWidget->getDiagramGraphicsView()->getConnectionsList()) {
    if (pConnectionLineAnnotation->getStartComponentName().compare(fromInterface) == 0 &&
        pConnectionLineAnnotation->getEndComponentName().compare(toInterface) == 0) {
      pFoundConnectionLineAnnotation = pConnectionLineAnnotation;
      break;
    }
  }
  // push the align interface to undo stack
  mpModelWidget->getUndoStack()->push(new AlignInterfacesCommand(this, fromInterface, toInterface, CG_X1_R_CG, CG_X1_PHI_CG, CG_X1_R_CG_new,
                                                                 CG_X1_PHI_CG_new, pFoundConnectionLineAnnotation));
  mpModelWidget->updateModelText();
  // Give error message if alignment failed
  if (!interfacesAligned(fromInterface, toInterface)) {
    if (showError) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0, tr("Alignment operation failed."),
                                                            Helper::scriptingKind, Helper::errorLevel));
    }
  }
}

/*!
 * \brief CompositeModelEditor::getInterfaceType
 * Returns the type of specified interface (e.g. "3D", "Input"...)
 * \param pConnectionLineAnnotation
 * \return
 */
int CompositeModelEditor::getInterfaceDimensions(QString interfacePoint)
{
  //Extract submodel and interface names
  QString modelName = interfacePoint.split(".").at(0);
  QString interfaceName = interfacePoint.split(".").at(1);

  QDomElement subModelElement = getSubModelElement(modelName);
  QDomElement interfaceElement = subModelElement.firstChildElement("InterfacePoint");
  while (!interfaceElement.isNull()) {
    if (interfaceElement.attribute("Name").compare(interfaceName) == 0) {
      return interfaceElement.attribute("Dimensions", "3").toInt();
    }
    interfaceElement = interfaceElement.nextSiblingElement("InterfacePoint");
  }
  return 3;    //Backwards compatibility
}

QString CompositeModelEditor::getInterfaceCausality(QString interfacePoint)
{
  //Extract submodel and interface names
  QString modelName = interfacePoint.split(".").at(0);
  QString interfaceName = interfacePoint.split(".").at(1);

  QDomElement subModelElement = getSubModelElement(modelName);
  QDomElement interfaceElement = subModelElement.firstChildElement("InterfacePoint");
  while (!interfaceElement.isNull()) {
    if (interfaceElement.attribute("Name").compare(interfaceName) == 0) {
      return interfaceElement.attribute("Causality", StringHandler::getTLMCausality(StringHandler::TLMBidirectional));
    }
    interfaceElement = interfaceElement.nextSiblingElement("InterfacePoint");
  }
  return StringHandler::getTLMCausality(StringHandler::TLMBidirectional);    //Backwards compatibility
}

/*!
 * \brief CompositeModelEditor::getInterfaceDomain
 * Returns the physical domain of specified interface (e.g. "Mechanical", "Hydraulic"...)
 * \param pConnectionLineAnnotation
 * \return
 */
QString CompositeModelEditor::getInterfaceDomain(QString interfacePoint)
{
  //Extract submodel and interface names
  QString modelName = interfacePoint.split(".").at(0);
  QString interfaceName = interfacePoint.split(".").at(1);

  QDomElement subModelElement = getSubModelElement(modelName);
  QDomElement interfaceElement = subModelElement.firstChildElement("InterfacePoint");
  while (!interfaceElement.isNull()) {
    if (interfaceElement.attribute("Name").compare(interfaceName) == 0) {
      //Default to mechanical for backwards compatibility
      return interfaceElement.attribute("Domain", StringHandler::getTLMDomain(StringHandler::Mechanical));
    }
    interfaceElement = interfaceElement.nextSiblingElement("InterfacePoint");
  }
  return StringHandler::getTLMDomain(StringHandler::Mechanical);    //Backwards compatibility
}

/*!
 * \brief CompositeModelEditor::fuzzyCompare
 * Special implementation of fuzzyCompare. Uses much larger tolerance than built-in qFuzzyCompare()
 * \param p1
 * \param p2
 * \return
 */
inline bool CompositeModelEditor::fuzzyCompare(double p1, double p2)
{
  //! @todo What tolerance should be used? This is just a random number that seemed to work for some reason.
  return (qAbs(p1 - p2) <= qMax(1e-4 * qMin(qAbs(p1), qAbs(p2)),1e-5));
}

/*!
 * \brief CompositeModelEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void CompositeModelEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = createStandardContextMenu();
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

/*!
 * \brief CompositeModelEditor::setPlainText
 * Reimplementation of QPlainTextEdit::setPlainText method.
 * Makes sure we dont update if the passed text is same.
 * \param text the string to set.
 * \param useInserText
 */
void CompositeModelEditor::setPlainText(const QString &text, bool useInserText)
{
  if (text != mpPlainTextEdit->toPlainText()) {
    mForceSetPlainText = true;
    mXmlDocument.setContent(text);
    updateAllOrientations();
    // use the text from mXmlDocument so that we can map error to line numbers. We don't care about users formatting in the file.
    if (!useInserText) {
      mpPlainTextEdit->setPlainText(mXmlDocument.toString());
    } else {
      QTextCursor textCursor (mpPlainTextEdit->document());
      textCursor.beginEditBlock();
      textCursor.select(QTextCursor::Document);
      textCursor.insertText(mXmlDocument.toString());
      textCursor.endEditBlock();
      mpPlainTextEdit->setTextCursor(textCursor);
    }
    mForceSetPlainText = false;
    mLastValidText = text;
  }
}

/*!
 * \brief CompositeModelEditor::contentsHasChanged
 * Slot activated when CompositeModelEditor's QTextDocument contentsChanged SIGNAL is raised.\n
 * Sets the model as modified so that user knows that his current CompositeModel is not saved.
 * \param position
 * \param charsRemoved
 * \param charsAdded
 */
void CompositeModelEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget->isVisible()) {
    if (charsRemoved == 0 && charsAdded == 0) {
      return;
    }
    /* if user is changing the read only file. */
    if (mpModelWidget->getLibraryTreeItem()->isReadOnly() && !mForceSetPlainText) {
      /* if user is changing the read-only class. */
      mpInfoBar->showMessage(tr("<b>Warning: </b>You are changing a read-only class."));
    } else {
      /* if user is changing, the normal file. */
      if (!mForceSetPlainText) {
        mpModelWidget->setWindowTitle(QString(mpModelWidget->getLibraryTreeItem()->getName()).append("*"));
        mpModelWidget->getLibraryTreeItem()->setIsSaved(false);
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(mpModelWidget->getLibraryTreeItem());
        mTextChanged = true;
      }
    }
  }
}

//! @class CompositeModelHighlighter
//! @brief A syntax highlighter for CompositeModelEditor.

//! Constructor
CompositeModelHighlighter::CompositeModelHighlighter(CompositeModelEditorPage *pCompositeModelEditorPage, QPlainTextEdit *pPlainTextEdit)
  : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpCompositeModelEditorPage = pCompositeModelEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void CompositeModelHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpCompositeModelEditorPage->getOptionsDialog()->getTextEditorPage()->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpCompositeModelEditorPage->getOptionsDialog()->getTextEditorPage()->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(mpCompositeModelEditorPage->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpCompositeModelEditorPage->getColor("Text"));
  mTagFormat.setForeground(mpCompositeModelEditorPage->getColor("Tag"));
  mElementFormat.setForeground(mpCompositeModelEditorPage->getColor("Element"));
  mCommentFormat.setForeground(mpCompositeModelEditorPage->getColor("Comment"));
  mQuotationFormat.setForeground(QColor(mpCompositeModelEditorPage->getColor("Quotes")));

  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);

  // CompositeModel Tags
  QStringList compositeModelTags;
  compositeModelTags << "<\\?"
                << "<"
                << "</"
                << "\\?>"
                << ">"
                << "/>";
  foreach (const QString &compositeModelTag, compositeModelTags) {
    rule.mPattern = QRegExp(compositeModelTag);
    rule.mFormat = mTagFormat;
    mHighlightingRules.append(rule);
  }

  // CompositeModel Elements
  QStringList elementPatterns;
  elementPatterns << "\\bxml\\b"
                  << "\\bModel\\b"
                  << "\\bAnnotations\\b"
                  << "\\bAnnotation\\b"
                  << "\\bSubModels\\b"
                  << "\\bSubModel\\b"
                  << "\\bInterfacePoint\\b"
                  << "\\bParameter\\b"
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

  // CompositeModel Comments
  mCommentStartExpression = QRegExp("<!--");
  mCommentEndExpression = QRegExp("-->");
}

/*!
  Highlights the multilines text.\n
  Quoted text.
  */
void CompositeModelHighlighter::highlightMultiLine(const QString &text)
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
void CompositeModelHighlighter::highlightBlock(const QString &text)
{
  /* Only highlight the text if user has enabled the syntax highlighting */
  if (!mpCompositeModelEditorPage->getOptionsDialog()->getTextEditorPage()->getSyntaxHighlightingGroupBox()->isChecked()) {
    return;
  }
  // set text block state
  setCurrentBlockState(0);
  setFormat(0, text.length(), mpCompositeModelEditorPage->getColor("Text"));
  foreach (const HighlightingRule &rule, mHighlightingRules) {
    QRegExp expression(rule.mPattern);
    int index = expression.indexIn(text);
    while (index >= 0) {
      int length = expression.matchedLength();
      setFormat(index, length, rule.mFormat);
      index = expression.indexIn(text, index + length);
    }
  }
  highlightMultiLine(text);
}

//! Slot activated whenever ModelicaEditor text settings changes.
void CompositeModelHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}
