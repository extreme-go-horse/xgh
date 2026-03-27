# AGAINST Agent — Mandatory Failure-Mode Checklist

Include answers to ALL of these in every AGAINST review. These are the questions that catch real bugs — not hypothetical ones.

## Fresh Install / State Gaps
- What happens on a machine with no prior config files, empty directories, or no existing state?
- Does the code assume files exist before writing them?
- Does the code assume prior state that a new user wouldn't have?

## Concurrent Access
- What happens if two processes run this simultaneously?
- Are writes atomic? Can they produce torn/partial output?
- Is any shared resource (file, DB, port) left in a bad state on failure?

## Predicate / Logic Errors
- Are boolean operators (AND/OR) correct in all conditions?
- Does any detection/matching predicate over-match (catches things it shouldn't)?
- Does any predicate under-match (misses valid cases)?
- What's the most unusual valid input that would be missed?

## User Data Safety
- Can this clobber user-created data that happens to match our pattern?
- Is the detection narrow enough to only touch what we own?

## Code Reviewer Perspective
- What would a fresh reviewer catch on first read that the author normalized?
- What implicit assumptions are baked in that aren't stated?
- What's the most subtle bug that would only appear in production?

## Spec/Implementation Drift
- Does the spec describe behavior that isn't actually implemented?
- Does the implementation do something the spec doesn't mention?
- Which is authoritative if they conflict?

## Resource Cleanup
- Are file handles, DB connections, or processes always closed on failure?
- Is any tmp file cleaned up if the operation fails midway?
- Can the system be left in an unrecoverable state?
