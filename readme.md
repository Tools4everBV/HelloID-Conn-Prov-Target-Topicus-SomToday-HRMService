# HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService

| :warning: Warning |
|:---------------------------|
| Note that this connector is not tested on HelloID or with a Somtoday environment. |

| :warning: Warning |
|:---------------------------|
| Note that this connector is "a work in progress" and therefore not ready to use in your production environment. |

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

| Endpoint     | Description |
| ------------ | ----------- |
|  CreatePerson           | creates or updates a person in HRM |

This connector will create and update persons, including the list of "vestigingen" of the person.

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                                     | Mandatory   |
| ------------ | -----------                                     | ----------- |
| UserName     | The UserName to connect to the API              | Yes         |
| Password     | -                                               | Yes         |
| BaseUrl      | The URL to the API. Like: https://portalnaam-oop.Somtoday.nl/services/HRMService?wsdl'               | Yes         |
| BrinNummer   | The BrinNummer of the school                     | Yes         |
| Proxyaddress | Optional web proxy, e.g. "http://localhost:8888  | No          |
| IsDebug      | When toggled, debug logging will be displayed    | No          |
### Prerequisites

### Remarks

#### Creation / correlation process

The api does not return any data from HRM, therefore it is not possible to differentiate between new and existing users. Existing users will be updated.

#### Update
In principle it is advised when updating users to specify all attributes of the user, not only the attributes that have been changed.
If a specific attribute is not known, it is usually best to set the attribute to $null in the account object, that way the attribute is omitted from the xml send.

Account attributes that are set to $null or are empty will not be added to the xml sent to Somtoday. If a attribute should be cleared explicitly, that is not implemented by this current template.

See the "HRM webservice.pdf" for information regarding specific attributes

#### enable/disable/grant/revoke
There are no specific endpoints for these actions available, nor is it possible to compare current settings. Use the "Update" action to calculate and implement permissions

#### delete
Not supported.

## Setup the connector

There are no specific requirements

## Getting help

For more information about the api, and the fields that can be updated, see the "HRM Webservice.pdf" document. in this directory.

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012558020-Configure-a-custom-PowerShell-target-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
