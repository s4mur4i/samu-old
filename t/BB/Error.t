#!/usr/bin/perl
use strict;
use warnings;
use 5.14.0;
use Test::More;
use Test::Exception;
use Test::Output;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use BB::Log;
use Data::Dumper;
use File::Find;

BEGIN { use_ok('BB::Error'); }
my %tested;
my %file;
open(my $fh, "<", "$FindBin::Bin/../../lib/BB/Error.pm");
while ( my $line = <$fh>) {
    if ( $line =~ /^\s*'([^']*)'\s*=>\s*{\s*/ ) {
        $file{$1} = 1;
    }
}
diag("Parsed Error.pm for all used exceptions");
close $fh;
diag("Throwing all exceptions");
###
$tested{'BaseException'}=1;
eval { BaseException->throw(); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sI'm blue and I'm a WTF.+;/, "Base Exception for all exceptions output");
###
$tested{'Template'}=1;
eval { Template->throw( error => 'test', template => 'test' ); };
combined_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sI'm blue and I'm a WTF.....;/, "Template Base exception");
###
$tested{'TaskEr'}=1;
throws_ok { TaskEr->throw( error  => 'test'); } 'TaskEr', 'TaskEr Exception';
eval { TaskEr->throw( error => 'test' ); };
combined_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sI'm blue and I'm a WTF.....;/, "TaskEr Base exception");
###
$tested{'Connection'}=1;
throws_ok { Connection->throw( error  => 'test'); } 'Connection', 'Connection Exception';
eval { Connection->throw( error => 'test' ); };
combined_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sI'm blue and I'm a WTF.....;/, "Connection Base exception");
###
$tested{'Vcenter'}=1;
throws_ok { Vcenter->throw( error  => 'test'); } 'Vcenter', 'Vcenter Exception';
eval { Vcenter->throw( error => 'test' ); };
combined_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sI'm blue and I'm a WTF.....;/, "VCenter Base exception");
###
$tested{'Entity'}=1;
throws_ok { Entity->throw( error  => 'test'); } 'Entity', 'Entity Exception';
eval { Entity->throw( error => 'test1', entity => 'test2' ); };
combined_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sI'm blue and I'm a WTF.....;/, "Entity Base exception");
###
$tested{'Entity::NumException'}=1;
throws_ok { Entity::NumException->throw( error  => 'test', entity => 'test', count  => '0'); } 'Entity::NumException', 'Entity Num Exception';
eval { Entity::NumException->throw( error  => 'test', entity => 'teste', count  => '1'); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test',entity=>'teste',count=>'1';$/, "Entity Numcount exception output");
####
$tested{'Entity::Status'}=1;
throws_ok { Entity::Status->throw( error => 'test', entity => 'test' ) } 'Entity::Status', 'Entity Status Exception';
eval { Entity::Status->throw( error => 'test', entity => 'teste' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test',entity=>'teste';$/, "Entity Status exception output");
###
$tested{'Entity::Auth'}=1;
throws_ok { Entity::Auth->throw( error    => 'test', entity   => 'test', username => 'Joe', password => 'secret'); } 'Entity::Auth', 'Entity Auth Exception';
eval { Entity::Auth->throw( error    => 'test', entity   => 'teste', username => 'me', password => 'bebebebe'); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test',entity=>'teste',user=>'me',pass=>'bebebebe';$/, "Entity Auth exception output");
###
$tested{'Entity::TransferError'}=1;
throws_ok { Entity::TransferError->throw( error    => 'test', entity   => 'test', filename => '/some/path/to.me'); } 'Entity::TransferError', 'Entity Transfer Error Exception';
eval { Entity::TransferError->throw( error    => 'test', entity   => 'teste', filename => 'tast'); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test',entity=>'teste',source=>'tast';$/, "Entity TransferError exception output");
###
$tested{'Entity::HWError'}=1;
throws_ok { Entity::HWError->throw( error => 'test', entity => 'test', hw => 'dick' ); } 'Entity::HWError', 'Entity HW Error Exception';
eval { Entity::HWError->throw( error => 'test1', entity => 'test2', hw => 'dick' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test1',entity=>'test2',hw=>'dick';$/, "Entity HWError exception output");
###
$tested{'Entity::Snapshot'}=1;
throws_ok { Entity::Snapshot->throw( error    => 'test', entity   => 'test', snapshot => 'default'); } 'Entity::Snapshot', 'Entity Snapshot Exception';
eval { Entity::Snapshot->throw( error    => 'test1', entity   => 'test2', snapshot => 'test3'); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test1',entity=>'test2',snapshot=>'test3';$/, "Entity Snapshot exception output");
###
$tested{'Entity::Mac'}=1;
throws_ok { Entity::Mac->throw( error  => 'test', entity => 'test', mac    => '00:00:00:00:00:00'); } 'Entity::Mac', 'Entity Mac Exception';
eval { Entity::Mac->throw( error => 'test1', entity => 'test2', mac => 'test3' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test1',entity=>'test2',mac=>'test3';$/, "Entity Mac exception output");
###
$tested{'Vcenter::ServiceContent'}=1;
throws_ok { Vcenter::ServiceContent->throw( error => 'test' ) } 'Vcenter::ServiceContent', 'VCenter Service Content Exception';
eval { Vcenter::ServiceContent->throw( error => 'test' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test';$/, "VCenter ServiceContent exception output");
###
$tested{'Vcenter::Path'}=1;
throws_ok { Vcenter::Path->throw( error => 'test', path => '/path/to/inventory' ); } 'Vcenter::Path', 'VCenter Path Exception';
eval { Vcenter::Path->throw( error => 'test', path => '/some/path/to/gold' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test',path=>'\/some\/path\/to\/gold';$/, "VCenter Path exception output");
###
$tested{'Vcenter::Opts'}=1;
throws_ok { Vcenter::Opts->throw( error => 'test', opt => 'test1' ); } 'Vcenter::Opts', 'VCenter Opts Exception';
eval { Vcenter::Opts->throw( error => 'test', opt => 'test2' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test',opt=>'test2';$/, "VCenter Opts exception output");
###
$tested{'Template::Status'}=1;
throws_ok { Template::Status->throw( error => 'test', template => 'test' ) } 'Template::Status', 'Template Status Exception';
eval { Template::Status->throw( error => 'test', template => 'template' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test',template=>'template';$/, "Template Status exception output");
###
$tested{'Template::Error'}=1;
throws_ok { Template::Error->throw( error => 'test', template => 'test' ) } 'Template::Error', 'Template Error Exception';
eval { Template::Error->throw( error => 'test', template => 'template' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test',template=>'template';$/, "Template Error exception output");
###
$tested{'Connection::Connect'}=1;
throws_ok { Connection::Connect->throw( error => 'test', type  => 'test', dest  => 'test'); } 'Connection::Connect', 'Connection Connect Exception';
eval { Connection::Connect->throw( error => 'test1', type  => 'test2', dest  => 'test3'); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test1',type=>'test2',dest=>'test3';$/, "Connection Connect exception output");
###
$tested{'TaskEr::NotDefined'}=1;
throws_ok { TaskEr::NotDefined->throw( error => 'test' ) } 'TaskEr::NotDefined', 'Task NotDefined Exception';
eval { TaskEr::NotDefined->throw( error => 'test' ); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test';$/, "TaskEr NotDefined exception output");
###
$tested{'TaskEr::Error'}=1;
throws_ok { TaskEr::Error->throw( error => 'test', detail => 'test', fault => 'test' ); } 'TaskEr::Error', 'Task Error Exception';
eval { TaskEr::Error->throw( error  => 'test1', fault  => 'test2', detail => 'test3'); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test1',detail=>'test3',fault=>'test2';$/, "TaskEr Error exception output");
###
$tested{'Vcenter::Module'}=1;
throws_ok { Vcenter::Module->throw( error => 'test', module => 'test' ); } 'Vcenter::Module', 'Vcenter Module Exception';
eval { Vcenter::Module->throw( error  => 'test1', module  => 'test2'); };
stderr_like( sub { &Error::catch_ex($@) }, qr/^Error.pm\s\[CRITICAL\]:\sDesc=>'test1',module=>'test2';$/, "Vcenter Module exception output");
###
diag("Testing if every Exception is tested from file");
for my $ex ( keys %tested ) {
    is( $file{$ex}, 1, "$ex is in file");
}
diag("Reverse test");
for my $ex ( keys %file) {
    is( $tested{$ex}, 1, "$ex is tested" );
}
my %infile;
my @files;
my $dir = "$FindBin::Bin/../../";
find( sub { if ( $File::Find::name =~ /\.pm$/ ) { push( @files, $File::Find::name ); } }, $dir);
find( sub { if ( $File::Find::name =~ /\.pl$/ ) { push( @files, $File::Find::name ); } }, $dir);
for my $file ( @files ) {
    open( my $fh, "<", $file);
    while ( my $line = <$fh>) {
        if ( $line =~ /(\w*::\w*)->throw/ ) {
            $infile{$1}=1;
        }
    }
    close $fh;
}
for my $ex ( keys %infile ) {
    is( $file{$ex},1, "$ex exists in Error.pm");
}

done_testing();
