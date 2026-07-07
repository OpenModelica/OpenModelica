within ;
package OpenModelicaBugs "Models from the #15940 report exercising ModelicaServices.Animation.Shape"

  model ShapeDoesNotAnimate1 "Shape used directly from ModelicaServices.Animation"
    ModelicaServices.Animation.Shape box(length = 1, width = 0.2, height = 0.1, r = {time,0,0});
    annotation(experiment(StopTime = 1.1));
  end ShapeDoesNotAnimate1;

  model ShapeDoesNotAnimate2 "Shape used directly, orientation given via a local record"
    record Orientation
      Real T[3,3];
      Real w[3] = zeros(3);
    end Orientation;
    ModelicaServices.Animation.Shape box(shapeType = "box", length = 1, width = 0.2, height = 0.1, r = {time,0,0}, R = Orientation(T = identity(3)));
    annotation(experiment(StopTime = 1.1));
  end ShapeDoesNotAnimate2;

  model ShapeDoesNotAnimate3 "Shape wrapped in a component (work-around hierarchy)"
    OpenModelicaBugs.BaseShape1 box(shapeType = "box", length = 1, width = 0.2, height = 0.1, r = {time,0,0}, T = identity(3));
    annotation(experiment(StopTime = 1.1));
  end ShapeDoesNotAnimate3;

  model ShapeDoesNotAnimate4 "Shape inherited via extends (the failing case in #15940)"
    OpenModelicaBugs.BaseShape2 box(shapeType = "box", length = 1, width = 0.2, height = 0.1, r = {time,0,0}, T = identity(3));
    annotation(experiment(StopTime = 1.1));
  end ShapeDoesNotAnimate4;

  model BaseShape1 "Wraps a ModelicaServices.Animation.Shape as a component"
    import Modelica.Units.SI;
    parameter String shapeType = "box";
    input SI.Position r_shape[3] = {0,0,0} annotation(Dialog);
    input Real lengthDirection[3] = {1,0,0} annotation(Dialog);
    input Real widthDirection[3] = {0,1,0} annotation(Dialog);
    input SI.Length length = 0 annotation(Dialog);
    input SI.Length width = 0 annotation(Dialog);
    input SI.Length height = 0 annotation(Dialog);
    input Real extra = 0.0 annotation(Dialog);
    input Real color[3] = {255,0,0} annotation(Dialog(colorSelector = true));
    input Real specularCoefficient = 0.7 annotation(Dialog);
    input SI.Position r[3] = {0,0,0} annotation(Dialog);
    input Real T[3,3] annotation(Dialog);
    record Orientation
      Real T[3,3];
      Real w[3] = zeros(3);
    end Orientation;
    ModelicaServices.Animation.Shape shape(shapeType = shapeType, r_shape = r_shape, lengthDirection = lengthDirection,
      widthDirection = widthDirection, length = length, width = width, height = height, extra = extra, color = color,
      specularCoefficient = specularCoefficient, r = r, R = Orientation(T = T));
  end BaseShape1;

  model BaseShape2 "Inherits a ModelicaServices.Animation.Shape via extends"
    extends ModelicaServices.Animation.Shape(R = Orientation(T = T));
    input Real T[3,3];
    record Orientation
      Real T[3,3];
      Real w[3] = zeros(3);
    end Orientation;
  end BaseShape2;

  annotation(uses(Modelica(version = "4.1.0"), ModelicaServices(version = "4.1.0")));
end OpenModelicaBugs;
