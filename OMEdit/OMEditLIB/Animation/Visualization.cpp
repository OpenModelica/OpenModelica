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
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#include "Visualization.h"

#if (QT_VERSION < QT_VERSION_CHECK(5, 2, 0))
#include <QGLWidget>
#endif

#include <QOpenGLContext> // must be included before OSG headers
#include <osg/GL> // for having direct access to glClear()

#include <osg/Array>
#include <osg/Drawable>
#include <osg/Geometry>
#include <osg/Shape>
#include <osg/ShapeDrawable>
#include <osg/StateAttribute>
#include <osg/Texture2D>
#include <osgDB/Options>
#include <osgDB/ReadFile>
#include <osgGA/OrbitManipulator>
#include <osgUtil/CullVisitor>

#include <OpenThreads/ScopedLock>

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

// Definition required for static constexpr members being ODR-used

constexpr char VectorObject::kAutoScaleRenderBinName[];


OMVisualBase::OMVisualBase(VisualizationAbstract* visualization, const std::string& modelFile, const std::string& path)
  : _modelFile(modelFile),
    _path(path),
    _xmlFileName(assembleXMLFileName(modelFile, path)),
    _updateVisitor(),
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
  int visualizerIdx = getVisualizerObjectIndexByID(visualizerName);
  AbstractVisualizerObject* visualizer = getVisualizerObjectByID(visualizerName);
  osg::ref_ptr<osg::Node> child = _visualization->getOMVisScene()->getScene().getRootNode()->getChild(visualizerIdx);
  _updateVisitor._visualizer = visualizer;
  _updateVisitor._changeMaterialProperties = changeMaterialProperties;
  child->accept(_updateVisitor);
}

void OMVisualBase::modifyVisualizer(const std::string& visualizerName, const bool changeMaterialProperties)
{
  int visualizerIdx = getVisualizerObjectIndexByID(visualizerName);
  AbstractVisualizerObject* visualizer = getVisualizerObjectByID(visualizerName);
  osg::ref_ptr<osg::Node> child = _visualization->getOMVisScene()->getScene().getRootNode()->getChild(visualizerIdx);
  _updateVisitor._visualizer = visualizer;
  _updateVisitor._changeMaterialProperties = changeMaterialProperties;
  visualizer->setStateSetAction(StateSetAction::modify);
  child->accept(_updateVisitor);
  visualizer->setStateSetAction(StateSetAction::update);
}

void OMVisualBase::updateVisualizer(AbstractVisualizerObject* visualizer, const bool changeMaterialProperties) {
  _updateVisitor._visualizer = visualizer;
  _updateVisitor._changeMaterialProperties = changeMaterialProperties;
  visualizer->getTransformNode()->accept(_updateVisitor);
}

void OMVisualBase::modifyVisualizer(AbstractVisualizerObject* visualizer, const bool changeMaterialProperties) {
  _updateVisitor._visualizer = visualizer;
  _updateVisitor._changeMaterialProperties = changeMaterialProperties;
  visualizer->setStateSetAction(StateSetAction::modify);
  visualizer->getTransformNode()->accept(_updateVisitor);
  visualizer->setStateSetAction(StateSetAction::update);
}

void OMVisualBase::updateVisualizer(AbstractVisualizerObject& visualizer, const bool changeMaterialProperties) {
  _updateVisitor._visualizer = &visualizer;
  _updateVisitor._changeMaterialProperties = changeMaterialProperties;
  visualizer.getTransformNode()->accept(_updateVisitor);
}

