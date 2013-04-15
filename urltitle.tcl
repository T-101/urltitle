# Script to grab titles from webpages
# Updated version by teel @ IRCnet
#
# Detects URL from IRC channels and prints out the title
#
# Version Log:
# 0.02     Updated version by teel. Added support for redirects, trimmed titles (remove extra whitespaces), some optimization
# 0.01a    Original version by rosc
#
################################################################################################################
# 
# Original script:
# Copyright C.Leonhardt (rosc2112 at yahoo com) Aug.11.2007 
# http://members.dandy.net/~fbn/urltitle.tcl.txt
# Loosely based on the tinyurl script by Jer and other bits and pieces of my own..
#
################################################################################################################
#
# Usage: 
#
# 1) Set the configs below
# 2) .chanset #channelname +urltitle        ;# enable script
# 3) .chanset #channelname +logurltitle     ;# enable logging
# Then just input a url in channel and the script will retrieve the title from the corresponding page.
#
# When reporting bugs, PLEASE include the .set errorInfo debug info! 
# Read here: http://forum.egghelp.org/viewtopic.php?t=10215
#
################################################################################################################

namespace eval UrlTitle {
  package require http                ;# You need the http package..

  # CONFIG
  set ignore "bdkqr|dkqr"   ;# User flags script will ignore input from
  set length 5              ;# minimum url length to trigger channel eggdrop use
  set delay 1               ;# minimum seconds to wait before another eggdrop use
  set timeout 5000          ;# geturl timeout (1/1000ths of a second)

  # BINDS
  bind pubm "-|-" {*://*} UrlTitle::handler
  setudef flag urltitle               ;# Channel flag to enable script.
  setudef flag logurltitle            ;# Channel flag to enable logging of script.

  set last 1                ;# Internal variable, stores time of last eggdrop use, don't change..
  set scriptVersion 0.02

  proc handler {nick host user chan text} {
    variable delay
    variable last
    variable ignore
    variable length
    set unixtime [clock seconds]
    if {[channel get $chan urltitle] && ($unixtime - $delay) > $last && (![matchattr $user $ignore])} {
      foreach word [split $text] {
        if {[string length $word] >= $length && [regexp {^(f|ht)tp(s|)://} $word] && ![regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
          set last $unixtime
          set urtitle [UrlTitle::parse $word]
          if {[string length $urtitle]} {
            putserv "PRIVMSG $chan :Title: $urtitle"
          }
          break
        }
      }
    }
    # change to return 0 if you want the pubm trigger logged additionally..
    return 1
  }

  proc parse {url} {
    variable timeout
    set title ""
    if {[info exists url] && [string length $url]} {
      if {[catch {set http [::http::geturl $url -timeout $timeout]} results]} {
        putlog "Connection to $url failed"
      } else {
        if { [::http::status $http] == "ok" } {
          set data [::http::data $http]
          set status [::http::code $http]
          set meta [::http::meta $http]
          switch -regexp -- $status {
            "HTTP.*200.*" {
              regexp -nocase {<title>(.*?)</title>} $data match title
              set title [string trim $title]
            }
            "HTTP\/[0-1]\.[0-1].3.*" {
              regexp -nocase {Location\s(http[^\s]+)} $meta match location
              set title [UrlTitle::parse $location]
            }
          }
          ::http::cleanup $http
        } else {
          putlog "Connection to $url failed"
        }
      }
    }
    return $title
  }

  putlog "Initialize Url Title Grabber v$scriptVersion"
}