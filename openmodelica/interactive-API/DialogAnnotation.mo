model DialogAnnotation
parameter Boolean tableOnFile = false "= true, if table is defined on file or in function usertab" annotation(Dialog(group = "Table data definition"));
  parameter Real table[:,:] = fill(0.0, 0, 2) "Table matrix (time = first column; e.g., table=[0,2])" annotation(Dialog(group = "Table data definition", enable = not tableOnFile));
  parameter String tableName = "NoName" "Table name on file or in function usertab (see docu)" annotation(Dialog(group = "Table data definition", enable = tableOnFile));
  parameter String fileName = "NoName" "File where matrix is stored" annotation(Dialog(group = "Table data definition", enable = tableOnFile, loadSelector(filter = "Text files (*.txt);;MATLAB MAT-files (*.mat)", caption = "Open file in which table is present")));
end DialogAnnotation;