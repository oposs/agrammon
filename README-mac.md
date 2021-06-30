# MacOS requirements

* libcrypto and libssl

  - brew install ...

  - https://github.com/sergot/openssl/issues/81

    ln -s /usr/local/opt/openssl/lib/libssl.1.1.dylib /usr/local/lib/libssl.dylib
    ln -s /usr/local/opt/openssl/lib/libcrypto.1.1.dylib /usr/local/lib/libcrypto.dylib

    (this might not be necessary for current rakudo installations as of
     2021-04)

* Postgres.app

  - add current PostgreSQL version in sidebar
  - old version: pg_dumpall pg.dump
    new version: psql -f pg.dump postgres

* libpq

  cd /usr/local/lib
  ln -s /Applications/Postgres.app/Contents//Versions/13/lib/libpq.* .

  (or similar for other PostgreSQL installations)
