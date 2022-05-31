package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/tinygo-org/tinygo/builder"
	"github.com/tinygo-org/tinygo/compileopts"
)

var outpath string
var useRelease bool

func main() {
	flag.StringVar(&outpath, "out", "", "path of the binary to create")
	flag.BoolVar(&useRelease, "use-release", true, "toggle to use tinygo via release instead of from source")
	flag.Parse()

	// set tinygo root
	wd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	var tinygoRoot string
	if useRelease {
		tinygoRoot = filepath.Join(wd, "lib/tinygo-release/tinygo")
	} else {
		tinygoRoot = filepath.Join(wd, "lib/tinygo")
	}
	fmt.Printf("setting TINYGOROOT env var to %v\n", tinygoRoot)
	os.Setenv("TINYGOROOT", tinygoRoot)

	pkgName := "."
	if flag.NArg() == 1 {
		pkgName = filepath.ToSlash(flag.Arg(0))
	} else if flag.NArg() > 1 {
		fmt.Fprintln(os.Stderr, "build only accepts a single positional argument: package name, but multiple were specified")
		os.Exit(1)
	}

	err = build(pkgName, outpath, &compileopts.Options{
		Target: "wasi",
		// zero optimization
		Opt: "z",
	})
	if err != nil {
		log.Fatalf("building binary: %v", err)
	}
}

func build(pkgName string, outpath string, options *compileopts.Options) error {
	config, err := builder.NewConfig(options)
	if err != nil {
		return err
	}
	return builder.Build(pkgName, outpath, config, func(result builder.BuildResult) error {
		if outpath == "" {
			if strings.HasSuffix(pkgName, ".go") {
				// A Go file was specified directly on the command line.
				// Base the binary name off of it.
				withoutFileEnding := pkgName[:len(pkgName)-3]
				outpath = filepath.Base(withoutFileEnding) + config.DefaultBinaryExtension()
			} else {
				// Pick a default output path based on the main directory.
				outpath = filepath.Base(result.MainDir) + config.DefaultBinaryExtension()
			}
		}

		if err := os.Rename(result.Binary, outpath); err != nil {
			// Moving failed. Do a file copy.
			inf, err := os.Open(result.Binary)
			if err != nil {
				return err
			}
			defer inf.Close()
			outf, err := os.OpenFile(outpath, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0777)
			if err != nil {
				return err
			}

			// Copy data to output file.
			_, err = io.Copy(outf, inf)
			if err != nil {
				return err
			}

			// Check whether file writing was successful.
			return outf.Close()
		} else {
			// Move was successful.
			return nil
		}
	})
}
