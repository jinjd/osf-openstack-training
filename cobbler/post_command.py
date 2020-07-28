#!/usr/bin/python
import os

os.system('cp /var/lib/cobbler/loaders/splash.xpm.gz   /var/lib/tftpboot/grub')
os.system('cp /mnt/ICOS.ks /var/lib/cobbler/kickstarts')
