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

#ifndef VISUALIZATION_H
#define VISUALIZATION_H

#include <stdlib.h>
#include <memory.h>
#include <iostream>
#include <functional>

#include <QColor>
#include <QImage>
#include <QOpenGLContext> // must be included before OSG headers

#include <osg/Transform>
#include <osg/AutoTransform>
#include <osg/MatrixTransform>
#include <osg/StateSet>
#include <osg/Image>
#include <osg/Geode>
#include <osg/Group>
#include <osg/Node>
#include <osg/NodeVisitor>
#include <osg/NodeCallback>
#include <osg/RenderInfo>
#include <osgUtil/RenderBin>
#include <osgUtil/RenderLeaf>
#include <osgViewer/View>

#include <OpenThreads/Mutex>

#include "ExtraShapes.h"

#include "AnimationUtil.h"
#include "TimeManager.h"
#include "rapidxml.hpp"

#include "AbstractVisualizer.h"
#include "Shape.h"
#include "Vector.h"

class VisualizationAbstract; // Forward declaration for passing a pointer to various constructors before class declaration

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
  virtual void apply(osg::Geode& node) override;
  virtual void apply(osg::Transform& node) override;
  virtual void apply(osg::AutoTransform& node); // Work-around for osg::NodeVisitor::apply(osg::AutoTransform&) (see OSG commit a4b0dc7)
  virtual void apply(osg::MatrixTransform& node) override;
  osg::Image* convertImage(const QImage& iImage);
  void applyTexture(osg::StateSet* ss, const std::string& imagePath);
  void changeColor(osg::StateSet* ss, const QColor color);
  void changeTransparency(osg::StateSet* ss, const float transparency);
public:
  AbstractVisualizerObject* _visualizer;
  bool _changeMaterialProperties;
};

class InfoVisitor : public osg::NodeVisitor
{
public:
  InfoVisitor();
  ~InfoVisitor() = default;
  InfoVisitor(const InfoVisitor& iv) = delete;
  InfoVisitor& operator=(const InfoVisitor& iv) = delete;
  std::string spaces();
  virtual void apply(osg::Node& node) override;
  virtual void apply(osg::Geode& node) override;
private:
  unsigned int _level;
};

class AutoTransformDrawCallback : public osgUtil::RenderBin::DrawCallback
{
public:
  AutoTransformDrawCallback();
  ~AutoTransformDrawCallback() = default;
  AutoTransformDrawCallback(const AutoTransformDrawCallback& callback) = delete;
  AutoTransformDrawCallback& operator=(const AutoTransformDrawCallback& callback) = delete;
  virtual void drawImplementation(osgUtil::RenderBin* bin, osg::RenderInfo& renderInfo, osgUtil::RenderLeaf*& previous) override;
};

class AutoTransformCullCallback : public osg::NodeCallback
{
public:
  AutoTransformCullCallback(VisualizationAbstract* visualization);
  ~AutoTransformCullCallback() = default;
  AutoTransformCullCallback(const AutoTransformCullCallback& callback) = delete;
  AutoTransformCullCallback& operator=(const AutoTransformCullCallback& callback) = delete;
  virtual void operator()(osg::Node* node, osg::NodeVisitor* nv) override; // Work-around for osg::Callback::run(osg::Object*, osg::Object*) (see OSG commit 977ec20)
protected:
  osg::ref_ptr<AutoTransformDrawCallback> _atDrawCallback;
  VisualizationAbstract* mpVisualization;
};

class AutoTransformVisualizer : public osg::AutoTransform
{
public:
  AutoTransformVisualizer(AbstractVisualizerObject* visualizer);
  ~AutoTransformVisualizer() = default;
  AutoTransformVisualizer(const AutoTransformVisualizer& transform) = delete;
  AutoTransformVisualizer& operator=(const AutoTransformVisualizer& transform) = delete;
  AbstractVisualizerObject* getVisualizerObject() const {return mpVisualizer;}
protected:
  AbstractVisualizerObject* mpVisualizer;
};

class OSGScene
{
public:
  OSGScene(VisualizationAbstract* visualization);
  ~OSGScene() = default;
  OSGScene(const OSGScene& osgs) = delete;
  OSGScene& operator=(const OSGScene& osgs) = delete;
  void setUpScene(std::vector<ShapeObject>& shapes);
  void setUpScene(std::vector<VectorObject>& vectors);
  osg::ref_ptr<osg::Group> getRootNode();
  std::string getPath() const;
  void setPath(const std::string path);
private:
  osg::ref_ptr<AutoTransformCullCallback> _atCullCallback;
  osg::ref_ptr<osg::Group> _rootNode;
  std::string _path;
};

class OMVisScene
{
public:
  OMVisScene(VisualizationAbstract* visualization);
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
  void initVisObjects();
  const std::string getModelFile() const;
  const std::string getPath() const;
  const std::string getXMLFileName() const;
  AbstractVisualizerObject* getVisualizerObjectByIdx(const std::size_t visualizerIdx);
  AbstractVisualizerObject* getVisualizerObjectByID(const std::string& visualizerID);
  int getVisualizerObjectIndexByID(const std::string& visualizerID);
private:
  void appendVisVariable(const rapidxml::xml_node<>* node, std::vector<std::string>& visVariables) const;
public:
  std::vector<ShapeObject> _shapes;
  std::vector<VectorObject> _vectors;
private:
  std::string _modelFile;
  std::string _path;
  std::string _xmlFileName;
};

class VisualizationAbstract
{
public:
  VisualizationAbstract();
  VisualizationAbstract(const std::string& modelFile, const std::string& path, const VisType visType = VisType::NONE);
  virtual ~VisualizationAbstract() = default;

  virtual void initData();
  void initVisualization();
  void setUpScene();
  virtual void initializeVisAttributes(const double time) = 0;
  virtual void updateVisAttributes(const double time) = 0;
  void chooseVectorScales(osgViewer::View* view, OpenThreads::Mutex* mutex = nullptr, std::function<void()> frame = nullptr);
  void sceneUpdate();
  void updateVisualizer(const std::string& visualizerName   , bool changeMaterialProperties = true);
  void modifyVisualizer(const std::string& visualizerName   , bool changeMaterialProperties = true);
  void updateVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties = true);
  void modifyVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties = true);
  void updateVisualizer(AbstractVisualizerObject& visualizer, bool changeMaterialProperties = true);
  void modifyVisualizer(AbstractVisualizerObject& visualizer, bool changeMaterialProperties = true);
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
rAndT rotateModelica2OSG(osg::Matrix3 T, osg::Vec3f r, osg::Vec3f r_shape, osg::Vec3f lDir, osg::Vec3f wDir, std::string type);
rAndT rotateModelica2OSG(osg::Matrix3 T, osg::Vec3f r, osg::Vec3f dir);

#endif
