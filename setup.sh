#!/bin/bash

# Purpose:  Set up needed modules and environment to run the security fix locally
# Author:  Tom Wolstencroft
# Date: 9/1/16

puppet module install herculesteam-augeasproviders_sysctl


puppet apply /opt/dv-security/manifests/init.pp

