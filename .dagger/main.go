package main

import (
	"context"
	"fmt"

	"dagger/tgbotserver/internal/dagger"
)

const (
	SourceGitUrl = "https://github.com/tdlib/telegram-bot-api"

	// https://hub.docker.com/_/alpine/tags/
	AlpineDockerImage = "alpine:3.22"

	ExposedPort = 80

	NL = "\n"
)

var (
	Ctx = context.TODO()
)

type Tgbotserver struct{}

func (m *Tgbotserver) Build() *dagger.Container {

	srcgit := dag.Git(SourceGitUrl).Head().Tree()

	a := dag.Container().
		From(AlpineDockerImage).
		WithExec([]string{"apk", "upgrade", "--no-cache"}).
		WithExec([]string{"apk", "add", "--no-cache", "alpine-sdk", "linux-headers", "zlib-dev", "openssl-dev", "gperf", "cmake"}).
		WithDirectory("/tgbotserver/", srcgit).
		WithDirectory("/tgbotserver/build/", dag.Directory()).
		WithWorkdir("/tgbotserver/build/").
		WithExec([]string{"cmake", "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_INSTALL_PREFIX:PATH=/tgbotserver/", "/tgbotserver/"}).
		WithExec([]string{"cmake", "--build", ".", "--target", "install"})

	b := dag.Container().
		From(AlpineDockerImage).
		WithExec([]string{"apk", "upgrade", "--no-cache"}).
		WithExec([]string{"apk", "add", "--no-cache", "openssl", "zlib", "libstdc++"}).
		WithDirectory("/tgbotserver/", dag.Directory()).
		WithWorkdir("/tgbotserver/").
		WithFile("/tgbotserver/tgbotserver", a.File("/tgbotserver/bin/telegram-bot-api")).
		WithEntrypoint([]string{"/tgbotserver", fmt.Sprintf("--http-port=%d", ExposedPort), "--local"}).
		WithExposedPort(ExposedPort)

	return b

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

	d := m.Build()
	if username != "" {
		d = d.WithRegistryAuth(registry, username, password)
	}
	p, _ := d.Publish(
		Ctx,
		registry+"/"+image,
	)

	return p

}
