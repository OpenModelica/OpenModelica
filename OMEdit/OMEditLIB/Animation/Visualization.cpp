/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#include "Visualization.h"

#include <cmath>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <exception>
#include <functional>
#include <limits>
#include <map>
#include <typeinfo>
#include <unordered_map>
#include <vector>

// Specializations required for std::map and std::unordered_map to work with const std::reference_wrapper as keys

template<typename T>
struct std::hash<const std::reference_wrapper<T>> {
  std::size_t operator()(const std::reference_wrapper<T>& ref) const {
    return reinterpret_cast<std::uintptr_t>(&ref.get());
  }
};

template<typename T>
struct std::less<const std::reference_wrapper<T>> {
  bool operator()(const std::reference_wrapper<T>& lhs, const std::reference_wrapper<T>& rhs) const {
    return &lhs.get() < &rhs.get();
  }
};

template<typename T>
struct std::equal_to<const std::reference_wrapper<T>> {
  bool operator()(const std::reference_wrapper<T>& lhs, const std::reference_wrapper<T>& rhs) const {
    return &lhs.get() == &rhs.get();
  }
};

OMVisualBase::OMVisualBase(VisualizationAbstract* visualization, const std::string& modelFile, const std::string& path)
  : _modelFile(modelFile),
    _path(path),
    _xmlFileName(assembleXMLFileName(modelFile, path)),
    _visualization(visualization),
    _shapes(),
    _vectors()
{
}

const std::string OMVisualBase::getModelFile() const
{
  return _modelFile;
}

const std::string OMVisualBase::getPath() const
{
  return _path;
}

const std::string OMVisualBase::getXMLFileName() const
{
  return _xmlFileName;
}

/*!
 * \brief OMVisualBase::getVisualizerObjects
 * get a container of AbstractVisualizerObject
 * \return all the visualizers
 */
std::vector<std::reference_wrapper<AbstractVisualizerObject>> OMVisualBase::getVisualizerObjects()
{
  std::vector<std::reference_wrapper<AbstractVisualizerObject>> visualizers;
  visualizers.reserve(_shapes.size() + _vectors.size());
  for (ShapeObject& shape : _shapes) {
    visualizers.push_back(shape);
  }
  for (VectorObject& vector : _vectors) {
    visualizers.push_back(vector);
  }
  return visualizers;
}

/*!
 * \brief OMVisualBase::getVisualizerObjectByIdx
 * get the AbstractVisualizerObject with the same visualizerIdx
 * \param the index of the visualizer
 * \return the selected visualizer
 */
AbstractVisualizerObject* OMVisualBase::getVisualizerObjectByIdx(const std::size_t visualizerIdx)
{
  std::vector<std::reference_wrapper<AbstractVisualizerObject>> visualizers = getVisualizerObjects();
  if (visualizerIdx < visualizers.size()) {
    return &visualizers.at(visualizerIdx).get();
  }
  return nullptr;
}

/*!
 * \brief OMVisualBase::getVisualizerObjectByID
 * get the AbstractVisualizerObject with the same visualizerID
 * \param the name of the visualizer
 * \return the selected visualizer
 */
AbstractVisualizerObject* OMVisualBase::getVisualizerObjectByID(const std::string& visualizerID)
{
  for (AbstractVisualizerObject& visualizer : getVisualizerObjects()) {
    if (visualizer._id == visualizerID) {
      return &visualizer;
    }
  }
  return nullptr;
}

/*!
 * \brief OMVisualBase::getVisualizerObjectIndexByID
 * get the index of the AbstractVisualizerObject with the same visualizerID
 * \param the name of the visualizer
 * \return the selected visualizer index
 */
int OMVisualBase::getVisualizerObjectIndexByID(const std::string& visualizerID)
{
  int i = 0;
  for (AbstractVisualizerObject& visualizer : getVisualizerObjects()) {
    if (visualizer._id == visualizerID) {
      return i;
    }
    i++;
  }
  return -1;
}

void OMVisualBase::updateVisualizer(const std::string& visualizerName, const bool changeMaterialProperties)
{
  updateVisualizer(getVisualizerObjectByID(visualizerName), changeMaterialProperties);
}

