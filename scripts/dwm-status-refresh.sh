#!/bin/bash
# Screenshot: http://s.natalian.org/2013-08-17/dwm_status.png
# Network speed stuff stolen from http://linuxclues.blogspot.sg/2009/11/shell-script-show-network-speed.html

CPUCOL="^c#a1f8b1^"
LIGHTCOL="^c#f9ad4f^"
MEMCOL="^c#92d2fc^"
TEMPCOL="^c#ffc4d3^"
DOTCOL="^c#75D701^"
BATCOL="^c#5b72c6^"
CHARCOL="^c#76daff^"
TEXTCOL="^c#ffffff^"
print_mem(){
 # memfree=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024 |bc   ))M
    #memfree=$(awk '/MemAvailable/ { printf "%.2f", $2/1024/1024}' /proc/meminfo)G
    memfree=$(free --mebi | sed -n '2{p;q}' | awk '{printf ("%2.2fG\n", ( $3 / 1024))}')
    echo -e "$MEMCOL $TEXTCOL$memfree"
}




print_bat(){
    #hash acpi || return 0
    #onl="$(grep "on-line" <(acpi -V))"
    #charge="$(awk '{ sum += $1 } END { print sum }' /sys/class/power_supply/BAT*/capacity)%"
    #if test -z "$onl"
    #then
        ## suspend when we close the lid
        ##systemctl --user stop inhibit-lid-sleep-on-battery.service
        #echo -e "${charge}"
    #else
        ## On mains! no need to suspend
        ##systemctl --user start inhibit-lid-sleep-on-battery.service
        #echo -e "${charge}"
    #fi
    #echo "$(get_battery_charging_status) $(get_battery_combined_percent)%, $(get_time_until_charged )";
    echo "$(get_battery_charging_status)  $TEXTCOL$(get_battery_combined_percent)";
}

get_battery_charging_status() {
    if $(acpi -b | grep --quiet Discharging)
    then
        echo "$BATCOL ";
    else # acpi can give Unknown or Charging if charging, https://unix.stackexchange.com/questions/203741/lenovo-t440s-battery-status-unknown-but-charging
        echo "$CHARCOL";
    fi
}

get_backlight() {
  xlight=$(xbacklight -get)
  echo "$LIGHTCOL  $TEXTCOL$xlight"
}



dwm_cpu() {
	cpu=$(cat ~/logs/cpu)
  echo "$CPUCOL $TEXTCOL$cpu"%

}


get_battery_combined_percent() {
    # get charge of all batteries, combine them
    total_charge=$(expr $(acpi -b | awk '{print $4}' | grep -Eo "[0-9]+" | paste -sd+ | bc));
    # get amount of batteries in the device
    battery_number=$(acpi -b | wc -l);
    percent=$(expr $total_charge / $battery_number);
    
    echo $percent;
}

print_temp(){
    test -f /sys/class/thermal/thermal_zone0/temp || return 0
    echo "$TEMPCOL $TEXTCOL$(head -c 2 /sys/class/thermal/thermal_zone0/temp)°"
}

print_date(){
    date '+%a ^c#ffd701^%m/%d ^c#76daff^%H:%M'
}

LOC=$(readlink -f "$0")
DIR=$(dirname "$LOC")
export IDENTIFIER="unicode"

. "$DIR/dwmbar-functions/dwm_cpu.sh"
#. "$DIR/dwmbar-functions/dwm_dot.sh"
#. "$DIR/dwmbar-functions/dwm_battery.sh"
#. "$DIR/dwmbar-functions/dwm_ccurse.sh"
#. "$DIR/dwmbar-functions/dwm_cmus.sh"
#. "$DIR/dwmbar-functions/dwm_countdown.sh"
#. "$DIR/dwmbar-functions/dwm_date.sh"
#. "$DIR/dwmbar-functions/dwm_keyboard.sh"
#. "$DIR/dwmbar-functions/dwm_mail.sh"
# . "$DIR/dwmbar-functions/dwm_network.sh"
# . "$DIR/dwmbar-functions/dwm_pulse.sh"
#. "$DIR/dwmbar-functions/dwm_resources.sh"
#. "$DIR/dwmbar-functions/dwm_transmission.sh"
#. "$DIR/dwmbar-functions/dwm_vpn.sh"
#. "$DIR/dwmbar-functions/dwm_weather.sh"

# This function parses /proc/net/dev file searching for a line containing $interface data.
# Within that line, the first and ninth numbers after ':' are respectively the received and transmited bytes.
function get_bytes {
	# Find active network interface
	interface=$(ip route get 8.8.8.8 2>/dev/null| awk '{print $5}')
	line=$(grep $interface /proc/net/dev | cut -d ':' -f 2 | awk '{print "received_bytes="$1, "transmitted_bytes="$9}')
	eval $line
	now=$(date +%s%N)
}

# Function which calculates the speed using actual and old byte number.
# Speed is shown in KByte per second when greater or equal than 1 KByte per second.
# This function should be called each second.
function get_velocity {
	value=$1
	old_value=$2
	now=$3

	timediff=$(($now - $old_time))
	velKB=$(echo "1000000000*($value-$old_value)/1024/$timediff" | bc)
	if test "$velKB" -gt 1024
	then
		echo $(echo "scale=2; $velKB/1024" | bc)MB/s
	else
		echo ${velKB}KB/s
	fi
}

# Get initial values
get_bytes
old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
old_time=$now

#!/bin/bash
get_bytes

# Calculates speeds
vel_recv=$(get_velocity $received_bytes $old_received_bytes $now)
vel_trans=$(get_velocity $transmitted_bytes $old_transmitted_bytes $now)

# Update old values to perform new calculations
old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
old_time=$now

# xsetroot -name "$(dwm_network) $(dwm_cpu)  $(print_mem)  ^b#111111^  $(print_bat)  $(print_temp)  $(dwm_pulse)  $(get_backlight)   ^d^   [$(print_date)^d^]"
xsetroot -name "[$MEMCOL⬇️ $TEXTCOL$vel_recv $MEMCOL⬆️ $TEXTCOL$vel_trans^d^] $(dwm_cpu) ^d^ $(print_mem) ^d^ $(print_temp) ^d^ [$(print_date)]"

exit 0

