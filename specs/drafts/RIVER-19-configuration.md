# DRAFT -- Issue #19
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #19
Task:     RIVER-19
Title:    Configuration
Why:
We should setup proper configuration usage. In this projects different usage, sometime we read envs, sometime harcoded values with password (for example "river"). I propose to use rust config crate. Each crate should use config module, that handle configuration read from fiel/envs) All envs should pe prefixed by RIVER_
Priority: should
Category: refactoring