void OMVisualBase::modifyVisualizer(const std::string& visualizerName, const bool changeMaterialProperties)
{
  modifyVisualizer(getVisualizerObjectByID(visualizerName), changeMaterialProperties);
}

void OMVisualBase::updateVisualizer(AbstractVisualizerObject* visualizer, const bool changeMaterialProperties) {
  _visualization->getScene()->updateVisualizer(visualizer, changeMaterialProperties);
}

void OMVisualBase::modifyVisualizer(AbstractVisualizerObject* visualizer, const bool changeMaterialProperties) {
  _visualization->getScene()->modifyVisualizer(visualizer, changeMaterialProperties);
}

void OMVisualBase::updateVisualizer(AbstractVisualizerObject& visualizer, const bool changeMaterialProperties) {
  _visualization->getScene()->updateVisualizer(&visualizer, changeMaterialProperties);
}

void OMVisualBase::modifyVisualizer(AbstractVisualizerObject& visualizer, const bool changeMaterialProperties) {
  _visualization->getScene()->modifyVisualizer(&visualizer, changeMaterialProperties);
}

void OMVisualBase::initVisObjects()
{
  if (!fileExists(_xmlFileName)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          QString(QObject::tr("Could not find the visual XML file %1."))
                                                          .arg(_xmlFileName.c_str()),
                                                          Helper::scriptingKind, Helper::errorLevel));
    return;
  }

  QFile file(QString::fromStdString(_xmlFileName));
  if (!file.open(QIODevice::ReadOnly)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          QString(QObject::tr("Could not open the visual XML file %1."))
                                                          .arg(_xmlFileName.c_str()),
                                                          Helper::scriptingKind, Helper::errorLevel));
    return;
  }

  QByteArray buffer = file.readAll();
  file.close();

  rapidxml::xml_document<> xmlDoc;
  xmlDoc.parse<0>(buffer.data());

  rapidxml::xml_node<>* rootNode = xmlDoc.first_node();
  rapidxml::xml_node<>* expNode;

  for (rapidxml::xml_node<>* shapeNode = rootNode->first_node("shape"); shapeNode; shapeNode = shapeNode->next_sibling("shape"))
  {
    ShapeObject shape; // Create a new object for each node to ensure that all attributes are reset to default values

    expNode = shapeNode->first_node("ident")->first_node();
    shape._id = std::string(expNode->value());

    //std::cout<<"id "<<shape._id<<std::endl;

    expNode = shapeNode->first_node("T")->first_node();
    shape._T[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._T[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._T[2] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._T[3] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._T[4] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._T[5] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._T[6] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._T[7] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._T[8] = getVisualizerAttributeForNode(expNode);

    expNode = shapeNode->first_node("r")->first_node();
    shape._r[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._r[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._r[2] = getVisualizerAttributeForNode(expNode);

    expNode = shapeNode->first_node("color")->first_node();
    shape._color[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._color[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._color[2] = getVisualizerAttributeForNode(expNode);

    expNode = shapeNode->first_node("specCoeff")->first_node();
    shape._specCoeff = getVisualizerAttributeForNode(expNode);

    expNode = shapeNode->first_node("type")->first_node();
    if (!expNode) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                            QString(QObject::tr("The type of %1 is not supported right in the visxml file."))
                                                            .arg(shape._id.c_str()),
                                                            Helper::scriptingKind, Helper::errorLevel));
      continue;
    }
    shape._type = std::string(expNode->value());

    if (isCADFile(shape._type))
    {
      shape._fileName = extractCADFilename(shape._type);
      if (!fileExists(shape._fileName)) {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                              QString(QObject::tr("Could not find the file %1."))
                                                              .arg(shape._fileName.c_str()),
                                                              Helper::scriptingKind, Helper::errorLevel));
        continue;
      }

      if (isDXFFile(shape._fileName)) {
        shape._type = "DXF";
      } else if (isSTLFile(shape._fileName)) {
        shape._type = "STL";
      } else if (isOBJFile(shape._fileName)) {
        shape._type = "OBJ";
      } else if (is3DSFile(shape._fileName)) {
        shape._type = "3DS";
      }
    }

    //std::cout<<"type "<<shape._type<<std::endl;

    expNode = shapeNode->first_node("r_shape")->first_node();
    shape._rShape[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._rShape[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._rShape[2] = getVisualizerAttributeForNode(expNode);

    expNode = shapeNode->first_node("lengthDir")->first_node();
    shape._lDir[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._lDir[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._lDir[2] = getVisualizerAttributeForNode(expNode);

    expNode = shapeNode->first_node("widthDir")->first_node();
    shape._wDir[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._wDir[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    shape._wDir[2] = getVisualizerAttributeForNode(expNode);

    expNode = shapeNode->first_node("length")->first_node();
    shape._length = getVisualizerAttributeForNode(expNode);
    expNode = shapeNode->first_node("width")->first_node();
    shape._width = getVisualizerAttributeForNode(expNode);
    expNode = shapeNode->first_node("height")->first_node();
    shape._height = getVisualizerAttributeForNode(expNode);

    expNode = shapeNode->first_node("extra")->first_node();
    shape._extra = getVisualizerAttributeForNode(expNode);

    _shapes.push_back(shape);
  }

  for (rapidxml::xml_node<>* vectorNode = rootNode->first_node("vector"); vectorNode; vectorNode = vectorNode->next_sibling("vector"))
  {
    VectorObject vector; // Create a new object for each node to ensure that all attributes are reset to default values

    expNode = vectorNode->first_node("ident")->first_node();
    vector._id = std::string(expNode->value());

    //std::cout<<"id "<<vector._id<<std::endl;

    expNode = vectorNode->first_node("T")->first_node();
    vector._T[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._T[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._T[2] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._T[3] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._T[4] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._T[5] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._T[6] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._T[7] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._T[8] = getVisualizerAttributeForNode(expNode);

    expNode = vectorNode->first_node("r")->first_node();
    vector._r[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._r[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._r[2] = getVisualizerAttributeForNode(expNode);

    expNode = vectorNode->first_node("color")->first_node();
    vector._color[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._color[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._color[2] = getVisualizerAttributeForNode(expNode);

    expNode = vectorNode->first_node("specCoeff")->first_node();
    vector._specCoeff = getVisualizerAttributeForNode(expNode);

    expNode = vectorNode->first_node("coordinates")->first_node();
    vector._coords[0] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._coords[1] = getVisualizerAttributeForNode(expNode);
    expNode = expNode->next_sibling();
    vector._coords[2] = getVisualizerAttributeForNode(expNode);

    expNode = vectorNode->first_node("quantity")->first_node();
    vector._quantity = getVisualizerAttributeForNode(expNode);

    expNode = vectorNode->first_node("headAtOrigin")->first_node();
    vector._headAtOrigin = getVisualizerAttributeForNode(expNode);

    expNode = vectorNode->first_node("twoHeadedArrow")->first_node();
    vector._twoHeadedArrow = getVisualizerAttributeForNode(expNode);

    _vectors.push_back(vector);
  }
}

void OMVisualBase::setFmuVarRefInVisObjects()
{
  try
  {
    for (ShapeObject& shape : _shapes)
    {
      //std::cout<<"shape "<<shape._id <<std::endl;

      shape._T[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[0]);
      shape._T[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[1]);
      shape._T[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[2]);
      shape._T[3].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[3]);
      shape._T[4].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[4]);
      shape._T[5].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[5]);
      shape._T[6].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[6]);
      shape._T[7].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[7]);
      shape._T[8].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._T[8]);

      shape._r[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._r[0]);
      shape._r[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._r[1]);
      shape._r[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._r[2]);

      shape._color[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._color[0]);
      shape._color[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._color[1]);
      shape._color[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._color[2]);

      shape._specCoeff.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._specCoeff);

      shape._rShape[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._rShape[0]);
      shape._rShape[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._rShape[1]);
      shape._rShape[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._rShape[2]);

      shape._lDir[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._lDir[0]);
      shape._lDir[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._lDir[1]);
      shape._lDir[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._lDir[2]);

      shape._wDir[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._wDir[0]);
      shape._wDir[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._wDir[1]);
      shape._wDir[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._wDir[2]);

      shape._length.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._length);
      shape._width.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._width);
      shape._height.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._height);

      shape._extra.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(shape._extra);

      //shape.dumpVisualizerAttributes();
    }

    for (VectorObject& vector : _vectors)
    {
      //std::cout<<"vector "<<vector._id <<std::endl;

      vector._T[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[0]);
      vector._T[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[1]);
      vector._T[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[2]);
      vector._T[3].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[3]);
      vector._T[4].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[4]);
      vector._T[5].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[5]);
      vector._T[6].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[6]);
      vector._T[7].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[7]);
      vector._T[8].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._T[8]);

      vector._r[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._r[0]);
      vector._r[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._r[1]);
      vector._r[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._r[2]);

      vector._color[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._color[0]);
      vector._color[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._color[1]);
      vector._color[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._color[2]);

      vector._specCoeff.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._specCoeff);

      vector._coords[0].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._coords[0]);
      vector._coords[1].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._coords[1]);
      vector._coords[2].fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._coords[2]);

      vector._quantity.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._quantity);

      vector._headAtOrigin.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._headAtOrigin);

      vector._twoHeadedArrow.fmuValueRef = _visualization->getFmuVariableReferenceForVisualizerAttribute(vector._twoHeadedArrow);

      //vector.dumpVisualizerAttributes();
    }
  }
  catch (std::exception& ex)
  {
    QString msg = QString(QObject::tr("Something went wrong in OMVisualBase::setFmuVarRefInVisObjects:\n%1."))
                  .arg(ex.what());
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::errorLevel));
    throw(msg.toStdString());
  }
}

