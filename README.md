
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dplyr-cli

<!-- badges: start -->

![](https://img.shields.io/badge/cool-useless-green.svg)
<!-- badges: end -->

`dplyr-cli` uses [{littler}](https://cran.r-project.org/package=littler)
to run dplyr commands on CSV files in the terminal.

`dplyr-cli` makes use of the terminal pipe `|` instead of the magrittr
pipe (`%>%`) to run sequences of commands.

    cat mtcars.csv | group_by cyl | summarise "mpg = mean(mpg)" | kable
    #> | cyl|      mpg|
    #> |---:|--------:|
    #> |   4| 26.66364|
    #> |   6| 19.74286|
    #> |   8| 15.10000|

## Motivation

I wanted to be able to do quick hacks on CSV files on the command line
without actually starting a proper R session.

## What dplyr commands are supported?

Any command of the form `dplyr::verb(.data, code)`

Currently two extra commands are supported which are not part of
`dplyr`.

  - `csv` performs no dplyr command, but only outputs the input data as
    CSV to stdout
  - `kable` performs no dplyr command, but only outputs the input data
    as a `knitr::kable()` formatted string to stdout

## Limitations

  - When using special shell characters such as `()`, you’ll have to
    quote your code arguments
  - Every command runs in a separate R session - startup overhead can
    get prohibitive.

## Usage

``` sh
./dplyr.sh --help
#> dplyr-cli
#> 
#> Usage:
#>     dplyr.sh <command> [--file=fn] [--csv | -c] [--verbose | -v] [<code>...]
#>     dplyr.sh -h | --help
#> 
#> Options:
#>     -h --help            show this help text
#>     -f FILE --file=FILE  input CSV or RDS filename. If reading from stdin, assumes CSV [default: stdin]
#>     -c --csv             write output to stdout in CSV format (instead of default RDS file)
#>     -v --verbose         be verbose
```

## Installation

`dplyr-cli` is run from the shell but at every invocation is starting a
new rsession where the following packages are expected to be installed:

``` r
install.packages('littler')  # Scripting front-end for R
install.packages('glue')     # text manipulation
install.packages('dplyr')    # data manipulation
install.packages('docopt')   # CLI description language
```

To do it from the cli, install `r-base` (`sudo apt -y install r-base`) and then run

```bash
sudo su - -c "R -e \"install.packages('littler', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('glue', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('dplyr', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('docopt', repos='http://cran.rstudio.com/')\""
```

You’ll then need to download the shell script from my github and put
`dplyr.sh` somewhere in your path.

    git clone https://github.com/coolbutuseless/dplyr-cli

# Example data

``` r
write.csv(mtcars, "mtcars.csv", row.names = FALSE)
```

# Example 1 - Basic Usage

``` sh
# cat contents of input CSV into dplyr-cli.  
# Use '-c' to output CSV if this is the final step
cat mtcars.csv | ./dplyr.sh filter -c mpg == 21
#> "mpg","cyl","disp","hp","drat","wt","qsec","vs","am","gear","carb"
#> 21,6,160,110,3.9,2.62,16.46,0,1,4,4
#> 21,6,160,110,3.9,2.875,17.02,0,1,4,4
```

``` sh
# Put quotes around any commands which contain special characters like <>()
cat mtcars.csv | ./dplyr.sh filter -c "mpg < 11"
#> "mpg","cyl","disp","hp","drat","wt","qsec","vs","am","gear","carb"
#> 10.4,8,472,205,2.93,5.25,17.98,0,0,3,4
#> 10.4,8,460,215,3,5.424,17.82,0,0,3,4
```

``` sh
# Combine dplyr commands with shell 'head' command
./dplyr.sh select --file mtcars.csv -c cyl | head -n 6
#> "cyl"
#> 6
#> 6
#> 4
#> 6
#> 8
```

# Example 2 - Simple piping of commands (with shell pipe, not magrittr pipe)

``` sh
cat mtcars.csv | \
   ./dplyr.sh mutate "cyl2 = 2 * cyl"  | \
   ./dplyr.sh filter "cyl == 8" | \
   ./dplyr.sh kable
#> |  mpg| cyl|  disp|  hp| drat|    wt|  qsec| vs| am| gear| carb| cyl2|
#> |----:|---:|-----:|---:|----:|-----:|-----:|--:|--:|----:|----:|----:|
#> | 18.7|   8| 360.0| 175| 3.15| 3.440| 17.02|  0|  0|    3|    2|   16|
#> | 14.3|   8| 360.0| 245| 3.21| 3.570| 15.84|  0|  0|    3|    4|   16|
#> | 16.4|   8| 275.8| 180| 3.07| 4.070| 17.40|  0|  0|    3|    3|   16|
#> | 17.3|   8| 275.8| 180| 3.07| 3.730| 17.60|  0|  0|    3|    3|   16|
#> | 15.2|   8| 275.8| 180| 3.07| 3.780| 18.00|  0|  0|    3|    3|   16|
#> | 10.4|   8| 472.0| 205| 2.93| 5.250| 17.98|  0|  0|    3|    4|   16|
#> | 10.4|   8| 460.0| 215| 3.00| 5.424| 17.82|  0|  0|    3|    4|   16|
#> | 14.7|   8| 440.0| 230| 3.23| 5.345| 17.42|  0|  0|    3|    4|   16|
#> | 15.5|   8| 318.0| 150| 2.76| 3.520| 16.87|  0|  0|    3|    2|   16|
#> | 15.2|   8| 304.0| 150| 3.15| 3.435| 17.30|  0|  0|    3|    2|   16|
#> | 13.3|   8| 350.0| 245| 3.73| 3.840| 15.41|  0|  0|    3|    4|   16|
#> | 19.2|   8| 400.0| 175| 3.08| 3.845| 17.05|  0|  0|    3|    2|   16|
#> | 15.8|   8| 351.0| 264| 4.22| 3.170| 14.50|  0|  1|    5|    4|   16|
#> | 15.0|   8| 301.0| 335| 3.54| 3.570| 14.60|  0|  1|    5|    8|   16|
```

# Example 3 - set up some aliases for convenience

``` sh
alias mutate="./dplyr.sh mutate"
alias filter="./dplyr.sh filter"
alias select="./dplyr.sh select"
alias summarise="./dplyr.sh summarise"
alias group_by="./dplyr.sh group_by"
alias ungroup="./dplyr.sh ungroup"
alias count="./dplyr.sh count"
alias arrange="./dplyr.sh arrange"
alias kable="./dplyr.sh kable"


cat mtcars.csv | group_by cyl | summarise "mpg = mean(mpg)" | kable
#> | cyl|      mpg|
#> |---:|--------:|
#> |   4| 26.66364|
#> |   6| 19.74286|
#> |   8| 15.10000|
```

## Security warning

`dplyr-cli` uses `eval(parse(text = ...))` on user input. Do not expose
this program to the internet or random users under any circumstances.

## Inspirations

  - [xsv](https://github.com/BurntSushi/xsv) - a fast CSV command line
    toolkit written in Rust
  - [jq](https://stedolan.github.io/jq/) - a command line JSON
    processor.
