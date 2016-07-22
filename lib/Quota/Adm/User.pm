
package Quota::Adm::User;

use strict;
use warnings;

use Quota::Adm::CommandUtils;

our $LinuxCmdFormat = "setquota -u %U %ub %uB %ui %uI %F;";
our $OpenBSDCmdFormat = "setquota -u -f %F -bh%uB -bs%ub -ih%uI -is%ui %U;";

sub new;
sub fromLine;

sub toCmd;

sub LoadFile;
sub GenCmdList;

sub new {
	my $class = shift;
	my $args = shift;

	my $filesys = exists $args->{filesys} ? $args->{filesys} : undef;
	my $user = exists $args->{user} ? $args->{user} : undef;

	my $bsoft = exists $args->{bsoft} ? $args->{bsoft} : undef;
	my $bhard = exists $args->{bhard} ? $args->{bhard} : undef;
	my $isoft = exists $args->{isoft} ? $args->{isoft} : undef;
	my $ihard = exists $args->{ihard} ? $args->{ihard} : undef;

	if(!($filesys && $user && $bsoft && $bhard && $isoft && $ihard)) {
		return undef;
	}

	my $fmt = undef;
	$fmt = $LinuxCmdFormat if $^O eq 'linux';
	$fmt = $OpenBSDCmdFormat if $^O eq 'openbsd';
	$fmt = "echo functionality for system $^O not implemented;"
		unless $fmt;

	my $self = {
		'filesys' => $filesys,
		'user' => $user,
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

	my $user_rx = '^((?:\w+|\W+|\d+|\/)*)'; # filesys
	$user_rx .= '\s+((?:\w+|\d+)*)'; # user
	$user_rx .= '\s+(\d+|[KkMmGgTt])'; # bsoft
	$user_rx .= '\s+(\d+|[KkMmGgTt])'; # bhard
	$user_rx .= '\s+(\d+)';	# isoft
	$user_rx .= '\s+(\d+)'; # ihard

	chomp $line;

	if($line =~ m@$user_rx@) {
		my $args = {
			'filesys' => $1,
			'user' => $2,
			'bsoft' => $3,
			'bhard' => $4,
			'isoft' => $5,
			'ihard' => $6
		};
		$ref = Quota::Adm::User->new($args);
	}

	return $ref;

}

sub toCmd {
	my $self = shift;

	my $filesys = $self->{filesys};
	my $user = $self->{user};

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

	my $usrquots = [];

	while (my $line = <FH>) {
		next if $line =~ m:^\s*#:;
		my $ref = Quota::Adm::User->fromLine($line);
		if($ref) {
			push @{$usrquots}, $ref;
		}
	}

	close FH;

	return $usrquots;
}

sub GenCmdList { # XXX: notused
	my $usrquots = shift;
	my $cmds = [];

	foreach my $uq (@{$usrquots}) {
		my $cmd = $uq->toCmd();
		push @{$cmds}, $cmd;
	}
	return $cmds;
}

1;