void OMVisualBase::updateVisObjects(const double time)
{
  // Update all visualizers
  //std::cout<<"updateVisObjects at "<<time <<std::endl;

  try
  {
    for (ShapeObject& shape : _shapes)
    {
      // Get the values for the scene graph objects
      //std::cout<<"shape "<<shape._id <<std::endl;

      _visualization->updateVisualizerAttribute(shape._T[0], time);
      _visualization->updateVisualizerAttribute(shape._T[1], time);
      _visualization->updateVisualizerAttribute(shape._T[2], time);
      _visualization->updateVisualizerAttribute(shape._T[3], time);
      _visualization->updateVisualizerAttribute(shape._T[4], time);
      _visualization->updateVisualizerAttribute(shape._T[5], time);
      _visualization->updateVisualizerAttribute(shape._T[6], time);
      _visualization->updateVisualizerAttribute(shape._T[7], time);
      _visualization->updateVisualizerAttribute(shape._T[8], time);

      _visualization->updateVisualizerAttribute(shape._r[0], time);
      _visualization->updateVisualizerAttribute(shape._r[1], time);
      _visualization->updateVisualizerAttribute(shape._r[2], time);

      _visualization->updateVisualizerAttribute(shape._color[0], time);
      _visualization->updateVisualizerAttribute(shape._color[1], time);
      _visualization->updateVisualizerAttribute(shape._color[2], time);

      _visualization->updateVisualizerAttribute(shape._specCoeff, time);

      _visualization->updateVisualizerAttribute(shape._rShape[0], time);
      _visualization->updateVisualizerAttribute(shape._rShape[1], time);
      _visualization->updateVisualizerAttribute(shape._rShape[2], time);

      _visualization->updateVisualizerAttribute(shape._lDir[0], time);
      _visualization->updateVisualizerAttribute(shape._lDir[1], time);
      _visualization->updateVisualizerAttribute(shape._lDir[2], time);

      _visualization->updateVisualizerAttribute(shape._wDir[0], time);
      _visualization->updateVisualizerAttribute(shape._wDir[1], time);
      _visualization->updateVisualizerAttribute(shape._wDir[2], time);

      _visualization->updateVisualizerAttribute(shape._length, time);
      _visualization->updateVisualizerAttribute(shape._width, time);
      _visualization->updateVisualizerAttribute(shape._height, time);

      _visualization->updateVisualizerAttribute(shape._extra, time);

      rAndT rT = rotateModelica2Scene(
          Mat3(shape._T[0].exp, shape._T[1].exp, shape._T[2].exp,
               shape._T[3].exp, shape._T[4].exp, shape._T[5].exp,
               shape._T[6].exp, shape._T[7].exp, shape._T[8].exp),
          Vec3(shape._r[0].exp, shape._r[1].exp, shape._r[2].exp),
          Vec3(shape._rShape[0].exp, shape._rShape[1].exp, shape._rShape[2].exp),
          Vec3(shape._lDir[0].exp, shape._lDir[1].exp, shape._lDir[2].exp),
          Vec3(shape._wDir[0].exp, shape._wDir[1].exp, shape._wDir[2].exp),
          shape._type);
      assemblePokeMatrix(shape._mat, rT._T, rT._r);

      // Update the shapes
      updateVisualizer(shape, true);
      //shape.dumpVisualizerAttributes();
    }

    for (VectorObject& vector : _vectors)
    {
      // Get the values for the scene graph objects
      //std::cout<<"vector "<<vector._id <<std::endl;

      _visualization->updateVisualizerAttribute(vector._T[0], time);
      _visualization->updateVisualizerAttribute(vector._T[1], time);
      _visualization->updateVisualizerAttribute(vector._T[2], time);
      _visualization->updateVisualizerAttribute(vector._T[3], time);
      _visualization->updateVisualizerAttribute(vector._T[4], time);
      _visualization->updateVisualizerAttribute(vector._T[5], time);
      _visualization->updateVisualizerAttribute(vector._T[6], time);
      _visualization->updateVisualizerAttribute(vector._T[7], time);
      _visualization->updateVisualizerAttribute(vector._T[8], time);

      _visualization->updateVisualizerAttribute(vector._r[0], time);
      _visualization->updateVisualizerAttribute(vector._r[1], time);
      _visualization->updateVisualizerAttribute(vector._r[2], time);

      _visualization->updateVisualizerAttribute(vector._color[0], time);
      _visualization->updateVisualizerAttribute(vector._color[1], time);
      _visualization->updateVisualizerAttribute(vector._color[2], time);

      _visualization->updateVisualizerAttribute(vector._specCoeff, time);

      _visualization->updateVisualizerAttribute(vector._coords[0], time);
      _visualization->updateVisualizerAttribute(vector._coords[1], time);
      _visualization->updateVisualizerAttribute(vector._coords[2], time);

      _visualization->updateVisualizerAttribute(vector._quantity, time);

      _visualization->updateVisualizerAttribute(vector._headAtOrigin, time);

      _visualization->updateVisualizerAttribute(vector._twoHeadedArrow, time);

      rAndT rT = rotateModelica2Scene(
          Mat3(vector._T[0].exp, vector._T[1].exp, vector._T[2].exp,
               vector._T[3].exp, vector._T[4].exp, vector._T[5].exp,
               vector._T[6].exp, vector._T[7].exp, vector._T[8].exp),
          Vec3(vector._r[0].exp, vector._r[1].exp, vector._r[2].exp),
          Vec3(vector._coords[0].exp, vector._coords[1].exp, vector._coords[2].exp));
      assemblePokeMatrix(vector._mat, rT._T, rT._r);

      // Update the vectors
      updateVisualizer(vector, true);
      //vector.dumpVisualizerAttributes();
    }
  }
  catch (std::exception& ex)
  {
    QString msg = QString(QObject::tr("Error in OMVisualBase::updateVisObjects at time point %1\n%2."))
                  .arg(QString::number(time), ex.what());
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, msg, Helper::scriptingKind, Helper::errorLevel));
    throw(msg.toStdString());
  }
}

