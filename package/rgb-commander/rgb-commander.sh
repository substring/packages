#!/usr/bin/env bash
RGBCOMMANDER_LOGFILE="$GAT_LOGPATH"/rgbcommander.log

pre_launch() {
  local system="$1"
  local rom="$2"

  #
  # Run rgbcommander to set LEDs based on rom
  # roms are configured in /usr/bin/rgbcommander/rgbcmdd.xml
  #
  log_info  ""
  log_info  "Prelaunching rgbcommander. Args: $@"

  #
  # Check if rgbcommander daemon is running (rgbcmdd)
  #
  if pgrep -x "rgbcmdd" >/dev/null
  then
    log_info  " RGBCommander: LEDs set for $rom"
    rgbcmdcon set,rom,$rom &>> $RGBCOMMANDER_LOGFILE
  else 
    log_debug " RGBCommander service not running.... exiting"
    return 1  
  fi
  log_info ""
}

post_launch() {

  #
  # This is for future use.
  # RGBCommander automatically resets the front end animation 
  # when returnning from groovymame
  #
  log_info ""
  log_info "Postlaunching rgbcommander. Args: $@"

  #
  #check if rgbcommander daemon is running (rgbcmdd)
  #
  if pgrep -x "rgbcmdd" >/dev/null
  then
    log_info "RGBCommander: restarting front end LED animation"
  else 
    log_debug " RGBCommander service not running.... exiting"
    return 1  
  fi
  log_info ""
}
