# quota conversion package - 
# converts repquota output to quotaadm input
#
# NOTE: currently Untested on OpenBSD
#

package Quota::Adm::Command::ConvertQuota;

use strict;
use warnings;

sub new {
	my $class = shift;
	my $app = shift;

	my $longhelp = "convert {user|group} fspath\n\n"
	. "Generate a quotaadm configuration from active user/group quotas\n"
	. "on the filesystem 'fspath'.\n"
	. "\n"
	. "Resulting output can be saved for later use by the\n"
	. "quotaadm setuser or quotaadm setgroup commands."
	. "\n"
	;

	my $self = {
		'app' => $app,
		'cmdname' => 'convert',
		'shorthelp' => "convert {user|group} fspath\n",
		'longhelp' => $longhelp
	};

	bless $self,$class;
	$app->register($self);
	return $self;

}

sub do {
	my $self = shift;
	my $args = shift;

	my $ugarg = shift @{$args};
	my $fsarg = shift @{$args};

	# hackish - violating mvc since ingest is not core function and lazy
	if (!(defined($ugarg) && defined($fsarg))
	  || ($ugarg !~ m:^(user|group)$:)) 
	{
		$self->{app}->longhelp($self->{cmdname});
		return 0;
	}

	$ugarg = '-u' if $ugarg eq 'user';
	$ugarg = '-g' if $ugarg eq 'group';

	my $repcmd;
	$repcmd = "repquota $ugarg -v $fsarg" if $^O eq 'linux';
	$repcmd = "repquota $ugarg $fsarg" if $^O eq 'openbsd';
	die "unsupported operating system $^O" unless $repcmd;

	open REPQUOTA, "$repcmd |" or die "couldn't spawn repquota(8): $!\n";
	
	my $meat = 0;
	
	print "# filesys\tlogname\tbsoft\tbhard\tisoft\tihard\n" if $ugarg eq '-u';
	print "# filesys\tgrname\tbhard\tisoft\tihard\n" if $ugarg eq '-g';
	
	while (my $line = <REPQUOTA>) {
		chomp $line;
		if(!$meat){
			if($line =~ m:^-+$:) {
				$meat = 1;
				next;
			}
			next;
		}
		if($line =~ m:^$:) {
			$meat = 0; 
			next;
		}
		my $elms = [ split /\s+/, $line ];
		${$elms}[0] =~ s:^#::; # id-only entry names prefixed with '#'
	
		# the following if/else gymnastics occurs since the number of 
	        # non-whitespace data fields expands/contracts depending
		# on whether or not a user is above/below quotas
	
		if(${$elms}[1] =~ m:^\+:) { 		# above - #6 is bgrace
			print "$fsarg "
				. ${$elms}[0] . "\t"
				. ${$elms}[3] . "\t"
				. ${$elms}[4] . "\t"
				. ${$elms}[7] . "\t"
				. ${$elms}[8] . "\n";
		}
		else { 					# below - #6 is isoft
			print "$fsarg "
				. ${$elms}[0] . "\t"
				. ${$elms}[3] . "\t"
				. ${$elms}[4] . "\t"
				. ${$elms}[6] . "\t"
				. ${$elms}[7] . "\n";
		}
	
	}
	close REPQUOTA;
	return 0;
}

1;
__DATA__
# hacked uppish example for dbg purposes
__DATA__

*** Report for user quotas on device /opt
Block grace time: 7days; Inode grace time: 7days
                        Block limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
root	-- 2068872       0       0            445     0     0       
dude	+- 28860164 15728640 31457280  5days   28354     0     0       
#500	--    1424       0       0              3     0     0       

Statistics:
Total blocks: 8
Data blocks: 1
Entries: 3
Used average: 5.000000

