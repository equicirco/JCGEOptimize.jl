# Design

## Role in JCGE

JCGEOptimize is designed as an optional layer around equilibrium models. A search
algorithm proposes candidate decisions, the model computes their equilibrium
outcomes, and the optimization layer evaluates the objectives and constraints
before proposing further candidates.

The architecture is general: policy design, parameter optimization, and
single-objective or multi-objective problems share this separation between
candidate decisions and equilibrium calculations.

## Responsibilities

The optimization component is intended to define and coordinate:

- Decision variables, their bounds, and their mapping to model inputs.
- Objectives and constraints computed from model outcomes.
- Interchangeable optimization backends, including Metaheuristics.jl.
- Evaluation records, solver-failure handling, and reproducible search histories.
- Results representing an optimum candidate or trade-offs among objectives.

JCGERuntime remains responsible for building and solving equilibrium models and
validating their numerical results. JCGEOutput provides the reporting facilities
for the resulting model outcomes and optimization results. Economic equations and
closures remain defined by the model and its JCGE blocks.

## Initial implementation status

The current source establishes the package module. This design describes the
interfaces to be implemented; version 0.0.1 does not yet execute optimization
searches or provide backend adapters.
