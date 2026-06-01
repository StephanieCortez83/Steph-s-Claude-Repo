# Connect to Microsoft Graph API
Connect-MgGraph -Scopes "User.Read.All"
Select-MgProfile Beta

$LogDate = Get-Date -f yyyyMMddhhmm
$SqlFile = "C:\temp\UpdateUserProfileSetSsoExternalIdentifier_$LogDate.sql"

Function Get-AllMgUsers {    
    begin{
        $sqlScript   = "USE [RevCycleDb]`n"
        $sqlScript  += "GO`n`n"
        $sqlScript  += "BEGIN TRY`n"
        $sqlScript  += "`tBEGIN TRAN`n"
    }
    process {
        $users = Get-MgUser -All
        $totalUsers = $users.Count

        $progress = 0
        foreach ($index in 0..($totalUsers - 1)) {
            $user = $users[$index]
            $progress++
            $percentComplete = ($progress / $totalUsers) * 100
            $progressParams = @{
                Activity        = "Processing Users"
                Status          = "User $($index + 1) of $totalUsers - $($user.userPrincipalName) - $($percentComplete -as [int])% Complete"
                PercentComplete = $percentComplete
            }
            Write-Progress @progressParams
            
            $sqlScript += "`t`tUPDATE [USER_PROFILE] SET [USER_PROFILE].[SSO_EXTERNAL_IDENTIFIER] = '$($user.Id)' WHERE [USER_PROFILE].[EMAIL_ADDRESS] = '$($user.Mail)'`n"
        }
    }
    end{
        $sqlScript  += "`tCOMMIT TRAN`n"
        $sqlScript  += "END TRY`n"
        $sqlScript  += "BEGIN CATCH`n"
        $sqlScript  += "`tPRINT 'ERROR :: ' + ERROR_MESSAGE()`n"
        $sqlScript  += "`tPRINT 'Rolling back transaction'`n"
        $sqlScript  += "`tIF (@@TRANCOUNT > 0)`n"
        $sqlScript  += "`t`tROLLBACK TRAN`n"
        $sqlScript  += "END CATCH"
        
        $sqlScript  | Out-File -FilePath $SqlFile
    }
}

Get-AllMgUsers