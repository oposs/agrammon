use v6;

role Agrammon::DB {
    method connection() { $*AGRAMMON-DB-CONNECTION }

    method with-db(&operation) {
        with $*AGRAMMON-DB-HANDLE {
            operation($*AGRAMMON-DB-HANDLE);
        }
        else {
            my $handle = self.connection.db;
            operation($handle); return;
            LEAVE $handle.finish;
        }
    }
}
