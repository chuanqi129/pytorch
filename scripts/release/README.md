# PyTorch release scripts performing branch cut and applying release only changes

These are a collection of scripts that are to be used for release activities.

> NOTE: All scripts should do no actual work unless the `DRY_RUN` environment variable is set
>       to `disabled`.
>       The basic idea being that there should be no potential to do anything dangerous unless
>       `DRY_RUN` is explicitly set to `disabled`.

### Order of Execution

1. Run cut-release-branch.sh to cut the release branch
2. Run apply-release-changes.sh to apply release only changes to create a PR with release only changes similar to this [PR](https://github.com/pytorch/pytorch/pull/149056)

#### XPU dependency selection

`third_party/xpu.txt` contains a full torch-xpu-ops commit SHA on main.
Before applying release-only changes, create `intel/torch-xpu-ops`'s
`release/X.Y` branch from the XPU commit pinned at the PyTorch branch cut.
`apply-release-changes.sh` checks that this branch exists and replaces the pin
with `refs/heads/release/X.Y`. Patch releases continue to use the same branch.

XPU builds fetch and resolve that branch each time CMake configures, then check
out the resolved commit directly. This also works for detached HEAD, release
tags, and PR checkouts because selection is based on the file, not the current
Git branch. A failed fetch is an error; it does not fall back to an old checkout.
An incremental build that does not reconfigure will keep its existing checkout.
Updates to torch-xpu-ops alone do not trigger PyTorch CI; trigger release
validation after merging dependency fixes.

For reproducible builds, set `TORCH_XPU_OPS_COMMIT` to a full SHA before building.
It overrides the file and is forwarded to the CMake cache. To resume branch
tracking in a reused build directory, explicitly clear the cached override
with `-Ccmake.define.TORCH_XPU_OPS_COMMIT=` when invoking pip. Merely unsetting
the environment variable does not clear the cache.

The configure log reports the selected ref and SHA, and
`<build-directory>/caffe2/torch-xpu-ops-commit.txt` records the SHA.
Archive this file with release artifacts and use its
SHA to reproduce a build, including builds from release tags.

For a release build matrix, resolve the branch once before starting the jobs
and pass the same `TORCH_XPU_OPS_COMMIT` to each job, including retries. Wiring
this shared resolution and artifact archival into release CI is a follow-up to
the draft build-side implementation.

#### Promoting packages

 Scripts for Promotion of PyTorch packages are under test-infra repository. Please follow [README.md](https://github.com/pytorch/test-infra/blob/main/release/README.md)
