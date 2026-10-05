//! The ellipse tube geometry shared by [`crate::ellipse`] and
//! [`crate::ellipse2014`]: `Ellipse.cs`'s `GenerateHighTube`/`GenerateLowTube`,
//! which is what the two versions have in common. `min_index` is the one
//! difference: csv-compare consolidates down to the first interval (1, so the
//! loop can decrement `index` to 0 and take the first-interval branch), while
//! the C in `SimulationResultsCmpTubes.c` stops at 2 to avoid an underflow, so
//! that branch is dead there.

pub(crate) struct Tubes {
    pub(crate) mh: Vec<f64>,
    pub(crate) ml: Vec<f64>,
    pub(crate) x_high: Vec<f64>,
    pub(crate) x_low: Vec<f64>,
    pub(crate) y_high: Vec<f64>,
    pub(crate) y_low: Vec<f64>,
    pub(crate) i0h: Vec<i64>,
    pub(crate) i1h: Vec<i64>,
    pub(crate) i0l: Vec<i64>,
    pub(crate) i1l: Vec<i64>,
    pub(crate) t_start: f64,
    pub(crate) t_stop: f64,
    pub(crate) x1: f64,
    pub(crate) y1: f64,
    pub(crate) x2: f64,
    pub(crate) y2: f64,
    pub(crate) current_slope: f64,
    pub(crate) slope_dif: f64,
    pub(crate) delta: f64,
    pub(crate) s: f64,
    pub(crate) x_rel_eps: f64,
    pub(crate) x_min_step: f64,
    pub(crate) min: f64,
    pub(crate) max: f64,
    pub(crate) count_low: usize,
    pub(crate) count_high: usize,
    /// Lowest `index` the consolidation loop still runs at: 1 or 2.
    pub(crate) min_index: isize,
}

impl Tubes {
    /// C `generateHighTube`.
    pub(crate) fn generate_high_tube(&mut self, x: &[f64], y: &[f64]) {
        let mut index = self.count_high as isize - 1;
        let m1 = self.mh[index as usize];
        let mut m2 = self.mh[(index - 1) as usize];
        self.slope_dif = (m1 - m2).abs();

        if self.slope_dif == 0.0
            || (self.slope_dif < 2e-15 * m1.abs().max(m2.abs())
                && self.i0h[self.count_high - 1] - self.i1h[self.count_high - 2] < 100)
        {
            self.i0h[(index - 1) as usize] = self.i0h[index as usize];
            self.count_high -= 1;
            let x3 = x[self.i0h[(index - 1) as usize] as usize];
            let y3 = y[self.i0h[(index - 1) as usize] as usize];
            let x4 = x[self.i1h[(index - 1) as usize] as usize];
            let y4 = y[self.i1h[(index - 1) as usize] as usize];
            self.mh[(index - 1) as usize] = (y3 - y4) / (x3 - x4);
        } else {
            self.x_high[index as usize] = self.x2
                - (self.delta * (m1 + m2)
                    / ((m2 * m2 + self.s * self.s).sqrt() + (m1 * m1 + self.s * self.s).sqrt()));
            if m1 * m2 < 0.0 {
                self.y_high[index as usize] = self.y2
                    + (self.delta
                        * (m1 * (m2 * m2 + self.s * self.s).sqrt()
                            - m2 * (m1 * m1 + self.s * self.s).sqrt()))
                        / (m1 - m2);
            } else {
                self.y_high[index as usize] = self.y2
                    + (self.s * self.s * self.delta * (m1 + m2)
                        / (m1 * (m2 * m2 + self.s * self.s).sqrt()
                            + m2 * (m1 * m1 + self.s * self.s).sqrt()));
            }

            if self.x_high[index as usize] == self.x_high[(index - 1) as usize]
                && self.y_high[index as usize] != self.y_high[(index - 1) as usize]
            {
                self.x_high[index as usize] = self.x_high[(index - 1) as usize] + self.x_min_step;
                self.y_high[index as usize] = self.y2
                    + m1 * (self.x_high[index as usize] - self.x2)
                    + self.delta * (m1 * m1 + self.s * self.s).sqrt();
                self.mh[(index - 1) as usize] =
                    (self.y_high[index as usize] - self.y_high[(index - 1) as usize]) / self.x_min_step;
            }

            while index >= self.min_index && self.x_high[index as usize] <= self.x_high[(index - 1) as usize] {
                self.i0h[(index - 1) as usize] = self.i0h[index as usize];
                self.i1h[(index - 1) as usize] = self.i1h[index as usize];
                self.mh[(index - 1) as usize] = self.mh[index as usize];
                index -= 1;
                self.count_high -= 1;

                if index == 0 {
                    let x3 = x[0];
                    self.x_high[index as usize] = x3 - self.delta;
                    self.y_high[index as usize] = self.y2
                        + m1 * (self.x_high[index as usize] - self.x2)
                        + self.delta * (m1 * m1 + self.s * self.s).sqrt();
                } else {
                    let x3 = self.x_high[(index - 1) as usize];
                    let y3 = self.y_high[(index - 1) as usize];
                    m2 = self.mh[(index - 1) as usize];
                    self.x_high[index as usize] = (m2 * x3 - m1 * self.x2 + self.y2 - y3
                        + self.delta * (m1 * m1 + self.s * self.s).sqrt())
                        / (m2 - m1);
                    self.y_high[index as usize] = (m2 * m1 * (x3 - self.x2)
                        + m2 * (self.y2 + self.delta * (m1 * m1 + self.s * self.s).sqrt())
                        - m1 * y3)
                        / (m2 - m1);
                }
            }
        }
    }

