/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/* ==========================================================================
 * PATCFH OVERVIEW, RouvenZ, August 2026
 *
 * Three independent improvements / issues are addressed. Every change is confined to this
 * file and is marked inline with PATCH 1, PATCH 2 or PATCH 3.
 *
 * --------------------------------------------------------------------------
 * PATCH 1 - Silent fallback of the outputs to an undefined value (usually 0.0)
 *           for continuously positive velocity. 
 *           This is supposed to fix issue #16182.
 * --------------------------------------------------------------------------
 * Root cause:
 *   findOppositeEndSpatialDistribution() documents that *eventPreValue is
 *   written whenever the return value is >= 1. Its "Step 0" shortcut (taken
 *   when the profile advanced by more than one full transport length since the
 *   last stored node) violated that contract: it returned
 *   doubleEndedListLen(storedEventsList), which is > 0 whenever the event list
 *   is non-empty, but never wrote *eventPreValue. The caller then executed
 *       outValue = eventPreValue;
 *   on an uninitialized local variable, silently replacing the correctly
 *   interpolated output with whatever the stack held - typically 0.0. No error
 *   or warning was emitted as long as the event list held exactly one event.
 *
 * Changes:
 *   1a) findOppositeEndSpatialDistribution(): both Step-0 shortcuts now set
 *       *eventPreValue to the interpolated value before returning, restoring
 *       the documented contract. All stored events lie beyond the outlet read
 *       position in that situation (they have already left the transport
 *       domain), so the interpolated value is also the correct pre-event value.
 *   1b) spatialDistribution(): eventPreValue is initialized to NAN as an
 *       explicit "not available" sentinel and is only used when it was actually
 *       written. If it was not, the interpolated value is kept and a warning is
 *       printed instead of silently corrupting the output.
 *
 * Note: this removes the undefined behaviour. It does not make integrator steps
 * that transport more than one full length accurate - such steps inherently
 * discard profile information. Keep -maxStepSize below length/v_max for
 * quantitatively correct results. 
 * 
 * The last sentence should considered to be added to the documentation of the 
 * spatialDistribution operator, as it is a general limitation of the operator 
 * and not an issue of this implementation.
 *
 * --------------------------------------------------------------------------
 * PATCH 2 - Crash on sign changes of the velocity (flow reversal) with
 *           "New end position is not bigger then previous last node." or
 *           "New front position is not smaller then previous first node.".
 *           This is supposed to fix issue #11449.
 * --------------------------------------------------------------------------
 * The node positions must stay monotone: for x increasing the new node is
 * pushed at the front with position -posX, for x decreasing at the back with
 * position -posX+1. The representation itself is fully reversal-capable - the
 * positions are material coordinates and the window [-posX, -posX+1] may slide
 * back and forth over them - but the bookkeeping that decides which end to
 * write had two holes:
 *
 *   a) The mismatch test
 *          isPositiveVelocity*realDirection > 0
 *      can only ever be true for isPositiveVelocity == 1, because false is 0 in
 *      C. The mirror-image mismatch (velocity reported negative while x
 *      actually increased) was therefore never corrected. The new node was
 *      pushed at the back with a position smaller than the current back
 *      position => "New end position is not bigger then previous last node."
 *
 *   b) The correction was only considered for deltaX > SPATIAL_ZERO_DELTA_X,
 *      while the monotonicity assertions in addNewNodeSpatialDistribution are
 *      exact. A backward drift of x inside that dead band was ignored yet still
 *      violated the assertion => "New front position is not smaller then
 *      previous first node."
 *
 * The mismatch itself is unavoidable: isPositiveVelocity comes from the
 * relation v >= 0, which is a discrete value evaluated with hysteresis and held
 * between events, whereas deltaX is whatever the integrator produced over the
 * step. Around a reversal the two disagree for at least one step.
 *
 * Changes:
 *   2a) storeSpatialDistribution(): the storage direction is derived from the
 *       sign of the actual change of x. The reported isPositiveVelocity is only
 *       used when x did not change at all, in which case the new node lands
 *       exactly on the current edge position, which the assertions allow.
 *       No threshold is involved, so the decision is always consistent with
 *       the exact assertions.
 *   2b) spatialDistribution(): the same mismatch test is made symmetric. The
 *       threshold and the "jumped" semantics are kept here, so an out-of-band
 *       drift does not needlessly suppress the extrapolation of the outputs.
 *   2c) The assertions used to be called with threadData == NULL, so a failing
 *       assertion had no jump buffer to unwind to and the process segfaulted
 *       instead of aborting the simulation with a message. threadData is now
 *       threaded through 
 *        - interpolateTransportedQuantity,
 *        - extrapolateTransportedQuantity, 
 *        - addNewNodeSpatialDistribution,
 *        - findOppositeEndSpatialDistribution and 
 *        - pruneSpatialDistribution.
 *
 * Remaining limitation: a sign change of v *inside* a single integrator step is
 * invisible to the operator, which sees one monotone move of x. That is a
 * property of the operator definition, not of this implementation.
 *
 * --------------------------------------------------------------------------
 * PATCH 3 - Absolute tolerances versus an unbounded position coordinate.
 *           
 *           This does NOT fix an issue, but can be considered for implementation
 *           to avoid potentially unwanted behaviour.
 * --------------------------------------------------------------------------
 * epsilon.h defines
 *     SPATIAL_EPS            = DBL_EPSILON   (2.2e-16, exactly one ulp at 1.0)
 *     SPATIAL_ZERO_DELTA_X   = 1e-12
 * as *absolute* tolerances, while posX = x/length grows without bound: after
 * 2e6 s at 1 m/s in a 100 m pipe, posX is about 2e4, where the spacing between
 * two representable doubles (the coordinate quantum) is already 3.6e-12 -
 * larger than both tolerances.
 *
 * What is NOT a problem here (measured by Claude, probably no fix needed):
 *   - Adding or subtracting 1.0 is *exact* for |x| < 2^52. The spans written by
 *     the pruning (edgeNodeData->position +/- 1) and the read positions (-posX,
 *     -posX+1) therefore carry no rounding error at all.
 *   - Subtracting two nearby doubles is exact as well, so deltaX and the node
 *     distances carry no rounding error either. The distance-to-one tests and
 *     the "x got reinitialized during an event" check do *not* misfire from
 *     large |posX|.
 *
 * What is a problem:
 *   - The tolerance can fall below the coordinate quantum. Already for
 *     |posX| > 1 the position tolerance is below the quantum (at 2e4 it is
 *     16384 times smaller), so every "same position" test becomes a
 *     bitwise equality; from |posX| > 4.5e3 the same holds for the
 *     SPATIAL_ZERO_DELTA_X dead band, which can then only be satisfied by an
 *     exactly zero deltaX. The comparisons therefore stop expressing what they
 *     were written to express.
 *   - The guards that protect the division inside interpolate/extrapolate
 *     (fabs(posA - posB) > SPATIAL_EPS) accept a node spacing of a single
 *     quantum and therefore no longer reject an ill-conditioned interpolation.
 *   - fabs(front->value - in0) > SPATIAL_EPS compares a *transported quantity*
 *     against a tolerance sized for 1.0. Specific enthalpies are of order 1e5,
 *     where one ulp is 7.3e-12, so any difference whatsoever counts as a
 *     discrete change. This is the case with a directly visible effect: it
 *     produces spurious event nodes, and a non-empty event list is exactly the
 *     precondition for the PATCH 1 failure mode.
 *
 * Fix: scale each tolerance with the magnitude of the operands the comparison is
 * made from - the only scale at which a floating point difference carries
 * information. The helpers spatialPosEps(), spatialValEps() and
 * spatialZeroDeltaX() below implement this, with the scale clamped at 1.0 from
 * below so that nothing becomes tighter than before near the origin.
 *
 * Residual limitation that scaling cannot address (but which is probably)
 * no problem anyways: the coordinate *resolution*
 * itself degrades as posX grows. Two stored nodes collapse onto one double once
 * v*h/length falls below |posX|*2^-52, which for a 2e6 s run means step sizes
 * below roughly 4e-10 s - not reachable in practice, but the only real remedy
 * would be to re-base the origin periodically, i.e. shift startPosX and all
 * stored positions by a constant.
 *
 * Not changed: initSpatialDistribution(). Its initialPoints are normalized to
 * [0, 1] by definition, so the absolute tolerance is already the correct one.
 * ========================================================================== */

