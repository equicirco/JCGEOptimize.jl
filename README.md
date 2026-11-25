# JCGEOptimize

## What is a CGE?

A Computable General Equilibrium (CGE) model represents an economy as
interconnected markets for goods and services, production factors,
institutions, and trade. It is calibrated with economic accounts—typically a
Social Accounting Matrix (SAM)—and solved numerically for an equilibrium.

## What is JCGE?

[JCGE](https://jcge.org) is a block-based CGE modeling and execution framework
in Julia. It provides a common model specification and reusable components for
constructing, validating, solving, and comparing CGE models.

## What is this package?

JCGEOptimize provides policy design and parameter optimization around CGE
models. Search algorithms propose decisions; a user-supplied evaluator solves
the model and returns the outcomes used to assess objectives and constraints.
JCGERuntime can solve each equilibrium, and JCGEOutput can report its results.

## Main features

- Bounded continuous decisions and constraints on model outcomes.
- Single-objective optimization and nondominated results for multiple objectives.
- Deterministic grid search and optional Metaheuristics.jl algorithms.
- Model-validity checks and complete evaluation histories.
- Seeded searches, evaluation budgets, and progress callbacks.

## Documentation

The [documentation](https://optimize.jcge.org/dev/) describes the package design,
usage, and API. A [StandardCGE policy optimization application](https://github.com/equicirco/JCGEExamples.jl/tree/main/examples/StandardCGEPolicyOptimization)
in JCGEExamples demonstrates constrained tax optimization and algorithm comparisons.

## How to cite

If you use the [JCGE](https://jcge.org) framework, please cite:

Boero, R. *JCGE - Julia Computable General Equilibrium Framework* [software], 2026.
DOI: 10.5281/zenodo.18282436
URL: https://JCGE.org

```bibtex
@software{boero_jcge_2026,
  title  = {JCGE - Julia Computable General Equilibrium Framework},
  author = {Boero, Riccardo},
  year   = {2026},
  doi    = {10.5281/zenodo.18282436},
  url    = {https://JCGE.org}
}
```

If you use this package, please cite:

Boero, R. *JCGEOptimize.jl - Policy design and parameter optimization for JCGE models.* [software], 2026.
URL: https://optimize.jcge.org
SourceCode: https://github.com/equicirco/JCGEOptimize.jl

```bibtex
@software{boero_jcgeoptimize_2026,
  title  = {JCGEOptimize.jl - Policy design and parameter optimization for JCGE models.},
  author = {Boero, Riccardo},
  year   = {2026},
  url    = {https://optimize.jcge.org}
}
```

If you use a specific tagged release, please cite the version DOI assigned on Zenodo for that release (preferred for exact reproducibility).
