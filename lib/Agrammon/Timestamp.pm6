use v6;

sub timestamp is export {
    ~DateTime.now( formatter => sub ($_) {
        sprintf '%02d.%02d.%04d %02d:%02d:%02d',
                .day, .month, .year, .hour, .minute, .second,
    });

}