void OMVisualBase::setUpScene()
{
  // Build scene graph
  _visualization->getScene()->setUpShapes(_shapes);
  _visualization->getScene()->setUpVectors(_vectors);
}

void OMVisualBase::updateVectorCoords(VectorObject& vector, const double time)
{
  _visualization->updateVisualizerAttribute(vector._coords[0], time);
  _visualization->updateVisualizerAttribute(vector._coords[1], time);
  _visualization->updateVisualizerAttribute(vector._coords[2], time);
}

/*!
 * \brief Adjust radius and length scaling of vector visualizers, independently.
 *        Framing the result is left to the viewer's fitToScene.
 */
void OMVisualBase::chooseVectorScales()
{
  if (_vectors.size() == 0) {
    return;
  }

  constexpr int8_t factorRadius = -10; // Vector radius vs. median of fixed radii [%]

  std::vector<std::reference_wrapper<VectorObject>> adjustableRadiusVectors;
  std::vector<float> radii;
  for (VectorObject& vector : _vectors) {
    if (vector.isRadiusAdjustable()) {
      adjustableRadiusVectors.push_back(vector);
    } else {
      const float radius = vector.getRadius();
      if (radius > 0) {
        radii.push_back(radius);
      }
    }
  }
  for (ShapeObject& shape : _shapes) {
    if (isCADType(shape._type)) {
      continue;
    }
    // For the world component, keep only the axis/gravity arrow lines
    if (shape._id.rfind("world.", 0) == 0 &&
        shape._id != "world.x_arrowLine" && shape._id != "world.y_arrowLine" &&
        shape._id != "world.z_arrowLine" && shape._id != "world.gravityArrowLine") {
      continue;
    }
    float radius = shape._width.exp / 2;
    if (shape._type == "sphere") {
      radius = shape._length.exp / 2;
    } else if (shape._type == "spring") {
      radius = shape._width.exp;
    }
    if (radius > 0) {
      radii.push_back(radius);
    }
  }
  if (!adjustableRadiusVectors.empty() && !radii.empty()) {
    const size_t s = radii.size();
    float median = radii[0];
    if (s > 1) {
      const auto beg = radii.begin();
      const auto mid = beg + s / 2;
      std::nth_element(beg, mid, radii.end());
      if (s & 1) {
        median = *mid;
      } else {
        const auto maxIt = std::max_element(beg, mid);
        median = *maxIt + (*mid - *maxIt) * 0.5f;
      }
    }
    const float scale = median / VectorObject::kRadius * (1.0f + factorRadius / 100.0f);
    for (VectorObject& vector : adjustableRadiusVectors) {
      vector.setRadiusScale(scale);
    }
  }

  /* Forces/torques are divided by their MSL reference so they render at a
     comparable size. */
  for (VectorObject& vector : _vectors) {
    if (vector.isLengthAdjustable()) {
      float scale = 1.0f;
      switch (vector.getQuantity()) {
        case VectorQuantity::force:
          scale /= VectorObject::kScaleForce;
          break;
        case VectorQuantity::torque:
          scale /= VectorObject::kScaleTorque;
          break;
        default:
          break;
      }
      vector.setLengthScale(scale);
    }
    updateVisualizer(vector); // rebuild the arrow at its new size
  }
}


