<img src="./assets/LSR_trans_white.png" />

# Lukes script repository
A package of handy bash tools/command for software development and personal purposes.

I created these scripts because I love automating my life at work and my personal administration. Feel free to use and even modify these scripts.

They are mainly written to be used in WLS2 Ubuntu, but I am planning to make it work on any system that supports bash out of the box.

LSR is easy to use, compiles itself, and can automatically be installed/updated/deinstalled.

## Installation guide
To install Lukes script repository. you need to run 2 simple commands.

```bash
# Clone the repository into ~/scripts
git clone https://github.com/justlucdewit/scripts ~/scripts

# Execute the install script
sudo ~/scripts/_install.sh
```

This should succesfully install Lukes Script Repository. No restart is needed.
Everything should be emediately available

## Usage
The following is a list of commands to be used in LSR

### **Simple Standalone Commands**

| command | usage | description |
|---------|-------|-------------|
| c | c | clear the terminal |
| l | l | display a vertical list of files/folders in the current working directory |
| p | p <projectname> | jump to the location of a project |
| rb | rb | reload bash (sources the bashrc file) |


### **Tmux commands**
| command | usage | description |
|---------|-------|-------------|
| t | t | open tmux in the current dir |
| shor | shor | Split the current pane horizontally |
| sver | sver | Split the current pane vertically |
| ml | ml | move to the pane on the left |
| mr | mr | move to the pane on the right |
| mu | mu | move to the pane that is upwards |
| md | md | move to the pane that is downward |
| el | el <n=5> | expand pane n columns to the left |
| er | er <n=5> | expand pane n columns to the right |
| eu | eu <n=5> | expand pane n columns up |
| ed | ed <n=5> | expand pane n columns down |
| tls | tls | lists all of the panes in all of the windows in all of the sessions |
| rp | rp <name> | rename the pane to the given name |
| tc | tc | close the current pane |
| tca | tca | close all panes |
| rip | rip <pane num> <command> | runs a command in the given pane |

# TODO:
 - SSH helpers
 - Saving and starting with previous path
 - use helper prints for everything
 - --fuzzy argument for codefind
 - Ensure no double build
 - npmscripts --show
 - ChatGpt command 