#' Render a reprex
#'
#' @description
#' Run a bit of R code using [rmarkdown::render()]. The goal is to make it
#' easy to share a small reproducible example ("reprex"), e.g., in a GitHub
#' issue. Reprex source can be
#'
#' * read from clipboard
#' * read from current selection or active document in RStudio
#'   (with [reprex_addin()])
#' * provided directly as expression, character vector, or string
#' * read from file
#'
#' @details
#' The usual "code + commented output" is returned invisibly, put on the
#' clipboard, and written to file. An HTML preview displays in RStudio's Viewer
#' pane, if available, or in the default browser, otherwise. Leading `"> "`
#' prompts, are stripped from the input code. Read more at
#' <http://reprex.tidyverse.org/>.
#'
#' reprex sets specific [knitr options](http://yihui.name/knitr/options/),
#' which you can supplement or override via the `opts_chunk` and
#' `opts_knit` arguments or via explicit calls to knitr in your reprex code
#' (see examples). If all you want to override is the `comment` option, use
#' the dedicated argument, e.g.`commment = "#;-)"`.
#' * Chunk options default to `collapse = TRUE`, `comment = "#>"`,
#'   `error = TRUE`. Note that `error = TRUE`, because a common use case is bug
#'   reporting.
#' * reprex also sets knitr's `upload.fun`. It defaults to
#'   [knitr::imgur_upload()] so figures produced by the reprex appear properly
#'   on GitHub, Stack Overflow, or Discourse. Note that this function requires
#'   the packages httr & xml2 or RCurl & XML, depending on your knitr version.
#'   When `venue = "r"`, `upload.fun` is set to `identity`, so that figures
#'   remain local. In that case, you may also want to set `outfile`.
#'
#' @param x An expression. If not given, `reprex()` looks for code in
#'   `input` or on the clipboard, in that order.
#' @param input Character. If has length one and lacks a terminating newline,
#'   interpreted as the path to a file containing reprex code. Otherwise,
#'   assumed to hold reprex code as character vector.
#' @param outfile Optional basename for output files. When `NULL`
#'   (default), reprex writes to temp files below the session temp directory. If
#'   `outfile = "foo"`, expect output files in current working directory,
#'   like `foo_reprex.R`, `foo_reprex.md`, and, if `venue = "r"`,
#'   `foo_rendered.R`. If `outfile = NA`, expect output files in
#'   a location and with basename derived from `input`, if sensible, or in
#'   current working directory with basename derived from [tempfile()]
#'   otherwise.
#' @param venue Character. Must be one of the following:
#' * "gh" for GitHub, the default
#' * "so" for Stack Overflow
#' * "ds" for Discourse, e.g.,
#'   [community.rstudio.com](https://community.rstudio.com). Note: this is
#'   currently just an alias for "gh"!
#' * "r" or "R" for a runnable R script, with commented output interleaved
#' @param advertise Logical. Whether to include a footer that describes when and
#'   how the reprex was created. Read more about [opt()].
#' @param si Logical. Whether to include [devtools::session_info()], if
#'   available, or [sessionInfo()] at the end of the reprex. When `venue` is
#'   "gh" or "ds", the session info is wrapped in a collapsible details tag.
#'   Read more about [opt()].
#' @param style Logical. Whether to style code with [styler::style_text()].
#'   Read more about [opt()].
#' @param show Logical. Whether to show rendered output in a viewer (RStudio or
#'   browser). Read more about [opt()].
#' @param comment Character. Prefix with which to comment out output, defaults
#'   to `"#>"`. Read more about [opt()].
#' @param render Logical. Whether to render the reprex or just create the
#'   templated `.R` file. Defaults to `TRUE`. Mostly for internal testing
#'   purposes.
#' @param opts_chunk,opts_knit Named list. Optional
#'   [knitr chunk and package options](http://yihui.name/knitr/options/) that
#'   are forwarded to `knitr::opts_chunk$set()` and `knitr::opts_knit$set()`,
#'   respectively.
#' @param tidyverse_quiet Logical. Sets the option `tidyverse.quiet`, which
#'   suppresses (`TRUE`, the default) or includes (`FALSE`) the startup message
#'   for the tidyverse package. Read more about [opt()].
#' @param std_out_err Logical. Whether to append a section for output sent to
#'   stdout and stderr by the reprex rendering process. This can be necessary to
#'   reveal output if the reprex spawns child processes or `system()` calls.
#'   Note this cannot be properly interleaved with output from the main R
#'   process, nor is there any guarantee that the lines from standard output and
#'   standard error are in correct chronological order. See [callr::r_safe()]
#'   for more. Read more about [opt()].
#'
#' @return Character vector of rendered reprex, invisibly.
#' @examples
#' \dontrun{
#' # put some code like this on the clipboard
#' # (y <- 1:4)
#' # mean(y)
#' reprex()
#'
#' # provide code as an expression
#' reprex(rbinom(3, size = 10, prob = 0.5))
#' reprex({y <- 1:4; mean(y)})
#' reprex({y <- 1:4; mean(y)}, style = TRUE)
#'
#' # note that you can include newlines in those brackets
#' # in fact, that is often a good idea
#' reprex({
#'   x <- 1:4
#'   y <- 2:5
#'   x + y
#' })
#'
#' ## provide code via character vector
#' reprex(input = c("x <- 1:4", "y <- 2:5", "x + y"))
#'
#' ## if just one line, terminate with '\n'
#' reprex(input = "rnorm(3)\n")
#'
#' ## customize the output comment prefix
#' reprex(rbinom(3, size = 10, prob = 0.5), comment = "#;-)")
#'
#' # override a default chunk option, in general
#' reprex({(y <- 1:4); median(y)}, opts_chunk = list(collapse = FALSE))
#' # the above is simply shorthand for this and produces same result
#' reprex({
#'   #+ setup, include = FALSE
#'   knitr::opts_chunk$set(collapse = FALSE)
#'
#'   #+ actual-reprex-code
#'   (y <- 1:4)
#'   median(y)
#' })
#'
#' # add prose, use general markdown formatting
#' reprex({
#'   #' # A Big Heading
#'   #'
#'   #' Look at my cute example. I love the
#'   #' [reprex](https://github.com/tidyverse/reprex#readme) package!
#'   y <- 1:4
#'   mean(y)
#' }, advertise = FALSE)
#'
#' # read reprex from file
#' writeLines(c("x <- 1:4", "mean(x)"), "foofy.R")
#' reprex(input = "foofy.R")
#'
#' # read from file and write to similarly-named outfiles
#' reprex(input = "foofy.R", outfile = NA)
#' list.files(pattern = "foofy")
#' file.remove(list.files(pattern = "foofy"))
#'
#' # write rendered reprex to file
#' reprex({
#'   x <- 1:4
#'   y <- 2:5
#'   x + y
#' }, outfile = "foofy")
#' list.files(pattern = "foofy")
#' file.remove(list.files(pattern = "foofy"))
#'
#' # write reprex to file AND keep figure local too, i.e. don't post to imgur
#' reprex({
#'   #' Some prose
#'   ## regular comment
#'   (x <- 1:4)
#'   median(x)
#'   plot(x)
#'   }, outfile = "blarg", opts_knit = list(upload.fun = identity))
#' list.files(pattern = "blarg")
#' unlink(list.files(pattern = "blarg"), recursive = TRUE)
#'
#' ## target venue = Stack Overflow
#' ## https://stackoverflow.com/editing-help
#' ret <- reprex({
#'   x <- 1:4
#'   y <- 2:5
#'   x + y
#' }, venue = "so")
#' ret
#'
#' ## target venue = R, also good for email or Slack snippets
#' ret <- reprex({
#'   x <- 1:4
#'   y <- 2:5
#'   x + y
#' }, venue = "R")
#' ret
#'
#' ## include prompt and don't comment the output
#' ## use this when you want to make your code hard to execute :)
#' reprex({
#'   x <- 1:4
#'   y <- 2:5
#'   x + y
#' }, opts_chunk = list(comment = NA, prompt = TRUE))
#'
#' ## leading prompts are stripped from source
#' reprex(input = c("> x <- 1:3", "> median(x)"))
#' }
#'
#' @import rlang
#' @export
reprex <- function(x = NULL,
                   input = NULL, outfile = NULL,
                   venue = c("gh", "so", "ds", "r"),
                   advertise = opt(TRUE),
                   si = opt(FALSE),
                   style = opt(FALSE),
                   show = opt(TRUE),
                   comment = opt("#>"),
                   opts_chunk = NULL,
                   opts_knit = NULL,
                   tidyverse_quiet = opt(TRUE),
                   std_out_err = opt(FALSE),
                   render = TRUE) {
  venue <- tolower(venue)
  venue <- match.arg(venue)
  venue <- ds_is_gh(venue)

  advertise <- arg_option(advertise)
  si <- arg_option(si)
  style <- arg_option(style)
  show <- arg_option(show)
  comment <- arg_option(comment)
  tidyverse_quiet <- arg_option(tidyverse_quiet)
  std_out_err <- arg_option(std_out_err)
  opts_chunk <- substitute(opts_chunk)
  opts_knit <- substitute(opts_knit)

  stopifnot(is_toggle(advertise), is_toggle(si), is_toggle(style))
  stopifnot(is_toggle(show), is_toggle(render))
  stopifnot(is.character(comment))
  stopifnot(is_toggle(tidyverse_quiet), is_toggle(std_out_err))
  if (!is.null(input)) stopifnot(is.character(input))
  if (!is.null(outfile)) stopifnot(is.character(outfile) || is.na(outfile))

  the_source <- NULL
  x_captured <- substitute(x)
  if (!is.null(x_captured) && !is.null(input)) {
    message("`input` ignored in favor of expression input in `x`.")
    input <- NULL
  }
  infile <- if (is_path(input)) input else NULL
  the_source <- stringify_expression(x_captured) %||% ingest_input(input)

  if (style) {
    if (requireNamespace("styler", quietly = TRUE)) {
      the_source <- styler::style_text(the_source)
    } else {
      message("Install the styler package in order to use `style = TRUE`.")
    }
  }

  if (venue == "so") {
    ## empty line between html comment re: syntax highlighting and reprex code
    the_source <- c("", the_source)
  }

  outfile_given <- !is.null(outfile)
  files <- make_filenames(make_filebase(outfile, infile))
  r_file <- files[["r_file"]]
  if (would_clobber(r_file)) {
    return(invisible())
  }
  std_file <- if (std_out_err) files[["std_file"]] else NULL

  the_source <- ensure_not_empty(the_source)
  the_source <- ensure_not_dogfood(the_source)
  the_source <- ensure_no_prompts(the_source)
  the_source <- apply_template(c(
    fodder[[venue]],
    si = if (isTRUE(si)) .reprex[["session_info"]],
    comment = comment,
    upload_fun = if (venue == "r") "identity" else "knitr::imgur_upload",
    user_opts_chunk = prep_opts(opts_chunk, which = "chunk"),
    user_opts_knit = prep_opts(opts_knit, which = "knit"),
    tidyverse_quiet = as.character(tidyverse_quiet),
    std_file_stub = if (std_out_err) paste0("#' `", std_file, "`\n#'"),
    advertisement = advertise,
    body = paste(the_source, collapse = "\n")
  ))
  writeLines(the_source, r_file)
  if (outfile_given) {
    message("Preparing reprex as .R file to render:\n  * ", r_file)
  }

  if (!render) {
    return(invisible(readLines(r_file, encoding = "UTF-8")))
  }

  message("Rendering reprex...")
  ## when venue = "r", the reprex_file != md_file, so we need both
  reprex_file <- md_file <- reprex_(r_file, std_file)

  if (std_out_err) {
    ## replace backtick'ed std_file with its (lightly processed) contents
    inject_file(
      reprex_file,
      std_file,
      pre_process = enfence, tag = "standard output and standard error"
    )
  }

  if (outfile_given) {
    ## pathstem = the common part of the two paths
    pathstem <- path_stem(r_file, md_file)
    message("Writing reprex markdown:\n  * ", sub(pathstem, "", md_file))
  }

  if (identical(venue, "r")) {
    reprex_file <- files[["rout_file"]]
    output_lines <- readLines(md_file, encoding = "UTF-8")
    output_lines <- convert_md_to_r(output_lines, comment = comment)
    writeLines(output_lines, reprex_file)
    if (outfile_given) {
      message("Writing reprex as commented R script:\n  * ", reprex_file)
    }
  }

  if (show) {
    rmarkdown::render(
      md_file,
      output_file = files[["html_file"]],
      clean = FALSE,
      quiet = TRUE,
      encoding = "UTF-8",
      output_options = if (pandoc2.0()) list(pandoc_args = "--quiet")
    )

    ## html must live in session temp dir in order to display within RStudio
    files[["html_file"]] <- force_tempdir(files[["html_file"]])
    viewer <- getOption("viewer") %||% utils::browseURL
    viewer(files[["html_file"]])
  }

  out_lines <- readLines(reprex_file, encoding = "UTF-8")

  if (clipboard_available()) {
    clipr::write_clip(out_lines)
    message("Rendered reprex is on the clipboard.")
  } else if (interactive()) {
    clipr::dr_clipr()
    message(
      "Unable to put result on the clipboard. How to get it:\n",
      "  * Capture what `reprex()` returns.\n",
      "  * Consult the output file. Control via `outfile` argument.\n",
      "Path to `outfile`:\n",
      "  * ", reprex_file
    )
    if (yep("Open the output file for manual copy?")) {
      withr::defer(utils::file.edit(reprex_file))
    }
  }

  invisible(out_lines)
}

reprex_ <- function(input, std_out_err = NULL) {
  callr::r_safe(
    function(input) {
      options(keep.source = TRUE)
      rmarkdown::render(input, quiet = TRUE, envir = globalenv())
    },
    args = list(input = input),
    spinner = interactive(),
    stdout = std_out_err,
    stderr = std_out_err
  )
}

convert_md_to_r <- function(lines, comment = "#>") {
  line_info <- classify_lines_bt(lines, comment = comment)
  lines <- ifelse(
    line_info == "prose" & nzchar(lines),
    paste("#'", lines),
    lines
  )
  lines[line_info != "bt"]
}
