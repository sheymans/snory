use strict;
use warnings;

use TOML qw(from_toml);
use File::Slurp qw(read_file write_file append_file);
use File::Copy qw(copy);
use File::Copy::Recursive qw(fcopy);
use Data::Dumper;
use File::Find qw(find);
use File::Basename qw(basename dirname);
use Image::ExifTool;
use Try::Tiny;
use Date::Parse qw(str2time);

# Read the TOML config file with metadata:
my $config = read_file("config.toml");

my ($config_data, $err) = from_toml($config);
unless ($config_data) {
    die "Error parsing toml: $err";
}

# Reading the config
my $header_file = $config_data->{header};
my $footer_file = $config_data->{footer};
my $title = $config_data->{title} || "No title";
my $javascripts = $config_data->{needed_js};
my $css = $config_data->{needed_css};
my $photo_dir = $config_data->{photos};
my $photo_format = $config_data->{photo_format} || "jpg";

unless (defined $photo_dir) {
    die "you need to specify a photos attribute with the directory to look for photos in config.toml";
}

my $header_text;
my $footer_text;
try {
    $header_text = read_file($header_file);
} catch {
    print "no header file specified, continuing without one."
};

try {
    $footer_text = read_file($footer_file);
} catch {
    print "no footer file specified, continuing without one."
};

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
append_file($index_file, "**$title**\n\n");

foreach my $js (@{$javascripts}) {
    print "copying $js to site\n";
    copy($js, "site");
}

if (defined $css) {
    copy($css, "site");
}

my @photo_metas = &collect_photo_metas();

my @photo_config_datas = &get_config_photos(@photo_metas);

print "Creating stories...\n";
for my $photo_config_data (@photo_config_datas) {
    &create_story($photo_config_data);
}

print "writing footer to $index_file\n";
append_file($index_file, "$footer_text\n");

# Collect all photo metas in the root directory $photo_dir.
sub collect_photo_metas {
    my @metas = ();
    find(sub { push @metas, $File::Find::name if &is_photo_meta}, $photo_dir);
    return @metas;
}

# A file is a meta for a photo if it ends on .toml. To be used in `File::Find`.
sub is_photo_meta {
    my $F = $File::Find::name;
    return $F =~ /toml$/;
}

# Create the location of the photo given the location of the meta. For example, the meta might be /home/pic.toml, which
# would make the photo file /home/pic.jpg (if the photo format is jpg).
sub photo_file {
    my $photo_meta = shift;
    my $photo_file = substr($photo_meta, 0, -4) . $photo_format;
    return $photo_file;
}

# Create a filename from a meta. For example, the meta might be /home/pic.toml, which would make the photo filename
# pic.jpg (if the photo format is jpg).
sub photo_filename {
    my $photo_meta = shift;
    my $photo_file = photo_file($photo_meta);
    return basename($photo_file);
}

# Create a story for a photo meta: this will create a story page, copy the photo to the right site location and
# add a link on the index page to this story page.
sub create_story {
    my ($config_photo_data) = @_;

    my $title = $config_photo_data->{title};
    my $date = $config_photo_data->{date};
    my $location = $config_photo_data->{location};
    my $description = $config_photo_data->{description};
    my $photo_meta = $config_photo_data->{photo_meta};

    my $story_html_base = &story_base_html($title, $date, $location, $photo_meta);

    my $photo_file = &photo_file($photo_meta);
    my $exif_info = &exif($photo_file);

    &create_story_page($title, $date, $location, $description, $photo_file, $story_html_base, $exif_info);

    my $destination_file = "site/$photo_file";
    fcopy($photo_file, $destination_file);

    &add_story_to_index($title, $date, $location, $story_html_base);

    print "Created $title, $date, $location story.\n";
}

# Read the EXIF info from the photo.
sub exif {
    my ($photo_filename) = @_;

    # Get Exif information from image file
    my $exifTool = new Image::ExifTool;
    my $info = $exifTool->ImageInfo($photo_filename);

    return $info;
}

# Get the photo data for a collection of photo metas (a photo meta is a location of the TOML with photo meta data)
sub get_config_photos {
    my @metas = @_;

    my @config_photo_datas = ();

    for my $photo_meta (@metas) {
        my $config_photo_data = &get_config_photo($photo_meta);
        push @config_photo_datas, $config_photo_data;
    }

    my @sorted = sort {
        my $d1 = $a->{date};
        my $d2 = $b->{date};

        my $epoch1 = str2time($d1);
        my $epoch2 = str2time($d2);

        # Most recent date first.
        $epoch2 cmp $epoch1;
    } @config_photo_datas;

    return @sorted;
}

# Read the TOML for a photo given a photo meta (a location where the TOML with the meta is).
sub get_config_photo {
    my $photo_meta = shift;

    my $config_photo = read_file($photo_meta);

    my ($config_photo_data, $err_photo) = from_toml($config_photo);
    unless ($config_photo_data) {
        die "Error parsing toml for story $photo_meta: $err_photo";
    }

    # Add the name of the meta to the meta data as well:
    $config_photo_data->{photo_meta} = $photo_meta;

    return $config_photo_data;
}

# Create the html story page.
sub create_story_page {
    my ($title, $date, $location, $description, $photo_file, $story_html_base, $exif_info) = @_;

    # File to write to:
    my $story_html = "site/$story_html_base";

    write_file($story_html, "$header_text\n");
    append_file($story_html, "**$title**\n");
    append_file($story_html, "\t$date\n");
    append_file($story_html, "\t$location\n");
    append_file($story_html, "\n![$description]($photo_file)\n");

    my $model = $$exif_info{'Model'};
    my $aperture = $$exif_info{'Aperture'};
    my $shutter_speed = $$exif_info{'ShutterSpeed'};
    my $lens = $$exif_info{'Lens'};
    append_file($story_html, "\n<center>(\_$model, f$aperture, ${shutter_speed}s, lens: $lens\_)</center>\n");

    append_file($story_html, "$footer_text\n");
}

# Create a base html filename for a story based on title, date, location.
sub story_base_html {
    my ($title, $date, $location, $photo_meta) = @_;

    # $photo_meta is a toml file with directory path, so it will always be unique during processing.
    my $unique_identifier = dirname($photo_meta);
    # get rid of slash / and dot
    $unique_identifier  =~ s/\/|\./_/g;

    my $story_html_base = "$unique_identifier-$title-$date-$location.html";
    # remove all whitespace
    $story_html_base =~ s/ +//g;
    return $story_html_base;
}

# Add story link to index file.
# TODO we want to add stories in order of date (most recent first).
sub add_story_to_index {
    my ($title, $date, $location, $story_html) = @_;
    append_file($index_file, "- [$date. $title. \_$location\_]($story_html)\n");
}
