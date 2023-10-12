#!/bin/bash

msp430-emu run &
msp430-emu-gui && echo "Waiting for emulator exit" && wait
