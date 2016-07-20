
# Quota::Adm Makefile.PL

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Quota::Adm',
	VERSION_FROM => 'lib/Quota/Adm.pm',
	EXE_FILES => [ 
		"bin/quotaadm",
	],
);

