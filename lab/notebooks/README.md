# `lab/notebooks/` - reserved for Phase 2

Intentionally empty. No notebook work is part of Phase 1.

Phase 2 (only after the user approves Phase 1) will **adapt the official
`../../bindcraft.ipynb`** rather than rebuild a notebook from scratch, adding:

- target / chain / hotspot / modality selection with `ipywidgets`
- reproducible config writing into `lab/configs/` or a per-user folder
- authorized SLURM H200 submission with persisted job IDs, so a notebook
  session can be closed while the campaign runs
- loading of historical campaigns, including the zero-accepted state and the
  filters that rejected candidates
- ranked-candidate tables and `py3Dmol` views of `3_Ranked/*.cif`
- FASTA / CSV / CIF / metadata export
- per-user or permission-controlled folders, with no credentials in the notebook

Colab-specific Google Drive and setup cells from the upstream notebook must not
be assumed to work on the institutional Jupyter/Workbench deployment, and
`py3Dmol` availability has to be checked there.

Out of scope for Phase 2 as well: R Shiny, Rosetta integration, and any hosted
public inference service (the upstream license restricts third-party hosted
access to the software's substantial functionality).
