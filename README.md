# Windows Account Creation & Onboarding (WACO)

![](https://vignette.wikia.nocookie.net/animaniacs/images/0/0d/Wakko_Warner.png/revision/latest?cb=20130118164509)

## Requirements

* PowerShell
* CyberArk Application Access Manager (AAM)
* CyberArk PAS Web Services REST API
* psPAS _[Linked below]_

## Presentation from CyberArk Impact 2019

[Security at Inception: Best Practices for Managing the Credential Lifecycle with REST APIs and Automation](https://www.slideshare.net/JoeGarciaCISSP/security-at-inception-best-practices-for-managing-the-credential-lifecycle-with-rest-apis-and-automation)

## Video Walkthrough

[![View Video on YouTube](https://img.youtube.com/vi/C_F4z5GITws/0.jpg)](https://www.youtube.com/watch?v=C_F4z5GITws)

## PowerShell Modules/Functions Used

* psPAS by pspete
  * [https://www.powershellgallery.com/packages/psPAS/2.3.0](https://www.powershellgallery.com/packages/psPAS/2.3.0)
  
## Links to Other Great CyberArk Automation

### Webinars

* ["On the Front Lines" (OTFL) Webinar: REST API From Start to Finish #1](https://github.com/infamousjoeg/cyberark-account-factory) \
_Link to webinar video in README_ \
In this webinar, we created a CyberArk Account Factory using psPAS and CredentialRetriever in 45 mins

* ["On the Front Lines" (OTFL) Webinar: REST API From Start to Finish #2](https://github.com/infamousjoeg/cyberark-safe-factory) \
_Link to webinar video in README_ \
In this webinar, we created a CyberArk Safe Factory using psPAS and CredentialRetriever in 45 mins

### REST API

* [CyberArk REST API on Postman](https://cybr.rocks/RESTAPI) \
Live documentation for CyberArk's REST API (All versions)

* [epv-api-scripts on GitHub](https://github.com/cyberark/epv-api-scripts) \
Home to the Account Onboarding Utility

### Ansible

* [CyberArk & Ansible - AAM Bi-Directional Integration](https://www.youtube.com/watch?v=PHT76FYLNbY&list=PL-p_9AwMQDmkS6rCXQrINn0Xc7dv73dWU&index=5&t=0s) \
Demonstration of retrieving and onboarding credentials in Ansible playbooks

* [pas-orchestrator on GitHub](https://github.com/cyberark/pas-orchestrator) \
Orchestrates the automatic deployment of PAS using Ansible

### Modules

#### Python

* [pyAIM](https://pypi.org/project/pyaim/) \
CyberArk Application Access Manager Client Library for Python 3

#### PowerShell

* [CredentialRetriever PowerShell Module for CyberArk](https://github.com/pspete/CredentialRetriever) \
Retrieve Credentials from CyberArk Central Credential Provider Web Service, or Local Credential Provider using CLIPasswordSDK


## PGP Verification

[![infamousjoeg Keybase PGP Verification](https://badgen.net/keybase/pgp/infamousjoeg)](https://keybase.io/infamousjoeg)
