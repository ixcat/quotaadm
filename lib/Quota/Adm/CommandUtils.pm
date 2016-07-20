
package Quota::Adm::CommandUtils;

# utility routines for Quota::Adm command generation/execution

use warnings;
use strict;

sub FormatString;
sub RunCommand;

our $DefaultFormat = "filesys : %F\n"
	    	   . "user    : %U\n"
	  	   . "group   : %G\n"
		   . "\n"
		   . "ubgrace : %fb\n"
		   . "uigrace : %fi\n"
		   . "gbgrace : %fB\n"
		   . "gigrace : %fI\n"
		   . "\n"
		   . "ubsoft  : %ub\n"
		   . "ubhard  : %uB\n"
		   . "uisoft  : %ui\n"
		   . "uihard  : %uI\n"
		   . "gbsoft  : %gb\n"
		   . "gbhard  : %gB\n"
		   . "gisoft  : %gi\n"
		   . "gihard  : %gI\n"
		   . "\n"
;

sub FormatString {
	my $fmt = shift;
	my $obj = shift;

	$fmt =~ s:%F:$obj->{filesys}:g if exists $obj->{filesys};
	$fmt =~ s:%U:$obj->{user}:g if exists $obj->{user};
	$fmt =~ s:%G:$obj->{group}:g if exists $obj->{group};

	$fmt =~ s:%fb:$obj->{ubgrace}:g if exists $obj->{ubgrace};
	$fmt =~ s:%fi:$obj->{uigrace}:g if exists $obj->{uigrace};
	$fmt =~ s:%fB:$obj->{gbgrace}:g if exists $obj->{gbgrace};
	$fmt =~ s:%fI:$obj->{gigrace}:g if exists $obj->{gigrace};

	# note: bsoft/bhard/isoft/ihard 'overloaded' btw group/user objs
	# this could potentially create ambiguity if wrong object applied 
	# to a given format string..

	$fmt =~ s:%ub:$obj->{bsoft}:g if exists $obj->{bsoft};
	$fmt =~ s:%uB:$obj->{bhard}:g if exists $obj->{bhard};
	$fmt =~ s:%ui:$obj->{isoft}:g if exists $obj->{isoft};
	$fmt =~ s:%uI:$obj->{ihard}:g if exists $obj->{ihard};

	$fmt =~ s:%gb:$obj->{bsoft}:g if exists $obj->{bsoft};
	$fmt =~ s:%gB:$obj->{bhard}:g if exists $obj->{bhard};
	$fmt =~ s:%gi:$obj->{isoft}:g if exists $obj->{isoft};
	$fmt =~ s:%gI:$obj->{ihard}:g if exists $obj->{ihard};

	return $fmt;

}

sub RunCommand {
	my $cmd = shift;

	my $dbg = $ENV{'QUOTAADM_DEBUG'};

	if ($dbg && $dbg eq 'v') { # verbose
		print "$cmd\n";
	}
	if ($dbg && $dbg eq 'p') { # printonly
		print "$cmd\n";
		return 0; 
	}
	my $rval = system $cmd;
	return $rval == 0 ? $rval : $? >> 8;
}

1;

