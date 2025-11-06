#include <gtest/gtest.h>
#include <cstring>
#include <memory>
#include <iostream>

extern "C"
{
#include "omc_error.h"
#include "omc_init.h"
#include "options.h"
#include "simulation_omc_assert.h"
#include "simulation_input_xml.h"
#include "model_help.h"
}

/**
 * @brief Fixture for testing parsing of init XML
 *
 * This fixture sets up dummy MODEL_DATA and SIMULATION_INFO structures.
 */
class InitXMLTest : public ::testing::Test
{
protected:
    MODEL_DATA modelData{};
    SIMULATION_INFO simulationInfo{};
    DATA data{};
    std::unique_ptr<STATIC_REAL_DATA[]> realVarsData;
    std::unique_ptr<STATIC_INTEGER_DATA[]> integerParameterData;

    void SetUp() override
    {
        // Setup OpenModelica function pointers for simulation asserts
        omc_assert = omc_assert_simulation;
        omc_assert_withEquationIndexes = omc_assert_simulation_withEquationIndexes;
        omc_assert_warning_withEquationIndexes = omc_assert_warning_simulation_withEquationIndexes;
        omc_assert_warning = omc_assert_warning_simulation;
        omc_terminate = omc_terminate_simulation;
        omc_throw = omc_throw_simulation;

        // Allocate memory
        modelData.nStates = 0;
        modelData.nVariablesReal = 1;
        realVarsData = std::make_unique<STATIC_REAL_DATA[]>(modelData.nVariablesReal);
        modelData.realVarsData = realVarsData.get();

        modelData.nParametersInteger = 1;
        integerParameterData = std::make_unique<STATIC_INTEGER_DATA[]>(modelData.nParametersInteger);
        modelData.integerParameterData = integerParameterData.get();

        modelData.initXMLData = nullptr;
        modelData.modelGUID = const_cast<char *>("test-guid");

        data.modelData = &modelData;
        data.simulationInfo = &simulationInfo;
        simulationInfo.OPENMODELICAHOME =
            const_cast<char *>("/home/user/workdir/OpenModelica/build_cmake/install_cmake/");

        initDumpSystem();

        MMC_INIT(0);
    }

    void TearDown() override
    {
        freeModelDataVars(&modelData);
    }
};

// Actual test case
TEST_F(InitXMLTest, ParseRealArrayVariableXML)
{
    const std::string xmlPath = std::string(TEST_RESOURCES_DIR) + "/01_RealArrayVariable_init.xml";

    // Simulate command-line flag for the XML file
    omc_flag[FLAG_F] = 1;
    omc_flagValue[FLAG_F] = const_cast<char *>(xmlPath.c_str());

    bool testSuccess = true;

    MMC_TRY_TOP()
    MMC_TRY_STACK()

    threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = &data;

    // Function under test
    read_input_xml(&modelData, &simulationInfo, threadData);

    MMC_ELSE()
    std::cerr << "Stack overflow!" << std::endl;
    testSuccess = false;
    MMC_CATCH_STACK()
    MMC_CATCH_TOP(std::cerr << "Test throw!" << std::endl; testSuccess = false);

    ASSERT_TRUE(testSuccess) << "XML parsing threw an exception or failed.";

    // Validate parsed model data
    EXPECT_STREQ(modelData.realVarsData[0].info.name, "x")
        << "Real variable name mismatch";

    EXPECT_EQ(modelData.realVarsData[0].dimension.numberOfDimensions, 1u)
        << "Expected one dimension";

    EXPECT_EQ(modelData.realVarsData[0].dimension.dimensions[0].type, DIMENSION_BY_START)
        << "Expected <dimension> to contain 'start'";

    EXPECT_EQ(modelData.realVarsData[0].dimension.dimensions[0].start, 4u)
        << "Expected start=4";

    EXPECT_EQ(modelData.realVarsData[0].dimension.dimensions[0].valueReference, -1)
        << "Expected no valueReference in <dimension>";

    EXPECT_EQ(modelData.realVarsData[0].dimension.scalar_length, 4u)
        << "Expected array length 4";

    EXPECT_STREQ(modelData.integerParameterData[0].info.name, "p")
        << "Integer parameter name mismatch";
}
