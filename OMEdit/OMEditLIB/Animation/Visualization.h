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

#include "AnimationUtil.h"
#include "TimeManager.h"
#include "rapidxml.hpp"

#include "AnimationScene.h"
#include "AbstractVisualizer.h"
#include "Shape.h"
#include "Vector.h"

class VisualizationAbstract; // Forward declaration for passing a pointer to various constructors before class declaration

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
  // The radius scale (median heuristic) and the per-quantity length scale come
  // from the data alone; fitting to the camera is the viewer's fitToScene.
  void chooseVectorScales();
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
  // The scene is the Qt Quick 3D scene owned by the viewer widget, injected here.
  void setScene(AnimationScene* scene) {mpScene = scene;}
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
  AnimationScene* mpScene = nullptr;
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
rAndT rotateModelica2Scene(Mat3 T, Vec3 r, Vec3 r_shape, Vec3 lDir, Vec3 wDir, std::string type);
rAndT rotateModelica2Scene(Mat3 T, Vec3 r, Vec3 dir);

#endif
