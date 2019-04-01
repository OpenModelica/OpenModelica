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

#include "Visualizer.h"

#if (QT_VERSION < QT_VERSION_CHECK(5, 2, 0))
#include <QGLWidget>
#endif
#include <osg/Image>
#include <osg/Shape>
#include <osg/Node>
#include <osgDB/Export>
#include <osgDB/Registry>
#include <osgDB/WriteFile>

OMVisualBase::OMVisualBase(const std::string& modelFile, const std::string& path)
  : _shapes(),
    _modelFile(modelFile),
    _path(path),
    _xmlFileName(assembleXMLFileName(modelFile, path)),
    _xmlDoc()
{
}

/*!
 * \brief OMVisualBase::getShapeObjectByID
 * get the shapeObject with the same shapeID
 *\param the name of the shape
 *\return the selected shape
 */
ShapeObject* OMVisualBase::getShapeObjectByID(std::string shapeID)
{
  for(std::vector<ShapeObject>::iterator shape =_shapes.begin() ; shape < _shapes.end(); ++shape )
  {
      if(shape->_id == shapeID) {
        return &(*shape);
      }
  }
  return 0;
}

/*!
 * \brief OMVisualBase::getShapeObjectIndexByID
 * get the shapeObjectIndex with the same shapeID
 *\param the name of the shape
 *\return the selected shape
 */
int OMVisualBase::getShapeObjectIndexByID(std::string shapeID)
{
  int i = 0;
  for(std::vector<ShapeObject>::iterator shape =_shapes.begin() ; shape < _shapes.end(); ++shape )
  {
      if(shape->_id == shapeID) {
        return i;
      }
   i +=1;
  }
  return -1;
}

void OMVisualBase::initXMLDoc()
{
  // Check if the XML file is available.
  if (!fileExists(_xmlFileName))
  {
    std::string msg = "Could not find the visual XML file" + _xmlFileName + ".";
    std::cout<<msg<<std::endl;
  }
  // read xml
  osgDB::ifstream t;
  // unused const char * titel = _xmlFileName.c_str();
  t.open(_xmlFileName.c_str(), std::ios::binary);      // open input file
  t.seekg(0, std::ios::end);    // go to the end
  int length = t.tellg();       // report location (this is the length)
  t.seekg(0, std::ios::beg);    // go back to the beginning
  char* buffer = new char[length];    // allocate memory for a buffer of appropriate dimension
  t.read(buffer, length);       // read the whole file into the buffer
  t.close();
  std::string buff = std::string(buffer);  // strings are good
  std::string buff2 = buff.substr(0, buff.find("</visualization>"));  // remove the crappy ending
  buff2.append("</visualization>");
  char* buff3 = strdup(buff2.c_str());  // cast to char*
  _xmlDoc.parse<0>(buff3);

}