///--------------------------------------------------///
///ABSTRACT VISUALIZATION CLASS----------------------///
///--------------------------------------------------///

VisualizationAbstract::VisualizationAbstract(const std::string& modelFile, const std::string& path, const VisType visType)
  : _visType(visType),
    mpOMVisualBase(new OMVisualBase(this, modelFile, path)),
    mpTimeManager(new TimeManager(0.0, 0.0, 0.0, 0.0, 0.016, 0.0, 1.0))
{
  // The Qt Quick 3D scene is injected by the viewer (setScene); path stored there.
  Q_UNUSED(path);
}

VisType VisualizationAbstract::getVisType() const
{
  return _visType;
}

AnimationScene* VisualizationAbstract::getScene() const
{
  return mpScene;
}

OMVisualBase* VisualizationAbstract::getBaseData() const
{
  return mpOMVisualBase;
}

TimeManager* VisualizationAbstract::getTimeManager() const
{
  return mpTimeManager;
}

void VisualizationAbstract::initData()
{
  getBaseData()->initVisObjects();
}

void VisualizationAbstract::setFmuVarRefInVisAttributes()
{
  getBaseData()->setFmuVarRefInVisObjects();
}

void VisualizationAbstract::initializeVisAttributes(const double time)
{
  getBaseData()->updateVisObjects(time);
}