//#if !defined(OMC_NDELAY_EXPRESSIONS) || OMC_NDELAY_EXPRESSIONS>0

/*! \file spatialDistribution.c
 */

#include "spatialDistribution.h"
#include "../../util/omc_error.h"
#include "../../util/ringbuffer.h"
#include "../../openmodelica.h"
#include "epsilon.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>


/**
 * @brief Describing value z(x,t).
 *
 * See Modelica specification 3.7.2.2 spatialDistribution for details
 * on transported quantity z(x,t).
 * https://specification.modelica.org/maint/3.4/Ch3.html#spatialdistribution
 */
typedef struct TRANSPORTED_QUANTITY_DATA {
  double position;    /* position x */
  double value;       /* transported quantity at position x */
} TRANSPORTED_QUANTITY_DATA;

/**
 * @brief Saving an event at given position.
 *
 * The zero crossing function will return 0 on this event,
 * zeroCrossValue until next event position
 * and -1*zeroCrossValue before this event.
 */
typedef struct TRANSPORTED_EVENT_DATA {
  double position;              /* position x */
  double zeroCrossValue;        /* Value of zero crossing at position x
                                 * Either +1 or -1 */
} TRANSPORTED_EVENT_DATA;


/* Private function prototypes
 * PATCH 2c: threadData is threaded through all helpers that assert, so a failing
 * assertion can unwind instead of dereferencing a NULL thread context. */
double interpolateTransportedQuantity(threadData_t *threadData, const TRANSPORTED_QUANTITY_DATA* leftData, const TRANSPORTED_QUANTITY_DATA* rightData, const double interpolationPos);
double extrapolateTransportedQuantity(threadData_t *threadData, const TRANSPORTED_QUANTITY_DATA* leftData, const TRANSPORTED_QUANTITY_DATA* rightData, const double extrapolationPos);
void addNewNodeSpatialDistribution(threadData_t *threadData, SPATIAL_DISTRIBUTION_DATA* spatialDistribution, int isPositiveVelocity, double position, double value, int isEvent);
int findOppositeEndSpatialDistribution(threadData_t *threadData, SPATIAL_DISTRIBUTION_DATA* spatialDistribution, double in0, double in1, double posX, int isPositiveVelocity, double* eventPreValue, double* outValue);
int pruneSpatialDistribution(threadData_t *threadData, SPATIAL_DISTRIBUTION_DATA* spatialDistribution, int isPositiveVelocity);


// ############################################################################
//
// PATCH 3: magnitude-scaled tolerances
//
// ############################################################################

/**
 * @brief Headroom in ulps for the scaled comparisons.
 *
 * The comparison has to be at least a few coordinate quanta wide to express
 * "not distinguishable at this scale", and a position may carry up to half an
 * ulp from the startPosX shift in shiftToStartPosX(), so one ulp is not enough
 * headroom while a handful is. At scale 1.0 this gives 1.8e-15, still many
 * orders of magnitude below the smallest physically meaningful spacing between
 * two nodes (v*h/length).
 */
static const double SPATIAL_EPS_ULPS = 8.0;

/**
 * @brief Magnitude of the two operands a difference was computed from.
 *
 * Clamped at 1.0 from below so that the scaled tolerances never become tighter
 * than the original absolute ones near the origin.
 */
static double spatialScale(double a, double b) {
  double scaleA = fabs(a);
  double scaleB = fabs(b);
  double scale = (scaleA > scaleB) ? scaleA : scaleB;
  return (scale > 1.0) ? scale : 1.0;
}

/**
 * @brief Tolerance for comparing two positions (or a difference of positions).
 *
 * Pass the two *operands*, not their difference: the absolute error of a
 * floating point difference is set by the magnitude of the operands, not by the
 * magnitude of the result. This matters for the distance-to-one tests, where the
 * result is about 1 while the operands can be of order 1e4.
 */
static double spatialPosEps(double posA, double posB) {
  return SPATIAL_EPS_ULPS * SPATIAL_EPS * spatialScale(posA, posB);
}

/**
 * @brief Tolerance for deciding whether a transported value changed discretely.
 *
 * The transported quantity is arbitrary (specific enthalpies are of order 1e5),
 * so an absolute tolerance of one ulp at 1.0 would classify every re-store as a
 * discrete change and fill the event list with spurious entries.
 */
static double spatialValEps(double valA, double valB) {
  return SPATIAL_EPS_ULPS * SPATIAL_EPS * spatialScale(valA, valB);
}

/**
 * @brief Scaled version of the "x is standing still" threshold.
 */
static double spatialZeroDeltaX(double posA, double posB) {
  return SPATIAL_ZERO_DELTA_X * spatialScale(posA, posB);
}

// ############################################################################
//
// Section for allocating/ deallocating spatial distribution data
//
// ############################################################################


/**
 * @brief Allocates memory for spatial distribution structs.
 *
 * Returns pointer to array with allocated spatial distribution structs.
 * To free memroy call freeSpatialDistribution.
 *
 * @param nSpatialDistributions           Number of spacial distributions to be allocated.
 * @return SPATIAL_DISTRIBUTION_DATA*     Array with allocated spatial distributions.
 */
SPATIAL_DISTRIBUTION_DATA* allocSpatialDistribution(unsigned int nSpatialDistributions) {
  /* Debug info */
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "Allocating memory for %i spatial distribution(s).", nSpatialDistributions);

  /* Variables */
  int i;
  SPATIAL_DISTRIBUTION_DATA* spatialDistributionData;

  if (nSpatialDistributions==0) {
    return NULL;
  }

  spatialDistributionData = (SPATIAL_DISTRIBUTION_DATA*) calloc(nSpatialDistributions, sizeof(SPATIAL_DISTRIBUTION_DATA));

  for(i=0; i<nSpatialDistributions; i++) {
    spatialDistributionData[i].index = i;
    spatialDistributionData[i].isInitialized = 0 /* false */;
    spatialDistributionData[i].startPosXSet = 0 /* false */;
    spatialDistributionData[i].startPosX = 0.0 /* false */;
    spatialDistributionData[i].oldPosX = 0.0;
    spatialDistributionData[i].transportedQuantity = allocDoubleEndedList(sizeof(TRANSPORTED_QUANTITY_DATA)); /* empty double ended list */
    spatialDistributionData[i].storedEvents = allocDoubleEndedList(sizeof(TRANSPORTED_EVENT_DATA));           /* empty double ended list */
    spatialDistributionData[i].lastStoredEventValue = 0;
  }

  return spatialDistributionData;
}


/**
 * @brief Frees array of spatial distributions.
 *
 * @param spatialDistributionData     Array with spatial distribution of length nSpatialDistributions.
 * @param nSpatialDistributions       Length of spatialDistributionData.
 */
void freeSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistributionData, unsigned int nSpatialDistributions) {
  /* Debug info */
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "Freeing %i spatial distribution(s).", nSpatialDistributions);

  /* Variables */
  int i;

  for(i=0; i<nSpatialDistributions; i++) {
    freeDoubleEndedList(spatialDistributionData[i].transportedQuantity);
    freeDoubleEndedList(spatialDistributionData[i].storedEvents);
  }
}


