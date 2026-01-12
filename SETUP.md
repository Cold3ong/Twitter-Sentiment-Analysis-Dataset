# Environment Setup — reproducible & Windows-friendly

This project is tested with Python 3.10 and PySpark 3.5.7.
To avoid ABI mismatches with compiled libraries (numpy, pandas, pyarrow), use a clean environment (conda is recommended on Windows).

Recommended (conda / conda-forge):

```powershell
# Create a conda environment with common compiled libs from conda-forge
conda create -n bigdata python=3.10 -c conda-forge -y
conda activate bigdata

# Install compiled libs from conda-forge (good for Windows compatibility) and kernel support
conda install -c conda-forge -y openjdk=17 numpy=1.24.4 pandas=2.1.3 pyarrow=11.0.0 matplotlib seaborn ipykernel

# Install PySpark and Python-only libraries with pip
pip install pyspark==3.5.7 sentence-transformers==2.2.2 vaderSentiment==3.3.2 gensim==4.3.1 scikit-learn==1.2.2

# (Optional) Add the environment to Jupyter kernels
python -m ipykernel install --user --name bigdata --display-name "bigdata (PySpark 3.5.7)"
```

Alternative (venv + pip):

```powershell
python -m venv .venv310
.\.venv310\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
python -m ipykernel install --user --name bigdata-venv --display-name "bigdata-venv (PySpark 3.5.7)"
```

Important notes:
- If you change numpy/pandas/pyarrow after the kernel is running, **restart the kernel**. Compiled wheels import C extensions and cannot be reliably hot-swapped.
- If you encounter errors like **ImportError: numpy.dtype size changed**, or **RuntimeError: module compiled against API version X but this version Y**, recreate your environment from scratch and install pinned versions.
- For Windows and writing Parquet locally, ensure `HADOOP_HOME` points to a Windows-friendly Hadoop/bin (with `winutils.exe`) if you use the local Spark binary that expects it. If you are only using PySpark with local mode and pip wheels, writing Parquet should generally work without `HADOOP_HOME`, but some situations require native libs.
 
Python 3.13 caveat:
- If you are using a system-wide Python 3.13 interpreter, you may encounter a build-time error with some build-time tooling when pip tries to build compiled libraries from source. The error commonly looks like:

```
AttributeError: module 'pkgutil' has no attribute 'ImpImporter'. Did you mean: 'zipimporter'?
```

This indicates that a build-time plugin (setuptools/pkg_resources) expects Python internals that changed in 3.13 and was invoked by the build environment. Solutions:

- Use `conda` to create a Python 3.10 environment (recommended) — the `environment.yml` included here will create one with compiled binaries from conda-forge.
- Use the Python Launcher on Windows to target Python 3.10 when creating a venv: `py -3.10 -m venv .venv310`
- When using pip, prefer binary wheels and avoid `pip` building from source: `python -m pip install --prefer-binary -r requirements.txt` or `pip install --only-binary=:all: numpy==1.24.4`.

Check the interpreter used by `pip`:

```powershell
# Shows which python and pip are used in current shell
python -V
python -m pip -V
which pip  # or (Get-Command pip).Path in PS
```

If the pip you're invoking resolves to Python 3.13 (or a different Python than 3.10), make sure you activate the intended venv or use `py -3.10 -m pip` to install into Python 3.10.
- Java: PySpark requires Java (OpenJDK) with a compatible `JAVA_HOME` set (OpenJDK 17 is recommended for Spark 3.4/3.5 and above). If you get JVM errors, check `java -version` and set `JAVA_HOME` accordingly.

VSCode users: ensure your selected Python interpreter matches the environment you created (bottom-right in VSCode). If you install packages into `.venv310`, also select the `.venv310` interpreter in VSCode and restart the kernel for notebooks.

Troubleshooting common issues:
- If `pandas` or `pyarrow` fails to import after a `pip install` or `pip upgrade`, run the following steps in a shell and restart the kernel:

```powershell
pip uninstall -y numpy pandas pyarrow
pip cache purge
pip install -r requirements.txt
```

- If that still fails, **recreate** the environment using `conda` or remove and create a new virtualenv and reinstall pinned versions.

If pip tries to build numpy from source (error like "Failed to build wheel for numpy"), try the following sequence in PowerShell (target Python 3.10 explicitly to avoid system Python 3.13):

```powershell
# Confirm Python and pip point to Python 3.10
python -V
python -m pip -V

# If these show Python 3.13 or another Python, run pip with the Python Launcher for 3.10
py -3.10 -m pip install --upgrade pip setuptools wheel

# Install binary wheels first to avoid building from source
py -3.10 -m pip install --only-binary=:all: numpy==1.24.4 pandas==2.1.3 pyarrow==11.0.0

# Then install the remaining requirements (prefer binary wheels when available)
py -3.10 -m pip install --prefer-binary -r requirements.txt
```

Note: Use `--only-binary=:all:` only for compiled packages you know have binary wheels for your Python version and platform (we recommend Python 3.10). If a package is not available as a prebuilt wheel for Python 3.10, prefer conda which provides compiled wheels from conda-forge.

If you see an error saying "A module that was compiled using NumPy 1.x cannot be run in NumPy 2.x", the module you're importing was compiled against NumPy 1.x and is not compatible with NumPy 2.x. You can either downgrade NumPy (recommended for now) or update/rebuild the module to use a toolchain compatible with NumPy 2.x.

Downgrade steps (Option B venv path):

```powershell
# Confirm the active interpreter uses Python 3.10; if not, activate a Python 3.10 venv or use `py -3.10`
py -3.10 -m pip uninstall -y numpy pandas pyarrow
py -3.10 -m pip install --only-binary=:all: numpy==1.24.4 pandas==2.1.3 pyarrow==11.0.0
py -3.10 -m pip install --prefer-binary -r requirements.txt
```

If you prefer to keep NumPy 2.x and the failing module must support NumPy 2.x, you (or the module maintainer) must rebuild the extension against NumPy 2.0+ (for example using pybind11 >= 2.12 to support both NumPy 1.x and 2.x builds). That often requires an update from the package maintainer and ships as a new wheel; the end user will need to install those updated wheels.

If you would like, I can add an `environment.yml` for `conda` which will create the environment for you (already included), or add a `make_env.ps1` PowerShell script to automate the setup.
