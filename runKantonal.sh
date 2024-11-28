#! /bin/bash
export PERL5LIB=thirdparty/lib/perl5
raku -Ilib bin/agrammon.raku --cfg-file=etc/agrammon.kantonal.yaml web version6/End.nhd
