#!/bin/bash
source "$HOME/scripts/inject/simple/helpers.sh"
source "$HOME/scripts/inject/simple/io_helpers.sh"
source "$HOME/scripts/inject/composites/lsr/lsr.sh"

# Recompile
enable_lsr_silence
lsr_main_command compile

# Run installation
disable_lsr_silence
lsr_main_command install