    /// C `generateLowTube`.
    pub(crate) fn generate_low_tube(&mut self, x: &[f64], y: &[f64]) {
        let mut index = self.count_low as isize - 1;
        let m1 = self.ml[index as usize];
        let mut m2 = self.ml[(index - 1) as usize];
        self.slope_dif = (m1 - m2).abs();

        if self.slope_dif == 0.0
            || (self.slope_dif < 2e-15 * m1.abs().max(m2.abs())
                && self.i0l[self.count_low - 1] - self.i1l[self.count_low - 2] < 100)
        {
            self.i0l[(index - 1) as usize] = self.i0l[index as usize];
            self.count_low -= 1;
            let x3 = x[self.i0l[(index - 1) as usize] as usize];
            let y3 = y[self.i0l[(index - 1) as usize] as usize];
            let x4 = x[self.i1l[(index - 1) as usize] as usize];
            let y4 = y[self.i1l[(index - 1) as usize] as usize];
            self.ml[(index - 1) as usize] = (y3 - y4) / (x3 - x4);
        } else {
            self.x_low[index as usize] = self.x2
                + (self.delta * (m1 + m2)
                    / ((m2 * m2 + self.s * self.s).sqrt() + (m1 * m1 + self.s * self.s).sqrt()));
            if m1 * m2 < 0.0 {
                self.y_low[index as usize] = self.y2
                    - (self.delta
                        * (m1 * (m2 * m2 + self.s * self.s).sqrt()
                            - m2 * (m1 * m1 + self.s * self.s).sqrt()))
                        / (m1 - m2);
            } else {
                self.y_low[index as usize] = self.y2
                    - (self.s * self.s * self.delta * (m1 + m2)
                        / (m1 * (m2 * m2 + self.s * self.s).sqrt()
                            + m2 * (m1 * m1 + self.s * self.s).sqrt()));
            }

            if self.x_low[index as usize] == self.x_low[(index - 1) as usize]
                && self.y_low[index as usize] != self.y_low[(index - 1) as usize]
            {
                self.x_low[index as usize] = self.x_low[(index - 1) as usize] + self.x_min_step;
                self.y_low[index as usize] = self.y2
                    + m1 * (self.x_low[index as usize] - self.x2)
                    - self.delta * (m1 * m1 + self.s * self.s).sqrt();
                self.ml[(index - 1) as usize] =
                    (self.y_low[index as usize] - self.y_low[(index - 1) as usize]) / self.x_min_step;
            }

            while index >= self.min_index && self.x_low[index as usize] <= self.x_low[(index - 1) as usize] {
                self.i0l[(index - 1) as usize] = self.i0l[index as usize];
                self.i1l[(index - 1) as usize] = self.i1l[index as usize];
                self.ml[(index - 1) as usize] = self.ml[index as usize];
                index -= 1;
                self.count_low -= 1;

                if index == 0 {
                    let x3 = x[0];
                    self.x_low[index as usize] = x3 - self.delta;
                    self.y_low[index as usize] = self.y2
                        + m1 * (self.x_low[index as usize] - self.x2)
                        - self.delta * (m1 * m1 + self.s * self.s).sqrt();
                } else {
                    let x3 = self.x_low[(index - 1) as usize];
                    let y3 = self.y_low[(index - 1) as usize];
                    m2 = self.ml[(index - 1) as usize];
                    self.x_low[index as usize] = (m2 * x3 - m1 * self.x2 + self.y2 - y3
                        - self.delta * (m1 * m1 + self.s * self.s).sqrt())
                        / (m2 - m1);
                    self.y_low[index as usize] = (m2 * m1 * (x3 - self.x2)
                        + m2 * (self.y2 - self.delta * (m1 * m1 + self.s * self.s).sqrt())
                        - m1 * y3)
                        / (m2 - m1);
                }
            }
        }
    }
}
