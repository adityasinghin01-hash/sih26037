# Check 6 — questions for whoever runs the DGX A100

Answer these exactly. Guesses are worse than blanks.

## Disk — the one that can kill the plan
1. How much **free** disk is on the machine right now? (`df -h`)
2. Is there a **per-user quota**? What is it? (`quota -s`)
3. Where should large datasets live — home, scratch, or a shared data mount?
4. Is scratch **wiped** on a schedule? How often?

> We need **~190 GB free at peak** for METEOR alone (93 GB of chunks + 93 GB
> reassembled, before extraction). Total dataset need is roughly **295 GB**.

## Internet
5. Does the **compute node itself** have outbound internet, or only the login node?
6. Is HuggingFace reachable? Test: `curl -I https://huggingface.co`
7. Is there a proxy to configure? Which environment variables?

## Access and booking
8. How do we book GPU time — queue system (Slurm?), calendar, or ad hoc?
9. Maximum job length? Maximum GPUs per user?
10. Can we get an **interactive** session, or batch jobs only?
11. Who approves accounts, and how long does approval take?

## Software
12. Python version available? Is conda or module-load available?
13. Can we install packages ourselves (`pip install --user`), or is it locked?
14. Is Docker or Singularity/Apptainer available?

## Answer format
Paste the raw command output. Do not summarise.
