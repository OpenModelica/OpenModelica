//! The model description an importer works with. FMI 1.0, 2.0 and 3.0 all parse
//! into these types: where the versions differ, the 3.0 spelling is the one kept
//! and the older forms are normalised onto it (`guid` → `instantiation_token`,
//! FMI 2.0's `Real` → `Float64`, a derivative's variable *index* → its value
//! reference). What only one version has (FMI 1.0 aliases, FMI 3.0 clocks) is
//! kept as it is.

use std::collections::HashMap;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum FmiVersion {
    Fmi1,
    Fmi2,
    Fmi3,
}

impl FmiVersion {
    pub fn as_str(self) -> &'static str {
        match self {
            FmiVersion::Fmi1 => "1.0",
            FmiVersion::Fmi2 => "2.0",
            FmiVersion::Fmi3 => "3.0",
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum InterfaceKind {
    ModelExchange,
    CoSimulation,
    ScheduledExecution,
}

impl InterfaceKind {
    pub fn as_str(self) -> &'static str {
        match self {
            InterfaceKind::ModelExchange => "ModelExchange",
            InterfaceKind::CoSimulation => "CoSimulation",
            InterfaceKind::ScheduledExecution => "ScheduledExecution",
        }
    }
}

/// FMI 3.0's variable types. FMI 1.0/2.0 `Real` is a [`VarType::Float64`],
/// `Integer` an [`VarType::Int32`].
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum VarType {
    Float32,
    Float64,
    Int8,
    UInt8,
    Int16,
    UInt16,
    Int32,
    UInt32,
    Int64,
    UInt64,
    Boolean,
    String,
    Binary,
    Enumeration,
    Clock,
}

impl VarType {
    /// The type whose `fmi3Get*`/`fmi3Set*` carries this one: FMI 3.0 moves
    /// enumerations over `fmi3Int64`, everything else over its own.
    pub fn wire(self) -> VarType {
        match self {
            VarType::Enumeration => VarType::Int64,
            t => t,
        }
    }

    /// Can be plotted, i.e. read as one `f64` per sample.
    pub fn is_numeric(self) -> bool {
        !matches!(self, VarType::String | VarType::Binary | VarType::Clock)
    }

    pub fn is_float(self) -> bool {
        matches!(self, VarType::Float32 | VarType::Float64)
    }

