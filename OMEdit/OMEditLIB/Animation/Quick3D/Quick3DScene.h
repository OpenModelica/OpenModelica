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

#ifndef QUICK3DSCENE_H
#define QUICK3DSCENE_H

#include <QHash>
#include <QObject>
#include <QString>

#include "Animation/AnimationScene.h"

class QQmlEngine;
class QQmlComponent;
class QQuick3DObject;
class Quick3DGeometry;
class QVector3D;
class VectorObject;
struct Mat4;

/*
 * Qt Quick 3D implementation of AnimationScene. Builds one Quick 3D Model per
 * visualizer under a QML-hosted scene root and pushes per-frame transform and
 * material updates to it. Everything is driven through the public QObject
 * property system (setProperty / setParentItem) and a small per-shape QML
 * component, so no Qt private (`*_p.h`) headers are needed — important because
 * native builds use whatever Qt the distro ships (not a pinned version).
 */
class Quick3DScene : public AnimationScene
{
public:
  Quick3DScene(QQmlEngine* engine, QQuick3DObject* sceneRoot);
  ~Quick3DScene() override;

  std::string getPath() const override;
  void setPath(const std::string& path) override;
  void setUpShapes(std::vector<ShapeObject>& shapes) override;
  void setUpVectors(std::vector<VectorObject>& vectors) override;
  void updateVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties) override;
  void modifyVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties) override;

  // World-space bounding sphere of all current items (for camera framing). Returns
  // false when the scene is empty.
  bool boundingSphere(QVector3D& center, float& radius) const;

private:
  struct Item
  {
    QObject* node = nullptr;           // body transform Node (also stored as the visualizer's transform handle)
    QObject* model = nullptr;          // Model carrying the mesh
    QObject* material = nullptr;       // PrincipledMaterial
    Quick3DGeometry* geometry = nullptr; // custom mesh (pipe/spring/arrow), reused across rebuilds
    QString geomKey;                   // last geometry signature, to skip per-frame rebuilds
  };

  Item createItem(AbstractVisualizerObject* visualizer);
  void applyShapeGeometry(const ShapeObject& shape, Item& item);
  void applyVectorGeometry(const VectorObject& vector, Item& item);
  Quick3DGeometry* ensureGeometry(Item& item);
  void useBuiltinMesh(const Item& item, const char* source, const QVector3D& scale, const QVector3D& position, const QVector3D& euler);
  void useCustomGeometry(const Item& item);
  void applyTransform(QObject* node, const Mat4& mat);
  void applyMaterial(AbstractVisualizerObject* visualizer, QObject* material);

  QQmlEngine* mEngine;
  QQuick3DObject* mSceneRoot;
  QQmlComponent* mItemComponent;
  QHash<AbstractVisualizerObject*, Item> mItems;
  std::string mPath;
};

#endif // QUICK3DSCENE_H
