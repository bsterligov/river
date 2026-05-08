# DRAFT -- Issue #4
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #4
Task:     RIVER-4
Title:    Setup DevOps
Why:
To ensure code quality we need setup CI on main branch.

It should 
- checkout 
- run fat check, clip and tests for rust.
- run sonarqube analysis with quality gate

use mine tasks for all actions
use only official  GitHub actions / sonarqube actions
Priority: must
Category: tools
