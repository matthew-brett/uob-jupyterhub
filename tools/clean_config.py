#!/usr/bin/env python
""" Clean config.yaml file of secrets

Do a manual check after running this script.
"""

from argparse import ArgumentParser, RawDescriptionHelpFormatter


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
        kL = k.lower()
        if isinstance(v, dict):
            clean_d(v)
            continue
        elif isinstance(v, str) and is_secret(k, v):
            v = rehex(v)
        elif 'email' in kL:
            v = 'yourname@somewhere.org'
        elif 'password' in kL:
            v = 'your_secret_password'
        elif kL == 'clientid' and v.startswith('cilogon:'):
            parts = v.split('/')
            parts[-1] = rehex(parts[-1])
            v = '/'.join(parts)
        d[k] = v


def main():
    parser = get_parser()
    args = parser.parse_args()

    yaml = YAML()
    with open(args.config_yaml, 'rt') as fobj:
        config = yaml.load(fobj)

    clean_d(config)

    with open(args.cleaned_yaml, 'wt') as fobj:
        fobj.write('# NB secret values replaced with fake equivalents.\n'
                   '# Please check before commit.\n\n')
        yaml.dump(config, fobj)


def get_parser():
    parser = ArgumentParser(description=__doc__,  # Usage from docstring
                            formatter_class=RawDescriptionHelpFormatter)
    parser.add_argument('config_yaml',
                        help='Configuration file to clean')
    parser.add_argument('-c', '--cleaned-yaml', default='config.yaml.cleaned',
                        help='Output yaml file (default "config.yaml.cleaned"')
    return parser


if __name__ == '__main__':
    main()
