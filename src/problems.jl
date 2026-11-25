"""
    DecisionVariable(name; lower, upper, initial=(lower + upper)/2)

A continuously varying model input with finite bounds and an initial candidate.
The evaluator receives decisions as a named tuple using these names.
"""
struct DecisionVariable
    name::Symbol
    lower::Float64
    upper::Float64
    initial::Float64
    function DecisionVariable(name::Symbol; lower::Real, upper::Real,
        initial::Real = lower / 2 + upper / 2)
        lo, hi, x = Float64.((lower, upper, initial))
        isfinite(lo) && isfinite(hi) && lo < hi ||
            throw(ArgumentError("Decision bounds must be finite with lower < upper"))
        isfinite(x) && lo <= x <= hi ||
            throw(ArgumentError("Initial decision must be finite and within its bounds"))
        new(name, lo, hi, x)
    end
end

positive_scale(value) = isfinite(value) && value > 0 ? Float64(value) :
    throw(ArgumentError("Scale must be finite and positive"))

"""
    Objective(name, measure; sense=:min, scale=1.0)

A scalar objective extracted from the evaluator's outcome. `sense` is `:min` or
`:max`. Search backends minimize signed values divided by `scale`; records retain
the original values and units.
"""
struct Objective{F}
    name::Symbol
    measure::F
    sense::Symbol
    scale::Float64
    function Objective(name::Symbol, measure::F; sense::Symbol = :min,
        scale::Real = 1.0) where F
        sense in (:min, :max) || throw(ArgumentError("Objective sense must be :min or :max"))
        new{F}(name, measure, sense, positive_scale(scale))
    end
end

"""
    OutcomeConstraint(name, measure; lower=-Inf, upper=0, tolerance=0, scale=1)

Bounds on a scalar outcome, including equality constraints when `lower == upper`.
`tolerance` is in the outcome's original units. Feasibility allows that tolerance
on either side; backend residuals are then divided by `scale`.
"""
struct OutcomeConstraint{F}
    name::Symbol
    measure::F
    lower::Float64
    upper::Float64
    tolerance::Float64
    scale::Float64
    function OutcomeConstraint(name::Symbol, measure::F; lower::Real = -Inf,
        upper::Real = 0.0, tolerance::Real = 0.0, scale::Real = 1.0) where F
        lo, hi, tol = Float64.((lower, upper, tolerance))
        !isnan(lo) && !isnan(hi) && lo <= hi && (isfinite(lo) || isfinite(hi)) ||
            throw(ArgumentError("Constraint needs ordered bounds and at least one finite bound"))
        isfinite(tol) && tol >= 0 || throw(ArgumentError("Tolerance must be finite and nonnegative"))
        new{F}(name, measure, lo, hi, tol, positive_scale(scale))
    end
end

"""
    OptimizationProblem(decisions, evaluator; objectives, constraints=[],
                        isvalid=outcome->true, on_error=:throw)

Describe an outer optimization problem. `evaluator(named_decisions)` performs a
model evaluation and returns its outcome. `isvalid` must accept only outcomes
whose equilibrium status and residuals satisfy the model's numerical criteria.
Rejected outcomes never enter the optimum or Pareto set.

Unexpected exceptions propagate by default. With `on_error=:record`, ordinary
exceptions become failed evaluation records. Interrupts always propagate.
"""
struct OptimizationProblem{F,V}
    decisions::Vector{DecisionVariable}
    evaluator::F
    objectives::Vector{Objective}
    constraints::Vector{OutcomeConstraint}
    isvalid::V
    on_error::Symbol
end

function OptimizationProblem(decisions, evaluator; objectives, constraints = OutcomeConstraint[],
    isvalid = outcome -> true, on_error::Symbol = :throw)
    variables = DecisionVariable[decisions...]
    targets = Objective[objectives...]
    bounds = OutcomeConstraint[constraints...]
    isempty(variables) && throw(ArgumentError("At least one decision is required"))
    isempty(targets) && throw(ArgumentError("At least one objective is required"))
    for entries in (variables, targets, bounds)
        names = getfield.(entries, :name)
        allunique(names) || throw(ArgumentError("Names within each problem component must be unique"))
    end
    on_error in (:throw, :record) || throw(ArgumentError("on_error must be :throw or :record"))
    return OptimizationProblem(variables, evaluator, targets, bounds, isvalid, on_error)
end