void OMVisualBase::modifyVisualizer(AbstractVisualizerObject& visualizer, const bool changeMaterialProperties) {
  _updateVisitor._visualizer = &visualizer;
  _updateVisitor._changeMaterialProperties = changeMaterialProperties;
  visualizer.setStateSetAction(StateSetAction::modify);
  visualizer.getTransformNode()->accept(_updateVisitor);
  visualizer.setStateSetAction(StateSetAction::update);
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

      rAndT rT = rotateModelica2OSG(
          osg::Matrix3(shape._T[0].exp, shape._T[1].exp, shape._T[2].exp,
                       shape._T[3].exp, shape._T[4].exp, shape._T[5].exp,
                       shape._T[6].exp, shape._T[7].exp, shape._T[8].exp),
          osg::Vec3f(shape._r[0].exp, shape._r[1].exp, shape._r[2].exp),
          osg::Vec3f(shape._rShape[0].exp, shape._rShape[1].exp, shape._rShape[2].exp),
          osg::Vec3f(shape._lDir[0].exp, shape._lDir[1].exp, shape._lDir[2].exp),
          osg::Vec3f(shape._wDir[0].exp, shape._wDir[1].exp, shape._wDir[2].exp),
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

      rAndT rT = rotateModelica2OSG(
          osg::Matrix3(vector._T[0].exp, vector._T[1].exp, vector._T[2].exp,
                       vector._T[3].exp, vector._T[4].exp, vector._T[5].exp,
                       vector._T[6].exp, vector._T[7].exp, vector._T[8].exp),
          osg::Vec3f(vector._r[0].exp, vector._r[1].exp, vector._r[2].exp),
          osg::Vec3f(vector._coords[0].exp, vector._coords[1].exp, vector._coords[2].exp));
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
  _visualization->getOMVisScene()->getScene().setUpScene(_shapes);
  _visualization->getOMVisScene()->getScene().setUpScene(_vectors);
}

void OMVisualBase::updateVectorCoords(VectorObject& vector, const double time)
{
  _visualization->updateVisualizerAttribute(vector._coords[0], time);
  _visualization->updateVisualizerAttribute(vector._coords[1], time);
  _visualization->updateVisualizerAttribute(vector._coords[2], time);
}

/*!
 * \brief   Adjust scaling of vector visualizers.
 * \details Choose suitable scales for the radius and the length of vector visualizers.
 *          Scaling is completely decoupled for radius and length.
 *          Only adjustable-radius vectors will have their radius adjusted, as well as
 *          only adjustable-length vectors will have their length adjusted.
 *          <hr>
 *          Adjustment of the radius scale is implemented as a heuristic
 *          that makes the radius of adjustable-radius vectors
 *          equal to the median value of
 *          - the radii of fixed-radius vectors and
 *          - the radii of relevant shapes,
 *          plus or minus some constant factor (default: -10%).
 *          <hr>
 *          Adjustment of the length scale is implemented as a heuristic
 *          that adjusts the length of adjustable-length vectors
 *          for each vector quantity independently
 *          (all adjustable-length vectors of the same vector quantity
 *          will see their length scaled with the same factor for consistent comparison)
 *          by performing a binary search (dichotomy), the aim of which is to
 *          increase the lengths as much as possible for vectors to be clearly visible,
 *          while ensuring that the following two constraints are satisfied,
 *          the first one having priority over the second one:
 *          - the vector lengths must be greater than that of their respective heads,
 *            plus or minus some constant margin (default: +10%),
 *            so that all the shaft lengths are guaranteed to be greater than zero;
 *          - the final camera distance to the focal center must not be greater than
 *            the initial distance obtained without drawing adjustable-length vectors,
 *            plus or minus some constant margin (default: +10%),
 *            so that the model size (and thus its first appearance) remains similar.
 *          The model size is computed from the bounding spheres of all the nodes in the model,
 *          and the home position of the camera is defined as a function of the model size.
 *          <hr>
 *          Hence, scaling vectors can be seen like scaling bounding spheres, and this explains why
 *          the radius is scaled before the length as it affects the bounding sphere of the vector.
 *          <hr>
 *          Time-varying vector lengths can be handled to some extent and are accounted for by
 *          sampling the simulation interval with a constant number of time samples (default: 100),
 *          a value of zero meaning that the criterion on the vector lengths is disregarded.
 *          Similarly, the check for the camera distance can be constantly enabled (default: true),
 *          and the heuristic no longer attempts to increase the lengths if the check is disabled,
 *          unless this is required by the first constraint when the latter is enabled.
 *          <hr>
 *          In order to avoid excessive length scales resulting from the first constraint,
 *          which may typically happen when vectors of the same quantity span different
 *          orders of magnitude and would be rendered with hardly comparable lengths,
 *          the definition of the vector length can be altered somewhat
 *          so as to measure either the shaft or the entire arrow.
 *          To this end, the counting up to the apex can be constantly enabled (default: true).
 *          When disabled, whether the vector is one- or two-headed, only the shaft length counts.
 *          <hr>
 *          During the binary search, floating-point numbers are treated as integer bit patterns,
 *          thus considering quantities as if they were given in units in the last place (ULP).
 *          This allows to stop the search when a constant precision is reached (default: 4096ulp)
 *          instead of doing comparisons between numbers with a constant floating-point tolerance.
 *          The value of the length scale is technically bounded from zero to infinity, and
 *          the initial guess for the search is chosen as the default value provided by the MSL.
 *          Since this is expected to be a good initial guess in general, for faster convergence
 *          the search can be reduced to a smaller interval (initial minimum and maximum bounds).
 *          However, those bounds shall be moved if the optimal value ends up being outside.
 *          For this purpose, a moving horizon can be constantly enabled (default: true)
 *          which automatically adapts the bounds such that, starting from an empty interval,
 *          the search continues either below or above the current value,
 *          shifting the bounds towards a constant horizon (default: 16777216ulp)
 *          that is either subtracted from or added to the current value.
 *          Whenever it moves, the default horizon has the effect of halving or doubling the value.
 *          <hr>
 *          After all length scales are adjusted, depending on the activated settings and margins,
 *          it is possible that the final camera distance is too big for the interesting parts of
 *          the model to be seen well enough, in which case it may be desirable to reject it and
 *          to render the scene using the initial camera distance even if this implies that
 *          the model cannot be seen entirely, meaning, some vectors cannot be compared.
 *          The tolerable zoom-out can be limited by adding some constant factor (default: 100%)
 *          above which the home position is reset, as if adjustable-length vectors were not drawn.
 * \note    For displaying a message to the user or for debugging purposes,
 *          MessagesWidget::addPendingMessage() shall be used instead of
 *          MessagesWidget::addGUIMessage() when \p mutex is locked.
 * \param[in] view OSG view of the scene composed of at least one camera.
 * \param[in] mutex OT mutex for synchronization of frame rendering.
 * \param[in] frame VW frame function to trigger frame rendering.
 */
void OMVisualBase::chooseVectorScales(osgViewer::View* view, OpenThreads::Mutex* mutex, std::function<void()> frame)
{
  /* Return early if there is nothing to do */
  if (view == nullptr || _vectors.size() == 0) {
    return;
  }

  /* Constants to be tuned for well-performing heuristics */
  constexpr int8_t factorRadius   = -10; // Factor for vector radius greater than median of fixed radii in percent [%]
  constexpr int8_t marginLength   = +10; // Margin for vector length greater than length of its head(s) in percent [%]
  constexpr int8_t marginDistance = +10; // Margin for home distance greater than initial home distance in percent [%]
  constexpr int8_t factorDistance = 100; // Factor for limiting final zoom-out of initial home distance in percent [%]
  constexpr uint32_t timeSamples = 100;  // Number of time samples to be inspected for vector length {32b}
  constexpr bool countUpToApex = true;   // Whether head(s) length shall be counted in vector length {0,1}
  constexpr bool checkDistance = true;   // Whether camera distance to focal center shall be checked {0,1}
  constexpr bool movingHorizon = true;   // Is moving horizon in units in the last place {0,1}
  constexpr uint32_t hulp = 0x01000000;  // Move this horizon in units in the last place [ulp]
  constexpr uint32_t pulp = 0x00001000;  // Minimum precision in units in the last place [ulp]

  /* Cancel out transform scales before adjustments begin */
  OpenThreads::ScopedPointerLock<OpenThreads::Mutex> lock(mutex); // Wait for any previous frame to complete rendering, and lock until adjustments are finished
  for (VectorObject& vector : _vectors) {
    vector.setAutoScaleCancellationRequired(true);
  }
  if (!frame) frame = std::bind(&osgViewer::ViewerBase::frame, view->getViewerBase(), USE_REFERENCE_TIME);
  frame(); // Work-around for osg::AutoTransform::computeBound() (see OSG commits 25abad8 & 92092a5 & 5c48904)

  /* Adjustable-radius vectors */
  {
    // Initialize containers of relevant shapes as well as fixed- and adjustable-radius vectors
    std::vector<ShapeObject>& relevantShapes = _shapes;
    std::vector<std::reference_wrapper<VectorObject>> fixedRadiusVectors;
    std::vector<std::reference_wrapper<VectorObject>> adjustableRadiusVectors;
    for (VectorObject& vector : _vectors) {
      if (vector.isRadiusAdjustable()) {
        adjustableRadiusVectors.push_back(vector);
      } else {
        fixedRadiusVectors.push_back(vector);
      }
    }

    // Proceed with scaling adjustable-radius vectors
    if (adjustableRadiusVectors.size() > 0) {
      float scale = 1;

      // Browse radii only if there are any fixed-radius vectors or relevant shapes
      if (fixedRadiusVectors.size() > 0 || relevantShapes.size() > 0) {
        std::vector<float> radii;

        // Store the radius of fixed-radius vectors
        for (VectorObject& vector : fixedRadiusVectors) {
          const float radius = vector.getRadius();

          // Take into account visible vectors only
          if (radius > 0) {
            radii.push_back(radius);
          }
        }

        // Store the radius of relevant shapes
        for (ShapeObject& shape : relevantShapes) {
          // Consider OSG shape drawables only
          if (isCADType(shape._type)) {
            continue;
          }

          // For the world component, discard axis labels and arrow heads
          if (shape._id.rfind("world.", 0) == 0) {
            if (shape._id.compare("world.x_arrowLine") != 0 &&
                shape._id.compare("world.y_arrowLine") != 0 &&
                shape._id.compare("world.z_arrowLine") != 0 &&
                shape._id.compare("world.gravityArrowLine") != 0) {
              continue;
            }
          }

          // Take the main dimension orthogonal to the principal direction
          float radius = shape._width.exp / 2;
          if (shape._type == "sphere") {
            radius = shape._length.exp / 2;
          } else if (shape._type == "spring") {
            radius = shape._width.exp;
          }

          // Take into account visible shapes only
          if (radius > 0) {
            radii.push_back(radius);
          }
        }

        // Compute the median of the radii (see https://stackoverflow.com/a/34077478)
        const size_t s = radii.size();
        if (s > 0) {
          float median = radii[0];
          if (s > 1) {
            const size_t n = s / 2;
            const std::vector<float>::iterator beg = radii.begin();
            const std::vector<float>::iterator end = radii.end();
            const std::vector<float>::iterator mid = beg + n;
            std::nth_element(beg, mid, end);
            if (s & 1) { // Odd-sized container
              median = *mid;
            } else { // Even-sized container
              // Following statement is equivalent to, but on average faster than:
              // const std::vector<float>::iterator max = beg;
              // std::nth_element(beg, max, mid, std::greater<float>{});
              const std::vector<float>::iterator max = std::max_element(beg, mid);
              // Average of left & right middle values (avoid overflow)
              median = *max + (*mid - *max) * .5f;
            }
          }

          // Scale the default radius
          scale = median / VectorObject::kRadius * (1.f + factorRadius / 100.f);
        }
      }

      // Apply the radius scale to all adjustable-radius vectors
      for (VectorObject& vector : adjustableRadiusVectors) {
        vector.setRadiusScale(scale);
        updateVisualizer(vector);
      }

      // Recompute the home position
      view->home();
    }
  }

  /* Adjustable-length vectors */
  {
    // Initialize a container of adjustable-length vectors
    std::vector<std::reference_wrapper<VectorObject>> adjustableLengthVectors;
    for (VectorObject& vector : _vectors) {
      if (vector.isLengthAdjustable()) {
        adjustableLengthVectors.push_back(vector);
      }
    }

    // Proceed with scaling adjustable-length vectors
    if (adjustableLengthVectors.size() > 0) {
      // Compute the time increment used to sample between the beginning and the end of the simulation
      const double timeStart = _visualization->getTimeManager()->getStartTime();
      const double timeStop  = _visualization->getTimeManager()->getEndTime();
      const double timeIncrement = timeSamples > 1 ? (timeStop - timeStart) / (timeSamples - 1) : 0;

      // Initialize a map of numbers of time samples, one for each adjustable-length vector
      std::unordered_map<const std::reference_wrapper<VectorObject>, uint32_t> numberOfSamples;
      for (VectorObject& vector : adjustableLengthVectors) {
        numberOfSamples[vector] = timeSamples > 0 && (timeIncrement <= 0 || vector.areCoordinatesConstant()) ? 1 : timeSamples;
      }

      // Store whether only the shaft length is counted for all adjustable-length vectors
      for (VectorObject& vector : adjustableLengthVectors) {
        vector.setOnlyShaftLengthCounted(!countUpToApex);
      }

      // Update the bounds of the whole scene without any adjustable-length vectors
      for (VectorObject& vector : adjustableLengthVectors) {
        vector.setInvisible();
        updateVisualizer(vector);
      }

      // Get the initial camera distance to the focal center
      view->home();
      const osgGA::OrbitManipulator* manipulator = static_cast<osgGA::OrbitManipulator*>(view->getCameraManipulator());
      const double initialDistance = manipulator->getDistance();

      // Initialize a map of adjustable-length vectors paired with their length scale, and grouped by their respective quantity
      std::map<const VectorQuantity, std::pair<float, std::vector<std::reference_wrapper<VectorObject>>>> data;
      for (VectorQuantity quantity = VectorQuantity::BEGIN; quantity != VectorQuantity::END; ++quantity) {
        float scale = 1;
        switch (quantity) {
          case VectorQuantity::force:
            scale /= VectorObject::kScaleForce;
            break;
          case VectorQuantity::torque:
            scale /= VectorObject::kScaleTorque;
            break;
          default:
            break;
        }
        for (VectorObject& vector : adjustableLengthVectors) {
          if (vector.getQuantity() == quantity) {
            data[quantity].first = scale;
            data[quantity].second.push_back(vector);
          }
        }
      }

      // Iterate over each quantity separately to adjust the related length scale
      for (std::pair<const VectorQuantity, std::pair<float, std::vector<std::reference_wrapper<VectorObject>>>>& pair : data) {
        float& scale = pair.second.first;
        std::vector<std::reference_wrapper<VectorObject>>& vectors = pair.second.second;

        // Make the vectors of the current quantity visible again
        // (the update is not necessary here because it is done inside and after the while loop in any case)
        for (VectorObject& vector : vectors) {
          vector.setVisible();
        }

        // Adjust the length scale for the current quantity as long as the criteria have not been met
        constexpr size_t fbytes = sizeof(float);
        constexpr size_t ubytes = sizeof(uint32_t);
        constexpr size_t bytes = std::min(fbytes, ubytes);
        constexpr float fmin = 0.f;
        constexpr float fmax = std::numeric_limits<float>::max();
        const     float fval = scale;
        uint32_t umin = 0;
        uint32_t umax = 0;
        uint32_t uval = 0;
        memcpy(&umin, &fmin, bytes);
        memcpy(&umax, &fmax, bytes);
        memcpy(&uval, &fval, bytes);
        uint32_t min = umin;
        uint32_t max = umax;
        uint32_t val = uval;
        bool isMinBelowLimit = false;
        bool isMaxAboveLimit = false;
        bool movedMinAlready = false;
        bool movedMaxAlready = false;
        bool squeezedTooMuch = false;
        bool unzoomedTooMuch = false;
        bool fulfilledWishes = false;
        while (!fulfilledWishes) {
          memset(&scale, 0x0, fbytes);
          memcpy(&scale, &val, bytes);

          // Apply the new length scale to the vectors of the current quantity
          for (VectorObject& vector : vectors) {
            vector.setLengthScale(scale);
            updateVisualizer(vector);
          }

          // Get the new camera distance to the focal center
          view->home();
          const double distance = manipulator->getDistance();

          // Determine if the new length scale has squeezed the vectors too much or unzoomed the scene too much
          squeezedTooMuch = false;
          if (timeSamples > 0) {
            for (VectorObject& vector : vectors) {
              float x, y, z;
              vector.getCoordinates(&x, &y, &z);
              const uint32_t samples = numberOfSamples[vector];
              for (uint32_t s = 0; s < samples; s++) {
                if (samples > 1) {
                  updateVectorCoords(vector, s + 1 == samples ? timeStop : timeStart + timeIncrement * s);
                }
                const float length = vector.getLength();
                if (length > 0 && length < vector.getHeadLength() * ((countUpToApex ? vector.isTwoHeadedArrow() ? 1.5f : 1.f : 0.f) + marginLength / 100.f)) {
                  squeezedTooMuch = true;
                  break;
                }
              }
              vector.setCoordinates(x, y, z);
              if (squeezedTooMuch) {
                break;
              }
            }
          }
          unzoomedTooMuch = checkDistance && distance > initialDistance * (1.f + marginDistance / 100.f);

          // Perform a floating-point binary search,
          // assuming non-negative as well as non-NaN values,
          // and interpreting the (assumed) IEEE 754 standard-compliant
          // floating-point numbers (see https://en.wikipedia.org/wiki/IEEE_754)
          // as integer bit patterns (see https://stackoverflow.com/questions/44991042),
          // i.e., using ULP arithmetic (see https://en.wikipedia.org/wiki/Unit_in_the_last_place).
          // For the sake of simplicity, the compiler is let optimize some of the operations and comparisons below.
          // Binary search is a synonym for dichotomy or bisection method (see https://en.wikipedia.org/wiki/Bisection_method).
          fulfilledWishes = true;
          if (!squeezedTooMuch && unzoomedTooMuch) {
            // Move binary search to lower half (floored)
            isMaxAboveLimit = unzoomedTooMuch;
            movedMaxAlready = true;
            if (movingHorizon && !movedMinAlready) {
              min = umax - umin > hulp && val > umin + hulp ? val - hulp : umin;
            }
            if (val > min) {
              max = val;
              if (max - min > pulp || !isMinBelowLimit) {
                val = max - min <= pulp ? min : min + ((max - min) >> 1);
                fulfilledWishes = false;
              }
            }
          } else if (checkDistance || squeezedTooMuch) {
            // Move binary search to higher half (ceiled)
            isMinBelowLimit = squeezedTooMuch;
            movedMinAlready = true;
            if (movingHorizon && !movedMaxAlready) {
              max = umax - umin > hulp && val < umax - hulp ? val + hulp : umax;
            }
            if (val < max) {
              min = val;
              if (max - min > pulp || !isMaxAboveLimit || isMinBelowLimit) {
                val = max - min <= pulp ? max : min + ((max - min + 1) >> 1);
                fulfilledWishes = false;
              }
            }
          }
        }

        // Make the vectors of the current quantity invisible again
        // (until all length scales have been carefully adjusted)
        for (VectorObject& vector : vectors) {
          vector.setInvisible();
          updateVisualizer(vector);
        }
      }

      // Update the bounds of the whole scene with all adjustable-length vectors using their adjusted length scales
      for (VectorObject& vector : adjustableLengthVectors) {
        vector.setVisible();
        updateVisualizer(vector);
      }

      // Get the final camera distance to the focal center
      view->home();
      const double finalDistance = manipulator->getDistance();

      // Check if the adjusted length scales have unzoomed the scene too much
      if (finalDistance > initialDistance * (1.f + factorDistance / 100.f)) {
        // Inform that the home position will be reset
        MessagesWidget::instance()->addPendingMessage(MessageItem(MessageItem::Modelica,
                                                                  GUIMessages::getMessage(GUIMessages::VISUALIZATION_VECTORS_SCALING_ZOOMED_OUT_SCENE_TOO_MUCH),
                                                                  Helper::scriptingKind,
                                                                  Helper::warningLevel));

        // Make all adjustable-length vectors invisible
        for (VectorObject& vector : adjustableLengthVectors) {
          vector.setInvisible();
          updateVisualizer(vector);
        }

        // Reset the home position
        view->home();

        // Make all adjustable-length vectors visible
        for (VectorObject& vector : adjustableLengthVectors) {
          vector.setVisible();
          updateVisualizer(vector);
        }
      }
    }
  }

  /* Counterbalance transform scales in the next cull traversal after adjustments are finished */
  if (mutex) mutex->unlock();
  MessagesWidget::instance()->showPendingMessages(); // Give a preemption chance to update widgets that may lead to a frame rendering
  if (mutex) mutex->  lock();
  for (VectorObject& vector : _vectors) {
    vector.setAutoScaleCancellationRequired(true);
  }
}


AutoTransformDrawCallback::AutoTransformDrawCallback()
{
}

void AutoTransformDrawCallback::drawImplementation(osgUtil::RenderBin* bin, osg::RenderInfo& renderInfo, osgUtil::RenderLeaf*& previous)
{
  glClear(GL_DEPTH_BUFFER_BIT); // Render on top of everything drawn so far
  bin->drawImplementation(renderInfo, previous);
}

AutoTransformCullCallback::AutoTransformCullCallback(VisualizationAbstract* visualization)
  : _atDrawCallback(new AutoTransformDrawCallback()),
    _visualization(visualization)
{
}

void AutoTransformCullCallback::operator()(osg::Node* node, osg::NodeVisitor* nv)
{
  if (node && nv && nv->getVisitorType() == osg::NodeVisitor::CULL_VISITOR) {
    osg::ref_ptr<osg::AutoTransform> at = dynamic_cast<osg::AutoTransform*>(node->asTransform()); // Work-around for osg::Transform::asAutoTransform() (see OSG commit a4b0dc7)
    if (at.valid()) {
      osg::ref_ptr<osgUtil::CullVisitor> cv = dynamic_cast<osgUtil::CullVisitor*>(nv); // Work-around for osg::NodeVisitor::asCullVisitor() (see OSG commit 8fc287c)
      if (cv.valid()) {
        osg::ref_ptr<osgUtil::RenderBin> rb = cv->getCurrentRenderBin();
        if (rb.valid()) {
          rb->setDrawCallback(rb->getBinNum() == VectorObject::kAutoScaleRenderBinNum ? _atDrawCallback.get() : nullptr);
        }
      }
      if (_visualization) {
        AbstractVisualizerObject* visualizer = nullptr;
        osg::ref_ptr<AutoTransformVisualizer> atv = dynamic_cast<AutoTransformVisualizer*>(at.get()); // Work-around for avoiding search in containers
        if (atv.valid()) {
          visualizer = atv->getVisualizerObject();
        } else {
          std::size_t visualizerIdx = _visualization->getOMVisScene()->getScene().getRootNode()->getChildIndex(node);
          visualizer = _visualization->getBaseData()->getVisualizerObjectByIdx(visualizerIdx);
        }
        if (visualizer && visualizer->isVector()) {
          VectorObject* vector = visualizer->asVector();
          if (vector->getAutoScaleCancellationRequired()) {
            vector->setAutoScaleCancellationRequired(false);
            vector->setTransfScale(1 / at->getScale().z()); // See osg::AutoTransform::accept(osg::NodeVisitor&) or in later versions osg::AutoTransform::computeMatrix(const osg::NodeVisitor*) (since OSG commit 92092a5)
            _visualization->getBaseData()->updateVisualizer(vector);
          }
        }
      }
    }
  }
  traverse(node, nv);
}

AutoTransformVisualizer::AutoTransformVisualizer(AbstractVisualizerObject* visualizer)
  : _visualizer(visualizer)
{
}


///--------------------------------------------------///
///ABSTRACT VISUALIZATION CLASS----------------------///
///--------------------------------------------------///

VisualizationAbstract::VisualizationAbstract()
  : _visType(VisType::NONE),
    mpOMVisScene(nullptr),
    mpOMVisualBase(nullptr),
    mpTimeManager(new TimeManager(0.0, 0.0, 1.0, 0.0, 0.1, 0.0, 1.0))
{
}

VisualizationAbstract::VisualizationAbstract(const std::string& modelFile, const std::string& path, const VisType visType)
  : _visType(visType),
    mpOMVisScene(new OMVisScene(this)),
    mpOMVisualBase(new OMVisualBase(this, modelFile, path)),
    mpTimeManager(new TimeManager(0.0, 0.0, 0.0, 0.0, 0.1, 0.0, 100.0))
{
  mpOMVisScene->getScene().setPath(path);
}

VisType VisualizationAbstract::getVisType() const
{
  return _visType;
}

OMVisScene* VisualizationAbstract::getOMVisScene() const
{
  return mpOMVisScene;
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
      // set new visualization time
      double newTime = mpTimeManager->getVisTime() + (mpTimeManager->getHVisual() * mpTimeManager->getSpeedUp());
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


OMVisScene::OMVisScene(VisualizationAbstract* visualization)
  : _scene(visualization)
{
}

OSGScene& OMVisScene::getScene()
{
  return _scene;
}

void OMVisScene::dumpOSGTreeDebug()
{
  // The node traverser which dumps the tree
  InfoVisitor infoVisitor;
  _scene.getRootNode()->accept(infoVisitor);
}


OSGScene::OSGScene(VisualizationAbstract* visualization)
  : _atCullCallback(new AutoTransformCullCallback(visualization)),
    _rootNode(new osg::Group()),
    _path("")
{
}

osg::ref_ptr<osg::Group> OSGScene::getRootNode()
{
  return _rootNode;
}

std::string OSGScene::getPath() const
{
  return _path;
}

void OSGScene::setPath(const std::string path)
{
  _path = path;
}

void OSGScene::setUpScene(std::vector<ShapeObject>& shapes)
{
  for (ShapeObject& shape : shapes)
  {
    osg::ref_ptr<osg::MatrixTransform> transf = new osg::MatrixTransform();
    transf->setName(shape._id);

    if (isAdvancedCADType(shape._type))
    { //advanced cad node
      //std::cout<<"It's an advanced cad and the filename is "<<shape._fileName<<std::endl;
      osg::ref_ptr<osg::Node> node = osgDB::readNodeFile(shape._fileName);
      if (node.valid())
      {
        osg::ref_ptr<CADFile> cad = new CADFile(node.get());

        transf->addChild(cad.get());
      }
    }
    else if (isSTLType(shape._type))
    { //stl node
      //std::cout<<"It's a stl and the filename is "<<shape._fileName<<std::endl;
      // Disable mesh optimization because it is too expensive (see OSG commit a082b57)
      osg::ref_ptr<osgDB::Options> options = new osgDB::Options("noTriStripPolygons");
      osg::ref_ptr<osg::Node> node = osgDB::readNodeFile(shape._fileName, options.get());
      if (node.valid())
      {
        osg::ref_ptr<CADFile> cad = new CADFile(node.get());

        transf->addChild(cad.get());
      }
    }
    else if (isDXFType(shape._type))
    { //geode with dxf drawable
      //std::cout<<"It's a dxf and the filename is "<<shape._fileName<<std::endl;
      osg::ref_ptr<DXFile> dxfDraw = new DXFile(shape._fileName);

      osg::ref_ptr<osg::Geode> geode = new osg::Geode();
      geode->addDrawable(dxfDraw.get());

      osg::ref_ptr<CADFile> cad = new CADFile(geode.get());

      transf->addChild(cad.get());
    }
    else
    { //geode with shape drawable
      osg::ref_ptr<osg::ShapeDrawable> shapeDraw = new osg::ShapeDrawable();

      osg::ref_ptr<osg::Geode> geode = new osg::Geode();
      geode->addDrawable(shapeDraw.get());

      transf->addChild(geode.get());
    }

    _rootNode->addChild(transf.get());

    shape.setTransformNode(transf);
  }
}

void OSGScene::setUpScene(std::vector<VectorObject>& vectors)
{
  for (VectorObject& vector : vectors)
  {
    osg::ref_ptr<AutoTransformVisualizer> transf = new AutoTransformVisualizer(&vector);
    transf->setName(vector._id);
    transf->setAutoRotateMode(osg::AutoTransform::NO_ROTATION);
    transf->setAutoScaleTransitionWidthRatio(0);
    transf->setAutoScaleToScreen(vector.isScaleInvariant());
    transf->setCullingActive(!vector.isScaleInvariant()); // Work-around for osg::AutoTransform::setAutoScaleToScreen(bool) (see OSG commit 5c48904)
    transf->getOrCreateStateSet()->setMode(GL_NORMALIZE, vector.isScaleInvariant() ? osg::StateAttribute::ON : osg::StateAttribute::OFF);
    transf->getOrCreateStateSet()->setRenderBinDetails(VectorObject::kAutoScaleRenderBinNum - !vector.isDrawnOnTop(), VectorObject::kAutoScaleRenderBinName);
    transf->addCullCallback(_atCullCallback.get());

    osg::ref_ptr<osg::ShapeDrawable> shapeDraw0 = new osg::ShapeDrawable(); // shaft cylinder
    osg::ref_ptr<osg::ShapeDrawable> shapeDraw1 = new osg::ShapeDrawable(); // first head cone
    osg::ref_ptr<osg::ShapeDrawable> shapeDraw2 = new osg::ShapeDrawable(); // second head cone

    osg::ref_ptr<osg::Geode> geode = new osg::Geode();
    geode->addDrawable(shapeDraw0.get());
    geode->addDrawable(shapeDraw1.get());
    geode->addDrawable(shapeDraw2.get());

    transf->addChild(geode.get());

    _rootNode->addChild(transf.get());

    vector.setTransformNode(transf);
  }
}


UpdateVisitor::UpdateVisitor()
  : _visualizer(nullptr),
    _changeMaterialProperties(true)
{
  setTraversalMode(NodeVisitor::TRAVERSE_ALL_CHILDREN);
}

/**
 Transform
 */
void UpdateVisitor::apply(osg::Transform& node)
{
  try {
    apply(dynamic_cast<osg::AutoTransform&>(node)); // Work-around for osg::NodeVisitor::apply(osg::AutoTransform&) (see OSG commit a4b0dc7)
  } catch (const std::bad_cast& exception) {
    NodeVisitor::apply(node);
  }
}

/**
 AutoTransform
 */
void UpdateVisitor::apply(osg::AutoTransform& node)
{
  //std::cout<<"AT "<<node.className()<<"  "<<node.getName()<<std::endl;
  node.setPosition(_visualizer->_mat.getTrans());
  node.setRotation(_visualizer->_mat.getRotate());
  traverse(node);
}

/**
 MatrixTransform
 */
void UpdateVisitor::apply(osg::MatrixTransform& node)
{
  //std::cout<<"MT "<<node.className()<<"  "<<node.getName()<<std::endl;
  node.setMatrix(_visualizer->_mat);
  traverse(node);
}

/**
 Geode
 */
void UpdateVisitor::apply(osg::Geode& node)
{
  //std::cout<<"GEODE "<<_visualizer->_id<<std::endl;
  bool changeMaterial = _changeMaterialProperties;
  bool changeTexture = false;

  switch (_visualizer->getStateSetAction())
  {
  case StateSetAction::update:
   {
    switch (_visualizer->getVisualizerType())
    {
    case VisualizerType::shape:
     {
      ShapeObject* shape = _visualizer->asShape();
      if (isCADType(shape->_type))
      {
        //it's a cad file so we have to rescale the underlying geometry vertices
        osg::ref_ptr<osg::Transform> transformNode = shape->getTransformNode();
        if (transformNode.valid() && transformNode->getNumChildren() > 0)
        {
          osg::ref_ptr<CADFile> cad = dynamic_cast<CADFile*>(transformNode->getChild(0));
          if (cad.valid())
          {
            cad->scaleVertices(node, shape->_extra.exp, shape->_length.exp, shape->_width.exp, shape->_height.exp);
          }
        }
      }
      else
      {
        //it's a drawable and not a cad file so we have to create a new drawable
        osg::ref_ptr<osg::Drawable> draw = node.getDrawable(0);
        draw->dirtyBound();
        draw->dirtyDisplayList();
        if (shape->_type == "pipe")
        {
          node.setDrawable(0, new Pipecylinder(shape->_width.exp * shape->_extra.exp / 2, shape->_width.exp / 2, shape->_length.exp));
        }
        else if (shape->_type == "pipecylinder")
        {
          node.setDrawable(0, new Pipecylinder(shape->_width.exp * shape->_extra.exp / 2, shape->_width.exp / 2, shape->_length.exp));
        }
        else if (shape->_type == "spring")
        {
          node.setDrawable(0, new Spring(shape->_width.exp, shape->_height.exp, shape->_extra.exp, shape->_length.exp));
        }
        else if (shape->_type == "cone")
        {
          osg::ref_ptr<osg::Cone> cone = new osg::Cone(osg::Vec3f(0, 0, 0), shape->_width.exp / 2, shape->_length.exp);
          cone->setCenter(cone->getCenter() - osg::Vec3f(0, 0, cone->getBaseOffset())); // Cancel out undesired offset
          draw->setShape(cone.get());
        }
        else if (shape->_type == "box")
        {
          draw->setShape(new osg::Box(osg::Vec3f(0, 0, shape->_length.exp / 2), shape->_width.exp, shape->_height.exp, shape->_length.exp));
        }
        else if (shape->_type == "cylinder")
        {
          draw->setShape(new osg::Cylinder(osg::Vec3f(0, 0, shape->_length.exp / 2), shape->_width.exp / 2, shape->_length.exp));
        }
        else if (shape->_type == "sphere")
        {
          draw->setShape(new osg::Sphere(osg::Vec3f(0, 0, shape->_length.exp / 2), shape->_length.exp / 2));
        }
        else
        {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                                QString(QObject::tr("Unknown type %1, we make a capsule.")).arg(shape->_type.c_str()),
                                                                Helper::scriptingKind, Helper::errorLevel));
          draw->setShape(new osg::Capsule(osg::Vec3f(0, 0, 0), 0.1, 0.5));
        }
        //std::cout<<"SHAPE "<<draw->getShape()->className()<<std::endl;
      }
      break;
     }//end case type shape

    case VisualizerType::vector:
     {
      VectorObject* vector = _visualizer->asVector();

      const bool  headAtOrigin = vector->hasHeadAtOrigin();
      const float vectorRadius = vector->getRadius();
      const float vectorLength = vector->getLength();
      const float   headRadius = vector->getHeadRadius();
      const float   headLength = vector->getHeadLength();
      const float  tHeadLength = vector->isTwoHeadedArrow() ? 1.5f * headLength : headLength;
      const float  arrowLength = vector->hasOnlyShaftLengthCounted() ? tHeadLength + vectorLength : vectorLength;
      const float  shaftRadius = vectorRadius;
      const float  shaftLength = arrowLength > tHeadLength ? arrowLength - tHeadLength : 0;
      const osg::Vec3f vectorDirection = osg::Vec3f(0, 0, 1);                                              // axis directed from tail to head of arrow
      const osg::Vec3f offsetPosition = vectorDirection * (headAtOrigin ? -arrowLength : 0);               // origin placed upon tail or head of arrow
      const osg::Vec3f shaftPosition = offsetPosition + vectorDirection * (arrowLength - tHeadLength) / 2; // center of    cylinder (such that top of shaft meets bottom of head)
      const osg::Vec3f head1Position = offsetPosition + vectorDirection * (arrowLength -  headLength);     // base   of  first cone (offset added by osg::Cone is canceled below)
      const osg::Vec3f head2Position = offsetPosition + vectorDirection * (arrowLength - tHeadLength);     // base   of second cone (offset added by osg::Cone is canceled below)

      osg::ref_ptr<osg::Cylinder> shaftShape = new osg::Cylinder(shaftPosition, shaftRadius, shaftLength);
      osg::ref_ptr<osg::Cone>     head1Shape = new osg::Cone    (head1Position,  headRadius,  headLength);
      osg::ref_ptr<osg::Cone>     head2Shape = new osg::Cone    (head2Position,  headRadius,  headLength);

      head1Shape->setCenter(head1Shape->getCenter() - vectorDirection * head1Shape->getBaseOffset());
      head2Shape->setCenter(head2Shape->getCenter() - vectorDirection * head2Shape->getBaseOffset());

      osg::ref_ptr<osg::Drawable> draw0 = node.getDrawable(0); // shaft cylinder
      draw0->dirtyBound();
      draw0->dirtyDisplayList();
      draw0->setShape(shaftShape.get());
      //std::cout<<"VECTOR shaft "<<draw0->getShape()->className()<<std::endl;

      osg::ref_ptr<osg::Drawable> draw1 = node.getDrawable(1); // first head cone
      draw1->dirtyBound();
      draw1->dirtyDisplayList();
      draw1->setShape(head1Shape.get());
      //std::cout<<"VECTOR first head "<<draw1->getShape()->className()<<std::endl;

      osg::ref_ptr<osg::Drawable> draw2 = node.getDrawable(2); // second head cone
      draw2->dirtyBound();
      draw2->dirtyDisplayList();
      if (vector->isTwoHeadedArrow())
      {
        draw2->setShape(head2Shape.get());
        //std::cout<<"VECTOR second head "<<draw2->getShape()->className()<<std::endl;
      }
      else
      {
        draw2->setShape(nullptr);
      }
      break;
     }//end case type vector

    default:
     {break;}

    }//end switch type
    break;
   }//end case action update

  case StateSetAction::modify:
   {
    changeTexture = true;
    break;
   }//end case action modify

  default:
   {break;}

  }//end switch action

  if (changeMaterial || changeTexture) {
    osg::ref_ptr<osg::StateSet> stateSet = nullptr;
    bool geometryColors = false;
    bool is3DSShape = false;

    if (_visualizer->isShape()) {
      ShapeObject* shape = _visualizer->asShape();
      if (isCADType(shape->_type)) {
        osg::ref_ptr<osg::Transform> transformNode = shape->getTransformNode();
        if (transformNode.valid() && transformNode->getNumChildren() > 0) {
          osg::ref_ptr<CADFile> cad = dynamic_cast<CADFile*>(transformNode->getChild(0));
          if (cad.valid()) {
            stateSet = cad->getOrCreateStateSet();
            geometryColors = !shape->getVisualProperties()->getColor().custom();
            is3DSShape = is3DSType(shape->_type);
          }
        }
      }
    }

    osg::ref_ptr<osg::StateSet> ss = stateSet.valid() ? stateSet.get() : node.getOrCreateStateSet();
    osg::Material::ColorMode mode = geometryColors ? osg::Material::AMBIENT_AND_DIFFUSE : osg::Material::OFF;

    AbstractVisualProperties* visualProperties = _visualizer->getVisualProperties();
    QColor      color            = visualProperties->getColor().get();
    float       specular         = visualProperties->getSpecular().get();
    float       transparency     = visualProperties->getTransparency().get();
    std::string textureImagePath = visualProperties->getTextureImagePath().get();

    if (changeMaterial) {
      //set color and specular coefficient
      changeColorOfMaterial(ss, mode, color, specular);

      //set transparency
      changeTransparencyOfMaterial(ss, transparency);
      if (geometryColors) {
        if (is3DSShape) {
          changeTransparencyOfGeometry<osg::Vec4ubArray, 255>(node, transparency);
        } else {
          changeTransparencyOfGeometry<osg::Vec4Array, 1>    (node, transparency);
        }
      }
    }

    if (changeTexture) {
      //set texture
      applyTexture(ss, textureImagePath);
    }
  }

  traverse(node);
}

