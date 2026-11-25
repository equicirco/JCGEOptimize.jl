"""
    EvaluationRecord

One model evaluation: named decisions, objective and constraint values in their
original units, scaled constraint violations, model-validity status, feasibility,
diagnostic message, elapsed seconds, and the evaluator's outcome. Evaluators
should return compact outcomes rather than retain a whole solver model per call.
"""
struct EvaluationRecord{O}
    id::Int
    decisions::NamedTuple
    objectives::Vector{Float64}
    constraints::Vector{Float64}
    violations::Vector{Float64}
    status::Symbol
    feasible::Bool
    message::String
    elapsed_seconds::Float64
    outcome::O
end

function named_decisions(problem, values)
    length(values) == length(problem.decisions) || throw(DimensionMismatch("Wrong decision count"))
    x = Tuple(Float64.(values))
    all(isfinite(value) && variable.lower <= value <= variable.upper
        for (value, variable) in zip(x, problem.decisions)) ||
        throw(ArgumentError("Decisions must be finite and within their declared bounds"))
    return NamedTuple{Tuple(variable.name for variable in problem.decisions)}(x)
end

function constraint_residuals(problem, values)
    residuals = Float64[]
    for (constraint, value) in zip(problem.constraints, values)
        isfinite(constraint.lower) && push!(residuals,
            (constraint.lower - value - constraint.tolerance) / constraint.scale)
        isfinite(constraint.upper) && push!(residuals,
            (value - constraint.upper - constraint.tolerance) / constraint.scale)
    end
    return residuals
end

function failed_evaluation(problem, id, decisions, status, message, started, outcome)
    return EvaluationRecord(id, decisions, fill(NaN, length(problem.objectives)),
        fill(NaN, length(problem.constraints)), fill(Inf, length(problem.constraints)),
        status, false, message, (time_ns() - started) / 1e9, outcome)
end

"""
    evaluate(problem, values; id=1) -> EvaluationRecord

Evaluate one bounded candidate. A numerically valid model can still be infeasible
for the outer outcome constraints. Nonfinite objective or constraint values are
rejected, regardless of the validity callback.
"""
function evaluate(problem::OptimizationProblem, values; id::Integer = 1)
    decisions = named_decisions(problem, values)
    started = time_ns()
    outcome = nothing
    try
        outcome = problem.evaluator(decisions)
        if !problem.isvalid(outcome)
            return failed_evaluation(problem, Int(id), decisions, :invalid,
                "Model outcome rejected by isvalid", started, outcome)
        end
        objectives = Float64[target.measure(outcome) for target in problem.objectives]
        constraints = Float64[bound.measure(outcome) for bound in problem.constraints]
        if !all(isfinite, objectives) || !all(isfinite, constraints)
            return failed_evaluation(problem, Int(id), decisions, :invalid,
                "Nonfinite objective or constraint value", started, outcome)
        end
        violations = [max(0.0, bound.lower - value - bound.tolerance,
            value - bound.upper - bound.tolerance) / bound.scale
            for (bound, value) in zip(problem.constraints, constraints)]
        return EvaluationRecord(Int(id), decisions, objectives, constraints, violations,
            :valid, all(iszero, violations), "", (time_ns() - started) / 1e9, outcome)
    catch error
        error isa InterruptException && rethrow()
        problem.on_error == :throw && rethrow()
        return failed_evaluation(problem, Int(id), decisions, :error,
            sprint(showerror, error), started, outcome)
    end
end

function minimized_objectives(problem, record)
    return [(target.sense == :min ? value : -value) / target.scale
        for (target, value) in zip(problem.objectives, record.objectives)]
end

"""
    evaluation_rows(result)

Return a vector of flat named tuples suitable for tabular export. Decision,
objective, constraint, and violation columns have explicit name prefixes; failed
evaluations remain in the table with their status and diagnostic message.
"""
function evaluation_rows(result)
    problem = result.problem
    return [merge((evaluation = record.id, status = string(record.status),
        feasible = record.feasible, message = record.message,
        elapsed_seconds = record.elapsed_seconds),
        (; (Symbol(:decision_, key) => value for (key, value) in pairs(record.decisions))...),
        (; (Symbol(:objective_, target.name) => value
            for (target, value) in zip(problem.objectives, record.objectives))...),
        (; (Symbol(:constraint_, bound.name) => value
            for (bound, value) in zip(problem.constraints, record.constraints))...),
        (; (Symbol(:violation_, bound.name) => value
            for (bound, value) in zip(problem.constraints, record.violations))...))
        for record in result.evaluations]
end
