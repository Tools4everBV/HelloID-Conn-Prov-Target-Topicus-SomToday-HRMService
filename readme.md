# HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService
| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

<br />
<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/somtoday-logo.png">
</p>

## Table of contents

- [Introduction](#Introduction)
- [Getting started](#Getting-started)
  + [Connection settings](#Connection-settings)
  + [Prerequisites](#Prerequisites)
  + [Remarks](#Remarks)
- [Setup the connector](@Setup-The-Connector)
- [Getting help](#Getting-help)
- [HelloID Docs](#HelloID-docs)

## Introduction

_HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService_ is a _target_ connector. Topicus-Somtoday-HRMService provides a SAOP API's that allow you to programmatically interact with its data. The HelloID connector uses the API endpoints listed in the table below.
This connector will also use the connectAPI to read the employeedata from Somtoday. 
The token will be retrieved from the HelloID proxy


| service      | Endpoint                          | Description |
| ------------ | ------------                      | ----------- |
|HelloID proxy |  somtoday/oauth2/token            | gets a token specific for the managed organisation |
|HRMservice    |  CreatePerson                     | creates or updates a person in HRM |
|ConnectAPI    |  /instelling                      | get the organisation |
|ConnectAPI    |  /instelling                      | get the organisation |
|ConnectAPI    |  /vestiging                       | gets all the related schools of the organisation |
|ConnectAPI    |  /vestiging/(schoolID)/medewerker | gets data of the active employee |

This connector will create and update persons, including the list of "vestigingen" of the person.

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                                     | Mandatory   |
| ------------ | -----------                                     | ----------- |
| SomHrmUserName     | The UserName to connect to the HRMservice              | Yes         |
| SomHrmPassword     | The Password to connect to the HRMservice                                               | Yes         |
| SomHrmBaseUrl      | The URL to the HRMservice Like: https://portalnaam-oop.Somtoday.nl/services/HRMService?wsdl'               | Yes         |
| ConnectClientId      | The client ID to connect to Topicus Connect API               | Yes         |
| ConnectClientSecret | ConnectAPI - Client Secret | Yes |
| ConnectBaseUrl |The URL to the Connect API environment | Yes |
| Connectorganization | The name of the organization in Somtoday | Yes         |
| BrinNummer   | The BrinNummer of the school                     | Yes         |
| Proxyaddress | Optional web proxy, e.g. "http://localhost:8888  | No          |
| IsDebug      | When toggled, debug logging will be displayed    | No          |

### Prerequisites

### Remarks
- As implementer, you need your own set of credentials before you can implement this connector. Therefore you need to sign a contract with the supplier.
- A School (also knows as an 'organization' within Somtoday) might have multiple departments (or vestigingen). Accounts are correlated based on the value of the 'Organization.Name' in the contract.


#### Creation / correlation process

Through the connect API you can get the data of only active employees to correlate and reuse the data from the retrieved employee.
It's is not possible to get an inactive employee.


#### Update
In principle it is necessary, when updating users, to specify all attributes of the user, not only the attributes that have been changed.

Account attributes that are set to $null or are empty will not be added to the xml sent to Somtoday. If a attribute should be cleared explicitly, that is not implemented by this current template.

See the "HRM webservice.pdf" for information regarding specific attributes



## Getting help

For more information about the api, and the fields that can be updated, see the "HRM Webservice.pdf" document. in this directory.

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012558020-Configure-a-custom-PowerShell-target-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