/**
 * @brief Initializes transportedQuantity of single spacial distribution.
 *
 * Spatial distribution array data->simulationInfo->spatialDistributionData has
 * to be allocated before using allocSpatialDistribution.
 *
 * @param data              Data
 * @param threadData        threadDate for error handling
 * @param index             Index of spatial distribution, has to match position data->simulationInfo->spatialDistributionData[index].
 * @param initialPoints     Array with initial points.
 *                          Is ordered from 0.0 = initialPoints[0] < initialPoints[i] < initialPoints[length] = 1.0
 * @param initialValues     Array with initial values at initial points.
 * @param length            Length of arrays initialPoints and initialValues.
 */
void initSpatialDistribution(DATA* data, threadData_t* threadData, unsigned int index, real_array* initialPoints, real_array* initialValues, unsigned int length) {
  /* Debug info */
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 1, "Initializing spatial distributions (index=%i)", index);

  /* Variables */
  int i;
  SPATIAL_DISTRIBUTION_DATA* spatialDistributionData;
  DOUBLE_ENDED_LIST* transportedQuantityList;
  TRANSPORTED_QUANTITY_DATA tmpData;
  TRANSPORTED_EVENT_DATA eventData;
  int numSamePos = 0;
  double lastZeroCrossValue = -1;
  modelica_real* initPnts = (modelica_real *) initialPoints->data;
  modelica_real* initVals = (modelica_real *) initialValues->data;

  /* Error checking */
  if (fabs(initPnts[0]) > SPATIAL_EPS ) {
    errorStreamPrint(OMC_LOG_STDOUT, 1, "Initialization of spatial distribution with index %i failed.", index);
    errorStreamPrint(OMC_LOG_STDOUT, 0, "initialPoints[0] = %e is not zero.", initPnts[0]);
    messageClose(OMC_LOG_STDOUT);
    omc_throw_function(threadData);
  }
  else if (fabs(initPnts[length-1] - 1.0) > SPATIAL_EPS) {
    errorStreamPrint(OMC_LOG_STDOUT, 1, "Initialization of spatial distribution with index %i failed.", index);
    errorStreamPrint(OMC_LOG_STDOUT, 0, "initialPoints[end] = %e is not one.", initPnts[length-1]);
    messageClose(OMC_LOG_STDOUT);
    omc_throw_function(threadData);
  }
  for (i=0; i<length-2; i++) {
    if (initPnts[i] > initPnts[i+1]) {
      errorStreamPrint(OMC_LOG_STDOUT, 1, "Initialization of spatial distribution with index %i failed.", index);
      errorStreamPrint(OMC_LOG_STDOUT, 0, "initialPoints[%i] > initialPoints[%i]", i, i+1);
      errorStreamPrint(OMC_LOG_STDOUT, 0, "%f > %f", initVals[i], initPnts[i+1]);
      messageClose(OMC_LOG_STDOUT);
      omc_throw_function(threadData);
    }
  }
  spatialDistributionData = &(data->simulationInfo->spatialDistributionData[index]);
  assertStreamPrint(threadData, 1 != spatialDistributionData->isInitialized, "SpatialDistribution was allready allocated!");

  /* Initialize quantity list */
  transportedQuantityList = spatialDistributionData->transportedQuantity;
  for (i=0; i<length-1; i++) {
    tmpData.position = initPnts[i];
    tmpData.value = initVals[i];
    pushBackDoubleEndedList(transportedQuantityList, (const void*) &tmpData);
    if (initPnts[i] == initPnts[i+1]) {
      numSamePos += 1;
      if (numSamePos > 1) {
        errorStreamPrint(OMC_LOG_STDOUT, 1, "Initialization of spatial distribution with index %i failed.", index);
        errorStreamPrint(OMC_LOG_STDOUT, 0, "initialPoints[%i] = initialPoints[%i] = initialPoints[%i]", i-1, i, i+1);
        errorStreamPrint(OMC_LOG_STDOUT, 0, "Only events with one pre-value and one value are allowed.");
        messageClose(OMC_LOG_STDOUT);
        omc_throw_function(threadData);
      }
      eventData.position = initPnts[i];
      lastZeroCrossValue = lastZeroCrossValue*(-1);
      eventData.zeroCrossValue = lastZeroCrossValue;
      pushBackDoubleEndedList(spatialDistributionData->storedEvents, (const void*) &eventData);
    } else {
      numSamePos = 0;
    }
  }
  tmpData.position = initPnts[length-1];
  tmpData.value = initVals[length-1];
  pushBackDoubleEndedList(transportedQuantityList, (const void*) &tmpData);

  spatialDistributionData->isInitialized = 1 /* true */;

  /* Debug info */
  doubleEndedListPrint(transportedQuantityList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "List of events");
  doubleEndedListPrint(spatialDistributionData->storedEvents, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);
  messageClose(OMC_LOG_SPATIALDISTR);
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "Finished initializing spatial distribution (index=%i)", index);
}


// ############################################################################
//
// Section for evaluating spatialDistribution operator
//
// ############################################################################


/**
 * @brief Shift posX so that the operator internally starts at x = 0.
 *
 * The spatialDistribution operator only depends on the change of the spatial
 * coordinate x (the transport distance), not on its absolute value, and its
 * initial profile (initialPoints/initialValues) is stored assuming x(t0) = 0.
 * The value of x at the very first call is captured once and subtracted from
 * every subsequent posX, so a model where x has a nonzero start value behaves
 * exactly like one starting at x = 0 (and no longer triggers a spurious
 * "x got reinitialized during an event" error at the initial event).
 *
 * @param spatialDistribution   Spatial distribution to shift for.
 * @param posX                  Value of position x.
 * @return double               posX relative to its value at the first call.
 */
static double shiftToStartPosX(SPATIAL_DISTRIBUTION_DATA* spatialDistribution, double posX) {
  if (!spatialDistribution->startPosXSet) {
    spatialDistribution->startPosX = posX;
    spatialDistribution->startPosXSet = 1 /* true */;
  }
  return posX - spatialDistribution->startPosX;
}


/**
 * @brief Store spatial distribution data for an accepted step.
 *
 * @param data                Data
 * @param threadData          Thread data for error handling
 * @param index               Index of spatial distribution.
 * @param in0                 First input to spatial distribution.
 * @param in1                 Second input to spatial distribution
 * @param posX                Value of position x.
 * @param isPositiveVelocity  Boolean describing if velocity v is positive (>=0).
 *                            Velocity v is `v:=der(x)`.
 */
