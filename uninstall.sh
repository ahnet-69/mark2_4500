# Create during installation
DIRPATH=/data/adb/mark2_4500

# Set paths
MODBINPATH=$DIRPATH/bin
MODDTBOPATH=$DIRPATH/dtbo

# Get current slot
SLOT=$(getprop ro.boot.slot_suffix)

if [ "$SLOT" != "_a" ] && [ "$SLOT" != "_b" ]; then
  echo "Failed to retrieve a valid slot"
  exit 1
else
  # Extract dtbo.img
  dd if=/dev/block/by-name/dtbo$SLOT of=$MODDTBOPATH/dtbo.img &> /dev/null
fi

if [ $? != 0 ]; then
  echo "Failed to extract dtbo.img"
  exit 1
fi

# Extract dtbo.dtbo
$MODBINPATH/mkdtimg dump $MODDTBOPATH/dtbo.img -b $MODDTBOPATH/dtbo.dtbo -o /dev/null

# Retrieve device model information
MODEL=$($MODBINPATH/fdtget $MODDTBOPATH/dtbo.dtbo.0 / model)

if [[ "$MODEL" =~ "PDX-203" ]]; then
  echo "Detected device: Xperia 1 II"
  $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/origin_pdx203.dtbo
elif [[ "$MODEL" =~ "PDX-204" ]]; then
  echo "Detected device: Xperia Pro"
  $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/origin_pdx203.dtbo
elif [[ "$MODEL" =~ "PDX-206" ]]; then
  echo "Detected device: Xperia 5 II"
  $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/origin_pdx206.dtbo
else
  echo "Unsupported device model"
  exit 1
fi

# Generate new_dtbo.img
$MODBINPATH/mkdtimg create $MODDTBOPATH/new_dtbo.img --page_size=4096 $MODDTBOPATH/new_dtbo.dtbo &> /dev/null

# Flash dtbo
dd if=$MODDTBOPATH/new_dtbo.img of=/dev/block/by-name/dtbo$SLOT &> /dev/null

if [ $? != 0 ]; then
  echo "Failed to restore dtbo.img"
  exit 1
fi

echo "bye"
# Clean up leftovers
rm -rf $DIRPATH
