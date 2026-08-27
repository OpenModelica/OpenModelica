//! Synchronous (clocked) partitions: the wasm-jit counterpart of the C runtime's
//! `simulation/solver/synchronous.c`.
//!
//! Clocked partitions are driven by a sorted list of activation timers: a
//! base-clock tick advances its own timer by `interval` and schedules the
//! sub-clock ticks falling inside it. The integrator never steps past the
//! earliest timer ([`Sync::next_time`], C's `checkForSynchronous`).
//!
//! One departure from C: `$_clkfire` cannot call back across the wasm boundary
//! into this list, so the model raises a flag in `SimData` and
//! [`Sync::take_fired`] turns it into a timer once the model call returns.

use alloc::format;
use alloc::vec::Vec;

use crate::driver::{
    self, MODEL_FN_EQS_SYNC, MODEL_FN_UPDATE_SYNC, Result, SimEngine, read_f64, read_i32, write_f64,
    write_i32,
};
use crate::omclog;
use crate::{BaseClockMeta, Layout, clock_field};

/// C's `SYNC_EPS` (`epsilon.h`).
pub const SYNC_EPS: f64 = 1e-14;

/// C's `RATIONAL`, kept exact: sub-clock activation is `shift + count*factor`
/// relative to the base clock, and only the ticks landing on an integer count.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Rat {
    num: i64,
    den: i64,
}

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while a != 0 {
        let tmp = a;
        a = b % a;
        b = tmp;
    }
    b.abs()
}

impl Rat {
    fn new(num: i64, den: i64) -> Rat {
        let g = gcd(num, den);
        let (num, den) = if g != 0 { (num / g, den / g) } else { (num, den) };
        if den < 0 { Rat { num: -num, den: -den } } else { Rat { num, den } }
    }
    fn int(n: i64) -> Rat {
        Rat { num: n, den: 1 }
    }
    fn add(self, o: Rat) -> Rat {
        Rat::new(self.num * o.den + o.num * self.den, self.den * o.den)
    }
    fn sub(self, o: Rat) -> Rat {
        Rat::new(self.num * o.den - o.num * self.den, self.den * o.den)
    }
    fn mul(self, o: Rat) -> Rat {
        Rat::new(self.num * o.num, self.den * o.den)
    }
    /// Largest integer `<= self`.
    fn floor(self) -> i64 {
        self.num / self.den - i64::from(self.num < 0 && self.num % self.den != 0)
    }
    fn to_real(self) -> f64 {
        self.num as f64 / self.den as f64
    }
}

/// C's `assertStreamPrint` inside `initSynchronous`: log the violated condition,
/// then the termination notice, and fail the run with the error the host reports
/// without adding a reason of its own.
fn init_assert(msg: &str) -> &'static str {
    omclog::debug(omclog::ASSERT, false, msg);
    driver::log_init_assert_notice();
    driver::ASSERT_ERR
}

/// C's `SYNC_TIMER`. `sub` is `None` for a base-clock timer (C's `sub_idx = -1`).
#[derive(Clone, Copy, Debug)]
struct Timer {
    base: u32,
    sub: Option<u32>,
    time: f64,
}

/// What one [`Sync::handle_timers`] pass did, C's `fire_timer_t`.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Fired {
    None,
    /// A clock ticked, without asking for an event.
    Timer,
    /// A clock with `holdEvents` ticked: the step is an event step.
    Event,
}

/// The clocked half of a run: the clock metadata and the ordered timer list.
/// Empty (and inert) for a model without clocked partitions.
pub struct Sync {
    clocks: Vec<BaseClockMeta>,
    /// Ordered by activation time, earliest first (C's `intvlTimers`).
    timers: Vec<Timer>,
    sim_data: u32,
    layout: Layout,
}

