#! /bin/bash
export PERL5LIB=thirdparty/lib/perl5
raku -Ilib bin/agrammon.raku --cfg-file=etc/agrammon.regional.yaml web version6/End.nhd
