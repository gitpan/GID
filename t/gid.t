#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
	package GIDTest;
	use GID;

	sub test_last_index {
		return last_index { $_ eq 1 } ( 1,1,1,1 );
	}

	sub test_uniq {
		return uniq ( 1,1,1,1 );
	}

	1;
}

{
	package GIDTest::NoDistinct;
	use GID qw(
		-distinct
	);

	sub test_distinct {
		return distinct ( 1,1,1,1 );
	}

	sub test_uniq {
		return uniq ( 1,1,1,1 );
	}

	1;
}

{
	package GIDTest::NoIo;
	use GID qw(
		-io
	);

	sub test_io {
		return io('xxxxxxxxxxxxxxxx');
	}

	1;
}

{
	package GIDTest::NoListMoreUtils;
	use GID qw(
		-List::MoreUtils
	);

	sub test_distinct {
		return distinct ( 1,1,1,1 );
	}

	sub test_uniq {
		return uniq ( 1,1,1,1 );
	}

	1;
}

is(GIDTest->test_last_index,3,'gid last_index works fine');
is_deeply([GIDTest->test_uniq],[1],'gid uniq works fine');

eval {
	GIDTest::NoDistinct->test_distinct;
};
like($@,qr/Undefined subroutine &GIDTest::NoDistinct::distinct/,'Excluded distinct on import');

is_deeply([GIDTest::NoDistinct->test_uniq],[1],'gid uniq works fine with exclude of distinct');

eval "
	package GIDTest::CrashExcludeInclude;
	use GID qw(
		-distinct
		distinct
	);
	1;
";
like($@,qr/GID: you can't define -exclude's and include's on import of GID/,'Not using include and exclude at once on import');

eval {
	GIDTest::NoIo->test_io;
};
like($@,qr/Undefined subroutine &GIDTest::NoIo::io/,'Don\'t load IO::All at all');

eval {
	GIDTest::NoListMoreUtils->test_distinct;
};
like($@,qr/Undefined subroutine &GIDTest::NoListMoreUtils::distinct/,'Excluded List::MoreUtils, distinct must fail');

eval {
	GIDTest::NoListMoreUtils->test_uniq;
};
like($@,qr/Undefined subroutine &GIDTest::NoListMoreUtils::uniq/,'Excluded List::MoreUtils, uniq must fail');

done_testing;
