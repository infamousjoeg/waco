##########################################
### IMPORT PS MODULES
Import-Module .\modules\pspete\psPAS
Import-Module .\modules\pspete\CredentialRetriever
Import-Module ActiveDirectory

##########################################
### RECEIVE USER INPUT

Write-Host "`r`n===============================" -ForegroundColor Yellow
Write-Host "CyberArk Account Factory" -ForegroundColor Yellow
Write-Host "===============================`r`n" -ForegroundColor Yellow

# DO: Keep asking for AD or Local
# UNTIL: A or L is chosen
do { $acctScope = Read-Host "Create a [A]ctive Directory User or [L]ocal User?" }
while ( $acctScope -notlike "L" -and $acctScope -notlike "A")

# Ask for Configuration ID from CMDB of Application
# This is a situational value -- only uncomment below if this is necessary for automation
#$cmdbConfigId = Read-Host "Enter the CMDB Configuration/Application ID"

# Ask for Account Owner ID
$accountOwnerId = Read-Host "Enter the ID of the Account Owner"

##########################################
### VARIABLES

$baseURI = "https://components.cyberarkdemo.com/"
$acctUsername = Read-Host "Enter the desired Username"
$acctDescription = Read-Host "Enter the account description"

##########################################
### RANDOMIZE & SECURE ACCOUNT PASSWORD
Add-Type -AssemblyName System.Web
$acctSecurePassword = ConvertTo-SecureString ([System.Web.Security.Membership]::GeneratePassword(20,10)) -AsPlainText -Force

##########################################
### CREATE AD OR LOCAL USER AND GRANT PRIVILEGED ENTITLEMENTS

function Show-Menu 
{ 
	 param ( 
		   [string]$Title = 'Group Membership Menu' 
	 ) 
	 Clear-Host 
	 Write-Host "================ $Title ================" 
	 
	 Write-Host "A: Press 'a' to add Account to Group." 
	 Write-Host "Q: Press 'q' to quit adding Account to Group(s)." 
} 

