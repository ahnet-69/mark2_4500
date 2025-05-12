# Prev slot
STATE_DIR="/data/adb/mark2_4500"
STATE_FILE="$STATE_DIR/last_slot"

MODPATH="/data/adb/modules/mark2_4500"
MODBINPATH=$STATE_DIR/bin
MODDTBOPATH=$STATE_DIR/dtbo

mkdir -p "$STATE_DIR"
mkdir -p "$MODDTBOPATH"
chmod 0700 "$STATE_DIR"

# Re-copy dirs if deleted
cp -f $MODPATH/dtbo/*.dtbo $MODDTBOPATH
if [ ! -d "$MODBINPATH" ]; then
  cp -rf $MODPATH/bin $MODBINPATH
  chmod +x $MODBINPATH/*
fi

# Current slot
CUR_SLOT=$(getprop ro.boot.slot_suffix)

if [ "$CUR_SLOT" != "_a" ] && [ $CUR_SLOT != "_b" ]; then
   log -p w -t mark2_4500 "Failed to retrieve valid slot"
   exit 1
fi

# Check if last slot exists
if [ -f "$STATE_FILE" ]; then
  LAST_SLOT=$(head -n1 "$STATE_FILE")
  if [ "$LAST_SLOT" != "_a" ] && [ $LAST_SLOT != "_b" ]; then
     echo "$CUR_SLOT" > "$STATE_FILE"
     chmod 0600 "$STATE_FILE"
     LAST_SLOT="$CUR_SLOT"
  fi
else
  echo "$CUR_SLOT" > "$STATE_FILE"
  chmod 0600 "$STATE_FILE"
  LAST_SLOT="$CUR_SLOT"
fi

# Re-do patch if slot changed
if [ "$CUR_SLOT" != "$LAST_SLOT" ]; then

  # Wait until system is booted
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
  done

  log -p i -t mark2_4500 "Boot Completed, Slot change detected. Running dtbo patch"

  # Extract dtbo.dtbo
  dd if=/dev/block/by-name/dtbo$CUR_SLOT of=$MODDTBOPATH/dtbo.img &> /dev/null
  $MODBINPATH/mkdtimg dump $MODDTBOPATH/dtbo.img -b $MODDTBOPATH/dtbo.dtbo -o /dev/null

  # Retrieve device model information
  MODEL=$($MODBINPATH/fdtget $MODDTBOPATH/dtbo.dtbo.0 / model)

  if [[ "$MODEL" =~ "PDX-203" ]]; then
    log -p i -t mark2_4500 "Detected device: Xperia 1 II"
    $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/overlay_pdx203.dtbo
  elif [[ "$MODEL" =~ "PDX-204" ]]; then
    log -p i -t mark2_4500 "Detected device: Xperia Pro"
    $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/overlay_pdx203.dtbo
  elif [[ "$MODEL" =~ "PDX-206" ]]; then
    log -p i -t mark2_4500 "Detected device: Xperia 5 II"
    $MODBINPATH/fdtoverlay -i $MODDTBOPATH/dtbo.dtbo.0 -o $MODDTBOPATH/new_dtbo.dtbo $MODDTBOPATH/overlay_pdx206.dtbo
  else
    log -p w -t mark2_4500 "Unsupported model ($MODEL), skipping DTBO patch"
    exit 1
  fi

  # Generate new_dtbo.img
  $MODBINPATH/mkdtimg create $MODDTBOPATH/new_dtbo.img --page_size=4096 $MODDTBOPATH/new_dtbo.dtbo &> /dev/null

  # Flash dtbo
  dd if=$MODDTBOPATH/new_dtbo.img of=/dev/block/by-name/dtbo$CUR_SLOT &> /dev/null

  echo "$CUR_SLOT" > "$STATE_FILE"
  chmod 0600 "$STATE_FILE"

  sed -i 's/^description=.*/description=⚠️‼️ SLOT CHANGED, DTBO REPATCHED, REBOOT TO APPLY CHANGES/' $MODPATH/module.prop

  log -p i -t mark2_4500 "Patching DTBO successful"

  # Remove these files - No longer needed
  rm -rf $MODDTBOPATH/dtbo $MODDTBOPATH/dtbo.dtbo.0 $MODDTBOPATH/*.img $MODDTBOPATH/new_dtbo.dtbo
else
  sed -i 's/^description=.*/description=✅ DTBO Patched Already, No Actions taken/' $MODPATH/module.prop
fi
