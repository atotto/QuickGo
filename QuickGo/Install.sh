#!/bin/sh

#  Install.sh
#  QuickGo
#
#  Created by Ato ARAKI on 2012/10/08.
#  Copyright (c) 2012 Ato ARAKI. All rights reserved.

if [ ! -d ~/Library/QuickLook/ ]
then
    mkdir -p ~/Library/QuickLook/
fi
cp -r QuickGo.qlgenerator ~/Library/QuickLook/
/usr/bin/qlmanage -r
