#!/usr/bin/env python
""" Clean config.yaml file of secrets

Do a manual check after running this script.
"""

from random import choices
from string import hexdigits

from ruamel.yaml import YAML

lowhex = [c for c in hexdigits if not c.isupper()]
lowhex_plus = lowhex + list('-')


def is_hex(s, minlen=8):
    if len(s) < minlen:
        return False
    return set(s).issubset(lowhex_plus)


def rehex(s):
    if '-' in s:
        return '-'.join(rehex(p) for p in s.split('-'))
    return ''.join(choices(lowhex, k=len(s)))


def is_secret(key, val):
    if 'secret' in key.lower():
        return True
    if key == 'tag':
        return False
    return is_hex(val)


def clean_d(d):
    for k, v in d.items():
        if isinstance(v, dict):
            clean_d(v)
            continue
        elif isinstance(v, str) and is_secret(k, v):
            v = rehex(v)
        elif k == 'contactEmail':
            v = 'yourname@somewhere.org'
        d[k] = v


yaml = YAML()
with open('config.yaml', 'rt') as fobj:
    config = yaml.load(fobj)


clean_d(config)


with open('config.yaml.cleaned', 'wt') as fobj:
    fobj.write('# NB secret values replaced with random equivalents.\n'
               '# Please check.\n\n')
    yaml.dump(config, fobj)