void OMVisualBase::initVisObjects()
{
  rapidxml::xml_node<>* rootNode = _xmlDoc.first_node();
  ShapeObject shape;
  rapidxml::xml_node<>* expNode;

  for (rapidxml::xml_node<>* shapeNode = rootNode->first_node("shape"); shapeNode; shapeNode = shapeNode->next_sibling())
  {
    expNode = shapeNode->first_node((const char*) "ident")->first_node();
    shape._id = std::string(expNode->value());

    expNode = shapeNode->first_node((const char*) "type")->first_node();

    if (expNode == 0)
    {
      std::cout<<"The type of  "<<shape._id<<" is not supported right in the visxml file."<<std::endl;
    }
    else
    {
      shape._type = std::string(expNode->value());
      if (isCADType(shape._type))
      {
        shape._fileName = extractCADFilename(shape._type);

        if (dxfFileType(shape._fileName))
        {
          shape._type = "dxf";
        }
        else if (stlFileType(shape._fileName))
        {
          shape._type = "stl";
        }

        if (!fileExists(shape._fileName))
        {
          std::cout<<"Could not find the file "<<shape._fileName<<std::endl;
        }
      }
      //std::cout<<"type "<<shape._id<<std::endl;
      //std::cout<<"type "<<shape._type<<std::endl;

      expNode = shapeNode->first_node((const char*) "length")->first_node();
      shape._length = getObjectAttributeForNode(expNode);
      expNode = shapeNode->first_node((const char*) "width")->first_node();
      shape._width = getObjectAttributeForNode(expNode);
      expNode = shapeNode->first_node((const char*) "height")->first_node();
      shape._height = getObjectAttributeForNode(expNode);

      expNode = shapeNode->first_node((const char*) "lengthDir")->first_node();
      shape._lDir[0] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._lDir[1] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._lDir[2] = getObjectAttributeForNode(expNode);

      expNode = shapeNode->first_node((const char*) "widthDir")->first_node();
      shape._wDir[0] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._wDir[1] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._wDir[2] = getObjectAttributeForNode(expNode);

      expNode = shapeNode->first_node((const char*) "r")->first_node();
      shape._r[0] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._r[1] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._r[2] = getObjectAttributeForNode(expNode);

      expNode = shapeNode->first_node((const char*) "r_shape")->first_node();
      shape._rShape[0] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._rShape[1] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._rShape[2] = getObjectAttributeForNode(expNode);

      expNode = shapeNode->first_node((const char*) "color")->first_node();
      shape._color[0] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._color[1] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._color[2] = getObjectAttributeForNode(expNode);

      expNode = shapeNode->first_node((const char*) "T")->first_node();
      shape._T[0] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._T[1] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._T[2] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._T[3] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._T[4] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._T[5] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._T[6] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._T[7] = getObjectAttributeForNode(expNode);
      expNode = expNode->next_sibling();
      shape._T[8] = getObjectAttributeForNode(expNode);

      expNode = shapeNode->first_node((const char*) "specCoeff")->first_node();
      shape._specCoeff = getObjectAttributeForNode(expNode);

      expNode = shapeNode->first_node((const char*) "extra")->first_node();
      shape._extra = getObjectAttributeForNode(expNode);

      _shapes.push_back(shape);
    }
  } // end for-loop
}

void OMVisualBase::clearXMLDoc()
{
  _xmlDoc.clear();
}

rapidxml::xml_node<>* OMVisualBase::getFirstXMLNode() const
{
  return _xmlDoc.first_node();
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
    char* cref = node->value();
    visVariables.push_back(std::string(cref));
  }
}


///--------------------------------------------------///
///ABSTRACT VISUALIZER CLASS-------------------------///
///--------------------------------------------------///

VisualizerAbstract::VisualizerAbstract()
  : _visType(VisType::NONE),
    mpOMVisualBase(nullptr),
    mpOMVisScene(nullptr),
    mpUpdateVisitor(nullptr)
{
  mpTimeManager = new TimeManager(0.0, 0.0, 1.0, 0.0, 0.1, 0.0, 1.0);
}

VisualizerAbstract::VisualizerAbstract(const std::string& modelFile, const std::string& path, const VisType visType)
  : _visType(visType),
    mpOMVisualBase(nullptr),
    mpOMVisScene(new OMVisScene()),
    mpUpdateVisitor(new UpdateVisitor()),
    mpTimeManager(new TimeManager(0.0, 0.0, 0.0, 0.0, 0.1, 0.0, 100.0))
{
  mpOMVisualBase = new OMVisualBase(modelFile, path);
  mpOMVisScene->getScene().setPath(path);
}

void VisualizerAbstract::initData()
{
  // In case of reloading, we need to make sure, that we have empty members.
  mpOMVisualBase->clearXMLDoc();
  // Initialize XML file and get visAttributes.
  mpOMVisualBase->initXMLDoc();
  mpOMVisualBase->initVisObjects();
}

void VisualizerAbstract::initVisualization()
{
  initializeVisAttributes(mpTimeManager->getStartTime());
  mpTimeManager->setVisTime(mpTimeManager->getStartTime());
  mpTimeManager->setRealTimeFactor(0.0);
  mpTimeManager->setPause(true);
}

TimeManager* VisualizerAbstract::getTimeManager() const
{
  return mpTimeManager;
}

