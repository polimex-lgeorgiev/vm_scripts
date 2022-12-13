#!/bin/bash
sudo apt -y update && sudo apt -y upgrade
sudo apt -y autoremove --purge && sudo apt -y autoclean
sudo apt-get clean
