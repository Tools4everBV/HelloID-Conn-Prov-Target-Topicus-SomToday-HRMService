#################################################
# HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService-Create
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions

function Get-ConnectAPIEmployee {
    [cmdletbinding()]
    Param (
        [string]$BaseUri,
        [object]$Headers,
        [object]$VestigingUUID,
        [string]$CorrelationField,
        [string]$CorrelationValue
    )
    try {
        # Pagination
        $amount = 50
        $offset = 0
        $employeeFound = $null

        do {
            $splatRestParams = @{
                Method          = 'GET'
                Uri             = "$BaseUri/rest/v1/connect/vestiging/$VestigingUUID/medewerker?amount=$amount&offset=$offset&peilschooljaar=HUIDIG"
                headers         = $Headers
                UseBasicParsing = $true
            }
            $responseEmployee = Invoke-RestMethod @splatRestParams -Verbose:$false -ErrorAction silentlycontinue

            $offset = $offset + $amount
            $employeeFound = $responseEmployee.medewerkers | Where-Object  $CorrelationField -eq $CorrelationValue

        } until (
            (($responseEmployee.medewerkers | Measure-Object).count -lt $amount) -OR ($null -ne $employeeFound)
        )

        if ($null -eq $employeeFound) {
            Write-Information "No employee found with [$CorrelationField] = [$CorrelationValue] in vestiging [$VestigingUUID]"
            return $null
        }

        if ($employeeFound.Count -gt 1) {
            throw "Multiple employees found with [$CorrelationField] = [$CorrelationValue] in vestiging [$VestigingUUID]"
        }

        Write-Information "Found employee with [$CorrelationField] = [$CorrelationValue] in Vestiging $VestigingUUID]"
        Write-Output $employeeFound
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

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

function New-SHA1String {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Phrase
    )
    [System.Security.Cryptography.SHA1CryptoServiceProvider] $sha1Hasher = [System.Security.Cryptography.SHA1CryptoServiceProvider]::new()
    [byte[]] $hashedDataBytes = $sha1Hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Phrase));
    write-output $([system.convert]::ToBase64String($hashedDataBytes))

}

