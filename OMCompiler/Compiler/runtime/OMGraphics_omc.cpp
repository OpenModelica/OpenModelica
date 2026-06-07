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
 * See the full OSMC Public License conditions for more details.
 */

/*
 * OMGraphics runtime glue.
 *
 * Bridges the in-memory model-instance reference of issue #15219
 * (getModelInstanceAnnotationReference -> integer handle, fetched as a boxed
 * MetaModelica "list-form" JSON value with ModelInstanceReference_get) to the
 * Qt-free OMGraphics SVG renderer. The boxed value is walked into an
 * OMGraphics::Json tree (mirroring OMEdit's OMCProxy::jsonValueFromMM), then the
 * renderer parses the Icon and produces SVG / the FMI 3.0 GraphicalRepresentation.
 *
 * These extern "C" entry points are called from MetaModelica (CevalScriptBackend,
 * FMI 3.0 FMU export) via `external "C" ... annotation(Library = "omcruntime")`.
 * The returned strings are GC-allocated so they survive as MetaModelica strings.
 */

/* meta_modelica.h self-guards extern "C" for C++ and pulls in gc/omc_gc.h
 * (omc_alloc_interface). */
#include "meta/meta_modelica.h"

#include "OMGraphics.h"

#include <cstring>
#include <string>
#include <vector>
#include <sstream>
#include <algorithm>

/* From ModelInstanceReference_omc.c (issue #15219 handle registry). */
extern "C" void* ModelInstanceReference_get(int handle);

namespace {

using OMGraphics::Json;

/* Walk a boxed list-form MetaModelica JSON value into an OMGraphics::Json.
 * After NFApi normalisation only the list-form node kinds appear
 * (JSON.LIST_OBJECT / JSON.LIST), never JSON.OBJECT / JSON.ARRAY. A boxed
 * uniontype record stores its record_description in slot 0 and its fields in
 * slots 1..n; tuples carry no descriptor (key/value live in slots 0/1). */
Json fromMM(void *value)
{
  Json out;
  if (value == NULL || MMC_IS_IMMEDIATE(value)) {
    return out; /* Null */
  }
  struct record_description *desc = (struct record_description*) MMC_STRUCTDATA(value)[0];
  const char *name = desc->name;

  if (strcmp(name, "JSON.LIST_OBJECT") == 0) {
    out.kind = Json::Kind::Object;
    void *lst = MMC_STRUCTDATA(value)[1];
    while (!MMC_NILTEST(lst)) {
      void *pair = MMC_CAR(lst);
      std::string key((const char*) MMC_STRINGDATA(MMC_STRUCTDATA(pair)[0]));
      out.obj.push_back(std::make_pair(key, fromMM(MMC_STRUCTDATA(pair)[1])));
      lst = MMC_CDR(lst);
    }
  } else if (strcmp(name, "JSON.LIST") == 0) {
    out.kind = Json::Kind::Array;
    void *lst = MMC_STRUCTDATA(value)[1];
    while (!MMC_NILTEST(lst)) {
      out.arr.push_back(fromMM(MMC_CAR(lst)));
      lst = MMC_CDR(lst);
    }
  } else if (strcmp(name, "JSON.STRING") == 0) {
    out.kind = Json::Kind::String;
    out.s = (const char*) MMC_STRINGDATA(MMC_STRUCTDATA(value)[1]);
  } else if (strcmp(name, "JSON.INTEGER") == 0) {
    out.kind = Json::Kind::Int;
    out.i = (long long) MMC_UNTAGFIXNUM(MMC_STRUCTDATA(value)[1]);
  } else if (strcmp(name, "JSON.NUMBER") == 0) {
    out.kind = Json::Kind::Double;
    out.d = mmc_prim_get_real(MMC_STRUCTDATA(value)[1]);
  } else if (strcmp(name, "JSON.TRUE") == 0) {
    out.kind = Json::Kind::Bool;
    out.b = true;
  } else if (strcmp(name, "JSON.FALSE") == 0) {
    out.kind = Json::Kind::Bool;
    out.b = false;
  }
  /* JSON.NULL (and, defensively, OBJECT/ARRAY which never reach here) -> Null */
  return out;
}

/* Copy a std::string into a GC-allocated C string (owned by the runtime GC so it
 * survives as a MetaModelica String). */
const char *gcString(const std::string &s)
{
  return omc_alloc_interface.malloc_strdup(s.c_str());
}

OMGraphics::Icon iconFromHandle(int handle)
{
  void *value = ModelInstanceReference_get(handle);
  if (!value) return OMGraphics::Icon();
  return OMGraphics::iconFromJson(fromMM(value));
}

/* One-entry cache of the walked model-instance tree, keyed by the boxed value
 * pointer. The graphical connector queries below are called once per connector
 * (count + info + icon), so this avoids re-walking the (possibly large) full
 * model instance each call. Single-threaded omc, so a plain static is fine. */
void *g_cachedPtr = NULL;
Json g_cachedRoot;

const Json &rootForHandle(int handle)
{
  void *value = ModelInstanceReference_get(handle);
  if (value != g_cachedPtr) {
    g_cachedPtr = value;
    g_cachedRoot = value ? fromMM(value) : Json();
  }
  return g_cachedRoot;
}

/* A placed connector component of the model: its instance name, the icon file
 * base name derived from its type, the placement bounding box (icon coordinates)
 * and a pointer to its type's Icon annotation (into the cached tree). */
struct PlacedConnector {
  std::string name;
  std::string iconBaseName;
  double x1, y1, x2, y2;
  const Json *icon; /* points into g_cachedRoot */
};

/* base name for a connector icon file: the type path with non-alphanumerics
 * turned into underscores (e.g. Modelica.Blocks.Interfaces.RealInput ->
 * Modelica_Blocks_Interfaces_RealInput). */
std::string iconBaseNameOf(const std::string &typeName)
{
  std::string s = typeName;
  for (char &c : s) {
    if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'))) c = '_';
  }
  return s;
}

/* placement extent [[x,y],[x,y]] -> bounding box (min/max). */
bool placementBox(const Json &ext, double box[4])
{
  if (!ext.isArray() || ext.size() < 2) return false;
  const Json &p1 = ext.at(0), &p2 = ext.at(1);
  if (!p1.isArray() || p1.size() < 2 || !p2.isArray() || p2.size() < 2) return false;
  double ax = p1.at(0).asNumber(), ay = p1.at(1).asNumber();
  double bx = p2.at(0).asNumber(), by = p2.at(1).asNumber();
  box[0] = std::min(ax, bx); box[1] = std::min(ay, by);
  box[2] = std::max(ax, bx); box[3] = std::max(ay, by);
  return true;
}

/* Collect the top-level connector components that carry a graphical Placement.
 * This is purely the *graphical* side: which interface lives where on the icon
 * and which icon to draw. Whether a port is an input or an output is NOT taken
 * from here (it comes from the flat model / modelDescription causality). */
std::vector<PlacedConnector> collectPlacedConnectors(const Json &root)
{
  std::vector<PlacedConnector> out;
  const Json &els = root.get("elements");
  if (!els.isArray()) return out;
  for (size_t i = 0; i < els.size(); ++i) {
    const Json &e = els.at(i);
    if (e.get("$kind").asString() != "component") continue;
    const Json &t = e.get("type");
    if (!t.isObject() || t.get("restriction").asString() != "connector") continue;
    /* placement = element.annotation.Placement.transformation.extent */
    const Json &ext = e.get("annotation").get("Placement").get("transformation").get("extent");
    double box[4];
    if (!placementBox(ext, box)) continue; /* no placement -> not drawn */
    PlacedConnector c;
    c.name = e.get("name").asString();
    c.iconBaseName = iconBaseNameOf(t.get("name").asString());
    c.x1 = box[0]; c.y1 = box[1]; c.x2 = box[2]; c.y2 = box[3];
    const Json &ic = t.get("annotation").get("Icon");
    c.icon = ic.isObject() ? &ic : NULL;
    out.push_back(c);
  }
  return out;
}

std::string numStr(double v)
{
  std::ostringstream os;
  os.precision(6);
  os << v;
  return os.str();
}

} // namespace

