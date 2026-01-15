model ArrayAttributes
  // === Real array examples =====================
  // Using `each` to apply attributes element-wise
  parameter Real r_each[2](each quantity = "Length",
                           each unit = "m",
                           each displayUnit = "cm",
                           each min = 0.0,
                           each max = 10.0,
                           each start = 1.0,
                           each fixed = true,
                           each nominal = 5.0,
                           each unbounded = false,
                           each stateSelect = StateSelect.default);
  // Using `fill` to assign attribute values as arrays
  parameter Real r_fill[2](quantity = fill("Mass",2),
                           unit = fill("kg", 2),
                           displayUnit = fill("g", 2),
                           min = fill(-1.0, 2),
                           max = fill(5.0, 2),
                           start = fill(2.0, 2),
                           fixed = fill(false, 2),
                           nominal = fill(3.0, 2),
                           unbounded = fill(false, 2),
                           stateSelect = fill(StateSelect.default, 2));
  // Using explicit array values
  parameter Real r_array[2](quantity = {"Time", "Time"},
                            unit = {"s", "s"},
                            displayUnit = {"ms", "ms"},
                            min = {-2.0, -1.0},
                            max = {10.0, 20.0},
                            start = {0.5, 1.5},
                            fixed = {true, false},
                            nominal = {1.0, 2.0},
                            unbounded = {true, false},
                            stateSelect = {StateSelect.always, StateSelect.always});

  // === Integer array examples ==================
  parameter Integer i_each[2](each quantity = "MyIntegerQuantity1",
                              each min = -10,
                              each max = 10,
                              each start = 0,
                              each fixed = true);
  parameter Integer i_fill[2](quantity = fill("MyIntegerQuantity2", 2),
                              min = fill(0, 2),
                              max = fill(100, 2),
                              start = fill(1, 2),
                              fixed = fill(false, 2));
  parameter Integer i_array[2](quantity = {"MyIntegerQuantity3", "MyIntegerQuantity3"},
                               min = {0, 0},
                               max = {20, 30},
                               start = {5, 10},
                               fixed = {true, false});

  // === Boolean array examples ==================
  parameter Boolean b_each[2](each quantity = "MyBooleanQuantity1",
                              each start = false,
                              each fixed = true);
  parameter Boolean b_fill[2](quantity = fill("MyBooleanQuantity2", 2),
                              start = fill(true, 2),
                              fixed = fill(false, 2));
  parameter Boolean b_array[2](quantity = {"MyBooleanQuantity2", "MyBooleanQuantity2"},
                               start = {true, false},
                               fixed = {true, true});

  // === String array examples ===================
  parameter String s_each[2](each quantity = "MyStringQuantity1",
                             each start = "init",
                             each fixed = true);
  parameter String s_fill[2](quantity = fill("MyStringQuantity2", 2),
                             start = fill("fillValue", 2),
                             fixed = fill(true, 2));
  parameter String s_array[2](quantity = {"MyStringQuantity2", "MyStringQuantity2"},
                              start = {"a", "b"},
                              fixed = {true, true});
end ArrayAttributes;
