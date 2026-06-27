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
#include "Quick3DGeometry.h"

#include <limits>

#include <QColor>
#include <QMatrix3x3>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuaternion>
#include <QUrl>
#include <QVariant>
#include <QVector3D>
#include <QtQuick3D/QQuick3DGeometry>
#include <QtQuick3D/QQuick3DObject>

#include "Animation/AbstractVisualizer.h"
#include "Animation/AnimationUtil.h"
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
  // Custom procedural meshes (pipe/spring/arrow) emit single-sided walls; render
  // them double-sided so triangle winding need not be exact. Built-in primitives
  // keep back-face culling.
  property bool omDoubleSided: false
  Model {
    id: model
    pickable: true
    materials: [ PrincipledMaterial {
      id: mat
      metalness: 0.0
      cullMode: omDoubleSided ? Material.NoCulling : Material.BackFaceCulling
      alphaMode: opacity < 0.999 ? PrincipledMaterial.Blend : PrincipledMaterial.Opaque
    } ]
  }
}
)QML";

QObject* childObject(QObject* owner, const char* property)
{
  return owner ? owner->property(property).value<QObject*>() : nullptr;
}

// World-space reach: distance from the node origin to the farthest corner of an
// axis-aligned box [mn,mx] scaled by s. Used to pad the camera-framing sphere.
float reachFromOrigin(const QVector3D& mn, const QVector3D& mx, const QVector3D& s)
{
  return QVector3D(qMax(qAbs(mn.x()), qAbs(mx.x())) * s.x(),
                   qMax(qAbs(mn.y()), qAbs(mx.y())) * s.y(),
                   qMax(qAbs(mn.z()), qAbs(mx.z())) * s.z())
    .length();
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
  if (item.model) {
    // View3D.pick() returns the hit Model; tag it so the picker maps back to the id.
    item.model->setObjectName(QString::fromStdString(visualizer->_id));
  }
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
    mItems.insert(&shape, item);
    updateVisualizer(&shape, true); // geometry is (re)built here, after dims are evaluated
  }
}

void Quick3DScene::setUpVectors(std::vector<VectorObject>& vectors)
{
  for (VectorObject& vector : vectors) {
    Item item = createItem(&vector);
    if (!item.node) {
      continue;
    }
    mItems.insert(&vector, item);
    updateVisualizer(&vector, true);
  }
}

Quick3DGeometry* Quick3DScene::ensureGeometry(Item& item)
{
  if (!item.geometry) {
    item.geometry = new Quick3DGeometry(item.node); // parented → freed with the node
  }
  return item.geometry;
}

void Quick3DScene::useBuiltinMesh(Item& item, const char* source, const QVector3D& scale, const QVector3D& position, const QVector3D& euler)
{
  // Built-in primitive: centred, Y-axis; scale/rotate/offset onto the Modelica +Z box.
  item.model->setProperty("geometry", QVariant::fromValue<QQuick3DGeometry*>(nullptr));
  item.model->setProperty("source", QUrl(QString::fromLatin1(source)));
  item.model->setProperty("scale", scale);
  item.model->setProperty("position", position);
  item.model->setProperty("eulerRotation", euler);
  if (item.node) {
    item.node->setProperty("omDoubleSided", false);
  }
  // The primitives span ±50 before scaling, offset by `position` from the node origin.
  item.radius = position.length() + 50.0f * qMax(scale.x(), qMax(scale.y(), scale.z()));
}

void Quick3DScene::useCustomGeometry(Item& item)
{
  // Custom mesh already in Modelica units along +Z from 0: no local transform.
  item.model->setProperty("source", QUrl());
  item.model->setProperty("geometry", QVariant::fromValue<QQuick3DGeometry*>(item.geometry));
  item.model->setProperty("scale", QVector3D(1, 1, 1));
  item.model->setProperty("position", QVector3D(0, 0, 0));
  item.model->setProperty("eulerRotation", QVector3D(0, 0, 0));
  if (item.node) {
    item.node->setProperty("omDoubleSided", true);
  }
  if (item.geometry) {
    item.radius = reachFromOrigin(item.geometry->boundsMin(), item.geometry->boundsMax(), QVector3D(1, 1, 1));
  }
}

void Quick3DScene::applyShapeGeometry(const ShapeObject& shape, Item& item)
{
  if (!item.model) {
    return;
  }
  if (isCADType(shape._type)) { // STL/DXF/OBJ/3DS: load + scale the mesh, own caching
    applyCadGeometry(shape, item);
    return;
  }
  const float length = shape._length.exp;
  const float width = shape._width.exp;
  const float height = shape._height.exp;
  const float extra = shape._extra.exp;
  // Skip the rebuild when nothing the mesh depends on changed (every frame otherwise).
  const QString key = QString::asprintf("%s|%.6g|%.6g|%.6g|%.6g", shape._type.c_str(), length, width, height, extra);
  if (key == item.geomKey) {
    return;
  }
  item.geomKey = key;

  const QVector3D pos(0, 0, length / 2.0f);
  if (shape._type == "box") {
    useBuiltinMesh(item, kCube, QVector3D(width / 100.f, height / 100.f, length / 100.f), pos, QVector3D(0, 0, 0));
  } else if (shape._type == "sphere") {
    useBuiltinMesh(item, kSphere, QVector3D(length / 100.f, length / 100.f, length / 100.f), pos, QVector3D(0, 0, 0));
  } else if (shape._type == "cylinder") {
    useBuiltinMesh(item, kCylinder, QVector3D(width / 100.f, length / 100.f, width / 100.f), pos, QVector3D(90, 0, 0));
  } else if (shape._type == "cone") {
    useBuiltinMesh(item, kCone, QVector3D(width / 100.f, length / 100.f, width / 100.f), pos, QVector3D(90, 0, 0));
  } else if (shape._type == "pipe" || shape._type == "pipecylinder") {
    // rO = width/2, rI = width*extra/2 (Visualization.cpp Pipecylinder args).
    ensureGeometry(item)->buildPipe(width * extra / 2.0f, width / 2.0f, length);
    useCustomGeometry(item);
  } else if (shape._type == "spring") {
    // Spring(coilRadius=width, wireRadius=height, windings=extra, length).
    ensureGeometry(item)->buildSpring(width, height, extra, length);
    useCustomGeometry(item);
  } else {
    // Unknown shape type: bounding-box placeholder.
    useBuiltinMesh(item, kCube, QVector3D(width / 100.f, height / 100.f, length / 100.f), pos, QVector3D(0, 0, 0));
  }
}

