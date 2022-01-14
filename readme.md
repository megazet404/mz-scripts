# mz-scripts

Some helper scripts for different tasks.

## [git-bundle](git-bundle.bash)

Creates git bundle of remote repository.

Usage:

``git-bundle [OPTION]... REPOSITORY-URL``

Options:

| Option         | Description |
|----------------|-------------|
| ``--7z``       | Pack bundle to 7zip archive. |
| ``--dic-size`` | Dictionary size for 7zip compression (default: 64m). |
| ``--anon``     | Name bundle inside 7zip archive as repo.bundle so as to avoid filename inconsistency when renaming 7zip archive. |
| ``--help``     | Print this help. |

Example:

```sh
git-bundle https://github.com/megazet404/mz-scripts.git
```

## [git-unbundle](git-unbundle.bash)

Restores repository from git bundle.

Usage:

``git-unbundle BUNDLE [OPTION]...``

Options are any ``git clone`` options (e.g. ``--bare``).

Note that unbundling to custom directory is not supported.

Example:

```sh
git-unbundle mz-scripts.bundle
```