switch($acctScope)
{
    # Case 2: Local User selected
    l {
        $acctAddress = (Get-NetIPAddress -InterfaceIndex 12 -AddressFamily IPv4).IPv4Address
        $acctLogonTo = $env:COMPUTERNAME
        
        try {
            New-LocalUser $acctUsername -Password $acctSecurePassword `
                -FullName $acctUsername -Description "${acctDescription}" `
                -ErrorAction Stop | Out-Null

            Write-Output "`r`nAccount created successfully in local Users group."

            Add-LocalGroupMember -Group "Administrators" -Member $acctUsername -ErrorAction Stop

            Write-Output "`r`nAccount added to local Administrators group successfully."
        } catch {
            Write-Output "`r`nThere was an error creating the local user account. $($PSItem.ToString())"
            Write-Host -NoNewLine "`r`nPress any key to continue..." -ForegroundColor Cyan
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            Exit
        }
    }
    # Case 1: Active Directory User selected
    a {
        $acctAddress = Read-Host "Enter the Domain where you would like to create the Account (i.e. cyberarkdemo.com)"
		$acctPath = Read-Host "Enter the OU Path where you would like to create the Account (i.e. OU=Service Accounts,OU=CyberArk,DC=cyberarkdemo,DC=com)"
        
        # Creation of new AD User -- Be sure to update the Path argument for where you keep
        #   your Service Accounts in AD. Typically, a Group Policy Object (GPO) is set to the
        #   Service Accounts Organizational Unit (OU) to prevent interactive logons.
        try {            
            New-ADUser -Name $acctUsername -AccountPassword $acctSecurePassword -ChangePasswordAtLogon $false `
                -Description $acctDescription -DisplayName $acctUsername `
                -Enabled $true -SamAccountName $acctUsername -UserPrincipalName "${acctUsername}@${acctAddress}" `
                -Path $acctPath -ErrorAction Stop
				
            Write-Output "`r`nAccount created successfully in Active Directory."
        } catch {
            Write-Output "`r`nThere was an error creating the Active Directory user account. $($PSItem.ToString())"
            Write-Host -NoNewLine "`r`nPress any key to continue..." -ForegroundColor Cyan
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            Exit
        }
		do 
			{ 
				 Show-Menu 
				 $input = Read-Host "Please make a selection" 
				 switch ($input) 
				 { 
					   'a' { 
							Clear-Host 
							$groupNameAD = Read-Host 'Enter the AD Group Name you want to add the Account to'
							Add-ADGroupMember -Identity $groupNameAD -Member $acctUsername
							$members = Get-ADGroupMember -Identity $groupNameAD -Recursive | Select-Object -ExpandProperty Name
							If ($members -contains $acctUsername) {
								  Write-Host "$acctUsername successfully added to $groupNameAD"
							 } Else {
									Write-Host "$acctUsername was NOT successfully added to $groupNameAD"
							}
					   } 'q' { 
							#do nothing 
					   } 
				 } 
				 pause 
			} 
			until ($input -eq 'q')
    }
    default {
        # do nothing
    }
}

##########################################
### LOG INTO THE PVWA - ROUND 1 (W/ END-USER CREDENTIALS)

# Prompt for End-User's Credentials to Login to PVWA
$caption = "CyberArk Account Factory"
$msg = "Enter your Username and Password to Authenticate to CyberArk"; 
$creds = $Host.UI.PromptForCredential($caption,$msg,"","")
if ($null -ne $creds)
{
	$secureUsername = $creds.username.Replace('\','');    
	$securePassword = ConvertTo-SecureString $creds.GetNetworkCredential().password -AsPlainText -Force
	$apiCredentials = New-Object System.Management.Automation.PSCredential($secureUsername, $securePassword)
}
else { 
	Log-Msg -Type Error -MSG "No Credentials were entered" -Footer
	exit
}
try {
    # Establish session connection to CyberArk Web Services & receive Authorization Token
    $token = New-PASSession -Credential $apiCredentials -BaseURI $baseURI  -ErrorAction Stop
    Write-Output "`r`nSecurely logged into CyberArk Web Services using ${secureUsername}."
} catch {
    Write-Output "`r`n[ ERROR ] Could not login to CyberArk Web Services. $($PSItem.ToString())"
    Write-Host -NoNewLine "`r`nPress any key to continue..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Exit
}

##########################################
### GET API CREDENTIALS FROM PVWA

# Get CyberArk SVC Account that will onboard the privileged credential into the Vault
$token | Get-PASAccount -Keywords 'x_admin' -Safe 'Windows Domain Admin' | Get-PASAccountPassword 

#Need to figure out how to get response back with password and set as a variable $apiCredentials2

$token | Close-PASSession

##########################################
### LOG INTO THE PVWA - ROUND 2 (W/ API USER CREDENTIALS)

try {
    # Establish session connection to CyberArk Web Services & receive Authorization Token
    $token2 = New-PASSession -Credential $apiCredentials2 -BaseURI $baseURI  -ErrorAction Stop
    Write-Output "`r`nSecurely logged into CyberArk Web Services using ${secureUsername}."
} catch {
    Write-Output "`r`n[ ERROR ] Could not login to CyberArk Web Services. $($PSItem.ToString())"
    Write-Host -NoNewLine "`r`nPress any key to continue..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Exit
}

##########################################
### ONBOARD ACCOUNT TO EPV

$platformID = Read-Host "Enter the desired PlatformID to assign the Account to"
$safeName = Read-Host "Enter the account description"

try {
    # Case 2: Local User selected - onboard to specified platformID
    if ($acctScope -like "l") {
        $acctResponse = ($token2 | Add-PASAccount -BaseURI $baseURI -name "${platformID}-${acctAddress}-${acctUsername}" `
            -address $acctAddress -userName $acctUsername -platformId $platformID `
            -SafeName $safeName -secret $acctSecurePassword -automaticManagementEnabled $true `
            -platformAccountProperties @{ "LogonDomain"="${acctLogonTo}"; }  -ErrorAction Stop)

        $acctAccountId = $acctResponse.id

        Write-Output "`r`nAutomatically onboarded ${acctUsername} successfully."
    
    # Case 1: Active Directory User selected - onboard to specified platformID
    } else {
        $acctResponse = ($token2 | Add-PASAccount -BaseURI $baseURI -name "${platformID}-${acctAddress}-${acctUsername}" `
            -address $acctAddress -userName $acctUsername -platformId $platformID `
            -SafeName $safeName -secret $acctSecurePassword -automaticManagementEnabled $true `
            -ErrorAction Stop)

        $acctAccountId = $acctResponse.id

        Write-Output "`r`nAutomatically onboarded ${acctUsername} successfully."
    }
} catch {
    Write-Output "`r`n[ ERROR ] Could not onboard account to EPV. $($PSItem.ToString())"
    Write-Host -NoNewLine "`r`nPress any key to continue..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Exit
}

##########################################
### VERIFY ACCOUNT ONBOARDED

try {
    # If we get a non-error response, we were successful! (Piping to Out-Null blocks the output)
    $token2 | Get-PASAccount -id $acctAccountId -ErrorAction Stop | Out-Null

    Write-Output "`r`nSuccessfully verified ${acctUsername} using Account Id ${acctAccountId}."
} catch {
    Write-Output "`r`n[ ERROR ] Could not successfully verify account. $($PSItem.ToString())"
    Write-Host -NoNewLine "`r`nPress any key to continue..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Exit
}

##########################################
### IMMEDIATE CHANGE PASSWORD OF ONBOARDED ACCOUNT

try {
    # If we get a non-error response, we were successful!
    $token2 | Start-PASCredChange -id $acctAccountId -ImmediateChangeByCPM Yes

    Write-Output "`r`nSuccessfully triggered ${acctUsername} using Account Id ${acctAccountId} for immediate change."
} catch {
    Write-Output "`r`n[ ERROR ] Could not trigger account for change - please initiate this manually from the PVWA. $($PSItem.ToString())"
    Write-Host -NoNewLine "`r`nPress any key to continue..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Exit
}

##########################################
### LOGOFF CYBERARK WEB SERVICES

try {
    # Again, we're looking for a non-error response while piping out to NULL
    $token2 | Close-PASSession -ErrorAction Stop | Out-Null

    Write-Output "`r`nLogged off CyberArk Web Services."
} catch {
    Write-Output "`r`n[ ERROR ] Could not logoff CyberArk Web Services - auto-logoff will `
        occur in 20 minutes. $($PSItem.ToString())"
    Exit
}

Write-Host "`r`nScript complete!" -ForegroundColor Green
Write-Host -NoNewLine "`r`nPress any key to continue..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')