extern "C" {

/* Render the model Icon referenced by `handle` to an SVG document. `modelName`
 * is substituted for the Modelica "%name" placeholder in Text shapes. Returns
 * the empty string when the model has no icon graphics. */
const char* OMGraphics_iconSVGFromHandle(int handle, const char *modelName)
{
  OMGraphics::Icon icon = iconFromHandle(handle);
  if (icon.graphics.empty()) return gcString("");
  OMGraphics::SvgOptions opts;
  if (modelName) opts.nameText = modelName;
  return gcString(OMGraphics::renderIconSVG(icon, opts));
}

/* Build the FMI 3.0 <GraphicalRepresentation> element for the model Icon
 * referenced by `handle`. Returns the empty string when there is no icon. */
const char* OMGraphics_graphicalRepresentationXMLFromHandle(int handle, double scaleToMm)
{
  OMGraphics::Icon icon = iconFromHandle(handle);
  if (icon.graphics.empty()) return gcString("");
  return gcString(OMGraphics::renderGraphicalRepresentationXML(icon, scaleToMm));
}

/* ------------------------------------------------------------------------- *
 * Placed-connector graphics (for FMI 3.0 TerminalGraphicalRepresentation).
 *
 * These expose only the GRAPHICAL side of each connector port: where it sits on
 * the model icon (placement box) and what icon to draw for it. The set of ports
 * and their input/output direction are determined from the flat model (the
 * caller reads the causality from modelDescription.xml); here we just supply the
 * geometry and the rendered connector icon, matched by the connector name.
 * ------------------------------------------------------------------------- */

/* Number of top-level connector components that have a graphical placement. */
int OMGraphics_placedConnectorCount(int handle)
{
  return (int) collectPlacedConnectors(rootForHandle(handle)).size();
}

/* Tab-separated graphical info for placed connector `index`:
 *   name \t iconBaseName \t x1 \t y1 \t x2 \t y2
 * (the placement bounding box in icon coordinates). Empty string if out range. */
const char* OMGraphics_placedConnectorInfo(int handle, int index)
{
  std::vector<PlacedConnector> cs = collectPlacedConnectors(rootForHandle(handle));
  if (index < 0 || index >= (int) cs.size()) return gcString("");
  const PlacedConnector &c = cs[index];
  std::ostringstream os;
  os << c.name << "\t" << c.iconBaseName << "\t"
     << numStr(c.x1) << "\t" << numStr(c.y1) << "\t" << numStr(c.x2) << "\t" << numStr(c.y2);
  return gcString(os.str());
}

/* Render the icon of placed connector `index`'s connector type to SVG (the port
 * symbol, e.g. the RealInput/RealOutput triangle). Empty if it has no icon. */
const char* OMGraphics_placedConnectorIconSVG(int handle, int index)
{
  std::vector<PlacedConnector> cs = collectPlacedConnectors(rootForHandle(handle));
  if (index < 0 || index >= (int) cs.size() || !cs[index].icon) return gcString("");
  OMGraphics::Icon icon = OMGraphics::iconFromJson(*cs[index].icon);
  if (icon.graphics.empty()) return gcString("");
  return gcString(OMGraphics::renderIconSVG(icon));
}

} // extern "C"
