S1 failed before project code ran, so I stopped and did not attempt S3 or `Sensed=true`, per instructions.

Full output:

```text
Incompatible processor. This Qt build requires the following features:
    neon
Could not create on-disk crash report: failed opening file: Operation not permitted: unspecified iostream_category error

MATLAB is exiting because of fatal error
time: command terminated abnormally
real 1.62
user 0.53
sys 0.26
time: signal: Invalid argument
```

Exit code: `1`. No results folder was created; all requested metrics and clearance claims remain `TODO(unverified)`.

Full report: [CODEX_JOB_03_OUTPUT.md](https://github.com/adityasinghin01-hash/sih26037/blob/main/CODEX_JOB_03_OUTPUT.md)