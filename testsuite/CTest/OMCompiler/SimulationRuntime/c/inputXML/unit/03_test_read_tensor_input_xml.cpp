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
 * Tests an init XML file defining an integer tensor variable with three dimensions.
 * The first dimension uses "valueReference", the other two use "start".
 */
class InitXMLTensorTest : public ::testing::Test
{
protected:
    MODEL_DATA modelData{};
    SIMULATION_INFO simulationInfo{};
    DATA data{};
    std::unique_ptr<STATIC_INTEGER_DATA[]> integerParameterData;

    void SetUp() override
    {
        // Configure OpenModelica simulation hooks
        omc_assert = omc_assert_simulation;
        omc_assert_withEquationIndexes = omc_assert_simulation_withEquationIndexes;
        omc_assert_warning_withEquationIndexes = omc_assert_warning_simulation_withEquationIndexes;
        omc_assert_warning = omc_assert_warning_simulation;
        omc_terminate = omc_terminate_simulation;
        omc_throw = omc_throw_simulation;

        // Allocate integer parameter data
        modelData.nStates = 0;
        modelData.nParametersInteger = 2;
        integerParameterData = std::make_unique<STATIC_INTEGER_DATA[]>(modelData.nParametersInteger);
        modelData.integerParameterData = integerParameterData.get();
        modelData.initXMLData = nullptr;
        modelData.modelGUID = const_cast<char *>("test-guid");

        // Simulation setup
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

TEST_F(InitXMLTensorTest, ParseIntTensorVariableXML)
{
    // Path provided by CMake definition (see CMakeLists.txt below)
    const std::string xmlPath =
        std::string(TEST_RESOURCES_DIR) + "/03_IntTensorVariable_init.xml";

    // Ensure file exists
    FILE *f = fopen(xmlPath.c_str(), "r");
    ASSERT_NE(f, nullptr) << "XML file not found: " << xmlPath;
    fclose(f);

    // Set XML flag
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

    // --- Validation ---
    const auto &param = modelData.integerParameterData[0];

    EXPECT_STREQ(param.info.name, "T")
        << "Expected integer parameter name 'T'.";

    EXPECT_EQ(param.dimension.numberOfDimensions, 3u)
        << "Expected three dimensions.";

    // Dimension 1
    const auto &dim1 = param.dimension.dimensions[0];
    EXPECT_EQ(dim1.type, DIMENSION_BY_VALUE_REFERENCE)
        << "Expected first dimension to use 'valueReference'.";
    EXPECT_EQ(dim1.start, 2u)
        << "Expected start=2 for first dimension.";
    EXPECT_EQ(dim1.valueReference, 1001u)
        << "Expected valueReference=1001 for first dimension.";

    // Dimension 2
    const auto &dim2 = param.dimension.dimensions[1];
    EXPECT_EQ(dim2.type, DIMENSION_BY_START)
        << "Expected second dimension to use 'start'.";
    EXPECT_EQ(dim2.start, 3u)
        << "Expected start=3 for second dimension.";
    EXPECT_EQ(dim2.valueReference, -1)
        << "Expected no valueReference for second dimension.";

    // Dimension 3
    const auto &dim3 = param.dimension.dimensions[2];
    EXPECT_EQ(dim3.type, DIMENSION_BY_START)
        << "Expected third dimension to use 'start'.";
    EXPECT_EQ(dim3.start, 4u)
        << "Expected start=4 for third dimension.";
    EXPECT_EQ(dim3.valueReference, -1)
        << "Expected no valueReference for third dimension.";

    // Scalar length check
    EXPECT_EQ(param.dimension.scalar_length, 24u)
        << "Expected scalar_length=24 (2×3×4 tensor).";
}
