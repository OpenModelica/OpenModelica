#include <gtest/gtest.h>
#include "arrayIndex.h"

// Test fixture
class ArrayVector : public ::testing::Test
{
protected:
    const size_t dim1 = 12;

    DIMENSION_ATTRIBUTE dimension = {
        .type = DIMENSION_BY_START,
        .start = static_cast<modelica_integer>(dim1),
        .valueReference = static_cast<modelica_integer>(-1)};
    DIMENSION_INFO dimension_info = {
        .numberOfDimensions = 1,
        .dimensions = &dimension};
};

// Test calculation of array length of vector variable
TEST_F(ArrayVector, VectorHasCorrectLength)
{
    // Arrange
    const size_t expected_length = dim1;

    // Act
    size_t actual_length = calculateLength(&dimension_info, nullptr, 0);

    // Assert
    EXPECT_EQ(actual_length, expected_length)
        << "Vector variable length mismatch: expected " << expected_length
        << ", got " << actual_length;
}
