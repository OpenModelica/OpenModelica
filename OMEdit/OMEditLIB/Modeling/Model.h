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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */
#ifndef MODEL_H
#define MODEL_H

#include <QJsonArray>
#include <QJsonObject>
#include <QColor>

namespace Model
{
  class Point
  {
  public:
    Point();
    Point(double x, double y);
    void deserialize(const QJsonArray &jsonArray);
    double x() const {return value[0];}
    double y() const {return value[1];}
private:
    double value[2];
  };

  class Extent
  {
  public:
    Extent();
    void deserialize(const QJsonArray &jsonArray);
    Point getExtent1() const {return point[0];}
    Point getExtent2() const {return point[1];}
private:
    Point point[2];
  };

  class CoordinateSystem
  {
  public:
    CoordinateSystem();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    Extent getExtent() const {return extent;}
    bool getPreserveAspectRatio() const {return preserveAspectRatio;}
    double getInitialScale() const {return initialScale;}
    Point getGrid() const {return grid;}
private:
    Extent extent;
    bool preserveAspectRatio;
    double initialScale;
    Point grid;
  };

  class GraphicItem
  {
  public:
    GraphicItem();
    bool getVisible() const {return visible;}
    Point getOrigin() const {return origin;}
    double getRotation() const {return rotation;}
  protected:
    void deserialize(const QJsonArray &jsonArray);
private:
    bool visible;
    Point origin;
    double rotation;
  };

  class Color
  {
  public:
    Color();
    void deserialize(const QJsonArray &jsonArray);
    QColor getColor() const {return color;}
private:
    QColor color;
  };

  enum class LinePattern {None, Solid, Dash, Dot, DashDot, DashDotDot};
  enum class FillPattern {None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere};
  enum class BorderPattern {None, Raised, Sunken, Engraved};
  enum class Smooth {None, Bezier};
  enum class EllipseClosure {None, Chord, Radial};
  enum class Arrow {None, Open, Filled, Half};
  enum class TextStyle {Bold, Italic, UnderLine};
  enum class TextAlignment {Left, Center, Right};

  class FilledShape
  {
  public:
    FilledShape();
    Color getLineColor() const {return lineColor;}
    Color getFillColor() const {return fillColor;}
    LinePattern getPattern() const {return pattern;}
    FillPattern getFillPattern() const {return fillPattern;}
    double getLineThickness() const {return lineThickness;}
  protected:
    void deserialize(const QJsonArray &jsonArray);
  private:
    Color lineColor;
    Color fillColor;
    LinePattern pattern;
    FillPattern fillPattern;
    double lineThickness;
  };

  class Shape : public GraphicItem, public FilledShape
  {
  public:
    Shape();
    virtual ~Shape();
  };

  class Rectangle : public Shape
  {
  public:
    Rectangle();
    void deserialize(const QJsonArray &jsonArray);
    BorderPattern getBorderPattern() const {return borderPattern;}
    Extent getExtent() const {return extent;}
    double getRadius() const {return radius;}
  private:
    BorderPattern borderPattern;
    Extent extent;
    double radius;
  };

  class Ellipse : public Shape
  {
  public:
    Ellipse();
    void deserialize(const QJsonArray &jsonArray);
    Extent getExtent() const {return extent;}
    double getStartAngle() const {return startAngle;}
    double getEndAngle() const {return endAngle;}
    EllipseClosure getClosure() const {return closure;}
  private:
    Extent extent;
    double startAngle;
    double endAngle;
    EllipseClosure closure;
  };

  class IconDiagramAnnotation
  {
  public:
    IconDiagramAnnotation();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    CoordinateSystem getCoordinateSystem() {return coordinateSystem;}
    QList<Shape*> getGraphics() const {return graphics;}

    CoordinateSystem coordinateSystem;
    QList<Shape*> graphics;

  };

  class Instance
  {
  public:
    Instance();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    IconDiagramAnnotation getIconAnnotation() const {return iconAnnotation;}
    IconDiagramAnnotation getDiagramAnnotation() const {return diagramAnnotation;}

    //  QVariantMap getIconCoordinateSystem() const;
    //  QList<QVariant> getIconAnnotation() const;
    //  QVariantMap getDiagramCoordinateSystem() const;
    //  QList<QVariant> getDiagramAnnotation() const;

    QString name;
    IconDiagramAnnotation iconAnnotation;
    IconDiagramAnnotation diagramAnnotation;
    //  QVariantMap annotation;

    //  QVariant mResult;
  };
}

#endif // MODEL_H