void VisualizerAbstract::modifyShape(std::string shapeName)
{
  int shapeIdx = getBaseData()->getShapeObjectIndexByID(shapeName);
  ShapeObject* shape = getBaseData()->getShapeObjectByID(shapeName);
  shape->setStateSetAction(stateSetAction::modify);
  mpUpdateVisitor->_shape = *shape;
  osg::ref_ptr<osg::Node> child = mpOMVisScene->getScene().getRootNode()->getChild(shapeIdx);  // the transformation
  child->accept(*mpUpdateVisitor);
  shape->setStateSetAction(stateSetAction::update);
}


void VisualizerAbstract::sceneUpdate()
{
  //measure realtime
  mpTimeManager->updateTick();
  //update scene and set next time step
  if (!mpTimeManager->isPaused()) {
    updateScene(mpTimeManager->getVisTime());
    //finish animation with pause when endtime is reached
    if (mpTimeManager->getVisTime() >= mpTimeManager->getEndTime()) {
      mpTimeManager->setPause(true);
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

void VisualizerAbstract::setUpScene()
{
  // Build scene graph.
  mpOMVisScene->getScene().setUpScene(mpOMVisualBase->_shapes);
}

VisType VisualizerAbstract::getVisType() const
{
  return _visType;
}

OMVisualBase* VisualizerAbstract::getBaseData() const
{
  return mpOMVisualBase;
}



OMVisScene* VisualizerAbstract::getOMVisScene() const
{
  return mpOMVisScene;
}

std::string VisualizerAbstract::getModelFile() const
{
  return mpOMVisualBase->getModelFile();
}

void VisualizerAbstract::startVisualization()
{
  if (mpTimeManager->getVisTime() < mpTimeManager->getEndTime() - 1.e-6)
  {
    mpTimeManager->setPause(false);
  }
  else
    std::cout<<"There is nothing left to visualize. Initialize the model first."<<std::endl;
}

void VisualizerAbstract::pauseVisualization()
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

int OSGScene::setUpScene(std::vector<ShapeObject> allShapes)
{
  int isOk(0);
  for (std::vector<ShapeObject>::size_type i = 0; i != allShapes.size(); i++) {
    ShapeObject shape = allShapes[i];
    osg::ref_ptr<osg::Geode> geode;
    osg::ref_ptr<osg::StateSet> ss;

    //color
    osg::ref_ptr<osg::Material> material = new osg::Material();
    material->setDiffuse(osg::Material::FRONT, osg::Vec4f(0.0, 0.0, 0.0, 0.0));

    //matrix transformation
    osg::ref_ptr<osg::MatrixTransform> transf = new osg::MatrixTransform();

    //cad node
    if (shape._type.compare("stl") == 0) {
      //std::cout<<"Its a CAD and the filename is "<<shape._fileName<<std::endl;
      osg::ref_ptr<osg::Node> node = osgDB::readNodeFile(shape._fileName);
      if (node) {
        osg::ref_ptr<osg::StateSet> ss = node->getOrCreateStateSet();
        ss->setAttribute(material.get());
        node->setStateSet(ss);
        transf->addChild(node.get());
      }
    } else if ((shape._type.compare("dxf") == 0)) {
      std::string name = shape._fileName;
      DXFile* shape = new DXFile(name);
      geode = new osg::Geode();
      geode->addDrawable(shape);
      transf->addChild(geode);
    } else { //geode with shape drawable
      osg::ref_ptr<osg::ShapeDrawable> shapeDraw = new osg::ShapeDrawable();
      shapeDraw->setColor(osg::Vec4(1.0, 1.0, 1.0, 1.0));
      geode = new osg::Geode();
      geode->addDrawable(shapeDraw.get());
      osg::ref_ptr<osg::StateSet> ss = geode->getOrCreateStateSet();
      ss->setAttribute(material.get());
      geode->setStateSet(ss);
      transf->addChild(geode.get());
    }
    _rootNode->addChild(transf.get());
  }
  return isOk;
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
  : _shape()
{
  setTraversalMode(NodeVisitor::TRAVERSE_ALL_CHILDREN);
}

/**
 MatrixTransform
 */
void UpdateVisitor::apply(osg::MatrixTransform& node)
{
  //std::cout<<"MT "<<node.className()<<"  "<<node.getName()<<std::endl;
  node.setMatrix(_shape._mat);
  traverse(node);
}

/**
 Geode
 */
void UpdateVisitor::apply(osg::Geode& node)
{
  //std::cout<<"GEODE "<< _shape._id<<" "<<_shape.getTransparency()<<std::endl;
  osg::ref_ptr<osg::StateSet> ss = node.getOrCreateStateSet();
  node.setName(_shape._id);
  switch(_shape.getStateSetAction())
  {
  case(stateSetAction::update):
   {
    //its a drawable and not a cad file so we have to create a new drawable
    if (_shape._type.compare("dxf") != 0 and (_shape._type.compare("stl") != 0))
    {
    osg::ref_ptr<osg::Drawable> draw = node.getDrawable(0);
    draw->dirtyDisplayList();
    if (_shape._type == "pipe")
    {
      node.removeDrawable(draw);
      draw = new Pipecylinder((_shape._width.exp * _shape._extra.exp) / 2, (_shape._width.exp) / 2, _shape._length.exp);
    }
    else if (_shape._type == "pipecylinder")
    {
      node.removeDrawable(draw);
      draw = new Pipecylinder((_shape._width.exp * _shape._extra.exp) / 2, (_shape._width.exp) / 2, _shape._length.exp);
    }
    else if (_shape._type == "spring")
    {
      node.removeDrawable(draw);
      draw = new Spring(_shape._width.exp, _shape._height.exp, _shape._extra.exp, _shape._length.exp);
    }
    else if (_shape._type == "cylinder")
    {
      draw->setShape(new osg::Cylinder(osg::Vec3f(0.0, 0.0, 0.0), _shape._width.exp / 2.0, _shape._length.exp));
    }
    else if (_shape._type == "box")
    {
      draw->setShape(new osg::Box(osg::Vec3f(0.0, 0.0, 0.0), _shape._width.exp, _shape._height.exp, _shape._length.exp));
    }
    else if (_shape._type == "cone")
    {
      draw->setShape(new osg::Cone(osg::Vec3f(0.0, 0.0, 0.0), _shape._width.exp / 2.0, _shape._length.exp));
    }
    else if (_shape._type == "sphere")
    {
      draw->setShape(new osg::Sphere(osg::Vec3f(0.0, 0.0, 0.0), _shape._length.exp / 2.0));
    }
    else
    {
      std::cout<<"Unknown type "<<_shape._type<<", we make a capsule."<<std::endl;
      draw->setShape(new osg::Capsule(osg::Vec3f(0.0, 0.0, 0.0), 0.1, 0.5));
    }
    //std::cout<<"SHAPE "<<draw->getShape()->className()<<std::endl;
    node.addDrawable(draw.get());
    }
    break;
   }//end case

  case(stateSetAction::modify):
   {
     //apply texture
     applyTexture(ss, _shape.getTextureImagePath());
     break;
   }//end case

   default:
   {break;}

  }//end switch

  //set color
  if (_shape._type.compare("dxf") != 0)
    changeColor(ss, _shape._color[0].exp, _shape._color[1].exp, _shape._color[2].exp);

  //set transparency
  makeTransparent(node, _shape.getTransparency());

  node.setStateSet(ss);
  traverse(node);
}

/*!
 * \brief UpdateVisitor::changeColor
 * changes color for a geode
 */
void UpdateVisitor::changeColor(osg::StateSet* ss, float r, float g, float b)
{
  osg::Material *material;
  if (!ss->getAttribute(osg::StateAttribute::MATERIAL))
    material = new osg::Material();
  else
    material = dynamic_cast<osg::Material*>(ss->getAttribute(osg::StateAttribute::MATERIAL));
  material->setDiffuse(osg::Material::FRONT, osg::Vec4f(r / 255, g / 255, b / 255, 1.0));
  ss->setAttribute(material);
}


/*!
 * \brief UpdateVisitor::applyTexture
 * sets a texture for a geode
 */
void UpdateVisitor::applyTexture(osg::StateSet* ss, std::string imagePath)
{
  if (imagePath.compare(""))
  {
    osg::Image *image = nullptr;
    std::string resIdent = ":/Resources";
    if(!imagePath.compare(0,resIdent.length(),resIdent))
    {
      QImage* qim = new QImage(QString::fromStdString(imagePath));
      image = convertImage(*qim);
      image->setInternalTextureFormat(GL_RGBA);
    }
    else
    {
      image = osgDB::readImageFile(imagePath);
    }
    if (image)
    {
    osg::Texture2D *texture = new osg::Texture2D;
    texture->setDataVariance(osg::Object::DYNAMIC);
    texture->setFilter(osg::Texture::MIN_FILTER, osg::Texture::LINEAR_MIPMAP_LINEAR);
    texture->setFilter(osg::Texture::MAG_FILTER, osg::Texture::LINEAR);
    texture->setWrap(osg::Texture::WRAP_S, osg::Texture::CLAMP);
    texture->setImage(image);
    texture->setResizeNonPowerOfTwoHint(false);// dont output console message about scaling
    ss->setTextureAttributeAndModes(0, texture, osg::StateAttribute::ON);
    }
  }
  else
  {
    ss->getTextureAttributeList().clear();
    ss->getTextureModeList().clear();
  }
}

osg::Image* UpdateVisitor::convertImage(const QImage& iImage)
{
  osg::Image* osgImage = new osg::Image();
  if (false == iImage.isNull()) {
#if (QT_VERSION >= QT_VERSION_CHECK(5, 2, 0))
    QImage glImage = iImage.convertToFormat(QImage::Format_RGBA8888_Premultiplied);
#else
    QImage glImage = QGLWidget::convertToGLFormat(iImage);
#endif
    if (false == glImage.isNull()) {
      unsigned char* data = new unsigned char[glImage.byteCount()];
      for(int i=0; i < glImage.byteCount(); ++i) {
        data[i] = glImage.bits()[i];
      }
      osgImage->setImage(glImage.width(), glImage.height(), 1, 4, GL_RGBA, GL_UNSIGNED_BYTE, data, osg::Image::USE_NEW_DELETE, 1);
    }
  }
  return osgImage;
}


/*!
 * \brief UpdateVisitor::makeTransparent
 * makes a geode transparent
 */
void UpdateVisitor::makeTransparent(osg::Geode& node, float transpCoeff)
{
  if (_shape.getTransparency())
      {
      node.getStateSet()->setMode( GL_BLEND, osg::StateAttribute::ON );
      node.getStateSet()->setRenderingHint(osg::StateSet::TRANSPARENT_BIN);
      osg::Material *material;
      if (NULL == node.getStateSet()->getAttribute(osg::StateAttribute::MATERIAL))
      {
        material = new osg::Material();
      }
      else
      {
        material = dynamic_cast<osg::Material*>(node.getStateSet()->getAttribute(osg::StateAttribute::MATERIAL));
      }
      material->setTransparency(osg::Material::FRONT_AND_BACK, transpCoeff);
      node.getStateSet()->setAttributeAndModes(material, osg::StateAttribute::OVERRIDE);
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
    osg::Drawable* drawable = geode.getDrawable(i);
    std::cout << spaces() << drawable->libraryName() << "::" << drawable->className() << std::endl;
  }
  traverse(geode);
  --_level;
}


osg::Vec3f Mat3mulV3(osg::Matrix3 M, osg::Vec3f V)
{
  return osg::Vec3f(M[0] * V[0] + M[1] * V[1] + M[2] * V[2], M[3] * V[0] + M[4] * V[1] + M[5] * V[2], M[6] * V[0] + M[7] * V[1] + M[8] * V[2]);
}

osg::Vec3f V3mulMat3(osg::Vec3f V, osg::Matrix3 M)
{
  return osg::Vec3f(M[0] * V[0] + M[3] * V[1] + M[6] * V[2], M[1] * V[0] + M[4] * V[1] + M[7] * V[2], M[2] * V[0] + M[5] * V[1] + M[8] * V[2]);
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
    vec / 100 * 1.e-15;
  return vecOut;
}


osg::Vec3f cross(osg::Vec3f vec1, osg::Vec3f vec2)
{
  osg::Vec3f vecOut;
  return osg::Vec3f(vec1[1] * vec2[2] - vec1[2] * vec2[1], vec1[2] * vec2[0] - vec1[0] * vec2[2], vec1[0] * vec2[1] - vec1[1] * vec2[0]);
}


Directions fixDirections(osg::Vec3f lDir, osg::Vec3f wDir)
{
  Directions dirs;
  osg::Vec3f e_x;
  osg::Vec3f e_y;

  //lengthDirection
  double abs_n_x = lDir.length();
  if (abs_n_x < 1e-10)
    e_x = osg::Vec3f(1.0, 0.0, 0.0);
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

//osg::Matrix assemblePokeMatrix(osg::Matrix M, const osg::Matrix3& T, const osg::Vec3f& r)
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


rAndT rotateModelica2OSG(osg::Vec3f r, osg::Vec3f r_shape, osg::Matrix3 T, osg::Vec3f lDirIn, osg::Vec3f wDirIn, float length,/* float width, float height,*/ std::string type)
{
  rAndT res;

  Directions dirs = fixDirections(lDirIn, wDirIn);
  osg::Vec3f hDir = dirs._lDir ^ dirs._wDir;
  //std::cout<<"lDir1 "<<dirs._lDir[0]<<", "<<dirs._lDir[1]<<", "<<dirs._lDir[2]<<", "<<std::endl;
  //std::cout<<"wDir1 "<<dirs._wDir[0]<<", "<<dirs._wDir[1]<<", "<<dirs._wDir[2]<<", "<<std::endl;
  //std::cout<<"hDir "<<hDir[0]<<", "<<hDir[1]<<", "<<hDir[2]<<", "<<std::endl;

  osg::Vec3f r_offset = osg::Vec3f(0.0, 0.0, 0.0);  // since in osg, the rotation starts in the symmetric centre and in msl at the end of the body, we need an offset here of l/2 for some geometries
  osg::Matrix3 T0 = osg::Matrix3(dirs._wDir[0], dirs._wDir[1], dirs._wDir[2], hDir[0], hDir[1], hDir[2], dirs._lDir[0], dirs._lDir[1], dirs._lDir[2]);
  //std::cout << "T0 " << T0[0] << ", " << T0[1]<< ", " << T0[2]<< ", " << std::endl;
  //std::cout << "   " << T0[3] << ", " << T0[4] << ", " << T0[5]<< ", " << std::endl;
  //std::cout << "   " << T0[6]<< ", " << T0[7] << ", " << T0[8]<< ", " << std::endl;

  if ((type == "cylinder") || (type == "box"))
  {
    r_offset = dirs._lDir * length / 2.0;
    res._r = V3mulMat3(r_shape + r_offset, T);
    res._r = res._r + r;
    res._T = Mat3mulMat3(T0, T);
  }
  else if (type == "sphere")
  {
    T0 = osg::Matrix3(dirs._lDir[0], dirs._lDir[1], dirs._lDir[2], dirs._wDir[0], dirs._wDir[1], dirs._wDir[2], hDir[0], hDir[1], hDir[2]);
    r_offset = dirs._lDir * length / 2.0;
    res._r = V3mulMat3(r_shape + r_offset, T);
    res._r = res._r + r;
    res._T = Mat3mulMat3(T0, T);
  }
  else if ((type == "stl") || (type == "dxf"))
  {
    T0 = osg::Matrix3(dirs._lDir[0], dirs._lDir[1], dirs._lDir[2], dirs._wDir[0], dirs._wDir[1], dirs._wDir[2], hDir[0], hDir[1], hDir[2]);
    res._r = V3mulMat3(r_shape, T);
    res._r = res._r + r;
    res._T = Mat3mulMat3(T0, T);
  }
  else if ((type == "spring")||(type == "pipecylinder")||(type == "cone") || (type == "pipe"))
  {
    res._r = V3mulMat3(r_shape, T);
    res._r = res._r + r;
    res._T = Mat3mulMat3(T0, T);
  }
  else
  {
    r_offset = dirs._lDir * length / 2.0;
    res._r = V3mulMat3(r_shape + r_offset, T);
    res._r = res._r + r;
    res._T = Mat3mulMat3(T0, T);
  }
  return res;
}

