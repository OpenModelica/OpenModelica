#include <windows.h>
#include "xmlparser.h"
#include "fmuWrapper.h"

typedef enum{flat, structured} fmiNamingConvention;
typedef enum{constant, parameter, discrete, continuous} fmiVariability;
typedef enum{input, output, internal, none} fmiCausality;
typedef enum{noalias,alias,negatedAlias} fmiAlias;
typedef enum{fmi_false, fmi_true} fmiBooleanXML;
typedef enum{sv_real, sv_integer, sv_boolean, sv_string,sv_enum} fmiScalarVariableType;

typedef struct{
	const char* declType;
	const char* start;
	fmiBooleanXML fixed;
} fmiSTRING;

typedef struct{
	fmiBooleanXML start;
	const char* declType;
	fmiBooleanXML fixed;
} fmiBOOLEAN;

typedef struct{
	const char* declType;
	const char* quantity;
	double min;
	double max;
	double start;
	fmiBooleanXML fixed;
} fmiINTEGER;

typedef struct{
	const char* declType;
	const char* quantity;
	const char* unit;
	const char* displayUnit;
	fmiBooleanXML relQuantity;
	double min;
	double max;
	double nominal;
	double start;
	fmiBooleanXML fixed;
} fmiREAL;

typedef struct{
	const char* name;
	fmiValueReference vr; // value reference;
	const char* description;
	Enu var;
	Enu causality;
	Enu alias;
	fmiScalarVariableType type;
	void* variable;	
} fmiScalarVariable;


// typedef struct{
	// const char* fmiVersion;
	// const char* modelName;
	// const char* modelIdentifier;
	// const char* guid;
	// const char* description;
	// const char* author;
	// const char* version;
	// const char* generationTool;
	// const char* generationDateAndTime;
	// NamingConvention variableNamingConvention;
	// unsigned int numberOfContinuousStates;
	// unsigned int numberOfEventIndicators;
	// fmuModelVaraibles** modelVariables;
// } fmuModelDescription;

static char* getDecompPath(const char * omPath, const char* mid);
static char* getDllPath(const char* decompPath,const char* mid);
static char* getXMLfile(const char * decompPath, const char * modeldes);
static int decompress(const char* fmuPath, const char* decompPath);
static char* getFMUname(const char* fmupath);
static int getNumberOfSV(ModelDescription* md);
void* allocateElmSV(fmiScalarVariable sv);
static void instScalarVariable(ModelDescription* md,fmiScalarVariable* list);
void tmpcodegen(size_t , size_t , const char* , const char*, const char* );
void blockcodegen(ModelDescription*, size_t , size_t , const char* , const char* , const char* , const char* );