impl Sync {
    /// C's `initSynchronous`: run the model's `functionInitSynchronous`, check the
    /// sub-clocks, then give every non-event base clock its first timer.
    pub fn new(e: &mut dyn SimEngine, model: &crate::SimMeta, sim_data: u32) -> Result<Sync> {
        let mut s = Sync {
            clocks: model.clocks.clone(),
            timers: Vec::new(),
            sim_data,
            layout: model.layout,
        };
        if s.clocks.is_empty() {
            return Ok(s);
        }
        e.call1("functionInitSynchronous", sim_data)?;
        // C emits this from the generated `function_initSynchronous`, ahead of the
        // checks below.
        for _ in s.clocks.iter().filter(|c| c.inferred) {
            omclog::warning(
                omclog::STDOUT,
                false,
                "Inferred clock, using default clock 'Clock(intervalCounter=1, resolution=1)'",
            );
        }
        for c in &s.clocks {
            // C's "Continuous clocked systems aren't supported yet." assert tests
            // `solverMethod != NULL`, and the generated code always sets it (""
            // or "External"), so it never fires — a solver clock runs as an
            // ordinary sub-clock. Not reproduced here for the same reason.
            for sub in &c.sub {
                if Rat::new(sub.shift_num, sub.shift_den).floor() < 0 {
                    return Err(init_assert(
                        "Shift of sub-clock is negative. Sub-clocks aren't allowed to fire before base-clock.",
                    ));
                }
                if c.is_event_clock && Rat::new(sub.factor_num, sub.factor_den).den != 1 {
                    return Err(init_assert(
                        "Factor of sub-clock of event-clock is not an integer, this is not allowed.",
                    ));
                }
            }
        }
        for i in 0..s.clocks.len() as u32 {
            e.call2(MODEL_FN_UPDATE_SYNC, sim_data, i)?;
            if !s.clocks[i as usize].is_event_clock {
                // C's `listPushFront`, so the clocks fire in reverse index order.
                s.timers.insert(0, Timer { base: i, sub: None, time: model.start_time });
            }
        }
        s.print_clocks(e)?;
        Ok(s)
    }

    pub fn is_empty(&self) -> bool {
        self.clocks.is_empty()
    }

    /// C's `checkForSynchronous`: the earliest activation time still scheduled, so
    /// the integrator can cut its step short and land on it. `+inf` when idle.
    pub fn next_time(&self) -> f64 {
        self.timers.first().map_or(f64::INFINITY, |t| t.time)
    }

    /// Insert keeping the list ordered by activation time, after any timer with the
    /// same time (C's `insertTimer`).
    fn insert(&mut self, timer: Timer) {
        let at = self.timers.iter().position(|t| t.time > timer.time).unwrap_or(self.timers.len());
        self.timers.insert(at, timer);
    }

    /// Turn the `$_clkfire` flags a discrete update raised into base-clock
    /// activations at `time`, and clear them.
    pub fn take_fired(&mut self, e: &mut dyn SimEngine, time: f64) -> Result<()> {
        for i in 0..self.clocks.len() as u32 {
            let off = self.sim_data + self.layout.clock_fire_off + i * 4;
            if read_i32(e, off)? == 0 {
                continue;
            }
            write_i32(e, off, 0)?;
            self.insert(Timer { base: i, sub: None, time });
        }
        Ok(())
    }

    /// C's `handleTimers`: fire every timer due at `time`, earliest first. `rows`
    /// receives the pre-tick result row C's `sim_result.emit` writes before each
    /// clocked partition is evaluated.
    ///
    /// `eps` is the caller's time tolerance: the driver made this activation its
    /// integration target, so a timer within `eps` of `time` must fire or the step
    /// makes no progress.
    pub fn handle_timers(
        &mut self,
        e: &mut dyn SimEngine,
        time: f64,
        eps: f64,
        mut rows: Option<&mut Vec<f64>>,
    ) -> Result<Fired> {
        let eps = eps.max(SYNC_EPS);
        let mut ret = Fired::None;
        while self.timers.first().is_some_and(|t| t.time <= time + eps) {
            let timer = self.timers.remove(0);
            let fired = match timer.sub {
                None => {
                    let first_is_base = self.handle_base_clock(e, timer.base, timer.time, rows.as_deref_mut())?;
                    let hold = first_is_base && self.clocks[timer.base as usize].sub[0].hold_events;
                    if hold { Fired::Event } else { Fired::Timer }
                }
                Some(sub) => self.handle_sub_clock(e, timer.base, sub, time, rows.as_deref_mut())?,
            };
            ret = fired;
        }
        Ok(ret)
    }

