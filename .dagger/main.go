package main

import (
	"context"
	"fmt"
	"strings"

	"dagger/tgbotserver/internal/dagger"

	"golang.org/x/sync/errgroup"
)

const (
	SourceGitUrl      = "https://github.com/tdlib/telegram-bot-api"
	GolangDockerImage = "golang:1.23.6"
	AlpineDockerImage = "alpine:3.21.2"
	ExposedPort       = 80

	NL = "\n"
)

var (
	Platforms = []dagger.Platform{
		"linux/arm64",
		"linux/amd64",
	}

	Ctx = context.TODO()
)

type Tgbotserver struct{}

func (m *Tgbotserver) Build() []*dagger.Container {

	srcgit := dag.Git(SourceGitUrl).Head().Tree()

	c := make([]*dagger.Container, 0, len(Platforms))

	eg, _ := errgroup.WithContext(Ctx)

	for _, platform := range Platforms {

		eg.Go(func() (err error) {

			fmt.Printf("platform==%s"+NL, platform)

			arch := strings.Split(string(platform), "/")[1]
			fmt.Printf("arch==%s"+NL, arch)

			// https://hub.docker.com/_/alpine/tags/
			a := dag.Container().
				From(AlpineDockerImage).
				WithExec([]string{"apk", "upgrade", "--no-cache"}).
				WithExec([]string{"apk", "add", "--no-cache", "alpine-sdk", "linux-headers", "zlib-dev", "openssl-dev", "gperf", "cmake"}).
				WithDirectory("/root/tgbotserver/", srcgit).
				WithDirectory("/root/tgbotserver/build/", dag.Directory()).
				WithWorkdir("/root/tgbotserver/build/").
				WithExec([]string{"cmake", "-DCMAKE_SYSTEM_PROCESSOR=" + arch, "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_INSTALL_PREFIX:PATH=/root/tgbotserver/", "/root/tgbotserver/"}).
				WithExec([]string{"cmake", "--build", ".", "--target", "install"})

			// https://hub.docker.com/_/alpine/tags/
			b := dag.Container(dagger.ContainerOpts{Platform: platform}).
				From(AlpineDockerImage).
				WithExec([]string{"apk", "upgrade", "--no-cache"}).
				WithExec([]string{"apk", "add", "--no-cache", "openssl", "zlib", "libstdc++"}).
				WithFile("/bin/tgbotserver", a.File("/root/tgbotserver/bin/telegram-bot-api")).
				WithWorkdir("/root/").
				WithEntrypoint([]string{"/bin/tgbotserver", fmt.Sprintf("--http-port=%d", ExposedPort), "--local"}).
				WithExposedPort(ExposedPort)

			c = append(c, b)

			return err
		})

		eg.Wait()

	}

	return c

}

func (m *Tgbotserver) Publish(
	// +default="ghcr.io"
	registry string,
	// +optional
	username string,
	// +optional
	password *dagger.Secret,
	image string,
) string {

	d := dag.Container()
	if username != "" {
		d = d.WithRegistryAuth(registry, username, password)
	}
	p, _ := d.Publish(Ctx,
		registry+"/"+image,
		dagger.ContainerPublishOpts{
			PlatformVariants: m.Build(),
		},
	)

	return p

}
