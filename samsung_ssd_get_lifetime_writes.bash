#!/bin/bash

#######################################
# Variables                           #
#######################################

ON_TIME_TAG="Power_On_Hours"
WEAR_COUNT_TAG="Wear_Leveling_Count"
LBAS_WRITTEN_TAG="Total_LBAs_Written"
LBA_SIZE=512 # Value in bytes

BYTES_PER_MB=1048576
BYTES_PER_GB=1073741824
BYTES_PER_TB=1099511627776

#######################################
# Get total data written...           #
#######################################

function show_info(){
	# Get SMART attributes
	SMART_INFO=$(sudo /usr/sbin/smartctl -A "$SSD_DEVICE")

	# Extract required attributes
	ON_TIME=$(echo "$SMART_INFO" | grep "$ON_TIME_TAG" | awk '{print $10}')
	WEAR_COUNT=$(echo "$SMART_INFO" | grep "$WEAR_COUNT_TAG" | awk '{print $4}' | sed 's/^0*//')
	LBAS_WRITTEN=$(echo "$SMART_INFO" | grep "$LBAS_WRITTEN_TAG" | awk '{print $10}')

	# Convert LBAs -> bytes
	BYTES_WRITTEN=$(echo "$LBAS_WRITTEN * $LBA_SIZE" | bc)
	MB_WRITTEN=$(echo "scale=3; $BYTES_WRITTEN / $BYTES_PER_MB" | bc)
	GB_WRITTEN=$(echo "scale=3; $BYTES_WRITTEN / $BYTES_PER_GB" | bc)
	TB_WRITTEN=$(echo "scale=3; $BYTES_WRITTEN / $BYTES_PER_TB" | bc)

	# Output results...
	echo "------------------------------"
	echo " SSD Status:   $SSD_DEVICE"
	echo "------------------------------"
	echo " On time:      $(echo $ON_TIME | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta') hr"
	echo "------------------------------"
	echo " Data written:"
	echo "           MB: $(echo $MB_WRITTEN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')"
	echo "           GB: $(echo $GB_WRITTEN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')"
	echo "           TB: $(echo $TB_WRITTEN | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')"
	echo "------------------------------"
	echo " Mean write rate:"
	echo "        MB/hr: $(echo "scale=3; $MB_WRITTEN / $ON_TIME" | bc | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')"
	echo "------------------------------"
	echo " Drive health: ${WEAR_COUNT} %"
	echo "------------------------------"
}

if [[ -n $1 ]]; then
	SSD_DEVICE=$1
	hdparm -I $SSD_DEVICE 2>/dev/null | grep 'Nominal Media Rotation Rate: Solid State Device' > /dev/null
	if [[ $? -ne 0 ]]; then
		echo "$SSD_DEVICE is not a solid state device!" >&2
		exit 1
	fi
	show_info
else
	for SSD_DEVICE in /dev/sd*[^0-9]; do
		hdparm -I $SSD_DEVICE 2>/dev/null | grep 'Nominal Media Rotation Rate: Solid State Device' > /dev/null
		[[ $? -eq 0 ]] && show_info
	done
fi