void storeSpatialDistribution(DATA* data, threadData_t *threadData, unsigned int index, double in0, double in1, double posX, int isPositiveVelocity) {
  /* Variables */
  SPATIAL_DISTRIBUTION_DATA* spatialDistribution;
  DOUBLE_ENDED_LIST* transportedQuantityList;
  DOUBLE_ENDED_LIST* storedEventsList;
  int walkedOverEvents = 0;
  double deltaX, realDirection;

  /* Access spatialDistribution */
  spatialDistribution = &(data->simulationInfo->spatialDistributionData[index]);
  transportedQuantityList = spatialDistribution->transportedQuantity;
  storedEventsList = spatialDistribution->storedEvents;

  /* Shift x so the operator starts at x = 0 (only the change of x matters) */
  posX = shiftToStartPosX(spatialDistribution, posX);

  /* Debug log */
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 1, "Calling storeSpatialDistribution (index=%i, time=%e)", index, data->localData[0]->timeValue);
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "spatialDistribution(%f, %f, %f, %s)", in0, in1, posX, isPositiveVelocity?"true":"false");
  doubleEndedListPrint(transportedQuantityList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "List of events");
  doubleEndedListPrint(storedEventsList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);

  if (data->simulationInfo->discreteCall) {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "Discrete call of storeSpatialDistribution");
    omc_throw_function(threadData);
  }

  /* Get deltaX */
  deltaX = spatialDistribution->oldPosX - posX;
  if (deltaX > 0) {
    realDirection = 1 /* positive */;
  } else if (deltaX < 0) {
    realDirection = -1 /* negative */;
    deltaX = -deltaX;
  } else {
    realDirection = 0 /* standing still */;
  }

  /* PATCH 2a: Derive the storage direction from the sign of the actual change of
   * x instead of trusting the reported isPositiveVelocity.
   *
   * realDirection == +1 means posX decreased, i.e. x decreased (v < 0), because
   * deltaX was computed as oldPosX - posX. realDirection == -1 means x increased
   * (v > 0). The reported isPositiveVelocity is the held value of the relation
   * v >= 0 and can lag the sign of deltaX by a step around a flow reversal.
   *
   * The previous test
   *     deltaX > SPATIAL_ZERO_DELTA_X && isPositiveVelocity*realDirection > 0
   * could only detect the mismatch (reported positive, x decreasing), because
   * false is 0 in C, and it ignored any mismatch inside the SPATIAL_ZERO_DELTA_X
   * dead band although the monotonicity assertions in
   * addNewNodeSpatialDistribution are exact. Both gaps ended in a failing
   * assertion (and, via threadData == NULL, in a crash) on sign changes of v.
   *
   * Deriving the direction from realDirection alone closes both gaps: the end
   * that is written is by construction the end that keeps the positions
   * monotone, for arbitrarily small |deltaX|. */
  if (realDirection > 0) {
    isPositiveVelocity = 0 /* false: x decreased, write at the back */;
  } else if (realDirection < 0) {
    isPositiveVelocity = 1 /* true: x increased, write at the front */;
  }
  /* realDirection == 0: keep the reported direction. The new node then lands
   * exactly on the current edge position, which the assertions allow (<=, >=)
   * and which is the existing event-node case handled below. */

  /* Add new node (oldPosX-deltaX, in0) or (oldPosX-deltaX+1, in1) to list
   * Check if it an event and only save it if has a discrete change in in0 or in1.
   */
  if (isPositiveVelocity) {
    TRANSPORTED_QUANTITY_DATA* front = (TRANSPORTED_QUANTITY_DATA*) firstDataDoubleEndedList(transportedQuantityList);
    /* PATCH 3: scaled position and value tolerances */
    if (fabs(-posX - front->position) < spatialPosEps(-posX, front->position)) {
      if (fabs(front->value - in0) > spatialValEps(front->value, in0)) {
        addNewNodeSpatialDistribution(threadData, spatialDistribution, isPositiveVelocity, -posX, in0, 1 /* true */);
      }
    } else {
      addNewNodeSpatialDistribution(threadData, spatialDistribution, isPositiveVelocity, -posX, in0, 0 /* false */);
    }
  } else {
    TRANSPORTED_QUANTITY_DATA* last = (TRANSPORTED_QUANTITY_DATA*) lastDataDoubleEndedList(transportedQuantityList);
    /* PATCH 3: scaled position and value tolerances */
    if (fabs(-posX+1 - last->position) < spatialPosEps(-posX+1, last->position)) {
      if (fabs(last->value - in1) > spatialValEps(last->value, in1)) {
        addNewNodeSpatialDistribution(threadData, spatialDistribution, isPositiveVelocity, -posX+1, in1, 1 /* true */);
      }
    } else {
      addNewNodeSpatialDistribution(threadData, spatialDistribution, isPositiveVelocity, -posX+1, in1, 0 /* false */);
    }
  }

  /* Remove nodes that droppen of spatial distribution */
  walkedOverEvents = pruneSpatialDistribution(threadData, spatialDistribution, isPositiveVelocity);
  if (walkedOverEvents > 1) {
    warningStreamPrint(OMC_LOG_STDOUT, 1, "Removed more then one event from spatialDistribution. Step size to big!");
    warningStreamPrint(OMC_LOG_STDOUT, 0, "time: %f, spatialDistribution index: %i, number of events: %i", data->localData[0]->timeValue, index, walkedOverEvents);
    messageCloseWarning(OMC_LOG_STDOUT);
  }

  /* Update oldPosX */
  spatialDistribution->oldPosX = posX;
  messageClose(OMC_LOG_SPATIALDISTR);
  return;
}


/**
 * @brief Evaluate spatialDistribution operator.
 *
 * (out0, out1) = spatialDistribution (in0, in1, posX, isPositiveVelocity)
 * If an event was outputted integrator needs to iterate.
 * Doesn't store in0 or in1 because this function doesn't know if the step will be accepted.
 *
 * @param data                Data
 * @param threadData          Thread data for error handling
 * @param index               Index of spatial distribution.
 * @param in0                 First input to spatial distribution.
 * @param in1                 Second input to spatial distribution
 * @param posX                Value of position x.
 * @param isPositiveVelocity  Boolean describing if velocity v is positive (>=0).
 *                            Velocity v is `v:=der(x)`.
 * @param out1                Second output of spatial distribution.
 * @return double             out0, first output of spatial distribution.
 */
