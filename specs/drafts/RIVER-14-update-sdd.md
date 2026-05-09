# DRAFT -- Issue #14
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #14
Task:     RIVER-14
Title:    Update SDD
Why:
I want update our SDD process. Work in the main brunck not a good idea (the primary consideration was to avoid conflicts) Queue system not clear too.

We shoulf use feature brunch approach. The first part spec creation is ok.

Before merge we should move task to pending state (at the end) should see how avoid conflicts in parallel specs. On spec merge we could add a pipeline to create a brunch + PR auto. Que is just for task in que, not need other state. Once task done, we could marq it as done in queue (not need remove)
Priority: must
Category: docs