osg::Image* UpdateVisitor::convertImage(const QImage& iImage)
{
  osg::Image* osgImage = new osg::Image();
  if (!iImage.isNull()) {
#if (QT_VERSION >= QT_VERSION_CHECK(5, 2, 0))
    QImage glImage = iImage.convertToFormat(QImage::Format_RGBA8888_Premultiplied);
#else
    QImage glImage = QGLWidget::convertToGLFormat(iImage);
#endif
    if (!glImage.isNull()) {
#if (QT_VERSION >= QT_VERSION_CHECK(5, 10, 0))
      int bytesSize = glImage.sizeInBytes();
#else // QT_VERSION_CHECK
      int bytesSize = glImage.byteCount();
#endif // QT_VERSION_CHECK
      unsigned char* data = new unsigned char[bytesSize];
      for (int i = 0; i < bytesSize; ++i) {
        data[i] = glImage.bits()[i];
      }
      osgImage->setImage(glImage.width(), glImage.height(), 1, 4, GL_RGBA, GL_UNSIGNED_BYTE, data, osg::Image::USE_NEW_DELETE, 1);
    }
  }
  return osgImage;
}

/*!
 * \brief UpdateVisitor::applyTexture
 * sets a texture on a geode
 */
void UpdateVisitor::applyTexture(osg::StateSet* ss, const std::string& imagePath)
{
  if (ss)
  {
    if (imagePath.compare(""))
    {
      osg::ref_ptr<osg::Image> image = nullptr;
      std::string resIdent = ":/Resources";
      if (!imagePath.compare(0, resIdent.length(), resIdent))
      {
        QImage* qim = new QImage(QString::fromStdString(imagePath));
        image = convertImage(*qim);
        delete qim;
        if (image.valid())
        {
          image->setInternalTextureFormat(GL_RGBA);
        }
      }
      else
      {
        image = osgDB::readImageFile(imagePath);
      }
      if (image.valid())
      {
        osg::ref_ptr<osg::Texture2D> texture = new osg::Texture2D();
        texture->setDataVariance(osg::Object::DYNAMIC);
        texture->setFilter(osg::Texture::MIN_FILTER, osg::Texture::LINEAR_MIPMAP_LINEAR);
        texture->setFilter(osg::Texture::MAG_FILTER, osg::Texture::LINEAR);
        texture->setWrap(osg::Texture::WRAP_S, osg::Texture::CLAMP);
        texture->setImage(image.get());
        texture->setResizeNonPowerOfTwoHint(false);// don't output console message about scaling
        ss->setTextureAttributeAndModes(0, texture.get(), osg::StateAttribute::ON | osg::StateAttribute::OVERRIDE);
      }
    }
    else
    {
      ss->getTextureAttributeList().clear();
      ss->getTextureModeList().clear();
    }
  }
}

