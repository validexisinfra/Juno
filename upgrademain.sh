#!/bin/bash
cd $HOME/juno
git fetch --tags && git checkout v28.0.2
make install
junod version
​
sudo systemctl restart junod && sudo journalctl -fu junod -o cat
