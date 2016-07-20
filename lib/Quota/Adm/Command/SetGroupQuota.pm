
package Quota::Adm::Command::SetGroupQuota;

use strict;
use warnings;

use Quota::Adm::Group;
use Quota::Adm::CommandUtils;

sub new {
	my $class = shift;
	my $app = shift;

	my $longhelp = "setgroup [cfgpath] [group]\n\n"
	. "Set group quota according to settings in the file 'cfgpath'.\n"
	. "\n"
	. "the configuration file format is as follows:\n"
	. "\n"
	. "  - lines starting with '#' are ignored\n"
	. "  - actual entries contain the following information:\n" 
	. "\n"
        . "    - a filesystem path\n"
        . "    - a group name\n"
        . "    - a block soft quota value\n"
        . "    - a block hard quota value\n"
        . "    - an inode soft quota value\n"
        . "    - an inode hard quota value\n"
	. "\n"
	. "    separated by whitespace. quota values are passed through\n"
	. "    to the underlying system-dependant quota setting tool,\n"
        . "    typically defaulting to KB. For example, the file:\n"
	. "\n"
        . "      #fs   gname   bsoft bhard isoft ihard\n" 
        . "      /data project 10240 20480 1024  2048\n"
	. "\n"
	. "    would configure soft limits of 10m and 1024 files\n"
	. "    and hard limits of 20m and 2048 files\n"
        . "    for users in the 'project' group on the /data filesystem.\n"
	. "\n"
	. "  - If 'cfgpath' is given, this file will be used,\n"
	. "    otherwise, the default, /etc/groupquota, will be used.\n"
	. "\n"
	. "  - If group is given, this group will be configured,\n"
	. "    otherwise, all configurations will be applied."
	. "\n"
	;

	my $self = {
		'app' => $app,
		'cmdname' => 'setgroup',
		'shorthelp' => "setgroup [cfgpath] [group]\n",
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
	my $group = shift @{$args};

	$cfgpath = "/etc/groupquota" unless $cfgpath;

	my $grpquots = Quota::Adm::Group::LoadFile($cfgpath);

	if(!$grpquots) {
		print STDERR "unable to load file from $cfgpath: $!\n";
		return 1;
	}

	my $ret = 0;
	foreach my $gq (@{$grpquots}) {
		if($group) {
			next if $group ne $gq->{user};
		}
		my $cmd = $gq->toCmd();
		$ret += Quota::Adm::CommandUtils::RunCommand($cmd);
	}
	return $ret;
}

1;
