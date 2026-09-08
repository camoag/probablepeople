#!/usr/bin/env bash
#
# Re-train the CRF models, overwriting the committed .crfsuite files.
#
# Training iterates a Python set, so the resulting model depends on PYTHONHASHSEED.
# Always train with a fixed seed, or every run produces a different model.
#
# Usage: ./train_models.sh [hash-seed]     (default: 1, what the committed models use)

set -euo pipefail

hash_seed="${1:-1}"

cd "$(dirname "$0")"

if ! command -v parserator >/dev/null 2>&1; then
    echo "parserator not found. Install the dev extras first:" >&2
    echo "    pip install '.[dev]'" >&2
    exit 1
fi

export PYTHONHASHSEED="$hash_seed"
export PYTHONPATH=".${PYTHONPATH:+:$PYTHONPATH}"

echo "Training with PYTHONHASHSEED=$hash_seed"

parserator train \
    name_data/labeled/person_labeled.xml,name_data/labeled/company_labeled.xml \
    probablepeople --modelfile=generic
parserator train name_data/labeled/person_labeled.xml probablepeople --modelfile=person
parserator train name_data/labeled/company_labeled.xml probablepeople --modelfile=company

# parserator also writes a timestamped copy of each model; keep only the canonical files.
rm -f probablepeople/*_settings_[0-9]*.crfsuite

echo
echo "Model fingerprints (sha256, first 16):"
python -c "
import hashlib
import pathlib

for path in sorted(pathlib.Path('probablepeople').glob('*.crfsuite')):
    print(f'  {hashlib.sha256(path.read_bytes()).hexdigest()[:16]}  {path.name}')
"