/*!
 * \brief UpdateVisitor::changeColorOfMaterial
 * changes color of a material
 */
void UpdateVisitor::changeColorOfMaterial(osg::StateSet* ss, const osg::Material::ColorMode mode, const QColor color, const float specular)
{
  if (ss)
  {
    osg::ref_ptr<osg::Material> material = dynamic_cast<osg::Material*>(ss->getAttribute(osg::StateAttribute::MATERIAL));
    if (!material.valid()) material = new osg::Material();
    material->setColorMode(mode);
    material->setAmbient  (osg::Material::FRONT_AND_BACK, osg::Vec4f(color.redF(), color.greenF(), color.blueF(), color.alphaF()));
    material->setDiffuse  (osg::Material::FRONT_AND_BACK, osg::Vec4f(color.redF(), color.greenF(), color.blueF(), color.alphaF()));
    material->setSpecular (osg::Material::FRONT_AND_BACK, osg::Vec4f(specular, specular, specular, 1.0));
    material->setShininess(osg::Material::FRONT_AND_BACK, 8.0); // Material shininess in range [0., 128.]
    ss->setAttributeAndModes(material.get(), osg::StateAttribute::ON | osg::StateAttribute::OVERRIDE);
  }
}

/*!
 * \brief UpdateVisitor::changeTransparencyOfMaterial
 * changes transparency of a material
 */
