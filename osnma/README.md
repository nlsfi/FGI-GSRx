# FGI-OSNMA

FGI-OSNMA is a Galileo Open Service Navigation Message Authentication (OSNMA)
implementation done with flexibility and integrability in mind. FGI-OSNMA can
be used as a library in third-party applications, or alternatively, the command
line utilities can be used for navigation message authentication and related
functionalities.

## Data

FGI-OSNMA (and OSNMA in general) functions by collecting nominal Galileo
I/NAV pages that will be accumulated into sub-frames (15 nominal pages). The
OSNMA material and the navigation messages are extracted from the sub-frames,
and the OSNMA material is used to authenticate the navigation message.

Therefore, the raw navigation pages are required to perform the processing.
At the moment these are available for example from Septentrio receiver (from
the GALRawINAV blocks).

At the moment FGI-OSNMA only supports the Septentrio Binary Format (SBF),
though the SBF can be read from either a file, network socket, or serial port.

## Subscriber system

Occurring events, such as authentication attempts or other authentication
related information, will be handled by executing callback function registered
in the `SubscriberSystem` class. The user can register custom
callbacks/subscribers by creating a class implementing the `Subscriber` class,
and registering it in the `datasink/subconfig.py` file.

## Usage

As a Python project, FGI-OSNMA is cross-platform. The project has been tested
under Linux and Windows.

### CLI

The command line interface (CLI) programs are located under `app/`. To get
information on the arguments and options, use the `-h` or `--help` option with
the given program.

The CLI programs included in the project are the following:
- `osnma-cli`: the command line interface, and the main way to use the project
- `osnma-reporter`: produce visualization and compute statistics related to the
  authentication events produced by the `osnma-cli`
- `osnma-rinex-filter`: remove unauthenticated navigation messages from RINEX3
  navigation files. Uses the output of `osnma-cli`.

### Library

The class responsible for the main authentication loop is the `OsnmaEngine`
located in the `osnma/engine.py` file. The use of this class to handle the main
authentication loop can be seen from `app/osnma-cli`.

The user can create custom subscribers, which can execute callback function
when a subframe result with the authentication events arrives, or when other
information is received. Examples of this can be seen from the
`datasink/subscribers.py` file.

## Changelog/TODOs

- 14.09.2023: Initial import.

- TODO:
    - Extend documentation
    - Resolve TODOs in the code
    - Add link to ION-GNSS+ 2023 publication
    - Add unit tests
