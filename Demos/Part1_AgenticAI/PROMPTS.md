# Part 1 prompt guide

Start a new chat in an empty folder containing only
`antenna_demo_requirements.md`. Keep this guide outside that folder. Enter each
prompt after reviewing the previous result.

## 1. Read the requirements

> In this folder, read the requirement document and give me the explanation.

## 2. Build the baseline

> Create a baseline model and evaluate its S11 using a fast interpolating sweep in MATLAB. Show the antenna, its S11, and the 3D directivity pattern.

## 3. Bound the experiment

> Plan a bounded experiment.

## 4. Review the plan

> Check any updates in the plan.

## 5. Evaluate and compare

> Compare the candidates and identify which meet every requirement.

Candidates need actual evaluations before they can be called feasible.

## 6. Review the demo conditions

> Adjust the demo conditions based on this result. I want to just demo it.

The supplied brief already contains the revised demonstration conditions. If the
results pass, keep those conditions; no further relaxation is necessary. Record any
requirement change and reevaluate affected candidates.

## 7. Show the trade-off

> Plot board area versus worst-band realized gain, highlighting feasible designs.

## 8. Show and save the selection

> Show the selected antenna, S11, and 3D directivity, summarize the demo checks, and save the reproducible code.

This is a useful stopping point for the single-element activity.

## 9. Extend to a coupled array

> Extend the chosen design to a 2x2 array. Include coupling and recommend element spacing.

Allow substantial computation time. Save checkpoints and report incomplete checks
without treating them as passes. The recorded example is available in the worked
example for discussion without a new solve.

## 10. Plan the physical feed

> Give me a table of candidates to test, including modeling the feed lines in MATLAB. Give me suggestions and help me plan candidates to achieve an array goal.

This asks for a next-study plan. Keep proposed goals and untested feed candidates
separate from evaluated antenna performance.
