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

#include "Quick3DScene.h"

#include <limits>

#include <QColor>
#include <QMatrix3x3>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuaternion>
#include <QUrl>
#include <QVector3D>
#include <QtQuick3D/QQuick3DObject>

#include "Animation/AbstractVisualizer.h"
#include "Animation/Shape.h"
#include "Animation/Vector.h"

namespace {
// Built-in Qt Quick 3D primitive mesh dimensions: #Cube is 100^3 centered at the
// origin; #Sphere has radius 50; #Cylinder/#Cone have radius 50, height 100 with
// their axis along +Y. The Modelica/OSG convention is a shape that extends along
// local +Z from 0 to length, with width/height across x/y.
const char* kCube = "#Cube";
const char* kSphere = "#Sphere";
const char* kCylinder = "#Cylinder";
const char* kCone = "#Cone";

// Per-shape QML: a transform Node carrying one Model whose single
// PrincipledMaterial blends only when translucent. omModel/omMaterial expose the
// inner objects so C++ can drive them via the property system.
const char* kItemQml = R"QML(
import QtQuick
import QtQuick3D
Node {
  property var omModel: model
  property var omMaterial: mat
  Model {
    id: model
    pickable: true
    materials: [ PrincipledMaterial {
      id: mat
      metalness: 0.0
      alphaMode: opacity < 0.999 ? PrincipledMaterial.Blend : PrincipledMaterial.Opaque
    } ]
  }
}
)QML";

QObject* childObject(QObject* owner, const char* property)
{
  return owner ? owner->property(property).value<QObject*>() : nullptr;
}
} // namespace

Quick3DScene::Quick3DScene(QQmlEngine* engine, QQuick3DObject* sceneRoot)
  : mEngine(engine),
    mSceneRoot(sceneRoot),
    mItemComponent(new QQmlComponent(engine))
{
  mItemComponent->setData(kItemQml, QUrl(QStringLiteral("qrc:/om/Quick3DSceneItem.qml")));
  if (mItemComponent->isError()) {
    qWarning("Quick3DScene: item component error: %s", qPrintable(mItemComponent->errorString()));
  }
}

Quick3DScene::~Quick3DScene()
{
  for (const Item& item : mItems) {
    delete item.node;
  }
  delete mItemComponent;
}

std::string Quick3DScene::getPath() const
{
  return mPath;
}

void Quick3DScene::setPath(const std::string& path)
{
  mPath = path;
}

Quick3DScene::Item Quick3DScene::createItem(AbstractVisualizerObject* visualizer)
{
  Item item;
  QObject* obj = mItemComponent->create(mEngine->rootContext());
  if (!obj) {
    qWarning("Quick3DScene: failed to create item for %s", visualizer->_id.c_str());
    return item;
  }
  QQuick3DObject* node3d = qobject_cast<QQuick3DObject*>(obj);
  if (node3d) {
    node3d->setParentItem(mSceneRoot);
  }
  obj->setObjectName(QString::fromStdString(visualizer->_id));
  item.node = obj;
  item.model = childObject(obj, "omModel");
  item.material = childObject(obj, "omMaterial");
  visualizer->setTransformNode(obj);
  return item;
}

void Quick3DScene::setUpShapes(std::vector<ShapeObject>& shapes)
{
  for (ShapeObject& shape : shapes) {
    Item item = createItem(&shape);
    if (!item.node) {
      continue;
    }
    applyShapeGeometry(shape, item.model);
    mItems.insert(&shape, item);
    updateVisualizer(&shape, true);
  }
}

void Quick3DScene::setUpVectors(std::vector<VectorObject>& vectors)
{
  // TODO Quick 3D vector (arrow) geometry; rendered as a thin box placeholder.
  for (VectorObject& vector : vectors) {
    Item item = createItem(&vector);
    if (!item.node) {
      continue;
    }
    if (item.model) {
      item.model->setProperty("source", QUrl(QStringLiteral("#Cylinder")));
      item.model->setProperty("scale", QVector3D(0.01f, 0.01f, 0.01f));
    }
    mItems.insert(&vector, item);
    updateVisualizer(&vector, true);
  }
}

