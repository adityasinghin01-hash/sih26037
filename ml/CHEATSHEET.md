# ML cheat sheet — every command, in order

`DATA` is a folder **outside the repo**. `~/meteor-data` is fine.
Run everything from the **repository root**.

## Once
```bash
pip install torch numpy onnx onnxruntime onnxscript      # onnxscript is NOT optional
export DATA=~/meteor-data
```

## The pipeline
```bash
# 1  get the data                                  1.81 GB down, 10.28 GB on disk
python3 ml/python/meteor/fetch_annotations.py --out $DATA

# 2  which label?  -> apply Decision 2 in ReadThis.md
python3 ml/python/meteor/check_balance.py --data $DATA --clips 1251 --every 10

# 3  build features       --force after ANY change to features.py / parse_xml.py / the label
python3 ml/python/meteor/build_dataset.py --data $DATA --out $DATA/features \
        --label <yield|assert> --force

# 4  split BY CLIP
python3 ml/python/meteor/split.py --features $DATA/features --val-frac 0.25

# 5  train both
python3 ml/python/model/train.py --features $DATA/features --model lstm      --epochs 20
python3 ml/python/model/train.py --features $DATA/features --model attention --epochs 20

# 6  may it go to MATLAB?   stop here if it says NOT READY
python3 ml/python/model/evaluate.py --features $DATA/features \
        --model $DATA/features/yield_lstm.pt

# 7  export     ONCE PER CHECKPOINT. no --opset flag, on purpose
python3 ml/python/export/to_onnx.py --model $DATA/features/yield_lstm.pt
python3 ml/python/export/to_onnx.py --model $DATA/features/yield_attention.pt
```

## Tests — run before every push
```bash
python3 ml/python/tests/test_contract.py     # the 31-feature contract
python3 ml/python/tests/test_parity.py       # regenerates the parity fixture
python3 ml/python/tests/test_metrics.py      # the evaluation maths itself
```

## In MATLAB
```matlab
check01_environment                          % products and BOTH add-ons
check04_onnx_lstm                            % read for PLACEHOLDER, not for "succeeded"
runtests('matlab/tests/testFeatureParity.m')   % after any features.py change
runtests('matlab/tests')                     % everything
```

## Ask your AI for
```
/first-run     the MATLAB that has never been run.  DO THIS FIRST
/ml-run        the whole pipeline for models 1 and 2
/ml-parity     the two feature builders must agree
/ml-models     models 3, 4 and 5 (YOLOX, DeepLab, PointPillars)
```

## Numbers to know
| | |
|---|---|
| Clips in METEOR | **1,251** (2,502 XML files) |
| Download / on disk | **1.81 GB / 10.28 GB** |
| Feature vector | **31**, positions frozen |
| Sequence length | **20** frames at 10 Hz |
| `yield` rate | 1 in 581 — too rare |
| `assert` rate | 1 in 14 |
| Model sizes | 25,090 and 58,434 parameters |
| Opsets written | **17, 18, 20** |

## Never
Invent a number · report accuracy alone · split by frame · reorder features 1–31 ·
rebuild without `--force` · commit data or models · edit `matlab/baseline/` or
`AGENTS.md` section 3 · summarise an error · tune until a safety check goes green
