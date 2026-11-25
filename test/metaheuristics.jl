import Metaheuristics

@testset "optional Metaheuristics backend" begin
    problem = OptimizationProblem([DecisionVariable(:x; lower = 0, upper = 1, initial = 0.5)],
        d -> d.x; objectives = [Objective(:cost, identity)],
        constraints = [OutcomeConstraint(:minimum, identity; lower = 0.3, upper = Inf)])
    factory = options -> Metaheuristics.DE(N = 12, options = options)
    backend = MetaheuristicsBackend(factory; seed = 31, max_evaluations = 160)
    first_run = optimize(problem, backend)
    second_run = optimize(problem, backend)
    @test first_run.best !== nothing && first_run.best.feasible
    @test 0.3 <= first_run.best.decisions.x < 0.34
    @test length(first_run.evaluations) <= 160
    @test getfield.(first_run.evaluations, :decisions) == getfield.(second_run.evaluations, :decisions)
    @test first_run.metadata.seed == 31
    @test first(first_run.evaluations).decisions.x == 0.5
    @test_throws ArgumentError MetaheuristicsBackend(factory; max_evaluations = 1)
    @test_throws ArgumentError MetaheuristicsBackend(factory; seed = -1)
    for penalty in (0.0, -1.0, Inf, NaN)
        @test_throws ArgumentError MetaheuristicsBackend(factory; failure_penalty = penalty)
    end

    short = optimize(problem, MetaheuristicsBackend(factory; max_evaluations = 3))
    @test length(short.evaluations) == 3
    @test short.stop_reason == "Evaluation budget reached"
    invalid = OptimizationProblem(problem.decisions, _ -> 0.0;
        objectives = [Objective(:score, identity)], isvalid = _ -> false)
    failed = optimize(invalid, MetaheuristicsBackend(factory; max_evaluations = 15))
    @test failed.best === nothing && isempty(failed.pareto)
    @test all(record.status == :invalid for record in failed.evaluations)

    tradeoff = OptimizationProblem(problem.decisions, identity;
        objectives = [Objective(:left, d -> d.x^2), Objective(:right, d -> (1 - d.x)^2)])
    multi = optimize(tradeoff, MetaheuristicsBackend(
        options -> Metaheuristics.NSGA2(N = 12, options = options);
        seed = 5, max_evaluations = 48))
    @test multi.best === nothing && length(multi.pareto) > 1
    @test all(record.feasible for record in multi.pareto)
end

@testset "Finite rejected-evaluation penalties" begin
    # With infinite fallback fitness, ECA's weighted population centre becomes
    # NaN in this two-dimensional case. PSO and DE must share the same valid
    # search interface and continue to exclude rejected model evaluations.
    decisions = [DecisionVariable(:x; lower = 0, upper = 1, initial = 0.5),
        DecisionVariable(:y; lower = 0, upper = 1, initial = 0.5)]
    problem = OptimizationProblem(decisions, identity;
        objectives = [Objective(:cost, d -> d.x^2 + d.y^2)],
        isvalid = d -> d.x >= 0.4)
    for constructor in (Metaheuristics.DE, Metaheuristics.ECA, Metaheuristics.PSO)
        result = optimize(problem, MetaheuristicsBackend(
            options -> constructor(N = 12, options = options);
            seed = 14, max_evaluations = 240, failure_penalty = 1e5))
        @test result.best !== nothing && result.best.feasible
        @test result.best.decisions.x >= 0.4
        @test only(result.best.objectives) < 0.3
        @test any(record -> record.status == :invalid, result.evaluations)
        @test all(record -> all(isfinite, values(record.decisions)), result.evaluations)
        @test all(record -> !record.feasible, filter(record -> record.status == :invalid, result.evaluations))
        @test result.metadata.failure_penalty == 1e5
        @test length(result.evaluations) <= 240
    end

    rejected = OptimizationProblem(decisions, identity;
        objectives = problem.objectives, isvalid = _ -> false)
    result = optimize(rejected, MetaheuristicsBackend(
        options -> Metaheuristics.ECA(N = 12, options = options);
        seed = 14, max_evaluations = 48))
    @test result.best === nothing && isempty(result.pareto)
    @test all(record -> record.status == :invalid && !record.feasible, result.evaluations)

    error_problem = OptimizationProblem(decisions, _ -> error("model solve failed");
        objectives = problem.objectives, on_error = :record)
    errors = optimize(error_problem, MetaheuristicsBackend(
        options -> Metaheuristics.ECA(N = 12, options = options);
        seed = 14, max_evaluations = 48))
    @test errors.best === nothing
    @test all(record -> record.status == :error && record.message == "model solve failed",
        errors.evaluations)
end
