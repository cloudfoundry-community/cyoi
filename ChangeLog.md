# Change Log

Cyoi (choose-your-own-infrastructure) is a library to ask an end-user to choose an infrastructure (AWS, OpenStack, etc), region, and login credentials.

## v0.4

* switch to using readwritesettings instead of fork of settingslogic

## v0.3

* added `cyoi keypair` & `cyoi key_pair`

## v0.2

* executable `cyoi` became `cyoi provider`
* added `cyoi address` to prompt or provision an IP address (AWS only at moment)

## v0.1

Initial release

* executable `cyoi [settings.yml]` - asks for provider information and stores in settings.yml (AWS & OpenStack)