    /// C's `handleBaseClock`: update the clock's statistics, evaluate its first
    /// sub-partition when that *is* the base clock, reschedule the base clock, and
    /// queue the sub-clock ticks falling inside this interval.
    fn handle_base_clock(
        &mut self,
        e: &mut dyn SimEngine,
        base: u32,
        time: f64,
        mut rows: Option<&mut Vec<f64>>,
    ) -> Result<bool> {
        let clock = self.clocks[base as usize].clone();
        let off = self.sim_data + self.layout.base_clock_off(base);
        let count = read_i32(e, off + clock_field::COUNT)? + 1;
        write_i32(e, off + clock_field::COUNT, count)?;
        // An event clock has no interval to derive the previous one from.
        if clock.is_event_clock {
            if count > 1 {
                let last = read_f64(e, off + clock_field::LAST_ACTIVATION)?;
                write_f64(e, off + clock_field::PREV_INTERVAL, time - last)?;
            }
        } else {
            let interval = read_f64(e, off + clock_field::INTERVAL)?;
            write_f64(e, off + clock_field::PREV_INTERVAL, interval)?;
        }
        write_f64(e, off + clock_field::LAST_ACTIVATION, time)?;

        let sub0 = &clock.sub[0];
        let first_is_base = sub0.shift_num == 0 && sub0.factor_num == 1 && sub0.factor_den == 1;
        if first_is_base {
            if let Some(r) = rows.as_deref_mut() {
                driver::capture_row(e, r, self.sim_data, &self.layout)?;
            }
            let s_off = self.sim_data + self.layout.sub_clock_off(clock.sub_base);
            let n = read_i32(e, s_off + clock_field::SUB_COUNT)? + 1;
            write_i32(e, s_off + clock_field::SUB_COUNT, n)?;
            let prev = read_f64(e, off + clock_field::PREV_INTERVAL)?;
            write_f64(e, s_off + clock_field::SUB_PREV_INTERVAL, prev)?;
            write_f64(e, s_off + clock_field::SUB_LAST_ACTIVATION, time)?;
            e.call2(MODEL_FN_EQS_SYNC, self.sim_data, clock.sub_base)?;
        }

        if !clock.is_event_clock {
            e.call2(MODEL_FN_UPDATE_SYNC, self.sim_data, base)?;
            let interval = read_f64(e, off + clock_field::INTERVAL)?;
            self.insert(Timer { base, sub: None, time: time + interval });
            omclog::info(
                omclog::SYNCHRONOUS,
                false,
                &format!("Activated base-clock {base} at time {}", driver::format_f(time)),
            );
        } else {
            omclog::info(
                omclog::SYNCHRONOUS,
                false,
                &format!("Activated event-clock {base} at time {}", driver::format_f(time)),
            );
        }

        // The sub-clock ticks inside this base interval:
        //   s = shift + subCount*factor - (baseCount - 1)
        // fires whenever `floor(s) == 0`, at `time + s*interval` — the interval
        // `updateSynchronous` just recomputed, as in C.
        let interval = read_f64(e, off + clock_field::INTERVAL)?;
        for k in usize::from(first_is_base)..clock.sub.len() {
            let sub = &clock.sub[k];
            let s_off = self.sim_data + self.layout.sub_clock_off(clock.sub_base + k as u32);
            let sub_count = read_i32(e, s_off + clock_field::SUB_COUNT)? as i64;
            let factor = Rat::new(sub.factor_num, sub.factor_den);
            let mut t = Rat::new(sub.shift_num, sub.shift_den)
                .sub(Rat::int(count as i64 - 1))
                .add(Rat::int(sub_count).mul(factor));
            while t.floor() == 0 {
                self.insert(Timer {
                    base,
                    sub: Some(k as u32),
                    time: time + t.to_real() * interval,
                });
                t = t.add(factor);
            }
        }
        Ok(first_is_base)
    }

