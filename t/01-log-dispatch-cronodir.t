use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::Mock::Guard;
use Test::More;

my $class = 'Log::Dispatch::CronoDir';

subtest 'Test instance' => sub {

    subtest 'Fails with insufficient params' => sub {
        dies_ok {
            $class->new(

                # Log::Dispatch::Output
                name      => 'foobar',
                min_level => 'debug',
                newline   => 1,

                # Log::Dispatch::CronoDir
                filename => 'test.log',
                )
        }, 'Missing dirname_pattern';

        dies_ok {
            $class->new(

                # Log::Dispatch::Output
                name      => 'foobar',
                min_level => 'debug',
                newline   => 1,

                # Log::Dispatch::CronoDir
                dirname_pattern => '/var/log/tmp/%Y/%m/%d',
                )
        }, 'Missing filename';
    };

    subtest 'Succeeds with valid params' => sub {
        my $dir = tempdir(CLEANUP => 1);
        my $log = $class->new(

            # Log::Dispatch::Output
            name      => 'foobar',
            min_level => 'debug',
            newline   => 1,

            # Log::Dispatch::CronoDir
            dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
            filename        => 'test.log',
        );
        my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
        my $output_dir = File::Spec->catdir($dir, $year + 1900, $mon + 1, $mday);

        isa_ok $log, 'Log::Dispatch::CronoDir';

        subtest 'Output dir is created' => sub {
            ok -d $output_dir;
        };
    };
};

subtest 'Test log_message' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $log = Log::Dispatch::CronoDir->new(

        # Log::Dispatch::Output
        name      => 'foobar',
        min_level => 'debug',
        newline   => 1,

        # Log::Dispatch::CronoDir
        dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
        filename        => 'test.log',
    );

    subtest 'Write to current directory' => sub {
        lives_ok { $log->log_message(level => 'error', message => 'Test1') };

        my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
        my $output_file = File::Spec->catfile($dir, $year + 1900, $mon + 1, $mday, 'test.log');

        ok -f $output_file;

        my $content = do {
            local $/ = undef;
            open my $fh, '<', $output_file;
            <$fh>;
        };

        is $content, "Test1\n";
    };

    subtest 'Write to 2000-01-01 directory' => sub {
        my $guard = mock_guard($class => { _localtime => sub { (0, 0, 0, 1, 0, 100) }, });

        lives_ok { $log->log_message(level => 'error', message => 'Test2') };

        my $output_file = File::Spec->catfile($dir, qw(2000 01 01), 'test.log');

        ok -f $output_file;

        my $content = do {
            local $/ = undef;
            open my $fh, '<', $output_file;
            <$fh>;
        };

        is $content, "Test1\n";
    };
};

subtest 'Test binmode' => sub {
    my $guard = mock_guard($class => { _localtime => sub { (0, 0, 0, 1, 0, 100) }, });

    subtest 'Multi-byte logging with :utf8' => sub {
        use utf8;

        my $dir = tempdir(CLEANUP => 1);
        my $log = Log::Dispatch::CronoDir->new(

            # Log::Dispatch::Output
            name      => 'foobar',
            min_level => 'debug',
            newline   => 1,

            # Log::Dispatch::CronoDir
            dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
            filename        => 'test.log',
            binmode         => ':utf8',
        );

        lives_ok { $log->log_message(level => 'error', message => 'あいうえお') };

        my $output_file = File::Spec->catfile($dir, qw(2000 01 01), 'test.log');

        my $content = do {
            local $/ = undef;
            open my $fh, '<', $output_file;
            binmode $fh, ':utf8';
            <$fh>
        };

        is $content, "あいうえお\n";
    };

    subtest 'Multi-byte logging without :utf8' => sub {
        no utf8;

        my $dir = tempdir(CLEANUP => 1);
        my $log = Log::Dispatch::CronoDir->new(

            # Log::Dispatch::Output
            name      => 'foobar',
            min_level => 'debug',
            newline   => 1,

            # Log::Dispatch::CronoDir
            dirname_pattern => File::Spec->catdir($dir, qw( %Y %m %d )),
            filename        => 'test.log',
        );

        lives_ok { $log->log_message(level => 'error', message => 'あいうえお') };

        my $output_file = File::Spec->catfile($dir, qw(2000 01 01), 'test.log');

        my $content = do {
            local $/ = undef;
            open my $fh, '<', $output_file;
            <$fh>
        };

        is $content, "あいうえお\n";
    };
};

done_testing;
