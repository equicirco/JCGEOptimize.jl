@testset "problem definitions and evaluation validity" begin
    @test_throws ArgumentError DecisionVariable(:x; lower = 1, upper = 0)
    @test_throws ArgumentError DecisionVariable(:x; lower = 0, upper = Inf)
    @test_throws ArgumentError DecisionVariable(:x; lower = 0, upper = 1, initial = 2)
    @test_throws ArgumentError Objective(:value, identity; sense = :other)
    @test_throws ArgumentError Objective(:value, identity; scale = 0)
    @test_throws ArgumentError OutcomeConstraint(:value, identity; lower = 2, upper = 1)
    @test_throws ArgumentError OutcomeConstraint(:value, identity; lower = -Inf, upper = Inf)
    @test_throws ArgumentError OutcomeConstraint(:value, identity; tolerance = -1)
    x = DecisionVariable(:x; lower = 0, upper = 1, initial = 0.5)
    @test_throws ArgumentError OptimizationProblem([x, x], identity;
        objectives = [Objective(:value, identity)])
    @test_throws ArgumentError OptimizationProblem([x], identity; objectives = [])
    @test_throws ArgumentError OptimizationProblem([x], identity;
        objectives = [Objective(:value, identity)], on_error = :ignore)
    problem = OptimizationProblem([x], d -> (value = 2d.x, valid = d.x > 0.1);
        objectives = [Objective(:value, o -> o.value; sense = :max)],
        constraints = [OutcomeConstraint(:minimum, o -> o.value;
            lower = 1.0, upper = Inf, tolerance = 0.01, scale = 2.0)],
        isvalid = o -> o.valid)
    record = evaluate(problem, [0.5]; id = 9)
    @test record.id == 9 && record.decisions == (x = 0.5,)
    @test record.feasible && record.status == :valid
    @test record.objectives == [1.0] && record.constraints == [1.0]
    @test record.outcome == (value = 1.0, valid = true)
    @test evaluate(problem, [0.496]).feasible
    infeasible = evaluate(problem, [0.4])
    @test infeasible.status == :valid && !infeasible.feasible
    @test isapprox(only(infeasible.violations), 0.095)
    @test evaluate(problem, [0.0]).status == :invalid
    @test_throws DimensionMismatch evaluate(problem, [0.5, 0.6])
    @test_throws ArgumentError evaluate(problem, [1.1])
    @test_throws ArgumentError evaluate(problem, [NaN])

    equality = OptimizationProblem([x], d -> d.x;
        objectives = [Objective(:value, identity)],
        constraints = [OutcomeConstraint(:balance, identity;
            lower = 0.5, upper = 0.5, tolerance = 0.001)])
    @test evaluate(equality, [0.5005]).feasible
    @test !evaluate(equality, [0.51]).feasible

    nonfinite = OptimizationProblem([x], d -> NaN; objectives = [Objective(:value, identity)])
    @test evaluate(nonfinite, [0.5]).status == :invalid
    broken = OptimizationProblem([x], d -> error("model failed");
        objectives = [Objective(:value, identity)])
    @test_throws ErrorException evaluate(broken, [0.5])
    recorded = OptimizationProblem([x], d -> error("model failed");
        objectives = [Objective(:value, identity)], on_error = :record)
    failure = evaluate(recorded, [0.5])
    @test failure.status == :error && !failure.feasible
    @test occursin("model failed", failure.message)
    interrupted = OptimizationProblem([x], d -> throw(InterruptException());
        objectives = [Objective(:value, identity)], on_error = :record)
    @test_throws InterruptException evaluate(interrupted, [0.5])
end
