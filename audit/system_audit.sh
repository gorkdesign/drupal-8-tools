#!/usr/bin/env bash

# Invoke the script from anywhere (e.g .bashrc alias).
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/common

# Make sure only root can execute the script.
if [[ "$(whoami)" != "root" ]]; then
  echo -e "${RED}You are required to run this script as root or with sudo! Aborting...${COLOR_ENDING}"
  exit 1
fi

MYSQL_MINIMUM="$(mysql -V | awk '{print $5}' | head -c 5)"
PHP_MINIMUM="$(php -v | awk '{print $2}' | head -c 5)"
DISABLE_FUNCTIONS="$(php -c /etc/php5/cli/php.ini -i | grep disable_functions | awk '{print $3$4}')"
DATE_TIMEZONE="$(grep "date.timezone" /etc/php5/apache2/php.ini | awk '{print $3}' | tail -1)"
DATE_TIMEZONE_CLI="$(grep "date.timezone" /etc/php5/cli/php.ini | awk '{print $3}' | tail -1)"
TWIG_EXTENSION="$(grep "extension=twig.so" /etc/php5/apache2/php.ini)"
TWIG_EXTENSION_CLI="$(grep "extension=twig.so" /etc/php5/cli/php.ini)"
XDEBUG_NESTING="$(grep "xdebug.max_nesting_level" /etc/php5/apache2/php.ini | awk '{print $3}')"
XDEBUG_NESTING_CLI="$(grep "xdebug.max_nesting_level" /etc/php5/cli/php.ini | awk '{print $3}')"

# Minimum required MySQL version.
if [[ "${MYSQL_MINIMUM}" < "5.5.3" ]]; then
  echo -e "Your MySQL version is too old (${MYSQL_MINIMUM}). Minimum requirement for Drupal 8 is PHP 5.5.3 ${RED}[ERROR]${COLOR_ENDING}"
else
  echo -e "MySQL version is ${MYSQL_MINIMUM} ${GREEN}[OK]${COLOR_ENDING}"
fi

# Minimum required PHP version.
if [[ "${PHP_MINIMUM}" < "5.4.2" ]]; then
  echo -e "Your PHP version is too old (${PHP_MINIMUM}). Minimum requirement for Drupal 8 is PHP 5.4.2 ${RED}[ERROR]${COLOR_ENDING}"
else
  echo -e "PHP version is ${PHP_MINIMUM} ${GREEN}[OK]${COLOR_ENDING}"
fi

# Drush requires PHP's disable_functions to be empty, except for PHP 5.5 - See https://github.com/drush-ops/drush/pull/357
if [[ "${DISABLE_FUNCTIONS}" == "novalue" ]]; then
  echo -e "PHP CLI's disable_functions are turned off ${GREEN}[OK]${COLOR_ENDING}"
else
  echo -e "PHP CLI's disable_functions are turned on and might cause issues with Drush. ${RED}[ERROR]${COLOR_ENDING}"
fi

# date.timezone needs to be set.
if [[ -z "${DATE_TIMEZONE}" ]] || [[ -z "${DATE_TIMEZONE_CLI}" ]]; then
  echo -e "PHP's date.timezone is not set. You should check your apache2 and CLI php.ini file settings. ${RED}[ERROR]${COLOR_ENDING}"
else
  echo -e "PHP's date.timezone is set ${GREEN}[OK]${COLOR_ENDING}"
fi

# The Twig C extension should ideally be enabled.
if [[ -z "${TWIG_EXTENSION}" ]] || [[ -z "${TWIG_EXTENSION_CLI}" ]]; then
  echo -e "The Twig C extension is not set. You should check your apache2 and CLI php.ini file settings or install the extension. See http://twig.sensiolabs.org/doc/installation.html#installing-the-c-extension. ${RED}[ERROR]${COLOR_ENDING}"
else
  echo -e "The Twig C extension is set ${GREEN}[OK]${COLOR_ENDING}"
fi

# If XDebug is enabled, then check max_nesting_level.
if [[ "${XDEBUG_NESTING}" < 256 ]] || [[ "${XDEBUG_NESTING_CLI}" < 256 ]]; then
  echo -e "PHP's xdebug.max_nesting_level should be set to 256 at a minimum. ${RED}[ERROR]${COLOR_ENDING}"
else
  echo -e "PHP's xdebug.max_nesting_level is correctly set. ${GREEN}[OK]${COLOR_ENDING}"
fi
