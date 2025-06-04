#!/bin/bash
cd $HOME/juno
git fetch --tags && git checkout v29.0.0
make install
junod version
​
sudo systemctl restart junod && sudo journalctl -fu junod -o cat