double spatialDistribution(DATA* data, threadData_t *threadData, unsigned int index, double in0, double in1, double posX, int isPositiveVelocity, double* out1) {
  /* Variables */
  SPATIAL_DISTRIBUTION_DATA* spatialDistribution;
  DOUBLE_ENDED_LIST* transportedQuantityList;
  DOUBLE_ENDED_LIST_NODE* firstNode;
  DOUBLE_ENDED_LIST_NODE* lastNode;
  TRANSPORTED_QUANTITY_DATA* firstNodeData;
  TRANSPORTED_QUANTITY_DATA* secondNodeData;
  TRANSPORTED_QUANTITY_DATA* lastNodeData;
  TRANSPORTED_QUANTITY_DATA* forelastNodeData;
  int walkedOverEvents;
  int realDirection;
  int jumped = 0;
  double deltaX;
  double eventPreValue = NAN;   /* PATCH 1b: sentinel "no event pre-value available" */
  double outValue;
  double out0;      /* First output variable */
  double out1Val;   /* Second output variable, only written to *out1 if out1 != NULL */

  /* Access spatialDistribution */
  spatialDistribution = &(data->simulationInfo->spatialDistributionData[index]);
  transportedQuantityList = spatialDistribution->transportedQuantity;

  /* Shift x so the operator starts at x = 0 (only the change of x matters) */
  posX = shiftToStartPosX(spatialDistribution, posX);

  /* Debug log */
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 1, "Calling spatialDistribution (index=%i, time=%e)", index, data->localData[0]->timeValue);
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "(out0,out1) = spatialDistribution(in0=%f, in1=%f, x=%f, isPositiveVelocity=%s)", in0, in1, posX, isPositiveVelocity?"true":"false");
  doubleEndedListPrint(transportedQuantityList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);

  /* Get deltaX */
  deltaX = spatialDistribution->oldPosX - posX;
  if (deltaX > 0) {
    realDirection = 1 /* positive */;
  } else if (deltaX < 0) {
    realDirection = -1 /* negative */;
    deltaX = -deltaX;
  } else {
    realDirection = 0 /* standing still */;
  }

  /* If real direction doesn't match isPositiveVelocity just flip isPositiveVelocity.
   * This still indicates something wrong, so we don't extrapolate the output.
   *
   * PATCH 2b: made symmetric. The original condition
   *     isPositiveVelocity*realDirection > 0
   * could only ever be true for isPositiveVelocity == 1, because false is 0 in C,
   * so the mismatch (velocity reported negative while x increased) was never
   * caught. Unlike the store path this keeps the SPATIAL_ZERO_DELTA_X threshold
   * and the "jumped" flag: a drift below the threshold must not suppress the
   * extrapolation of the outputs.
   * PATCH 3: the threshold is scaled with the magnitude of the positions. */
  if (deltaX > spatialZeroDeltaX(spatialDistribution->oldPosX, posX) &&
      ((isPositiveVelocity && realDirection > 0) || (!isPositiveVelocity && realDirection < 0))) {
    isPositiveVelocity  = !isPositiveVelocity;
    jumped = 1 /* true */;
  }

  /* Check if x was reinitialized
   * PATCH 3: scaled threshold. deltaX itself is exact (subtraction of two nearby
   * doubles), but the plain SPATIAL_ZERO_DELTA_X falls below the coordinate
   * quantum for |posX| > 4.5e3, where this dead band degenerates into "deltaX is
   * exactly zero". */
  if (deltaX > spatialZeroDeltaX(spatialDistribution->oldPosX, posX) && data->simulationInfo->discreteCall) {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "x got reinitialized during an event at time %f. OpenModelica can't handle that.", data->localData[0]->timeValue);
    omc_throw_function(threadData);
  }

  /* Special case: Zero progress
   * PATCH 3: scaled tolerance, see above */
  if (deltaX < spatialPosEps(spatialDistribution->oldPosX, posX)) {
    firstNodeData = (TRANSPORTED_QUANTITY_DATA*) firstDataDoubleEndedList(transportedQuantityList);
    lastNodeData = (TRANSPORTED_QUANTITY_DATA*) lastDataDoubleEndedList(transportedQuantityList);
    out0 = firstNodeData->value;
    out1Val = lastNodeData->value;
    if (out1 != NULL) {
      *out1 = out1Val;
    }
    infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "(out0,out1) = (%f, %f)", out0, out1Val);
    messageClose(OMC_LOG_SPATIALDISTR);
    return out0;
  }

  /* Get value of ou0/out1 by walkling over list */
  walkedOverEvents = findOppositeEndSpatialDistribution(threadData, spatialDistribution, in0, in1, posX, isPositiveVelocity, &eventPreValue, &outValue);

  /* Handle events that would come out of spatialDistribution */
  if (walkedOverEvents > 1) {
    warningStreamPrint(OMC_LOG_STDOUT, 1, "Need to output more then one event from spatialDistribution. Step size to big!");
    warningStreamPrint(OMC_LOG_STDOUT, 0, "time: %f, spatialDistribution index: %i, number of events: %i", data->localData[0]->timeValue, index, walkedOverEvents);
    messageCloseWarning(OMC_LOG_STDOUT);
  }
  if (walkedOverEvents>0 && !data->simulationInfo->discreteCall) {
    /* PATCH 1b: Only substitute the pre-event value if it was actually provided.
     * Using it unconditionally read an uninitialized variable whenever
     * findOppositeEndSpatialDistribution returned a non-zero event count
     * without writing eventPreValue, which silently forced the output to an
     * undefined value (typically 0.0). */
    if (!isnan(eventPreValue)) {
      infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "Found event in spatial distribution at time %f", data->localData[0]->timeValue);
      outValue = eventPreValue;
    } else {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "spatialDistribution index %i reported %i event(s) without a pre-value at time %f. Keeping interpolated value.", index, walkedOverEvents, data->localData[0]->timeValue);
    }
  }

  /* Extrapolate return values to break up quasi-loop with inputs */
  firstNodeData = (TRANSPORTED_QUANTITY_DATA*) firstDataDoubleEndedList(transportedQuantityList);
  secondNodeData = dataDoubleEndedList(getNextNodeDoubleEndedList(getFirstNodeDoubleEndedList(transportedQuantityList)));
  lastNodeData = (TRANSPORTED_QUANTITY_DATA*) lastDataDoubleEndedList(transportedQuantityList);
  forelastNodeData = dataDoubleEndedList(getPreviousNodeDoubleEndedList(getLastNodeDoubleEndedList(transportedQuantityList)));
  /* PATCH 3: scaled tolerances. The second test guards the division by the node
   * distance inside extrapolateTransportedQuantity, so it has to use the same
   * scale as the positions it compares. */
  if (isPositiveVelocity) {
    if (jumped) {
      out0 = in0;
    } else if (deltaX > spatialPosEps(spatialDistribution->oldPosX, posX) &&
               fabs(firstNodeData->position-secondNodeData->position) > spatialPosEps(firstNodeData->position, secondNodeData->position)) {
      out0 = extrapolateTransportedQuantity(threadData, firstNodeData, secondNodeData, -posX);
    } else {
      out0 = firstNodeData->value;
    }
    out1Val = outValue;
  } else {
    out0 = outValue;
    if (jumped) {
      out1Val = in1;
    } else if (deltaX > spatialPosEps(spatialDistribution->oldPosX, posX) &&
               fabs(forelastNodeData->position-lastNodeData->position) > spatialPosEps(forelastNodeData->position, lastNodeData->position)) {
      out1Val = extrapolateTransportedQuantity(threadData, forelastNodeData, lastNodeData, -posX+1);
    } else {
      out1Val = lastNodeData->value;
    }
  }

  if (out1 != NULL) {
    *out1 = out1Val;
  }

  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "(out0,out1) = (%f, %f)", out0, out1Val);
  messageClose(OMC_LOG_SPATIALDISTR);
  return out0;
}


// ############################################################################
//
// Section for evaluating spatialDistribution zero-crossing function
//
// ############################################################################


/**
 * @brief Returns value of zero crossing at position x.
 *
 * zeroCross(x):= -1 if there are no events or before the first event.
 * Otherwise zeroCross(x):=(-1)*zeroCross(x_E), where x_E is the position of the nearest event with bigger position.
 * If there is no event with bigger position zeroCross(x):=zeroCross(x_E) where x_E is the event with the biggest position.
 *
 * @param data                Data
 * @param threadData          threadDate for error handling
 * @param index               Index of spatial distribution, has to match position data->simulationInfo->spatialDistributionData[index].
 * @param posX                Value of position x.
 * @param isPositiveVelocity  Unused
 * @return double             Value of zeroCrossing at position posX.
 */
