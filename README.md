# Drum-Machine
A Drum Machine built like a sequencer using [Turbo x86 Assembler](https://sourceforge.net/projects/guitasm8086/)

## How to Run
To run use tasm with dos-box emulator<br>
First, download, install and run [DOSBOX (an x86 emulator w/ DOS)](https://www.dosbox.com/download.php?main=1)
  - `cycles = max`
  - `mount c c:`
  - `c:`
  - Navigate to your local repository
  - `drums`

#### Important
Make sure you include the ui.bmp in the same directory.

#### To recompile using TASM and Tlink
  - tasm /zi drums.asm
  - tlink /v drums.obj
  - drums 

## How to Use
  - Arrow keys to move the green Cursor
  - Space to mark or unmark a position to be played (when its highlighted by the green cursor)
  - Backspace to unmark everything and init the sequencer
  - Enter to Play / Pause
  - Use - / + to decrease or increase the playing speed
  - To quit, press ESC

<br>
This project was built as part of CS class in 10th grade.<br>
Enjoy!
