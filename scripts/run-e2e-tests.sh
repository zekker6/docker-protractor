#!/bin/bash
# Move to the Protractor test project folder
cd $HOME

echo "User name: " $(id -u -n)
echo "User ID (UID): " $(id -u)
echo "Home folder is: " $(pwd)
echo "Node version: " $(node --version)
echo "Yarn version: " $(yarn --version)

echo "Yarn directory: " $(yarn config get prefix)
echo "Protractor version: " $(protractor --version)

# Install the necessary packages
yarn install

# Verifies that versions and hashed value of the package contents in the project’s package.json matches that of yarn’s lock file.
# This helps to verify that the package dependencies have not been altered.
# https://github.com/yarnpkg/yarn/issues/3167
# yarn check --integrity
if [[ $RUN_YARN_CHECK == "y" ]]; then
    yarn check
fi

# Run the Selenium installation script, located in the local node_modules/ directory.
# This script downloads the files required to run Selenium itself and build a start script and a directory with them.
# When this script is finished, we can start the standalone version of Selenium with the Chrome driver by executing the start script.
node ./node_modules/protractor/bin/webdriver-manager update
# Right now this is not necessary, because of 'directConnect: true' in the 'protractor.conf.js'
# echo "Starting webdriver"
# node ./node_modules/protractor/bin/webdriver-manager start [OR webdriver-manager start] &"
# echo "Finished starting webdriver"

echo "Running Protractor tests"
# X11 for Ubuntu is not configured! The following configurations are needed for XVFB.
# Make a new display with virtual screen 0 with resolution 1920x1080 24dpi
xvfb-run --server-args="-screen 0 $PROTRACTOR_RESOLUTION_CONFIG" -a $@
export RESULT=$?

echo "Protractor tests have done"
# Remove temporary folders
rm -rf .config .local .pki .cache .dbus .gconf .mozilla
# Set the file access permissions (read, write and access) recursively for the result folders
chmod -Rf 777 reports

exit $RESULT