function New-SoapBody {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject] $Account
    )

    [system.text.StringBuilder] $soapPerson = [system.text.StringBuilder]::new()

    if (-not [string]::IsNullOrEmpty($Account.medewerkerNummer)) { $temp = $soapPerson.Append("<medewerkernummer>$($Account.medewerkerNummer)</medewerkernummer>`n") }
    $temp = $soapPerson.Append("<afkorting>$($Account.afkorting)</afkorting>`n")
    $temp = $soapPerson.Append("<achternaam>$($Account.achternaam)</achternaam>`n")
    #if (-not [string]::IsNullOrEmpty($Account.meisjesnaam)) { $temp = $soapPerson.Append("<meisjesnaam>$($Account.meisjesnaam)</meisjesnaam>`n") }
    $temp = $soapPerson.Append("<meisjesnaam>$($Account.meisjesnaam)</meisjesnaam>`n")
    if (-not [string]::IsNullOrEmpty($Account.voorletters)) { $temp = $soapPerson.Append("<voorletters>$($Account.voorletters)</voorletters>`n") }
    if (-not [string]::IsNullOrEmpty($Account.voorvoegsel)) { $temp = $soapPerson.Append("<voorvoegsel>$($Account.voorvoegsel)</voorvoegsel>`n") }
    if (-not [string]::IsNullOrEmpty($Account.roepnaam)) { $temp = $soapPerson.Append("<roepnaam>$($Account.roepnaam)</roepnaam>`n") }
    if (-not [string]::IsNullOrEmpty($Account.voornamen)) { $temp = $soapPerson.Append("<voornamen>$($Account.voornamen)</voornamen>`n") }
    $temp = $soapPerson.Append("<geslacht>$($Account.geslacht)</geslacht>`n")
    if (-not [string]::IsNullOrEmpty($Account.geboortedatum)) { $temp = $soapPerson.Append("<geboortedatum>$($Account.geboortedatum)</geboortedatum>`n") }
    if (-not [string]::IsNullOrEmpty($Account.geboorteplaats)) { $temp = $soapPerson.Append("<geboorteplaats>$($Account.geboorteplaats)</geboorteplaats>`n") }
    if (-not [string]::IsNullOrEmpty($Account.geboortelandcode)) { $temp = $soapPerson.Append("<geboortelandcode>$($Account.geboortelandcode)</geboortelandcode>`n") }
    if (-not [string]::IsNullOrEmpty($Account.nationaliteitcode)) { $temp = $soapPerson.Append("<nationaliteitcode>$($Account.nationaliteitcode)</nationaliteitcode>`n") }
    if (-not [string]::IsNullOrEmpty($Account.burgerlijkestaat)) { $temp = $soapPerson.Append("<burgerlijkestaat>$($Account.burgerlijkestaat)</burgerlijkestaat>`n") }
    if (-not [string]::IsNullOrEmpty($Account.ibanNummer)) { $temp = $soapPerson.Append("<ibanNummer>$($Account.ibanNummer)</ibanNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.bicNummer)) { $temp = $soapPerson.Append("<bicNummer>$($Account.bicNummer)</bicNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.casoNummer)) { $temp = $soapPerson.Append("<casoNummer>$($Account.casoNummer)</casoNummer>`n") }

    $temp = $soapPerson.Append("<HRMAdres>`n")
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.straat)) { $temp = $soapPerson.Append("<straat>$($Account.HRMAdres.straat)</straat>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.huisnummer)) { $temp = $soapPerson.Append("<huisnummer>$($Account.HRMAdres.huisnummer)</huisnummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.postcode)) { $temp = $soapPerson.Append("<postcode>$($Account.HRMAdres.postcode)</postcode>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.plaatsnaam)) { $temp = $soapPerson.Append("<plaatsnaam>$($Account.HRMAdres.plaatsnaam)</plaatsnaam>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland1)) { $temp = $soapPerson.Append("<buitenland1>$($Account.HRMAdres.buitenland1)</buitenland1>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland2)) { $temp = $soapPerson.Append("<buitenland2>$($Account.HRMAdres.buitenland2)</buitenland2>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland3)) { $temp = $soapPerson.Append("<buitenland3>$($Account.HRMAdres.buitenland3)</buitenland3>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.telefoonnummer)) { $temp = $soapPerson.Append("<telefoonnummer>$($Account.HRMAdres.telefoonnummer)</telefoonnummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.geheimAdres)) { $temp = $soapPerson.Append("<geheimAdres>$($Account.HRMAdres.geheimAdres)</geheimAdres>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.geheimTelefoonnummer)) { $temp = $soapPerson.Append("<geheimTelefoonnummer>$($Account.HRMAdres.geheimTelefoonnummer)</geheimTelefoonnummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.landcode)) { $temp = $soapPerson.Append("<landcode>$($Account.HRMAdres.landcode)</landcode>`n") }
    $temp = $soapPerson.Append("</HRMAdres>`n")

    if (-not [string]::IsNullOrEmpty($Account.mobielNummer)) { $temp = $soapPerson.Append("<mobielNummer>$($Account.mobielNummer)</mobielNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.geheimMobielNummer)) { $temp = $soapPerson.Append("<geheimMobielNummer>$($Account.geheimMobielNummer)</geheimMobielNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.internNummer)) { $temp = $soapPerson.Append("<internNummer>$($Account.internNummer)</internNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.onderwijsPersoneel)) { $temp = $soapPerson.Append("<onderwijsPersoneel>$($Account.onderwijsPersoneel)</onderwijsPersoneel>`n") }
    if (-not [string]::IsNullOrEmpty($Account.ondersteunendPersoneel)) { $temp = $soapPerson.Append("<ondersteunendPersoneel>$($Account.ondersteunendPersoneel)</ondersteunendPersoneel>`n") }
    if (-not [string]::IsNullOrEmpty($Account.externMedewerkerNummer)) { $temp = $soapPerson.Append("<externMedewerkerNummer>$($Account.externMedewerkerNummer)</externMedewerkerNummer>`n") }

    foreach ($Vestiging in  $Account.vestigingen) {
        $temp = $soapPerson.Append("<vestigingen>`n")   
        $temp = $soapPerson.Append("<afkorting>$($Vestiging.afkorting)</afkorting>`n")
        if (-not [string]::IsNullOrEmpty($Vestiging.brinNummer)) { $temp = $soapPerson.Append("<brinNummer>$($Vestiging.brinNummer)</brinNummer>`n") }
        $temp = $soapPerson.Append("</vestigingen>`n")
    }

    if (-not [string]::IsNullOrEmpty($Account.gebruikersnaam)) { $temp = $soapPerson.Append("<gebruikersnaam>$($Account.gebruikersnaam)</gebruikersnaam>`n") }
    if (-not [string]::IsNullOrEmpty($Account.wachtwoord)) { $temp = $soapPerson.Append("<wachtwoord>$($Account.wachtwoord)</wachtwoord>`n") }
    if (-not [string]::IsNullOrEmpty($Account.email)) { $temp = $soapPerson.Append("<email>$($Account.email)</email>`n") }
    if (-not [string]::IsNullOrEmpty($Account.functie)) { $temp = $soapPerson.Append("<functie>$($Account.functie)</functie>`n") }
    if (-not [string]::IsNullOrEmpty($Account.datumInDienst)) { $temp = $soapPerson.Append("<datumInDienst>$($Account.datumInDienst)</datumInDienst>`n") }
    if (-not [string]::IsNullOrEmpty($Account.datumUitDienst)) { $temp = $soapPerson.Append("<datumUitDienst>$($Account.datumUitDienst)</datumUitDienst>`n") }
    if (-not [string]::IsNullOrEmpty($Account.redenUitDienst)) { $temp = $soapPerson.Append("<redenUitDienst>$($Account.redenUitDienst)</redenUitDienst>`n") }
    if (-not [string]::IsNullOrEmpty($Account.uitsluitenCorrespondentie)) { $temp = $soapPerson.Append("<uitsluitenCorrespondentie>$($Account.uitsluitenCorrespondentie)</uitsluitenCorrespondentie>`n") }

    [string] $soapbody = @"
    <createPerson xmlns="http://hrm.webservices.iridium.topicus.nl/">
        <HRMperson xmlns="">
        $($soapPerson.ToString())
        </HRMperson>
    </createPerson>
"@

    Write-Output $soapbody
}

function New-SoapHeader {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $brincode
    )
    [DateTime] $created = [DateTime]::Now.ToUniversalTime()
    [string] $createdStr = $created.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    [string] $phrase = [Guid]::NewGuid().ToString();
    [string] $nonce = New-SHA1String($phrase);


    $brincode4 = $brincode.Substring(0, 4)

    $Header = @"
    <Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
        <UsernameToken wsu:Id="UsernameToken - 1AEA5E598817F48387146183029981292" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
            	<Username>$($actionContext.Configuration.SomHrmUserName)</Username>
            <Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$($actionContext.Configuration.SomHrmPassword)</Password>
            <Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">$nonce</Nonce>
			<Created>
            $createdStr</Created>
			</UsernameToken>
		</Security>
		<Brinnummer xmlns="http://hrm.koppelingen.iridium.topicus.nl/">$brincode4</Brinnummer>
"@
    Write-Output $Header
}