void VisualizationAbstract::updateVisAttributes(const double time)
{
  getBaseData()->updateVisObjects(time);
}

void VisualizationAbstract::setUpScene()
{
  getBaseData()->setUpScene();
}

void VisualizationAbstract::sceneUpdate()
{
  // measure real time
  mpTimeManager->updateTick();
  // set next time step
  if (!mpTimeManager->isPaused()) {
    // finish animation with pause when end time is reached
    if (mpTimeManager->getVisTime() >= mpTimeManager->getEndTime()) {
      if (mpTimeManager->canRepeat()) {
        initVisualization();
        mpTimeManager->setPause(false);
      } else {
        mpTimeManager->setPause(true);
      }
    } else {
      // Advance by the real wall-clock time elapsed since the last frame (×speedUp)
      // instead of a fixed step, so when rendering can't keep up the playback skips
      // ahead and stays synced to real time rather than lagging behind.
      double newTime = mpTimeManager->getVisTime() + (mpTimeManager->getPlaybackDelta() * mpTimeManager->getSpeedUp());
      if (newTime <= mpTimeManager->getEndTime()) {
        mpTimeManager->setVisTime(newTime);
      } else {
        mpTimeManager->setVisTime(mpTimeManager->getEndTime());
      }
      // update scene
      updateScene(mpTimeManager->getVisTime());
    }
  }
}

