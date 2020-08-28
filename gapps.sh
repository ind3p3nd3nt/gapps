#!/usr/bin/env bash
ZIPFILE=${1}
USAGESTRING="Usage: ${0} open_gapps_zip_file.zip";
TEMPDIR=/tmp/gapps_installer


if [ $# -lt 1 ]; then
  echo ${USAGESTRING};
  exit 1;
fi

if [ ! -f ${ZIPFILE} ]; then
  echo ${USAGESTRING};
  exit 2;
fi

if [ ! ${ANDROID_HOME} ]; then
  echo "ANDROID_HOME is not set"
  exit 3;
fi

if [ ! -d ${ANDROID_HOME} ]; then
  echo "ANDROID_HOME is not valid"
  exit 4;
fi
sudo apt install libc++-dev libtcmalloc-minimal4 unzip lzip tar adb;
rm -rf ${TEMPDIR} && mkdir -p ${TEMPDIR}
unzip ${ZIPFILE} 'Core/*' -d ${TEMPDIR}
cd ${TEMPDIR}
rm Core/setup*
lzip -d Core/*.lz
for f in $(ls Core/*.tar); do
  tar -x --strip-components 2 -f $f
done

echo "Which AVD?"
emulator -list-avds
echo -en "\n>"
read AVD

echo -en "\ndetermining location of system.img file for ${AVD} ..."
IMAGE_SYSDIR=`grep "image.sysdir.1" ${HOME}/.android/avd/${AVD}.avd/config.ini | cut -f2 -d"="`
echo "${ANDROID_HOME}/${IMAGE_SYSDIR}"

echo "copying, checking and resizing system.img for ${AVD}"
cp "${ANDROID_HOME}/${IMAGE_SYSDIR}system.img" "${HOME}/.android/avd/${AVD}.avd/system.img"
if [ -f "${ANDROID_HOME}/${IMAGE_SYSDIR}encryptionkey.img" ]; then
  echo "copying encryptionkey.img ..."
  cp "${ANDROID_HOME}/${IMAGE_SYSDIR}encryptionkey.img" "${HOME}/.android/avd/${AVD}.avd/encryptionkey.img"
fi
"${ANDROID_HOME}/emulator/bin64/e2fsck" -f "${HOME}/.android/avd/${AVD}.avd/system.img"
"${ANDROID_HOME}/emulator/bin64/resize2fs" "${HOME}/.android/avd/${AVD}.avd/system.img" 3072M

echo "starting ${AVD}"

${ANDROID_HOME}/tools/emulator -netdelay none -netspeed full -avd ${AVD} -partition-size 1024 -writable-system > /dev/null 2>&1 &


read -r -p "Has the emulator booted ? Do you want to continue? [Y/n] " input 
case $input in ([yY][eE][sS]|[yY])


sudo adb root
sudo adb disable-verity
sudo adb reboot
esac
read -r -p "Has the emulator finished rebooting ? Do you want to continue? [Y/n] " input 
case $input in ([yY][eE][sS]|[yY])
sudo adb remount
sudo adb shell "mount -o remount,rw /sys"
sudo adb push etc /system
sudo adb push framework /system
sudo adb push app /system
sudo adb push priv-app /system

sleep 5
echo "Restart android in your emulator"
echo "done."
esac
