<# Check environment and compiled packages versions for Option B venv-based setup

Usage:
  PowerShell> .\check_env.ps1
#>

param(
    [string] $PythonExec = '',
    [switch] $ShowAll,
    [switch] $InstallPlotting
)

function _Write($m) { Write-Host $m }

if (-not $PythonExec) {
    # Default to 'py -3.10' on Windows to target Python 3.10
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $PythonExeName = 'py'
        $PythonArgs = '-3.10'
    } else {
        $PythonExeName = 'python'
        $PythonArgs = ''
    }
} else {
        # If the user passed a value like 'py -3.10', a bare 'python', or a path to an exe
        $parts = $PythonExec -split '\s+' | Where-Object {$_ -ne ''}
        # If the user passed a full path that ends with python.exe, prefer that as the exe name and don't split the path based on spaces
        if ($PythonExec -match '\.exe$') {
            # If there are spaces in the path, the split above will have broken it. Use the raw string instead.
            $PythonExeName = $PythonExec
            $PythonArgs = ''
        } else {
        # If the first token looks like a Windows path or ends with .exe and the path contains spaces,
        # reconstruct the path if it got split by spaces (e.g., 'C:\Path With Spaces\python.exe')
        if ($parts[0] -match '^[A-Za-z]:\\' -or $parts[0] -match '\.exe$') {
            # find index of token that likely ends the path (ends with .exe)
            $endIdx = -1
            for ($i = 0; $i -lt $parts.Count; $i++) { if ($parts[$i] -match '\.exe$') { $endIdx = $i; break } }
            if ($endIdx -ge 0) {
                $PythonExeName = ($parts[0..$endIdx] -join ' ')
                $PythonArgs = if ($parts.Count -gt ($endIdx + 1)) { ($parts[($endIdx + 1)..($parts.Count - 1)] -join ' ') } else { '' }
            } else {
                # fallback: no .exe token found; keep first token as exe name and rest as args
                $PythonExeName = $parts[0]
                $PythonArgs = if ($parts.Count -gt 1) { ($parts[1..($parts.Count - 1)] -join ' ') } else { '' }
            }
        } else {
            $PythonExeName = $parts[0]
            $PythonArgs = if ($parts.Count -gt 1) { ($parts[1..($parts.Count - 1)] -join ' ') } else { '' }
        }
        }
    }

_Write("Using: $PythonExeName $PythonArgs")

# Basic checks
if ($PythonArgs -ne $null -and $PythonArgs -ne '') {
    & "$PythonExeName" $PythonArgs -V
    & "$PythonExeName" $PythonArgs -m pip --version
} else {
    & "$PythonExeName" -V
    & "$PythonExeName" -m pip --version
}

$pkgs = @('numpy','pandas','pyarrow','pyspark','matplotlib','seaborn')
foreach ($p in $pkgs) {
    Write-Host "--- Checking $p ---"
    try {
        # print metadata via pip to avoid import if it may crash
        if ($PythonArgs -ne $null -and $PythonArgs -ne '') {
            & "$PythonExeName" $PythonArgs -m pip show $p | Out-Host
        } else {
            & "$PythonExeName" -m pip show $p | Out-Host
        }
        # try to gently import if user requests
            if ($ShowAll) {
                        try {
                        if ($PythonArgs -ne $null -and $PythonArgs -ne '') {
                            & "$PythonExeName" $PythonArgs -c "import importlib; m=importlib.import_module('$p'); print('OK import', getattr(m,'__version__',str(m)))" 2>&1 | Out-Host
                        } else {
                            & "$PythonExeName" -c "import importlib; m=importlib.import_module('$p'); print('OK import', getattr(m,'__version__',str(m)))" 2>&1 | Out-Host
                        }
                    } catch {
                    Write-Host "Could not import ${p}: $_"
                    # If user asked to auto-install plotting libs (safe pure-Python wheels in many platforms), do it for matplotlib/seaborn
                    if ($InstallPlotting -and ($p -in @('matplotlib', 'seaborn'))) {
                        Write-Host "Attempting to install ${p} into: $PythonExeName $PythonArgs"
                        try {
                            if ($PythonArgs -ne $null -and $PythonArgs -ne '') {
                                & "$PythonExeName" $PythonArgs -m pip install --upgrade pip setuptools wheel --prefer-binary | Out-Host
                                & "$PythonExeName" $PythonArgs -m pip install --prefer-binary ${p} | Out-Host
                            } else {
                                & "$PythonExeName" -m pip install --upgrade pip setuptools wheel --prefer-binary | Out-Host
                                & "$PythonExeName" -m pip install --prefer-binary ${p} | Out-Host
                            }
                            Write-Host "Installed ${p}; re-checking import..."
                            if ($PythonArgs -ne $null -and $PythonArgs -ne '') {
                                if ($PythonArgs -ne $null -and $PythonArgs -ne '') {
                                    & "$PythonExeName" $PythonArgs -c "import importlib; importlib.import_module('${p}'); print('${p} installed OK')" 2>&1 | Out-Host
                                } else {
                                    & "$PythonExeName" -c "import importlib; importlib.import_module('${p}'); print('${p} installed OK')" 2>&1 | Out-Host
                                }
                            } else {
                                & "$PythonExeName" -c "import importlib; importlib.import_module('${p}'); print('${p} installed OK')" 2>&1 | Out-Host
                            }
                        } catch {
                            Write-Host "Auto-install of ${p} failed: $_"
                        }
                    }
                }
        }
    } catch {
        Write-Host "Package ${p} not installed or pip error: $_"
    }
}

# Hint for py -3.10 usage
if ($InstallPlotting) {
    Write-Host "Running with -InstallPlotting: missing plotting libs will be installed into the chosen interpreter."
}
Write-Host "\nRecommendation: use 'py -3.10' to activate venv/Python 3.10 and run the 'make_env.ps1' script, or use conda for compiled libs."