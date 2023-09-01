#!/bin/bash
MSG="OMEdit not available on Debian due to lack of Qt 4.7. Only the Ubuntu packages support OMEdit."
zenity --error --text="$MSG" >/dev/null 2>/dev/null || echo $MSG
