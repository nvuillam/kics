package console

import (
	_ "embed" // Embed kics CLI img and scan-flags
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/Checkmarx/kics/internal/console/flags"
	consoleHelpers "github.com/Checkmarx/kics/internal/console/helpers"
	internalPrinter "github.com/Checkmarx/kics/internal/console/printer"
	"github.com/Checkmarx/kics/internal/constants"
	"github.com/Checkmarx/kics/internal/metrics"
	"github.com/Checkmarx/kics/pkg/progress"
	"github.com/pkg/errors"
	"github.com/rs/zerolog/log"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"golang.org/x/term"
)

func preRun(cmd *cobra.Command) error {
	err := initializeConfig(cmd)
	if err != nil {
		return errors.New(initError + err.Error())
	}

	err = flags.Validate()
	if err != nil {
		return err
	}

	err = flags.ValidateQuerySelectionFlags()
	if err != nil {
		return err
	}
	err = internalPrinter.SetupPrinter(cmd.InheritedFlags())
	if err != nil {
		return errors.New(initError + err.Error())
	}
	err = metrics.InitializeMetrics(flags.GetStrFlag(flags.ProfilingFlag), flags.GetStrFlag(flags.CIFlag))
	if err != nil {
		return errors.New(initError + err.Error())
	}
	return nil
}

func setupConfigFile() (bool, error) {
	if flags.GetStrFlag(flags.ConfigFlag) == "" {
		path := flags.GetMultiStrFlag(flags.PathFlag)
		if len(path) == 0 {
			return true, nil
		}
		if len(path) > 1 {
			warnings = append(warnings, "Any kics.config file will be ignored, please use --config if kics.config is wanted")
			return true, nil
		}
		configPath := path[0]
		info, err := os.Stat(configPath)
		if err != nil {
			return true, nil
		}
		if !info.IsDir() {
			configPath = filepath.Dir(configPath)
		}
		_, err = os.Stat(filepath.ToSlash(filepath.Join(configPath, constants.DefaultConfigFilename)))
		if err != nil {
			if os.IsNotExist(err) {
				return true, nil
			}
			return true, err
		}
		flags.SetStrFlag(flags.ConfigFlag, filepath.ToSlash(filepath.Join(configPath, constants.DefaultConfigFilename)))
	}
	return false, nil
}

func initializeConfig(cmd *cobra.Command) error {
	log.Debug().Msg("console.initializeConfig()")

	v := viper.New()
	v.SetEnvPrefix("KICS")
	v.AutomaticEnv()
	errBind := flags.BindFlags(cmd, v)
	if errBind != nil {
		return errBind
	}

	exit, err := setupConfigFile()
	if err != nil {
		return err
	}
	if exit {
		return nil
	}

	base := filepath.Base(flags.GetStrFlag(flags.ConfigFlag))
	v.SetConfigName(base)
	v.AddConfigPath(filepath.Dir(flags.GetStrFlag(flags.ConfigFlag)))
	ext, err := consoleHelpers.FileAnalyzer(flags.GetStrFlag(flags.ConfigFlag))
	if err != nil {
		return err
	}
	v.SetConfigType(ext)
	if err := v.ReadInConfig(); err != nil {
		return err
	}

	errBind = flags.BindFlags(cmd, v)
	if errBind != nil {
		return errBind
	}
	return nil
}

type console struct {
	Printer       *consoleHelpers.Printer
	ProBarBuilder *progress.PbBuilder
}

func newConsole() *console {
	return &console{}
}

// preScan is responsible for scan preparation
func (console *console) preScan() {
	log.Debug().Msg("console.scan()")
	for _, warn := range warnings {
		log.Warn().Msgf(warn)
	}

	printer := consoleHelpers.NewPrinter(flags.GetBoolFlag(flags.MinimalUIFlag))
	printer.Success.Printf("\n%s\n", banner)

	versionMsg := fmt.Sprintf("\nScanning with %s\n\n", constants.GetVersion())
	fmt.Println(versionMsg)
	log.Info().Msgf(strings.ReplaceAll(versionMsg, "\n", ""))

	noProgress := flags.GetBoolFlag(flags.NoProgressFlag)
	if !term.IsTerminal(int(os.Stdin.Fd())) || strings.EqualFold(flags.GetStrFlag(flags.LogLevelFlag), "debug") {
		noProgress = true
	}

	proBarBuilder := progress.InitializePbBuilder(
		noProgress,
		flags.GetBoolFlag(flags.CIFlag),
		flags.GetBoolFlag(flags.SilentFlag))

	console.Printer = printer
	console.ProBarBuilder = proBarBuilder
}
