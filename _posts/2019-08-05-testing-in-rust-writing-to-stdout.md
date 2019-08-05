---
layout: post
title: "Testing in Rust: Writing to Stdout"
date: 2019-08-05 08:00
comments: true
categories: rust testing
published: true
---

For the last two years, I've been one of the organizers of [an elective Rust](https://fmi.rust-lang.bg/) course in Sofia University. Last semester, one of the homework assignments we came up with was to build several kinds of "logger" structs with buffering, multiple outputs, and with tagged logging. (The full assignment is [here](https://2018.fmi.rust-lang.bg/tasks/3), but all the instructions are in Bulgarian.)

It was a pretty good exercise on using `Rc` and `RefCell` that wasn't a linked list or a similar data structure. The goal was to ensure a logger can be cloned, with the copies sharing both the same buffer and output.

Testing the code seemed easy at first glance, but I did run into a bit of a problem when simulating loggers printing to "the screen". The solution is not exactly complicated, but I think it's a good pattern to share.

<!-- more -->

## The `Write` Trait and Simple Stubs

The common trait for output in Rust is [`std::io::Write`](https://doc.rust-lang.org/std/io/trait.Write.html). This is implemented for files, sockets, and, most importantly for testing purposes, for `Vec<u8>` and `&mut Vec<u8>`. This makes it very easy to write a basic test:

``` rust
#[test]
fn test_mutable_reference() {
    // Prepare our output stub:
    let mut out = Vec::new();

    // Don't take ownership, so we can access it for the assertion:
    let mut logger = Logger::new(&mut out);
    logger.log("Some warning");
    logger.flush();

    // Easier to compare if we just convert the bytes to a string first:
    let string_output = String::from_utf8(out).unwrap();

    assert_eq!(string_output, "Some warning\n");
}
```

The logger implementation is a simplified version of the one in the task:

``` rust
use std::io::{Write};

pub struct Logger<W: Write> {
    out: W,
}

impl<W: Write> Logger<W> {
    pub fn new(out: W) -> Self {
        Logger { out }
    }

    // Just write the message directly to the given output with a newline.
    pub fn log(&mut self, message: &str) {
        self.out.write(message.as_bytes()).unwrap();
        self.out.write(b"\n").unwrap();
    }

    // Not an interesting method, but could be if we added buffering.
    pub fn flush(&mut self) {
        self.out.flush().unwrap();
    }
}
```

There's no timestamps, no `Clone` implementation, and it's a terrible idea to use `unwrap` in there (more on that later), but it's enough to demonstrate the problem, even though the first test passes just fine:

```
running 1 test
test test_mutable_reference ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
```

The issue shows up when we try to *share* the output vector somehow, so we can see how multiple loggers' output interpolates:

``` rust
#[test]
fn test_mutable_reference_in_two_places() {
    let mut out = Vec::new();

    // Does not compile:
    let mut logger1 = Logger::new(&mut out);
    let mut logger2 = Logger::new(&mut out);

    logger1.log("One");
    logger2.log("Two");
    logger1.log("Three");

    logger1.flush();
    logger2.flush();

    assert_eq!(String::from_utf8(out).unwrap(), "One\nTwo\nThree\n");
}
```

You can't really compile this code, because you'd be taking two mutable references to the same vector, in the same scope. You *could* create the loggers in two separate scopes, but that's not what I'd like to test. If I initialized the two loggers with `std::io::stdout()` in a main function, they'd print "One", "Two", and "Three" just fine.

Of course, the `stdout()` function returns separate `Stdout` structs that share a file descriptor, probably with some amount of locking. So, instead of using a simple `Vec`, we can do something fancier.

## A More Robust Stub

The solution to sharing resources in Rust is usually `Rc`, with an added `RefCell` so we can allow mutability:

``` rust
use std::io::{self, Write};
use std::rc::Rc;
use std::cell::RefCell;

#[derive(Clone)]
struct TestWriter {
    storage: Rc<RefCell<Vec<u8>>>,
}

impl TestWriter {
    // Creating a new `TestWriter` just means packaging an empty `Vec` in all
    // the wrappers.
    //
    fn new() -> Self {
        TestWriter { storage: Rc::new(RefCell::new(Vec::new())) }
    }

    // Once we're done writing to the buffer, we can pull it out of the `Rc` and
    // the `RefCell` and inspect its contents.
    //
    fn into_inner(self) -> Vec<u8> {
        Rc::try_unwrap(self.storage).unwrap().into_inner()
    }

    // It's easier to compare strings than byte vectors.
    //
    fn into_string(self) -> String {
        String::from_utf8(self.into_inner()).unwrap()
    }
}
```

This struct is perfectly cloneable and holds a simple mutable vector. All we need to do is implement the `Write` trait for it that delegates methods to the vector through a `borrow_mut()`:

``` rust
impl Write for TestWriter {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        self.storage.borrow_mut().write(buf)
    }

    fn flush(&mut self) -> io::Result<()> {
        self.storage.borrow_mut().flush()
    }
}
```

With this, our "fake stdout" can be cloned between two loggers just fine:

``` rust
#[test]
fn test_clonable_writer() {
    let out = TestWriter::new();

    {
        let mut logger1 = Logger::new(out.clone());
        let mut logger2 = Logger::new(out.clone());
        logger1.log("One");
        logger2.log("Two");
        logger1.log("Three");

        logger1.flush();
        logger2.flush();
    }

    // Ownership of `out` is never transferred, so we can access it:
    assert_eq!(out.into_string(), "One\nTwo\nThree\n");
}
```

If we wanted to test loggers in different threads, we could change the `Rc<RefCell<Vec<u8>>>` to `Arc<Mutex<Vec<u8>>>` and use `lock().unwrap()` instead of `borrow_mut()`.

All the `unwrap` calls are not a problem, given that there's no "user" to report errors to -- if we've somehow messed up our test setup, it should probably blow up. We might make it a bit clearer what broke by using `expect` calls instead. For instance:

``` rust
fn into_inner(self) -> Vec<u8> {
    Rc::try_unwrap(self.storage).
        expect("TestWriter: More than one Rc refers to the inner Vec").
        into_inner()
}
```

That said, it's not ideal to keep using `unwrap` in the logger code itself.

## Error Handling

It's not exactly obvious what the best way to handle errors is, for a logger. For one thing, we want the logger to be the thing printing the errors to files or to standard output. Returning `Result` from every single `log` statement would also be kind of annoying to deal with. The idea we came up with for the homework task was to split things up a bit and create pairs of methods -- one that is allowed to fail and one that logs the error to stderr:

``` rust
// A testable method that might error out:
pub fn try_log(&mut self, message: &str) -> io::Result<()> {
    self.out.borrow_mut().write(message.as_bytes())?;
    self.out.borrow_mut().write(b"\n")?;
    Ok(())
}

// A simple wrapper that we expect just ignores stuff:
pub fn log(&mut self, message: &str) {
    if let Err(e) = self.try_log(message) {
        eprintln!("{}", e);
    }
}
```

In order to test it, we can just create another struct that implements `Write` by failing unconditionally:

``` rust
struct ErroringWriter {}

impl Write for ErroringWriter {
    fn write(&mut self, _buf: &[u8]) -> io::Result<usize> {
        Err(io::Error::new(io::ErrorKind::Other, "Write Error!"))
    }

    fn flush(&mut self) -> io::Result<()> {
        Err(io::Error::new(io::ErrorKind::Other, "Flush Error!"))
    }
}
```

It returns the right kind of error, and a specific message, if we really wanted to test details. I'd personally be fine with a simpler assertion:

``` rust
#[test]
fn test_erroring_io() {
    let out = ErroringWriter {};
    let mut logger = Logger::new(out);

    if let Ok(_) = logger.try_log("One") {
        assert!(false, "Expected try_log with an erroring writer to return an error")
    }

    // Should not panic:
    logger.log("Two");
    logger.flush();
}
```

If it's not an error, there's something wrong, and that's probably good enough guidance for something this simple. If you want to go in the other direction, a more sophisticated mock might even have methods to toggle its erroring or non-erroring state with more `Rc`/`RefCell` juggling.

## Extracting to a Separate File

Having the custom structs in the actual test files can get in the way. What we could do is extract a separate `testing.rs` file to stick the code in:

```
src
├── lib.rs
├── main.rs
└── testing.rs
tests
└── test_logger.rs
```

We'll need the module actually exported in `lib.rs`:

``` rust
pub mod testing;

pub struct Logger<W: Write> {
    // ...
```

And then we have to import it in the test code:

``` rust
use logger::Logger;
use logger::testing::*;

#[test]
fn test_clonable_writer() {
    let out = TestWriter::new();
    // ...
```

It's a bit annoying, since the test module is included with the "real" code. You'd think it'd be possible to avoid this with a `#[cfg(test)]`, but at the time of writing, I couldn't manage to do it -- adding a `#[cfg(test)]` above the `pub mod testing` line doesn't compile. We could, however, add `#[cfg(test)]` to the individual types and impls:

``` rust
#[cfg(test)]
#[derive(Clone)]
pub struct TestWriter {
    storage: Arc<Mutex<Vec<u8>>>,
}

#[cfg(test)]
impl TestWriter {
    // ...
```

That way, the module itself is always compiled in, but the structs are only present in the binary that's used for testing. Difficult to say if it's worth the trouble -- these mock types would only be imported in tests either way, so there's little chance of naming conflicts or binary bloat.

## Closing Thoughts and Further Reading

The standard library includes some powerful testing tools and a convenient test runner. Even so, it can be worth it to create custom tools to make tests simpler to write and easier to read. Extracting them to their own module means they can easily be shared between different test files. You might even decide to split them up additionally into, say, `src/testing/io.rs`, `src/testing/assertions.rs` and so on.

In the end, tests are code too -- reusing common logic works just as well, and you can apply all the same engineering patterns you use in "real" code.

If you need more flexibility in testing I/O in particular, try [`std::io::Cursor`](https://doc.rust-lang.org/std/io/struct.Cursor.html). It works just like a `Vec` for reading and writing, but allows you to rewind it and seek into it, like you could with a real file.

For more ideas on mocking, you might also take a look at "[Mocking in Rust with conditional compilation](https://klausi.github.io/rustnish/2019/03/31/mocking-in-rust-with-conditional-compilation.html)".
