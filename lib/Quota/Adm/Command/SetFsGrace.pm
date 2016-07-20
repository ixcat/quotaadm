
package Quota::Adm::Command::SetFsGrace;

use strict;
use warnings;

use Quota::Adm::Filesystem;
use Quota::Adm::CommandUtils;

sub new {
	my $class = shift;
	my $app = shift;

	my $longhelp = "setfs [cfgpath] [fspath]\n\n"
	. "Set filesystem grace according to settings in the file 'cfgpath'.\n"
	. "\n"
	. "the configuration file format is as follows:\n"
	. "\n"
	. "  - lines starting with '#' are ignored\n"
	. "  - actual entries contain the following information:\n" 
	. "\n"
        . "    - a filesystem path\n"
        . "    - a user block grace time in seconds\n"
        . "    - a user inode grace time in seconds\n"
        . "    - a group block grace time in seconds\n"
        . "    - a group inode grace time in seconds\n"
	. "\n"
	. "    separated by whitespace. for example, the file:\n"
	. "\n"
        . "      # fs  ubsecs uisecs gbsecs gisecs\n"
        . "      /data 604800 604800 604800 604800\n"
	. "\n"
	. "    would configure a 7 day block and inode grace period\n"
        . "    on the /data filesystem.\n"
	. "\n"
	. "  - If 'cfgpath' is given, this file will be used,\n"
	. "    otherwise, the default, /etc/fsquota, will be used.\n"
	. "\n"
	. "  - If fspath is given, this filesystem will be configured,\n"
	. "    otherwise, all configurations will be applied."
	. "\n"
	;

	my $self = {
		'app' => $app,
		'cmdname' => 'setfs',
		'shorthelp' => "setfs [cfgpath] [fspath]\n",
		'longhelp' => $longhelp
	};

	bless $self,$class;
	$app->register($self);
	return $self;
}

sub do {
	my $self = shift;
	my $args = shift;

	my $cfgpath = shift @{$args};
	my $fspath = shift @{$args};

	$cfgpath = "/etc/fsquota" unless $cfgpath;

	my $fsquots = Quota::Adm::Filesystem::LoadFile($cfgpath);

	if(!$fsquots) {
		print STDERR "unable to load file from $cfgpath: $!\n";
		return 1;
	}

	my $ret = 0;
	foreach my $fsq (@{$fsquots}) {
		if($fspath) {
			next if $fspath ne $fsq->{fileesys};
		}
		my $cmd = $fsq->toCmd();
		$ret += Quota::Adm::CommandUtils::RunCommand($cmd);
	}
	return $ret;
}

1;
