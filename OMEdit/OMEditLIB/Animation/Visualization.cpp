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

#include <osg/Image>
#include <osg/Shape>
#include <osg/Node>
#include <osgDB/Export>
#include <osgDB/Registry>
#include <osgDB/WriteFile>

OMVisualBase::OMVisualBase(const std::string& modelFile, const std::string& path)
  : _shapes(),
    _vectors(),
    _modelFile(modelFile),
    _path(path),
    _xmlFileName(assembleXMLFileName(modelFile, path))
{
}

/*!
 * \brief OMVisualBase::getVisualizerObjectByID
 * get the AbstractVisualizerObject with the same visualizerID
 *\param the name of the visualizer
 *\return the selected visualizer
 */
AbstractVisualizerObject* OMVisualBase::getVisualizerObjectByID(const std::string& visualizerID)
{
  std::vector<std::reference_wrapper<AbstractVisualizerObject>> visualizers;
  visualizers.reserve(_shapes.size() + _vectors.size());
  for (ShapeObject& shape : _shapes) {
    visualizers.push_back(shape);
  }
  for (VectorObject& vector : _vectors) {
    visualizers.push_back(vector);
  }
  for (AbstractVisualizerObject& visualizer : visualizers) {
    if (visualizer._id == visualizerID) {
      return &visualizer;
    }
  }
  return nullptr;
}

/*!
 * \brief OMVisualBase::getVisualizerObjectIndexByID
 * get the index of the AbstractVisualizerObject with the same visualizerID
 *\param the name of the visualizer
 *\return the selected visualizer index
 */