void UpdateVisitor::changeTransparencyOfMaterial(osg::StateSet* ss, const float transparency)
{
  if (ss)
  {
    osg::ref_ptr<osg::Material> material = dynamic_cast<osg::Material*>(ss->getAttribute(osg::StateAttribute::MATERIAL));
    if (!material.valid()) material = new osg::Material();
    material->setTransparency(osg::Material::FRONT_AND_BACK, transparency);
    ss->setAttributeAndModes(material.get(), osg::StateAttribute::ON | osg::StateAttribute::OVERRIDE);
    ss->setMode(GL_BLEND, transparency ? osg::StateAttribute::ON : osg::StateAttribute::OFF);
    ss->setRenderingHint(transparency ? osg::StateSet::TRANSPARENT_BIN : osg::StateSet::OPAQUE_BIN);
  }
}

/*!
 * \brief UpdateVisitor::changeTransparencyOfGeometry
 * changes transparency of a geode's geometry
 */
template<typename Vec4Array, unsigned int scale>
void UpdateVisitor::changeTransparencyOfGeometry(osg::Geode& geode, const float transparency)
{
  using Vec4 = typename Vec4Array::ElementDataType;
  using type = typename Vec4::value_type;
  type opacity = (1.0 - transparency) * scale;
  unsigned int num = geode.getNumDrawables();
  for (unsigned int i = 0; i < num; i++) {
    osg::Drawable* drawable = geode.getDrawable(i);
    if (drawable) {
      osg::Geometry* geometry = drawable->asGeometry();
      if (geometry) {
        Vec4Array* colors = dynamic_cast<Vec4Array*>(geometry->getColorArray());
        if (colors) {
          for (Vec4& color : colors->asVector()) {
            color.a() = opacity;
          }
          colors->dirty();
          drawable->dirtyDisplayList();
        }
      }
    }
  }
}

