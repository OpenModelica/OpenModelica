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

#ifndef ANIMATIONSCENE_H
#define ANIMATIONSCENE_H

#include <string>
#include <vector>

class AbstractVisualizerObject;
class ShapeObject;
class VectorObject;

/*
 * Renderer-neutral scene interface. It is the only coupling point between the
 * renderer-agnostic visualization data classes (VisualizationAbstract /
 * OMVisualBase) and the backend that draws the model: building a node per
 * visualizer and pushing per-frame transform/material updates to it. OSGScene
 * is the OpenSceneGraph implementation; a Qt Quick 3D implementation plugs in
 * here without the data classes knowing the backend.
 */
class AnimationScene
{
public:
  virtual ~AnimationScene() = default;
  virtual std::string getPath() const = 0;
  virtual void setPath(const std::string& path) = 0;
  virtual void setUpShapes(std::vector<ShapeObject>& shapes) = 0;
  virtual void setUpVectors(std::vector<VectorObject>& vectors) = 0;
  virtual void updateVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties) = 0;
  virtual void modifyVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties) = 0;
};

#endif // ANIMATIONSCENE_H
