# Warning
warning () {
  ui_print "***************************************"
  ui_print "********      !!! WARNING !!!     *********"
  ui_print "***************************************"
  ui_print "**  Please ensure you have a computer at hand and have backed up dtbo.img  **"
  ui_print "**  This script is only for second-gen devices using a third-gen battery  **"
  ui_print "**  Since battery information cannot be detected, please verify it yourself  **"
  ui_print "**  A device restart is required after installation  **"
  ui_print "**  The first installation may cause abnormal battery readings  **"
  ui_print "**  No need to worry, just use and charge as normal  **"
  ui_print "***************************************"
}

# First-time installation prompt
TIMESTAMP=`date +%s`
DIRPATH=/data/adb/mark2_4500

# Display warning message
warning

mkdir $DIRPATH

# Set paths
MODBINPATH=$MODPATH/bin
MODDTBOPATH=$MODPATH/dtbo

# Grant execution permissions
chmod +x $MODBINPATH/*

# For uninstallation
cp -rf $MODBINPATH $MODDTBOPATH $DIRPATH

# Get current slot
SLOT=$(getprop ro.boot.slot_suffix)

if [ "$SLOT" != "_a" ] && [ $SLOT != "_b" ]; then
  ui_print "**  Failed to retrieve valid slot  **"
  abort "***************************************"
else
  # Extract dtbo.img
  dd if=/dev/block/by-name/dtbo$SLOT of=$MODDTBOPATH/dtbo.img &> /dev/null
fi

if [ $? != 0 ]; then
  ui_print "**  Failed to extract dtbo.img  **"
  abort "***************************************"
fi

# Extract dtbo.dtbo
$MODBINPATH/mkdtimg dump $MODDTBOPATH/dtbo.img -b $MODDTBOPATH/dtbo.dtbo -o /dev/null

# Retrieve device model information
MODEL=$($MODBINPATH/fdtget $MODDTBOPATH/dtbo.dtbo.0 / model)

if [[ "$MODEL" =~ "PDX-203" ]]; then
  ui_print "**  Detected device: Xperia 1 II  **"
  $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/overlay_pdx203.dtbo
  rm $MODPATH/system/product/overlay/FrameworkRes-PDX206-PowerProfile.apk
elif [[ "$MODEL" =~ "PDX-204" ]]; then
  ui_print "**  Detected device: Xperia Pro  **"
  $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/overlay_pdx203.dtbo
  rm $MODPATH/system/product/overlay/FrameworkRes-PDX206-PowerProfile.apk
elif [[ "$MODEL" =~ "PDX-206" ]]; then
  ui_print "**  Detected device: Xperia 5 II  **"
  $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/overlay_pdx206.dtbo
  rm $MODPATH/system/product/overlay/FrameworkRes-PDX203-PowerProfile.apk
else
  ui_print "**  Unsupported device model  **"
  abort "***************************************"
fi

# Generate new_dtbo.img
$MODBINPATH/mkdtimg create $MODDTBOPATH/new_dtbo.img --page_size=4096 $MODDTBOPATH/new_dtbo.dtbo &> /dev/null

# Flash dtbo
dd if=$MODDTBOPATH/new_dtbo.img of=/dev/block/by-name/dtbo$SLOT &> /dev/null

if [ $? != 0 ]; then
  ui_print "**  Failed to flash new_dtbo.img  **"
  abort "***************************************"
fi

ui_print "**  Installation successful, please restart the device  **"
ui_print "***************************************"
