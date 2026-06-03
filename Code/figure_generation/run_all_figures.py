#!/usr/bin/env python3
"""
Run all figure-generation scripts for the LFP choice probability Zenodo release.

Expected location:
    LFP_choice_probability_Zenodo_release_v1/Code/figure_generation/run_all_figures.py

This script calls each standalone plotting script in Code/figure_generation using
the same Python executable that is running this script. Each plotting script reads
from ../../Source_Data and writes to ../../Output/generated_figures.

Usage:
    python run_all_figures.py

Optional:
    python run_all_figures.py --list
    python run_all_figures.py --only Fig3 Fig4
    python run_all_figures.py --skip FigS8
    python run_all_figures.py --continue-on-error
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass(frozen=True)
class Job:
    key: str
    script: str
    description: str
    required: bool = True


# Main figure-generation scripts.
# Order is manuscript/supplement order, not dependency order.
JOBS: list[Job] = [
    Job(
        key="Fig1G",
        script="plot_fig1G_behavioral_sensitivity.py",
        description="Generate Fig. 1G behavioral sensitivity panel.",
    ),
    Job(
        key="Fig3",
        script="plot_fig3_cp_timecourses.py",
        description="Generate Fig. 3 CP time courses and epoch aggregation.",
    ),
    Job(
        key="Fig4",
        script="plot_fig4_frequency_specific_decomposition.py",
        description="Generate Fig. 4 frequency-specific decomposition and reward-history panels.",
    ),
    Job(
        key="FigS1S3",
        script="plot_figS1S3_monkeywise_cp.py",
        description="Generate Supplementary Figs. S1-S3 monkey-wise CP traces.",
    ),
    Job(
        key="FigS5AB",
        script="plot_figS5AB_decoder_accuracy.py",
        description="Generate Supplementary Fig. S5A-B decoder accuracy panels.",
    ),
    Job(
        key="FigS8",
        script="plot_figS8_saline_control.py",
        description="Generate Supplementary Fig. S8 saline-control panel.",
    ),
]

# Optional verification scripts. These are run only if present.
OPTIONAL_JOBS: list[Job] = [
    Job(
        key="VerifyFig3S1S3",
        script="verify_fig3_S1S3_mean_sem.py",
        description="Verify Fig. 3 and Supplementary Figs. S1-S3 mean ± SEM values.",
        required=False,
    ),
]


def script_dir() -> Path:
    return Path(__file__).resolve().parent


def repo_root() -> Path:
    # run_all_figures.py lives in: <repo>/Code/figure_generation/
    return script_dir().parents[1]


def format_job_list(jobs: Iterable[Job]) -> str:
    lines = []
    for job in jobs:
        requirement = "required" if job.required else "optional"
        lines.append(f"  {job.key:<16} {job.script:<48} {requirement}  {job.description}")
    return "\n".join(lines)


def select_jobs(only: list[str] | None, skip: list[str] | None) -> list[Job]:
    all_jobs = JOBS + OPTIONAL_JOBS

    keys = {job.key for job in all_jobs}
    if only:
        bad = sorted(set(only).difference(keys))
        if bad:
            raise ValueError(f"Unknown --only job key(s): {bad}. Valid keys: {sorted(keys)}")
        selected = [job for job in all_jobs if job.key in set(only)]
    else:
        selected = list(all_jobs)

    if skip:
        bad = sorted(set(skip).difference(keys))
        if bad:
            raise ValueError(f"Unknown --skip job key(s): {bad}. Valid keys: {sorted(keys)}")
        selected = [job for job in selected if job.key not in set(skip)]

    return selected


def run_job(job: Job, continue_on_error: bool) -> tuple[str, bool]:
    path = script_dir() / job.script

    if not path.exists():
        if job.required:
            msg = f"[MISSING] {job.key}: required script not found: {path}"
            print(msg, file=sys.stderr)
            if not continue_on_error:
                raise FileNotFoundError(msg)
            return job.key, False

        print(f"[SKIP] {job.key}: optional script not found: {path}")
        return job.key, True

    print("\n" + "=" * 88)
    print(f"[RUN] {job.key}: {job.description}")
    print(f"      script: {path.name}")
    print("=" * 88)

    result = subprocess.run(
        [sys.executable, str(path)],
        cwd=str(script_dir()),
        text=True,
        capture_output=True,
    )

    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="" if result.stderr.endswith("\n") else "\n")

    if result.returncode != 0:
        print(f"[FAIL] {job.key}: exit code {result.returncode}", file=sys.stderr)
        if not continue_on_error:
            raise subprocess.CalledProcessError(result.returncode, [sys.executable, str(path)])
        return job.key, False

    print(f"[OK] {job.key}")
    return job.key, True


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run all figure-generation scripts for the LFP choice probability Zenodo release."
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available jobs and exit.",
    )
    parser.add_argument(
        "--only",
        nargs="+",
        default=None,
        help="Run only the selected job key(s), e.g. --only Fig3 Fig4.",
    )
    parser.add_argument(
        "--skip",
        nargs="+",
        default=None,
        help="Skip selected job key(s), e.g. --skip FigS8.",
    )
    parser.add_argument(
        "--continue-on-error",
        action="store_true",
        help="Continue running later jobs if one job fails.",
    )
    args = parser.parse_args()

    all_jobs = JOBS + OPTIONAL_JOBS

    if args.list:
        print("Available figure-generation jobs:\n")
        print(format_job_list(all_jobs))
        return

    selected = select_jobs(args.only, args.skip)

    print("LFP choice probability figure-generation runner")
    print(f"Repository root: {repo_root()}")
    print(f"Figure-generation folder: {script_dir()}")
    print(f"Python executable: {sys.executable}")
    print("\nSelected jobs:")
    print(format_job_list(selected))

    results: list[tuple[str, bool]] = []
    for job in selected:
        results.append(run_job(job, continue_on_error=args.continue_on_error))

    print("\n" + "=" * 88)
    print("Run summary")
    print("=" * 88)
    failed = []
    for key, ok in results:
        status = "OK" if ok else "FAILED"
        print(f"{key:<16} {status}")
        if not ok:
            failed.append(key)

    if failed:
        raise SystemExit(f"One or more jobs failed: {failed}")

    print("\nAll selected jobs completed successfully.")


if __name__ == "__main__":
    main()
