package Q::Loader::SQLite;

use strict;
use warnings;

use base 'Q::Loader::DBI';

use DBD::SQLite;

use Q::Validate qw( validate SCALAR_TYPE );

use Scalar::Util qw( looks_like_number );


unless ( defined &DBD::SQLite::db::column_info )
{
    *DBD::SQLite::db::column_info = \&_sqlite_column_info;
}

sub _sqlite_column_info {
    my($dbh, $catalog, $schema, $table, $column) = @_;

    my $sth_columns = $dbh->prepare( qq{PRAGMA table_info('$table')} );
    $sth_columns->execute;

    my @names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME
                    DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH
                    DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE
                    REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB
                    CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE
                    sqlite_autoincrement
                  );

    my @cols;
    while ( my $col_info = $sth_columns->fetchrow_hashref ) {
        next if defined $column && $column ne $col_info->{name};

        my %col;

        $col{TABLE_NAME} = $table;
        $col{COLUMN_NAME} = $col_info->{name};

        my $type = $col_info->{type};
        if ( $type =~ s/(\w+)\((\d+)(?:,(\d+))?\)/$1/ ) {
            $col{COLUMN_SIZE}    = $2;
            $col{DECIMAL_DIGITS} = $3;
        }

        $col{DATA_TYPE} = $type;

        $col{COLUMN_DEF} = $col_info->{dflt_value}
            if defined $col_info->{dflt_value};

        if ( $col_info->{notnull} ) {
            $col{NULLABLE}    = 0;
            $col{IS_NULLABLE} = 'NO';
        }
        else {
            $col{NULLABLE}    = 1;
            $col{IS_NULLABLE} = 'YES';
        }

        for my $key (@names) {
            $col{$key} = undef
                unless exists $col{$key};
        }

        push @cols, \%col;
    }

    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my $sth = $sponge->prepare("column_info $table", {
        rows => [ map { [ @{$_}{@names} ] } @cols ],
        NUM_OF_FIELDS => scalar @names,
        NAME => \@names,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());
    return $sth;
}

{
    my $spec = { name => SCALAR_TYPE };
    sub make_schema
    {
        my $self = shift;
        my %p    = validate( @_, $spec );

        $self->{schema_name} = delete $p{name};

        return $self->SUPER::make_schema(@_);
    }
}

sub _schema_name { $_[0]->{schema_name} }

sub _is_auto_increment
{
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    my $sql = $self->_table_sql($table);

    my $name = $col_info->{COLUMN_NAME};

    return $sql =~ /\Q$name\E\s+\w+[^,]+autoincrement(?:,|$)/m ? 1 : 0;
}

sub _table_sql {
    my $self     = shift;
    my $table    = shift;

    my $name = $table->name();
    return $self->{__table_sql__}{$name}
        if $self->{__table_sql__}{$name};

    return $self->{__table_sql__}{$name} =
        $self->dbh()->selectcol_arrayref
            ( 'SELECT sql FROM sqlite_master WHERE tbl_name = ?', {}, $table->name() )->[0];
}

sub _default
{
    my $self    = shift;
    my $default = shift;

    if ( $default =~ /^NULL$/i )
    {
        return undef;
    }
    elsif ( looks_like_number($default) )
    {
        return $default;
    }
    elsif ( $default =~ /CURRENT_(?:TIME(?:STAMP)?|DATE)/ )
    {
        return Q::Literal->term($default);
    }
    else
    {
        # defaults come back un-quoted from SQLite
        return $default;
    }
}


1;

__END__