void Quick3DScene::applyShapeGeometry(const ShapeObject& shape, QObject* model)
{
  if (!model) {
    return;
  }
  const float length = shape._length.exp;
  const float width = shape._width.exp;
  const float height = shape._height.exp;

  QUrl source;
  QVector3D scale(1, 1, 1);
  QVector3D position(0, 0, length / 2.0f);
  QVector3D euler(0, 0, 0);

  if (shape._type == "box") {
    source = QUrl(QString::fromLatin1(kCube));
    scale = QVector3D(width / 100.0f, height / 100.0f, length / 100.0f);
  } else if (shape._type == "sphere") {
    source = QUrl(QString::fromLatin1(kSphere));
    scale = QVector3D(length / 100.0f, length / 100.0f, length / 100.0f);
  } else if (shape._type == "cylinder" || shape._type == "pipe" || shape._type == "pipecylinder") {
    // #Cylinder axis is +Y; rotate it onto +Z. TODO hollow pipe via QQuick3DGeometry.
    source = QUrl(QString::fromLatin1(kCylinder));
    scale = QVector3D(width / 100.0f, length / 100.0f, width / 100.0f);
    euler = QVector3D(90, 0, 0);
  } else if (shape._type == "cone") {
    source = QUrl(QString::fromLatin1(kCone));
    scale = QVector3D(width / 100.0f, length / 100.0f, width / 100.0f);
    euler = QVector3D(90, 0, 0);
  } else if (shape._type == "spring") {
    // TODO spring helix via QQuick3DGeometry; thin cylinder placeholder for now.
    source = QUrl(QString::fromLatin1(kCylinder));
    scale = QVector3D(width / 100.0f, length / 100.0f, width / 100.0f);
    euler = QVector3D(90, 0, 0);
  } else {
    // CAD (dxf/stl/obj/3ds) and unknown: bounding-box placeholder. TODO mesh import.
    source = QUrl(QString::fromLatin1(kCube));
    scale = QVector3D(width / 100.0f, height / 100.0f, length / 100.0f);
  }

  model->setProperty("source", source);
  model->setProperty("scale", scale);
  model->setProperty("position", position);
  model->setProperty("eulerRotation", euler);
}

void Quick3DScene::applyTransform(QObject* node, const Mat4& mat)
{
  if (!node) {
    return;
  }
  // mat is in OSG row-vector convention (world = local * mat): translation lives
  // in row 3 and the top-left 3x3 is the row-vector rotation. Qt Quick 3D uses the
  // column-vector convention (world = M * local), so the rotation is the transpose.
  const QVector3D position(float(mat(3, 0)), float(mat(3, 1)), float(mat(3, 2)));
  const float r[9] = {
    float(mat(0, 0)), float(mat(1, 0)), float(mat(2, 0)),
    float(mat(0, 1)), float(mat(1, 1)), float(mat(2, 1)),
    float(mat(0, 2)), float(mat(1, 2)), float(mat(2, 2))
  };
  const QQuaternion rotation = QQuaternion::fromRotationMatrix(QMatrix3x3(r));

  node->setProperty("position", position);
  node->setProperty("rotation", rotation);
}

void Quick3DScene::applyMaterial(AbstractVisualizerObject* visualizer, QObject* material)
{
  AbstractVisualProperties* props = visualizer->getVisualProperties();
  if (!material || !props) {
    return;
  }
  QColor color = props->getColor().get();
  const float transparency = props->getTransparency().get();
  const float specular = props->getSpecular().get();

  material->setProperty("baseColor", color);
  material->setProperty("opacity", double(1.0f - transparency));
  material->setProperty("roughness", double(qBound(0.0f, 1.0f - specular, 1.0f)));
}

void Quick3DScene::updateVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties)
{
  auto it = mItems.constFind(visualizer);
  if (it == mItems.constEnd()) {
    return;
  }
  const Item& item = it.value();
  // Shape dimensions (_length/_width/_height) are evaluated only in updateVisObjects,
  // which runs AFTER setUpShapes — so the geometry/scale set once at setUp would be
  // zero (→ invisible models). Re-apply it here (this method is called from the first
  // attribute update and every frame), which also handles time-varying dimensions.
  if (ShapeObject* shape = dynamic_cast<ShapeObject*>(visualizer)) {
    applyShapeGeometry(*shape, item.model);
  }
  applyTransform(item.node, visualizer->_mat);
  if (changeMaterialProperties) {
    applyMaterial(visualizer, item.material);
  }
}

bool Quick3DScene::boundingSphere(QVector3D& center, float& radius) const
{
  if (mItems.isEmpty()) {
    return false;
  }
  QVector3D mn(std::numeric_limits<float>::max(), std::numeric_limits<float>::max(), std::numeric_limits<float>::max());
  QVector3D mx = -mn;
  float pad = 0.0f;
  for (const Item& item : mItems) {
    if (!item.node) {
      continue;
    }
    const QVector3D p = item.node->property("position").value<QVector3D>();
    mn.setX(qMin(mn.x(), p.x())); mn.setY(qMin(mn.y(), p.y())); mn.setZ(qMin(mn.z(), p.z()));
    mx.setX(qMax(mx.x(), p.x())); mx.setY(qMax(mx.y(), p.y())); mx.setZ(qMax(mx.z(), p.z()));
    if (item.model) {
      // Built-in primitives span ~100 units before scaling; half-extent ≈ 50*scale.
      const QVector3D s = item.model->property("scale").value<QVector3D>();
      pad = qMax(pad, 50.0f * qMax(s.x(), qMax(s.y(), s.z())));
    }
  }
  center = (mn + mx) * 0.5f;
  radius = (mx - mn).length() * 0.5f + pad;
  if (radius < 1.0e-3f) {
    radius = 1.0f;
  }
  return true;
}

void Quick3DScene::modifyVisualizer(AbstractVisualizerObject* visualizer, bool changeMaterialProperties)
{
  // Quick 3D has no separate "modify" state-set pass; material is recreated by the
  // same property update.
  updateVisualizer(visualizer, changeMaterialProperties);
}
