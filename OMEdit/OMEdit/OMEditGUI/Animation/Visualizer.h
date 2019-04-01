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

#ifndef VISUALIZER_H
#define VISUALIZER_H

#include <stdlib.h>
#include <memory.h>
#include <iostream>

#include <QImage>
#include <osg/NodeVisitor>
#include <osg/Geode>
#include <osg/MatrixTransform>
#include <osg/ShapeDrawable>
#include <osg/Material>
#include <osgDB/ReadFile>
#include <osg/Texture2D>
#include <osg/TexMat>

#include "AnimationUtil.h"
#include "ExtraShapes.h"
#include "rapidxml.hpp"
#include "Shapes.h"
#include "TimeManager.h"

struct UserSimSettingsMAT
{
  double speedup;
};

class UpdateVisitor : public osg::NodeVisitor
{
 public:
  UpdateVisitor();
  virtual ~UpdateVisitor() = default;
  UpdateVisitor(const UpdateVisitor& uv) = delete;
  UpdateVisitor& operator=(const UpdateVisitor& uv) = delete;
  virtual void apply(osg::Geode& node);
  virtual void apply(osg::MatrixTransform& node);
  void makeTransparent(osg::Geode& node, float transpCoeff);
  void applyTexture(osg::StateSet* ss, std::string imagePath);
  void changeColor(osg::StateSet* ss, float r, float g, float b);
  osg::Image* convertImage(const QImage& iImage);
public:
  ShapeObject _shape;
};

class InfoVisitor : public osg::NodeVisitor
{
public:
  InfoVisitor();
  ~InfoVisitor() = default;
  InfoVisitor(const InfoVisitor& iv) = delete;
  InfoVisitor& operator=(const InfoVisitor& iv) = delete;
  std::string spaces();
  virtual void apply(osg::Node& node);
  virtual void apply(osg::Geode& node);
private:
  unsigned int _level;
};

class OSGScene
{
 public:
  OSGScene();
  ~OSGScene() = default;
  OSGScene(const OSGScene& osgs) = delete;
  OSGScene& operator=(const OSGScene& osgs) = delete;
  int setUpScene(std::vector<ShapeObject> allShapes);
  osg::ref_ptr<osg::Group> getRootNode();
  std::string getPath() const;
  void setPath(const std::string path);
 private:
  osg::ref_ptr<osg::Group> _rootNode;
  std::string _path;
};

class OMVisScene
{
 public:
  OMVisScene();
  ~OMVisScene() = default;
  OMVisScene(const OMVisScene& omvv) = delete;
  OMVisScene& operator=(const OMVisScene& omvv) = delete;
  void dumpOSGTreeDebug();
  OSGScene& getScene();
 private:
  OSGScene _scene;
};

class OMVisualBase
{
 public:
  OMVisualBase(const std::string& modelFile, const std::string& path);
  OMVisualBase() = delete;
  ~OMVisualBase() = default;
  OMVisualBase(const OMVisualBase& omvb) = delete;
  OMVisualBase& operator=(const OMVisualBase& omvb) = delete;
  void initXMLDoc();
  void clearXMLDoc();
  void initVisObjects();
  const std::string getModelFile() const;
  const std::string getPath() const;
  rapidxml::xml_node<>* getFirstXMLNode() const;
  const std::string getXMLFileName() const;
  ShapeObject* getShapeObjectByID(std::string shapeID);
  int getShapeObjectIndexByID(std::string shapeID);
private:
  void appendVisVariable(const rapidxml::xml_node<>* node, std::vector<std::string>& visVariables) const;
public:
  std::vector<ShapeObject> _shapes;
 private:
  std::string _modelFile;
  std::string _path;
  std::string _xmlFileName;
  rapidxml::xml_document<> _xmlDoc;
};

class VisualizerAbstract
{
 public:
  VisualizerAbstract();
  VisualizerAbstract(const std::string& modelFile, const std::string& path, const VisType visType = VisType::NONE);
  virtual ~VisualizerAbstract() = default;

  virtual void initData();
  void initVisualization();
  void setUpScene();
  virtual void initializeVisAttributes(const double time) = 0;
  virtual void updateVisAttributes(const double time) = 0;
  void sceneUpdate();
  void modifyShape(std::string shapeName);
  virtual void simulate(TimeManager& omvm) = 0;
  virtual void updateScene(const double time) = 0;

  TimeManager* getTimeManager() const;
  OMVisualBase* getBaseData() const;
  VisType getVisType() const;
  OMVisScene* getOMVisScene() const;
  std::string getModelFile() const;

  //virtual void setSimulationSettings(const UserSimSettingsFMU& simSetFMU) { };
  //virtual void simulate(TimeManager& omvm) = 0;
  virtual void startVisualization();
  virtual void pauseVisualization();
protected:
  const VisType _visType;
  OMVisualBase* mpOMVisualBase;
  OMVisScene* mpOMVisScene;
  UpdateVisitor* mpUpdateVisitor;
  TimeManager* mpTimeManager;
};

osg::Vec3f Mat3mulV3(osg::Matrix3 M, osg::Vec3f V);
osg::Vec3f V3mulMat3(osg::Vec3f V, osg::Matrix3 M);
osg::Matrix3 Mat3mulMat3(osg::Matrix3 M1, osg::Matrix3 M2);
osg::Vec3f normalize(osg::Vec3f vec);
osg::Vec3f cross(osg::Vec3f vec1, osg::Vec3f vec2);
Directions fixDirections(osg::Vec3f lDir, osg::Vec3f wDir);
void assemblePokeMatrix(osg::Matrix& M, const osg::Matrix3& T, const osg::Vec3f& r);
rAndT rotateModelica2OSG(osg::Vec3f r, osg::Vec3f r_shape, osg::Matrix3 T, osg::Vec3f lDirIn, osg::Vec3f wDirIn, float length,/* float width, float height,*/ std::string type);

#endif