double spatialDistributionZeroCrossing(DATA* data, threadData_t *threadData, unsigned int index, unsigned int relationIndex, double posX, int isPositiveVelocity) {
  /* Variables */
  SPATIAL_DISTRIBUTION_DATA* spatialDistribution;
  DOUBLE_ENDED_LIST* storedEventsList;
  DOUBLE_ENDED_LIST_NODE* currentNode;
  TRANSPORTED_EVENT_DATA* currentNodeData;
  double zeroCrossingValue = -1;
  double prevPosition, prevValue;

  /* Access spatialDistribution */
  spatialDistribution = &(data->simulationInfo->spatialDistributionData[index]);
  storedEventsList = spatialDistribution->storedEvents;

  /* Shift x so the operator starts at x = 0 (only the change of x matters).
   * Do NOT capture the start position here: the zero-crossing function is
   * evaluated unconditionally by the solver, also while the operator is frozen
   * inside an inactive if-branch. Capturing the start position here would mark
   * the operator as started too early and make the guarded storeSpatialDistribution/
   * spatialDistribution calls see a spurious jump in x (#16099). While the
   * operator has not started yet its event list is empty and the returned value
   * does not depend on posX anyway. */
  if (spatialDistribution->startPosXSet) {
    posX = posX - spatialDistribution->startPosX;
  }

  if (doubleEndedListLen(storedEventsList) == 0) {
    zeroCrossingValue = data->simulationInfo->zeroCrossingsPre[relationIndex];
    infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "spatialDistributionZeroCrossing(%e) = %e (no stored events, returning previous value)", posX, zeroCrossingValue);
    return zeroCrossingValue;
  }

  if (isPositiveVelocity) {
    currentNode = getLastNodeDoubleEndedList(storedEventsList);
    currentNodeData = dataDoubleEndedList(currentNode);
    // -posX+1 is behind last event
    if (currentNodeData->position < -posX+1 ) {
      zeroCrossingValue = -currentNodeData->zeroCrossValue;
    } else {
      while (currentNode != NULL) {
        // Am I on an event?
        /* PATCH 3: scaled tolerance */
        if (fabs(currentNodeData->position+posX-1) <= spatialPosEps(currentNodeData->position, posX)) {
          zeroCrossingValue = -currentNodeData->zeroCrossValue;
          break;
        }

        prevPosition = currentNodeData->position;
        prevValue = currentNodeData->zeroCrossValue;
        currentNode = getPreviousNodeDoubleEndedList(currentNode);
        // Did I walk over the first element in the list?
        if (currentNode==NULL) {
          zeroCrossingValue = prevValue;  /* prevValue value of first list element */
          break;
        }
        currentNodeData = dataDoubleEndedList(currentNode);

        // Are we between two events?
        if (currentNodeData->position < -posX+1 && -posX+1 < prevPosition) {
          zeroCrossingValue = prevValue;
          break;
        }
      }
    }
  } else {
    currentNode = getFirstNodeDoubleEndedList(storedEventsList);
    currentNodeData = dataDoubleEndedList(currentNode);
    // -posX is before first event
    if (currentNodeData->position > -posX ) {
      zeroCrossingValue = currentNodeData->zeroCrossValue;
    } else {
      while (currentNode != NULL) {
        // Am I on an event?
        /* PATCH 3: scaled tolerance */
        if (fabs(currentNodeData->position+posX) <= spatialPosEps(currentNodeData->position, posX)) {
          zeroCrossingValue = -currentNodeData->zeroCrossValue;
          break;
        }

        prevPosition = currentNodeData->position;
        prevValue = currentNodeData->zeroCrossValue;
        currentNode = getNextNodeDoubleEndedList(currentNode);
        // Did I walk over the first element in the list?
        if (currentNode==NULL) {
          zeroCrossingValue = -prevValue;  /* prevValue value of first list element */
          break;
        }
        currentNodeData = dataDoubleEndedList(currentNode);

        // Are we between two events?
        if (currentNodeData->position > -posX && -posX > prevPosition) {
          zeroCrossingValue = -prevValue;
          break;
        }
      }
    }
  }


  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "List of events for spatialDistributionZeroCrossing(%e) = %e", posX, zeroCrossingValue);
  doubleEndedListPrint(storedEventsList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);

  return zeroCrossingValue;
}


// ############################################################################
//
// Section for "small" helper functions
//
// ############################################################################


/**
 * @brief Linear interpolation between left and right (position,value) pair at given position.
 *
 * leftData->position < interpolationPos < rightData->position must hold.
 *
 * @param leftData                Left (position,value) pair
 * @param rightData               Right (position,value) pair
 * @param interpolationPos        Position where to interpolate.
 * @return double                 Interpolated value
 */
double interpolateTransportedQuantity(threadData_t *threadData, const TRANSPORTED_QUANTITY_DATA* leftData, const TRANSPORTED_QUANTITY_DATA* rightData, const double interpolationPos) {
  double leftPosition, rightPosition;
  double leftValue, rightValue;
  double distPos;
  double interpolatedValue;

  leftPosition = leftData->position;
  leftValue = leftData->value;
  rightPosition = rightData->position;
  rightValue = rightData->value;
  distPos = rightPosition - leftPosition;

  /* PATCH 2c: threadData instead of NULL, so this aborts the simulation with a
   * message instead of crashing the process. */
  assertStreamPrint(threadData, distPos > 0, "interpolateTransportedQuantity: wrong order or same position!");

  interpolatedValue = leftValue  * ((rightPosition-interpolationPos)/distPos)
                    + rightValue * ((interpolationPos-leftPosition)/distPos);

  return interpolatedValue;
}


/**
 * @brief Linear extrapolation at given position.
 *
 * @param leftData              Left (position,value) pair
 * @param rightData             Right (position,value) pair
 * @param extrapolationPos      Position where to interpolate.
 * @return double               Extrapolated value.
 */
double extrapolateTransportedQuantity(threadData_t *threadData, const TRANSPORTED_QUANTITY_DATA* leftData, const TRANSPORTED_QUANTITY_DATA* rightData, const double extrapolationPos) {
  double leftPosition, rightPosition;
  double leftValue, rightValue;
  double distPos;
  double extrapolatedValue;

  leftPosition = leftData->position;
  leftValue = leftData->value;
  rightPosition = rightData->position;
  rightValue = rightData->value;
  distPos = rightPosition - leftPosition;

  /* PATCH 2c: threadData instead of NULL */
  assertStreamPrint(threadData, distPos > 0, "interpolateTransportedQuantity: wrong order or same position!");

  extrapolatedValue = leftValue + (rightValue-leftValue)/(distPos) * (extrapolationPos - leftPosition);
  return extrapolatedValue;
}


/**
 * @brief Adding new pair (position, value) to front or back of spatial distribution.
 *
 * For positive velocity add at frond, else at back.
 * If this node is an event node add an event to stored events list as well.
 *
 * @param transportedQuantityList     Double ended list representing spatial distribution.
 * @param front                       Boolean value if node should be added at the front (true) or the end (false).
 * @param position                    Position of new node.
 * @param value                       Value of new node.
 * @param isEvent                     Boolean value if new node is an event node.
 */
void addNewNodeSpatialDistribution(threadData_t *threadData, SPATIAL_DISTRIBUTION_DATA* spatialDistribution, int front, double position, double value, int isEvent) {
  /* Variables */
  DOUBLE_ENDED_LIST* transportedQuantityList = spatialDistribution->transportedQuantity;
  DOUBLE_ENDED_LIST* storedEventsList = spatialDistribution->storedEvents;
  TRANSPORTED_QUANTITY_DATA newNodeData;
  TRANSPORTED_EVENT_DATA newEventNodeData;

  /* New node */
  newNodeData.position = position;
  newNodeData.value = value;
  newEventNodeData.position = position;

  /* Add node to transported quantity list */
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "Adding (%e,%e) at %s.", newNodeData.position, newNodeData.value, front?"front":"back");
  /* PATCH 2c: these two assertions are the ones that used to fire on flow
   * reversal. With threadData == NULL a failing assertion had no jump buffer to
   * unwind to and took the process down instead of aborting the simulation. */
  if (front) {
    // Make sure new first node is smaller then previous first node
    TRANSPORTED_QUANTITY_DATA* oldFront = (TRANSPORTED_QUANTITY_DATA*) firstDataDoubleEndedList(transportedQuantityList);
    assertStreamPrint(threadData, position<=oldFront->position, "New front position is not smaller then previous first node.");
    pushFrontDoubleEndedList(transportedQuantityList, (const void*) &newNodeData);
  } else {
    // Make sure new first node is smaller then previous first node
    TRANSPORTED_QUANTITY_DATA* oldEnd = (TRANSPORTED_QUANTITY_DATA*) lastDataDoubleEndedList(transportedQuantityList);
    assertStreamPrint(threadData, position>=oldEnd->position, "New end position is not bigger then previous last node.");
    pushBackDoubleEndedList(transportedQuantityList, (const void*) &newNodeData);
  }

  /* Add event to stored event list */
  if (isEvent == 1) {
    if (front) {
      if (doubleEndedListLen(storedEventsList) == 0) {
        if (spatialDistribution->lastStoredEventValue==0) {
          newEventNodeData.zeroCrossValue = 1;
        } else {
          newEventNodeData.zeroCrossValue = -spatialDistribution->lastStoredEventValue;
        }
      } else {
        // Make sure new first node is smaller then previous first node
        TRANSPORTED_EVENT_DATA* oldEventFront = (TRANSPORTED_EVENT_DATA*) firstDataDoubleEndedList(storedEventsList);
        assertStreamPrint(threadData, position<=oldEventFront->position, "New front position is not smaller then previous first event node.");
        newEventNodeData.zeroCrossValue = oldEventFront->zeroCrossValue*(-1);
      }
      pushFrontDoubleEndedList(storedEventsList, (const void*) &newEventNodeData);
    } else {
      if (doubleEndedListLen(storedEventsList) == 0) {
        newEventNodeData.zeroCrossValue = 1;
      } else {
        // Make sure new first node is smaller then previous first node
        TRANSPORTED_EVENT_DATA* oldEventEnd = (TRANSPORTED_EVENT_DATA*) lastDataDoubleEndedList(storedEventsList);
        assertStreamPrint(threadData, position>=oldEventEnd->position, "New end position is not bigger then previous last event node.");
        newEventNodeData.zeroCrossValue = oldEventEnd->zeroCrossValue*(-1);
      }
      pushBackDoubleEndedList(storedEventsList, (const void*) &newEventNodeData);
    }
    infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "Adding event (%e,%e) at %s.", newEventNodeData.position, newEventNodeData.zeroCrossValue, front?"front":"back");
  }

  /* Debug prints */
  doubleEndedListPrint(transportedQuantityList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "List of events");
  doubleEndedListPrint(storedEventsList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);
}


