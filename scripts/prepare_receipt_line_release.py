"""Build an unpublished additive release from the prior published artifact, never the dirty source tree."""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import re
from urllib.parse import unquote
import xml.etree.ElementTree as ET
import zipfile

root = Path(__file__).resolve().parent.parent
baseline = root / 'Systems Integration_Approved Product List_1.1.2.25.app'
extra = ['src/OMSAPI2/OMS2PostedReceiptLines.Api.Page.al', 'src/OMSAPI2/OMS2ReceiptLineRead.PermissionSet.al']
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert digest(baseline) == '9bba7c00417cb710e9627b231c690e22d8ee6d605d9f8e904f05123e92296e12', 'Prior artifact changed; review before rebuilding'
ns = {'m': 'http://schemas.microsoft.com/navx/2015/manifest'}
output = root / 'artifacts/receipt-line-1.1.2.26'
output.mkdir(parents=True, exist_ok=True)
compiler = Path('C:/Users/ghene.winters/.vscode/extensions/ms-dynamics-smb.al-18.1.2842859/bin/alc.exe')
sources = []
with tempfile.TemporaryDirectory(prefix='vms-receipt-line-release-') as directory:
    stage = Path(directory)
    with zipfile.ZipFile(baseline) as archive:
        manifest = ET.fromstring(archive.read('NavxManifest.xml'))
        app = manifest.find('m:App', ns)
        assert app is not None and app.attrib['Version'] == '1.1.2.25'
        assert app.attrib['Id'] == '5aebd1c1-2f62-4145-b924-32816b4d64d5'
        config = {key: app.attrib[attr] for key, attr in [('id', 'Id'), ('name', 'Name'), ('publisher', 'Publisher'),
            ('brief', 'Brief'), ('description', 'Description'), ('platform', 'Platform'), ('application', 'Application'), ('runtime', 'Runtime'), ('target', 'Target')]}
        config.update(version='1.1.2.26', idRanges=[{'from': int(x.attrib['MinObjectId']), 'to': int(x.attrib['MaxObjectId'])} for x in manifest.findall('m:IdRanges/m:IdRange', ns)],
            dependencies=[{'id': x.attrib['Id'], 'name': x.attrib['Name'], 'publisher': x.attrib['Publisher'], 'version': x.attrib['MinVersion']} for x in manifest.findall('m:Dependencies/m:Dependency', ns)],
            features=['NoImplicitWith'], resourceExposurePolicy={'allowDebugging': False, 'allowDownloadingSource': False, 'includeSourceInSymbolFile': False})
        for entry in archive.namelist():
            if not entry.endswith('.al'):
                continue
            name = entry
            while unquote(name) != name:
                name = unquote(name)
            assert name.startswith('src/src/')
            relative = Path(name[len('src/'):])
            target = stage / relative
            assert target.resolve().is_relative_to(stage.resolve()) and not target.exists()
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(entry))
            sources.append({'path': relative.as_posix(), 'sha256': digest(target), 'origin': 'published-1.1.2.25'})
        # Preserve shipped report layouts and the original control-addin JS/CSS, not local frontend builds.
        for entry in archive.namelist():
            if entry.startswith('layout/'):
                relative = unquote(entry[len('layout/'):])
                target = stage / relative
                assert target.resolve().is_relative_to(stage.resolve())
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(entry))
        for source in stage.rglob('*.al'):
            content = source.read_text(encoding='utf-8-sig')
            if not re.search(r'\bcontroladdin\b', content, re.I):
                continue
            for relative in re.findall(r"'(.*?)'", content):
                entry = 'addin/src/' + relative
                if entry not in archive.namelist():
                    continue
                target = source.parent / relative
                assert target.resolve().is_relative_to(stage.resolve())
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(entry))
    assert len(sources) == 148
    for relative in extra:
        target = stage / relative
        assert not target.exists()
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes((root / relative).read_bytes())
        sources.append({'path': relative, 'sha256': digest(target), 'origin': 'reviewed-receipt-read'})
    (stage / 'app.json').write_text(json.dumps(config, indent=2), encoding='utf-8')
    package = output / 'Systems Integration_Approved Product List_1.1.2.26.app'
    result = subprocess.run([str(compiler), '/project:' + str(stage), '/packagecachepath:' + str(root / '.alpackages'), '/out:' + str(package)], capture_output=True, text=True)
    (output / 'compile.log').write_text(result.stdout + result.stderr, encoding='utf-8')
    assert result.returncode == 0, 'AL compilation failed; see compile.log'
    # Check every source survived packaging unchanged; only the two new objects are added.
    with zipfile.ZipFile(package) as archive:
        compiled = {}
        for name in archive.namelist():
            if name.endswith('.al'):
                decoded = name
                while unquote(decoded) != decoded:
                    decoded = unquote(decoded)
                assert decoded.startswith('src/src/')
                compiled[decoded[len('src/'):]] = hashlib.sha256(archive.read(name)).hexdigest()
        assert compiled == {x['path']: x['sha256'] for x in sources}
        with zipfile.ZipFile(baseline) as original:
            for entry in original.namelist():
                if entry.startswith('addin/src/') or entry.startswith('layout/'):
                    assert archive.read(entry) == original.read(entry), 'Existing runtime asset changed: ' + entry
    evidence = {'version': config['version'], 'status': 'compiled, NOT published', 'baseline': str(baseline), 'baselineSha256': digest(baseline),
        'package': str(package), 'packageSha256': digest(package), 'preservedSources': 148, 'addedSources': 2, 'sources': sources,
        'limitations': ['baseline artifact must match installed 1.1.2.25 before publication', 'runtime filter/permission checks pending', 'no financial action included']}
    (output / 'release-manifest.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: evidence[key] for key in ['version', 'status', 'preservedSources', 'addedSources', 'packageSha256']}))