    /// The `SYNC_SUB_CLOCK` arm of C's `handleTimers`.
    fn handle_sub_clock(
        &mut self,
        e: &mut dyn SimEngine,
        base: u32,
        sub: u32,
        time: f64,
        rows: Option<&mut Vec<f64>>,
    ) -> Result<Fired> {
        let clock = &self.clocks[base as usize];
        let flat = clock.sub_base + sub;
        let hold = clock.sub[sub as usize].hold_events;
        if let Some(r) = rows {
            driver::capture_row(e, r, self.sim_data, &self.layout)?;
        }
        let s_off = self.sim_data + self.layout.sub_clock_off(flat);
        let n = read_i32(e, s_off + clock_field::SUB_COUNT)? + 1;
        write_i32(e, s_off + clock_field::SUB_COUNT, n)?;
        let last = read_f64(e, s_off + clock_field::SUB_LAST_ACTIVATION)?;
        write_f64(e, s_off + clock_field::SUB_PREV_INTERVAL, time - last)?;
        write_f64(e, s_off + clock_field::SUB_LAST_ACTIVATION, time)?;
        e.call2(MODEL_FN_EQS_SYNC, self.sim_data, flat)?;
        let what = if hold { "which triggered event " } else { "" };
        omclog::info(
            omclog::SYNCHRONOUS,
            false,
            &format!("Activated sub-clock ({base},{sub}) {what}at time {}", driver::format_f(time)),
        );
        Ok(if hold { Fired::Event } else { Fired::Timer })
    }

    /// C's `printClocks`, the `LOG_SYNCHRONOUS` dump after initialization.
    fn print_clocks(&self, e: &dyn SimEngine) -> Result<()> {
        if !omclog::active(omclog::SYNCHRONOUS) {
            return Ok(());
        }
        omclog::info(omclog::SYNCHRONOUS, true, "Initialized synchronous timers.");
        omclog::info(omclog::SYNCHRONOUS, false, &format!("Number of base clocks: {}", self.clocks.len()));
        for (i, c) in self.clocks.iter().enumerate() {
            omclog::info(omclog::SYNCHRONOUS, true, &format!("Base clock {}", i + 1));
            let off = self.sim_data + self.layout.base_clock_off(i as u32);
            let interval = read_f64(e, off + clock_field::INTERVAL)?;
            let counter = read_i32(e, off + clock_field::INTERVAL_COUNTER)?;
            if c.is_event_clock {
                omclog::info(omclog::SYNCHRONOUS, false, "is event clock");
            } else {
                if counter != -1 {
                    let res = read_i32(e, off + clock_field::RESOLUTION)?;
                    omclog::info(
                        omclog::SYNCHRONOUS,
                        false,
                        &format!("intervalCounter/resolution = : {counter}/{res}"),
                    );
                }
                omclog::info(omclog::SYNCHRONOUS, false, &format!("interval: {}", omclog::e(interval, 0, 6)));
            }
            omclog::info(omclog::SYNCHRONOUS, false, &format!("Number of sub-clocks: {}", c.sub.len()));
            for (j, s) in c.sub.iter().enumerate() {
                omclog::info(
                    omclog::SYNCHRONOUS,
                    true,
                    &format!("Sub-clock {} of base clock {}", j + 1, i + 1),
                );
                omclog::info(omclog::SYNCHRONOUS, false, &format!("shift: {}/{}", s.shift_num, s.shift_den));
                omclog::info(omclog::SYNCHRONOUS, false, &format!("factor: {}/{}", s.factor_num, s.factor_den));
                let method = if s.external_solver { "External" } else { "none" };
                omclog::info(omclog::SYNCHRONOUS, false, &format!("solverMethod: {method}"));
                omclog::info(omclog::SYNCHRONOUS, false, &format!("holdEvents: {}", s.hold_events));
                omclog::close(omclog::SYNCHRONOUS);
            }
            omclog::close(omclog::SYNCHRONOUS);
        }
        omclog::close(omclog::SYNCHRONOUS);
        Ok(())
    }
}

/// Clear the `$_clkfire` flags. Run before initialization: `SimData` comes from a
/// recycled `rt_alloc` block, and the initial system's discrete update may already
/// raise a flag, which [`Sync::new`] then collects.
pub fn clear_fire_flags(e: &mut dyn SimEngine, sim_data: u32, layout: &Layout) -> Result<()> {
    for i in 0..layout.n_base_clocks {
        write_i32(e, sim_data + layout.clock_fire_off + i * 4, 0)?;
    }
    Ok(())
}
