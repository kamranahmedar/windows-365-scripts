#REMEDIATION-SCRIPT
# ==============================

# Regenerate and Bind RDP Certificate

# Tested for Cloud PC / RDS / AVD

# Run as SYSTEM (Intune)

# ==============================

$ErrorActionPreference = "Stop"

try {

    Write-Output "Starting RDP certificate regeneration..."

    # Set DNS name (use computer name if unsure)

    $DnsName = $env:COMPUTERNAME
 
    # Create self-signed certificate in LocalMachine\RemoteDesktop

    $cert = New-SelfSignedCertificate `

        -DnsName $DnsName `

        -CertStoreLocation "Cert:\LocalMachine\My" `

        -KeySpec KeyExchange `

        -NotAfter (Get-Date).AddYears(2)

    if (-not $cert) {

        throw "Failed to create self-signed certificate"

    }

    $rdStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Remote Desktop","LocalMachine")

    $rdStore.Open("ReadWrite")

    $rdStore.Add($cert)

    $rdStore.Close()

    $thumbprint = $cert.Thumbprint

    $cert | Remove-Item

    Write-Output "Certificate created successfully"

    Write-Output "Thumbprint: $thumbprint"

    # Bind certificate to RDP service

    Write-Output "Binding certificate to RDP listener..."

    wmic /namespace:\\root\cimv2\TerminalServices `

        PATH Win32_TSGeneralSetting `

        Set SSLCertificateSHA1Hash="$thumbprint" | Out-Null

    # Restart RDP service to force reload

    Write-Output "Restarting Remote Desktop Services..."

    Restart-Service TermService -Force

    Write-Output "RDP certificate regeneration and binding completed successfully"

}

catch {

    Write-Error "RDP certificate remediation failed: $_"

    exit 1

}
 
9:57 AM Meeting ended: 2h 24m 17s 

 
