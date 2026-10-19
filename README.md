# HelloID-Conn-Prov-Target-Topicus-SomToday-HRMService

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible for acquiring connection details such as usernames, passwords and certificates. A contract or agreement with the supplier may also be required. Contact the client's application manager to coordinate the requirements.

> [!WARNING]
> The Somtoday Connect API calls have been tested with a Somtoday test environment, but the SOAP actions have not. Changes to the SOAP calls may be required during implementation.

<p align="center">
    <img src="https://raw.githubusercontent.com/Tools4everBV/HelloID-Conn-Prov-Target-Topicus-SomToday-HRMService/refs/heads/main/Logo.png" alt="Topicus Somtoday HRMService">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Topicus-SomToday-HRMService](#helloid-conn-prov-target-topicus-somtoday-hrmservice)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Supported features](#supported-features)
  - [Getting started](#getting-started)
    - [HelloID Icon URL](#helloid-icon-url)
    - [Requirements](#requirements)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Field mapping](#field-mapping)
    - [Account Reference](#account-reference)
  - [Remarks](#remarks)
    - [SOAP API behavior](#soap-api-behavior)
    - [Update behavior](#update-behavior)
    - [Create response](#create-response)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Topicus-SomToday-HRMService_ is a target connector for Topicus Somtoday. It uses the Somtoday Connect REST API to import and correlate employee accounts, and the HRMService SOAP API to create or update employee data.

## Supported features

The following features are available:

| Feature                                   | Supported | Actions                | Remarks                                      |
| ----------------------------------------- | --------- | ---------------------- | -------------------------------------------- |
| **Account Lifecycle**                     | ✅         | Create, Update, Delete | Update unconditionally updates configured fields |
| **Permissions**                           | ❌         | -                      |                                              |
| **Resources**                             | ❌         | -                      |                                              |
| **Entitlement Import: Accounts**          | ✅         | -                      | Implemented in `import.ps1`                  |
| **Entitlement Import: Permissions**       | ❌         | -                      |                                              |
| **Governance Reconciliation Resolutions** | ❌         | -                      |                                              |

## Getting started

### HelloID Icon URL

Use this URL for the icon of the HelloID Provisioning target system:

```text
https://raw.githubusercontent.com/Tools4everBV/HelloID-Conn-Prov-Target-Topicus-SomToday-HRMService/refs/heads/main/Icon.png
```

### Requirements

- Access to both the Somtoday HRMService SOAP API and the Somtoday Connect REST API.
- Valid credentials for both services. The Connect API may require Topicus credentials or Tools4ever Connector Proxy credentials, depending on the selected connection method.
- Confirm with the client's application manager whether a supplier contract, allowlisting or other access prerequisites are required.
- Review and adapt the correlation fields to match the implementation in the source system.

### Connection settings

The following settings are required to connect to the APIs:

| Setting             | Description                                                                              | Mandatory |
| ------------------- | ---------------------------------------------------------------------------------------- | --------- |
| SomHrmUserName      | Username for the Somtoday HRMService                                                     | Yes       |
| SomHrmPassword      | Password for the Somtoday HRMService                                                     | Yes       |
| SomHrmBaseUrl       | HRMService host name, without `https://` or the service path                             | Yes       |
| SomHrmBrinNr        | BRIN number of the school associated with the HRMService                                 | Yes       |
| ConnectClientId     | Client ID for the Somtoday Connect API                                                   | Yes       |
| ConnectClientSecret | Client secret for the Somtoday Connect API                                               | Yes       |
| ConnectBaseUrl      | Connect API environment host name, without `https://`                                    | Yes       |
| ConnectOrganization | Name of the organization in Somtoday                                                    | Yes       |
| UseConnectorProxy   | Whether to use the Tools4ever Connector Proxy for the Connect API (defaults to `false`) | No        |

For example, enter `acceptatie.somtoday.nl` for `ConnectBaseUrl`. `SomHrmBaseUrl` should contain the HRM host name, for example `portalnaam-oop.somtoday.nl`; the connector adds the protocol and service path.

`UseConnectorProxy` applies only to the Connect REST API. The HRMService SOAP connection does not use the Connector Proxy. Production use of the proxy may be required; confirm the required connection method and credentials with the application manager.

### Correlation configuration

The correlation configuration specifies which properties are used to match an existing account in _Topicus Somtoday HRMService_ to a person in _HelloID_.

| Setting                   | Value                                             |
| ------------------------- | ------------------------------------------------- |
| Enable correlation        | `True`                                            |
| Person correlation field  | `PersonContext.Person.Custom.MedewerkerAfkorting` |
| Account correlation field | `afkorting`                                       |

The appropriate correlation fields depend on the Somtoday implementation and may need to be changed.

> [!TIP]
> For more information on correlation, see the HelloID [correlation documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html).

### Field mapping

Import the field mapping by using the [fieldMapping.json](fieldMapping.json) file.

### Account Reference

The account reference's `uuid` property is populated from the `uuid` property of the correlated employee account in the Connect API. A newly created account does not yet have this UUID, so `externMedewerkerNummer` is used as a temporary reference. The update script looks up the account by UUID when available, or otherwise by `externnummer`, and then fills in the UUID reference.

## Remarks

### SOAP API behavior

The HRMService exposes a single SOAP operation, `createPerson`, for creating or updating an employee record. The Connect API is also required to correlate employee accounts, so credentials for both services are needed. The SOAP actions have not been tested against a Somtoday environment and may need adjustment.

### Update behavior

When updating an employee, the HRMService generally requires all employee attributes, not only changed values. Since the Connect API does not expose all HRM attributes in a form that can be retrieved by this connector, the update script unconditionally sends all configured fields when triggered.

### Create response

The HRMService call does not return the created account. On create, `outputContext.data` is therefore a copy of `ActionContext.data`.

## Development resources

See [HRM Webservice.pdf](HRM%20Webservice.pdf) for information about specific HRM attributes.

### API endpoints

The following endpoints are used by the connector:

| Endpoint                                                               | HTTP method | Description                                                           |
| ---------------------------------------------------------------------- | ----------- | --------------------------------------------------------------------- |
| `https://inloggen.{ConnectBaseUrl}/oauth2/token?organisation={uuid}`   | POST        | Retrieves an OAuth token; the Connector Proxy can be used instead    |
| `/rest/v1/connect/instelling`                                          | GET         | Retrieves Somtoday organizations                                      |
| `/rest/v1/connect/vestiging`                                           | GET         | Retrieves locations available to the authenticated token             |
| `/rest/v1/connect/vestiging/{VestigingUUID}/medewerker`                | GET         | Retrieves employees for a location                                    |
| `/rest/v1/connect/vestiging/{VestigingUUID}/medewerker/{uuid}/account` | GET         | Retrieves employee account information                                |
| `https://{SomHrmBaseUrl}/services/HRMService?wsdl`                      | POST (SOAP) | Calls the `createPerson` operation to create or update an employee   |

### API documentation

- [Somtoday Connect API Swagger documentation](https://editor.swagger.io/?url=https://api.somtoday.nl/rest/v1/connect/documented/openapi)
- See [HRM Webservice.pdf](HRM%20Webservice.pdf) for the HRMService SOAP attributes.

## Getting help

> [!TIP]
> For more information on configuring a HelloID PowerShell connector, see the [HelloID PowerShell target system documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html).

## HelloID docs

The official HelloID documentation is available at [docs.helloid.com](https://docs.helloid.com/).
