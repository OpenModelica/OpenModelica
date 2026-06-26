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

#include "Quick3DViewerWidget.h"

#include <cmath>

#include <QMatrix3x3>
#include <QMouseEvent>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QUrl>
#include <QWheelEvent>
#include <QtMath>
#include <QtQuick3D/QQuick3DObject>

#include "Quick3DScene.h"

namespace {
const char* kShellQml = R"QML(
import QtQuick
import QtQuick3D
Item {
  View3D {
    objectName: "view3d"
    anchors.fill: parent
    environment: SceneEnvironment {
      clearColor: "#f2f2f2"
      backgroundMode: SceneEnvironment.Color
      antialiasingMode: SceneEnvironment.MSAA
      antialiasingQuality: SceneEnvironment.High
    }
    PerspectiveCamera {
      objectName: "camera"
      position: Qt.vector3d(2, 2, 4)
      eulerRotation.x: -20
      clipNear: 0.01
      clipFar: 10000
    }
    DirectionalLight { eulerRotation.x: -40; eulerRotation.y: -20 }
    DirectionalLight { eulerRotation.x: 40; eulerRotation.y: 160; brightness: 0.4 }
    Node { objectName: "sceneRoot" }
  }
}
)QML";
} // namespace

Quick3DViewerWidget::Quick3DViewerWidget(QWidget* parent)
  : QQuickWidget(parent),
    mpScene(nullptr),
    mpSceneRoot(nullptr),
    mpCamera(nullptr),
    mCenter(0.0f, 0.0f, 0.0f),
    mDistance(5.0f)
{
  setResizeMode(QQuickWidget::SizeRootObjectToView);

  QQmlComponent* shell = new QQmlComponent(engine(), this);
  shell->setData(kShellQml, QUrl(QStringLiteral("qrc:/om/Quick3DSceneShell.qml")));
  if (shell->isError()) {
    qWarning("Quick3DViewerWidget: shell error: %s", qPrintable(shell->errorString()));
    return;
  }
  QObject* root = shell->create(engine()->rootContext());
  setContent(QUrl(QStringLiteral("qrc:/om/Quick3DSceneShell.qml")), shell, root);

  mpSceneRoot = root ? qobject_cast<QQuick3DObject*>(root->findChild<QObject*>(QStringLiteral("sceneRoot"))) : nullptr;
  mpCamera = root ? root->findChild<QObject*>(QStringLiteral("camera")) : nullptr;
  if (mpSceneRoot) {
    mpScene = new Quick3DScene(engine(), mpSceneRoot);
  } else {
    qWarning("Quick3DViewerWidget: scene root not found");
  }
}

Quick3DViewerWidget::~Quick3DViewerWidget()
{
  delete mpScene;
}

AnimationScene* Quick3DViewerWidget::getScene() const
{
  return mpScene;
}

namespace {
// Build the camera orientation (local axes → world) from its world right/up/
// backward basis vectors. The camera looks down its local -Z (= -backward).
QQuaternion orientationFromBasis(const QVector3D& right, const QVector3D& up, const QVector3D& backward)
{
  const float m[9] = {
    right.x(), up.x(), backward.x(),
    right.y(), up.y(), backward.y(),
    right.z(), up.z(), backward.z()
  };
  return QQuaternion::fromRotationMatrix(QMatrix3x3(m));
}
} // namespace

void Quick3DViewerWidget::applyCamera()
{
  if (!mpCamera) {
    return;
  }
  const QVector3D backward = mOrientation.rotatedVector(QVector3D(0, 0, 1));
  mpCamera->setProperty("position", mCenter + backward * mDistance);
  mpCamera->setProperty("rotation", mOrientation);
}

void Quick3DViewerWidget::fitToScene()
{
  QVector3D center;
  float radius = 1.0f;
  if (mpScene && mpScene->boundingSphere(center, radius)) {
    mCenter = center;
    // Distance so the sphere fits the (default 60°) vertical FOV, with margin.
    mDistance = qMax(radius / std::tan(qDegreesToRadians(30.0f)), 0.1f) * 1.3f;
  }
  if (mOrientation.isIdentity()) {
    setCameraView(Isometric);
    return;
  }
  applyCamera();
}

void Quick3DViewerWidget::setCameraView(CameraView view)
{
  // Match the OSG presets (their camera-to-world matrices): right/up/eye-direction
  // per view, looking at the origin so the world axes line up as they do in OSG.
  switch (view) {
    case Isometric:
      mOrientation = orientationFromBasis(QVector3D(0.7071f, 0.0f, -0.7071f),
                                          QVector3D(-0.409f, 0.816f, -0.409f),
                                          QVector3D(0.57735f, 0.57735f, 0.57735f));
      break;
    case Side:  // +z toward viewer, x right, y up
      mOrientation = orientationFromBasis(QVector3D(1, 0, 0), QVector3D(0, 1, 0), QVector3D(0, 0, 1));
      break;
    case Front: // +y toward viewer, z right, x up
      mOrientation = orientationFromBasis(QVector3D(0, 0, 1), QVector3D(1, 0, 0), QVector3D(0, 1, 0));
      break;
    case Top:   // +x toward viewer, -z right, y up
      mOrientation = orientationFromBasis(QVector3D(0, 0, -1), QVector3D(0, 1, 0), QVector3D(1, 0, 0));
      break;
  }
  mCenter = QVector3D(0, 0, 0);
  applyCamera();
}

void Quick3DViewerWidget::orbitCamera(float deltaYawDeg, float deltaPitchDeg)
{
  // Turntable: yaw about world up (+Y), pitch about the camera's current right axis.
  const QQuaternion yaw = QQuaternion::fromAxisAndAngle(QVector3D(0, 1, 0), deltaYawDeg);
  const QVector3D right = mOrientation.rotatedVector(QVector3D(1, 0, 0));
  const QQuaternion pitch = QQuaternion::fromAxisAndAngle(right, deltaPitchDeg);
  mOrientation = (yaw * pitch * mOrientation).normalized();
  applyCamera();
}

void Quick3DViewerWidget::mousePressEvent(QMouseEvent* event)
{
  mLastMousePos = event->pos();
  QQuickWidget::mousePressEvent(event);
}

void Quick3DViewerWidget::mouseMoveEvent(QMouseEvent* event)
{
  if (event->buttons() & Qt::LeftButton) {
    const QPoint delta = event->pos() - mLastMousePos;
    mLastMousePos = event->pos();
    orbitCamera(-delta.x() * 0.4f, delta.y() * 0.4f);
  }
  QQuickWidget::mouseMoveEvent(event);
}

void Quick3DViewerWidget::wheelEvent(QWheelEvent* event)
{
  const float steps = event->angleDelta().y() / 120.0f;
  if (steps != 0.0f) {
    mDistance = qMax(mDistance * std::pow(0.9f, steps), 0.01f);
    applyCamera();
  }
  event->accept();
}
