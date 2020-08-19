# centos5-pyinstaller
## Example usage

### Generate .spec file
<code>
docker run --rm -v /path/to/repo:/src ate59/centos5-pyinstaller "pyinstaller --onefile script.py"
</code>

### Build a new version
<code>
docker run --rm -v /path/to/repo:/src ate59/centos5-pyinstaller "pyinstaller script.spec"
</code>