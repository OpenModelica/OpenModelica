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

#ifndef VISUALIZATION_H
#define VISUALIZATION_H

#include <stdlib.h>
#include <memory.h>
#include <iostream>
#include <functional>

#include <QColor>
#include <QImage>

// The OpenSceneGraph renderer (OSGScene/UpdateVisitor/...) does not build for
// Emscripten; on wasm only the renderer-neutral data classes and math helpers of
// this header are used, with a Qt Quick 3D backend (see Animation/Quick3D/).
#if !defined(OMEDIT_ANIMATION_QUICK3D)
#include <QOpenGLContext> // must be included before OSG headers

#include <osg/Version>
#include <osg/Uniform>
#include <osg/Transform>
#include <osg/AutoTransform>
#include <osg/MatrixTransform>
#include <osg/Image>
#include <osg/Material>
#include <osg/StateSet>
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
#endif

#include "AnimationUtil.h"
#include "TimeManager.h"
#include "rapidxml.hpp"

#include "AnimationScene.h"
#include "AbstractVisualizer.h"
#include "Shape.h"
#include "Vector.h"

class VisualizationAbstract; // Forward declaration for passing a pointer to various constructors before class declaration

#if !defined(OMEDIT_ANIMATION_QUICK3D)
class UpdateVisitor : public osg::NodeVisitor
{
public:
  UpdateVisitor();
  virtual ~UpdateVisitor() = default;
  UpdateVisitor(const UpdateVisitor& uv) = delete;
  UpdateVisitor& operator=(const UpdateVisitor& uv) = delete;
  virtual void apply(osg::Geode& node) override;
  virtual void apply(osg::Transform& node) override;
#if OSG_MIN_VERSION_REQUIRED(3, 6, 0)
  virtual void apply(osg::AutoTransform& node) override;
#else
  virtual void apply(osg::AutoTransform& node); // Work-around for osg::NodeVisitor::apply(osg::AutoTransform&) (see OSG commit a4b0dc7)
#endif
  virtual void apply(osg::MatrixTransform& node) override;
  osg::Image* convertImage(const QImage& iImage);
  void applyTexture(osg::StateSet* ss, const std::string& imagePath);
  void changeColorOfMaterial(osg::StateSet* ss, const osg::Material::ColorMode mode, const QColor color, const float specular);
  void changeTransparencyOfMaterial(osg::StateSet* ss, const float transparency);
  template<typename Vec4Array, unsigned int scale>
  void changeTransparencyOfGeometry(osg::Geode& geode, const float transparency);
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
private:
  osg::ref_ptr<AutoTransformDrawCallback> _atDrawCallback;
  VisualizationAbstract* _visualization;
};

class AutoTransformVisualizer : public osg::AutoTransform
{
public:
  AutoTransformVisualizer(AbstractVisualizerObject* visualizer);
  ~AutoTransformVisualizer() = default;
  AutoTransformVisualizer(const AutoTransformVisualizer& transform) = delete;
  AutoTransformVisualizer& operator=(const AutoTransformVisualizer& transform) = delete;
  AbstractVisualizerObject* getVisualizerObject() const {return _visualizer;}
private:
  AbstractVisualizerObject* _visualizer;
};

class OSGScene : public AnimationScene
{
public:
  OSGScene(VisualizationAbstract* visualization);
  ~OSGScene() = default;
  OSGScene(const OSGScene& osgs) = delete;
  OSGScene& operator=(const OSGScene& osgs) = delete;
  osg::ref_ptr<osg::Group> getRootNode();
  std::string getPath() const override;
  void setPath(const std::string& path) override;
  void setUpShapes(std::vector<ShapeObject>& shapes) override;
  void setUpVectors(std::vector<VectorObject>& vectors) override;
  void updateVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties) override;
  void modifyVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties) override;
private:
  osg::ref_ptr<AutoTransformCullCallback> _atCullCallback;
  osg::ref_ptr<osg::Group> _rootNode;
  std::string _path;
  UpdateVisitor _updateVisitor;
};

class OMVisScene
{
public:
  OMVisScene(VisualizationAbstract* visualization);
  ~OMVisScene() = default;
  OMVisScene(const OMVisScene& omvs) = delete;
  OMVisScene& operator=(const OMVisScene& omvs) = delete;
  OSGScene& getScene();
  void dumpOSGTreeDebug();
private:
  OSGScene _scene;
};
#endif // !OMEDIT_ANIMATION_QUICK3D

class OMVisualBase
{
public:
  OMVisualBase(VisualizationAbstract* visualization, const std::string& modelFile, const std::string& path);
  OMVisualBase() = delete;
  ~OMVisualBase() = default;
  OMVisualBase(const OMVisualBase& omvb) = delete;
  OMVisualBase& operator=(const OMVisualBase& omvb) = delete;

