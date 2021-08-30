# migrates form.yaml from old format to new format

import os 
from yaml import load, dump
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper
from collections import OrderedDict
import ruamel.yaml.util

def fix_field(c):
    if c['type'] == 'variable':
        return c

    # remove default
    try:
        del c['settings']['default']
        if not c['settings']:
            del c['settings']
    except KeyError:
        pass
    if c['type'] == 'string-input':
        c['type'] = 'input'
        if 'settings' not in c:
            c['settings'] = {}
        c['settings']['type'] = 'string'
    if c['type'] == 'number-input':
        c['type'] = 'input'
        if 'settings' not in c:
            c['settings'] = {}
        c['settings']['type'] = 'number'
    if c['type'] == 'string-input-password':
        c['type'] = 'input'
        if 'settings' not in c:
            c['settings'] = {}
        c['settings']['type'] = 'password'
    if c['type'] == 'provider-select':
        c['type'] = 'select'
        if 'settings' not in c:
            c['settings'] = {}
        c['settings']['type'] = 'provider'
    if c['type'] == 'env-key-value-array':
        c['type'] = 'key-value-array'
        if 'settings' not in c:
            c['settings'] = {}
        c['settings']['type'] = 'env'
    
    print(c)
    return c

def migrate(path):
    form, indent, block_seq_indent = ruamel.yaml.util.load_yaml_guess_indent(open(f"{path}/form.yaml"))
    for i, _ in enumerate(form['tabs']):
        for j, _ in enumerate(form['tabs'][i]['sections']):
            for k, c in enumerate(form['tabs'][i]['sections'][j]['contents']):
                form['tabs'][i]['sections'][j]['contents'][k] = fix_field(c)

    ruamel.yaml.round_trip_dump(form, open(f"{path}/form.yaml", "w+"), indent=indent,
                            block_seq_indent=block_seq_indent)

migrate("applications/web")
DIRS = ['applications/']