/**
 * @brief Gets value from opposite end of list.
 *
 * @param transportedQuantityList     Double ended list containing spatial distribution.
 * @param isPositiveVelocity          Boolean describing if velocity v is positive (>=0).
 *                                    Velocity v is `v:=der(x)`.
 * @param eventPreValue               On output containing value of first/last node before event.
 *                                    This value is only written when function returned 1 or greater.
 *                                    PATCH: (Patch 1a) The "Step 0" shortcuts below also honour this contract
 *                                    now; they used to return a non-zero count without writing it.
 * @return int                        Return number of events that were encountered.
 */
int findOppositeEndSpatialDistribution(threadData_t *threadData, SPATIAL_DISTRIBUTION_DATA* spatialDistribution, double in0, double in1, double posX, int isPositiveVelocity, double* eventPreValue, double* outValue) {
  /* Variables */
  DOUBLE_ENDED_LIST* transportedQuantityList = spatialDistribution->transportedQuantity;
  DOUBLE_ENDED_LIST* storedEventsList = spatialDistribution->storedEvents;
  DOUBLE_ENDED_LIST_NODE* currentNode;
  DOUBLE_ENDED_LIST_NODE* firstNode;
  DOUBLE_ENDED_LIST_NODE* lastNode;
  DOUBLE_ENDED_LIST_NODE* prevVisitedNode;
  TRANSPORTED_QUANTITY_DATA* currentNodeData;
  TRANSPORTED_QUANTITY_DATA* prevVisitedNodeData;
  TRANSPORTED_QUANTITY_DATA* firstNodeData;
  TRANSPORTED_QUANTITY_DATA* lastNodeData;
  TRANSPORTED_QUANTITY_DATA tempData;
  double edgeNodePosition;
  double currentDistance;
  int walkedOverEvents = 0;

  /* Step 0
   * Check if we are still in spatialDistribution intervall or if deltaX > 1
   */
  firstNode = getFirstNodeDoubleEndedList(transportedQuantityList);
  firstNodeData = firstDataDoubleEndedList(transportedQuantityList);
  lastNode = getLastNodeDoubleEndedList(transportedQuantityList);
  lastNodeData = lastDataDoubleEndedList(transportedQuantityList);
  if (isPositiveVelocity) {
    if (-posX+1 < firstNodeData->position) {
      // We need to interpolate (-posX,in0) <-> (-posX+1,out1) <-> (firstNodeData->position, firstNodeData->value)
      //                                                  ^
      //                                                  |
      tempData.position = -posX;
      tempData.value = in0;
      *outValue = interpolateTransportedQuantity(threadData, &tempData, firstNodeData, -posX + 1);
      /* PATCH 1a: Every stored event lies at a position >= firstNodeData->position,
       * i.e. beyond the outlet read position -posX+1, so all of them have already
       * left the transport domain during this step. The interpolated value is
       * therefore also the correct pre-event value. Writing it keeps the
       * documented contract "eventPreValue is valid whenever the return value is
       * >= 1" and stops the caller from substituting an uninitialized value. */
      *eventPreValue = *outValue;
      return doubleEndedListLen(storedEventsList);
    }
  } else {
    if (-posX > lastNodeData->position) {
      // We need to interpolate (lastNodeData->position,lastNodeData->value) <-> (-posX, out0) <-> (-posX+1,in1)
      //                                                                                  ^
      //                                                                                  |
      tempData.position = -posX+1;
      tempData.value = in1;
      *outValue = interpolateTransportedQuantity(threadData, lastNodeData, &tempData, -posX);
      /* PATCH 1a: see comment in the positive velocity branch above. */
      *eventPreValue = *outValue;
      return doubleEndedListLen(storedEventsList);
    }
  }

  /* Step 1
   * Walk over list, starting from opposite side of edgeNode,
   * until distance between currentNode and edgeNode < 1.
   */
  if (isPositiveVelocity) {
    edgeNodePosition = firstNodeData->position;
    currentNode = lastNode;
  } else {
    edgeNodePosition = lastNodeData->position;
    currentNode = firstNode;
  }
  currentNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(currentNode);

  /* PATCH 3: a meaningful "not distinguishable from 1" tolerance has to be scaled
   * by the magnitude of the *operands*, not by the magnitude of the difference
   * (which is about 1). With the absolute SPATIAL_EPS this test degenerates into
   * an exact comparison as soon as |position| > 1. The distance itself is exact -
   * subtracting two nearby doubles introduces no error - so this scaling makes
   * the comparison meaningful rather than fixing an observed misfire.
   * PATCH 2c: threadData instead of NULL. */
  currentDistance = fabs(currentNodeData->position - edgeNodePosition);
  if (currentDistance + spatialPosEps(currentNodeData->position, edgeNodePosition) < 1) {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "Error for spatialDistribution in function findOppositeEndSpatialDistribution.\nThis case should not be possible. Please open a bug report about it.");
    omc_throw_function(threadData);
    return walkedOverEvents;
  }

  /* Move to neighbor */
  prevVisitedNode = currentNode;
  prevVisitedNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(prevVisitedNode);

  while (currentNode != NULL) {
    if (isPositiveVelocity) {
      currentNode = getPreviousNodeDoubleEndedList(currentNode);
    } else {
      currentNode = getNextNodeDoubleEndedList(currentNode);
    }
    if(currentNode == NULL) {
      break;
    }
    currentNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(currentNode);

    /* Check for event:
     * Current node position equal to previous visited node position
     */
    /* PATCH 3: scaled tolerance */
    if (fabs(prevVisitedNodeData->position - currentNodeData->position) < spatialPosEps(prevVisitedNodeData->position, currentNodeData->position)) {
      *eventPreValue = prevVisitedNodeData->value;
      walkedOverEvents += 1;
    }

    /* Check if distance between currentNode and edgeNode is < 1
     * PATCH 3: scaled tolerance */
    currentDistance = fabs(currentNodeData->position - edgeNodePosition);
    if (currentDistance + spatialPosEps(currentNodeData->position, edgeNodePosition) < 1) {
      break;
    } else {
      prevVisitedNode = currentNode;
      prevVisitedNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(prevVisitedNode);
    }
  }

  /* Step 2
   * Interpolate at edgeNodePosition +/- 1.
   */
  if (currentNode == NULL) {
    /* Walked over all elements of list */
    if (isPositiveVelocity) {
      *outValue = lastNodeData->value;
    } else {
      *outValue = firstNodeData->value;
    }
  } else {
    if (isPositiveVelocity) {
      *outValue = interpolateTransportedQuantity(threadData, currentNodeData, prevVisitedNodeData, edgeNodePosition + 1);
    } else {
      *outValue = interpolateTransportedQuantity(threadData, prevVisitedNodeData, currentNodeData, edgeNodePosition - 1);
    }
  }

  return walkedOverEvents;
}



