[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1300855.svg)](https://doi.org/10.5281/zenodo.1300855)

# Candidate Smasher
Make artificial constructs, performance feedback display candidates, by smashing together the attributes from a performance feedback template and a feedback recipient.

## Installation
- Pull from source repository.
- Add bin to PATH

## Use

```sh
cansmash [options] spek.json
```
or
```sh
cat spek.json | cansmash spek.json
```

## Examples
```sh
bin/cansmash generate --path spec/fixtures/spek.json --md-source=spec/fixtures/templates-metadata.json
```
