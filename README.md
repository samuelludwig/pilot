# PILOT

Well ok, so, here's the brief: this is a bastardization of `ianthehenry/sd`.

And here's the long:

I really really really like the ideas behind `sd`, and I wanted to try and
implement it myself. I also happened to have wanted to try out this random
language I've come accross called Janet. Janet has been delightful.

Additionally, I think there are one or two things I would really like to add to
`sd`, like parsing comments in different langs, multiple templates for the
`new` command, and an additional way to have the scripts stored/accessed.

## Methods of script storage/access

The typical way `sd` stores scripts in a given dir is _flat_. Meaning you have
a setup like:

```
# Where `(x)` indicates "executable"
| dir
| + nix
| - + search (x)
| - + search.help
| - + version (x)
| + git
| - + go-back (x)
| - + go-back.help
| - + go-back-helper.sh
| - + logs (x)
| - + logs.help
| - + .help
| - + some-shared-helper.ext
```

In addition to this format, for projects that ask for a little more structure
or organization, I'd like to be able to organize things like so:

```
| dir
| + nix
| - + search
| - - + main (x)
| - - + .help
| - + version (x)
| + git
| - + go-back
| - - + main (x)
| - - + go-back.help
| - - + go-back-helper.sh
| - + logs
| - - + main (x)
| - - + .help
| - + .help
| - + some-shared-helper.ext
```

Where, for example, calling `nix search` would execute `dir/nix/search/main`,
and `nix search --help` would `cat` `dir/nix/search/.help`. 

