# Git Performance, Large Files, and Maintenance

## Repository Maintenance

```bash
# Garbage collection
git gc
git gc --aggressive  # More thorough, slower

# Prune unreachable objects
git prune

# Verify repository
git fsck
git fsck --full

# Optimize repository
git repack -a -d --depth=250 --window=250

# Git 2.51+: Path-walk repacking (generates smaller packs)
# More efficient delta compression by walking paths
git repack --path-walk -a -d

# Count objects
git count-objects -v

# Repository size
du -sh .git
```

## Large Files

```bash
# Find large files in history
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  sed -n 's/^blob //p' |
  sort --numeric-sort --key=2 |
  tail -n 10

# Git LFS (Large File Storage)
git lfs install
git lfs track "*.psd"
git lfs track "*.zip"
git add .gitattributes
git add file.psd
git commit -m "Add large file"

# List LFS files
git lfs ls-files

# Fetch LFS files
git lfs fetch
git lfs pull
```

## Shallow Clones

```bash
# Shallow clone (faster, less disk space)
git clone --depth 1 <url>

# Unshallow (convert to full clone)
git fetch --unshallow

# Fetch more history
git fetch --depth=100
```
