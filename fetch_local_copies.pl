#!/usr/bin/perl
use strict;
use warnings;

use File::Path qw(make_path);
use File::Basename qw(basename);
use File::Find;

make_path('page_requisites');
make_path('archive');

my $dir;

open(my $fh, '<', 'README.md') or die "Could not open file: $!";
while (my $row = <$fh>) {
    chomp $row;

    if ($row =~ /^# (.*)/) {
        $dir = encode($1);

    } elsif ($row =~ /^### (.*)/) {
        $dir = (split /\//, $dir)[0] . '/' . encode($1);
        make_path('archive/' . $dir);

    } elsif ($row =~ /\[(.*)\]\((.*)\)/) {
        my $title = $1;
        my $url = $2;

        # Make sure the URL is not anchored to a fixed header
        $url =~ s/#[^\/]*$//;

        # Fetch a local copy of the page
        qx{wget $url -P 'page_requisites' --config=.wgetrc};
        
        # Find the file to view the page, which is either an index.html file
        # in a directory with the name "basename($url)", or a file named
        # "basename($url)"
        my @file_list;
        find (sub {
                return unless -d $_ || -f $_;
                return unless basename($url) eq $_;
                push @file_list, $File::Find::name;
            }, 'page_requisites');

        # Make sure it exists and is unique because I'm not entirely sure
        # about the above comment
        die sprintf("No (unique) match for '%s'", basename($url))
        unless 0+@file_list == 1;
        my $file;
        if (-f $file_list[0]) {
            $file = $file_list[0];
        } elsif (-d $file_list[0] && -e $file_list[0] . '/index.html') {
            $file = $file_list[0] . '/index.html';
        }
        die sprintf("File not found for '%s'", basename($url))
        unless defined $file;

        # Create a symbolic link to the file for convenient access in a tidy
        # directory tree
        symlink($file, 'archive/' . $dir . '/' . encode($title));
    }
}

sub encode {
    my $text = lc($_[0]);
    $text =~ s/[[:punct:]]//g;
    $text =~ s/\s+/-/g;
    return $text;
}
