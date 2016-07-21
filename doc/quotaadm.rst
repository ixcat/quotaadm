.. $Id$

========
quotaadm
========

Overview
--------

Quotaadm is a simple cli utility for the simple managment of
filesystem quotas.  It is a light wrapper around command line tools,
such as the Linux and OpenBSD flavors of the 'setquota' utility
which applies values stored in configuration files to the various
filesystems on the system where it is run.

Currently, the utility has been tested on Linux (el7) and OpenBSD
(5.9), though the underlying logic was written with portability in
mind and so should be portable to any system where an available
command utility can be used to apply filesystem quotas via the use
of printf(3)-like format strings to execute subcommands.

While in some cases it could be just as easy to generate scripts
to execute the needed commands, providing an intermediate format
as described here along with system-specific means to set the various
settings should allow for easier generation of quota configurations
from system-agnostic sources such as databases, as well as facillitate
portability between different systems when this is required.

Installation
------------

First, ensure that the-system specific quota and setquota tools are
installed - on Linux (rhel), this entails installing the 'quota'
package, on OpenBSD, core quota tools are part of the base system,
but the setquota userland utility is available from the sysutils/setquota
port or in packages. From here, enable quotas as is appropriate to
the desired target system, which typically entails mounting any
quota filesystems with a quota option and enabling system quota
processing.  For specific details, see the appropriate system quota
documentation.

In addition to system setup and installation of the appropriate
system-specific 'setquota' utility, installing quotaadm follows a
typical perl install process::

  $ perl Makefile.PL
  $ make
  # make install

Configuration 
-------------

The utility uses 3 configuration files for filesystem grace, user
quotas, and group quotas, /etc/fsquota, /etc/userquota, and
/etc/groupquota, respectively. The format for each of these files
follow, and exaples are provided in the doc/examples area of the
source distribution.

fsquota configuration file example
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An example fileystem grace configuraiton file is as follows::

  # fs       ubsecs uisecs gbsecs gisecs
  /usr/local 604800 604800 604800 604800

To note, this functionality is not supported on OpenBSD since
the underlying 'setquota' tool does not currently support this
functionality.

userquota configuration file example
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An example user quota configuraiton file is as follows::

  #filesys   logname blksoft  blkhard  inosoft inohard
  /usr/local chris   10485760 20971520 128000  256000

groupquota configuration file example
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An example group quota configuraiton file is as follows::

  #filesys   grname blksoft  blkhard  inosoft inohard
  /usr/local staff  10485760 20971520 128000  256000

Usage
-----

The tool can be invoked according to the following synopsys,
also given when the tool is run without arguments::

  $ ./bin/quotaadm 
  usage: quotaadm cmd args
    where 'cmd args' is one of:
      - help: print this help
      - help cmd: print detailed help for 'cmd'
      - setfs [cfgpath] [fspath]
      - setuser [cfgpath] [user]
      - setgroup [cfgpath] [group]
      - convert {user|group} fspath

As can be seen from the synopsys, alternate configuration files can
be used if so desired, and full help is available for each subcommand
via the help subcommand. Additionally, for debugging or testing
purposes, the QUOTAADM_DEBUG environment variable can be set to
provide verbose output or to prevent actual execution of the
underlying quota-setting tool according to the following scheme:

  - QUOTAADM_DEBUG=v : print commands before execution
  - QUOTAADM_DEBUG=p : print commands and do not execute

Developer Notes
---------------

Generally speaking, the utility uses an extremely simple MVC controller,
whereby :

 - The data models for the various configuration 'objects' are
   defined in Quota::Adm::Objecttype modules
 - Various user commands to manipulate the objects are defined 
   in the various Quota::Adm::Command::Commandname module
 - The Quota::Adm::Command class provides a generic execution
   controller to execute the various command objects.

To extend the system, this model can be easily extened, and in the
case of porting the tool to other systems, a generic data model and
format string mechanism for subcommand execution is provided within
the Quota::Adm::CommandUtils package used by the various subcommands.
Any system providing the ability to manipulate quotas from a userland
command according to the overall behavior described here should be
able to leverage the format string methods within Quota::Adm::CommandUtils
in combination with perl's built-in $^O operating system variable
in the various commands to call the necessary system-specific
subcommand to perform the low level quota manipulation operations.

