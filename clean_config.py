#!/usr/bin/env python
""" Clean config.yaml file of secrets

Do a manual check after running this script.
"""

from itertools import cycle

# pip install ruamel.yaml
from ruamel.yaml import YAML

lowhex = list('a0b1c2d3e4f56789')
lowhex_plus = lowhex + list('-')


def is_hex(s, minlen=8):
    if len(s) < minlen:
        return False
    return set(s).issubset(lowhex_plus)


def rehex(s):
    if '-' in s:
        return '-'.join(rehex(p) for p in s.split('-'))
    return ''.join(f for r, f in zip(s, cycle(lowhex)))


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
        elif 'email' in k.lower():
            v = 'yourname@somewhere.org'
        elif 'password' in k.lower():
            v = 'your_secret_password'
        d[k] = v


yaml = YAML()
with open('config.yaml', 'rt') as fobj:
    config = yaml.load(fobj)


clean_d(config)


with open('config.yaml.cleaned', 'wt') as fobj:
    fobj.write('# NB secret values replaced with random equivalents.\n'
               '# Please check.\n\n')
    yaml.dump(config, fobj)
