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

#ifndef QUICK3DVIEWERWIDGET_H
#define QUICK3DVIEWERWIDGET_H

#include <QQuickWidget>
#include <QQuaternion>
#include <QString>
#include <QVector3D>
#include <QPoint>

class Quick3DScene;
class AnimationScene;
class AbstractAnimationWindow;
class AbstractVisualizerObject;
class QQuick3DObject;

/*
 * Qt Quick 3D viewport widget. Hosts a QML scene shell (View3D + camera + lights
 * + scene-root Node) and owns the Quick3DScene that populates that root. The
 * scene is exposed as the renderer-neutral AnimationScene the visualization data
 * classes drive. Owns a simple orbit camera (turntable around the scene centre)
 * driven by the toolbar presets and the mouse.
 */
class Quick3DViewerWidget : public QQuickWidget
{
  Q_OBJECT
public:
  enum CameraView { Isometric, Top, Side, Front };

  Quick3DViewerWidget(QWidget* parent = nullptr);
  ~Quick3DViewerWidget() override;
  AnimationScene* getScene() const;
  QObject* getCamera() const { return mpCamera; }
  QQuick3DObject* getSceneRoot() const { return mpSceneRoot; }

  // Frame the whole scene (bounding sphere) at the current view angle.
  void fitToScene();
  // Snap to a preset viewing angle, keeping the framed distance/centre.
  void setCameraView(CameraView view);
  // Turntable orbit by the given yaw/pitch deltas (degrees).
  void orbitCamera(float deltaYawDeg, float deltaPitchDeg);

protected:
  void mousePressEvent(QMouseEvent* event) override;
  void mouseMoveEvent(QMouseEvent* event) override;
  void wheelEvent(QWheelEvent* event) override;

private:
  void applyCamera();
  // Ray-pick at a view pixel: returns the hit Model's objectName (visualizer id).
  QString pickName(const QPointF& viewPos);
  // Shift+right-click: pick the visualizer under the cursor and pop up the
  // visual-property context menu (color/transparency/specular/reset), like the
  // OSG ViewerWidget. Backend-agnostic — changes route through modifyVisualizer.
  void pickVisualizer(const QPointF& viewPos);
  void showVisualizerPickContextMenu(const QPoint& pos);

  Quick3DScene* mpScene;
  QQuick3DObject* mpSceneRoot;
  QObject* mpCamera;
  AbstractAnimationWindow* mpAnimationWindow;
  AbstractVisualizerObject* mpSelectedVisualizer;

  // Orbit-camera state: an orientation (camera local axes → world) plus the
  // look-at point and distance. The camera sits at mCenter + backward*mDistance.
  QVector3D mCenter;
  QQuaternion mOrientation;
  float mDistance;
  QPoint mLastMousePos;
};

#endif // QUICK3DVIEWERWIDGET_H
