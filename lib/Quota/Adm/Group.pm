
package Quota::Adm::Group;

use strict;
use warnings;

use Quota::Adm::CommandUtils;

our $LinuxCmdFormat = "setquota -g %G %gb %gB %gi %gI %F;";
our $OpenBSDCmdFormat = "setquota -g -f %F -bh%gB -bs%gb -ih%gI -is%gi %G;";

sub new;
sub fromLine;

sub toCmd;

sub LoadFile;
sub GenCmdList;

sub new {

	my $class = shift;
	my $args = shift;

	my $filesys = exists $args->{filesys} ? $args->{filesys} : undef;
	my $group = exists $args->{group} ? $args->{group} : undef;

	my $bsoft = exists $args->{bsoft} ? $args->{bsoft} : undef;
	my $bhard = exists $args->{bhard} ? $args->{bhard} : undef;
	my $isoft = exists $args->{isoft} ? $args->{isoft} : undef;
	my $ihard = exists $args->{ihard} ? $args->{ihard} : undef;

	if(!($filesys && $group && $bsoft && $bhard && $isoft && $ihard)) {
		return undef;
	}

	my $fmt = undef;
	$fmt = $LinuxCmdFormat if $^O eq 'linux';
	$fmt = $OpenBSDCmdFormat if $^O eq 'openbsd';
	$fmt = "echo functionality for system $^O not implemented;"
		unless $fmt;

	my $self = {
		'filesys' => $filesys,
		'group' => $group,
		'bsoft' => $bsoft,
		'bhard' => $bhard,
		'isoft' => $isoft,
		'ihard' => $ihard,
		'fmt' => $fmt
	};

	bless $self,$class;
	return $self;
}

sub fromLine {

	my $class = shift;
	my $line = shift;
	my $ref = undef;

	my $group_rx = '^((?:\w+|\/)*)'; # filesys
	$group_rx .= '\s+((?:\w+|\d+)*)'; # group
	$group_rx .= '\s+(\d+|[KkMmGgTt])'; # blksoft
	$group_rx .= '\s+(\d+|[KkMmGgTt])'; # blkhard
	$group_rx .= '\s+(\d+)'; # inosoft
	$group_rx .= '\s+(\d+)'; # inohard
	
	chomp $line;

	if ($line =~ m@$group_rx@) {
		my $args = {
			'filesys' => $1,
			'group'  => $2,
			'bsoft' => $3,
			'bhard' => $4,
			'isoft' => $5,
			'ihard' => $6
		};
		$ref = Quota::Adm::Group->new($args);
	}

	return $ref;

}

sub toCmd {
	my $self = shift;

	my $filesys = $self->{filesys};
	my $group = $self->{group};

	my $bsoft = $self->{bsoft};
	my $bhard = $self->{bhard};
	my $isoft = $self->{isoft};
	my $ihard = $self->{ihard};

	my $cmd = Quota::Adm::CommandUtils::FormatString($self->{fmt}, $self);

	return $cmd;
}

sub LoadFile {
	my $fname = shift;

	open FH, "<$fname" or return undef;

	my $grpquots = [];

	while (my $line = <FH>) {
		next if $line =~ m:^\s*#:;
		my $ref = Quota::Adm::Group->fromLine($line);
		if($ref) {
			push @{$grpquots}, $ref;
		}
	}

	close FH;

	return $grpquots;

}

sub GenCmdList { # XXX: notused
	my $grpquots = shift;
	my $cmds = [];

	foreach my $gq (@{$grpquots}) {
		my $cmd = $gq->toCmd();
		push @{$cmds}, $cmd;
	}
	return $cmds;
}

1;

