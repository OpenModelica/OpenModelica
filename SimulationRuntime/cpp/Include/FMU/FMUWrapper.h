#pragma once
#include <iostream>
#include <string>
#include <vector>
#include <assert.h>
#include "FMU/IFMUInterface.h"
#include "FMU/FMUGlobalSettings.h"

// build MODEL_CLASS from MODEL_IDENTIFIER
#define FMU_PASTER(a, b) a ## b
#define FMU_CONCAT(a, b) FMU_PASTER(a, b)
#define MODEL_CLASS FMU_CONCAT(MODEL_IDENTIFIER_SHORT, Extension)

class FMUWrapper : public IFMUInterface
{
public:
    FMUWrapper(fmiString instanceName, fmiString GUID, fmiCallbackFunctions functions, fmiBoolean loggingOn);
    virtual ~FMUWrapper();
    virtual fmiStatus setDebugLogging  (fmiBoolean loggingOn);

/*  independent variables and re-initialization of caching */
    virtual fmiStatus setTime                (fmiReal time);
    virtual fmiStatus setContinuousStates    (const fmiReal x[], size_t nx);
    virtual fmiStatus completedIntegratorStep(fmiBoolean& callEventUpdate);
    virtual fmiStatus setReal                (const fmiValueReference vr[], size_t nvr, const fmiReal    value[]);
    virtual fmiStatus setInteger             (const fmiValueReference vr[], size_t nvr, const fmiInteger value[]);
    virtual fmiStatus setBoolean             (const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]);
    virtual fmiStatus setString              (const fmiValueReference vr[], size_t nvr, const fmiString  value[]);

/*  of the model equations */
    virtual fmiStatus initialize(fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo& eventInfo);

    virtual fmiStatus getDerivatives    (fmiReal derivatives[]    , size_t nx);
    virtual fmiStatus getEventIndicators(fmiReal eventIndicators[], size_t ni);

    virtual fmiStatus getReal   (const fmiValueReference vr[], size_t nvr, fmiReal    value[]);
    virtual fmiStatus getInteger(const fmiValueReference vr[], size_t nvr, fmiInteger value[]);
    virtual fmiStatus getBoolean(const fmiValueReference vr[], size_t nvr, fmiBoolean value[]);
    virtual fmiStatus getString (const fmiValueReference vr[], size_t nvr, fmiString  value[]);

    virtual fmiStatus eventUpdate               (fmiBoolean intermediateResults, fmiEventInfo& eventInfo);
    virtual fmiStatus getContinuousStates       (fmiReal states[], size_t nx);
    virtual fmiStatus getNominalContinuousStates(fmiReal x_nominal[], size_t nx);
    virtual fmiStatus getStateValueReferences   (fmiValueReference vrx[], size_t nx);
    virtual fmiStatus terminate                 ();
    virtual fmiStatus setExternalFunction       (fmiValueReference vr[], size_t nvr, const void* value[]);
private:
    FMUGlobalSettings _global_settings;
    boost::shared_ptr<MODEL_CLASS> _model;
    std::vector<fmiReal> _tmp_real_buffer;
    std::vector<fmiInteger> _tmp_int_buffer;
    std::vector<fmiBoolean> _tmp_bool_buffer;
    double _need_update;
    void updateModel();
};