InfoVisitor::InfoVisitor()
  : _level(0)
{
  setTraversalMode(NodeVisitor::TRAVERSE_ALL_CHILDREN);
}

std::string InfoVisitor::spaces()
{
  return std::string(_level * 2, ' ');
}

void InfoVisitor::apply(osg::Node& node)
{
  std::cout << spaces() << node.libraryName() << "::" << node.className() << std::endl;
  ++_level;
  traverse(node);
  --_level;
}

void InfoVisitor::apply(osg::Geode& geode)
{
  std::cout << spaces() << geode.libraryName() << "::" << geode.className() << std::endl;
  ++_level;
  for (size_t i = 0; i < geode.getNumDrawables(); ++i)
  {
    osg::ref_ptr<osg::Drawable> drawable = geode.getDrawable(i);
    std::cout << spaces() << drawable->libraryName() << "::" << drawable->className() << std::endl;
  }
  traverse(geode);
  --_level;
}


osg::Vec3f Mat3mulV3(osg::Matrix3 M, osg::Vec3f V)
{
  return osg::Vec3f(M[0] * V[0] + M[1] * V[1] + M[2] * V[2],
                    M[3] * V[0] + M[4] * V[1] + M[5] * V[2],
                    M[6] * V[0] + M[7] * V[1] + M[8] * V[2]);
}

