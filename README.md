# iwatch

```bash
iwatch FILES CMD
```
Run `CMD` when one of `FILES` is modified.  If `CMD` is long running, `iwatch`
will terminate the previous one and wait for it to finish before starting a new
one.  This is useful for troubleshooting servers or anything that takes a long
time to run.

The `FILES` argument can also be `@...` to ask to watch all files tracked by
git in a certain directory, and CMD can containt `%` which will be expanded to
the first file or `%^` which will be expanded to the whole list of files.

See [iwatch manpage](share/man/man1/iwatch.org) for more info.

## Requirements

### Mac OS

The [`fswatch`](https://emcrisostomo.github.io/fswatch/) command must be
available in PATH. 

### Linux

The `inotifywait` command must be available in PATH.  It comes from the
[inotify-tools](https://github.com/inotify-tools/inotify-tools/) on GitHub.
Use a commit like [81c6c9881](https://github.com/inotify-tools/inotify-tools/tree/81c6c9881edf4844f2b8250e63f82da9cb7f5444)
to get the C version if that's easier for you than compiling the Rust version.

# pwatch

Same as `iwatch` but written in Python except I didn't do the `@...` for files
and the `%`, `%^` thing for the command.

See [pwatch manpage](share/man/man1/pwatch.org) for more info.

## Requirements

The [watchdog](https://pypi.org/project/watchdog/) package is used to monitor
the filesystem

# Installing

Simply add this repo's `bin` directory to your PATH.  The generated manpages
are tracked so users without pandoc don't need to do anything else.

Normally you don't need to add anything to `MANPATH` for the manpages to be
findable.  If you `MANPATH` is unset or contains a leading, double, or trailing
colon, the manpages will be found automatically via the manpath map (see `man
manpath` or run `manpath -d` if you are curous).
