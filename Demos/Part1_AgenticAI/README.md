# Part 1: Agentic AI workflows

Follow an antenna from written requirements through a baseline, a bounded candidate
study, a selected design, a coupled 2×2 array, and a plan for its physical feed.

## Replay the worked example

Use MATLAB R2026b with Antenna Toolbox and RF Toolbox. From this directory:

```matlab
run(fullfile("Worked_Example", "Results", "antenna_demo.m"))
```

The supplied script defaults to `freshRun = false` and `includeArray = true`.
It loads the supplied checkpoints and opens the saved array figures. It does not
resume the budget-exhausted array study. To view only the selected antenna's
geometry, S11, and 3D directivity, open
[antenna_demo.m](Worked_Example/Results/antenna_demo.m), set `includeArray = false`,
and run it. Set `showEarlierStages = true` to also show baseline and comparison plots.

The source files, saved models, CSVs, PNGs, and MATLAB figures are all included.
The roughly 76 MB `array_study.mat` is intentional: it preserves the complete saved
state, including the incomplete fine-mesh run, without triggering another solve.

## Run your own clean agent workflow

1. Copy the single [requirements file](Clean_Start/antenna_demo_requirements.md)
   into a new empty folder of your choice.
2. Open that new folder as your agent workspace and start a new chat. Keep the
   [prompt guide](PROMPTS.md) outside the new folder.
3. Connect the client to a local MATLAB installation using the
   [MATLAB MCP server](https://github.com/matlab/matlab-mcp-server).
   The [MATLAB Agentic Toolkit](https://github.com/matlab/matlab-agentic-toolkit)
   provides domain skills. Follow their installation instructions for your client.
4. Enter the prompts one at a time. The agent should set MATLAB's current folder to
   the new workspace and create its own code, models, and results there.

This clean run uses only the requirements as project input. The worked example is
available separately for comparison after the run. A clean project folder does not
remove the need for MATLAB, toolbox licenses, or the installed MCP tools.

## Recompute with the supplied MATLAB code

Open [antenna_demo.m](Worked_Example/Results/antenna_demo.m), set `freshRun = true`,
and choose `includeArray`. The self-contained script writes a new timestamped
`Worked_Example/Results/reproduction_*` folder and preserves the supplied results.
Start with `includeArray = false` for the single-element workflow.

The code uses soft numerical budgets: 180 seconds for the element study and
600 seconds for the array. An in-flight solver call can exceed those limits.
The recorded array run exceeded three hours because of one long call, so a fresh
array solve is an extended computation, not a guaranteed short demo.

## Saved results

| Stage | Read / view | Recorded status |
| --- | --- | --- |
| Baseline | [Summary](Worked_Example/baseline_results/baseline_summary.txt) · [S11](Worked_Example/baseline_results/baseline_s11.png) | D1 is a starting model; it fails the match target |
| Six candidates | [Comparison](Worked_Example/candidate_results/comparison_summary.md) | D2 and D6 pass screening |
| Selected element | [Demo checks](Worked_Example/selected_results/demo_checks.md) · [Geometry](Worked_Example/selected_results/selected_geometry.png) · [S11](Worked_Example/selected_results/selected_s11.png) · [3D directivity](Worked_Example/selected_results/selected_directivity_3d.png) | D6: 100 × 100 mm board; worst sampled S11 −12.16 dB; minimum sampled realized gain 8.90 dBi |
| Coupled 2×2 array | [Summary](Worked_Example/array_results/array_summary.md) · [Geometry](Worked_Example/array_results/array_geometry.png) · [Spacing comparison](Worked_Example/array_results/array_spacing_comparison.png) · [Port curves](Worked_Example/array_results/array_port_curves.png) | Provisional 105 mm spacing, 205 × 205 mm outline, 14.97 dBi minimum sampled broadside gain |
| Physical feed | [Candidate plan](Worked_Example/feed_plan/array_feed_plan.md) · [Candidate CSV](Worked_Example/feed_plan/feed_candidates.csv) | Six planned candidates; feed performance not yet evaluated |

The array has three completed screening spacings. Fine-mesh verification has
17/21 S-parameter frequencies and 0/3 gain frequencies; its 3D pattern and remaining
field checks are pending. Array gain uses 1 W total incident power and excludes
physical divider, cable, and connector losses. These are sampled demonstration
checks, not continuous-band or fabrication qualification.

The active brief uses 2.44–2.46 GHz and a maximum **individual** board of 125 × 125 mm.
Some unchanged slides show the earlier draft targets; use the packaged requirements
and result summaries for this worked example.

## Explore feed planning

With RF PCB Toolbox installed, change MATLAB's current folder to `Worked_Example`
and run:

```matlab
[feedCandidates, feedPlan] = planArrayFeedCandidates;
```

This creates candidate tables and initial microstrip dimensions. It does not perform
a feed-network EM solve or establish that a feed candidate meets the proposed goals.
