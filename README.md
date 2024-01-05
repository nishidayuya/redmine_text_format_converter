# Redmine text format converter

A Redmine plugin to convert text format from Textile to Markdown.

[![License X11](https://img.shields.io/badge/license-X11-brightgreen.svg)](https://raw.githubusercontent.com/nishidayuya/redmine_text_format_converter/master/LICENSE.txt)

## Requirements

* Redmine
* Pandoc 1.13 or later

## Installation

Copy the plugin directory into your Redmine plugins directory and run `bundle install`.

```sh
$ cd /path/to/redmine/plugins/
$ git clone https://github.com/nishidayuya/redmine_text_format_converter.git
$ cd redmine_text_format_converter/
$ bundle install
```

## Usage

Convert issues, comments, wikis, news, documents and messages text format from Textile to Markdown.

```sh
$ cd /path/to/redmine/
$ bundle exec rake redmine:convert_text_format
```

Optional: If your Pandoc stalled, check texts and fix it.

```sh
$ cd /path/to/redmine/
$ bundle exec rake redmine:check_texts redmine:fix_invalid_texts
```
