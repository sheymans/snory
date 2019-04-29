use strict;
use warnings;

use TOML qw(from_toml);
use File::Slurp qw(read_file write_file append_file);
use File::Copy qw(copy);
use Data::Dumper;
use File::Find qw(find);
use File::Basename qw(basename);

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


foreach my $js (@{$javascripts}) {
    print "copying $js to site\n";
    copy($js, "site");
}

my @photo_metas = ();
my $photo_dir = $config_data->{photos};
my $photo_format = $config_data->{photo_format};


find(\&add_to_photo_metas, $photo_dir);

print "Creating stories...\n";
for my $photo_meta (@photo_metas) {
    my $photo_file = &create_photo_file_from_meta($photo_meta);
    my $config_photo_data = &create_story($photo_meta, $photo_file);
    &create_story_on_index($config_photo_data);
}

print "writing footer to $index_file\n";
append_file($index_file, "$footer_text\n");

sub is_photo_meta {
    my $F = $File::Find::name;
    return $F =~ /toml$/;
}

sub add_to_photo_metas {
    if (is_photo_meta) {
        push @photo_metas, $File::Find::name;
    }
}

sub create_photo_file_from_meta {
    my $photo_meta = shift;
    my $photo_file = substr($photo_meta, 0, -4) . $photo_format;
    return $photo_file;
}

sub create_photo_filename_from_meta {
    my $photo_meta = shift;
    my $photo_file = create_photo_file_from_meta($photo_meta);
    return basename($photo_file);
}

sub create_story {
    my ($photo_meta, $photo_file) = @_;
    my $config_photo = read_file($photo_meta);

    my ($config_photo_data, $err_photo) = from_toml($config_photo);
    unless ($config_photo_data) {
        die "Error parsing toml: $err_photo";
    }

    my $title = $config_photo_data->{title};
    my $date = $config_photo_data->{date};
    my $location = $config_photo_data->{location};
    my $description = $config_photo_data->{description};

    my $story_html = "site/$title-$date-$location.html";
    # remove all whitespace
    $story_html =~ s/ +//g;

    write_file($story_html, "$header_text\n");
    append_file($story_html, "**$title**\n");
    append_file($story_html, "\t$date\n");
    append_file($story_html, "\t$location\n");


    my $photo_filename = &create_photo_filename_from_meta($photo_meta);
    append_file($story_html, "![$description]($photo_filename)\n");

    append_file($story_html, "$footer_text\n");

    # Copy the photo file over to right location.
    copy($photo_file, "site");
    print "Created $title, $date, $location story.\n";

    return $config_photo_data;

}

sub create_story_on_index {
    my $config_photo_data = shift;

    my $title = $config_photo_data->{title};
    my $date = $config_photo_data->{date};
    my $location = $config_photo_data->{location};

    my $story_html = "./$title-$date-$location.html";
    # remove all whitespace
    $story_html =~ s/ +//g;

    append_file($index_file, "- [$date. $title. \_$location\_]($story_html)\n");
}







