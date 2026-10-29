"""Check installed data and execute one bundled genome as a non-root user.

This is a runtime smoke test, not validation of typing accuracy.
"""
from importlib.resources import files
from pathlib import Path
import subprocess
import tempfile
import zipfile

import pyhmmer
import pyrodigal
import pandas
import joblib
import clinker

subprocess.run(["python", "-m", "pip", "check"], check=True)
subprocess.run(["ktypr", "--help"], check=True)
data = files("ktypr").joinpath("data")
assert any(p.name.endswith(".hmm") for p in data.joinpath("hmms").iterdir()), "Missing HMMs"
assert any(p.name.endswith(".tsv") for p in data.iterdir()), "Missing tables"
with zipfile.ZipFile(str(data.joinpath("reference_clusters.zip"))) as archive:
    assert archive.testzip() is None, "Corrupt reference archive"

samples = sorted(
    p for p in Path("/opt/ktypr-source/test/genomes/fasta").rglob("*")
    if p.is_file() and p.suffix.lower() in {".fa", ".fna", ".fasta"}
)
assert samples, "Upstream test FASTA not found; review its test directory layout"
with tempfile.TemporaryDirectory(prefix="ktypr-smoke-") as tmp:
    out = Path(tmp) / "results"
    subprocess.run(
        ["ktypr", "-i", str(samples[0]), "-o", str(out), "-n", "1"],
        cwd=tmp, check=True, timeout=600,
    )
    outputs = list(out.rglob("*_ktypr.tsv"))
    assert outputs and all(p.stat().st_size for p in outputs), "Missing prediction output"
    print("Smoke test passed:", samples[0].name)
