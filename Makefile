test:
	prove -j8 -e 'perl6 -Ilib' t
unit-test:
	AGRAMMON_UNIT_TEST=1 prove -j8 -e 'perl6 -Ilib' t
