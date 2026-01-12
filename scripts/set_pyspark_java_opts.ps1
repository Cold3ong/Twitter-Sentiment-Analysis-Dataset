<#
Set recommended Java options for PySpark (for current session only, non-persistent)
Usage:
  pwsh.exe -File .\scripts\set_pyspark_java_opts.ps1
  # or persist manually if required
#>

Write-Host "Configuring recommended PySpark Java options for the current PowerShell session..." -ForegroundColor Cyan

# Example extraJavaOptions for Spark that can help with modularity (Java 9+ accessibility issues)
$extra = "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED"

# For local testing with pip-installed pyspark (pyspark wheel), set PYSPARK_SUBMIT_ARGS
$submit = "--conf spark.driver.extraJavaOptions=\"$extra\" --conf spark.executor.extraJavaOptions=\"$extra\" pyspark-shell"

# Apply to session
$env:PYSPARK_SUBMIT_ARGS = $submit
Write-Host "Set PYSPARK_SUBMIT_ARGS for the session. Current value:" -ForegroundColor Green
Write-Host $env:PYSPARK_SUBMIT_ARGS

# Print reminder
Write-Host "Reminder: If you're running spark in a separate service, ensure that the service process receives these java options as well (or is launched with matching options)." -ForegroundColor Yellow
Write-Host "To persist for all future sessions you can add the above line to your user profile or set via setx (not done here to avoid accidental PATH modification)." -ForegroundColor Yellow