    /// The `<Float64 …>` element name, which is also the FMI 3.0 API suffix.
    pub fn as_str(self) -> &'static str {
        match self {
            VarType::Float32 => "Float32",
            VarType::Float64 => "Float64",
            VarType::Int8 => "Int8",
            VarType::UInt8 => "UInt8",
            VarType::Int16 => "Int16",
            VarType::UInt16 => "UInt16",
            VarType::Int32 => "Int32",
            VarType::UInt32 => "UInt32",
            VarType::Int64 => "Int64",
            VarType::UInt64 => "UInt64",
            VarType::Boolean => "Boolean",
            VarType::String => "String",
            VarType::Binary => "Binary",
            VarType::Enumeration => "Enumeration",
            VarType::Clock => "Clock",
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Causality {
    Parameter,
    CalculatedParameter,
    Input,
    Output,
    #[default]
    Local,
    Independent,
    StructuralParameter,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Variability {
    Constant,
    Fixed,
    Tunable,
    Discrete,
    #[default]
    Continuous,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Initial {
    Exact,
    Approx,
    Calculated,
}

/// FMI 1.0 `<ScalarVariable alias=…>`: an alias shares another variable's value
/// reference, so a master must not treat it as an independent variable.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Alias {
    #[default]
    NoAlias,
    Alias,
    NegatedAlias,
}

/// Start values, one per element of an array variable (scalars have one).
#[derive(Clone, PartialEq, Debug)]
pub enum Start {
    Reals(Vec<f64>),
    Ints(Vec<i64>),
    Bools(Vec<bool>),
    Strings(Vec<String>),
    Binaries(Vec<Vec<u8>>),
}

impl Start {
    /// The first element as an `f64`, for the numeric types a master can set
    /// without knowing which one it is.
    pub fn first_f64(&self) -> Option<f64> {
        match self {
            Start::Reals(v) => v.first().copied(),
            Start::Ints(v) => v.first().map(|&i| i as f64),
            Start::Bools(v) => v.first().map(|&b| b as u8 as f64),
            _ => None,
        }
    }
}

/// An array dimension: either a fixed `start` extent or one a structural
/// parameter carries (`valueReference`).
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Dimension {
    Fixed(u64),
    ValueReference(u32),
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum IntervalVariability {
    Constant,
    Fixed,
    Tunable,
    Changing,
    Countdown,
    Triggered,
}

/// The `<Clock>` attributes (FMI 3.0 only).
#[derive(Clone, Debug)]
pub struct ClockInfo {
    pub interval_variability: IntervalVariability,
    pub can_be_deactivated: bool,
    pub priority: Option<u32>,
    pub interval_decimal: Option<f64>,
    pub shift_decimal: f64,
    pub supports_fraction: bool,
    pub resolution: Option<u64>,
    pub interval_counter: Option<u64>,
    pub shift_counter: u64,
}

/// The `<Binary>` attributes (FMI 3.0 only).
#[derive(Clone, Debug)]
pub struct BinaryInfo {
    pub mime_type: String,
    /// `None` when the FMU set no upper bound on the value's size.
    pub max_size: Option<u64>,
}

/// An `<Alias>` child (FMI 3.0): another name for the same value reference.
#[derive(Clone, Debug)]
pub struct VariableAlias {
    pub name: String,
    pub description: Option<String>,
    pub display_unit: Option<String>,
}

#[derive(Clone, Debug)]
pub struct Variable {
    pub name: String,
    pub value_reference: u32,
    /// 1-based position in `<ModelVariables>`, which is how FMI 1.0/2.0
    /// `<ModelStructure>` and `<DirectDependency>` refer to a variable.
    pub index: u32,
    pub description: Option<String>,
    pub ty: VarType,
    pub causality: Causality,
    pub variability: Variability,
    pub initial: Option<Initial>,
    pub start: Option<Start>,
    pub declared_type: Option<String>,
    pub quantity: Option<String>,
    pub unit: Option<String>,
    pub display_unit: Option<String>,
    pub relative_quantity: bool,
    pub unbounded: bool,
    pub min: Option<f64>,
    pub max: Option<f64>,
    pub nominal: Option<f64>,
    /// The value reference of the variable this one is the derivative of;
    /// normalised from FMI 2.0's variable index.
    pub derivative: Option<u32>,
    pub reinit: bool,
    pub previous: Option<u32>,
    pub intermediate_update: bool,
    pub clocks: Vec<u32>,
    pub dimensions: Vec<Dimension>,
    pub clock: Option<ClockInfo>,
    pub binary: Option<BinaryInfo>,
    pub aliases: Vec<VariableAlias>,
    /// FMI 1.0 only; [`Alias::NoAlias`] everywhere else.
    pub alias: Alias,
    pub can_handle_multiple_set_per_time_instant: bool,
}

impl Variable {
    /// A variable a master may set: an input, or a parameter during
    /// initialization. FMI 1.0 aliases are excluded — setting one sets the
    /// variable it aliases.
    pub fn is_settable(&self) -> bool {
        self.alias == Alias::NoAlias
            && matches!(
                self.causality,
                Causality::Input | Causality::Parameter | Causality::StructuralParameter
            )
    }

    /// Number of elements: the product of the fixed dimensions. `None` when a
    /// dimension is only known once the FMU is instantiated.
    pub fn fixed_len(&self) -> Option<u64> {
        let mut n = 1u64;
        for d in &self.dimensions {
            match d {
                Dimension::Fixed(k) => n = n.checked_mul(*k)?,
                Dimension::ValueReference(_) => return None,
            }
        }
        Some(n)
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum DependenciesKind {
    Dependent,
    Constant,
    Fixed,
    Tunable,
    Discrete,
}

/// One `<ModelStructure>` entry.
#[derive(Clone, Debug)]
pub struct Unknown {
    pub value_reference: u32,
    /// FMI 1.0/2.0 spell the unknown as a 1-based variable index; 0 for FMI 3.0.
    pub index: u32,
    /// `None` when the attribute is absent, which means "depends on everything"
    /// — not the same as an empty list, which means "depends on nothing".
    pub dependencies: Option<Vec<u32>>,
    pub dependencies_kind: Vec<DependenciesKind>,
}

#[derive(Clone, Debug, Default)]
pub struct ModelStructure {
    pub outputs: Vec<Unknown>,
    /// `<ContinuousStateDerivative>` (3.0) / `<Derivatives>` (2.0).
    pub continuous_state_derivatives: Vec<Unknown>,
    pub clocked_states: Vec<Unknown>,
    pub initial_unknowns: Vec<Unknown>,
    /// FMI 3.0 only: 1.0/2.0 carry the count in `numberOfEventIndicators`.
    pub event_indicators: Vec<Unknown>,
}

#[derive(Clone, Copy, Debug, Default)]
pub struct DefaultExperiment {
    pub start_time: Option<f64>,
    pub stop_time: Option<f64>,
    pub tolerance: Option<f64>,
    pub step_size: Option<f64>,
}

/// A `<ModelExchange>`, `<CoSimulation>` or `<ScheduledExecution>` element. The
/// fields no version of that interface has are left at their defaults.
#[derive(Clone, Debug, Default)]
pub struct Interface {
    pub model_identifier: String,
    pub needs_execution_tool: bool,
    pub can_be_instantiated_only_once_per_process: bool,
    pub can_not_use_memory_management_functions: bool,
    pub can_get_and_set_state: bool,
    pub can_serialize_state: bool,
    pub provides_directional_derivatives: bool,
    pub provides_adjoint_derivatives: bool,
    pub provides_per_element_dependencies: bool,
    pub provides_evaluate_discrete_states: bool,
    /// FMI 3.0 spelling; FMI 2.0's `completedIntegratorStepNotNeeded` is
    /// inverted into it, and FMI 1.0 always needs the call.
    pub needs_completed_integrator_step: bool,
    pub can_handle_variable_communication_step_size: bool,
    pub fixed_internal_step_size: Option<f64>,
    pub max_output_derivative_order: u32,
    pub recommended_intermediate_input_smoothness: i32,
    pub provides_intermediate_update: bool,
    pub might_return_early_from_do_step: bool,
    pub can_return_early_after_intermediate_update: bool,
    pub has_event_mode: bool,
    /// FMI 1.0/2.0 Co-Simulation.
    pub can_interpolate_inputs: bool,
    pub can_run_asynchronously: bool,
    /// FMI 1.0 `<Capabilities>`.
    pub can_handle_events: bool,
    pub can_reject_steps: bool,
    pub can_signal_events: bool,
    /// `<SourceFiles>`, when the FMU ships its sources.
    pub source_files: Vec<String>,
}

#[derive(Clone, Debug)]
pub struct BaseUnit {
    pub kg: i32,
    pub m: i32,
    pub s: i32,
    pub a: i32,
    pub k: i32,
    pub mol: i32,
    pub cd: i32,
    pub rad: i32,
    pub factor: f64,
    pub offset: f64,
}

#[derive(Clone, Debug)]
pub struct DisplayUnit {
    pub name: String,
    pub factor: f64,
    pub offset: f64,
    /// FMI 3.0's reciprocal display units (mpg, Siemens): the display value is
    /// `factor / value`, and the spec allows it only with `offset = 0`. Plain
    /// `factor * value + offset` when not set.
    pub inverse: bool,
}

#[derive(Clone, Debug)]
pub struct Unit {
    pub name: String,
    pub base_unit: Option<BaseUnit>,
    pub display_units: Vec<DisplayUnit>,
}

#[derive(Clone, Debug)]
pub struct EnumerationItem {
    pub name: String,
    pub value: i64,
    pub description: Option<String>,
}

/// A `<TypeDefinitions>` entry: FMI 3.0's `<Float64Type name=…>` and the older
/// `<SimpleType>`/`<Type>` alike.
#[derive(Clone, Debug)]
pub struct TypeDefinition {
    pub name: String,
    pub ty: VarType,
    pub description: Option<String>,
    pub quantity: Option<String>,
    pub unit: Option<String>,
    pub display_unit: Option<String>,
    pub relative_quantity: bool,
    pub unbounded: bool,
    pub min: Option<f64>,
    pub max: Option<f64>,
    pub nominal: Option<f64>,
    pub items: Vec<EnumerationItem>,
}

/// One `<Annotations>` entry, kept as the XML the tool wrote. `name` is FMI 3.0's
/// `type` or the older `<Tool name=…>`.
#[derive(Clone, Debug)]
pub struct ToolAnnotation {
    pub name: String,
    pub xml: String,
}

#[derive(Clone, Debug)]
pub struct LogCategory {
    pub name: String,
    pub description: Option<String>,
}

#[derive(Clone, Debug)]
pub struct ModelDescription {
    pub fmi_version: FmiVersion,
    /// Exactly what the file said (`"3.0"`, but also `"3.0.1"` or `"2.0.4"`).
    pub fmi_version_string: String,
    pub model_name: String,
    /// FMI 3.0 `instantiationToken`; the `guid` of the older versions.
    pub instantiation_token: String,
    pub description: Option<String>,
    pub author: Option<String>,
    pub version: Option<String>,
    pub copyright: Option<String>,
    pub license: Option<String>,
    pub generation_tool: Option<String>,
    pub generation_date_and_time: Option<String>,
    pub variable_naming_convention: String,
    pub model_exchange: Option<Interface>,
    pub co_simulation: Option<Interface>,
    pub scheduled_execution: Option<Interface>,
    pub default_experiment: Option<DefaultExperiment>,
    pub variables: Vec<Variable>,
    pub model_structure: ModelStructure,
    pub units: Vec<Unit>,
    pub type_definitions: Vec<TypeDefinition>,
    pub log_categories: Vec<LogCategory>,
    pub tool_annotations: Vec<ToolAnnotation>,
    /// FMI 1.0/2.0 attribute; for FMI 3.0 the `<EventIndicator>` count.
    pub number_of_event_indicators: u32,
    /// FMI 1.0 attribute. Later versions derive the count from
    /// `<ContinuousStateDerivative>`.
    pub number_of_continuous_states: Option<u32>,
    /// `valueReference` → index into `variables`. FMI 1.0 lets several
    /// variables share one, so this is the first (non-alias) of them.
    pub(crate) vr_index: HashMap<u32, usize>,
}

impl ModelDescription {
    /// The OpenModelica `<Figures>` annotation, parsed. Empty when the model
    /// declared none.
    pub fn figures(&self) -> Vec<crate::figures::Figure> {
        crate::figures::figures(&self.tool_annotations)
    }

    /// The OpenModelica `<Visualization>` annotation naming the `_visual.xml`
    /// scene in `resources/`.
    pub fn visualization(&self) -> Option<crate::figures::Visualization> {
        crate::figures::visualization(&self.tool_annotations)
    }

    pub(crate) fn build_index(&mut self) {
        self.vr_index.clear();
        for (i, v) in self.variables.iter().enumerate() {
            if v.alias == Alias::NoAlias {
                self.vr_index.entry(v.value_reference).or_insert(i);
            }
        }
        if self.fmi_version == FmiVersion::Fmi3 {
            self.number_of_event_indicators = self.model_structure.event_indicators.len() as u32;
        }
    }

    pub fn variable_by_vr(&self, vr: u32) -> Option<&Variable> {
        self.vr_index.get(&vr).map(|&i| &self.variables[i])
    }

    pub fn variable_by_name(&self, name: &str) -> Option<&Variable> {
        self.variables.iter().find(|v| v.name == name)
    }

    /// The interface of `kind`, when the FMU offers it.
    pub fn interface(&self, kind: InterfaceKind) -> Option<&Interface> {
        match kind {
            InterfaceKind::ModelExchange => self.model_exchange.as_ref(),
            InterfaceKind::CoSimulation => self.co_simulation.as_ref(),
            InterfaceKind::ScheduledExecution => self.scheduled_execution.as_ref(),
        }
    }

    pub fn interfaces(&self) -> Vec<InterfaceKind> {
        [
            InterfaceKind::ModelExchange,
            InterfaceKind::CoSimulation,
            InterfaceKind::ScheduledExecution,
        ]
        .into_iter()
        .filter(|&k| self.interface(k).is_some())
        .collect()
    }

    /// Continuous states, as the value references of the variables the
    /// `<ContinuousStateDerivative>` entries differentiate. Model Exchange needs
    /// them in this order — it is the order `fmi3GetContinuousStates` uses.
    pub fn continuous_states(&self) -> Vec<u32> {
        self.model_structure
            .continuous_state_derivatives
            .iter()
            .filter_map(|u| self.variable_by_vr(u.value_reference)?.derivative)
            .collect()
    }

    pub fn number_of_continuous_states(&self) -> u32 {
        match self.number_of_continuous_states {
            Some(n) => n,
            None => self.model_structure.continuous_state_derivatives.len() as u32,
        }
    }

    /// The independent variable (`time`), when one is declared.
    pub fn time_variable(&self) -> Option<&Variable> {
        self.variables.iter().find(|v| v.causality == Causality::Independent)
    }

    /// Fill in what a variable inherits from its `declaredType`. FMI lets a
    /// variable leave unit/min/max/nominal to the type it declares.
    pub(crate) fn resolve_declared_types(&mut self) {
        let types: HashMap<&str, &TypeDefinition> =
            self.type_definitions.iter().map(|t| (t.name.as_str(), t)).collect();
        let patches: Vec<(usize, TypeDefinition)> = self
            .variables
            .iter()
            .enumerate()
            .filter_map(|(i, v)| {
                let t = types.get(v.declared_type.as_deref()?)?;
                Some((i, (*t).clone()))
            })
            .collect();
        for (i, t) in patches {
            let v = &mut self.variables[i];
            v.quantity = v.quantity.take().or_else(|| t.quantity.clone());
            v.unit = v.unit.take().or_else(|| t.unit.clone());
            v.display_unit = v.display_unit.take().or_else(|| t.display_unit.clone());
            v.min = v.min.or(t.min);
            v.max = v.max.or(t.max);
            v.nominal = v.nominal.or(t.nominal);
            v.relative_quantity |= t.relative_quantity;
            v.unbounded |= t.unbounded;
        }
    }
}

impl Default for ModelDescription {
    fn default() -> Self {
        ModelDescription {
            fmi_version: FmiVersion::Fmi3,
            fmi_version_string: String::new(),
            model_name: String::new(),
            instantiation_token: String::new(),
            description: None,
            author: None,
            version: None,
            copyright: None,
            license: None,
            generation_tool: None,
            generation_date_and_time: None,
            variable_naming_convention: "flat".to_string(),
            model_exchange: None,
            co_simulation: None,
            scheduled_execution: None,
            default_experiment: None,
            variables: Vec::new(),
            model_structure: ModelStructure::default(),
            units: Vec::new(),
            type_definitions: Vec::new(),
            log_categories: Vec::new(),
            tool_annotations: Vec::new(),
            number_of_event_indicators: 0,
            number_of_continuous_states: None,
            vr_index: HashMap::new(),
        }
    }
}
