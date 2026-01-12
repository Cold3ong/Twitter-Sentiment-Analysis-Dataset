$ErrorActionPreference = "Stop"

$pysparkJars = "C:\Users\swkan\Downloads\VSCode\Big Data Group Project\.venv310\Lib\site-packages\pyspark\jars"
$cutoffDate = Get-Date "2025-11-20 12:00"

Write-Host "Cleaning up old PySpark JARs in $pysparkJars..."

# Get files older than the cutoff (the 11:55 ones)
$oldJars = Get-ChildItem $pysparkJars | Where-Object { $_.LastWriteTime -lt $cutoffDate }

if ($oldJars) {
    Write-Host "Found $($oldJars.Count) old JAR files."
    foreach ($jar in $oldJars) {
        try {
            Remove-Item -Path $jar.FullName -Force
            Write-Host "Deleted: $($jar.Name)"
        } catch {
            Write-Host "Failed to delete $($jar.Name): $_" -ForegroundColor Red
            Write-Host "Please close any running Python processes (including VS Code Notebook kernels) and try again." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "No old JARs found."
}

Write-Host "Cleanup complete."
