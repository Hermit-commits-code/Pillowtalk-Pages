# switch_default_branch.ps1
# Usage: run in PowerShell (it will prompt for a PAT with repo/admin scope)
# This script will:
# 1) Create a remote backup branch old-main-backup from origin/main
# 2) Set default_branch to cleaned-main
# 3) Delete remote main
# It requires that you have network access and are an admin on the repo.

param()

$owner = "Hermit-commits-code"
$repo = "Spicy-Reads"
$baseUri = "https://api.github.com/repos/$owner/$repo"

Write-Host "This script will change the default branch to 'cleaned-main' and delete 'main' from remote."
$confirm = Read-Host "Type YES to continue"
if ($confirm -ne 'YES') {
    Write-Host "Aborting. You must type YES to proceed."; exit 1
}

# Read token securely
$secureToken = Read-Host -Prompt "Paste your GitHub Personal Access Token (repo/admin)" -AsSecureString
# Convert SecureString to plain text for use in headers
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

$headers = @{ Authorization = "token $token"; Accept = "application/vnd.github+json" }

try {
    Write-Host "Getting remote 'main' ref..."
    $mainRef = Invoke-RestMethod -Uri "$baseUri/git/refs/heads/main" -Headers $headers -ErrorAction Stop
    $sha = $mainRef.object.sha
    Write-Host "main SHA: $sha"
} catch {
    Write-Error "Failed to read remote main ref. Ensure 'main' exists and your token has rights. $_"; exit 1
}

# Create backup branch
$backupRef = @{ ref = "refs/heads/old-main-backup"; sha = $sha } | ConvertTo-Json
try {
    Write-Host "Creating remote backup branch 'old-main-backup'..."
    Invoke-RestMethod -Method Post -Uri "$baseUri/git/refs" -Headers $headers -Body $backupRef -ContentType "application/json" -ErrorAction Stop
    Write-Host "Created 'old-main-backup'"
} catch {
    Write-Warning "Could not create 'old-main-backup'. It might already exist. Continuing..."
}

# Set default branch to cleaned-main
$patch = @{ default_branch = "cleaned-main" } | ConvertTo-Json
try {
    Write-Host "Setting default branch to 'cleaned-main'..."
    Invoke-RestMethod -Method Patch -Uri $baseUri -Headers $headers -Body $patch -ContentType "application/json" -ErrorAction Stop
    Write-Host "Default branch updated to 'cleaned-main'"
} catch {
    Write-Error "Failed to set default branch. $_"; exit 1
}

# Delete remote main
try {
    Write-Host "Deleting remote 'main'..."
    Invoke-RestMethod -Method Delete -Uri "$baseUri/git/refs/heads/main" -Headers $headers -ErrorAction Stop
    Write-Host "Deleted remote 'main'"
} catch {
    Write-Error "Failed to delete remote main. $_"; exit 1
}

Write-Host "All done. Please re-apply branch protections if needed and inform collaborators to update their clones."

# zero-out token variable
$token = $null
Remove-Variable -Name secureToken -ErrorAction SilentlyContinue

exit 0
