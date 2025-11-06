#include <gtest/gtest.h>
#include "arrayIndex.h"

// Test fixture
class ArrayScalar : public ::testing::Test
{
protected:
    DIMENSION_INFO dimension_info{0};
};

// Test calculation of array length of scalar variable
TEST_F(ArrayScalar, ScalarHasLengthOne)
{
    // Arrange
    const size_t expected_length = 1;

    // Act
    size_t actual_length = calculateLength(&dimension_info, nullptr, 0);

    // Assert
    EXPECT_EQ(actual_length, expected_length)
        << "A scalar variable should always have length 1.";
}
