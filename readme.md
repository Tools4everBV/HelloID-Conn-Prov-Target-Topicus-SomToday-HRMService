# HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService

<!--
** for extra information about alert syntax please refer to [Alerts](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts)
-->

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

> [!WARNING]
> The calls to the SomToday Connect API have been tested with a SomToday test environment, but the SOAP actions have not. Therefore, changes to the SOAP call may be required when implementing. 

<p align="center">
  <img src="">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService](#helloid-conn-prov-target-Topicus-Somtoday-HRMService)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Supported  features](#supported--features)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Field mapping](#field-mapping)
    - [Account Reference](#account-reference)
  - [Remarks](#remarks)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService_ is a _target_ connector. _Topicus-Somtoday-HRMService_ utilizes a combined set of Rest and SOAP interfaces that allow you to Read employee account data from Somtoday by means of the Connect API (Rest), and create/update  associated or new HRM employee data (SOAP)

## Supported  features

The following features are available:

| Feature                                   | Supported | Actions                                 | Remarks           |
| ----------------------------------------- | --------- | --------------------------------------- | ----------------- |
| **Account Lifecycle**                     | ✅        | Create, Update, Delete                  | Update (when triggered) unconditionally updates all configured fields |
| **Permissions**                           | ❌        |                                         |                   |
| **Resources**                             | ❌        | -                                       |                   |
| **Entitlement Import: Accounts**          | ✅        | import.ps1                              |                   |
| **Entitlement Import: Permissions**       | ❌        | -                                       |                   |
| **Governance Reconciliation Resolutions** | ❌        | -                                       |                   |

## Getting started

### Prerequisites
No specific prerequisites, but you may need to tweak the correlation configuration fields depending on availability in your source systems.

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                                     | Mandatory   |
| ------------ | -----------                                     | ----------- |
| SomHrmUserName     | The UserName to connect to the HRMservice     | Yes         |
| SomHrmPassword     | The Password to connect to the HRMservice       | Yes         |
| SomHrmBaseUrl      | The URL to the HRMservice Like: https://portalnaam-oop.Somtoday.nl/services/HRMService?wsdl'               | Yes         |
| ConnectClientId      | The client ID to connect to Topicus Connect API               | Yes         |
| ConnectClientSecret | ConnectAPI - Client Secret | Yes |
| ConnectBaseUrl |The URL to the Connect API environment | Yes |
| ConnectOrganization | The name of the organization in Somtoday | Yes         |
| BrinNummer   | The BrinNummer of the school associated whit the HRM service | Yes |
| USECONECTORPROXY | whether or not to use the specific Tools4ever Connector proxy for access to the Connect API | Yes |



- The ConnectBaseUrl should be without "https://" ,  so for example "acceptatie.somtoday.nl"
- The USECONECTORPROXY specifies if you connect to the SomToday Connect API directly(with credentials provided by Topicus), or by means of our Connector proxy (with credentials  provided by Tools4ever). Usually it is required to use the Connector Proxy for production environments.
- The USECONECTORPROXY setting only applies to the Connect Rest API. The HRM SOAP connection does not use the connector proxy.
 

### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _Topicus-Somtoday-HRMService_ to a person in _HelloID_.

| Setting                   | Value                             |
| ------------------------- | --------------------------------- |
| Enable correlation        | `True`                            |
| Person correlation field  | `PersonContext.Person.Custom.MedewerkerAfkorting` |
| Account correlation field | `afkorting`                       |

Note, which fields should be used for the correlation are highly dependent on your Somtoday implementation, so it is likely that you need to change this configuration to fit your environment.

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Account Reference

The account reference <Accountreference>.uuid property is populated with the property `uuid`  from the correlated employee account from the "Connect" API.
When creating a new account this property is not yet available, instead the property <Accountreference>.externMedewerkerNummer is specified as temporary alternative reference. The update script will lookup the account by uuid if available, if not by 'externnummer' =   <Accountreference>.externMedewerkerNummer, and fill de reference with the found uuid.

## Remarks
- The HRMService support only one SOAP call in total, to create and or update a employee record.
  In order to allow correlation with SomToDay employee accounts, the SomToday Connect API is used, therfore credentials are needed for both connections.

- In principle it is necessary, when updating users, to specify all attributes of the user, not only the attributes that have been changed.
  As not all HRM attributes can in a simple way be retrieved by the Connect API calls, the current implementation updates the HRM data unconditionally, when the update script is triggerd.

- The HRMService call does not return the created account, so on create the outputContext.data is a copy of the ActionContext.data

## Development resources
  See the "HRM webservice.pdf" for information regarding specific attributes

### API endpoints

Somtoday Connect API

| Endpoint                                                             | Description                                                  |
| -------------------------------------------------------------------- | ------------------------------------------------------------ |
| <TokenURL>/oauth2/token?organisation=<organisationId>                | Retrieves the oAuth token                                    |
| /rest/v1/connect/vestiging                                           | Retrieves organizations for which the token is authenticated |
| /rest/v1/connect/vestiging/<VestigingUUID>/medewerker                | Retrieves all employees for a specific department            |
| /rest/v1/connect/vestiging/<VestigingUUID>/medewerker/<uuid>/account | Retrieves Account information                    |

SOAP actions
```xml
<createPerson xmlns="http://hrm.webservices.iridium.topicus.nl/">...</CreatePerson>
```

### API documentation

[Swagger Documentation](https://editor.swagger.io/?url=https://api.somtoday.nl/rest/v1/connect/documented/openapi)

See the "HRM webservice.pdf" for information regarding specific attributes

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
