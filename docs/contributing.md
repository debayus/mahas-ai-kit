# Working on the kit

```bash
bash tests/run.sh
```

The tests build setups from the templates for each combination of choices and run `verify.sh` on them, check that `verify.sh` rejects broken setups, and run `detect.sh` on small repositories made for the test. They need bash, git, and python3, and write only to a temporary folder.

[Back to the README](../README.md)
