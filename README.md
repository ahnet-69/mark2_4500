# mark2_4500
Expansion module for Xperia II series after replacing with third-generation battery

Translated to English with auto slot detection.
<br />
## This module does not make the battery last longer — do not flash it recklessly for that reason
<br />
<br />

Third-generation battery data comes from [sonyxperiadev/kernel](https://github.com/sonyxperiadev/kernel/tree/aosp/LA.UM.9.14.r1/arch/arm64/boot/dts/somc)
<br />

Only supports Xperia third-generation batteries, and modifies the following based on the data:
1. Maximum charging voltage
2. Maximum charging current
3. Battery protection voltage
4. Stepped charging voltages
5. Charging cutoff current
<br />

Data exists but cannot be modified:
1. Charging temperature curve
2. 30W fast charging
<br />
<br />

If you replaced with another third-party battery, do not use this module directly<br />
Ask the battery supplier for battery data and modify the above values yourself
<br />

The auto-packaging script provided in this project requires Linux and zip to be installed. After modifying the data, run `./build.sh`