/**
 * @brief Remove nodes until distance between first and last element is 1.
 *
 * @param transportedQuantityList     Double ended list containing spatial distribution.
 * @param isPositiveVelocity          Boolean describing if velocity v is positive (>=0).
 *                                    Velocity v is `v:=der(x)`.
 * @param eventPreValue               On output containing value of first/last node before event.
 *                                    This value is only written when function returned 1 or greater.
 * @return int                        Return number of events that were encountered.
 */
int pruneSpatialDistribution(threadData_t *threadData, SPATIAL_DISTRIBUTION_DATA* spatialDistribution, int isPositiveVelocity) {
  /* Variables */
  DOUBLE_ENDED_LIST* transportedQuantityList = spatialDistribution->transportedQuantity;
  DOUBLE_ENDED_LIST* storedEventsList = spatialDistribution->storedEvents;
  DOUBLE_ENDED_LIST_NODE* edgeNode;
  DOUBLE_ENDED_LIST_NODE* currentNode;
  DOUBLE_ENDED_LIST_NODE* prevVisitedNode;
  TRANSPORTED_QUANTITY_DATA* edgeNodeData;
  TRANSPORTED_QUANTITY_DATA* currentNodeData;
  TRANSPORTED_QUANTITY_DATA* prevVisitedNodeData;
  TRANSPORTED_EVENT_DATA* eventData;
  int walkedOverEvents = 0;
  int i;
  double currentDistance;

  /* Step 1
   * Walk over list, starting from opposite side of edgeNode,
   * until distance between currentNode and edgeNode < 1.
   */
  if (isPositiveVelocity) {
    edgeNode = getFirstNodeDoubleEndedList(transportedQuantityList);
    currentNode = getLastNodeDoubleEndedList(transportedQuantityList);
  } else {
    edgeNode = getLastNodeDoubleEndedList(transportedQuantityList);
    currentNode = getFirstNodeDoubleEndedList(transportedQuantityList);
  }
  edgeNodeData  = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(edgeNode);
  currentNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(currentNode);

  /* PATCH 3: scaled tolerance, PATCH 2c: threadData instead of NULL */
  currentDistance = fabs(currentNodeData->position - edgeNodeData->position);
  if (currentDistance + spatialPosEps(currentNodeData->position, edgeNodeData->position) < 1) {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "Error for spatialDistribution in function pruneSpatialDistribution.\nThis case should not be possible. Please open a bug reoprt about it.");
    omc_throw_function(threadData);
  }

  /* Move to neighbor */
  prevVisitedNode = currentNode;
  prevVisitedNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(prevVisitedNode);

  while (currentNode != edgeNode) {
    if (isPositiveVelocity) {
      currentNode = getPreviousNodeDoubleEndedList(currentNode);
    } else {
      currentNode = getNextNodeDoubleEndedList(currentNode);
    }
    currentNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(currentNode);

    /* Check for event:
     * Current node position equal to previous visited node position
     */
    /* PATCH 3: scaled tolerance */
    if (fabs(prevVisitedNodeData->position - currentNodeData->position) < spatialPosEps(prevVisitedNodeData->position, currentNodeData->position)) {
      walkedOverEvents += 1;
    }

    /* Check if distance between currentNode and edgeNode is < 1
     * PATCH 3: scaled tolerance */
    currentDistance = fabs(currentNodeData->position - edgeNodeData->position);
    if (currentDistance + spatialPosEps(currentNodeData->position, edgeNodeData->position) < 1) {
      break;
    } else {
      prevVisitedNode = currentNode;
      prevVisitedNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(prevVisitedNode);
    }
  }

  /* Step 2
   * Interpolate at edgeNode->position +/- 1.
   */
  /* PATCH 3: scaled tolerance */
  if (currentDistance + spatialPosEps(currentNodeData->position, edgeNodeData->position) < 1) {
    if (isPositiveVelocity) {
      prevVisitedNodeData->value = interpolateTransportedQuantity(threadData, currentNodeData, prevVisitedNodeData, edgeNodeData->position + 1);
      prevVisitedNodeData->position = edgeNodeData->position + 1;
    } else {
      prevVisitedNodeData->value = interpolateTransportedQuantity(threadData, prevVisitedNodeData, currentNodeData, edgeNodeData->position - 1);
      prevVisitedNodeData->position = edgeNodeData->position - 1;
    }
    infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "Interpolate at %s", isPositiveVelocity?"end":"front");
  }

  /* Step 3
   * Remove all nodes that have a distance to edge > 1.
   */
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "Removing nodes %s node %p", isPositiveVelocity?"after":"before", (void*)prevVisitedNode);
  if (isPositiveVelocity) {
    clearAfterNodeDoubleEndedList(transportedQuantityList, prevVisitedNode);
  } else {
    clearBeforeNodeDoubleEndedList(transportedQuantityList, prevVisitedNode);
  }

  /* Step 4
   * Remove all events that are outside spatial distribution [leftEdge-SPATIAL_ZERO_DELTA_X, rightEdge+SPATIAL_ZERO_DELTA_X]
   */
  if (doubleEndedListLen(storedEventsList) > 0) {
    if (isPositiveVelocity) {
      eventData = lastDataDoubleEndedList(storedEventsList);
      /* PATCH 3: scaled tolerance */
      while (edgeNodeData->position+1 + spatialZeroDeltaX(edgeNodeData->position, eventData->position) < eventData->position) {
        spatialDistribution->lastStoredEventValue = eventData->zeroCrossValue;
        removeLastDoubleEndedList(storedEventsList);
        if (doubleEndedListLen(storedEventsList) == 0) {
          break;
        } else {
          eventData = lastDataDoubleEndedList(storedEventsList);
        }
      }
    } else {
      eventData = firstDataDoubleEndedList(storedEventsList);
      /* PATCH 3: scaled tolerance */
      while (edgeNodeData->position-1 - spatialZeroDeltaX(edgeNodeData->position, eventData->position) > eventData->position) {
        spatialDistribution->lastStoredEventValue = eventData->zeroCrossValue;
        removeFirstDoubleEndedList(storedEventsList);
        if (doubleEndedListLen(storedEventsList) == 0) {
          break;
        } else {
          eventData = firstDataDoubleEndedList(storedEventsList);
        }
      }
    }
  }

  /* Debug prints */
  doubleEndedListPrint(transportedQuantityList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);
  infoStreamPrint(OMC_LOG_SPATIALDISTR, 0, "List of events");
  doubleEndedListPrint(storedEventsList, OMC_LOG_SPATIALDISTR, &printTransportedQuantity);

  return walkedOverEvents;
}


/**
 * @brief Print transported quantity data to stream.
 *
 * Prints tuple (position, value).
 *
 * @param data          Void pointer to transportedQuantityData.
 *                      Will be casted to TRANSPORTED_QUANTITY_DATA*.
 * @param stream        Stream of OMC_LOG_STREAM type.
 * @param nodePointer   Address of node storing this data.
 */
void printTransportedQuantity(void* data, int stream, void* nodePointer) {
  TRANSPORTED_QUANTITY_DATA* transportedQuantityData = (TRANSPORTED_QUANTITY_DATA*) data;
  infoStreamPrint(stream, 0, "%p: (%e,%e)", nodePointer, transportedQuantityData->position, transportedQuantityData->value);
}


//#endif