void VisualizationAbstract::initVisualization()
{
  mpTimeManager->setPause(true);
  mpTimeManager->setRealTimeFactor(0.0);
  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  initializeVisAttributes(mpTimeManager->getVisTime());
}

void VisualizationAbstract::startVisualization()
{
  if (mpTimeManager->getVisTime() < mpTimeManager->getEndTime() - 1.e-6) {
    mpTimeManager->setPause(false);
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          QObject::tr("There is nothing left to visualize. Initialize the model first."),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
}

void VisualizationAbstract::pauseVisualization()
{
  mpTimeManager->setPause(true);
}


Vec3 Mat3mulV3(Mat3 M, Vec3 V)
{
  return Vec3(M[0] * V[0] + M[1] * V[1] + M[2] * V[2],
              M[3] * V[0] + M[4] * V[1] + M[5] * V[2],
              M[6] * V[0] + M[7] * V[1] + M[8] * V[2]);
}

Vec3 V3mulMat3(Vec3 V, Mat3 M)
{
  return Vec3(M[0] * V[0] + M[3] * V[1] + M[6] * V[2],
              M[1] * V[0] + M[4] * V[1] + M[7] * V[2],
              M[2] * V[0] + M[5] * V[1] + M[8] * V[2]);
}

Mat3 Mat3mulMat3(Mat3 M1, Mat3 M2)
{
  Mat3 M3;
  for (int i = 0; i < 3; ++i)
  {
    for (int j = 0; j < 3; ++j)
    {
      float x = 0.0;
      for (int k = 0; k < 3; ++k)
      {
        x = M1[i * 3 + k] * M2[k * 3 + j] + x;
      }
      M3[i * 3 + j] = x;
    }
  }

  return M3;
}

// Single-precision std::sqrt rather than QVector3D::length(), which uses a
// higher-precision hypot and diverges by ~1e-6.
static float vec3Length(const Vec3& v)
{
  return std::sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
}

Vec3 normalize(Vec3 vec)
{
  Vec3 vecOut;
  const float len = vec3Length(vec);
  if (len >= 100 * 1.e-15)
    vecOut = vec / len;
  else
    vecOut = vec / (100 * 1.e-15);
  return vecOut;
}

Vec3 cross(Vec3 vec1, Vec3 vec2)
{
  return Vec3(vec1[1] * vec2[2] - vec1[2] * vec2[1],
              vec1[2] * vec2[0] - vec1[0] * vec2[2],
              vec1[0] * vec2[1] - vec1[1] * vec2[0]);
}

Directions fixDirections(Vec3 lDir, Vec3 wDir)
{
  Directions dirs;
  Vec3 e_x;
  Vec3 e_y;

  //lengthDirection
  double abs_n_x = vec3Length(lDir);
  if (abs_n_x < 1e-10)
    e_x = Vec3(1, 0, 0);
  else
    e_x = lDir / abs_n_x;

  //widthDirection
  Vec3 n_z_aux = cross(e_x, wDir);
  Vec3 e_y_aux;
  if (QVector3D::dotProduct(n_z_aux, n_z_aux) > 1e-6)
    e_y_aux = wDir;
  else
  {
    if (fabs(e_x[0]) > 1e-6)
      e_y_aux = Vec3(0, 1, 0);
    else
      e_y_aux = Vec3(1, 0, 0);
  }
  e_y = cross(normalize(cross(e_x, e_y_aux)), e_x);

  dirs._lDir = e_x;
  dirs._wDir = e_y;
  return dirs;
}

void assemblePokeMatrix(Mat4& M, const Mat3& T, const Vec3& r)
{
  M(3, 3) = 1.0;
  for (int row = 0; row < 3; ++row)
  {
    M(3, row) = r[row];
    M(row, 3) = 0.0;
    for (int col = 0; col < 3; ++col)
      M(row, col) = T[row * 3 + col];
  }
}

rAndT rotateModelica2Scene(Mat3 T, Vec3 r, Vec3 r_shape, Vec3 lDir, Vec3 wDir, std::string type)
{
  rAndT res;

  Directions dirs = fixDirections(lDir, wDir);
  Vec3 hDir = cross(dirs._lDir, dirs._wDir);
  //std::cout << "lDir " << dirs._lDir[0] << ", " << dirs._lDir[1] << ", " << dirs._lDir[2] << std::endl;
  //std::cout << "wDir " << dirs._wDir[0] << ", " << dirs._wDir[1] << ", " << dirs._wDir[2] << std::endl;
  //std::cout << "hDir " <<       hDir[0] << ", " <<       hDir[1] << ", " <<       hDir[2] << std::endl;

  Mat3 T0;
  if (isCADType(type))
  {
    T0 = Mat3(dirs._lDir[0], dirs._lDir[1], dirs._lDir[2],
              dirs._wDir[0], dirs._wDir[1], dirs._wDir[2],
                    hDir[0],       hDir[1],       hDir[2]);
  } else {
    T0 = Mat3(dirs._wDir[0], dirs._wDir[1], dirs._wDir[2],
                    hDir[0],       hDir[1],       hDir[2],
              dirs._lDir[0], dirs._lDir[1], dirs._lDir[2]);
  }
  //std::cout << "T0 " << T0[0] << ", " << T0[1] << ", " << T0[2] << std::endl;
  //std::cout << "   " << T0[3] << ", " << T0[4] << ", " << T0[5] << std::endl;
  //std::cout << "   " << T0[6] << ", " << T0[7] << ", " << T0[8] << std::endl;

  res._r = V3mulMat3(r_shape, T) + r;
  res._T = Mat3mulMat3(T0, T);

  return res;
}

rAndT rotateModelica2Scene(Mat3 T, Vec3 r, Vec3 dir)
{
  rAndT res;

  // See https://math.stackexchange.com/a/413235
  int i = dir[0] ? 0 : dir[1] ? 1 : 2;
  int j = (i + 1) % 3;

  Vec3 lDir = dir;
  Vec3 wDir = Vec3();
  wDir[i] = -lDir[j];
  wDir[j] = +lDir[i];

  Directions dirs = fixDirections(lDir, wDir);
  Vec3 hDir = cross(dirs._lDir, dirs._wDir);
  //std::cout << "lDir " << dirs._lDir[0] << ", " << dirs._lDir[1] << ", " << dirs._lDir[2] << std::endl;
  //std::cout << "wDir " << dirs._wDir[0] << ", " << dirs._wDir[1] << ", " << dirs._wDir[2] << std::endl;
  //std::cout << "hDir " <<       hDir[0] << ", " <<       hDir[1] << ", " <<       hDir[2] << std::endl;

  Mat3 T0 = Mat3(dirs._wDir[0], dirs._wDir[1], dirs._wDir[2],
                       hDir[0],       hDir[1],       hDir[2],
                 dirs._lDir[0], dirs._lDir[1], dirs._lDir[2]);
  //std::cout << "T0 " << T0[0] << ", " << T0[1] << ", " << T0[2] << std::endl;
  //std::cout << "   " << T0[3] << ", " << T0[4] << ", " << T0[5] << std::endl;
  //std::cout << "   " << T0[6] << ", " << T0[7] << ", " << T0[8] << std::endl;

  res._r = r;
  res._T = Mat3mulMat3(T0, T);

  return res;
}