osg::Vec3f V3mulMat3(osg::Vec3f V, osg::Matrix3 M)
{
  return osg::Vec3f(M[0] * V[0] + M[3] * V[1] + M[6] * V[2],
                    M[1] * V[0] + M[4] * V[1] + M[7] * V[2],
                    M[2] * V[0] + M[5] * V[1] + M[8] * V[2]);
}

osg::Matrix3 Mat3mulMat3(osg::Matrix3 M1, osg::Matrix3 M2)
{
  osg::Matrix3 M3;
  for (int i = 0; i < 3; ++i)
  {
    for (int j = 0; j < 3; ++j)
    {
      //cout<<" i and j "<<i<<" "<<j<<endl;
      float x = 0.0;
      for (int k = 0; k < 3; ++k)
      {
        //cout<<M1[i*3+k]<<" * "<<M2[k*3+j]<<" = "<<M1[i*3+k]*M2[k*3+j]<<endl;
        x = M1[i * 3 + k] * M2[k * 3 + j] + x;
      }
      M3[i * 3 + j] = x;
    }
  }

  return M3;
}

osg::Vec3f normalize(osg::Vec3f vec)
{
  osg::Vec3f vecOut;
  if (vec.length() >= 100 * 1.e-15)
    vecOut = vec / vec.length();
  else
    vecOut = vec / (100 * 1.e-15);
  return vecOut;
}