  const std::string getModelFile() const;
  const std::string getPath() const;
  const std::string getXMLFileName() const;

  std::vector<std::reference_wrapper<AbstractVisualizerObject>> getVisualizerObjects();
  AbstractVisualizerObject* getVisualizerObjectByIdx(const std::size_t visualizerIdx);
  AbstractVisualizerObject* getVisualizerObjectByID(const std::string& visualizerID);
  int getVisualizerObjectIndexByID(const std::string& visualizerID);

  void updateVisualizer(const std::string& visualizerName   , const bool changeMaterialProperties = false);
  void modifyVisualizer(const std::string& visualizerName   , const bool changeMaterialProperties = true );
  void updateVisualizer(AbstractVisualizerObject* visualizer, const bool changeMaterialProperties = false);
  void modifyVisualizer(AbstractVisualizerObject* visualizer, const bool changeMaterialProperties = true );
  void updateVisualizer(AbstractVisualizerObject& visualizer, const bool changeMaterialProperties = false);
  void modifyVisualizer(AbstractVisualizerObject& visualizer, const bool changeMaterialProperties = true );

  void initVisObjects();
  void setFmuVarRefInVisObjects();
  void updateVisObjects(const double time);

  void setUpScene();

  void updateVectorCoords(VectorObject& vector, const double time);
#if !defined(OMEDIT_ANIMATION_QUICK3D)
  void chooseVectorScales(osgViewer::View* view, OpenThreads::Mutex* mutex = nullptr, std::function<void()> frame = nullptr);
#else
  // Quick 3D has no OSG view/AutoTransform: pick the radius scale (median
  // heuristic) and the per-quantity length scale from the data alone; the
  // iterative camera-fit refinement is replaced by the viewer's fitToScene.
  void chooseVectorScales();
#endif
private:
  std::string _modelFile;
  std::string _path;
  std::string _xmlFileName;
  VisualizationAbstract* _visualization;
  std::vector<ShapeObject> _shapes;
  std::vector<VectorObject> _vectors;
};

class VisualizationAbstract
{
public:
  VisualizationAbstract(const std::string& modelFile, const std::string& path, const VisType visType = VisType::NONE);
  virtual ~VisualizationAbstract() = default;

  VisType getVisType() const;
#if !defined(OMEDIT_ANIMATION_QUICK3D)
  OMVisScene* getOMVisScene() const;
#else
  // On wasm the scene is the Qt Quick 3D scene owned by the viewer widget, injected here.
  void setScene(AnimationScene* scene) {mpScene = scene;}
#endif
  // Renderer-neutral scene the data classes drive (the OSG scene natively, the
  // Qt Quick 3D scene on wasm).
  AnimationScene* getScene() const;
  OMVisualBase* getBaseData() const;
  TimeManager* getTimeManager() const;

  virtual void initData();
  virtual void setFmuVarRefInVisAttributes();
  virtual unsigned int getFmuVariableReferenceForVisualizerAttribute(VisualizerAttribute& attr) {Q_UNUSED(attr); return 0;}
  virtual void initializeVisAttributes(const double time);
  virtual void updateVisAttributes(const double time);
  virtual void updateVisualizerAttribute(VisualizerAttribute& attr, const double time) = 0;
  virtual void updateScene(const double time) = 0;
  virtual void simulate(TimeManager& omvm) = 0;

  void setUpScene();
  void sceneUpdate();

  void initVisualization();
  void startVisualization();
  void pauseVisualization();
private:
  const VisType _visType;
protected:
#if !defined(OMEDIT_ANIMATION_QUICK3D)
  OMVisScene* mpOMVisScene;
#else
  AnimationScene* mpScene = nullptr;
#endif
  OMVisualBase* mpOMVisualBase;
  TimeManager* mpTimeManager;
};

Vec3 Mat3mulV3(Mat3 M, Vec3 V);
Vec3 V3mulMat3(Vec3 V, Mat3 M);
Mat3 Mat3mulMat3(Mat3 M1, Mat3 M2);
Vec3 normalize(Vec3 vec);
Vec3 cross(Vec3 vec1, Vec3 vec2);
Directions fixDirections(Vec3 lDir, Vec3 wDir);
void assemblePokeMatrix(Mat4& M, const Mat3& T, const Vec3& r);
rAndT rotateModelica2OSG(Mat3 T, Vec3 r, Vec3 r_shape, Vec3 lDir, Vec3 wDir, std::string type);
rAndT rotateModelica2OSG(Mat3 T, Vec3 r, Vec3 dir);

#endif
