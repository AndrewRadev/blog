---
layout: post
title: "Testing in Rust: Temporary Files"
date: 2019-03-01 14:30
comments: true
categories: rust testing
published: true
---

I recently wrote a tool to manipulate images embedded in mp3 tags: [id3-image](https://github.com/AndrewRadev/id3-image). To be able to make changes to the code with confidence, I needed tests. Rust comes with the very sensible `Write` trait that could have allowed me to mock any IO (a blog post for another day), but in this case, the project relied on the excellent [id3 crate](https://crates.io/crates/id3), so I wasn't doing any file-writing myself.

Instead, I wanted to have an actual mp3 file and an actual image, apply my code to them, and inspect the results. This generally isn't difficult to do, but I ran into a few unexpected gotchas, so I'll summarize how I ended up implementing it.

<!-- more -->

## First Attempt: a Tempdir

I've done this often in other projects: Create a temporary directory per-test, change into it, copy some test files, and then work on them as needed. When the test is done, the entire directory can be wiped out.

In Rust, I'd do this with a macro like so:

``` rust
macro_rules! in_temp_dir {
    ($block:block) => {
        let tmpdir = tempfile::tempdir().unwrap();
        env::set_current_dir(&tmpdir).unwrap();

        $block;
    }
}
```

The `tempfile::tempdir()` function comes from the [tempfile](https://crates.io/crates/tempfile) crate. After unwrapping, I get a `TempDir` that, when dropped, will remove the directory. Neat.

The next step is copying a test file from a predefined place. In my case, I put some files in `tests/fixtures/`, so:

``` rust
macro_rules! fixture {
    ($filename:expr) => {
        let root_dir = &env::var("CARGO_MANIFEST_DIR").expect("$CARGO_MANIFEST_DIR");
        let mut source_path = PathBuf::from(root_dir);
        source_path.push("tests/fixtures");
        source_path.push($filename);

        fs::copy(source_path, $filename).unwrap();
    }
}
```

It doesn't *have* to be a macro, but it means I can be a bit loose about the type of `$filename`, at least to start. The env var `CARGO_MANIFEST_DIR` is something I'm just using to get the root of my project. Not sure if there's a better way, but I always run tests via cargo, so I feel like it should be reasonably reliable.

I could use these two tools to build a simple test that embeds an image and then checks if it worked:

``` rust
#[test]
fn test_successful_jpeg_image_embedding() {
    in_temp_dir!({
        fixture!("no_image.mp3");
        fixture!("test.jpg");

        // No embedded pictures to begin with:
        let tag = id3::Tag::read_from_path("no_image.mp3").unwrap();
        assert!(tag.pictures().count() == 0);

        embed_image("no_image.mp3", "test.jpg").unwrap();

        // One embedded picture after we've run the function:
        let tag = id3::Tag::read_from_path("no_image.mp3").unwrap();
        assert!(tag.pictures().count() > 0);
    });
}
```

It's a readable test, as long as you know what the helper macros do. And it works quite well. The problem shows up when I write more than one of these.

## The problem

With several tests, this approach fails:

```
failures:

---- test_successful_png_image_embedding stdout ----
thread 'test_successful_png_image_embedding' panicked at 'called `Result::unwrap()` on an `Err` value: entity not found', src/libcore/result.rs:997:5
note: Run with `RUST_BACKTRACE=1` environment variable to display a backtrace.

---- test_remove_and_add_image stdout ----
thread 'test_remove_and_add_image' panicked at 'called `Result::unwrap()` on an `Err` value: entity not found', src/libcore/result.rs:997:5

---- test_successful_image_embedding_in_a_file_that_already_has_an_image stdout ----
thread 'test_successful_image_embedding_in_a_file_that_already_has_an_image' panicked at 'called `Result::unwrap()` on an `Err` value: StringError("Error writing image to music file test.mp3: entity not found")', src/libcore/result.rs:997:5


failures:
    test_remove_and_add_image
    test_successful_image_embedding_in_a_file_that_already_has_an_image
    test_successful_png_image_embedding

test result: FAILED. 2 passed; 3 failed; 0 ignored; 0 measured; 0 filtered out
```

Even more annoying, the failures are random -- different tests fail at different times. Usually, when I have problems like this, it's a timing issue -- could it be that filesystem changes are not being persisted? Does adding a few `sleep`s help?

I'll spare you the debugging session -- the problem is more of a feature:

```
If you want to control the number of simultaneous running test cases, pass the
`--test-threads` option to the test binaries:

    cargo test -- --test-threads=1
```

Changing the directory per test doesn't work, because several tests are setting it basically at the same time. And the current working directory is process-local, not thread-local, so there's no way to ensure each test thread is isolated.

## Files and Paths

So what to do? An option is to run with `--test-threads=1`. This works just fine, but it seems like a hassle to require users of the tool to run tests in a special way.

Instead of changing directories, we could allocate a temporary path for fixtures instead, and use that:

``` rust
let song_file  = fixture!("no_image.mp3");
let image_file = fixture!("test.jpg");
```

The tempfile crate does have a `tempfile()` function that's automatically deleted when we have no reference to it anymore. Unlike with `tempdir()` which returns a custom structure, this gives us a `File` whose deletion is handled by the operating system.

It doesn't seem like a bad option. I'd expect I'd be able to do this:

``` rust
// Spoiler: doesn't compile
embed_image(&song_file.path, &image_file.path).unwrap();
```

Unfortunately, no:

```
error[E0609]: no field `path` on type `std::fs::File`
```

The built-in `File` type doesn't give us a way to get its path. As it turns out, not every file needs to have a real path. From [a reddit thread](https://www.reddit.com/r/rust/comments/4sthxj/how_to_get_path_from_file/):

> With `from_raw_fd` you can have a unix pipe, a standard input/output stream or even a TCP/IP socket wrapped in a File.

Leave it to Rust to illuminate my misconceptions, again. There *is* a crate that could help with this particular case: [filepath](https://crates.io/crates/filepath). Instead, I figured I'd use `TempDir` instead and package it up in a more reusable way.

## A Reasonable Solution

Let's start by making our own type, instead of passing around `File`s or `PathBuf`s:

``` rust
struct Fixture {
    path: PathBuf,
    source: PathBuf,
    _tempdir: TempDir,
}
```

The `_tempdir` field has an underscore, because its only purpose there is to keep ownership of it. That way it's dropped when the `Fixture` is dropped. There's separate `source` and `path`, because I'd like to separate creating a `Fixture` and copying the test file over (for purely pragmatic reasons that'll be clear later).

Creating a new fixture is a mixture of the previous `in_temp_dir!` and `fixture!` macros:


``` rust
impl Fixture {
    fn blank(fixture_filename: &str) -> Self {
        // First, figure out the right file in `tests/fixtures/`:
        let root_dir = &env::var("CARGO_MANIFEST_DIR").expect("$CARGO_MANIFEST_DIR");
        let mut source = PathBuf::from(root_dir);
        source.push("tests/fixtures");
        source.push(&fixture_filename);

        // The "real" path of the file is going to be under a temporary directory:
        let tempdir = tempfile::tempdir().unwrap();
        let mut path = PathBuf::from(&tempdir.path());
        path.push(&fixture_filename);

        Fixture { _tempdir: tempdir, source, path }
    }
}
```

So this creates a "blank" fixture -- its directory exists and will be cleaned up, and it has a path, but there's nothing there yet. In order to copy the file, I'll add one more associated function:

``` rust
impl Fixture {
    fn copy(fixture_filename: &str) -> Self {
        let fixture = Fixture::blank(fixture_filename);
        fs::copy(&fixture.source, &fixture.path).unwrap();
        fixture
    }
}
```

This will actually copy the file from the source path into the temporary directory where we'll be changing it. To make the tests a bit more terse, why not add a `Deref` implementation and a helper method:

``` rust
impl Deref for Fixture {
    type Target = Path;

    fn deref(&self) -> &Self::Target {
        self.path.deref()
    }
}

fn read_tag(path: &Path) -> id3::Tag {
    id3::Tag::read_from_path(path).unwrap()
}
```

Going overboard with derefs is generally discouraged, but this is code that will only be used for testing -- we can be a bit more loose with it, throw unwraps around, that sort of thing. Whether it's actually a good idea depends on personal preference, I feel. Here's what the test looks like now:

``` rust
#[test]
fn test_successful_jpeg_image_embedding() {
    let song  = Fixture::copy("no_image.mp3");
    let image = Fixture::copy("test.jpg");

    let tag = read_tag(&song);
    assert!(tag.pictures().count() == 0);

    embed_image(&song, &image).unwrap();

    let tag = read_tag(&song);
    assert!(tag.pictures().count() > 0);
}
```

I like this quite a lot. It might be that `embed_image(&song.path, &image.path)` would have been clearer, but if we change `embed_image` to accept a slightly different argument (a `File`? A custom type?), we could just `Deref` to a different thing. So there's some added flexibility in saying "our custom test-only structure is auto-converted to whatever the code expects".

As for `Fixture::blank`, here's how I use it in a different test:

``` rust
#[test]
fn test_extracting_a_jpg_image() {
    let song  = Fixture::copy("test.mp3");  // a copied fixture
    let image = Fixture::blank("test.jpg"); // a blank fixture

    // To start:
    //   - the song file has at least one embedded picture
    //   - the image path doesn't correspond to an existing file
    let tag = read_tag(&song);
    assert!(tag.pictures().count() > 0);
    assert!(!image.exists());

    extract_first_image(&song, &image).unwrap();

    // After we've run the code, the image should exist on the filesystem
    assert!(image.exists());
}
```

So, using `TempDir` here has the nice benefit that we don't *need* to have a real file -- we can just keep a placeholder in the system that can be used as an output.

## Closing Thoughts

I'm sure there's other ways to deal with filesystem testing, but this is one that I'm quite happy with and a pattern I'll likely use elsewhere. If you'd like to see the full test suite, you can check the project out [on github](https://github.com/AndrewRadev/id3-image).

If you have ideas for improvements on the test suite (or on the code), feel free to open an issue on the repo to start a conversation.
