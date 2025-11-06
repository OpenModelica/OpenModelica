#include <gtest/gtest.h>
#include <cstring>
#include <memory>
#include <iostream>
#include <string>

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
 * Tests an init XML file defining a matrix variable with two dimension tags.
 * Each dimension uses only the "start" attribute.
 */
class InitXMLMatrixTest : public ::testing::Test
{
protected:
    MODEL_DATA modelData{};
    SIMULATION_INFO simulationInfo{};
    DATA data{};
    std::unique_ptr<STATIC_REAL_DATA[]> realVarsData;

    void SetUp() override
    {
        // Setup OpenModelica assert and runtime hooks
        omc_assert = omc_assert_simulation;
        omc_assert_withEquationIndexes = omc_assert_simulation_withEquationIndexes;
        omc_assert_warning_withEquationIndexes = omc_assert_warning_simulation_withEquationIndexes;
        omc_assert_warning = omc_assert_warning_simulation;
        omc_terminate = omc_terminate_simulation;
        omc_throw = omc_throw_simulation;

        // Allocate model data
        modelData.nStates = 0;
        modelData.nVariablesReal = 1;
        realVarsData = std::make_unique<STATIC_REAL_DATA[]>(modelData.nVariablesReal);
        modelData.realVarsData = realVarsData.get();
        modelData.initXMLData = nullptr;
        modelData.modelGUID = const_cast<char *>("test-guid");

        // Setup simulation info
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

TEST_F(InitXMLMatrixTest, ParseRealMatrixVariableXML)
{
    // Use absolute path from CMake definition (see below)
    const std::string xmlPath =
        std::string(TEST_RESOURCES_DIR) + "/02_RealMatrixVariable_init.xml";

    // Verify file exists before running
    FILE *f = fopen(xmlPath.c_str(), "r");
    ASSERT_NE(f, nullptr) << "XML file not found: " << xmlPath;
    fclose(f);

    // Set XML file flag
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

    ASSERT_TRUE(testSuccess) << "XML parsing failed or threw an exception.";

    // --- Validation checks ---
    EXPECT_STREQ(modelData.realVarsData[0].info.name, "A")
        << "Expected real variable name 'A'.";

    EXPECT_EQ(modelData.realVarsData[0].dimension.numberOfDimensions, 2u)
        << "Expected two dimensions.";

    // Dimension 1
    const auto &dim1 = modelData.realVarsData[0].dimension.dimensions[0];
    EXPECT_EQ(dim1.type, DIMENSION_BY_START)
        << "Expected first dimension to use 'start'.";
    EXPECT_EQ(dim1.start, 3u)
        << "Expected start=3 in first dimension.";
    EXPECT_EQ(dim1.valueReference, -1)
        << "Expected no valueReference in first dimension.";

    // Dimension 2
    const auto &dim2 = modelData.realVarsData[0].dimension.dimensions[1];
    EXPECT_EQ(dim2.type, DIMENSION_BY_START)
        << "Expected second dimension to use 'start'.";
    EXPECT_EQ(dim2.start, 2u)
        << "Expected start=2 in second dimension.";
    EXPECT_EQ(dim2.valueReference, -1)
        << "Expected no valueReference in second dimension.";

    // Scalar length
    EXPECT_EQ(modelData.realVarsData[0].dimension.scalar_length, 6u)
        << "Expected scalar_length=6 (matrix size 3x2).";
}