void Quick3DScene::applyCadGeometry(const ShapeObject& shape, Item& item)
{
  // Parse the mesh once (it doesn't change), then scale every update. The mesh
  // loads in native coordinates; OSG scales the vertices by length/width/height
  // on x/y/z when `extra` is set, else leaves them native — do the same via the
  // model's scale property (cheap) rather than rebuilding the mesh.
  const QString fileKey = QStringLiteral("cad|%1|%2")
                            .arg(QString::fromStdString(shape._type), QString::fromStdString(shape._fileName));
  if (item.geomKey != fileKey) {
    item.geomKey = fileKey;
    Quick3DGeometry* geom = ensureGeometry(item);
    item.cadLoaded = geom->buildFromCadFile(QString::fromStdString(shape._type), QString::fromStdString(shape._fileName));
    if (item.cadLoaded) {
      item.model->setProperty("source", QUrl());
      item.model->setProperty("geometry", QVariant::fromValue<QQuick3DGeometry*>(geom));
      item.model->setProperty("position", QVector3D(0, 0, 0));
      item.model->setProperty("eulerRotation", QVector3D(0, 0, 0));
      if (item.node) {
        item.node->setProperty("omDoubleSided", true);
      }
    } else {
      // Missing/unparsable file: unit-cube placeholder so the object is still visible.
      qWarning("Quick3DScene: could not load CAD file %s (%s)", shape._fileName.c_str(), shape._type.c_str());
      useBuiltinMesh(item, kCube, QVector3D(1, 1, 1), QVector3D(0, 0, 0), QVector3D(0, 0, 0));
    }
  }
  if (item.cadLoaded) {
    const QVector3D scale = (shape._extra.exp != 0.0f)
                              ? QVector3D(shape._length.exp, shape._width.exp, shape._height.exp)
                              : QVector3D(1, 1, 1);
    item.model->setProperty("scale", scale);
    if (item.geometry) {
      item.radius = reachFromOrigin(item.geometry->boundsMin(), item.geometry->boundsMax(), scale);
    }
  }
}

void Quick3DScene::applyVectorGeometry(const VectorObject& vector, Item& item)
{
  if (!item.model) {
    return;
  }
  const float length = vector.getLength();
  const float radius = vector.getRadius();
  const float headLength = vector.getHeadLength();
  const float headRadius = vector.getHeadRadius();
  const QString key = QString::asprintf("arrow|%.6g|%.6g|%.6g|%.6g", length, radius, headLength, headRadius);
  if (key == item.geomKey) {
    return;
  }
  item.geomKey = key;
  ensureGeometry(item)->buildArrow(radius, length, headRadius, headLength);
  useCustomGeometry(item);
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
  auto it = mItems.find(visualizer);
  if (it == mItems.end()) {
    return;
  }
  Item& item = it.value();
  // Shape dimensions (_length/_width/_height) are evaluated only in updateVisObjects,
  // which runs AFTER setUpShapes — so the geometry/scale set once at setUp would be
  // zero (→ invisible models). Re-apply it here (this method is called from the first
  // attribute update and every frame); the geomKey check skips the rebuild unless a
  // mesh-affecting dimension actually changed (handles time-varying dimensions).
  if (ShapeObject* shape = dynamic_cast<ShapeObject*>(visualizer)) {
    applyShapeGeometry(*shape, item);
  } else if (VectorObject* vector = dynamic_cast<VectorObject*>(visualizer)) {
    applyVectorGeometry(*vector, item);
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
  // Centre on the box of node origins, then grow the radius by each item's own
  // world reach (mesh extent from its node origin) — works for shapes anywhere,
  // not just near the origin, and for custom/CAD meshes in real units.
  QVector3D mn(std::numeric_limits<float>::max(), std::numeric_limits<float>::max(), std::numeric_limits<float>::max());
  QVector3D mx = -mn;
  for (const Item& item : mItems) {
    if (!item.node) {
      continue;
    }
    const QVector3D p = item.node->property("position").value<QVector3D>();
    mn.setX(qMin(mn.x(), p.x())); mn.setY(qMin(mn.y(), p.y())); mn.setZ(qMin(mn.z(), p.z()));
    mx.setX(qMax(mx.x(), p.x())); mx.setY(qMax(mx.y(), p.y())); mx.setZ(qMax(mx.z(), p.z()));
  }
  center = (mn + mx) * 0.5f;
  radius = 0.0f;
  for (const Item& item : mItems) {
    if (!item.node) {
      continue;
    }
    const QVector3D p = item.node->property("position").value<QVector3D>();
    radius = qMax(radius, (p - center).length() + item.radius);
  }
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
