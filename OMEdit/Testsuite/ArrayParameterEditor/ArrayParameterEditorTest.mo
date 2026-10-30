package ArrayParameterEditorTest

  model Component
    parameter Real matrix[:, :] = [[1, 2]; [3, 4]];
    parameter Real vector[:] = [1, 2, 3];
    parameter Integer integerMatrix[:, :] = [[1, 0]; [0, 1]];
    parameter Real emptyMatrix[:, :] = fill(0.0, 0, 2);
    parameter Real scalar = 5;
    // both bracket formats for the same 2D value
    parameter Real matrixBrackets[2, 3] = [1, 2, 3; 4, 5, 6];
    parameter Real matrixBraces[2, 3] = {{1, 2, 3}, {4, 5, 6}};
    // both bracket formats for vectors
    parameter Real vectorBrackets[1, 3] = [1, 2, 3];
    parameter Real vectorBraces[3] = {1, 2, 3};
    // 3D arrays cannot be edited as a table
    parameter Real array3D[2, 3, 2] = {{{1, 7}, {2, 8}, {3, 9}},
                                       {{4, 10}, {5, 11}, {6, 12}}};
    parameter Real array3DDynamic[:, :, :] = {{{1, 2}, {3, 4}},
                                              {{5, 6}, {7, 8}}};
  end Component;

  model System
    Component component
      annotation(Placement(transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}})));
  end System;
end ArrayParameterEditorTest;