#endregion

try {
    # Initial Assignments
    $outputContext.AccountReference = 'Currently not available'       

    Write-information "Retrieving Somtoday organizationUUID's"

    $splatRestParams = @{
        Method = 'GET'
        Uri    = "https://api.$($actionContext.Configuration.ConnectBaseUrl)/rest/v1/connect/instelling"
    }
    $responseOrganizations = Invoke-RestMethod @splatRestParams -verbose:$false
    $organization = $responseOrganizations.instellingen.Where({ $_.naam -eq "$($actionContext.Configuration.ConnectOrganization)" })

    if ([string]::isNullOrEmpty($organization.uuid)) {
        throw "An organization (instelling) with name: [$($actionContext.Configuration.Instelling)] could not be found"
    }

    Write-information "Found uuid $($organization.uuid) for organisation $($actionContext.Configuration.ConnectOrganization)"

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

    Write-Information 'Retrieving UUID for the current school'   
    $curSchool = ($responseVestigingen.vestigingen.Where({ $_.naam -eq $actionContext.Data._extension_currentSchoolName }))  
    if ($null -eq $CurSchool.uuid) {
        throw "A school (vestiging) with name: [$( $actionContext.Data._extension_currentSchoolName)] could not be found"
    }
    
    Write-Information "Found uuid: $($CurSchool.uuid) for school $($CurSchool.naam))"
   
    # Validate correlation configuration
    if ($actionContext.CorrelationConfiguration.Enabled) {
        $correlationField = $actionContext.CorrelationConfiguration.AccountField
        $correlationValue = $actionContext.CorrelationConfiguration.PersonFieldValue

        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        Write-Information "Verifying if employee with [$($correlationField)]: [$($correlationValue)] exists"     
        $lastFoundEmployeeUUID = $null         
        foreach ($vestiging in $responseVestigingen.vestigingen) {
            if ($vestiging.naam -ne $currentSchoolName) {
                $splatGetEmployee = @{
                    BaseUri          = "https://api.$($actionContext.Configuration.ConnectBaseUrl)"
                    Headers          = $headers
                    VestigingUUID    = $vestiging.uuid
                    CorrelationField = $correlationField
                    CorrelationValue = $correlationValue
                }
            }
            $FoundEmployee = Get-ConnectAPIEmployee @splatGetEmployee 
            if ( $null -ne $FoundEmployee) {
                $correlatedEmployee = $FoundEmployee 
                if ($null -eq $lastFoundEmployeeUUID) {
                    $lastFoundEmployeeUUID = $FoundEmployee.uuid
                }
                else {
                    if ($lastFoundEmployeeUUID -ne $FoundEmployee.uuid) {
                        throw "Multiple accounts found with correlation value [$correlationValue]"
                    }                   
                }
            }            
        } 
    }
    if ($correlatedEmployee.Count -eq 0) {
        $action = 'CreateHRMAccount'
    }
    else {
        $action = 'CorrelateHRMAccount'
    } 

    # Process
    switch ($action) {
        'CreateHRMAccount' {

            $account = $actionContext.Data

            $vestigingenList = [System.Collections.Generic.List[PSCustomObject]]::new()

            if ($CurSchool.brins.count -eq 1) {
                $brin = $CurSchool.brins | Select-Object -first 1
            }
            else {
                $AfkortingBrin = $CurSchool.brins | Where-Object { $_ -eq $CurSchool.afkorting }
                if ($AfkortingBrin.count -eq 1) {
                    $brin = $AfkortingBrin
                }
                else {
                    Throw "Could not determine correct BRIN for $($CurSchool.naam)"
                }
            }
            $curVestiging = @{
                afkorting  = $CurSchool.afkorting   
                brinNummer = $brin
            }
            $vestigingenlist.add($curVestiging)              
        
            $account | Add-Member -NotePropertyMembers @{vestigingen = $vestigingenList }

            $splatRestMethodParams = @{
                Uri             = "https://$($actionContext.Configuration.SomHrmBaseUrl)/services/HRMService?wsdl"
                Method          = 'POST'
                ContentType     = "text/xml; charset=utf-8"
                UseBasicParsing = $true
            }        

            $SoapHeader = New-SoapHeader -Brincode $actionContext.Configuration.SomhrmBrinNr
            $SoapBody = New-SoapBody -account $account

            $createPersonXmlBody = @"
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Header>
      $SoapHeader
    </soapenv:Header>
    <soapenv:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        $SoapBody
    </soapenv:Body>
</soapenv:Envelope>
"@
            $splatRestMethodParams['Body'] = $createPersonXmlBody

            # Make sure to test with special characters and if needed; add utf8 encoding.
            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information 'Creating and correlating Topicus-Somtoday-HRMService account'
                $responseCreatePerson = Invoke-RestMethod @splatRestMethodParams 

                # Make sure to filter out arrays from $outputContext.Data (If this is not mapped to type Array in the fieldmapping). This is not supported by HelloID.
                # $outputContext.Data = $createdAccount
                $outputContext.AccountReference = [PSCustomObject]@{
                    externMedewerkerNummer = $account.externMedewerkerNummer
                    UUID                   = $null
                }

            }
            else {
                Write-Information '[DryRun] Create and correlate Topicus-Somtoday-HRMService account, will be executed during enforcement'
            }
            $auditLogMessage = "Create account was successful. AccountReference is: [$($outputContext.AccountReference)]"
            break
        }

        'CorrelateHRMAccount' {
            Write-Information 'Correlating Topicus-Somtoday-HRMService account'

            # Make sure to filter out arrays from $outputContext.Data (If this is not mapped to type Array in the fieldmapping). This is not supported by HelloID.            
            $outputContext.Data = @{}
            $outputContext.AccountReference = $outputContext.AccountReference = [PSCustomObject]@{
                externMedewerkerNummer = $actionContext.Data.externMedewerkerNummer
                UUID                   = $correlatedEmployee.uuid
            }
            $outputContext.AccountCorrelated = $true
            $auditLogMessage = "Correlated account: [$($outputContext.AccountReference)] on field: [$($correlationField)] with value: [$($correlationValue)]"
            break
        }
    }

    $outputContext.success = $true
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Action  = $action
            Message = $auditLogMessage
            IsError = $false
        })
}
catch {
    $outputContext.success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Topicus-Somtoday-HRMServiceError -ErrorObject $ex
        $auditMessage = "Could not create or correlate Topicus-Somtoday-HRMService account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    }
    else {
        $auditMessage = "Could not create or correlate Topicus-Somtoday-HRMService account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}