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

encapsulated package OMGraphics
" file:        OMGraphics.mo
  package:     OMGraphics
  description: Qt-free rendering of Modelica graphical (Icon) annotations.

  Renders the Icon of an in-memory model instance (issue #15219; the handle
  comes from NFApi.getModelInstanceReference) to SVG, to a PNG raster, or to
  the FMI 3.0 <GraphicalRepresentation> element. First user: FMI 3.0 export."

public function iconSVGFromHandle
  "`modelName` is substituted for the %name placeholder of Text shapes.
   Empty if there is no icon."
  input Integer handle;
  input String modelName;
  output String svg;
  external "C" svg = OMGraphics_iconSVGFromHandle(handle, modelName) annotation(Library = "omcruntime");
end iconSVGFromHandle;

public function graphicalRepresentationXMLFromHandle
  "Empty if there is no icon."
  input Integer handle;
  input Real scaleToMm;
  output String xml;
  external "C" xml = OMGraphics_graphicalRepresentationXMLFromHandle(handle, scaleToMm) annotation(Library = "omcruntime");
end graphicalRepresentationXMLFromHandle;

public function writeIconPNGFromHandle
  "FMI 3.0 requires a PNG icon file. PNG bytes are binary, so the file is
   written here rather than returned as a String."
  input Integer handle;
  input String modelName;
  input String path;
  output Boolean ok;
  external "C" ok = OMGraphics_writeIconPNGFromHandle(handle, modelName, path) annotation(Library = "omcruntime");
end writeIconPNGFromHandle;

public function placedConnectorCount
  "Top-level connector components with a graphical placement."
  input Integer handle;
  output Integer n;
  external "C" n = OMGraphics_placedConnectorCount(handle) annotation(Library = "omcruntime");
end placedConnectorCount;

public function placedConnectorInfo
  "Tab-separated graphical info for placed connector `index`:
   name, iconBaseName, x1, y1, x2, y2 (placement bounding box in icon coordinates)."
  input Integer handle;
  input Integer index;
  output String info;
  external "C" info = OMGraphics_placedConnectorInfo(handle, index) annotation(Library = "omcruntime");
end placedConnectorInfo;

public function placedConnectorIconSVG
  "The port symbol, i.e. the icon of the connector's type. Empty if it has none."
  input Integer handle;
  input Integer index;
  output String svg;
  external "C" svg = OMGraphics_placedConnectorIconSVG(handle, index) annotation(Library = "omcruntime");
end placedConnectorIconSVG;

public function writePlacedConnectorIconPNG
  "The port symbol of placed connector `index`, rasterised to `path`."
  input Integer handle;
  input Integer index;
  input String path;
  output Boolean ok;
  external "C" ok = OMGraphics_writePlacedConnectorIconPNG(handle, index, path) annotation(Library = "omcruntime");
end writePlacedConnectorIconPNG;

annotation(__OpenModelica_Interface="omgraphics");
end OMGraphics;
