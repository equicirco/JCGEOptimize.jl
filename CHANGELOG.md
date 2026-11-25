# JCGEOptimize Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-11-25

### Added

- An optional optimization layer around JCGE equilibrium models with bounded
  decisions, objective directions and scaling, and outcome constraints.
- Model-validity callbacks, explicit failure records, original-unit evaluation
  histories, feasible optima, and nondominated results for multiple objectives.
- Deterministic grid search and an optional Metaheuristics.jl extension with
  seeded algorithms, hard evaluation budgets, and evaluation callbacks.
- Documentation of the package design, responsibilities, and intended
  integration with JCGERuntime and JCGEOutput.
- Analytical search, failure-handling, constraint, budget, and reproducibility
  tests, CI, and documentation deployment workflow.
- Apache 2.0 license and citation metadata.

### Fixed

- Pass finite, configurable penalties for rejected evaluations to Metaheuristics
  algorithms, preventing undefined fitness-weighted averages in ECA while
  preserving failure records and excluding failed candidates from reported optima.
