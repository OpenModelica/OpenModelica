/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 * Contributors 2011: Abhinn Kothari
 */

#ifndef COMPONENT_H
#define COMPONENT_H

#include "ShapeAnnotation.h"
#include "ProjectTabWidget.h"
#include "OMCProxy.h"
#include "CornerItem.h"
#include "ConnectorWidget.h"
#include "LineAnnotation.h"
#include "PolygonAnnotation.h"
#include "RectangleAnnotation.h"
#include "EllipseAnnotation.h"
#include "TextAnnotation.h"
#include "BitmapAnnotation.h"
#include "IconProperties.h"
#include "IconParameters.h"
#include "ComponentsProperties.h"
#include "Transformation.h"

class OMCProxy;
class GraphicsScene;
class GraphicsView;
class CornerItem;
class Connector;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;
class BitmapAnnotation;
class IconProperties;
class IconParameters;
class Transformation;

class Component : public ShapeAnnotation
{
    Q_OBJECT
private:
    QString mAnnotationString;
    bool mIsConnector;
    QString mName;
    QString mClassName;
    CornerItem *mpTopLeftCornerItem;
    CornerItem *mpTopRightCornerItem;
    CornerItem *mpBottomLeftCornerItem;
    CornerItem *mpBottomRightCornerItem;
    QAction *mpIconPropertiesAction;
    QAction *mpIconAttributesAction;
    QAction *mpIsConnectModeAction;

    void createActions();
public:
    Component(QString value, QString name, QString className, QPointF position, int type, bool connector,
              OMCProxy *omc, GraphicsView *graphicsView, Component *pParent = 0);
    Component(QString value, QString className, int type, bool connector, Component *pParent = 0);
    Component(QString value, QString transformationString, ComponentsProperties *pComponentProperties, int type,
              bool connector, Component *pParent = 0);
    /* Used for Library Component */
    Component(QString value, QString className, bool connector, OMCProxy *omc, Component *pParent = 0);
    Component(QString value, QString className, bool connector, Component *pParent = 0);
    Component(QString value, QString transformationString, ComponentsProperties *pComponentProperties, bool connector,
              Component *pParent = 0);
    /* Used for Library Component */
    /* Copy Constructors */
    Component(Component *pComponent, QString name, QPointF position, int type, bool connector,
              GraphicsView *graphicsView, Component *pParent = 0);
    /* Copy Constructors */
    ~Component();

    QRectF mRectangle;    // stores the extent points
    QString mTransformationString;
    int mType;
    bool mPreserveAspectRatio;
    qreal mInitialScale;
    QList<qreal> mGrid;
    Component *mpParentComponent;
    OMCProxy *mpOMCProxy;
    GraphicsView *mpGraphicsView;
    ComponentsProperties *mpComponentProperties;
    QList<ComponentsProperties*> mpChildComponentProperties;
    Transformation *mpTransformation;
    QList<ShapeAnnotation*> mpShapesList;
    QList<Component*> mpInheritanceList;
    QList<Component*> mpComponentsList;
    QList<IconParameters*> mIconParametersList;
    bool mIsLibraryComponent;
    QPointF mOldPosition;
    bool isMousePressed;

    bool parseAnnotationString(Component *item, QString value, bool libraryIcon = false);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    QString getName();
    void updateName(QString newName);
    void updateParameterValue(QString oldValue, QString newValue);
    QString getClassName();
    Component* getParentComponent();
    Component* getRootParentComponent();
    void getClassComponents(QString className, int type);
    void getClassComponents(QString className, int type, Component *pParent);
    void copyClassComponents(Component *pComponent);
    void createSelectionBox();
    void setSelectionBoxActive();
    void setSelectionBoxPassive();
    void setSelectionBoxHover();
    void updateSelectionBox();
    void addConnector(Connector *item);
    void setComponentFlags();
    void unsetComponentFlags();
    bool getIsConnector();
    QString getTransformationString();
signals:
    void componentClicked(Component*);
    void connectorComponentClicked(Component*);
    void componentMoved();
    void componentPositionChanged();
    void componentDeleted();
    void componentSelected();
    void componentRotated(bool isRotated);
    void componentScaled();
public slots:
    void updateAnnotationString(bool updateBothViews = true);
    void showSelectionBox();
    void resizeComponent(qreal resizeFactorX, qreal resizeFactorY);
    void deleteMe(bool update = true);
    void copyComponent();
    //void pasteComponent();
    void openIconProperties();
    void openIconAttributes();
    void changeConnectMode();
protected:
    virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
    virtual void hoverEnterEvent(QGraphicsSceneHoverEvent *event);
    virtual void hoverLeaveEvent(QGraphicsSceneHoverEvent *event);
    virtual void contextMenuEvent(QGraphicsSceneContextMenuEvent *event);
    virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
};

#endif // COMPONENT_H
