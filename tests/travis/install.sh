#!/usr/bin/env bash

# NAME
#     install.sh - Install Travis CI dependencies
#
# SYNOPSIS
#     install.sh
#
# DESCRIPTION
#     Creates the test fixture.

cd "$(dirname "$0")"; source ../../../orca/bin/travis/_includes.sh

assert_env_vars

[[ "$ORCA_JOB" != "DEPRECATED_CODE_SCAN_SUT" ]] || orca fixture:init -f --sut=${ORCA_SUT_NAME} --sut-only --no-site-install

[[ "$ORCA_JOB" != "DEPRECATED_CODE_SCAN_CONTRIB" ]] || orca fixture:init -f --sut=${ORCA_SUT_NAME} --sut-only --no-site-install

[[ "$ORCA_JOB" != "ISOLATED_RECOMMENDED" ]] || orca fixture:init -f --sut=${ORCA_SUT_NAME} --sut-only --profile=${ORCA_PROFILE}

[[ "$ORCA_JOB" != "INTEGRATED_RECOMMENDED" ]] || orca fixture:init -f --sut=${ORCA_SUT_NAME} --profile=${ORCA_PROFILE}

[[ "$ORCA_JOB" != "CORE_PREVIOUS" ]] || orca fixture:init -f --sut=${ORCA_SUT_NAME} --core=PREVIOUS_RELEASE --profile=${ORCA_PROFILE}

[[ "$ORCA_JOB" != "ISOLATED_DEV" ]] || orca fixture:init -f --sut=${ORCA_SUT_NAME} --sut-only --dev --profile=${ORCA_PROFILE}

[[ "$ORCA_JOB" != "INTEGRATED_DEV" ]] || orca fixture:init -f --sut=${ORCA_SUT_NAME} --dev --profile=${ORCA_PROFILE}

[[ "$ORCA_JOB" != "CORE_NEXT" ]] || orca fixture:init -f --sut=${ORCA_SUT_NAME} --core=NEXT_DEV --dev --profile=${ORCA_PROFILE}

if [[ ! "$ORCA_JOB" && "$DB_FIXTURE" ]]; then
  orca fixture:init -f --sut=acquia/headless_lightning --sut-only --no-site-install

  cd "$ORCA_FIXTURE_DIR/docroot"

  DB="$TRAVIS_BUILD_DIR/tests/fixtures/$DB_FIXTURE.php.gz"

  php core/scripts/db-tools.php import ${DB}

  drush php:script "$TRAVIS_BUILD_DIR/tests/update.php"

  # Ensure menu_ui is installed.
  drush pm-enable menu_ui --yes

  drush updatedb --yes
  drush update:lightning --no-interaction --yes

  # Reinstall modules which were blown away by the database restore.
  orca fixture:enable-modules

  # Reinstall from exported configuration to prove that it's coherent.
  drush config:export --yes
  drush site:install --yes --existing-config

  drush config:set moderation_dashboard.settings redirect_on_login 1 --yes

  # Set the fixture state to reset to between tests.
  orca fixture:backup -f
fi
