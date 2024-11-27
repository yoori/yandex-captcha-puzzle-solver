#!/bin/bash

# should be runned under root

INSTALL_ROOT="$1"
CHROME_VERSION="$2"

mkdir -p "$INSTALL_ROOT"

curl "https://dl.google.com/linux/linux_signing_key.pub" 2>/dev/null | tee /etc/apt/trusted.gpg.d/google.asc >/dev/null

touch /etc/apt/sources.list.d/chrome-find-repos.list
echo 'deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main' >>/etc/apt/sources.list.d/chrome-find-repos.list

apt update -y --no-install-recommends >/dev/null 2>&1
mkdir -p "$INSTALL_ROOT"

apt list --all-versions 2>/dev/null | grep -E '^(google-chrome-.*|chromium/)' | \
  tr '\t' ' ' >/tmp/available_all_chrome_versions

cat /tmp/available_all_chrome_versions | awk -F' ' '{if($3 = "'"$(arch)"'"){print $0}}' \
  >/tmp/available_platform_chrome_versions

FOUND_VERSION=$(cat /tmp/available_platform_chrome_versions |
  awk '{ if ($2 ~ /^'"$(echo "$CHROME_VERSION" | sed 's/[.]/\\\./')"'/) {print $1" "$2} }' |
  sed -r 's|(^[^ ]+)/[^ ]+ (.*)$|\1 \2|' | head -n1 | tr ' ' '=')

if [ "$FOUND_VERSION" = "" ] ; then
  echo "Can't find chrome of required version: $CHROME_VERSION , all available versions (for all platforms):" >&2
  cat /tmp/available_all_chrome_versions >&2
  echo "Version available for your platform ($(arch)):" >&2
  cat /tmp/available_platform_chrome_versions >&2
  exit 1
fi

echo "To install package: $FOUND_VERSION"

apt remove -y "$(echo "$FOUND_VERSION" | awk -F= '{print $1}')" >/dev/null 2>&1

rm -rf /tmp/chrome_download >/dev/null
mkdir /tmp/chrome_download
pushd /tmp/chrome_download >/dev/null 2>&1

apt download "$FOUND_VERSION" >/tmp/chrome_install.err 2>&1 || (
  echo "Chrome install failed:" >&2 ; cat /tmp/chrome_install.err >&2 ;
  echo "Available versions: " >&2 ; cat /tmp/available_chrome_versions >&2 ;
  exit 1 ;
) || exit 1

find . -type f -exec dpkg-deb -R {} "$INSTALL_ROOT" \;

popd
