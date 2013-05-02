/* -------------------------------------------------------------------------
 * xmlparser.h
 * A parser for file modelVariables.xml of an FMU.
 * Copyright 2010 QTronic GmbH. All rights reserved.
 * Modified for OpenModelica Project.
 * -------------------------------------------------------------------------*/


#ifndef xmlparser_h
#define xmlparser_h

#include <fmiModelTypes.h>

#define SIZEOF_ELM 26
extern const char *elmNames[SIZEOF_ELM];

#define SIZEOF_ATT 34
extern const char *attNames[SIZEOF_ATT];

#define SIZEOF_ENU 13
extern const char *enuNames[SIZEOF_ENU];

/* Attributes */
typedef enum {
    elm_fmiModelDescription,elm_UnitDefinitions,elm_BaseUnit,elm_DisplayUnitDefinition,elm_TypeDefinitions,
    elm_Type,elm_RealType,elm_IntegerType,elm_BooleanType,elm_StringType,
  elm_EnumerationType,elm_Item, elm_DefaultExperiment,elm_VendorAnnotations,elm_Tool,
  elm_Annotation,elm_ModelVariables,elm_ArrayVariable,elm_ScalarVariable,elm_DirectDependency,
  elm_Name,elm_Real,elm_Integer,elm_Boolean,elm_String,elm_Enumeration
} Elm;

/* Attributes */
typedef enum {
  att_fmiVersion,att_displayUnit,att_gain,att_offset,att_unit,att_name,att_description,att_quantity,att_relativeQuantity,
  att_min,att_max,att_nominal,att_declaredType,att_start,att_fixed,att_startTime,att_stopTime,att_tolerance,att_value,
  att_valueReference,att_variability,att_causality,att_alias,att_modelName,att_modelIdentifier,att_guid,att_author,
  att_version,att_generationTool,att_generationDateAndTime,att_variableNamingConvention,att_numberOfContinuousStates,
  att_numberOfEventIndicators,att_input
} Att;

/* Enumeration values */
typedef enum {
    enu_flat,enu_structured,enu_constant,enu_parameter,enu_discrete,enu_continuous,
    enu_input,enu_output,enu_internal,enu_none,enu_noAlias,enu_alias,enu_negatedAlias
} Enu;

/* AST node for element
 * DisplayUnitDefinition, RealType, IntegerType, BooleanType, StringType
 * DefaultExperiment, Item, Annotation, Name, Real, Integer, Boolean, String, Enumeration */
typedef struct {
    Elm type;    /* element type */
    const char** attributes; /* null or n attribute value strings */
    int n;       /* size of attributes, even number */
} Element;

/* AST node for element that has a list of elements
 * BaseUnit, EnumerationType, Tool, DirectDependency */
typedef struct {
    Elm type;    /* element type */
    const char** attributes; /* null or n attribute value strings */
    int n;       /* size of attributes, even number */
    Element** list;    /* null-terminated array of pointers to elements, not null */
} ListElement;

/* AST node for element Type */
typedef struct {
    Elm type;    /* element type */
    const char** attributes; /* null or n attribute value strings */
    int n;       /* size of attributes, an even number */
    Element* typeSpec; /* one of RealType, IntegerType etc. */
} Type;

/* AST node for element ScalarVariable */
typedef struct {
    Elm type;    /* element type */
    const char** attributes; /* null or n attribute value strings */
    int n;       /* size of attributes, even number */
    Element* typeSpec; /* one of Real, Integer, etc */
    Element** directDependencies; /* null or null-terminated list of Name */
} ScalarVariable;

/* AST node for element ArrayVariable for the future
typedef struct{

} ArrayVariable;
*/

typedef struct{
  ScalarVariable** scalarVariables;
  /* ArrayVariable** arrayVariables; array varialbes for later use */
} ModelVariables;

/* AST node for element ModelDescription */
typedef struct {
    Elm type;    /* element type */
    const char** attributes; /* null or n attribute value strings */
    int n;       /* size of attributes, even number */
    ListElement** unitDefinitions;    /* NULL or null-terminated list of BaseUnits */
    Type**  typeDefinitions;    /* NULL or null-terminated list of Types */
    Element*      defaultExperiment;  /* NULL or DefaultExperiment */
    ListElement** vendorAnnotations;  /* NULL or null-terminated list of Tools */
    ScalarVariable** modelVariables;  /* NULL or null-terminated list of ScalarVariable */
} ModelDescription;

/* types of AST nodes used to represent an element */
typedef enum {
    astElement,
    astListElement,
    astType,
    astScalarVariable,
  astArrayVariable,
  astModelVariables,
    astModelDescription
} AstNodeType;

/* Possible results when retrieving an attribute value from an element */
typedef enum {
    valueMissing,
    valueDefined,
    valueIllegal
} ValueStatus;

/* Public methods: Parsing and low-level AST access */
ModelDescription* parse(const char* xmlPath);
const char* getString(void* element, Att a);
double getDouble     (void* element, Att a, ValueStatus* vs);
int getInt     (void* element, Att a, ValueStatus* vs);
unsigned int getUInt (void* element, Att a, ValueStatus* vs);
char getBoolean      (void* element, Att a, ValueStatus* vs);
Enu getEnumValue     (void* element, Att a, ValueStatus* vs);
void freeElement     (void* element);

/* Convenience methods for AST access. To be used afer successful validation only. */
const char* getFmiVersion(ModelDescription* md);
const char* getModelName(ModelDescription* md);
const char* getModelIdentifier(ModelDescription* md);
int getNumberOfContStates(ModelDescription* md);
int getNumberOfEventIndicators(ModelDescription* md);
const char* getName(void* element);
Enu getCausality(void* scalarVariable);
Enu getVariability(void* scalarVariable);
Enu getAlias(void* scalarVariable);
fmiValueReference getValueReference(void* scalarVariable);
ScalarVariable* getVariableByName(ModelDescription* md, const char* name);
ScalarVariable* getVariable(ModelDescription* md, fmiValueReference vr, Elm type);
Type* getDeclaredType(ModelDescription* md, const char* declaredType);
const char* getString2(ModelDescription* md, void* sv, Att a);
const char * getDescription(ModelDescription* md, ScalarVariable* sv);
const char * getVariableAttributeString(ModelDescription* md, fmiValueReference vr, Elm type, Att a);
double getVariableAttributeDouble(ModelDescription* md, fmiValueReference vr, Elm type, Att a, ValueStatus* vs);
double getNominal(ModelDescription* md, fmiValueReference vr);

#endif /* xmlparser_h */

