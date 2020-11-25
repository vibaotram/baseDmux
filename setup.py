from setuptools import setup
import os

with open("README.md", "r") as rm:
    long_description = rm.read()


with open("baseDmux/version", "r") as vs:
      __version__ = vs.read()

setup(name='baseDmux',
      version=__version__,
      description='baseDmux: something',
      long_description=long_description,
      url='https://github.com/vibaotram/baseDmux',
      author='Me',
      author_email='author@gmail.com',
      license='GPLv3',
      packages=['baseDmux'],
      # package_dir={'baseDmux': 'baseDmux/data'},
      package_data={'baseDmux': ['data/*', 'data/*/*', 'data/*/*/*', 'data/*/*/*/*'],},
      entry_points={"console_scripts": ['baseDmux = baseDmux.baseDmux:main']},
      include_package_data=True,
      zip_safe=False)
