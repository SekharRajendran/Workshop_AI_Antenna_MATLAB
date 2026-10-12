# AI-Enabled Antenna-to-System Design with LLMs, MCP and MATLAB

**MILCOM 2027 · Tutorial TUT13 · Attendee materials**

Use this repository to follow the presentations, explore the demonstrated results,
and work through the MATLAB examples. The tutorial connects agentic engineering
workflows, pretrained antenna models, pattern reconstruction, and RF system design.

## Start here

1. Download the repository with **Code → Download ZIP**, then extract it, or clone it with Git.
2. Read the [Overview slides](Slides/00_Overview.pdf).
3. Choose a demo below. In MATLAB, set the current folder to that demo's directory
   and open its `.m` file. Plain-text Live Scripts include explanatory text and saved output.
4. For Part 1, start with the saved worked example; use the separate clean starter
   when you want an agent to build its own solution.

## Slides and activities

| Section | Slides | Demo / activity |
| --- | --- | --- |
| Overview | [Tutorial overview](Slides/00_Overview.pdf) | Introduction and learning journey |
| Part 1 | [Agentic AI workflows](Slides/01_Agentic_AI_Workflows.pdf) | [Requirements, baseline, bounded study, coupled array, and feed planning](Demos/Part1_AgenticAI/README.md) |
| Part 2A | [AI models, first section of Part 2](Slides/02_AI_Models_and_Pattern_Reconstruction.pdf) | [Pretrained antenna optimization](Demos/Part2A_PretrainedModels/README.md) · [Exercises](Exercises/README.md#part-2a-pretrained-antenna-models) |
| Part 2B | [Pattern reconstruction, second section of Part 2](Slides/02_AI_Models_and_Pattern_Reconstruction.pdf) | [Reconstruct 3D patterns from sparse cuts](Demos/Part2B_PatternReconstruction/README.md) · [Exercises](Exercises/README.md#part-2b-pattern-reconstruction) |
| Part 3 | [Antenna-to-system integration](Slides/03_Antenna_to_System_Integration.pdf) | [Scope and available materials](Demos/Part3_SystemIntegration/README.md) |
| Bonus | [Antenna optimization](Slides/04_Bonus_Antenna_Optimization.pdf) | [MATLAB exercise](Exercises/README.md#bonus-antenna-optimization) · [Python/MATLAB optimizer](Demos/Bonus_Optimization/Python/README.md) |

The PDFs are direct slide exports from the current source presentations, with no
content edits. They contain the visible slides in presentation order. Hidden slides,
speaker notes, narration scripts, animations, and playable embedded videos are not
part of the PDF export. The [slide index](Slides/README.md) records page counts.
Use the demo code and saved results for the interactive examples.

## Software

**MATLAB R2026b is the reference release for these materials.** Some pretrained AI
features and visualizations are release-specific; earlier releases may not support
every example. Use a MATLAB installation or MATLAB Online environment that has the
required release and products. A MATLAB license and the relevant toolbox licenses
are needed to execute the code; the PDFs, PNGs, and CSVs can be read independently.

| Activity | Products / setup |
| --- | --- |
| Part 1 antenna and array | MATLAB, Antenna Toolbox, RF Toolbox |
| Part 1 physical-feed planning | Above, plus RF PCB Toolbox |
| Part 1 agent-driven clean start | A compatible AI/MCP client and the local MATLAB MCP server; see the [Part 1 setup guide](Demos/Part1_AgenticAI/README.md) |
| Part 2A optimization | MATLAB, Antenna Toolbox, Global Optimization Toolbox; dependency analysis also identifies Optimization Toolbox and Statistics and Machine Learning Toolbox |
| Part 2B reconstruction | MATLAB and Antenna Toolbox with `patternFromAI` available |
| Bonus MATLAB exercise | MATLAB, Antenna Toolbox, and the optimization capabilities used by PCB Antenna Designer |
| Bonus Python demo | Local MATLAB, Antenna Toolbox, RF Toolbox, compatible MATLAB Engine for Python, and the [listed Python packages](Demos/Bonus_Optimization/Python/requirements.txt) |

If MATLAB prompts for an AI model download or an additional component, follow the
instructions for the installed release before running that section. An AI client
account or service subscription is separate from MATLAB licensing. Running the
supplied MATLAB examples does not require an AI client.

## What to expect from the results

Part 1 includes the recorded 11–12 October 2026 run and reproducible code. The selected
D6 element passed the stated sampled demo checks. The 2×2 array recommendation is
provisional: screening is complete, while finer-mesh verification and the 3D array
pattern remain incomplete. The physical-feed candidates are a plan, not evaluated
designs. See the [worked-example guide](Demos/Part1_AgenticAI/README.md#saved-results)
for the result files and limitations.

Recorded solver times are examples, not runtime guarantees. Begin with saved results
before starting a new EM study. Part 2 uses AI predictions and reconstruction; use
independent electromagnetic analysis or measurements to validate a final design.

Part 3 currently provides the presentation only. Standalone system-demo scripts,
Simulink models, and an end-to-end handoff from the antenna examples are not included.

## Folder map

```text
Slides/                         Current presentations as PDFs
Demos/Part1_AgenticAI/           Clean starter, prompts, and complete worked example
Demos/Part2A_PretrainedModels/   AI antenna optimization Live Script
Demos/Part2B_PatternReconstruction/  Reconstruction Live Script and input datasets
Demos/Part3_SystemIntegration/  Scope of the slide-based system section
Demos/Bonus_Optimization/       Python/MATLAB optimization example
Exercises/                      Exercises, solutions, and required input data
LICENSE                         Existing repository license
```

## License

The existing [CC0 license](LICENSE) is included unchanged. MATLAB and other required
software are obtained separately under their own licenses.
