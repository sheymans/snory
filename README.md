# snory

> Tell a story with snory. 

`snory` creates an offline website for your photos. It currently creates 
one page per photo. Pages are in markdown format and the [example](./example) uses 
[markdeep](https://casual-effects.com/markdeep/) to format the markdown in html.

Markdeep allows for several styles and the [example](./example) uses the LaTeX style (see the [footer](./example/feet.html)).

You can add your own CSS by way of automatic footer/header inclusion, if so specificed in the global configuration [config.toml](./example/config.toml).

`snory` intends to allow for easy photo processing and documenting without affecting any existing photo folder structure, nor relying on
any proprietary software: all your photo's meta-data (title, location, ...) will be stored transparently alongside your photos.

For an example of a `snory` generated website, see [iwokeupthismorning](http://iwokeupthismorning.net).

## Quick Example

Once you pulled this repository:

```
$ cd example
$ perl snory.pl
$ open site/index.html
```

The generated website will be in `example/site`.

Resolve any missing _perl_ libraries using `cpan`. For example,

```
$ cpan TOML
```

## Details

### `config.toml`

Make sure that the directory from which you run `perl snory.pl` has a `config.toml` file. That file 
allows for the following attributes:

```
header = "head.html"
footer = "feet.html"
needed_js = ["markdeep.js"]
needed_css = "specific.css"
title = "I Woke Up this Morning"
photos = "./photos"
photo_format = "jpg"
```

- The `header` specifies the `html` file that will be included at the top of each page. 
- The `footer` specifies the `html` file that will be included at the bottom of each page.
- The `needed_js` specifies a list of Javascript files that you would like included in each page.
- The `needed_css` specifies a `css` file that you would like to include in each page.
- The `title` is the title used on the generated `index.html` page.
- The `photos` attribute specifies the top-level directory of all the photos you would like to include. Note that not all photos would be included, only those with another corresponding
`toml` file (see below).
- The `photo_format` indicates what photo format all your pictures are in. Currently, this is a setting that needs to applies for all the photos you want to include (you cannot mix formats).

### Including Photos

You indicate for an individual photo that you would like included for processing by `snory` by writing a corresponding `toml` file. 
For example, if you have a photo `ship.jpg` that you would like
to create a story for, you include (in the same directory as the photo), a file `ship.toml` that looks as follows:

```
title = "Grainery"
date = "26 December 2018"
location = "Seattle, USA"
description = "Ship waiting for grain."
```

This file will describe your photo transparently and can just live alongside your photo without depending on any software to maintain it.

## Contributing

Please open issues if you have feature requests or find bugs. As I do not expect to develop this actively except for my own needs,
 I welcome any contributions that extend the capability of `snory`. Thanks.