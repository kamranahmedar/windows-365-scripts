#DETECTION-SCRIPT
# ==============================
# Detection: Valid RDP cert exists?
# Checks LocalMachine\Remote Desktop store for any cert not expired
# Exit 0 = OK (no remediation)
# Exit 1 = Missing/expired (run remediation)
# ==============================
$ErrorActionPreference = "Stop"
try {
    $now = Get-Date
    $validCert = Get-ChildItem 'Cert:\LocalMachine\RemoteDesktop\' -ErrorAction SilentlyContinue |
        Where-Object { $_.NotAfter -gt $now.AddDays(-10) } |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1
    if ($null -ne $validCert) {
        Write-Output ("OK: Valid RDP cert found. Thumbprint={0}, NotAfter={1}" -f $validCert.Thumbprint, $validCert.NotAfter)
        exit 0
    }
    Write-Output "NOT OK: No valid RDP cert in LocalMachine\Remote Desktop store."
    exit 1
}
catch {
    Write-Output ("Detection error: {0}" -f $_.Exception.Message)
    exit 1
}