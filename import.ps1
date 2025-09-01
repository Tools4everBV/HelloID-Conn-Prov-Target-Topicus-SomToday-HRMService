#################################################  
# HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService-Import
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-Topicus-Somtoday-HRMServiceError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            if ($errorDetailsObject.errors) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.errors -join ', '
            }
            elseif ($errorDetailsObject.message) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
            }
            elseif ($errorDetailsObject.error_description) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.error_description
            }
            else {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject
            }        
        }
        catch {
            $httpErrorObj.FriendlyMessage = "Error: [$($httpErrorObj.ErrorDetails)] [$($_.Exception.Message)]"
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    Write-Information 'Starting Topicus-Somtoday-HRMService account entitlement import'
   
    Write-information "Retrieving Somtoday organizationUUID's"

    $splatRestParams = @{
        Method = 'GET'
        Uri    = "https://api.$($actionContext.Configuration.ConnectBaseUrl)/rest/v1/connect/instelling"
    }
    $responseOrganizations = Invoke-RestMethod @splatRestParams -verbose:$false
    $organization = $responseOrganizations.instellingen.Where({ $_.naam -eq "$($actionContext.Configuration.Connectorganization)" })

    if ([string]::isNullOrEmpty($organization.uuid)) {
        throw "An organization (instelling) with name: [$($actionContext.Configuration.Instelling)] could not be found"
    }

    Write-information "Found uuid $($organization.uuid) for organisation $($config.Connectorganization)"

    Write-Information 'Determine oAuth URI'
    $oAuthUri = "https://inloggen.$($actionContext.Configuration.ConnectBaseUrl)/oauth2/token?organisation=$($organization.uuid)"
    if ($actionContext.Configuration.UseConnectorProxy -eq $true) {
        $oAuthUri = "https://connectors.helloid.cloud/service/proxy/api/Connector/somtoday/oauth2/token?organisation=$($organization.uuid)"
    }

    
    Write-Information "Using oAuth URI: [$($oAuthUri.Split('?')[0])]"
    Write-Information "Retrieving oAuth token for organization: [$($organization.naam)]"
    $splatTokenParams = @{
        Method      = 'POST'
        Uri         = $oAuthUri
        Body        = "client_id=$($actionContext.Configuration.ConnectClientId)&client_secret=$($actionContext.Configuration.ConnectClientSecret)&grant_type=client_credentials"
        ContentType = 'application/x-www-form-urlencoded'
    }
    $responseToken = Invoke-RestMethod @splatTokenParams

    Write-Information 'Adding authorizationToken to headers'
    $headers = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $headers.Add('Authorization', "Bearer $($responseToken.access_token)")
    $headers.Add('Content-Type', 'application/json')
    $headers.Add('Accept', 'application/json')

    Write-Information 'Retrieving organizations for which the token is authenticated'
    $splatOrgParams = @{
        Method  = 'GET'
        Uri     = "https://api.$($actionContext.Configuration.ConnectBaseUrl)/rest/v1/connect/vestiging"
        headers = $headers
    }
    $responseVestigingen = Invoke-RestMethod @splatOrgParams

    $importedAccounts = @{}
    foreach ($vestiging in $responseVestigingen.vestigingen) {
        $amount = 50
        $offset = 0
        do {
            $splatRestParams = @{
                Method          = 'GET'
                Uri             = "https://api.$($actionContext.Configuration.ConnectBaseUrl)/rest/v1/connect/vestiging/$($vestiging.uuid)/medewerker?amount=$amount&offset=$offset&peilschooljaar=HUIDIG"
                headers         = $Headers
                UseBasicParsing = $true
            }
            $responseEmployee = Invoke-RestMethod @splatRestParams -Verbose:$false -ErrorAction silentlycontinue
            foreach ($employee in $responseEmployee.medewerkers) {
                $importedAccounts[$employee.uuid] = $employee
            } 
            $offset = $offset + $amount         

        } until (
            ($responseEmployee.medewerkers.count -lt $amount) -OR ($null -ne $employeeFound)
        )

    }   

    foreach ($accountUUID in $importedAccounts.keys) {
        # Making sure only fieldMapping fields are imported
        $data = @{}
        $account = $importedAccounts[$accountUUID]
        foreach ($field in $actionContext.ImportFields) {
            switch ($field) {
                'externMedewerkerNummer' {
                    $data["$field"] = $account.externnummer
                    break
                }
                default {
                    $data["$field"] = $account.$field
                }
            }
        }         

        # Make sure the displayName has a value
        $displayName = "$($account.roepnaam) $($account.achternaam)".trim()
        if ([string]::IsNullOrWhiteSpace($displayName)) {
            $displayName = $account.uuid
        }       

        # Make sure the userName has a value
        if ([string]::IsNullOrWhiteSpace($account.UserName)) {
            $UserName = $Account.uuid
        }
        else {
            $UserName = $account.UserName
        }

        # Return the result
        Write-Output @{
            AccountReference = $account.uuid
            displayName      = $displayName
            UserName         = $UserName
            Enabled          = $false
            Data             = $data
        }
    }
    Write-Information 'Topicus-Somtoday-HRMService account entitlement import completed'
}
catch {
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Topicus-Somtoday-HRMServiceError -ErrorObject $ex
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
        Write-Error "Could not import Topicus-Somtoday-HRMService account entitlements. Error: $($errorObj.FriendlyMessage)"
    }
    else {
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        Write-Error "Could not import Topicus-Somtoday-HRMService account entitlements. Error: $($ex.Exception.Message)"
    }
}