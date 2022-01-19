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
