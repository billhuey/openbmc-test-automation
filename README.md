## Features of OpenBMC Test Automation ##

**Interface Feature List**
* REST
* DMTF Redfish
* Out-of-band IPMI
* SSH to BMC and Host OS

**Key Feature List**
* Power on/off
* Reboot Host
* Reset BMC
* Code update BMC and host
* Power management
* Fan controller
* HTX bootme
* XCAT execution
* Network
* IPMI support (generic and DCMI compliant)
* Factory reset
* RAS (Reliability, availability and serviceability)
* Web UI testing
* IO storage and EEH (Enhanced Error Handling) testing
* Secure boot
* SNMP (Simple Network Management Protocol)
* Remote Logging via Rsyslog
* LDAP (Lightweight Directory Access Protocol)
* Certificate

**Debugging Supported List**
* SOL collection
* FFDC collection
* Error injection from host

## Installation Setup Guide ##
* [Robot Framework Install Instruction](https://github.com/robotframework/robotframework/blob/master/INSTALL.rst)

* Miscellaneous
Packages required to be installed for OpenBmc Automation.
Install the packages and it's dependencies via `pip`

    REST base packages:
    ```
    $ pip install -U requests
    $ pip install -U robotframework-requests
    $ pip install -U robotframework-httplibrary
    ```

    Python redfish library packages:
    For more detailed intstructions see [python-redfish-library](https://github.com/DMTF/python-redfish-library)
    ```
    $ pip install redfish
    ```

    SSH and SCP base packages:
    For more detailed installation instructions see [robotframework-sshlibrary](https://pypi.python.org/pypi/robotframework-sshlibrary)
    ```
    $ pip install robotframework-sshlibrary
    $ pip install robotframework-scplibrary
    ```

    Installing tox:
    ```
    $ pip install -U tox
    ```

If using Python 3.x, use the corresponding `pip3` to install packages.

## OpenBMC Test Development ##

These documents contain details on developing OpenBMC test code and debugging.

 - [MAINTAINERS](https://github.com/openbmc/docs/blob/master/MAINTAINERS): OpenBMC code maintainers information.
 - [CONTRIBUTING.md](CONTRIBUTING.md): Coding guidelines.
 - [REST-cheatsheet.md](https://github.com/openbmc/docs/blob/master/REST-cheatsheet.md): Quick reference for some common
   curl commands required for testing.
 - [README.md](https://github.com/openbmc/phosphor-webui/blob/master/README.md): Web UI setup reference.
 - [Tools.md](https://github.com/openbmc/openbmc-test-automation/blob/master/docs/openbmc_test_tools.md): Reference information for helper tools.
 - [Corporate CLA and Individual CLA](https://github.com/openbmc/docs/blob/master/CONTRIBUTING.md#submitting-changes-via-gerrit-server): Submitting changes via Gerrit server

## Testing Setup Steps ##

To verify the installation setup is completed and ready to execute.

* Download the openbmc-test-automation repository:
    ```
    $ git clone https://github.com/openbmc/openbmc-test-automation
    $ cd openbmc-test-automation
    ```
* Execute basic setup test run:
    ```
    $ robot -v OPENBMC_HOST:xx.xx.xx.xx templates/test_openbmc_setup.robot
    ```
    where xx.xx.xx.xx is the BMC hostname or IP.

## Test Layout ##

There are several sub-directories within the openbmc-test-automation base which
contain test suites, tools, templates, etc. These sub-directories are
classified as follows:

`tests/`: Contains the general test cases for OpenBMC stack functional
          verification. The "tests" subdirectory uses legacy REST and will be
          deprecated at some point and therefore no longer supported.

`extended/`: Contains test cases for boot testing, code update testing, etc.

`systest/`: Contains test cases for HTX bootme, IO storage and EEH testing.

`xcat/`: Contains test cases for XCAT automation.

`gui/`: Contains test cases for web UI and security scanning tool automation.

`network/`: Contains test cases for network testing. It covers IPv4 in static mode
            and in DHCP mode.

`snmp/`: Contains test cases for SNMP (Simple Network Management Protocol)
         configuration testing.

`remote_logging`: Contains test cases for remote logging via rsyslog.

`openpower/ras/`: Contains test cases for RAS (Reliability, Availability and
                  Serviceability) for an OpenPOWER system.

`openpower/secureboot/`: Contains test cases for secure boot testing on a
                         secure boot feature enabled OpenPOWER system only.

`tools/`: Contains various tools.

`templates/`: Contains sample code examples and setup testing.

`test_list/`: Contains the argument files used for skipping test cases
              (e.g "skip_test", "skip_test_extended", etc.) or
              grouping them (e.g "HW_CI", "CT_basic_run", etc.).


## Redfish Test Layout ##

OpenBMC is moving steadily towards DTMF Redfish, which is an open industry standard
specification and schema that meets the expectations of end users for simple,
modern and secure management of scalable platform hardware.

`redfish`: Contains test cases for DMTF Redfish-related feature supported on OpenBMC.


## Quickstart ##
To run openbmc-automation first you need to install the prerequisite Python
packages which will help to invoke tests through tox (Note that tox
version 2.3.1 or greater is required) or via Robot CLI command.

**Robot Command Line**

* Execute all test suites for `tests/`:
    ```
    $ robot -v OPENBMC_HOST:xx.xx.xx.xx  tests
    ```

* Execute a test suite:
    ```
    $ robot -v OPENBMC_HOST:xx.xx.xx.xx  tests/test_basic_poweron.robot
    ```

* Initialize the following environment variables which will be used during testing:
    ```
    $ export OPENBMC_HOST=<openbmc machine ip address>
    $ export OPENBMC_PASSWORD=<openbmc password>
    $ export OPENBMC_USERNAME=<openbmc username>
    $ export OPENBMC_MODEL=[./data/Witherspoon.py, ./data/Palmetto.py, etc]
    $ export IPMI_COMMAND=<Dbus/External>
    $ export IPMI_PASSWORD=<External IPMI password>
    ```

* For QEMU tests, set the following environment variables as well:
    ```
    $ export SSH_PORT=<ssh port number>
    $ export HTTPS_PORT=<https port number>
    ```

* Run tests:
    ```
    $ tox -e tests
    ```

* How to run individual test:

    One specific test:
    ```
    $ tox -e default -- --include Power_On_Test  tests/test_basic_poweron.robot
    ```
    No preset environment variables, default configuration for all supported
    systems:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- tests
    ```
    No preset environment variables, one test case from a test suite:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --include Power_On_Test tests/test_basic_poweron.robot
    ```
    No preset environment variables, the entire test suite:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- tests
    ```

    No preset environment variables, the entire test suite excluding test
    cases using argument file:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/skip_test tests
    ```

    Exclude test list for supported systems:
    ```
    Palmetto:  test_lists/skip_test_palmetto
    Witherspoon:  test_lists/skip_test_witherspoon
    ```


* Run IPMI tests:

    Running only out-of-band IPMI tests:
    ```
    $ robot -v IPMI_COMMAND:External -v OPENBMC_HOST:x.x.x.x --argumentfile test_lists/witherspoon/skip_inband_ipmi tests/ipmi/
    ```

    Running only inband IPMI tests:
    ```
    $ robot -v IPMI_COMMAND:Inband -v OPENBMC_HOST:x.x.x.x -v OS_HOST:x.x.x.x -v OS_USERNAME:xxxx -v OS_PASSWORD:xxxx --argumentfile test_lists/witherspoon/skip_oob_ipmi tests/ipmi/
    ```


* Run GUI tests:

    By default, GUI runs with Firefox browser and headless mode. Example with chrome browser and header mode:
    ```
    $ robot -v OPENBMC_HOST:x.x.x.x -v GUI_BROWSER:gc -v GUI_MODE:header gui/obmc_gui/test/
    ```

    Run GUI default CI test bucket:
    ```
    $ robot -v OPENBMC_HOST:x.x.x.x --argumentfile test_lists/BMC_WEB_CI gui/obmc_gui/test/
    ```

* Run LDAP tests:

    Before using LDAP test functions, be sure appropriate LDAP user(s) and group(s) have been created on your LDAP server.
    Note: There are multiple ways to create LDAP users / groups and all depend on your LDAP server.
    One common way for openldap is ldapadd / ldapmodify refer https://linux.die.net/man/1/ldapadd
    For ldapsearch, refer to "https://linux.die.net/man/1/ldapsearch".
    Microsoft ADS: refer to  https://searchwindowsserver.techtarget.com/definition/Microsoft-Active-Directory-Domain-Services-AD-DS
    ```
    $ cd tests_ldap/
    $ robot -v OPENBMC_HOST:x.x.x.x -v LDAP_SERVER_URI:<ldap(s)//LDAP Hostname / IP> -v LDAP_BIND_DN:<LDAP Bind DN> -v LDAP_BASE_DN:<LDAP Base DN> -v LDAP_BIND_DN_PASSWORD:<LDAP Bind password> -v LDAP_SEARCH_SCOPE:<LDAP search scope> -v LDAP_SERVER_TYPE:<LDAP server type> -v LDAP_USER:<LDAP user-id> -v LDAP_USER_PASSWORD:<LDAP PASSWORD> -v GROUP_NAME:<Group Name> -v GROUP_PRIVILEGE:<Privilege>  test_user_ldap_management.robot
    ```

* How to run CI and CT bucket test:

    Default CI test bucket list:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/HW_CI tests
    ```

    Default CI smoke test bucket list:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/CT_basic_run tests
    ```

* Run extended tests:

    For-loop test (default iteration is 10):
    ```
    $ robot -v OPENBMC_HOST:x.x.x.x -v OPENBMC_SYSTEMMODEL:xxxxxx -v ITERATION:n -v LOOP_TEST_COMMAND:xxxxxx extended/full_suite_regression.robot
    ```

    Example using tox testing a test suite for 5 iterations "witherspoon":
    ```
    OPENBMC_HOST=x.x.x.x  LOOP_TEST_COMMAND="tests/test_fw_version.robot" ITERATION=5 OPENBMC_SYSTEMMODEL=witherspoon tox -e witherspoon -- ./extended/full_suite_regression.robot
    ```

**Jenkins jobs tox commands**
* HW CI tox command:
    ```
    $ OPENBMC_HOST=x.x.x.x tox -e default -- --argumentfile test_lists/HW_CI tests
    ```

## Code Update ##

Currently supported BMC and PNOR update formats are UBI and non-UBI.
For code update information, please refer to [code-update.md](https://github.com/openbmc/docs/blob/master/code-update/code-update.md)


* UBI Format *

    For BMC code update, download the system type *.ubi.mdt.tar image from
    https://openpower.xyz/job/openbmc-build/ and run as follows:

    For Witherspoon system:
    ```
    $ cd extended/code_update/
    $ robot -v OPENBMC_HOST:x.x.x.x -v IMAGE_FILE_PATH:<image path>/obmc-phosphor-image-witherspoon.ubi.mtd.tar --include REST_BMC_Code_Update  bmc_code_update.robot
    ```

    For host code update, download the system type *.pnor.squashfs.tar image
    from https://openpower.xyz/job/openpower-op-build/ and run as follows:

    For Witherspoon system:
    ```
    $ cd extended/code_update/
    $ robot -v OPENBMC_HOST:x.x.x.x -v IMAGE_FILE_PATH:<image path>/witherspoon.pnor.squashfs.tar --include REST_Host_Code_Update  host_code_update.robot
    ```

* Non-UBI Format *

    For BMC code update, download the system type *all.tar image from
    https://openpower.xyz/job/openbmc-build/ and run as follows:

    For a Zaius system:
    ```
    $ cd extended/code_update/
    $ robot -v OPENBMC_HOST:x.x.x.x -v FILE_PATH:<image path>/zaius-<date time>.all.tar --include Initiate_Code_Update_BMC update_bmc.robot
    ```

    For host code update, download the system type *.pnor from
    https://openpower.xyz/job/openpower-op-build/ and run as follows:

    For a Zaius system:
    ```
    $ cd extended/
    $ robot -v OPENBMC_HOST:x.x.x.x -v PNOR_IMAGE_PATH:<image path>/zaius.pnor test_bios_update.robot
    ```
