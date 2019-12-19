# Agrammon

## The simulation model

Ammonia volatilisation is a significant source of nitrogen (N) loss in
agriculture.  Almost one-third of the N load of farmyard manure is lost this
way, resulting in both a financial loss as well as diminished productivity
for the farmer.  At the same time, ammonia emissions are detrimental to the
environment, in particular to natural ecosystems.

The simulation model Agrammon allows ammonia emissions to be calculated, and
shows how changes in structure and production methods at the farm level
affect emissions.

The model was developed by the [Swiss College of Agriculture
(SHL)](http://www.shl.bfh.ch/) and the companies [Bonjour Engineering
GmbH](http://http://www.ecodata.ch) and [Oetiker+Partner
AG](https://www.oetiker.ch), with support from the [Federal Office for the
Environment (FOEN)](https://www.bafu.admin.ch/bafu/en/home.html).

Please see the [Agrammon website](https://www.agrammon.ch) for more details.

## Port to Raku

This is a port of the existing Agrammon web application to Raku. It is complete enough to
run models from the command line, however the web UI related parts, user management, and
so forth are still to be ported.

## Running tests

To only run unit tests, set `AGRAMMON_UNIT_TEST=1` in the environment. The integration
tests currently have quite some setup dependencies; this should be addressed in the
future.
