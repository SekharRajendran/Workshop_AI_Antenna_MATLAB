# Part 2B: Pattern reconstruction

Open [demo_part2b_pattern_reconstruction_5g.m](demo_part2b_pattern_reconstruction_5g.m)
in MATLAB R2026b's Live Editor with Antenna Toolbox available. Set the current
folder to this directory and run the sections in order.

The demo reconstructs 3D directivity from sparse cuts using `patternFromAI`. It
compares a patch element, a uniform 4×4 array, a steered array, and an array estimate
formed using pattern multiplication. Input datasets are included beside the script:

- `patchElement_28GHz_patternData.mat`
- `patchArray4x4_28GHz_uniformPatternData.mat`
- `patchArray4x4_28GHz_steeredPatternData.mat`

These are synthetic EM reference datasets, not new chamber measurements. Use the
displayed errors and reference patterns to assess the reconstruction. A predicted
pattern is not independent validation of an antenna.

Try the [Part 2B exercises](../../Exercises/README.md) after the demo.
