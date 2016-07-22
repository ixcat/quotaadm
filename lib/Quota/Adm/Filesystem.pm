
package Quota::Adm::Filesystem;

use strict;
use warnings;

use Quota::Adm::CommandUtils;

our $LinuxCmdFmt = "setquota -u -t %fb %fi %F;"
	. " setquota -g -t %fB %fI %F;" ;

our $OpenBSDCmdFmt = "echo filesystem grace not implemented on OpenBSD;";

sub new;
sub fromLine;

sub toCmd;

sub LoadFile;
sub GenCmdList;

sub new {
	my $class = shift;
	my $args = shift;

	my $filesys = exists $args->{filesys} ? $args->{filesys} : undef;

	my $ubgrace = exists $args->{ubgrace} ? $args->{ubgrace} : undef;
	my $uigrace = exists $args->{uigrace} ? $args->{uigrace} : undef;
	my $gbgrace = exists $args->{gbgrace} ? $args->{gbgrace} : undef;
	my $gigrace = exists $args->{gigrace} ? $args->{gigrace} : undef;

	if(!(defined($filesys) 
		&& defined($ubgrace) && defined($uigrace)
		&& defined($gbgrace) && defined($gbgrace))) {
		return undef;
	}

	my $fmt = undef;
	$fmt = $LinuxCmdFmt if $^O eq 'linux';
	$fmt = $OpenBSDCmdFmt if $^O eq 'openbsd';
	$fmt = "echo functionality for system $^O not implemented;"
		unless $fmt;

	my $self = {
		'filesys' => $filesys,
		'ubgrace' => $ubgrace,
		'uigrace' => $uigrace,
		'gbgrace' => $gbgrace,
		'gigrace' => $gigrace,
		'fmt' => $fmt
	};

	bless $self,$class;
	return $self;
}

sub fromLine {
	my $class = shift;
	my $line = shift;
	my $ref = undef;

	chomp $line; 

	my $fs_rx = '^(.*?)'			# filesys
		. '\s+(\d+)'			# ubgrace
		. '\s+(\d+)'			# uigrace
		. '\s+(\d+)'			# gbgrace
		. '\s+(\d+)'			# gigrace
	;

	if ($line =~ m@$fs_rx@) {
		my $args = {
			'filesys' => $1,
			'ubgrace' => $2,
			'uigrace' => $3,
			'gbgrace' => $4,
			'gigrace' => $5
		};
		$ref = Quota::Adm::Filesystem->new($args);
	}

	return $ref;
}

sub toCmd {
	my $self = shift;

	my $filesys = $self->{filesys};
	my $ubgrace = $self->{ubgrace};
	my $uigrace = $self->{uigrace};
	my $gbgrace = $self->{gbgrace};
	my $gigrace = $self->{gigrace};

	my $cmd = Quota::Adm::CommandUtils::FormatString($self->{fmt}, $self);
	return $cmd;
}

sub LoadFile {
	my $fname = shift;

	open FH, "<$fname" or return undef;

	my $fsquots = [];

	while (my $line = <FH>) {
		next if $line =~ m:^\s*#:;
		my $ref = Quota::Adm::Filesystem->fromLine($line);
		if($ref) {
			push @{$fsquots}, $ref;
		}
	}

	close FH;

	return $fsquots;
}

sub GenCmdList { # XXX: not used
	my $fsquots = shift;
	my $cmds = [];

	foreach my $fsq (@{$fsquots}) {
		my $cmd = $fsq->toCmd();
		push @{$cmds}, $cmd;
	}

	return $cmds;
}

1;
