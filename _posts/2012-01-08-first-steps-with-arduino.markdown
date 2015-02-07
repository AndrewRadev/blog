---
layout: post
title: "First Steps With Arduino"
date: 2012-01-08 17:58
comments: true
categories: arduino
---

I finally bought an Arduino to play around with. Considering I'm studying
robotics, it's a good first step. If the word doesn't ring a bell, an "Arduino"
is a simple programmable chip. You can write code (a "sketch") in a subset of
C++ and then upload it to the board. You can wire all kinds of sensors and
motors to the Arduino and build some pretty cool stuff
([a sliding door](http://lifehacker.com/5863112/make-your-own-star-treksupermarket-automatic-pneumatic-door),
[a portal turret plush toy](http://upnotnorth.net/projects/portal-turret-plushie/)).

Naturally, starting something new, I ran into a few bumps. While there's a ton
of information on the Arduino forums, and even in the Arch Linux wiki, it was
still a bit of an adventure to get the ball rolling on my machine.

In this post, I'll describe the solutions to a few of my issues. I'll also
explain how the compile and upload process works, at least to the extent of my
understanding, and how to get started with building through the command-line.
So, if you're not interested in my headaches, feel free to jump down to "Step
1: Preprocessing".

<!-- more -->

## Getting it to work

An [Arduino Uno](http://www.arduino.cc/en/Main/arduinoBoardUno) is probably the
most popular model at the moment. It connects to a computer through USB, but
the cable's other endpoint is a different kind of port, so there's some kind of
a translation going on. When the cable is connected, a device called
`/dev/ttyACM0` is created. The device name varies depending on the OS. After
plugging it in and running the java-based IDE with the `arduino` command, it
was a simple matter of choosing an example "sketch" (piece of code) and
uploading it to the board in order to get started.

While it all mostly "just worked", it did so only the first time. A second attempt to upload a sketch resulted in this error message:

```
avrdude: ser_open(): can't open device "/dev/ttyACM0": Input/output error
ioctl("TIOCMGET"): Invalid argument
```

Afterwards, the `/dev/ttyACM0` device had disappeared without a trace.
Unplugging the cable and putting it back again seemed to solve the issue, but
it wasn't exactly a very reasonable solution. So I did a `tail -f
/var/log/kernel.log`, and found that the failing upload was causing these
messages:

```
Dec 28 10:48:43 localhost kernel: [ 6506.042437] xhci_hcd 0000:0b:00.0: ERROR no room on ep ring
Dec 28 10:48:43 localhost kernel: [ 6506.042443] cdc_acm 2-1:1.1: acm_submit_read_urb - usb_submit_urb failed: -12
Dec 28 10:48:43 localhost kernel: [ 6506.042447] tty_port_close_start: tty->count = 1 port count = 0.
```

Googling for "no room on ep ring" found a lot of entries, but most were fairly
old and solutions involved recompiling the drivers with some experimental
patches. I assume it's an issue with the USB 3.0 ports on my laptop. To work
around this problem for now, I just reload the relevant kernel module like so:

``` bash
$ sudo modprobe -r xhci_hcd && sudo modprobe xhci_hcd
```

Not very elegant, but it beats re-inserting the cable by hand. You'd need to
either be a sudoer, or put it in a script and set its
[SUID bit](http://en.wikipedia.org/wiki/Setuid).
I'm not sure how you could make the IDE execute that if you need to, but it's
easy enough if you're going the Makefile way, which I'll get to a bit later.

Another weird problem was that the `delay()` function didn't work at all. Here's the Arduino's "Hello World" program:

``` cpp
void setup() {
	pinMode(13, OUTPUT);
}

void loop() {
	digitalWrite(13, HIGH);
	delay(1000);
	digitalWrite(13, LOW);
	delay(1000);
}
```

The `setup` function is called once and it sets pin 13 to "output" mode. The
`loop` function is the main event loop, and turns the pin on and off with a
1000-millisecond delay. Since the pin is connected to a LED, this should make
it blink every second.

When I tried it, though, the light just turned on and stayed that way. The
reason is explained in the
[Arch Linux wiki](https://wiki.archlinux.org/index.php/Arduino#delay.28.29_function_doesn.27t_work).
Turns out the problem's in the Arch compiler. Adding a `Serial.begin(9600)`
seems to fix the problem.

``` cpp
void setup() {
	Serial.begin(9600);
	pinMode(13, OUTPUT);
}
```

`Serial.begin` is used for communication between the Arduino and a connected
computer, so there's probably no harm in having it there anyway. Hopefully,
there'll be a proper fix soon.

## Compiling and uploading without an IDE, quick'n'dirty

After all of my odd problems were (kinda) fixed, it was time to drop the IDE.
Don't get me wrong, the Arduino IDE makes it really easy to get started, and I
respect its use in attracting even non-programmers to the platform. As a
programmer, though, I'd like to have more freedom in building my toolchain, so
command-line we go.

An obvious first thing to do was google around a bit. I found a few solutions
involving makefiles, cmake and a couple of tools I hadn't heard about.
Unfortunately, most of them didn't quite work out of the box. The platform had
changed with time, so most of what I found was a bit outdated.

I eventually got one running by tweaking paths and flags, and later found a
working one [here](http://arduino.cc/forum/index.php/topic,83725.0.html).
Still, I wasn't completely comfortable with it all. I'm not a C programmer, so
makefiles are a bit of a challenge for me to navigate. The heaps of variables
are obviously meant to make the code more flexible, but confuse the hell out of
me. So, mostly for learning purposes, I tried to make a more minimalistic build
script. I'll go through it step by step and explain how stuff works.

### Step 1: Preprocessing

The most basic of arduino sketches contains definitions for two functions,
`setup` and `loop`. To be able to actually compile that, the IDE adds an
`#include` header at the top and a `main` function at the bottom of the file.
This is generally a neat idea, but it's done on a copy of the file, which means
that any compilation errors will be detected in the copy, and not the original
one. So, I decided to do something a bit different.

First, let's create a `main.h` header file:

``` cpp main.h
#include "Arduino.h"

#define MAIN \
	int main(void) { init(); setup(); for (;;) loop(); return 0; }

extern "C" void __cxa_pure_virtual(void) {
    while(1);
}
```

The first part includes necessary stuff from the Arduino libraries. With the
second, we define a `MAIN` macro that contains the default main function. It's
placed somewhere within the arduino libs, which are in `/usr/share/arduino/` on
my Linux, so I did a `find /usr/share/arduino -name main.cpp` to locate it. The
third part fixes an odd problem with the compiler. This seems to be the
recommended workaround, although I still have no clue why an endless loop is
considered a good solution in this case. The actual issue is that the language
is only a subset of C++, so this definition stubs out a missing area.

Note that the included file is called `Arduino.h`, **not** `WProgram.h` as most
tutorials explain. This is a subtle change since the 1.0 version of the
libraries (read about it in the [release
notes](http://arduino.cc/en/Main/ReleaseNotes)).

It would be a good idea to automate the creation of `main.h`, since Arduino's
`main.cpp` file may change in the future, but I don't feel it's terribly
important.

The actual sketch should now look something like this:

``` cpp main.cpp
#include "main.h"

void setup() { /* ... */ }
void loop() { /* ... */ }

MAIN
```

The Arduino-specific stuff is nicely isolated in `main.h`, which could either
be generated, or copied over to every new project. We just have to include it
and put the `MAIN` macro at the bottom. I also decided to use a "cpp" extension
for sketches, at least for now. If nothing else, it helps with syntax and
indentation settings with Vim.

### Step 2: Compiling

The challenge here lies in gathering all the bits and pieces and compiling them
together. The compiler is called "avr-gcc" and seems to be very compatible with
gcc in how it's used.

``` bash
#! /bin/sh

ARDUINO_PATH='/usr/share/arduino/hardware/arduino/cores/arduino'
VARIANTS_PATH='/usr/share/arduino/hardware/arduino/variants/standard'
MCU='atmega328p'
F_CPU=16000000

CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/wiring.c"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/wiring_analog.c"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/wiring_digital.c"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/wiring_pulse.c"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/wiring_shift.c"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/WInterrupts.c"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/HardwareSerial.cpp"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/WMath.cpp"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/WString.cpp"
CORE_SOURCES="$CORE_SOURCES $ARDUINO_PATH/Print.cpp"

test -d build || mkdir build

avr-gcc -o build/main.elf -mmcu=$MCU -DF_CPU=$F_CPU $CORE_SOURCES main.cpp -I$ARDUINO_PATH -I$VARIANTS_PATH
```

The compiler needs to know what the architecture of the chip would be, hence
the `-m mcu=atmega328p`. This may vary depending on the kind of Arduino used.
We also need to define the contant `F_CPU`, the frequency of the internal
clock. The `-I` flags add needed library include paths.

The rest is just a list of all the sources to compile together in the simplest
way possible -- no intermediate object files, just all the sources smushed
together. For my purposes, that's quite enough.

### Step 2½: Generating a .hex file

A small intermediate step is taking the compiled `main.elf` file and
translating it into something that can be uploaded to the board. The `avr-gcc`
toolchain comes with a command that does that:

``` bash
#! /bin/sh

avr-objcopy -O ihex -R .eeprom build/main.elf build/main.hex
```

The `-O` flag specifies the format of the hex file, which will also be given to
avrdude later. The `-R .eeprom` removes a specific section of the code that
shouldn't be on the chip.

### Step 3: Uploading

Now that the hex file is ready, all that's left is actually getting it on the
board. The tool used for that is called "avrdude".

``` bash
#! /bin/sh

MCU='atmega328p'
PORT='/dev/ttyACM0'
UPLOAD_RATE=115200

# Hack for some USB 3.0 issues
sudo modprobe -r xhci_hcd && sudo modprobe xhci_hcd
sleep 1

avrdude -p$MCU -P$PORT -carduino -b$UPLOAD_RATE -U flash:w:build/main.hex:i
```

The hack I'm using for my USB issues has its place just before the upload. The
`-p`, `-P` and `-b` parameters should be fairly self-explanatory. The `-c
arduino` part tells avrdude the architecture of the chip. The last parameter
given with `-U` is the description of the operation. Its parts, separated by
`:` are:

- Memory type: "flash"
- Operation type: "w" for "write"
- Filename: build/main.hex
- Format of the hex file: "i" for "Intel Hex"

A quick `man avrdude` should be able to explain this in a lot more detail.

## Going further

The script may be a pretty simple one, but it works for my experiments so far.
With a fairly powerful machine, compiling everything on any change is not a big
deal given the size of the libraries. Here's (mostly) the same script as a
[Makefile](https://gist.github.com/1578715). And
[this](http://www.kerrywong.com/2011/12/17/makefile-for-arduino-1-0/) is a much
more complete makefile found in the arduino forums. With both of these, a
simple `:make` in vim will compile the sketch and show any errors in the
quickfix window.
