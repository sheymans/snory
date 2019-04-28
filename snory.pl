use strict;
use warnings;

use TOML qw(from_toml);
use File::Slurp qw(read_file write_file append_file);
use File::Copy qw(copy);
use Data::Dumper;

# Read the TOML config file with metadata:
my $config = read_file("config.toml");

my ($config_data, $err) = from_toml($config);
unless ($config_data) {
    die "Error parsing toml: $err";
}

# Reading the config
my $header_file = $config_data->{header};
my $footer_file = $config_data->{footer};
my $title = $config_data->{title};
my $javascripts = $config_data->{needed_js};


my $header_text = read_file($header_file);
my $footer_text = read_file($footer_file);

# Create the "site" directory if it does not exist yet:

if (-e "site") {
    print "directory site exists, overwriting contents\n";
} else {
    print "creating directory site\n";
    mkdir "site";
}

my $index_file = "site/index.html";

print "writing header text to $index_file\n";
write_file($index_file, "$header_text\n");

print "writing title to $index_file\n";
append_file($index_file, "**$title**\n");

print "writing footer to $index_file\n";
append_file($index_file, "$footer_text\n");

foreach my $js (@{$javascripts}) {
    print "copying $js to site\n";
    copy($js, "site");
}


print "done writing $index_file\n";







