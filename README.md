# UbuProv (Ubuntu-based Provisioner)

UbuProv is a script to install packages from a list in pkgs.txt, copy over certain scripts, files, configs, etc to appropriate locations, tweak and update GRUB, etc.

Currently functionality is very based.

### Roadmap

 * Create machine or function/task based package lists in separate files (i.e. system-ace.txt or function-general.txt)
 * Separate out into sub-scripts to clean up code, make it all more readable, etc.
 * Ensure UbuProv can be run fully unattended (currently certain packages have human interaction dialogs). 
