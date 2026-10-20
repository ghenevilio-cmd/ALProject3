"""Verify the direct root build retains the reviewed application and excludes the test object."""
from pathlib import Path
import hashlib
import io
import json
import re
import xml.etree.ElementTree as ET
import zipfile
from urllib.parse import unquote

root = Path(__file__).resolve().parent.parent
reviewed = root / 'artifacts/receipt-concept-1.1.2.28/Systems Integration_Approved Product List_1.1.2.28.app'
direct = root / 'Systems Integration_Approved Product List_1.1.2.28.app'
test = root / 'tests/receipt-concept/Systems Integration_OMS Receipt Concept Tests_1.0.0.0.app'
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
assert sha(reviewed) == '62b3eb0a0e497af3fe3000bbae53a445084adeb99e9394d7cf8022b2f5c55d13'

def xml_value(data, navigation=False):
    node = ET.fromstring(data)
    def value(n):
        attrs = dict(n.attrib)
        if n.tag.rsplit('}', 1)[-1] == 'Build':
            attrs.pop('Timestamp', None)
            attrs.pop('By', None)
        if navigation:
            attrs.pop('ControlGUID', None)
        children = [value(child) for child in n]
        if navigation:
            children.sort(key=repr)
        return n.tag, sorted(attrs.items()), (n.text or '').strip(), children
    return value(node)

extra = 'src/tests/receipt-concept/ReceiptConceptTests.Codeunit.al'
metadata = {'NavxManifest.xml', 'navigation.xml', 'addin/POS_Control_Addin.zip', 'addin/TBGC_Receiving_Control_Addin.zip'}
with zipfile.ZipFile(reviewed) as a, zipfile.ZipFile(direct) as b:
    assert set(b.namelist()) == set(a.namelist()) | {extra}, 'Unexpected added/removed package entries'
    assert b.read(extra) == (root / 'tests/receipt-concept/ReceiptConceptTests.Codeunit.al').read_bytes()
    for name in a.namelist():
        if name not in metadata:
            assert a.read(name) == b.read(name), 'Reviewed payload changed: ' + name
            if name.endswith('.al'):
                relative = name
                while unquote(relative) != relative:
                    relative = unquote(relative)
                assert (root / relative.removeprefix('src/')).read_bytes() == a.read(name), 'Root source changed: ' + relative
        elif name.endswith('.zip'):
            with zipfile.ZipFile(io.BytesIO(a.read(name))) as x, zipfile.ZipFile(io.BytesIO(b.read(name))) as y:
                assert set(x.namelist()) == set(y.namelist())
                assert all(x.read(n) == y.read(n) for n in x.namelist()), 'Control-addin content changed'
        else:
            assert xml_value(a.read(name), name == 'navigation.xml') == xml_value(b.read(name), name == 'navigation.xml'), name
    symbols = json.loads(b.read('SymbolReference.json'))
    assert all(c['Id'] != 80351 for c in symbols.get('Codeunits', [])), 'Test object leaked into production'
with zipfile.ZipFile(test) as z:
    symbols = json.loads(z.read('SymbolReference.json'))
    units = symbols.get('Codeunits', [])
    assert len(units) == 1 and units[0]['Id'] == 80351
    methods = {m['Name'] for m in units[0].get('Methods', [])}
    expected = set(re.findall(r'\[Test\]\s+procedure (\w+)', (root / 'tests/receipt-concept/ReceiptConceptTests.Codeunit.al').read_text()))
    assert len(expected) == 7 and expected <= methods, 'Separate test procedures missing'
assert json.loads((root / 'app.json').read_text())['version'] == '1.1.2.28'
assert 'OMS_RECEIPT_CONCEPT_TESTS' not in json.loads((root / 'app.json').read_text()).get('preprocessorSymbols', [])
assert json.loads((root / 'tests/receipt-concept/app.json').read_text())['preprocessorSymbols'] == ['OMS_RECEIPT_CONCEPT_TESTS']
print(json.dumps({'result': 'PASS', 'productionPackageSha256': sha(direct), 'testPackageSha256': sha(test),
    'applicationSources': 153, 'runtimeAssets': 7, 'compiledSymbolsIdentical': True,
    'productionContainsTestCodeunit': False, 'separateTestProcedures': len(expected)}, indent=2))
