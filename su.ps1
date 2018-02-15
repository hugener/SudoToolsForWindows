function Execute-Command ($commandPath, $commandArguments)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $commandArguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null

    [pscustomobject]@{
        stdout = $p.StandardOutput.ReadToEnd()
        stderr = $p.StandardError.ReadToEnd()
        ExitCode = $p.ExitCode  
    }
    $p.WaitForExit()
}

$verb = $args[0]
$skip = 0
if ($verb -eq "-f")
{
    $skip = 1
    $isAdminSet = $true
}
else
{
    $regex = New-Object System.Text.RegularExpressions.Regex('Account active *(?<IsActive>\w+)', [System.Text.RegularExpressions.RegexOptions] "MultiLine, IgnoreCase")
    $adminAccountState = Execute-Command "net" "user administrator" 
    $match = $regex.Match($adminAccountState.stdout)
    $isAdminSet = !$match.Value.Contains("No")
}

if ($verb -eq "-s")
{
	Write-Host "Force set up"
	$isAdminSet = $false
}

if (!$isAdminSet)
{
	Write-Host "Admin not set"

	$activeAdminAccountResult = Execute-Command "net" "user administrator /active:yes"
    $password = Read-Host -AsSecureString "Enter password"
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    $passwordConfirmation = Read-Host -AsSecureString "Confirm password"
    $passwordConfirmation = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordConfirmation))
    if ($password -eq $passwordConfirmation)
    {
        $activeAdminAccountResult = Execute-Command "net" "user administrator $password"
        if ($activeAdminAccountResult.ExitCode -eq 0)
        {
            Write-Host "Password set"
        }
        else
        {
            Write-Host "Password not set"
        }
    }
    else
    {
        Write-Host "Password missmatch"
    }
}
else
{
    $commandLine = $args | Select-Object -Skip $skip;
	Start-Process -FilePath "runas" -ArgumentList "/user:administrator /savecred ""$commandLine""" -NoNewWindow -Wait
}