osg::Vec3f cross(osg::Vec3f vec1, osg::Vec3f vec2)
{
  return osg::Vec3f(vec1[1] * vec2[2] - vec1[2] * vec2[1],
                    vec1[2] * vec2[0] - vec1[0] * vec2[2],
                    vec1[0] * vec2[1] - vec1[1] * vec2[0]);
}

Directions fixDirections(osg::Vec3f lDir, osg::Vec3f wDir)
{
  Directions dirs;
  osg::Vec3f e_x;
  osg::Vec3f e_y;

  //lengthDirection
  double abs_n_x = lDir.length();
  if (abs_n_x < 1e-10)
    e_x = osg::Vec3f(1, 0, 0);
  else
    e_x = lDir / abs_n_x;

  //widthDirection
  osg::Vec3f n_z_aux = cross(e_x, wDir);
  osg::Vec3f e_y_aux;
  if (n_z_aux * n_z_aux > 1e-6)
    e_y_aux = wDir;
  else
  {
    if (fabs(e_x[0]) > 1e-6)
      e_y_aux = osg::Vec3f(0, 1, 0);
    else
      e_y_aux = osg::Vec3f(1, 0, 0);
  }
  e_y = cross(normalize(cross(e_x, e_y_aux)), e_x);

  dirs._lDir = e_x;
  dirs._wDir = e_y;
  return dirs;
}

void assemblePokeMatrix(osg::Matrix& M, const osg::Matrix3& T, const osg::Vec3f& r)
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

rAndT rotateModelica2OSG(osg::Matrix3 T, osg::Vec3f r, osg::Vec3f r_shape, osg::Vec3f lDir, osg::Vec3f wDir, std::string type)
{
  rAndT res;

  Directions dirs = fixDirections(lDir, wDir);
  osg::Vec3f hDir = dirs._lDir ^ dirs._wDir;
  //std::cout << "lDir " << dirs._lDir[0] << ", " << dirs._lDir[1] << ", " << dirs._lDir[2] << std::endl;
  //std::cout << "wDir " << dirs._wDir[0] << ", " << dirs._wDir[1] << ", " << dirs._wDir[2] << std::endl;
  //std::cout << "hDir " <<       hDir[0] << ", " <<       hDir[1] << ", " <<       hDir[2] << std::endl;

  osg::Matrix3 T0;
  if (isCADType(type))
  {
    T0 = osg::Matrix3(dirs._lDir[0], dirs._lDir[1], dirs._lDir[2],
                      dirs._wDir[0], dirs._wDir[1], dirs._wDir[2],
                            hDir[0],       hDir[1],       hDir[2]);
  } else {
    T0 = osg::Matrix3(dirs._wDir[0], dirs._wDir[1], dirs._wDir[2],
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

rAndT rotateModelica2OSG(osg::Matrix3 T, osg::Vec3f r, osg::Vec3f dir)
{
  rAndT res;

  // See https://math.stackexchange.com/a/413235
  int i = dir[0] ? 0 : dir[1] ? 1 : 2;
  int j = (i + 1) % 3;

  osg::Vec3f lDir = dir;
  osg::Vec3f wDir = osg::Vec3f();
  wDir[i] = -lDir[j];
  wDir[j] = +lDir[i];

  Directions dirs = fixDirections(lDir, wDir);
  osg::Vec3f hDir = dirs._lDir ^ dirs._wDir;
  //std::cout << "lDir " << dirs._lDir[0] << ", " << dirs._lDir[1] << ", " << dirs._lDir[2] << std::endl;
  //std::cout << "wDir " << dirs._wDir[0] << ", " << dirs._wDir[1] << ", " << dirs._wDir[2] << std::endl;
  //std::cout << "hDir " <<       hDir[0] << ", " <<       hDir[1] << ", " <<       hDir[2] << std::endl;

  osg::Matrix3 T0 = osg::Matrix3(dirs._wDir[0], dirs._wDir[1], dirs._wDir[2],
                                       hDir[0],       hDir[1],       hDir[2],
                                 dirs._lDir[0], dirs._lDir[1], dirs._lDir[2]);
  //std::cout << "T0 " << T0[0] << ", " << T0[1] << ", " << T0[2] << std::endl;
  //std::cout << "   " << T0[3] << ", " << T0[4] << ", " << T0[5] << std::endl;
  //std::cout << "   " << T0[6] << ", " << T0[7] << ", " << T0[8] << std::endl;

  res._r = r;
  res._T = Mat3mulMat3(T0, T);

  return res;
}