int OMVisualBase::getVisualizerObjectIndexByID(const std::string& visualizerID)
{
  int i = 0;
  std::vector<std::reference_wrapper<AbstractVisualizerObject>> visualizers;
  visualizers.reserve(_shapes.size() + _vectors.size());
  for (ShapeObject& shape : _shapes) {
    visualizers.push_back(shape);
  }
  for (VectorObject& vector : _vectors) {
    visualizers.push_back(vector);
  }
  for (AbstractVisualizerObject& visualizer : visualizers) {
    if (visualizer._id == visualizerID) {
      return i;
    }
    i++;
  }
  return -1;
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

    if (isCADType(shape._type))
    {
      shape._fileName = extractCADFilename(shape._type);
      if (!fileExists(shape._fileName)) {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                              QString(QObject::tr("Could not find the file %1."))
                                                              .arg(shape._fileName.c_str()),
                                                              Helper::scriptingKind, Helper::errorLevel));
        continue;
      }

      if (dxfFileType(shape._fileName)) {
        shape._type = "dxf";
      } else if (stlFileType(shape._fileName)) {
        shape._type = "stl";
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

void OMVisualBase::appendVisVariable(const rapidxml::xml_node<>* node, std::vector<std::string>& visVariables) const
{
  if (strcmp("cref", node->name()) == 0)
  {
    visVariables.push_back(std::string(node->value()));
  }
}


///--------------------------------------------------///
///ABSTRACT VISUALIZATION CLASS----------------------///
///--------------------------------------------------///

VisualizationAbstract::VisualizationAbstract()
  : _visType(VisType::NONE),
    mpOMVisualBase(nullptr),
    mpOMVisScene(nullptr),
    mpUpdateVisitor(nullptr)
{
  mpTimeManager = new TimeManager(0.0, 0.0, 1.0, 0.0, 0.1, 0.0, 1.0);
}

VisualizationAbstract::VisualizationAbstract(const std::string& modelFile, const std::string& path, const VisType visType)
  : _visType(visType),
    mpOMVisualBase(nullptr),
    mpOMVisScene(new OMVisScene()),
    mpUpdateVisitor(new UpdateVisitor()),
    mpTimeManager(new TimeManager(0.0, 0.0, 0.0, 0.0, 0.1, 0.0, 100.0))
{
  mpOMVisualBase = new OMVisualBase(modelFile, path);
  mpOMVisScene->getScene().setPath(path);
}

void VisualizationAbstract::initData()
{
  mpOMVisualBase->initVisObjects();
}

void VisualizationAbstract::initVisualization()
{
  initializeVisAttributes(mpTimeManager->getStartTime());
  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  mpTimeManager->setRealTimeFactor(0.0);
  mpTimeManager->setPause(true);
}

TimeManager* VisualizationAbstract::getTimeManager() const
{
  return mpTimeManager;
}

void VisualizationAbstract::modifyVisualizer(const std::string& visualizerName)
{
  int visualizerIdx = getBaseData()->getVisualizerObjectIndexByID(visualizerName);
  AbstractVisualizerObject* visualizer = getBaseData()->getVisualizerObjectByID(visualizerName);
  visualizer->setStateSetAction(StateSetAction::modify);
  mpUpdateVisitor->_visualizer = visualizer;
  osg::ref_ptr<osg::Node> child = mpOMVisScene->getScene().getRootNode()->getChild(visualizerIdx);
  child->accept(*mpUpdateVisitor);
  visualizer->setStateSetAction(StateSetAction::update);
}


void VisualizationAbstract::sceneUpdate()
{
  //measure realtime
  mpTimeManager->updateTick();
  //update scene and set next time step
  if (!mpTimeManager->isPaused()) {
    updateScene(mpTimeManager->getVisTime());
    //finish animation with pause when endtime is reached
    if (mpTimeManager->getVisTime() >= mpTimeManager->getEndTime()) {
      if (mpTimeManager->canRepeat()) {
        initVisualization();
        mpTimeManager->setPause(false);
      } else {
        mpTimeManager->setPause(true);
      }
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

void VisualizationAbstract::setUpScene()
{
  // Build scene graph.
  mpOMVisScene->getScene().setUpScene(mpOMVisualBase->_shapes);
  mpOMVisScene->getScene().setUpScene(mpOMVisualBase->_vectors);
}

VisType VisualizationAbstract::getVisType() const
{
  return _visType;
}

OMVisualBase* VisualizationAbstract::getBaseData() const
{
  return mpOMVisualBase;
}



OMVisScene* VisualizationAbstract::getOMVisScene() const
{
  return mpOMVisScene;
}

std::string VisualizationAbstract::getModelFile() const
{
  return mpOMVisualBase->getModelFile();
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


OMVisScene::OMVisScene()
  : _scene()
{
}

void OMVisScene::dumpOSGTreeDebug()
{
  // The node traverser which dumps the tree
  InfoVisitor infoVisitor;
  _scene.getRootNode()->accept(infoVisitor);
}

OSGScene& OMVisScene::getScene()
{
  return _scene;
}


OSGScene::OSGScene()
  : _rootNode(new osg::Group()),
    _path("")
{
}

void OSGScene::setUpScene(const std::vector<ShapeObject>& shapes)
{
  for (const ShapeObject& shape : shapes)
  {
    osg::ref_ptr<osg::MatrixTransform> transf = new osg::MatrixTransform();

    if (shape._type.compare("stl") == 0)
    { //cad node
      //std::cout<<"It's a stl and the filename is "<<shape._fileName<<std::endl;
      osg::ref_ptr<osg::Node> node = osgDB::readNodeFile(shape._fileName);

      if (node)
      {
        osg::ref_ptr<osg::Material> material = new osg::Material();
        material->setDiffuse(osg::Material::FRONT, osg::Vec4f(0.0, 0.0, 0.0, 0.0));

        osg::ref_ptr<osg::StateSet> ss = node->getOrCreateStateSet();
        ss->setAttribute(material.get());

        node->setStateSet(ss.get());

        transf->addChild(node.get());
      }
    }
    else if (shape._type.compare("dxf") == 0)
    { //geode with dxf drawable
      //std::cout<<"It's a dxf and the filename is "<<shape._fileName<<std::endl;
      osg::ref_ptr<DXFile> dxfDraw = new DXFile(shape._fileName);

      osg::ref_ptr<osg::Geode> geode = new osg::Geode();
      geode->addDrawable(dxfDraw.get());

      transf->addChild(geode.get());
    }
    else
    { //geode with shape drawable
      osg::ref_ptr<osg::ShapeDrawable> shapeDraw = new osg::ShapeDrawable();
      shapeDraw->setColor(osg::Vec4(1.0, 1.0, 1.0, 1.0));

      osg::ref_ptr<osg::Geode> geode = new osg::Geode();
      geode->addDrawable(shapeDraw.get());

      osg::ref_ptr<osg::Material> material = new osg::Material();
      material->setDiffuse(osg::Material::FRONT, osg::Vec4f(0.0, 0.0, 0.0, 0.0));

      osg::ref_ptr<osg::StateSet> ss = geode->getOrCreateStateSet();
      ss->setAttribute(material.get());

      geode->setStateSet(ss.get());

      transf->addChild(geode.get());
    }

    _rootNode->addChild(transf.get());
  }
}

void OSGScene::setUpScene(const std::vector<VectorObject>& vectors)
{
  for (const VectorObject& vector : vectors)
  {
    Q_UNUSED(vector);

    osg::ref_ptr<osg::MatrixTransform> transf = new osg::MatrixTransform();

    osg::ref_ptr<osg::ShapeDrawable> shapeDraw0 = new osg::ShapeDrawable(); // shaft cylinder
    shapeDraw0->setColor(osg::Vec4(1.0, 1.0, 1.0, 1.0));

    osg::ref_ptr<osg::ShapeDrawable> shapeDraw1 = new osg::ShapeDrawable(); // first head cone
    shapeDraw1->setColor(osg::Vec4(1.0, 1.0, 1.0, 1.0));

    osg::ref_ptr<osg::ShapeDrawable> shapeDraw2 = new osg::ShapeDrawable(); // second head cone
    shapeDraw2->setColor(osg::Vec4(1.0, 1.0, 1.0, 1.0));

    osg::ref_ptr<osg::Geode> geode = new osg::Geode();
    geode->addDrawable(shapeDraw0.get());
    geode->addDrawable(shapeDraw1.get());
    geode->addDrawable(shapeDraw2.get());

    osg::ref_ptr<osg::Material> material = new osg::Material();
    material->setDiffuse(osg::Material::FRONT, osg::Vec4f(0.0, 0.0, 0.0, 0.0));

    osg::ref_ptr<osg::StateSet> ss = geode->getOrCreateStateSet();
    ss->setAttribute(material.get());

    geode->setStateSet(ss.get());

    transf->addChild(geode.get());

    _rootNode->addChild(transf.get());
  }
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


UpdateVisitor::UpdateVisitor()
  : _visualizer(nullptr)
{
  setTraversalMode(NodeVisitor::TRAVERSE_ALL_CHILDREN);
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
  //std::cout<<"GEODE "<< _visualizer->_id<<" "<<_visualizer->getTransparency()<<std::endl;
  osg::ref_ptr<osg::StateSet> ss = node.getOrCreateStateSet();
  node.setName(_visualizer->_id);
  switch (_visualizer->getStateSetAction())
  {
  case StateSetAction::update:
   {
    switch (_visualizer->getVisualizerType())
    {
    case VisualizerType::shape:
     {
      ShapeObject* shape = static_cast<ShapeObject*>(_visualizer);
      if (shape->_type.compare("dxf") != 0 and shape->_type.compare("stl") != 0)
      {
        //it's a drawable and not a cad file so we have to create a new drawable
        osg::ref_ptr<osg::Drawable> draw = node.getDrawable(0);
        draw->dirtyDisplayList();
        if (shape->_type == "pipe")
        {
          node.removeDrawable(draw.get());
          draw = new Pipecylinder(shape->_width.exp * shape->_extra.exp / 2, shape->_width.exp / 2, shape->_length.exp);
        }
        else if (shape->_type == "pipecylinder")
        {
          node.removeDrawable(draw.get());
          draw = new Pipecylinder(shape->_width.exp * shape->_extra.exp / 2, shape->_width.exp / 2, shape->_length.exp);
        }
        else if (shape->_type == "spring")
        {
          node.removeDrawable(draw.get());
          draw = new Spring(shape->_width.exp, shape->_height.exp, shape->_extra.exp, shape->_length.exp);
        }
        else if (shape->_type == "box")
        {
          draw->setShape(new osg::Box(osg::Vec3f(), shape->_width.exp, shape->_height.exp, shape->_length.exp));
        }
        else if (shape->_type == "cone")
        {
          draw->setShape(new osg::Cone(osg::Vec3f(), shape->_width.exp / 2, shape->_length.exp));
        }
        else if (shape->_type == "cylinder")
        {
          draw->setShape(new osg::Cylinder(osg::Vec3f(), shape->_width.exp / 2, shape->_length.exp));
        }
        else if (shape->_type == "sphere")
        {
          draw->setShape(new osg::Sphere(osg::Vec3f(), shape->_length.exp / 2));
        }
        else
        {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                                QString(QObject::tr("Unknown type %1, we make a capsule.")).arg(shape->_type.c_str()),
                                                                Helper::scriptingKind, Helper::errorLevel));
          draw->setShape(new osg::Capsule(osg::Vec3f(), 0.1, 0.5));
        }
        //std::cout<<"SHAPE "<<draw->getShape()->className()<<std::endl;
        node.addDrawable(draw.get());
      }
      break;
     }//end case type shape

    case VisualizerType::vector:
     {
      VectorObject* vector = static_cast<VectorObject*>(_visualizer);

      const float vectorRadius = vector->getRadius();
      const float vectorLength = vector->getLength();
      const float headRadius = vector->getHeadRadius();
      const float headLength = vector->getHeadLength();
      const float shaftRadius = vectorRadius;
      const float shaftLength = vectorLength > headLength ? vectorLength - headLength : 0;
      const osg::Vec3f vectorDirection = osg::Vec3f(0, 0, 1); // axis of symmetry directed from tail to head of arrow
      const osg::Vec3f shaftPosition = vectorDirection * (- headLength / 2); // center of cylinder shifted for top of shaft to meet bottom of first head
      const osg::Vec3f head1Position = vectorDirection * (vectorLength / 2 - headLength); // base of first cone (offset added by osg::Cone is canceled below)
      const osg::Vec3f head2Position = head1Position - vectorDirection * headLength / 2; // base of second cone (offset added by osg::Cone is canceled below)

      osg::ref_ptr<osg::Cylinder> shaftShape = new osg::Cylinder(shaftPosition, shaftRadius, shaftLength);
      osg::ref_ptr<osg::Cone> head1Shape = new osg::Cone(head1Position, headRadius, headLength);
      osg::ref_ptr<osg::Cone> head2Shape = new osg::Cone(head2Position, headRadius, headLength);

      head1Shape->setCenter(head1Shape->getCenter() - vectorDirection * head1Shape->getBaseOffset());
      head2Shape->setCenter(head2Shape->getCenter() - vectorDirection * head2Shape->getBaseOffset());

      osg::ref_ptr<osg::Drawable> draw0 = node.getDrawable(0); // shaft cylinder
      draw0->dirtyDisplayList();
      draw0->setShape(shaftShape.get());
      //std::cout<<"VECTOR shaft "<<draw0->getShape()->className()<<std::endl;

      osg::ref_ptr<osg::Drawable> draw1 = node.getDrawable(1); // first head cone
      draw1->dirtyDisplayList();
      draw1->setShape(head1Shape.get());
      //std::cout<<"VECTOR first head "<<draw1->getShape()->className()<<std::endl;

      osg::ref_ptr<osg::Drawable> draw2 = node.getDrawable(2); // second head cone
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
     //apply texture
     applyTexture(ss.get(), _visualizer->getTextureImagePath());
     break;
   }//end case action modify

  default:
   {break;}

  }//end switch action

  //set color
  if (!_visualizer->isShape() or static_cast<ShapeObject*>(_visualizer)->_type.compare("dxf") != 0)
    changeColor(ss.get(), _visualizer->_color[0].exp, _visualizer->_color[1].exp, _visualizer->_color[2].exp);

  //set transparency
  changeTransparency(ss.get(), _visualizer->getTransparency());

  node.setStateSet(ss.get());
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
 * sets a texture for a geode
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
        if (image.get())
        {
          image->setInternalTextureFormat(GL_RGBA);
        }
      }
      else
      {
        image = osgDB::readImageFile(imagePath);
      }
      if (image.get())
      {
        osg::ref_ptr<osg::Texture2D> texture = new osg::Texture2D();
        texture->setDataVariance(osg::Object::DYNAMIC);
        texture->setFilter(osg::Texture::MIN_FILTER, osg::Texture::LINEAR_MIPMAP_LINEAR);
        texture->setFilter(osg::Texture::MAG_FILTER, osg::Texture::LINEAR);
        texture->setWrap(osg::Texture::WRAP_S, osg::Texture::CLAMP);
        texture->setImage(image.get());
        texture->setResizeNonPowerOfTwoHint(false);// don't output console message about scaling
        ss->setTextureAttributeAndModes(0, texture.get(), osg::StateAttribute::ON);
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
 * \brief UpdateVisitor::changeColor
 * changes color for a geode
 */
void UpdateVisitor::changeColor(osg::StateSet* ss, float r, float g, float b)
{
  if (ss)
  {
    osg::ref_ptr<osg::Material> material = dynamic_cast<osg::Material*>(ss->getAttribute(osg::StateAttribute::MATERIAL));
    if (!material.get()) material = new osg::Material();
    material->setDiffuse(osg::Material::FRONT, osg::Vec4f(r / 255, g / 255, b / 255, 1.0));
    ss->setAttribute(material.get());
  }
}

/*!
 * \brief UpdateVisitor::changeTransparency
 * changes transparency for a geode
 */
void UpdateVisitor::changeTransparency(osg::StateSet* ss, float transpCoeff)
{
  if (ss and _visualizer->getTransparency())
  {
    ss->setMode(GL_BLEND, osg::StateAttribute::ON);
    ss->setRenderingHint(osg::StateSet::TRANSPARENT_BIN);
    osg::ref_ptr<osg::Material> material = dynamic_cast<osg::Material*>(ss->getAttribute(osg::StateAttribute::MATERIAL));
    if (!material.get()) material = new osg::Material();
    material->setTransparency(osg::Material::FRONT_AND_BACK, transpCoeff);
    ss->setAttributeAndModes(material.get(), osg::StateAttribute::OVERRIDE);
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

rAndT rotateModelica2OSG(osg::Matrix3 T, osg::Vec3f r, osg::Vec3f r_shape, osg::Vec3f lDir, osg::Vec3f wDir, float length/*, float width, float height*/, std::string type)
{
  rAndT res;

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

  // Since in OSG, the rotation starts at the center of symmetry and in MSL at the end of the body,
  // we need an offset here of half the length for some geometries
  osg::Vec3f r_offset = dirs._lDir * length / 2;

  if (type == "stl" || type == "dxf")
  {
    res._r = V3mulMat3(r_shape, T);
    T0 = osg::Matrix3(dirs._lDir[0], dirs._lDir[1], dirs._lDir[2],
                      dirs._wDir[0], dirs._wDir[1], dirs._wDir[2],
                            hDir[0],       hDir[1],       hDir[2]);
  }
  else if (type == "sphere")
  {
    res._r = V3mulMat3(r_shape + r_offset, T);
    T0 = osg::Matrix3(dirs._lDir[0], dirs._lDir[1], dirs._lDir[2],
                      dirs._wDir[0], dirs._wDir[1], dirs._wDir[2],
                            hDir[0],       hDir[1],       hDir[2]);
  }
  else if (type == "pipe" || type == "pipecylinder" || type == "spring" || type == "cone")
  {
    res._r = V3mulMat3(r_shape, T);
  }
  else/* if (type == "box" || type == "cylinder")*/
  {
    res._r = V3mulMat3(r_shape + r_offset, T);
  }

  res._r = res._r + r;
  res._T = Mat3mulMat3(T0, T);

  return res;
}

rAndT rotateModelica2OSG(osg::Matrix3 T, osg::Vec3f r, osg::Vec3f dir, float length)
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

  // Since in OSG, the rotation starts at the center of symmetry and in MSL at the end of the body,
  // we need an offset here of half the length of the vector
  osg::Vec3f r_offset = dirs._lDir * length / 2;

  res._r = V3mulMat3(r_offset, T) + r;
  res._T = Mat3mulMat3(T0, T);

  return res;
}
